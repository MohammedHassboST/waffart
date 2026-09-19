-- دالة لحساب السعر حسب الكمية باستخدام Tiered Pricing
CREATE OR REPLACE FUNCTION get_tiered_price(
    p_product_id UUID,
    p_quantity INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_price NUMERIC(12,2);
    v_base_price NUMERIC(12,2);
BEGIN
    -- البحث عن السعر المناسب حسب الكمية
    SELECT price_per_unit INTO v_price
    FROM product_tiers
    WHERE product_id = p_product_id
      AND p_quantity >= min_quantity
      AND (max_quantity IS NULL OR p_quantity <= max_quantity)
    ORDER BY min_quantity DESC
    LIMIT 1;

    -- لو لم يوجد سعر متدرج، استخدم السعر الأساسي
    IF v_price IS NULL THEN
        SELECT base_price INTO v_base_price
        FROM products WHERE id = p_product_id;
        RETURN v_base_price;
    END IF;

    RETURN v_price;
END;
$$;

-- تحديث دالة تأكيد الطلب لاستخدام التسعير المتدرج
CREATE OR REPLACE FUNCTION confirm_order_atomic(
    p_customer_id UUID,
    p_cart_items JSONB,
    p_delivery_address TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_order_number TEXT;
    v_item RECORD;
    v_vendor_id UUID;
    v_sub_order_id UUID;
    v_current_stock INT;
    v_current_offer_remaining INT;
    v_total NUMERIC(12,2) := 0;
    v_result JSONB;
    v_final_price NUMERIC(12,2);
BEGIN
    v_order_number := 'WF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                      LPAD(NEXTVAL('order_seq')::TEXT, 5, '0');

    INSERT INTO orders (customer_id, order_number, delivery_address, notes, status)
    VALUES (p_customer_id, v_order_number, p_delivery_address, p_notes, 'pending')
    RETURNING id INTO v_order_id;

    FOR v_item IN
        SELECT * FROM jsonb_to_recordset(p_cart_items)
        AS x(product_id UUID, offer_id UUID, quantity INT, unit_price NUMERIC(12,2))
    LOOP
        SELECT vendor_id, stock_quantity
        INTO v_vendor_id, v_current_stock
        FROM products
        WHERE id = v_item.product_id
        FOR UPDATE;

        IF v_current_stock < v_item.quantity THEN
            RAISE EXCEPTION 'الكمية غير كافية للمنتج: %', v_item.product_id;
        END IF;

        -- حساب السعر النهائي: عرض ← تسعير متدرج ← سعر أساسي
        IF v_item.offer_id IS NOT NULL THEN
            v_final_price := v_item.unit_price;
            SELECT remaining_quantity INTO v_current_offer_remaining
            FROM offers WHERE id = v_item.offer_id FOR UPDATE;

            IF v_current_offer_remaining < v_item.quantity THEN
                RAISE EXCEPTION 'كمية العرض غير كافية';
            END IF;

            UPDATE offers
            SET sold_quantity = sold_quantity + v_item.quantity
            WHERE id = v_item.offer_id;

            INSERT INTO inventory_movements
                (product_id, offer_id, movement_type, quantity_change, reference_id)
            VALUES
                (v_item.product_id, v_item.offer_id, 'sale', -v_item.quantity, v_order_id);
        ELSE
            -- استخدام التسعير المتدرج
            v_final_price := get_tiered_price(v_item.product_id, v_item.quantity);
        END IF;

        UPDATE products
        SET stock_quantity = stock_quantity - v_item.quantity,
            updated_at = NOW()
        WHERE id = v_item.product_id;

        INSERT INTO inventory_movements
            (product_id, movement_type, quantity_change, reference_id)
        VALUES
            (v_item.product_id, 'sale', -v_item.quantity, v_order_id);

        INSERT INTO sub_orders (order_id, vendor_id, vendor_order_number, subtotal)
        VALUES (v_order_id, v_vendor_id, v_order_number || '-V' || v_vendor_id,
                v_item.quantity * v_final_price)
        ON CONFLICT (order_id, vendor_id)
        DO UPDATE SET subtotal = sub_orders.subtotal + (v_item.quantity * v_final_price)
        RETURNING id INTO v_sub_order_id;

        INSERT INTO sub_order_items
            (sub_order_id, product_id, offer_id, product_name, quantity, unit_price)
        SELECT v_sub_order_id, v_item.product_id, v_item.offer_id, p.name,
               v_item.quantity, v_final_price
        FROM products p WHERE p.id = v_item.product_id;

        v_total := v_total + (v_item.quantity * v_final_price);
    END LOOP;

    UPDATE orders SET total_amount = v_total WHERE id = v_order_id;
    DELETE FROM cart_items WHERE customer_id = p_customer_id;

    v_result := jsonb_build_object(
        'order_id', v_order_id,
        'order_number', v_order_number,
        'total_amount', v_total,
        'status', 'pending'
    );

    RETURN v_result;
END;
$$;

-- سياسات RLS للتسعير المتدرج
ALTER TABLE product_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view tiers"
ON product_tiers FOR SELECT
USING (TRUE);

CREATE POLICY "Vendors manage their own product tiers"
ON product_tiers FOR ALL
USING (product_id IN (
    SELECT id FROM products WHERE
        vendor_id IN (SELECT id FROM vendors WHERE profile_id = auth.uid())
));
-- ============================================================
-- 1. confirm_order_atomic (موجودة مسبقاً)
-- ============================================================

-- ============================================================
-- 2. cancel_order_atomic: إلغاء طلب وإرجاع الكميات
-- ============================================================
CREATE OR REPLACE FUNCTION cancel_order_atomic(
    p_order_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_customer_id UUID;
    v_status TEXT;
    v_item RECORD;
BEGIN
    -- قفل الطلب
    SELECT customer_id, status INTO v_customer_id, v_status
    FROM orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
    END IF;

    IF v_status IN ('delivered', 'cancelled') THEN
        RETURN jsonb_build_object('success', false, 'error', 'CANNOT_CANCEL');
    END IF;

    -- إرجاع المخزون لكل عنصر
    FOR v_item IN
        SELECT soi.product_id, soi.offer_id, soi.quantity
        FROM sub_order_items soi
        JOIN sub_orders so ON so.id = soi.sub_order_id
        WHERE so.order_id = p_order_id
    LOOP
        -- إرجاع المنتج
        UPDATE products
        SET stock_quantity = stock_quantity + v_item.quantity
        WHERE id = v_item.product_id;

        -- إرجاع العرض إذا وُجد
        IF v_item.offer_id IS NOT NULL THEN
            UPDATE offers
            SET sold_quantity = sold_quantity - v_item.quantity
            WHERE id = v_item.offer_id;
        END IF;

        -- تسجيل الحركة
        INSERT INTO inventory_movements
            (product_id, offer_id, movement_type, quantity_change, reference_id)
        VALUES
            (v_item.product_id, v_item.offer_id, 'return', v_item.quantity, p_order_id);
    END LOOP;

    -- تحديث الطلب
    UPDATE orders
    SET status = 'cancelled',
        updated_at = NOW()
    WHERE id = p_order_id;

    UPDATE sub_orders
    SET status = 'cancelled',
        rejection_reason = p_reason,
        updated_at = NOW()
    WHERE order_id = p_order_id
      AND status NOT IN ('shipped', 'delivered');

    RETURN jsonb_build_object('success', true, 'order_id', p_order_id);
END;
$$;

-- ============================================================
-- 3. add_product_with_stock: إضافة منتج مع مخزون أولي
-- ============================================================
CREATE OR REPLACE FUNCTION add_product_with_stock(
    p_vendor_id UUID,
    p_category_id UUID,
    p_name TEXT,
    p_description TEXT,
    p_image_urls TEXT[],
    p_sale_type TEXT,
    p_base_price NUMERIC,
    p_unit_label TEXT,
    p_initial_stock INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_product_id UUID;
BEGIN
    -- التحقق أن المورد يخص المستخدم الحالي
    IF NOT EXISTS (
        SELECT 1 FROM vendors
        WHERE id = p_vendor_id AND profile_id = auth.uid()
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
    END IF;

    INSERT INTO products (
        vendor_id, category_id, name, description, image_urls,
        sale_type, base_price, unit_label, stock_quantity
    ) VALUES (
        p_vendor_id, p_category_id, p_name, p_description, p_image_urls,
        p_sale_type, p_base_price, p_unit_label, p_initial_stock
    ) RETURNING id INTO v_product_id;

    -- تسجيل الحركة الأولية
    IF p_initial_stock > 0 THEN
        INSERT INTO inventory_movements
            (product_id, movement_type, quantity_change, notes, created_by)
        VALUES
            (v_product_id, 'restock', p_initial_stock, 'Initial stock', auth.uid());
    END IF;

    RETURN jsonb_build_object('success', true, 'product_id', v_product_id);
END;
$$;

-- ============================================================
-- 4. restock_product_atomic: إضافة مخزون جديد بأمان
-- ============================================================
CREATE OR REPLACE FUNCTION restock_product_atomic(
    p_product_id UUID,
    p_quantity INT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_vendor_id UUID;
    v_new_stock INT;
BEGIN
    -- التحقق من الصلاحية
    SELECT vendor_id INTO v_vendor_id
    FROM products WHERE id = p_product_id FOR UPDATE;

    IF v_vendor_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vendors
        WHERE id = v_vendor_id AND profile_id = auth.uid()
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
    END IF;

    IF p_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY');
    END IF;

    UPDATE products
    SET stock_quantity = stock_quantity + p_quantity,
        updated_at = NOW()
    WHERE id = p_product_id
    RETURNING stock_quantity INTO v_new_stock;

    INSERT INTO inventory_movements
        (product_id, movement_type, quantity_change, notes, created_by)
    VALUES
        (p_product_id, 'restock', p_quantity, p_notes, auth.uid());

    RETURN jsonb_build_object(
        'success', true,
        'new_stock', v_new_stock
    );
END;
$$;

-- ============================================================
-- 5. create_offer_atomic: إنشاء عرض مع حجز كمية
-- ============================================================
CREATE OR REPLACE FUNCTION create_offer_atomic(
    p_product_id UUID,
    p_title TEXT,
    p_offer_price NUMERIC,
    p_total_quantity INT,
    p_sale_type TEXT,
    p_end_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_vendor_id UUID;
    v_base_price NUMERIC;
    v_stock INT;
    v_offer_id UUID;
BEGIN
    SELECT vendor_id, base_price, stock_quantity
    INTO v_vendor_id, v_base_price, v_stock
    FROM products WHERE id = p_product_id FOR UPDATE;

    IF v_vendor_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM vendors WHERE id = v_vendor_id AND profile_id = auth.uid()
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
    END IF;

    IF p_total_quantity > v_stock THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INSUFFICIENT_STOCK',
            'available', v_stock
        );
    END IF;

    INSERT INTO offers (
        product_id, vendor_id, title, offer_price, original_price,
        total_quantity, sale_type, end_at
    ) VALUES (
        p_product_id, v_vendor_id, p_title, p_offer_price, v_base_price,
        p_total_quantity, p_sale_type, p_end_at
    ) RETURNING id INTO v_offer_id;

    -- تسجيل تخصيص المخزون للعرض
    INSERT INTO inventory_movements
        (product_id, offer_id, movement_type, quantity_change, notes)
    VALUES
        (p_product_id, v_offer_id, 'offer_allocation', -p_total_quantity,
         'Allocated to offer');

    RETURN jsonb_build_object('success', true, 'offer_id', v_offer_id);
END;
$$;

-- ============================================================
-- 6. grant_vendor_access: الموافقة على مورد (للأدمن فقط)
-- ============================================================
CREATE OR REPLACE FUNCTION grant_vendor_access(
    p_vendor_id UUID,
    p_approved BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
    END IF;

    UPDATE vendors
    SET is_approved = p_approved,
        approved_by = auth.uid(),
        approved_at = NOW()
    WHERE id = p_vendor_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- ============================================================
-- منح صلاحية التنفيذ للمستخدمين المسجلين
-- ============================================================
GRANT EXECUTE ON FUNCTION confirm_order_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_order_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION add_product_with_stock TO authenticated;
GRANT EXECUTE ON FUNCTION restock_product_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION create_offer_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION grant_vendor_access TO authenticated;
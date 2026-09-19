-- ============================================================
-- WAFFART INITIAL SCHEMA
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. PROFILES (يمتد من auth.users)
-- ============================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('customer', 'vendor', 'admin')) DEFAULT 'customer',
    business_name TEXT,
    address TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_phone ON public.profiles(phone);
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- ============================================================
-- 2. VENDORS
-- ============================================================
CREATE TABLE public.vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    store_name TEXT NOT NULL,
    store_description TEXT,
    logo_url TEXT,
    commission_rate NUMERIC(5,2) DEFAULT 0.00,
    minimum_order_value NUMERIC(12,2) DEFAULT 0.00,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES public.profiles(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vendors_approved ON public.vendors(is_approved);

-- ============================================================
-- 3. CATEGORIES
-- ============================================================
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar TEXT NOT NULL,
    name_en TEXT,
    icon_url TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. PRODUCTS
-- ============================================================
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id),
    name TEXT NOT NULL,
    description TEXT,
    image_urls TEXT[] DEFAULT '{}',
    sale_type TEXT NOT NULL CHECK (sale_type IN ('wholesale', 'unit', 'both')),
    base_price NUMERIC(12,2) NOT NULL CHECK (base_price >= 0),
    unit_label TEXT DEFAULT 'كرتونة',
    stock_quantity INT NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT positive_stock CHECK (stock_quantity >= 0)
);

CREATE INDEX idx_products_vendor ON public.products(vendor_id);
CREATE INDEX idx_products_category ON public.products(category_id);
CREATE INDEX idx_products_active ON public.products(is_active) WHERE is_active = TRUE;

-- ============================================================
-- 5. PRODUCT TIERS (Tiered Pricing)
-- ============================================================
CREATE TABLE public.product_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    min_quantity INT NOT NULL CHECK (min_quantity > 0),
    max_quantity INT,
    price_per_unit NUMERIC(12,2) NOT NULL CHECK (price_per_unit >= 0),
    UNIQUE(product_id, min_quantity),
    CHECK (max_quantity IS NULL OR max_quantity >= min_quantity)
);

-- ============================================================
-- 6. OFFERS (الميزة الأساسية)
-- ============================================================
CREATE TABLE public.offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    offer_price NUMERIC(12,2) NOT NULL CHECK (offer_price >= 0),
    original_price NUMERIC(12,2) NOT NULL CHECK (original_price >= 0),
    total_quantity INT NOT NULL CHECK (total_quantity > 0),
    sold_quantity INT NOT NULL DEFAULT 0,
    remaining_quantity INT GENERATED ALWAYS AS (total_quantity - sold_quantity) STORED,
    sale_type TEXT NOT NULL CHECK (sale_type IN ('wholesale', 'unit', 'both')),
    start_at TIMESTAMPTZ DEFAULT NOW(),
    end_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_offer_quantities CHECK (sold_quantity >= 0 AND sold_quantity <= total_quantity),
    CONSTRAINT valid_prices CHECK (offer_price <= original_price)
);

CREATE INDEX idx_offers_active ON public.offers(is_active, end_at) WHERE is_active = TRUE;
CREATE INDEX idx_offers_vendor ON public.offers(vendor_id);
CREATE INDEX idx_offers_product ON public.offers(product_id);

-- ============================================================
-- 7. CART ITEMS
-- ============================================================
CREATE TABLE public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    offer_id UUID REFERENCES public.offers(id) ON DELETE SET NULL,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, product_id, offer_id)
);

CREATE INDEX idx_cart_customer ON public.cart_items(customer_id);

-- ============================================================
-- 8. ORDERS
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS order_seq START 1;

CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id),
    order_number TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_method TEXT DEFAULT 'cod',
    delivery_address TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_customer ON public.orders(customer_id);
CREATE INDEX idx_orders_status ON public.orders(status);

-- ============================================================
-- 9. SUB_ORDERS (طلب لكل مورد)
-- ============================================================
CREATE TABLE public.sub_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id),
    vendor_order_number TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'rejected', 'processing', 'shipped', 'delivered', 'cancelled')),
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, vendor_id)
);

CREATE INDEX idx_sub_orders_order ON public.sub_orders(order_id);
CREATE INDEX idx_sub_orders_vendor ON public.sub_orders(vendor_id);

-- ============================================================
-- 10. SUB_ORDER_ITEMS
-- ============================================================
CREATE TABLE public.sub_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_order_id UUID NOT NULL REFERENCES public.sub_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    offer_id UUID REFERENCES public.offers(id),
    product_name TEXT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL,
    total_price NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

CREATE INDEX idx_sub_order_items_sub ON public.sub_order_items(sub_order_id);

-- ============================================================
-- 11. INVENTORY MOVEMENTS (Audit Trail)
-- ============================================================
CREATE TABLE public.inventory_movements (
    id BIGSERIAL PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES public.products(id),
    offer_id UUID REFERENCES public.offers(id),
    movement_type TEXT NOT NULL
        CHECK (movement_type IN ('sale', 'restock', 'adjustment', 'return', 'offer_allocation')),
    quantity_change INT NOT NULL,
    reference_id UUID,
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inventory_movements_product ON public.inventory_movements(product_id, created_at DESC);

-- ============================================================
-- 12. TRIGGER: تحديث updated_at تلقائياً
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_profiles
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_products
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_orders
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_sub_orders
    BEFORE UPDATE ON public.sub_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 13. TRIGGER: إنشاء profile تلقائياً بعد تسجيل مستخدم جديد
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, phone, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'مستخدم جديد'),
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 14. دالة تأكيد الطلب الذرية (Atomic Order Confirmation)
-- ============================================================
CREATE OR REPLACE FUNCTION public.confirm_order_atomic(
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
BEGIN
    -- 1. إنشاء الطلب الرئيسي
    v_order_number := 'WF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                      LPAD(NEXTVAL('order_seq')::TEXT, 5, '0');

    INSERT INTO public.orders (customer_id, order_number, delivery_address, notes, status)
    VALUES (p_customer_id, v_order_number, p_delivery_address, p_notes, 'pending')
    RETURNING id INTO v_order_id;

    -- 2. المرور على كل عنصر في السلة
    FOR v_item IN
        SELECT * FROM jsonb_to_recordset(p_cart_items)
        AS x(product_id UUID, offer_id UUID, quantity INT, unit_price NUMERIC(12,2))
    LOOP
        -- 2.1 قفل صف المنتج
        SELECT vendor_id, stock_quantity
        INTO v_vendor_id, v_current_stock
        FROM public.products
        WHERE id = v_item.product_id
        FOR UPDATE;

        IF v_current_stock < v_item.quantity THEN
            RAISE EXCEPTION 'الكمية غير كافية للمنتج: %', v_item.product_id;
        END IF;

        -- 2.2 لو المنتج من عرض
        IF v_item.offer_id IS NOT NULL THEN
            SELECT remaining_quantity INTO v_current_offer_remaining
            FROM public.offers WHERE id = v_item.offer_id FOR UPDATE;

            IF v_current_offer_remaining < v_item.quantity THEN
                RAISE EXCEPTION 'كمية العرض غير كافية للعرض: %', v_item.offer_id;
            END IF;

            UPDATE public.offers
            SET sold_quantity = sold_quantity + v_item.quantity
            WHERE id = v_item.offer_id;

            INSERT INTO public.inventory_movements
                (product_id, offer_id, movement_type, quantity_change, reference_id)
            VALUES
                (v_item.product_id, v_item.offer_id, 'sale', -v_item.quantity, v_order_id);
        END IF;

        -- 2.3 خصم المخزون
        UPDATE public.products
        SET stock_quantity = stock_quantity - v_item.quantity,
            updated_at = NOW()
        WHERE id = v_item.product_id;

        INSERT INTO public.inventory_movements
            (product_id, movement_type, quantity_change, reference_id)
        VALUES
            (v_item.product_id, 'sale', -v_item.quantity, v_order_id);

        -- 2.4 إنشاء/تحديث الطلب الفرعي
        INSERT INTO public.sub_orders (order_id, vendor_id, vendor_order_number, subtotal)
        VALUES (v_order_id, v_vendor_id, v_order_number || '-V' || v_vendor_id,
                v_item.quantity * v_item.unit_price)
        ON CONFLICT (order_id, vendor_id)
        DO UPDATE SET subtotal = public.sub_orders.subtotal + (v_item.quantity * v_item.unit_price)
        RETURNING id INTO v_sub_order_id;

        -- 2.5 إضافة عنصر الطلب الفرعي
        INSERT INTO public.sub_order_items
            (sub_order_id, product_id, offer_id, product_name, quantity, unit_price)
        SELECT v_sub_order_id, v_item.product_id, v_item.offer_id, p.name,
               v_item.quantity, v_item.unit_price
        FROM public.products p WHERE p.id = v_item.product_id;

        v_total := v_total + (v_item.quantity * v_item.unit_price);
    END LOOP;

    -- 3. تحديث الإجمالي
    UPDATE public.orders SET total_amount = v_total WHERE id = v_order_id;

    -- 4. حذف السلة
    DELETE FROM public.cart_items WHERE customer_id = p_customer_id;

    -- 5. النتيجة
    v_result := jsonb_build_object(
        'order_id', v_order_id,
        'order_number', v_order_number,
        'total_amount', v_total,
        'status', 'pending'
    );

    RETURN v_result;
END;
$$;
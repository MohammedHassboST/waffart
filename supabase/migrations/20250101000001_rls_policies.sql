-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================

-- تفعيل RLS على كل الجداول
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sub_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sub_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES
-- ============================================================
CREATE POLICY "Users can view their own profile"
ON public.profiles FOR SELECT
USING (id = auth.uid());

CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (id = auth.uid());

-- ============================================================
-- VENDORS
-- ============================================================
CREATE POLICY "Anyone can view approved vendors"
ON public.vendors FOR SELECT
USING (is_approved = TRUE OR profile_id = auth.uid());

CREATE POLICY "Vendors can update their own store"
ON public.vendors FOR UPDATE
USING (profile_id = auth.uid());

-- ============================================================
-- CATEGORIES
-- ============================================================
CREATE POLICY "Anyone can view active categories"
ON public.categories FOR SELECT
USING (is_active = TRUE);

CREATE POLICY "Admins can manage categories"
ON public.categories FOR ALL
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- PRODUCTS
-- ============================================================
CREATE POLICY "Anyone can view active products"
ON public.products FOR SELECT
USING (is_active = TRUE);

CREATE POLICY "Vendors can insert their own products"
ON public.products FOR INSERT
WITH CHECK (vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid()));

CREATE POLICY "Vendors can update their own products"
ON public.products FOR UPDATE
USING (vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid()));

CREATE POLICY "Vendors can delete their own products"
ON public.products FOR DELETE
USING (vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid()));

-- ============================================================
-- OFFERS
-- ============================================================
CREATE POLICY "Anyone can view active offers"
ON public.offers FOR SELECT
USING (is_active = TRUE);

CREATE POLICY "Vendors can manage their own offers"
ON public.offers FOR ALL
USING (vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid()));

-- ============================================================
-- CART ITEMS
-- ============================================================
CREATE POLICY "Customers manage their own cart"
ON public.cart_items FOR ALL
USING (customer_id = auth.uid())
WITH CHECK (customer_id = auth.uid());

-- ============================================================
-- ORDERS
-- ============================================================
CREATE POLICY "Customers view their own orders"
ON public.orders FOR SELECT
USING (customer_id = auth.uid());

CREATE POLICY "Admins view all orders"
ON public.orders FOR SELECT
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- SUB_ORDERS
-- ============================================================
CREATE POLICY "Vendors view their own sub_orders"
ON public.sub_orders FOR SELECT
USING (vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid()));

CREATE POLICY "Vendors update their own sub_orders"
ON public.sub_orders FOR UPDATE
USING (vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid()));

CREATE POLICY "Customers view sub_orders of their orders"
ON public.sub_orders FOR SELECT
USING (order_id IN (SELECT id FROM public.orders WHERE customer_id = auth.uid()));

CREATE POLICY "Admins view all sub_orders"
ON public.sub_orders FOR SELECT
USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- SUB_ORDER_ITEMS
-- ============================================================
CREATE POLICY "View items of accessible sub_orders"
ON public.sub_order_items FOR SELECT
USING (sub_order_id IN (
    SELECT id FROM public.sub_orders WHERE
        vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid())
        OR order_id IN (SELECT id FROM public.orders WHERE customer_id = auth.uid())
));

-- ============================================================
-- INVENTORY MOVEMENTS
-- ============================================================
CREATE POLICY "Vendors view their own inventory movements"
ON public.inventory_movements FOR SELECT
USING (product_id IN (
    SELECT id FROM public.products WHERE
        vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid())
));
-- جدول معاملات الدفع
CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES profiles(id),
    gateway TEXT NOT NULL CHECK (gateway IN ('paymob', 'stripe', 'cod', 'wallet')),
    gateway_transaction_id TEXT UNIQUE,
    gateway_order_id TEXT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'EGP',
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'processing', 'succeeded', 'failed', 'refunded', 'cancelled')),
    failure_reason TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payment_transactions_order ON payment_transactions(order_id);
CREATE INDEX idx_payment_transactions_customer ON payment_transactions(customer_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_gateway ON payment_transactions(gateway_transaction_id);

-- جدول استرداد المبالغ
CREATE TABLE payment_refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES payment_transactions(id),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'succeeded', 'failed')),
    gateway_refund_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- إضافة طرق دفع للطلبات
ALTER TABLE orders ADD COLUMN IF NOT EXISTS
    payment_status TEXT DEFAULT 'unpaid'
    CHECK (payment_status IN ('unpaid', 'paid', 'partial', 'refunded'));

ALTER TABLE orders ADD COLUMN IF NOT EXISTS
    payment_transaction_id UUID REFERENCES payment_transactions(id);

-- RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_refunds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers see their own transactions"
ON payment_transactions FOR SELECT
USING (customer_id = auth.uid());

CREATE POLICY "Admins see all transactions"
ON payment_transactions FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins manage refunds"
ON payment_refunds FOR ALL
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- دالة لتأكيد الدفع
CREATE OR REPLACE FUNCTION confirm_payment(
    p_transaction_id UUID,
    p_gateway_transaction_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
BEGIN
    UPDATE payment_transactions
    SET status = 'succeeded',
        gateway_transaction_id = p_gateway_transaction_id,
        updated_at = NOW()
    WHERE id = p_transaction_id
    RETURNING order_id INTO v_order_id;

    IF v_order_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND');
    END IF;

    UPDATE orders
    SET payment_status = 'paid',
        payment_transaction_id = p_transaction_id,
        status = CASE WHEN status = 'pending' THEN 'confirmed' ELSE status END
    WHERE id = v_order_id;

    RETURN jsonb_build_object('success', true, 'order_id', v_order_id);
END;
$$;
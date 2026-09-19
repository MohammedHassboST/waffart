-- جدول تكاملات الموردين
CREATE TABLE erp_integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('odoo', 'sap', 'zoho', 'custom_webhook', 'csv')),
    display_name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,

    -- Webhook URL للاستقبال
    webhook_url TEXT,
    webhook_secret TEXT,

    -- API credentials (encrypted)
    api_url TEXT,
    api_key_encrypted TEXT,
    api_secret_encrypted TEXT,

    -- Sync settings
    sync_interval_minutes INT DEFAULT 30,
    last_sync_at TIMESTAMPTZ,
    last_sync_status TEXT CHECK (last_sync_status IN ('success', 'failed', 'partial')),
    last_sync_error TEXT,

    -- Field mapping (كيفية ربط حقول المورد بحقولنا)
    field_mapping JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(vendor_id, provider)
);

CREATE INDEX idx_erp_integrations_vendor ON erp_integrations(vendor_id);

-- سجل مزامنة
CREATE TABLE erp_sync_logs (
    id BIGSERIAL PRIMARY KEY,
    integration_id UUID NOT NULL REFERENCES erp_integrations(id) ON DELETE CASCADE,
    sync_type TEXT NOT NULL CHECK (sync_type IN ('full', 'incremental', 'manual')),
    direction TEXT NOT NULL CHECK (direction IN ('pull', 'push')),

    records_processed INT DEFAULT 0,
    records_succeeded INT DEFAULT 0,
    records_failed INT DEFAULT 0,

    status TEXT NOT NULL CHECK (status IN ('running', 'completed', 'failed')),
    error_details JSONB,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_erp_sync_logs_integration ON erp_sync_logs(integration_id, started_at DESC);

-- جدول ربط SKUs
CREATE TABLE erp_sku_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    integration_id UUID NOT NULL REFERENCES erp_integrations(id) ON DELETE CASCADE,
    local_product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    external_sku TEXT NOT NULL,
    external_variant_id TEXT,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(integration_id, external_sku)
);

-- RLS
ALTER TABLE erp_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_sku_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors manage their own integrations"
ON erp_integrations FOR ALL
USING (vendor_id IN (SELECT id FROM vendors WHERE profile_id = auth.uid()));

CREATE POLICY "Vendors view their own sync logs"
ON erp_sync_logs FOR SELECT
USING (integration_id IN (
    SELECT id FROM erp_integrations WHERE
        vendor_id IN (SELECT id FROM vendors WHERE profile_id = auth.uid())
));

CREATE POLICY "Vendors manage their own sku mappings"
ON erp_sku_mappings FOR ALL
USING (integration_id IN (
    SELECT id FROM erp_integrations WHERE
        vendor_id IN (SELECT id FROM vendors WHERE profile_id = auth.uid())
));

-- دالة استقبال تحديثات المخزون من Webhook
CREATE OR REPLACE FUNCTION update_stock_from_erp(
    p_external_sku TEXT,
    p_new_quantity INT,
    p_integration_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_product_id UUID;
    v_old_quantity INT;
BEGIN
    SELECT local_product_id INTO v_product_id
    FROM erp_sku_mappings
    WHERE integration_id = p_integration_id AND external_sku = p_external_sku;

    IF v_product_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'SKU_NOT_MAPPED');
    END IF;

    SELECT stock_quantity INTO v_old_quantity
    FROM products WHERE id = v_product_id FOR UPDATE;

    UPDATE products
    SET stock_quantity = p_new_quantity,
        updated_at = NOW()
    WHERE id = v_product_id;

    INSERT INTO inventory_movements
        (product_id, movement_type, quantity_change, reference_id, notes)
    VALUES
        (v_product_id, 'adjustment', p_new_quantity - v_old_quantity, p_integration_id,
         'ERP sync: ' || p_external_sku);

    RETURN jsonb_build_object(
        'success', true,
        'product_id', v_product_id,
        'old_quantity', v_old_quantity,
        'new_quantity', p_new_quantity
    );
END;
$$;
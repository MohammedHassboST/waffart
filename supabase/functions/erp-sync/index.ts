import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

interface SyncPayload {
  integration_id: string;
  sync_type: 'full' | 'incremental';
}

serve(async (req) => {
  try {
    const { integration_id, sync_type } = (await req.json()) as SyncPayload;

    // 1. جلب بيانات التكامل
    const { data: integration, error: intErr } = await supabase
      .from('erp_integrations')
      .select('*')
      .eq('id', integration_id)
      .single();

    if (intErr || !integration) throw new Error('Integration not found');
    if (!integration.is_active) throw new Error('Integration inactive');

    // 2. بدء سجل مزامنة
    const { data: log } = await supabase
      .from('erp_sync_logs')
      .insert({
        integration_id,
        sync_type,
        direction: 'pull',
        status: 'running',
      })
      .select()
      .single();

    let processed = 0;
    let succeeded = 0;
    let failed = 0;

    try {
      // 3. جلب البيانات من نظام ERP
      const products = await fetchFromErp(
        integration.provider,
        integration.api_url,
        integration.api_key_encrypted,
      );

      processed = products.length;

      // 4. تحديث المخزون
      for (const product of products) {
        try {
          await supabase.rpc('update_stock_from_erp', {
            p_external_sku: product.sku,
            p_new_quantity: product.quantity,
            p_integration_id: integration_id,
          });
          succeeded++;
        } catch (e) {
          failed++;
          console.error(`Failed for SKU ${product.sku}:`, e);
        }
      }

      // 5. تحديث الحالة النهائية
      await supabase
        .from('erp_sync_logs')
        .update({
          status: failed > 0 && succeeded === 0 ? 'failed' : 'completed',
          records_processed: processed,
          records_succeeded: succeeded,
          records_failed: failed,
          completed_at: new Date().toISOString(),
        })
        .eq('id', log.id);

      await supabase
        .from('erp_integrations')
        .update({
          last_sync_at: new Date().toISOString(),
          last_sync_status: failed === 0 ? 'success' : 'partial',
        })
        .eq('id', integration_id);

      return new Response(
        JSON.stringify({ success: true, processed, succeeded, failed }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    } catch (e) {
      await supabase
        .from('erp_sync_logs')
        .update({
          status: 'failed',
          error_details: { message: e.message },
          completed_at: new Date().toISOString(),
        })
        .eq('id', log.id);

      throw e;
    }
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});

async function fetchFromErp(
  provider: string,
  apiUrl: string,
  apiKey: string,
): Promise<Array<{ sku: string; quantity: number }>> {
  switch (provider) {
    case 'odoo':
      return fetchFromOdoo(apiUrl, apiKey);
    case 'zoho':
      return fetchFromZoho(apiUrl, apiKey);
    case 'custom_webhook':
      const res = await fetch(apiUrl, {
        headers: { Authorization: `Bearer ${apiKey}` },
      });
      const json = await res.json();
      return json.products || [];
    default:
      return [];
  }
}

async function fetchFromOdoo(apiUrl: string, apiKey: string) {
  // Odoo JSON-RPC integration
  const res = await fetch(`${apiUrl}/web/session/authenticate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      params: { db: 'main', login: 'api', password: apiKey },
    }),
  });
  const session = await res.json();
  // ثم جلب المنتجات
  const productsRes = await fetch(`${apiUrl}/web/dataset/call_kw`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Cookie: session.result.session_id,
    },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'call',
      params: {
        model: 'product.product',
        method: 'search_read',
        args: [[['type', '=', 'product']]],
        kwargs: { fields: ['default_code', 'qty_available'] },
      },
    }),
  });
  const data = await productsRes.json();
  return (data.result || []).map((p: any) => ({
    sku: p.default_code,
    quantity: Math.floor(p.qty_available),
  }));
}

async function fetchFromZoho(apiUrl: string, apiKey: string) {
  const res = await fetch(`${apiUrl}/items`, {
    headers: { Authorization: `Zoho-oauthtoken ${apiKey}` },
  });
  const json = await res.json();
  return (json.items || []).map((p: any) => ({
    sku: p.sku,
    quantity: p.stock_on_hand || 0,
  }));
}
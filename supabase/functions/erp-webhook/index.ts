import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async (req) => {
  try {
    const url = new URL(req.url);
    const integrationId = url.searchParams.get('integration_id');
    const secret = url.searchParams.get('secret');

    if (!integrationId || !secret) {
      return new Response('Missing params', { status: 400 });
    }

    // التحقق من الـ secret
    const { data: integration } = await supabase
      .from('erp_integrations')
      .select('webhook_secret')
      .eq('id', integrationId)
      .single();

    if (integration?.webhook_secret !== secret) {
      return new Response('Unauthorized', { status: 401 });
    }

    const payload = await req.json();

    // المتوقع: { items: [{ sku, quantity }, ...] }
    const items = payload.items || [];
    let updated = 0;

    for (const item of items) {
      const { error } = await supabase.rpc('update_stock_from_erp', {
        p_external_sku: item.sku,
        p_new_quantity: item.quantity,
        p_integration_id: integrationId,
      });
      if (!error) updated++;
    }

    return new Response(
      JSON.stringify({ success: true, updated, total: items.length }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500 },
    );
  }
});
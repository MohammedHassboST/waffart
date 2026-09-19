import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'No auth' }), { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: 'Invalid token' }), { status: 401 });
  }

  // فحص RLS
  const { data: rlsCheck } = await supabase
    .from('audit_rls_status')
    .select()
    .eq('rls_enabled', false);

  const { data: grants } = await supabase
    .from('audit_grants')
    .select()
    .eq('grantee', 'anon');

  return new Response(
    JSON.stringify({
      user_id: user.id,
      tables_without_rls: rlsCheck?.length || 0,
      anon_grants: grants?.length || 0,
      status: (rlsCheck?.length || 0) === 0 ? 'SECURE' : 'VULNERABLE',
    }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
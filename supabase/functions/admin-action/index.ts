// supabase/functions/admin-action/index.ts
const adminClient = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // ← آمن هنا فقط
);

// التحقق من أن المستدعي أدمن
const { data: profile } = await adminClient
  .from('profiles')
  .select('role')
  .eq('id', user.id)
  .single();

if (profile?.role !== 'admin') {
  return new Response('Forbidden', { status: 403 });
}

// الآن نفذ العملية الإدارية
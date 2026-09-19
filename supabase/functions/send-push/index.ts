import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  try {
    const { user_ids, title, body, type, reference_id } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. جلب رموز الأجهزة النشطة
    const { data: tokens, error } = await supabase
      .from('device_tokens')
      .select('fcm_token, user_id, platform')
      .in('user_id', user_ids)
      .eq('is_active', true);

    if (error) throw error;
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    // 2. إرسال الإشعارات عبر FCM
    const results = await Promise.all(
      tokens.map(async (t) => {
        const res = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${FCM_SERVER_KEY}`,
          },
          body: JSON.stringify({
            to: t.fcm_token,
            notification: { title, body, sound: 'default' },
            data: { type, reference_id: reference_id || '' },
            priority: 'high',
          }),
        });
        return res.json();
      })
    );

    // 3. حفظ الإشعارات في قاعدة البيانات
    await supabase.from('notifications').insert(
      user_ids.map((uid: string) => ({
        user_id: uid,
        title,
        body,
        type,
        reference_id,
      }))
    );

    return new Response(JSON.stringify({ sent: results.length }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});
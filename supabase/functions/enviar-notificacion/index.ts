import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const FCM_SERVICE_ACCOUNT = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')!);
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);


async function obtenerTokenAccesoGoogle(): Promise<string> {
  const base64url = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const ahora = Math.floor(Date.now() / 1000);
  const unsigned = `${base64url({ alg: 'RS256', typ: 'JWT' })}.${base64url({
    iss: FCM_SERVICE_ACCOUNT.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: ahora,
    exp: ahora + 3600,
  })}`;

  const pemBody = FCM_SERVICE_ACCOUNT.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8', keyBytes, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  );
  const firma = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cryptoKey, new TextEncoder().encode(unsigned));
  const firmaB64 = btoa(String.fromCharCode(...new Uint8Array(firma)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${unsigned}.${firmaB64}`,
  });
  const data = await res.json();
  if (!data.access_token) throw new Error('No se pudo autenticar con Google: ' + JSON.stringify(data));
  return data.access_token;
}

async function enviarPush(token: string, titulo: string, mensaje: string) {
  const accessToken = await obtenerTokenAccesoGoogle();
  await fetch(`https://fcm.googleapis.com/v1/projects/${FCM_SERVICE_ACCOUNT.project_id}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: { token, notification: { title: titulo, body: mensaje } } }),
  });
}

async function enviarCorreo(destinatario: string, titulo: string, mensaje: string) {
  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: 'Comunidad BGA <onboarding@resend.dev>',
      to: destinatario,
      subject: titulo,
      html: `<p>${mensaje}</p>`,
    }),
  });
}

Deno.serve(async (req) => {
  const { record: notificacion } = await req.json();

  const { data: usuario } = await supabase
    .from('usuarios')
    .select('correo, notificaciones_externas_activas')
    .eq('id', notificacion.usuario_id)
    .single();

  if (!usuario || !usuario.notificaciones_externas_activas) {
    return new Response('Canales externos desactivados', { status: 200 });
  }

  await enviarCorreo(usuario.correo, notificacion.titulo, notificacion.mensaje);

  const { data: dispositivos } = await supabase
    .from('dispositivos_push')
    .select('token')
    .eq('usuario_id', notificacion.usuario_id);

  for (const d of dispositivos ?? []) {
    try {
      await enviarPush(d.token, notificacion.titulo, notificacion.mensaje);
    } catch (_e) {
      // Un token vencido no debe frenar el resto del envío.
    }
  }

  return new Response('OK', { status: 200 });
});
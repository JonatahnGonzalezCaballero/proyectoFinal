import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

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
    return new Response('Notificaciones por correo desactivadas', { status: 200 });
  }

  await enviarCorreo(usuario.correo, notificacion.titulo, notificacion.mensaje);
  return new Response('OK', { status: 200 });
});
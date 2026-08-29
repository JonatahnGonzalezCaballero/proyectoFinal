create extension if not exists pgcrypto;

-- 1. ROLES

create table public.roles (
  id     uuid primary key default gen_random_uuid(),
  nombre text not null unique check (nombre in ('ciudadano','administrador'))
);

insert into public.roles (nombre) values ('ciudadano'), ('administrador');


-- 2. USUARIOS (perfil público vinculado 1:1 a auth.users)

create table public.usuarios (
  id               uuid primary key references auth.users(id) on delete cascade,
  rol_id           uuid not null references public.roles(id),
  nombre_completo  text not null,
  correo           text not null unique,
  telefono         text,
  avatar_url       text,
  activo           boolean not null default true,
  fecha_registro   timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_rol_ciudadano uuid;
begin
  select id into v_rol_ciudadano from public.roles where nombre = 'ciudadano';

  insert into public.usuarios (id, rol_id, nombre_completo, correo)
  values (
    new.id,
    v_rol_ciudadano,
    coalesce(new.raw_user_meta_data ->> 'nombre_completo', ''),
    new.email
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.prevenir_escalada_privilegios()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.rol_id <> old.rol_id and not public.es_admin() then
    raise exception 'No tiene permisos para cambiar su rol';
  end if;
  if new.activo <> old.activo and not public.es_admin() then
    raise exception 'No tiene permisos para cambiar el estado de la cuenta';
  end if;
  return new;
end;
$$;

-- 3. CATEGORIAS

create table public.categorias (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null unique,
  descripcion text,
  activo      boolean not null default true
);

-- 4. PROPUESTAS

create table public.propuestas (
  id                  uuid primary key default gen_random_uuid(),
  usuario_id          uuid not null references public.usuarios(id),
  categoria_id        uuid not null references public.categorias(id),
  titulo              text not null,
  descripcion         text not null,
  ubicacion           text,
  estado              text not null default 'pendiente'
                        check (estado in ('pendiente','en_revision','aprobada','rechazada','convertida_proyecto')),
  observaciones       text,
  revisado_por        uuid references public.usuarios(id),
  fecha_revision      timestamptz,
  fecha_creacion      timestamptz not null default now(),
  fecha_actualizacion timestamptz not null default now()
);

create or replace function public.set_fecha_actualizacion()
returns trigger language plpgsql as $$
begin
  new.fecha_actualizacion = now();
  return new;
end;
$$;

create trigger trg_propuestas_actualizacion
  before update on public.propuestas
  for each row execute function public.set_fecha_actualizacion();

-- 5. PROPUESTA_ARCHIVOS

create table public.propuesta_archivos (
  id            uuid primary key default gen_random_uuid(),
  propuesta_id  uuid not null references public.propuestas(id) on delete cascade,
  url           text not null,
  tipo          text,
  fecha_subida  timestamptz not null default now()
);

-- 6. VOTACIONES

create table public.votaciones (
  id             uuid primary key default gen_random_uuid(),
  titulo         text not null,
  descripcion    text,
  fecha_inicio   timestamptz not null,
  fecha_fin      timestamptz not null,
  estado         text not null default 'programada'
                   check (estado in ('programada','activa','finalizada','cancelada')),
  creado_por     uuid not null references public.usuarios(id),
  fecha_creacion timestamptz not null default now(),
  check (fecha_fin > fecha_inicio)
);

-- 7. VOTACION_OPCIONES

create table public.votacion_opciones (
  id           uuid primary key default gen_random_uuid(),
  votacion_id  uuid not null references public.votaciones(id) on delete cascade,
  propuesta_id uuid not null references public.propuestas(id),
  orden        int not null default 0,
  unique (votacion_id, propuesta_id)
);

-- 8. VOTO_REGISTROS

create table public.voto_registros (
  id           uuid primary key default gen_random_uuid(),
  usuario_id   uuid not null references public.usuarios(id),
  votacion_id  uuid not null references public.votaciones(id),
  fecha_voto   timestamptz not null default now(),
  unique (usuario_id, votacion_id)
);

-- 9. VOTOS  (elección anónima - SIN usuario_id)

create table public.votos (
  id                  uuid primary key default gen_random_uuid(),
  votacion_id         uuid not null references public.votaciones(id),
  votacion_opcion_id  uuid not null references public.votacion_opciones(id),
  fecha               timestamptz not null default now()
);

create or replace function public.emitir_voto(p_votacion_id uuid, p_opcion_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_estado  text;
  v_inicio  timestamptz;
  v_fin     timestamptz;
  v_valida  boolean;
begin
  if auth.uid() is null then
    raise exception 'Debe iniciar sesión para votar';
  end if;

  select estado, fecha_inicio, fecha_fin
    into v_estado, v_inicio, v_fin
    from public.votaciones
   where id = p_votacion_id
   for update;

  if not found then
    raise exception 'La votación no existe';
  end if;

  if v_estado <> 'activa' or now() < v_inicio or now() > v_fin then
    raise exception 'La votación no está activa en este momento';
  end if;

  select exists (
    select 1 from public.votacion_opciones
     where id = p_opcion_id and votacion_id = p_votacion_id
  ) into v_valida;

  if not v_valida then
    raise exception 'La opción no pertenece a esta votación';
  end if;

  insert into public.voto_registros (usuario_id, votacion_id)
  values (auth.uid(), p_votacion_id);

  insert into public.votos (votacion_id, votacion_opcion_id)
  values (p_votacion_id, p_opcion_id);
end;
$$;

-- Vista de resultados
create view public.resultados_votacion as
select
  vo.votacion_id,
  vo.id as votacion_opcion_id,
  p.titulo as propuesta_titulo,
  count(v.id) as total_votos
from public.votacion_opciones vo
left join public.votos v on v.votacion_opcion_id = vo.id
join public.propuestas p on p.id = vo.propuesta_id
group by vo.votacion_id, vo.id, p.titulo;

-- 10. PROYECTOS

create table public.proyectos (
  id                  uuid primary key default gen_random_uuid(),
  propuesta_id        uuid unique references public.propuestas(id),
  responsable_id      uuid not null references public.usuarios(id),
  titulo              text not null,
  descripcion         text,
  estado              text not null default 'planeado'
                        check (estado in ('planeado','en_ejecucion','finalizado','suspendido')),
  porcentaje_avance   int not null default 0 check (porcentaje_avance between 0 and 100),
  fecha_inicio        date,
  fecha_fin_estimada  date,
  fecha_creacion      timestamptz not null default now(),
  check (fecha_fin_estimada is null or fecha_inicio is null or fecha_fin_estimada >= fecha_inicio)
);

-- 11. PROYECTO_ACTUALIZACIONES

create table public.proyecto_actualizaciones (
  id                 uuid primary key default gen_random_uuid(),
  proyecto_id        uuid not null references public.proyectos(id) on delete cascade,
  autor_id           uuid not null references public.usuarios(id),
  descripcion        text not null,
  porcentaje_avance  int check (porcentaje_avance between 0 and 100),
  fecha              timestamptz not null default now()
);

create or replace function public.actualizar_avance_proyecto()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.porcentaje_avance is not null then
    update public.proyectos
       set porcentaje_avance = new.porcentaje_avance,
           estado = case when new.porcentaje_avance = 100 then 'finalizado' else estado end
     where id = new.proyecto_id;
  end if;
  return new;
end;
$$;

create trigger trg_actualizar_avance
  after insert on public.proyecto_actualizaciones
  for each row execute function public.actualizar_avance_proyecto();

-- 12. PROYECTO_ARCHIVOS

create table public.proyecto_archivos (
  id                uuid primary key default gen_random_uuid(),
  actualizacion_id  uuid not null references public.proyecto_actualizaciones(id) on delete cascade,
  url               text not null,
  tipo              text,
  fecha_subida      timestamptz not null default now()
);

-- 13. NOTIFICACIONES

create table public.notificaciones (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references public.usuarios(id) on delete cascade,
  titulo      text not null,
  mensaje     text not null,
  tipo        text,
  leida       boolean not null default false,
  fecha       timestamptz not null default now()
);

-- 14. AUDITORIA

create table public.auditoria (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references public.usuarios(id),
  accion      text not null,
  entidad     text not null,
  entidad_id  uuid,
  detalle     jsonb,
  fecha       timestamptz not null default now()
);

-- 15. ÍNDICES

create index idx_propuestas_usuario        on public.propuestas(usuario_id);
create index idx_propuestas_categoria      on public.propuestas(categoria_id);
create index idx_propuestas_estado         on public.propuestas(estado);
create index idx_votos_opcion              on public.votos(votacion_opcion_id);
create index idx_voto_registros_votacion   on public.voto_registros(votacion_id);
create index idx_notificaciones_usuario    on public.notificaciones(usuario_id, leida);
create index idx_auditoria_fecha           on public.auditoria(fecha desc);
create index idx_proyectos_estado          on public.proyectos(estado);


-- 16. FUNCIÓN HELPER PARA RLS (evita recursión en políticas)

create or replace function public.es_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
      from public.usuarios u
      join public.roles r on r.id = u.rol_id
     where u.id = auth.uid() and r.nombre = 'administrador'
  );
$$;

create trigger trg_usuarios_prevenir_escalada
  before update on public.usuarios
  for each row execute function public.prevenir_escalada_privilegios();

-- 17. ROW LEVEL SECURITY

alter table public.roles                    enable row level security;
alter table public.usuarios                  enable row level security;
alter table public.categorias                enable row level security;
alter table public.propuestas                enable row level security;
alter table public.propuesta_archivos        enable row level security;
alter table public.votaciones                enable row level security;
alter table public.votacion_opciones         enable row level security;
alter table public.voto_registros            enable row level security;
alter table public.votos                     enable row level security;
alter table public.proyectos                 enable row level security;
alter table public.proyecto_actualizaciones  enable row level security;
alter table public.proyecto_archivos         enable row level security;
alter table public.notificaciones            enable row level security;
alter table public.auditoria                 enable row level security;

create policy roles_select on public.roles
  for select to authenticated using (true);

-- usuarios
create policy usuarios_select on public.usuarios
  for select to authenticated
  using (id = auth.uid() or public.es_admin());

create policy usuarios_update_propio on public.usuarios
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy usuarios_admin_todo on public.usuarios
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- categorias: lectura pública, gestión solo admin
create policy categorias_select on public.categorias
  for select to authenticated using (true);

create policy categorias_admin on public.categorias
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- propuestas
create policy propuestas_select on public.propuestas
  for select to authenticated
  using (usuario_id = auth.uid() or estado = 'aprobada' or public.es_admin());

create policy propuestas_insert on public.propuestas
  for insert to authenticated
  with check (usuario_id = auth.uid());

create policy propuestas_update_propia on public.propuestas
  for update to authenticated
  using (usuario_id = auth.uid() and estado = 'pendiente')
  with check (usuario_id = auth.uid() and estado = 'pendiente');

create policy propuestas_admin on public.propuestas
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- propuesta_archivos
create policy propuesta_archivos_select on public.propuesta_archivos
  for select to authenticated
  using (exists (
    select 1 from public.propuestas p
     where p.id = propuesta_id
       and (p.usuario_id = auth.uid() or p.estado = 'aprobada' or public.es_admin())
  ));

create policy propuesta_archivos_insert on public.propuesta_archivos
  for insert to authenticated
  with check (exists (
    select 1 from public.propuestas p
     where p.id = propuesta_id and p.usuario_id = auth.uid() and p.estado = 'pendiente'
  ));

create policy propuesta_archivos_admin on public.propuesta_archivos
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- votaciones: lectura pública, gestión solo admin
create policy votaciones_select on public.votaciones
  for select to authenticated using (true);

create policy votaciones_admin on public.votaciones
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- votacion_opciones
create policy votacion_opciones_select on public.votacion_opciones
  for select to authenticated using (true);

create policy votacion_opciones_admin on public.votacion_opciones
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- voto_registros: cada quien ve solo si YA votó (no ve la elección)
create policy voto_registros_select_propio on public.voto_registros
  for select to authenticated using (usuario_id = auth.uid());

create policy voto_registros_select_admin on public.voto_registros
  for select to authenticated using (public.es_admin());

-- votos: SIN políticas de select/insert/update/delete para 'authenticated'.
-- Acceso denegado por defecto. Único camino de escritura: emitir_voto().
-- Único camino de lectura: la vista resultados_votacion (ver abajo).

revoke insert, update, delete on public.votos          from authenticated;
revoke insert, update, delete on public.voto_registros  from authenticated;
grant execute on function public.emitir_voto(uuid, uuid) to authenticated;
grant select on public.resultados_votacion to authenticated;

-- proyectos: transparencia -> visibles para todo autenticado
create policy proyectos_select on public.proyectos
  for select to authenticated using (true);

create policy proyectos_admin on public.proyectos
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- proyecto_actualizaciones
create policy proyecto_actualizaciones_select on public.proyecto_actualizaciones
  for select to authenticated using (true);

create policy proyecto_actualizaciones_admin on public.proyecto_actualizaciones
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- proyecto_archivos
create policy proyecto_archivos_select on public.proyecto_archivos
  for select to authenticated using (true);

create policy proyecto_archivos_admin on public.proyecto_archivos
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- notificaciones: cada quien ve y marca como leídas solo las suyas
create policy notificaciones_select_propias on public.notificaciones
  for select to authenticated using (usuario_id = auth.uid());

create policy notificaciones_update_propias on public.notificaciones
  for update to authenticated
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

create policy notificaciones_admin on public.notificaciones
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- auditoria: solo el admin consulta; las inserciones se harán desde
-- funciones SECURITY DEFINER en fases posteriores (aprobar, crear votación, etc.)
create policy auditoria_select_admin on public.auditoria
  for select to authenticated using (public.es_admin());

-- 18. STORAGE — BUCKETS Y POLÍTICAS

insert into storage.buckets (id, name, public) values ('avatares',   'avatares',   true)  on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('propuestas', 'propuestas', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('evidencias', 'evidencias', false) on conflict (id) do nothing;

-- avatares: cada usuario sube/borra en su propia carpeta {user_id}/...
-- bucket público -> lectura sin restricción (útil para <img> directo)
create policy avatares_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

create policy avatares_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

-- propuestas: el dueño sube/borra en su carpeta; lectura para autenticados
create policy propuestas_files_select on storage.objects
  for select to authenticated using (bucket_id = 'propuestas');

create policy propuestas_files_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'propuestas' and (storage.foldername(name))[1] = auth.uid()::text);

create policy propuestas_files_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'propuestas' and ((storage.foldername(name))[1] = auth.uid()::text or public.es_admin()));

-- evidencias: solo el admin sube/borra; lectura para autenticados
create policy evidencias_select on storage.objects
  for select to authenticated using (bucket_id = 'evidencias');

create policy evidencias_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'evidencias' and public.es_admin());

create policy evidencias_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'evidencias' and public.es_admin());


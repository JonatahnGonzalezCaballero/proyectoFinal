create extension if not exists pgcrypto;

-- 1. ROLES
create table if not exists public.roles (
  id     uuid primary key default gen_random_uuid(),
  nombre text not null unique check (nombre in ('ciudadano','administrador'))
);

insert into public.roles (nombre) values ('ciudadano'), ('administrador')
on conflict (nombre) do nothing;

-- 2. USUARIOS
create table if not exists public.usuarios (
  id                              uuid primary key references auth.users(id) on delete cascade,
  rol_id                          uuid not null references public.roles(id),
  nombre_completo                 text not null,
  correo                          text not null unique,
  telefono                        text,
  avatar_url                      text,
  alias                           text check (alias is null or (length(alias) between 2 and 40)),
  activo                          boolean not null default true,
  notificaciones_externas_activas boolean not null default true,
  fecha_registro                  timestamptz not null default now()
);

-- 3. FUNCIONES HELPER
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

create or replace function public.usuario_activo()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select coalesce((select activo from public.usuarios where id = auth.uid()), false);
$$;

-- 4. SINCRONIZACIÓN AUTH - PERFIL
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5. ANTI-ESCALADA DE PRIVILEGIOS (usuarios)
create or replace function public.prevenir_escalada_privilegios()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if new.rol_id <> old.rol_id and not public.es_admin() then
    raise exception 'No tiene permisos para cambiar su rol';
  end if;
  if new.activo <> old.activo and not public.es_admin() then
    raise exception 'No tiene permisos para cambiar el estado de la cuenta';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_usuarios_prevenir_escalada on public.usuarios;
create trigger trg_usuarios_prevenir_escalada
  before update on public.usuarios
  for each row execute function public.prevenir_escalada_privilegios();

-- 6. CATEGORIAS
create table if not exists public.categorias (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null unique,
  descripcion text,
  activo      boolean not null default true
);

insert into public.categorias (nombre, descripcion) values
  ('Infraestructura vial', 'Vías, andenes, puentes peatonales, señalización'),
  ('Espacios públicos y parques', 'Parques, plazas, zonas verdes y de recreación'),
  ('Seguridad ciudadana', 'Iluminación, cámaras, frentes de seguridad'),
  ('Medio ambiente', 'Arborización, manejo de residuos, cuencas'),
  ('Cultura y educación', 'Bibliotecas, casas de cultura, actividades educativas'),
  ('Servicios públicos', 'Acueducto, alcantarillado, energía, gas')
on conflict (nombre) do nothing;

-- 7. PROPUESTAS
create table if not exists public.propuestas (
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

drop trigger if exists trg_propuestas_actualizacion on public.propuestas;
create trigger trg_propuestas_actualizacion
  before update on public.propuestas
  for each row execute function public.set_fecha_actualizacion();

-- 8. PROPUESTA_ARCHIVOS
create table if not exists public.propuesta_archivos (
  id            uuid primary key default gen_random_uuid(),
  propuesta_id  uuid not null references public.propuestas(id) on delete cascade,
  url           text not null,
  tipo          text,
  fecha_subida  timestamptz not null default now()
);

-- 9. VOTACIONES
create table if not exists public.votaciones (
  id             uuid primary key default gen_random_uuid(),
  titulo         text not null,
  descripcion    text,
  fecha_inicio   timestamptz not null,
  fecha_fin      timestamptz not null,
  estado         text not null default 'programada'
                   check (estado in ('programada','activa','finalizada','cancelada')),
  tipo           text not null default 'seleccion_multiple'
                   check (tipo in ('seleccion_multiple','si_no')),
  creado_por     uuid not null references public.usuarios(id),
  fecha_creacion timestamptz not null default now(),
  check (fecha_fin > fecha_inicio)
);

-- 10. VOTACION_OPCIONES
create table if not exists public.votacion_opciones (
  id           uuid primary key default gen_random_uuid(),
  votacion_id  uuid not null references public.votaciones(id) on delete cascade,
  propuesta_id uuid not null references public.propuestas(id),
  etiqueta     text not null default '',
  orden        int not null default 0,
  unique (votacion_id, propuesta_id, etiqueta)
);

-- 11. VOTO_REGISTROS
create table if not exists public.voto_registros (
  id           uuid primary key default gen_random_uuid(),
  usuario_id   uuid not null references public.usuarios(id),
  votacion_id  uuid not null references public.votaciones(id),
  fecha_voto   timestamptz not null default now(),
  unique (usuario_id, votacion_id)
);

-- 12. VOTOS (elección anónima — sin usuario_id)
create table if not exists public.votos (
  id                  uuid primary key default gen_random_uuid(),
  votacion_id         uuid not null references public.votaciones(id),
  votacion_opcion_id  uuid not null references public.votacion_opciones(id),
  fecha               timestamptz not null default now()
);

-- Único punto de entrada para votar
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

  if not public.usuario_activo() then
    raise exception 'Su cuenta está desactivada y no puede participar en votaciones';
  end if;

  select estado, fecha_inicio, fecha_fin into v_estado, v_inicio, v_fin
    from public.votaciones where id = p_votacion_id for update;

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

-- Vista de resultados agregados
create or replace view public.resultados_votacion as
select
  vo.votacion_id,
  vo.id as votacion_opcion_id,
  p.titulo as propuesta_titulo,
  count(v.id) as total_votos,
  vo.etiqueta,
  case when vo.etiqueta <> '' then vo.etiqueta else p.titulo end as opcion_titulo
from public.votacion_opciones vo
left join public.votos v on v.votacion_opcion_id = vo.id
join public.propuestas p on p.id = vo.propuesta_id
group by vo.votacion_id, vo.id, p.titulo, vo.etiqueta;

-- Función de creación de votaciones
create or replace function public.crear_votacion(
  p_titulo text,
  p_descripcion text,
  p_fecha_inicio timestamptz,
  p_fecha_fin timestamptz,
  p_tipo text,
  p_propuesta_ids uuid[]
)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_votacion_id uuid;
  v_propuesta_id uuid;
  v_orden int := 0;
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para crear votaciones';
  end if;

  if p_tipo not in ('seleccion_multiple','si_no') then
    raise exception 'Tipo de votación no válido';
  end if;

  if p_tipo = 'seleccion_multiple' and (array_length(p_propuesta_ids,1) is null or array_length(p_propuesta_ids,1) < 2) then
    raise exception 'Debe seleccionar al menos dos propuestas';
  end if;

  if p_tipo = 'si_no' and (array_length(p_propuesta_ids,1) is null or array_length(p_propuesta_ids,1) <> 1) then
    raise exception 'Una votación de Sí/No debe tener exactamente una propuesta';
  end if;

  insert into public.votaciones (titulo, descripcion, fecha_inicio, fecha_fin, tipo, creado_por)
  values (p_titulo, p_descripcion, p_fecha_inicio, p_fecha_fin, p_tipo, auth.uid())
  returning id into v_votacion_id;

  if p_tipo = 'si_no' then
    v_propuesta_id := p_propuesta_ids[1];
    insert into public.votacion_opciones (votacion_id, propuesta_id, etiqueta, orden)
    values (v_votacion_id, v_propuesta_id, 'Sí', 0);
    insert into public.votacion_opciones (votacion_id, propuesta_id, etiqueta, orden)
    values (v_votacion_id, v_propuesta_id, 'No', 1);
  else
    foreach v_propuesta_id in array p_propuesta_ids loop
      insert into public.votacion_opciones (votacion_id, propuesta_id, orden)
      values (v_votacion_id, v_propuesta_id, v_orden);
      v_orden := v_orden + 1;
    end loop;
  end if;

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'crear_votacion', 'votaciones', v_votacion_id,
          jsonb_build_object('titulo', p_titulo, 'tipo', p_tipo, 'propuestas', p_propuesta_ids));

  return v_votacion_id;
end;
$$;

create or replace function public.actualizar_estado_votacion(p_votacion_id uuid, p_nuevo_estado text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para modificar votaciones';
  end if;

  if p_nuevo_estado not in ('activa','finalizada','cancelada') then
    raise exception 'Estado no válido';
  end if;

  update public.votaciones set estado = p_nuevo_estado where id = p_votacion_id;

  if not found then
    raise exception 'La votación no existe';
  end if;

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'modificar_votacion', 'votaciones', p_votacion_id,
          jsonb_build_object('nuevo_estado', p_nuevo_estado));
end;
$$;

-- Transición automática de estado según fecha
create or replace function public.actualizar_votaciones_programadas()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.votaciones
  set estado = 'activa'
  where estado = 'programada'
    and now() >= fecha_inicio
    and now() < fecha_fin;

  update public.votaciones
  set estado = 'finalizada'
  where estado = 'activa'
    and now() >= fecha_fin;

  update public.votaciones
  set estado = 'finalizada'
  where estado = 'programada'
    and now() >= fecha_fin;
end;
$$;

-- 13. PROYECTOS
create table if not exists public.proyectos (
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

-- 14. PROYECTO_ACTUALIZACIONES
create table if not exists public.proyecto_actualizaciones (
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

drop trigger if exists trg_actualizar_avance on public.proyecto_actualizaciones;
create trigger trg_actualizar_avance
  after insert on public.proyecto_actualizaciones
  for each row execute function public.actualizar_avance_proyecto();

-- Conversión de propuesta a proyecto, registro de avances y cambio de estado.
create or replace function public.crear_proyecto_desde_propuesta(
  p_propuesta_id uuid,
  p_titulo text,
  p_descripcion text,
  p_fecha_inicio date default null,
  p_fecha_fin_estimada date default null
)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_proyecto_id uuid;
  v_estado_propuesta text;
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para crear proyectos';
  end if;

  select estado into v_estado_propuesta from public.propuestas where id = p_propuesta_id;

  if v_estado_propuesta is null then
    raise exception 'La propuesta no existe';
  end if;

  if v_estado_propuesta <> 'aprobada' then
    raise exception 'Solo se puede crear un proyecto a partir de una propuesta aprobada';
  end if;

  insert into public.proyectos (propuesta_id, responsable_id, titulo, descripcion, fecha_inicio, fecha_fin_estimada)
  values (p_propuesta_id, auth.uid(), p_titulo, p_descripcion, p_fecha_inicio, p_fecha_fin_estimada)
  returning id into v_proyecto_id;

  update public.propuestas set estado = 'convertida_proyecto' where id = p_propuesta_id;

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'crear_proyecto', 'proyectos', v_proyecto_id,
          jsonb_build_object('propuesta_id', p_propuesta_id, 'titulo', p_titulo));

  return v_proyecto_id;
end;
$$;

create or replace function public.registrar_avance_proyecto(
  p_proyecto_id uuid,
  p_descripcion text,
  p_porcentaje_avance int default null
)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_actualizacion_id uuid;
  v_estado_actual text;
  v_porcentaje_actual int;
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para registrar avances';
  end if;

  select estado, porcentaje_avance into v_estado_actual, v_porcentaje_actual
  from public.proyectos where id = p_proyecto_id;

  if v_estado_actual is null then
    raise exception 'El proyecto no existe';
  end if;

  if v_estado_actual = 'finalizado' then
    raise exception 'El proyecto ya está finalizado y no admite más avances';
  end if;

  if p_porcentaje_avance is not null and (p_porcentaje_avance < 0 or p_porcentaje_avance > 100) then
    raise exception 'El porcentaje debe estar entre 0 y 100';
  end if;

  if p_porcentaje_avance is not null and p_porcentaje_avance < v_porcentaje_actual then
    raise exception 'El porcentaje no puede ser menor al avance actual de % por ciento', v_porcentaje_actual;
  end if;

  insert into public.proyecto_actualizaciones (proyecto_id, autor_id, descripcion, porcentaje_avance)
  values (p_proyecto_id, auth.uid(), p_descripcion, p_porcentaje_avance)
  returning id into v_actualizacion_id;
  -- trg_actualizar_avance sincroniza proyectos.porcentaje_avance.

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'actualizar_proyecto', 'proyectos', p_proyecto_id,
          jsonb_build_object('actualizacion_id', v_actualizacion_id, 'porcentaje_avance', p_porcentaje_avance));

  return v_actualizacion_id;
end;
$$;

create or replace function public.actualizar_estado_proyecto(p_proyecto_id uuid, p_nuevo_estado text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para modificar proyectos';
  end if;

  if p_nuevo_estado not in ('planeado','en_ejecucion','finalizado','suspendido') then
    raise exception 'Estado no válido';
  end if;

  update public.proyectos set estado = p_nuevo_estado where id = p_proyecto_id;

  if not found then
    raise exception 'El proyecto no existe';
  end if;

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'actualizar_proyecto', 'proyectos', p_proyecto_id,
          jsonb_build_object('nuevo_estado', p_nuevo_estado));
end;
$$;

-- 15. PROYECTO_ARCHIVOS
create table if not exists public.proyecto_archivos (
  id                uuid primary key default gen_random_uuid(),
  actualizacion_id  uuid not null references public.proyecto_actualizaciones(id) on delete cascade,
  url               text not null,
  tipo              text,
  fecha_subida      timestamptz not null default now()
);

-- 16. NOTIFICACIONES
create table if not exists public.notificaciones (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references public.usuarios(id) on delete cascade,
  titulo      text not null,
  mensaje     text not null,
  tipo        text,
  leida       boolean not null default false,
  fecha       timestamptz not null default now()
);

-- Generación automática de notificaciones ante eventos del sistema
create or replace function public.notificar_cambio_estado_propuesta()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.estado = 'aprobada' and old.estado <> 'aprobada' then
    insert into public.notificaciones (usuario_id, titulo, mensaje, tipo)
    values (new.usuario_id, 'Propuesta aprobada',
            format('Tu propuesta "%s" fue aprobada.', new.titulo), 'propuesta_aprobada');
  elsif new.estado = 'rechazada' and old.estado <> 'rechazada' then
    insert into public.notificaciones (usuario_id, titulo, mensaje, tipo)
    values (new.usuario_id, 'Propuesta rechazada',
            format('Tu propuesta "%s" fue rechazada. Motivo: %s',
                   new.titulo, coalesce(new.observaciones, 'No especificado')),
            'propuesta_rechazada');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notificar_propuesta on public.propuestas;
create trigger trg_notificar_propuesta
  after update on public.propuestas
  for each row execute function public.notificar_cambio_estado_propuesta();

create or replace function public.notificar_cambio_estado_votacion()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.estado = 'activa' and old.estado <> 'activa' then
    insert into public.notificaciones (usuario_id, titulo, mensaje, tipo)
    select u.id, 'Nueva votación disponible',
           format('La votación "%s" ya está abierta. ¡Participa!', new.titulo),
           'votacion_activa'
    from public.usuarios u
    join public.roles r on r.id = u.rol_id
    where r.nombre = 'ciudadano' and u.activo = true;
  elsif new.estado = 'finalizada' and old.estado <> 'finalizada' then
    insert into public.notificaciones (usuario_id, titulo, mensaje, tipo)
    select vr.usuario_id, 'Votación finalizada',
           format('La votación "%s" finalizó. Consulta los resultados.', new.titulo),
           'votacion_finalizada'
    from public.voto_registros vr
    where vr.votacion_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notificar_votacion on public.votaciones;
create trigger trg_notificar_votacion
  after update on public.votaciones
  for each row execute function public.notificar_cambio_estado_votacion();

create or replace function public.notificar_actualizacion_proyecto()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_usuario_id uuid;
  v_proyecto_titulo text;
begin
  select p.usuario_id, pr.titulo into v_usuario_id, v_proyecto_titulo
  from public.proyectos pr
  join public.propuestas p on p.id = pr.propuesta_id
  where pr.id = new.proyecto_id;

  if v_usuario_id is not null then
    insert into public.notificaciones (usuario_id, titulo, mensaje, tipo)
    values (v_usuario_id, 'Actualización de proyecto',
            format('Hay una nueva actualización en el proyecto "%s".', v_proyecto_titulo),
            'proyecto_actualizado');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notificar_actualizacion_proyecto on public.proyecto_actualizaciones;
create trigger trg_notificar_actualizacion_proyecto
  after insert on public.proyecto_actualizaciones
  for each row execute function public.notificar_actualizacion_proyecto();

-- 17. AUDITORIA
create table if not exists public.auditoria (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references public.usuarios(id),
  accion      text not null,
  entidad     text not null,
  entidad_id  uuid,
  detalle     jsonb,
  fecha       timestamptz not null default now()
);

-- 18. VISTA DE PERFILES PÚBLICOS
create or replace view public.perfiles_publicos as
select id, alias, nombre_completo
from public.usuarios
where activo = true;

-- 19. FUNCIONES DE ADMINISTRACIÓN
create or replace function public.aprobar_propuesta(p_propuesta_id uuid, p_observaciones text default null)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para aprobar propuestas';
  end if;

  update public.propuestas
  set estado = 'aprobada', observaciones = p_observaciones,
      revisado_por = auth.uid(), fecha_revision = now()
  where id = p_propuesta_id;

  if not found then
    raise exception 'La propuesta no existe';
  end if;

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'aprobar_propuesta', 'propuestas', p_propuesta_id,
          jsonb_build_object('observaciones', p_observaciones));
end;
$$;

create or replace function public.rechazar_propuesta(p_propuesta_id uuid, p_observaciones text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para rechazar propuestas';
  end if;

  if p_observaciones is null or length(trim(p_observaciones)) = 0 then
    raise exception 'Debe indicar el motivo del rechazo';
  end if;

  update public.propuestas
  set estado = 'rechazada', observaciones = p_observaciones,
      revisado_por = auth.uid(), fecha_revision = now()
  where id = p_propuesta_id;

  if not found then
    raise exception 'La propuesta no existe';
  end if;

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'rechazar_propuesta', 'propuestas', p_propuesta_id,
          jsonb_build_object('observaciones', p_observaciones));
end;
$$;

create or replace function public.admin_actualizar_usuario(
  p_usuario_id uuid,
  p_rol_id uuid,
  p_activo boolean
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para gestionar usuarios';
  end if;

  if p_usuario_id = auth.uid() then
    raise exception 'No puede modificar su propia cuenta desde este panel';
  end if;

  update public.usuarios set rol_id = p_rol_id, activo = p_activo where id = p_usuario_id;

  if not found then
    raise exception 'El usuario no existe';
  end if;

  insert into public.auditoria (usuario_id, accion, entidad, entidad_id, detalle)
  values (auth.uid(), 'gestionar_usuarios', 'usuarios', p_usuario_id,
          jsonb_build_object('nuevo_rol_id', p_rol_id, 'nuevo_activo', p_activo));
end;
$$;

create or replace function public.obtener_metricas()
returns jsonb
language plpgsql
stable
security definer set search_path = public
as $$
declare
  v_resultado jsonb;
begin
  if not public.es_admin() then
    raise exception 'No tiene permisos para consultar métricas';
  end if;

  select jsonb_build_object(
    'usuarios_registrados', (select count(*) from public.usuarios),
    'propuestas_registradas', (select count(*) from public.propuestas),
    'propuestas_pendientes', (select count(*) from public.propuestas where estado = 'pendiente'),
    'propuestas_en_revision', (select count(*) from public.propuestas where estado = 'en_revision'),
    'propuestas_aprobadas', (select count(*) from public.propuestas where estado in ('aprobada','convertida_proyecto')),
    'propuestas_rechazadas', (select count(*) from public.propuestas where estado = 'rechazada'),
    'propuestas_convertidas', (select count(*) from public.propuestas where estado = 'convertida_proyecto'),
    'votaciones_programadas', (select count(*) from public.votaciones where estado = 'programada'),
    'votaciones_activas', (select count(*) from public.votaciones where estado = 'activa'),
    'votaciones_finalizadas', (select count(*) from public.votaciones where estado = 'finalizada'),
    'votaciones_canceladas', (select count(*) from public.votaciones where estado = 'cancelada'),
    'total_votos', (select count(*) from public.votos),
    'proyectos_planeados', (select count(*) from public.proyectos where estado = 'planeado'),
    'proyectos_activos', (select count(*) from public.proyectos where estado = 'en_ejecucion'),
    'proyectos_finalizados', (select count(*) from public.proyectos where estado = 'finalizado'),
    'proyectos_suspendidos', (select count(*) from public.proyectos where estado = 'suspendido'),
    'proyectos_por_categoria', (
      select coalesce(
        jsonb_agg(jsonb_build_object('categoria', c.nombre, 'total', conteo.total) order by conteo.total desc),
        '[]'::jsonb
      )
      from (
        select p.categoria_id, count(*) as total
        from public.proyectos pr
        join public.propuestas p on p.id = pr.propuesta_id
        group by p.categoria_id
      ) conteo
      join public.categorias c on c.id = conteo.categoria_id
    ),
    'nivel_participacion', (
      select case
        when (select count(*) from public.usuarios where activo = true) = 0 then 0
        else round(
          100.0 * (select count(distinct usuario_id) from public.voto_registros)
          / (select count(*) from public.usuarios where activo = true), 1
        )
      end
    )
  ) into v_resultado;

  return v_resultado;
end;
$$;

-- 20. ÍNDICES
create index if not exists idx_propuestas_usuario        on public.propuestas(usuario_id);
create index if not exists idx_propuestas_categoria       on public.propuestas(categoria_id);
create index if not exists idx_propuestas_estado          on public.propuestas(estado);
create index if not exists idx_propuesta_archivos_propuesta on public.propuesta_archivos(propuesta_id);
create index if not exists idx_votos_opcion               on public.votos(votacion_opcion_id);
create index if not exists idx_voto_registros_votacion    on public.voto_registros(votacion_id);
create index if not exists idx_notificaciones_usuario     on public.notificaciones(usuario_id, leida);
create index if not exists idx_auditoria_fecha            on public.auditoria(fecha desc);
create index if not exists idx_proyectos_estado           on public.proyectos(estado);

-- 21. ROW LEVEL SECURITY
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

drop policy if exists roles_select on public.roles;
create policy roles_select on public.roles for select to authenticated using (true);

drop policy if exists usuarios_select on public.usuarios;
create policy usuarios_select on public.usuarios
  for select to authenticated using (id = auth.uid() or public.es_admin());

drop policy if exists usuarios_update_propio on public.usuarios;
create policy usuarios_update_propio on public.usuarios
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists usuarios_admin_todo on public.usuarios;
create policy usuarios_admin_todo on public.usuarios
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists categorias_select on public.categorias;
create policy categorias_select on public.categorias for select to authenticated using (true);

drop policy if exists categorias_admin on public.categorias;
create policy categorias_admin on public.categorias
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists propuestas_select on public.propuestas;
create policy propuestas_select on public.propuestas
  for select to authenticated
  using (usuario_id = auth.uid() or estado = 'aprobada' or public.es_admin());

drop policy if exists propuestas_insert on public.propuestas;
create policy propuestas_insert on public.propuestas
  for insert to authenticated
  with check (usuario_id = auth.uid() and public.usuario_activo());

drop policy if exists propuestas_update_propia on public.propuestas;
create policy propuestas_update_propia on public.propuestas
  for update to authenticated
  using (usuario_id = auth.uid() and estado = 'pendiente' and public.usuario_activo())
  with check (usuario_id = auth.uid() and estado = 'pendiente' and public.usuario_activo());

drop policy if exists propuestas_admin on public.propuestas;
create policy propuestas_admin on public.propuestas
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists propuesta_archivos_select on public.propuesta_archivos;
create policy propuesta_archivos_select on public.propuesta_archivos
  for select to authenticated
  using (exists (
    select 1 from public.propuestas p
    where p.id = propuesta_id and (p.usuario_id = auth.uid() or p.estado = 'aprobada' or public.es_admin())
  ));

drop policy if exists propuesta_archivos_insert on public.propuesta_archivos;
create policy propuesta_archivos_insert on public.propuesta_archivos
  for insert to authenticated
  with check (
    public.usuario_activo()
    and exists (select 1 from public.propuestas p where p.id = propuesta_id and p.usuario_id = auth.uid() and p.estado = 'pendiente')
  );

drop policy if exists propuesta_archivos_admin on public.propuesta_archivos;
create policy propuesta_archivos_admin on public.propuesta_archivos
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists votaciones_select on public.votaciones;
create policy votaciones_select on public.votaciones for select to authenticated using (true);

drop policy if exists votaciones_admin on public.votaciones;
create policy votaciones_admin on public.votaciones
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists votacion_opciones_select on public.votacion_opciones;
create policy votacion_opciones_select on public.votacion_opciones for select to authenticated using (true);

drop policy if exists votacion_opciones_admin on public.votacion_opciones;
create policy votacion_opciones_admin on public.votacion_opciones
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists voto_registros_select_propio on public.voto_registros;
create policy voto_registros_select_propio on public.voto_registros
  for select to authenticated using (usuario_id = auth.uid());

drop policy if exists voto_registros_select_admin on public.voto_registros;
create policy voto_registros_select_admin on public.voto_registros
  for select to authenticated using (public.es_admin());

revoke insert, update, delete on public.votos          from authenticated;
revoke insert, update, delete on public.voto_registros  from authenticated;
grant execute on function public.emitir_voto(uuid, uuid) to authenticated;
grant select on public.resultados_votacion to authenticated;
grant select on public.perfiles_publicos to authenticated;

grant execute on function public.aprobar_propuesta(uuid, text) to authenticated;
grant execute on function public.rechazar_propuesta(uuid, text) to authenticated;
grant execute on function public.crear_votacion(text, text, timestamptz, timestamptz, text, uuid[]) to authenticated;
grant execute on function public.actualizar_estado_votacion(uuid, text) to authenticated;
grant execute on function public.crear_proyecto_desde_propuesta(uuid, text, text, date, date) to authenticated;
grant execute on function public.registrar_avance_proyecto(uuid, text, int) to authenticated;
grant execute on function public.actualizar_estado_proyecto(uuid, text) to authenticated;
grant execute on function public.admin_actualizar_usuario(uuid, uuid, boolean) to authenticated;
grant execute on function public.obtener_metricas() to authenticated;

drop policy if exists proyectos_select on public.proyectos;
create policy proyectos_select on public.proyectos for select to authenticated using (true);

drop policy if exists proyectos_admin on public.proyectos;
create policy proyectos_admin on public.proyectos
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists proyecto_actualizaciones_select on public.proyecto_actualizaciones;
create policy proyecto_actualizaciones_select on public.proyecto_actualizaciones for select to authenticated using (true);

drop policy if exists proyecto_actualizaciones_admin on public.proyecto_actualizaciones;
create policy proyecto_actualizaciones_admin on public.proyecto_actualizaciones
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists proyecto_archivos_select on public.proyecto_archivos;
create policy proyecto_archivos_select on public.proyecto_archivos for select to authenticated using (true);

drop policy if exists proyecto_archivos_admin on public.proyecto_archivos;
create policy proyecto_archivos_admin on public.proyecto_archivos
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists notificaciones_select_propias on public.notificaciones;
create policy notificaciones_select_propias on public.notificaciones
  for select to authenticated using (usuario_id = auth.uid());

drop policy if exists notificaciones_update_propias on public.notificaciones;
create policy notificaciones_update_propias on public.notificaciones
  for update to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

drop policy if exists notificaciones_admin on public.notificaciones;
create policy notificaciones_admin on public.notificaciones
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists auditoria_select_admin on public.auditoria;
create policy auditoria_select_admin on public.auditoria for select to authenticated using (public.es_admin());

-- 22. STORAGE — BUCKETS Y POLÍTICAS
insert into storage.buckets (id, name, public) values ('avatares',   'avatares',   true)  on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('propuestas', 'propuestas', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('evidencias', 'evidencias', false) on conflict (id) do nothing;

drop policy if exists avatares_insert on storage.objects;
create policy avatares_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatares_update on storage.objects;
create policy avatares_update on storage.objects
  for update to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatares_select on storage.objects;
create policy avatares_select on storage.objects
  for select to authenticated using (bucket_id = 'avatares');

drop policy if exists avatares_delete on storage.objects;
create policy avatares_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists propuestas_files_select on storage.objects;
create policy propuestas_files_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'propuestas'
    and exists (
      select 1 from public.propuestas p
      where p.id::text = (storage.foldername(name))[2]
        and (p.usuario_id = auth.uid() or p.estado = 'aprobada' or public.es_admin())
    )
  );

drop policy if exists propuestas_files_insert on storage.objects;
create policy propuestas_files_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'propuestas' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists propuestas_files_update on storage.objects;
create policy propuestas_files_update on storage.objects
  for update to authenticated
  using (bucket_id = 'propuestas' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'propuestas' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists propuestas_files_delete on storage.objects;
create policy propuestas_files_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'propuestas' and ((storage.foldername(name))[1] = auth.uid()::text or public.es_admin()));

drop policy if exists evidencias_select on storage.objects;
create policy evidencias_select on storage.objects
  for select to authenticated using (bucket_id = 'evidencias');

drop policy if exists evidencias_insert on storage.objects;
create policy evidencias_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'evidencias' and public.es_admin());

drop policy if exists evidencias_update on storage.objects;
create policy evidencias_update on storage.objects
  for update to authenticated
  using (bucket_id = 'evidencias' and public.es_admin())
  with check (bucket_id = 'evidencias' and public.es_admin());

drop policy if exists evidencias_delete on storage.objects;
create policy evidencias_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'evidencias' and public.es_admin());

-- 23. AUTOMATIZACIÓN (pg_cron)
select cron.schedule(
  'actualizar-votaciones-programadas',
  '* * * * *',
  $$select public.actualizar_votaciones_programadas();$$
) where not exists (
  select 1 from cron.job where jobname = 'actualizar-votaciones-programadas'
);

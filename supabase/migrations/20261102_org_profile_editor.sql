-- KAISA Organization Profile editor (apply after organizations + memberships migrations).
-- Allows approved organization Admins to edit presentation fields only.
-- Status, name, ownership and roles remain controlled by existing LGU flows.
create or replace function public.kaisa_org_admin_profile_get(p_organization_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_row jsonb;
begin
 if auth.uid() is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not exists (
   select 1 from public.kaisa_organization_memberships m
   where m.organization_id = p_organization_id and m.user_id = auth.uid()
     and m.status = 'approved' and m.role = 'Admin'
 ) then raise exception 'KAISA_ORG_ADMIN_REQUIRED'; end if;
 select jsonb_build_object('id',o.id,'name',o.name,'category',o.category,
   'description',o.description,'mission',o.mission,'location',o.location,
   'contact_email',o.contact_email,'status',o.status) into v_row
 from public.kaisa_organizations o where o.id = p_organization_id;
 if v_row is null then raise exception 'KAISA_ORGANIZATION_NOT_FOUND'; end if;
 return v_row;
end $$;

create or replace function public.kaisa_org_admin_profile_update(
 p_organization_id uuid,p_description text,p_mission text,
 p_location text,p_contact_email text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_row jsonb; v_email text := nullif(btrim(coalesce(p_contact_email,'')),'');
begin
 if auth.uid() is null then raise exception 'KAISA_LOGIN_REQUIRED'; end if;
 if not exists (
   select 1 from public.kaisa_organization_memberships m
   join public.kaisa_organizations o on o.id=m.organization_id
   where m.organization_id=p_organization_id and m.user_id=auth.uid()
     and m.status='approved' and m.role='Admin' and o.status='published'
 ) then raise exception 'KAISA_ORG_ADMIN_REQUIRED'; end if;
 if char_length(coalesce(p_description,''))>2000 or
    char_length(coalesce(p_mission,''))>2000 or
    char_length(coalesce(p_location,''))>250 or
    char_length(coalesce(p_contact_email,''))>254 then
   raise exception 'KAISA_PROFILE_VALUE_TOO_LONG'; end if;
 if v_email is not null and v_email !~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
   raise exception 'KAISA_INVALID_CONTACT_EMAIL'; end if;
 update public.kaisa_organizations
 set description=btrim(coalesce(p_description,'')), mission=btrim(coalesce(p_mission,'')),
     location=nullif(btrim(coalesce(p_location,'')),''), contact_email=v_email,
     updated_at=now()
 where id=p_organization_id;
 return public.kaisa_org_admin_profile_get(p_organization_id);
end $$;
revoke all on function public.kaisa_org_admin_profile_get(uuid) from public;
revoke all on function public.kaisa_org_admin_profile_update(uuid,text,text,text,text) from public;
grant execute on function public.kaisa_org_admin_profile_get(uuid) to authenticated;
grant execute on function public.kaisa_org_admin_profile_update(uuid,text,text,text,text) to authenticated;

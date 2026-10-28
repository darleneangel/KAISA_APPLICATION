-- KAISA Smart Search V1. Prerequisites: Events, Organizations, Profile migrations.
-- Read-only, safe fields only; no email/address/contact/ID data.
-- Search one-character prefixes (e.g. E), with strict result caps.
create or replace function public.kaisa_global_search(p_query text)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  q text := left(btrim(coalesce(p_query,'')), 80);
  result jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if char_length(q) < 1 then return '[]'::jsonb; end if;
  -- union result groups, capped independently to avoid flooding short queries
  select coalesce(jsonb_agg(to_jsonb(x) order by x.rank, x.title), '[]'::jsonb) into result
  from (
    select * from (
      select 'event'::text kind,e.id::text id,e.title title,
        coalesce(e.category,'Event') || ' · ' || coalesce(e.location,'Community event') subtitle,
        case when lower(e.title) like lower(q) || '%' then 0 else 1 end rank
      from public.kaisa_events e
      where e.status='published' and
        (e.title ilike '%'||q||'%' or e.category ilike '%'||q||'%' or e.organization_name ilike '%'||q||'%')
      order by rank,e.title limit 8
    ) ev
    union all
    select * from (
      select 'organization'::text kind,o.id::text id,o.name title,
        coalesce(o.category,'Community') || ' · Organization' subtitle,
        case when lower(o.name) like lower(q) || '%' then 0 else 1 end rank
      from public.kaisa_organizations o
      where o.status='published' and
        (o.name ilike '%'||q||'%' or o.category ilike '%'||q||'%' or o.description ilike '%'||q||'%')
      order by rank,o.name limit 8
    ) org
    union all
    select * from (
      select 'resident'::text kind,r.user_id::text id,
        coalesce(nullif(btrim(concat_ws(' ',r.first_name,r.last_name)),''),'KAISA Resident') title,
        'Resident profile'::text subtitle,
        case when lower(coalesce(r.first_name,'')) like lower(q) || '%' then 0 else 1 end rank
      from public.resident_profiles r
      where btrim(concat_ws(' ',r.first_name,r.last_name)) ilike '%'||q||'%'
      order by rank,title limit 8
    ) residents
  ) x;
  return result;
end;
$$;
revoke all on function public.kaisa_global_search(text) from public, anon;
grant execute on function public.kaisa_global_search(text) to authenticated;

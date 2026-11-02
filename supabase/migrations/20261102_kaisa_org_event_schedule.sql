-- Organization-scoped event schedule: read-only. Apply after Org Admin + QR attendance migrations.
-- Uses attendance session ownership until events gains an organization_id foreign key.
CREATE OR REPLACE FUNCTION public.kaisa_admin_event_schedule(p_organization_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF NOT public.kaisa_admin_is_allowed(p_organization_id) THEN
    RAISE EXCEPTION 'KAISA_ORG_ADMIN_NOT_AUTHORIZED';
  END IF;
  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'event_id', e.id,
      'title', e.title,
      'starts_at', e.starts_at,
      'ends_at', e.ends_at,
      'location', e.location,
      'category', e.category,
      'status', e.status,
      'capacity', e.capacity,
      'registered', (SELECT count(*) FROM public.kaisa_event_registrations r
          WHERE r.event_id = e.id AND r.status IN ('registered', 'attended')),
      'present', (SELECT count(*) FROM public.kaisa_event_attendance a
          WHERE a.event_id = e.id),
      'completed', (SELECT count(*) FROM public.kaisa_event_attendance a
          WHERE a.event_id = e.id AND a.checked_out_at IS NOT NULL)
    ) ORDER BY e.starts_at ASC)
    FROM public.kaisa_events e
    WHERE EXISTS (SELECT 1 FROM public.kaisa_event_checkin_sessions s
                  WHERE s.event_id = e.id AND s.organization_id = p_organization_id)
  ), '[]'::jsonb);
END;
$$;
REVOKE ALL ON FUNCTION public.kaisa_admin_event_schedule(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.kaisa_admin_event_schedule(uuid) TO authenticated;

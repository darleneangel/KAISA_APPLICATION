-- KAISA organization admin read-only management dashboard MVP.
-- Depends on kaisa_organizations, memberships, events, event registrations, QR attendance.
-- Scope MUST be enforced server-side. No global authenticated table SELECT granted.
-- An approved membership with role Admin grants access to one organization.
-- NOTE: Existing kaisa_events uses organization_name text, not org FK. For this MVP,
-- attendee reporting is restricted to event_checkin_sessions.organization_id.
-- Future: add a real organization_id FK on kaisa_events for all admin event operations.
CREATE OR REPLACE FUNCTION public.kaisa_admin_my_organizations()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT COALESCE(jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'category',o.category)
 ORDER BY o.name),'[]'::jsonb)
 FROM public.kaisa_organizations o
 JOIN public.kaisa_organization_memberships m ON m.organization_id=o.id
 WHERE m.user_id=auth.uid() AND m.status='approved' AND m.role='Admin' AND o.status='published';
$$;
CREATE OR REPLACE FUNCTION public.kaisa_admin_is_allowed(p_organization_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT auth.uid() IS NOT NULL AND EXISTS (
  SELECT 1 FROM public.kaisa_organization_memberships m
  JOIN public.kaisa_organizations o ON o.id=m.organization_id
  WHERE m.organization_id=p_organization_id AND m.user_id=auth.uid()
    AND m.role='Admin' AND m.status='approved' AND o.status='published');
$$;
-- Includes per-event report entries; never expose resident PII to other organizations.
CREATE OR REPLACE FUNCTION public.kaisa_admin_overview(p_organization_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_result jsonb; BEGIN
 IF NOT public.kaisa_admin_is_allowed(p_organization_id) THEN
   RAISE EXCEPTION 'KAISA_ORG_ADMIN_NOT_AUTHORIZED'; END IF;
 SELECT jsonb_build_object(
  'approved_members', (SELECT count(*) FROM public.kaisa_organization_memberships m WHERE m.organization_id=p_organization_id AND m.status='approved'),
  'pending_members', (SELECT count(*) FROM public.kaisa_organization_memberships m WHERE m.organization_id=p_organization_id AND m.status='pending'),
  'officers', (SELECT count(*) FROM public.kaisa_organization_memberships m WHERE m.organization_id=p_organization_id AND m.status='approved' AND m.role IN ('Admin','Officer')),
  'events', (SELECT count(*) FROM public.kaisa_event_checkin_sessions s WHERE s.organization_id=p_organization_id),
  'registrations', (SELECT count(*) FROM public.kaisa_event_registrations r JOIN public.kaisa_event_checkin_sessions s ON s.event_id=r.event_id WHERE s.organization_id=p_organization_id AND r.status IN ('registered','attended')),
  'checked_in', (SELECT count(*) FROM public.kaisa_event_attendance a JOIN public.kaisa_event_checkin_sessions s ON s.event_id=a.event_id WHERE s.organization_id=p_organization_id),
  'checked_out', (SELECT count(*) FROM public.kaisa_event_attendance a JOIN public.kaisa_event_checkin_sessions s ON s.event_id=a.event_id WHERE s.organization_id=p_organization_id AND a.checked_out_at IS NOT NULL),
  'event_summary', COALESCE((SELECT jsonb_agg(jsonb_build_object(
     'event_id',e.id,'event',e.title,'starts_at',e.starts_at,
     'registered',(SELECT count(*) FROM public.kaisa_event_registrations r WHERE r.event_id=e.id AND r.status IN ('registered','attended')),
     'present',(SELECT count(*) FROM public.kaisa_event_attendance a WHERE a.event_id=e.id),
     'future',(SELECT count(*) FROM public.kaisa_event_checkin_sessions s WHERE s.event_id=e.id AND s.opens_at>now()),
     'completed',(SELECT count(*) FROM public.kaisa_event_attendance a WHERE a.event_id=e.id AND a.checked_out_at IS NOT NULL)
    ) ORDER BY e.starts_at DESC)
   FROM public.kaisa_event_checkin_sessions s JOIN public.kaisa_events e ON e.id=s.event_id
   WHERE s.organization_id=p_organization_id),'[]'::jsonb)
 ) INTO v_result;
 RETURN v_result;
END $$;
-- Restricted report of actual attendance. No address/email/ID document included.
CREATE OR REPLACE FUNCTION public.kaisa_admin_attendance_report(p_organization_id uuid,p_event_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
BEGIN
 IF NOT public.kaisa_admin_is_allowed(p_organization_id) THEN RAISE EXCEPTION 'KAISA_ORG_ADMIN_NOT_AUTHORIZED'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.kaisa_event_checkin_sessions s WHERE s.organization_id=p_organization_id AND s.event_id=p_event_id) THEN
  RAISE EXCEPTION 'KAISA_EVENT_NOT_ASSIGNED_TO_ORGANIZATION'; END IF;
 RETURN COALESCE((SELECT jsonb_agg(jsonb_build_object(
  'resident_id',r.user_id,'name',trim(concat_ws(' ',p.first_name,p.last_name)),
  'registration_status',r.status,'checked_in_at',a.checked_in_at,'checked_out_at',a.checked_out_at)
  ORDER BY p.last_name,p.first_name)
 FROM public.kaisa_event_registrations r
 LEFT JOIN public.resident_profiles p ON p.user_id=r.user_id
 LEFT JOIN public.kaisa_event_attendance a ON a.event_id=r.event_id AND a.user_id=r.user_id
 WHERE r.event_id=p_event_id AND r.status IN ('registered','attended')), '[]'::jsonb);
END $$;
REVOKE ALL ON FUNCTION public.kaisa_admin_my_organizations(),public.kaisa_admin_is_allowed(uuid),
 public.kaisa_admin_overview(uuid),public.kaisa_admin_attendance_report(uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.kaisa_admin_my_organizations(),public.kaisa_admin_is_allowed(uuid),
 public.kaisa_admin_overview(uuid),public.kaisa_admin_attendance_report(uuid,uuid) TO authenticated;
-- No write operations: member approvals/creation and org roles still require Super Admin workflow.

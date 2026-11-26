-- Verified event feedback and LGU Operations private event reports.
BEGIN;

CREATE TABLE public.kaisa_event_feedback (
  event_id uuid NOT NULL REFERENCES public.kaisa_events(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  feedback text NOT NULL CHECK (char_length(btrim(feedback)) BETWEEN 1 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (event_id, user_id)
);
ALTER TABLE public.kaisa_event_feedback ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaisa_event_feedback FROM anon, authenticated;

CREATE FUNCTION public.kaisa_event_modal_feedback(p_event_id uuid)
RETURNS TABLE (rating smallint, feedback text, created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT f.rating, f.feedback, f.created_at
  FROM public.kaisa_event_feedback f
  JOIN public.kaisa_events e ON e.id = f.event_id
  WHERE auth.uid() IS NOT NULL AND f.event_id = p_event_id
    AND e.status = 'published'
    AND EXISTS (
      SELECT 1 FROM public.kaisa_event_attendance a
      WHERE a.event_id = f.event_id AND a.user_id = f.user_id
        AND a.checked_in_by IS NOT NULL AND a.checked_out_at IS NOT NULL
        AND a.checked_out_by IS NOT NULL
    )
  ORDER BY f.created_at DESC, f.user_id;
$$;
REVOKE ALL ON FUNCTION public.kaisa_event_modal_feedback(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.kaisa_event_modal_feedback(uuid) TO authenticated;

CREATE TABLE public.kaisa_event_private_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.kaisa_events(id),
  reporter_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  category text NOT NULL CHECK (category IN (
    'Misleading information', 'Inappropriate content', 'Fraudulent or suspicious activity',
    'Unauthorized activity', 'Harassment or discrimination', 'Safety concerns', 'Other'
  )),
  explanation text NOT NULL CHECK (char_length(btrim(explanation)) BETWEEN 10 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX kaisa_event_private_reports_event_idx ON public.kaisa_event_private_reports(event_id);
ALTER TABLE public.kaisa_event_private_reports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaisa_event_private_reports FROM anon, authenticated;
GRANT INSERT (event_id, category, explanation), SELECT ON public.kaisa_event_private_reports TO authenticated;

CREATE POLICY event_private_report_submit ON public.kaisa_event_private_reports
FOR INSERT TO authenticated WITH CHECK (
  reporter_id = (SELECT auth.uid())
  AND EXISTS (SELECT 1 FROM public.kaisa_events e
              WHERE e.id = event_id AND e.status = 'published')
);
CREATE POLICY event_private_report_operations_read ON public.kaisa_event_private_reports
FOR SELECT TO authenticated USING (
  (SELECT auth.jwt() -> 'app_metadata' ->> 'kaisa_lgu_role') = 'lgu_operations_admin'
);

COMMIT;

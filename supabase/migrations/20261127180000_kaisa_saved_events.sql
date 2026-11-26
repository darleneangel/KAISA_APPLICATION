BEGIN;

CREATE TABLE public.kaisa_saved_events (
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public.kaisa_events(id) ON DELETE CASCADE,
  saved_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, event_id)
);
CREATE INDEX kaisa_saved_events_event_idx ON public.kaisa_saved_events(event_id);
ALTER TABLE public.kaisa_saved_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaisa_saved_events FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT (event_id), DELETE ON public.kaisa_saved_events TO authenticated;

CREATE POLICY saved_events_select_own ON public.kaisa_saved_events
FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));

CREATE POLICY saved_events_insert_own_published ON public.kaisa_saved_events
FOR INSERT TO authenticated WITH CHECK (
  user_id = (SELECT auth.uid()) AND EXISTS (
    SELECT 1 FROM public.kaisa_events e
    WHERE e.id = kaisa_saved_events.event_id AND e.status = 'published'
  )
);

CREATE POLICY saved_events_delete_own ON public.kaisa_saved_events
FOR DELETE TO authenticated USING (user_id = (SELECT auth.uid()));

COMMIT;

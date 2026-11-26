BEGIN;

CREATE TABLE public.kaisa_organization_profiles (
  organization_id uuid PRIMARY KEY REFERENCES public.kaisa_organizations(id) ON DELETE CASCADE,
  cover_image text CHECK (char_length(cover_image) <= 2048),
  logo_image text CHECK (char_length(logo_image) <= 2048),
  gallery_images text[] NOT NULL DEFAULT '{}' CHECK (cardinality(gallery_images) <= 6),
  vision text CHECK (char_length(vision) <= 2000),
  website text CHECK (char_length(website) <= 2048),
  office_hours text CHECK (char_length(office_hours) <= 300),
  sdg_goals smallint[] NOT NULL DEFAULT '{}'
    CHECK (sdg_goals <@ ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]::smallint[])
);
ALTER TABLE public.kaisa_organization_profiles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaisa_organization_profiles FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.kaisa_organization_profiles TO authenticated;
CREATE POLICY organization_profiles_published ON public.kaisa_organization_profiles
FOR SELECT TO authenticated USING (EXISTS (
  SELECT 1 FROM public.kaisa_organizations o
  WHERE o.id = organization_id AND o.status = 'published'
));
CREATE POLICY organization_profiles_admin_write ON public.kaisa_organization_profiles
FOR ALL TO authenticated USING (public.kaisa_admin_is_allowed(organization_id))
WITH CHECK (public.kaisa_admin_is_allowed(organization_id));

CREATE TABLE public.kaisa_organization_follows (
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id uuid NOT NULL REFERENCES public.kaisa_organizations(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, organization_id)
);
CREATE INDEX kaisa_organization_follows_org_idx ON public.kaisa_organization_follows(organization_id);
ALTER TABLE public.kaisa_organization_follows ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaisa_organization_follows FROM anon, authenticated;
GRANT SELECT, INSERT (organization_id), DELETE ON public.kaisa_organization_follows TO authenticated;
CREATE POLICY organization_follows_own ON public.kaisa_organization_follows
FOR ALL TO authenticated USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()) AND EXISTS (
  SELECT 1 FROM public.kaisa_organizations o
  WHERE o.id = organization_id AND o.status = 'published'
));

CREATE TABLE public.kaisa_organization_feedback (
  organization_id uuid NOT NULL REFERENCES public.kaisa_organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text NOT NULL CHECK (char_length(btrim(comment)) BETWEEN 1 AND 1200),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (organization_id, user_id)
);
ALTER TABLE public.kaisa_organization_feedback ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaisa_organization_feedback FROM anon, authenticated;

CREATE FUNCTION public.kaisa_resident_organization_feedback(p_organization_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  WITH visible AS (
    SELECT f.rating, f.comment, f.created_at
    FROM public.kaisa_organization_feedback f
    JOIN public.kaisa_organizations o ON o.id = f.organization_id
    WHERE auth.uid() IS NOT NULL AND o.status = 'published' AND o.id = p_organization_id
  )
  SELECT jsonb_build_object(
    'rating', (SELECT avg(rating) FROM visible),
    'count', (SELECT count(*) FROM visible),
    'comments', (SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY r.created_at DESC),'[]'::jsonb)
                 FROM (SELECT * FROM visible ORDER BY created_at DESC LIMIT 30) r)
  );
$$;

CREATE FUNCTION public.kaisa_resident_rate_organization(p_organization_id uuid, p_rating smallint, p_comment text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.kaisa_organization_memberships m
    JOIN public.kaisa_organizations o ON o.id=m.organization_id AND o.status='published'
    WHERE m.organization_id=p_organization_id AND m.user_id=auth.uid()
      AND m.status='approved' AND lower(m.role)='member'
  ) THEN RAISE EXCEPTION 'KAISA_APPROVED_MEMBER_REQUIRED'; END IF;
  INSERT INTO public.kaisa_organization_feedback(organization_id,user_id,rating,comment)
  VALUES (p_organization_id,auth.uid(),p_rating,btrim(p_comment))
  ON CONFLICT (organization_id,user_id) DO UPDATE
    SET rating=excluded.rating, comment=excluded.comment, created_at=now();
END;
$$;

CREATE FUNCTION public.kaisa_resident_followed_announcements()
RETURNS TABLE (id uuid, organization_id uuid, organization_name text, title text, body text, created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT a.id, a.organization_id, o.name, a.title, a.body, a.created_at
  FROM public.kaisa_organization_follows f
  JOIN public.kaisa_organizations o ON o.id=f.organization_id AND o.status='published'
  JOIN public.kaisa_org_announcements a ON a.organization_id=o.id AND a.visibility='public'
  WHERE f.user_id=auth.uid()
  ORDER BY a.created_at DESC, a.id
  LIMIT 12;
$$;

CREATE FUNCTION public.kaisa_resident_event_organizations()
RETURNS TABLE (event_id uuid, organization_id uuid)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
  SELECT s.event_id, s.organization_id FROM public.kaisa_event_checkin_sessions s
  JOIN public.kaisa_events e ON e.id=s.event_id AND e.status='published'
  JOIN public.kaisa_organizations o ON o.id=s.organization_id AND o.status='published'
  WHERE auth.uid() IS NOT NULL;
$$;

REVOKE ALL ON FUNCTION public.kaisa_resident_organization_feedback(uuid),
  public.kaisa_resident_rate_organization(uuid,smallint,text), public.kaisa_resident_followed_announcements(),
  public.kaisa_resident_event_organizations() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.kaisa_resident_organization_feedback(uuid),
  public.kaisa_resident_rate_organization(uuid,smallint,text), public.kaisa_resident_followed_announcements(),
  public.kaisa_resident_event_organizations() TO authenticated;

COMMIT;

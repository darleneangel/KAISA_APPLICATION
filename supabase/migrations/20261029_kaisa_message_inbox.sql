-- Run AFTER 20261029_kaisa_public_profiles_messages.sql.
-- Authenticated participants can see only their own conversation list.
-- Do not expose email, phone, address or other private profile fields.
CREATE OR REPLACE FUNCTION public.kaisa_message_inbox()
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
  WITH own_messages AS (
    SELECT m.id,
           m.body,
           m.created_at,
           m.sender_id = auth.uid() AS from_me,
           CASE WHEN m.sender_id = auth.uid()
                THEN m.recipient_id ELSE m.sender_id END AS other_user_id
    FROM public.kaisa_direct_messages m
    WHERE auth.uid() IS NOT NULL
      AND (m.sender_id = auth.uid() OR m.recipient_id = auth.uid())
  ), latest AS (
    SELECT DISTINCT ON (other_user_id) *
    FROM own_messages
    ORDER BY other_user_id, created_at DESC, id DESC
  )
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'other_user_id', l.other_user_id,
    'display_name', COALESCE(
      NULLIF(btrim(concat_ws(' ', p.first_name, p.last_name)), ''),
      NULLIF(p.full_name, ''), 'KAISA Resident'
    ),
    'avatar_path', p.avatar_path,
    'last_message', l.body,
    'last_at', l.created_at,
    'from_me', l.from_me
  ) ORDER BY l.created_at DESC), '[]'::jsonb)
  FROM latest l
  LEFT JOIN public.resident_profiles p ON p.user_id = l.other_user_id;
$$;
REVOKE ALL ON FUNCTION public.kaisa_message_inbox() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.kaisa_message_inbox() TO authenticated;

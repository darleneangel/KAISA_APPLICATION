
-- KAISA: LGU Superadmin Authorization
-- Checks ONLY the currently logged-in account.

CREATE OR REPLACE FUNCTION public.kaisa_is_lgu_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.kaisa_entitlements
    WHERE user_id = (SELECT auth.uid())
      AND is_super_admin IS TRUE
  );
$$;

-- Prevent public or anonymous access.
REVOKE ALL ON FUNCTION public.kaisa_is_lgu_admin()
FROM PUBLIC, anon;

-- Allow signed-in accounts to check their own status.
GRANT EXECUTE ON FUNCTION public.kaisa_is_lgu_admin()
TO authenticated;

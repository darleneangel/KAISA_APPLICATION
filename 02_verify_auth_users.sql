-- READ ONLY. Discover how your friend's NEW LGU-admin code stores and checks roles.
-- There is NO permission-changing SQL in this package.

-- A. Tables/columns that could store distinct admin roles.
SELECT c.table_schema, c.table_name, c.column_name, c.data_type
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND (
    c.table_name ILIKE '%admin%' OR c.table_name ILIKE '%role%' OR
    c.table_name ILIKE '%permission%' OR c.table_name ILIKE '%entitlement%' OR
    c.column_name ILIKE '%admin%' OR c.column_name ILIKE '%role%' OR
    c.column_name ILIKE '%permission%'
  )
ORDER BY c.table_name, c.ordinal_position;

-- B. Functions involved in LGU admin authorization.
SELECT n.nspname AS function_schema, p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS input_signature
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND (
    p.proname ILIKE '%admin%' OR p.proname ILIKE '%role%' OR
    p.proname ILIKE '%permission%' OR p.proname ILIKE '%lgu%'
  )
ORDER BY p.proname;

-- C. Existing RLS policies referring to admin roles.
SELECT schemaname, tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND (policyname ILIKE '%admin%' OR policyname ILIKE '%lgu%' OR
       policyname ILIKE '%role%' OR tablename ILIKE '%admin%')
ORDER BY tablename, policyname;

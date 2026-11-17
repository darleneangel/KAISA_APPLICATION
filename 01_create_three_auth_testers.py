-- READ ONLY. Run in the matching Supabase project's SQL Editor.
-- Replace YOUR_GMAIL_BASE with the mailbox entered into the Python script.
-- These are Auth logins only; role access is a separate step.
SELECT
  u.id AS auth_user_id,
  u.email,
  CASE WHEN u.email_confirmed_at IS NOT NULL THEN 'CONFIRMED' ELSE 'UNCONFIRMED' END AS email_status,
  COALESCE(e.is_super_admin, false) AS has_legacy_super_admin_entitlement,
  e.tier
FROM auth.users AS u
LEFT JOIN public.kaisa_entitlements AS e ON e.user_id = u.id
WHERE lower(u.email) IN (
  'YOUR_GMAIL_BASE+kaisa-lgu-it-qa@gmail.com',
  'YOUR_GMAIL_BASE+kaisa-lgu-verification-qa@gmail.com',
  'YOUR_GMAIL_BASE+kaisa-lgu-operations-qa@gmail.com'
)
ORDER BY u.email;

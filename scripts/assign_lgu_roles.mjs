
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('Missing Supabase Admin credentials.');
}

const supabase = createClient(
  supabaseUrl,
  serviceRoleKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
);

// Replace ALL placeholders before running.
const admins = [
  {
    userId: '3c8d3c44-b366-476f-9718-1d580bbe69ab',
    email: 'angel.lustre0809@gmail.com',
    role: 'lgu_it_admin',
  },
  {
    userId: '887eb16d-3b0d-4365-90c4-a7e05c3cb7f9',
    email: 'angel.lustre0818@gmail.com',
    role: 'lgu_verification_admin',
  },
  {
    userId: '1a8e10b4-aafd-4b19-8cb9-c6b8f87d9ca0',
    email: 's.darleneangel.custodio@sscr.edu',
    role: 'lgu_operations_admin',
  },
];

const allowedRoles = new Set([
  'lgu_it_admin',
  'lgu_verification_admin',
  'lgu_operations_admin',
]);

if (
  new Set(admins.map((a) => a.userId)).size !== 3 ||
  new Set(admins.map((a) => a.email.toLowerCase())).size !== 3 ||
  new Set(admins.map((a) => a.role)).size !== 3
) {
  throw new Error('Admin assignments must be unique.');
}

// Verify all identities before changing any account.
const verified = [];

for (const admin of admins) {
  if (!allowedRoles.has(admin.role)) {
    throw new Error(`Invalid role: ${admin.role}`);
  }

  const { data, error } =
      await supabase.auth.admin.getUserById(admin.userId);

  if (error || !data.user) {
    throw new Error(
      `Cannot verify user ${admin.userId}: ${error?.message}`,
    );
  }

  if (
    data.user.email?.toLowerCase() !==
    admin.email.toLowerCase()
  ) {
    throw new Error(
      `Email mismatch for ${admin.userId}. Aborting.`,
    );
  }

  if (!data.user.email_confirmed_at) {
    throw new Error(
      `Email is not confirmed for ${admin.email}.`,
    );
  }

  verified.push({
    ...admin,
    existingMetadata: data.user.app_metadata ?? {},
  });
}

// Assign the verified roles.
for (const admin of verified) {
  const { error } =
      await supabase.auth.admin.updateUserById(
    admin.userId,
    {
      app_metadata: {
        ...admin.existingMetadata,
        is_super_admin: true,
        kaisa_lgu_role: admin.role,
      },
    },
  );

  if (error) {
    throw new Error(
      `Failed to assign ${admin.role}: ${error.message}`,
    );
  }

  console.log(`Assigned ${admin.role} successfully.`);
}

console.log('LGU administrator provisioning complete.');

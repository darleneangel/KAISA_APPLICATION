
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('Missing Supabase Admin credentials.');
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// ORIGINAL LGU SUPERADMIN ACCOUNTS
// Keep their known UIDs and role assignments.
const originalAdmins = [
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

// NEW KAISA PROTOTYPE ACCOUNTS
// Their UIDs will be retrieved from Supabase.
const testAdmins = [
  {
    userId: 'e807a059-ae3a-4da6-bc55-e68ce001dbaa',
    email: 'it.admin@kaisa.example.com',
    role: 'lgu_it_admin',
  },
  {
    userId: 'b2212275-e468-4006-8426-e0da14b64e35',
    email: 'verification.admin@kaisa.example.com',
    role: 'lgu_verification_admin',
  },
  {
    userId: '65f72cce-9274-4674-b9b0-42ba4ddb0219',
    email: 'operations.admin@kaisa.example.com',
    role: 'lgu_operations_admin',
  },
];

const allowedRoles = new Set([
  'lgu_it_admin',
  'lgu_verification_admin',
  'lgu_operations_admin',
]);

const admins = [...originalAdmins, ...testAdmins];

// Validate configuration before making changes.
if (
  new Set(admins.map((a) => a.email.toLowerCase())).size !==
  admins.length
) {
  throw new Error('Duplicate administrator email detected.');
}

if (
  new Set(originalAdmins.map((a) => a.userId)).size !==
  originalAdmins.length
) {
  throw new Error('Duplicate original administrator UID detected.');
}

for (const admin of admins) {
  if (!allowedRoles.has(admin.role)) {
    throw new Error(`Invalid role: ${admin.role}`);
  }
}

// Retrieve users with pagination.
async function findUserByEmail(email) {
  const target = email.trim().toLowerCase();
  let page = 1;

  while (true) {
    const { data, error } =
      await supabase.auth.admin.listUsers({
        page,
        perPage: 100,
      });

    if (error) {
      throw new Error(
        `Cannot retrieve users: ${error.message}`,
      );
    }

    const users = data.users ?? [];

    const user = users.find(
      (u) => u.email?.toLowerCase() === target,
    );

    if (user) return user;

    if (users.length < 100) break;

    page++;
  }

  throw new Error(
    `Account not found in Supabase Auth: ${email}`,
  );
}

// STEP 1: Verify every account before changing metadata.
const verified = [];

for (const admin of admins) {
  let user;

  if (admin.userId) {
    const { data, error } =
      await supabase.auth.admin.getUserById(admin.userId);

    if (error || !data.user) {
      throw new Error(
        `Cannot verify ${admin.email}: ${error?.message}`,
      );
    }

    user = data.user;
  } else {
    user = await findUserByEmail(admin.email);
  }

  if (
    user.email?.toLowerCase() !== admin.email.toLowerCase()
  ) {
    throw new Error(
      `Email mismatch for ${admin.email}. Aborting.`,
    );
  }

  if (!user.email_confirmed_at) {
    throw new Error(
      `Email is not confirmed for ${admin.email}.`,
    );
  }

  verified.push({
    userId: user.id,
    email: user.email,
    role: admin.role,
    existingMetadata: user.app_metadata ?? {},
  });

  console.log(`Verified account: ${admin.email}`);
}

// Ensure no two entries refer to the same Supabase user.
if (
  new Set(verified.map((a) => a.userId)).size !==
  verified.length
) {
  throw new Error(
    'Multiple assignments point to the same user.',
  );
}

// STEP 2: Assign verified administrator roles.
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
      `Failed to assign ${admin.email}: ${error.message}`,
    );
  }

  console.log(
    `Assigned ${admin.role} to ${admin.email}`,
  );
}

console.log(
  `LGU provisioning complete: ${verified.length} accounts.`,
);

-- Explicitly approved demo data only. Existing organizations are untouched.
BEGIN;

CREATE TEMP TABLE organization_demo_input ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('01', 'Cavite Coastal Mangrove & Marine Watch', 'Environment',
   'A volunteer group restoring the mangrove shoreline and monitoring waste along Cavite City waters.',
   'Organize coastal rehabilitation and train resident shoreline volunteers.',
   'A resilient coastline with healthy mangroves and resident-led stewardship.',
   'Samonte Park Shoreline, Cavite City', 'stitch-organization-coast.jpg', ARRAY[11,13,14]),
  ('02', 'Lingap Caridad Health Association', 'Health',
   'A community group supporting health education and barangay wellness outreach.',
   'Help residents discover preventive care resources and local health programs.',
   'Accessible health information throughout Cavite City.', 'Caridad Covered Court',
   'stitch-feed-health.jpg', ARRAY[3,10]),
  ('03', 'Sining Kabite Youth Collective', 'Arts & Culture',
   'Youth artists and mentors documenting Cavite heritage through community art.',
   'Make neighborhood arts education accessible to young residents.',
   'A city where young people preserve and reinterpret local heritage.',
   'Plaza Soledad Sea Wall', 'stitch-feed-mural.jpg', ARRAY[4,11]),
  ('04', 'Dalahican Preparedness Volunteers', 'Safety',
   'A resident volunteer team focused on flood readiness and safe neighborhood assembly.',
   'Practice and share practical disaster preparedness skills.',
   'Prepared neighborhoods that can respond together.',
   'Dalahican Baywalk Evacuation Area', 'unlad_pier.jpg', ARRAY[11,13]),
  ('05', 'San Roque Animal Welfare Volunteers', 'Animal Welfare',
   'Resident volunteers promoting responsible pet care and community animal welfare.',
   'Share practical guidance on safe pet ownership and wellness.',
   'A safer, healthier barangay for residents and pets.',
   'San Roque Barangay Plaza', 'regada_2025.jpg', ARRAY[3,11]),
  ('06', 'Cavite Youth Bayanihan Network', 'Youth',
   'Local youth groups working together on leadership projects and civic participation.',
   'Connect young residents with mentoring and volunteer opportunities.',
   'Youth leadership that strengthens local civic participation.',
   'Montano Hall Auditorium', 'regada_foam_2025.jpg', ARRAY[4,16,17]),
  ('07', 'Cañacao Shoreline Green Patrol', 'Environment',
   'A community cleanup team supporting waste sorting and coastal conservation.',
   'Run cleanup activities and promote responsible waste management.',
   'Cleaner shorelines and a culture of waste reduction.',
   'Cañacao Fishing Wharf', 'stitch-feed-mangroves.jpg', ARRAY[12,14])
) AS d(suffix, name, category, description, mission, vision, location, cover, sdgs);

INSERT INTO public.kaisa_organizations (id,name,category,description,mission,location,status)
SELECT ('e6941422-69c7-4af2-b01c-731501abef' || suffix)::uuid,
       '[TEST] ' || name, category, description, mission, location, 'published'
FROM organization_demo_input
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.kaisa_organization_profiles (organization_id,cover_image,gallery_images,vision,office_hours,sdg_goals)
SELECT o.id, 'assets/images/cavite/' || d.cover,
       CASE WHEN d.suffix = '01' THEN ARRAY['assets/images/cavite/stitch-organization-mural.jpg', 'assets/images/cavite/stitch-organization-mangroves.jpg']
         ELSE ARRAY[]::text[] END,
       d.vision, 'Demo office schedule · Weekdays, 9 AM–4 PM', d.sdgs::smallint[]
FROM organization_demo_input d
JOIN public.kaisa_organizations o ON o.id=('e6941422-69c7-4af2-b01c-731501abef' || d.suffix)::uuid
  AND o.name='[TEST] ' || d.name
ON CONFLICT (organization_id) DO NOTHING;

UPDATE public.kaisa_events e SET organization_name=o.name
FROM organization_demo_input d
JOIN public.kaisa_organizations o ON o.id=('e6941422-69c7-4af2-b01c-731501abef' || d.suffix)::uuid
  AND o.name='[TEST] ' || d.name
WHERE e.id=('d32111fd-8580-48bc-9ab6-c7f4afb963' || d.suffix)::uuid
  AND left(e.title, 7)='[TEST] ';

COMMIT;

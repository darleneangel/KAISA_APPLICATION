-- Run with psql against local Supabase on 127.0.0.1:54322.
\set ON_ERROR_STOP on
SELECT (:'HOST' IN ('127.0.0.1', 'localhost', '::1') AND :'PORT' = '54322')
  AS local_target \gset
\if :local_target
\else
  \echo Feed fixtures require a local Supabase database on port 54322.
  SELECT 1 / 0;
\endif

BEGIN;

WITH fixtures(id, title, organization, category, venue, summary, instructions, days, capacity) AS (
  VALUES
    ('d32111fd-8580-48bc-9ab6-c7f4afb96301'::uuid,
      '[TEST] Samonte Park Coastal Mangrove Planting & Estuary Defense', 'Cavite Coastal Mangrove & Marine Watch', 'Environment',
      'Samonte Park Shoreline, Cavite City', 'Join a coastal rehabilitation workshop and help plant mangrove seedlings along the estuary.',
      'Bring gloves, water and closed shoes.', 1, 60),
    ('d32111fd-8580-48bc-9ab6-c7f4afb96302'::uuid,
      '[TEST] Lingap Kalusugan: Free Barangay Medical & Dental Triage', 'Lingap Caridad Health Association', 'Health',
      'Caridad Covered Court, Cavite City', 'Explore the demo clinic schedule for preventive checkups, dental triage and family health guidance.',
      'Arrive 15 minutes before orientation.', 1, 40),
    ('d32111fd-8580-48bc-9ab6-c7f4afb96303'::uuid,
      '[TEST] Cavite Heritage & Shoreline Murals: Youth Civic Art', 'Sining Kabite Youth Collective', 'Arts & Culture',
      'Plaza Soledad Sea Wall, Cavite City', 'Join a workshop on documenting local heritage through a community mural.',
      'Wear clothes suitable for painting.', 1, 35),
    ('d32111fd-8580-48bc-9ab6-c7f4afb96304'::uuid,
      '[TEST] Dalahican Disaster Preparedness & Flood Sandbagging Drill', 'CDRRMO Cavite City Operations', 'Safety',
      'Dalahican Baywalk Evacuation Area', 'Practice sandbag placement, review evacuation guidance and meet community response volunteers.',
      'Bring a notebook and drinking water.', 4, 45),
    ('d32111fd-8580-48bc-9ab6-c7f4afb96305'::uuid,
      '[TEST] Barangay San Roque Rabies Vaccination & Pet Wellness Clinic', 'Cavite City Veterinary Office', 'Animal Welfare',
      'San Roque Barangay Plaza', 'Preview the demo pet wellness clinic and its animal-care guidance.',
      'Bring your pet''s vaccination record for the demonstration.', 5, 120),
    ('d32111fd-8580-48bc-9ab6-c7f4afb96306'::uuid,
      '[TEST] Cavite City Youth Bayanihan Summit', 'Sangguniang Kabataan Federation', 'Youth',
      'Montano Hall Auditorium', 'Connect with local youth groups for leadership workshops and volunteer planning.',
      'Check in at the auditorium entrance.', 6, 150),
    ('d32111fd-8580-48bc-9ab6-c7f4afb96307'::uuid,
      '[TEST] Oplan Kalinisan: Cañacao Shoreline Sweep & Waste Segregation', 'CENRO & Youth Green Patrol', 'Environment',
      'Cañacao Fishing Wharf', 'Help collect shoreline litter and learn the local waste segregation process.',
      'Wear closed shoes and bring drinking water.', 8, 80)
), scheduled AS (
  SELECT *, (
    date_trunc('day', now() AT TIME ZONE 'Asia/Manila') +
    make_interval(days => days, hours => CASE category
      WHEN 'Health' THEN 10 WHEN 'Arts & Culture' THEN 11 ELSE 9 END)
  ) AT TIME ZONE 'Asia/Manila' AS starts_at
  FROM fixtures
)
INSERT INTO public.kaisa_events (
  id, title, organization_name, category, location, description, instructions,
  starts_at, ends_at, capacity, status
)
SELECT id, title, organization, category, venue, summary, instructions,
  starts_at, starts_at + interval '2 hours', capacity, 'published'
FROM scheduled
ON CONFLICT (id) DO UPDATE
  SET title = excluded.title,
      organization_name = excluded.organization_name,
      category = excluded.category,
      location = excluded.location,
      description = excluded.description,
      instructions = excluded.instructions,
      starts_at = excluded.starts_at,
      ends_at = excluded.ends_at
  WHERE left(kaisa_events.title, 7) = '[TEST] ';

COMMIT;

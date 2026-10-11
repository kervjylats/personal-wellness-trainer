-- supabase/seed.sql
--
-- Local-dev seed data. Applied automatically by `supabase start` /
-- `supabase db reset`.
--
-- Deliberately minimal: most app tables (agreements, transactions,
-- commissions, activities, ...) reference profiles, and profiles
-- reference auth.users — they cannot be seeded until a real auth
-- account exists. In local dev, sign up through the app (or the Auth
-- admin) first; handle_new_user() in triggers.sql mints the profile
-- row and the owner's business automatically. This file only seeds the
-- tables that stand alone.
--
-- Activation keys: the buyer's redemption-code flow
-- (signUp(redemptionCode:) → get_activation_key_by_code() →
-- handle_new_user()) looks codes up in this table. Redeemed keys are
-- marked in place by the signup path.

-- Job ids must match the app's category config (see
-- lib/config — yoga_studio, pilates_studio, meditation_teacher,
-- nutritionist, reiki_practitioner, strength_coach).

insert into public.activation_keys (key_code, job_id, business_name, primary_color) values
    ('ZEN-YOGA-777',   'yoga_studio',        'Lotus Flow Studio',     '#2471A3'),
    ('PIL-POWER-101',  'pilates_studio',     'Core Current Pilates',  '#16A085'),
    ('STILL-MIND-42',  'meditation_teacher', 'Stillwater Meditation', '#8E44AD'),
    ('NUTRI-PLATE-9',  'nutritionist',       'Green Plate Nutrition', '#27AE60'),
    ('REIKI-REST-3',   'reiki_practitioner', 'Reiki Rest Room',       '#D35400'),
    ('STRENGTH-5',     'strength_coach',     'Iron Harbor Strength',  '#C0392B')
on conflict (key_code) do nothing;

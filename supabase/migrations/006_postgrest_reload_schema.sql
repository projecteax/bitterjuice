-- Run this in Supabase SQL Editor if PostgREST still says a table is missing from the "schema cache"
-- after you created it (or you linked a new project). Safe to run anytime.

NOTIFY pgrst, 'reload schema';

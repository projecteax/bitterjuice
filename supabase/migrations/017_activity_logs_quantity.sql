-- =============================================================================
-- Activity logs: optional quantity (e.g., distance in km)
-- =============================================================================

alter table public.activity_logs
  add column if not exists quantity_value numeric,
  add column if not exists quantity_unit text;

-- Simple constraint: if one is set, both should be set
alter table public.activity_logs
  add constraint activity_logs_quantity_pair_check
    check (
      (quantity_value is null and (quantity_unit is null or quantity_unit = ''))
      or (quantity_value is not null and quantity_value >= 0 and quantity_unit is not null and quantity_unit <> '')
    )
    not valid;

alter table public.activity_logs
  validate constraint activity_logs_quantity_pair_check;

notify pgrst, 'reload schema';


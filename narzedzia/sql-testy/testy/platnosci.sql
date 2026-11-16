\set ON_ERROR_STOP 0
\pset tuples_only on
\set VERBOSITY terse
create schema t; grant usage on schema t to anon, authenticated, service_role;
create function t.expect(p_label text, p_sql text, p_code text) returns text language plpgsql as $$
begin
  execute p_sql;
  return 'FAIL ' || p_label || ' (no error, expected ' || p_code || ')';
exception when others then
  if sqlstate = p_code then return 'ok   ' || p_label || ' [' || sqlstate || ']';
  else return 'FAIL ' || p_label || ' [' || sqlstate || ': ' || sqlerrm || ']'; end if;
end $$;
grant execute on function t.expect(text, text, text) to anon, authenticated, service_role;
create function t.eq(p_label text, p_got anyelement, p_want anyelement) returns text language sql as $$
  select case when p_got is not distinct from p_want then 'ok   ' else 'FAIL ' end || p_label || ' = ' || coalesce(p_got::text, 'NULL')
$$;
grant execute on function t.eq(text, anyelement, anyelement) to anon, authenticated, service_role;
create function t.as_user(p_sub text, p_aal text) returns void language sql as $$
  select set_config('request.jwt.claim.sub', p_sub, false), set_config('request.jwt.claims', '{"aal":"' || p_aal || '"}', false);
$$;
grant execute on function t.as_user(text, text) to anon, authenticated, service_role;
create function t.h(p text) returns text language sql immutable as $$ select encode(digest(p, 'sha256'), 'hex') $$;
grant execute on function t.h(text) to anon, authenticated, service_role;

-- Supabase default: service_role has table privileges in public (stub lacks them); keep snippet's audit-log restriction
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage on all sequences in schema public to service_role;
revoke update, delete, truncate on client_audit_log from service_role;

-- ===================== fixtures =====================

-- ===================== fixtures (płatności za szkolenia, 00, D42) =====================
-- a = właściciel salonu A, e1 = pracownik A, b = właściciel salonu B, f1 = admin, f2 = agent,
-- c1 = właściciel organizatora 1, c3 = członek organizatora 1, c2 = właściciel organizatora 2, u1..u9 = pracownicy A
insert into auth.users values
 ('00000000-0000-0000-0000-00000000000a','ownera@example.com'), ('00000000-0000-0000-0000-00000000000b','ownerb@example.com'),
 ('00000000-0000-0000-0000-0000000000e1','empa@example.com'),   ('00000000-0000-0000-0000-0000000000f1','admin@example.com'),
 ('00000000-0000-0000-0000-0000000000f2','agent@example.com'),  ('00000000-0000-0000-0000-0000000000c1','org1@example.com'),
 ('00000000-0000-0000-0000-0000000000c2','org2@example.com'),   ('00000000-0000-0000-0000-0000000000c3','org1m@example.com');
insert into auth.users select ('00000000-0000-0000-0000-0000000001' || lpad(g::text, 2, '0'))::uuid, 'u' || g || '@example.com' from generate_series(1,9) g;
insert into admin_users(user_id, role) values ('00000000-0000-0000-0000-0000000000f1','admin'),('00000000-0000-0000-0000-0000000000f2','agent');
insert into client_accounts(id, display_name, nip, city) values ('aaaaaaaa-0000-0000-0000-000000000001','Salon Przykładowy A','9876543210','Kraków'),
                                                           ('bbbbbbbb-0000-0000-0000-000000000001','Salon Przykładowy B','1112223332','Gdańsk');
insert into client_policies(account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to, published_at)
 values ('aaaaaaaa-0000-0000-0000-000000000001','tax-protect','colonnade','Tax Protect','BP/2026/000123 (przykład)','active','2026-01-01','2026-12-31',now()),
        ('bbbbbbbb-0000-0000-0000-000000000001','tax-protect','colonnade','Tax Protect','BP/2026/000124 (przykład)','active','2026-01-01','2026-12-31',now());
select public.app_activate_client_account('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownera@example.com', t.h('tokA')) is not null;
select public.app_activate_client_account('bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownerb@example.com', t.h('tokB')) is not null;
select public.app_accept_invitation(t.h('tokA'),'00000000-0000-0000-0000-00000000000a','ownera@example.com') is not null;
select public.app_accept_invitation(t.h('tokB'),'00000000-0000-0000-0000-00000000000b','ownerb@example.com') is not null;
select public.app_create_invitation('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','empa@example.com','employee', t.h('tokE')) is not null;
select public.app_accept_invitation(t.h('tokE'),'00000000-0000-0000-0000-0000000000e1','empa@example.com') is not null;
insert into client_members(account_id, user_id, role, status)
 select 'aaaaaaaa-0000-0000-0000-000000000001', ('00000000-0000-0000-0000-0000000001' || lpad(g::text, 2, '0'))::uuid, 'employee', 'active'
   from generate_series(1,9) g;
insert into training_organizers(id, kind, display_name, legal_name, nip, city, status, verified_at, verified_by, terms_version) values
 ('eeeeeeee-0000-0000-0000-000000000001','firma','Organizator przykładowy','Organizator Przykładowy sp. z o.o.','5556667776','Kraków','active',now(),'00000000-0000-0000-0000-0000000000f1','org-v1'),
 ('eeeeeeee-0000-0000-0000-000000000002','firma','Inny organizator (przykład)','Inny Organizator s.c.','7778889998','Gdańsk','active',now(),'00000000-0000-0000-0000-0000000000f1','org-v1');
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','org1@example.com','owner',t.h('tokO1')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO1'),'00000000-0000-0000-0000-0000000000c1','org1@example.com') is not null;
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','org1m@example.com','member',t.h('tokO3')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO3'),'00000000-0000-0000-0000-0000000000c3','org1m@example.com') is not null;
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000f1','org2@example.com','owner',t.h('tokO2')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO2'),'00000000-0000-0000-0000-0000000000c2','org2@example.com') is not null;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','promo-12m',now(),'FV/2026/11/001 (przykład)') is not null;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000f2','promo-12m',now(),'FV/2026/11/002 (przykład)') is not null;

\set terms '{"seller_legal_name":"Organizator Przykładowy sp. z o.o.","seller_address":"ul. Przykładowa 1, 30-001 Kraków","seller_nip":"5556667776","seller_register":"KRS 0000000000 (przykład)","seller_email":"szkolenia@example.com","seller_phone":"+48 000 000 000","cancellation_rules":"Rezygnacja do 14 dni przed szkoleniem – zwrot całości; później – zwrot 50 procent ceny (przykład).","withdrawal_info":"Konsument może odstąpić od umowy w terminie 14 dni, z wyjątkami dla usług z określonym terminem (przykład).","complaint_info":"Reklamacje rozpatrujemy w terminie 14 dni od otrzymania (przykład).","terms_body":"Regulamin szkoleń organizatora przykładowego. Sprzedawcą jest organizator. Portal BeautyPolisa nie jest stroną umowy. Płatność obsługuje operator płatności. Faktury wystawia organizator. Szczegóły organizacyjne przekazujemy po zapisie (przykład)."}'
\set osoba '{"buyer_kind":"osoba","buyer_name":"Anna Przykładowa","invoice_email":"anna@example.com"}'
\set firma '{"buyer_kind":"firma","buyer_name":"Salon Przykładowy A sp. z o.o.","nip":"9876543210","street":"ul. Przykładowa 2","postal_code":"30-001","city":"Kraków","invoice_email":"faktury@example.com"}'

-- szkolenie płatne online (450 zł, 2 miejsca) i drugie do testu równoległego (1 miejsce)
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity, per_account_limit,
                      price_kind, price_gross_pln, payment_mode)
 values ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Stylizacja brwi (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '20 days', now()+interval '20 days 4 hours', 2, 10, 'platne', 450.00, 'online'),
        ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Laminacja rzęs (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '21 days', now()+interval '21 days 4 hours', 1, 10, 'platne', 300.00, 'online');
reset role;
select id as t1 from trainings where title like 'Stylizacja%' \gset
select id as t2 from trainings where title like 'Laminacja%' \gset

-- ===================== 1. Wypłaty, warunki sprzedaży, publikacja =====================
select '--- 1. payouts, sales terms, publish ---';
set role service_role;
select t.expect('publish online training without payouts and terms', format($q$select public.app_moderate_training(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'t1'), 'P0001');
select t.expect('payout register by organiser member (not owner)', $q$select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c3','stripe','acct_TEST1')$q$, 'P0001');
select t.expect('payout register bad provider', $q$select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','paypal','acct_TEST1')$q$, 'BP422');
select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','stripe','acct_TEST1') as pa1 \gset
select t.eq('payout register idempotent', public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','stripe','acct_TEST1'), :'pa1'::uuid);
select t.expect('payout account of org 1 claimed by org 2', $q$select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000c2','stripe','acct_TEST1')$q$, 'P0001');
select t.eq('payout status from operator: requirements due -> onboarding', public.app_payout_account_set_status('stripe','acct_TEST1', true, false, true), 'onboarding');
select t.expect('sales terms by member', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c3',%L)$q$, :'terms'), 'P0001');
select t.expect('sales terms NIP other than verified profile (DSA art. 30)', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1',%L)$q$, jsonb_set(:'terms'::jsonb, '{seller_nip}', '"1112223332"')), 'BP422');
select t.expect('sales terms with URL', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1',%L)$q$, jsonb_set(:'terms'::jsonb, '{complaint_info}', '"Reklamacje: https://example.com/reklamacje (przykład)"')), 'BP422');
select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1', :'terms') as st1 \gset
select t.expect('second terms version while first pending', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1',%L)$q$, :'terms'), 'BP409');
select t.expect('terms approved by organiser', format($q$select public.app_sales_terms_moderate(%L,'00000000-0000-0000-0000-0000000000c1','approve')$q$, :'st1'), 'P0001');
select public.app_sales_terms_moderate(:'st1','00000000-0000-0000-0000-0000000000f2','approve');
select t.expect('publish with payouts still onboarding', format($q$select public.app_moderate_training(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'t1'), 'P0001');
select t.eq('payout status from operator: active', public.app_payout_account_set_status('stripe','acct_TEST1', true, true, false), 'active');
select t.expect('publish during payout cooldown (karencja 72 h)', format($q$select public.app_moderate_training(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'t1'), 'P0001');
reset role;
select t.eq('cooldown: usable_from = activation + 72 h', (select usable_from - activated_at from organizer_payout_accounts where provider_account_ref = 'acct_TEST1'), interval '72 hours');
update organizer_payout_accounts set usable_from = now() - interval '1 minute' where provider_account_ref = 'acct_TEST1';  -- karencja minęła
set role service_role;
select public.app_moderate_training(:'t1','00000000-0000-0000-0000-0000000000f2','publish',1);
select public.app_moderate_training(:'t2','00000000-0000-0000-0000-0000000000f2','publish',1);
reset role;
select t.eq('training published', (select status from trainings where id = :'t1'), 'published');
select t.eq('audit: payout_account_status_changed x2', (select count(*) from client_audit_log where action = 'payout_account_status_changed'), 1::bigint);

-- ===================== 2. zamówienie: kwota z bazy, idempotencja, brak nadsprzedaży =====================
select '--- 2. order create ---';
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.expect('authenticated cannot EXECUTE app_training_order_create', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),%L,'Anna Przykładowa','ownera@example.com',%L,'sprz-v1')$q$, :'t1', :'st1', :'osoba'), '42501');
select t.expect('authenticated cannot EXECUTE app_payment_webhook', $q$select public.app_payment_webhook('stripe','evt_x','payment.succeeded','pi_x',null,null,1,'PLN',repeat('0',64))$q$, '42501');
reset role;
set role service_role;
select t.expect('order by non-member (organiser c2 for salon A)', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-0000000000c2','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),%L,'Ktoś Przykładowy','org2@example.com',%L,'sprz-v1')$q$, :'t1', :'st1', :'osoba'), 'P0001');
select t.expect('firma with invalid NIP (BP422, no value)', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),%L,'Anna Przykładowa','ownera@example.com',%L,'sprz-v1')$q$, :'t1', :'st1', jsonb_set(:'firma'::jsonb,'{nip}','"9876543211"')), 'BP422');
select t.expect('firma without address', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),%L,'Anna Przykładowa','ownera@example.com',%L,'sprz-v1')$q$, :'t1', :'st1', (:'firma'::jsonb - 'street')), 'BP422');
select t.expect('stale sales terms version', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),gen_random_uuid(),'Anna Przykładowa','ownera@example.com',%L,'sprz-v1')$q$, :'t1', :'osoba'), 'BP409');
select t.expect('free-style register on online training (app_training_register)', format($q$select public.app_training_register(%L,'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','Anna Przykładowa','ownera@example.com','info-v1')$q$, :'t1'), 'BP409');
select order_id as oa, amount_grosze as oa_amount, platform_fee_grosze as oa_fee, created as oa_created
  from public.app_training_order_create(:'t1','00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001',
       '11111111-1111-1111-1111-111111111111', :'st1','Anna Przykładowa','ownera@example.com', :'firma','sprz-v1') \gset
select t.eq('amount from DB (450.00 zł -> 45000 gr)', :'oa_amount'::integer, 45000);
select t.eq('platform fee 0 during promotion (00, D42)', :'oa_fee'::integer, 0);
select t.eq('order created', :'oa_created'::boolean, true);
select t.eq('idempotent: same key -> same order, created=false',
  (select order_id::text || '/' || created from public.app_training_order_create(:'t1','00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001',
       '11111111-1111-1111-1111-111111111111', :'st1','Anna Przykładowa','ownera@example.com', :'firma','sprz-v1')), :'oa' || '/false');
select t.eq('second tab (new key, active reservation) -> same order',
  (select order_id from public.app_training_order_create(:'t1','00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','Anna Przykładowa','ownera@example.com', :'firma','sprz-v1')), :'oa'::uuid);
select t.expect('same key reused for other training', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111',%L,'Anna Przykładowa','ownera@example.com',%L,'sprz-v1')$q$, :'t2', :'st1', :'osoba'), 'BP409');
-- przeglądarka „podsuwa” kwotę – funkcja nie ma takiego parametru, a pole w p_buyer jest ignorowane
select order_id as oe, amount_grosze as oe_amount
  from public.app_training_order_create(:'t1','00000000-0000-0000-0000-0000000000e1','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','Ewa Przykładowa','empa@example.com', (:'osoba'::jsonb || '{"amount_grosze":100,"price_gross_pln":1}'), 'sprz-v1') \gset
select t.eq('amount ignores client-supplied fields', :'oe_amount'::integer, 45000);
reset role;
select t.eq('seats_held = 2 (two reservations), seats_registered = 0', (select seats_held || '/' || seats_registered from trainings where id = :'t1'), '2/0');
set role service_role;
select t.expect('third buyer – no seats (no oversell)', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-000000000101','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),%L,'U1 Przykładowy','u1@example.com',%L,'sprz-v1')$q$, :'t1', :'st1', :'osoba'), 'BP409');
reset role;
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
select t.expect('organiser changes price with open reservations', format($q$update trainings set price_gross_pln = 1.00 where id = %L$q$, :'t1'), 'P0001');
select t.expect('organiser cannot touch seats_held (no grant)', format($q$update trainings set seats_held = 0 where id = %L$q$, :'t1'), '42501');
reset role;
select t.eq('audit: training_order_created x2', (select count(*) from client_audit_log where action = 'training_order_created'), 2::bigint);

-- ===================== 3. wygasanie rezerwacji =====================
select '--- 3. reservation expiry ---';
update training_orders set reserved_until = now() - interval '1 second' where id = :'oe';
set role service_role;
select t.eq('cron: 1 reservation expired', public.app_expire_training_orders(), 1);
reset role;
select t.eq('expired order + seat released', (select o.status || '/' || t.seats_held from training_orders o join trainings t on t.id = o.training_id where o.id = :'oe'), 'expired/1');
select t.eq('audit: reserved -> expired (system actor)', (select actor from client_audit_log where entity_id = :'oe' and action = 'training_order_status_changed' and payload->>'to' = 'expired'), 'system:reservation-expiry');
set role service_role;
select order_id as ou1 from public.app_training_order_create(:'t1','00000000-0000-0000-0000-000000000101','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','U1 Przykładowy','u1@example.com', :'osoba','sprz-v1') \gset
select t.eq('freed seat can be ordered again', (select status from training_orders where id = :'ou1'), 'reserved');
select t.expect('attach payment to someone else''s order', format($q$select public.app_training_payment_attach(%L,'00000000-0000-0000-0000-00000000000a','stripe','pi_U1','2030-01-01')$q$, :'ou1'), 'P0001');
select public.app_training_payment_attach(:'ou1','00000000-0000-0000-0000-000000000101','stripe','pi_U1', now() + interval '15 minutes') as pu1 \gset
reset role;
update training_orders set reserved_until = now() - interval '1 second' where id = :'ou1';
set role service_role;
select order_id as ou2 from public.app_training_order_create(:'t1','00000000-0000-0000-0000-000000000102','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','U2 Przykładowy','u2@example.com', :'osoba','sprz-v1') \gset
reset role;
select t.eq('lazy expiry inside order_create (u1 expired, u2 reserved)', (select string_agg(status, ',' order by created_at) from training_orders where id in (:'ou1', :'ou2')), 'expired,reserved');
select t.eq('seats_held after lazy expiry', (select seats_held from trainings where id = :'t1'), 2);
set role service_role;
select t.expect('attach payment after reservation expired', format($q$select public.app_training_payment_attach(%L,'00000000-0000-0000-0000-000000000101','stripe','pi_U1b',now())$q$, :'ou1'), 'BP409');
reset role;

-- ===================== 4. webhook: podpisane zdarzenie, kwota/waluta/zamówienie, idempotencja, kolejność =====================
select '--- 4. webhook ---';
set role service_role;
select public.app_training_payment_attach(:'oa','00000000-0000-0000-0000-00000000000a','stripe','pi_A1', now() + interval '15 minutes') as pa \gset
select t.eq('payment attach idempotent', public.app_training_payment_attach(:'oa','00000000-0000-0000-0000-00000000000a','stripe','pi_A1', now()), :'pa'::uuid);
select t.expect('webhook: invalid event type', $q$select public.app_payment_webhook('stripe','evt_bad','payment.whatever','pi_A1',null,null,45000,'PLN',repeat('0',64))$q$, 'BP422');
select t.eq('webhook: unknown payment ref', public.app_payment_webhook('stripe','evt_unk','payment.succeeded','pi_NOPE',null,null,45000,'PLN',t.h('u')), 'unknown_ref');
select t.eq('webhook: amount mismatch rejected', public.app_payment_webhook('stripe','evt_a1','payment.succeeded','pi_A1',null,:'oa',44999,'PLN',t.h('a1')), 'rejected_mismatch');
select t.eq('webhook: currency mismatch rejected', public.app_payment_webhook('stripe','evt_a2','payment.succeeded','pi_A1',null,:'oa',45000,'EUR',t.h('a2')), 'rejected_mismatch');
select t.eq('webhook: order id in metadata mismatch rejected', public.app_payment_webhook('stripe','evt_a3','payment.succeeded','pi_A1',null,:'ou2',45000,'PLN',t.h('a3')), 'rejected_mismatch');
reset role;
select t.eq('order still reserved after rejected events', (select status from training_orders where id = :'oa'), 'reserved');
select t.eq('discrepancies opened (unknown, amount, currency, order)', (select string_agg(kind, ',' order by kind) from payment_discrepancies), 'amount_mismatch,currency_mismatch,order_mismatch,unknown_payment');
set role service_role;
select t.eq('webhook: payment.succeeded -> paid', public.app_payment_webhook('stripe','evt_a4','payment.succeeded','pi_A1',null,:'oa',45000,'PLN',t.h('a4'),now(),'blik'), 'paid');
select t.eq('webhook: same event again -> duplicate', public.app_payment_webhook('stripe','evt_a4','payment.succeeded','pi_A1',null,:'oa',45000,'PLN',t.h('a4'),now(),'blik'), 'duplicate');
select t.eq('webhook: same success, new event id -> ignored_stale', public.app_payment_webhook('stripe','evt_a5','payment.succeeded','pi_A1',null,:'oa',45000,'PLN',t.h('a5')), 'ignored_stale');
select t.eq('webhook: failed after succeeded (out of order) -> ignored_stale', public.app_payment_webhook('stripe','evt_a6','payment.failed','pi_A1',null,:'oa',45000,'PLN',t.h('a6')), 'ignored_stale');
reset role;
select t.eq('order paid, payment succeeded (blik)', (select o.status || '/' || p.status || '/' || p.method from training_orders o join training_payments p on p.order_id = o.id where o.id = :'oa'), 'paid/succeeded/blik');
select t.eq('registration registered + contact snapshot (salon name for firma)', (select r.status || '/' || c.salon_name from training_orders o join training_registrations r on r.id = o.registration_id join training_participant_contacts c on c.registration_id = r.id where o.id = :'oa'), 'registered/Salon Przykładowy A sp. z o.o.');
select t.eq('counters: held 1 (u2), registered 1', (select seats_held || '/' || seats_registered from trainings where id = :'t1'), '1/1');
select t.eq('audit reserved->paid by system:webhook:stripe', (select actor from client_audit_log where entity_id = :'oa' and payload->>'to' = 'paid'), 'system:webhook:stripe');
select t.eq('outbox training_order_paid to user:<uuid>', (select recipient from outbox_emails where template = 'training_order_paid'), 'user:00000000-0000-0000-0000-00000000000a');
select t.eq('webhook events stored without raw payload (columns)', (select count(*) from information_schema.columns where table_name = 'payment_webhook_events' and column_name in ('payload','raw','body')), 0::bigint);

-- spóźniona płatność bez miejsca → zwrot automatyczny; z wolnym miejscem → zapis
set role service_role;
select public.app_training_payment_attach(:'ou2','00000000-0000-0000-0000-000000000102','stripe','pi_U2', now()) as pu2 \gset
reset role;
update training_orders set reserved_until = now() - interval '1 second' where id = :'ou2';
set role service_role;
select public.app_expire_training_orders() >= 1;
select order_id as ou3 from public.app_training_order_create(:'t1','00000000-0000-0000-0000-000000000103','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','U3 Przykładowy','u3@example.com', :'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'ou3','00000000-0000-0000-0000-000000000103','stripe','pi_U3', now()) is not null;
select t.eq('u3 paid (training now full)', public.app_payment_webhook('stripe','evt_u3','payment.succeeded','pi_U3',null,:'ou3',45000,'PLN',t.h('u3')), 'paid');
select t.eq('late payment of expired u2, no seat -> refund_required', public.app_payment_webhook('stripe','evt_u2','payment.succeeded','pi_U2',null,:'ou2',45000,'PLN',t.h('u2')), 'refund_required');
reset role;
select t.eq('u2 order refund_pending (spozniona-platnosc) + refund requested', (select o.status || '/' || o.refund_reason || '/' || r.status || '/' || r.amount_grosze from training_orders o join training_refunds r on r.order_id = o.id where o.id = :'ou2'), 'refund_pending/spozniona-platnosc/requested/45000');
select t.eq('no oversell after late payment', (select seats_registered || '/' || capacity from trainings where id = :'t1'), '2/2');
select t.eq('discrepancy late_payment_no_seat', (select count(*) from payment_discrepancies where kind = 'late_payment_no_seat' and order_id = :'ou2'), 1::bigint);
set role service_role;
select t.eq('capacity 2 -> 4 by organiser', public.app_training_set_capacity(:'t1','00000000-0000-0000-0000-0000000000c1',4), 0);
select order_id as ou4 from public.app_training_order_create(:'t1','00000000-0000-0000-0000-000000000104','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','U4 Przykładowy','u4@example.com', :'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'ou4','00000000-0000-0000-0000-000000000104','stripe','pi_U4', now()) is not null;
reset role;
update training_orders set reserved_until = now() - interval '1 second' where id = :'ou4';
set role service_role;
select public.app_expire_training_orders() = 1;
select t.eq('late payment with free seat -> paid_late', public.app_payment_webhook('stripe','evt_u4','payment.succeeded','pi_U4',null,:'ou4',45000,'PLN',t.h('u4')), 'paid_late');
-- podwójna płatność: dwie sesje tego samego zamówienia
select order_id as ou5 from public.app_training_order_create(:'t1','00000000-0000-0000-0000-000000000105','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','U5 Przykładowy','u5@example.com', :'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'ou5','00000000-0000-0000-0000-000000000105','stripe','pi_U5a', now()) is not null;
select public.app_training_payment_attach(:'ou5','00000000-0000-0000-0000-000000000105','stripe','pi_U5b', now()) is not null;
select t.eq('u5 first session paid', public.app_payment_webhook('stripe','evt_u5a','payment.succeeded','pi_U5a',null,:'ou5',45000,'PLN',t.h('u5a')), 'paid');
select t.eq('u5 second session also paid -> refund_required (double)', public.app_payment_webhook('stripe','evt_u5b','payment.succeeded','pi_U5b',null,:'ou5',45000,'PLN',t.h('u5b')), 'refund_required');
reset role;
select t.eq('u5 stays paid, duplicate refund requested', (select o.status || '/' || r.reason from training_orders o join training_refunds r on r.order_id = o.id where o.id = :'ou5'), 'paid/podwojna-platnosc');
select t.eq('counters after paid/late/double: held 0, registered 4', (select seats_held || '/' || seats_registered from trainings where id = :'t1'), '0/4');
set role service_role;
select t.expect('u5 orders again after paying (already paid)', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-000000000105','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),%L,'U5 Przykładowy','u5@example.com',%L,'sprz-v1')$q$, :'t1', :'st1', :'osoba'), 'BP409');
reset role;

-- ===================== 5. zwroty (inicjuje organizator, wykonuje operator) =====================
select '--- 5. refunds ---';
set role service_role;
select t.expect('refund by organiser member (not owner)', format($q$select public.app_training_refund_request(%L,'00000000-0000-0000-0000-0000000000c3',10000,'rezygnacja',false)$q$, :'oa'), 'P0001');
select t.expect('refund by other organiser', format($q$select public.app_training_refund_request(%L,'00000000-0000-0000-0000-0000000000c2',10000,'rezygnacja',false)$q$, :'oa'), 'P0001');
select t.expect('refund by staff (money of organiser)', format($q$select public.app_training_refund_request(%L,'00000000-0000-0000-0000-0000000000f1',10000,'rezygnacja',false)$q$, :'oa'), 'P0001');
select t.expect('refund above paid amount', format($q$select public.app_training_refund_request(%L,'00000000-0000-0000-0000-0000000000c1',45001,'rezygnacja',false)$q$, :'oa'), 'BP422');
select public.app_training_refund_request(:'oa','00000000-0000-0000-0000-0000000000c1',10000,'rezygnacja',false) as ra1 \gset
select t.expect('second refund while first in progress', format($q$select public.app_training_refund_request(%L,'00000000-0000-0000-0000-0000000000c1',1000,'rezygnacja',false)$q$, :'oa'), 'BP409');
select t.eq('refund attach -> submitted', public.app_training_refund_attach(:'ra1','re_A1'), 'submitted');
select t.eq('refund attach repeated -> idempotent', public.app_training_refund_attach(:'ra1','re_A1'), 'submitted');
select t.eq('refund.succeeded wrong amount -> rejected', public.app_payment_webhook('stripe','evt_r0','refund.succeeded','re_A1','pi_A1',:'oa',9999,'PLN',t.h('r0')), 'rejected_mismatch');
select t.eq('refund.succeeded partial', public.app_payment_webhook('stripe','evt_r1','refund.succeeded','re_A1','pi_A1',:'oa',10000,'PLN',t.h('r1')), 'partially_refunded');
select t.eq('refund event duplicate', public.app_payment_webhook('stripe','evt_r1','refund.succeeded','re_A1','pi_A1',:'oa',10000,'PLN',t.h('r1')), 'duplicate');
reset role;
select t.eq('partial refund keeps seat', (select o.status || '/' || o.refunded_grosze || '/' || r.status from training_orders o join training_registrations r on r.id = o.registration_id where o.id = :'oa'), 'partially_refunded/10000/registered');
set role service_role;
select public.app_training_refund_request(:'oa','00000000-0000-0000-0000-0000000000c1',35000,'rezygnacja',true) as ra2 \gset
reset role;
select t.eq('full refund with cancellation releases seat at once', (select seats_registered from trainings where id = :'t1'), 3);
set role service_role;
select t.eq('refund webhook faster than attach -> matched to pending refund', public.app_payment_webhook('stripe','evt_r2','refund.succeeded','re_A2','pi_A1',:'oa',35000,'PLN',t.h('r2')), 'refunded');
select t.eq('attach after webhook -> idempotent status', public.app_training_refund_attach(:'ra2','re_A2'), 'succeeded');
reset role;
select t.eq('order refunded 45000', (select status || '/' || refunded_grosze from training_orders where id = :'oa'), 'refunded/45000');
set role service_role;
select (select id from training_refunds where order_id = :'ou5' and reason = 'podwojna-platnosc') as rdup \gset
select t.eq('duplicate payment refund attach', public.app_training_refund_attach(:'rdup','re_U5b'), 'submitted');
select t.eq('duplicate payment refunded, order stays paid', public.app_payment_webhook('stripe','evt_r3','refund.succeeded','re_U5b','pi_U5b',:'ou5',45000,'PLN',t.h('r3')), 'refunded_duplicate');
select t.eq('refund.failed unknown ref', public.app_payment_webhook('stripe','evt_r4','refund.failed','re_NOPE','pi_U5a',null,45000,'PLN',t.h('r4')), 'unknown_ref');
select t.eq('external refund from operator panel recorded', public.app_payment_webhook('stripe','evt_r5','refund.succeeded','re_EXT','pi_U4',:'ou4',5000,'PLN',t.h('r5')), 'partially_refunded');
reset role;
select t.eq('u5 status after duplicate refund', (select status from training_orders where id = :'ou5'), 'paid');
select t.eq('discrepancy external_refund', (select count(*) from payment_discrepancies where kind = 'external_refund'), 1::bigint);

-- ===================== 6. rezygnacja uczestnika i odwołanie szkolenia =====================
select '--- 6. cancel request, event cancelled ---';
set role service_role;
select t.expect('paid seat cannot be cancelled by app_training_cancel', format($q$select public.app_training_cancel(%L,'00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000103')$q$, :'t1'), 'BP409');
select t.expect('cancel request for someone else''s order', format($q$select public.app_training_order_cancel_request(%L,'00000000-0000-0000-0000-000000000104')$q$, :'ou3'), 'P0001');
select public.app_training_order_cancel_request(:'ou3','00000000-0000-0000-0000-000000000103');
select public.app_training_order_cancel_request(:'ou3','00000000-0000-0000-0000-000000000103');
reset role;
select t.eq('cancel request recorded once', (select count(*) from client_audit_log where action = 'training_order_cancel_requested' and entity_id = :'ou3'), 1::bigint);
select t.eq('outbox to organizer:<uuid>', (select count(*) from outbox_emails where template = 'training_order_cancel_requested' and recipient = 'organizer:eeeeeeee-0000-0000-0000-000000000001'), 1::bigint);
set role service_role;
select order_id as ou6 from public.app_training_order_create(:'t1','00000000-0000-0000-0000-000000000106','aaaaaaaa-0000-0000-0000-000000000001',
       gen_random_uuid(), :'st1','U6 Przykładowy','u6@example.com', :'osoba','sprz-v1') \gset
select public.app_training_cancel_event(:'t1','00000000-0000-0000-0000-0000000000c1','Choroba prowadzącej (przykład)');
reset role;
select t.eq('cancel event: open reservation cancelled', (select status from training_orders where id = :'ou6'), 'cancelled');
select t.eq('cancel event: refunds odwolanie for u3, u4 (rest), u5', (select string_agg(o.order_ref is not null || ':' || r.amount_grosze, ',' order by r.amount_grosze) from training_refunds r join training_orders o on o.id = r.order_id where r.reason = 'odwolanie'), 'true:40000,true:45000,true:45000');
select t.eq('cancel event: counters zeroed', (select seats_held || '/' || seats_registered from trainings where id = :'t1'), '0/0');
select t.eq('cancel event: orders refund_pending', (select count(*) from training_orders where training_id = :'t1' and status = 'refund_pending'), 4::bigint);
select t.eq('cancel event: e-mails training_cancelled_refund', (select count(*) from outbox_emails where template = 'training_cancelled_refund'), 3::bigint);
set role service_role;
select t.expect('order on cancelled training', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-000000000107','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),%L,'U7 Przykładowy','u7@example.com',%L,'sprz-v1')$q$, :'t1', :'st1', :'osoba'), 'BP409');
reset role;

-- ===================== 7. RLS i Data API =====================
select '--- 7. RLS ---';
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000a','aal1');
select t.eq('buyer A sees own orders only', (select count(*) from training_orders), 1::bigint);
select t.eq('buyer A sees own buyer data', (select count(*) from training_order_buyer_data), 1::bigint);
select t.expect('buyer cannot read user_id', 'select user_id from training_orders', '42501');
select t.expect('buyer cannot read idempotency_key', 'select idempotency_key from training_orders', '42501');
select t.expect('buyer cannot insert order (no grant)', format($q$insert into training_orders(order_ref, training_id) values ('SZ-2611-00000000', %L)$q$, :'t1'), '42501');
select t.expect('buyer cannot update amount', 'update training_orders set amount_grosze = 1', '42501');
select t.eq('buyer sees 0 payments/refunds/webhooks', (select count(*) from training_payments) + (select count(*) from training_refunds) + (select count(*) from payment_webhook_events), 0::bigint);
select t.as_user('00000000-0000-0000-0000-000000000103','aal1');
select t.eq('buyer u3 sees own order', (select count(*) from training_orders), 1::bigint);
select t.as_user('00000000-0000-0000-0000-00000000000b','aal2');
select t.eq('owner B sees 0 orders', (select count(*) from training_orders), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
select t.eq('organiser: 0 orders, 0 buyer data via Data API (only functions)', (select count(*) from training_orders) + (select count(*) from training_order_buyer_data), 0::bigint);
select t.eq('organiser sees own payout account status', (select status from organizer_payout_accounts), 'active');
select t.expect('organiser cannot read provider_account_ref', 'select provider_account_ref from organizer_payout_accounts', '42501');
select t.eq('organiser sees fee setting 0', (select fee_bps from platform_fee_settings), 0::smallint);
select t.as_user('00000000-0000-0000-0000-0000000000c2','aal2');
select t.eq('other organiser: 0 payout accounts', (select count(*) from organizer_payout_accounts), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000f1','aal2');
select t.eq('staff (aal2) sees all orders', (select count(*) from training_orders) > 5, true);
select t.eq('staff sees 0 buyer data (minimisation)', (select count(*) from training_order_buyer_data), 0::bigint);
select t.eq('staff sees webhook events and discrepancies', (select count(*) from payment_webhook_events) > 0 and (select count(*) from payment_discrepancies) > 0, true);
select t.as_user('00000000-0000-0000-0000-0000000000f1','aal1');
select t.eq('staff with aal1 sees 0 orders', (select count(*) from training_orders), 0::bigint);
reset role;
set role anon;
select t.expect('anon: training_orders', 'select count(*) from training_orders', '42501');
select t.expect('anon: platform_fee_settings', 'select count(*) from platform_fee_settings', '42501');
select t.eq('anon: active sales terms public (seller data, DSA art. 30)', (select seller_nip from organizer_sales_terms), '5556667776');
select t.eq('anon: catalogue shows payment_mode', (select payment_mode from trainings where id = :'t2'), 'online');
reset role;
set role service_role;
select t.eq('organiser order list via function (paid/refund states only: A, u2..u5)', (select count(*) from public.app_organizer_training_orders(:'t1','00000000-0000-0000-0000-0000000000c1')), 5::bigint);
select t.expect('other organiser order list', format($q$select * from public.app_organizer_training_orders(%L,'00000000-0000-0000-0000-0000000000c2')$q$, :'t1'), 'P0001');
select t.eq('invoice data via function (firma NIP)', (select nip from public.app_organizer_invoice_data(:'oa','00000000-0000-0000-0000-0000000000c3')), '9876543210');
select t.expect('invoice data for unpaid (expired) order', format($q$select * from public.app_organizer_invoice_data(%L,'00000000-0000-0000-0000-0000000000c1')$q$, :'oe'), 'P0001');
select t.expect('invoice path outside order folder', format($q$select public.app_training_order_invoice_attach(%L,'00000000-0000-0000-0000-0000000000c1','FV/1/2026','aaaaaaaa-0000-0000-0000-000000000001/%s/11111111-1111-1111-1111-111111111111.pdf',%L)$q$, :'ou3', :'ou3', repeat('a',64)), 'BP422');
select public.app_training_order_invoice_attach(:'ou3','00000000-0000-0000-0000-0000000000c1','FV/1/2026 (przykład)',
       'eeeeeeee-0000-0000-0000-000000000001/' || :'ou3' || '/11111111-1111-1111-1111-111111111111.pdf', repeat('a',64));
select t.eq('buyer gets invoice path', public.app_training_invoice_path(:'ou3','00000000-0000-0000-0000-000000000103') like 'eeeeeeee-%', true);
select t.expect('other user cannot get invoice path', format($q$select public.app_training_invoice_path(%L,'00000000-0000-0000-0000-000000000104')$q$, :'ou3'), 'P0001');
reset role;
select t.eq('audit: organizer_orders_viewed + invoice_data_viewed', (select count(*) from client_audit_log where action in ('organizer_orders_viewed','organizer_invoice_data_viewed')), 2::bigint);

-- ===================== 8. prowizja jako parametr =====================
select '--- 8. platform fee ---';
set role service_role;
select t.expect('fee changed by agent', $q$select public.app_set_platform_fee('00000000-0000-0000-0000-0000000000f2',500,0,now()+interval '1 day','decyzja testowa (przykład)')$q$, 'P0001');
select t.expect('fee > 0 during promotion (00, D42)', $q$select public.app_set_platform_fee('00000000-0000-0000-0000-0000000000f1',500,0,now()+interval '1 day','decyzja testowa (przykład)')$q$, 'BP409');
select t.expect('fee backdated', $q$select public.app_set_platform_fee('00000000-0000-0000-0000-0000000000f1',0,0,now()-interval '1 day','decyzja testowa (przykład)')$q$, 'BP422');
reset role;
update app_promotions set ends_at = now() + interval '2 days';
set role service_role;
select t.eq('fee 5 % after promotion end accepted', public.app_set_platform_fee('00000000-0000-0000-0000-0000000000f1',500,0,now()+interval '3 days','decyzja testowa po promocji (przykład)') is not null, true);
select t.eq('order now still 0 fee (snapshot, promotion active)', (select platform_fee_grosze from public.app_training_order_create(:'t2','00000000-0000-0000-0000-000000000108','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),:'st1','U8 Przykładowy','u8@example.com',:'osoba','sprz-v1')), 0);
select t.eq('fee in effect at +4 days = 500 bps', (public.platform_fee_current(now()+interval '4 days')).fee_bps, 500::smallint);
reset role;
update app_promotions set ends_at = null;

-- ===================== 9. kontrola spójności i retencja =====================
select '--- 9. health, retention ---';
set role service_role;
select t.eq('health: seat counters consistent', (select n from public.app_payment_health() where check_name = 'seat_counter'), 0::bigint);
select t.eq('health: paid without registration', (select n from public.app_payment_health() where check_name = 'paid_without_registration'), 0::bigint);
reset role;
update trainings set starts_at = now() - interval '14 months', ends_at = now() - interval '14 months' + interval '4 hours' where id = :'t1';
update training_refunds set status = 'succeeded', succeeded_at = now() where status in ('requested','submitted');
update training_orders set status = 'refunded', refunded_grosze = amount_grosze where status = 'refund_pending';
set role service_role;
select t.eq('retention runs', public.app_purge_training_orders() > 0, true);
reset role;
select t.eq('buyer data of paid t1 orders removed 90 days after training', (select count(*) from training_order_buyer_data b join training_orders o on o.id = b.order_id where o.training_id = :'t1' and o.status not in ('expired','cancelled')), 0::bigint);
select t.eq('buyer data of unpaid orders kept < 7 days', (select count(*) from training_order_buyer_data b join training_orders o on o.id = b.order_id where o.training_id = :'t1'), 3::bigint);
update training_orders set created_at = now() - interval '8 days' where training_id = :'t1' and status in ('expired','cancelled');
set role service_role;
select public.app_purge_training_orders() >= 0;
reset role;
select t.eq('buyer data of unpaid orders removed after 7 days', (select count(*) from training_order_buyer_data b join training_orders o on o.id = b.order_id where o.training_id = :'t1'), 0::bigint);
select t.eq('t1 orders anonymised (no user/account)', (select count(*) from training_orders where training_id = :'t1' and (user_id is not null or account_id is not null)), 0::bigint);
select t.eq('financial record kept (amounts)', (select count(*) from training_orders where training_id = :'t1' and amount_grosze = 45000), 8::bigint);

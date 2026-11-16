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
reset role;
update organizer_payout_accounts set usable_from = now() - interval '1 minute' where provider_account_ref = 'acct_TEST1';  -- karencja minęła
set role service_role;
select public.app_moderate_training(:'t1','00000000-0000-0000-0000-0000000000f2','publish',1);
select public.app_moderate_training(:'t2','00000000-0000-0000-0000-0000000000f2','publish',1);
reset role;
select t.eq('training published', (select status from trainings where id = :'t1'), 'published');
select t.eq('audit: payout_account_status_changed x2', (select count(*) from client_audit_log where action = 'payout_account_status_changed'), 1::bigint);


-- ===================== PRZEGLĄD RED TEAM PŁATNOŚCI (13.11.2026) – testy poprawek =====================
\set U1 '00000000-0000-0000-0000-000000000101'
\set U2 '00000000-0000-0000-0000-000000000102'
\set U3 '00000000-0000-0000-0000-000000000103'
\set U4 '00000000-0000-0000-0000-000000000104'
\set U5 '00000000-0000-0000-0000-000000000105'
\set U6 '00000000-0000-0000-0000-000000000106'
\set U7 '00000000-0000-0000-0000-000000000107'
\set U8 '00000000-0000-0000-0000-000000000108'
\set U9 '00000000-0000-0000-0000-000000000109'
\set A  'aaaaaaaa-0000-0000-0000-000000000001'
\set ORG1 'eeeeeeee-0000-0000-0000-000000000001'
\set C1 '00000000-0000-0000-0000-0000000000c1'
\set C3 '00000000-0000-0000-0000-0000000000c3'
\set F1 '00000000-0000-0000-0000-0000000000f1'
\set F2 '00000000-0000-0000-0000-0000000000f2'
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity, per_account_limit,
                      price_kind, price_gross_pln, payment_mode)
 values (:'ORG1','pending_review','Henna pudrowa (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '30 days', now()+interval '30 days 4 hours', 10, 10, 'platne', 200.00, 'online'),
        (:'ORG1','pending_review','Makijaż permanentny (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '40 days', now()+interval '40 days 4 hours', 10, 10, 'platne', 200.00, 'online'),
        (:'ORG1','pending_review','Odwołanie (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '45 days', now()+interval '45 days 4 hours', 10, 10, 'platne', 200.00, 'online'),
        (:'ORG1','pending_review','Bez zamówień (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '46 days', now()+interval '46 days 4 hours', 10, 10, 'platne', 200.00, 'online'),
        (:'ORG1','pending_review','Szkolenie za 5 dni (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '5 days', now()+interval '5 days 4 hours', 10, 10, 'platne', 200.00, 'online');
reset role;
select id as t3 from trainings where title like 'Henna%' \gset
select id as t4 from trainings where title like 'Makijaż%' \gset
select id as t5 from trainings where title like 'Odwołanie%' \gset
select id as t6 from trainings where title like 'Bez zamówień%' \gset
select id as t7 from trainings where title like 'Szkolenie za 5%' \gset
set role service_role;
select count(public.app_moderate_training(id,:'F2','publish',1)) from trainings where id in (:'t3',:'t4',:'t5',:'t6',:'t7');

select '--- RT1: zwrot przed płatnością (zła kolejność) ---';
select order_id as r1 from public.app_training_order_create(:'t3',:'U1',:'A',gen_random_uuid(),:'st1','U1 Przykładowy','u1@example.com',:'osoba','sprz-v1') \gset
select t.eq('RT10 reservation = 30 min for Stripe (min session)', (select reserved_until - created_at from training_orders where id = :'r1'), interval '30 minutes');
select public.app_training_payment_attach(:'r1',:'U1','stripe','pi_RT1',now()) is not null;
select t.eq('RT1 refund before payment -> deferred', public.app_payment_webhook('stripe','evt_rt1_r','refund.succeeded','re_RT1','pi_RT1',:'r1',20000,'PLN',repeat('1',64)), 'deferred_out_of_order');
select t.eq('RT1 nothing recorded (order, refunds, seats)', (select o.status || '/' || (select count(*) from training_refunds r where r.order_id = o.id) || '/' || t.seats_held from training_orders o join trainings t on t.id = o.training_id where o.id = :'r1'), 'reserved/0/1');
select t.eq('RT1 payment ->', public.app_payment_webhook('stripe','evt_rt1_p','payment.succeeded','pi_RT1',null,:'r1',20000,'PLN',repeat('2',64)), 'paid');
select t.eq('RT1 refund redelivered ->', public.app_payment_webhook('stripe','evt_rt1_r','refund.succeeded','re_RT1','pi_RT1',:'r1',20000,'PLN',repeat('1',64)), 'refunded');
select t.eq('RT1 final: order/payment/refunds/seats', (select o.status || '/' || p.status || '/' || (select string_agg(r.reason || ':' || r.status, ',') from training_refunds r where r.order_id = o.id) || '/' || t.seats_held || '/' || t.seats_registered
   from training_orders o join training_payments p on p.order_id = o.id join trainings t on t.id = o.training_id where o.id = :'r1'), 'refunded/refunded/inne:succeeded/0/0');

select '--- RT2: spory (wynik sporu) ---';
select order_id as r2 from public.app_training_order_create(:'t3',:'U2',:'A',gen_random_uuid(),:'st1','U2 Przykładowy','u2@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'r2',:'U2','stripe','pi_RT2',now()) is not null;
select public.app_payment_webhook('stripe','evt_rt2_p','payment.succeeded','pi_RT2',null,:'r2',20000,'PLN',repeat('3',64));
select public.app_payment_webhook('stripe','evt_rt2_d','dispute.opened','dp_RT2','pi_RT2',:'r2',20000,'PLN',repeat('4',64));
select t.expect('RT2 refund during dispute', format($q$select public.app_training_refund_request(%L,%L,20000,'rezygnacja')$q$, :'r2', :'C1'), 'BP409');
select t.expect('RT2 dispute.closed without outcome', format($q$select public.app_payment_webhook('stripe','evt_rt2_c0','dispute.closed','dp_RT2','pi_RT2',%L,20000,'PLN',repeat('5',64))$q$, :'r2'), 'BP422');
select t.eq('RT2 dispute lost ->', public.app_payment_webhook('stripe','evt_rt2_c','dispute.closed','dp_RT2','pi_RT2',:'r2',20000,'PLN',repeat('5',64), p_dispute_outcome => 'lost'), 'dispute_lost');
select t.eq('RT2 lost: order/reason/disputed/payment/registration/refund rows', (select o.status || '/' || o.refund_reason || '/' || (o.disputed_at is null) || '/' || p.status || '/' || r.status || '/' || (select count(*) from training_refunds x where x.order_id = o.id)
   from training_orders o join training_payments p on p.order_id = o.id join training_registrations r on r.id = o.registration_id where o.id = :'r2'), 'refunded/chargeback/true/refunded/cancelled/0');
select t.eq('RT2 lost: e-mail to participant and organizer', (select count(*) from outbox_emails where template in ('training_order_chargeback','training_order_dispute_closed')), 2::bigint);
select order_id as r2b from public.app_training_order_create(:'t3',:'U3',:'A',gen_random_uuid(),:'st1','U3 Przykładowy','u3@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'r2b',:'U3','stripe','pi_RT2B',now()) is not null;
select public.app_payment_webhook('stripe','evt_rt2b_p','payment.succeeded','pi_RT2B',null,:'r2b',20000,'PLN',repeat('6',64));
select public.app_payment_webhook('stripe','evt_rt2b_d','dispute.opened','dp_RT2B','pi_RT2B',:'r2b',20000,'PLN',repeat('7',64));
select t.eq('RT2 dispute won ->', public.app_payment_webhook('stripe','evt_rt2b_c','dispute.closed','dp_RT2B','pi_RT2B',:'r2b',20000,'PLN',repeat('8',64), p_dispute_outcome => 'won'), 'dispute_won');
select t.eq('RT2 won: order paid, disputed_at cleared, payment succeeded', (select o.status || '/' || (o.disputed_at is null) || '/' || p.status from training_orders o join training_payments p on p.order_id = o.id where o.id = :'r2b'), 'paid/true/succeeded');
select t.eq('RT2 won: organiser can refund again', public.app_training_refund_request(:'r2b',:'C1',5000,'rezygnacja',false) is not null, true);

select '--- RT3: odwołanie szkolenia z opłaconymi zamówieniami (uprawnienia, spór) ---';
select order_id as r3 from public.app_training_order_create(:'t5',:'U4',:'A',gen_random_uuid(),:'st1','U4 Przykładowy','u4@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'r3',:'U4','stripe','pi_RT3',now()) is not null;
select public.app_payment_webhook('stripe','evt_rt3_p','payment.succeeded','pi_RT3',null,:'r3',20000,'PLN',repeat('9',64));
select order_id as r3d from public.app_training_order_create(:'t5',:'U5',:'A',gen_random_uuid(),:'st1','U5 Przykładowy','u5@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'r3d',:'U5','stripe','pi_RT3D',now()) is not null;
select public.app_payment_webhook('stripe','evt_rt3d_p','payment.succeeded','pi_RT3D',null,:'r3d',20000,'PLN',repeat('a',64));
select public.app_payment_webhook('stripe','evt_rt3d_d','dispute.opened','dp_RT3D','pi_RT3D',:'r3d',20000,'PLN',repeat('b',64));
select t.expect('RT3 member (not owner) cancels paid training', format($q$select public.app_training_cancel_event(%L,%L,'test')$q$, :'t5', :'C3'), 'P0001');
select t.expect('RT3 agent cancels paid training', format($q$select public.app_training_cancel_event(%L,%L,'Organizator zgłosił odwołanie telefonicznie (przykład)')$q$, :'t5', :'F2'), 'P0001');
select t.expect('RT3 admin cancels paid training, short reason', format($q$select public.app_training_cancel_event(%L,%L,'krótko')$q$, :'t5', :'F1'), 'BP422');
select t.expect('RT3 agent removes paid training (moderation)', format($q$select public.app_moderate_training(%L,%L,'remove',null,null,'Naruszenie regulaminu – szczegóły w zgłoszeniu (przykład)')$q$, :'t5', :'F2'), 'P0001');
select public.app_training_cancel_event(:'t6',:'C3','Brak chętnych (przykład)');
select t.eq('RT3 member cancels training WITHOUT paid orders', (select status from trainings where id = :'t6'), 'cancelled');
select public.app_training_cancel_event(:'t5',:'C1','Choroba prowadzącej (przykład)');
select t.eq('RT3 owner cancel: refund only for non-disputed order', (select string_agg(o.order_ref is not null || ':' || (o.id = :'r3'), ',') from training_refunds r join training_orders o on o.id = r.order_id where o.training_id = :'t5'), 'true:true');
select t.eq('RT3 disputed order: no refund, team alert, buyer e-mail', (select count(*) from outbox_emails where template in ('payment_dispute_training_cancelled','training_cancelled_dispute')), 2::bigint);
select t.eq('RT3 counters zeroed', (select seats_held || '/' || seats_registered from trainings where id = :'t5'), '0/0');

select '--- RT4: faktura na NIP – widoczność dla właściciela salonu ---';
select order_id as r4 from public.app_training_order_create(:'t4','00000000-0000-0000-0000-0000000000e1',:'A',gen_random_uuid(),:'st1','Ewa Przykładowa','empa@example.com',
  jsonb_set(jsonb_set(:'firma'::jsonb,'{nip}','"1112223332"'),'{buyer_name}','"Ewa Przykładowa – działalność (przykład)"'),'sprz-v1') \gset
select t.eq('RT4 employee JDG order: bill_to_account', (select bill_to_account from training_orders where id = :'r4'), false);
select t.expect('RT4 employee orders on salon NIP', format($q$select * from public.app_training_order_create(%L,'00000000-0000-0000-0000-0000000000e1',%L,gen_random_uuid(),%L,'Ewa Przykładowa','empa@example.com',%L,'sprz-v1')$q$, :'t3', :'A', :'st1', :'firma'), 'BP409');
select public.app_training_payment_attach(:'r4','00000000-0000-0000-0000-0000000000e1','stripe','pi_RT4',now()) is not null;
select public.app_payment_webhook('stripe','evt_rt4_p','payment.succeeded','pi_RT4',null,:'r4',20000,'PLN',repeat('c',64));
select public.app_training_order_invoice_attach(:'r4',:'C1','FV/1 (przykład)', :'ORG1'||'/'||:'r4'||'/11111111-2222-3333-4444-555555555555.pdf', repeat('a',64));
select t.expect('RT4 owner cannot get invoice of employee JDG order', format($q$select public.app_training_invoice_path(%L,'00000000-0000-0000-0000-00000000000a')$q$, :'r4'), 'P0001');
select t.eq('RT4 employee gets own invoice', public.app_training_invoice_path(:'r4','00000000-0000-0000-0000-0000000000e1') is not null, true);
select order_id as r4o from public.app_training_order_create(:'t4','00000000-0000-0000-0000-00000000000a',:'A',gen_random_uuid(),:'st1','Anna Przykładowa','ownera@example.com',:'firma','sprz-v1') \gset
reset role;
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.eq('RT4 owner sees only salon-NIP orders via RLS', (select string_agg((id = :'r4o')::text, ',') from training_orders where account_id = :'A' and bill_to_account), 'true');
select t.eq('RT4 owner does not see employee JDG order', (select count(*) from training_orders where id = :'r4'), 0::bigint);
reset role;

select '--- RT7: płatność bez referencji (nasz UUID), druga referencja, nieznana płatność, uzgadnianie ---';
set role service_role;
select order_id as r7 from public.app_training_order_create(:'t3',:'U6',:'A',gen_random_uuid(),:'st1','U6 Przykładowy','u6@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_begin(:'r7',:'U6','stripe') as p7 \gset
-- Worker padł po createCheckout: brak referencji w bazie; webhook z naszym UUID z metadanych
select t.eq('RT7 payment by our UUID (no ref stored) ->', public.app_payment_webhook('stripe','evt_rt7_p','payment.succeeded','cs_RT7',null,:'r7',20000,'PLN',repeat('d',64), p_charge_ref => 'pi_RT7', p_our_payment_id => :'p7'), 'paid');
select t.eq('RT7 refs filled (session + charge)', (select provider_payment_ref || '/' || provider_charge_ref from training_payments where id = :'p7'), 'cs_RT7/pi_RT7');
select public.app_training_refund_request(:'r7',:'C1',20000,'rezygnacja') as rf7 \gset
select t.eq('RT7 refund webhook with charge ref only ->', public.app_payment_webhook('stripe','evt_rt7_r','refund.succeeded','re_RT7','pi_RT7',:'r7',20000,'PLN',repeat('e',64)), 'refunded');
select t.eq('RT7 unknown payment ->', public.app_payment_webhook('stripe','evt_rt7_u','payment.succeeded','cs_UNKNOWN',null,null,20000,'PLN',repeat('f',64)), 'unknown_ref');
select t.eq('RT7 unknown payment redelivered (not duplicate) ->', public.app_payment_webhook('stripe','evt_rt7_u','payment.succeeded','cs_UNKNOWN',null,null,20000,'PLN',repeat('f',64)), 'unknown_ref');
select order_id as r7b from public.app_training_order_create(:'t3',:'U7',:'A',gen_random_uuid(),:'st1','U7 Przykładowy','u7@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_begin(:'r7b',:'U7','stripe') as p7b \gset
reset role;
update training_payments set created_at = now() - interval '40 minutes' where id = :'p7b';
set role service_role;
select t.eq('RT7 pending payment without ref goes to reconciliation', (select count(*) from public.app_payments_to_reconcile() where payment_id = :'p7b' and provider_payment_ref is null), 1::bigint);
select public.app_training_payment_attach(:'r7b',:'U7','stripe','cs_RT7B',now()+interval '30 minutes', :'p7b') = :'p7b';
select public.app_training_order_abandon(:'r7b',:'U7');
select t.eq('RT11 abandoned order: session to cancel (claimed once)', (select string_agg(provider_payment_ref, ',') from public.app_checkouts_to_cancel()), 'cs_RT7B');
select t.eq('RT11 second claim within 15 min: nothing', (select count(*) from public.app_checkouts_to_cancel()), 0::bigint);

select '--- RT8: prawa konsumenta (odstąpienie, żądanie wcześniejszego rozpoczęcia) ---';
select t.expect('RT8 training in 5 days without early-start request', format($q$select * from public.app_training_order_create(%L,%L,%L,gen_random_uuid(),%L,'U8 Przykładowy','u8@example.com',%L,'sprz-v1')$q$, :'t7', :'U8', :'A', :'st1', :'osoba'), 'BP422');
select order_id as r8e from public.app_training_order_create(:'t7',:'U8',:'A',gen_random_uuid(),:'st1','U8 Przykładowy','u8@example.com',:'osoba','sprz-v1','wczesny-start-v1') \gset
select t.eq('RT8 early start recorded with version', (select early_start_notice_version from training_orders where id = :'r8e'), 'wczesny-start-v1');
select order_id as r8 from public.app_training_order_create(:'t3',:'U8',:'A',gen_random_uuid(),:'st1','U8 Przykładowy','u8@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_attach(:'r8',:'U8','stripe','pi_RT8',now()) is not null;
select public.app_payment_webhook('stripe','evt_rt8_p','payment.succeeded','pi_RT8',null,:'r8',20000,'PLN',repeat('0',63)||'1');
select t.expect('RT8 withdrawal by someone else', format($q$select public.app_training_order_withdraw(%L,%L,'odstapienie-v1')$q$, :'r8', :'U9'), 'P0001');
select public.app_training_order_withdraw(:'r8',:'U8','odstapienie-v1');
select public.app_training_order_withdraw(:'r8',:'U8','odstapienie-v1');
select t.eq('RT8 withdrawal: declared, seat released, e-mails (buyer + organiser), audit once', (select (o.withdrawal_declared_at is not null) || '/' || r.status || '/' ||
   (select count(*) from outbox_emails where template in ('training_order_withdrawal','training_order_withdrawal_received')) || '/' ||
   (select count(*) from client_audit_log where action = 'training_order_withdrawal_declared' and entity_id = o.id)
   from training_orders o join training_registrations r on r.id = o.registration_id where o.id = :'r8'), 'true/cancelled/2/1');
reset role;
update training_orders set withdrawal_declared_at = now() - interval '4 days' where id = :'r8';
set role service_role;
select t.eq('RT8 health: withdrawal without refund after 3 days', (select n from public.app_payment_health() where check_name = 'withdrawal_overdue'), 1::bigint);
select t.eq('RT8 organiser refunds (odstapienie)', public.app_training_refund_request(:'r8',:'C1',20000,'odstapienie') is not null, true);
select t.eq('RT8 health after refund', (select n from public.app_payment_health() where check_name = 'withdrawal_overdue'), 0::bigint);
reset role;
update training_orders set paid_at = now() - interval '15 days' where id = :'r2b';
set role service_role;
select t.expect('RT8 withdrawal after 14 days', format($q$select public.app_training_order_withdraw(%L,%L,'odstapienie-v1')$q$, :'r2b', :'U3'), 'BP409');

select '--- RT9: limity sprzedaży nowego organizatora ---';
reset role;
update app_settings set new_organizer_max_grosze = (select sum(amount_grosze) from training_orders where organizer_id = :'ORG1'
  and (status in ('paid','partially_refunded','refund_pending','refunded') or (status = 'reserved' and reserved_until > now()))) + 10000;
set role service_role;
select t.expect('RT9 new organiser over sales limit', format($q$select * from public.app_training_order_create(%L,%L,%L,gen_random_uuid(),%L,'U9 Przykładowy','u9@example.com',%L,'sprz-v1')$q$, :'t4', :'U9', :'A', :'st1', :'osoba'), 'BP409');
reset role;
update app_settings set new_organizer_max_grosze = 2000000;
update training_organizers set verified_at = now() - interval '61 days' where id = :'ORG1';
update app_settings set new_organizer_max_grosze = 10000;
set role service_role;
select t.eq('RT9 organiser after 60 days: no limit', (select created from public.app_training_order_create(:'t4',:'U9',:'A',gen_random_uuid(),:'st1','U9 Przykładowy','u9@example.com',:'osoba','sprz-v1')), true);
reset role;
update app_settings set new_organizer_max_grosze = 2000000;
set role service_role;

select '--- RT5: zmiana konta wypłat (karencja, alerty, TOTP, KYB) ---';
select t.expect('RT5 payout link without fresh TOTP', format($q$select public.app_payout_link_issued(%L,%L,now() - interval '10 minutes')$q$, :'ORG1', :'C1'), 'BP409');
select public.app_payout_link_issued(:'ORG1',:'C1',now() - interval '1 minute');
select t.eq('RT5 link for active account: audit + alert (owner, verified address, team)', (select count(*) from client_audit_log where action = 'payout_account_link_created') || '/' ||
   (select string_agg(split_part(recipient, ':', 1), ',' order by recipient) from outbox_emails where template like 'payout_change_alert%' and payload ->> 'kind' = 'payout_link_for_active_account'), '1/organizer-verified,team,user');
select public.app_payout_account_set_status('stripe','acct_TEST1', false, false, true, true);
select public.app_payout_account_register(:'ORG1',:'C1','stripe','acct_ATTACKER') is not null;
select t.eq('RT5 new account alert (2 accounts x owner, verified address, team)', (select count(*) from outbox_emails where template like 'payout_change_alert%' and payload ->> 'kind' = 'payout_account_created'), 6::bigint);
select t.eq('RT5 new account active', public.app_payout_account_set_status('stripe','acct_ATTACKER', true, true, false), 'active');
select t.expect('RT5 order during cooldown (karencja)', format($q$select * from public.app_training_order_create(%L,%L,%L,gen_random_uuid(),%L,'U1 Przykładowy','u1@example.com',%L,'sprz-v1')$q$, :'t4', :'U1', :'A', :'st1', :'osoba'), 'BP409');
reset role;
update organizer_payout_accounts set usable_from = now() - interval '1 minute' where provider_account_ref = 'acct_ATTACKER';
set role service_role;
select t.eq('RT5 operator: payout destination changed -> cooldown again', public.app_payout_account_set_status('stripe','acct_ATTACKER', true, true, false, p_destination_changed => true), 'active');
select t.eq('RT5 destination change: usable_from in future, audit, discrepancy', (select (usable_from > now() + interval '71 hours') from organizer_payout_accounts where provider_account_ref = 'acct_ATTACKER') || '/' ||
   (select count(*) from client_audit_log where action = 'payout_destination_changed') || '/' ||
   (select count(*) from payment_discrepancies where kind = 'payout_destination_changed' and resolved_at is null), 'true/1/1');
select t.eq('RT5 KYB tax id of another company -> restricted', public.app_payout_account_set_status('stripe','acct_ATTACKER', true, true, false, p_entity_tax_id => '1112223332'), 'restricted');
select t.eq('RT5 KYB mismatch discrepancy', (select count(*) from payment_discrepancies where kind = 'kyb_mismatch'), 1::bigint);
select t.eq('RT5 KYB tax id = profile NIP -> active', public.app_payout_account_set_status('stripe','acct_ATTACKER', true, true, false, p_entity_tax_id => '5556667776'), 'active');
select t.eq('RT5 owner MFA reset by adviser', public.app_organizer_owner_mfa_reset(:'C1',:'F2'), 1);
select t.expect('RT5 refund within 72 h after MFA reset', format($q$select public.app_training_refund_request(%L,%L,1000,'rezygnacja',false)$q$, :'r2b', :'C1'), 'P0001');
select t.expect('RT5 payout link within 72 h after MFA reset', format($q$select public.app_payout_link_issued(%L,%L,now())$q$, :'ORG1', :'C1'), 'P0001');
select t.eq('RT5 MFA reset alert', (select count(*) from outbox_emails where template like 'payout_change_alert%' and payload ->> 'kind' = 'owner_mfa_reset'), 3::bigint);
reset role;
update organizer_members set mfa_reset_at = now() - interval '73 hours' where user_id = :'C1';
update organizer_payout_accounts set usable_from = now() - interval '1 minute' where provider_account_ref = 'acct_ATTACKER';
set role service_role;

select '--- RT6: zawieszony organizator ---';
select order_id as r6a from public.app_training_order_create(:'t4',:'U2',:'A',gen_random_uuid(),:'st1','U2 Przykładowy','u2@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_begin(:'r6a',:'U2','stripe') as p6a \gset
select public.app_training_payment_attach(:'r6a',:'U2','stripe','cs_RT6A',now()+interval '30 minutes', :'p6a') is not null;
select order_id as r6b from public.app_training_order_create(:'t4',:'U3',:'A',gen_random_uuid(),:'st1','U3 Przykładowy','u3@example.com',:'osoba','sprz-v1') \gset
select public.app_training_payment_begin(:'r6b',:'U3','stripe') as p6b \gset
select public.app_training_payment_attach(:'r6b',:'U3','stripe','cs_RT6B',now()+interval '30 minutes', :'p6b') is not null;
select t.expect('RT6 suspension by organiser', format($q$select public.app_suspend_organizer(%L,%L,'test (przykład)')$q$, :'ORG1', :'C1'), 'P0001');
select count(*) as nres from training_orders where organizer_id = :'ORG1' and status = 'reserved' \gset
select t.eq('RT6 suspension closes all reservations of organiser', public.app_suspend_organizer(:'ORG1',:'F2','Fałszywe dane organizatora (przykład)'), :nres);
select t.eq('RT6 no reservations left', (select count(*) from training_orders where organizer_id = :'ORG1' and status = 'reserved'), 0::bigint);
select t.expect('RT6 new payment session after suspension', format($q$select public.app_training_payment_begin(%L,%L,'stripe')$q$, :'r6a', :'U2'), 'BP409');
select t.eq('RT6 payment after suspension -> automatic refund', public.app_payment_webhook('stripe','evt_rt6_p','payment.succeeded','cs_RT6A',null,:'r6a',20000,'PLN',repeat('0',62)||'22'), 'refund_required');
select t.eq('RT6 refund reason', (select o.status || '/' || r.reason || '/' || r.requested_by from training_orders o join training_refunds r on r.order_id = o.id where o.id = :'r6a'), 'refund_pending/organizator-zawieszony/system:webhook:stripe');
select t.eq('RT6 open session of closed reservation goes to cancelCheckout', (select string_agg(provider_payment_ref, ',') from public.app_checkouts_to_cancel()), 'cs_RT6B');
reset role;
select t.eq('RT6 seat counters consistent', (select n from public.app_payment_health() where check_name = 'seat_counter'), 0::bigint);
select '--- RT6b: zawieszenie bezpośrednio w /panel (RLS) – rezerwacje zamyka cron ---';
update training_organizers set status = 'active' where id = :'ORG1';
set role service_role;
select order_id as r6c from public.app_training_order_create(:'t4',:'U4',:'A',gen_random_uuid(),:'st1','U4 Przykładowy','u4@example.com',:'osoba','sprz-v1') \gset
reset role;
update training_organizers set status = 'suspended' where id = :'ORG1';
set role service_role;
select t.eq('RT6b cron run', public.app_expire_training_orders() >= 1, true);
select t.eq('RT6b cron closes reservation of suspended organiser', (select status from training_orders where id = :'r6c'), 'cancelled');
reset role;
select t.eq('RT6b seat counters consistent', (select n from public.app_payment_health() where check_name = 'seat_counter'), 0::bigint);
select '--- RT10: uprawnienia funkcji po zmianach (bez funkcji rozszerzeń – w Supabase pgcrypto jest w extensions) ---';
create view t.fn as
  select p.oid, p.proname, p.prosecdef,
         exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%') as has_search_path,
         p.proname ~ '(payment|training_order|refund|checkout|payout|sales_terms|platform_fee|invoice)' as payment
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e');
select t.eq('RT10 SECURITY DEFINER only', (select string_agg(proname, ',' order by proname) from t.fn where prosecdef),
  'app_is_staff,app_purge_audit_log,client_account_ids,client_audit_staff_change,employer_account_ids,organizer_ids');
select t.eq('RT10 SECURITY DEFINER without search_path', (select coalesce(string_agg(proname, ',' order by proname), '(none)') from t.fn where prosecdef and not has_search_path), '(none)');
select t.eq('RT10 payment fns without search_path', (select coalesce(string_agg(proname, ',' order by proname), '(none)') from t.fn where payment and not has_search_path), '(none)');
select t.eq('RT10 exec authenticated', (select string_agg(proname, ',' order by proname) from t.fn where has_function_privilege('authenticated', oid, 'execute')),
  'app_is_staff,client_account_ids,employer_account_ids,organizer_ids,zabiegi_ids');
select t.eq('RT10 exec anon', (select coalesce(string_agg(proname, ',' order by proname), '(none)') from t.fn where has_function_privilege('anon', oid, 'execute')), '(none)');
select t.eq('RT10 payment fns without service_role (trigger only)', (select coalesce(string_agg(proname, ',' order by proname), '(none)') from t.fn where payment and not has_function_privilege('service_role', oid, 'execute')),
  'training_orders_status_audit');

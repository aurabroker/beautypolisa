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
-- users: a = owner salon A (client), b = owner salon B (client, no phone), e1 = employee A,
-- f1 = admin, f2 = agent, c1 = organiser 1, c2 = organiser 2, d1 = employer D1, d2 = employer D2 (pending),
-- s1/s2 = job seekers, x1..x3 = extra users for phone limits
insert into auth.users values
 ('00000000-0000-0000-0000-00000000000a','ownera@example.com'), ('00000000-0000-0000-0000-00000000000b','ownerb@example.com'),
 ('00000000-0000-0000-0000-0000000000e1','empa@example.com'),   ('00000000-0000-0000-0000-0000000000f1','admin@example.com'),
 ('00000000-0000-0000-0000-0000000000f2','agent@example.com'),  ('00000000-0000-0000-0000-0000000000c1','org1@example.com'),
 ('00000000-0000-0000-0000-0000000000c2','org2@example.com'),   ('00000000-0000-0000-0000-0000000000d1','pracodawca1@example.com'),
 ('00000000-0000-0000-0000-0000000000d2','pracodawca2@example.com'), ('00000000-0000-0000-0000-0000000000d3','pracodawca3@example.com'),
 ('00000000-0000-0000-0000-0000000000a1','szukam1@example.com'), ('00000000-0000-0000-0000-0000000000a2','szukam2@example.com'),
 ('00000000-0000-0000-0000-0000000000b1','x1@example.com'), ('00000000-0000-0000-0000-0000000000b2','x2@example.com'),
 ('00000000-0000-0000-0000-0000000000b3','x3@example.com');
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
insert into training_organizers(id, kind, display_name, legal_name, nip, city, status, verified_at, verified_by, terms_version) values
 ('eeeeeeee-0000-0000-0000-000000000001','firma','Organizator przykładowy','Organizator Przykładowy sp. z o.o.','5556667776','Kraków','active',now(),'00000000-0000-0000-0000-0000000000f1','org-v1'),
 ('eeeeeeee-0000-0000-0000-000000000002','firma','Inny organizator (przykład)','Inny Organizator s.c.','7778889998','Gdańsk','active',now(),'00000000-0000-0000-0000-0000000000f1','org-v1');
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','org1@example.com','owner',t.h('tokO1')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO1'),'00000000-0000-0000-0000-0000000000c1','org1@example.com') is not null;
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000f1','org2@example.com','owner',t.h('tokO2')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO2'),'00000000-0000-0000-0000-0000000000c2','org2@example.com') is not null;

\set gusD1 '{"nip":"2223334443","result":"aktywny","regon":"123456785","entity_type":"P","legal_name":"Studio Przykładowe sp. z o.o.","city":"Poznań","postal_code":"60-001"}'
\set gusA  '{"nip":"9876543210","result":"aktywny","regon":"123456786","entity_type":"P","legal_name":"Salon Przykładowy A sp. z o.o.","city":"Kraków","postal_code":"30-001"}'
\set gusB  '{"nip":"1112223332","result":"aktywny","regon":"123456787","entity_type":"F","legal_name":"Salon Przykładowy B","city":"Gdańsk","postal_code":"80-001"}'
\set seek1 '{"first_name":"Łucja","profession":"stylistka-paznokci","city":"Kraków","voivodeship":"malopolskie","cooperation_forms":["umowa-o-prace","najem-stanowiska"],"experience":"3-5-lat","available_from":"2026-12-01","description":"Stylizacja paznokci, manicure hybrydowy i żelowy (przykład)."}'

-- ===================== 0. defaults =====================
select '--- 0. defaults ---';
select t.eq('flag szukam_pracy on at launch (P1a)', (select enabled from app_feature_flags where key='szukam_pracy'), true);
select t.eq('promotion on, 21 days, 10000/1000', (select enabled::text || '/' || ad_days || '/' || organizer_12m_net_pln || '/' || organizer_1m_net_pln from app_promotions), 'true/21/10000.00/1000.00');
select t.eq('nip checksum Aura Expert NIP from L1', public.nip_checksum_ok('5242793544'), true);
select t.eq('nip checksum wrong digit', public.nip_checksum_ok('5242793545'), false);
select t.eq('nip checksum letters', public.nip_checksum_ok('52427935AB'), false);

-- ===================== 1. employer registration + GUS =====================
select '--- 1. employer registration ---';
set role service_role;
select t.expect('invalid NIP (BP422, no value in message)', $q$select public.app_employer_register('00000000-0000-0000-0000-0000000000d1','2223334444','Studio Przykładowe','reg-v1')$q$, 'BP422');
select t.expect('staff cannot register employer', $q$select public.app_employer_register('00000000-0000-0000-0000-0000000000f2','2223334443','Studio','reg-v1')$q$, 'P0001');
select t.expect('display name with URL', $q$select public.app_employer_register('00000000-0000-0000-0000-0000000000d1','2223334443','www.oferta.example','reg-v1')$q$, 'BP422');
select t.expect('SEC-02 reserved display name (ERGO Hestia)', $q$select public.app_employer_register('00000000-0000-0000-0000-0000000000d1','2223334443','Rekrutacja ERGO Hestia','reg-v1')$q$, 'BP422');
select t.eq('D1 registers', public.app_employer_register('00000000-0000-0000-0000-0000000000d1','2223334443','Studio Przykładowe','reg-v1') is not null, true);
select t.expect('D1 second pending registration', $q$select public.app_employer_register('00000000-0000-0000-0000-0000000000d1','3334445554','Drugie studio','reg-v1')$q$, 'P0001');
select t.eq('SEC-03 same NIP as pending D1: neutral (pending account, no error)', public.app_employer_register('00000000-0000-0000-0000-0000000000b1','2223334443','Studio Drugie (przykład)','reg-v1') is not null, true);
select t.eq('SEC-03 NIP of active client salon A: neutral (pending account, no error)', public.app_employer_register('00000000-0000-0000-0000-0000000000b2','9876543210','Salon Drugi (przykład)','reg-v1') is not null, true);
select t.eq('D2 registers own NIP', public.app_employer_register('00000000-0000-0000-0000-0000000000d2','3334445554','Gabinet Przykładowy','reg-v1') is not null, true);
reset role;
select t.eq('SEC-03 pending accounts do not reserve NIP (2 pending for D1 NIP)', (select count(*) from client_accounts where nip='2223334443' and status='pending'), 2::bigint);
select id as d1acc from client_accounts where nip='2223334443' and created_by='00000000-0000-0000-0000-0000000000d1' \gset
select id as b1dup from client_accounts where nip='2223334443' and created_by='00000000-0000-0000-0000-0000000000b1' \gset
select id as b2dup from client_accounts where nip='9876543210' and kind='employer' \gset
select id as d2acc from client_accounts where nip='3334445554' \gset
set role service_role;
select t.expect('GUS result for other NIP', format($q$select public.app_employer_record_gus(%L,'system:gus','{"nip":"9876543210","result":"aktywny","regon":"123456785","legal_name":"X"}')$q$, :'d1acc'), 'P0001');
select t.expect('GUS bad actor', format($q$select public.app_employer_record_gus(%L,'user:00000000-0000-0000-0000-0000000000d1',%L)$q$, :'d1acc', :'gusD1'), 'P0001');
select t.expect('GUS manual by client user', format($q$select public.app_employer_record_gus(%L,'staff:00000000-0000-0000-0000-0000000000d1',%L)$q$, :'d1acc', :'gusD1'), 'P0001');
select t.expect('GUS active without REGON (CHECK)', format($q$select public.app_employer_record_gus(%L,'system:gus','{"nip":"2223334443","result":"aktywny"}')$q$, :'d1acc'), '23514');
select t.eq('GUS service error -> no change', public.app_employer_record_gus(:'d1acc','system:gus','{"nip":"2223334443","result":"blad-uslugi"}'), false);
select t.expect('activate D1 before GUS', format($q$select public.app_employer_activate(%L,'00000000-0000-0000-0000-0000000000d1')$q$, :'d1acc'), 'P0001');
select t.eq('GUS active D1', public.app_employer_record_gus(:'d1acc','system:gus', :'gusD1'), true);
reset role;
select t.eq('D1 legal name prefilled from GUS', (select legal_name || ' / ' || city from client_accounts where id=:'d1acc'), 'Studio Przykładowe sp. z o.o. / Poznań');
set role service_role;
select t.expect('activate D1 without phone', format($q$select public.app_employer_activate(%L,'00000000-0000-0000-0000-0000000000d1')$q$, :'d1acc'), 'P0001');
reset role;

-- ===================== 2. SMS =====================
select '--- 2. SMS ---';
set role service_role;
select public.app_phone_send_code('00000000-0000-0000-0000-0000000000d1', t.h('+48600000001'), '001', t.h('d1:123456')) as v1 \gset
select t.expect('second code within 60 s', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000d1', t.h('+48600000001'), '001', t.h('d1:654321'))$q$, 'BP429');
select t.eq('wrong code -> false (attempt counted)', public.app_phone_verify_code('00000000-0000-0000-0000-0000000000d1', :'v1', t.h('d1:000000')), false);
reset role;
select t.eq('attempts after wrong code', (select attempts from phone_verifications where id=:'v1'), 1::smallint);
set role service_role;
select t.expect('other user uses my verification id', format($q$select public.app_phone_verify_code('00000000-0000-0000-0000-0000000000d2', %L, t.h('d1:123456'))$q$, :'v1'), 'P0001');
select t.eq('correct code', public.app_phone_verify_code('00000000-0000-0000-0000-0000000000d1', :'v1', t.h('d1:123456')), true);
select t.expect('code reuse', format($q$select public.app_phone_verify_code('00000000-0000-0000-0000-0000000000d1', %L, t.h('d1:123456'))$q$, :'v1'), 'P0001');
-- 5 wrong attempts burn the code
select public.app_phone_send_code('00000000-0000-0000-0000-0000000000b1', t.h('+48600000009'), '009', t.h('b1:111111')) as v2 \gset
select public.app_phone_verify_code('00000000-0000-0000-0000-0000000000b1', :'v2', t.h('x')) from generate_series(1,5);
select t.expect('6th attempt after 5 wrong', format($q$select public.app_phone_verify_code('00000000-0000-0000-0000-0000000000b1', %L, t.h('b1:111111'))$q$, :'v2'), 'P0001');
reset role;
-- expired code
update phone_verifications set created_at = now() - interval '11 minutes', expires_at = now() - interval '1 minute' where id = :'v2';
-- per-number limit (3 per day): v2 used +48600000009 once; two more users, then fourth send refused
set role service_role;
select public.app_phone_send_code('00000000-0000-0000-0000-0000000000b2', t.h('+48600000009'), '009', t.h('b2:1')) is not null;
select public.app_phone_send_code('00000000-0000-0000-0000-0000000000b3', t.h('+48600000009'), '009', t.h('b3:1')) is not null;
select t.expect('4th send to same number in 24 h', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000d3', t.h('+48600000009'), '009', t.h('d3:1'))$q$, 'BP429');
reset role;
-- accounts per number (2): number of d1 verified also by b2 -> third user refused
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-0000000000b2', t.h('+48600000001'), '001', now());
set role service_role;
select t.expect('3rd account on same number (neutral BP429, SEC-11)', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000d3', t.h('+48600000001'), '001', t.h('d3:2'))$q$, 'BP429');
reset role;
delete from user_phones where user_id='00000000-0000-0000-0000-0000000000b2';
-- per-user daily limit (5)
update phone_verifications set created_at = created_at - interval '2 minutes', expires_at = expires_at - interval '2 minutes';
update sms_send_log set created_at = created_at - interval '2 minutes';
set role service_role;
select t.eq('d3 send #1', public.app_phone_send_code('00000000-0000-0000-0000-0000000000d3', t.h('+48600000031'), '031', t.h('d3:a')) is not null, true);
reset role;
insert into sms_send_log(user_ref, phone_hmac, created_at)
 select '00000000-0000-0000-0000-0000000000d3', t.h('+4860000003' || g), now() - interval '5 minutes' * g from generate_series(2,5) g;
set role service_role;
select t.expect('6th send per user per day', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000d3', t.h('+48600000039'), '039', t.h('d3:b'))$q$, 'BP429');
reset role;
-- global daily cap (spend protection)
update app_settings set sms_daily_cap = (select count(*) from sms_send_log where created_at > now() - interval '1 day');
set role service_role;
select t.expect('global daily SMS cap', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000a1', t.h('+48600000041'), '041', t.h('a1:1'))$q$, 'BP429');
reset role;
update app_settings set sms_daily_cap = 300;
-- SEC-04: deleting the Auth user does not reset SMS limits
insert into auth.users values ('00000000-0000-0000-0000-0000000000b4','x4@example.com');
set role service_role;
select public.app_phone_send_code('00000000-0000-0000-0000-0000000000b4', t.h('+48600000077'), '077', t.h('b4:1'), t.h('60000')) is not null;
reset role;
select count(*) as glob_before from sms_send_log where created_at > now() - interval '1 day' \gset
delete from auth.users where id = '00000000-0000-0000-0000-0000000000b4';
select t.eq('SEC-04 phone_verifications cascade-deleted with user', (select count(*) from phone_verifications where user_id = '00000000-0000-0000-0000-0000000000b4'), 0::bigint);
select t.eq('SEC-04 global count unchanged after user deletion', (select count(*) from sms_send_log where created_at > now() - interval '1 day'), :'glob_before'::bigint);
set role service_role;
select public.app_phone_send_code('00000000-0000-0000-0000-0000000000b2', t.h('+48600000077'), '077', t.h('b2:7')) is not null;
reset role;
update sms_send_log set created_at = created_at - interval '2 minutes' where phone_hmac = t.h('+48600000077');
set role service_role;
select public.app_phone_send_code('00000000-0000-0000-0000-0000000000b3', t.h('+48600000077'), '077', t.h('b3:7')) is not null;
select t.expect('SEC-04 per-number limit still counts the deleted user''s send', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000a1', t.h('+48600000077'), '077', t.h('a1:7'))$q$, 'BP429');
reset role;
-- SEC-11: hourly cap, prefix limit, conversion breaker
update app_settings set sms_hourly_cap = (select count(*) from sms_send_log where created_at > now() - interval '1 hour');
set role service_role;
select t.expect('SEC-11 hourly cap', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000a1', t.h('+48600000081'), '081', t.h('a1:8'))$q$, 'BP429');
reset role;
update app_settings set sms_hourly_cap = 40;
insert into sms_send_log(user_ref, phone_hmac, prefix_hmac, created_at) select gen_random_uuid(), t.h('+4870000' || g), t.h('70000'), now() - interval '20 minutes' from generate_series(1,10) g;
set role service_role;
select t.expect('SEC-11 per-prefix hourly limit', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000a1', t.h('+48700000099'), '099', t.h('a1:9'), t.h('70000'))$q$, 'BP429');
reset role;
insert into sms_send_log(user_ref, phone_hmac, created_at) select gen_random_uuid(), t.h('+4871000' || g), now() - interval '30 minutes' from generate_series(1,12) g;
set role service_role;
select t.expect('SEC-11 conversion breaker (>=20 settled sends, <30% verified)', $q$select public.app_phone_send_code('00000000-0000-0000-0000-0000000000a1', t.h('+48600000082'), '082', t.h('a1:10'))$q$, 'BP429');
reset role;
delete from sms_send_log where user_ref not in (select id from auth.users) and user_ref is not null and created_at < now() - interval '15 minutes';
select t.eq('no phone number or code stored in clear', (select count(*) from information_schema.columns where table_name in ('user_phones','phone_verifications','sms_send_log') and column_name in ('phone','phone_e164','code')), 0::bigint);

-- ===================== 3. employer activation & RLS =====================
select '--- 3. employer activation & RLS ---';
set role service_role;
select public.app_employer_activate(:'d1acc','00000000-0000-0000-0000-0000000000d1');
select t.eq('activate D1', (select status from client_accounts where id = :'d1acc'), 'active');
select t.eq('SEC-03 other pending registration for D1 NIP closed on activation', (select status from client_accounts where id = :'b1dup'), 'closed');
select t.expect('activate D2 without GUS', format($q$select public.app_employer_activate(%L,'00000000-0000-0000-0000-0000000000d2')$q$, :'d2acc'), 'P0001');
select t.expect('activate client salon via employer fn', $q$select public.app_employer_activate('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a')$q$, 'P0001');
select t.expect('client activation fn on employer account', format($q$select public.app_activate_client_account(%L,'00000000-0000-0000-0000-0000000000f1','x@example.com',t.h('q'))$q$, :'d2acc'), 'P0001');
select t.expect('D1 owner invites employee (MVP: no team)', format($q$select public.app_create_invitation(%L,'00000000-0000-0000-0000-0000000000d1','prac@example.com','employee',t.h('tokX'))$q$, :'d1acc'), 'P0001');
-- salon A: GUS + phone for owner A; salon B: GUS only (owner B without phone)
select t.eq('GUS A', public.app_employer_record_gus('aaaaaaaa-0000-0000-0000-000000000001','system:gus', :'gusA'), true);
select t.eq('GUS B', public.app_employer_record_gus('bbbbbbbb-0000-0000-0000-000000000001','system:gus', :'gusB'), true);
reset role;
select t.eq('client A legal name kept from staff/GUS only if empty', (select legal_name from client_accounts where id='aaaaaaaa-0000-0000-0000-000000000001'), 'Salon Przykładowy A sp. z o.o.');
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-00000000000a', t.h('+48600000002'), '002', now());
-- SEC-03: pending account with NIP of active client salon A -> 'conflict', no activation, owner A notified
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-0000000000b2', t.h('+48600000062'), '062', now());
set role service_role;
select public.app_employer_record_gus(:'b2dup','system:gus', :'gusA');
select t.eq('SEC-03 activation with NIP of active account -> conflict', public.app_employer_activate(:'b2dup','00000000-0000-0000-0000-0000000000b2'), 'conflict');
reset role;
delete from user_phones where user_id='00000000-0000-0000-0000-0000000000b2';
select t.eq('SEC-03 conflict: pending account stays pending', (select status from client_accounts where id = :'b2dup'), 'pending');
select t.eq('SEC-03 conflict: e-mail to owner of existing account + team', (select string_agg(template || '>' || recipient, ',' order by template) from outbox_emails where template like 'employer_nip_%'), 'employer_nip_attempt>user:00000000-0000-0000-0000-00000000000a,employer_nip_conflict_team>team:pracodawcy');
-- SEC-02: trust level 2
set role service_role;
select t.eq('SEC-02 D1 (GUS only) cannot read Szukam pracy', public.employer_trusted_actor(:'d1acc','00000000-0000-0000-0000-0000000000d1'), false);
select t.expect('SEC-02 trust set by employer user', format($q$select public.app_employer_trust(%L,'00000000-0000-0000-0000-0000000000d1','telefon-zwrotny')$q$, :'d1acc'), 'P0001');
select t.expect('SEC-02 unknown trust method (CHECK)', format($q$select public.app_employer_trust(%L,'00000000-0000-0000-0000-0000000000f2','bo-tak')$q$, :'d1acc'), '23514');
select public.app_employer_trust(:'d1acc','00000000-0000-0000-0000-0000000000f2','telefon-zwrotny');
select t.eq('SEC-02 D1 trusted after staff callback', public.employer_trusted_actor(:'d1acc','00000000-0000-0000-0000-0000000000d1'), true);
select t.eq('SEC-02 client salon A trusted ex officio (owner with phone)', public.employer_trusted_actor('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a'), true);
reset role;
select t.eq('SEC-02 trust approves display name', (select display_name_approved_at is not null from client_accounts where id = :'d1acc'), true);

\set offer_cols '(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)'
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select t.eq('D1 employer_account_ids (1)', (select count(*) from public.employer_account_ids()), 1::bigint);
select t.eq('D1 client_account_ids owner (1)', (select count(*) from public.client_account_ids('owner')), 1::bigint);
select t.eq('D1 sees own account only', (select string_agg(kind || ':' || display_name, ',') from client_accounts), 'employer:Studio Przykładowe');
select t.eq('D1 sees 0 policies of salons', (select count(*) from client_policies), 0::bigint);
select t.eq('D1 sees own GUS record (2 rows: error + active)', (select count(*) from employer_verifications), 2::bigint);
select t.eq('D1 sees own phone last3', (select phone_last3 from user_phones), '001');
select t.expect('D1 reads phone_hmac', $q$select phone_hmac from user_phones$q$, '42501');
select t.expect('D1 reads phone_verifications', $q$select count(*) from phone_verifications$q$, '42501');
select t.expect('D1 writes user_phones', $q$insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-0000000000d1', repeat('a',64),'123',now())$q$, '42501');
select t.expect('D1 sets employer_verified_at', $q$update client_accounts set employer_verified_at = now()$q$, '42501');
select t.eq('D1 reads app_settings (0, staff only)', (select count(*) from app_settings), 0::bigint);
select t.eq('D1 promotions (staff only) 0', (select count(*) from app_promotions), 0::bigint);
insert into job_offers (account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values (:'d1acc','draft','Stylistka paznokci (przykład)','stylistka-paznokci','umowa-zlecenie','czesc-etatu','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10));
insert into job_offer_contacts(offer_id, method, email) select id,'formularz','rekrutacja@studio-przyklad.example' from job_offers;
update job_offers set status='pending_review';
select t.eq('D1 sees own offer', (select count(*) from job_offers), 1::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal1');
select t.eq('D1 aal1 employer_account_ids (0)', (select count(*) from public.employer_account_ids()), 0::bigint);
select t.expect('D1 aal1 inserts offer (RLS)', format($q$insert into job_offers %s values (%L,'draft','Fryzjer (przykład)','fryzjer','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10))$q$, :'offer_cols', :'d1acc'), '42501');
select t.as_user('00000000-0000-0000-0000-0000000000d2','aal2');
select t.eq('D2 pending sees own account (0 – not active)', (select count(*) from client_accounts), 0::bigint);
select t.expect('D2 pending inserts offer', format($q$insert into job_offers %s values (%L,'draft','Fryzjer (przykład)','fryzjer','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10))$q$, :'offer_cols', :'d2acc'), '42501');
select t.as_user('00000000-0000-0000-0000-00000000000b','aal2');
select t.eq('owner B (GUS ok, no phone) employer ids (0)', (select count(*) from public.employer_account_ids()), 0::bigint);
select t.expect('owner B without phone inserts offer', $q$insert into job_offers (account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description) values ('bbbbbbbb-0000-0000-0000-000000000001','draft','Fryzjer (przykład)','fryzjer','b2b','elastyczny','Gdańsk','pomorskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10))$q$, '42501');
select t.eq('owner B sees D1 draft offer (0)', (select count(*) from job_offers), 0::bigint);
select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.eq('owner A (GUS + phone) employer ids (1)', (select count(*) from public.employer_account_ids()), 1::bigint);
insert into job_offers (account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','pending_review','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10));
select t.eq('owner A sees own offer only (D1 offer in review hidden)', (select count(*) from job_offers), 1::bigint);
select t.expect('owner A inserts offer for D1', format($q$insert into job_offers %s values (%L,'draft','Fryzjer (przykład)','fryzjer','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10))$q$, :'offer_cols', :'d1acc'), '42501');
select t.eq('owner A sees D1 GUS records (0)', (select count(*) from employer_verifications where account_id = :'d1acc'), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000e1','aal1');
select t.eq('employee A employer ids (0)', (select count(*) from public.employer_account_ids()), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
select t.eq('organiser employer ids (0)', (select count(*) from public.employer_account_ids()), 0::bigint);
reset role;

-- ===================== 4. moderation of offers, 21 days, promotion =====================
select '--- 4. offers: 21 days, GUS freshness, promotion ---';
select id as d1offer from job_offers where account_id = :'d1acc' \gset
set role service_role;
select t.expect('SEC-05 publish with unconfirmed recruitment address', format($q$select public.app_moderate_job_offer(%L,'00000000-0000-0000-0000-0000000000f2','publish',2)$q$, :'d1offer'), 'P0001');
select public.app_reply_address_request(:'d1acc','00000000-0000-0000-0000-0000000000d1','Rekrutacja@Studio-Przyklad.example', t.h('tokRA1'));
select t.eq('SEC-05 wrong token does not confirm', public.app_reply_address_confirm(t.h('zly')), false);
select t.eq('SEC-05 confirm link', public.app_reply_address_confirm(t.h('tokRA1')), true);
select t.eq('SEC-05 token single use', public.app_reply_address_confirm(t.h('tokRA1')), false);
reset role;
update client_accounts set employer_verified_at = now() - interval '121 days' where id = :'d1acc';
set role service_role;
select t.expect('publish with stale GUS check', format($q$select public.app_moderate_job_offer(%L,'00000000-0000-0000-0000-0000000000f2','publish',2)$q$, :'d1offer'), 'P0001');
select public.app_employer_record_gus(:'d1acc','system:gus', :'gusD1');
select public.app_set_promotion('otwarcie-portalu', false, '00000000-0000-0000-0000-0000000000f1');
select t.expect('publish without active promotion', format($q$select public.app_moderate_job_offer(%L,'00000000-0000-0000-0000-0000000000f2','publish',2)$q$, :'d1offer'), 'BP409');
select t.expect('agent changes promotion', $q$select public.app_set_promotion('otwarcie-portalu', true, '00000000-0000-0000-0000-0000000000f2', 'decyzja P1')$q$, 'P0001');
select t.expect('admin enables promotion without decision ref', $q$select public.app_set_promotion('otwarcie-portalu', true, '00000000-0000-0000-0000-0000000000f1', null)$q$, 'P0001');
select public.app_set_promotion('otwarcie-portalu', true, '00000000-0000-0000-0000-0000000000f1', 'decyzja zleceniodawcy P1 z 12.11.2026');
select public.app_moderate_job_offer(:'d1offer','00000000-0000-0000-0000-0000000000f2','publish',2);
select t.eq('publish D1 offer', (select status from job_offers where id = :'d1offer'), 'published');
reset role;
select t.eq('offer valid exactly 21 days', (select expires_at - published_at from job_offers where id = :'d1offer'), interval '21 days');
select t.expect('CHECK: offer longer than 21 days', format($q$update job_offers set expires_at = published_at + interval '22 days' where id = %L$q$, :'d1offer'), '23514');
set role anon; select t.as_user('','aal1');
select t.eq('anon sees published D1 offer (1)', (select count(*) from job_offers), 1::bigint);
select t.eq('anon sees employer name snapshot', (select employer_name from job_offers), 'Studio Przykładowe');
reset role;
select slug as d1slug from job_offers where id = :'d1offer' \gset
set role service_role;
select t.expect('SEC-19 relay message with URL (BP422)', format($q$select public.app_relay_job_message(%L, '{"message":"Moje portfolio: www.przyklad.pl","sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com"}')$q$, :'d1slug'), 'BP422');
select t.eq('relay to confirmed address', public.app_relay_job_message(:'d1slug', '{"message":"Dzień dobry, chętnie porozmawiam o pracy (przykład).","sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com"}') is not null, true);
reset role;
update employer_reply_addresses set verified_at = null, token_hash = t.h('x'), token_expires_at = now() where account_id = :'d1acc';
set role service_role;
select t.expect('SEC-05 relay refused when address not confirmed', format($q$select public.app_relay_job_message(%L, '{"message":"Dzień dobry (przykład).","sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com"}')$q$, :'d1slug'), 'P0001');
reset role;
update employer_reply_addresses set verified_at = now(), token_hash = null, token_expires_at = null where account_id = :'d1acc';
select t.expect('SEC-19 CHECK: phone number in offer text', format($q$update job_offers set description = description || ' Tel. 600 100 200' where id = %L$q$, :'d1offer'), '23514');
select t.expect('SEC-19 CHECK: e-mail in offer text', format($q$update job_offers set description = description || ' cv@studio.example' where id = %L$q$, :'d1offer'), '23514');
select t.eq('SEC-19 salary range and date are not a phone number', (select 'Wynagrodzenie 6000-7500 zł brutto, start 2026-12-01, tel. wewn. 12' !~ '(^|[^0-9])(\+?48[ .-]?)?([0-9]{3}[ .-]?[0-9]{3}[ .-]?[0-9]{3}|[0-9]{2}[ .-]?[0-9]{3}[ .-]?[0-9]{2}[ .-]?[0-9]{2})([^0-9]|$)'), true);
update job_offers set published_at = now() - interval '21 days', expires_at = now() - interval '1 second' where id = :'d1offer';
set role service_role;
select t.eq('expiry job (1)', public.app_expire_job_offers(), 1);
reset role;
select t.eq('offer expired', (select status from job_offers where id = :'d1offer'), 'expired');
-- GUS: company no longer active -> employer account suspended, client salon keeps account (D-B)
set role service_role;
select t.eq('GUS inactive D1', public.app_employer_record_gus(:'d1acc','system:gus','{"nip":"2223334443","result":"nieaktywny"}'), false);
select t.eq('GUS inactive salon B', public.app_employer_record_gus('bbbbbbbb-0000-0000-0000-000000000001','system:gus','{"nip":"1112223332","result":"nie-znaleziono"}'), false);
reset role;
select t.eq('D1 suspended, B active without employer verification', (select string_agg(status || ':' || coalesce(employer_verified_at::text, 'null'), ',' order by kind desc) from client_accounts where id in (:'d1acc','bbbbbbbb-0000-0000-0000-000000000001')), 'suspended:null,active:null');
set role service_role;
select public.app_employer_record_gus('bbbbbbbb-0000-0000-0000-000000000001','system:gus', :'gusB');
select t.eq('manual verification by agent when GUS down', public.app_employer_record_gus(:'d1acc','staff:00000000-0000-0000-0000-0000000000f2', :'gusD1'), true);
reset role;
select t.eq('manual record source', (select source from employer_verifications where account_id = :'d1acc' order by checked_at desc, id limit 1), 'personel');
-- staff re-activates suspended employer through RLS path? (only pending/suspended/closed allowed) -> re-activation via function only
update client_accounts set status = 'active', suspended_at = null where id = :'d1acc';  -- as postgres (staff runbook after manual check)

-- ===================== 5. job seekers =====================
select '--- 5. job seekers ---';
create function t.errmsg(p_sql text) returns text language plpgsql as $$
begin execute p_sql; return '(no error)'; exception when others then return sqlstate || ' ' || sqlerrm; end $$;
grant execute on function t.errmsg(text) to service_role;
set role service_role;
select t.expect('seeker without phone', $q$select public.app_job_seeker_register('00000000-0000-0000-0000-0000000000a1', true, 'reg-v1', 'iod-v1')$q$, 'P0001');
reset role;
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values
 ('00000000-0000-0000-0000-0000000000a1', t.h('+48600000051'), '051', now()),
 ('00000000-0000-0000-0000-0000000000a2', t.h('+48600000052'), '052', now()),
 ('00000000-0000-0000-0000-0000000000f2', t.h('+48600000053'), '053', now());
set role service_role;
select t.expect('seeker under 18', $q$select public.app_job_seeker_register('00000000-0000-0000-0000-0000000000a1', false, 'reg-v1', 'iod-v1')$q$, 'P0001');
select t.expect('staff as seeker', $q$select public.app_job_seeker_register('00000000-0000-0000-0000-0000000000f2', true, 'reg-v1', 'iod-v1')$q$, 'P0001');
select t.expect('ad before seeker account', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L, 'iod-v1')$q$, :'seek1'), 'P0001');
select public.app_job_seeker_register('00000000-0000-0000-0000-0000000000a1', true, 'reg-v1', 'iod-v1');
select public.app_job_seeker_register('00000000-0000-0000-0000-0000000000a2', true, 'reg-v1', 'iod-v1');
select t.expect('URL in description (BP422, validated before write)', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"description":"Zobacz www.przyklad.pl"}', 'iod-v1')$q$, :'seek1'), 'BP422');
select t.expect('phone in description (BP422, validated before write)', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"description":"Zadzwoń 600 100 200"}', 'iod-v1')$q$, :'seek1'), 'BP422');
select t.expect('surname in first_name (BP422, validated before write)', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"first_name":"Łucja Przykładowa"}', 'iod-v1')$q$, :'seek1'), 'BP422');
select t.eq('PRIV-12 error message without the value', t.errmsg(format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"description":"Zadzwoń 600 100 200"}', 'iod-v1')$q$, :'seek1')), 'BP422 szukam-pracy: nieprawidłowe pole description');
select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', :'seek1', 'iod-v1') as ad1 \gset
select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a2', (:'seek1')::jsonb || '{"first_name":"Ewa","city":"","voivodeship":"pomorskie"}', 'iod-v1') as ad2 \gset
select t.eq('one ad per seeker: save again updates same row', public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', (:'seek1')::jsonb || '{"city":"Wieliczka"}', 'iod-v1') = :'ad1', true);
reset role;
select t.eq('ads total (2)', (select count(*) from candidate_ads), 2::bigint);
select t.eq('ad1 version 2 after edit', (select content_version from candidate_ads where id = :'ad1'), 2);
select t.eq('PRIV-07 city optional (voivodeship only)', (select city is null from candidate_ads where id = :'ad2'), true);
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000a1','aal1');
select t.eq('seeker 1 sees own ad only (cross-tenant)', (select string_agg(first_name, ',') from candidate_ads), 'Łucja');
select t.expect('seeker reads seeker_id', $q$select seeker_id from candidate_ads$q$, '42501');
select t.expect('seeker reads moderation_note', $q$select moderation_note from candidate_ads$q$, '42501');
select t.expect('seeker inserts ad directly', $q$insert into candidate_ads (seeker_id, first_name, profession, city, voivodeship, cooperation_forms, experience, available_from, notice_version) values ('00000000-0000-0000-0000-0000000000a2','Ola','fryzjer','Łódź','lodzkie','{b2b}','do-1-roku','2026-12-01','v1')$q$, '42501');
select t.expect('seeker updates own ad directly', $q$update candidate_ads set status = 'published'$q$, '42501');
select t.eq('seeker sees own seeker row', (select count(*) from job_seekers), 1::bigint);
select t.eq('seeker employer ids (0)', (select count(*) from public.employer_account_ids()), 0::bigint);
select t.eq('seeker sees client accounts (0)', (select count(*) from client_accounts), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select t.eq('employer sees pending ads (0)', (select count(*) from candidate_ads), 0::bigint);
reset role;
set role service_role;
select t.expect('moderate stale version', format($q$select public.app_moderate_candidate_ad(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'ad1'), 'P0001');
select t.expect('moderate by employer', format($q$select public.app_moderate_candidate_ad(%L,'00000000-0000-0000-0000-0000000000d1','publish',2)$q$, :'ad1'), 'P0001');
select public.app_moderate_candidate_ad(:'ad1','00000000-0000-0000-0000-0000000000f2','publish',2);
reset role;
select t.eq('seeker ad valid exactly 21 days', (select expires_at - published_at from candidate_ads where id = :'ad1'), interval '21 days');
select t.expect('CHECK: seeker ad longer than 21 days', format($q$update candidate_ads set expires_at = published_at + interval '22 days' where id = %L$q$, :'ad1'), '23514');

-- reads after publication
select ad_ref as ad1ref from candidate_ads where id = :'ad1' \gset
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select t.eq('SEC-01 employer token + Data API: 0 rows (no employer policy)', (select count(*) from candidate_ads), 0::bigint);
select t.expect('employer reads seeker_id', $q$select seeker_id from candidate_ads$q$, '42501');
select t.expect('SEC-01 employer calls page function directly', $q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', gen_random_uuid())$q$, '42501');
select t.eq('employer sees job_seekers (0)', (select count(*) from job_seekers), 0::bigint);
select t.eq('employer sees seekers phones (0)', (select count(*) from user_phones where user_id <> '00000000-0000-0000-0000-0000000000d1'), 0::bigint);
reset role;
set role service_role;
select t.eq('trusted employer D1 page: 1 card (pending ad2 hidden)', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc')), 1::bigint);
select t.eq('card fields, ad_ref not row id', (select first_name || '/' || city || '/' || profession || '/' || (ad_ref <> :'ad1')::text from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc')), 'Łucja/Wieliczka/stylistka-paznokci/true');
select t.eq('filter by voivodeship (pomorskie: 0)', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc', null, '{"voivodeship":"pomorskie"}')), 0::bigint);
select t.eq('cursor after last card: 0', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc', (select jsonb_build_object('published_at', published_at, 'ad_ref', ad_ref) from candidate_ads where id = :'ad1'))), 0::bigint);
select t.eq('salon A owner (client, phone) page: 1', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001')), 1::bigint);
select t.expect('salon B owner without phone', $q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-00000000000b', 'bbbbbbbb-0000-0000-0000-000000000001')$q$, 'P0001');
select t.expect('employee A', $q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-000000000001')$q$, 'P0001');
select t.expect('pending employer D2', format($q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d2', %L)$q$, :'d2acc'), 'P0001');
select t.expect('D1 user for salon A account', $q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', 'aaaaaaaa-0000-0000-0000-000000000001')$q$, 'P0001');
-- SEC-01 daily quota and alert
reset role;
update app_settings set candidate_cards_per_day = 20, candidate_cards_alert = 20;
insert into candidate_ad_views_daily(account_id, day, n) values (:'d1acc', current_date, 19)
  on conflict (account_id, day) do update set n = 19, alerted_at = null;
set role service_role;
select t.eq('quota: last card of the day', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc')), 1::bigint);
select t.expect('quota exhausted -> BP429', format($q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', %L)$q$, :'d1acc'), 'BP429');
reset role;
select t.eq('alert to team once', (select count(*) from outbox_emails where template = 'candidate_views_alert' and account_id = :'d1acc'), 1::bigint);
update app_settings set candidate_cards_per_day = 200, candidate_cards_alert = 150;
delete from candidate_ad_views_daily;
-- PRIV-07 hidden NIPs
set role service_role;
select t.expect('hide invalid NIP', $q$select public.app_candidate_hidden_nips_set('00000000-0000-0000-0000-0000000000a1', array['1234567890'])$q$, 'BP422');
select public.app_candidate_hidden_nips_set('00000000-0000-0000-0000-0000000000a1', array['222-333-44-43']);
select t.eq('PRIV-07 D1 (hidden NIP) page: 0', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc')), 0::bigint);
select t.eq('PRIV-07 salon A still sees: 1', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001')), 1::bigint);
select public.app_candidate_hidden_nips_set('00000000-0000-0000-0000-0000000000a1', '{}');
reset role;
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000a2','aal1');
select t.eq('seeker 2 sees only own pending ad', (select string_agg(first_name || ':' || status, ',') from candidate_ads), 'Ewa:pending_review');
select t.as_user('00000000-0000-0000-0000-0000000000f2','aal2');
select t.eq('staff sees moderation queue (2)', (select count(*) from candidate_ads), 2::bigint);
reset role;
set role anon; select t.as_user('','aal1');
select t.expect('anon reads candidate_ads', $q$select count(*) from candidate_ads$q$, '42501');
select t.expect('anon reads job_seekers', $q$select count(*) from job_seekers$q$, '42501');
select t.expect('anon reads user_phones', $q$select count(*) from user_phones$q$, '42501');
select t.expect('anon reads employer_verifications', $q$select count(*) from employer_verifications$q$, '42501');
select t.expect('anon calls employer_account_ids', $q$select public.employer_account_ids()$q$, '42501');
reset role;

-- contact relay employer -> seeker (p_ad = ad_ref)
\set msg '{"message":"Dzień dobry, zapraszamy na rozmowę w studiu (przykład).","reply_to":"rekrutacja@studio-przyklad.example"}'
set role service_role;
select t.expect('owner B (no phone) contacts', format($q$select public.app_candidate_contact(%L,'bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000b',%L)$q$, :'ad1ref', :'msg'), 'P0001');
select t.expect('employee contacts', format($q$select public.app_candidate_contact(%L,'aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000e1',%L)$q$, :'ad1ref', :'msg'), 'P0001');
select t.expect('D1 contacts as salon A', format($q$select public.app_candidate_contact(%L,'aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1',%L)$q$, :'ad1ref', :'msg'), 'P0001');
select t.expect('contact by row id instead of ad_ref', format($q$select public.app_candidate_contact(%L,%L,'00000000-0000-0000-0000-0000000000d1',%L)$q$, :'ad1', :'d1acc', :'msg'), 'P0001');
select t.expect('contact to pending ad', format($q$select public.app_candidate_contact((select ad_ref from candidate_ads where id = %L),%L,'00000000-0000-0000-0000-0000000000d1',%L)$q$, :'ad2', :'d1acc', :'msg'), 'P0001');
select t.expect('SEC-06 phone number in message', format($q$select public.app_candidate_contact(%L,%L,'00000000-0000-0000-0000-0000000000d1','{"message":"Proszę o kontakt pod numerem 600 100 200 (przykład).","reply_to":"rekrutacja@studio-przyklad.example"}')$q$, :'ad1ref', :'d1acc'), 'BP422');
select t.expect('SEC-06 messenger in message', format($q$select public.app_candidate_contact(%L,%L,'00000000-0000-0000-0000-0000000000d1','{"message":"Napisz do nas na WhatsApp, szybciej odpowiemy (przykład).","reply_to":"rekrutacja@studio-przyklad.example"}')$q$, :'ad1ref', :'d1acc'), 'BP422');
select t.expect('SEC-05 reply_to not confirmed for account', format($q$select public.app_candidate_contact(%L,%L,'00000000-0000-0000-0000-0000000000d1','{"message":"Dzień dobry, zapraszamy na rozmowę (przykład).","reply_to":"hr@ergo-hestia-rekrutacja.example"}')$q$, :'ad1ref', :'d1acc'), 'BP422');
select t.eq('D1 contacts seeker 1', public.app_candidate_contact(:'ad1ref', :'d1acc', '00000000-0000-0000-0000-0000000000d1', :'msg') is not null, true);
select t.expect('D1 second message to same ad', format($q$select public.app_candidate_contact(%L,%L,'00000000-0000-0000-0000-0000000000d1',%L)$q$, :'ad1ref', :'d1acc', :'msg'), 'P0001');
-- SEC-06 risk phrase -> held for moderator; salon A uses owner login address
select public.app_reply_address_from_login('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','ownera@example.com');
select public.app_candidate_contact(:'ad1ref','aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','{"message":"Przed rozmową prosimy o kaucję za materiały (przykład).","reply_to":"ownera@example.com"}') as heldcid \gset
reset role;
select t.eq('SEC-06 risk phrase: message held (not sent)', (select (next_attempt_at = 'infinity')::text || '/' || (payload->>'held') from outbox_emails o join candidate_ad_contact_log l on l.outbox_id = o.id where l.id = :'heldcid'), 'true/true');
set role service_role;
select t.expect('release by employer user', format($q$select public.app_release_candidate_contact(%L,'00000000-0000-0000-0000-0000000000d1','send')$q$, :'heldcid'), 'P0001');
select public.app_release_candidate_contact(:'heldcid','00000000-0000-0000-0000-0000000000f2','reject');
reset role;
select t.eq('SEC-06 rejected held message anonymised', (select recipient || o.status from outbox_emails o join candidate_ad_contact_log l on l.outbox_id = o.id where l.id = :'heldcid'), 'anonymizedfailed');
select t.eq('outbox recipient is marker, no e-mail', (select recipient from outbox_emails o join candidate_ad_contact_log l on l.outbox_id = o.id where l.account_id = :'d1acc'), 'user:00000000-0000-0000-0000-0000000000a1');
select t.eq('outbox payload keys', (select string_agg(k, ',' order by k) from outbox_emails o join candidate_ad_contact_log l on l.outbox_id = o.id, jsonb_object_keys(o.payload) k where l.account_id = :'d1acc'), 'contact_id,employer_city,employer_legal_name,employer_name,employer_nip,held,message,reply_to,reply_to_domain');
select t.eq('employer name in e-mail = approved display name', (select payload->>'employer_name' from outbox_emails o join candidate_ad_contact_log l on l.outbox_id = o.id where l.account_id = :'d1acc'), 'Studio Przykładowe');
update outbox_emails set status = 'sent' where template = 'candidate_contact' and status = 'pending';
set role service_role;
select t.eq('purge after send (1)', public.app_purge_relay_messages(), 1);
reset role;
select t.eq('outbox anonymised', (select string_agg(recipient || payload::text, ',') from outbox_emails where template = 'candidate_contact'), 'anonymized{},anonymized{}');
select id as cid from candidate_ad_contact_log where account_id = :'d1acc' \gset
set role service_role;
select t.expect('DSA-13 report without good-faith statement', format($q$select public.app_report_candidate_contact(%L, 'oplata-za-prace', 'Prośba o opłatę za szkolenie przed zatrudnieniem (przykład).')$q$, :'cid'), 'BP422');
select t.expect('DSA-13 report with too short justification', format($q$select public.app_report_candidate_contact(%L, 'oplata-za-prace', 'opłata', null, true)$q$, :'cid'), 'BP422');
select t.eq('seeker reports message (good faith, optional e-mail and name)', public.app_report_candidate_contact(:'cid', 'oplata-za-prace', 'Prośba o opłatę za szkolenie przed zatrudnieniem (przykład).', 'Szukam1@Example.com', true, 'Łucja Przykładowa') is not null, true);
select t.eq('employer reports ad (by ad_ref)', public.app_report_candidate_ad(:'ad1ref', 'podszywanie', 'Ogłoszenie podaje się za pracownicę innej firmy (przykład).', null, true) is not null, true);
select t.expect('report bad reason', format($q$select public.app_report_candidate_ad(%L,'nie-lubie','Uzasadnienie zgłoszenia ma ponad 20 znaków.',null,true)$q$, :'ad1ref'), 'BP422');
-- SEC-06 block employer
select t.eq('SEC-06 seeker blocks D1 via contact link', public.app_candidate_block_employer('00000000-0000-0000-0000-0000000000a1', :'cid'), true);
select t.eq('SEC-06 other user cannot use the link', public.app_candidate_block_employer('00000000-0000-0000-0000-0000000000a2', :'cid'), false);
select t.eq('SEC-06 blocked employer page: 0', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc')), 0::bigint);
reset role;
select t.eq('report points to employer D1', (select reported_account_id = :'d1acc' from abuse_reports where target = 'candidate_contact'), true);
select t.eq('DSA-13 good_faith stored', (select bool_and(good_faith) from abuse_reports), true);
-- SEC-06: two justified reports pause messaging (account quota check order: pause first)
update abuse_reports set handled_at = now(), outcome = 'uzasadnione';
insert into abuse_reports(target, reported_account_id, reason, details, good_faith, handled_at, outcome)
 values ('employer', 'aaaaaaaa-0000-0000-0000-000000000001', 'oszustwo', 'Drugie uzasadnione zgłoszenie (przykład testowy).', true, now(), 'uzasadnione'),
        ('employer', 'aaaaaaaa-0000-0000-0000-000000000001', 'oszustwo', 'Trzecie uzasadnione zgłoszenie (przykład testowy).', true, now(), 'uzasadnione');
set role service_role;
select t.expect('SEC-06 messaging paused after 2 justified reports', format($q$select public.app_candidate_contact(%L,'aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','{"message":"Dzień dobry, zapraszamy na rozmowę (przykład).","reply_to":"ownera@example.com"}')$q$, :'ad1ref'), 'P0001');
reset role;
delete from abuse_reports where target = 'employer';
update abuse_reports set handled_at = null, outcome = null;

-- flag OFF
select '--- 5b. flag off ---';
set role service_role;
select t.expect('agent disables flag', $q$select public.app_set_feature_flag('szukam_pracy', false, '00000000-0000-0000-0000-0000000000f2')$q$, 'P0001');
select public.app_set_feature_flag('szukam_pracy', false, '00000000-0000-0000-0000-0000000000f1');
select t.expect('OFF save', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L, 'iod-v1')$q$, :'seek1'), 'BP404');
select t.expect('OFF contact', format($q$select public.app_candidate_contact(%L,'aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a',%L)$q$, :'ad1', :'msg'), 'BP404');
select t.expect('OFF moderate', format($q$select public.app_moderate_candidate_ad(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'ad2'), 'BP404');
select t.expect('OFF register seeker', $q$select public.app_job_seeker_register('00000000-0000-0000-0000-0000000000b1', true, 'reg-v1', 'iod-v1')$q$, 'BP404');
select t.expect('OFF employer page', $q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001')$q$, 'BP404');
reset role;
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select t.eq('OFF employer sees (0)', (select count(*) from candidate_ads), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000f2','aal2');
select t.eq('OFF staff sees (0)', (select count(*) from candidate_ads), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000a2','aal1');
select t.eq('OFF author still sees own ad (1)', (select count(*) from candidate_ads), 1::bigint);
reset role;
set role service_role;
select t.eq('OFF author deletes ad', public.app_candidate_ad_delete('00000000-0000-0000-0000-0000000000a2'), true);
select public.app_job_seeker_close('00000000-0000-0000-0000-0000000000a2');
select public.app_set_feature_flag('szukam_pracy', true, '00000000-0000-0000-0000-0000000000f1', 'decyzja zleceniodawcy P1 z 12.11.2026');
reset role;
select t.eq('seeker 2 gone', (select count(*) from job_seekers where user_id = '00000000-0000-0000-0000-0000000000a2'), 0::bigint);
-- expiry and retention
update candidate_ads set published_at = now() - interval '21 days', expires_at = now() - interval '1 second' where id = :'ad1';
set role service_role;
select t.eq('purge: expire only (0 deleted)', public.app_purge_candidate_ads(), 0);
reset role;
select t.eq('ad1 expired', (select status from candidate_ads where id = :'ad1'), 'expired');
set role service_role;
select t.eq('employer page: expired ad hidden (0)', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-00000000000a', 'aaaaaaaa-0000-0000-0000-000000000001')), 0::bigint);
reset role;
set role service_role;
select t.eq('renew expired ad = save -> moderation', public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', :'seek1', 'iod-v1') = :'ad1', true);
select public.app_moderate_candidate_ad(:'ad1','00000000-0000-0000-0000-0000000000f2','publish',(select content_version from candidate_ads where id = :'ad1'));
reset role;
select t.eq('PRIV-07 new ad_ref after re-publication', (select ad_ref <> :'ad1ref' from candidate_ads where id = :'ad1'), true);
set role service_role;
select t.expect('remove without reasons', format($q$select public.app_moderate_candidate_ad(%L,'00000000-0000-0000-0000-0000000000f2','remove',null,null,'krótko')$q$, :'ad1'), 'P0001');
select public.app_moderate_candidate_ad(:'ad1','00000000-0000-0000-0000-0000000000f2','remove',null,null,'Ogłoszenie narusza regulamin (przykład).');
select t.expect('save after removal (appeal via staff)', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L, 'iod-v1')$q$, :'seek1'), 'P0001');
reset role;

-- ===================== 6. organiser plans and catalogue =====================
select '--- 6. organiser plans ---';
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity)
 values ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Higiena pracy w salonie (przykład)','Krótko','Opis szkolenia przykładowego.','online',now()+interval '10 days',now()+interval '10 days 2 hours',5);
select t.expect('organiser sets plan_valid_until (no grant)', $q$update trainings set plan_valid_until = now() + interval '5 years'$q$, '42501');
select t.expect('organiser inserts own plan', $q$insert into organizer_plans(organizer_id, plan_code, price_net_pln, valid_from, valid_until) values ('eeeeeeee-0000-0000-0000-000000000001','promo-12m',1,now(),now()+interval '12 months')$q$, '42501');
reset role;
select id as tr1 from trainings limit 1 \gset
set role service_role;
select t.expect('publish training without plan', format($q$select public.app_moderate_training(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'tr1'), 'P0001');
select t.expect('plan set by organiser user', $q$select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','promo-12m',now())$q$, 'P0001');
select t.expect('unknown plan code', $q$select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','vip',now())$q$, 'P0001');
select t.expect('plan start in the past', $q$select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','promo-1m',now() - interval '3 days')$q$, 'P0001');
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','promo-1m',now(),'FV/2026/11/001 (przykład)') as plan1 \gset
reset role;
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity)
 values ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Szkolenie za trzy miesiące (przykład)','Krótko','Opis szkolenia przykładowego.','online',now()+interval '90 days',now()+interval '90 days 2 hours',5);
reset role;
select id as tr2 from trainings where title like 'Szkolenie za trzy%' \gset
set role service_role;
select t.expect('BIZ-15 publish training starting after plan end', format($q$select public.app_moderate_training(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'tr2'), 'P0001');
reset role;
select t.eq('1-month plan price 1000 net', (select price_net_pln from organizer_plans where id = :'plan1'), 1000.00);
select t.expect('CHECK: 12m plan with wrong period', $q$insert into organizer_plans(organizer_id, plan_code, price_net_pln, valid_from, valid_until) values ('eeeeeeee-0000-0000-0000-000000000001','promo-12m',10000,now(),now()+interval '6 months')$q$, '23514');
set role service_role;
select public.app_moderate_training(:'tr1','00000000-0000-0000-0000-0000000000f2','publish',1);
reset role;
select t.eq('training plan_valid_until = plan end', (select plan_valid_until = (select valid_until from organizer_plans where id = :'plan1') from trainings where id = :'tr1'), true);
set role anon; select t.as_user('','aal1');
select t.eq('anon sees training with active plan (1)', (select count(*) from trainings), 1::bigint);
select t.expect('anon reads plan_valid_until', $q$select plan_valid_until from trainings$q$, '42501');
select t.expect('anon reads organizer_plans', $q$select count(*) from organizer_plans$q$, '42501');
reset role;
-- contiguous 12-month plan after the 1-month plan extends visibility
set role service_role;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','promo-12m',(select valid_until from organizer_plans where id = :'plan1')) as plan2 \gset
reset role;
select t.eq('12-month plan price 10000 net', (select price_net_pln from organizer_plans where id = :'plan2'), 10000.00);
select t.eq('contiguous plans: visible until end of 12m plan', (select plan_valid_until = (select valid_until from organizer_plans where id = :'plan2') from trainings where id = :'tr1'), true);
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
select t.eq('organiser 1 sees own plans (2)', (select count(*) from organizer_plans), 2::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000c2','aal2');
select t.eq('organiser 2 sees org 1 plans (0)', (select count(*) from organizer_plans), 0::bigint);
select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.eq('salon owner sees plans (0)', (select count(*) from organizer_plans), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000f2','aal2');
select t.eq('staff sees plans (2)', (select count(*) from organizer_plans), 2::bigint);
reset role;
-- registration: employer account cannot register (trainings for client salons, Q17)
insert into client_members(account_id, user_id, role, status) values (:'d1acc','00000000-0000-0000-0000-0000000000d3','owner','active');
set role service_role;
select t.expect('employer account registers for training', format($q$select public.app_training_register(%L,'00000000-0000-0000-0000-0000000000d1',%L,'Pracodawczyni Przykładowa','pracodawca1@example.com','org-info-v1')$q$, :'tr1', :'d1acc'), 'P0001');
select t.eq('salon owner registers', public.app_training_register(:'tr1','00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','Właścicielka Przykładowa','ownera@example.com','org-info-v1'), 'registered');
-- cancel both plans -> catalogue hides training, new registrations refused, registered keeps details access
select public.app_cancel_organizer_plan(:'plan2','00000000-0000-0000-0000-0000000000f2','Brak płatności (przykład)');
select public.app_cancel_organizer_plan(:'plan1','00000000-0000-0000-0000-0000000000f2','Brak płatności (przykład)');
select t.expect('register after plan cancelled', format($q$select public.app_training_register(%L,'00000000-0000-0000-0000-0000000000e1','aaaaaaaa-0000-0000-0000-000000000001','Pracownica Przykładowa','empa@example.com','org-info-v1')$q$, :'tr1'), 'P0001');
reset role;
set role anon; select t.as_user('','aal1');
select t.eq('anon sees training after plan cancelled (0)', (select count(*) from trainings), 0::bigint);
reset role;
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
select t.eq('organiser still sees own trainings (2, incl. pending tr2)', (select count(*) from trainings), 2::bigint);
select t.expect('SEC-01 organiser reads participants via Data API', $q$select count(*) from training_participant_contacts$q$, '42501');
reset role;
set role service_role;
select t.eq('organiser sees participant via logged function (1)', (select count(*) from public.app_training_participants(:'tr1','00000000-0000-0000-0000-0000000000c1')), 1::bigint);
select t.expect('organiser 2 reads participants of org 1', format($q$select * from public.app_training_participants(%L,'00000000-0000-0000-0000-0000000000c2')$q$, :'tr1'), 'P0001');
select t.expect('staff reads participants (minimisation)', format($q$select * from public.app_training_participants(%L,'00000000-0000-0000-0000-0000000000f2')$q$, :'tr1'), 'P0001');
reset role;
select t.eq('participants view logged', (select count(*) from client_audit_log where action = 'organizer_participants_viewed' and entity_id = :'tr1'), 1::bigint);
-- plan expiry over time (no cancel): plan valid_until in the past -> hidden
set role service_role;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','promo-1m',now()) as plan3 \gset
reset role;
set role anon; select t.as_user('','aal1');
select t.eq('anon sees training with new plan (1)', (select count(*) from trainings), 1::bigint);
reset role;
update trainings set plan_valid_until = now() - interval '1 second' where id = :'tr1';
set role anon; select t.as_user('','aal1');
select t.eq('anon after plan_valid_until passed (0)', (select count(*) from trainings), 0::bigint);
reset role;
set role service_role;
select t.eq('daily sync restores from active plan', public.app_sync_organizer_plans() >= 1, true);
select public.app_set_promotion('otwarcie-portalu', false, '00000000-0000-0000-0000-0000000000f1');
select t.expect('plan without active promotion', $q$select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000f2','promo-1m',now())$q$, 'BP409');
select public.app_set_promotion('otwarcie-portalu', true, '00000000-0000-0000-0000-0000000000f1', 'decyzja zleceniodawcy P1 z 12.11.2026');
reset role;
set role anon; select t.as_user('','aal1');
select t.eq('anon sees training after sync (1)', (select count(*) from trainings), 1::bigint);
reset role;

-- ===================== 7. retention =====================
select '--- 7. retention ---';
update client_accounts set created_at = now() - interval '8 days' where id = :'d2acc';
update abuse_reports set handled_at = now() - interval '31 days';
update phone_verifications set created_at = now() - interval '31 days', expires_at = now() - interval '31 days' + interval '5 minutes' where user_id = '00000000-0000-0000-0000-0000000000b1';
set role service_role;
select t.eq('purge verification data > 0', public.app_purge_verification_data() > 0, true);
reset role;
select t.eq('D2 unfinished registration closed, GUS name cleared', (select status || ':' || coalesce(legal_name, 'null') from client_accounts where id = :'d2acc'), 'closed:null');
select t.eq('NIP of closed registration free again', (select count(*) from client_accounts where nip = '3334445554' and status <> 'closed'), 0::bigint);
select t.eq('reporter e-mails cleared', (select count(reporter_email) from abuse_reports), 0::bigint);
select t.eq('old SMS rows gone', (select count(*) from phone_verifications where user_id = '00000000-0000-0000-0000-0000000000b1'), 0::bigint);
-- PRIV-14 additional retention
update abuse_reports set handled_at = now() - interval '13 months';
set role service_role;
select public.app_purge_verification_data();
reset role;
select t.eq('PRIV-14 report details anonymised 12 months after handling', (select count(*) from abuse_reports where details is null and anonymized_at is not null and reporter_name is null), (select count(*) from abuse_reports));
-- pending seeker ad without decision for 30 days
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-0000000000b3', t.h('+48600000093'), '093', now());
set role service_role;
select public.app_job_seeker_register('00000000-0000-0000-0000-0000000000b3', true, 'reg-v1', 'iod-v1');
select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000b3', (:'seek1')::jsonb || '{"first_name":"Ola"}', 'iod-v1') as ad3 \gset
reset role;
update candidate_ads set submitted_at = now() - interval '31 days', updated_at = now() - interval '31 days' where id = :'ad3';
set role service_role;
select public.app_purge_candidate_ads();
reset role;
select t.eq('PRIV-14 pending ad without decision 30 days deleted', (select count(*) from candidate_ads where id = :'ad3'), 0::bigint);
select t.eq('PRIV-14 author informed', (select count(*) from outbox_emails where template = 'candidate_ad_purged' and recipient = 'user:00000000-0000-0000-0000-0000000000b3'), 1::bigint);
-- job offers: expired 13 months ago -> row deleted
update job_offers set published_at = now() - interval '13 months' - interval '21 days', expires_at = now() - interval '13 months' where id = :'d1offer';
set role service_role;
select public.app_expire_job_offers();
reset role;
select t.eq('PRIV-14 offer row deleted 12 months after end', (select count(*) from job_offers where id = :'d1offer'), 0::bigint);
-- inactive job seeker: warning, then closure
update job_seekers set last_seen_at = now() - interval '13 months' where user_id = '00000000-0000-0000-0000-0000000000b3';
set role service_role;
select public.app_purge_inactive_accounts();
reset role;
select t.eq('PRIV-14 inactive seeker warned', (select count(*) from outbox_emails where template = 'account_inactive_warning' and recipient = 'user:00000000-0000-0000-0000-0000000000b3'), 1::bigint);
update job_seekers set inactivity_warned_at = now() - interval '31 days' where user_id = '00000000-0000-0000-0000-0000000000b3';
set role service_role;
select t.eq('PRIV-14 inactive seeker closed after 30 days', public.app_purge_inactive_accounts(), 1);
reset role;
select t.eq('PRIV-14 seeker row gone', (select count(*) from job_seekers where user_id = '00000000-0000-0000-0000-0000000000b3'), 0::bigint);
-- GUS data of closed accounts 12 months after closing
insert into employer_verifications(account_id, nip, source, result, checked_by, checked_at) values (:'d2acc','3334445554','gus-bir','blad-uslugi','system:gus', now() - interval '14 months');
update client_accounts set closed_at = now() - interval '13 months' where id = :'d2acc';
set role service_role;
select public.app_purge_verification_data();
reset role;
select t.eq('PRIV-14 GUS rows of account closed > 12 months deleted', (select count(*) from employer_verifications where account_id = :'d2acc'), 0::bigint);
-- SEC-16: staff edits identity of an employer account
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000f2','aal2');
select t.expect('SEC-16 staff changes legal_name of employer account', format($q$update client_accounts set legal_name = 'Inna nazwa' where id = %L$q$, :'d2acc'), 'P0001');
reset role;
update client_accounts set employer_verified_at = now(), employer_trusted_at = now(), employer_trust_method = 'list-na-adres-siedziby' where id = :'b2dup';
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000f2','aal2');
update client_accounts set nip = '5242793544' where id = :'b2dup';
reset role;
select t.eq('SEC-16 NIP change resets GUS and trust', (select (employer_verified_at is null and employer_trusted_at is null)::text from client_accounts where id = :'b2dup'), 'true');
select t.eq('SEC-16 identity change logged without values', (select payload::text from client_audit_log where action = 'account_identity_changed' and account_id = :'b2dup' order by id desc limit 1), '{"nip": true, "legal_name": false, "display_name": false}');
-- BIZ-15: plan without invoice number expires after 14 days; registration only for trainings within plan
set role service_role;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000f2','promo-1m',now()) as plan4 \gset
reset role;
update organizer_plans set created_at = now() - interval '15 days' where id = :'plan4';
set role service_role;
select public.app_sync_organizer_plans();
reset role;
select t.eq('BIZ-15 plan without invoice cancelled after 14 days', (select status from organizer_plans where id = :'plan4'), 'cancelled');
set role service_role;
select t.expect('BIZ-15 invoice by organiser user', format($q$select public.app_set_organizer_plan_invoice(%L,'00000000-0000-0000-0000-0000000000c1','FV/1/2026')$q$, :'plan3'), 'P0001');
select public.app_set_organizer_plan_invoice(:'plan3','00000000-0000-0000-0000-0000000000f2','FV/2026/11/003 (przykład)');
reset role;
update trainings set plan_valid_until = starts_at - interval '1 day' where id = :'tr1';
set role service_role;
select t.expect('BIZ-15 register for training starting after plan end', format($q$select public.app_training_register(%L,'00000000-0000-0000-0000-0000000000e1','aaaaaaaa-0000-0000-0000-000000000001','Pracownica Przykładowa','empa@example.com','org-info-v1')$q$, :'tr1'), 'P0001');
select public.app_sync_organizer_plans();
reset role;

-- ===================== 8. privileges =====================
select '--- 8. privileges ---';
select t.eq('fn exec anon (none)', (select coalesce(string_agg(p.proname, ','), '(none)') from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute') and p.proname not in (select proname from pg_proc pp join pg_depend d on d.objid = pp.oid and d.deptype = 'e')), '(none)');
select 'zone fns exec authenticated', string_agg(p.proname, ',' order by p.proname) from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and has_function_privilege('authenticated', p.oid, 'execute') and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e');
select 'P1 fns exec service_role', count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and (p.proname like 'app_%' or p.proname in ('nip_checksum_ok','promo_ad_days','organizer_plan_until','organizer_plan_sync','candidate_ad_check_payload')) and has_function_privilege('service_role', p.oid, 'execute');
select 'P1 fns NOT exec by service_role (expect app_purge_audit_log? none)', coalesce(string_agg(p.proname, ','), '(none)') from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname like 'app\_%' and not has_function_privilege('service_role', p.oid, 'execute') and p.proname <> 'app_create_lead';
select 'SECURITY DEFINER in zone', string_agg(p.proname, ',' order by p.proname) from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.prosecdef;
select 'functions without search_path', coalesce(string_agg(p.proname, ','), '(none)') from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e') and (p.proconfig is null or not exists (select 1 from unnest(p.proconfig) c where c like 'search_path=%'));
select 'tables with RLS and no policy', string_agg(c.relname, ',' order by c.relname) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity and not exists (select 1 from pg_policy p where p.polrelid = c.oid);
select 'tables without RLS', coalesce(string_agg(c.relname, ','), '(none)') from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;
select t.eq('anon column grants on P1 tables (0)', (select count(*) from information_schema.column_privileges where grantee = 'anon' and table_name in ('candidate_ads','job_seekers','user_phones','phone_verifications','employer_verifications','app_settings','app_promotions','organizer_plans','candidate_ad_contact_log','app_feature_flags')), 0::bigint);
select t.eq('authenticated grant on secrets columns (0)', (select count(*) from information_schema.column_privileges where grantee = 'authenticated' and ((table_name = 'user_phones' and column_name = 'phone_hmac') or (table_name = 'candidate_ads' and column_name in ('seeker_id','moderation_note')) or table_name = 'phone_verifications' or (table_name = 'trainings' and column_name = 'plan_valid_until'))), 0::bigint);
select t.eq('policies for public role (0)', (select count(*) from pg_policies where schemaname = 'public' and 'public' = any(roles)), 0::bigint);
select t.eq('no candidate profile/CV/application tables', (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind = 'r' and c.relname ~ '(candidate_(profile|cv)|job_applications|resume|cv_)'), 0::bigint);
select 'TEST-21 owners of SECURITY DEFINER helpers (rolsuper/bypassrls)', string_agg(distinct r.rolname || ':' || r.rolsuper || '/' || r.rolbypassrls, ',') from pg_proc p join pg_roles r on r.oid = p.proowner where p.proname in ('client_account_ids','employer_account_ids','organizer_ids');

-- ===================== 9. SEC-08 suspension takes content down =====================
select '--- 9. suspension ---';
select id as aoffer from job_offers where account_id = 'aaaaaaaa-0000-0000-0000-000000000001' \gset
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
update job_offers set status = 'draft' where id = :'aoffer';
insert into job_offer_contacts(offer_id, method, email) values (:'aoffer','formularz','ownera@example.com');
update job_offers set status = 'pending_review' where id = :'aoffer';
reset role;
set role service_role;
select public.app_moderate_job_offer(:'aoffer','00000000-0000-0000-0000-0000000000f2','publish',(select content_version from job_offers where id = :'aoffer'));
select public.app_relay_job_message((select slug from job_offers where id = :'aoffer'), '{"message":"Dzień dobry (przykład).","sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com"}') is not null;
reset role;
set role anon; select t.as_user('','aal1');
select t.eq('before suspension anon sees salon A offer (1)', (select count(*) from job_offers where id = :'aoffer'), 1::bigint);
reset role;
set role service_role;
select t.expect('suspend without reason', $q$select public.app_suspend_account('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','zle')$q$, 'BP422');
select public.app_suspend_account('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','Publikowanie ogłoszeń wprowadzających w błąd (przykład).');
reset role;
set role anon; select t.as_user('','aal1');
select t.eq('SEC-08 after suspension anon sees 0 offers of salon A', (select count(*) from job_offers where id = :'aoffer'), 0::bigint);
reset role;
select t.eq('SEC-08 pending relay to suspended account cleared', (select count(*) from outbox_emails where account_id = 'aaaaaaaa-0000-0000-0000-000000000001' and template in ('job_relay','candidate_contact') and status = 'pending'), 0::bigint);
select t.eq('SEC-08 owner informed with reason', (select count(*) from outbox_emails where template = 'account_content_removed' and account_id = 'aaaaaaaa-0000-0000-0000-000000000001' and payload ? 'reason'), 1::bigint);
select t.eq('SEC-08 suspension logged with staff actor', (select actor from client_audit_log where action = 'account_suspended' and account_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 'staff:00000000-0000-0000-0000-0000000000f2');
-- job seeker suspension
update candidate_ads set status = 'pending_review', rejection_reason = null where id = :'ad1';   -- (as after an appeal)
set role service_role;
select public.app_suspend_job_seeker('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000f2','Ogłoszenie dodane przez osobę niepełnoletnią (przykład).');
reset role;
select t.eq('SEC-08 seeker suspended, ad removed with reason', (select j.status || '/' || c.status || '/' || (c.rejection_reason is not null)::text from job_seekers j join candidate_ads c on c.seeker_id = j.user_id where j.user_id = '00000000-0000-0000-0000-0000000000a1'), 'suspended/removed/true');

-- ===================== 10. SEC-03 NIP takeover by trusted firm =====================
select '--- 10. NIP takeover ---';
set role service_role;
select public.app_employer_register('00000000-0000-0000-0000-0000000000d3','2223334443','Studio Przykładowe – właściciel (przykład)','reg-v1') as d3acc \gset
select public.app_employer_record_gus(:'d3acc','system:gus', :'gusD1');
reset role;
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-0000000000d3', t.h('+48600000033'), '033', now())
  on conflict (user_id) do nothing;
set role service_role;
select public.app_employer_trust(:'d1acc','00000000-0000-0000-0000-0000000000f2', null);
select t.eq('untrusted pending account vs active untrusted D1 -> conflict', public.app_employer_activate(:'d3acc','00000000-0000-0000-0000-0000000000d3'), 'conflict');
select public.app_employer_trust(:'d3acc','00000000-0000-0000-0000-0000000000f2','list-na-adres-siedziby');
select t.eq('trusted firm takes NIP over from untrusted account', public.app_employer_activate(:'d3acc','00000000-0000-0000-0000-0000000000d3'), 'active');
reset role;
select t.eq('previous untrusted D1 account closed', (select status from client_accounts where id = :'d1acc'), 'closed');
select t.eq('one active account per NIP', (select count(*) from client_accounts where nip = '2223334443' and status in ('active','suspended')), 1::bigint);

select 'audit P1 actions', string_agg(distinct action, ',' order by action) from client_audit_log where action in ('employer_registered','employer_gus_checked','phone_verified','job_seeker_registered','job_seeker_closed','candidate_ad_submitted','candidate_ad_deleted','promotion_changed','organizer_plan_set','organizer_plan_cancelled','account_activated');

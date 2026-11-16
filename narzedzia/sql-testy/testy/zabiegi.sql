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

-- ===================== Z. zabiegi (00, D41) =====================
reset role;
select '--- Z. zabiegi (00, D41) ---';
grant execute on function t.errmsg(text) to authenticated;
create function t.plan(p text) returns setof text language plpgsql as $$ begin return query execute 'explain ' || p; end $$;
-- Z0. lista z pliku (blok gen:zabiegi-ids)
select t.eq('Z0 zabiegi_ids: 117, first g1-01, last g4-08', (select cardinality(z)::text || '/' || z[1] || '/' || z[117] from (select public.zabiegi_ids() z) q), '117/g1-01/g4-08');
select t.eq('Z0 groups 40/38/31/8', (select string_agg(n::text, '/' order by g) from (select left(i, 2) g, count(*) n from unnest(public.zabiegi_ids()) i group by 1) q), '40/38/31/8');
select t.eq('Z0 active = all (nothing retired yet)', public.zabiegi_ids(true) = public.zabiegi_ids(), true);
select t.eq('Z0 EXECUTE: anon no, authenticated yes, service_role yes',
  has_function_privilege('anon','public.zabiegi_ids(boolean)','execute')::text || '/' || has_function_privilege('authenticated','public.zabiegi_ids(boolean)','execute')::text || '/' || has_function_privilege('service_role','public.zabiegi_ids(boolean)','execute')::text, 'false/true/true');
select t.eq('Z0 page fn and filter fn: service_role only', (select string_agg(r || ':' || has_function_privilege(r, f, 'execute')::text, ',' order by f, r) from unnest(array['anon','authenticated','service_role']) r, unnest(array['public.app_job_offers_page(jsonb,jsonb)','public.zabiegi_filter(jsonb)']) f),
  'anon:false,authenticated:false,service_role:true,anon:false,authenticated:false,service_role:true');
select t.eq('Z0 GIN indexes', (select string_agg(indexname, ',' order by indexname) from pg_indexes where indexname like '%zabiegi%'), 'candidate_ads_zabiegi_idx,job_offers_zabiegi_idx');

-- Z1. oferta: pole zabiegi zapisuje właściciel przez Data API (guard + CHECK)
\set zoff_cols '(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description, zabiegi)'
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select t.expect('Z1 offer with unknown zabieg id -> BP422', format($q$insert into job_offers %s values (%L,'draft','Stylistka paznokci (przykład)','stylistka-paznokci','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10),'{g1-03,g9-99}')$q$, :'zoff_cols', :'d1acc'), 'BP422');
select t.expect('Z1 offer with null element -> BP422', format($q$insert into job_offers %s values (%L,'draft','Stylistka paznokci (przykład)','stylistka-paznokci','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10),array['g1-03',null])$q$, :'zoff_cols', :'d1acc'), 'BP422');
select t.expect('Z1 offer with 31 zabiegi -> BP422', format($q$insert into job_offers %s values (%L,'draft','Stylistka paznokci (przykład)','stylistka-paznokci','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10),(public.zabiegi_ids())[1:31])$q$, :'zoff_cols', :'d1acc'), 'BP422');
select t.eq('Z1 error without values (PRIV-12)', t.errmsg(format($q$insert into job_offers %s values (%L,'draft','Stylistka paznokci (przykład)','stylistka-paznokci','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10),'{g9-99}')$q$, :'zoff_cols', :'d1acc')), 'BP422 job_offers: nieprawidłowe pole zabiegi');
insert into job_offers (account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description, zabiegi)
 values (:'d1acc','draft','Stylistka paznokci (przykład)','stylistka-paznokci','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10), (public.zabiegi_ids())[1:30])
 returning id as zoff \gset
select t.eq('Z1 30 zabiegi accepted', (select cardinality(zabiegi) from job_offers where id = :'zoff'), 30);
update job_offers set zabiegi = '{g2-12,g1-03,g1-03}' where id = :'zoff';
select t.eq('Z1 duplicates removed, sorted', (select zabiegi::text from job_offers where id = :'zoff'), '{g1-03,g2-12}');
select t.eq('Z1 optional: offer without zabiegi has empty array', (select zabiegi::text from job_offers where id = :'d1offer'), '{}');
insert into job_offer_contacts(offer_id, method, email) values (:'zoff','formularz','rekrutacja@studio-przyklad.example');
update job_offers set status = 'pending_review' where id = :'zoff';
reset role;
set role service_role;
select public.app_moderate_job_offer(:'zoff','00000000-0000-0000-0000-0000000000f2','publish',(select content_version from job_offers where id = :'zoff'));
reset role;
select t.eq('Z1 offer with zabiegi published', (select status from job_offers where id = :'zoff'), 'published');
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select content_version as zver from job_offers where id = :'zoff' \gset
update job_offers set zabiegi = '{g1-03,g2-12,g4-01}' where id = :'zoff';
select t.eq('Z1 zabiegi change on published offer -> moderation, version +1', (select status || '/' || (content_version = :zver + 1)::text from job_offers where id = :'zoff'), 'pending_review/true');
select t.expect('Z1 zabiegi change during moderation -> exception', format($q$update job_offers set zabiegi = '{g1-03}' where id = %L$q$, :'zoff'), 'P0001');
reset role;
set role service_role;
select public.app_moderate_job_offer(:'zoff','00000000-0000-0000-0000-0000000000f2','publish',(select content_version from job_offers where id = :'zoff'));
select t.expect('Z1 bypassing guard (service_role): unknown id -> CHECK', format($q$update job_offers set zabiegi = '{g9-99}' where id = %L$q$, :'zoff'), '23514');
select t.expect('Z1 bypassing guard (service_role): 31 ids -> CHECK', format($q$update job_offers set zabiegi = (public.zabiegi_ids())[1:31] where id = %L$q$, :'zoff'), '23514');
reset role;
select t.expect('Z1 bypassing guard (postgres): null element -> CHECK', format($q$update job_offers set zabiegi = array['g1-03',null] where id = %L$q$, :'zoff'), '23514');
-- anon (Data API): kolumna zabiegi publiczna, RLS bez zmian
set role anon; select t.as_user('','aal1');
select t.eq('Z1 anon reads zabiegi of published offer', (select zabiegi::text from job_offers where id = :'zoff'), '{g1-03,g2-12,g4-01}');
select t.eq('Z1 anon overlap filter (PostgREST ov)', (select count(*) from job_offers where zabiegi && '{g4-01,g3-05}'), 1::bigint);
select t.expect('Z1 anon still cannot read account_id', $q$select account_id from job_offers$q$, '42501');
select t.expect('Z1 anon cannot call page function', $q$select * from public.app_job_offers_page('{}')$q$, '42501');
select t.expect('Z1 anon cannot call zabiegi_ids', $q$select public.zabiegi_ids()$q$, '42501');
reset role;
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select t.expect('Z1 authenticated cannot call page function', $q$select * from public.app_job_offers_page('{}')$q$, '42501');
reset role;

-- Z2. publiczna lista: filtr LUB, kolejność od najnowszej, 20 na stronę, kursor
-- fixtures (as postgres, guard bypassed): 22 published offers of salon A with controlled published_at
insert into job_offers (slug, account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description, employer_name, published_at, expires_at, zabiegi)
select 'kosmetolog-krakow-z' || i, 'aaaaaaaa-0000-0000-0000-000000000001', 'published', 'Oferta ' || i || ' (przykład)', 'kosmetolog', 'umowa-o-prace', 'pelny-etat', 'Kraków', 'malopolskie', 6000, 7500, 'MONTH',
       repeat('Opis ogłoszenia przykładowego. ', 10), 'Salon Przykładowy A', now() - make_interval(hours => i), now() - make_interval(hours => i) + interval '21 days',
       case i when 1 then '{g2-12}'::text[] when 2 then '{g2-12,g3-05,g4-01}'::text[] when 3 then '{g3-05}'::text[] else '{}'::text[] end
  from generate_series(1, 22) i;
set role service_role;
select t.eq('Z2 no filter: 20 per page', (select count(*) from public.app_job_offers_page('{}')), 20::bigint);
select t.eq('Z2 newest first', (select bool_and(ok) from (select published_at <= lag(published_at) over (order by published_at desc, id desc) or lag(published_at) over (order by published_at desc, id desc) is null as ok from public.app_job_offers_page('{}')) q), true);
select t.eq('Z2 cursor: next page has the rest', (select count(*) from public.app_job_offers_page('{}', (select jsonb_build_object('published_at', published_at, 'id', id) from public.app_job_offers_page('{}') order by published_at asc, id asc limit 1))), 3::bigint);
select t.eq('Z2 filter one zabieg (g2-12): D1 offer, offers 1, 2', (select string_agg(title, ',' order by published_at desc) from public.app_job_offers_page('{"zabiegi":["g2-12"]}')), 'Stylistka paznokci (przykład),Oferta 1 (przykład),Oferta 2 (przykład)');
select t.eq('Z2 OR filter (g3-05 OR g4-01): D1 offer + 2 + 3, newest first, not by number of matches',
  (select string_agg(title, ',' order by published_at desc) from public.app_job_offers_page('{"zabiegi":["g4-01","g3-05"]}')), 'Stylistka paznokci (przykład),Oferta 2 (przykład),Oferta 3 (przykład)');
select t.eq('Z2 OR filter keeps chronological order (offer 2 has 2 matches, D1 offer 1)', (select title from public.app_job_offers_page('{"zabiegi":["g4-01","g3-05"]}') limit 1), 'Stylistka paznokci (przykład)');
select t.eq('Z2 zabiegi + profession combined (AND across filters)', (select count(*) from public.app_job_offers_page('{"zabiegi":["g4-01","g3-05"],"profession":"kosmetolog"}')), 2::bigint);
select t.eq('Z2 empty zabiegi array = no filter', (select count(*) from public.app_job_offers_page('{"zabiegi":[]}')), 20::bigint);
select t.eq('Z2 duplicates in filter ignored', (select count(*) from public.app_job_offers_page('{"zabiegi":["g2-12","g2-12"]}')), 3::bigint);
select t.expect('Z2 unknown id in filter -> BP422', $q$select * from public.app_job_offers_page('{"zabiegi":["g2-12","g9-99"]}')$q$, 'BP422');
select t.expect('Z2 non-string in filter -> BP422', $q$select * from public.app_job_offers_page('{"zabiegi":[12]}')$q$, 'BP422');
select t.expect('Z2 filter not an array -> BP422', $q$select * from public.app_job_offers_page('{"zabiegi":"g2-12"}')$q$, 'BP422');
select t.eq('Z2 result has no match score column', (select count(*) from information_schema.routines r join information_schema.parameters p on p.specific_name = r.specific_name where r.routine_name in ('app_job_offers_page','app_candidate_ads_page') and p.parameter_mode = 'OUT' and p.parameter_name ~ '(score|match|dopas|rank)'), 0::bigint);
reset role;
-- GIN in plan at realistic size (5000 published offers, few with g2-12) – in a rolled-back transaction
begin;
insert into job_offers (slug, account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description, employer_name, published_at, expires_at, zabiegi)
select 'kosmetolog-krakow-p' || i, 'aaaaaaaa-0000-0000-0000-000000000001', 'published', 'Oferta P' || i || ' (przykład)', (array['kosmetolog','fryzjer','podolog','linergistka'])[1 + i % 4], 'umowa-o-prace', 'pelny-etat', 'Kraków', 'malopolskie', 6000, 7500, 'MONTH',
       repeat('Opis ogłoszenia przykładowego. ', 10), 'Salon Przykładowy A', now() - make_interval(mins => i), now() - make_interval(mins => i) + interval '21 days',
       case when i % 500 = 0 then '{g2-12}'::text[] else array[(public.zabiegi_ids())[1 + i % 40]] end
  from generate_series(1, 5000) i;
analyze job_offers;
select t.eq('Z2 GIN index used for zabiegi && (service_role path, 5000 offers)', (select bool_or(l ~ 'job_offers_zabiegi_idx') from t.plan($q$select id from public.job_offers o where o.status = 'published' and o.expires_at > now() and o.zabiegi && '{g2-12}'::text[] order by o.published_at desc, o.id desc limit 20$q$) l), true);
select 'Z2 plan (info)', l from t.plan($q$select id from public.job_offers o where o.status = 'published' and o.expires_at > now() and o.zabiegi && '{g2-12}'::text[] order by o.published_at desc, o.id desc limit 20$q$) l;
grant execute on function t.plan(text) to anon;
set role anon; select t.as_user('','aal1');
select 'Z2 anon plan under RLS (info)', l from t.plan($q$select id from public.job_offers o where o.zabiegi && '{g2-12}'::text[] order by o.published_at desc, o.id desc limit 20$q$) l;
reset role;
rollback;

-- Z3. „Szukam pracy”: pole i filtr; RLS, kwota i service_role bez zmian
set role service_role;
select t.expect('Z3 seeker ad: unknown zabieg -> BP422', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"zabiegi":["g1-03","g9-99"]}', 'iod-v1')$q$, :'seek1'), 'BP422');
select t.eq('Z3 error message without the value', t.errmsg(format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"zabiegi":["g9-99"]}', 'iod-v1')$q$, :'seek1')), 'BP422 szukam-pracy: nieprawidłowe pole zabiegi');
select t.expect('Z3 seeker ad: 31 zabiegi -> BP422', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || jsonb_build_object('zabiegi', to_jsonb((public.zabiegi_ids())[1:31])), 'iod-v1')$q$, :'seek1'), 'BP422');
select t.expect('Z3 seeker ad: null element -> BP422', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"zabiegi":["g1-03",null]}', 'iod-v1')$q$, :'seek1'), 'BP422');
select t.expect('Z3 seeker ad: zabiegi not an array -> BP422', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', %L::jsonb || '{"zabiegi":"g1-03"}', 'iod-v1')$q$, :'seek1'), 'BP422');
select t.eq('Z3 seeker ad saved with zabiegi', public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', (:'seek1')::jsonb || '{"city":"Wieliczka","zabiegi":["g2-12","g1-03","g1-03"]}', 'iod-v1') = :'ad1', true);
reset role;
select t.eq('Z3 stored normalized, back in moderation', (select zabiegi::text || '/' || status from candidate_ads where id = :'ad1'), '{g1-03,g2-12}/pending_review');
select t.expect('Z3 CHECK on candidate_ads (bypass): unknown id', format($q$update candidate_ads set zabiegi = '{g9-99}' where id = %L$q$, :'ad1'), '23514');
set role service_role;
select public.app_moderate_candidate_ad(:'ad1','00000000-0000-0000-0000-0000000000f2','publish',(select content_version from candidate_ads where id = :'ad1'));
reset role;
-- author reads own zabiegi through Data API; employer still 0 rows (SEC-01)
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000a1','aal1');
select t.eq('Z3 author reads own zabiegi (Data API)', (select zabiegi::text from candidate_ads), '{g1-03,g2-12}');
select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
select t.eq('Z3 employer token + Data API: still 0 rows', (select count(*) from candidate_ads), 0::bigint);
select t.eq('Z3 employer token: overlap filter does not leak (0)', (select count(*) from candidate_ads where zabiegi && '{g2-12}'), 0::bigint);
reset role;
select coalesce((select n::int from candidate_ad_views_daily where account_id = :'d1acc' and day = current_date), 0) as zviews0 \gset
set role service_role;
select t.eq('Z3 page filter g2-12: 1 card', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc', null, '{"zabiegi":["g2-12"]}')), 1::bigint);
select t.eq('Z3 page returns zabiegi', (select zabiegi::text from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc', null, '{"zabiegi":["g1-03"]}')), '{g1-03,g2-12}');
select t.eq('Z3 page filter g4-01: 0 cards', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc', null, '{"zabiegi":["g4-01"]}')), 0::bigint);
select t.eq('Z3 page OR filter (g4-01 OR g1-03): 1 card', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc', null, '{"zabiegi":["g4-01","g1-03"]}')), 1::bigint);
select t.eq('Z3 page zabiegi + voivodeship (AND across filters): 0', (select count(*) from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', :'d1acc', null, '{"zabiegi":["g1-03"],"voivodeship":"pomorskie"}')), 0::bigint);
reset role;
select coalesce((select n::int from candidate_ad_views_daily where account_id = :'d1acc' and day = current_date), 0) as zviews1 \gset
select t.eq('Z3 quota counts returned cards only (3 cards)', :zviews1 - :zviews0, 3);
set role service_role;
select t.expect('Z3 page unknown id -> BP422', format($q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000d1', %L, null, '{"zabiegi":["g9-99"]}')$q$, :'d1acc'), 'BP422');
reset role;
select t.eq('Z3 rejected filter does not consume quota', (select n::int from candidate_ad_views_daily where account_id = :'d1acc' and day = current_date), :zviews1);
set role service_role;
select t.expect('Z3 page untrusted actor still refused before filter', $q$select * from public.app_candidate_ads_page('00000000-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-000000000001', null, '{"zabiegi":["g1-03"]}')$q$, 'P0001');
reset role;

-- Z4. wycofanie pozycji z listy (symulacja nowej wersji bloku: g4-01 wycofane)
create table t.zfn as select pg_get_functiondef('public.zabiegi_ids(boolean)'::regprocedure) d;
-- build the "retired" variant from the original: active = all minus g4-01, retired = {g4-01}
select replace(replace(d, '''g4-01'',', ''), 'v_wycofane text[] := array[]::text[]', 'v_wycofane text[] := array[''g4-01'']::text[]') from t.zfn \gexec
select t.eq('Z4 retired variant: 116 active, 117 known', cardinality(public.zabiegi_ids(true))::text || '/' || cardinality(public.zabiegi_ids())::text, '116/117');
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000d1','aal2');
update job_offers set status = 'closed' where id = :'zoff';
select t.eq('Z4 offer keeps retired g4-01 (non-content update ok)', (select status || '/' || ('g4-01' = any(zabiegi))::text from job_offers where id = :'zoff'), 'closed/true');
insert into job_offers (account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description, zabiegi)
 values (:'d1acc','draft','Podolog (przykład)','podolog','b2b','elastyczny','Poznań','wielkopolskie',40,60,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10), '{g4-02}')
 returning id as zoff2 \gset
select t.expect('Z4 cannot add retired id to an offer', format($q$update job_offers set zabiegi = '{g4-01,g4-02}' where id = %L$q$, :'zoff2'), 'BP422');
update job_offers set zabiegi = '{g4-02,g4-03}' where id = :'zoff2';
select t.eq('Z4 active ids still accepted', (select zabiegi::text from job_offers where id = :'zoff2'), '{g4-02,g4-03}');
reset role;
update candidate_ads set zabiegi = '{g1-03,g4-01}' where id = :'ad1';   -- as before retirement
set role service_role;
select t.eq('Z4 seeker re-save keeps retired g4-01', public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a1', (:'seek1')::jsonb || '{"zabiegi":["g1-03","g4-01"]}', 'iod-v1') = :'ad1', true);
select t.expect('Z4 seeker cannot add retired id (seeker 2)', format($q$select public.app_candidate_ad_save('00000000-0000-0000-0000-0000000000a2', %L::jsonb || '{"first_name":"Ewa","zabiegi":["g4-01"]}', 'iod-v1')$q$, :'seek1'), 'BP422');
select t.eq('Z4 filter by retired id still accepted (old links)', (select count(*) from public.app_job_offers_page('{"zabiegi":["g4-01"]}')), 1::bigint);
reset role;
select d from t.zfn \gexec
select t.eq('Z4 original list restored', cardinality(public.zabiegi_ids(true)), 117);
select '--- Z. end ---';

\set ON_ERROR_STOP 0
\pset tuples_only on
\set VERBOSITY terse
-- Scenariusze 2–10 testu lokalnego Strefy (dok. 11): konta salonów i zaproszenia, organizatorzy i szkolenia,
-- „Dam pracę”, pracownik, anon, formularz kontaktowy, zapisy na szkolenia, dziennik audytu, uprawnienia.
-- Asercje: t.expect (kod błędu) i t.eq (wartość). Wyjątki z funkcji mają wspólny kod P0001, więc tam t.eq
-- porównuje kod i treść komunikatu (t.errmsg) – inaczej odmowa z innego powodu przeszłaby jako „ok”.
-- Wywołania funkcji void: t.errmsg(…) = '(no error)'.
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
create function t.errmsg(p_sql text) returns text language plpgsql as $$
begin execute p_sql; return '(no error)'; exception when others then return sqlstate || ' ' || sqlerrm; end $$;
grant execute on function t.errmsg(text) to anon, authenticated, service_role;
create function t.as_user(p_sub text, p_aal text) returns void language sql as $$
  select set_config('request.jwt.claim.sub', p_sub, false), set_config('request.jwt.claims', '{"aal":"' || p_aal || '"}', false);
$$;
grant execute on function t.as_user(text, text) to anon, authenticated, service_role;
create function t.h(p text) returns text language sql immutable as $$ select encode(digest(p, 'sha256'), 'hex') $$;
grant execute on function t.h(text) to anon, authenticated, service_role;

-- ===================== fixtures (postgres) =====================
insert into auth.users values ('00000000-0000-0000-0000-00000000000a','ownera@example.com'),
 ('00000000-0000-0000-0000-00000000000b','ownerb@example.com'),
 ('00000000-0000-0000-0000-0000000000e1','empa@example.com'),
 ('00000000-0000-0000-0000-0000000000f1','staff@example.com'),
 ('00000000-0000-0000-0000-0000000000c1','org1@example.com'),
 ('00000000-0000-0000-0000-0000000000c2','org2@example.com');
insert into admin_users(user_id, role) select '00000000-0000-0000-0000-0000000000f1','admin';
insert into pricing_versions(id, product,label,valid_from,is_active,source_note,approved_by_label,approved_at)
 values ('11111111-1111-1111-1111-111111111111','oc-beauty','t','2026-01-01',true,'t','x',now());
-- salon A z odwołaniem do CRM: crm_tenant i crm_ref tylko razem (CHECK client_accounts_check4)
insert into client_accounts(id, display_name, crm_tenant, crm_ref) values ('aaaaaaaa-0000-0000-0000-000000000001','Salon Przykładowy A','tenant-przyklad','crm-1'),('bbbbbbbb-0000-0000-0000-000000000001','Salon Przykładowy B',null,null);
-- OC beauty (00, D43): gabinet kosmetologiczny, 1–5 osób, suma 200 000 zł, ochrona prawna = 790 + 92 = 882 zł
-- (snippets/oc-skladka.js z taryfa-oc-beauty.json); dawniej oc_risk_groups '{2}', oc_tariff_group 2, 'do-5'
insert into client_policies(id, account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to, premium_amount, premium_period, oc_rodzaje, oc_kategoria, oc_sum_insured, oc_legal_protection, oc_team_size_band, pricing_version_id, published_at)
 values ('cccccccc-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','oc-beauty','ergo-hestia','OC','BP/2026/000123 (przykład)','active','2026-01-01','2026-12-31',882,'year','{kosmetologiczny}','kosmetologiczny',200000,true,'1-5','11111111-1111-1111-1111-111111111111',now());
-- D-A: salon B ma tylko Tax Protect (bez kwoty – taryfa spoza audytu)
insert into client_policies(id, account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to, published_at)
 values ('cccccccc-0000-0000-0000-00000000000b','bbbbbbbb-0000-0000-0000-000000000001','tax-protect','colonnade','Tax Protect','BP/2026/000124 (przykład)','active','2026-01-01','2026-12-31',now());
select t.eq('activate A', public.app_activate_client_account('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownera@example.com', t.h('tokA')) is not null, true);
select t.eq('activate B (Tax Protect only, D-A)', public.app_activate_client_account('bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownerb@example.com', t.h('tokB')) is not null, true);
select t.eq('accept A (e-mail in other case)', public.app_accept_invitation(t.h('tokA'),'00000000-0000-0000-0000-00000000000a','OwnerA@example.com'), 'aaaaaaaa-0000-0000-0000-000000000001'::uuid);
select t.eq('accept B', public.app_accept_invitation(t.h('tokB'),'00000000-0000-0000-0000-00000000000b','ownerb@example.com'), 'bbbbbbbb-0000-0000-0000-000000000001'::uuid);
select t.eq('invite emp', public.app_create_invitation('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','empa@example.com','employee', t.h('tokE')) is not null, true);
select t.eq('accept emp', public.app_accept_invitation(t.h('tokE'),'00000000-0000-0000-0000-0000000000e1','empa@example.com'), 'aaaaaaaa-0000-0000-0000-000000000001'::uuid);
select t.eq('ERR rotate accepted invitation of A (by owner B)', t.errmsg($q$select public.app_rotate_invitation_token((select id from client_invitations where email='empa@example.com'),'00000000-0000-0000-0000-00000000000b',t.h('tokZ'))$q$), 'P0001 rotate: zaproszenie nieaktywne');
select t.eq('staff invites owner A as employee', public.app_create_invitation('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownera@example.com','employee', t.h('tokD')) is not null, true);
-- odmowa z braku uprawnień – na aktywnym zaproszeniu salonu A (wyżej zaproszenie było już przyjęte)
select t.eq('ERR rotate active A invite by owner B (not a member of A)', t.errmsg($q$select public.app_rotate_invitation_token((select id from client_invitations where email='ownera@example.com' and accepted_at is null),'00000000-0000-0000-0000-00000000000b',t.h('tokZ'))$q$), 'P0001 rotate: brak uprawnień');
select t.eq('rotate by staff ok', t.errmsg($q$select public.app_rotate_invitation_token((select id from client_invitations where email='ownera@example.com' and accepted_at is null),'00000000-0000-0000-0000-0000000000f1',t.h('tokD2'))$q$), '(no error)');
select t.eq('ERR downgrade owner (rotated token)', t.errmsg($q$select public.app_accept_invitation(t.h('tokD2'),'00000000-0000-0000-0000-00000000000a','ownera@example.com')$q$), 'P0001 accept: ta osoba jest już właścicielem salonu – zaproszenie obniżyłoby jej rolę');
select t.eq('ERR owner A into admin_users', t.errmsg($q$insert into admin_users(user_id, role) values ('00000000-0000-0000-0000-00000000000a','viewer')$q$), 'P0001 admin_users: konto klienta, pracodawcy, organizatora lub osoby szukającej pracy nie może być kontem personelu');
insert into client_policy_documents(policy_id, account_id, kind, title, storage_path, mime_type, size_bytes, sha256, published_at)
 values ('cccccccc-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','polisa','Polisa','aaaaaaaa-0000-0000-0000-000000000001/cccccccc-0000-0000-0000-00000000000a/x.pdf','application/pdf',1000,repeat('a',64),now());
insert into storage.objects(bucket_id,name) values ('client-documents','aaaaaaaa-0000-0000-0000-000000000001/cccccccc-0000-0000-0000-00000000000a/x.pdf');

-- ===================== staff creates and verifies organisers (RLS path, aal2) =====================
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000f1','aal2');
insert into training_organizers(kind, display_name, legal_name, nip, city, status) values
 ('firma','Organizator przykładowy','Organizator Przykładowy sp. z o.o.','1111111111','Kraków','pending'),
 ('firma','Inny organizator (przykład)','Inny Organizator s.c.','2222222222','Gdańsk','pending');
insert into training_organizers(kind, account_id, display_name, legal_name, nip, city, status) values
 ('salon','aaaaaaaa-0000-0000-0000-000000000001','Salon Przykładowy A – szkolenia','Salon Przykładowy A','3333333333','Kraków','pending');
select t.expect('ERR staff insert salon organiser without account', $q$insert into training_organizers(kind, display_name, legal_name, nip) values ('salon','x y','x y','4444444444')$q$, '23514');
select t.expect('ERR staff activates without verification', $q$update training_organizers set status='active' where nip='1111111111'$q$, '23514');
select t.expect('ERR staff changes account_id (no grant)', $q$update training_organizers set account_id=null where nip='3333333333'$q$, '42501');
update training_organizers set status='active', verified_at=now(), verified_by='00000000-0000-0000-0000-0000000000f1', terms_version='org-v1';
select t.eq('staff sees organisers (3)', (select count(*) from training_organizers), 3::bigint);
reset role;
select id as org_a from training_organizers where nip='1111111111' \gset
select id as org_b from training_organizers where nip='2222222222' \gset
select id as org_s from training_organizers where nip='3333333333' \gset
select t.eq('audit organizer events (3 created, 3 verified)', (select string_agg(action || ':' || n, ',' order by action) from (select action, count(*) n from client_audit_log where entity='organizer' group by 1) q), 'organizer_created:3,organizer_verified:3');
select t.eq('org invite o1', public.app_create_organizer_invitation(:'org_a','00000000-0000-0000-0000-0000000000f1','org1@example.com','owner',t.h('tokO1')) is not null, true);
select t.eq('org invite o2', public.app_create_organizer_invitation(:'org_b','00000000-0000-0000-0000-0000000000f1','org2@example.com','owner',t.h('tokO2')) is not null, true);
select t.eq('org invite ownerA to salon-organiser', public.app_create_organizer_invitation(:'org_s','00000000-0000-0000-0000-0000000000f1','ownera@example.com','owner',t.h('tokOS')) is not null, true);
select t.eq('ERR client token as organiser token', t.errmsg($q$select public.app_accept_organizer_invitation(t.h('tokD2'),'00000000-0000-0000-0000-00000000000a','ownera@example.com')$q$), 'P0001 organizer accept: zaproszenie wygasło albo zostało użyte');
select t.eq('accept o1', public.app_accept_organizer_invitation(t.h('tokO1'),'00000000-0000-0000-0000-0000000000c1','org1@example.com'), :'org_a'::uuid);
select t.eq('accept o2', public.app_accept_organizer_invitation(t.h('tokO2'),'00000000-0000-0000-0000-0000000000c2','org2@example.com'), :'org_b'::uuid);
select t.eq('accept ownerA as organiser', public.app_accept_organizer_invitation(t.h('tokOS'),'00000000-0000-0000-0000-00000000000a','ownera@example.com'), :'org_s'::uuid);
-- P1 prelude: NIP w GUS + telefon dla salonów A i B, plan organizatora A
update client_accounts set nip='9876543210' where id='aaaaaaaa-0000-0000-0000-000000000001';
update client_accounts set nip='1112223332' where id='bbbbbbbb-0000-0000-0000-000000000001';
select t.eq('P1 gus A', public.app_employer_record_gus('aaaaaaaa-0000-0000-0000-000000000001','system:gus', '{"nip":"9876543210","result":"aktywny","regon":"123456785","entity_type":"P","legal_name":"Salon Przykładowy A sp. z o.o.","city":"Kraków","postal_code":"30-001"}'), true);
select t.eq('P1 gus B', public.app_employer_record_gus('bbbbbbbb-0000-0000-0000-000000000001','system:gus', '{"nip":"1112223332","result":"aktywny","regon":"123456786","entity_type":"P","legal_name":"Salon Przykładowy B s.c.","city":"Gdańsk","postal_code":"80-001"}'), true);
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-00000000000a', repeat('1',64),'001',now()), ('00000000-0000-0000-0000-00000000000b', repeat('2',64),'002',now());
select t.eq('P1 plan org A', public.app_set_organizer_plan(:'org_a','00000000-0000-0000-0000-0000000000f1','promo-12m',now(),'FV/2026/11/001 (przykład)') is not null, true);
select t.eq('staff invited to organiser (invitation itself is created)', public.app_create_organizer_invitation(:'org_a','00000000-0000-0000-0000-0000000000f1','staff@example.com','member',t.h('tokSt')) is not null, true);
select t.eq('ERR staff as organiser (accept)', t.errmsg($q$select public.app_accept_organizer_invitation(t.h('tokSt'),'00000000-0000-0000-0000-0000000000f1','staff@example.com')$q$), 'P0001 organizer accept: konto personelu nie może należeć do organizatora');

-- ===================== organiser o1 =====================
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
select t.eq('ERR o1 insert published', t.errmsg(format($q$insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (%L,'published','Szkolenie przykładowe','s','d','online',now()+interval '10 days',now()+interval '10 days 2 hours',1)$q$, :'org_a')), 'P0001 trainings: nowe szkolenie może być tylko szkicem albo trafić do moderacji');
select t.expect('ERR o1 insert for org B (RLS)', format($q$insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (%L,'draft','Szkolenie cudze','s','d','online',now()+interval '10 days',now()+interval '10 days 2 hours',1)$q$, :'org_b'), '42501');
select t.expect('ERR o1 insert URL in description', format($q$insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (%L,'draft','Szkolenie z linkiem','s','Zapisy: https://evil.example','online',now()+interval '10 days',now()+interval '10 days 2 hours',1)$q$, :'org_a'), '23514');
select t.expect('ERR o1 sets published_at (no grant)', format($q$insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, published_at) values (%L,'draft','Szkolenie przykładowe','s','d','online',now()+interval '10 days',now()+interval '10 days 2 hours',now())$q$, :'org_a'), '42501');
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (:'org_a','pending_review','Higiena pracy w salonie – ERGO (przykład)','Krótko','Opis szkolenia przykładowego.','online',now()+interval '10 days',now()+interval '10 days 2 hours',1);
select t.eq('o1 slug (no reserved term) / status / version / seats', (select (slug ~ '^szkolenie-[0-9a-f]{8}$')::text || '/' || status || '/' || content_version || '/' || seats_registered from trainings), 'true/pending_review/1/0');
select t.expect('ERR o1 update capacity', $q$update trainings set capacity=50$q$, '42501');
select t.eq('ERR o1 update content during review', t.errmsg($q$update trainings set summary='zmiana'$q$), 'P0001 trainings: szkolenie jest w moderacji – wycofaj je do szkicu, aby zmienić treść');
-- w moderacji odmowa zapada przed sprawdzeniem adresu; sam adres – niżej, na szkicu (evil host in draft / path trick)
select t.eq('ERR o1 private details evil host (during review)', t.errmsg($q$insert into training_private_details(training_id, online_join_url) select id,'https://evil.example/zoom.us' from trainings$q$), 'P0001 training_private_details: szkolenie jest w moderacji');
select t.eq('ERR o1 private details during review', t.errmsg($q$insert into training_private_details(training_id, online_join_url) select id,'https://zoom.us/j/123' from trainings$q$), 'P0001 training_private_details: szkolenie jest w moderacji');
update trainings set status='draft';
select t.expect('ERR evil host in draft', $q$insert into training_private_details(training_id, online_join_url) select id,'https://zoom.us.evil.example/j/1' from trainings$q$, '23514');
select t.expect('ERR evil host path trick', $q$insert into training_private_details(training_id, online_join_url) select id,'https://evil.example/https://zoom.us/' from trainings$q$, '23514');
insert into training_private_details(training_id, online_join_url) select id,'https://us02web.zoom.us/j/123' from trainings;
update trainings set status='pending_review';
select t.eq('o1 version after resubmit (2)', (select content_version::int from trainings), 2);
select t.eq('o1 sees client_accounts (0)', (select count(*) from client_accounts), 0::bigint);
select t.eq('o1 sees client_policies (0)', (select count(*) from client_policies), 0::bigint);
select t.eq('o1 sees job_offers (0)', (select count(*) from job_offers), 0::bigint);
select t.eq('o1 sees training_registrations (0)', (select count(*) from training_registrations), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000c1','aal1');
select t.eq('o1 aal1 sees own trainings (0)', (select count(*) from trainings), 0::bigint);
reset role;

-- ===================== staff moderates training =====================
select t.eq('ERR moderate training stale version', t.errmsg($q$select public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',1)$q$), 'P0001 moderate training: szkolenie zmieniono w trakcie moderacji (wersja 2, oczekiwano 1)');
select t.eq('moderate training ok', t.errmsg($q$select public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',2)$q$), '(no error)');
select t.eq('training status / published_at set', (select status || '/' || (published_at is not null)::text from trainings), 'published/true');
-- o1 edits a published training -> back to review
set role authenticated;
select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
update trainings set summary='Krótko, poprawione';
select t.eq('o1 edit published -> pending_review v3', (select status || '/' || content_version from trainings), 'pending_review/3');
update trainings set status='draft';
-- zmiana szczegółów prywatnych opublikowanego szkolenia – niżej, po ponownej publikacji
reset role;
-- resubmit and publish
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
update trainings set status='pending_review';
reset role;
select t.eq('publish again after resubmit', t.errmsg($q$select public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',(select content_version from trainings limit 1))$q$), '(no error)');
select t.eq('published version (v3 edit, v4 resubmit)', (select status || '/' || content_version from trainings), 'published/4');
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
update training_private_details set online_join_url='https://meet.google.com/abc-defg-hij';
select t.eq('o1 private details change on published -> pending_review', (select status from trainings), 'pending_review');
reset role;
select t.eq('publish again', t.errmsg($q$select public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',(select content_version from trainings limit 1))$q$), '(no error)');

-- ===================== owner A: job offers =====================
set role authenticated;
select t.as_user('00000000-0000-0000-0000-00000000000a','aal1');
select t.eq('A aal1 sees accounts (0 – TOTP mandatory for owners)', (select count(*) from client_accounts), 0::bigint);
select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.eq('A sees accounts (1)', (select count(*) from client_accounts), 1::bigint);
select t.expect('ERR A reads crm_ref', $q$select crm_ref from client_accounts$q$, '42501');
select t.expect('ERR A reads crm_tenant', $q$select crm_tenant from client_accounts$q$, '42501');
select t.eq('A sees policies (1)', (select count(*) from client_policies), 1::bigint);
select t.eq('A sees docs (1)', (select count(*) from client_policy_documents), 1::bigint);
select t.eq('A sees storage obj (1)', (select count(*) from storage.objects), 1::bigint);
select t.eq('A sees members (2)', (select count(*) from client_members), 2::bigint);
select t.eq('A (also organiser S) sees trainings of org A? published only (1)', (select count(*) from trainings), 1::bigint);
select t.expect('ERR A offer with URL', $q$insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','pending_review','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10) || 'www.example.com')$q$, '23514');
select t.expect('ERR A sets slug (no grant)', $q$insert into job_offers(account_id, slug, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','aura-consulting-rekrutuje','draft','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10))$q$, '42501');
insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','pending_review','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10));
select t.eq('A offer: slug / employer / status / version', (select (slug ~ '^kosmetolog-krakow-[0-9a-f]{8}$')::text || '/' || employer_name || '/' || status || '/' || content_version from job_offers), 'true/Salon Przykładowy A/pending_review/1');
select t.eq('ERR A edit during review (bait-and-switch)', t.errmsg($q$update job_offers set description = repeat('Praca za granicą, wpłać zaliczkę. ',10)$q$), 'P0001 job_offers: ogłoszenie jest w moderacji – wycofaj je do szkicu, aby zmienić treść');
select t.eq('ERR A contacts during review', t.errmsg($q$insert into job_offer_contacts(offer_id, method, email) select id,'formularz','rekrutacja@salon-a.example' from job_offers$q$), 'P0001 job_offer_contacts: ogłoszenie jest w moderacji – wycofaj je do szkicu, aby zmienić kontakt');
update job_offers set status='draft';
insert into job_offer_contacts(offer_id, method, email) select id,'formularz','rekrutacja@salon-a.example' from job_offers;
update job_offers set status='pending_review';
select t.eq('A version (2)', (select content_version::int from job_offers), 2);
select t.eq('ERR A set published', t.errmsg($q$update job_offers set status='published'$q$), 'P0001 job_offers: niedozwolona zmiana statusu pending_review → published');
select t.expect('ERR A set published_at', $q$update job_offers set published_at=now()$q$, '42501');
select t.expect('ERR A call app fn', $q$select public.app_expire_job_offers()$q$, '42501');
reset role;
-- v1.4 (SEC-05): adres rekrutacyjny potwierdzony linkiem przed moderacją
select t.eq('reply address request', t.errmsg($q$select public.app_reply_address_request('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','rekrutacja@salon-a.example', t.h('tokRA'))$q$), '(no error)');
select t.eq('reply address confirmed', public.app_reply_address_confirm(t.h('tokRA')), true);
select t.eq('ERR moderate stale version', t.errmsg($q$select public.app_moderate_job_offer((select id from job_offers limit 1),'00000000-0000-0000-0000-0000000000f1','publish',1)$q$), 'P0001 moderate: ogłoszenie zmieniono w trakcie moderacji (wersja 2, oczekiwano 1)');
select t.eq('moderate ok', t.errmsg($q$select public.app_moderate_job_offer((select id from job_offers limit 1),'00000000-0000-0000-0000-0000000000f1','publish',2)$q$), '(no error)');
select t.eq('offer status', (select status from job_offers), 'published');
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
update job_offer_contacts set method='telefon', phone='+48 600 000 000';
select t.eq('A contact change on published -> pending_review (v3)', (select status || '/' || content_version from job_offers), 'pending_review/3');
-- draft limit
insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 select 'aaaaaaaa-0000-0000-0000-000000000001','draft','Fryzjer (przykład) '||g,'fryzjer','umowa-o-prace','pelny-etat','Aura','malopolskie',5000,6000,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10) from generate_series(1,4) g;
select t.eq('reserved city dropped from slug', (select count(*) from job_offers where slug ~ '^fryzjer-[0-9a-f]{8}$'), 4::bigint);
select t.eq('ERR 6th draft/pending', t.errmsg($q$insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','draft','Fryzjer (przykład) 6','fryzjer','umowa-o-prace','pelny-etat','Kraków','malopolskie',5000,6000,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10))$q$), 'P0001 job_offers: limit 5 ogłoszeń w szkicu lub w moderacji na salon');
reset role;
select t.eq('republish A', t.errmsg($q$select public.app_moderate_job_offer((select id from job_offers where profession='kosmetolog'),'00000000-0000-0000-0000-0000000000f1','publish',3)$q$), '(no error)');
-- salon B: no active policy anymore (D-B)
update client_policies set status='expired' where account_id='bbbbbbbb-0000-0000-0000-000000000001';
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000b','aal2');
select t.eq('B (expired policy) still sees account (D-B) (1)', (select count(*) from client_accounts), 1::bigint);
select t.eq('B sees archival policy (1)', (select count(*) from client_policies), 1::bigint);
insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('bbbbbbbb-0000-0000-0000-000000000001','draft','Podolog (przykład)','podolog','b2b','elastyczny','Gdańsk','pomorskie',60,90,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10));
insert into job_offer_contacts(offer_id, method, phone) select id,'telefon','600 000 001' from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001';
update job_offers set status='pending_review' where account_id='bbbbbbbb-0000-0000-0000-000000000001';
select t.eq('B sees A contacts (0)', (select count(*) from job_offer_contacts where account_id='aaaaaaaa-0000-0000-0000-000000000001'), 0::bigint);
select t.expect('ERR B writes contact for A offer', $q$insert into job_offer_contacts(offer_id, method, phone) select id,'telefon','600 000 002' from job_offers where profession='kosmetolog'$q$, '42501');
with u as (update job_offers set title='hack hack' where profession='kosmetolog' returning 1)
select t.eq('B update A offer (0 rows)', count(*), 0::bigint) from u;
reset role;
update client_accounts set employer_verified_at = now() - interval '121 days' where id='bbbbbbbb-0000-0000-0000-000000000001';
select t.eq('ERR publish B without NIP check', t.errmsg($q$select public.app_moderate_job_offer((select id from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001'),'00000000-0000-0000-0000-0000000000f1','publish',2)$q$), 'P0001 moderate: NIP pracodawcy wymaga ponownego sprawdzenia w GUS albo konto jest nieaktywne');
select t.eq('P1 gus B again', public.app_employer_record_gus('bbbbbbbb-0000-0000-0000-000000000001','system:gus', '{"nip":"1112223332","result":"aktywny","regon":"123456786","entity_type":"P","legal_name":"Salon Przykładowy B s.c.","city":"Gdańsk","postal_code":"80-001"}'), true);
select t.eq('publish B with NIP check', t.errmsg($q$select public.app_moderate_job_offer((select id from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001'),'00000000-0000-0000-0000-0000000000f1','publish',2)$q$), '(no error)');

-- ===================== employee A =====================
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000e1','aal1');
select t.eq('E sees policies (0)', (select count(*) from client_policies), 0::bigint);
select t.eq('E sees docs (0)', (select count(*) from client_policy_documents), 0::bigint);
select t.eq('E sees storage (0)', (select count(*) from storage.objects), 0::bigint);
select t.eq('E sees contacts (0)', (select count(*) from job_offer_contacts), 0::bigint);
select t.eq('E sees own salon offers (5)', (select count(*) from job_offers where account_id='aaaaaaaa-0000-0000-0000-000000000001'), 5::bigint);
reset role;

-- ===================== anon =====================
set role anon; select t.as_user('','aal1');
select t.eq('anon offers (2)', (select count(*) from job_offers), 2::bigint);
select t.expect('ERR anon account_id', $q$select account_id from job_offers$q$, '42501');
select t.expect('ERR anon contacts', $q$select count(*) from job_offer_contacts$q$, '42501');
select t.eq('anon trainings (1)', (select count(*) from trainings), 1::bigint);
select t.eq('anon organisers (3) + name', (select count(display_name) from training_organizers), 3::bigint);
select t.expect('ERR anon organiser status', $q$select status from training_organizers$q$, '42501');
select t.expect('ERR anon policies', $q$select count(*) from client_policies$q$, '42501');
select t.expect('ERR anon organizer_ids', $q$select public.organizer_ids()$q$, '42501');
reset role;

-- ===================== relay form =====================
select t.eq('ERR relay to phone-only offer', t.errmsg($q$select public.app_relay_job_message((select slug from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001'), '{"sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com","message":"Dzień dobry"}')$q$), 'P0001 relay: salon nie przyjmuje wiadomości przez formularz');
-- A switched to phone too; switch back to form via staff path? use postgres to set form contact
update job_offer_contacts set method='formularz' where account_id='aaaaaaaa-0000-0000-0000-000000000001';
select t.eq('relay ok', public.app_relay_job_message((select slug from job_offers where profession='kosmetolog'), '{"sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com","message":"Dzień dobry, chętnie porozmawiam."}') is not null, true);
select t.eq('outbox has message', (select recipient || '/' || (payload ? 'message')::text from outbox_emails where template='job_relay'), 'rekrutacja@salon-a.example/true');
update outbox_emails set status='sent' where template='job_relay';
select t.eq('purge after send', public.app_purge_relay_messages((select id from outbox_emails where template='job_relay')), 1);
select t.eq('outbox purged', (select recipient || '/' || payload::text from outbox_emails where template='job_relay'), 'anonymized/{}');
select t.eq('relay log has no PII columns', (select string_agg(column_name, ',' order by ordinal_position) from information_schema.columns where table_name='job_offer_relay_log'), 'id,offer_id,outbox_id,created_at');

-- ===================== trainings: registration, organiser view =====================
select t.eq('reg A', public.app_training_register((select id from trainings limit 1),'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','Właścicielka Przykładowa','ownera@example.com','org-info-v1'), 'registered');
select t.eq('reg E (waitlist)', public.app_training_register((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000e1','aaaaaaaa-0000-0000-0000-000000000001','Pracownica Przykładowa','empa@example.com','org-info-v1'), 'waitlisted');
select t.eq('ERR reg without notice', t.errmsg($q$select public.app_training_register((select id from trainings limit 1),'00000000-0000-0000-0000-00000000000b','bbbbbbbb-0000-0000-0000-000000000001','B','ownerb@example.com',null)$q$), 'P0001 register: brak informacji o przekazaniu danych organizatorowi');
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
reset role; select t.eq('o1 sees contacts via fn (1 registered, waitlist hidden)', (select count(*) from public.app_training_participants((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1')), 1::bigint);
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
-- tabela kontaktów celowo nie ma user_id, a odczyt przez Data API jest zablokowany (organizator czyta funkcją)
select t.expect('ERR o1 reads registrations user_id (no such column in contacts)', $q$select user_id from training_participant_contacts$q$, '42703');
select t.expect('ERR o1 reads contacts via Data API', $q$select count(*) from training_participant_contacts$q$, '42501');
select t.eq('o1 sees registrations (0)', (select count(*) from training_registrations), 0::bigint);
select t.eq('o1 sees private details (1)', (select count(*) from training_private_details), 1::bigint);
reset role;
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c2','aal2');
select t.expect('ERR o2 reads contacts via Data API', $q$select count(*) from training_participant_contacts$q$, '42501');
select t.eq('o2 sees org A private details (0)', (select count(*) from training_private_details), 0::bigint);
select t.eq('o2 sees client_members (0)', (select count(*) from client_members), 0::bigint);
reset role;
select t.eq('ERR capacity by o2', t.errmsg($q$select public.app_training_set_capacity((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c2',5)$q$), 'P0001 capacity: brak uprawnień');
select t.eq('capacity 2 by o1 promotes (1 from waitlist)', public.app_training_set_capacity((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1',2), 1);
select t.eq('ERR capacity below seats', t.errmsg($q$select public.app_training_set_capacity((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1',1)$q$), 'P0001 capacity: limit nie może być mniejszy niż liczba zapisanych i zarezerwowanych (2)');
select t.eq('seats registered / capacity', (select seats_registered || '/' || capacity from trainings), '2/2');
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
reset role; select t.eq('o1 sees contacts via fn (2)', (select count(*) from public.app_training_participants((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1')), 2::bigint);
reset role;
select t.eq('ERR attendance before start', t.errmsg($q$select public.app_training_mark_attendance((select id from training_registrations limit 1),'00000000-0000-0000-0000-0000000000c1','attended')$q$), 'P0001 attendance: szkolenie jeszcze się nie rozpoczęło');
select t.eq('log organiser view', t.errmsg($q$select public.app_log_organizer_access((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1','organizer_participants_viewed')$q$), '(no error)');
select t.eq('ERR o2 log on A training', t.errmsg($q$select public.app_log_organizer_access((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c2','organizer_participants_exported')$q$), 'P0001 organizer log: brak uprawnień');
-- employee sees private details while active
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000e1','aal1');
select t.eq('E sees private details (1)', (select count(*) from training_private_details), 1::bigint);
reset role;
update client_members set last_seen_at = now() - interval '13 months' where user_id='00000000-0000-0000-0000-0000000000e1';
select t.eq('dormant revoked (1)', public.app_revoke_dormant_members(), 1);
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000e1','aal1');
select t.eq('E after revoke sees private details (0)', (select count(*) from training_private_details), 0::bigint);
reset role;
select t.eq('cancel A by staff', t.errmsg($q$select public.app_training_cancel((select id from trainings limit 1),'00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000000f1')$q$), '(no error)');
select t.eq('audit actor for staff cancel (staff/all)', (select count(*) filter (where actor like 'staff:%') || '/' || count(*) from client_audit_log where action='training_cancelled'), '1/1');
select t.eq('contacts after cancel (1)', (select count(*) from training_participant_contacts), 1::bigint);
select t.eq('cancel event by o1', t.errmsg($q$select public.app_training_cancel_event((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1','Choroba prowadzącej (przykład)')$q$), '(no error)');
select t.eq('training status', (select status from trainings), 'cancelled');

-- ===================== audit log integrity =====================
select t.eq('ERR truncate audit (postgres)', t.errmsg($q$truncate client_audit_log$q$), 'P0001 client_audit_log: TRUNCATE zabroniony');
select t.eq('ERR update audit', t.errmsg($q$update client_audit_log set action='policy_updated' where id=1$q$), 'P0001 client_audit_log: wpisów nie można zmieniać');
set role service_role;
select t.expect('ERR service_role delete audit', $q$delete from client_audit_log$q$, '42501');
select t.expect('ERR service_role truncate audit', $q$truncate client_audit_log$q$, '42501');
reset role;
select t.eq('purge audit (0)', public.app_purge_audit_log(), 0);
select 'audit rows (info)', count(*) from client_audit_log;
select t.eq('audit actors (role prefixes only)', (select string_agg(a, ', ' order by a) from (select distinct split_part(actor, ':', 1) || case when actor like 'system:%' then ':' || split_part(actor, ':', 2) else '' end a from client_audit_log) q),
  'staff, system, system:capacity, system:dormant, system:gus, system:reply-address, user');

-- ===================== privileges (bez funkcji rozszerzeń – w Supabase pgcrypto jest w schemacie extensions) =====================
select t.eq('fn exec anon (none)', (select coalesce(string_agg(p.proname, ',' order by p.proname), '(none)') from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and has_function_privilege('anon', p.oid, 'execute') and not exists (select 1 from pg_depend d where d.objid=p.oid and d.deptype='e')), '(none)');
select t.eq('fn exec authenticated', (select string_agg(p.proname, ',' order by p.proname) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and has_function_privilege('authenticated', p.oid, 'execute') and not exists (select 1 from pg_depend d where d.objid=p.oid and d.deptype='e')),
  'app_is_staff,client_account_ids,employer_account_ids,organizer_ids,zabiegi_ids');
select t.eq('tables with RLS and no policy (service_role only)', (select string_agg(c.relname, ',' order by c.relname) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' and c.relrowsecurity and not exists (select 1 from pg_policy p where p.polrelid=c.oid)),
  'candidate_ad_contact_log,candidate_ad_views_daily,candidate_blocks,client_policy_reminders,job_offer_relay_log,newsletter_subscribers,outbox_emails,phone_verifications,sms_send_log,training_participant_contacts');
select t.eq('job_applications gone', to_regclass('public.job_applications') is null, true);

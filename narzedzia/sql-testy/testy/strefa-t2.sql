\set ON_ERROR_STOP 0
\pset tuples_only on
\set VERBOSITY terse
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
insert into client_accounts(id, display_name, crm_ref) values ('aaaaaaaa-0000-0000-0000-000000000001','Salon Przykładowy A','crm-1'),('bbbbbbbb-0000-0000-0000-000000000001','Salon Przykładowy B',null);
insert into client_policies(id, account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to, premium_amount, premium_period, oc_risk_groups, oc_tariff_group, oc_sum_insured, oc_legal_protection, oc_team_size_band, pricing_version_id, published_at)
 values ('cccccccc-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','oc-beauty','ergo-hestia','OC','BP/2026/000123 (przykład)','active','2026-01-01','2026-12-31',882,'year','{2}',2,200000,true,'do-5','11111111-1111-1111-1111-111111111111',now());
-- D-A: salon B ma tylko Tax Protect (bez kwoty – taryfa spoza audytu)
insert into client_policies(id, account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to, published_at)
 values ('cccccccc-0000-0000-0000-00000000000b','bbbbbbbb-0000-0000-0000-000000000001','tax-protect','colonnade','Tax Protect','BP/2026/000124 (przykład)','active','2026-01-01','2026-12-31',now());
select 'activate A', public.app_activate_client_account('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownera@example.com', encode(digest('tokA','sha256'),'hex')) is not null;
select 'activate B (Tax Protect only, D-A)', public.app_activate_client_account('bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownerb@example.com', encode(digest('tokB','sha256'),'hex')) is not null;
select 'accept A', public.app_accept_invitation(encode(digest('tokA','sha256'),'hex'),'00000000-0000-0000-0000-00000000000a','OwnerA@example.com');
select 'accept B', public.app_accept_invitation(encode(digest('tokB','sha256'),'hex'),'00000000-0000-0000-0000-00000000000b','ownerb@example.com');
select 'invite emp', public.app_create_invitation('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','empa@example.com','employee', encode(digest('tokE','sha256'),'hex')) is not null;
select 'accept emp', public.app_accept_invitation(encode(digest('tokE','sha256'),'hex'),'00000000-0000-0000-0000-0000000000e1','empa@example.com');
select 'ERR expected: rotate A invite by owner B'; select public.app_rotate_invitation_token((select id from client_invitations where email='empa@example.com'),'00000000-0000-0000-0000-00000000000b',encode(digest('tokZ','sha256'),'hex'));
select 'staff invites owner A as employee', public.app_create_invitation('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownera@example.com','employee', encode(digest('tokD','sha256'),'hex')) is not null;
select 'rotate by staff ok'; select public.app_rotate_invitation_token((select id from client_invitations where email='ownera@example.com' and accepted_at is null),'00000000-0000-0000-0000-0000000000f1',encode(digest('tokD2','sha256'),'hex'));
select 'ERR expected: downgrade owner'; select public.app_accept_invitation(encode(digest('tokD2','sha256'),'hex'),'00000000-0000-0000-0000-00000000000a','ownera@example.com');
select 'ERR expected: owner A into admin_users'; insert into admin_users(user_id, role) values ('00000000-0000-0000-0000-00000000000a','viewer');
insert into client_policy_documents(policy_id, account_id, kind, title, storage_path, mime_type, size_bytes, sha256, published_at)
 values ('cccccccc-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','polisa','Polisa','aaaaaaaa-0000-0000-0000-000000000001/cccccccc-0000-0000-0000-00000000000a/x.pdf','application/pdf',1000,repeat('a',64),now());
insert into storage.objects(bucket_id,name) values ('client-documents','aaaaaaaa-0000-0000-0000-000000000001/cccccccc-0000-0000-0000-00000000000a/x.pdf');

-- ===================== staff creates and verifies organisers (RLS path, aal2) =====================
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000f1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
insert into training_organizers(kind, display_name, legal_name, nip, city, status) values
 ('firma','Organizator przykładowy','Organizator Przykładowy sp. z o.o.','1111111111','Kraków','pending'),
 ('firma','Inny organizator (przykład)','Inny Organizator s.c.','2222222222','Gdańsk','pending');
insert into training_organizers(kind, account_id, display_name, legal_name, nip, city, status) values
 ('salon','aaaaaaaa-0000-0000-0000-000000000001','Salon Przykładowy A – szkolenia','Salon Przykładowy A','3333333333','Kraków','pending');
select 'ERR expected: staff insert salon organiser without account'; insert into training_organizers(kind, display_name, legal_name, nip) values ('salon','x y','x y','4444444444');
select 'ERR expected: staff activates without verification'; update training_organizers set status='active' where nip='1111111111';
select 'ERR expected: staff changes account_id (no grant)'; update training_organizers set account_id=null where nip='3333333333';
update training_organizers set status='active', verified_at=now(), verified_by='00000000-0000-0000-0000-0000000000f1', terms_version='org-v1';
select 'staff sees organisers (3)', count(*) from training_organizers;
reset role;
select id as org_a from training_organizers where nip='1111111111' \gset
select id as org_b from training_organizers where nip='2222222222' \gset
select id as org_s from training_organizers where nip='3333333333' \gset
select 'audit organizer events', count(*) from client_audit_log where entity='organizer';
select 'org invite o1', public.app_create_organizer_invitation(:'org_a','00000000-0000-0000-0000-0000000000f1','org1@example.com','owner',encode(digest('tokO1','sha256'),'hex')) is not null;
select 'org invite o2', public.app_create_organizer_invitation(:'org_b','00000000-0000-0000-0000-0000000000f1','org2@example.com','owner',encode(digest('tokO2','sha256'),'hex')) is not null;
select 'org invite ownerA to salon-organiser', public.app_create_organizer_invitation(:'org_s','00000000-0000-0000-0000-0000000000f1','ownera@example.com','owner',encode(digest('tokOS','sha256'),'hex')) is not null;
select 'ERR expected: client token as organiser token'; select public.app_accept_organizer_invitation(encode(digest('tokD2','sha256'),'hex'),'00000000-0000-0000-0000-00000000000a','ownera@example.com');
select 'accept o1', public.app_accept_organizer_invitation(encode(digest('tokO1','sha256'),'hex'),'00000000-0000-0000-0000-0000000000c1','org1@example.com');
select 'accept o2', public.app_accept_organizer_invitation(encode(digest('tokO2','sha256'),'hex'),'00000000-0000-0000-0000-0000000000c2','org2@example.com');
select 'accept ownerA as organiser', public.app_accept_organizer_invitation(encode(digest('tokOS','sha256'),'hex'),'00000000-0000-0000-0000-00000000000a','ownera@example.com');
-- P1 prelude: NIP w GUS + telefon dla salonów A i B, plan organizatora A
update client_accounts set nip='9876543210' where id='aaaaaaaa-0000-0000-0000-000000000001';
update client_accounts set nip='1112223332' where id='bbbbbbbb-0000-0000-0000-000000000001';
select 'P1 gus A', public.app_employer_record_gus('aaaaaaaa-0000-0000-0000-000000000001','system:gus', '{"nip":"9876543210","result":"aktywny","regon":"123456785","entity_type":"P","legal_name":"Salon Przykładowy A sp. z o.o.","city":"Kraków","postal_code":"30-001"}');
select 'P1 gus B', public.app_employer_record_gus('bbbbbbbb-0000-0000-0000-000000000001','system:gus', '{"nip":"1112223332","result":"aktywny","regon":"123456786","entity_type":"P","legal_name":"Salon Przykładowy B s.c.","city":"Gdańsk","postal_code":"80-001"}');
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values ('00000000-0000-0000-0000-00000000000a', repeat('1',64),'001',now()), ('00000000-0000-0000-0000-00000000000b', repeat('2',64),'002',now());
select 'P1 plan org A', public.app_set_organizer_plan(:'org_a','00000000-0000-0000-0000-0000000000f1','promo-12m',now(),'FV/2026/11/001 (przykład)') is not null;
select 'ERR expected: staff as organiser'; select public.app_create_organizer_invitation(:'org_a','00000000-0000-0000-0000-0000000000f1','staff@example.com','member',encode(digest('tokSt','sha256'),'hex')) is not null;
select public.app_accept_organizer_invitation(encode(digest('tokSt','sha256'),'hex'),'00000000-0000-0000-0000-0000000000f1','staff@example.com');

-- ===================== organiser o1 =====================
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
select 'ERR expected: o1 insert published'; insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (:'org_a','published','Szkolenie przykładowe','s','d','online',now()+interval '10 days',now()+interval '10 days 2 hours',1);
select 'ERR expected: o1 insert for org B (RLS)'; insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (:'org_b','draft','Szkolenie cudze','s','d','online',now()+interval '10 days',now()+interval '10 days 2 hours',1);
select 'ERR expected: o1 insert URL in description'; insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (:'org_a','draft','Szkolenie z linkiem','s','Zapisy: https://evil.example','online',now()+interval '10 days',now()+interval '10 days 2 hours',1);
select 'ERR expected: o1 sets published_at (no grant)'; insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, published_at) values (:'org_a','draft','Szkolenie przykładowe','s','d','online',now()+interval '10 days',now()+interval '10 days 2 hours',now());
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity) values (:'org_a','pending_review','Higiena pracy w salonie – ERGO (przykład)','Krótko','Opis szkolenia przykładowego.','online',now()+interval '10 days',now()+interval '10 days 2 hours',1);
select 'o1 slug (no reserved term)', slug, status, content_version, seats_registered from trainings;
select 'ERR expected: o1 update capacity'; update trainings set capacity=50;
select 'ERR expected: o1 update content during review'; update trainings set summary='zmiana';
select 'ERR expected: o1 private details evil host'; insert into training_private_details(training_id, online_join_url) select id,'https://evil.example/zoom.us' from trainings;
select 'ERR expected: o1 private details during review'; insert into training_private_details(training_id, online_join_url) select id,'https://zoom.us/j/123' from trainings;
update trainings set status='draft';
select 'ERR expected: evil host in draft'; insert into training_private_details(training_id, online_join_url) select id,'https://zoom.us.evil.example/j/1' from trainings;
select 'ERR expected: evil host path trick'; insert into training_private_details(training_id, online_join_url) select id,'https://evil.example/https://zoom.us/' from trainings;
insert into training_private_details(training_id, online_join_url) select id,'https://us02web.zoom.us/j/123' from trainings;
update trainings set status='pending_review';
select 'o1 version after resubmit (2)', content_version from trainings;
select 'o1 sees client_accounts (0)', count(*) from client_accounts;
select 'o1 sees client_policies (0)', count(*) from client_policies;
select 'o1 sees job_offers (0)', count(*) from job_offers;
select 'o1 sees training_registrations (0)', count(*) from training_registrations;
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
select 'o1 aal1 sees own trainings (0)', count(*) from trainings;
reset role;

-- ===================== staff moderates training =====================
select 'ERR expected: moderate training stale version'; select public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',1);
select 'moderate training ok', public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',2);
select 'training status', status, published_at is not null from trainings;
-- o1 edits a published training -> back to review
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
update trainings set summary='Krótko, poprawione';
select 'o1 edit published -> pending_review v3', status, content_version from trainings;
update trainings set status='draft';
select 'ERR expected: o1 private details change when published handled later';
reset role;
-- resubmit and publish
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
update trainings set status='pending_review';
reset role;
select 'publish v5', public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',(select content_version from trainings limit 1));
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
update training_private_details set online_join_url='https://meet.google.com/abc-defg-hij';
select 'o1 private details change on published -> pending_review', status from trainings;
reset role;
select 'publish again', public.app_moderate_training((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000f1','publish',(select content_version from trainings limit 1));

-- ===================== owner A: job offers =====================
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000000a',false), set_config('request.jwt.claims','{"aal":"aal1"}',false);
select 'A aal1 sees accounts (0 – TOTP mandatory for owners)', count(*) from client_accounts;
select set_config('request.jwt.claims','{"aal":"aal2"}',false);
select 'A sees accounts (1)', count(*) from client_accounts;
select 'ERR expected: A reads crm_ref'; select crm_ref from client_accounts;
select 'A sees policies (1)', count(*) from client_policies;
select 'A sees docs (1)', count(*) from client_policy_documents;
select 'A sees storage obj (1)', count(*) from storage.objects;
select 'A sees members (2)', count(*) from client_members;
select 'A (also organiser S) sees trainings of org A? published only (1)', count(*) from trainings;
select 'ERR expected: A offer with URL'; insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','pending_review','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10) || 'www.example.pl');
select 'ERR expected: A sets slug (no grant)'; insert into job_offers(account_id, slug, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','aura-consulting-rekrutuje','draft','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10));
insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','pending_review','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10));
select 'A offer', slug ~ '^kosmetolog-krakow-[0-9a-f]{8}$', employer_name, status, content_version from job_offers;
select 'ERR expected: A edit during review (bait-and-switch)'; update job_offers set description = repeat('Praca za granicą, wpłać zaliczkę. ',10);
select 'ERR expected: A contacts during review'; insert into job_offer_contacts(offer_id, method, email) select id,'formularz','rekrutacja@salon-przyklad.pl' from job_offers;
update job_offers set status='draft';
insert into job_offer_contacts(offer_id, method, email) select id,'formularz','rekrutacja@salon-przyklad.pl' from job_offers;
update job_offers set status='pending_review';
select 'A version (2)', content_version from job_offers;
select 'ERR expected: A set published'; update job_offers set status='published';
select 'ERR expected: A set published_at'; update job_offers set published_at=now();
select 'ERR expected: A call app fn'; select public.app_expire_job_offers();
reset role;
-- v1.4 (SEC-05): adres rekrutacyjny potwierdzony linkiem przed moderacją
select public.app_reply_address_request('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','rekrutacja@salon-przyklad.pl', encode(digest('tokRA','sha256'),'hex'));
select 'reply address confirmed', public.app_reply_address_confirm(encode(digest('tokRA','sha256'),'hex'));
select 'ERR expected: moderate stale version'; select public.app_moderate_job_offer((select id from job_offers limit 1),'00000000-0000-0000-0000-0000000000f1','publish',1);
select 'moderate ok', public.app_moderate_job_offer((select id from job_offers limit 1),'00000000-0000-0000-0000-0000000000f1','publish',2);
select 'offer status', status from job_offers;
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000000a',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
update job_offer_contacts set method='telefon', phone='+48 600 000 000';
select 'A contact change on published -> pending_review (v3)', status, content_version from job_offers;
-- draft limit
insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 select 'aaaaaaaa-0000-0000-0000-000000000001','draft','Fryzjer (przykład) '||g,'fryzjer','umowa-o-prace','pelny-etat','Aura','malopolskie',5000,6000,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10) from generate_series(1,4) g;
select 'reserved city dropped from slug', count(*) from job_offers where slug ~ '^fryzjer-[0-9a-f]{8}$';
select 'ERR expected: 6th draft/pending'; insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('aaaaaaaa-0000-0000-0000-000000000001','draft','Fryzjer (przykład) 6','fryzjer','umowa-o-prace','pelny-etat','Kraków','malopolskie',5000,6000,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10));
reset role;
select 'republish A', public.app_moderate_job_offer((select id from job_offers where profession='kosmetolog'),'00000000-0000-0000-0000-0000000000f1','publish',3);
-- salon B: no active policy anymore (D-B)
update client_policies set status='expired' where account_id='bbbbbbbb-0000-0000-0000-000000000001';
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000000b',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
select 'B (expired policy) still sees account (D-B) (1)', count(*) from client_accounts;
select 'B sees archival policy (1)', count(*) from client_policies;
insert into job_offers(account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values ('bbbbbbbb-0000-0000-0000-000000000001','draft','Podolog (przykład)','podolog','b2b','elastyczny','Gdańsk','pomorskie',60,90,'HOUR',repeat('Opis ogłoszenia przykładowego. ',10));
insert into job_offer_contacts(offer_id, method, phone) select id,'telefon','600 000 001' from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001';
update job_offers set status='pending_review' where account_id='bbbbbbbb-0000-0000-0000-000000000001';
select 'B sees A contacts (0)', count(*) from job_offer_contacts where account_id='aaaaaaaa-0000-0000-0000-000000000001';
select 'ERR expected: B writes contact for A offer'; insert into job_offer_contacts(offer_id, method, phone) select id,'telefon','600 000 002' from job_offers where profession='kosmetolog';
select 'B update A offer (0 rows)'; update job_offers set title='hack hack' where profession='kosmetolog';
reset role;
update client_accounts set employer_verified_at = now() - interval '121 days' where id='bbbbbbbb-0000-0000-0000-000000000001';
select 'ERR expected: publish B without NIP check'; select public.app_moderate_job_offer((select id from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001'),'00000000-0000-0000-0000-0000000000f1','publish',2);
select 'P1 gus B again', public.app_employer_record_gus('bbbbbbbb-0000-0000-0000-000000000001','system:gus', '{"nip":"1112223332","result":"aktywny","regon":"123456786","entity_type":"P","legal_name":"Salon Przykładowy B s.c.","city":"Gdańsk","postal_code":"80-001"}');
select 'publish B with NIP check', public.app_moderate_job_offer((select id from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001'),'00000000-0000-0000-0000-0000000000f1','publish',2);

-- ===================== employee A =====================
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000e1',false), set_config('request.jwt.claims','{"aal":"aal1"}',false);
select 'E sees policies (0)', count(*) from client_policies;
select 'E sees docs (0)', count(*) from client_policy_documents;
select 'E sees storage (0)', count(*) from storage.objects;
select 'E sees contacts (0)', count(*) from job_offer_contacts;
select 'E sees own salon offers (5)', count(*) from job_offers where account_id='aaaaaaaa-0000-0000-0000-000000000001';
reset role;

-- ===================== anon =====================
set role anon; select set_config('request.jwt.claim.sub','',false), set_config('request.jwt.claims','',false);
select 'anon offers (2)', count(*) from job_offers;
select 'ERR expected: anon account_id'; select account_id from job_offers;
select 'ERR expected: anon contacts'; select count(*) from job_offer_contacts;
select 'anon trainings (1)', count(*) from trainings;
select 'anon organisers (3) + name', count(*) from training_organizers;
select 'ERR expected: anon organiser status'; select status from training_organizers;
select 'ERR expected: anon policies'; select count(*) from client_policies;
select 'ERR expected: anon organizer_ids'; select public.organizer_ids();
reset role;

-- ===================== relay form =====================
select 'ERR expected: relay to phone-only offer'; select public.app_relay_job_message((select slug from job_offers where account_id='bbbbbbbb-0000-0000-0000-000000000001'), '{"sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com","message":"Dzień dobry"}');
-- A switched to phone too; switch back to form via staff path? use postgres to set form contact
update job_offer_contacts set method='formularz' where account_id='aaaaaaaa-0000-0000-0000-000000000001';
select 'relay ok', public.app_relay_job_message((select slug from job_offers where profession='kosmetolog'), '{"sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com","message":"Dzień dobry, chętnie porozmawiam."}') is not null;
select 'outbox has message', recipient, payload ? 'message' from outbox_emails where template='job_relay';
update outbox_emails set status='sent' where template='job_relay';
select 'purge after send', public.app_purge_relay_messages((select id from outbox_emails where template='job_relay'));
select 'outbox purged', recipient, payload from outbox_emails where template='job_relay';
select 'relay log has no PII columns', string_agg(column_name, ',') from information_schema.columns where table_name='job_offer_relay_log';

-- ===================== trainings: registration, organiser view =====================
select 'reg A', public.app_training_register((select id from trainings limit 1),'00000000-0000-0000-0000-00000000000a','aaaaaaaa-0000-0000-0000-000000000001','Właścicielka Przykładowa','ownera@example.com','org-info-v1');
select 'reg E (waitlist)', public.app_training_register((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000e1','aaaaaaaa-0000-0000-0000-000000000001','Pracownica Przykładowa','empa@example.com','org-info-v1');
select 'ERR expected: reg without notice'; select public.app_training_register((select id from trainings limit 1),'00000000-0000-0000-0000-00000000000b','bbbbbbbb-0000-0000-0000-000000000001','B','ownerb@example.com',null);
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
reset role; select 'o1 sees contacts via fn (1 registered, waitlist hidden)', count(*) from public.app_training_participants((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1');
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
select 'ERR expected: o1 reads registrations user_id'; select user_id from training_participant_contacts;
select 'o1 sees registrations (0)', count(*) from training_registrations;
select 'o1 sees private details (1)', count(*) from training_private_details;
reset role;
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c2',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
select 'ERR expected: o2 reads contacts via Data API'; select count(*) from training_participant_contacts;
select 'o2 sees org A private details (0)', count(*) from training_private_details;
select 'o2 sees client_members (0)', count(*) from client_members;
reset role;
select 'ERR expected: capacity by o2'; select public.app_training_set_capacity((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c2',5);
select 'capacity 2 by o1 promotes', public.app_training_set_capacity((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1',2);
select 'ERR expected: capacity below seats'; select public.app_training_set_capacity((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1',1);
select 'seats', seats_registered, capacity from trainings;
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000c1',false), set_config('request.jwt.claims','{"aal":"aal2"}',false);
reset role; select 'o1 sees contacts via fn (2)', count(*) from public.app_training_participants((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1');
reset role;
select 'ERR expected: attendance before start'; select public.app_training_mark_attendance((select id from training_registrations limit 1),'00000000-0000-0000-0000-0000000000c1','attended');
select 'log organiser view', public.app_log_organizer_access((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1','organizer_participants_viewed');
select 'ERR expected: o2 log on A training'; select public.app_log_organizer_access((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c2','organizer_participants_exported');
-- employee sees private details while active
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000e1',false), set_config('request.jwt.claims','{"aal":"aal1"}',false);
select 'E sees private details (1)', count(*) from training_private_details;
reset role;
update client_members set last_seen_at = now() - interval '13 months' where user_id='00000000-0000-0000-0000-0000000000e1';
select 'dormant revoked (1)', public.app_revoke_dormant_members();
set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000e1',false), set_config('request.jwt.claims','{"aal":"aal1"}',false);
select 'E after revoke sees private details (0)', count(*) from training_private_details;
reset role;
select 'cancel A by staff', public.app_training_cancel((select id from trainings limit 1),'00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000000f1');
select 'audit actor for staff cancel', actor like 'staff:%' from client_audit_log where action='training_cancelled';
select 'contacts after cancel (1)', count(*) from training_participant_contacts;
select 'cancel event by o1', public.app_training_cancel_event((select id from trainings limit 1),'00000000-0000-0000-0000-0000000000c1','Choroba prowadzącej (przykład)');
select 'training status', status from trainings;

-- ===================== audit log integrity =====================
select 'ERR expected: truncate audit (postgres)'; truncate client_audit_log;
select 'ERR expected: update audit'; update client_audit_log set action='policy_updated' where id=1;
set role service_role;
select 'ERR expected: service_role delete audit'; delete from client_audit_log;
select 'ERR expected: service_role truncate audit'; truncate client_audit_log;
reset role;
select 'purge audit (0)', public.app_purge_audit_log();
select 'audit rows', count(*) from client_audit_log;
select 'actors', string_agg(distinct split_part(actor, ':', 1) || case when actor like 'system:%' then ':' || split_part(actor, ':', 2) else '' end, ', ') from client_audit_log;

-- ===================== privileges =====================
select 'fn exec anon', string_agg(p.proname, ',') from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and has_function_privilege('anon', p.oid, 'execute');
select 'fn exec authenticated', string_agg(p.proname, ',' order by p.proname) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and has_function_privilege('authenticated', p.oid, 'execute');
select 'tables with RLS and no policy', string_agg(c.relname, ',') from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' and c.relrowsecurity and not exists (select 1 from pg_policy p where p.polrelid=c.oid);
select 'job_applications gone', to_regclass('public.job_applications') is null;

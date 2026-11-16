-- Zakładki w Strefie salonu (00, D44; snippets/strefa-klienta.sql 10.7a; TEST-21 pkt 22).
-- Preferencja widoku client_accounts.ukryte_zakladki i app_client_set_tab_visibility(): tylko właściciel,
-- idempotentnie, z wpisem w dzienniku; moduły „Dam pracę”, „Szukam pracy” i „Szkolenia” działają tak samo
-- przy ukrytych zakładkach (to nie jest kontrola dostępu). Dane wyłącznie przykładowe (example.com / .example).
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
create function t.err(p_sql text) returns text language plpgsql as $$
begin
  execute p_sql;
  return null;
exception when others then
  return sqlstate || ': ' || sqlerrm;
end $$;
grant execute on function t.err(text) to anon, authenticated, service_role;

-- Supabase: service_role ma uprawnienia do tabel w public (zaślepka ich nie nadaje); ograniczenie dziennika jak w snippecie
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage on all sequences in schema public to service_role;
revoke update, delete, truncate on client_audit_log from service_role;

-- ===================== fikstury =====================
-- a = właścicielka salonu A, e1 = pracownica A (bez TOTP), b = właściciel salonu B, s3 = właścicielka salonu C
-- (zawieszony), d1 = właściciel konta pracodawcy D1, f1 = admin, f2 = agent, c1 = właścicielka organizatora 1
\set A '''aaaaaaaa-0000-0000-0000-000000000001'''
\set B '''bbbbbbbb-0000-0000-0000-000000000001'''
\set C '''cccccccc-0000-0000-0000-000000000001'''
\set D '''dddddddd-0000-0000-0000-000000000001'''
\set ua '''00000000-0000-0000-0000-00000000000a'''
\set ub '''00000000-0000-0000-0000-00000000000b'''
\set ue '''00000000-0000-0000-0000-0000000000e1'''
\set us3 '''00000000-0000-0000-0000-0000000000a3'''
\set ud '''00000000-0000-0000-0000-0000000000d1'''
\set uf1 '''00000000-0000-0000-0000-0000000000f1'''
\set uf2 '''00000000-0000-0000-0000-0000000000f2'''
\set uc1 '''00000000-0000-0000-0000-0000000000c1'''
insert into auth.users values
 ('00000000-0000-0000-0000-00000000000a','ownera@example.com'), ('00000000-0000-0000-0000-00000000000b','ownerb@example.com'),
 ('00000000-0000-0000-0000-0000000000e1','empa@example.com'),   ('00000000-0000-0000-0000-0000000000a3','ownerc@example.com'),
 ('00000000-0000-0000-0000-0000000000d1','pracodawca1@example.com'),
 ('00000000-0000-0000-0000-0000000000f1','admin@example.com'),  ('00000000-0000-0000-0000-0000000000f2','agent@example.com'),
 ('00000000-0000-0000-0000-0000000000c1','org1@example.com');
insert into admin_users(user_id, role) values ('00000000-0000-0000-0000-0000000000f1','admin'),('00000000-0000-0000-0000-0000000000f2','agent');
insert into client_accounts(id, display_name, nip, city) values
 (:A,'Salon Przykładowy A','9876543210','Kraków'), (:B,'Salon Przykładowy B','1112223332','Gdańsk'),
 (:C,'Salon Przykładowy C','5555555555','Łódź');
insert into client_policies(account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to, published_at)
 select id, 'tax-protect','colonnade','Tax Protect','BP/2026/0001' || n || ' (przykład)','active','2026-01-01','2026-12-31',now()
   from (values (:A::uuid, 1), (:B::uuid, 2), (:C::uuid, 3)) v(id, n);
select public.app_activate_client_account(:A, :uf1, 'ownera@example.com', t.h('tokA')) is not null;
select public.app_activate_client_account(:B, :uf1, 'ownerb@example.com', t.h('tokB')) is not null;
select public.app_activate_client_account(:C, :uf1, 'ownerc@example.com', t.h('tokC')) is not null;
select public.app_accept_invitation(t.h('tokA'), :ua, 'ownera@example.com') is not null;
select public.app_accept_invitation(t.h('tokB'), :ub, 'ownerb@example.com') is not null;
select public.app_accept_invitation(t.h('tokC'), :us3, 'ownerc@example.com') is not null;
select public.app_create_invitation(:A, :ua, 'empa@example.com', 'employee', t.h('tokE')) is not null;
select public.app_accept_invitation(t.h('tokE'), :ue, 'empa@example.com') is not null;
update client_accounts set status = 'suspended', suspended_at = now() where id = :C;
-- konto pracodawcy z rejestracji (P1b) – wprost, bo test dotyczy tylko odmowy
insert into client_accounts(id, kind, display_name, legal_name, nip, city, status, activated_at, employer_verified_at)
 values (:D, 'employer', 'Studio Przykładowe', 'Studio Przykładowe sp. z o.o.', '2223334443', 'Poznań', 'active', now(), now());
insert into client_members(account_id, user_id, role, status) values (:D, :ud, 'owner', 'active');
-- organizator z planem, szkolenie bezpłatne i płatne online
insert into training_organizers(id, kind, display_name, legal_name, nip, city, status, verified_at, verified_by, terms_version) values
 ('eeeeeeee-0000-0000-0000-000000000001','firma','Organizator przykładowy','Organizator Przykładowy sp. z o.o.','5556667776','Kraków','active',now(),'00000000-0000-0000-0000-0000000000f1','org-v1');
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000001', :uf1, 'org1@example.com', 'owner', t.h('tokO1')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO1'), :uc1, 'org1@example.com') is not null;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001', :uf2, 'promo-12m', now(), 'FV/2026/11/001 (przykład)') is not null;
\set terms '{"seller_legal_name":"Organizator Przykładowy sp. z o.o.","seller_address":"ul. Przykładowa 1, 30-001 Kraków","seller_nip":"5556667776","seller_register":"KRS 0000000000 (przykład)","seller_email":"szkolenia@example.com","seller_phone":"+48 000 000 000","cancellation_rules":"Rezygnacja do 14 dni przed szkoleniem – zwrot całości; później – zwrot 50 procent ceny (przykład).","withdrawal_info":"Konsument może odstąpić od umowy w terminie 14 dni, z wyjątkami dla usług z określonym terminem (przykład).","complaint_info":"Reklamacje rozpatrujemy w terminie 14 dni od otrzymania (przykład).","terms_body":"Regulamin szkoleń organizatora przykładowego. Sprzedawcą jest organizator. Portal BeautyPolisa nie jest stroną umowy. Płatność obsługuje operator płatności. Faktury wystawia organizator. Szczegóły organizacyjne przekazujemy po zapisie (przykład)."}'
\set osoba '{"buyer_kind":"osoba","buyer_name":"Ewa Przykładowa","invoice_email":"empa@example.com"}'
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity)
 values ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Higiena pracy w salonie (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '10 days', now()+interval '10 days 2 hours', 5);
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity, per_account_limit,
                      price_kind, price_gross_pln, payment_mode)
 values ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Stylizacja brwi (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '20 days', now()+interval '20 days 4 hours', 5, 10, 'platne', 450.00, 'online');
reset role;
select id as tf from trainings where title like 'Higiena%' \gset
select id as tp from trainings where title like 'Stylizacja%' \gset
set role service_role;
select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001', :uc1, 'stripe', 'acct_ZAKL1') is not null;
select public.app_payout_account_set_status('stripe', 'acct_ZAKL1', true, false, true);
select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001', :uc1, :'terms') as st1 \gset
select public.app_sales_terms_moderate(:'st1', :uf2, 'approve');
select public.app_payout_account_set_status('stripe', 'acct_ZAKL1', true, true, false);
reset role;
update organizer_payout_accounts set usable_from = now() - interval '1 minute' where provider_account_ref = 'acct_ZAKL1';
set role service_role;
select public.app_moderate_training(:'tf', :uf2, 'publish', 1);
select public.app_moderate_training(:'tp', :uf2, 'publish', 1);
-- salon A jako pracodawca (poziom 1 i 2): NIP w GUS, telefon właścicielki, potwierdzony adres formularza
select public.app_employer_record_gus(:A, 'system:gus', '{"nip":"9876543210","result":"aktywny","regon":"123456786","entity_type":"P","legal_name":"Salon Przykładowy A sp. z o.o.","city":"Kraków","postal_code":"30-001"}');
reset role;
insert into user_phones(user_id, phone_hmac, phone_last3, verified_at) values (:ua, t.h('+48600000002'), '002', now());
set role service_role;
select public.app_reply_address_request(:A, :ua, 'rekrutacja@salon-a.example', t.h('tokRA')) is not null;
select public.app_reply_address_confirm(t.h('tokRA'));
reset role;
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
insert into job_offers (account_id, status, title, profession, employment_type, working_time, city, voivodeship, salary_min, salary_max, salary_unit, description)
 values (:A,'draft','Kosmetolog (przykład)','kosmetolog','umowa-o-prace','pelny-etat','Kraków','malopolskie',6000,7500,'MONTH',repeat('Opis ogłoszenia przykładowego. ',10));
insert into job_offer_contacts(offer_id, method, email) select id, 'formularz', 'rekrutacja@salon-a.example' from job_offers;
update job_offers set status = 'pending_review';
reset role;
select id as offer, content_version as offer_v from job_offers where account_id = :A \gset
select t.eq('fikstura: 2 szkolenia opublikowane', (select count(*) from trainings where status = 'published'), 2::bigint);
select t.eq('fikstura: oferta salonu A w moderacji', (select status from job_offers where id = :'offer'), 'pending_review');

-- ===================== 1. Wartość domyślna =====================
select '--- 1. domyślnie wszystkie zakładki widoczne ---';
select t.eq('domyślnie {} (salony i pracodawca)', (select string_agg(distinct ukryte_zakladki::text, ',') from client_accounts), '{}');
select t.eq('kolumna NOT NULL z domyślną {}', (select is_nullable || '/' || column_default from information_schema.columns where table_name = 'client_accounts' and column_name = 'ukryte_zakladki'), 'NO/''{}''::text[]');

-- ===================== 2. Uprawnienia i walidacja =====================
select '--- 2. kto może zmienić, walidacja ---';
set role authenticated; select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.expect('authenticated (właścicielka) nie ma EXECUTE', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',false)$q$, :A, :ua), '42501');
reset role;
set role anon; select t.as_user('','aal1');
select t.expect('anon nie ma EXECUTE', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',false)$q$, :A, :ua), '42501');
reset role;
select t.eq('EXECUTE tylko service_role (anon/authenticated/public: brak)',
  (select string_agg(r, ',' order by r) from unnest(array['anon','authenticated','service_role','public']) r
    where (r = 'public' and exists (select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) x
                                     where p.proname = 'app_client_set_tab_visibility' and x.grantee = 0))
       or (r <> 'public' and has_function_privilege(r, 'public.app_client_set_tab_visibility(uuid,uuid,text,boolean)', 'execute'))),
  'service_role');
select t.eq('security invoker, search_path ustalony',
  (select (not prosecdef)::text || '/' || array_to_string(proconfig, ',') from pg_proc where proname = 'app_client_set_tab_visibility'),
  'true/search_path=""');
set role service_role;
select t.expect('pracownica salonu A', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',false)$q$, :A, :ue), 'P0001');
select t.expect('właściciel innego salonu (B → A)', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',false)$q$, :A, :ub), 'P0001');
select t.expect('personel admin (preferencja salonu – zmienia właściciel)', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',false)$q$, :A, :uf1), 'P0001');
select t.expect('organizator szkoleń (obcy dla salonu)', format($q$select public.app_client_set_tab_visibility(%L,%L,'szkolenia',false)$q$, :A, :uc1), 'P0001');
select t.expect('właściciel konta pracodawcy (kind employer)', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',false)$q$, :D, :ud), 'P0001');
select t.expect('właścicielka zawieszonego salonu C', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',false)$q$, :C, :us3), 'P0001');
select t.expect('nieistniejące konto', format($q$select public.app_client_set_tab_visibility(gen_random_uuid(),%L,'praca',false)$q$, :ua), 'P0001');
select t.expect('nieznana zakładka', format($q$select public.app_client_set_tab_visibility(%L,%L,'zespol',false)$q$, :A, :ua), 'BP422');
select t.expect('wielkość liter (Praca)', format($q$select public.app_client_set_tab_visibility(%L,%L,'Praca',false)$q$, :A, :ua), 'BP422');
select t.expect('zakładka NULL', format($q$select public.app_client_set_tab_visibility(%L,%L,null,false)$q$, :A, :ua), 'BP422');
select t.expect('stan NULL', format($q$select public.app_client_set_tab_visibility(%L,%L,'praca',null)$q$, :A, :ua), 'BP422');
select t.eq('komunikat BP422 bez wartości (PRIV-12)', t.err(format($q$select public.app_client_set_tab_visibility(%L,%L,'zespol<script>',false)$q$, :A, :ua)), 'BP422: tabs: nieprawidłowe pole zakladka albo widoczna');
reset role;
select t.eq('po odmowach: bez zmian i bez wpisów w dzienniku',
  (select string_agg(distinct ukryte_zakladki::text, ',') from client_accounts)
   || '/' || (select count(*) from client_audit_log where action = 'account_tab_visibility_changed'), '{}/0');

-- ===================== 3. Właścicielka ukrywa i pokazuje (idempotentnie) =====================
select '--- 3. właścicielka ukrywa i pokazuje ---';
select count(*) as idc0 from client_audit_log where action = 'account_identity_changed' and account_id = :A \gset
set role service_role;
select t.eq('ukryj Pracę → {praca}', public.app_client_set_tab_visibility(:A, :ua, 'praca', false), '{praca}'::text[]);
select t.eq('ukryj Pracę ponownie → ten sam stan', public.app_client_set_tab_visibility(:A, :ua, 'praca', false), '{praca}'::text[]);
reset role;
select t.eq('dziennik: 1 wpis mimo powtórzenia', (select count(*) from client_audit_log where action = 'account_tab_visibility_changed'), 1::bigint);
select t.eq('dziennik: aktor, encja, payload bez PII',
  (select actor || '|' || entity || '|' || entity_id::text || '|' || payload::text from client_audit_log where action = 'account_tab_visibility_changed'),
  'user:00000000-0000-0000-0000-00000000000a|account|aaaaaaaa-0000-0000-0000-000000000001|{"widoczna": false, "zakladka": "praca"}');
set role service_role;
select t.eq('ukryj Szkolenia → {praca,szkolenia} (posortowane)', public.app_client_set_tab_visibility(:A, :ua, 'szkolenia', false), '{praca,szkolenia}'::text[]);
select t.eq('pokaż Pracę → {szkolenia}', public.app_client_set_tab_visibility(:A, :ua, 'praca', true), '{szkolenia}'::text[]);
select t.eq('pokaż Pracę ponownie → ten sam stan', public.app_client_set_tab_visibility(:A, :ua, 'praca', true), '{szkolenia}'::text[]);
select t.eq('pokaż Szkolenia → {}', public.app_client_set_tab_visibility(:A, :ua, 'szkolenia', true), '{}'::text[]);
select t.eq('pokaż już widoczną → {}', public.app_client_set_tab_visibility(:A, :ua, 'szkolenia', true), '{}'::text[]);
reset role;
select t.eq('dziennik: 4 zmiany, kolejność',
  (select string_agg((payload->>'zakladka') || ':' || (payload->>'widoczna'), ',' order by id) from client_audit_log where action = 'account_tab_visibility_changed'),
  'praca:false,szkolenia:false,praca:true,szkolenia:true');
select t.eq('wyzwalacz audytu kont nie dopisuje account_identity_changed', (select count(*) from client_audit_log where action = 'account_identity_changed' and account_id = :A), :'idc0'::bigint);
select t.eq('salon B bez zmian', (select ukryte_zakladki from client_accounts where id = :B), '{}'::text[]);
-- stan do dalszych testów: salon A ukrywa obie zakładki (np. salon jednoosobowy)
set role service_role;
select t.eq('ukryj Pracę', public.app_client_set_tab_visibility(:A, :ua, 'praca', false), '{praca}'::text[]);
select t.eq('ukryj Szkolenia', public.app_client_set_tab_visibility(:A, :ua, 'szkolenia', false), '{praca,szkolenia}'::text[]);
reset role;
select t.eq('stan salonu A', (select ukryte_zakladki from client_accounts where id = :A), '{praca,szkolenia}'::text[]);

-- ===================== 4. Odczyt: członkowie salonu (istniejące polityki), bez zapisu przez Data API =====================
select '--- 4. odczyt przez członków salonu ---';
set role authenticated;
select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.eq('właścicielka A (aal2) czyta stan', (select ukryte_zakladki from client_accounts where id = :A), '{praca,szkolenia}'::text[]);
select t.eq('właścicielka A widzi zmiany w Historii konta', (select count(*) from client_audit_log where action = 'account_tab_visibility_changed'), 6::bigint);
select t.expect('właścicielka A: UPDATE kolumny przez Data API', format($q$update client_accounts set ukryte_zakladki = '{}' where id = %L$q$, :A), '42501');
select t.as_user('00000000-0000-0000-0000-00000000000a','aal1');
select t.eq('właścicielka A bez aal2: 0 wierszy (jak dotąd)', (select count(*) from client_accounts), 0::bigint);
select t.as_user('00000000-0000-0000-0000-0000000000e1','aal1');
select t.eq('pracownica A (bez TOTP) czyta stan', (select ukryte_zakladki from client_accounts where id = :A), '{praca,szkolenia}'::text[]);
select t.eq('pracownica A nie widzi dziennika (jak dotąd)', (select count(*) from client_audit_log), 0::bigint);
select t.expect('pracownica A: UPDATE kolumny', format($q$update client_accounts set ukryte_zakladki = '{}' where id = %L$q$, :A), '42501');
select t.as_user('00000000-0000-0000-0000-00000000000b','aal2');
select t.eq('właściciel B: 0 wierszy salonu A', (select count(*) from client_accounts where id = :A), 0::bigint);
select t.eq('właściciel B: własny stan {}', (select ukryte_zakladki from client_accounts where id = :B), '{}'::text[]);
select t.as_user('00000000-0000-0000-0000-0000000000f1','aal2');
select t.eq('personel (aal2) czyta stan salonu A', (select ukryte_zakladki from client_accounts where id = :A), '{praca,szkolenia}'::text[]);
select t.expect('personel: UPDATE kolumny przez Data API (brak grantu)', format($q$update client_accounts set ukryte_zakladki = '{}' where id = %L$q$, :A), '42501');
reset role;
set role anon; select t.as_user('','aal1');
select t.expect('anon: client_accounts', $q$select ukryte_zakladki from client_accounts$q$, '42501');
reset role;

-- ===================== 5. CHECK – zapis z pominięciem funkcji =====================
select '--- 5. CHECK ---';
select t.expect('CHECK: wartość spoza listy', format($q$update client_accounts set ukryte_zakladki = '{zespol}' where id = %L$q$, :B), '23514');
select t.expect('CHECK: kolejność inna niż kanoniczna', format($q$update client_accounts set ukryte_zakladki = '{szkolenia,praca}' where id = %L$q$, :B), '23514');
select t.expect('CHECK: powtórzenie', format($q$update client_accounts set ukryte_zakladki = '{praca,praca}' where id = %L$q$, :B), '23514');
select t.expect('CHECK: NULL w tablicy', format($q$update client_accounts set ukryte_zakladki = array[null]::text[] where id = %L$q$, :B), '23514');
select t.expect('CHECK: NULL obok wartości', format($q$update client_accounts set ukryte_zakladki = array['praca', null] where id = %L$q$, :B), '23514');
select t.expect('NOT NULL', format($q$update client_accounts set ukryte_zakladki = null where id = %L$q$, :B), '23502');
select t.expect('CHECK: preferencja konta pracodawcy', format($q$update client_accounts set ukryte_zakladki = '{praca}' where id = %L$q$, :D), '23514');

-- ===================== 6. Szkolenia działają przy ukrytej zakładce =====================
select '--- 6. szkolenia przy ukrytej zakładce ---';
set role service_role;
select t.eq('pracownica zapisuje się na szkolenie bezpłatne', public.app_training_register(:'tf', :ue, :A, 'Ewa Przykładowa', 'empa@example.com', 'org-info-v1'), 'registered');
select t.eq('właścicielka zapisuje się na szkolenie bezpłatne', public.app_training_register(:'tf', :ua, :A, 'Anna Przykładowa', 'ownera@example.com', 'org-info-v1'), 'registered');
select order_id as op, amount_grosze as op_amount
  from public.app_training_order_create(:'tp', :ue, :A, gen_random_uuid(), :'st1', 'Ewa Przykładowa', 'empa@example.com', :'osoba', 'sprz-v1') \gset
select t.eq('zamówienie szkolenia płatnego: kwota z bazy', :'op_amount'::integer, 45000);
select public.app_training_payment_attach(:'op', :ue, 'stripe', 'pi_ZAKL1', now() + interval '15 minutes') is not null;
select t.eq('webhook: płatność → paid', public.app_payment_webhook('stripe','evt_z1','payment.succeeded','pi_ZAKL1',null,:'op',45000,'PLN',t.h('z1'),now(),'blik'), 'paid');
reset role;
select t.eq('zapisy salonu A na nadchodzące szkolenia (informacja przy przełączniku)',
  (select count(*) from training_registrations r join trainings tr on tr.id = r.training_id
    where r.account_id = :A and r.status in ('registered','waitlisted') and tr.starts_at > now()), 3::bigint);
select t.eq('e-mail modułu wychodzi (training_order_paid do kupującej)',
  (select count(*) from outbox_emails where template = 'training_order_paid' and account_id = :A and recipient = 'user:' || :ue), 1::bigint);
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000e1','aal1');
select t.eq('pracownica widzi katalog szkoleń (2)', (select count(*) from trainings where status = 'published'), 2::bigint);
select t.eq('pracownica widzi swoje zapisy (2)', (select count(*) from training_registrations where user_id = :ue), 2::bigint);
select t.eq('pracownica widzi swoje zamówienie (paid)', (select status from training_orders where id = :'op'), 'paid');
reset role;
set role anon; select t.as_user('','aal1');
select t.eq('publiczny katalog szkoleń bez zmian (anon: 2)', (select count(*) from trainings), 2::bigint);
reset role;

-- ===================== 7. „Dam pracę” i „Szukam pracy” działają przy ukrytej zakładce =====================
select '--- 7. praca przy ukrytej zakładce ---';
set role service_role;
select public.app_moderate_job_offer(:'offer', :uf2, 'publish', :'offer_v');
reset role;
select t.eq('moderacja publikuje ofertę salonu z ukrytą Pracą', (select status from job_offers where id = :'offer'), 'published');
select slug as offer_slug from job_offers where id = :'offer' \gset
set role anon; select t.as_user('','aal1');
select t.eq('publiczna tablica: anon widzi ofertę salonu A', (select count(*) from job_offers where title = 'Kosmetolog (przykład)'), 1::bigint);
reset role;
set role service_role;
select t.eq('app_job_offers_page() zwraca ofertę salonu A', (select count(*) from public.app_job_offers_page('{}'::jsonb) where id = :'offer'), 1::bigint);
select t.eq('wiadomość kandydata przekazana (formularz)', public.app_relay_job_message(:'offer_slug', '{"message":"Dzień dobry, chętnie porozmawiam o pracy (przykład).","sender_name":"Kandydatka Przykładowa","reply_to":"kandydatka@example.com"}') is not null, true);
reset role;
select t.eq('outbox job_relay do salonu A', (select count(*) from outbox_emails where template = 'job_relay' and account_id = :A), 1::bigint);
set role service_role;
select t.eq('cron wygaszania nie rusza aktywnej oferty', public.app_expire_job_offers() >= 0 and (select status from job_offers where id = :'offer') = 'published', true);
reset role;
select t.eq('aktywne oferty salonu A (informacja przy przełączniku)',
  (select count(*) from job_offers where account_id = :A and status = 'published' and expires_at > now()), 1::bigint);
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000e1','aal1');
select t.eq('pracownica widzi ogłoszenia salonu (adres bezpośredni działa)', (select count(*) from job_offers where id = :'offer'), 1::bigint);
select t.as_user('00000000-0000-0000-0000-00000000000a','aal2');
select t.eq('właścicielka widzi kontakt w ofercie', (select count(*) from job_offer_contacts), 1::bigint);
reset role;
-- „Szukam pracy”: zależy tylko od globalnego przełącznika (11.9.6), który ma pierwszeństwo
set role service_role;
select t.eq('Szukam pracy przy ukrytej Pracy: odczyt działa (0 ogłoszeń, bez błędu)', (select count(*) from public.app_candidate_ads_page(:ua, :A)), 0::bigint);
select public.app_set_feature_flag('szukam_pracy', false, :uf1, null);
select t.expect('przełącznik wyłączony → BP404 niezależnie od preferencji', format($q$select count(*) from public.app_candidate_ads_page(%L,%L)$q$, :ua, :A), 'BP404');
select t.eq('pokazanie Pracy nie włącza Szukam pracy', public.app_client_set_tab_visibility(:A, :ua, 'praca', true), '{szkolenia}'::text[]);
select t.expect('nadal BP404', format($q$select count(*) from public.app_candidate_ads_page(%L,%L)$q$, :ua, :A), 'BP404');
select t.eq('przełącznik nie zmienia preferencji salonu', (select ukryte_zakladki from public.client_accounts where id = :A), '{szkolenia}'::text[]);
select public.app_set_feature_flag('szukam_pracy', true, :uf1, 'decyzja zleceniodawcy P1 z 12.11.2026 (przykład w teście)');
select t.eq('przełącznik włączony: odczyt znów działa', (select count(*) from public.app_candidate_ads_page(:ua, :A)), 0::bigint);
reset role;
select t.eq('preferencja nie zmienia app_feature_flags', (select enabled from app_feature_flags where key = 'szukam_pracy'), true);

-- ===================== 8. Stan końcowy; brak zależności modułów od preferencji =====================
-- (równoległe zmiany dwóch zakładek – blokada wiersza – sprawdza zestaw wyscigi, R4)
select '--- 8. stan końcowy i dziennik ---';
select t.eq('dziennik salonu A: 7 zmian, salon B: 0',
  (select count(*) filter (where account_id = :A) || '/' || count(*) filter (where account_id = :B)
     from client_audit_log where action = 'account_tab_visibility_changed'), '7/0');
select t.eq('funkcje modułów nie czytają ukryte_zakladki',
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosrc like '%ukryte_zakladki%' and p.proname <> 'app_client_set_tab_visibility'), 0::bigint);
select t.eq('polityki RLS nie czytają ukryte_zakladki',
  (select count(*) from pg_policies where coalesce(qual, '') || coalesce(with_check, '') like '%ukryte_zakladki%'), 0::bigint);

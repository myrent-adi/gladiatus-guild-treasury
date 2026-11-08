-- Run once in Supabase > SQL Editor, on a NEW project.
-- Public leaderboard; only authenticated users can add members and donations.
-- Only administrators can remove a donation. Never put service_role keys in the site.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('member','admin'))
);

create table if not exists public.guild_members (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 45),
  created_at timestamptz not null default now()
);
alter table public.guild_members add column if not exists rank text not null default 'Member';
create unique index if not exists guild_members_name_ci on public.guild_members (lower(name));

create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.guild_members(id) on delete restrict,
  amount bigint not null check (amount between 1 and 999999999999999),
  donated_at date not null,
  note text not null default '' check (char_length(note) <= 100),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists donations_member_id_idx on public.donations(member_id);

-- Separate bank fee/commission ledger. Never mix with donations.
create table if not exists public.bank_fees (
  id uuid primary key default gen_random_uuid(),
  amount bigint not null check (amount between 1 and 999999999999999),
  earned_at date not null,
  note text not null default '' check (char_length(note) <= 100),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,role) values (new.id,'member') on conflict(id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_guild on auth.users;
create trigger on_auth_user_created_guild after insert on auth.users
for each row execute procedure public.create_profile_for_new_user();
-- Backfill profiles if any users existed before the script was installed.
insert into public.profiles(id,role)
select id,'member' from auth.users on conflict(id) do nothing;

alter table public.profiles enable row level security;
alter table public.guild_members enable row level security;
alter table public.donations enable row level security;
alter table public.bank_fees enable row level security;

drop policy if exists "Read own role" on public.profiles;
create policy "Read own role" on public.profiles for select to authenticated using ((select auth.uid()) = id);
-- No client-side profile UPDATE policy: the admin role is set in the SQL editor.

drop policy if exists "Public member list" on public.guild_members;
create policy "Public member list" on public.guild_members for select to anon,authenticated using (true);
drop policy if exists "Signed in members can add gladiators" on public.guild_members;
create policy "Signed in members can add gladiators" on public.guild_members for insert to authenticated with check (true);

drop policy if exists "Public donation ledger" on public.donations;
create policy "Public donation ledger" on public.donations for select to anon,authenticated using (true);
drop policy if exists "Signed in members can record donations" on public.donations;
create policy "Signed in members can record donations" on public.donations
for insert to authenticated with check (created_by = (select auth.uid()));
drop policy if exists "Admins can delete donations" on public.donations;
create policy "Admins can delete donations" on public.donations
for delete to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "Public bank commission ledger" on public.bank_fees;
create policy "Public bank commission ledger" on public.bank_fees for select to anon,authenticated using (true);
drop policy if exists "Signed in members can record bank commissions" on public.bank_fees;
create policy "Signed in members can record bank commissions" on public.bank_fees
for insert to authenticated with check (created_by = (select auth.uid()));
drop policy if exists "Admins can delete bank commission entries" on public.bank_fees;
create policy "Admins can delete bank commission entries" on public.bank_fees
for delete to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

-- After registering your own email on the website, make yourself admin:
-- UPDATE public.profiles SET role = 'admin'
-- WHERE id = (SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL@example.com');
-- Refresh the website after the UPDATE. Do NOT expose your email/password publicly.

-- Screenshot roster (active ranks only; RIP excluded). Insert once; safe to re-run.
insert into public.guild_members(name,rank) values ('SirNuma','Master') on conflict do nothing;
insert into public.guild_members(name,rank) values ('The.T','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Mc.isus123','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Eolo','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('[GOC]Consul','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Canto.','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Phi965t','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('[THE]-Ange-','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Arghantaa','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('peymimi','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HH_Titanium_HH','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HH_MadKing_THE','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Usasz11.','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('THE_MadMax_THE','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('ZimaBlue','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('[THE]ExorcIsT','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Markus1','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Aveloca','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('•Yggdrasill•','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('satana_satanas2','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('ElPriest.','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('satana_satan22.','Admin') on conflict do nothing;
insert into public.guild_members(name,rank) values ('rock','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Neus_Gesicht','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Raveniacus','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Syndicato','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('_Meikor_','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('BigAnubis','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('testobolan','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Bigoune','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Anonymous.','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('^^WhiteTiger^^','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Yogi','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Mr.Gladiatus','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('THRULL','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('FUNES','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Valkyrja','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Ashuuuuu','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('[T-H-E]Noahoba','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('EirikrBlood','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('xRax','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Bozo','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Connavar,','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HH_Roberto','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HH_LoVl_HH','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('THE_Armorachia','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Witcher_hun','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('--Spartacus--','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('pontAz','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('DaveBautista','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('CaesarPoco','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('[ANGELS]Newboi,','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('THE_RockShakur','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Mezdo','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('P12_MontBlanc','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HH_Berserker_HH','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('GumboJack','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HH_isphan_HH','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Mirtam','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('[THE]Worms_s30','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HH_szappan','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('HHYork74HH','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Alfi','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Lukyl','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('marcusandreas','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('RINGO','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('glo73','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('PeterParker','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Ogre','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Logan529','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Buljooki_UNIjb','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Grim_Reaper','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Nopherus','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('BabadoRX','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Travellerr','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('francescosette7','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('LegolasWarrior','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Bubu3elette','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('mangusta','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Alupigus','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Venace','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Wisdom','Tribun') on conflict do nothing;
insert into public.guild_members(name,rank) values ('SchwanzusLongus','General') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Gorthur','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Peng','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Starship','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('_Big-Roberto_','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Alvius','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Zaro','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('ISpikeSpiegel','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Dey','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('eraz','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Nagyherceg1','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Calvin_Klein,','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Viento-Frio','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Mangos','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('ThorinOak','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Itheree','Senator') on conflict do nothing;
insert into public.guild_members(name,rank) values ('Aletheia','Senator') on conflict do nothing;

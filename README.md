# Gladiatus Guild Treasury — S59 EN

English-language, Roman-inspired fan-made guild donation ledger. Designed for `myrent-adi` on GitHub.

## Preview before publishing

Open `index.html` in a browser. The active guild roster is preloaded from your screenshot; players with **RIP** rank are excluded. **The.T** is marked as guild owner in the preview. All donations begin at **zero** because the screenshot shows honour, not donations. With the default empty `config.js`, it shows a working local demo with the active -Empire- [T-H-E] screenshot roster. Preview edits stay in that browser only. You can also open `index.html` from a GitHub Pages address after publishing.

## Multiple donations per player

Record as many donations as you want for the same gladiator. Each submission creates a separate dated transaction in Donation History; the leaderboard **adds all transactions together** and shows the cumulative gold total and the number of donations. Selecting a player displays their current running total. Removing an incorrect transaction subtracts only that transaction (admin-only when Supabase is connected). RIP-ranked players are excluded from the initial roster.

## Publish FREE using GitHub Pages

1. Sign in to GitHub as **myrent-adi**.
2. Create a **public repository** named `gladiatus-guild-treasury`.
3. Upload `index.html`, `config.js`, `supabase.sql`, and `README.md` to the repository root (or extract this ZIP, then upload the files).
4. In the repository open **Settings → Pages → Build and deployment**. Choose **Deploy from a branch**, branch **main**, folder **/(root)**, then **Save**.
5. The expected URL will be **https://myrent-adi.github.io/gladiatus-guild-treasury/**. Publication may take a few minutes.

## Enable real shared donations with Supabase (free tier)

1. Create a Supabase project at https://supabase.com/ (free tier, subject to limits).
2. Open **SQL Editor**, paste and run all contents of `supabase.sql`. Use a new/empty Supabase project.
3. In **Project Settings → API** (or **Connect** in newer dashboards), copy the **Project URL** and **public anon/publishable key**. In `config.js`, paste them into `supabaseUrl` and `supabaseAnonKey`. **NEVER** use the `service_role` or a secret key in browser code.
4. Commit the edited `config.js` to GitHub. Public URL and public anon key are intended to be visible; database security depends on the RLS rules in `supabase.sql`.
5. Under **Authentication → URL Configuration**, set your Site URL to `https://myrent-adi.github.io/gladiatus-guild-treasury/` and add this exact same URL to **Redirect URLs**. In **Authentication → Providers → Email**, enable email sign-ups. To avoid random strangers signing up, consider restricting registration/invitations rather than allowing public email sign-ups; see security note below.
6. Open your published site; click **Register** and confirm your email if prompted. Then **Sign In**.
7. In Supabase **SQL Editor**, set yourself as admin, changing the email to your own actual registered email:

```sql
UPDATE public.profiles SET role = 'admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL@example.com');
```

8. Refresh the website. You and registered guildmates can add members and donations; your admin account can delete mistaken donations. Everyone can view the leaderboard.

## Important security details

- **Sign-up is open by default** if email registration is enabled. That means **anyone on the internet can create an account and enter donations**. For a private guild ledger, turn off open sign-ups after your guild members have registered, or use Supabase's invite flow. An invite-only workflow is recommended for real data.
- Registered users can enter donations under **any** listed gladiator name. This is intentionally a shared manually maintained ledger, **not proof** that gold was transferred in the game. No automatic Gameforge connection.
- Public readers can see all gladiator names, amounts, dates, and notes; do not enter private information in notes.
- Members cannot remove records; admins can delete mistaken donations. User-added records are not independently verified. For strict accounting, implement review/approval and audit logging before relying on it.
- The UI loads Supabase JS from a public CDN. Online mode requires an internet connection.
- GitHub Pages is free for a public repository under GitHub's current terms, and Supabase has a free usage tier with limits. No paid domain needed.
- This is an independent fan project, not an official Gladiatus or Gameforge website. No game passwords are collected; users register separate website credentials.

## Guild roster and account ownership

The screenshot supplied by The.T is used only to prefill active names (Master, Admin, Tribun, General and Senator), not donation amounts. RIP members are not imported. Review names for typos because screenshot text is small. In live mode, the `supabase.sql` file seeds the same list. **The.T being shown as guild owner is only a display marker; website admin permissions are granted by the Supabase `profiles` role, not by name.**


## Forum Gladiatorius upgrade goal (23 November 2026)

The homepage now includes an editable building-goal calculator. Defaults based on the screenshot: displayed upgrade cost 94,911,994,662 gold; guild fortune 24,024,468,627 gold; an **assumed additional** 35% event reduction on the already displayed price. It estimates remaining gold, current progress, savings, and the amount per active member. The event stacking rule is **not verified**; check the game price during the event. The calculator inputs persist only to the browser (not Supabase). Donations are never automatically added to the in-game fortune, to avoid double counting.

## Bank fees vs player donations

Player donations and bank commission income are two independent ledgers. Record every donation in **Record Donation**, and new bank commission income in **Record Bank Fee Income**. The guild fortune field is a manual snapshot from the in-game bank and is NOT automatically increased by recorded fees or donations, as they may already be included in that snapshot. Total donated gold and total bank fee income are shown separately. The `bank_fees` table and its permissions are included in `supabase.sql`; run the updated SQL in Supabase before using this feature online.

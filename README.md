# Gladiatus -Empire- [T-H-E] — Direct on-page donations (no Supabase)

Visitors enter donations **directly on the Gladiatus website**, not through GitHub Issues. The public leaderboard aggregates your existing 33 donation records with **approved** new entries from a shared Google Sheet. The form can be used from a phone without a GitHub account.

**Important:** GitHub Pages alone cannot synchronize input between browsers. This setup uses Google Sheets + Google Apps Script as a free shared storage service, **not a traditional database**. Google usage limits apply. It has **manual moderation**: new entries appear in the spreadsheet as `Pending`; The.T changes `Pending` to `Approved` to publish them. Unapproved entries do not affect the totals.

## 1. Set up the Sheet

1. Create a **new Google Sheet** in your Google account, e.g. `Gladiatus Empire Donations`.
2. Select **Extensions → Apps Script**.
3. Replace the default script text with all the code from `Code.gs`.
4. Save the project, select function `setup`, and click **Run** once. Confirm the Google authorization prompts if you trust your own code. This creates the `Donations` tab.
5. Select **Deploy → New deployment → Web app**.
6. Select **Execute as: Me**; **Who has access: Anyone**. Click Deploy.
7. Copy the **Web app URL** ending in `/exec`. Do **not** share access to edit the Google Sheet with members; only you should edit `Status`.
8. Open `settings.js` in this download and paste the URL into `appsScriptUrl` between the single quotes.

**Security:** Because the form is public, anyone can send a `Pending` submission. You must verify the donations in-game before approving them. Spam is possible, and Google Apps Script usage limits apply. Only the spreadsheet owner/authorized editors should change statuses. Do not put passwords or secret API keys in `settings.js`.

## 2. Upload to GitHub Pages

Upload or replace the following in the **root** of `myrent-adi/gladiatus-guild-treasury`:

- `index.html`
- `settings.js`
- `data/members.json`
- `data/donations.json`

You can leave old `config.js` and `supabase.sql` in the repository; the new website does not use them. The old GitHub Issues workflow is no longer needed.

When GitHub Pages finishes publishing, open `https://myrent-adi.github.io/gladiatus-guild-treasury/` and use Ctrl+F5 to reload.

## 3. What happens when a member submits a donation?

1. Select a **Gladiator**, enter **Donated gold** and a date in **Record a Donation** on the website.
2. Press **Submit Donation**; the entry is appended to Google Sheets with `Pending` status.
3. The.T verifies the amount and changes that row's `Status` cell to exactly `Approved`.
4. All browsers and phones see it in the leaderboard after **Refresh** or an automatic refresh (about once per minute).
5. Every approved donation for the same player adds to that player's total.

Never add the original 33 donations to the Google Sheet as well; the website already includes them in `data/donations.json`. Adding them again would double-count them.

## Limitations

- This is **manual approval**, not automated proof of in-game payments. There is no connection to Gameforge.
- Google account is required for the **administrator** to set up and approve donations; guild members need no Google or GitHub login to submit.
- If Google Apps Script is unavailable or blocked in a user's browser, the form may not submit and new entries may not refresh. Check the Google Sheet to confirm receipt.
- The static GitHub opening records are preserved. To correct those old entries, edit `data/donations.json`.
- If you want instant auto-publication without admin approval, you would have to accept a higher risk of fraudulent entries.

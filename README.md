# Gladiatus Guild Treasury · Shared donations without a database

Official location: https://myrent-adi.github.io/gladiatus-guild-treasury/

## What this does

- The website displays the 99 active members (excluding RIP rank) and the existing 33 donation records totaling **15,225,244,307 gold**.
- Guild members submit a **GitHub Issue** using the `Gold donation request` form.
- The.T (or another trusted **repository collaborator**) verifies the claim and adds the **`approved`** label.
- GitHub Actions appends the approved request to `data/donations.json` and commits the change.
- The public site loads the JSON from GitHub's raw content service and updates once every 60 seconds (and when Refresh is clicked). New approved entries may take a little while to propagate through GitHub caching.
- The same player can have many separate donations. The leaderboard automatically sums them.
- Forum target uses a manually entered snapshot and does not add historical donations again.

## Install (replace current site)

1. Extract this archive.
2. In the GitHub repository `myrent-adi/gladiatus-guild-treasury`, upload **all** files and folders from the extracted package at the root (replace `index.html`). In particular, keep `.github/ISSUE_TEMPLATE/donation.yml`, `.github/workflows/approve-donation.yml`, `scripts/approve_donation.py`, `data/members.json`, and `data/donations.json` in their corresponding paths.
3. In **Settings → General → Features**, turn on **Issues**, if off.
4. In **Settings → Actions → General → Workflow permissions**, select **Read and write permissions** and save. This permits the repository workflow to update only the ledger file. If organization rules prevent this, use a PR-based or manual merge flow instead.
5. Verify **Actions** are allowed for the repository. GitHub Pages may stay configured as `Deploy from a branch` → `main` → `/(root)`.
6. In **Issues → Labels**, create a label exactly named `approved` (lowercase) and a label named `donation-request` if they do not exist. Issue forms can create the request label automatically only if it exists.
7. Visit the website and verify the totals and active roster.
8. Test: create a donation Issue, then **after verification** apply `approved`. Check the `Approve guild donation` workflow in Actions. Once finished, click Refresh on the website.

## Important caveats

- Anyone with a GitHub account may **submit** an Issue if Issues are public. Only collaborators with permission to manage labels should **approve** a donation.
- Do **not** give ordinary players write access to the repository or label-management rights.
- No secrets, GitHub personal access tokens or Supabase keys are used by the webpage. The old `config.js` and `supabase.sql` from the previous version are not needed and can be removed if desired.
- GitHub Pages is static hosting: updates require GitHub Actions or manual file commits, rather than a true live database. This workflow commits the data, while the page reads its latest approved ledger from raw GitHub content, so it does not rely on GitHub Pages redeploying after bot commits.
- An existing Issue can be approved **once**; repeated labels cannot double-count it.
- GitHub Issues are public, so do not enter private information in the request.
- The `approved` workflow validates the player against the active roster, date and amount before updating.
- You may need to refresh again because raw.githubusercontent.com can cache files.
- If a guild member has no GitHub account, The.T can submit a donation Issue for them.

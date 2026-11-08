#!/usr/bin/env python3
"""Approve a manually labeled GitHub Issue and append to the public ledger.

Only called by an issue labeled `approved`; repository collaborators control labels.
Idempotent by GitHub Issue number to prevent double counting.
"""
import datetime
import json
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def abort(message):
    raise SystemExit('Rejected donation: ' + message)


def field(body, label):
    # GitHub Issue Forms serialize each field under a Markdown heading.
    m = re.search(r'(?m)^### ' + re.escape(label) + r'\s*\n(.*?)(?=\n### |\Z)', body, re.S)
    return m.group(1).strip() if m else ''


def main():
    event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    issue = event.get('issue', {})
    labels = {label['name'] for label in issue.get('labels', [])}
    if 'approved' not in labels or 'donation-request' not in labels:
        abort('Issue must have both donation-request and approved labels')
    if issue.get('state') != 'open':
        abort('Issue is not open')
    body = issue.get('body') or ''
    player = field(body, 'Gladiator').strip()
    raw_amount = field(body, 'Amount (gold)').strip()
    raw_date = field(body, 'Date (YYYY-MM-DD)').strip()
    note = field(body, 'Note').strip()
    if not re.fullmatch(r'[0-9]{1,15}', raw_amount):
        abort('Gold amount must contain digits only')
    amount = int(raw_amount)
    if amount < 1:
        abort('Gold amount must be positive')
    try:
        actual_date = datetime.date.fromisoformat(raw_date)
    except ValueError:
        abort('Invalid ISO date')
    if actual_date.isoformat() != raw_date:
        abort('Use YYYY-MM-DD date format')
    if actual_date > datetime.date.today() + datetime.timedelta(days=1):
        abort('Donation date cannot be in the future')
    if len(note) > 220:
        abort('Note is too long')
    if note == '_No response_':
        note = ''
    roster = json.loads((ROOT / 'data/members.json').read_text())
    lookup = {member['name'].casefold(): member['name'] for member in roster}
    if player.casefold() not in lookup:
        abort('Unknown player or RIP player: ' + player)
    player = lookup[player.casefold()]
    ledger_path = ROOT / 'data/donations.json'
    ledger = json.loads(ledger_path.read_text())
    issue_number = issue.get('number')
    if not isinstance(issue_number, int) or issue_number < 1:
        abort('Missing GitHub Issue number')
    if any(d.get('issue') == issue_number for d in ledger['donations']):
        print('Issue already recorded; no duplicate added')
        return
    ledger['donations'].append({
        'id': 'issue-' + str(issue_number),
        'issue': issue_number,
        'player': player,
        'amount': amount,
        'date': raw_date,
        'note': note,
    })
    ledger_path.write_text(json.dumps(ledger, ensure_ascii=False, indent=2) + '\n')
    print('Approved Issue', issue_number, player, amount, 'gold')


if __name__ == '__main__':
    main()

/* Gladiatus Guild Treasury: donation submission status modal.
 * Add <script src="./donation-modal.js" defer></script> to index.html.
 * Uses the existing donationForm and donationResponseFrame; does not alter data.
 */
(() => {
  'use strict';
  function start() {
    const form = document.getElementById('donationForm');
    const frame = document.getElementById('donationResponseFrame');
    if (!form || !frame || document.getElementById('donationStatusModal')) return;

    const css = document.createElement('style');
    css.textContent = `
      #donationStatusModal[hidden] { display:none !important }
      #donationStatusModal { position:fixed; inset:0; z-index:2147483640; display:grid; place-items:center; padding:20px; background:rgba(5,4,3,.82) }
      #donationStatusModal .dsm-card { box-sizing:border-box; width:min(100%,400px); padding:28px 24px; text-align:center; color:#f8ebd7; background:linear-gradient(150deg,#382518,#1c130d); border:1px solid #b4874d; box-shadow:0 18px 65px #000b; border-radius:8px; font:16px/1.5 system-ui,sans-serif }
      #donationStatusModal .dsm-icon { display:grid; place-items:center; margin:0 auto 15px; width:57px; height:57px; color:#f4ce88; border-radius:50%; background:#4b311d; font-size:29px }
      #donationStatusModal h2 { margin:0 0 10px; font:700 27px/1.2 Georgia,serif; color:#f4ce88; border:0; padding:0 }
      #donationStatusModal p { margin:0 0 20px; color:#e6d3b5; overflow-wrap:anywhere }
      #donationStatusModal .dsm-spinner { width:26px; height:26px; border:3px solid #927047; border-top-color:#ffe2a4; border-radius:50%; animation:dsm-spin .8s linear infinite }
      @keyframes dsm-spin { to { transform:rotate(360deg) } }
      @media(prefers-reduced-motion:reduce){ #donationStatusModal .dsm-spinner { animation:none } }
      #donationStatusModal button { background:linear-gradient(#f7daa0,#c9934c); color:#211409; border:0; border-radius:5px; padding:12px 24px; font:700 16px system-ui,sans-serif; min-height:44px; cursor:pointer }
    `;
    document.head.appendChild(css);

    const modal = document.createElement('div');
    modal.id = 'donationStatusModal';
    modal.hidden = true;
    modal.setAttribute('role', 'dialog');
    modal.setAttribute('aria-modal', 'true');
    modal.setAttribute('aria-labelledby', 'dsmTitle');
    modal.innerHTML = '<div class="dsm-card"><div class="dsm-icon" id="dsmIcon" aria-hidden="true"></div><h2 id="dsmTitle"></h2><p id="dsmText" aria-live="polite"></p><button type="button" id="dsmClose" hidden>Close</button></div>';
    document.body.appendChild(modal);
    const title = modal.querySelector('#dsmTitle');
    const detail = modal.querySelector('#dsmText');
    const icon = modal.querySelector('#dsmIcon');
    const close = modal.querySelector('#dsmClose');
    let waiting = false;
    let timer = null;
    let previousFocus = null;

    function show(state, message) {
      modal.hidden = false;
      const saving = state === 'sending';
      title.textContent = saving ? 'Sending donation…' : state === 'success' ? 'Donation sent successfully!' : state === 'error' ? 'Submission failed' : 'Donation request sent';
      detail.textContent = message;
      icon.replaceChildren();
      if (saving) {
        const spinner = document.createElement('span'); spinner.className = 'dsm-spinner'; icon.appendChild(spinner);
      } else icon.textContent = state === 'success' ? '✓' : state === 'error' ? '!' : '?';
      close.hidden = saving;
      if (!saving) close.focus();
    }
    function finish(state, message) {
      if (!waiting) return;
      waiting = false;
      clearTimeout(timer);
      show(state, message);
    }
    close.addEventListener('click', () => {
      modal.hidden = true;
      if (previousFocus && typeof previousFocus.focus === 'function') previousFocus.focus();
    });
    modal.addEventListener('keydown', event => {
      if (event.key === 'Escape' && !close.hidden) close.click();
      if (event.key === 'Tab' && !close.hidden) { event.preventDefault(); close.focus(); }
    });

    // This capture handler runs before the existing submit handler and retains its validation.
    form.addEventListener('submit', event => {
      const config = window.TREASURY_SETTINGS || {};
      const player = form.querySelector('[name="player"]');
      const amount = form.querySelector('[name="amount"]');
      const chosen = player && player.value;
      const gold = amount ? Number(amount.value) : 0;
      if (!config.appsScriptUrl || !form.checkValidity() || !chosen || !Number.isSafeInteger(gold) || gold < 1) return;
      if (waiting) { event.preventDefault(); return; }
      waiting = true;
      previousFocus = document.activeElement;
      show('sending', 'Saving your donation to the guild ledger. Please keep this page open.');
      timer = setTimeout(() => finish('unknown', 'The donation request was submitted for review. The.T will check and approve it in Google Sheets. Receipt has not yet been confirmed, so please do not submit it again.'), 14000);
    }, true);

    // A success popup is shown ONLY after receiving a positive message from the Apps Script iframe.
    window.addEventListener('message', event => {
      if (!waiting || event.source !== frame.contentWindow) return;
      const data = event.data;
      if (!data || data.type !== 'gladiatus-donation-result') return;
      if (data.ok === true) finish('success', 'Your donation has been saved and is awaiting review and approval by The.T.');
      else finish('error', data.message || 'Google Sheets did not accept the donation.');
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start, {once:true});
  else start();
})();

/* Gladiatus Guild Treasury: read bank balance from Google Sheets via existing Apps Script.
   No secret or admin token is required for this read-only display. */
(() => {
  'use strict';
  const init = () => {
    const fortune = document.getElementById('fortune');
    if (!fortune || !window.TREASURY_SETTINGS?.appsScriptUrl) return;
    const endpoint = window.TREASURY_SETTINGS.appsScriptUrl.trim();
    if (!/^https:\/\/script\.google\.com\/macros\/s\/[A-Za-z0-9_-]+\/exec(?:\?.*)?$/.test(endpoint)) return;

    const status = document.createElement('p');
    status.id = 'bankSyncStatus';
    status.style.cssText = 'font-size:12px;color:#d2b99a;margin:6px 0 0;overflow-wrap:anywhere';
    fortune.insertAdjacentElement('afterend',status);
    let inFlight = false;
    let hasRemoteValue = false;
    let onTimeout = null;

    function fetchBank() {
      if (inFlight) return;
      inFlight = true;
      status.textContent = 'Updating guild bank balance from Google Sheets…';
      const callback = 'gladiatusBankCb_' + Date.now() + '_' + Math.floor(Math.random() * 100000);
      const script = document.createElement('script');
      let settled = false;
      function finish(error, data) {
        if (settled) return;
        settled = true;
        inFlight = false;
        clearTimeout(onTimeout);
        script.remove();
        delete window[callback];
        if (error) {
          status.textContent = (hasRemoteValue ? 'Latest bank update unavailable; showing last loaded value. ' : 'Could not load bank balance. ') + error.message;
          return;
        }
        // A blank GuildBank sheet returns gold:null. Never overwrite the existing value with zero.
        if (data.gold === null || data.gold === undefined || data.gold === '') {
          status.textContent = 'No bank balance saved in GuildBank yet.';
          return;
        }
        const gold = Number(data.gold);
        if (!Number.isSafeInteger(gold) || gold < 0) {
          status.textContent = 'Invalid bank balance in Google Sheets.';
          return;
        }
        fortune.value = String(gold);
        hasRemoteValue = true;
        // Trigger the existing forum calculator, including Gold still needed and progress.
        fortune.dispatchEvent(new Event('input', { bubbles: true }));
        status.textContent = '✓ Guild bank synced from Google Sheets' + (data.updatedAt ? ' · ' + new Date(data.updatedAt).toLocaleString() : '');
      }
      window[callback] = data => {
        if (!data || data.ok !== true) return finish(new Error(data?.error || 'Unexpected response'));
        finish(null, data);
      };
      script.onerror = () => finish(new Error('Network or access error'));
      onTimeout = setTimeout(() => finish(new Error('Request timed out')), 15000);
      const url = new URL(endpoint);
      url.searchParams.set('action', 'bank');
      url.searchParams.set('callback', callback);
      url.searchParams.set('t', String(Date.now()));
      script.src = url.toString();
      document.head.append(script);
    }
    const refresh = document.getElementById('refreshBtn');
    if (refresh) refresh.addEventListener('click', fetchBank);
    fetchBank();
    setInterval(fetchBank, 60000);
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init, { once: true });
  else init();
})();

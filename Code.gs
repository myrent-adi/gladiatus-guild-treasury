/**
 * Gladiatus Guild Treasury — Google Sheets bridge.
 * Create script from Extensions > Apps Script inside the destination spreadsheet.
 * Deploy as Web app: Execute as Me; Who has access: Anyone.
 * DO NOT store administrator passwords or GitHub tokens in the public website.
 * New rows are Pending until The.T manually changes Status to Approved.
 */
const TAB_NAME = 'Donations';
const HEADERS = ['ID', 'Submitted At', 'Gladiator', 'Gold', 'Donation Date', 'Note', 'Status'];

function sheet_() {
  const book = SpreadsheetApp.getActiveSpreadsheet();
  if (!book) throw new Error('Open this script from its Google Spreadsheet.');
  let tab = book.getSheetByName(TAB_NAME);
  if (!tab) tab = book.insertSheet(TAB_NAME);
  if (tab.getLastRow() === 0) {
    tab.appendRow(HEADERS);
    tab.setFrozenRows(1);
    tab.getRange('D:D').setNumberFormat('0');
    tab.getRange('G1').setNote('The guild administrator changes Pending to Approved after checking in-game donations.');
  }
  return tab;
}

function setup() {
  sheet_();
}

function doGet(e) {
  const callback = String(e.parameter.callback || '');
  if (!/^[A-Za-z_$][A-Za-z0-9_$]{0,90}$/.test(callback)) {
    return ContentService.createTextOutput('Invalid callback').setMimeType(ContentService.MimeType.TEXT);
  }
  try {
    const tab = sheet_();
    const rows = tab.getDataRange().getValues().slice(1);
    const donations = rows.filter(r => String(r[6]).trim().toLowerCase() === 'approved')
      .map(r => ({
        id: String(r[0]),
        player: String(r[2]),
        amount: Number(r[3]),
        date: r[4] instanceof Date ? Utilities.formatDate(r[4], Session.getScriptTimeZone(), 'yyyy-MM-dd') : String(r[4]),
        note: String(r[5] || '').slice(0,100)
      })).filter(r => Number.isSafeInteger(r.amount) && r.amount > 0);
    return jsonp_(callback, {ok:true,donations});
  } catch (err) {
    return jsonp_(callback, {ok:false,error:'Unable to read approved donations'});
  }
}

function jsonp_(callback, value) {
  return ContentService.createTextOutput(callback + '(' + JSON.stringify(value).replace(/\u2028/g,'\\u2028').replace(/\u2029/g,'\\u2029') + ');')
    .setMimeType(ContentService.MimeType.JAVASCRIPT);
}

function doPost(e) {
  try {
    const p = e.parameter || {};
    const name = String(p.player || '').trim();
    const amount = Number(p.amount);
    const date = String(p.date || '');
    const note = String(p.note || '').trim();
    if (!name || name.length > 45 || !Number.isSafeInteger(amount) || amount < 1 || amount > 999999999999999 ||
        !/^\d{4}-\d{2}-\d{2}$/.test(date) || note.length > 100) {
      return response_(false,'Invalid donation details.');
    }
    const lock = LockService.getScriptLock();
    lock.waitLock(10000);
    try {
      const tab = sheet_();
      tab.appendRow([Utilities.getUuid(), new Date(), name, amount, date, note, 'Pending']);
    } finally {
      lock.releaseLock();
    }
    return response_(true,'Donation submitted for review.');
  } catch(err) {
    return response_(false,'Unable to submit donation.');
  }
}

function response_(ok, message) {
  const payload = JSON.stringify({type:'gladiatus-donation-result', ok, message});
  const html = '<!doctype html><html><body><script>window.parent.postMessage(' + payload + ',"*");<\/script></body></html>';
  return HtmlService.createHtmlOutput(html).setTitle('Donation response');
}

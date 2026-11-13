const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const html = fs.readFileSync('index.html', 'utf8');
const script = html.slice(html.indexOf('function certificateStatus('), html.indexOf('function renderRoster()'));
const elements = { certificateBody: {}, certificateEmpty: {} };
const context = vm.createContext({
  document: { getElementById: id => elements[id] },
  escapeHtml: s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;'),
  fmtDate: iso => iso.split('-').reverse().join('/')
});
vm.runInContext(script, context);

test('certificati scaduti, in scadenza e date non valide', () => {
  const today = new Date(2024, 1, 28, 23, 30);
  for (const [date, expected] of [
    ['2023-01-01', 'expired'], ['2024-02-27', 'expired'], ['2024-02-28', 'warning'],
    ['2024-04-28', 'warning'], ['2024-04-29', ''], ['', ''],
    ['2024-02-30', ''], ['2024-2-29', '']
  ]) {
    assert.equal(context.certificateStatus(date, today), expected, date);
  }
});

test('lista ordinata per scadenza, con nomi protetti e stato vuoto', () => {
  const today = new Date();
  const dateAfter = days => {
    const date = new Date(today.getFullYear(), today.getMonth(), today.getDate() + days);
    return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');
  };
  context.roster = [
    { nome: 'ULTIMO', scadenzaCertificato: dateAfter(60) },
    { nome: '<PRIMO>', scadenzaCertificato: dateAfter(0) },
    { nome: 'SCADUTO', scadenzaCertificato: dateAfter(-1) },
    { nome: 'OLTRE', scadenzaCertificato: dateAfter(61) }
  ];
  context.renderCertificates();
  assert.match(elements.certificateBody.innerHTML, /&lt;PRIMO>/);
  assert.ok(elements.certificateBody.innerHTML.indexOf('&lt;PRIMO>') < elements.certificateBody.innerHTML.indexOf('ULTIMO'));
  assert.ok(elements.certificateBody.innerHTML.indexOf('SCADUTO') < elements.certificateBody.innerHTML.indexOf('&lt;PRIMO>'));
  assert.match(elements.certificateBody.innerHTML, /class="certificate-expired"><td>SCADUTO<\/td>.*<td>Scaduto<\/td>/);
  assert.match(elements.certificateBody.innerHTML, /class="certificate-warning"><td>&lt;PRIMO><\/td>.*<td>In scadenza<\/td>/);
  assert.doesNotMatch(elements.certificateBody.innerHTML, /OLTRE/);
  assert.equal(elements.certificateEmpty.hidden, true);
  context.roster = [];
  context.renderCertificates();
  assert.equal(elements.certificateBody.innerHTML, '');
  assert.equal(elements.certificateEmpty.hidden, false);
});

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const html = fs.readFileSync('index.html', 'utf8');
const script = html.slice(html.indexOf('function isCertificateExpiring('), html.indexOf('function renderRoster()'));
const elements = { certificateBody: {}, certificateEmpty: {} };
const context = vm.createContext({
  document: { getElementById: id => elements[id] },
  escapeHtml: s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;'),
  fmtDate: iso => iso.split('-').reverse().join('/')
});
vm.runInContext(script, context);

test('scadenze entro 60 giorni inclusi, senza date trascorse o non valide', () => {
  const today = new Date(2024, 1, 28, 23, 30);
  for (const [date, expected] of [
    ['2024-02-27', false], ['2024-02-28', true], ['2024-04-28', true],
    ['2024-04-29', false], ['', false], ['2024-02-30', false], ['2024-2-29', false]
  ]) {
    assert.equal(context.isCertificateExpiring(date, today), expected, date);
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
  assert.doesNotMatch(elements.certificateBody.innerHTML, /SCADUTO|OLTRE/);
  assert.equal(elements.certificateEmpty.hidden, true);
  context.roster = [];
  context.renderCertificates();
  assert.equal(elements.certificateBody.innerHTML, '');
  assert.equal(elements.certificateEmpty.hidden, false);
});

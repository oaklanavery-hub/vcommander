const { playbackClockSkew } = require('./browser_clock.cjs');
// Two isolated browser sessions exercise the real exported Godot UI and server.
const serverUrl = (() => {
  let value;
  try { value = new URL(process.env.PVP_SERVER_URL || 'ws://127.0.0.1:10000'); }
  catch { throw Error('PVP_SERVER_URL must be a public WSS endpoint or loopback WS URL'); }
  const loopback = value.protocol === 'ws:' && ['127.0.0.1', 'localhost'].includes(value.hostname);
  if ((!loopback && value.protocol !== 'wss:') || value.username || value.password || value.search || value.hash) {
    throw Error('PVP_SERVER_URL requires WSS remotely and must not contain credentials, a query or a fragment');
  }
  return value;
})();
const { chromium } = require(process.env.PVP_PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs');
const path = require('node:path');

(async () => {
  const output = 'build/qa-browser';
  fs.mkdirSync(output, { recursive: true });
  const browser = await chromium.launch({ headless: true, args: [
    '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--enable-webgl',
  ] });
  const errors = [];
  const contexts = [];
  const pages = [];
  const consoleLog = [];
  try {
    async function page() {
      const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
      contexts.push(context);
      const tab = await context.newPage();
      pages.push(tab);
      tab.on('pageerror', error => { errors.push(String(error)); console.error('Browser:', error); });
      tab.on('console', message => {
        consoleLog.push(message.type() + ': ' + message.text());
        if (/SCRIPT ERROR:|\bERROR:/.test(message.text())) { errors.push(message.text()); console.error('Godot browser:', message.text()); }
      });
      tab.on('requestfailed', request => consoleLog.push('Request failed: ' + request.url() + ' ' + request.failure()?.errorText));
      tab.setDefaultTimeout(180000);
      return tab;
    }
    const address = new URL('http://127.0.0.1:8765/index.html');
    address.searchParams.set('pvp_server', serverUrl.href);
    const base = address.href;
    const local = await page();
    await local.goto(base + '&qa_role=local&qa_stage=prepare');
    await local.waitForFunction(() => window.vcommanderLocalQa?.stage === 'prepare');
    const prepared = await local.evaluate(() => window.vcommanderLocalQa);
    if (!prepared.ok || !prepared.persistent || !prepared.continue_visible) throw Error('Local browser checkpoint was not saved');
    await local.screenshot({ path: path.join(output, 'browser_local_saved.png') });
    // Allow the engine's normal asynchronous browser filesystem sync, then
    // replace the entire WebAssembly instance in the same browser context.
    await local.waitForTimeout(2500);
    await local.goto(base + '&qa_role=local&qa_stage=restore');
    await local.waitForFunction(() => window.vcommanderLocalQa?.stage === 'restore');
    const restored = await local.evaluate(() => window.vcommanderLocalQa);
    if (!restored.ok || !restored.continue_visible || restored.scene !== 'Draft') throw Error('Actual Continue adventure failed after browser restart');
    if (JSON.stringify(prepared.snapshot) !== JSON.stringify(restored.snapshot) || restored.clock > prepared.clock || restored.clock < prepared.clock - 0.5) throw Error('Browser recovery changed the offer, seed, allowance or clock');
    if (JSON.stringify(prepared.opponent_snapshot) !== JSON.stringify(restored.opponent_snapshot) || JSON.stringify(prepared.hearts) !== JSON.stringify(restored.hearts) || prepared.pending !== restored.pending) throw Error('Browser recovery changed the rival, hearts or pending profile identity');
    if (JSON.stringify(prepared.public_specialization) !== JSON.stringify(restored.public_specialization)) throw Error('Browser recovery revealed or replaced the rival current path');
    await local.screenshot({ path: path.join(output, 'browser_local_resumed.png') });
    await local.context().close();
    console.log('Browser local recovery passed: actual commander-path purchase, IndexedDB restart, actual Continue button, exact draft/RNG, preserved path/redraw/clock, hidden rival path and no profile loss.');
    const sudden = await page();
    await sudden.goto(base + '&qa_role=local&qa_stage=sudden_prepare');
    await sudden.waitForFunction(() => window.vcommanderLocalQa?.stage === 'sudden_prepare');
    const suddenPrepared = await sudden.evaluate(() => window.vcommanderLocalQa);
    if (!suddenPrepared.ok || !suddenPrepared.persistent) throw Error('Enhanced power was not saved through the actual draft button');
    await sudden.screenshot({ path: path.join(output, 'browser_sudden_saved.png') });
    await sudden.waitForTimeout(2500);
    await sudden.goto(base + '&qa_role=local&qa_stage=sudden_restore');
    await sudden.waitForFunction(() => window.vcommanderLocalQa?.stage === 'sudden_restore');
    const suddenRestored = await sudden.evaluate(() => window.vcommanderLocalQa);
    if (!suddenRestored.ok || suddenRestored.scene !== 'Draft') throw Error('Sudden Death Continue adventure failed');
    for (const key of ['snapshot', 'opponent_snapshot', 'hearts', 'public_buffs', 'public_specialization', 'pending']) {
      if (JSON.stringify(suddenPrepared[key]) !== JSON.stringify(suddenRestored[key])) throw Error('Sudden Death restart changed ' + key);
    }
    if (suddenRestored.clock > suddenPrepared.clock || suddenRestored.clock < suddenPrepared.clock - 0.5) throw Error('Sudden Death restart changed pick time');
    await sudden.screenshot({ path: path.join(output, 'browser_sudden_resumed.png') });
    await sudden.context().close();
    console.log('Browser Sudden Death recovery passed: actual enhanced draft pick, IndexedDB reload, actual Continue, exact mixed cohorts/RNG, 180-second budget, hidden rival powers, path, redraw and profile identity.');
    const upgrades = await page();
    await upgrades.goto(base + '&qa_role=local&qa_stage=upgrade_prepare');
    await upgrades.waitForFunction(() => window.vcommanderLocalQa?.stage === 'upgrade_prepare');
    const upgradePrepared = await upgrades.evaluate(() => window.vcommanderLocalQa);
    if (!upgradePrepared.ok || !upgradePrepared.persistent) throw Error('Actual unit forge purchase failed: ' + JSON.stringify(upgradePrepared));
    await upgrades.screenshot({ path: path.join(output, 'browser_upgrades_saved.png') });
    await upgrades.waitForTimeout(2500);
    await upgrades.goto(base + '&qa_role=local&qa_stage=upgrade_restore');
    await upgrades.waitForFunction(() => window.vcommanderLocalQa?.stage === 'upgrade_restore');
    const upgradeRestored = await upgrades.evaluate(() => window.vcommanderLocalQa);
    if (!upgradeRestored.ok || upgradeRestored.scene !== 'Draft') throw Error('Unit forge Continue failed after restart: ' + JSON.stringify(upgradeRestored));
    for (const key of ['wallet', 'owned', 'mastery', 'price', 'active_upgrades', 'preview_level', 'snapshot', 'opponent_snapshot', 'public_upgrades', 'hearts', 'pending']) {
      if (JSON.stringify(upgradePrepared[key]) !== JSON.stringify(upgradeRestored[key])) throw Error('Unit forge restart changed ' + key);
    }
    if (upgradeRestored.clock > upgradePrepared.clock || upgradeRestored.clock < upgradePrepared.clock - 0.5) throw Error('Unit forge restart changed draft time');
    await upgrades.screenshot({ path: path.join(output, 'browser_upgrades_resumed.png') });
    await upgrades.context().close();
    console.log('Browser unit upgrades passed: actual main-menu/standalone Forge/200-XP button, separate Lv. 2 art, IndexedDB restart, actual Continue, exact 200-XP balance/400-XP next price, unchanged mastery, frozen upgrades, AI/public collection, draft/RNG and hearts.');
    const host = await page();
    await host.goto(base + '&qa_role=host');
    await host.waitForFunction(() => window.vcommanderPvpQa?.room?.length === 6, null,
      { timeout: process.env.PVP_SERVER_URL ? 120000 : 60000 });
    const room = (await host.evaluate(() => window.vcommanderPvpQa)).room;
    await host.screenshot({ path: path.join(output, 'browser_host_waiting.png') });
    const guest = await page();
    await guest.goto(base + '&qa_role=guest&room=' + room);
    await host.waitForFunction(() => window.vcommanderPvpQa?.opening_time >= 0.7 && window.vcommanderPvpQa?.battle_time === 0);
    await host.screenshot({ path: path.join(output, 'browser_host_opening.png') });
    await guest.waitForFunction(() => window.vcommanderPvpQa?.phase === 'playing');
    await host.waitForFunction(() => window.vcommanderPvpQa?.battle_time >= 0.7);
    const [first, second] = await Promise.all([host, guest].map(tab => tab.evaluate(() => ({
      ...window.vcommanderPvpQa, observed_at_ms: Date.now()
    }))));
    if (first.room !== second.room || first.side !== 'player' || second.side !== 'opponent') throw Error('Incorrect private seats');
    if (first.font_symbols_ready !== true || second.font_symbols_ready !== true) throw Error('Exported browser is missing bundled UI symbol glyphs');
    if (first.play_at !== second.play_at || first.play_until !== second.play_until) throw Error('Different server timelines');
    const clockSkew = playbackClockSkew(first, second);
    if (clockSkew > 0.5) throw Error('Browser playback clocks diverged: ' + JSON.stringify({ clockSkew, first, second }));
    if (!first.controls_locked || !second.controls_locked || !first.local_left || !second.local_left) throw Error('Shared controls or local-left viewpoint failed');
    await host.screenshot({ path: path.join(output, 'browser_host_battle.png') });
    await guest.screenshot({ path: path.join(output, 'browser_guest_battle.png') });
    await host.waitForFunction(() => window.vcommanderPvpQa?.finished);
    await guest.waitForFunction(() => window.vcommanderPvpQa?.finished);
    const result = await host.evaluate(() => window.vcommanderPvpQa);
    const rival = await guest.evaluate(() => window.vcommanderPvpQa);
    if (JSON.stringify(result.losses) !== JSON.stringify(rival.losses) || result.winner !== rival.winner || result.round_winner !== rival.round_winner) throw Error('Browser results disagree');
    if ((result.losses.player || 0) + (result.losses.opponent || 0) < 1) throw Error('Round did not score a heart');
    if (!result.records_unchanged || !rival.records_unchanged) throw Error('Friend playtest changed local records');
    if (errors.length) throw Error(errors.join('\n'));
    await host.screenshot({ path: path.join(output, 'browser_host_result.png') });
    await guest.screenshot({ path: path.join(output, 'browser_guest_result.png') });
    console.log('Exported-browser PvP passed against ' + serverUrl.host + ': two isolated WebGL2 sessions, bundled UI glyphs, invite/join/draft, Commander opening, shared 1x clock, mirrored guest, common result and untouched mastery.');
  } catch (error) {
    console.error(consoleLog.slice(-60).join('\n'));
    fs.writeFileSync(path.join(output, 'browser-console.txt'), consoleLog.join('\n'));
    for (let index = 0; index < pages.length; index++) {
      const tab = pages[index];
      await tab.screenshot({ path: path.join(output, 'failure_' + index + '.png') }).catch(() => {});
      const state = await tab.evaluate(() => ({ qa: window.vcommanderPvpQa, body: document.body.innerText,
        config: typeof GODOT_CONFIG === 'undefined' ? null : GODOT_CONFIG })).catch(() => null);
      console.error('Browser state:', JSON.stringify(state));
      fs.writeFileSync(path.join(output, 'failure_' + index + '.json'), JSON.stringify(state, null, 2));
    }
    throw error;
  } finally {
    for (const context of contexts) await context.close();
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });

'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { playbackClockSkew } = require('../tools/browser_clock.cjs');

test('healthy clocks agree despite evaluations two seconds apart', () => {
  assert.equal(playbackClockSkew(
    { battle_time: 5, observed_at_ms: 10000 },
    { battle_time: 7, observed_at_ms: 12000 }), 0);
});
test('real drift remains visible after observation-time alignment', () => {
  assert.equal(playbackClockSkew(
    { battle_time: 5, observed_at_ms: 10000 },
    { battle_time: 8, observed_at_ms: 12000 }), 1);
  assert.equal(playbackClockSkew(
    { battle_time: 5, observed_at_ms: 10000 },
    { battle_time: 6, observed_at_ms: 10000 }), 1);
});
test('the existing half-second tolerance still catches a stalled peer', () => {
  assert.ok(playbackClockSkew(
    { battle_time: 5, observed_at_ms: 10000 },
    { battle_time: 5.6, observed_at_ms: 10000 }) > 0.5);
  assert.ok(playbackClockSkew(
    { battle_time: 5, observed_at_ms: 10000 },
    { battle_time: 5.3, observed_at_ms: 10000 }) < 0.5);
});
test('missing, infinite or invalid samples cannot silently pass', () => {
  for (const battle_time of [undefined, NaN, Infinity]) {
    assert.throws(() => playbackClockSkew(
      { battle_time, observed_at_ms: 10000 },
      { battle_time: 5, observed_at_ms: 10000 }));
  }
});

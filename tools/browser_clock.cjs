'use strict';

// Compare progress at a common observation time. Browser evaluations may run
// at different moments even when both players follow the same server clock.
function playbackClockSkew(first, second) {
  for (const sample of [first, second]) {
    if (!Number.isFinite(sample.battle_time) || !Number.isFinite(sample.observed_at_ms)) {
      throw new Error('Missing finite browser playback sample');
    }
  }
  return Math.abs((first.battle_time - second.battle_time)
    - (first.observed_at_ms - second.observed_at_ms) / 1000);
}

module.exports = { playbackClockSkew };

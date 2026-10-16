# Game Design — VCommander

## High concept

VCommander is a progressive, browser-first drafting auto-battler centered on VTuber Commanders and customizable four-card Armies.

The player chooses a main Commander, equips an Army of four cards, and enters a drafting/auto-combat match. A Commander has a signature four-card set. Equipping the complete set activates that Commander's set bonus.

## Phase 1 fantasy

The initial prototype proves only the core choice:

**Commander + four-card Army + full-set synergy + drafting + automatic battle.**

The starter content uses three elemental families:

- Fire
- Water
- Earth

## Design pillars

### Commander identity
The Commander should meaningfully shape army-building decisions rather than acting as a cosmetic portrait.

### Readable armies
A player should be able to understand what four cards they brought and whether a set bonus is active at a glance.

### Data-driven growth
Adding future Commanders, cards, sets, elements and balance changes should mostly involve new or edited content data rather than changes to core code.

### Reproducible battles
Auto-combat needs deterministic seeded simulation so bugs and balance outcomes can be reproduced.

### Browser first
The prototype must remain practical to play through a normal web browser.

## Out of scope for the first prototype

- PvP networking
- Accounts or cloud saves
- Gacha
- Monetization
- Large card collection
- Final VTuber artwork
- Final economy or progression

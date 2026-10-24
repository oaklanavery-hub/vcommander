# Permanent unit upgrades

The user approved the supplied `Vcommande upgrades.xlsx` reference (Sheet1 E2:E25) on 2026-10-24, with explicit first-version balancing. Each unit has one permanent Lv. 2 purchase. A shared wallet makes XP earned with any Commander spendable on an unlocked unit. Existing lifetime XP becomes available; previously earned levels, records, achievements and card ownership remain intact.

## Costs and rewards

The first profile purchase costs **200 XP**, every later unit costs **400 XP**. Wins earn **100 XP**, completed losses **50 XP**, forfeits zero. Per-Commander lifetime mastery remains 250 XP per level. Buying an upgrade deducts its recorded price from spendable XP only. Completed-match settlement remains exact-once. Purchases require an unlocked unit and no pending local/online adventure. Save errors do not consume XP before a committed write.

At a hypothetical 50% win rate, average earnings are 75 XP per full adventure. Starting with no wallet, a preferred four-unit warband costs 1400 XP (about 19 adventures), six units 2200 (about 30), all 24 units 9400 (about 126). These are arithmetic planning estimates, not observed player behavior or guarantees. Existing unit-unlock requirements still apply and old profiles may already have a balance.

## Lv. 2 abilities

All original abilities remain unless the description explicitly replaces a parameter. Damage uses ordinary DEF, absorption, team ownership and death resolution. Twin-hit and dual-head damage percentages apply **after DEF**, preserving their intended advantage against armor; minimum damage remains 1. Different upgrades have different tactical benefits, so costs do not substitute for balance testing.

| Unit | Upgrade | Effective description |
| --- | --- | --- |
| Magma Golem | Inferno Ring | Keeps Burning Aura and releases a large fire ring every 3 seconds for 150% ATK before DEF. |
| Fire Imp | Twin Strikes | Each melee attack hits twice, each dealing 75% of a regular hit after DEF. Volatile Imp is unchanged. |
| Sorcerer | Greater Fireball | Larger fireballs splash a medium radius for 60% ATK around the enemy hit. |
| Dragon | Scorched Ground | Dragonfire keeps its burn and leaves a large fire field for 5 seconds, dealing 20% ATK each second. One ground field per Dragon; a new hit replaces it. |
| Ash Phoenix | Last Ember | On death, restores 30% Max HP to living allies in a large radius. |
| Spriggan | Lasting Embers | A fire trail remains until two later fireball arrivals. If its owner dies, it fades within 10 seconds. Each trail damages an enemy once per tick. |
| Ice Giant | Ice Splinters | Each normal attack has a seeded 20% chance to burst ice in a small radius around its target for 75% ATK before DEF. |
| Sea Serpent | Twin Heads | Two heads attack at twice the normal rate, each shot dealing 70% of a regular hit after DEF. The Attack Speed rating cap still applies. |
| Penguins | Deeper Puddles | Healing Puddle restores 5.5% Max HP per tick instead of 5%: a relative 10% healing increase. |
| Water Wizard | Crashing Tide | Shots push enemies a moderate distance and slow movement by 20% for 1 second. |
| Tidal Guard | Shell Breaker | Every third attack deals 200% ATK before DEF instead of 160%. |
| Nymph | Riptide | Water gush pushes enemies a large distance and slows their movement by 20% for 1 second. Each enemy is hit once per gush. |
| Giant Tree | Ancient Canopy | Grows 20% larger visually and increases the healing aura radius by 25%. |
| Pitcher Plant | Binding Vines | Vine Pull roots the pulled enemy for 2 seconds. Root blocks walking and starting a backline transit, but permits attacking and forced displacement. |
| Bear | Relentless Maul | Consecutive melee strikes on the same target gain 5% damage per strike, up to 50%. Switching targets resets the bonus. Maul still empowers every third hit. |
| Wood Archers | Double Loose | Each attack fires two arrows, each dealing 75% of a regular hit after DEF. |
| Spore Sage | Armor Spores | Direct hits reduce the target’s DEF by 3% per stack, up to 30%. Stacks last 5 seconds after the latest hit and are shared across allied Spore Sages. |
| Mole | Upheaval | Each normal attack has a seeded 15% chance to knock its enemy back a small distance. Cracks still block displacement. |
| Giant Slime | Jelly Family | Small slimes split once more into two tiny slimes each, with 50% of their parent’s HP and ATK. Two split generations maximum; revived parents never split a second time. |
| Slime Cannon | Clinging Shots | Direct hits also reduce Attack Speed by 5% per stack, up to 30%, for 5 seconds after the latest hit. The ordinary splash slow remains. |
| Slime Ball | Corrosive Jelly | On death, leaves a large field for 5 seconds that reduces enemy DEF by 20% while inside. Overlapping corrosive fields do not stack. |
| Slime Barrel | Clogging Spill | The death explosion and damaging pool remain. A large field also slows enemies inside by 15% for 10 seconds; overlapping fields do not stack. |
| Jelly Medic | Last Remedy | On death, leaves a large healing pool for 5 seconds, restoring 10% Max HP each second to allies inside. Overlapping Last Remedy pools heal once per tick. |
| Sticky Slime | Final Bond | On death, links all enemies within a medium radius for 5 seconds. Hits to one share 25% of actual damage with each linked partner. Shared damage cannot share again; overlapping links use the strongest share per partner. |

## Adventure and presentation rules

The purchased collection freezes at adventure start and is supplied equally to both PvAI sides. Runtime transformations copy base content and apply once before optional Commander paths. Old saved adventures remain base-unit adventures, and recorded upgrades/powers/paths reconstruct without rescoring hearts or currency. Private PvP retains base units while its public entry remains Coming Soon.

All 24 units have separate Lv. 2 sprite artwork in cards, rosters, living/dead/revived replay actors and inspection. The normal atlas stays unchanged. Root vines, elemental pulses, persistent fire/corrosion/slowing/healing fields and ability sounds read recorded combat evidence. Ground fields honor exact event creation, replacement and expiry; they never appear early or extend the battle after army elimination. No effect or team text is added over units. Art provenance and prompts are in [UPGRADE_ART.md](../assets/pixel/UPGRADE_ART.md).

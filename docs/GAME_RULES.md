# Game Rules

This file is the authoritative gameplay rules document. Rules not written here are not considered locked.

## Match setup

**R001 — Commander selection**  
A player selects one Commander for a match.

**R002 — Army size**  
A player's equipped Army contains exactly four Army cards. All four slots must be filled before the match can begin.

**R003 — Unique Army cards**  
The same Army card cannot occupy more than one loadout slot.

**R004 — Mixed elements**  
The four Army cards may be mixed freely across Fire, Water, Earth and Slime regardless of the Commander's element.

**R005 — Commander theme activation**  
A Commander references a themed set. The Commander bonus activates when all four equipped cards belong to that set theme.

**R006 — Theme pools can grow**  
A Commander theme may contain more than four available cards. Any four unique cards belonging to that theme satisfy the four-card activation rule.

**R007 — In-match card pool**  
Only the four Army cards selected before the match can appear as Army choices during that match.

**R008 — Starter elements**  
The starter roster is Fire, Water and Earth.

**R009 — Initial opponent**  
The first playable target is player-versus-AI, not online PvP.

**R010 — Set bonuses**  
The starter full-theme bonuses are Fire +10% ATK, Water +10% DEF and Earth +10% Max HP. They persist for the match and stack multiplicatively with Buff Cards.

## Draft rules

**R011 — Random offer**  
Each draft selection shows three randomized choices.

**R012 — Unit caps**  
Every Army card defines a summon amount and a maximum unit count for the match army. Selecting the card adds its summon amount up to the cap.

**R013 — Unit exhaustion**  
When a unit type reaches its cap, that Army card permanently leaves that player's draft pool for the rest of the match.

**R014 — Buff cards**  
Buff Cards are part of the normal draft pool from Round 2 onward. Starter buffs are +15% ATK, +25% HP, +20% Attack Speed, +25% DEF and +30% Movement Speed.

**R015 — Army-wide persistent buffs**  
A selected Buff Card affects the entire army, including units summoned in later rounds, and persists for the match.

**R016 — Buff offer limit**  
While at least one Army card is still eligible, a three-card offer contains at most two Buff Cards and therefore always includes an Army choice.

**R017 — Opening draft**  
All three selections before Battle 1 are guaranteed Army-card choices. Buff Cards do not appear in the opening pre-battle phase.

**R018 — Selection points**  
A normal pre-battle phase gives three selections. The side that lost the previous battle gets four selections in its next pre-battle phase.

**R019 — Reroll cadence**  
After every selection, all three displayed choices are randomized again. There is no manual reroll in the default rules; R113 defines a separately opted-in local experiment.

**R020 — Buff stacking**  
The same Buff Card may be selected any number of times per match. Identical and different buffs stack multiplicatively. Existing Attack Speed and Movement Speed caps still apply.

**R021 — Unlimited power cards**  
Buff Cards do not exhaust and stay in the draft pool regardless of stack count.

**R022 — One Army card remaining**  
If exactly one Army card remains eligible, every offer must include it plus up to two Buff Cards.

**R023 — All Army cards exhausted**  
Once all four Army cards are exhausted, offers may contain three Buff Cards.

**R024 — No legal cards remaining**  
A phase ends early only if no legal choice exists. With the standard unlimited Buff pool, non-opening phases always have legal power-card choices, including repeated Sudden Death rounds.

**R025 — Selection timer**  
Each individual selection has a 30-second timer. The timer resets after every selection. Local pause, help and settings menus suspend the selection clock until the player returns.

**R026 — Timeout**  
If time expires, one of the three displayed cards is selected at random. Commander skills are never auto-selected.

**R027 — No skipping**  
Selection points must be spent unless no legal card choices remain.

**R028 — Draft information**  
Buff Cards display effect and stack count. Local PvAI offers also show how many currently recruited units gain a stat increase; tooltips show per-type before/after values using the exact combat calculation, including theme bonuses, rounding and speed caps. No-gain cards remain legal and permanent buffs also affect future recruits. Army cards display summon gain and current/capped unit count.

**R029 — Current army summary**  
The player's full current army composition, active Buff stacks, Commander skill uses remaining and round-loss count are visible during drafting.

**R030 — Opponent information**  
The opponent's Commander, existing army composition, Buff stacks, Commander skill uses, round losses, set-bonus status and exact set-bonus effect are visible. Only the opponent's current pre-battle selections are hidden until combat begins.

## Commander active skills

**R031 — Skill cost and limit**  
Each Commander has one active skill. Using it costs one selection point. A skill can be used at most twice per match and at most once per pre-battle phase.

**R032 — Round 1 availability**  
Commander skills may be selected during the opening pre-battle phase even though the random card offer is Army-only.

**R033 — Skill timing**  
Selected Commander skills resolve immediately before combat begins. If both sides selected a skill, both resolve simultaneously.
The replay holds both armies and the battle clock at zero until all selected Commander skill animations finish; normal battle movement and attacks start afterward.

**R034 — Fire: Meteor Barrage**  
Fire summons six meteors. Each meteor directly targets an enemy unit. Meteors spread across different targets before cycling back through targets when fewer than six enemies exist.

**R035 — Meteor damage**  
A direct meteor hit has base damage equal to 20% of that target's own Max HP. Enemies caught in the AoE take base damage equal to 10% of their own Max HP. Normal DEF then reduces the damage, with the normal minimum-damage floor.

**R036 — Water: Frozen Field**  
For that battle round only, the enemy army suffers -20% Attack Speed and -15% Movement Speed. Units entering later in that same battle are also affected. Frozen scenery covers the entire battlefield for the full round; status markers identify the affected enemy army.

**R037 — Earth: Plant Summon**  
Earth summons six stationary plants at random valid positions on the enemy field for that battle round only. Plants stay on their casting Commander’s team regardless of where they spawn. They target and damage enemies only, never the caster’s army or other allied plants, and count as normal allied units for round resolution.

**R038 — Earth plant attack**  
Plants target the nearest enemy in range and fire one seed every 1.5 seconds. Each seed has base damage equal to 8% of the target's Max HP, then normal DEF applies.

**R039 — Earth plant durability**  
Plants have their own HP and DEF, can be targeted normally, use ordinary targeting rules, and disappear after the round.

## Persistent army and round reset

**R040 — Drafted army persists**  
Units accumulated through drafting become the player's army composition for the match.

**R041 — Full round reset**  
Every battle starts from a fresh battlefield. All accumulated units respawn at full HP; deaths and remaining HP from the previous battle do not carry over.

**R042 — Match progression persists**  
Army unit counts, Buff stacks, Commander skill uses spent and round losses persist between rounds.

## Formation and movement

**R043 — Battlefield orientation**  
The desktop battlefield starts as an open left-versus-right 2D field. Temporary ability-created crack barriers may block movement during combat. Decorative trees are outside the rendered playable ground. The player starts on the left and the opponent on the right.

**R044 — Full-field camera**  
The entire battlefield remains visible throughout combat; combat does not require camera panning or dynamic zoom.

**R045 — Free movement**  
Units move continuously rather than on a grid. Diagonal movement and natural pathing around other units are allowed.

**R046 — Collision**  
All allied and enemy units have physical collision and cannot pass through one another.

**R047 — Automatic formation**  
Starting formation is automatic. Tanks occupy the front-most positions, then other melee units, with ranged/backline units behind.
Both sides use the same deterministic tactical planner after drafting is complete and the battle rosters are revealed, before Commander skills resolve. It allocates multiple spaced ranks based on army size, places shorter-range attackers ahead of longer-range casters, and seeks central covered positions where healers can reach frontline allies. Melee wings and contact abilities receive positions suited to approaching combat. Enemy area damage encourages wider spacing; enemy melee pressure increases the value of protecting support and ranged units. Input card order does not determine top/bottom groups. Placement respects the field bounds and physical separation; units then follow the normal free movement and targeting rules.
These are heuristic tactical choices, not a guarantee of the best possible formation or a battle win. Numeric spacing and scoring weights are provisional playtest tuning.

**R048 — Ranged spacing**  
Ranged units try to maintain distance from their target. They stop briefly to attack, then resume repositioning if necessary.

**R049 — Pixel movement response**  
Movement changes are immediate with no acceleration or turning-inertia simulation. Movement Speed controls travel speed.

## Targeting and attacks

**R050 — Melee targeting**  
Standard melee units target the nearest valid enemy.

**R051 — Tank targeting**  
Tanks prioritize enemy Tanks/frontline targets, then fall back to the nearest valid enemy.

**R052 — Ranged targeting**  
Ranged units target the nearest valid enemy.

**R053 — Target lock**  
A unit stays locked to its current target until that target dies or becomes invalid/unreachable. It does not switch merely because another enemy becomes closer.

**R054 — Retargeting**  
When a target dies, units immediately acquire the next valid target according to their targeting rule. If the current target becomes unreachable, they retarget the nearest reachable valid enemy.

**R055 — Melee range requirement**  
Melee units must physically reach their own attack range. They cannot attack through an allied frontline.

**R056 — Projectile collision**  
Ranged projectiles pass through allied units but stop at the first enemy hit unless a specific ability explicitly pierces or deals AoE.

**R057 — Ranged hit commitment**  
Once fired at a valid locked target, a ranged attack is guaranteed to hit if that target is still alive when it resolves. If the target dies while the projectile is travelling, that projectile disappears.

**R058 — Melee hit commitment**  
Once a melee attack begins against a valid target in range, the attack is guaranteed to hit even if the target moves during the attack animation.

**R059 — No crit/dodge**  
The base combat system has no critical-hit, dodge, evasion or random miss mechanics.

**R060 — No elemental counter triangle**  
Elements do not intrinsically deal bonus or reduced damage to each other. Fire, Water, Earth and Slime define identity, themes and abilities.

## Stats and damage

**R061 — Normal attack damage**  
Normal unit damage is `max(1, ATK - DEF)`.

**R062 — Buff calculation order**  
Buffs modify raw unit stats before combat calculations.

**R063 — Multiplicative stacking**  
Repeated percentage buffs multiply the already-modified value rather than adding percentage points.

**R064 — Rounding**  
Final modified combat stats use normal rounding to whole numbers.

**R065 — Speed ratings**  
Attack Speed and Movement Speed are whole-number ratings. Attack Speed 100 equals one attack per second and uses `attack_interval = 100 / attack_speed`.

**R066 — Speed caps**  
Attack Speed and Movement Speed are each capped at 200.

**R067 — Uncapped core stats**  
HP, ATK and DEF have no ordinary gameplay cap. Calculations use finite floating-point values; at impractical thousands-of-picks scales, modified base stats saturate at 1e100 solely to avoid numeric overflow. This does not exhaust or reject Buff picks.

**R068 — Minimum damage**  
DEF may reduce a valid damaging hit to 1 damage but never to zero or below. R091 absorption then reduces the damage reaching HP and can produce fractional damage below 1.

## Unit abilities and starter roster

**R069 — Unit abilities**  
Army units may have passive or active combat abilities. A unit's data definition describes its ability; generic systems must not hardcode a specific unit ID.

**R070 — Fire starter roster**  
Magma Golem is 1/3 Tank with Burning Aura. Fire Imp is 3/9 Melee with an on-death pushback/burn explosion. Sorcerer is 2/6 Range with AoE Fireballs. Dragon is 1/2 Range with large-area damage-over-time Dragonfire.

**R071 — Water starter roster**  
Ice Giant is 2/6 Tank with a local Attack Speed slow aura. Sea Serpent is 2/6 Range with basic water shots. Penguins are 1/3 Healer with Healing Puddle. Water Wizard is 2/4 Range with pushback attacks.

**R072 — Earth starter roster**  
Giant Tree is 1/3 Tank with a large healing aura. Pitcher Plant is 2/4 Range with Vine Pull into melee damage. Bear is 2/6 Melee with every third attack empowered. Wood Archers are 2/4 long-range basic attackers.

**R073 — Provisional balance values**  
The exact starter numeric stats and ability tuning in `data/` are approved as the initial playtest baseline, but may be rebalanced after simulation/playtesting without changing the conceptual unit roles above.

## Battle and match resolution

**R074 — Round timer**  
A battle round lasts at most 120 seconds.

**R075 — Immediate victory**  
The round ends immediately when one side has no surviving units, after resolving death abilities, death-created units and revival from that simulation step. Lingering areas do not count as surviving units.

**R076 — Draw**  
If both sides lose their last surviving unit simultaneously, or the timer expires while both still have surviving units, the round is a draw.

**R077 — Draw consequence**  
A draw counts as a round loss for both sides.

**R078 — Match loss**  
A player loses the match upon reaching four round losses unless both players reach their fourth loss from the same drawn round.

**R079 — Sudden death trigger**  
If both sides reach four losses together, the match enters Sudden Death rather than ending as a draw.

**R080 — Sudden death draft**  
Before every Sudden Death battle, both sides receive three selections. The loser-comeback fourth selection does not apply.

**R081 — Sudden death repeat**  
If a Sudden Death battle is also a draw, another three-selection Sudden Death round begins. Repeat until one side wins outright.

## Presentation baseline

**R082 — Movement animation**  
Pixel units use eight-direction movement animations.

**R083 — Attack animation**  
Attack animations may use four directions and face toward the target rather than requiring eight unique attack directions.

**R084 — Idle and death**  
Each unit uses one neutral idle animation and one neutral death animation.

## Starter balance values

The starter data files are the authoritative initial playtest values for HP, ATK, DEF, Attack Speed, Movement Speed, range, summon amount/cap and ability parameters.

These values are deliberately provisional for balance tuning. A balance-only change should preserve the locked mechanics unless a gameplay rule is intentionally changed here.

## Slime Court expansion

**R085 — Slime Princess and army**
Slime Princess adds the Slime theme. Giant Slime is 1/4 Tank, Slime Cannon 2/4 Range, Slime Ball 2/6 Melee and Slime Barrel 2/6 Melee. These fractions are recruit amount/unit cap.

**R086 — Giant Slime split**
On death, Giant Slime creates two smaller allied versions with half the parent's Max HP and attack, before applying a death-spawn set bonus. Children start at full child HP, cannot split and do not inherit revival. Each Giant splits only once across its original body and revived body. Children have the parent's other combat stats and round-wide modifiers and count toward round survival.

**R087 — Slime Cannon**
Slime Cannon shoots a slime projectile that damages the enemy hit and reduces enemy Attack Speed and Movement Speed in a small impact radius. Repeated splashes refresh the same slow rather than stacking; the strongest temporary speed slow applies, multiplicatively with round-wide modifiers. Cannon slow percentages and duration are provisional tuning in its definition.

**R088 — Slime Barrel**
On death, Slime Barrel immediately explodes against enemies in a large radius and leaves a damaging area at that location for ten seconds. Enemies take damage while inside the area; allies never take explosion or area damage. The source's death does not cancel the area. Normal DEF applies. A battle still ends under R075; lingering pools do not postpone elimination. Damage amounts and tick interval are provisional tuning.

**R089 — Slime theme bonus**
Equipping four unique Slime Court cards with Slime Princess activates A Fresh Beginning. Each ally created or revived after a death receives +100% of its spawn attack. This bonus affects that new body only, after inherited stats, child scaling and persistent Buffs; it does not increase surviving allies' attack or ordinary round-start spawns. Each qualifying birth applies the multiplier once.

**R090 — Slime Princess: Royal Jelly**
Selected before battle under normal Commander skill cost/use/timing rules, Royal Jelly blesses each starting drafted ally with one revival at 50% of its own Max HP. The blessing resolves simultaneously with opposing skills, before any pre-battle damage. Revival creates a new allied body, preserves its combat stats/ability and round-wide modifiers, clears temporary statuses and triggers the active death-spawn bonus. Death abilities resolve when the original body falls; the Giant's once-only split remains spent after revival. Newly created summons do not inherit the blessing. Revival and children are temporary to that round and never change drafted unit counts or caps.

**R091 — Slime Ball: Jelly Burst**
Slime Ball keeps regular melee attacks and absorbs 30% of every valid incoming damaging hit after normal DEF/minimum damage calculation, including projectiles, Commander skills, auras, pools, damage over time and death explosions. The prevented damage is stored separately from HP; fractional amounts accumulate without per-hit rounding. Healing does not consume the stored amount. Allies cannot damage it or grant charge.

Every ten seconds of its current body's lifetime, it releases the entire stored amount against each living enemy in a medium radius, gives those enemies outward pushback, and resets its stored amount. The periodic burst does not kill or replace the Slime Ball. An empty cycle advances the timer without damage or pushback. Bursts expend their charge even if no enemy is in range. Stored damage is already post-defense: releasing it does not deduct DEF again, apply an attack multiplier or impose another minimum-damage floor; a target's own absorption can still reduce/store it. Radius and pushback distance use the existing balance definitions and collision/field limits.

If Slime Ball dies with stored damage, it releases double the stored amount at its death position with the same radius and enemy-only pushback, once, as part of death resolution before round elimination. The lethal hit contributes its absorbed portion. All hits in the same damage batch resolve before deaths; lethal damage on a periodic deadline produces the doubled death burst instead of a periodic burst from that body. Royal Jelly revives it with empty storage and a new ten-second timer, retaining the normal death-spawn attack bonus for regular attacks. A new round always starts empty.

## Personal Commander mastery

**R092 — Per-Commander personal record**
Each Commander has a separate local PvAI record keyed by stable Commander ID: full matches played, wins, losses, forfeits and mastery XP. A match is tracked when its first battle begins; leaving the opening draft before that point has no record or reward. Every full match settles once. Individual round wins, draws and Sudden Death rounds never grant separate mastery rewards. Match win rate is wins / (wins + losses); forfeits are included in losses. An empty record has no established win rate.

**R093 — Permanent mastery**
A completed match win grants 100 mastery XP; a completed match loss grants 25 XP. A forfeit grants 0 XP. Commanders start at Level 1 with 0 XP and gain one level per 250 XP. Levels and XP never decrease. A better win ratio earns more XP at equal match count. The initial level interval is content-defined playtest tuning. Mastery levels grant no combat stat or unit-cap multipliers. R099–R101 define achievements, four starter cards per Commander and permanent collection rewards.

**R094 — Forfeit and persistence**
Explicitly leaving or replacing an unfinished match after its first battle begins records one forfeit loss for the Commander who began it. Restarting or refreshing a recoverable local match does not forfeit: **Continue adventure** restores both drafts, random state, current selection time, hearts and skill budgets. An unwatched battle restarts the identical replay at 1×; a previously watched result may reopen its report. New adventure asks before abandoning a saved unfinished match. Legacy pending matches without a checkpoint retain the old one-forfeit recovery policy. Invalid/incompatible checkpoints show a notice rather than silently discarding records.

An already completed match retains its resolved win/loss and reward, including when leaving its final battle replay. Rewards are settled by authoritative match state, with presentation revealing them only after the final replay finishes. Reopening/replaying a result never grants XP again. Persisted last-settlement identity makes recovery idempotent across profile/checkpoint write interruptions.

Records persist on the current device/browser through a versioned local profile and backup. Save/load failures are visible and preserve session play; unreadable profile files are not overwritten with empty defaults. Automated test/capture scripts use isolated or in-memory profiles. Account sync, online competitive ratings and shared leaderboards are outside this personal PvAI system.

## Unranked friend-room playtest

**R095 — Private online matches**
Two players use a room invitation code and their own Commander/four-card loadout. The server validates content, legal hidden selections, timers, skill budgets, combat and scoring. Existing draft/combat/heart/comeback/Sudden Death rules apply. Current rival picks remain hidden until both drafts finish. Friend playtest outcomes do not alter personal PvAI records, mastery or competitive rank.

**R096 — Shared battle clock**
Both players watch shared 1× playback without individual pause, speed or result-skip controls. After both have received the replay, the server schedules its start. Commander skill animations finish before combat time advances; results are scored/revealed after the full shared battle and contact tail. Opening settings/help does not pause an online draft or battle. After a nonfinal result, both players continue before a new draft starts. The local PvAI pause/playback rules are unchanged.

**R097 — Online reconnect and forfeit**
In a started two-player match, a disconnected player has sixty seconds to reconnect to their reserved seat using their private session. The server clock and legal timeout selections continue. At expiry that player forfeits and the other side wins; if both seats expire at exactly the same time, the abandoned match cancels without a winner/reward. A completed final battle retains its result when it finishes before a disconnect deadline. Reconnect restores the current phase and shared playback time. A free-host restart or room resource expiry cancels the session without awarding a fabricated match result. These unranked outcomes never grant local mastery or rating.

## Achievements and mastery rewards

**R098 — PvP availability**
Friend PvP is paused and presented as **Coming Soon**. Ordinary players cannot create, join or reconnect through the game, including with a server URL override. The implementation remains for a later compatible release. Developer integration fixtures explicitly enable it in memory.

**R099 — Achievement progression**
Local achievements use settled complete-match records. Forfeits count in the existing loss record but do not count as completed matches for achievements. Match wins and permanent Commander levels contribute to the data-defined milestones. Achievements are granted automatically, once, remain earned, and grant recognition without extra XP, currencies or combat stat bonuses. They appear in the Achievements & Rewards journal. Existing qualifying records receive earned achievements when the profile is loaded.

**R100 — Mastery collection rewards**
Each Commander starts with four Army cards and has two automatic, permanent rewards. The first requires **Level 3 (500 XP) AND three wins** with that Commander. The second requires **Level 5 (1000 XP) AND six wins**. Neither level nor wins alone is sufficient. A reward is not auto-equipped and can be used in any Commander's mixed warband. Any four unique matching theme cards still satisfy R005/R006; a warband always has four slots. The PvAI opponent chooses from the same currently available collection. Locked cards remain previewable but cannot be equipped, loaded via a preset or used to start a match.

Valid existing schema-1/2 profiles permanently retain every previously ordinary card, including cards used in saved warbands, and all earned entitlements. Migration preserves XP, records and pending-match identity; it never fabricates wins. Fresh profiles use the new starter lineup. Qualifying records backfill rewards on load.

**R101 — Starter and mastery roster**

| Commander | Starting cards | Level 3 + 3 wins | Level 5 + 6 wins |
| --- | --- | --- | --- |
| Fire | Magma Golem, Fire Imp, Sorcerer, Ash Phoenix | Spriggan | Dragon |
| Water | Ice Giant, Sea Serpent, Penguins, Tidal Guard | Water Wizard | Nymph |
| Earth | Giant Tree, Bear, Wood Archers, Spore Sage | Pitcher Plant | Mole |
| Slime | Giant Slime, Slime Cannon, Slime Ball, Jelly Medic | Slime Barrel | Sticky Slime |

Spore Sage recruits two per pick with a cap of four; its HP, attack and splash ability are unchanged. Ash Phoenix, Tidal Guard, Spore Sage and Jelly Medic retain their ordinary healing, empowered attack and splash mechanics. Mastery changes availability, never unit combat stats or unit caps.


## Backline specialists

**R102 — Backline specialist roster**
Spriggan (Fire), Nymph (Water), Mole (Earth) and Sticky Slime (Slime) each recruit two units per pick with a cap of four. The first three are Melee assassins; Sticky Slime is Range support. Their mastery requirements are listed in R101; existing ownership is retained under R100. Four unique equipped cards remain the army limit.

**R103 — Backline transit**
Spriggan and Nymph cast once every five seconds, beginning when combat starts. They select the deepest living enemy backline unit (Range/Healer preferred, then other roles), travel rapidly across the field and materialize in a free position beside it. Both are invulnerable only during transit. They do not attack during transit and ignore surface collision; other units do not collide with their travelling form. Cooldown runs from cast start. Damage from every source, including shared damage and damage over time, respects this immunity. The transit endpoint is committed at cast time; it does not chase moving targets indefinitely. A new cast selects the current enemy backline again.

**R104 — Spriggan flame trail**
Spriggan's fireball leaves a continuous burning path. Enemies within its width take damage over time; allies never take trail damage. Each enemy takes at most one pulse per cast per tick regardless of overlapping trail segments. The trail can persist after its caster dies, but it does not count as a surviving unit. Initial tuning: 0.8-second transit, four-second trail from its first segment, 0.7-unit radius and 35% ATK every 0.5 seconds, subject to normal DEF.

**R105 — Nymph gush**
Nymph's moving water damages and pushes enemies in or near its swept path, once per enemy per cast. Allies are unaffected; enemy transit immunity is respected. Pushback respects field, actor collision and active crack barriers. Initial tuning: 0.8-second transit, 1.3-unit contact radius, 80% ATK damage and moderate pushback. This interprets the requested gush damage as damage received by contacted enemies.

**R106 — Mole tunnels and cracks**
Mole tunnels to the enemy backline using the same target/landing policy and leaves a crack segment along its tunnel on emergence. A crack lasts five seconds and blocks BOTH armies' ordinary movement and forced displacement. Units route around finite endpoints; melee attacks cannot cross a crack. Projectiles and ability transit can cross it. A crack rising under a unit displaces it to a free shoulder when possible; it grants no damage or friendly fire. Cracks expire even if the Mole dies and never count as survivors. Mole ignores surface collision while travelling but receives damage normally; its request does not grant immunity. Initial tuning: five-second tunnel cooldown, one-second tunnel, every third ordinary strike deals 180% ATK before DEF. Existing Bear/Tidal Guard third-strike numbers remain unchanged.

**R107 — Sticky damage links**
Every five seconds, while an enemy is in normal attack range, Sticky Slime marks that enemy and up to one additional enemy in range and near the first. Marks last five seconds. A single marked enemy has no partner to share with. Any allied damaging source hitting one of a pair also deals 50% of the actual HP damage (after DEF and absorption, excluding overkill) to the other. The original hit is not reduced. Copied damage is already post-defense, can be absorbed, respects invulnerability and never triggers another share. Duplicate marks do not multiply the copy to the same partner; distinct partner pairs can coexist. Marks retain their caster's allegiance and expire on time, including after caster death. Defeated/revived bodies do not inherit old marks. Initial tuning: normal range 5 and partner radius 3.5 units.


**R108 — Personal developer collection access**
The developer may activate a privately supplied access key in Settings → Developer access. This enables all current collection cards on that device without granting XP, match wins, levels, achievements or permanent card entitlements. Mastery continues to earn rewards normally, and the journal distinguishes developer access from earned rewards. Ordinary players receive no access by default; an invalid key or an unverified local flag cannot enable it. The key is not published in the source or build. Activation/removal is unavailable during a match; removing it revalidates the equipped army and retains actual earned cards. PvP remains Coming Soon. This device-local testing credential is not account authentication or trusted competitive authorization.

## Battle feedback and learning

**R109 — Battle report**
After complete battle playback, players may inspect a two-sided report grouped by unit type. Damage counts actual HP removed, excluding overkill; healing counts positive HP restored, excluding overheal. Absorption counts recorded damage prevented/stored by an absorption ability, independently of DEF. Kills credit the last damaging source only when that body actually dies. Death-spawned and revived bodies group with their card, while Commander skill damage and summoned units remain identifiable. Survival counts living bodies and their actual lifetimes. Damage, healing and protection have separate highlights; there is no score that treats raw damage as every role's value. Reports never change outcomes or grant rewards, and cannot expose a result before replay completion.

The report's short recap separates recorded observations from optional next-draft suggestions. Frontline loss is assessed after all births/deaths at the same simulation time, so a simultaneous split or revival is not a false collapse. Backline-transit assassins and temporary Commander plants are not treated as an opening frontline. Damage-share facts use effective HP loss, and absence of evidence creates no invented explanation. Suggestions are choices to test, not a causal verdict or guaranteed counter.

**R110 — Unit inspection**
Selecting a visible unit during local battle playback opens its current HP, modified stats, ability/cooldown and active effects beside the arena. The whole field remains visible. Inspection reads the displayed replay time only and never controls movement, targeting or combat. Unit ownership/effect word labels remain off battlefield actors.

Drafting and combat share a centered round/time and Commander/hearts strip, with four-card recruited/cap rosters outside playable ground. Draft choices occupy the center while both public rosters, theme effects, skill budgets and power stacks remain readable. Combat's army-health balance bar totals current visible living HP, including summoned/death-created bodies; it predicts no result and reveals no future damage. During drafting the bar is neutral and labelled as unrevealed until battle. The rival's current selections remain hidden under R030.

**R111 — Optional guided first match**
Players may start guidance from How to Play. It teaches actual Commander selection, four-card army setup, legal drafting and optional skill selection, normal pre-battle/battle playback, inspection and the report. Short reading panels pause local clocks and restore the prior pause state. Guidance may be ended at any time. The match uses normal rules, records, XP and forfeit behavior; completing guidance creates no extra reward. Only tutorial completion is saved as a separate local preference. Guidance is not available in friend PvP.

**R112 — PvAI styles and difficulty**
Local opponents use seeded Swarm, Sustain, Burst or Backline pressure plans when assembling and growing a legal four-card army. Settings selects Casual, Standard or Veteran before the next adventure; the active choice is retained on recovery. All difficulties use the same collection, card stats, pick budgets and skill limits. Casual makes less consistent draft decisions; Standard and Veteran weight counters to the player's previous public army, with Veteran using more consistent priorities. Neither sees current hidden picks or future combat results. The rival roster identifies its plan and difficulty. These are heuristic policies, not guarantees that one difficulty always wins a particular seed.

**R113 — Optional redraw experiment**
Off by default, Settings may enable the local PvAI redraw experiment for the next adventure. Both sides may redraw the full offer once per round, including opening and Sudden Death rounds. A redraw costs no selection, grants no selection, does not reset the current pick timer and may repeat cards. Normal opening/unit-cap/buff-offer rules still apply. The allowance refreshes only at the next round, not after a pick or restart. Both drafts and the experiment choice are retained on recovery. It never changes friend-room rules.

**R114 — Local pacing evidence**
Adventure insights keeps bounded, device-local observations for the latest 30 played PvAI adventures: round counts, draft time while actively choosing, simulated battle duration at 1×, actual viewing time, drawn/time-limit/Sudden Death rounds, difficulty and redraw participation. Reading while paused is excluded. Reopening a scored round does not add another observation. Default and experiment samples remain distinguishable; these observations never grant rewards, change difficulty automatically or alter the existing overtime rules.

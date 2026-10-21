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
After every selection, all three displayed choices are randomized again. There is no manual reroll.

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
Buff Cards display effect and stack count. Army cards display summon gain and current/capped unit count.

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
The desktop battlefield is a completely open left-versus-right 2D field. The player starts on the left and the opponent on the right.

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
HP, ATK and DEF have no hard cap beyond content/buff rules.

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
A completed match win grants 100 mastery XP; a completed match loss grants 25 XP. A forfeit grants 0 XP. Commanders start at Level 1 with 0 XP and gain one level per 250 XP. Levels and XP never decrease. A better win ratio earns more XP at equal match count. The initial level interval is content-defined playtest tuning. Mastery levels grant no combat stat or unit-cap multipliers. R099–R101 add achievements and permanent collection rewards; the sixteen original cards remain available from the start.

**R094 — Forfeit and persistence**
Leaving or replacing an unfinished match after its first battle begins records one forfeit loss for the Commander who began it. A persisted unfinished match recovered after restarting the game also settles once as a forfeit. An already completed match retains its resolved win/loss and reward, including when leaving its final battle replay. Rewards are settled by authoritative match state, with presentation revealing them only after the final replay finishes. Reopening/replaying a result never grants XP again.

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
All sixteen original Army cards remain available from the start. The first reward for each Commander requires both permanent Level 3 (500 XP) and three wins with that Commander. The reward unlocks automatically and permanently, is not auto-equipped, and may then be used in any Commander's mixed warband. Any four unique cards of a theme still satisfy R005/R006; a warband always has exactly four slots. The PvAI opponent chooses from the same currently available collection as the player. Locked cards are visible for preview but cannot be equipped, loaded via a preset or used to start a match. Existing qualifying records receive the unlock on load; levels, wins and XP are preserved.

**R101 — Initial mastery reward roster**
Fire unlocks **Ash Phoenix**, a 1/2 Healer placing a small four-second healing sanctuary. Water unlocks **Tidal Guard**, a 2/4 Melee unit whose third attack is empowered. Earth unlocks **Spore Sage**, a 1/3 Range unit firing small-area splash projectiles. Slime unlocks **Jelly Medic**, a 1/3 Healer placing a medium four-second healing pool. These use the existing generic area-heal, empowered-attack and ranged-AoE mechanics; they obey ordinary collision, targeting, defense and death/revival rules. New numbers in data are initial playtest tuning, not guarantees of final balance. Rewards add tactical choices without modifying existing unit stats.

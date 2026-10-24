# Lv. 2 unit artwork

Original project artwork generated with the built-in image-generation tool on 2026-10-24, using the existing project-owned `roster-v5.png` as the identity/style reference. No paid external service or third-party character artwork was added.

The final game asset is `roster-upgrades-v1.png`: twenty-four 64×64 cells in six columns/four rows, ordered by Fire, Water, Earth and Slime, then stable unit number. `tools/pack_upgrade_art.gd` extracts the generated complete sprite silhouettes and scales them with nearest-neighbor sampling. Existing base-unit atlas pixels are unchanged. The upgraded atlas is consumed by card portraits, public rosters and current replay actors, including death and revival.

All generation/edit prompts are preserved below. Later passes improve transparent isolation and spacing. Source character designs remain separate from simulation rules and tuning.

## Initial prompt

```text
Use case: identity-preserve. Asset type: one production pixel-art game sprite atlas for the permanent LEVEL TWO upgrades of VCommander.
Input image: edit/reference target is the existing roster atlas. Preserve every creature's identity, original elemental colors, cozy fantasy pixel style, dark brown outlines, three-quarter view and roughly original stance. Make each upgraded form clearly more developed through armor, ornament, anatomy or equipment, never merely a recolor.
Create a NEW atlas, 1536 x 1024, exactly SIX columns and FOUR rows, each cell 256 x 256. Exactly ONE centered complete character in each cell. All cells have a truly TRANSPARENT background, generous 32px transparent margins, no frames, shadows, labels, text, particles outside the silhouette, weapons crossing cell boundaries or scenery. Crisp deliberate pixel clusters, nearest-neighbor look, readable at 64x64. Same detail and finish as the reference, no blur or painterly rendering. Characters should face mostly right as in the reference; retain centered lower-body anchor suitable for animated mesh rigs.

ROW 1 FIRE, left to right:
1 Magma Golem: original dark volcanic boulder tank with richer bronze rock plating, tall ember-crystal shoulders and bright lava fissures.
2 Fire Imp: recognizable small orange fire demon with TWO fierce flaming clawed hands, bronze shoulder guards and forked flame crest.
3 Sorcerer: original crimson/bronze robed fire wizard with a grander carved staff, two contained fire orbs, richer dark red hood and gold trim.
4 Dragon: original stout red dragon with reinforced charcoal-red scales, gold-tipped flame crest and more ornate wings, one dragon head.
5 Ash Phoenix: recognizable orange-gold healing phoenix with longer sunburst plumage, ash-violet feather accents and elegant pale-gold chest crest.
6 Spriggan: original red-orange woodland fire assassin with ember antlers, layered charred-leaf mantle, fiery claws and long curled flame tail.

ROW 2 WATER:
1 Ice Giant: recognizable blue ice-boulder tank with larger jagged ice crystals and frosty silver shoulder plating.
2 Sea Serpent: one coiled teal sea-serpent body with EXACTLY TWO CLEAR DISTINCT SERPENT HEADS rising side by side from the body; matching jade scales, cream underside and gold fins. Two heads essential.
3 Penguins: ONE original black-white penguin healer, now an azure-silver hood and healing satchel, ornate icy staff and gentle blue feather crest.
4 Water Wizard: original slender blue water mage with grander sapphire robe, silver wave embroidery, crescent staff and contained water coil.
5 Tidal Guard: original blue-lavender armored sea warrior with stronger shell shield, silver shell armor and broad crescent weapon.
6 Nymph: original pale blue water spirit assassin with flowing turquoise wave hair, pearl ornaments, fin-like shoulder mantle and water ribbons close to body.

ROW 3 EARTH:
1 Giant Tree: original living broad oak tank with much larger golden-green canopy, heavy mossy bark, gnarled root feet and bronze-natural runes.
2 Pitcher Plant: original curling green pitcher creature with larger red-and-gold toothed pitcher lid, thick thorny grasping vines and root bracers.
3 Bear: original brown bear with heavy leaf-and-bark shoulder armor, powerful marked foreclaws and richer mane; remain a bear, not humanoid.
4 Wood Archers: ONE original woodland archer with moss-green hood, bronze leaf armor, upgraded longbow held ready and TWO arrows visibly nocked.
5 Spore Sage: original golden mushroom mage with layered golden-purple cap clusters, twisted staff, moss cape and contained spore beads.
6 Mole: original brown miner mole with brass-spiked digging gauntlets, reinforced mining helmet, cracked-stone shoulder plates and a compact pick.

ROW 4 SLIME PRINCESS:
1 Giant Slime: GREEN original large blob tank with a leafy golden crown, larger gel lobes and three tiny bright green gel cores visible inside.
2 Slime Cannon: GREEN original slime cannon creature with a reinforced brass-banded green barrel, two green ooze reservoirs and sturdier wooden/brass base.
3 Slime Ball: WHITE original rounded slime with pearl-white gel, pale lavender crystal fissures, small dark friendly face and clear bulging absorbent lobes. Must remain WHITE.
4 Slime Barrel: PINK original barrel slime with reinforced dark wooden hoops, pink crystal encrustation and thick dripping pink jelly.
5 Jelly Medic: original white-lavender jelly healer with pale botanical cap, lavender blossom mantle, medicine satchel and bright green potion orb.
6 Sticky Slime: original pink-lavender long-armed sticky slime with thicker raised adhesive arms, clear web-like threads close to its silhouette and a violet star-web crest.

Keep the reference's recognizable identities. Every upgraded unit must have visible new silhouette/equipment details. Uniform scale across cells except the intentionally broad tree/golem. No commanders, no extra units in a cell.
```

## Transparent-isolation pass

```text
Use case: background-extraction, precise-object-edit.
Edit target is the supplied 6-column by 4-row pixel fantasy unit atlas. Keep the EXACT 24 characters, pixel colors inside characters, poses, anatomy (especially the two-headed teal serpent), equipment, unit order, and pixel style. This is a production transparent sprite sheet, NOT an illustration.
REMOVE EVERY COLORED BACKGROUND RECTANGLE AND EVERY COLORED BACKGROUND HALO. Set all empty space around each character to actual alpha 0, including between limbs, wings, staffs and vines. No ambient glow or cast shadow outside a character silhouette. Only the character pixels should be visible against a neutral checkerboard. Fully opaque solid sprite interiors, crisp transparent edges. Do not preserve the colored red/blue/green/lavender backdrop or its gradients as translucent fog.
Preserve exactly six columns and four rows at 1536x1024. Fit each complete character inside the middle 200x200 pixels of its own 256x256 cell, with at least 24px truly transparent padding on every side. No sprite clipping, no cross-cell overlap, no text, no labels, no decorations or ground. The actual transparent channel must contain clean zero-alpha empty margins; never draw a checkerboard into the image. Preserve all original character design details.
```

## Final spacing pass and atlas extraction

```text
Use case: game-sprite-sheet, precise-object-edit. Re-layout the supplied 24-character transparent pixel fantasy upgrade atlas into a STRICT 6-column by 4-row grid at 1536 by 1024. Every cell is 256 by 256. Preserve these exact 24 designs, order and pixel fantasy style, including two heads on the teal serpent, white Slime Ball, green Slime Giant and Cannon, pink Barrel. CRITICAL PRODUCTION FIX: every complete character must fit within the central 192 by 192 square of its own cell (32-pixel zero-alpha margin on ALL FOUR SIDES). Shrink characters uniformly to accomplish this. Do not let wings, serpent heads, tails, leaves, weapons or slimes cross any cell boundary. The prior image has neighboring fragments crossing into the Penguin, Nymph, Slime Ball and Sorcerer cells; remove those fragments from the wrong cells and keep each complete character in its own cell. No detached decoration, no tiny fragments, no glow haze, no ground, no background panels, no letters, no text, no grid lines. Crisp opaque sprite interiors and transparent alpha-zero empty space. Keep all 24 figures visually distinct and recognizable: first row Fire (golem, imp, sorcerer, dragon, phoenix, spriggan), second Water (ice giant, two-headed serpent, penguin, wizard, shell guard, nymph), third Earth (tree, pitcher plant, armored bear, double-arrow archer, mushroom sage, mining mole), fourth Slime (green crowned giant, green brass cannon, white crystal ball, pink barrel, lavender medic, sticky pink-violet slime).
```

Native review found that source silhouettes still crossed nominal cell borders. `tools/pack_upgrade_art.gd` now extracts the 24 complete connected sprite silhouettes, preserving their pixels, then scales and centers each in its own 64×64 transparent game cell. This prevents a neighboring tail, wing or weapon fragment from appearing in another portrait. The normal roster atlas remains unchanged. Native comparisons cover all 24 original/Lv. 2 pairs, the forge, compact larger-text actions, four upgraded battles and inspection.

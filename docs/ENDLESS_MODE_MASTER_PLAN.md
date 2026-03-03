# Endless Roguelite Master Plan (2D Top-Down)

## 0. Current Implemented Baseline
- Single main mode: Endless (2D top-down).
- Wave loop: intermission -> combat -> card pick.
- Core skills: 360 sword sweep, dash, grenade, multi-bullet modes.
- Enemy archetypes: `Chaser`, `Shooter`, `Dasher`.
- Dynamic arena mutation each wave: obstacles + pulse hazards.
- 3-card random reward after each wave.

## 1. Core Vision
- Build a highly replayable FPS + movement roguelite with:
- Deep build diversity.
- Multi-layer combat pressure.
- Terrain-driven tactics.
- Deterministic fairness + controlled randomness.
- Long-term meta progression.

## 2. Final Target Pillars
- Combat Depth:
- 10+ enemy classes, 6+ elite modifiers, 5+ boss archetypes.
- Build System:
- 150+ cards, 12 weapon tags, 10 shield tags, synergy graph with breakpoints.
- Spatial Dynamics:
- Arena mutation every wave + periodic global events.
- Run Structure:
- 3 acts per run, 10 waves per act, boss gates, shops, risk events.
- Meta Layer:
- Persistent unlock tree, relic codex, challenge contracts.

## 3. Architecture Expansion Roadmap
- Data-driven configs:
- Move enemies/cards/events/wave tables to `*.tres` or JSON schemas.
- Runtime systems split:
- `WaveDirector`, `SpawnDirector`, `TerrainDirector`, `CardDirector`, `DifficultyDirector`, `RunState`.
- Event bus:
- Typed gameplay events (`enemy_killed`, `player_damaged`, `wave_started`, `card_picked`).
- Save model:
- Mid-run snapshot + meta-progression save.

## 4. Enemy Complexity Plan
- Add families:
- Rushers, artillery, area-denial, support, summoner, stealth, shield-breaker.
- Behavior layers:
- State machines + utility scoring + threat response.
- Squad logic:
- Role composition by wave budget (frontline/backline/control).
- Elite system:
- Prefix modifiers (`Haste`, `Reflect`, `Void`, `Regenerating`, `Explosive`).
- Boss framework:
- Phase transitions, scripted arena interactions, telegraphed punish windows.

## 5. Terrain Mutation Plan
- Geometry mutations:
- Rotating lanes, collapsing bridges, rising walls, temporary safe domes.
- Hazard grid:
- Heatmap-driven danger zones with telegraph phases.
- Traversal set:
- Jump pads, grapples, conveyor strips, anti-grav pockets.
- Mutation deck:
- Each wave rolls 1 primary + 1 secondary mutation from weighted pools.

## 6. Card/Economy Complexity Plan
- Card taxonomy:
- Offensive / Defensive / Mobility / Utility / Economy / Conversion.
- Rarity tiers:
- Common, Rare, Epic, Corrupted.
- Synergy engine:
- Tag stacks unlocking combo effects (e.g. `Arc + Overheat + Echo`).
- Economy:
- Shards from kills, reroll, lock card, purge card, upgrade card.
- Risk cards:
- Strong upside + permanent downside.

## 7. Difficulty Director
- Budget model:
- Wave budget scales by wave + player power score.
- Dynamic correction:
- If player is overperforming, increase flanker/control pressure.
- Rubber-band caps:
- Prevent unwinnable spikes.
- Mode variants:
- Normal, Hard, Nightmare, Endless Ascension.

## 8. Progression / Meta
- Unlock tracks:
- Enemy family unlocks, new card pools, new arena mutations.
- Persistent currencies:
- Core currency + challenge currency + boss currency.
- Account upgrades:
- Starting options, reroll token caps, new starter loadouts.
- Contracts:
- Run modifiers with score multipliers.

## 9. UX and Telemetry
- HUD expansion:
- Build tags, synergy indicators, wave threat meter, mutation feed.
- Death recap:
- Damage sources timeline + build suggestions.
- Replay seed:
- Shareable run seeds.
- Telemetry:
- Wave clear times, card pick rates, build win rates, enemy lethality heatmap.

## 10. Suggested Execution Phases
- Phase A (now -> short term):
- Stabilize endless baseline, add 3 more enemies, add elites, add 30 cards.
- Phase B:
- Introduce bosses + act structure + shop nodes.
- Phase C:
- Meta progression, save/load, challenge contracts.
- Phase D:
- Advanced AI utility, mutation deck system, full telemetry loop.
- Phase E:
- Balance pass, content scale-up, polish + VFX + audio layering.

## 11. Definition of Done (Full Product)
- 60 FPS stable in heavy wave scenarios.
- 45+ minutes average successful high-skill run.
- 30%+ build archetype viability.
- No dominant strategy > 60% win share.
- New player first clear feasible within 3-8 runs.

# 2D Rogue Endless - Deep Complexity Plan

## Goal
Build a long-term, high-complexity loop where each run differs at:
- Build path (player archetypes and branch exclusivity)
- Enemy ecosystem (roles, synergies, counterplay)
- Terrain ecology (theme + dynamic directives + hazard chains)
- Mid-wave pacing (event directives and phase shifts)

## Current Baseline (Already Implemented)
- Multi-bullet modes, magic set, and status interactions.
- Terrain themes + hazard types + wave mutators.
- Wave directives (surge, seismic, flux, beacon drop, hellburst).
- Enemy roster includes support and assault specialists.
- Enemy faction-role layer now active in combat (Legion/Arcane/Void/Storm + Frontline/Skirmisher/Support/Controller/Siege).

## Phase A: Enemy Ecology 2.0
### A1. Faction Layer
- Assign each enemy a faction tag: `Legion`, `Arcane`, `Void`, `Storm`.
- Faction bonuses:
  - Legion: pack armor when near same faction.
  - Arcane: skill cooldown reduction when casting chain.
  - Void: periodic blink reposition.
  - Storm: projectile speed scaling with nearby hazards.
- Counterplay:
  - Player can break faction links by killing anchor unit.

### A2. Role Synergy Graph
- Roles: `Frontline`, `Skirmisher`, `Support`, `Controller`, `Siege`.
- Runtime synergy effects:
  - Support buffs nearest 2 Frontline units.
  - Controller forces player movement with zoning.
  - Siege gains damage if player is in open lanes.
- UI hint:
  - Wave preview shows top 2 role clusters.
  - Status: implemented (preview now displays top faction + role clusters).

### A3. Mini-boss Kit Variants
- Replace single miniboss template with variant kits:
  - `Bulwark`: rotating shield sectors.
  - `Harrier`: rapid dash chains.
  - `Ritualist`: summon ritual circles requiring interruption.
- Each kit has 2 possible phase transitions at HP thresholds.

## Phase B: Terrain & Objective Complexity
### B1. Multi-Layer Terrain Events
- Add wave-level objective events:
  - `Pylon Capture`: disable pylon before overcharge.
  - `Convoy Fracture`: moving hazard train crosses arena.
  - `Rift Seal`: destroy rift nodes to stop elite spawns.
- Failure does not end run, but applies punitive modifiers.
- Status: partially implemented (`Pylon Capture` + `Rift Seal` runtime objective with success/fail branches).

### B2. Hazard Network
- Hazards become linked nodes:
  - Adjacent nodes can chain pulses.
  - Mixed element nodes trigger reactions (fire + storm => shockburn).
- Add decay and re-ignition states.

### B3. Mid-Wave Terrain Mutation
- Wave has 2 mutation checkpoints (time or kill-based).
- At mutation:
  - Layout opens/closes lanes.
  - Hazard types rotate.
  - Directive pool changes.

## Phase C: Buildcraft Meta Depth
### C1. Archetype Commitment
- Add archetype meter for 4 schools:
  - Blade, Ballistic, Arcane, Tactical.
- Picking cards fills meter; at threshold unlocks keystone cards.
- Keystone cards are strong but enforce tradeoffs.

### C2. Socketed Augments
- Cards can grant `socket` slots.
- Drop-style augments attach to bullet/spell/grenade nodes.
- Example:
  - `Overheat Lens`: +damage over time, +recoil spread.
  - `Phase Prism`: bullets split when crossing hazard edges.

### C3. Conditional Combo Cards
- Cards that activate only under state conditions:
  - During overdrive.
  - While shield is empty.
  - After 3 dashes in 6s.

## Phase D: Run-Level Systems
### D1. Threat Director
- Runtime evaluator reads:
  - DPS output
  - Damage intake
  - Position entropy
  - Hazard usage efficiency
- Dynamically adjusts:
  - Spawn rhythm
  - Directive intensity
  - Elite composition

### D2. World Afflictions
- Global run afflictions every N waves:
  - `Low Visibility`
  - `Mana Static`
  - `Rupture Tides`
- Player can pick one mitigation before next wave.

### D3. Meta Relics
- Outside-run relic unlocks with strict conditions.
- Relics alter run rules, not just stats.

## Delivery Strategy
1. Implement Phase A1+A2 first (highest combat depth per code cost). Status: mostly done (core combat + preview UI + anchor-counterplay done).
2. Then B1 (objective events) to diversify wave pacing.
3. Then C1 (archetype commitment) to lock build identity.
4. Add D1 director only after telemetry hooks are ready.

## Telemetry Hooks Needed
- Per-wave:
  - kill time distribution
  - hazard deaths
  - directive trigger outcome
- Per-build:
  - card pick order
  - archetype meter trajectory
  - damage source breakdown

## Balance Guardrails
- Any new high-complexity system must keep:
  - `wave clear median` within target band
  - `avoidable death ratio` above threshold
  - no single archetype >15% win-rate delta over others

# Final Fantasy VI-Style RPG Game Plan
## Solo Developer - Godot 4 - World Exploration Focus

---

## Executive Summary

Build a turn-based JRPG with FF6-inspired world exploration mechanics using Godot 4. Focus on overworld navigation, dungeon crawling, and party management for solo development scope.

### Current Prototype Milestone

The current playable prototype covers a village/forest adventure with two connected quests and inspectable clues, followed by an optional hunter contract with two mixed encounters. Forest Shade, Bramble Wolf, Ashwing, Thornback, and Cave Sentinel have distinct stats, weaknesses, or combat behaviors; mixed battles support choosing a target and let each living enemy act. The Ashwing drains MP with Cinder bolt, while the Thornback's Shell guard reduces the next hit. The slice also includes optional potion/gold/XP discoveries, a healing campfire, NPC dialogue, saved progression, and hero creation with a name, class, and rerollable class-based stats. Warrior, Mage, and Rogue have distinct combat advantages. The village trader sells potions and equipment; a character-and-bag menu supports comparing and equipping one item in each of seven slots (weapon, body, head, arms, hands, legs, and feet), selling items at the trader, and dropping unwanted items. Equipped stats affect battle damage and defense. Completing the main adventure unlocks an optional cave with a warding Cave Sentinel and a permanent one-time treasure reward. The exploration HUD keeps the current objective and survival stats visible without the detailed equipment list. A Map / Journal screen (M) shows the player's position, known landmarks and quest destinations, plus active, completed, and upcoming objectives. This is a vertical-slice milestone, not completion of the broader phases below.

**Current art/audio pass:** original pixel-style SVG art now covers the overworld tiles, hero classes, village NPCs and buildings, trees, and all current monsters. Original loopable chiptune themes distinguish the title menu, Greenvale, and battle, with effects for combat actions and victories. The title menu and in-game controls can mute all audio, and that preference persists between sessions. Interface art, character animation, and location ambience remain future polish.

**Recommended next step:** stabilize the legacy dungeon prototype before expanding its scope: it currently generates room metadata, but `set_tile()` does not render tiles and the dungeon scene does not constrain movement to generated corridors. Then playtest and balance the active Greenvale loop, and continue the art/audio polish before adding party or world scope.

### Current Implementation Status (November 2026)

| Area | Status |
|---|---|
| Title menu and save flow | Implemented: Continue, three-slot Load, New Game/hero creation, in-game Save/Load, and persistent audio mute preference |
| Greenvale adventure | Playable vertical slice: one continuous village/forest map, linked main quests, optional hunter contract, cave encounter/reward, NPCs, clues, and healing |
| Combat and progression | Implemented for one selected hero against single or mixed encounters, including class differences, enemy intent patterns, XP/levels, gold, equipment, and consumables |
| Inventory and shop | Implemented in the active slice: seven equipment slots, item comparison, equip/discard, and buying/selling at Rowan's shop |
| Map and journal | Implemented for the current Greenvale map and quest flow |
| Art and audio | First authored pass implemented: static SVG art, three music themes, combat effects, and global On/Off toggle; animation, authored UI art, ambience, and separate volume controls remain |
| Party-based RPG | Not implemented in the active game; the playable slice is single-hero, and the four-character party remains a design goal |
| Multi-zone world | Not implemented as a connected zone system; the cave is an area in the current Greenvale map |
| Procedural dungeon | Prototype only, not part of the active game loop; the generator's tile-writing method is empty and the legacy scene is not a complete rendered dungeon |
| Builds and platform validation | Not prepared; no export presets or mobile-control validation |

These are implementation-status notes, not completion claims for the broader design targets below. The legacy `core`, `systems`, and scene scripts are not automatically integrated into the active Greenvale slice.

---

## Original Core Design Targets

### Game Genre & Style
- **Genre**: Classic Turn-Based RPG (FF6 style)
- **Platform target**: PC-first, with mobile support as a later goal; mobile controls and platform builds are not implemented
- **Scope**: Solo developer - focused mechanics over content volume
- **Visual Style target**: Pixel art with a retro aesthetic

### Long-Term Feature Targets (Prioritized for Solo Dev)
1. **Overworld Exploration** - Grid-based movement between zones
2. **Turn-Based Combat** - Menu-driven battles with elemental system
3. **Party Management** - 4-character party (reduced from FF6's 6 for scope)
4. **Dungeon Crawling** - Procedurally generated rooms
5. **Progression System** - XP, leveling, equipment upgrades

### Out of Scope (Phase 2+)
- Full story narrative with cutscenes
- Voice acting
- Complex combo systems
- Multiplayer features

---

## Technical Architecture

### Engine & Tools
```
Engine: Godot 4.x
Language: GDScript
Export Targets: Windows, macOS, Linux, Android, iOS
```

### Project Structure
```
3d_game/
├── assets/
│   ├── art/              # Active slice SVG artwork
│   ├── audio/            # Active slice music and effects
│   ├── characters/       # Legacy import metadata
│   ├── environments/     # Legacy import metadata
│   └── ui/               # Legacy import metadata; active UI is mostly code-drawn
├── scenes/
│   ├── ui/main_menu.tscn # Application entry scene
│   ├── game.tscn         # Active Greenvale slice
│   ├── battle.tscn       # Active slice battle
│   ├── dungeons/         # Legacy dungeon prototype
│   ├── combat/           # Legacy combat scenes
│   └── autoloads/        # Shared/legacy system nodes
├── scripts/
│   ├── game/             # Active Greenvale and battle logic
│   ├── ui/               # Active title menu
│   ├── autoloads/        # Audio director and asset manager
│   ├── systems/          # Standalone system prototypes
│   ├── dungeons/         # Legacy dungeon scene
│   └── core/             # General RPG classes, not an active party system
├── tests/gameplay_smoke.gd
└── plans/                # Design documents
```

---

## Long-Term Implementation Phases

The phases below describe the original target architecture. Use the current-status table above to distinguish those goals from features already present in the playable slice; several older scripts are prototypes rather than integrated systems.

### Phase 1: Core Systems (Foundation)
**Goal**: Build reusable systems for all game features

**Current status**: Partial. The active slice has solo-hero class stats, turn-based combat, inventory/equipment, and JSON save/load. A reusable four-character party, complete elemental/status-effect system, and integrated shared core systems are not implemented.

#### Tasks:
- [ ] **Character System**
  - Character base class with stats (HP, MP, ATK, DEF, etc.)
  - 4 unique characters with distinct abilities
  - Equipment slots system
  
- [ ] **Party Management**
  - Party composition logic
  - Active/backup character switching
  - Status effects tracking

- [ ] **Combat System**
  - Turn-based battle engine
  - Action menu (Attack, Magic, Item, Guard)
  - Enemy AI with simple patterns
  - Damage calculation formulas
  
- [ ] **Save/Load System**
  - JSON serialization for game state
  - Auto-save on level completion

### Phase 2: Overworld Exploration
**Goal**: Create the main gameplay loop

**Current status**: Partial. The active game provides one continuous Greenvale village/forest map, NPC quests, clues, exploration rewards, and an optional cave area. Multiple connected zones, a world map transition system, and random step-based encounters are not implemented in the active slice.

#### Tasks:
- [ ] **Overworld Map**
  - Tile-based navigation system
  - Zone transition logic
  - Day/night cycle (optional)
  
- [ ] **Zone System**
  - 5-7 distinct zones (village, forest, cave, castle, etc.)
  - Zone-specific enemies and items
  - NPCs with simple dialogue
  
- [ ] **Event System**
  - Random encounters (10% chance per step)
  - NPC interactions
  - Item pickups

### Phase 3: Dungeon Generation
**Goal**: Create replayable dungeon content

**Current status**: Prototype only. The legacy generator produces room dictionaries, but `set_tile()` is a no-op, the dungeon scene does not render the generated layout, and player movement is only bounded by the rectangular grid rather than the generated corridors. This is not a playable dungeon.

#### Tasks:
- [ ] **Procedural Room Generator**
  - Corridor-based layout algorithm
  - Room types (combat, treasure, boss, exit)
  
- [ ] **Dungeon Scenes**
  - Individual room templates
  - Lighting and atmosphere effects
  
- [ ] **Boss System**
  - 3 unique bosses with multi-phase mechanics
  - Boss arena customization

### Phase 4: Content & Polish
**Goal**: Add content and refine gameplay

**Current status**: In progress. Original static SVG art and original music/effects are used by the active slice. Animation, authored UI assets, location ambience, and accessibility/volume-mix controls remain future work.

#### Tasks:
- [ ] **Content Creation**
  - Character sprites/models (4 characters)
  - Enemy designs (15-20 enemies)
  - UI assets (menus, buttons, icons)
  
- [ ] **Audio Implementation**
  - Battle BGM tracks
  - Zone-specific music
  - Sound effects for actions
  
- [ ] **UI Polish**
  - Menu animations
  - HUD elements
  - Accessibility options

### Phase 5: Testing & Launch Prep
**Goal**: Ensure quality and prepare release

**Current status**: Partial. A gameplay smoke-test script covers major slice flows, but this is not a complete playtest, platform-performance pass, or release build setup. No export presets are currently configured.

#### Tasks:
- [ ] **Bug Fixing**
  - Playtest sessions
  - Memory leak checks
  - Performance optimization
  
- [ ] **Build Configuration**
  - Export presets for all platforms
  - Icon and splash screens
  - App store metadata (if publishing)

---

## Character Design (4 Characters)

### Warrior
- Role: Physical damage dealer
- Abilities: Sword attacks, shield bash, heavy strike
- Progression: Weapon upgrades, critical hit chance

### Mage
- Role: Magic damage/healer
- Abilities: Fire/Ice/Lightning spells, heal, buff
- Progression: MP pool, spell potency

### Thief
- Role: Utility/stealth
- Abilities: Steal items, dodge attacks, trap detection
- Progression: Evasion rate, steal success chance

### Monk
- Role: Balanced fighter
- Abilities: Hand-to-hand combat, counterattack, stun
- Progression: Attack speed, defense bonus

---

## Combat Mechanics

### Turn Order System
```gdscript
# Simplified turn calculation
turn_order = (ATK / DEF) * 100
# Higher value acts first
```

### Action Menu Structure
```
Battle Flow:
1. Player selects action (Attack/Magic/Item/Guard/Flee)
2. Execute player action(s)
3. Enemy AI responds
4. Repeat until battle ends
```

### Elemental System
- Elements: Fire, Ice, Lightning, Wind, Earth, Water
- Resistances: Each enemy has elemental weaknesses/resistances
- Status Effects: Burn (Fire), Freeze (Ice), Shock (Lightning)

---

## Data Structures

### Character Class
```gdscript
class_name Character
var name: String
var hp: int
var max_hp: int
var mp: int
var atk: float
var def: float
var mag: float
var resistances: Dictionary  # element -> multiplier
var equipment: Equipment[]
var status_effects: StatusEffect[]
```

### Enemy Class
```gdscript
class_name Enemy extends Character
var ai_behavior: String      # "aggressive", "defensive", "balanced"
var attack_patterns: Array   # List of possible actions with weights
var loot_table: Dictionary   # Items dropped with probabilities
```

---

## Risk Assessment

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Combat system complexity | High | Start simple, iterate based on playtesting |
| Procedural generation bugs | Medium | Test thoroughly before finalizing algorithm |
| Performance with many entities | Medium | Use object pooling for particles/effects |

### Development Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Content creation time | High | Use placeholder assets, focus on systems first |
| Scope creep | High | Strictly follow phase priorities |
| Burnout | Medium | Build in rest days, celebrate milestones |

---

## Validation Plan

### Playtesting Milestones
1. **Milestone 1**: Combat system functional with 2 characters vs 1 enemy
   - Verify turn order works correctly
   - Test all action types
   
2. **Milestone 2**: Overworld navigation between 3 zones
   - Check zone transitions work smoothly
   - Random encounters trigger appropriately

3. **Milestone 3**: Complete dungeon run with boss fight
   - Procedural generation creates valid layouts
   - Boss mechanics are challenging but fair

4. **Milestone 4**: Full game loop (explore -> battle -> progress)
   - Save/load works correctly
   - Progression feels rewarding

### Quality Metrics
- Combat: Battle resolution time < 3 minutes average
- Performance: FPS > 60 on target devices
- Content: Minimum 5 zones, 1 dungeon, 3 bosses

---

## Remaining Product Decisions

1. **Audio mixing**: The game currently supports a persisted global mute toggle. Decide whether independent music/effects sliders justify the UI and settings complexity.
2. **Art scope**: The pixel style is established. Prioritize walk cycles and environmental variety before adding a much larger set of assets.
3. **Platform scope**: Current controls are keyboard/mouse-oriented. Decide which platform(s) to validate before implementing touch controls or export presets.

---

## Next Steps

1. Make the dungeon prototype a real playable space: render the generated rooms and corridors, constrain movement to floor tiles, and guarantee a reachable exit.
2. Playtest Greenvale from New Game through the main quest and optional content; tune combat pacing, class identity, clue clarity, and shop/reward balance.
3. Add character animation, environmental variation, UI art, location ambience, and separate music/effects volume controls.
4. Revisit party management and additional zones only after the current vertical slice is validated.
5. Add export presets and platform-specific testing when the feature set and controls are stable.

The original MVP timeline is no longer a useful estimate because the project has since evolved into an iterative vertical slice; estimate remaining work after the dungeon and playtest scopes are defined.

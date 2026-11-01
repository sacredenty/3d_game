# Chrono Chronicles - FF6-Style RPG

A turn-based JRPG built with Godot 4, inspired by Final Fantasy VI's world exploration mechanics.

## Current Playable Slice

- Explore a tile-based village and forest clearing with solid world boundaries, trees, and buildings
- Talk to Mira, follow the quest objective, and fight a shade with attack, guard, and potion actions
- Earn gold for completing the quest; progress saves between sessions
- Terrain and character pixel art are generated at runtime as placeholders until source art is added

## How to Run

1. Open Godot 4 in this directory
2. Run the default `res://scenes/game.tscn` scene
3. Press F5 or run from the Play button

## Controls

### Greenvale Adventure
- **WASD** or **Arrow Keys**: Move
- **E**: Talk to Mira / continue dialogue
- **1-5** (or click): Attack, Ember magic, Guard, Potion, Flee
- Ember costs 8 MP; shade victories award XP, and leveling up increases HP and MP
- **Save / Load**: Open the three-slot save menu; overwriting a used slot requires confirmation
- Quest, combat, hero, and world position progress auto-save as you play; loaded slots become the active auto-save
- Use **New Game** on the HUD at any time to start over; confirmation protects the active run, and other save slots remain unchanged

## Project Structure

```
3d_game/
├── assets/              # Game assets (sprites, audio)
│   ├── characters/     # Character sprites/models
│   ├── environments/   # Overworld tiles, dungeon rooms
│   ├── ui/             # UI elements
│   └── audio/          # BGM, SFX
├── scenes/
│   ├── main/           # Main game scene
│   ├── combat/         # Battle scenes
│   ├── overworld/      # Overworld map
│   └── dungeons/       # Dungeon exploration
├── scripts/
│   ├── game/           # Greenvale playable slice and generated pixel art
│   ├── core/           # Base classes (Character, Equipment)
│   ├── systems/        # Game systems (Combat, Save, etc.)
│   │   ├── combat/     # Combat engine
│   │   ├── overworld/  # Overworld navigation
│   │   └── dungeons/   # Dungeon generation
│   ├── main/           # Main game manager
│   └── ui/             # UI controllers
├── plans/              # Design documents
└── project.godot       # Godot project file
```

## Next Steps (Phase 4-5)

1. **Content Creation**: Add character sprites, enemy designs, UI assets
2. **Audio Implementation**: Battle BGM, zone music, SFX
3. **UI Polish**: Menu animations, HUD elements
4. **Testing**: Playtest sessions, bug fixes
5. **Build Configuration**: Export presets for all platforms

## Technical Notes

- Turn order calculated by `(ATK / DEF) * 100`
- Elemental system: Fire, Ice, Lightning, Wind, Earth, Water
- Status effects: Burn, Freeze, Shock, Poison, Sleep
- Greenvale progress auto-saves to `user://greenvale_progress.json`; manual slots are stored alongside it as `user://greenvale_progress_slot_1.json` through `_slot_3.json`

## Default Party

| Class | Role | HP | ATK | DEF | MP | MAG |
|-------|------|----|-----|-----|----|-----|
| Warrior | Physical DPS | 120 | 15.0 | 8.0 | - | - |
| Mage | Magic/Heal | 70 | - | 4.0 | 60 | 12.0 |
| Thief | Utility | 65 | 12.0 | 5.0 | - | 8.0 |
| Monk | Balanced | 90 | 14.0 | 7.0 | 30 | - |

## Known Issues

- Greenvale's first-pass pixel art is generated in code; replace it with a hand-authored tileset and animations as art is added
- The legacy dungeon and broader RPG systems are still prototypes and are not part of the current playable loop

# Chrono Chronicles - FF6-Style RPG

A turn-based JRPG built with Godot 4, inspired by Final Fantasy VI's world exploration mechanics.

## Features Implemented (Phase 1-3)

### Core Systems ✅
- Character class with HP, MP, ATK, DEF stats
- Equipment slots (weapon, armor, accessory)
- Party management for 4 characters
- Turn-based combat engine
- Save/load system using JSON serialization

### Overworld Exploration ✅
- Tile-based navigation system
- Zone transitions (village, forest, cave, castle)
- Random encounter system (15% chance per step)
- Enemy AI with attack patterns and elemental effects

### Dungeon Generation ✅
- Procedural room layout algorithm
- Room types: combat, treasure, boss, exit
- Corridor-based navigation
- Boss encounters

## How to Run

1. Open Godot 4 in this directory
2. Select `res://scenes/main/main_scene.tscn` as the main scene
3. Press F5 or run from the Play button

## Controls

### Overworld Movement
- **WASD** or **Arrow Keys**: Move player
- Random encounters trigger automatically when moving

### Combat (Keyboard)
- **A / 1**: Attack
- **Z / 2**: Magic
- **I / 3**: Item
- **G / 4**: Guard
- **Q / ESC**: Flee

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
- Save data stored in `user://savegame.json`

## Default Party

| Class | Role | HP | ATK | DEF | MP | MAG |
|-------|------|----|-----|-----|----|-----|
| Warrior | Physical DPS | 120 | 15.0 | 8.0 | - | - |
| Mage | Magic/Heal | 70 | - | 4.0 | 60 | 12.0 |
| Thief | Utility | 65 | 12.0 | 5.0 | - | 8.0 |
| Monk | Balanced | 90 | 14.0 | 7.0 | 30 | - |

## Known Issues

- Combat UI needs visual implementation (currently text-only)
- Overworld map rendering uses placeholder tiles
- Dungeon scene needs tilemap integration

# Chrono Chronicles - FF6-Style RPG

A turn-based JRPG built with Godot 4, inspired by Final Fantasy VI's world exploration mechanics.

## Current Playable Slice

- Explore a tile-based village and forest clearing with solid world boundaries, trees, and buildings
- Talk to Mira, investigate forest tracks, and complete two linked quests against the Forest Shade and Bramble Wolf
- After restoring peace, accept Mira's optional hunter contract: examine clues, then fight Ashwing and Thornback in two targetable mixed encounters
- Distinct enemy tactics include Ashwing's MP-draining Cinder bolt and Thornback's one-hit Shell guard; the wolf is fast and the Cave Sentinel wards itself
- Every monster encounter awards gold on victory; battle results show the drop, and mixed encounters combine both monsters' gold
- Rowan's shop separates buying from selling: buy from stock, sell items from your inventory, and see the price or payout on each button
- The Bag is for equipping gear and discarding extras; it compares gear with the currently equipped item and prevents removing the equipped copy
- Open the world map and quest journal with **M** or the HUD button; the map marks the player's position, village landmarks, current clues, and unlocked destinations, while the journal separates active, completed, and upcoming objectives
- After restoring peace, explore an optional cave, face the Cave Sentinel's ward, and claim its one-time Crystal Heart reward
- Earn gold for completing the quest; progress saves between sessions
- Terrain and character pixel art are generated at runtime as placeholders until source art is added

## How to Run

1. Open Godot 4 in this directory
2. Run the default `res://scenes/game.tscn` scene
3. Press F5 or run from the Play button

## Controls

### Greenvale Adventure
- **WASD** or **Arrow Keys**: Move
- **E**: Talk to Mira, trade with Rowan, or continue dialogue
- **I** or **Bag**: Open the character and inventory menu anywhere; compare/equip gear and discard unwanted items
- **1-5** (or click): Attack, Ember magic, Guard, Potion, Flee
- In mixed battles, click an enemy's target button before choosing an action
- Ember costs 8 MP; victories award XP, and leveling up increases maximum HP and MP without restoring damage or spent MP
- At Rowan's shop beside the village gate, use **Buy** for shop stock and **Sell +N G** for your items; the Bag has separate **Equip** and **Discard** actions
- Equipped items cannot be discarded or sold unless you own another copy; selling is only available in Rowan's shop
- Gear for all seven equipment slots adds physical/Ember damage or reduces incoming hits
- Complete Mira's adventure to unlock the cave; interact with the cave entrance, treasure, and exit using **E**
- **Save / Load**: Open the three-slot save menu; overwriting a used slot requires confirmation
- Quest, combat, equipment, inventory, and world position progress auto-save as you play; loaded slots become the active auto-save
- Use **New Game** on the HUD at any time to start over; confirmation protects the active run, and other save slots remain unchanged
- The compact HUD shows the current objective and survival/progression stats; detailed equipment is in the Bag menu

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

## Next Recommended Milestone

1. **Playtest and balance**: Check whether the map and journal make clue routes clear, and tune mixed-fight difficulty, class balance, and monster gold rewards
2. **Replace generated art**: Add authored hero, monster, environment, map, and UI assets while preserving the current gameplay layout
3. **Add audio**: Give Greenvale, exploration clues, and each battle a distinct sound and music identity
4. **Expand the world deliberately**: Build another connected location or party member only after the current quest-and-combat loop is fun
5. **Prepare builds**: Add export presets and platform-specific testing after the content and controls stabilize

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

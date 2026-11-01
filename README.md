# Chrono Chronicles

A solo-hero, turn-based JRPG prototype built with Godot 4, inspired by classic JRPG exploration and combat.

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
- The playable slice uses original pixel-style SVG artwork for the overworld, heroes, NPCs, buildings, and monsters
- Original title, exploration, and battle chiptune loops play alongside combat effects; much of the interface and map markers remain code-drawn
- The game is a focused vertical slice, not yet the larger party-based, multi-zone RPG described by the original design brief
- Hero, NPC, building, tree, and monster artwork is static; animation, varied directional poses, and authored UI art have not been added

## How to Run

1. Open Godot 4 in this directory
2. Run the default title menu (`res://scenes/ui/main_menu.tscn`)
3. Press F5 or run from the Play button

## Title Menu

- **Continue** resumes the latest updated adventure, including a save slot selected from Load Game, and is disabled when no save exists.
- **Load Game** opens the three save slots and is disabled when no slot save exists.
- **New Game** opens hero creation. The current save is not replaced until **Begin Adventure** is confirmed; canceling returns to the title menu.

## Art and Audio

- Original pixel-style SVG assets live in `assets/art/`; SVG sources are kept editable and use crisp pixel edges when rendered in game.
- Original loopable chiptune themes and short combat effects live in `assets/audio/` as WAV files.
- The title menu, Greenvale exploration, and combat use distinct music themes. Combat actions and victories trigger matching sound effects.
- Use **Audio: On / Off** on the title menu or in-game controls to mute or restore all audio; the preference is saved between sessions.

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
├── assets/
│   ├── art/             # Authored SVG artwork used by the Greenvale slice
│   ├── audio/           # Original WAV music and sound effects
│   ├── characters/      # Legacy import metadata; not the active slice artwork
│   ├── environments/    # Legacy import metadata; not the active slice tileset
│   └── ui/              # Legacy import metadata; current UI is mostly code-drawn
├── scenes/
│   ├── ui/main_menu.tscn
│   ├── game.tscn        # Active Greenvale adventure
│   ├── battle.tscn      # Battle UI used by the active slice
│   ├── dungeons/        # Legacy dungeon prototype
│   ├── combat/          # Legacy combat scenes
│   └── autoloads/       # Legacy/general RPG system nodes
├── scripts/
│   ├── game/            # Active Greenvale and battle logic
│   ├── ui/              # Active title menu
│   ├── autoloads/       # Shared audio director and asset manager
│   ├── systems/         # Older standalone system prototypes
│   ├── dungeons/        # Legacy dungeon scene
│   └── core/            # General RPG classes, not an active party system
├── tests/gameplay_smoke.gd
├── plans/              # Design documents
└── project.godot       # Godot project file
```

## Next Recommended Milestone

1. **Stabilize the dungeon prototype before expanding it**: The legacy generator creates room data, but its `set_tile()` is a no-op and the dungeon scene does not render or constrain movement to generated corridors. Finish a complete, traversable dungeon before treating procedural generation as a game feature.
2. **Playtest and balance Greenvale**: Check clue-route clarity, mixed-fight targeting and pacing, class differences, monster gold, and equipment prices.
3. **Polish the presentation**: Add character animation, more environmental variation, authored UI elements, ambient audio, and independent music/effects volume controls.
4. **Expand scope only after playtesting**: Add another connected location or party members only after the current solo-hero loop is consistently fun.
5. **Prepare builds**: Add export presets and platform testing once controls, content, and presentation are stable.

## Technical Notes

- The active slice controls one hero; Warrior, Mage, and Rogue are starting classes, not party members.
- Greenvale progress auto-saves to `user://greenvale_progress.json`; manual slots use `user://greenvale_progress_slot_1.json` through `_slot_3.json`.
- The audio preference is stored in `user://settings.cfg`.

## Known Issues

- The legacy dungeon scene and generator are not part of the active Greenvale loop; tile rendering is unimplemented and movement does not follow generated corridors.
- Map markers, parts of the world dressing, and most interface styling are still created in code; current authored character and monster art is static.
- The four-character party, multi-zone progression, full elemental/status-effect systems, mobile controls, and export setup remain design goals or separate prototypes, not complete active features.

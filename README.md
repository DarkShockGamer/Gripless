# Gripless 🏎️

A multiplayer top-down drift-tandem racing game built with Godot 4 (GDScript).

## Features
- **Multiplayer**: Host or join games with up to 4 players via ENet networking
- **Drift Physics**: Realistic drift mechanics with slip angle, handbrake, and lateral grip simulation
- **Tandem Scoring**: Score bonus points when two cars drift near each other simultaneously
- **3 Tracks**: Industrial Drift, Harbor Circuit, Mountain Pass — each with unique layouts
- **Fog of War**: Limited visibility with a shader-based fog-of-war reveal
- **Progression**: Earn coins, buy new cars with different stats in the shop
- **4 Cars**: Rusty Hatchback (starter), Street Racer, Drift King, V8 Beast

## How to Play

### Setup
1. Open project in Godot 4.2+
2. Run the project (F5)

### Controls
| Action | Keys |
|--------|------|
| Accelerate | W / Up Arrow |
| Brake/Reverse | S / Down Arrow |
| Steer Left | A / Left Arrow |
| Steer Right | D / Right Arrow |
| Handbrake (Drift) | Space |

### Multiplayer
1. **Host**: Enter your name, select car, click HOST. Share your IP with friends.
2. **Join**: Enter your name, select car, click JOIN, enter host's IP, click Connect.
3. In lobby: select track (host only), click READY when ready.
4. Host clicks START GAME when all players are ready.

### Scoring
- Drift Score: Accumulates while drifting (slip angle × speed)
- Tandem Bonus: +500 × combo when drifting within 200px of another drifting car
- Combo Multiplier: Increases with each tandem bonus (max ×5)
- Currency: Earn coins (score ÷ 10) at end of each race

## Project Structure
```
scenes/
  main_menu/   - Title screen with host/join/shop
  lobby/       - Pre-game room with player list and track select
  game/        - Main gameplay scene
  car/         - Car physics and visuals
  hud/         - In-game overlay (score, speed, timer)
  tracks/      - Track1, Track2, Track3
  results/     - Post-race score screen
  shop/        - Car purchase screen
scripts/
  NetworkManager.gd  - ENet multiplayer management
  GameState.gd       - Session state singleton
  SaveGame.gd        - Local save/load persistence
shaders/
  fog_of_war.gdshader - Visibility shader
```

## Technical Details
- **Engine**: Godot 4.2+
- **Networking**: ENet peer-to-peer, host-as-server model, port 7777
- **Physics**: RigidBody2D with custom lateral grip/drift forces
- **Sync**: MultiplayerSynchronizer for positions + RPC for scoring
- **Save**: JSON save file at `user://savegame.json`

---
_Original README below_

# Gripless

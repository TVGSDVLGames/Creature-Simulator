# Project Ethos Fan Simulator — Quest 3 WebXR (Build 01)

**Play:** https://tvgsdvlgames.github.io/Creature-Simulator/quest-lab/ethos-vr/

Fan-made bedroom parody in true binocular WebXR. This version reconstructs our previous September Godot room simulator's features, but the original Godot source ZIP was not available for direct reuse.

## Features
- Real independent left- and right-eye XRViewerPose rendering, projection and viewports; 6DoF tracked head movement.
- VR controller aim rays, trigger interactions, left-stick motion, right-stick 30-degree snap turns and haptics (where supported).
- Bedroom: bed, desk, PC, chair, shelves, posters, blinds, LEDs, shrine, lamp, rugs, litter, pizza and fan memorabilia.
- Interactions with PC launcher, "Time Since Ethos" wall clock, bed, shrine, pizza, trash, posters, shelving and exit.
- Title/menu with BEGIN COPING and CHECK SERVERS AGAIN; fictional GAME OFFLINE launcher and escalating joke dialogue.
- 16 actual bundled GLB assets from Kenney CC0, including models with embedded PNG textures, using an in-browser GLB parser without CDNs or external libraries.
- Desktop browser mode and optional phone touchscreen preview.

## Quest 3 testing
1. Open the Play link in Meta Quest Browser and choose ENTER STEREOSCOPIC VR.
2. Move your head around to check stereo depth and 6DoF parallax.
3. Left thumbstick moves, right thumbstick snap-turns, and controller trigger interacts with the object under the colored ray.
4. Use Quest's system controls to leave immersive mode.

Desktop fallback: BEGIN COPING, WASD to move, mouse to look, E to interact, R to reset. Phone preview: drag left side for walking, right side for looking; use INTERACT button.

## Asset sources
The 16 files in assets/ are Kenney Furniture Kit and Kenney Food Kit models copied from:
https://github.com/Hidencod/tge-assets

Asset licensing: Kenney CC0-1.0, as recorded in the source project's catalog. No official 2K/31st Union game assets or private source files are included. The launcher failure is a **fictional fan joke**, not a statement about the real game's status.

## Verified and remaining
- JavaScript syntax parsed successfully.
- All 16 asset files committed (349,824 bytes total).
- GitHub repository writes succeeded.
- Public Pages serving, real Quest browser rendering and controller mappings still need physical-device verification.

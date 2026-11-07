# PROJECT ETHOS Fan Simulator — Quest 3 Stereoscopic VR Build 02

**Quest Browser:** https://tvgsdvlgames.github.io/Creature-Simulator/quest-lab/ethos-vr/

## Recovered actual source, November 6, 2026
Recovered the exact 95,875,014-byte Library file:
ProjectEthosFanSimulator_PASS5_TITLE_HUMOR_GODOT.zip

The original Godot 4.7.1 project was inside ProjectEthosFanSimulator/.
The original archive contains scripts/main.gd (53,062 bytes), scripts/fan_controller.gd,
~44 custom OBJ props, real ETHOS screenshots, synthesized fan-room audio, PBR materials,
the Pass5 title, Steam-like fake PC launcher, captioned joke interactions and the timer.

This WebXR edition is **an actual port of the contents of that archive**:
- 41 original Pass5 OBJ *instances*, converted and bundled in two GLB files with
  the source's original node positions, model orientations and scales.
- Six original ETHOS screenshots from assets/ethos bundled as one WebP 3x2 atlas.
- The original Pass5 room_hum, ui_click and server_denied sounds, transcoded to Opus.
- Rebuilt 8 x 6 meter room, 14-slat back wall, left-window blinds, real timer placement,
  shrine, props, and PC location copied from scripts/main.gd.
- Exact Pass5 humor captions and functional fake launcher/offline/retry interactions.
- 16 extra Kenney CC0 GLB models remain bundled as fallback if the original model packs fail.
- True two-eye WebXR binocular rendering: per-eye view/projection, 6DoF headset
  tracking, Quest controller aim/trigger, thumbstick locomotion and snap turning.
- Desktop (WASD/mouse/E) and phone browser fallback; these are not VR.

Total original GLB binary bytes: 2,087,604 (major 858,016 and details 1,229,588).
Original screenshot atlas: 18,832 bytes, optimized down from the original images.
Original audio is the archived Pass5 recordings compressed for the web.

## Quest controls
Open link in Meta Quest Browser and choose **ENTER STEREOSCOPIC VR**.
Left stick: move, right stick: 30° snap turn, trigger: interact with highlighted
physical objects. PC interaction opens an in-headset Steam-style panel:
trigger once to PLAY ETHOS -> GAME OFFLINE, trigger again to check again.
Quest system control exits VR.

## Provenance
The archived Godot Pass5 source has original procedural prop OBJ models, not
AI concept art; the original source already included a KayKit CC0 pictureframe.
Kenney CC0 fallback models are from https://github.com/Hidencod/tge-assets.
No engine binary is shipped. Fan parody, not affiliated with 2K or 31st Union.

## Verification
- Source ZIP found and inspected by filename, manifest, source scripts, and size.
- Original binary props, images and audio transferred to GitHub and SHA verified.
- JavaScript parsed without syntax errors.
- **Public GitHub Pages serving and Quest 3 physical hardware are not yet verified.**

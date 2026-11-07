# Project ETHOS Fan Simulator — Quest 3 Stereoscopic WebXR, Build 03

**Open in Quest Browser:** https://tvgsdvlgames.github.io/Creature-Simulator/quest-lab/ethos-vr/

## Source recovered and reused

The actual 95,875,014-byte project in the user's ChatGPT Library was found:

`ProjectEthosFanSimulator_PASS5_TITLE_HUMOR_GODOT.zip`

The archive contains the complete original Godot 4.x project, including `scripts/main.gd`, `scripts/fan_controller.gd`, detailed custom OBJ models, PBR material maps, six authentic Project ETHOS press/gameplay images, synthesized fan-room audio, joke interactions and the title menu.

The **active WebXR build** includes:
- 41 original source OBJ instances, rebuilt as two local GLB asset files (~2.09 MB combined), preserving Godot positioning/scale.
- Full-resolution optimized versions of all **six original screenshots** in `source_visuals.tar.gz`; older low-res source atlas retained as fallback.
- The original wall, wood floor, carpet and other albedo textures optimized for browser rendering, also in `source_visuals.tar.gz`.
- All three original synthesized sounds as web-optimized Opus files.
- Rebuilt 8×6-meter room, physical window blinds, slatted workstation wall, clock location, PC and shrine placement from the source script.
- Fake Steam-style in-world launcher (PC, PLAY ETHOS, GAME OFFLINE, retry), source joke dialogue, clock and interacting with furniture.
- Two distinct WebXR views, headset motion, Quest controller pointer/trigger, left-stick locomotion and right-stick snap turn.
- Desktop and mobile browser fallback modes. These are **not** stereoscopic VR.
- 16 additional local Kenney CC0 GLB models as backup if source geometry cannot be loaded.

The newly uploaded `original_assets.tar.gz` also preserves a separate 42-object GLB conversion directly from the archive, alongside the unmodified screenshot contents, textures and audio. It is a source/reference pack; the lighter two-GLB runtime geometry is used for speed.

## Controls
On a Quest 3 open the link in **Meta Quest Browser** and choose **ENTER STEREOSCOPIC VR**. Left stick moves, right stick snap-turns (30°), trigger interacts. Trigger on the computer to open the fake launcher; trigger to PLAY ETHOS and see the offline response, then trigger to retry. Quest system button exits.

Desktop: Begin Coping, WASD, mouse movement, E to interact, R to reset. Mobile: left touch drag moves, right touch drag turns, INTERACT button selects.

## Verification
- Exact archived source was located and examined, not recreated from guesses.
- Original WebXR code parses as JavaScript.
- GitHub uploads for code, original GLB geometry, screenshots, textures and audio have been confirmed.
- Added an automated GitHub Actions browser screenshot/WebGL smoke test under `.github/workflows/quest-vr-browser-smoke.yml`.
- Quest 3 stereo, actual headset controller mapping and physical-device frame rate remain **unverified until tested on the headset**.

## Legal / attribution
Unofficial fan parody, not affiliated with 2K or 31st Union. Source contains gameplay/press screenshots. Models and sounds are from the user's archived fan project. Fallback assets: Kenney CC0 via https://github.com/Hidencod/tge-assets.

# ▶ Play Creature Simulator in Your Browser

## **[LAUNCH THE PLAYABLE BUILD →](https://creature-simulator-play-tvhsdvlgames.vercel.app/)**

**No download or installation required.** Built in Godot 4.7.1 with keyboard/mouse and controller support.

---

# Creature Simulator

A first-person creature-care simulation prototype built in **Godot 4.7.1**. Internally the project is titled **Specimen Care // Gloop**: the player works repeated lab shifts caring for a strange specimen whose health, trust, mood, hunger, filth, sleep, and behavior evolve over time.

![Creature Simulator gameplay](docs/gameplay.png)

## Highlights

- **14 care shifts**, each built around a 3:30 objective loop.
- Persistent creature stats including hunger, filth, health, sleep, boredom, mood, and trust.
- **15 behavior states** with visible changes to Gloop's movement and presentation.
- Physical care tools: food, bio-scrubber, medicine injector, samples, replaceable biofilters, enrichment ring, and scanner.
- Workstations for meds, samples, filters, enrichment, scanning, operations, growth, logs, and requisitions.
- **20 persistent upgrades** plus consumable restocking.
- **40+ Specimen Log entries** and **15 lab incident types**.
- Credits, research samples, progression, save/continue support, and escalating shift objectives.
- Keyboard/mouse and controller support, including explicit controller onboarding and adjustable look settings.
- Vendored Godot first-person/controller components documented under `vendor/` and `SOURCES.md`.

## Controls

- **WASD / Left Stick** — Move
- **Mouse / Right Stick** — Look
- **E / A** — Interact
- **Q / B** — Drop held item
- **Esc / Start** — Pause

Vertical look defaults to normal/non-inverted and can be changed in Options. Look sensitivity is adjustable.

## Running the project

1. Install **Godot 4.7.1**.
2. Import `project.godot`.
3. Run `main.tscn`.

## Repository notes

This repository is based on the latest **release-candidate / new-player-feel** source snapshot, including the controller onboarding and filth/pause fixes. Development notes are preserved in the pass text files. Third-party and source attribution is documented in `SOURCES.md` and the `vendor/` directory.

## Project status

Playable prototype / portfolio project focused on systemic simulation, readable player feedback, first-person interaction, persistent progression, controller accessibility, and fast iteration in Godot.

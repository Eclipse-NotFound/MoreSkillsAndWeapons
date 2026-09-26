# MoreSkillsAndWeapons

[English](README.md) · [简体中文](README.zh-CN.md)

New skills and weapons for **Fallout Equestria: REMAINS** — the combat-expansion mod of this mod collection.

## Features (v1.14.x)

- **Ricochet**: bullets bounce off walls once, mirror-style (toggleable in settings).
- **Programmable grenade launcher (mswglau)**: granted automatically on load; tune drop rate, wall-bounce count before detonation, muzzle velocity and bounce impulse — SATS trajectories reflect the settings live.
- **Laser skill family**: laser eyes and a laser pointer, with configurable penetration through cabinets/glass, and a cabinet-blocking toggle for the pointer; adaptive radius and response tuning for near-target behaviour.
- **Grenade shoot-down**: shoot grenades, missiles and launched shells out of the air (inherited from the collection).
- **Sprint weapon swap**: hold Shift and use number keys 1–0 to swap the primary quick slots while sprinting.
- **Crouch/ladder aim**: hold Shift+W to raise your muzzle while crouched or climbing ladders.
- **Magic dash keeps stance**: cast magic dash while crouched/prone and keep the stance through and after the dash.
- **Constant spread**: the mod launcher's spread no longer grows with weapon wear.
- SATS enemy-selection and aiming fixes over the vanilla behaviour.

## Requirements

- Fallout Equestria: REMAINS (1.02 recommended).
- The one-time **ModLoader** game patch — see
  [ModLoader Releases](https://github.com/Eclipse-NotFound/ModLoader/releases) → `Remains-GamePatch`.

## Install

1. Download `MoreSkillsAndWeapons_v1.14.3.zip` from [Releases](../../releases).
2. Copy the zip's `mods` folder into your game root (next to `pfe.swf`).
3. Restart the game.

## Usage

Open settings with **F6** in game (or the PipBuck settings page). Every feature above has a toggle/parameter there; settings persist across restarts.

## Disable / uninstall

Set the mod's switches to `0` in `mods/loader-manifest.txt`, or delete `mods/MoreSkills&Weapons`. The directory name really contains `&` — keep it as-is.

## Build from source

AS3 sources live in `src/`; build scripts and notes are in `build/` (development records are in Chinese). The release artifact is `release/MoreSkillsWeaponsMod.swf` (entry class `MoreSkillsWeaponsMod`, static `init(main)`).

## Related mods

[ModLoader](https://github.com/Eclipse-NotFound/ModLoader) ·
[Sandevistan](https://github.com/Eclipse-NotFound/Sandevistan) ·
[TDFC](https://github.com/Eclipse-NotFound/TDFC) ·
[RealisticVision](https://github.com/Eclipse-NotFound/RealisticVision) ·
[RandomRooms](https://github.com/Eclipse-NotFound/RandomRooms) ·
[RConnect](https://github.com/Eclipse-NotFound/RConnect)

> Fan mod project; not affiliated with the game's authors.

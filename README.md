# MoreSkillsAndWeapons — more ways to fight

**English** · [简体中文](README.zh-CN.md)

Add target-seeking bullets, ricochets, a non-lethal laser gun, a configurable grenade launcher, and weapon swapping while sprinting.

**[Download v1.15.3 — MoreSkillsAndWeapons_v1.15.3.zip](https://github.com/Eclipse-NotFound/MoreSkillsAndWeapons/releases/download/v1.15.3/MoreSkillsAndWeapons_v1.15.3.zip)** · [Release notes / other versions](https://github.com/Eclipse-NotFound/MoreSkillsAndWeapons/releases)

Use the download link above, or open the release page, expand **Assets**, and select that filename. **Source code** and the green **Code → Download ZIP** button are development files, not the installable package.

## What changes?

- **Smart weapons:** lock onto visible targets and guide bullets toward them, with optional multiple locks and focus fire. Smart weapons are off by default.
- **Ricochets and grenade launcher:** tune bounces, flight and detonation behavior.
- **Non-lethal laser gun and laser pointer:** blind enemies by hitting eyes or sensors, with adjustable obstruction behavior.
- **Combat controls:** swap weapons while sprinting, raise your gun when crouching or climbing, keep your stance through a magic dash, and shoot down grenades and missiles.

## Install

For **Windows / Remains 1.02**.

1. Save and close the game. In your Steam Library, right-click Remains → **Manage → Browse local files**. The game folder contains `pfe.swf` and `application.xml`.
2. If this is your first mod from this collection, complete the [ModLoader first-time setup](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.md#first-install), including the game patch and scanner. Skip this if already installed.
3. Extract the ZIP and **merge its `mods` folder into the game folder**. Avoid a nested `mods/mods` folder.
4. Double-click **`mods/ModLoader/RemainsModScanner.exe`** inside the game folder. Wait for it to finish, close its message, then launch the game normally.

Check that this file exists: `mods/MoreSkills&Weapons/release/MoreSkillsWeaponsMod.swf`. Press F6 in game to open MSW settings. Keep the `&` in the folder name.

[Folder diagram, updating and recovery](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.md)

## Your first session

Press **F6**, then choose a feature to try. You can also use **PipBuck → Settings → Mods (`模组`) → MSW**. Settings persist between sessions.

| Control | Action |
|---|---|
| F6 | Open/close MSW settings |
| Hold Shift + number keys 1–0 | Switch primary quick-slot weapons while sprinting |
| Hold Shift + W while crouching or climbing | Raise the muzzle |

To try smart bullets, enable the main switch in the smart-weapon settings and acquire a visible enemy. Installing the mod alone does not enable it.

## Updates, removal and compatibility

Before updating, save and close the game, back up `mods/MoreSkills&Weapons`, merge the new files, run the scanner and restart. Preserve your configuration. To disable the mod temporarily, move its folder outside `mods` as a backup, scan again and restart.

This guide covers v1.15.3 on Remains 1.02. The laser causes no direct HP damage, but a blinded enemy can still hurt other characters. Every weapon and co-op combination has not been fully verified.

## Need help?

Check the folder location, run the scanner, and fully restart the game. See the [installation troubleshooting guide](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.md#troubleshooting) for common problems.

If it still fails, [report an issue](https://github.com/Eclipse-NotFound/MoreSkillsAndWeapons/issues) with your game version, mod version, other installed mods, steps to reproduce, and what you expected versus what happened. Include a screenshot or exact error if available; a personal save is not needed for an initial report.

<details>
<summary>Development resources (not needed to install)</summary>

This page describes the downloadable release; repository source may be ahead. See [src](src/) for implementation, with design, validation and version records in the project tree.

</details>

[Browse the mod collection](https://github.com/Eclipse-NotFound/ModLoader#choose-mods) · [First-time installation guide](https://github.com/Eclipse-NotFound/ModLoader/blob/master/docs/INSTALL.md)

An unofficial fan project. You need your own copy of the game.

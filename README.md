<div align="center">

<img src="docs/title.png" width="500" alt="Dude, Don't Slack!">

[![Game Version](https://img.shields.io/badge/wow-3.3.5a-blue.svg)](https://github.com/arkrosclou/DudeDontSlack)

A big icon in the middle of your screen when a raid mechanic lands on **you**.<br>
Marks, chains, standing in bad stuff. Nothing on you, nothing on screen.

</div>

## What it catches

It comes with a ready-made list, taken from what DBM warns you about:

- **Trial of the Crusader**: Incinerate Flesh, Legion Flame, Mistress' Kiss, Paralytic Toxin, Burning Bile,
  Touch of Light / Darkness, Penetrating Cold, Pursued by Anub'arak
- **Icecrown Citadel**: Coldflame, Death and Decay, Mark of the Fallen Champion, Gas Spore, Vile Gas, Mutated
  Infection, Volatile Ooze, Gaseous Bloat, Unbound Plague, Pact of the Darkfallen, Swarming Shadows, Frenzied
  Bloodthirst, Frost Beacon, Unchained Magic, Necrotic Plague, Defile, Harvest Soul, Raging Spirit
- **Ruby Sanctum**: Fiery Combustion, Soul Consumption, Enervating Brand, Flame Beacon
- **Ulduar**: Searing Light, Gravity Bomb, Mark of the Faceless, Brain Link, Malady of the Mind

You can add any other buff or debuff by its spell id. It works on any client language, and one id covers
every difficulty.

Each icon shows how long the aura lasts and its stacks. Several at once line up side by side.

## How to install

1. Download the addon: **[DudeDontSlack-master.zip](https://github.com/arkrosclou/DudeDontSlack/archive/refs/heads/master.zip)**.
2. Open the zip. Inside is a folder called `DudeDontSlack-master`. Copy it into your addons folder
   (`Interface/AddOns`) and **rename it to `DudeDontSlack`**. With the `-master` ending the game will not load it.
3. Start the game. At the character selection screen, click **AddOns** (bottom left) and make sure
   **Dude, Don't Slack!** is enabled.

## How to update

Download the zip again and replace the `DudeDontSlack` folder with the new one. Your settings are kept: they
live in the `WTF` folder, not in the addon.

## Quick start

Type `/dds` to open the options, or right-click the frame. The frame starts unlocked: drag it where you want
it, then lock it. Use `/dds test` to see sample icons.

In the options:

- **Lock frame**: while unlocked, the frame always shows so you can move it
- **Only in a raid group**: turn it off to use it solo or in a party
- **Icon size**: 32 to 200 px, 80 by default
- **Watched auras**: add a spell id, delete a row, or go back to the defaults

| Command | What it does |
|---|---|
| `/dds` | open the options |
| `/dds add <spellId>` | watch an aura |
| `/dds remove <spellId>` | stop watching an aura |
| `/dds list` | list the watched auras |
| `/dds defaults` | reset the list to the defaults |
| `/dds lock` | lock / unlock the frame |
| `/dds test` | show sample icons; run again to turn them off |
| `/dds reset` | move the frame back to the center |

## Problems

Found a bug or got a Lua error? Please [open an issue](https://github.com/arkrosclou/DudeDontSlack/issues).

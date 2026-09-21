# Dude, Don't Slack!

WoW 3.3.5a. Shows a big icon when a raid mechanic lands on you: marks, chains,
standing in bad stuff. Nothing on you, nothing on screen.

## How it works

The options hold a list of spell ids. Each id is turned into its localized name
(`GetSpellInfo`), and your buffs and debuffs are matched by that name on every
`UNIT_AURA`. One id covers the 10/25/heroic variants of a mechanic, and the addon
works on any client language.

Every matching aura gets its own square icon (left to right) with the duration
spiral and the stack count.

The default list comes from the debuffs the DBM modules announce on the player:
Trial of the Crusader (Jaraxxus, beasts, twins, Anub'arak), Icecrown Citadel
(Coldflame, Death and Decay, Saurfang's mark, Plagueworks, Blood-Queen's pact,
Sindragosa's beacon and Unchained Magic, Lich King's plague and Defile), Ruby
Sanctum (Halion's combustion/consumption) and a few from Ulduar.

## Options

`/dds` or Interface Options > Dude, Don't Slack!

- **Lock frame** - unlocked, the frame always shows so it can be dragged; right-click opens the options
- **Only in a raid group** - off to see it solo or in a party
- **Test mode** - three sample icons
- **Icon size** - 32 to 200 px, 80 by default
- **Watched auras** - add a spell id, delete a row, or go back to the defaults

## Slash commands

```
/dds                  options
/dds add <spellId>    watch an aura
/dds remove <spellId>
/dds list
/dds defaults         reset the aura list
/dds lock | test | reset
```

## Installation

WoW 3.3.5a (Wrath of the Lich King). Download the repository and put its files
into `Interface\AddOns\DudeDontSlack` - the folder must be named `DudeDontSlack`, the same as the
`.toc` file. Or clone it straight there:

```
git clone https://github.com/arkrosclou/DudeDontSlack.git Interface/AddOns/DudeDontSlack
```
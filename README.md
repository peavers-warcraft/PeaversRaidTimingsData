# PeaversRaidTimingsData

[![AddonSentry](https://addonsentry.io/api/public/repos/peavers-warcraft/PeaversRaidTimingsData/badge.svg)](https://addonsentry.io/dashboard/peavers-warcraft/PeaversRaidTimingsData)

A data library addon for World of Warcraft that provides the ghost replay data behind [PeaversRaidTimings](https://github.com/peavers-warcraft/PeaversRaidTimings). Think of the ghost car in an arcade racer: for each boss, difficulty and spec this addon ships **one** top-ranked player's **actual** cast timeline, transcribed verbatim from [lorrgs.io](https://lorrgs.io), so you can race your own run against a real one.

## Features

<!-- peavers:features -->
- One real player's real pull per encounter, difficulty and spec — a verbatim cast timeline, never an average
- All three roles covered: dps, healers and tanks
- Full attribution shipped with every ghost — player, report, fight, region, rank, metric and total, so consumers can show who is being followed
- Spell IDs only — names and icons resolve client-side, so the data is small and correct in every locale
- Clean public API consumed by PeaversRaidTimings and available to any addon
- No configuration, no saved variables — pure data provider
<!-- /peavers:features -->

## Why a ghost, and not a consensus

An earlier design merged around 50 logs per spec into a median "consensus" timeline. That was wrong and has been removed. Measurement showed top players simply do not converge on cast times — healers landed within ±3s of a given consensus time only about 30% of the time — so a median describes a performance **nobody actually gave**.

A ghost has no agreement problem to solve: it is one person's run, replayed as it happened. That is why there is no `conf`, no `iqr`, no confidence score and no statistical quality gate anywhere in this schema, and why none should be reintroduced.

<!-- peavers:custom -->
## API

The addon exposes a global `PeaversRaidTimingsData.API`:

```lua
local API = PeaversRaidTimingsData.API

-- Who we are replaying. Attribution is mandatory: surface it in your UI.
local ghost = API.GetGhost(encounterID, difficultyID, specID)
-- ghost = { player = "Awaken", report = "QKcB6hq1dvfXTz8Y", fight = 34,
--           region = "EU", rank = 1, metric = "hps", total = 252285, duration = 433.0 }

-- That player's cast timeline, chronological, verbatim from the log. Returns nil
-- on any miss (unknown encounter, difficulty or spec) and never errors, so you
-- can query optimistically straight out of ENCOUNTER_START.
local casts = API.GetCasts(encounterID, difficultyID, specID)
-- casts[i] = { spell = spellID, t = secondsFromPull }

-- Generator run time, "YYYY-MM-DD HH:MM:SS" UTC, display only.
local updated = API.GetLastUpdate()
```

`t` is seconds from the pull (`ENCOUNTER_START`), one decimal place. Because it is one player's real run, the same spell id repeats once per cast they actually made — key on list position, never on spell id. All returned tables are shared, not copied — treat them as read-only.

Displaying the attribution is the expected use of `GetGhost`:

```lua
-- "Following: Awaken - rank 1 - 252k HPS"
local line = ("Following: %s - rank %d - %.0fk %s")
    :format(ghost.player, ghost.rank, ghost.total / 1000, ghost.metric:upper())
```

> **Note:** `src/Data/RaidTimings.lua` holds real generated data — 40 specs for Rotmire (encounter 3159, mythic), produced by `lorrgs-module` from live lorrgs rankings. The generator overwrites the file wholesale on each run.
>
> Two current limitations worth knowing: only **mythic** difficulty is scraped, so a heroic pull finds no ghost; and casts are filtered to spells with a cooldown of 45s or more, so a ghost is a subset of the player's full log rather than every button they pressed.
<!-- /peavers:custom -->


## Installation

This is a data library used by other Peavers addons and doesn't require direct user interaction. [PeaversUpdater](https://github.com/peavers-warcraft/PeaversUpdater/releases/latest) installs and updates it automatically alongside its parent addon.

---

*Part of the [Peavers](https://peavers.io) addon collection · [Report an issue](https://github.com/peavers-warcraft/PeaversRaidTimingsData/issues) · [Support development on Patreon](https://www.patreon.com/Peavers)*

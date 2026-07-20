---
title: "PeaversRaidTimingsData Documentation"
layout: default
---

# PeaversRaidTimingsData

**PeaversRaidTimingsData** is a World of Warcraft addon library that provides *ghost replay* data. Think of the ghost car in an arcade racer: for each encounter, difficulty and specialization it ships **one** top-ranked player's **actual** cast timeline, transcribed verbatim, so a consuming addon can replay it against the fight clock and let the player race their own run against a real one.

It applies to all three roles — dps, healers and tanks.

The data is generated: `lorrgs-module` in PeaversAddonDataSupplier picks the ranked log for each spec/boss, transcribes its cast timeline, and opens a pull request against this repo. Nothing here is hand-maintained except during bring-up.

## Installation & Setup

1. Install **PeaversRaidTimingsData** into `Interface/AddOns/PeaversRaidTimingsData`.
2. Declare it in your own addon's **.toc** so it loads first:
   ```
   ## OptionalDeps: PeaversRaidTimingsData
   ```
3. Access the library through the global table:
   ```lua
   local PeaversRaidTimingsData = _G["PeaversRaidTimingsData"]
   local API = PeaversRaidTimingsData and PeaversRaidTimingsData.API
   ```

---
## API Overview

`PeaversRaidTimingsData.API` exposes three functions:

- Fetch the ghost metadata (who is being replayed) for an encounter/difficulty/spec.
- Fetch that ghost's cast timeline.
- Ask when the data was last generated.

Every function is defensive: bad arguments and missing data return `nil` rather than raising. There is no error-message return value — a `nil` simply means "no ghost published for that", which is a normal and expected outcome.

---

## Function Reference

### 1. `API.GetGhost(encounterID, difficultyID, specID)`

Returns the attribution for the run being replayed.

**Parameters:**

| Name           | Type   | Required | Description                                                             |
|----------------|--------|----------|-------------------------------------------------------------------------|
| `encounterID`  | number | Yes      | **DungeonEncounterID**, as handed to you by `ENCOUNTER_START`.          |
| `difficultyID` | number | Yes      | Difficulty ID, as handed to you by `ENCOUNTER_START` (e.g. `16` Mythic).|
| `specID`       | number | Yes      | Specialization ID, e.g. from `GetSpecializationInfo`.                   |

**Returns:**

- `ghost` (table or `nil`) – A [Ghost Object](#ghost-object), or `nil` if no ghost is published for that combination.

> `encounterID` is a **DungeonEncounterID** (`DungeonEncounter.db2`), not a wowcompare.io encounter id. The two are different namespaces; the generator maps between them, so pass the client's id through unchanged.

### 2. `API.GetCasts(encounterID, difficultyID, specID)`

Returns that ghost's cast timeline. Same parameters as `GetGhost`.

**Returns:**

- `casts` (table or `nil`) – An array of [Cast Objects](#cast-object) in chronological order by ascending `t`, or `nil` if no ghost is published.

### 3. `API.GetLastUpdate()`

Returns the generator run time as a `"YYYY-MM-DD HH:MM:SS"` UTC string, or `nil`. Display only — it is not parsed.

---

## Data Structures

### Ghost Object

| Key        | Type   | Description                                                        |
|------------|--------|--------------------------------------------------------------------|
| `player`   | string | Character name from the log.                                       |
| `report`   | string | wowcompare.io report code.                                         |
| `fight`    | number | Fight id within that report.                                       |
| `region`   | string | `"EU"`, `"US"`, `"KR"`, `"TW"` or `"CN"`.                          |
| `rank`     | number | This run's rank on the ranking it was taken from.                  |
| `metric`   | string | Ranking metric: `"hps"` or `"dps"` (tanks rank on dps).            |
| `total`    | number | The metric value for that run.                                     |
| `duration` | number | Pull length in seconds — useful for showing progress against the ghost. |

**Attribution is required.** Because this replays a named person's real performance, consumers are expected to surface who they are following:

```lua
-- "Following: Awaken - rank 1 - 252k HPS"
local line = ("Following: %s - rank %d - %.0fk %s")
    :format(ghost.player, ghost.rank, ghost.total / 1000, ghost.metric:upper())
```

`report` and `fight` are enough to rebuild the source log url, so you can link the run.

### Cast Object

| Key     | Type   | Description                                                                                     |
|---------|--------|-------------------------------------------------------------------------------------------------|
| `spell` | number | Spell ID. Resolve the name and icon client-side with `C_Spell.GetSpellName` / `GetSpellTexture`. |
| `t`     | number | Seconds from the pull (`ENCOUNTER_START`), float to one decimal place.                          |

That is the whole object. There is no `conf`, no `iqr`, no `anchor` and no `offset` — see below.

**The same spell id repeats** once per cast the ghost actually made, so track your position in the list. Never key on spell id.

---

## Why a ghost, and not a consensus

An earlier design merged around 50 logs per spec into a median "consensus" timeline. That was wrong and has been removed.

Measurement showed top players simply do not converge on cast times — healers landed within ±3s of a given consensus time only about 30% of the time — so a median timeline describes a performance **nobody actually gave**. A ghost has no agreement problem to solve: it is one person's run, replayed as it happened.

That is why there is no confidence score, no interquartile spread and no statistical quality gate anywhere in this schema, and why none should be reintroduced. The only open questions are which log to pick and whether it was transcribed faithfully.

---

## Notes on the data

- **Returned tables are shared, not copied.** Treat everything the API hands back as read-only; mutating it corrupts the data for every other consumer in the session.
- **Missing specs are normal.** If no suitable ranked log exists for a spec on a boss, nothing is published and both functions return `nil`.
- **The ghost drifts on off-pace pulls.** Everything is absolute time from the pull, and the 12.0 client cannot detect boss phase transitions — `COMBAT_LOG_EVENT_UNFILTERED` is forbidden to addons, boss `UNIT_*` events are blocked during encounters, and `C_EncounterTimeline` spell IDs are secret values. A fight that runs long desyncs from the ghost, exactly as a ghost car pulls away from a slower lap. `ghost.duration` tells you the pace being raced.

---

## Examples

### Example 1: Load a ghost at the start of an encounter

```lua
local API = _G["PeaversRaidTimingsData"] and _G["PeaversRaidTimingsData"].API

local function OnEncounterStart(encounterID, difficultyID)
    if not API then return end

    local specIndex = GetSpecialization()
    local specID = specIndex and GetSpecializationInfo(specIndex)
    if not specID then return end

    local ghost = API.GetGhost(encounterID, difficultyID, specID)
    local casts = API.GetCasts(encounterID, difficultyID, specID)
    if not ghost or not casts then
        -- Normal outcome: nothing published for this boss/difficulty/spec.
        return
    end

    print(("Following: %s - rank %d - %.0fk %s"):format(
        ghost.player, ghost.rank, ghost.total / 1000, ghost.metric:upper()))

    for i, cast in ipairs(casts) do
        print(("%3d  %6.1fs  %s"):format(
            i, cast.t, C_Spell.GetSpellName(cast.spell) or cast.spell))
    end
end
```

### Example 2: Find the next cast for the current fight clock

```lua
-- `index` is your own cursor into the cast list; it only ever moves forward.
local function AdvanceGhost(casts, index, elapsed, leadIn)
    while casts[index] and casts[index].t <= elapsed do
        index = index + 1
    end

    local next = casts[index]
    if next and next.t - elapsed <= leadIn then
        -- Announce it: "<spell> in <n> seconds".
        return index, next, next.t - elapsed
    end

    return index, nil, nil
end
```

### Example 3: Show the data age

```lua
local updated = API.GetLastUpdate()
print("Ghost data last generated: " .. (updated or "unknown"))
```

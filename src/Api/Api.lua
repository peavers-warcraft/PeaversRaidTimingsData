local _, addonTable = ...

-- Create the global addon table
_G["PeaversRaidTimingsData"] = _G["PeaversRaidTimingsData"] or {}
local publicAPI = _G["PeaversRaidTimingsData"]

-- Create the API namespace
publicAPI.API = publicAPI.API or {}
local API = publicAPI.API

---Resolves one spec entry out of the ghost database (see src\Data\RaidTimings.lua).
---Every argument is type-checked and every level of the lookup is guarded, so a
---missing encounter, difficulty or spec yields nil rather than an error.
---@param encounterID number DungeonEncounterID from ENCOUNTER_START
---@param difficultyID number difficultyID from ENCOUNTER_START
---@param specID number specialization ID from GetSpecializationInfo
---@return table|nil spec Spec entry ({ ghost = {...}, casts = {...} }), or nil on any miss
local function getSpec(encounterID, difficultyID, specID)
	if type(encounterID) ~= "number" or type(difficultyID) ~= "number" or type(specID) ~= "number" then
		return nil
	end

	local data = addonTable.RaidTimings
	if type(data) ~= "table" or type(data.encounters) ~= "table" then
		return nil
	end

	local encounter = data.encounters[encounterID]
	if type(encounter) ~= "table" then
		return nil
	end

	local difficulty = encounter[difficultyID]
	if type(difficulty) ~= "table" or type(difficulty.specs) ~= "table" then
		return nil
	end

	local spec = difficulty.specs[specID]
	if type(spec) ~= "table" then
		return nil
	end

	return spec
end

---Returns the ghost attribution for one spec on one encounter at one difficulty
---(see src\Data\RaidTimings.lua).
---Shape: { player = "Awaken", report = "QKcB6hq1dvfXTz8Y", fight = 34,
---region = "EU", rank = 1, metric = "hps" | "dps" | "dtps", total = 252285,
---duration = 433.0 }. This addon ships ONE real player's ONE real pull per spec,
---never an average of many, so the run is always attributable: consumers are
---expected to surface it ("Following: Awaken - rank 1 - 252k HPS") and can
---rebuild the source log url from `report` and `fight`. `duration` is the length
---of that pull in seconds, so a consumer can show progress against the ghost.
---Returns nil on any miss (unknown encounter, difficulty or spec) and never
---errors, so callers can query optimistically straight out of ENCOUNTER_START.
---The table is shared, not copied - treat it as read-only.
---@param encounterID number DungeonEncounterID from ENCOUNTER_START
---@param difficultyID number difficultyID from ENCOUNTER_START
---@param specID number specialization ID from GetSpecializationInfo
---@return table|nil ghost Ghost metadata table, or nil if no ghost is published
function API.GetGhost(encounterID, difficultyID, specID)
	local spec = getSpec(encounterID, difficultyID, specID)
	if not spec or type(spec.ghost) ~= "table" then
		return nil
	end

	return spec.ghost
end

---Returns the ghost's cast timeline for one spec on one encounter at one
---difficulty (see src\Data\RaidTimings.lua).
---Shape: { { spell = spellID, t = seconds }, ... }, chronological by ascending
---`t`. `t` is SECONDS from the pull (ENCOUNTER_START), float, one decimal place,
---transcribed verbatim from the source log - it is what that player actually did
---on that pull, not a modelled, median or smoothed time. Spell ids only: resolve
---name and icon client-side via C_Spell.*. The same spell id repeats wherever the
---ghost recast it, so consumers must key on position in the list, never on spell
---id. Pair with GetGhost to attribute the run being replayed.
---Returns nil on any miss (unknown encounter, difficulty or spec) and never
---errors, so callers can query optimistically straight out of ENCOUNTER_START.
---The table is shared, not copied - treat it as read-only.
---@param encounterID number DungeonEncounterID from ENCOUNTER_START
---@param difficultyID number difficultyID from ENCOUNTER_START
---@param specID number specialization ID from GetSpecializationInfo
---@return table|nil casts Array of cast tables, or nil if no ghost is published
function API.GetCasts(encounterID, difficultyID, specID)
	local spec = getSpec(encounterID, difficultyID, specID)
	if not spec or type(spec.casts) ~= "table" then
		return nil
	end

	return spec.casts
end

---Returns the timestamp of the last generator run that produced this data.
---Format: "YYYY-MM-DD HH:MM:SS" (UTC). Intended for display only - it is a
---string, not a parsed time.
---@return string|nil updated Timestamp string, or nil if no data is published
function API.GetLastUpdate()
	local data = addonTable.RaidTimings
	if type(data) ~= "table" or type(data.updated) ~= "string" then
		return nil
	end

	return data.updated
end

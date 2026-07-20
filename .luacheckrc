-- PeaversRaidTimingsData luacheck config. Thin wrapper over the shared Peavers base (../wow-api).
-- The base supplies the lua51+wow standard, ignore/exclude policy, and stds.wow (WoW API:
-- generated from /papidump when present, else curated). allow_defined_top is off, so every
-- global this addon creates must be listed below — that list is its documented _G footprint.
-- Run: ../wow-api/scripts/lint.sh   (override package path with WOW_API_DIR)

local apiDir = (os and os.getenv and os.getenv("WOW_API_DIR")) or "../wow-api"
local loadBase = loadfile(apiDir .. "/config/luacheckrc.base.lua")

if loadBase then
	local base = loadBase(apiDir)

	std             = base.std
	ignore          = base.ignore
	exclude_files   = base.exclude
	max_line_length = false
	codestyle       = false
	allow_defined_top = base.allow_defined_top
	stds.wow        = base.wow

	-- base.globals (PeaversChangelogs, SlashCmdList) + this addon's SavedVariables.
	globals = base.globals
	for _, g in ipairs({}) do globals[#globals + 1] = g end
else
	-- Shared base unavailable (no ../wow-api checkout, e.g. a standalone clone):
	-- degrade to a plain lua51 run so luacheck still works instead of erroring.
	std             = "lua51"
	max_line_length = false
	codestyle       = false
	allow_defined_top = true
	globals = { "PeaversChangelogs", "SlashCmdList" }
end

-- River crossing world (720x300) for pine country; see ../crossing_banks.lua.
local K = dofile(app.params.kit)
dofile((app.params.kit:gsub("lib%.lua$", "crossing_banks.lua")))(K, "pine", 184913)

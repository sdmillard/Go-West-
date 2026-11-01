-- River crossing world (720x300) for sage country; see ../crossing_banks.lua.
local K = dofile(app.params.kit)
dofile((app.params.kit:gsub("lib%.lua$", "crossing_banks.lua")))(K, "sage", 184901)

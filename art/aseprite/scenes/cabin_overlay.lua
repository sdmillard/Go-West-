-- The party's winter cabin, laid over a timber stop's picture while it is built (400x168).
-- Three sizes in rows (small for the middle distance, medium, large for the foreground) and
-- five stages in columns: felled logs, walls half raised, walls up with rafters, finished,
-- finished under snow. Each 80x56 frame has the cabin's left ground corner at (12, 52).
-- Sizes run about 3 px to the foot near the viewer, like the people in the scenes.
-- ui/trail_view.gd places it from the "cabin" point in data/scene_ambience.json.
local K = dofile(app.params.kit)
local FW, FH = 80, 56
local SIZES = {{30, 12}, {40, 16}, {54, 21}}
K.canvas(FW * 5, FH * 3, 1846)
K.layer("cabins", function()
  for r, s in ipairs(SIZES) do
    for c = 1, 5 do
      local stage = math.min(c, 4)
      K.log_cabin((c - 1) * FW + 12, (r - 1) * FH + 52, s[1], s[2], stage, c == 5)
    end
  end
end)
K.save("cabin_overlay")

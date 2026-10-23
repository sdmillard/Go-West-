-- Courthouse and Jail Rocks (432x150), seen from the trail along the North Platte.
-- They stand about five miles south of the road: two eroded Brule clay and Arikaree sandstone
-- buttes, Courthouse broad with a domed crown and steep gullied walls, Jail Rock smaller to
-- its east, both rising off long pale aprons above the Pumpkin Creek plain. Emigrants called
-- Courthouse "the Castle" or "the Solitary Tower".
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 96

K.canvas(W, H, 1848)

K.layer("sky", function()
  K.sky(W, HORIZON, {{24, 22, 0.9}, {188, 12, 1.2}, {372, 30, 0.7}})
  -- low far breaks of the Wildcat Hills behind the rocks
  K.ridge(0, W - 1, HORIZON - 4, HORIZON, function(x) return 6 + 3 * math.sin(x / 37) + 2 * math.sin(x / 11 + 1) end, "far_hill", "mist", "haze")
end)

K.layer("rocks", function()
  -- Courthouse: the bigger mass with a western buttress
  K.butte({cx = 112, crown = 12, top = 62, shoulder = 78, base = 96, foot = 46, seed = 3})
  K.butte({cx = 150, crown = 26, top = 40, shoulder = 66, base = 98, foot = 70, seed = 1})
  -- Jail Rock across the gap
  K.butte({cx = 262, crown = 11, top = 56, shoulder = 74, base = 98, foot = 40, seed = 5})
end)

K.layer("plain", function()
  K.rect(0, 97, W, H - 97, "sage")
  K.dither(0, 97, W, 3, "far_hill", "sage")
  K.rect(0, 108, W, H - 108, "grass")
  K.dither(0, 104, W, 4, "sage", "grass")
  for i = 1, 900 do
    local x, y = K.rnd(W), 98 + K.rnd(H - 98)
    local d = (y - 98) / (H - 98)
    K.px(x, y, (K.rnd(3) == 0) and "gold" or ((d > 0.5 and K.rnd(2) == 0) and "leaf" or "sage"))
  end
  for i = 1, 26 do K.sage(10 + K.rnd(W - 20), 112 + K.rnd(36)) end
  -- the wagon road along the valley, crossing in the foreground
  local road = K.smooth({{-10, 132, 7}, {120, 126, 6}, {260, 116, 4}, {440, 108, 2}}, 10)
  K.ribbon(road, "ochre", 1)
  K.ribbon(road, "gold", -2)
  for i = 1, #road - 1, 2 do K.px(math.floor(road[i][1]), math.floor(road[i][2]), "rust") end
end)

K.layer("travelers", function()
  -- a train strung along the road for scale against the rocks
  K.far_wagon(318, 113, 1)
  K.far_wagon(346, 111, 1)
  K.wagon(150, 131, 1)
  K.team(198, 131, 1, {"red"}, {"light", true})
  K.person(140, 132, "red", "bonnet", true)
  K.person(232, 130, "blue", "deep", false)
end)

K.save("location_courthouse_rock")

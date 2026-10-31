-- Horse Shoe Creek (432x150).
-- West of Fort Laramie the road left the river for the rough "Black Hills" (the Laramie
-- Mountains' foothills): red earth, scattered pine and cedar on the ridges, and at Horse Shoe
-- Creek a clear, quick stream with timber and good grass, a favorite noon or night camp.
-- Laramie Peak stands dark and high to the south-west.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184832)

local stream = {{440, 104, 2}, {380, 110, 3}, {320, 108, 3}, {260, 116, 4}, {200, 124, 5}, {140, 134, 6}, {80, 148, 7}, {40, 160, 8}}

K.layer("sky", function()
  K.sky(W, 84, {{40, 10, 0.7}, {250, 20, 0.9}}, "mist")
end)

K.layer("hills", function()
  -- Laramie Peak: a dark timbered dome rising well above the foothills
  K.ridge(0, W - 1, 0, 90, function(x) local d = (x - 300) / 64; return -(72 - 42 * math.exp(-d * d) + 3 * math.sin(x / 13)) end, "storm", "storm_lt", "storm_dk")
  for i = 1, 260 do
    local x, y = 220 + K.rnd(170), 30 + K.rnd(50)
    if K.at(x, y) == "storm" then K.px(x, y, (i % 3 == 0) and "storm_dk" or "pine") end
  end
  -- rough red foothills with pine on the crests
  K.ridge(0, W - 1, 0, 100, function(x) return -(64 + 8 * math.sin(x / 31) + 4 * math.sin(x / 11 + 1)) end, "brick", "brick_lt", "brick_dk")
  K.ridge(0, W - 1, 0, 104, function(x) return -(78 + 6 * math.sin(x / 23 + 2) + 3 * math.sin(x / 7)) end, "rust", "ochre", "brick")
  for i = 1, 700 do
    local x, y = K.rnd(W), 56 + K.rnd(48)
    local c = K.at(x, y)
    if c == "brick" or c == "rust" then K.px(x, y, ({"sage", "ochre", "brick_dk", "dirt_dk"})[i % 4 + 1]) end
  end
end)

K.layer("pines", function()
  for x = 4, W, 13 do
    local top = 64 + math.floor(8 * math.sin(x / 31) + 4 * math.sin(x / 11 + 1))
    if (x * 7) % 3 ~= 0 then K.conifer(x, 100 - (100 - top) + 4 + (x % 5), 7 + x % 4) end
  end
  for x = 10, W, 17 do
    local top = 78 + math.floor(6 * math.sin(x / 23 + 2) + 3 * math.sin(x / 7))
    if x % 2 == 0 then K.conifer(x, top + 6, 9 + x % 5) end
  end
end)

K.layer("meadow", function()
  K.rect(0, 100, W, H - 100, "rust")
  -- the creek bottom: grass, a clear gravelly stream, willow and box elder
  K.ellipse(220, 140, 260, 40, "grass")
  for i = 1, 900 do
    local x, y = K.rnd(W), 100 + K.rnd(50)
    if K.at(x, y) == "grass" then K.px(x, y, ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end
  end
  local water = K.smooth(stream)
  K.ribbon(water, "stone", 2)
  K.river(water, false)
  for i = 1, 40 do
    local x, y = 60 + K.rnd(380), 100 + K.rnd(50)
    if K.at(x, y) == "stone" then K.px(x, y, (i % 2 == 0) and "stone_lt" or "stone_dk") end
  end
  local road = K.smooth({{440, 132, 4}, {360, 128, 4}, {300, 132, 4}, {240, 130, 3}, {190, 120, 3}, {150, 110, 2}, {100, 104, 2}, {30, 100, 1}})
  K.ribbon(road, "brick_dk", 1); K.ribbon(road, "rust", 0)
  for _, w in ipairs({{250, 112, 1}, {300, 104, 1}, {170, 124, 1}, {110, 140, 1}, {214, 136, 2}, {350, 110, 1}}) do K.willow(w[1], w[2], w[3]) end
  K.elm(330, 106, 1); K.elm(140, 120, 1); K.elm(60, 140, 1)
  K.conifer(410, 150, 26); K.conifer(20, 120, 18)
  K.boulder(392, 138, 6, 4); K.boulder(36, 146, 4, 3)
end)

K.layer("figures", function()
  -- a noon halt: oxen loosed to graze, a wagon on the road, someone filling a bucket
  K.wagon(330, 138, -1)
  K.ox(270, 140, -1, "light"); K.ox(380, 146, 1, "dark")
  K.person(212, 126, "blue", "deep")
  K.rect(218, 122, 3, 3, "wood")
  K.person(352, 142, "red", "bonnet", true)
end)

K.save("location_horseshoe_creek")

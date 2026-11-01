-- Weber River crossing at the foot of Echo Canyon (432x150).
-- The Mormon road comes down Echo Canyon between red sandstone cliffs to the Weber, where the
-- pioneer company of 1847 forded it. Cottonwoods and willows line the river; the Wasatch
-- rises beyond, with snow left in its gullies into summer.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185323)

local river = {{-10, 112, 6}, {80, 116, 7}, {170, 118, 8}, {260, 114, 8}, {350, 108, 7}, {440, 104, 6}}

K.layer("sky", function()
  K.sky(W, 66, {{60, 10, 0.7}, {250, 16, 0.9}}, "mist")
end)

K.layer("mountains", function()
  K.peaks(0, W - 1, 80, 92, function(x) return 40 + 12 * math.sin(x / 47 + 1) + 6 * math.sin(x / 13) + 3 * math.sin(x / 5) end, 46)
  -- the Wasatch's timbered lower slopes
  K.ridge(0, W - 1, 0, 96, function(x) return -(74 - 6 * math.sin(x / 29) - 3 * math.sin(x / 11 + 1)) end, "teal", "haze", "teal")
  for i = 1, 700 do local x, y = K.rnd(W), 64 + K.rnd(32); if K.at(x, y) == "teal" then K.px(x, y, ({"pine", "leaf", "teal"})[i % 3 + 1]) end end
end)

K.layer("cliffs", function()
  -- red sandstone ledges of Echo Canyon's mouth on the left, stepped and streaked
  for x = 0, 150 do
    local top = math.floor(36 + 0.30 * x + 5 * math.sin(x / 9) + 3 * math.sin(x / 4))
    local foot = 104
    for y = top, foot do
      local band = (y + math.floor(2 * math.sin(x / 31))) % 9
      local c = (band < 2) and "brick_lt" or ((band < 6) and "brick" or "brick_dk")
      -- vertical joints and rills, only here and there
      if (x % 23 == 5) and y > top + 3 and y < top + 30 then c = "brick_dk" end
      if y == top then c = "rust" end
      K.px(x, y, c)
    end
  end
  for i = 1, 200 do local x, y = K.rnd(150), 40 + K.rnd(64); if K.at(x, y) == "brick" then K.px(x, y, ({"brick_lt", "rust", "ochre"})[i % 3 + 1]) end end
end)

K.layer("bottom", function()
  K.rect(0, 100, W, H - 100, "grass")
  for i = 1, 1400 do K.px(K.rnd(W), 100 + K.rnd(H - 100), ({"sage", "grass", "leaf", "gold", "sage"})[i % 5 + 1]) end
  local water = K.smooth(river)
  K.river(water, "stone_lt")
  for i = 1, 160 do
    local x = 200 + K.rnd(70)
    local y = 110 + K.rnd(14)
    K.rect(x, y, 1 + K.rnd(3), 1, (K.rnd(3) == 0) and "white" or "light_blue")
  end
  local road = K.smooth({{300, 104, 2}, {340, 100, 2}, {400, 98, 2}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
  road = K.smooth({{236, 126, 3}, {226, 138, 5}, {210, 152, 6}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("trees", function()
  for _, t in ipairs({{170, 102, 1}, {300, 98, 1}, {340, 100, 1}, {392, 98, 1}, {30, 140, 2}, {410, 146, 2}}) do K.elm(t[1], t[2], t[3]) end
  for i = 1, #river - 1 do local a = river[i]; if i ~= 3 then K.willow(a[1] + 30, a[2] + a[3] + 6, 1) end end
end)

K.layer("figures", function()
  K.wagon(212, 120, 1)
  K.team(262, 116, 1, {"dark"}, {"red"})
  K.wade(210, 290, 120, 4)
  K.wagon(120, 146, 1)
  K.team(170, 142, 1, {"light", true}, {"dark"})
  K.person(218, 144, "brick", "hat"); K.person(232, 146, "blue", "bonnet", true)
end)

K.save("location_weber_river")

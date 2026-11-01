-- Humboldt Wells (432x150).
-- At the head of the Humboldt, deep spring holes stand open in a green meadow: clear pools in
-- the grass, rushes round them, the meadow running down into the start of Mary's River. Sage
-- hills close it in, with the Ruby and East Humboldt ranges blue to the south.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185113)

local function well(x, y, rx, ry)
  K.ellipse(x, y, rx + 2, ry + 1, "leaf")
  K.ellipse(x, y, rx, ry, "blue")
  K.ellipse(x - 1, y - 1, rx - 2, math.max(1, ry - 1), "sky_top")
  K.rect(x - rx // 2, y - 1, math.max(1, rx // 2), 1, "light_blue")
  for i = -rx, rx, 3 do K.line(x + i, y - ry - 1, x + i - 1, y - ry - 4, (i % 2 == 0) and "pine" or "grass") end
end

K.layer("sky", function()
  K.sky(W, 74, {{170, 10, 0.8}, {360, 18, 0.6}}, "mist")
end)

K.layer("ranges", function()
  -- the East Humboldt and Ruby ranges, blue with distance, a little old snow in the gullies
  K.ridge(0, W - 1, 0, 90, function(x) return -(56 - 10 * math.sin(x / 37 + 1) - 5 * math.sin(x / 15 + 2) - 2 * math.sin(x / 5)) end, "far_hill", "mist", "haze")
  for x = 0, W - 1, 1 do
    local top = math.floor(56 - 10 * math.sin(x / 37 + 1) - 5 * math.sin(x / 15 + 2) - 2 * math.sin(x / 5) + 0.5)
    if top < 46 and (x * 13) % 7 < 3 then K.line(x, top + 1, x + 1, top + 3 + (x % 4), "mist") end
  end
  K.ridge(0, W - 1, 0, 96, function(x) return -(78 - 5 * math.sin(x / 41 + 2) - 2 * math.sin(x / 11)) end, "sage", "haze", "teal")
  for i = 1, 260 do local x, y = K.rnd(W), 72 + K.rnd(22); if K.at(x, y) == "sage" then K.px(x, y, (i % 3 == 0) and "teal" or "haze") end end
end)

K.layer("meadow", function()
  K.rect(0, 90, W, H - 90, "grass")
  for i = 1, 1600 do K.px(K.rnd(W), 90 + K.rnd(H - 90), ({"leaf", "sage", "grass", "gold", "leaf"})[i % 5 + 1]) end
  -- the start of the river winding off west
  local run = K.smooth({{230, 112, 2}, {180, 104, 2}, {120, 98, 2}, {50, 94, 2}, {-10, 92, 1}})
  K.ribbon(run, "leaf", 2); K.river(run, false)
  well(250, 116, 10, 4); well(300, 126, 7, 3); well(206, 132, 12, 4); well(352, 112, 6, 2); well(150, 120, 5, 2)
  local road = K.smooth({{440, 104, 2}, {380, 102, 2}, {320, 104, 3}, {280, 140, 4}, {200, 146, 5}, {-10, 142, 5}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("brush", function()
  for _, s in ipairs({{20, 104}, {90, 108}, {400, 120}, {420, 138}, {380, 96}, {16, 128}}) do K.sage(s[1], s[2]) end
  for _, w in ipairs({{100, 98, 1}, {60, 96, 1}, {176, 106, 1}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("figures", function()
  K.wagon(120, 142, -1)
  K.team(106, 138, -1, {"dark"}, {"red"})
  K.person(236, 120, "teal", "bonnet", true) -- dipping water
  K.ox(320, 116, -1, "light"); K.ox(176, 124, 1, "dark")
  K.far_wagon(390, 101, -1)
end)

K.save("location_humboldt_wells")

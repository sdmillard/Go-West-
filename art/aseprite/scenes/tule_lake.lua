-- Tule Lake (432x150).
-- The road skirts a great marshy lake under a dark lava bluff. Tules grow higher than a man in
-- the shallows; ducks and geese rise off the open water. This is Modoc country.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185201)

local function tules(x0, x1, base, h)
  for x = x0, x1 do
    -- clumps and gaps, not a fence
    local dense = math.sin(x / 9 + base) + 0.7 * math.sin(x / 3.7 + base * 2)
    if dense > -0.2 and K.rnd(3) ~= 0 then
      local hh = math.floor(h * (0.55 + 0.25 * dense)) - K.rnd(math.max(1, h // 3))
      local c = ({"sage", "grass", "silt_lt", "leaf"})[K.rnd(4) + 1]
      if K.season == "autumn" or K.season == "winter" then c = ({"silt_lt", "silt", "ochre", "sand"})[K.rnd(4) + 1] end
      K.line(x, base, x + K.rnd(3) - 1, base - hh, c)
      if K.rnd(5) == 0 then K.rect(x, base - hh, 1, 2, "wood") end
    end
  end
end

K.layer("sky", function()
  K.sky(W, 80, {{80, 14, 0.6}, {230, 6, 1.0}}, "mist")
end)

K.layer("land", function()
  -- far shore and hills to the south, Mount Shasta faint and white beyond
  K.peaks(300, 400, 64, 70, function(x) return math.max(0, 26 - math.abs(x - 350) * 0.6) end, 14)
  K.ridge(0, W - 1, 0, 84, function(x) return -(64 - 4 * math.sin(x / 37) - 2 * math.sin(x / 13)) end, "far_hill", "mist", "haze")
  -- the lava bluff on the right, dark and blocky
  K.ridge(220, W - 1, 0, 106, function(x) local f = math.min(1, (x - 220) / 50); return -(96 - f * (36 + 3 * math.sin(x / 7))) end, "roof", "roof_lt", "roof_dk")
  -- the bluff face: grey-brown lava ledges with sage on the benches
  for i = 1, 1400 do
    local x, y = 220 + K.rnd(212), 58 + K.rnd(48)
    if K.at(x, y) == "roof" then K.px(x, y, ({"roof_dk", "stone_dk", "roof_lt", "sage", "silt", "stone_dk"})[K.rnd(6) + 1]) end
  end
  for i = 1, 26 do
    local x, y = 240 + K.rnd(190), 64 + K.rnd(38)
    if K.at(x, y) and K.at(x, y) ~= "sky" and K.at(x, y - 3) and K.at(x, y - 3) ~= "mist" then
      local w = 6 + K.rnd(14); K.rect(x, y, w, 1, "stone"); K.rect(x + 1, y + 1, w, 1, "ink")
    end
  end
end)

K.layer("lake", function()
  K.rect(0, 80, 260, 30, "sky_top")
  K.poly({{0, 80}, {260, 80}, {280, 104}, {0, 110}}, "sky_top")
  for i = 1, 160 do K.rect(K.rnd(270), 82 + K.rnd(26), 2 + K.rnd(5), 1, (i % 2 == 0) and "light_blue" or "sea") end
  tules(0, 60, 96, 10); tules(110, 180, 94, 9); tules(0, 280, 112, 14)
end)

K.layer("shore", function()
  K.rect(0, 109, W, H - 109, "sage")
  for i = 1, 1400 do K.px(K.rnd(W), 109 + K.rnd(H - 109), ({"silt_lt", "grass", "sage", "silt", "clap_sh"})[i % 5 + 1]) end
  local road = K.smooth({{440, 118, 3}, {360, 124, 4}, {280, 132, 4}, {180, 140, 5}, {-10, 144, 5}})
  K.ribbon(road, "silt", 1); K.ribbon(road, "clap_sh", 0)
  tules(0, 120, 116, 8)
  -- waterfowl over the open water
  for _, b in ipairs({{60, 70}, {66, 67}, {72, 66}, {78, 68}, {140, 74}, {146, 72}, {152, 75}}) do K.px(b[1], b[2], "ink"); K.px(b[1] - 1, b[2] - 1, "ink"); K.px(b[1] + 1, b[2] - 1, "ink") end
end)

K.layer("figures", function()
  K.wagon(250, 134, -1)
  K.team(236, 130, -1, {"dark"}, {"red"})
  K.wagon(340, 122, -1)
  K.team(326, 118, -1, {"light", true}, {"dark"})
  K.person(300, 138, "blue", "hat")
  -- a Modoc tule canoe on the water
  K.rect(150, 100, 14, 2, "ochre"); K.rect(151, 102, 12, 1, "wood"); K.rect(156, 96, 1, 4, "deep"); K.line(152, 99, 160, 97, "wood")
end)

K.save("location_tule_lake")

-- Fort Walla Walla, the Hudson's Bay Company's Fort Nez Percés (432x150).
-- The post stood on a bare sandy bench on the east bank of the Columbia just above the mouth of
-- the Walla Walla River. After the wooden fort burned in 1841 it was rebuilt in adobe: a
-- square of thick mud-brick walls with two bastions at opposite corners and the gate toward the
-- river. Below it the Columbia turns west through Wallula Gap, between dark basalt walls topped
-- by the two weathered pillars later called the Twin Sisters. Across the river the dry brown
-- Horse Heaven Hills; no trees but the willows at the creek mouth. The ensign is laid over by
-- ui/scene_ambience.gd from the point in scene_ambience.json.
local K = dofile(app.params.kit)
local W, H = 432, 150
local RIVER = 86

K.canvas(W, H, 1841)

K.layer("sky", function()
  K.sky(W, RIVER, {{64, 12, 0.7}, {214, 20, 0.9}, {360, 8, 0.6}}, "sand")
end)

K.layer("hills", function()
  -- Horse Heaven Hills across the Columbia: long, low, treeless and sun-browned
  K.ridge(0, W - 1, RIVER - 2, RIVER + 2, function(x) return 13 + 4 * math.sin(x / 47 + 2) + 2 * math.sin(x / 15) end, "far_hill", "mist", "haze")
  K.ridge(0, 300, RIVER, RIVER + 2, function(x) return 6 + 3 * math.sin(x / 29 + 1) + math.sin(x / 7) end, "clap_sh", "sand", "stone_dk")
  -- Wallula Gap: the basalt walls close in on the right where the river turns west
  local gap = function(x) return 4 + 26 * math.min(1, math.max(0, (x - 290) / 70)) ^ 1.3 + 2 * math.sin(x / 6) end
  K.ridge(286, W - 1, RIVER + 1, RIVER + 2, gap, "roof", "roof_lt", "roof_dk")
  -- flat-lying flows show as stepped rims across the wall, talus aprons beneath
  for x = 290, W - 1 do
    local top = math.floor(RIVER + 1 - gap(x) + 0.5)
    for _, f in ipairs({{RIVER - 20, 2}, {RIVER - 11, 2}}) do
      local y0 = f[1] + math.floor(math.sin(x / 40))
      if y0 > top + 1 then
        K.rect(x, y0, 1, f[2], "roof_dk"); K.px(x, y0 - 1, "stone_dk")
      end
    end
    for y = RIVER - 5, RIVER + 1 do
      if y > top + 1 and K.rnd(3) ~= 0 then K.px(x, y, (K.rnd(3) == 0) and "stone_dk" or ((K.rnd(2) == 0) and "ochre" or "rust")) end
    end
    if top < RIVER - 8 and (x % 7 == 0) then K.px(x, top + 2 + K.rnd(4), "ink") end
  end
  -- the two pillars on the rim, weathered out of the topmost flow
  for _, p in ipairs({{372, 5, 13}, {386, 4, 17}}) do
    local cx, hw, h = p[1], p[2], p[3]
    local base = math.floor(RIVER + 1 - gap(cx) + 0.5) + 1
    local l, r = 0, 0
    for y = base - h, base do
      local t = (y - (base - h)) / h
      -- ragged columns: rounded heads, a waist, and a scree skirt at the foot
      local w = hw - ((t < 0.15) and 2 or 0) + ((t > 0.8) and math.floor((t - 0.8) * 20) or 0)
      if K.rnd(3) == 0 then l = K.rnd(3) - 1 end
      if K.rnd(3) == 0 then r = K.rnd(3) - 1 end
      local a, b = cx - w + l, cx + w + r
      K.rect(a, y, b - a, 1, "roof")
      K.px(a, y, "roof_lt"); K.px(a + 1, y, "roof_lt")
      K.rect(b - 2, y, 2, 1, "roof_dk")
      if K.rnd(5) == 0 then K.px(a + 2 + K.rnd(math.max(1, b - a - 4)), y, "roof_dk") end
    end
  end
end)

K.layer("river", function()
  -- the Columbia, broad and clear, running across the picture into the gap
  K.rect(0, RIVER, W, 16, "blue")
  K.rect(0, RIVER, W, 1, "light_blue")
  for y = RIVER + 1, RIVER + 15 do
    for x = 0, W - 1 do
      if (y < RIVER + 4 and (x + y) % 2 == 0) or ((x * 7 + y * 11) % 29 == 0) then K.px(x, y, "sky_top") end
    end
  end
  for i = 1, 90 do
    local x, y = K.rnd(W), RIVER + 3 + K.rnd(12)
    K.rect(x, y, 1 + K.rnd(4), 1, (K.rnd(7) == 0) and "white" or "light_blue")
  end
end)

K.layer("bench", function()
  -- the sandy bench the post stands on, sloping down to a gravel shore
  K.poly({{0, 104}, {120, 101}, {260, 103}, {431, 100}, {431, 150}, {0, 150}}, "sand")
  K.poly({{0, 102}, {120, 99}, {260, 101}, {431, 98}, {431, 101}, {260, 104}, {120, 102}, {0, 105}}, "clap_sh")
  for x = 0, W - 1 do if K.rnd(3) == 0 then K.px(x, 101 + math.floor(math.sin(x / 9)), "stone") end end
  -- low dunes of drifting sand
  for _, d in ipairs({{300, 122, 46, 5}, {396, 114, 40, 4}, {40, 140, 60, 5}}) do
    K.ellipse(d[1], d[2], d[3], d[4], "cream")
    K.ellipse(d[1] + 6, d[2] + 2, d[3] - 8, d[4] - 2, "sand")
    K.rect(d[1] - d[3] + 6, d[2] + d[4] - 1, d[3] * 2 - 12, 1, "clap_sh")
  end
  -- the Walla Walla coming in at the left foreground, willows at its mouth
  K.river(K.smooth({{-10, 136, 7}, {40, 128, 5}, {70, 118, 4}, {58, 110, 3}, {80, 103, 3}}, 10), "clap_sh")
  for _, p in ipairs({{12, 128}, {34, 122}, {86, 118}, {50, 108}, {96, 106}, {66, 101}}) do K.willow(p[1], p[2], 1) end
  for i = 1, 900 do
    local x, y = K.rnd(W), 102 + K.rnd(48)
    local c = K.at(x, y)
    if c == "sand" or c == "cream" then K.px(x, y, ({"gold", "clap_sh", "cream", "sand"})[i % 4 + 1]) end
  end
  for i = 1, 40 do
    local x, y = K.rnd(W), 108 + K.rnd(42)
    local c = K.at(x, y)
    if c == "sand" or c == "gold" or c == "cream" or c == "clap_sh" then K.sage(x, y) end
  end
  -- the road down from the Blue Mountains to the gate
  local road = K.smooth({{440, 148, 7}, {360, 140, 5}, {290, 128, 4}, {250, 118, 3}, {226, 112, 2}}, 10)
  K.ribbon(road, "clap_sh", 1)
  K.ribbon(road, "cream", -1)
end)

K.layer("fort", function()
  -- seen from the landward side, corner-on: the long south wall sunlit, the east wall in shade
  local x0, x1, top, foot = 150, 268, 92, 113
  -- side wall running back toward the river
  K.poly({{x1, top}, {x1 + 40, top - 6}, {x1 + 40, foot - 9}, {x1, foot}}, "ochre")
  K.line(x1, top, x1 + 40, top - 6, "sand")
  for i = 1, 2 do K.line(x1, top + i * 7, x1 + 40, top - 6 + i * 6, "rust") end
  -- roofs of the trade store and men's houses inside
  K.poly({{170, top - 1}, {175, top - 7}, {214, top - 7}, {218, top - 1}}, "roof"); K.line(175, top - 7, 214, top - 7, "roof_lt")
  K.poly({{226, top - 1}, {229, top - 5}, {262, top - 5}, {264, top - 1}}, "roof_dk")
  K.rect(200, top - 12, 3, 5, "brick"); K.px(200, top - 13, "brick_lt")
  -- the long adobe wall: mud brick courses, eroded coping, rain streaks
  K.rect(x0, top, x1 - x0, foot - top, "sand")
  K.rect(x0, top - 1, x1 - x0, 2, "cream")
  for y = top + 3, foot - 2, 3 do
    for x = x0, x1 - 1 do if (x + y * 3) % 11 == 0 then K.px(x, y, "clap_sh") end end
  end
  for i = 1, 140 do K.px(x0 + K.rnd(x1 - x0), top + 2 + K.rnd(foot - top - 3), (K.rnd(3) == 0) and "clap_sh" or "gold") end
  for x = x0 + 3, x1 - 3, 7 do if K.rnd(2) == 0 then K.rect(x, top + 1, 1, 3 + K.rnd(6), "clap_sh") end end
  K.rect(x0, foot - 1, x1 - x0, 1, "ochre")
  -- landward wicket gate
  K.rect(214, foot - 13, 12, 13, "deep"); K.rect(215, foot - 12, 10, 12, "wood")
  K.rect(219, foot - 12, 1, 12, "deep"); K.rect(213, foot - 14, 14, 1, "ink")
  -- far bastion at the river corner, small with distance
  K.rect(x1 + 34, top - 22, 14, 24, "clap_sh"); K.rect(x1 + 41, top - 21, 7, 23, "ochre")
  K.rect(x1 + 33, top - 24, 16, 2, "wood")
  K.rect(x1 + 37, top - 15, 2, 3, "deep")
  -- near bastion: square, two storeys, loopholes and a pole-and-earth roof
  local bx, by = 128, 66
  K.rect(bx, by, 26, foot + 2 - by, "sand")
  K.rect(bx + 18, by, 8, foot + 2 - by, "clap_sh")
  K.rect(bx - 1, by - 2, 28, 3, "wood"); K.rect(bx - 1, by - 2, 28, 1, "ochre")
  for _, p in ipairs({{bx + 5, by + 8}, {bx + 13, by + 8}, {bx + 5, by + 28}, {bx + 13, by + 28}, {bx + 21, by + 18}}) do K.rect(p[1], p[2], 2, 3, "ink") end
  K.rect(bx, by + 22, 26, 1, "clap_sh")
  for i = 1, 70 do K.px(bx + K.rnd(18), by + 3 + K.rnd(foot - by - 4), (K.rnd(2) == 0) and "gold" or "clap_sh") end
  K.shadow(bx - 3, foot + 3, 32); K.shadow(x0, foot + 1, x1 - x0)
  -- flagstaff; the ensign flies from (141, 42) in scene_ambience.json
  K.rect(140, 42, 1, 22, "deep"); K.px(140, 41, "gold")
end)

K.layer("travelers", function()
  -- an Indian lodge of mats by the creek; trade with the Walla Wallas and Cayuses
  local lx, ly = 104, 127
  K.poly({{lx - 12, ly}, {lx, ly - 18}, {lx + 12, ly}}, "ochre")
  K.poly({{lx, ly - 18}, {lx + 12, ly}, {lx + 3, ly}}, "rust")
  for y = ly - 14, ly - 2, 4 do K.line(lx - (ly - y) * 0.6 + 1, y, lx + (ly - y) * 0.6 - 1, y, "wood") end
  K.line(lx - 2, ly - 22, lx + 2, ly - 16, "deep"); K.line(lx + 2, ly - 22, lx - 2, ly - 16, "deep")
  K.rect(lx - 2, ly - 7, 4, 7, "deep")
  K.shadow(lx - 13, ly + 1, 27)
  K.person(124, 130, "red", "deep")
  -- a wagon come down from the Blue Mountains, the team pulling toward the gate
  K.wagon(318, 140, -1)
  K.team(300, 139, -1, {"red"}, {"light", true})
  K.person(372, 144, "blue", "roof")
  K.person(258, 128, "teal", "bonnet", true)
end)

K.save("location_fort_walla_walla")

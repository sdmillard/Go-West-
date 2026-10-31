-- Ending pictures (432x150 each), shown when a journey ends short of or instead of Oregon.
--   location_ending_post            settled at a trading post: hands and squatters camped by its wall
--   location_ending_cabin           settled in the party's own cabin in timber country
--   location_ending_run_off         run off: the party walking away with what it can carry
--   location_ending_east            turned back: the wagon heading east for the Missouri settlements
--   location_ending_lost            the journey lost: a lone grave beside the road at dusk
--   location_ending_homestead_east  settled in Missouri: a clearing in the hardwoods, worm fence and corn
--   location_ending_homestead_west  settled at the edge of the Willamette settlements: a clearing in the firs
-- ui/main.gd picks one from state.status and state.settled (see docs/CABINS_AND_ENDINGS.md).
local K = dofile(app.params.kit)
local W, H = 432, 150

local function smoke(x, y, n)
  for i = 0, n do
    local sx = x + math.floor(3 * math.sin(i / 2.2) + i * 0.6)
    local c = (i < n / 3) and "stone" or ((i < n * 2 / 3) and "stone_lt" or "mist")
    K.px(sx, y - i * 2, c); K.px(sx + 1, y - i * 2, c)
    if i % 3 == 0 then K.px(sx - 1, y - i * 2 - 1, c) end
  end
end

local function stump(x, y)
  K.rect(x, y - 3, 4, 3, "wood"); K.rect(x, y - 3, 4, 1, "sand"); K.px(x + 1, y - 3, "ochre"); K.px(x + 3, y - 1, "deep")
end

-- a zigzag split-rail (worm) fence running along the ground from x0 to x1
local function worm_fence(x0, x1, y)
  for x = x0, x1 - 8, 8 do
    for r = 0, 2 do
      K.line(x, y - 2 - r * 3, x + 8, y - 4 - r * 3, (r % 2 == 0) and "wood" or "ochre")
    end
    K.rect(x, y - 10, 1, 10, "deep")
  end
end

local function bundle(x, y)
  -- a traveler with a blanket roll on the back
  K.rect(x - 3, y - 12, 3, 5, "stone_dk"); K.rect(x - 3, y - 12, 3, 1, "stone_lt")
end

local function grass_ground(top, base, a, b)
  K.rect(0, top, W, H - top, base)
  for y = top, H - 1 do
    for x = 0, W - 1 do
      if K.rnd(6) == 0 then K.px(x, y, (K.rnd(2) == 0) and a or b) end
    end
  end
end

---------------------------------------------------------------- settled at a post
K.canvas(W, H, 1849)
K.layer("sky", function() K.sky(W, 87, {{70, 14, 0.9}, {300, 10, 0.7}}, "sand") end)
K.layer("land", function()
  K.ridge(0, W - 1, 82, 86, function(x) return 12 + 5 * math.sin(x / 37 + 1) + 2 * math.sin(x / 11) end, "far_hill", "mist", "haze")
  grass_ground(86, "sand", "clap_sh", "sage")
  for i = 1, 60 do local x, y = K.rnd(W), 96 + K.rnd(54); K.sage(x, y) end
end)
K.layer("post", function()
  -- the adobe wall and bastion of the post, the gate open
  local x0, x1, top, foot = 250, 432, 70, 104
  K.rect(x0, top, x1 - x0, foot - top, "sand"); K.rect(x0, top - 1, x1 - x0, 2, "cream")
  for y = top + 3, foot - 2, 3 do for x = x0, x1 - 1 do if (x + y * 3) % 11 == 0 then K.px(x, y, "clap_sh") end end end
  for i = 1, 160 do K.px(x0 + K.rnd(x1 - x0), top + 2 + K.rnd(foot - top - 3), (K.rnd(2) == 0) and "gold" or "clap_sh") end
  K.rect(350, foot - 18, 18, 18, "deep"); K.rect(352, foot - 16, 6, 16, "wood"); K.rect(361, foot - 16, 6, 16, "wood")
  local bx = 262
  K.rect(bx, top - 22, 24, foot - top + 22, "sand"); K.rect(bx + 17, top - 22, 7, foot - top + 22, "clap_sh")
  K.rect(bx - 1, top - 24, 26, 3, "wood")
  for _, p in ipairs({{bx + 5, top - 14}, {bx + 13, top - 14}, {bx + 5, top + 4}}) do K.rect(p[1], p[2], 2, 3, "ink") end
  K.rect(bx + 11, top - 46, 1, 22, "deep")
  K.rect(bx + 12, top - 45, 12, 7, "red"); K.rect(bx + 12, top - 45, 12, 1, "white"); K.rect(bx + 12, top - 42, 12, 1, "white")
  K.shadow(x0, foot + 1, x1 - x0)
end)
K.layer("camp", function()
  -- the party's lean-to of poles and wagon cover against the wall, the wagon box beside it
  local lx = 300
  K.poly({{lx, 104}, {lx + 4, 82}, {lx + 40, 82}, {lx + 44, 104}}, "cream")
  K.poly({{lx + 30, 104}, {lx + 36, 82}, {lx + 40, 82}, {lx + 44, 104}}, "sand")
  K.rect(lx + 14, 92, 12, 12, "deep")
  for _, px_ in ipairs({lx + 2, lx + 42}) do K.rect(px_, 80, 1, 25, "wood") end
  K.wagon(186, 116, 1)
  K.rect(232, 112, 12, 2, "wood") -- tongue down on the ground
  -- a fire with a kettle on a tripod
  local fx = 260
  K.line(fx - 5, 118, fx, 106, "deep"); K.line(fx + 5, 118, fx, 106, "deep")
  K.rect(fx - 2, 112, 4, 3, "ink"); K.rect(fx - 3, 117, 7, 2, "ochre"); K.px(fx, 116, "gold"); K.px(fx - 1, 116, "red")
  smoke(fx, 104, 14)
  -- hands at work: one splitting firewood, one carrying a bale for the post, one at the washing line
  K.person(150, 128, "rust", "deep")
  K.rect(146, 126, 6, 3, "wood"); K.line(153, 113, 156, 109, "wood"); K.rect(155, 108, 3, 2, "stone_dk")
  K.person(330, 124, "blue", "roof"); K.rect(333, 106, 7, 5, "sand"); K.rect(333, 106, 7, 1, "cream")
  K.line(100, 102, 136, 104, "stone"); K.rect(100, 100, 1, 18, "wood"); K.rect(136, 102, 1, 16, "wood")
  for _, c in ipairs({{106, "white"}, {114, "teal"}, {123, "cream"}}) do K.rect(c[1], 103, 5, 7, c[2]) end
  K.person(118, 124, "teal", "bonnet", true)
  -- the oxen grazing out on the flat
  K.ox(60, 112, 1, "red"); K.ox(30, 118, -1, "dark")
end)
K.save("location_ending_post")

---------------------------------------------------------------- settled in the party's own cabin
K.canvas(W, H, 1850)
K.layer("sky", function() K.sky(W, 91, {{120, 12, 0.8}, {330, 18, 1.0}}, "mist") end)
K.layer("woods", function()
  K.ridge(0, W - 1, 78, 82, function(x) return 16 + 7 * math.sin(x / 47 + 2) + 2 * math.sin(x / 9) end, "far_hill", "mist", "haze")
  for x = 0, W - 1, 7 do K.conifer(x + K.rnd(4), 92, 20 + K.rnd(10), "teal", "haze", "far_hill") end
  grass_ground(90, "grass", "leaf", "sage")
  for x = -4, W, 13 do if x < 150 or x > 330 then K.conifer(x + K.rnd(6), 104 + K.rnd(6), 36 + K.rnd(16), "ink", "pine", "leaf") end end
end)
K.layer("clearing", function()
  K.ellipse(240, 122, 110, 18, "sage")
  for i = 1, 300 do local x, y = 130 + K.rnd(220), 106 + K.rnd(34); if K.at(x, y) == "sage" then K.px(x, y, (K.rnd(2) == 0) and "grass" or "ochre") end end
  for _, s in ipairs({{150, 130}, {176, 140}, {300, 136}, {330, 126}, {200, 112}, {280, 110}}) do stump(s[1], s[2]) end
  K.log_cabin(210, 118, 54, 21)
  smoke(260, 80, 22)
  -- woodpile and chopping block, the wagon box turned into a shed
  for i = 0, 3 do K.rect(272, 116 - i * 2, 14 - i * 2, 2, (i % 2 == 0) and "wood" or "ochre") end
  K.rect(186, 114, 7, 4, "wood"); K.rect(186, 114, 7, 1, "sand"); K.line(190, 113, 194, 108, "wood")
  K.rect(120, 120, 34, 10, "blue"); K.rect(120, 120, 34, 1, "light_blue"); K.rect(118, 116, 38, 4, "cream")
  K.person(228, 126, "teal", "bonnet", true)
  K.person(200, 128, "rust", "deep")
  K.person(246, 130, "blue", "roof")
  worm_fence(290, 360, 132)
end)
K.save("location_ending_cabin")

---------------------------------------------------------------- run off
K.canvas(W, H, 1851)
K.layer("sky", function()
  K.rect(0, 0, W, 28, "storm"); K.blend(0, 28, W, "storm", "storm_lt")
  K.rect(0, 31, W, 30, "storm_lt"); K.blend(0, 61, W, "storm_lt", "stone")
  K.rect(0, 64, W, 26, "stone")
end)
K.layer("land", function()
  K.ridge(0, W - 1, 86, 90, function(x) return 10 + 4 * math.sin(x / 33) + math.sin(x / 7) end, "storm", "storm_lt", "storm_dk")
  grass_ground(90, "sage", "stone_dk", "ochre")
  local road = K.smooth({{-10, 140, 8}, {120, 128, 6}, {240, 116, 4}, {340, 104, 2}, {440, 96, 1}}, 12)
  K.ribbon(road, "silt", 1); K.ribbon(road, "silt_lt", 0)
end)
K.layer("left behind", function()
  -- the camp they were made to leave: a bare lean-to, the fire out, a kettle on its side
  local cx = 330
  K.poly({{cx, 104}, {cx + 6, 86}, {cx + 34, 86}, {cx + 40, 104}}, "wood")
  K.poly({{cx + 4, 104}, {cx + 8, 90}, {cx + 32, 90}, {cx + 36, 104}}, "ink")
  for xx = cx + 2, cx + 38, 4 do K.line(xx, 104, xx + 2, 86, "ox") end
  K.rect(cx - 16, 106, 8, 2, "stone_dk"); K.px(cx - 13, 105, "ink"); K.px(cx - 11, 106, "stone")
  K.rect(cx + 50, 104, 5, 3, "ink")
  K.shadow(cx - 2, 105, 44)
end)
K.layer("party", function()
  -- the party trudging away down the road with what they can carry, heads down
  for i, p in ipairs({{92, "rust", "deep"}, {112, "teal", "bonnet", true}, {130, "blue", "roof"}, {150, "red", "bonnet", true}}) do
    local y = 132 - i * 2
    K.person(p[1], y, p[2], p[3], p[4])
    bundle(p[1], y)
  end
  -- a handcart with the last of their goods
  local hx = 58
  K.rect(hx, 124, 22, 6, "wood"); K.rect(hx, 124, 22, 1, "ochre")
  K.rect(hx + 3, 118, 8, 6, "cream"); K.rect(hx + 12, 120, 6, 4, "stone_dk")
  K.wheel(hx + 11, 131, 4)
  K.line(hx + 22, 126, hx + 32, 122, "wood")
  K.person(hx + 34, 134, "ochre", "deep")
end)
K.save("location_ending_run_off")

---------------------------------------------------------------- turned back east
K.canvas(W, H, 1852)
K.layer("sky", function()
  -- morning, the sun low ahead in the east (left)
  K.sky(W, 89, {{200, 16, 1.0}, {360, 10, 0.7}}, "cream")
  K.ellipse(40, 82, 26, 10, "sand"); K.ellipse(40, 82, 18, 8, "cream")
  K.ellipse(40, 80, 7, 7, "white")
end)
K.layer("prairie", function()
  K.ridge(0, W - 1, 86, 88, function(x) return 3 + 2 * math.sin(x / 41) end, "haze", "mist", "far_hill")
  -- the timber line of the Missouri bottoms and settlement smoke far ahead
  for x = 0, 120, 3 do
    local h = 4 + math.floor(2 * math.sin(x / 5))
    K.rect(x, 86 - h, 3, h, (x % 2 == 0) and "far_hill" or "haze")
  end
  smoke(30, 80, 10); smoke(70, 82, 8)
  grass_ground(88, "grass", "gold", "leaf")
  local road = K.smooth({{-10, 96, 1}, {100, 104, 3}, {220, 118, 5}, {340, 132, 8}, {450, 146, 10}}, 12)
  K.ribbon(road, "silt", 1); K.ribbon(road, "silt_lt", 0)
end)
K.layer("wagon", function()
  -- the wagon and team facing east, a walker leading, the dust behind them
  K.wagon(236, 128, -1)
  K.team(190, 127, -1, {"dark"}, {"red", true})
  K.person(170, 128, "rust", "deep")
  K.person(290, 134, "teal", "bonnet", true)
  for i = 1, 80 do local x, y = 286 + K.rnd(60), 116 + K.rnd(16); K.px(x, y, (K.rnd(2) == 0) and "silt_lt" or "cream") end
end)
K.save("location_ending_east")

---------------------------------------------------------------- the journey lost
K.canvas(W, H, 1853)
K.layer("sky", function()
  -- dusk: the light going out of the west behind the grave
  K.rect(0, 0, W, 30, "roof"); K.blend(0, 30, W, "roof", "brick_dk")
  K.rect(0, 33, W, 20, "brick_dk"); K.blend(0, 53, W, "brick_dk", "brick")
  K.rect(0, 56, W, 16, "brick"); K.blend(0, 72, W, "brick", "ochre")
  K.rect(0, 75, W, 10, "ochre"); K.blend(0, 85, W, "ochre", "gold")
  K.ellipse(330, 92, 14, 6, "gold"); K.ellipse(330, 92, 10, 4, "cream")
end)
K.layer("land", function()
  -- a lone butte far off and the plain going dark
  K.poly({{60, 92}, {74, 74}, {96, 72}, {110, 92}}, "roof_dk")
  K.ridge(0, W - 1, 90, 92, function(x) return 2 + math.sin(x / 19) end, "roof", "roof_lt", "roof_dk")
  grass_ground(92, "roof", "roof_dk", "roof_lt")
  local road = K.smooth({{-10, 120, 4}, {140, 114, 3}, {300, 104, 2}, {440, 98, 1}}, 12)
  K.ribbon(road, "roof_dk", 1); K.ribbon(road, "roof_lt", 0)
end)
K.layer("grave", function()
  -- the grave beside the road: a long mound piled with stones against wolves, a board at its head
  local gx, gy = 196, 132
  K.ellipse(gx, gy, 24, 5, "ox_dk"); K.ellipse(gx, gy - 2, 22, 4, "ox")
  for i = 1, 40 do
    local x, y = gx - 18 + K.rnd(36), gy - 3 + K.rnd(5)
    K.rect(x, y, 2, 1, (K.rnd(3) == 0) and "stone" or "stone_dk")
  end
  K.rect(gx + 20, gy - 22, 2, 22, "wood"); K.rect(gx + 22, gy - 22, 1, 22, "deep")
  K.rect(gx + 15, gy - 17, 12, 2, "wood"); K.rect(gx + 15, gy - 15, 12, 1, "deep")
  K.px(gx + 18, gy - 21, "gold")
  K.shadow(gx - 22, gy + 4, 50)
  -- a broken wheel left by the road and a few cast-off things
  K.wheel(118, 120, 7)
  K.line(112, 126, 126, 112, "roof")
  K.rect(256, 122, 6, 4, "wood"); K.rect(256, 122, 6, 1, "ochre")
  -- tall grass in the foreground, lit at the tips
  for x = 0, W - 1, 2 do
    local h = 4 + K.rnd(7)
    K.line(x, H - 1, x + K.rnd(3) - 1, H - 1 - h, (K.rnd(4) == 0) and "ochre" or "ox_dk")
  end
end)
K.save("location_ending_lost")

---------------------------------------------------------------- homestead clearings
local function homestead(west, seed, name)
  K.canvas(W, H, seed)
  K.layer("sky", function() K.sky(W, 89, {{90, 10, 0.8}, {270, 20, 0.9}, {400, 12, 0.6}}, "mist") end)
  K.layer("woods", function()
    if west then
      -- Mount Hood far to the east above the forested foothills
      K.poly({{300, 82}, {340, 40}, {350, 38}, {392, 82}}, "far_hill")
      K.poly({{332, 50}, {340, 40}, {350, 38}, {358, 50}, {350, 46}, {344, 52}, {338, 48}}, "white")
      K.ridge(0, W - 1, 80, 84, function(x) return 12 + 5 * math.sin(x / 29) + math.sin(x / 7) end, "teal", "haze", "pine")
    else
      K.ridge(0, W - 1, 82, 84, function(x) return 8 + 3 * math.sin(x / 37) + math.sin(x / 9) end, "far_hill", "mist", "haze")
    end
    grass_ground(88, "grass", "leaf", "sage")
    for x = -6, W + 6, 11 do
      if x < 110 or x > 360 then
        if west then K.conifer(x + K.rnd(5), 104 + K.rnd(8), 40 + K.rnd(18), "ink", "pine", "leaf")
        else K.elm(x + K.rnd(5), 104 + K.rnd(8), 0.8 + K.rnd(4) / 10) end
      end
    end
  end)
  K.layer("clearing", function()
    -- the plowed patch with young corn (east) or wheat stubble (west), stumps still standing in it
    K.poly({{120, 140}, {150, 112}, {290, 112}, {340, 140}}, "dirt_dk")
    for y = 114, 140, 3 do K.line(120 + (140 - y), y, 340 - (140 - y) * 1.5, y, "ox") end
    for i = 1, 90 do
      local x, y = 140 + K.rnd(180), 114 + K.rnd(24)
      if K.at(x, y) == "dirt_dk" or K.at(x, y) == "ox" then
        if west then K.px(x, y, "gold") else K.px(x, y, "leaf"); K.px(x, y - 1, "grass") end
      end
    end
    for _, s in ipairs({{170, 124}, {230, 132}, {290, 120}, {140, 136}}) do stump(s[1], s[2]) end
    if not west then
      -- girdled trees left standing dead in the field, Missouri fashion
      for _, t in ipairs({{200, 116}, {268, 126}}) do
        K.rect(t[1], t[2] - 30, 2, 30, "stone_dk"); K.line(t[1], t[2] - 24, t[1] - 6, t[2] - 32, "stone_dk"); K.line(t[1] + 1, t[2] - 18, t[1] + 7, t[2] - 26, "stone_dk")
      end
    end
    worm_fence(110, 360, 144)
    K.log_cabin(48, 116, 50, 20)
    smoke(93, 80, 18)
    K.person(108, 122, "teal", "bonnet", true)
    K.person(250, 128, "rust", "deep")
    K.ox(260, 124, 1, "dark"); K.line(250, 118, 258, 120, "wood")
    K.rect(372, 116, 30, 8, "blue"); K.rect(372, 116, 30, 1, "light_blue"); K.wheel(378, 126, 5); K.wheel(396, 126, 5)
  end)
  K.save(name)
end
homestead(false, 1854, "location_ending_homestead_east")
homestead(true, 1855, "location_ending_homestead_west")

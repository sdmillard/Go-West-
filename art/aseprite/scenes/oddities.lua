-- Unhinged mode place pictures (432x150 each), shown while the place's choice is open.
-- no seasons: these places do not change with the year, which is part of the joke.
--   event_taco_hut       a purple and yellow stucco taco restaurant on the Kansas prairie
--   event_prairie_light  a white lighthouse on the dry Platte plain, lamp lit
--   event_onyx_sphere    a colossal polished black sphere on the salt flats, party tiny below it
--   event_beached_ship   a three-masted ship upright in the grass, crew lowering a boat
--   event_cul_de_sac     a paved circle of 1990s houses with green lawns in sage country
--   event_laundromat     a glass-fronted 24-hour laundromat beside the soda springs
--   event_round_hole     a perfectly round black hole in Snake River sage plain
--   event_traffic_light  a red traffic light on a wire across the trail at South Pass
-- Drawn as plainly as any fort or ford: no winks, no glow effects beyond what a lamp gives.
local K = dofile(app.params.kit)
local W, H = 432, 150

local function grass_ground(top, base)
  K.rect(0, top, W, H - top, base or "grass")
  for y = top, H - 1 do for x = 0, W - 1 do if K.rnd(6) == 0 then K.px(x, y, ({"leaf", "gold", "sage"})[K.rnd(3) + 1]) end end end
end
local function sage_ground(top)
  K.rect(0, top, W, H - top, "sand")
  for y = top, H - 1 do for x = 0, W - 1 do if K.rnd(7) == 0 then K.px(x, y, ({"clap_sh", "stone", "ochre", "sage"})[K.rnd(4) + 1]) end end end
  for i = 1, 60 do K.sage(K.rnd(W), top + 6 + K.rnd(H - top - 6)) end
end
local function road(pts, a, b)
  local r = K.smooth(pts, 12); K.ribbon(r, a or "silt", 1); K.ribbon(r, b or "silt_lt", 0)
end
local function party(x, y)
  K.wagon(x, y, 1); K.team(x + 48, y - 1, 1, {"dark"}, {"light", true})
end

---------------------------------------------------------------- Taco Hut
K.canvas(W, H, 2201)
K.layer("country", function()
  K.sky(W, 86, {{40, 14, 0.9}, {330, 20, 1.1}}, "mist")
  K.ridge(0, W - 1, 84, 88, function(x) return 4 + 2 * math.sin(x / 47) end, "far_hill", "mist", "haze")
  grass_ground(88, "grass")
  road({{-10, 140, 6}, {140, 132, 5}, {300, 126, 4}, {440, 120, 3}})
end)
K.layer("building", function()
  -- paved lot in front, lying flat: painted stall lines slant away from us
  K.poly({{190, 104}, {402, 104}, {414, 124}, {180, 124}}, "asphalt")
  K.rect(190, 104, 212, 1, "asphalt_lt")
  for x = 204, 392, 20 do K.line(x, 106, x - 3, 113, "cream") end
  for i = 1, 60 do K.px(190 + K.rnd(220), 105 + K.rnd(18), "asphalt_lt") end
  K.rect(180, 124, 234, 1, "stone")
  -- low stucco block with a mission-style parapet; its east end turned away in shade
  K.rect(214, 74, 140, 32, "hut_purple")
  K.rect(214, 74, 140, 2, "hut_purple_lt")
  K.poly({{354, 74}, {364, 70}, {364, 102}, {354, 106}}, "hut_purple_dk")
  K.poly({{214, 74}, {224, 70}, {364, 70}, {354, 74}}, "hut_yellow")
  K.poly({{232, 74}, {246, 62}, {274, 62}, {288, 74}}, "hut_yellow")
  K.rect(246, 62, 28, 1, "white")
  K.rect(214, 98, 140, 8, "hut_yellow")
  -- windows with the lights on, a glass door
  for _, x in ipairs({222, 300, 324}) do K.rect(x, 82, 20, 12, "glass"); K.rect(x, 82, 20, 1, "white"); K.rect(x + 9, 82, 1, 12, "hut_purple_dk") end
  K.rect(258, 82, 12, 16, "glass"); K.rect(263, 82, 1, 16, "ink")
  -- the sign on a pole: TACO HUT in block letters (3x5 font)
  K.rect(388, 50, 2, 56, "storm_dk")
  K.rect(366, 34, 48, 18, "hut_purple_dk"); K.rect(367, 35, 46, 16, "hut_yellow")
  local font = {T = {"111","010","010","010","010"}, A = {"010","101","111","101","101"}, C = {"111","100","100","100","111"},
    O = {"111","101","101","101","111"}, H = {"101","101","111","101","101"}, U = {"101","101","101","101","111"}}
  local function word(s, x, y)
    for i = 1, #s do
      local g = font[s:sub(i, i)]
      for r = 1, 5 do for c = 1, 3 do if g[r]:sub(c, c) == "1" then K.px(x + (i - 1) * 4 + c - 1, y + r - 1, "hut_purple_dk") end end end
    end
  end
  word("TACO", 382, 37); word("HUT", 384, 44)
  -- a speaker post by the drive
  K.rect(196, 96, 2, 10, "storm"); K.rect(193, 90, 8, 6, "hut_purple"); K.rect(194, 91, 6, 4, "storm_dk")
end)
K.layer("figures", function()
  party(70, 136)
  K.person(176, 128, "blue", "roof"); K.person(186, 127, "teal", "bonnet", true)
end)
K.save("event_taco_hut")

---------------------------------------------------------------- the light on the plain
K.canvas(W, H, 2202)
K.layer("country", function()
  K.sky(W, 90, {{60, 18, 1.0}, {250, 10, 0.8}}, "sand")
  K.ridge(0, W - 1, 88, 92, function(x) return 6 + 3 * math.sin(x / 29 + 2) end, "far_hill", "mist", "haze")
  grass_ground(92, "gold")
  road({{-10, 142, 6}, {160, 134, 5}, {320, 126, 4}, {440, 122, 3}})
end)
K.layer("light", function()
  -- keeper's cottage
  K.rect(300, 96, 30, 16, "white"); K.side_wall(330, 112, 8, 16, "clap_sh", "clap_sh")
  K.gable_roof(298, 96, 34, 9)
  K.door(312, 112, 10)
  -- tapering white tower with a red band, gallery and lantern
  K.poly({{258, 112}, {286, 112}, {280, 36}, {264, 36}}, "white")
  K.poly({{276, 112}, {286, 112}, {280, 36}, {275, 36}}, "stone_lt")
  K.poly({{262, 76}, {282, 76}, {281, 66}, {263, 66}}, "signal_red")
  K.rect(258, 32, 28, 3, "ink"); K.rect(260, 31, 24, 1, "storm")
  K.rect(264, 22, 16, 10, "glass"); K.rect(271, 24, 3, 6, "signal_amber"); K.rect(272, 25, 1, 4, "white")
  K.poly({{262, 22}, {282, 22}, {276, 14}, {268, 14}}, "storm_dk"); K.rect(271, 11, 2, 3, "storm_dk")
  -- the beam, pale, across the sky to the left
  for i = 0, 60 do K.px(262 - i * 3, 26 - math.floor(i / 6), "cream") ; K.px(262 - i * 3, 27 - math.floor(i / 6), "white") end
  K.rect(264, 102, 4, 6, "glass")
  -- a dinghy upturned by the door, oars
  K.poly({{336, 112}, {356, 112}, {353, 108}, {339, 108}}, "teal"); K.line(334, 114, 360, 110, "wood")
end)
K.layer("figures", function()
  party(70, 138)
  K.person(320, 116, "blue", "ink") -- the keeper, in a dark coat
  K.person(176, 132, "rust", "deep")
end)
K.save("event_prairie_light")

---------------------------------------------------------------- the sphere
K.canvas(W, H, 2203)
K.layer("country", function()
  K.sky(W, 100, {{20, 12, 0.8}, {380, 22, 0.7}}, "mist")
end)
K.layer("sphere", function()
  -- the salt flat first, with the far range low on the horizon
  K.ridge(0, W - 1, 98, 102, function(x) return 7 + 4 * math.sin(x / 37) + 2 * math.sin(x / 7) end, "far_hill", "mist", "haze")
  K.rect(0, 102, W, H - 102, "white")
  for y = 102, H - 1 do for x = 0, W - 1 do if K.rnd(9) == 0 then K.px(x, y, "stone_lt") end end end
  for i = 1, 30 do local x, y = K.rnd(W), 106 + K.rnd(40); K.line(x, y, x + 6 + K.rnd(10), y + K.rnd(3) - 1, "stone_lt") end
  -- standing at its foot: only the bottom of the sphere is in the picture, a black curve
  -- rising out of the top of the frame and coming down to touch the salt beside the party
  local R, contact_x, ground = 420, 318, 122
  local cx, cy = contact_x, ground - R
  local function limb(y) local d = R * R - (y - cy) ^ 2; return d > 0 and cx - math.sqrt(d) or nil end
  for y = 0, ground do
    local lx = limb(y)
    if lx then
      for x = math.max(0, math.floor(lx)), W - 1 do
        -- below its equator it faces the ground: the lower it is the more white salt it mirrors
        local nx, ny = (x - cx) / R, (y - cy) / R
        local c = "onyx"
        if ny > 0.985 then c = "storm_dk" elseif ny > 0.97 then c = "onyx_hi" end
        if ny > 0.995 then c = (nx < -0.02) and "storm" or "storm_dk" end
        K.px(x, y, c)
      end
      -- a thin bright line of sky along the limb
      K.px(math.floor(lx), y, "onyx_glint"); K.px(math.floor(lx) + 1, y, "onyx_hi")
    end
  end
  -- the long gleam of the sky running down its curve, a little inside the limb
  for y = 0, 90 do
    local lx = limb(y)
    if lx then
      local t = y / 90
      local w = math.floor(1 + 5 * math.sin(math.pi * t))
      local x0 = math.floor(lx) + 10 + math.floor(8 * t)
      for x = x0, x0 + w do K.px(x, y, (x - x0 > 0 and x - x0 < w and t > 0.25 and t < 0.75) and "onyx_glint" or "onyx_hi") end
    end
  end
  -- the dark wedge of shade where it meets the salt
  for x = contact_x - 60, W - 1 do
    local lx = limb(ground - 1)
    local y = ground + 1 + math.floor(math.max(0, (x - (contact_x - 60)) / 40))
    for yy = ground, math.min(H - 1, y) do if x >= contact_x - 60 then K.px(x, yy, (x > contact_x - 30) and "stone_dk" or "stone") end end
  end
end)
K.layer("figures", function()
  -- the party halted right beside it, at their own size
  party(60, 140)
  K.person(222, 132, "blue", "roof"); K.person(236, 134, "red", "bonnet", true)
  K.person(262, 126, "brick", "rust") -- one gone up close to put a hand on it
end)
K.save("event_onyx_sphere")

---------------------------------------------------------------- the ship on the Platte
K.canvas(W, H, 2204)
K.layer("country", function()
  K.sky(W, 82, {{100, 14, 1.0}, {300, 22, 0.8}}, "sand")
  K.ridge(0, W - 1, 80, 84, function(x) return 8 + 4 * math.sin(x / 23 + 1) end, "far_hill", "mist", "haze")
  grass_ground(84, "gold")
  K.river({{-10, 96, 4}, {140, 92, 5}, {300, 98, 6}, {440, 94, 5}}, "silt", true)
  road({{-10, 142, 6}, {180, 134, 5}, {440, 124, 3}})
end)
K.layer("ship", function()
  -- hull sitting upright in the grass, keel buried
  K.poly({{196, 100}, {356, 100}, {346, 120}, {210, 120}}, "hull")
  K.rect(196, 100, 160, 2, "wood"); K.rect(206, 108, 144, 1, "gold")
  for x = 222, 330, 16 do K.rect(x, 110, 4, 3, "ink") end -- gun ports
  K.poly({{340, 100}, {372, 92}, {370, 96}, {346, 102}}, "hull") -- bowsprit
  -- three masts with furled sails and yards
  for i, m in ipairs({{226, 34}, {276, 22}, {324, 38}}) do
    K.rect(m[1], m[2], 2, 100 - m[2], "wood")
    for _, yy in ipairs({m[2] + 8, m[2] + 26, m[2] + 44}) do
      if yy < 96 then K.rect(m[1] - 16, yy, 34, 1, "wood"); K.rect(m[1] - 14, yy + 1, 30, 2, "sail") end
    end
    K.line(m[1], m[2], m[1] - 30, 100, "deep"); K.line(m[1] + 1, m[2], m[1] + 30, 100, "deep")
  end
  K.rect(276, 16, 10, 5, "signal_red") -- pennant
  -- a boat being lowered onto the grass, sailors with the falls
  K.poly({{360, 126}, {388, 126}, {384, 132}, {364, 132}}, "teal")
  K.line(362, 104, 364, 126, "sand"); K.line(386, 104, 384, 126, "sand")
end)
K.layer("figures", function()
  party(40, 140)
  K.person(150, 132, "blue", "roof")
  for _, p in ipairs({{372, 126}, {396, 134}, {408, 132}}) do K.person(p[1], p[2], "white", "ink") end
end)
K.save("event_beached_ship")

---------------------------------------------------------------- the houses in the sage
K.canvas(W, H, 2205)
K.layer("country", function()
  K.sky(W, 80, {{70, 16, 0.9}, {260, 12, 0.7}}, "sand")
  K.ridge(0, W - 1, 78, 82, function(x) return 12 + 7 * math.sin(x / 31) + 2 * math.sin(x / 9) end, "far_hill", "mist", "haze")
  sage_ground(82)
end)
K.layer("street", function()
  -- the paved road leaves the ruts and ends in a circle
  road({{-10, 144, 6}, {120, 136, 5}, {440, 130, 3}})
  K.poly({{150, 136}, {176, 136}, {196, 118}, {184, 116}}, "asphalt")
  K.ellipse(250, 110, 66, 9, "asphalt"); K.ellipse(250, 110, 18, 3, "lawn")
  K.rect(184, 110, 132, 1, "asphalt_lt")
  -- lawns and houses around the circle, alternating siding
  local houses = {{164, 96, "siding_tan"}, {206, 92, "siding_blue"}, {250, 90, "cream"}, {294, 92, "siding_tan"}, {336, 96, "siding_blue"}}
  for _, h in ipairs(houses) do
    local x, y = h[1], h[2]
    K.rect(x - 4, y, 40, 10, "lawn"); K.dither(x - 4, y + 8, 40, 2, "lawn", "lawn_lt")
    K.rect(x, y - 14, 32, 14, h[3]); K.side_wall(x + 32, y, 5, 14, "clap_sh", "clap_sh")
    K.gable_roof(x - 2, y - 14, 36, 7)
    K.rect(x + 20, y - 10, 10, 10, "asphalt_lt") -- garage door
    K.window(x + 4, y - 11, 6, 5); K.door(x + 12, y, 8)
    K.rect(x + 34, y + 2, 1, 1, "light_blue"); K.px(x + 33, y + 1, "white") -- a sprinkler's spray
  end
  -- a mailbox at the turn
  K.rect(186, 118, 1, 6, "storm"); K.rect(184, 115, 5, 3, "storm_dk")
end)
K.layer("figures", function()
  party(36, 142)
  K.person(140, 136, "rust", "deep"); K.person(150, 137, "teal", "bonnet", true)
end)
K.save("event_cul_de_sac")

---------------------------------------------------------------- the laundromat
K.canvas(W, H, 2206)
K.layer("country", function()
  K.sky(W, 84, {{30, 10, 0.8}, {280, 18, 1.0}}, "mist")
  K.ridge(0, W - 1, 82, 86, function(x) return 14 + 6 * math.sin(x / 26 + 3) end, "far_hill", "mist", "haze")
  sage_ground(86)
  -- the soda springs: pale mineral mounds with a little water
  for _, m in ipairs({{60, 102}, {96, 108}, {140, 100}}) do K.ellipse(m[1], m[2], 12, 4, "stone_lt"); K.ellipse(m[1], m[2] - 1, 4, 1, "light_blue") end
  road({{-10, 144, 6}, {200, 134, 5}, {440, 126, 3}})
end)
K.layer("building", function()
  K.rect(218, 76, 150, 36, "laundro_white")
  K.poly({{368, 76}, {378, 72}, {378, 108}, {368, 112}}, "stone_lt")
  K.rect(214, 72, 158, 5, "storm_dk"); K.poly({{372, 72}, {382, 68}, {382, 72}, {372, 77}}, "storm_dk")
  K.rect(214, 112, 168, 2, "stone") -- a concrete apron
  -- long glass front with the machines inside, round doors in a row
  K.rect(224, 82, 138, 24, "glass")
  for x = 228, 352, 14 do K.rect(x, 92, 12, 12, "laundro_white"); K.ellipse(x + 5, 98, 3, 3, "storm_lt"); K.px(x + 4, 97, "white") end
  K.rect(224, 82, 138, 1, "white")
  -- sign boards: OPEN 24 HOURS suggested by lettering blocks
  K.sign(232, 64, 60, "cream", 18); K.sign(310, 64, 48, "signal_red", 14)
  for _, x in ipairs({240, 284, 318, 350}) do K.rect(x, 68, 1, 4, "storm_dk") end
  K.rect(290, 104, 12, 8, "glass")
end)
K.layer("figures", function()
  party(40, 140)
  K.person(300, 104, "red", "bonnet", true) -- the woman folding, seen through the glass
  K.rect(304, 98, 6, 2, "white")
end)
K.save("event_laundromat")

---------------------------------------------------------------- the hole
K.canvas(W, H, 2207)
K.layer("country", function()
  K.sky(W, 80, {{110, 14, 1.0}, {340, 20, 0.8}}, "sand")
  K.ridge(0, W - 1, 78, 82, function(x) return 6 + 3 * math.sin(x / 41) end, "far_hill", "mist", "haze")
  sage_ground(82)
  for _, b in ipairs({{90, 96}, {380, 100}}) do K.basalt(b[1], b[2], 20, 8) end
  road({{-10, 140, 6}, {200, 132, 5}, {440, 126, 3}})
end)
K.layer("hole", function()
  -- perfectly round, seen at a slant: a dark ellipse with a hard glassy rim
  K.ellipse(280, 112, 26, 8, "stone_lt")
  K.ellipse(280, 112, 24, 7, "ink")
  for x = 258, 302 do K.px(x, 112 + math.floor(7 * math.sqrt(math.max(0, 1 - ((x - 280) / 24) ^ 2))), "white") end
  -- a pebble in the air above it, coming back up
  K.rect(282, 92, 2, 2, "stone_dk")
end)
K.layer("figures", function()
  party(50, 138)
  K.person(244, 116, "blue", "roof"); K.person(254, 117, "red", "deep")
end)
K.save("event_round_hole")

---------------------------------------------------------------- the red light at the pass
K.canvas(W, H, 2208)
K.layer("country", function()
  K.sky(W, 88, {{50, 16, 0.9}, {290, 12, 1.1}}, "mist")
  -- the Wind River peaks off to the north, the pass itself a broad open saddle
  local function top(x) return 62 - 12 * math.sin(x / 53 + 1) - 5 * math.sin(x / 17) - 2 * math.sin(x / 5) end
  K.ridge(0, W - 1, 0, 90, function(x) return -top(x) end, "far_hill", "mist", "haze")
  for x = 0, W - 1 do local t = math.floor(top(x) + 0.5); if t < 56 then for y = t, t + (56 - t) // 2 do K.px(x, y, ((x + y) % 4 == 0) and "mist" or "white") end end end
  K.ridge(0, W - 1, 0, 92, function(x) return -(80 - 3 * math.sin(x / 31)) end, "sage", "haze", "teal")
  sage_ground(90)
  road({{-10, 142, 6}, {200, 128, 5}, {440, 112, 3}})
end)
K.layer("light", function()
  -- two cedar posts and a sagging wire across the road
  K.rect(150, 70, 3, 64, "wood"); K.rect(330, 64, 3, 54, "wood")
  for x = 152, 330 do K.px(x, 72 + math.floor(10 * math.sin((x - 152) / 178 * math.pi)) - math.floor((x - 152) / 30), "ink") end
  -- the signal head hangs at the low point: red lit, amber and green dark
  local x, y = 238, 78
  K.rect(x + 3, y - 4, 1, 4, "ink")
  K.rect(x, y, 8, 22, "hut_yellow"); K.rect(x + 1, y + 1, 6, 20, "storm_dk")
  K.ellipse(x + 3, y + 4, 2, 2, "signal_red"); K.px(x + 2, y + 3, "white")
  K.ellipse(x + 3, y + 10, 2, 2, "signal_off"); K.ellipse(x + 3, y + 16, 2, 2, "signal_off")
  -- the stop line painted across the ruts
  K.rect(186, 132, 40, 1, "white")
end)
K.layer("figures", function()
  party(110, 142)
  K.person(222, 136, "blue", "roof")
end)
K.save("event_traffic_light")

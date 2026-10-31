-- Trail event pictures (432x150 each), shown while the event's choice is open.
--   event_bandits          road agents stopping the wagon in broken sage country
--   event_cayuse_riders    Cayuse horsemen watching the train from a ridge during the war of 1848
--   event_waiilatpu_ruins  the burned Whitman mission at Waiilatpu, a year after November 1847
--   event_horse_thieves    a night raid on the picket line, the stock driven off
--   event_war_volunteers   Oregon volunteer riflemen met on the road, the 1848 campaign
--   event_wagon_fire       a wagon cover alight in camp, the party fighting it
--   event_posse            a Missouri sheriff's posse riding the party down near the line
--   event_regulators       armed regulators blocking the road, a coil of rope among them
--   event_bounty_hunters   hard men with a handbill waiting at a camp
-- Figures stay plain at this scale; no caricature, no warbonnets or war paint as shorthand.
local K = dofile(app.params.kit)
local W, H = 432, 150

local HORSE = {bay = {"ox", "ox_dk", "ink"}, chestnut = {"rust", "ox", "brick_dk"}, gray = {"stone_lt", "stone", "stone_dk"},
  dun = {"gold", "ochre", "deep"}, black = {"roof", "roof_dk", "ink"}, pinto = {"white", "stone", "ox_dk"}}
-- a horse side-on, 22 px long, (x, y) = hind hoof on the ground; optional rider
local function horse(x, y, coat, facing, rider)
  local c = HORSE[coat]
  local function X(dx) return (facing > 0) and (x + dx) or (x + 22 - dx) end
  local function R(dx, dy, w, h, col) K.rect((facing > 0) and (x + dx) or (x + 22 - dx - w + 1), y + dy, w, h, col) end
  R(2, -12, 15, 6, c[1]); R(2, -7, 15, 1, c[2])
  for _, l in ipairs({2, 5, 13, 16}) do R(l, -6, 1, 6, c[2]) end
  R(16, -15, 3, 5, c[1]); R(17, -17, 5, 3, c[1]); R(21, -16, 1, 2, c[3])
  K.px(X(17), y - 18, c[3]); K.px(X(19), y - 16, "ink")
  R(1, -12, 1, 7, c[3]); R(15, -16, 2, 4, c[3])
  if coat == "pinto" then R(5, -11, 5, 3, "ox_dk"); R(12, -10, 3, 2, "ox_dk") end
  K.shadow(x - 1, y + 1, 24)
  if rider then
    -- seated figure: coat, leg down the flank, head and hat, the long gun if any
    R(8, -21, 5, 8, rider.coat); R(9, -14, 2, 5, "deep")
    R(9, -24, 3, 3, rider.skin or "skin"); R(8, -25, 5, 1, rider.hat or "deep"); R(9, -27, 3, 2, rider.hat or "deep")
    if rider.mask then R(9, -23, 3, 1, rider.mask) end
    if rider.gun then K.line(X(6), y - 26, X(14), y - 15, "storm_dk") end
    if rider.rope then K.ellipse(X(7), y - 16, 2, 2, "sand") end
  end
end

local function standing(x, y, coat, hat, opts)
  opts = opts or {}
  K.person(x, y, coat, hat, opts.skirt)
  if opts.gun then K.line(x + 4, y - 16, x + 6, y - 2, "storm_dk") end
  if opts.mask then K.rect(x, y - 12, 3, 1, opts.mask) end
end

local function sage_ground(top)
  K.rect(0, top, W, H - top, "sand")
  for y = top, H - 1 do for x = 0, W - 1 do if K.rnd(7) == 0 then K.px(x, y, ({"clap_sh", "stone", "ochre", "sage"})[K.rnd(4) + 1]) end end end
  for i = 1, 70 do K.sage(K.rnd(W), top + 6 + K.rnd(H - top - 6)) end
end

local function grass_ground(top, base)
  K.rect(0, top, W, H - top, base or "grass")
  for y = top, H - 1 do for x = 0, W - 1 do if K.rnd(6) == 0 then K.px(x, y, ({"leaf", "gold", "sage"})[K.rnd(3) + 1]) end end end
end

local function road(pts, a, b)
  local r = K.smooth(pts, 12); K.ribbon(r, a or "silt", 1); K.ribbon(r, b or "silt_lt", 0)
end

---------------------------------------------------------------- bandits
K.canvas(W, H, 1848)
K.layer("country", function()
  K.sky(W, 84, {{90, 12, 0.8}, {310, 16, 1.0}}, "sand")
  K.ridge(0, W - 1, 82, 86, function(x) return 14 + 7 * math.sin(x / 33 + 1) + 3 * math.sin(x / 9) end, "far_hill", "mist", "haze")
  sage_ground(86)
  road({{-10, 136, 6}, {160, 128, 5}, {300, 118, 3}, {440, 110, 2}})
  for _, b in ipairs({{250, 112, 9, 6}, {300, 108, 7, 5}, {372, 118, 12, 8}}) do K.boulder(b[1], b[2], b[3], b[4]) end
end)
K.layer("holdup", function()
  K.wagon(70, 134, 1); K.team(118, 133, 1, {"dark"}, {"light", true})
  standing(160, 136, "blue", "roof"); standing(62, 140, "teal", "bonnet", {skirt = true})
  -- road agents across the road, kerchiefs up, guns leveled
  horse(240, 128, "black", -1, {coat = "roof", hat = "ink", mask = "red", gun = true})
  horse(270, 122, "bay", -1, {coat = "ox_dk", hat = "deep", mask = "stone_lt", gun = true})
  standing(212, 134, "ox_dk", "ink", {gun = true, mask = "red"})
end)
K.save("event_bandits")

---------------------------------------------------------------- Cayuse riders
K.canvas(W, H, 1849)
K.layer("country", function()
  K.sky(W, 80, {{60, 14, 0.9}, {290, 10, 0.7}}, "mist")
  K.ridge(0, W - 1, 78, 82, function(x) return 16 + 6 * math.sin(x / 41) + math.sin(x / 9) end, "far_hill", "mist", "haze")
  grass_ground(82, "gold")
  -- a long bunchgrass ridge above the road, the riders on its crest
  K.poly({{180, 104}, {240, 86}, {360, 82}, {432, 92}, {432, 108}}, "ochre")
  K.line(240, 86, 360, 82, "sand")
  road({{-10, 140, 6}, {160, 132, 5}, {300, 124, 3}, {440, 118, 2}})
end)
K.layer("riders", function()
  for i, r in ipairs({{256, 88, "pinto"}, {282, 86, "bay"}, {306, 85, "gray"}, {332, 84, "chestnut"}}) do
    horse(r[1], r[2], r[3], -1, {coat = (i % 2 == 0) and "cream" or "ochre", hat = "deep", skin = "skin_dk", gun = (i % 2 == 1)})
  end
  -- the train halted on the road below, people watching
  K.wagon(60, 138, 1); K.team(108, 137, 1, {"red"}, {"dark", true})
  standing(152, 140, "blue", "roof"); standing(170, 138, "rust", "deep", {gun = true}); standing(50, 142, "teal", "bonnet", {skirt = true})
end)
K.save("event_cayuse_riders")

---------------------------------------------------------------- Waiilatpu ruins
K.canvas(W, H, 1850)
K.layer("valley", function()
  K.sky(W, 82, {{100, 10, 0.9}, {320, 18, 1.1}}, "mist")
  K.ridge(0, W - 1, 80, 84, function(x) return 18 + 6 * math.sin(x / 57 + 2) + 2 * math.sin(x / 13) end, "far_hill", "mist", "haze")
  grass_ground(84, "gold")
  -- the mill pond and the line of the Walla Walla River trees
  K.ellipse(360, 104, 40, 5, "blue"); K.ellipse(356, 103, 30, 2, "light_blue")
  for x = 300, 430, 9 do K.willow(x, 96, 0.5) end
end)
K.layer("ruins", function()
  -- the mission house: adobe walls burned out, roof gone, door and window holes black
  local x0, y0 = 120, 118
  for x = x0, x0 + 95 do
    -- adobe walls standing to uneven heights after the fire, the roof gone
    local top = y0 - 22 + math.floor(5 * math.abs(math.sin(x / 7)) + 4 * math.abs(math.sin(x / 19)))
    K.rect(x, top, 1, y0 - top, "sand"); K.px(x, top, "cream")
  end
  for i = 1, 140 do local px_, py = x0 + K.rnd(96), y0 - 14 + K.rnd(14); K.px(px_, py, (K.rnd(2) == 0) and "clap_sh" or "ochre") end
  for _, w in ipairs({{12, 9, 6}, {34, 8, 14}, {58, 9, 6}, {80, 9, 6}}) do K.rect(x0 + w[1], y0 - w[3] - 8, 6, w[3], "ink") end
  for i = 1, 50 do K.px(x0 + K.rnd(96), y0 - 20 + K.rnd(18), "roof_dk") end -- scorching
  K.rect(x0 + 40, y0 - 30, 6, 8, "roof_dk"); K.px(x0 + 41, y0 - 31, "roof")
  -- charred beams fallen across the floor
  K.line(x0 + 20, y0 - 2, x0 + 44, y0 - 10, "ink"); K.line(x0 + 60, y0 - 1, x0 + 80, y0 - 8, "roof_dk")
  K.shadow(x0 - 2, y0 + 1, 100)
  -- the long grave of the dead, a low mound with a rough board
  K.ellipse(268, 130, 22, 3, "ox_dk"); K.ellipse(268, 129, 20, 2, "ox")
  K.rect(290, 116, 2, 14, "wood"); K.rect(286, 120, 10, 2, "wood")
  -- the orchard of young apple trees, untended
  for x = 30, 100, 14 do K.elm(x, 120, 0.45) end
  -- the party, stopped and quiet
  K.wagon(330, 142, -1); standing(318, 144, "blue", "roof"); standing(390, 142, "teal", "bonnet", {skirt = true})
end)
K.save("event_waiilatpu_ruins")

---------------------------------------------------------------- horse thieves (night)
K.canvas(W, H, 1851)
K.layer("night", function()
  K.rect(0, 0, W, 50, "ink"); K.blend(0, 50, W, "ink", "roof_dk"); K.rect(0, 53, W, 30, "roof_dk"); K.blend(0, 83, W, "roof_dk", "storm_dk")
  for i = 1, 60 do K.px(K.rnd(W), K.rnd(70), (K.rnd(4) == 0) and "white" or "stone") end
  K.ellipse(360, 24, 7, 7, "stone_lt"); K.ellipse(358, 23, 6, 6, "white")
  K.ridge(0, W - 1, 84, 88, function(x) return 10 + 4 * math.sin(x / 37) + math.sin(x / 7) end, "storm_dk", "storm", "ink")
  K.rect(0, 88, W, H - 88, "storm_dk")
  for i = 1, 900 do K.px(K.rnd(W), 88 + K.rnd(62), (K.rnd(3) == 0) and "storm" or "roof_dk") end
end)
K.layer("raid", function()
  -- the camp asleep: a dim wagon, the fire down to embers, a picket line cut
  K.wagon(40, 132, 1)
  for x = 60, 92 do if (x % 3) == 0 then K.px(x, 140, "storm") end end
  K.rect(118, 138, 7, 2, "brick_dk"); K.px(121, 137, "gold"); K.px(120, 136, "brick_lt")
  K.line(150, 128, 200, 126, "stone_dk"); K.rect(150, 124, 1, 8, "wood"); K.rect(200, 122, 1, 8, "wood")
  -- the horses driven off at a run by shadowed riders
  for _, h in ipairs({{236, 124, "gray"}, {262, 120, "bay"}, {288, 126, "chestnut"}}) do horse(h[1], h[2], h[3], 1, nil) end
  horse(214, 128, "black", 1, {coat = "ink", hat = "ink", skin = "roof"})
  horse(318, 118, "black", 1, {coat = "ink", hat = "ink", skin = "roof"})
  -- a guard starting up from his blanket
  standing(132, 140, "blue", "roof", {gun = true})
end)
K.save("event_horse_thieves")

---------------------------------------------------------------- war volunteers
K.canvas(W, H, 1852)
K.layer("country", function()
  K.sky(W, 84, {{70, 12, 0.8}, {270, 18, 1.0}}, "mist")
  K.ridge(0, W - 1, 82, 86, function(x) return 16 + 6 * math.sin(x / 47) + math.sin(x / 9) end, "far_hill", "mist", "haze")
  grass_ground(86, "gold")
  road({{-10, 132, 5}, {160, 128, 5}, {300, 122, 3}, {440, 116, 2}})
end)
K.layer("company", function()
  -- the Oregon volunteers in their own clothes, rifles across the saddle, a flag carried at the head
  local riders = {{180, 128, "bay", "rust"}, {206, 126, "chestnut", "blue"}, {232, 124, "gray", "ox_dk"}, {258, 122, "dun", "teal"}, {284, 120, "black", "cream"}, {310, 118, "bay", "red"}}
  for _, r in ipairs(riders) do horse(r[1], r[2], r[3], -1, {coat = r[4], hat = "deep", gun = true}) end
  K.rect(184, 92, 1, 22, "wood"); K.rect(185, 93, 12, 7, "red"); for y = 94, 99, 2 do K.rect(185, y, 12, 1, "white") end; K.rect(185, 93, 5, 3, "blue")
  K.wagon(40, 136, 1); standing(100, 136, "blue", "roof"); standing(120, 134, "teal", "bonnet", {skirt = true})
end)
K.save("event_war_volunteers")

---------------------------------------------------------------- wagon fire
K.canvas(W, H, 1853)
K.layer("camp", function()
  K.sky(W, 86, {{140, 14, 0.9}, {360, 10, 0.7}}, "sand")
  K.ridge(0, W - 1, 84, 88, function(x) return 8 + 3 * math.sin(x / 37) + math.sin(x / 9) end, "far_hill", "mist", "haze")
  grass_ground(88)
end)
K.layer("fire", function()
  local x, y = 170, 132
  K.wagon(x, y, 1)
  -- flames through the bonnet, tongues licking up, smoke rolling off downwind
  for fx = x + 2, x + 44 do
    local reach = 14 + math.floor(12 * math.abs(math.sin(fx / 3.3)) + 6 * math.abs(math.sin(fx / 7.1)))
    for fy = y - 18, y - 18 - reach, -1 do
      local t = (y - 18 - fy) / reach
      if t < 0.8 or K.rnd(3) > 0 then K.px(fx, fy, (t < 0.3) and "white" or ((t < 0.55) and "gold" or ((t < 0.8) and "brick_lt" or "red"))) end
    end
  end
  for i = 1, 40 do K.px(x + 4 + K.rnd(38), y - 20 - K.rnd(14), "ink") end
  for i = 0, 40 do
    local sx, sy = x + 24 + i * 4, y - 58 - i * 1.4 + 4 * math.sin(i / 3)
    K.ellipse(sx, sy, 5 + i / 4, 3 + i / 8, (i < 12) and "storm" or ((i < 26) and "storm_lt" or "stone"))
  end
  -- the party with buckets and a wet blanket, goods dragged clear
  standing(150, 136, "blue", "roof"); K.rect(146, 128, 3, 3, "wood")
  standing(226, 138, "rust", "deep"); K.rect(230, 126, 6, 4, "stone_dk")
  standing(250, 140, "teal", "bonnet", {skirt = true}); K.rect(254, 130, 3, 3, "wood")
  K.crate(110, 140); K.barrel(124, 142)
  K.team(240, 118, 1, {"dark"}, {"light", true})
end)
K.save("event_wagon_fire")

---------------------------------------------------------------- posse
K.canvas(W, H, 1854)
K.layer("country", function()
  K.sky(W, 84, {{90, 14, 0.9}, {330, 12, 0.8}}, "mist")
  K.ridge(0, W - 1, 82, 86, function(x) return 6 + 3 * math.sin(x / 41) end, "far_hill", "mist", "haze")
  for x = 0, 140, 4 do K.elm(x + K.rnd(3), 88, 0.4) end -- the timber of the Missouri border behind
  grass_ground(86)
  road({{-10, 120, 2}, {140, 124, 3}, {300, 132, 5}, {440, 140, 6}})
end)
K.layer("posse", function()
  -- the sheriff in front, deputies spread out behind with shotguns and rifles, riding the party down
  local men = {{150, 126, "black", "roof"}, {124, 120, "bay", "rust"}, {100, 124, "chestnut", "ox_dk"}, {176, 120, "gray", "blue"}, {76, 118, "dun", "cream"}}
  for _, m in ipairs(men) do horse(m[1], m[2], m[3], 1, {coat = m[4], hat = "deep", gun = true}) end
  K.px(160, 102, "gold")
  K.wagon(300, 140, 1); K.team(348, 139, 1, {"dark"}, {"red", true})
  standing(286, 144, "blue", "roof"); standing(392, 142, "teal", "bonnet", {skirt = true})
end)
K.save("event_posse")

---------------------------------------------------------------- regulators
K.canvas(W, H, 1855)
K.layer("country", function()
  K.sky(W, 82, {{60, 10, 0.8}, {260, 16, 1.0}}, "mist")
  K.ridge(0, W - 1, 80, 84, function(x) return 10 + 4 * math.sin(x / 31) + math.sin(x / 7) end, "far_hill", "mist", "haze")
  grass_ground(84)
  road({{-10, 136, 6}, {180, 128, 4}, {320, 120, 3}, {440, 114, 2}})
  for x = 300, 432, 12 do K.elm(x + K.rnd(5), 108, 0.6) end
end)
K.layer("regulators", function()
  -- farmers turned regulators across the road: rifles, a shotgun, one with a coil of rope on his saddle
  horse(232, 128, "bay", -1, {coat = "ox_dk", hat = "deep", gun = true, rope = true})
  horse(260, 122, "dun", -1, {coat = "cream", hat = "roof", gun = true})
  standing(208, 132, "rust", "deep", {gun = true}); standing(288, 126, "stone", "roof", {gun = true}); standing(304, 128, "brick", "deep", {gun = true})
  K.wagon(60, 138, 1); K.team(108, 137, 1, {"red"}, {"light", true})
  standing(156, 138, "blue", "roof"); standing(50, 142, "teal", "bonnet", {skirt = true})
end)
K.save("event_regulators")

---------------------------------------------------------------- bounty hunters
K.canvas(W, H, 1856)
K.layer("country", function()
  K.sky(W, 86, {{120, 12, 0.8}, {340, 8, 0.6}}, "sand")
  K.ridge(0, W - 1, 84, 88, function(x) return 12 + 5 * math.sin(x / 43 + 1) + 2 * math.sin(x / 9) end, "far_hill", "mist", "haze")
  sage_ground(88)
end)
K.layer("hunters", function()
  -- their camp: two horses at a picket, a small fire; one man holds up the handbill with the party's description
  horse(300, 126, "gray", -1, nil); horse(330, 122, "black", -1, nil)
  K.line(296, 116, 360, 112, "stone_dk")
  K.rect(250, 134, 7, 2, "ochre"); K.px(253, 133, "gold"); K.px(252, 132, "red")
  standing(232, 136, "roof", "ink", {gun = true})
  standing(268, 134, "ox_dk", "deep"); K.rect(264, 120, 6, 8, "cream"); K.rect(265, 122, 4, 1, "ink"); K.rect(265, 124, 4, 1, "stone_dk"); K.rect(265, 126, 3, 1, "stone_dk")
  standing(212, 138, "storm", "roof", {gun = true})
  -- the party's wagon pulling up on the road
  K.wagon(40, 138, 1); K.team(88, 137, 1, {"dark"}, {"light", true})
  standing(140, 140, "blue", "roof")
end)
K.save("event_bounty_hunters")

-- Native community visit scenes (432x150 each), following docs/NATIVE_ENCOUNTER_ART_BRIEF.md
-- and the notes in data/native_encounters.json. Original compositions of everyday work:
-- trading provisions, handling horses, piloting water, carrying loads. Clothing stays plain at
-- this scale; no tipis as shorthand, no warbonnets, no ceremonial or sacred designs, no later
-- reservation buildings. Same figure treatment as the approved Wasco scene (encounter_wasco.lua).
--   encounter_platte         Pawnee families traveling the Platte, provisions on pack horses
--   encounter_fort_hall      Northern Shoshone and Bannock families near the private trading post
--   encounter_grande_ronde   Nez Perce owners and their horses in the valley grass
--   encounter_umatilla       Umatilla families by their gardens on the river
--   encounter_deschutes      a local pilot, canoe and waiting loads on a gravel bar of the Deschutes
--   encounter_columbia_raft  Upper Chinookan portage crews carrying loads past the Cascades
local K = dofile(app.params.kit)
local W, H = 432, 150

local function resident(x, y, coat)
  K.person(x, y, coat, "deep", false)
  K.rect(x - 1, y - 16, 5, 3, "deep")
  K.rect(x, y - 13, 3, 3, "skin_dk")
  K.line(x + 2, y - 14, x + 3, y - 9, "deep")
end

local function resident_woman(x, y, coat)
  K.person(x, y, coat, "deep", true)
  K.rect(x - 1, y - 16, 5, 3, "deep")
  K.rect(x, y - 13, 3, 3, "skin_dk")
  K.line(x - 1, y - 14, x - 1, y - 8, "deep"); K.line(x + 3, y - 14, x + 3, y - 8, "deep")
end

-- a horse side-on, 22 px long, (x, y) = hind hoof on the ground
local HORSE = {bay = {"ox", "ox_dk", "ink"}, chestnut = {"rust", "ox", "brick_dk"}, gray = {"stone_lt", "stone", "stone_dk"},
  dun = {"gold", "ochre", "deep"}, black = {"roof", "roof_dk", "ink"}, pinto = {"white", "stone", "ox_dk"}}
local function horse(x, y, coat, facing, pack)
  local c = HORSE[coat]
  local function X(dx) return (facing > 0) and (x + dx) or (x + 22 - dx) end
  local function R(dx, dy, w, h, col) K.rect((facing > 0) and (x + dx) or (x + 22 - dx - w + 1), y + dy, w, h, col) end
  R(2, -12, 15, 6, c[1]); R(2, -7, 15, 1, c[2])
  for _, l in ipairs({2, 5, 13, 16}) do R(l, -6, 1, 6, c[2]) end
  R(16, -15, 3, 5, c[1]); R(17, -17, 5, 3, c[1]); R(21, -16, 1, 2, c[3])
  K.px(X(17), y - 18, c[3]); K.px(X(19), y - 16, "ink")
  R(1, -12, 1, 7, c[3]); R(15, -16, 2, 4, c[3])
  if coat == "pinto" then R(5, -11, 5, 3, "ox_dk"); R(12, -10, 3, 2, "ox_dk") end
  if pack then
    R(5, -16, 9, 5, "sand"); R(5, -16, 9, 1, "cream"); R(7, -12, 5, 4, "ochre"); K.line(X(9), y - 16, X(9), y - 8, "wood")
  end
  K.shadow(x - 1, y + 1, 24)
end

local function parcel(x, y, c)
  K.rect(x, y - 5, 8, 5, c or "ochre"); K.rect(x, y - 5, 8, 1, "cream"); K.line(x + 4, y - 5, x + 4, y - 1, "wood")
end

local function basket(x, y)
  K.ellipse(x, y, 5, 3, "wood"); K.ellipse(x, y - 2, 5, 1, "ochre"); K.line(x - 3, y, x + 3, y, "clap_sh")
end

---------------------------------------------------------------- Platte
K.canvas(W, H, 1848)
K.layer("valley", function()
  K.sky(W, 84, {{60, 12, 0.8}, {260, 18, 1.0}, {390, 8, 0.6}}, "mist")
  K.ridge(0, W - 1, 82, 85, function(x) return 6 + 3 * math.sin(x / 47) + math.sin(x / 13) end, "far_hill", "mist", "haze")
  K.rect(0, 85, W, 18, "light_blue")
  -- the braided Platte: wide, shallow, channels between pale sandbars
  for _, b in ipairs({{40, 92, 50, 3}, {150, 96, 70, 3}, {300, 90, 60, 2}, {390, 97, 40, 2}}) do
    K.ellipse(b[1], b[2], b[3], b[4], "sand"); K.ellipse(b[1] - 4, b[2] - 1, b[3] - 10, 1, "cream")
  end
  for i = 1, 80 do local x, y = K.rnd(W), 86 + K.rnd(16); if K.at(x, y) == "light_blue" then K.rect(x, y, 2 + K.rnd(5), 1, "sky") end end
  K.ellipse(250, 88, 30, 3, "leaf"); for x = 226, 274, 6 do K.elm(x, 89, 0.35) end
  K.rect(0, 103, W, H - 103, "grass")
  for i = 1, 1400 do local x, y = K.rnd(W), 103 + K.rnd(47); K.px(x, y, ({"leaf", "sage", "gold", "grass"})[K.rnd(4) + 1]) end
  K.rect(0, 103, W, 1, "sand")
end)
K.layer("people", function()
  -- a family traveling with loaded horses, provisions spread on a mat for exchange
  horse(70, 128, "bay", 1, true); horse(40, 132, "dun", 1, true); horse(104, 124, "pinto", 1, false)
  K.poly({{170, 134}, {226, 131}, {234, 142}, {176, 145}}, "cream"); K.line(170, 134, 226, 131, "clap_sh")
  parcel(184, 139); parcel(198, 138, "rust"); parcel(212, 137)
  basket(160, 140)
  resident(150, 136, "rust"); resident_woman(240, 138, "ochre"); resident(132, 130, "cream")
  resident_woman(96, 134, "teal")
  K.person(262, 138, "blue", "roof", false)
  K.wagon(330, 128, -1)
end)
K.save("encounter_platte")

---------------------------------------------------------------- Fort Hall
K.canvas(W, H, 1849)
K.layer("snake river bottom", function()
  K.sky(W, 82, {{100, 10, 0.8}, {320, 16, 0.9}}, "mist")
  K.ridge(0, W - 1, 80, 84, function(x) return 14 + 6 * math.sin(x / 61 + 1) + 2 * math.sin(x / 15) end, "far_hill", "mist", "haze")
  K.rect(0, 84, W, H - 84, "sage")
  for i = 1, 1200 do local x, y = K.rnd(W), 84 + K.rnd(66); K.px(x, y, ({"grass", "stone", "ochre", "leaf"})[K.rnd(4) + 1]) end
  K.rect(0, 92, W, 5, "blue"); K.rect(0, 92, W, 1, "light_blue")
  for x = 0, W - 1, 9 do if K.rnd(2) == 0 then K.willow(x, 92, 0.4) end end
end)
K.layer("post", function()
  -- the whitewashed adobe post of the Hudson's Bay Company, small in the distance
  local x0 = 300
  K.rect(x0, 70, 96, 22, "white"); K.rect(x0, 70, 96, 2, "stone_lt"); K.rect(x0 + 44, 80, 10, 12, "deep")
  K.rect(x0 - 8, 62, 14, 30, "white"); K.rect(x0 + 2, 62, 4, 30, "stone_lt"); K.rect(x0 - 9, 60, 16, 2, "wood")
  K.rect(x0 + 90, 64, 12, 28, "white"); K.rect(x0 + 98, 64, 4, 28, "stone_lt")
  K.rect(x0 + 40, 44, 1, 18, "deep"); K.rect(x0 + 41, 45, 9, 5, "red"); K.rect(x0 + 41, 45, 3, 2, "white")
  K.shadow(x0 - 8, 93, 112)
end)
K.layer("people", function()
  -- families with horses and a few parcels of dried provisions to spare, fish drying on a rack
  K.line(40, 132, 40, 110, "wood"); K.line(92, 130, 92, 108, "wood"); K.line(38, 111, 94, 109, "ochre")
  for x = 46, 86, 8 do K.rect(x, 111, 3, 9, "rust"); K.px(x + 1, 111, "cream"); K.px(x, 120, "brick_dk") end
  horse(120, 126, "gray", 1, false); horse(150, 130, "chestnut", -1, true); horse(280, 116, "bay", -1, false)
  parcel(196, 136); parcel(210, 135, "rust"); basket(226, 138)
  resident(186, 136, "ochre"); resident_woman(236, 136, "rust"); resident(110, 132, "cream"); resident_woman(70, 136, "teal")
  K.person(256, 136, "red", "deep", false)
end)
K.save("encounter_fort_hall")

---------------------------------------------------------------- Grande Ronde
K.canvas(W, H, 1850)
K.layer("valley", function()
  K.sky(W, 74, {{80, 14, 0.9}, {330, 10, 0.7}}, "mist")
  K.ridge(0, W - 1, 72, 76, function(x) return 22 + 8 * math.sin(x / 53 + 2) + 2 * math.sin(x / 11) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 76, 80, function(x) return 10 + 4 * math.sin(x / 31) + math.sin(x / 7) end, "teal", "haze", "pine")
  for x = 0, W - 1, 5 do K.conifer(x + K.rnd(3), 80, 6 + K.rnd(5), "pine", "teal", "haze") end
  K.rect(0, 80, W, H - 80, "grass")
  for i = 1, 1600 do local x, y = K.rnd(W), 80 + K.rnd(70); K.px(x, y, ({"leaf", "gold", "sage", "grass", "ochre"})[K.rnd(5) + 1]) end
  K.line(0, 96, 120, 92, "blue"); K.line(120, 92, 260, 98, "blue"); K.line(260, 98, 431, 94, "blue")
end)
K.layer("herd", function()
  -- the herd grazing, mixed colors; a few spotted horses among the bays, grays and duns
  for _, h in ipairs({{230, 108, "bay", 1}, {262, 112, "gray", -1}, {296, 106, "dun", 1}, {320, 116, "pinto", -1}, {350, 108, "chestnut", 1},
    {380, 114, "black", -1}, {250, 122, "dun", -1}, {300, 126, "bay", 1}, {360, 128, "gray", 1}}) do horse(h[1], h[2], h[3], h[4], false) end
  -- an owner holding a horse on a lead, an emigrant asking terms; others watching the herd
  horse(150, 138, "pinto", 1, false); K.line(170, 124, 178, 128, "wood")
  resident(180, 140, "ochre"); K.person(204, 140, "blue", "roof", false)
  resident(330, 136, "cream"); resident_woman(120, 140, "rust")
  K.wagon(30, 136, 1)
end)
K.save("encounter_grande_ronde")

---------------------------------------------------------------- Umatilla
K.canvas(W, H, 1851)
K.layer("river", function()
  K.sky(W, 80, {{60, 12, 0.8}, {280, 18, 1.0}}, "mist")
  K.ridge(0, W - 1, 78, 82, function(x) return 16 + 6 * math.sin(x / 43 + 1) + math.sin(x / 9) end, "sand", "cream", "ochre")
  K.rect(0, 82, W, H - 82, "grass")
  for i = 1, 1200 do local x, y = K.rnd(W), 82 + K.rnd(68); K.px(x, y, ({"leaf", "sage", "gold"})[K.rnd(3) + 1]) end
  K.poly({{0, 92}, {432, 88}, {432, 96}, {0, 100}}, "blue"); K.line(0, 92, 432, 88, "light_blue")
  for x = 0, W - 1, 14 do K.willow(x + K.rnd(6), 92, 0.45) end
end)
K.layer("gardens", function()
  -- a garden plot in rows beside the river, kept clear of the stock
  K.poly({{230, 112}, {380, 108}, {420, 130}, {250, 136}}, "dirt_dk")
  for i = 0, 7 do
    local y = 112 + i * 3
    K.line(232 + i * 3, y, 384 + i * 5, y - 3 + i * 0.4, "ox")
    for x = 236 + i * 3, 380 + i * 5, 5 do K.px(x, y - 1, "leaf"); K.px(x, y - 2, "grass") end
  end
  for x = 228, 420, 8 do K.rect(x, 138 - (x - 228) * 0.03, 1, 5, "wood") end
end)
K.layer("people", function()
  -- produce and dried provisions on a mat, a family and its cattle, an emigrant trading
  K.poly({{110, 130}, {166, 127}, {172, 140}, {114, 142}}, "cream")
  basket(124, 136); basket(140, 135); parcel(152, 136)
  resident_woman(104, 134, "rust"); resident(180, 136, "ochre"); resident(260, 128, "cream")
  K.person(198, 138, "blue", "roof", false)
  K.ox(40, 124, 1, "red"); K.ox(66, 130, -1, "light")
  horse(396, 146, "bay", -1, false)
end)
K.save("encounter_umatilla")

---------------------------------------------------------------- Deschutes
K.canvas(W, H, 1852)
K.layer("canyon", function()
  K.sky(W, 60, {{120, 10, 0.8}, {330, 8, 0.7}}, "sand")
  -- basalt walls and the swift green river cutting between them
  K.ridge(0, W - 1, 58, 64, function(x) return 26 + 8 * math.sin(x / 37) + 3 * math.sin(x / 9) end, "roof", "roof_lt", "roof_dk")
  K.rect(0, 63, W, 17, "roof")
  for x = 0, W - 1 do
    -- columnar basalt: broken joints and talus at the foot, not a fence
    if K.rnd(5) == 0 then K.rect(x, 60 + K.rnd(10), 1, 3 + K.rnd(6), "roof_dk") end
    for y = 74, 79 do if K.rnd(3) == 0 then K.px(x, y, (K.rnd(2) == 0) and "stone_dk" or "roof_lt") end end
  end
  K.rect(0, 80, W, 34, "teal")
  for i = 1, 160 do
    local x, y = K.rnd(W), 82 + K.rnd(30)
    K.rect(x, y, 2 + K.rnd(8), 1, (K.rnd(3) == 0) and "white" or "haze")
  end
  for _, r in ipairs({{120, 96}, {200, 90}, {290, 100}, {340, 88}}) do
    K.ellipse(r[1], r[2], 5, 2, "roof_dk"); K.rect(r[1] - 8, r[2] - 1, 3, 1, "white"); K.rect(r[1] + 5, r[2] + 1, 4, 1, "white")
  end
  K.poly({{0, 112}, {150, 108}, {300, 114}, {431, 110}, {431, 149}, {0, 149}}, "stone")
  for i = 1, 900 do local x, y = K.rnd(W), 110 + K.rnd(40); if K.at(x, y) == "stone" then K.px(x, y, ({"stone_lt", "stone_dk", "silt", "stone"})[K.rnd(4) + 1]) end end
end)
K.layer("work", function()
  -- a fishing scaffold on the rocks across the channel, kept clear by the travelers
  K.line(352, 86, 380, 80, "wood"); K.line(358, 86, 358, 74, "wood"); K.line(374, 82, 374, 72, "wood")
  K.line(356, 74, 378, 72, "ochre"); resident(366, 80, "cream")
  -- the pilot's dugout drawn up on the gravel bar, waiting loads stacked, the pilot explaining the channel
  K.poly({{140, 116}, {150, 122}, {214, 122}, {228, 114}, {212, 118}, {154, 119}}, "deep")
  K.line(144, 116, 220, 116, "ochre"); K.line(196, 116, 206, 104, "wood")
  K.crate(250, 130); K.barrel(268, 132); K.crate(262, 124)
  parcel(286, 134, "sand")
  resident(232, 132, "ochre"); K.person(310, 136, "blue", "roof", false); K.person(326, 138, "rust", "deep", false)
  K.wagon(40, 140, 1)
end)
K.save("encounter_deschutes")

---------------------------------------------------------------- Cascades portage
K.canvas(W, H, 1853)
K.layer("gorge", function()
  K.sky(W, 70, {{70, 12, 0.9}, {300, 18, 1.1}}, "mist")
  K.ridge(0, W - 1, 60, 72, function(x) return 22 + 8 * math.sin(x / 51 + 1) + 3 * math.sin(x / 11) end, "teal", "haze", "pine")
  for x = 0, W - 1, 4 do K.conifer(x + K.rnd(3), 60 + K.rnd(10), 10 + K.rnd(8), "pine", "teal", "leaf") end
  -- the rapids: white water broken over boulders
  K.rect(0, 72, W, 30, "blue")
  for i = 1, 520 do local x, y = K.rnd(W), 73 + K.rnd(28); K.rect(x, y, 2 + K.rnd(6), 1, (K.rnd(3) > 0) and "white" or "light_blue") end
  for _, b in ipairs({{60, 84}, {140, 90}, {220, 80}, {300, 92}, {380, 86}}) do K.ellipse(b[1], b[2], 6, 3, "roof"); K.ellipse(b[1] - 2, b[2] - 1, 3, 1, "roof_lt") end
  K.poly({{0, 100}, {432, 96}, {432, 149}, {0, 149}}, "leaf")
  for i = 1, 1100 do local x, y = K.rnd(W), 98 + K.rnd(52); K.px(x, y, ({"grass", "pine", "sage", "leaf"})[K.rnd(4) + 1]) end
  -- the shore path the loads go round by
  local path = K.smooth({{-10, 128, 5}, {120, 122, 4}, {260, 116, 3}, {440, 108, 2}}, 12)
  K.ribbon(path, "silt", 1); K.ribbon(path, "silt_lt", 0)
  for _, t in ipairs({{12, 148}, {400, 148}, {380, 142}}) do K.conifer(t[1], t[2], 44, "ink", "pine", "leaf") end
end)
K.layer("portage", function()
  -- crews carrying loads with straps across the brow, a family's goods waiting at the landing
  local function carrier(x, y, coat, woman)
    if woman then resident_woman(x, y, coat) else resident(x, y, coat) end
    K.rect(x - 4, y - 13, 4, 6, "sand"); K.rect(x - 4, y - 13, 4, 1, "cream"); K.line(x - 1, y - 13, x + 1, y - 15, "wood")
  end
  carrier(100, 126, "ochre"); carrier(130, 124, "cream", true); carrier(176, 121, "rust"); carrier(212, 119, "ochre")
  K.crate(300, 112); K.barrel(316, 114); parcel(290, 116)
  K.person(330, 118, "blue", "roof", false); resident(282, 114, "cream")
  -- the raft and wagon bed tied at the upper landing
  K.rect(320, 96, 40, 4, "wood"); K.rect(320, 96, 40, 1, "ochre"); K.rect(328, 90, 22, 6, "cream")
  K.line(318, 98, 306, 104, "deep")
end)
K.save("encounter_columbia_raft")

-- Old Fort Boise, Hudson's Bay Company post near the mouth of the Boise River (432x150).
-- A small adobe square (the 1834 post was rebuilt in adobe about 1838) on the east bank of
-- the Snake, seen corner-on: the long front wall with its gate, the side wall running back,
-- a two-storey bastion at the corner and the HBC ensign on its staff (the flag itself is laid
-- over by ui/scene_ambience.gd). Willows mark the Boise mouth; the broad Snake runs behind
-- toward the Owyhee hills. The 1863 army Fort Boise, forty miles east, is not this place.
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 84

K.canvas(W, H, 1838)

K.layer("sky", function()
  K.sky(W, HORIZON, {{100, 18, 0.8}, {286, 10, 1.0}, {402, 28, 0.6}}, "sand")
  -- Owyhee hills beyond the Snake, dry and banded
  K.ridge(0, W - 1, HORIZON - 4, HORIZON + 2, function(x) return 16 + 6 * math.sin(x / 41 + 1) + 3 * math.sin(x / 13) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, HORIZON, HORIZON + 4, function(x) return 7 + 3 * math.sin(x / 23 + 2) + math.sin(x / 5) end, "clap_sh", "sand", "stone_dk")
end)

K.layer("land", function()
  K.rect(0, 86, W, H - 86, "sand")
  K.dither(0, 86, W, 2, "clap_sh", "sand")
  -- the Snake behind the post, broad and slow
  K.river(K.smooth({{-10, 92, 4}, {120, 90, 5}, {260, 93, 6}, {440, 90, 6}}, 10), "ochre")
  -- the Boise coming in from the right foreground, lined with willows
  K.river(K.smooth({{440, 146, 8}, {404, 134, 6}, {418, 120, 5}, {378, 112, 4}, {360, 102, 3}, {372, 96, 3}, {346, 92, 2}}, 10), "ochre")
  for _, p in ipairs({{394, 128}, {432, 126}, {398, 112}, {356, 110}, {388, 100}, {342, 100}, {362, 92}}) do K.willow(p[1], p[2], 1) end
  for i = 1, 700 do
    local x, y = K.rnd(W), 88 + K.rnd(H - 88)
    if K.at(x, y) == "sand" then K.px(x, y, (K.rnd(3) == 0) and "clap_sh" or ((K.rnd(2) == 0) and "gold" or "cream")) end
  end
  for i = 1, 30 do
    local x, y = K.rnd(W), 100 + K.rnd(48)
    if K.at(x, y) == "sand" or K.at(x, y) == "gold" or K.at(x, y) == "cream" or K.at(x, y) == "clap_sh" then K.sage(x, y) end
  end
  -- the road from the east to the gate
  local road = K.smooth({{-10, 146, 6}, {80, 136, 5}, {150, 124, 3}, {178, 116, 2}}, 10)
  K.ribbon(road, "clap_sh", 1)
  K.ribbon(road, "cream", -1)
end)

K.layer("fort", function()
  local function adobe(pts, fill, line, rows)
    K.poly(pts, fill)
    for _, r in ipairs(rows or {}) do K.line(r[1], r[2], r[3], r[4], line) end
  end
  -- side wall running back to the right: foreshortened, in shade
  adobe({{250, 92}, {300, 86}, {300, 104}, {250, 114}}, "ochre", "rust", {{250, 100, 300, 92}, {250, 107, 300, 98}})
  K.rect(250, 91, 1, 23, "ochre")
  K.line(250, 92, 300, 86, "sand"); K.line(250, 91, 300, 85, "cream")
  -- far corner bastion, small with distance
  K.rect(292, 74, 16, 30, "clap_sh"); K.rect(291, 73, 18, 2, "wood"); K.rect(301, 75, 7, 29, "ochre")
  K.rect(297, 82, 2, 3, "deep")
  -- front wall, sunlit, with coping, drip stains and the gate
  K.rect(150, 92, 100, 22, "sand")
  K.rect(150, 91, 100, 2, "cream")
  for i = 1, 160 do K.px(150 + K.rnd(100), 94 + K.rnd(19), (K.rnd(3) == 0) and "clap_sh" or "gold") end
  for x = 152, 248, 6 do if K.rnd(2) == 0 then K.rect(x, 93, 1, 3 + K.rnd(5), "clap_sh") end end
  K.rect(150, 113, 100, 1, "ochre")
  K.rect(192, 99, 16, 15, "deep"); K.rect(193, 100, 14, 14, "wood")
  K.rect(199, 100, 1, 14, "deep"); K.rect(193, 106, 14, 1, "deep")
  K.rect(191, 98, 18, 1, "ink")
  -- roofs of the store and dwellings inside, showing over the wall
  K.poly({{214, 91}, {218, 86}, {246, 86}, {249, 91}}, "roof"); K.line(218, 86, 246, 86, "roof_lt")
  K.poly({{156, 91}, {160, 87}, {184, 87}, {187, 91}}, "roof_dk")
  K.rect(232, 82, 3, 5, "brick"); K.px(232, 81, "brick_lt")
  -- near corner bastion: two storeys, loopholes, pole roof
  K.rect(132, 70, 24, 46, "sand")
  K.rect(148, 70, 8, 46, "clap_sh")
  K.rect(131, 68, 26, 3, "wood"); K.rect(131, 68, 26, 1, "ochre")
  for _, p in ipairs({{137, 78}, {145, 78}, {137, 96}, {145, 96}, {151, 87}}) do K.rect(p[1], p[2], 2, 3, "ink") end
  K.rect(132, 92, 24, 1, "clap_sh")
  for i = 1, 60 do K.px(132 + K.rnd(16), 72 + K.rnd(42), (K.rnd(2) == 0) and "gold" or "clap_sh") end
  K.shadow(128, 117, 34); K.shadow(150, 115, 102)
  -- flagstaff on the bastion; the ensign flies from (144, 46) in scene_ambience.json
  K.rect(143, 46, 1, 22, "deep"); K.px(143, 45, "gold")
end)

K.layer("travelers", function()
  K.far_wagon(176, 120, 1)
  K.wagon(64, 142, 1)
  K.team(112, 141, 1, {"light"}, {"dark", true})
  K.person(54, 143, "red", "bonnet", true)
end)

K.save("location_fort_boise")

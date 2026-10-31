-- American Falls of the Snake (432x150).
-- Below Fort Hall the Snake River spreads wide and pours over a broad, ragged ledge of black
-- basalt in a run of falls and chutes, about fifteen to twenty feet. The road kept to the south
-- bank above it. Shoshone and Bannock people fished here in season; one fisherman stands on
-- the rocks with his spear, another carries the catch up the bank.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184879)

K.layer("sky", function()
  K.sky(W, 74, {{100, 12, 0.8}, {320, 22, 0.6}}, "mist")
end)

K.layer("far shore", function()
  K.ridge(0, W - 1, 0, 80, function(x) return -(66 + 3 * math.sin(x / 53) + math.sin(x / 13)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 82, function(x) return -(74 + 2 * math.sin(x / 31 + 1)) end, "clap_sh", "sand", "silt")
  for i = 1, 200 do local x, y = K.rnd(W), 70 + K.rnd(12); if K.at(x, y) == "clap_sh" then K.px(x, y, (i % 2 == 0) and "sage" or "silt") end end
end)

K.layer("river", function()
  -- the river above the falls: wide, smooth, sliding toward the ledge
  K.rect(0, 80, W, 28, "blue")
  for i = 1, 140 do local x, y = K.rnd(W), 81 + K.rnd(18); K.rect(x, y, 3 + K.rnd(6), 1, (i % 4 == 0) and "light_blue" or "sky_top") end
  -- the black basalt ledge, broken into blocks, the water pouring over between them
  local LIP = function(x) return 100 + math.floor(3 * math.sin(x / 19) + 2 * math.sin(x / 7)) end
  for x = 0, W - 1 do
    local lip = LIP(x)
    local chute = (math.sin(x / 13) + 0.8 * math.sin(x / 5.3 + 1) + 0.5 * math.sin(x / 31)) > -0.35
    local foot = chute and 122 or (122 - math.floor(4 + 4 * math.sin(x / 9)))
    for y = lip, foot do
      if chute then
        local c = ((x + y * 3) % 7 == 0) and "light_blue" or "white"
        if y > lip + 14 then c = ((x + y) % 3 == 0) and "light_blue" or "white" end
        if (x * 5 + y) % 11 == 0 then c = "mist" end
        K.px(x, y, c)
      else
        local h = (x * 73 + y * 151 + (x // 4) * 37) % 13
        K.px(x, y, (h == 0 and "ink") or (h < 4 and "roof_dk") or (h == 12 and "roof_lt") or "roof")
      end
    end
    if not chute then K.px(x, lip, "roof_lt") end
  end
  -- the pool and spray below, the river running on
  K.rect(0, 118, W, 18, "blue")
  for x = 0, W - 1 do
    local lip = LIP(x)
    local chute = (math.sin(x / 13) + 0.8 * math.sin(x / 5.3 + 1) + 0.5 * math.sin(x / 31)) > -0.35
    if not chute then
      local top = 122 - math.floor(4 + 4 * math.sin(x / 9))
      for y = lip, top do local h = (x * 73 + y * 151 + (x // 4) * 37) % 13
        K.px(x, y, (h == 0 and "ink") or (h < 4 and "roof_dk") or (h == 12 and "roof_lt") or "roof") end
      K.px(x, lip, "roof_lt")
    end
  end
  for i = 1, 300 do local x, y = K.rnd(W), 118 + K.rnd(14); K.rect(x, y, 1 + K.rnd(3), 1, (i % 3 == 0) and "white" or "light_blue") end
  -- near bank of basalt and sage
  K.ridge(0, W - 1, 0, H, function(x) return -(130 + 3 * math.sin(x / 17) + math.sin(x / 5)) end, "roof", "roof_lt", "roof_dk")
  K.rect(0, 136, W, H - 136, "silt")
  for i = 1, 600 do K.px(K.rnd(W), 136 + K.rnd(14), ({"silt_lt", "sage", "silt_dk", "sand"})[i % 4 + 1]) end
  for i = 1, 16 do K.sage(K.rnd(W), 140 + K.rnd(10)) end
  for _, b in ipairs({{60, 112, 8}, {140, 116, 6}, {300, 110, 9}, {380, 118, 7}}) do
    K.ellipse(b[1], b[2], b[3], 4, "roof"); K.ellipse(b[1] - 1, b[2] - 1, b[3] - 2, 2, "roof_lt")
  end
end)

K.layer("people", function()
  -- a Shoshone fisherman on a rock at the foot of a chute, spear poised
  K.person(300, 108, "ochre", "deep", false)
  K.rect(299, 92, 5, 3, "deep"); K.rect(300, 95, 3, 3, "skin_dk")
  K.line(304, 94, 312, 112, "wood"); K.px(312, 113, "stone_lt")
  -- his companion carrying salmon up the bank
  K.person(220, 142, "rust", "deep", true)
  K.rect(219, 126, 5, 3, "deep"); K.rect(220, 129, 3, 3, "skin_dk")
  K.rect(224, 134, 2, 6, "red"); K.rect(226, 135, 2, 5, "brick_lt")
  -- emigrants stopped on the road to look
  K.wagon(380, 148, -1)
  K.person(352, 146, "blue", "deep"); K.person(342, 147, "teal", "bonnet", true)
end)

K.save("location_american_falls")

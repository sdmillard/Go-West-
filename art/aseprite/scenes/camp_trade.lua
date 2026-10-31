-- An emigrant family's noon camp beside the road, 1848 (622x273, the camp trading counter screen).
-- no seasons: build.sh --seasons skips this script (indoors, a trading counter, or its own season).
-- Families on the road were not traders: they swapped whatever they could spare, a sack of meal,
-- a spare wheel, a few pounds of salt or lead, and paid dear for what they had run short of.
-- ui/post_store_view.gd covers (244..622, 0..236) with the two goods panels and the bottom strip with
-- the footer, so the wagon, the family and their spare goods all sit in the left bay (0..244, 0..236).
local K = dofile(app.params.kit)
local W, H = 622, 273
local HORIZON = 118

K.canvas(W, H, 1847)

----------------------------------------------------------------- 1. Sky, rolling grass, a creek line
K.layer("land", function()
  K.sky(W, HORIZON, {{70, 22, 1.3}, {300, 14, 1.0}, {500, 30, 1.5}}, "mist")
  local hill = function(x) return 6 + 5 * math.sin(x / 53 + 1.2) + 2 * math.sin(x / 17) end
  K.ridge(0, W - 1, HORIZON, HORIZON, hill, "far_hill", "mist", "haze")
  K.rect(0, HORIZON, W, H - HORIZON, "grass")
  for y = HORIZON, H - 1 do
    for x = 0, W - 1 do
      local r = K.rnd(math.max(4, 36 - math.floor((y - HORIZON) / 5)))
      if r == 0 then K.px(x, y, "sage") elseif r == 1 then K.px(x, y, "leaf") elseif r == 2 and y > 170 then K.px(x, y, "gold") end
    end
  end
  -- willows along a creek behind the camp
  for _, t in ipairs({{12, 124}, {40, 122}, {98, 123}, {150, 121}, {214, 124}, {262, 122}}) do K.willow(t[1], t[2], 1) end
  -- trampled ground around the camp
  K.ellipse(110, 214, 104, 26, "dirt_dk")
  for i = 1, 900 do
    local x, y = 10 + K.rnd(200), 190 + K.rnd(48)
    if K.at(x, y) == "dirt_dk" then K.px(x, y, (i % 3 == 0) and "ochre" or "shadow") end
  end
end)

----------------------------------------------------------------- 2. Oxen grazing out on the grass
K.layer("neighbours", function()
  -- another family nooning further along the creek, seen in the camp's own picture
  K.wagon(300, 178, 1)
  K.tent(392, 180, 18, 24)
  K.person(366, 182, "red", "bonnet", true)
  K.person(352, 183, "blue", "deep")
  K.team(420, 186, -1, {"light", true}, {"dark"})
end)

K.layer("stock", function()
  K.ox(176, 148, 1, "red", true)
  K.ox(214, 152, -1, "dark", false)
  K.ox(132, 144, 1, "light", true)
end)

----------------------------------------------------------------- 3. The wagon, its cover tied up for airing
K.layer("wagon", function()
  local x, y = 26, 196
  K.rect(x - 4, y + 1, 126, 4, "wagon_shadow")
  K.rect(x + 8, y - 24, 104, 4, "deep")
  -- blue-painted bed with a darker sideboard
  K.poly({{x, y - 50}, {x + 116, y - 50}, {x + 112, y - 24}, {x + 4, y - 24}}, "blue")
  K.rect(x, y - 50, 116, 2, "light_blue"); K.rect(x + 2, y - 38, 112, 1, "teal"); K.rect(x + 4, y - 25, 108, 1, "ink")
  -- bonnet: a sprung canvas over hickory bows, the near side rolled up
  K.poly({{x + 2, y - 50}, {x - 4, y - 80}, {x + 12, y - 96}, {x + 104, y - 96}, {x + 120, y - 80}, {x + 114, y - 50}}, "cream")
  K.poly({{x + 2, y - 50}, {x - 4, y - 80}, {x + 12, y - 96}, {x + 22, y - 96}, {x + 12, y - 80}, {x + 12, y - 50}}, "white")
  K.poly({{x + 104, y - 96}, {x + 120, y - 80}, {x + 114, y - 50}, {x + 98, y - 50}, {x + 106, y - 80}}, "clap_sh")
  for _, bx in ipairs({30, 52, 74}) do K.line(x + bx, y - 95, x + bx + 2, y - 66, "sand") end
  K.rect(x + 12, y - 66, 92, 6, "sand"); K.rect(x + 12, y - 60, 92, 1, "clap_sh")
  -- inside, under the rolled cover: a trunk, a churn and sacks
  K.rect(x + 16, y - 59, 90, 9, "deep")
  K.rect(x + 20, y - 58, 22, 8, "brick"); K.rect(x + 20, y - 58, 22, 1, "brick_lt"); K.px(x + 30, y - 55, "gold")
  K.rect(x + 48, y - 60, 8, 10, "wood"); K.rect(x + 48, y - 60, 8, 1, "ochre")
  K.ellipse(x + 70, y - 54, 8, 4, "cream"); K.ellipse(x + 88, y - 54, 8, 4, "clap_sh")
  K.wheel(x + 92, y - 15, 15)
  K.wheel(x + 24, y - 12, 12)
  K.line(x + 116, y - 20, x + 146, y - 6, "wood")
  -- a yoke and bows laid down by the tongue
  K.rect(x + 128, y + 2, 26, 3, "wood"); K.rect(x + 128, y + 2, 26, 1, "ochre")
  K.line(x + 132, y + 5, x + 130, y + 10, "rust"); K.line(x + 148, y + 5, x + 150, y + 10, "rust")
end)

----------------------------------------------------------------- 4. The noon fire, the family and what they can spare
K.layer("camp", function()
  -- a cook fire with a kettle hung from a tripod
  local fx, fy = 196, 214
  K.ellipse(fx, fy + 2, 9, 3, "shadow")
  K.line(fx - 9, fy, fx, fy - 22, "wood"); K.line(fx + 9, fy, fx, fy - 22, "wood"); K.line(fx, fy + 2, fx, fy - 22, "deep")
  K.line(fx, fy - 22, fx, fy - 14, "stone_ink")
  K.rect(fx - 5, fy - 14, 10, 7, "ink"); K.rect(fx - 5, fy - 14, 10, 1, "stone_dk")
  K.rect(fx - 4, fy - 3, 8, 3, "red"); K.rect(fx - 2, fy - 6, 4, 3, "gold"); K.px(fx, fy - 7, "cream")
  K.rect(fx - 7, fy, 14, 2, "deep")
  for i = 0, 6 do K.px(fx + 1 + (i % 2), fy - 24 - i * 3, "mist") end

  -- a quilt spread on the grass with the family's spare goods
  K.poly({{30, 212}, {128, 210}, {136, 232}, {22, 234}}, "red")
  for x = 30, 128, 8 do K.line(x, 211, x - 6, 233, "brick_dk") end
  K.line(26, 222, 132, 221, "brick_dk")
  K.line(22, 234, 30, 212, "cream"); K.line(128, 210, 136, 232, "cream")
  -- a sack of cornmeal, a crock of salt, a small box of lead balls, a folded coat
  K.ellipse(44, 222, 9, 7, "clap_sh"); K.ellipse(42, 220, 5, 4, "cream"); K.rect(41, 213, 6, 2, "stone_dk")
  K.rect(60, 218, 9, 10, "stone"); K.rect(60, 218, 9, 1, "stone_lt"); K.rect(61, 216, 7, 2, "stone_dk")
  K.rect(76, 222, 12, 6, "wood"); K.rect(76, 222, 12, 1, "ochre"); for bx = 78, 86, 2 do K.px(bx, 224, "stone_dk") end
  K.rect(94, 218, 22, 9, "blue"); K.rect(94, 218, 22, 1, "light_blue"); K.rect(104, 220, 1, 6, "ink")
  -- a spare wheel leaning against the wagon bed
  K.wheel(18, 200, 11)

  -- the husband: shirtsleeves, braces, a wide-brimmed hat, holding out a powder horn to trade
  local mx, gy = 150, 226
  K.rect(mx - 8, gy + 1, 18, 3, "wagon_shadow")
  K.rect(mx - 4, gy - 2, 4, 2, "ink"); K.rect(mx + 2, gy - 2, 4, 2, "ink")
  K.rect(mx - 4, gy - 20, 4, 18, "roof"); K.rect(mx + 2, gy - 20, 4, 18, "roof"); K.rect(mx - 4, gy - 20, 1, 18, "roof_lt")
  K.rect(mx - 6, gy - 40, 13, 20, "cream"); K.rect(mx - 6, gy - 40, 3, 20, "white"); K.rect(mx + 5, gy - 40, 2, 20, "clap_sh")
  K.line(mx - 3, gy - 40, mx - 3, gy - 21, "deep"); K.line(mx + 3, gy - 40, mx + 3, gy - 21, "deep")
  K.rect(mx - 9, gy - 38, 3, 12, "cream"); K.rect(mx - 9, gy - 26, 3, 3, "skin")
  K.line(mx + 7, gy - 37, mx + 14, gy - 30, "cream"); K.rect(mx + 14, gy - 32, 3, 3, "skin")
  K.rect(mx + 15, gy - 35, 6, 3, "cream"); K.px(mx + 21, gy - 34, "deep")
  K.rect(mx - 3, gy - 49, 8, 9, "skin"); K.rect(mx + 3, gy - 49, 2, 9, "skin_dk")
  K.px(mx - 1, gy - 46, "ink"); K.px(mx + 2, gy - 46, "ink"); K.rect(mx - 3, gy - 42, 8, 2, "appearance_hair")
  K.rect(mx - 8, gy - 51, 18, 2, "wood"); K.rect(mx - 4, gy - 56, 10, 5, "wood"); K.rect(mx - 4, gy - 53, 10, 1, "deep")

  -- the wife: calico dress, apron and sunbonnet, a basket of eggs on her arm
  local wx = 220
  K.rect(wx - 9, gy + 1, 20, 3, "wagon_shadow")
  K.poly({{wx - 6, gy - 30}, {wx + 6, gy - 30}, {wx + 10, gy}, {wx - 10, gy}}, "teal")
  for yy = gy - 28, gy - 2, 4 do K.line(wx - 8, yy, wx + 8, yy, "haze") end
  K.poly({{wx - 4, gy - 28}, {wx + 4, gy - 28}, {wx + 5, gy - 4}, {wx - 5, gy - 4}}, "white")
  K.rect(wx - 6, gy - 42, 12, 14, "teal"); K.rect(wx - 6, gy - 42, 3, 14, "haze")
  K.rect(wx - 9, gy - 40, 3, 12, "teal"); K.rect(wx - 9, gy - 28, 3, 3, "skin")
  K.ellipse(wx - 10, gy - 24, 5, 3, "ochre"); K.px(wx - 12, gy - 26, "white"); K.px(wx - 9, gy - 26, "white")
  K.rect(wx + 6, gy - 40, 3, 12, "teal"); K.rect(wx + 6, gy - 28, 3, 3, "skin")
  K.rect(wx - 3, gy - 50, 7, 8, "skin"); K.rect(wx + 2, gy - 50, 2, 8, "skin_dk")
  K.px(wx - 1, gy - 47, "ink")
  K.rect(wx - 6, gy - 54, 12, 6, "cream"); K.rect(wx - 7, gy - 52, 3, 10, "cream"); K.rect(wx + 4, gy - 52, 3, 6, "cream")
  K.rect(wx - 6, gy - 54, 12, 1, "white"); K.rect(wx + 5, gy - 46, 4, 5, "cream")

  -- a child sitting on the wagon tongue
  K.rect(176, 196, 5, 7, "red"); K.rect(176, 191, 5, 5, "skin"); K.rect(176, 190, 5, 2, "appearance_hair")
  K.rect(176, 203, 2, 5, "roof"); K.rect(179, 203, 2, 5, "roof")
end)

K.save("location_camp_trade")

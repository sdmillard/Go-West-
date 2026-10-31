-- The guardhouse at Fort Kearny, 1848 (432x150).
-- The new post on the Platte had no stockade. The Missouri volunteer battalion that built it in
-- 1848 lived in tents and in low buildings of cut prairie sod and adobe, and its guardhouse was
-- one of them: thick sod walls, a pole-and-sod roof sprouting grass, a plank door and a sentry.
-- Behind, the rows of wall tents, the flagstaff, sod walls half raised, and the flat valley of
-- the Platte with the cottonwood islands on the river.
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 88

K.canvas(W, H, 1848)

-- stacked sod: blocks laid in courses, each cut face dark with root-matted edges
local function sod(x, y, w, h)
  K.rect(x, y, w, h, "dirt_dk")
  local row = 0
  for yy = y, y + h - 1, 3 do
    K.rect(x, yy, w, 1, "silt_dk")
    local off = (row % 2 == 0) and 0 or 4
    for xx = x + off, x + w - 1, 8 do K.px(xx, yy + 1, "deep"); K.px(xx, yy + 2, "deep") end
    row = row + 1
  end
  for i = 1, w * h / 24 do
    local px, py = x + K.rnd(w), y + K.rnd(h)
    K.px(px, py, ({"silt", "deep", "ox"})[K.rnd(3) + 1])
  end
end

K.layer("sky", function()
  K.sky(W, HORIZON + 2, {{90, 12, 1.0}, {300, 20, 0.8}}, "mist")
end)

K.layer("plain", function()
  -- the Platte valley: the river a pale line with wooded islands, the bluffs low and far
  K.ridge(0, W - 1, HORIZON, HORIZON + 1, function(x) return 4 + 2 * math.sin(x / 41) + math.sin(x / 13) end, "far_hill", "mist", "haze")
  K.rect(0, HORIZON + 1, W, H - HORIZON - 1, "grass")
  K.rect(0, HORIZON + 1, W, 2, "light_blue"); K.rect(0, HORIZON + 3, W, 1, "sky")
  for _, i in ipairs({{60, 16}, {176, 10}, {352, 22}}) do
    K.ellipse(i[1], HORIZON - 1, i[2], 3, "pine"); K.ellipse(i[1] - 3, HORIZON - 2, i[2] - 4, 2, "leaf")
    K.rect(i[1] - i[2], HORIZON + 1, i[2] * 2, 1, "sand")
  end
  for y = HORIZON + 4, H - 1 do
    for x = 0, W - 1 do
      if K.rnd(7) == 0 then K.px(x, y, ({"sage", "leaf", "ochre", "grass"})[K.rnd(4) + 1]) end
    end
  end
  -- the beaten parade ground
  K.ellipse(220, 128, 200, 14, "silt")
  for i = 1, 400 do
    local x, y = 20 + K.rnd(400), 116 + K.rnd(26)
    if K.at(x, y) == "silt" then K.px(x, y, (K.rnd(2) == 0) and "silt_lt" or "silt_dk") end
  end
end)

K.layer("post", function()
  -- the camp of the volunteer battalion: tents in rows behind the guardhouse
  for i = 0, 5 do K.tent(30 + i * 22, HORIZON + 16, 8, 11) end
  for i = 0, 3 do K.tent(322 + i * 24, HORIZON + 15, 8, 11) end
  -- the flagstaff and its colours
  K.rect(286, 30, 1, HORIZON - 16, "deep"); K.px(286, 29, "gold")
  K.rect(287, 31, 14, 8, "red"); for y = 32, 38, 2 do K.rect(287, y, 14, 1, "white") end
  K.rect(287, 31, 6, 4, "blue"); K.px(289, 32, "white"); K.px(291, 33, "white")
end)

K.layer("guardhouse", function()
  -- the guardhouse: thick sod walls, a low pole-and-sod roof sprouting grass, a plank door
  local x0, w, top, foot = 150, 110, 98, 124
  sod(x0, top, w, foot - top)
  K.poly({{x0 + w, top}, {x0 + w + 20, top - 5}, {x0 + w + 20, foot - 4}, {x0 + w, foot}}, "silt_dk")
  for yy = top + 3, foot - 2, 3 do K.line(x0 + w, yy, x0 + w + 19, yy - 4, "deep") end
  -- roof: protruding poles, a sod blanket, tufts of grass and a few sunflowers gone to seed
  K.poly({{x0 - 4, top}, {x0 + 16, top - 6}, {x0 + w + 24, top - 6}, {x0 + w + 20, top}}, "silt")
  K.rect(x0 + 14, top - 7, w + 10, 2, "grass")
  K.rect(x0 - 4, top - 1, w + 24, 2, "silt_dk")
  for x = x0 - 4, x0 + w + 22 do
    if K.rnd(2) == 0 then K.px(x, top - 4 - K.rnd(2), (K.rnd(3) == 0) and "sage" or "grass") end
    if K.rnd(4) == 0 then K.px(x, top - 6, "leaf") end
  end
  for x = x0 - 2, x0 + w + 2, 7 do K.rect(x, top + 1, 2, 2, "wood"); K.px(x, top + 1, "ochre") end
  -- door of rough planks, a barred loophole on either side
  local dx = x0 + 50
  K.rect(dx, foot - 17, 11, 17, "deep"); K.rect(dx + 1, foot - 16, 9, 16, "wood")
  for xx = dx + 3, dx + 7, 2 do K.rect(xx, foot - 16, 1, 16, "deep") end
  K.rect(dx + 1, foot - 12, 9, 1, "storm_dk"); K.rect(dx + 1, foot - 5, 9, 1, "storm_dk"); K.px(dx + 8, foot - 9, "storm_lt")
  K.rect(dx - 3, foot - 19, 17, 2, "wood")
  for _, wx in ipairs({x0 + 18, x0 + 84}) do
    K.rect(wx, top + 8, 6, 5, "ink"); K.rect(wx + 1, top + 8, 1, 5, "storm_lt"); K.rect(wx + 3, top + 8, 1, 5, "storm_lt")
    K.rect(wx - 1, top + 13, 8, 1, "wood")
  end
  K.shadow(x0 - 2, foot + 1, w + 24)
  -- the sentry at the door, musket at shoulder arms, and the corporal of the guard
  K.person(dx - 10, foot + 4, "blue", "storm_dk")
  K.line(dx - 6, foot - 14, dx - 6, foot - 2, "wood"); K.line(dx - 6, foot - 19, dx - 6, foot - 12, "storm_dk")
  K.person(dx + 22, foot + 6, "blue", "storm_dk")
  -- an army wagon and a water barrel by the wall
  K.barrel(x0 + w + 28, foot + 2)
  K.wagon(360, 142, -1)
end)

K.save("location_jail_army")

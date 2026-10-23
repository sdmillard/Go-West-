-- Big Blue River crossing (432x150).
-- Near Alcove Spring the Big Blue runs between low prairie ridges, its banks lined with
-- cottonwood, elm and oak. In ordinary water it was forded over a gravel bottom; in flood
-- parties waited days for it to fall. No later ferry is shown.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184825)

local course = {{440, 96, 4}, {360, 100, 6}, {280, 108, 9}, {210, 116, 12}, {150, 128, 15}, {90, 140, 18}, {30, 156, 21}}

K.layer("sky", function()
  K.sky(W, 74, {{300, 14, 1.0}, {90, 24, 0.6}}, "mist")
end)

K.layer("ridges", function()
  K.ridge(0, W - 1, 0, 100, function(x) return -(68 + 4 * math.sin(x / 53) + 2 * math.sin(x / 17)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 100, function(x) return -(78 + 6 * math.sin(x / 37 + 2) + 2 * math.sin(x / 11)) end, "sage", "clap_sh", "grass")
  for i = 1, 400 do
    local x, y = K.rnd(W), 74 + K.rnd(26)
    if K.at(x, y) == "sage" then K.px(x, y, (i % 2 == 0) and "gold" or "grass") end
  end
end)

K.layer("bottom", function()
  K.rect(0, 92, W, H - 92, "grass")
  for i = 1, 1200 do
    local x, y = K.rnd(W), 92 + K.rnd(H - 92)
    K.px(x, y, ({"leaf", "sage", "gold", "grass"})[i % 4 + 1])
    if i % 4 == 0 then K.px(x, y - 1, "sage") end
  end
  -- gravel bars and the river
  local water = K.smooth(course)
  K.ribbon(water, "dirt_dk", 4)
  K.ribbon(water, "clap_sh", 2)
  K.river(water, false)
  -- the ford: a broad riffle over gravel where the road crosses
  for i = 1, 60 do
    local x, y = 170 + K.rnd(80), 112 + K.rnd(20)
    if K.at(x, y) == "blue" or K.at(x, y) == "sky_top" then K.rect(x, y, 2 + K.rnd(3), 1, (i % 3 == 0) and "white" or "light_blue") end
  end
  for i = 1, 30 do
    local x, y = 160 + K.rnd(100), 110 + K.rnd(26)
    if K.at(x, y) == "sky_top" then K.px(x, y, "stone") end
  end
  -- road down the near bank into the ford, and out up the far side
  local near = K.smooth({{440, 150, 7}, {360, 140, 6}, {290, 132, 5}, {246, 126, 4}})
  K.ribbon(near, "rust", 1); K.ribbon(near, "ochre", 0)
  local far = K.smooth({{176, 116, 3}, {150, 108, 3}, {110, 102, 2}, {60, 98, 2}, {-6, 96, 2}})
  K.ribbon(far, "rust", 1); K.ribbon(far, "ochre", 0)
end)

K.layer("timber", function()
  -- a belt of timber following the river into the distance
  for i = 1, #course - 1 do
    local a, b = course[i], course[i + 1]
    for s = 0, 4 do
      local t = s / 5
      local x, y = a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
      local w = a[3] + (b[3] - a[3]) * t
      local sc = (y > 134) and 2 or 1
      -- far bank (upper side) gets a tree most steps; near bank fewer, so the ford stays open
      if K.rnd(3) == 0 and not (x > 140 and x < 260) then K.elm(math.floor(x - 4), math.floor(y - w - 2), sc) end
      if K.rnd(4) == 0 and x > 300 then K.elm(math.floor(x + 6), math.floor(y + w + 8), sc) end
    end
  end
  for _, w in ipairs({{132, 112, 1}, {270, 120, 1}, {300, 104, 1}, {116, 128, 1}, {380, 104, 1}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("figures", function()
  -- a wagon in the ford, knee-deep over the gravel, the next waiting on the near bank
  K.wagon(186, 124, -1)
  K.team(176, 120, -1, {"dark"}, {"red", true})
  K.wade(184, 234, 125, 5)
  K.wade(148, 178, 121, 5)
  K.person(240, 124, "blue", "deep")
  K.wade(238, 243, 125, 5)
  K.wagon(330, 140, -1)
  K.team(320, 138, -1, {"light"}, {"dark", true})
  K.person(384, 146, "red", "bonnet", true)
  K.person(394, 147, "teal", "roof")
end)

K.save("location_big_blue")

-- John Day River crossing (432x150).
-- Where the trail met the John Day (McDonald Ford) the river runs shallow over gravel through
-- open, rolling bunchgrass hills capped here and there with thin rimrock. Diarists note the
-- steep pull down to the ford and the climb out. Here one wagon is in the ford while
-- another is already climbing the far grade.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184828)

local function dome(x, c, w, h) local d = (x - c) / w; return (math.abs(d) < 1) and h * (1 - d * d) ^ 0.8 or 0 end

-- dry bunchgrass texture: short vertical strokes in the given shades
local function grass(x0, y0, x1, y1, base, a, b, n)
  for i = 1, n do
    local x, y = x0 + K.rnd(x1 - x0), y0 + K.rnd(y1 - y0)
    if K.at(x, y) == base then
      K.px(x, y, (i % 3 == 0) and b or a)
      if K.rnd(2) == 0 then K.px(x, y - 1, a) end
    end
  end
end

K.layer("sky", function()
  K.sky(W, 66, {{40, 22, 0.7}, {196, 10, 1.1}, {372, 26, 0.6}}, "mist")
end)

K.layer("far hills", function()
  K.ridge(0, W - 1, 0, 90, function(x) return -(60 + 4 * math.sin(x / 37) + 2 * math.sin(x / 13 + 1)) end, "far_hill", "mist", "haze")
end)

K.layer("hills", function()
  -- back row of rounded hills, a little hazy
  local back = function(x) return math.max(dome(x, 70, 90, 26), dome(x, 210, 80, 20), dome(x, 350, 100, 30)) end
  K.ridge(0, W - 1, 92, 112, back, "ochre", "gold", "rust")
  -- thin rimrock caps on the two high hills
  for x = 0, W - 1 do
    local h = back(x)
    if h > 20 then
      local top = math.floor(92 - h + 0.5)
      K.rect(x, top, 1, 2, ((x % 4) == 0) and "roof_dk" or "roof")
      K.px(x, top, "stone_dk")
    end
  end
  -- nearer hills on either side of the river gap
  local near_l = function(x) return dome(x, 40, 120, 40) + 3 * math.sin(x / 9) * ((x < 150) and 0.3 or 0) end
  local near_r = function(x) return dome(x, 420, 150, 46) end
  K.ridge(0, 170, 104, 108, near_l, "gold", "sand", "ochre")
  K.ridge(272, W - 1, 108, 112, near_r, "ochre", "gold", "rust")
  -- east-facing slopes turn away from the light
  for _, f in ipairs({{near_l, 0, 170, 104}, {near_r, 272, W - 1, 108}, {back, 0, W - 1, 92}}) do
    for x = f[2], f[3] do
      if f[1](x + 2) - f[1](x - 2) < -1.2 then
        local top = math.floor(f[4] - f[1](x) + 0.5)
        for y = top + 4, top + 14 do
          local c = K.at(x, y)
          if (x + y) % 2 == 0 and c == "gold" then K.px(x, y, "ochre") elseif (x + y) % 2 == 0 and c == "ochre" then K.px(x, y, "rust") end
        end
      end
    end
  end
  grass(0, 50, W, 112, "gold", "ochre", "sand", 900)
  grass(0, 50, W, 112, "ochre", "rust", "gold", 900)
  -- draws with darker grass and a few junipers
  for _, d in ipairs({{60, 70, 52, 100}, {120, 80, 132, 104}, {330, 70, 316, 104}, {390, 66, 398, 108}}) do
    K.line(d[1], d[2], d[3], d[4], "rust"); K.line(d[1] + 1, d[2], d[3] + 1, d[4], "sage")
  end
  for _, j in ipairs({{58, 92}, {64, 96}, {318, 98}, {326, 102}, {396, 100}, {130, 100}}) do
    K.ellipse(j[1], j[2] - 3, 3, 3, "pine"); K.ellipse(j[1] - 1, j[2] - 4, 2, 2, "leaf"); K.px(j[1], j[2], "deep")
  end
  -- the road climbing out on the far side
  local grade = K.smooth({{256, 112, 2}, {300, 100, 2}, {330, 88, 1}, {372, 74, 1}, {404, 66, 1}})
  K.ribbon(grade, "rust", 1); K.ribbon(grade, "sand", 0)
end)

K.layer("bottom", function()
  -- river flat and near bank
  K.rect(0, 108, W, H - 108, "sage")
  K.poly({{0, 112}, {160, 106}, {280, 110}, {431, 116}, {431, 120}, {0, 120}}, "grass")
  K.rect(0, 120, W, H - 120, "clap_sh")
  for i = 1, 700 do
    local x, y = K.rnd(W), 108 + K.rnd(H - 108)
    local c = K.at(x, y)
    if c == "sage" then K.px(x, y, (i % 2 == 0) and "grass" or "gold")
    elseif c == "clap_sh" then K.px(x, y, ({"sand", "stone", "ochre", "stone_dk"})[i % 4 + 1]) end
  end
  -- broad gravel bars and the shallow river
  local course = K.smooth({{-6, 112, 4}, {90, 114, 6}, {180, 126, 10}, {240, 134, 12}, {330, 128, 10}, {440, 118, 7}})
  K.ribbon(course, "stone", 5)
  K.ribbon(course, "clap_sh", 3)
  K.river(course, false)
  -- riffles over the ford where the trail crosses
  for i = 0, 10 do K.rect(176 + i * 5 + (i % 2), 120 + (i % 3) * 3, 3, 1, "white") end
  for i = 1, 70 do
    local x, y = K.rnd(W), 110 + K.rnd(26)
    if K.at(x, y) == "stone" or K.at(x, y) == "clap_sh" then K.rect(x, y, 2, 1, (i % 2 == 0) and "stone_dk" or "stone_lt") end
  end
  -- trail down to the ford from the near side
  local trail = K.smooth({{70, 156, 7}, {120, 146, 6}, {170, 136, 5}, {196, 128, 4}})
  K.ribbon(trail, "ochre", 1); K.ribbon(trail, "sand", 0)
  -- willows and a few cottonwood saplings along the bars
  for _, w in ipairs({{20, 116, 1}, {36, 118, 1}, {118, 121, 1}, {290, 117, 1}, {306, 118, 1}, {420, 124, 1}, {402, 125, 2}}) do
    K.willow(w[1], w[2], w[3])
  end
  grass(0, 128, W, H, "clap_sh", "gold", "ochre", 500)
  for i = 1, 30 do
    local x, y = K.rnd(W), 132 + K.rnd(18)
    local c = K.at(x, y)
    if c == "clap_sh" or c == "gold" or c == "stone" then K.sage(x, y) end
  end
end)

K.layer("figures", function()
  -- wagon in the ford, heading across to the far grade
  K.wagon(176, 128, 1)
  K.team(230, 125, 1, {"dark"}, {"red", true})
  K.line(222, 125, 246, 114, "deep")
  for i = 0, 9 do K.px(182 + i * 6, 129 + (i % 2), "white") end
  K.person(262, 124, "blue", "deep")
  -- the wagon ahead, small on the climb
  local fx, fy = 344, 84
  K.rect(fx, fy - 6, 10, 4, "blue"); K.rect(fx, fy - 10, 10, 4, "cream"); K.px(fx, fy - 10, "white")
  K.rect(fx + 1, fy - 2, 2, 2, "deep"); K.rect(fx + 7, fy - 2, 2, 2, "deep")
  K.rect(fx + 11, fy - 5, 8, 3, "ox_dk"); K.px(fx + 18, fy - 6, "ox_dk")
  -- family waiting on the near bank for their turn
  K.person(96, 140, "red", "bonnet", true)
  K.person(104, 141, "teal", "bonnet", true)
  K.person(112, 140, "rust", "roof")
end)

K.save("location_john_day")

-- Independence Rock (432x150).
-- A lone granite whaleback on the Sweetwater, about 130 feet high and a third of a mile long.
-- Emigrants camped on the flats beside it, climbed it, and painted their names on it in axle
-- grease and tar. The rock dwarfs the wagons corralled at its foot.
local K = dofile(app.params.kit)
local W, H = 432, 150
local BASE = 108

K.canvas(W, H, 184822)

local function body_h(x)
  local d = (x - 214) / 168
  return (math.abs(d) < 1) and 58 * (1 - d * d) ^ 0.55 or 0
end

local function rock_h(x)
  -- long, low turtle-back: a flattened ellipse with lumpy granite domes
  local d = (x - 214) / 168
  if math.abs(d) >= 1 then return 0 end
  local body = 58 * (1 - d * d) ^ 0.55
  local lumps = 4 * math.max(0, math.sin(x / 17)) + 3 * math.max(0, math.sin(x / 7 + 1)) * (1 - math.abs(d))
  return body + lumps
end

K.layer("sky", function()
  K.sky(W, 78, {{24, 14, 0.6}, {340, 10, 0.9}}, "mist")
end)

K.layer("distance", function()
  -- the Sweetwater valley: far blue ranges and low sage ridges
  K.ridge(0, W - 1, 0, BASE, function(x) return -(70 + 6 * math.sin(x / 33 + 1) + 2 * math.sin(x / 9)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, BASE, function(x) return -(84 + 3 * math.sin(x / 21)) end, "sage", "clap_sh", "grass")
end)

K.layer("flats", function()
  K.rect(0, BASE - 4, W, H - BASE + 4, "clap_sh")
  for i = 1, 1100 do
    local x, y = K.rnd(W), BASE - 4 + K.rnd(H - BASE + 4)
    K.px(x, y, ({"sand", "ochre", "sage", "clap_sh", "gold"})[i % 5 + 1])
  end
  -- the Sweetwater winding across the foreground, grassy along its banks
  local course = K.smooth({{-6, 128, 3}, {60, 124, 4}, {140, 136, 5}, {230, 126, 5}, {330, 138, 6}, {440, 130, 6}})
  K.ribbon(course, "grass", 6)
  K.river(course, "sand")
  -- road along the valley
  local road = K.smooth({{-6, 120, 2}, {100, 117, 2}, {200, 119, 2}, {300, 117, 2}, {440, 121, 3}})
  K.ribbon(road, "ochre", 1); K.ribbon(road, "sand", 0)
  for i = 1, 70 do
    local x, y = K.rnd(W), BASE + K.rnd(H - BASE)
    local c = K.at(x, y)
    if c ~= "blue" and c ~= "sky_top" and c ~= "grass" and c ~= "sand" and c ~= "ochre" and c ~= "light_blue" and c ~= "white" then K.sage(x, y) end
  end
end)

K.layer("rock", function()
  K.ridge(40, 390, BASE, BASE, rock_h, "stone_dk", "stone_lt", "stone_ink")
  -- broad modelling: light falls from the upper left across the whole dome
  for x = 40, 390 do
    local h = rock_h(x)
    if h > 0 then
      local top = math.floor(BASE - h + 0.5)
      local u = (x - 214) / 168
      for y = top + 1, BASE do
        local v = (BASE - y) / h
        local lit = -0.75 * u + 0.9 * v - 0.25 + 0.08 * math.sin(x / 9 + y / 7)
        if (x + y) % 2 == 0 then lit = lit + 0.05 end
        local c = (lit > 0.62) and "stone_lt" or ((lit > 0.15) and "stone" or ((lit > -0.25) and "stone_dk" or "stone_ink"))
        K.px(x, y, c)
      end
    end
  end
  -- exfoliating granite sheets: curved cracks following the dome
  for _, k in ipairs({{70, 0.35}, {110, 0.5}, {160, 0.3}, {200, 0.55}, {250, 0.4}, {300, 0.5}, {350, 0.35}}) do
    for dx = -14, 14 do
      local x = k[1] + dx
      local h = rock_h(x)
      if h > 0 then K.px(x, math.floor(BASE - h * (1 - k[2]) + math.abs(dx) * 0.25), "stone_ink") end
    end
  end
  -- lichen and weathering
  for i = 1, 300 do
    local x, y = 40 + K.rnd(350), 48 + K.rnd(60)
    local c = K.at(x, y)
    if c == "stone" or c == "stone_dk" then K.px(x, y, ({"ochre", "rust", "sage", "stone_ink"})[i % 4 + 1]) end
  end
  -- names daubed in axle grease along the base, where people could reach
  for i = 1, 26 do
    local x, y = 70 + K.rnd(290), BASE - 4 - K.rnd(8)
    if K.at(x, y) == "stone_dk" or K.at(x, y) == "stone" then
      K.rect(x, y, 2 + K.rnd(4), 1, "ink"); K.px(x + K.rnd(3), y - 1, "ink")
    end
  end
  -- boulders and grass at the foot
  for x = 40, 390, 3 do
    if rock_h(x) > 0 then K.px(x, BASE + 1, "grass"); if K.rnd(3) == 0 then K.px(x, BASE, "sage") end end
  end
end)

K.layer("figures", function()
  -- climbers on the crown, a few pixels against 130 feet of granite
  for _, p in ipairs({{196, "red"}, {204, "blue"}, {236, "cream"}}) do
    local top = math.floor(BASE - rock_h(p[1]) + 0.5)
    K.rect(p[1], top - 3, 1, 2, p[2]); K.px(p[1], top - 4, "skin")
  end
  -- wagons corralled on the flat at the rock's west end
  for i, w in ipairs({{60, 116, 1}, {84, 117, 1}, {108, 117, -1}, {130, 116, -1}, {96, 112, 1}}) do K.far_wagon(w[1], w[2], w[3]) end
  -- smoke from the cook fire
  K.px(100, 106, "stone_lt"); K.px(101, 104, "mist"); K.px(100, 102, "mist")
  -- near the viewer, a man with a tar bucket and a woman headed for the rock
  K.person(318, 149, "blue", "deep")
  K.rect(323, 144, 3, 4, "ink"); K.px(323, 143, "wood")
  K.person(306, 148, "red", "bonnet", true)
end)

K.save("location_independence_rock")

-- North Platte upper crossing (432x150).
-- Where the road leaves the North Platte for the Sweetwater, the river is broad, cold and swift,
-- and every season drowned someone. Dark, pine-topped Casper Mountain rises to the south and
-- the Red Buttes glow upriver. In good water wagons forded with the river over the hubs.
local K = dofile(app.params.kit)
local W, H = 432, 150
local N, S = 98, 128

K.canvas(W, H, 184836)

K.layer("sky", function()
  K.sky(W, 96, {{70, 14, 0.8}, {250, 6, 0.7}, {390, 24, 0.5}}, "mist")
end)

K.layer("highlands", function()
  -- Casper Mountain: a long dark ridge, pine on top
  local cm = function(x) return 22 + 8 * math.exp(-((x - 120) / 70) ^ 2) + 3 * math.sin(x / 17) end
  K.ridge(0, 260, N, N, cm, "far_hill", "mist", "haze")
  for x = 0, 260 do
    local top = math.floor(N - cm(x) + 0.5)
    for y = top, top + 3 + math.floor(2 * math.sin(x / 5)) do K.px(x, y, "teal") end
    if x % 4 == 0 then K.px(x, top - 1, "teal") end
  end
  -- the Red Buttes upriver
  local rb = function(x)
    local h = 0
    for _, b in ipairs({{300, 16, 22}, {346, 22, 18}, {392, 18, 24}}) do
      local d = math.abs(x - b[1])
      if d < b[3] then h = math.max(h, b[2] * math.min(1, (b[3] - d) / 6)) end
    end
    return h
  end
  K.ridge(250, W - 1, N, N, rb, "rust", "ochre", "brick_dk")
  for x = 250, W - 1 do
    local h = rb(x)
    if h > 4 then for y = math.floor(N - h) + 3, N, 4 do K.px(x, y, "brick") end end
  end
  K.rect(0, N - 4, W, 5, "sage")
  K.dither(0, N - 5, W, 1, "sage", "clap_sh")
end)

K.layer("river", function()
  K.rect(0, N + 1, W, S - N + 2, "blue")
  for y = N + 1, S + 2 do
    for x = 0, W - 1 do
      if (y < N + 3 and (x + y) % 2 == 0) or ((x * 7 + y * 3) % 37 == 0) then K.px(x, y, "sky_top") end
    end
  end
  for i = 1, 110 do
    local x, y = K.rnd(W), N + 2 + K.rnd(S - N)
    K.rect(x, y, 2 + math.floor((y - N) / 8) + K.rnd(3), 1, (K.rnd(4) == 0) and "white" or "light_blue")
  end
  -- far bank cottonwoods
  for _, t in ipairs({{30, 98}, {64, 99}, {180, 98}, {214, 99}, {420, 98}}) do K.elm(t[1], t[2], 1) end
  -- a sandbar mid-river
  K.ellipse(320, 110, 30, 2, "clap_sh"); K.ellipse(318, 109, 22, 1, "sand"); K.rect(346, 111, 8, 1, "white")
end)

K.layer("near bank", function()
  K.poly({{0, S + 2}, {130, S}, {260, S + 3}, {431, S}, {431, 150}, {0, 150}}, "sand")
  K.poly({{0, S + 6}, {130, S + 4}, {260, S + 8}, {431, S + 4}, {431, 150}, {0, 150}}, "clap_sh")
  for i = 1, 700 do
    local x, y = K.rnd(W), S + K.rnd(22)
    local c = K.at(x, y)
    if c == "clap_sh" then K.px(x, y, ({"sage", "gold", "ochre", "clap_sh"})[i % 4 + 1])
    elseif c == "sand" then K.px(x, y, (i % 2 == 0) and "stone" or "clap_sh") end
  end
  for i = 1, 18 do
    local x, y = K.rnd(W), S + 10 + K.rnd(12)
    if K.at(x, y) ~= "sand" then K.sage(x, y) end
  end
  K.elm(404, 148, 2)
end)

K.layer("figures", function()
  -- a wagon well out in the current, the river over the hubs; the oxen breasting the current
  K.wagon(168, 116, -1)
  K.team(158, 112, -1, {"dark"}, {"light", true})
  K.wade(166, 216, 117, 7)
  K.wade(128, 160, 113, 7)
  -- the next wagon waiting its turn on the near bank
  K.wagon(278, 146, -1)
  K.team(268, 142, -1, {"red"}, {"dark", true})
  K.person(330, 146, "teal", "bonnet", true)
  K.person(340, 147, "blue", "roof")
end)

K.save("location_north_platte")

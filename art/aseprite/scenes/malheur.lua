-- Malheur River (432x150). Not a timber stop.
-- Where the road struck the Malheur, hot springs rose beside the cold river: pools hot enough
-- to cook meat, steaming in the morning air, the ground around crusted white and rust with
-- minerals, willows along the stream and bare sage hills on every side.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184894)

local river = {{-10, 104, 3}, {60, 108, 4}, {120, 104, 4}, {190, 112, 5}, {260, 108, 5}, {330, 118, 6}, {400, 128, 7}, {450, 138, 8}}

K.layer("sky", function()
  K.sky(W, 76, {{60, 14, 0.7}, {280, 8, 0.9}}, "mist")
end)

K.layer("hills", function()
  K.ridge(0, W - 1, 0, 96, function(x) return -(62 + 8 * math.abs(math.sin(x / 43)) + 3 * math.sin(x / 13)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 100, function(x) return -(76 + 6 * math.sin(x / 29 + 1) + 2 * math.sin(x / 7)) end, "clap_sh", "sand", "silt")
  K.rect(0, 94, W, H - 94, "silt_lt")
  for i = 1, 1000 do
    local x, y = K.rnd(W), 70 + K.rnd(80)
    local c = K.at(x, y)
    if c == "silt_lt" or c == "clap_sh" then K.px(x, y, ({"silt", "sand", "sage", "clap_sh"})[i % 4 + 1]) end
  end
  for i = 1, 70 do K.sage(K.rnd(W), 96 + K.rnd(54)) end
end)

K.layer("river", function()
  local water = K.smooth(river)
  K.ribbon(water, "grass", 3)
  K.river(water, false)
  for i = 1, #river - 1 do local a = river[i]; K.willow(a[1] + 14, a[2] - a[3] - 1, 1); if i % 2 == 0 then K.willow(a[1] + 30, a[2] + a[3] + 5, 1) end end
  local road = K.smooth({{440, 150, 4}, {380, 144, 4}, {300, 140, 3}, {220, 134, 3}, {150, 124, 2}, {80, 116, 2}, {-6, 112, 1}})
  K.ribbon(road, "silt", 1); K.ribbon(road, "sand", 0)
end)

K.layer("springs", function()
  -- the hot springs: mineral terraces, clear blue-green pools, a hot run into the river
  for _, p in ipairs({{170, 132, 22, 6}, {214, 126, 12, 4}, {130, 140, 10, 3}}) do
    K.ellipse(p[1], p[2], p[3] + 6, p[4] + 3, "brick_lt")
    K.ellipse(p[1], p[2], p[3] + 3, p[4] + 2, "stone_lt")
    K.ellipse(p[1], p[2], p[3], p[4], "teal"); K.ellipse(p[1] - 2, p[2] - 1, p[3] - 4, math.max(1, p[4] - 2), "haze")
    K.ellipse(p[1] - 4, p[2] - 1, math.max(1, p[3] - 10), 1, "mist")
  end
  K.line(192, 130, 216, 118, "teal"); K.line(193, 131, 217, 119, "stone_lt")
  -- steam rising in drifting puffs, thinning as it goes
  for _, s in ipairs({{170, 126}, {214, 120}, {132, 136}, {190, 124}}) do
    for k = 0, 11 do
      if k % 4 ~= 3 then
        local x = s[1] + math.floor(2 * math.sin(k / 2 + s[1]) + k * 0.7)
        local y = s[2] - k * 3
        local r = 1 + k // 3
        K.ellipse(x, y, r, 1, (k < 5) and "white" or "mist")
        if k < 3 then K.px(x - r, y, "mist") end
      end
    end
  end
end)

K.layer("figures", function()
  K.wagon(330, 146, -1)
  K.team(316, 141, -1, {"red"}, {"light", true})
  K.person(150, 140, "blue", "deep"); K.line(154, 132, 158, 138, "wood")
  K.person(196, 144, "teal", "bonnet", true)
  K.person(352, 148, "rust", "roof")
end)

K.save("location_malheur")

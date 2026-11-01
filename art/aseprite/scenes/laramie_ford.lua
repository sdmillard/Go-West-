-- Laramie River ford below Fort John (432x150).
-- The Laramie comes down clear from the Laramie Range to the North Platte. Westbound wagons
-- ford it about a mile above the mouth to reach Fort John, the adobe post of the American Fur
-- Company on the far (west) bank: a walled square with two corner blockhouses and a gate
-- tower, not the later army buildings. Lakota lodges stand near the post in summer.
-- Laramie Peak shows dark blue on the western horizon.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185311)

local river = {{-10, 150, 14}, {60, 136, 13}, {140, 120, 11}, {220, 108, 9}, {300, 100, 7}, {380, 96, 6}, {440, 94, 5}}

K.layer("sky", function()
  K.sky(W, 74, {{80, 14, 0.8}, {300, 6, 1.0}}, "mist")
end)

K.layer("hills", function()
  -- Laramie Peak and the Black Hills to the west, low bluffs behind the post
  K.ridge(0, W - 1, 0, 84, function(x) local d = (x - 70) / 40; return -(48 - 22 * math.exp(-d * d) - 3 * math.sin(x / 17)) end, "haze", "far_hill", "haze")
  K.ridge(0, W - 1, 0, 90, function(x) return -(70 - 5 * math.sin(x / 41 + 2) - 2 * math.sin(x / 9)) end, "clap_sh", "sand", "clap_sh")
end)

K.layer("bottom", function()
  K.rect(0, 84, W, H - 84, "sage")
  for i = 1, 1200 do K.px(K.rnd(W), 84 + K.rnd(H - 84), ({"sage", "grass", "gold", "sage", "silt_lt"})[i % 5 + 1]) end
  local water = K.smooth(river)
  K.river(water, "sand")
  -- the ford: broken riffles across the shallow gravel
  for i = 1, 180 do
    local x = 150 + K.rnd(60)
    local y = 106 + math.floor((210 - x) * 0.16) + K.rnd(12)
    K.rect(x, y, 1 + K.rnd(3), 1, (K.rnd(3) == 0) and "white" or "light_blue")
  end
  -- the road down to the ford and up the far bank to the gate
  local near = K.smooth({{180, 150, 5}, {176, 136, 4}, {180, 124, 3}})
  K.ribbon(near, "rust", 1); K.ribbon(near, "ochre", 0)
  local far = K.smooth({{196, 104, 2}, {230, 96, 2}, {262, 92, 2}})
  K.ribbon(far, "rust", 0); K.ribbon(far, "ochre", 0)
end)

K.layer("fort", function()
  -- Fort John across the river: adobe walls, two blockhouses, the gate tower
  local x0, y0 = 250, 92
  K.rect(x0, y0 - 9, 74, 9, "clap_sh"); K.rect(x0, y0 - 9, 74, 1, "cream")
  K.rect(x0 + 74, y0 - 8, 8, 8, "silt"); K.rect(x0 + 74, y0 - 8, 8, 1, "clap_sh")
  for _, b in ipairs({{x0 - 4, 14}, {x0 + 66, 14}}) do
    K.rect(b[1], y0 - b[2], 10, b[2], "sand"); K.rect(b[1], y0 - b[2], 10, 1, "cream"); K.rect(b[1] + 8, y0 - b[2] + 1, 2, b[2] - 1, "clap_sh")
    K.rect(b[1] + 3, y0 - b[2] + 4, 2, 2, "deep")
  end
  K.rect(x0 + 30, y0 - 15, 12, 15, "sand"); K.rect(x0 + 30, y0 - 15, 12, 1, "cream"); K.rect(x0 + 34, y0 - 6, 4, 6, "deep")
  K.rect(x0 + 35, y0 - 25, 1, 10, "deep"); K.rect(x0 + 36, y0 - 25, 5, 3, "red"); K.rect(x0 + 36, y0 - 23, 5, 1, "white")
  K.shadow(x0 - 4, y0, 88)
  -- Lakota lodges on the flat beside the post
  for _, l in ipairs({{350, 94, 7}, {372, 92, 6}, {392, 95, 7}, {414, 93, 5}}) do
    K.poly({{l[1], l[2] - l[3] * 2}, {l[1] + l[3], l[2]}, {l[1] - l[3], l[2]}}, "cream")
    K.poly({{l[1], l[2] - l[3] * 2}, {l[1] + l[3], l[2]}, {l[1] + 1, l[2]}}, "clap_sh")
    K.line(l[1] - 1, l[2] - l[3] * 2 - 3, l[1] + 1, l[2] - l[3] * 2 + 1, "wood"); K.line(l[1] + 2, l[2] - l[3] * 2 - 3, l[1], l[2] - l[3] * 2 + 1, "wood")
    K.rect(l[1] - 1, l[2] - 3, 2, 3, "deep")
  end
end)

K.layer("trees", function()
  for _, t in ipairs({{20, 110, 1}, {64, 104, 1}, {108, 98, 1}, {330, 120, 1}, {404, 126, 1}}) do K.elm(t[1], t[2], t[3]) end
  for i = 2, #river - 1 do local a = river[i]; K.willow(a[1] - 20, a[2] - a[3] - 3, 1) end
  K.willow(250, 130, 1); K.willow(300, 138, 1)
end)

K.layer("figures", function()
  -- one wagon in the ford, another waiting its turn on the near bank
  K.wagon(176, 122, -1)
  K.team(150, 117, -1, {"red"}, {"dark"})
  K.wade(124, 224, 120, 4)
  K.wagon(196, 148, -1)
  K.team(170, 144, -1, {"dark"}, {"light", true})
  K.person(250, 146, "blue", "hat"); K.person(262, 147, "red", "bonnet", true)
end)

K.save("location_laramie_ford")

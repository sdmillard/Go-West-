-- Great Salt Lake City, 1848 (432x150).
-- A year old. The Saints lived in and around the "Old Fort": a square of adobe and log houses
-- built wall to wall, their backs forming the stockade, on the bench below the Wasatch. Beyond
-- it the city was only surveyed: very wide streets staked across the sage, a few new cabins,
-- irrigation ditches led from City Creek, and thin crops after the crickets of 1848. No temple,
-- no tabernacle yet. The Wasatch rises steeply behind, with snow on the high peaks.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184847)

local function adobe_house(x, y, w, h)
  K.rect(x, y - h, w, h, "silt_lt"); K.rect(x, y - h, w, 1, "clap_sh")
  for i = 1, w * h // 6 do K.px(x + K.rnd(w), y - h + K.rnd(h), (K.rnd(2) == 0) and "silt" or "sand") end
  K.rect(x - 1, y - h - 2, w + 2, 2, "dirt_dk"); K.rect(x - 1, y - h - 3, w + 2, 1, "silt")
  K.rect(x + 2, y - 6, 3, 6, "deep"); K.rect(x + w - 6, y - h + 3, 3, 3, "ink")
end
local function cabin(x, y, w, h)
  for yy = y - 1, y - h, -2 do K.rect(x, yy, w, 2, "wood"); K.rect(x, yy, w, 1, "ochre") end
  K.poly({{x - 2, y - h}, {x + w // 2, y - h - 5}, {x + w + 2, y - h}}, "roof")
  K.rect(x + w // 2 - 1, y - 6, 3, 6, "deep")
end

K.layer("sky", function()
  K.sky(W, 60, {{60, 10, 0.7}, {200, 18, 0.9}}, "mist")
end)

K.layer("wasatch", function()
  local top = function(x) return 56 - 16 * math.abs(math.sin(x / 37)) - 9 * math.abs(math.sin(x / 13 + 1)) end
  K.ridge(0, W - 1, 0, 96, function(x) return -top(x) end, "far_hill", "mist", "haze")
  for x = 0, W - 1 do
    local t = math.floor(top(x) + 0.5)
    local depth = math.floor(40 - t) + ((x * 7) % 3)
    for y = t, t + depth do
      local lit = top(x + 1) < top(x - 1)
      K.px(x, y, lit and (((x + y) % 6 == 0) and "light_blue" or "white") or (((x + y) % 5 == 0) and "white" or "light_blue"))
    end
  end
  -- the foothill bench, sage-grey, with City Creek canyon opening at the right
  K.ridge(0, W - 1, 0, 100, function(x) return -(78 + 3 * math.sin(x / 23) - 6 * math.exp(-((x - 360) / 20) ^ 2)) end, "sage", "far_hill", "teal")
  K.poly({{350, 76}, {360, 84}, {372, 76}}, "teal")
end)

K.layer("city", function()
  K.rect(0, 92, W, H - 92, "sage")
  for i = 1, 1200 do local x, y = K.rnd(W), 92 + K.rnd(H - 92); K.px(x, y, ({"silt_lt", "sage", "stone_lt", "ochre"})[i % 4 + 1]) end
  for i = 1, 40 do K.sage(K.rnd(W), 96 + K.rnd(54)) end
  -- the very wide surveyed streets, staked out and only beaten here and there
  for _, y in ipairs({100, 124}) do K.rect(0, y, W, 6, "silt"); K.rect(0, y, W, 1, "silt_dk") end
  for _, x in ipairs({90, 250}) do K.poly({{x, 92}, {x + 10, 92}, {x + 22 + (x - 200) // 8, H}, {x + 4 + (x - 200) // 8, H}}, "silt") end
  for x = 0, W, 24 do K.rect(x, 99, 1, 2, "wood"); K.rect(x + 6, 123, 1, 2, "wood") end
  -- a ditch from City Creek running along the street, and thin fields of wheat and corn
  K.line(370, 90, 360, 99, "blue"); K.rect(0, 107, 360, 1, "blue")
  for _, f in ipairs({{290, 132, 70, 14}, {14, 112, 60, 10}, {300, 108, 50, 12}}) do
    K.rect(f[1], f[2], f[3], f[4], "silt_dk")
    for xx = f[1] + 1, f[1] + f[3] - 1, 3 do for yy = f[2] + 1, f[2] + f[4] - 1, 2 do if (xx + yy) % 5 ~= 0 then K.px(xx, yy, (yy % 4 == 1) and "gold" or "sage") end end end
  end
  -- scattered new cabins out on the lots
  cabin(28, 104, 16, 8); cabin(312, 104, 14, 7); cabin(400, 122, 16, 8)
end)

K.layer("fort", function()
  -- the Old Fort: houses built side by side, their blank backs facing out as the wall
  local x0, y0, w = 120, 120, 150
  K.rect(x0, y0 - 16, w, 16, "silt_lt")
  for xx = x0, x0 + w - 1, 10 do K.rect(xx, y0 - 16, 1, 16, "silt"); K.rect(xx + 1, y0 - 18, 8, 2, "dirt_dk") end
  for i = 1, 300 do K.px(x0 + K.rnd(w), y0 - 16 + K.rnd(16), (K.rnd(2) == 0) and "silt" or "sand") end
  -- a log section of the wall and the gate
  for yy = y0 - 1, y0 - 16, -2 do K.rect(x0 + 100, yy, 30, 2, "wood"); K.rect(x0 + 100, yy, 30, 1, "ochre") end
  K.rect(x0 + 66, y0 - 12, 14, 12, "deep"); K.rect(x0 + 67, y0 - 11, 12, 11, "ink")
  K.rect(x0 + 66, y0 - 14, 14, 2, "wood")
  -- roofs of the houses inside the square showing over the wall
  for i = 0, 6 do adobe_house(x0 + 6 + i * 20, y0 - 18, 14, 6) end
  K.shadow(x0, y0 + 1, w)
  -- the liberty pole the pioneers raised
  K.rect(x0 + 74, 70, 1, 32, "wood"); K.rect(x0 + 75, 71, 10, 6, "red"); for y = 72, 76, 2 do K.rect(x0 + 75, y, 10, 1, "white") end; K.rect(x0 + 75, 71, 4, 3, "blue")
end)

K.layer("figures", function()
  K.wagon(330, 146, -1)
  K.team(316, 141, -1, {"dark"}, {"light", true})
  K.person(214, 132, "teal", "bonnet", true); K.person(224, 133, "blue", "deep")
  K.person(70, 140, "rust", "roof"); K.rect(74, 134, 1, 8, "wood")
  K.person(160, 138, "red", "bonnet", true)
  K.ox(40, 146, 1, "red")
end)

K.save("location_salt_lake")

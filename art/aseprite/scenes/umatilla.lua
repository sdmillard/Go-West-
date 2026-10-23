-- Umatilla River (432x150).
-- Coming down off the Blue Mountains the road reaches the Umatilla, a cottonwood-lined river in
-- dry, rolling bunchgrass hills: the homeland of the Umatilla, Cayuse and Walla Walla peoples,
-- whose horse herds diarists remarked on. A village of mat lodges stands well off the road.
-- The pine-dark Blue Mountains rise behind.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184837)

-- a long A-frame lodge of tule mats, sunlit on its left slope
local function lodge(x, y, len)
  K.poly({{x, y}, {x + 4, y - 6}, {x + len - 4, y - 6}, {x + len, y}}, "ochre")
  K.poly({{x, y}, {x + 4, y - 6}, {x + len / 2, y - 6}, {x + len / 2 - 2, y}}, "gold")
  for i = x + 3, x + len - 3, 3 do K.px(i, y - 3, "rust") end
  K.rect(x + 4, y - 7, len - 8, 1, "wood")
  K.rect(x + math.floor(len / 2) - 1, y - 3, 2, 3, "deep")
  K.px(x + 6, y - 9, "mist"); K.px(x + 7, y - 11, "mist")
end

K.layer("sky", function()
  K.sky(W, 100, {{100, 16, 0.7}, {300, 8, 1.0}}, "mist")
end)

K.layer("blue mountains", function()
  local bm = function(x) return 34 + 8 * math.sin(x / 47 + 1) + 4 * math.sin(x / 13) end
  K.ridge(0, W - 1, 0, 100, function(x) return -(88 - bm(x)) end, "far_hill", "mist", "haze")
  for x = 0, W - 1 do
    local top = math.floor(88 - bm(x) + 0.5)
    local line = top + 4 + math.floor(3 * math.sin(x / 9))
    for y = line, 100 do K.px(x, y, ((x + 2 * y) % 7 == 0) and "haze" or "teal") end
    if x % 3 == 0 then K.px(x, line - 1, "teal") end
  end
end)

K.layer("hills", function()
  local h1 = function(x) return 20 + 10 * math.sin(x / 38 + 2) + 4 * math.sin(x / 15) end
  K.ridge(0, W - 1, 104, 108, h1, "gold", "sand", "ochre")
  for x = 0, W - 1 do
    if h1(x + 2) - h1(x - 2) < -1 then
      local top = math.floor(104 - h1(x) + 0.5)
      for y = top + 3, top + 12 do if (x + y) % 2 == 0 and K.at(x, y) == "gold" then K.px(x, y, "ochre") end end
    end
  end
  for i = 1, 900 do
    local x, y = K.rnd(W), 74 + K.rnd(36)
    if K.at(x, y) == "gold" then K.px(x, y, (i % 3 == 0) and "sand" or "ochre") end
  end
end)

K.layer("bottom", function()
  K.rect(0, 106, W, H - 106, "sage")
  for i = 1, 1400 do
    local x, y = K.rnd(W), 106 + K.rnd(44)
    K.px(x, y, ({"gold", "grass", "clap_sh", "sage", "ochre"})[i % 5 + 1])
  end
  local river = K.smooth({{-6, 116, 3}, {80, 112, 3}, {160, 120, 4}, {240, 114, 4}, {320, 124, 5}, {440, 120, 5}})
  K.ribbon(river, "grass", 4)
  K.river(river, "clap_sh")
  local road = K.smooth({{440, 104, 1}, {380, 110, 2}, {320, 134, 4}, {250, 140, 5}, {160, 144, 6}, {-6, 148, 7}})
  K.ribbon(road, "ochre", 1); K.ribbon(road, "sand", 0)
end)

K.layer("village", function()
  -- cottonwoods along the river, mat lodges on the far bench, horses grazing
  for _, t in ipairs({{40, 112}, {104, 112}, {290, 114}, {352, 120}, {410, 116}}) do K.elm(t[1], t[2], 1) end
  for _, w in ipairs({{70, 114}, {150, 118}, {226, 118}, {300, 120}, {380, 122}}) do K.willow(w[1], w[2], 1) end
  lodge(132, 106, 22); lodge(160, 104, 18); lodge(184, 106, 24)
  for _, h in ipairs({{214, 104, "rust"}, {222, 106, "deep"}, {232, 103, "cream"}, {244, 105, "rust"}, {256, 104, "wood"}, {226, 101, "ochre"}}) do
    local x, y = h[1], h[2]
    K.rect(x, y - 3, 5, 2, h[3]); K.px(x + 5, y - 4, h[3]); K.px(x + 6, y - 5, h[3])
    K.px(x, y - 1, "deep"); K.px(x + 4, y - 1, "deep"); K.px(x - 1, y - 3, h[3])
  end
end)

K.layer("figures", function()
  -- a wagon coming down the road toward the river crossing
  K.wagon(300, 140, -1)
  K.team(290, 136, -1, {"red"}, {"light", true})
  K.person(356, 140, "blue", "deep")
  K.far_wagon(392, 112, -1)
end)

K.save("location_umatilla")

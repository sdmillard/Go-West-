-- Devil's Gate (432x150).
-- The Sweetwater River cuts a narrow cleft, a few yards wide and hundreds of feet deep,
-- through a spur of bare granite. Wagons could not pass the gap and went around the ridge;
-- emigrants climbed in to look. Here the river leaves the cleft and winds across the sage
-- flats toward the viewer while the trail swings round the ridge's end.
local K = dofile(app.params.kit)
local W, H = 432, 150
local GROUND = 96
local GAP = 218

K.canvas(W, H, 184826)

local function dome(x, c, w, h) local d = (x - c) / w; return (math.abs(d) < 1) and h * (1 - d * d) ^ 0.7 or 0 end
local function ridge_height(x)
  local h = math.max(dome(x, 120, 64, 36), dome(x, 190, 40, 56), dome(x, 248, 42, 58), dome(x, 318, 60, 40), dome(x, 70, 40, 22), dome(x, 390, 44, 22))
  -- crags break the smooth domes
  return h + ((h > 6) and (2 * math.sin(x / 3.1) + 1.5 * math.sin(x / 1.7 + 1)) or 0)
end

K.layer("sky", function()
  K.sky(W, 82, {{30, 14, 1.1}, {300, 22, 0.8}, {404, 8, 0.5}}, "mist")
end)

K.layer("distance", function()
  -- Sweetwater valley rim and far blue hills
  K.ridge(0, W - 1, 0, GROUND, function(x) return -(74 + 4 * math.sin(x / 40) + 2 * math.sin(x / 9)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, GROUND, function(x) return -(84 + 3 * math.sin(x / 27 + 2)) end, "sage", "clap_sh", "grass")
end)

K.layer("plain", function()
  K.rect(0, GROUND, W, H - GROUND, "clap_sh")
  for i = 1, 900 do
    local x, y = K.rnd(W), GROUND + K.rnd(H - GROUND)
    K.px(x, y, ({"sand", "ochre", "sage", "clap_sh"})[i % 4 + 1])
  end
  -- grassy bottomland along the river
  local course = K.smooth({{GAP, 96, 3}, {200, 104, 5}, {150, 114, 8}, {108, 126, 11}, {150, 140, 14}, {120, 156, 16}})
  K.ribbon(course, "sage", 9)
  K.ribbon(course, "grass", 5)
  K.river(K.smooth({{GAP, 96, 2}, {200, 104, 3}, {150, 114, 4}, {108, 126, 6}, {150, 140, 7}, {120, 156, 8}}), "sand")
  -- the trail rounds the east end of the ridge
  local trail = K.smooth({{440, 128, 7}, {370, 124, 6}, {330, 112, 4}, {372, 100, 3}, {420, 94, 2}})
  K.ribbon(trail, "ochre", 1)
  K.ribbon(trail, "sand", 0)
  for i = 1, 60 do
    local x, y = K.rnd(W), GROUND + 4 + K.rnd(H - GROUND - 4)
    local c = K.at(x, y)
    if c ~= "blue" and c ~= "sky_top" and c ~= "grass" and c ~= "sand" then K.sage(x, y) end
  end
end)

K.layer("granite ridge", function()
  K.ridge(30, 430, GROUND + 2, GROUND + 2, ridge_height, "stone_dk", "stone", "stone_ink")
  -- jointed granite blocks: dark cracks with a lit upper-left lip
  for i = 1, 260 do
    local x, y = 40 + K.rnd(380), 38 + K.rnd(60)
    if K.at(x, y) == "stone_dk" then
      local len = 3 + K.rnd(6)
      if i % 2 == 0 then
        K.line(x, y, x + len, y + K.rnd(3) - 1, "stone_ink"); K.line(x, y - 1, x + len - 1, y - 1 + K.rnd(2), "stone")
      else
        K.line(x, y, x + K.rnd(3) - 1, y + len, "stone_ink"); K.line(x - 1, y, x - 1, y + len - 1, "stone")
      end
    end
  end
  -- warm lichen and sage pockets on ledges
  for i = 1, 90 do
    local x, y = 40 + K.rnd(380), 46 + K.rnd(52)
    if K.at(x, y) == "stone_dk" then K.px(x, y, ({"clap_sh", "sage", "rust"})[i % 3 + 1]) end
  end
  -- the cleft: deep shadow, a shaded west wall and a sunlit east wall
  for x = GAP - 6, GAP + 6 do
    local top = math.floor(GROUND + 2 - ridge_height(x) + 0.5)
    for y = top, GROUND + 1 do
      local c = "stone_ink"
      if x >= GAP + 3 then c = (x >= GAP + 5) and "stone" or "stone_dk" end
      if x == GAP - 1 or x == GAP then c = "ink" end
      K.px(x, y, c)
    end
  end
  K.rect(GAP - 2, GROUND - 3, 5, 5, "blue")
  -- boulder apron at the foot
  for _, b in ipairs({{60, 98, 4, 2}, {96, 99, 5, 3}, {248, 98, 4, 2}, {300, 99, 6, 3}, {356, 98, 4, 2}, {186, 99, 3, 2}}) do
    K.ellipse(b[1], b[2], b[3], b[4], "stone_dk")
    K.ellipse(b[1] - 1, b[2] - 1, b[3] - 1, b[4] - 1, "stone")
    K.px(b[1] - b[3] + 1, b[2] - 1, "stone_lt")
  end
end)

K.layer("figures", function()
  -- a wagon rounding the ridge, and two emigrants walking back from a look into the gap
  K.wagon(316, 124, -1)
  K.team(306, 124, -1, {"red"}, {"dark", true})
  K.line(304, 117, 291, 110, "deep")
  K.person(236, 112, "red", "bonnet", true)
  K.person(244, 113, "deep", "roof")
end)

K.save("location_devils_gate")

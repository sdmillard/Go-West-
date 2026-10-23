-- Devil's Gate (432x150).
-- The Sweetwater River cuts a narrow cleft, a few yards wide and hundreds of feet deep,
-- through a spur of bare granite. Wagons could not pass the gap and went around the ridge;
-- emigrants climbed in to look. Here the river leaves the cleft and winds across the sage
-- flats toward the viewer while the trail swings round the ridge's end.
local K = dofile(app.params.kit)
local W, H = 432, 150
local GROUND = 104
local GAP = 218

K.canvas(W, H, 184826)

local function dome(x, c, w, h) local d = (x - c) / w; return (math.abs(d) < 1) and h * (1 - d * d) ^ 0.7 or 0 end
local function ridge_height(x)
  local h = math.max(dome(x, 120, 70, 52), dome(x, 188, 46, 82), dome(x, 250, 48, 86), dome(x, 322, 66, 58), dome(x, 64, 46, 30), dome(x, 392, 48, 30))
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
  local course = K.smooth({{GAP, 104, 3}, {204, 110, 4}, {166, 117, 6}, {124, 127, 9}, {150, 140, 12}, {116, 156, 15}})
  K.ribbon(course, "sage", 9)
  K.ribbon(course, "grass", 5)
  K.river(K.smooth({{GAP, 104, 1}, {204, 110, 2}, {166, 117, 3}, {124, 127, 5}, {150, 140, 6}, {116, 156, 8}}), "sand")
  -- the trail runs along the foot of the ridge, then swings south toward the viewer
  local trail = K.smooth({{440, 108, 1}, {360, 110, 2}, {290, 113, 3}, {256, 124, 5}, {244, 140, 7}, {250, 158, 9}})
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
  -- broad light and shade: faces turned to the upper-left sun are pale, the rest falls into shadow
  local base = function(x) return math.max(dome(x, 120, 70, 52), dome(x, 188, 46, 82), dome(x, 250, 48, 86), dome(x, 322, 66, 58), dome(x, 64, 46, 30), dome(x, 392, 48, 30)) end
  for x = 30, 430 do
    local top = math.floor(GROUND + 2 - ridge_height(x) + 0.5)
    local slope = base(x + 3) - base(x - 3)
    local reach = math.floor(math.min(40, base(x) * 0.6))
    for y = top, math.min(GROUND + 1, top + reach) do
      if slope < -3 then K.px(x, y, ((y - top) > reach - 6 and (x + y) % 2 == 0) and "stone_dk" or "stone_ink")
      elseif slope < -1 and (x + y) % 2 == 0 then K.px(x, y, "stone_ink")
      elseif slope > 2 and y < top + reach * 0.5 then K.px(x, y, ((y - top) > reach * 0.4 and (x + y) % 2 == 0) and "stone_dk" or "stone")
      end
    end
  end
  -- jointed granite blocks: dark cracks with a lit upper-left lip
  for i = 1, 240 do
    local x, y = 30 + K.rnd(390), 18 + K.rnd(86)
    local here = K.at(x, y)
    if here == "stone_dk" or here == "stone" then
      local len = 3 + K.rnd(6)
      if i % 2 == 0 then
        K.line(x, y, x + len, y + K.rnd(3) - 1, "stone_ink"); K.line(x, y - 1, x + len - 1, y - 1 + K.rnd(2), "stone")
      else
        K.line(x, y, x + K.rnd(3) - 1, y + len, "stone_ink"); K.line(x - 1, y, x - 1, y + len - 1, "stone")
      end
    end
  end
  -- warm lichen and sage pockets on ledges
  for i = 1, 150 do
    local x, y = 30 + K.rnd(390), 26 + K.rnd(78)
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
  for _, b in ipairs({{60, 106, 4, 2}, {96, 107, 5, 3}, {270, 106, 4, 2}, {300, 107, 6, 3}, {356, 106, 4, 2}, {186, 107, 3, 2}}) do
    K.ellipse(b[1], b[2], b[3], b[4], "stone_dk")
    K.ellipse(b[1] - 1, b[2] - 1, b[3] - 1, b[4] - 1, "stone")
    K.px(b[1] - b[3] + 1, b[2] - 1, "stone_lt")
  end
end)

K.layer("figures", function()
  -- the gap is some 370 feet deep: a wagon train at the ridge's foot is tiny against it
  K.far_wagon(330, 111, -1)
  K.far_wagon(362, 110, -1)
  K.far_wagon(396, 109, -1)
  -- near the viewer, a wagon has pulled off the road while two emigrants look back at the gate
  K.wagon(356, 146, -1)
  K.team(346, 146, -1, {"red"}, {"dark", true})
  K.person(286, 144, "red", "bonnet", true)
  K.person(296, 145, "deep", "roof")
end)

K.save("location_devils_gate")

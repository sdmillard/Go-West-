-- Fandango Pass (432x150).
-- The top of the Warner Mountains among yellow pines. The road comes up out of Surprise Valley
-- and here drops so steeply to Goose Lake, shining far below to the west, that the wagons are
-- let down with ropes round the trees and the wheels locked.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185177)

local function pine(x, y, h)
  -- ponderosa: bare reddish trunk, clumped crown high up
  K.rect(x - 1, y - h, 2, h, "rust"); K.px(x - 1, y - h // 2, "brick_lt")
  local dk, md, lt = "pine", "leaf", "grass"
  if K.season == "winter" then lt = "white" end
  local n = 3 + h // 14
  for i = 0, n - 1 do
    local cy = y - h + i * (h // (n + 2))
    local r = math.floor(3 + i * 1.3 + h / 14)
    K.ellipse(x + ((i % 2 == 0) and -2 or 2), cy, r, 3, dk)
    K.ellipse(x + ((i % 2 == 0) and -3 or 1), cy - 1, r - 2, 2, md)
    K.px(x - r + 1, cy - 2, lt); K.px(x - r + 3, cy - 2, lt)
  end
end

K.layer("sky", function()
  K.sky(W, 70, {{60, 10, 0.8}, {340, 6, 0.7}}, "mist")
end)

K.layer("view", function()
  -- far west: the Goose Lake basin below, ranges beyond
  K.ridge(0, W - 1, 0, 92, function(x) return -(56 - 6 * math.sin(x / 47) - 3 * math.sin(x / 13)) end, "far_hill", "mist", "haze")
  K.rect(0, 66, W, 30, "far_hill")
  K.poly({{-1, 70}, {200, 68}, {300, 72}, {260, 78}, {-1, 80}}, "light_blue")
  K.rect(0, 72, 240, 1, "mist")
  for i = 1, 60 do K.rect(K.rnd(240), 70 + K.rnd(8), 3, 1, "sea") end
  K.ridge(0, W - 1, 0, H - 1, function(x) return -(80 + 4 * math.sin(x / 23)) end, "teal", "haze", "pine")
  -- timber on the slopes below, falling away toward the lake
  for i = 1, 2400 do local x, y = K.rnd(W), 80 + K.rnd(70); if K.at(x, y) == "teal" then K.px(x, y, ({"pine", "pine", "leaf", "haze"})[i % 4 + 1]) end end
end)

K.layer("mountain", function()
  -- the pass: the near slope falls away to the left
  K.ridge(0, W - 1, 0, H - 1, function(x) local f = x / W; return -(150 - f * 66 - 10 * f * f * math.sin(x / 17) - 3 * math.sin(x / 7)) end, "sage", "gold", "silt")
  for i = 1, 1800 do local x, y = K.rnd(W), 80 + K.rnd(70); local c = K.at(x, y); if c == "sage" then K.px(x, y, ({"grass", "silt_lt", "gold", "leaf", "sage"})[i % 5 + 1]) end end
  -- the road plunging down to the left
  local road = K.smooth({{440, 92, 3}, {380, 96, 3}, {320, 104, 3}, {260, 116, 4}, {200, 130, 4}, {150, 146, 5}, {120, 156, 5}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
  for _, b in ipairs({{300, 120, 4, 2}, {210, 108, 5, 2}, {380, 112, 4, 2}}) do K.boulder(b[1], b[2], b[3], b[4]) end
end)

K.layer("trees", function()
  for _, t in ipairs({{20, 140, 40}, {60, 130, 34}, {96, 120, 30}, {170, 112, 28}, {230, 100, 26}, {330, 94, 30}, {360, 98, 34}, {404, 92, 36}, {420, 132, 46}, {270, 148, 44}, {140, 98, 18}, {300, 90, 20}}) do pine(t[1], t[2], t[3]) end
end)

K.layer("figures", function()
  -- a wagon being let down: rope from the rear axle round a tree, men holding it back
  K.wagon(200, 132, -1)
  K.team(186, 128, -1, {"dark"}, {"light", true})
  K.line(248, 128, 272, 126, "sand"); K.line(272, 126, 270, 128, "sand")
  K.person(256, 130, "blue", "hat"); K.person(264, 128, "red", "hat")
  K.wagon(330, 104, -1)
  K.team(316, 100, -1, {"red"}, {"dark"})
  K.person(350, 106, "teal", "bonnet", true)
end)

K.save("location_fandango_pass")

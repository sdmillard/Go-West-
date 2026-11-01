-- Canyon Creek (432x150).
-- A narrow forested canyon with the creek for its road: wagons crossing and recrossing the
-- water among boulders and fallen timber, steep timbered walls on both sides shutting out the
-- sky. Here the November rains caught the 1846 companies.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185251)

K.layer("sky", function()
  K.sky(W, 100, {{216, 8, 0.6}}, "mist")
end)

K.layer("walls", function()
  -- far: the canyon bending away in grey-green haze
  K.ridge(0, W - 1, 0, 112, function(x) return -(46 + 12 * math.abs(math.sin(x / 31)) + 3 * math.sin(x / 7)) end, "haze", "far_hill", "teal")
  for i = 1, 22 do local x = 140 + K.rnd(150); K.conifer(x, 60 + math.floor(12 * math.abs(math.sin(x / 31))) + 6 + K.rnd(30), 6 + K.rnd(5), "teal", "haze", "far_hill") end
  -- near walls: steep and dark with fir; ragged skylines, not ruled slopes
  local function lwall(x) return 6 + 150 * (x / 200) ^ 1.3 + 8 * math.sin(x / 13) + 4 * math.sin(x / 5) end
  local function rwall(x) return 6 + 150 * ((W - 1 - x) / 190) ^ 1.3 + 8 * math.sin(x / 11 + 1) + 4 * math.sin(x / 4.3) end
  K.ridge(0, W - 1, 0, H - 1, function(x) return -math.min(150, math.min(lwall(x), rwall(x))) end, "pine", "leaf", "ink")
  for i = 1, 3000 do local x, y = K.rnd(W), K.rnd(H); if K.at(x, y) == "pine" then K.px(x, y, ({"ink", "leaf", "pine", "teal", "ink"})[K.rnd(5) + 1]) end end
  for i = 1, 34 do
    local x = K.rnd(200); local y = math.floor(lwall(x)) + 6 + K.rnd(40)
    if y < 150 then K.conifer(x, y, 14 + K.rnd(14)) end
    x = W - 1 - K.rnd(190); y = math.floor(rwall(x)) + 6 + K.rnd(40)
    if y < 150 then K.conifer(x, y, 14 + K.rnd(14)) end
  end
end)

K.layer("creek", function()
  -- the creek bed is the road: gravel bars, water, boulders, fallen logs
  for y = 96, H - 1 do
    local half = 18 + (y - 96) * 2.6
    local cx = 216 + math.floor(6 * math.sin(y / 9))
    K.rect(math.floor(cx - half), y, math.floor(2 * half), 1, "stone_dk")
  end
  for i = 1, 900 do local x, y = K.rnd(W), 96 + K.rnd(54); if K.at(x, y) == "stone_dk" then K.px(x, y, ({"stone", "silt", "stone_dk", "stone_lt"})[K.rnd(4) + 1]) end end
  local water = K.smooth({{214, 96, 3}, {224, 108, 5}, {200, 122, 8}, {236, 136, 10}, {190, 152, 12}})
  K.river(water, false)
  for _, b in ipairs({{170, 116, 5, 3}, {262, 128, 6, 3}, {140, 140, 7, 3}, {300, 146, 8, 3}, {230, 112, 3, 2}}) do
    K.ellipse(b[1], b[2], b[3], b[4], "stone_dk"); K.ellipse(b[1] - 1, b[2] - 1, b[3] - 2, b[4] - 1, "stone"); K.px(b[1] - b[3] + 2, b[2] - b[4] + 1, "stone_lt")
  end
  -- fallen timber across the bed
  for d = 0, 2 do K.line(150, 126 + d, 192, 121 + d, (d == 0) and "ochre" or ((d == 1) and "wood" or "deep")) end
  K.ellipse(150, 127, 2, 2, "ochre"); K.px(150, 127, "wood")
  for d = 0, 1 do K.line(256, 106 + d, 284, 111 + d, (d == 0) and "wood" or "deep") end
end)

K.layer("figures", function()
  K.wagon(204, 134, 1)
  K.team(254, 130, 1, {"dark"}, {"red"})
  K.wade(202, 250, 134, 4); K.wade(254, 282, 130, 4)
  K.person(196, 142, "blue", "hat"); K.person(296, 134, "teal", "bonnet", true)
  K.wade(192, 200, 142, 4)
  K.far_wagon(220, 104, 1)
  -- a broken, abandoned wagon on a bar
  K.rect(110, 140, 30, 4, "blue"); K.rect(112, 136, 4, 4, "wood"); K.wheel(118, 145, 4); K.line(140, 146, 150, 140, "wood")
end)

K.save("location_canyon_creek")

-- River crossing backdrop for the travel screen (432x150).
-- Sky, the far shore's timber, and the two landing banks. The water is left transparent:
-- ui/trail_view.gd fills it (clear for fords and floats, muddy for ferries) and animates the
-- ripples, so wagons and swimmers can sit in it. The bank shapes match NEAR_BANK and
-- FAR_BANK in trail_view.gd, which clips the water to them.
local K = dofile(app.params.kit)
local W, H = 432, 150
local NEAR = {{0, 96}, {43, 108}, {84, 150}, {0, 150}}
local FAR = {{432, 82}, {399, 86}, {333, 150}, {432, 150}}

K.canvas(W, H, 184840)

K.layer("sky", function()
  K.sky(W, 64, {{70, 14, 0.8}, {300, 8, 0.6}}, "mist")
end)

K.layer("far shore", function()
  -- low bluffs, then the cottonwood and willow timber along the far side
  K.ridge(0, W - 1, 64, 66, function(x) return 16 + 6 * math.sin(x / 41 + 1) + 2 * math.sin(x / 13) end, "far_hill", "mist", "haze")
  K.rect(0, 64, W, 14, "leaf")
  for x = -4, W + 4, 5 do
    local h = 5 + K.rnd(5)
    K.ellipse(x, 70 - h, 4 + K.rnd(2), h, (K.rnd(3) == 0) and "pine" or "leaf")
    K.ellipse(x - 1, 69 - h, 2, math.max(1, h - 3), "grass")
  end
  for i = 1, 260 do
    local x, y = K.rnd(W), 66 + K.rnd(11)
    K.px(x, y, ({"pine", "grass", "leaf", "teal"})[i % 4 + 1])
  end
  -- a strip of wet sand where the far shore meets the water
  K.rect(0, 76, W, 2, "clap_sh"); K.dither(0, 76, W, 1, "clap_sh", "sand")
end)

K.layer("banks", function()
  K.poly(NEAR, "sand")
  K.poly(FAR, "sage")
  for i = 1, 1400 do
    local x, y = K.rnd(W), 80 + K.rnd(70)
    local c = K.at(x, y)
    if c == "sand" then K.px(x, y, ({"clap_sh", "cream", "ochre", "sand"})[i % 4 + 1])
    elseif c == "sage" then K.px(x, y, ({"grass", "gold", "leaf", "sage"})[i % 4 + 1]) end
  end
  -- wet, darker edge where each bank meets the water
  local function edge(a, b, c1, c2)
    K.line(a[1], a[2], b[1], b[2], c1)
    K.line(a[1] + ((a[1] < 216) and -1 or 1), a[2], b[1] + ((a[1] < 216) and -1 or 1), b[2], c2)
  end
  edge(NEAR[1], NEAR[2], "dirt_dk", "clap_sh"); edge(NEAR[2], NEAR[3], "dirt_dk", "clap_sh")
  edge(FAR[1], FAR[2], "dirt_dk", "grass"); edge(FAR[2], FAR[3], "dirt_dk", "grass")
  -- wagon ruts running down into the water and up out of it
  K.line(0, 118, 50, 126, "dirt_dk"); K.line(0, 124, 54, 134, "dirt_dk")
  K.line(0, 119, 50, 127, "ochre"); K.line(0, 125, 54, 135, "ochre")
  K.line(374, 106, 431, 99, "grass"); K.line(368, 116, 431, 109, "grass")
  K.line(374, 107, 431, 100, "gold"); K.line(368, 117, 431, 110, "gold")
  -- willows on the near point, a cottonwood and sage on the far landing
  K.willow(10, 104, 1); K.willow(30, 110, 1)
  K.elm(420, 92, 1)
  -- grass tufts on the far landing, driftwood on the near bar
  for _, g in ipairs({{404, 128}, {418, 140}, {392, 146}, {380, 132}, {424, 120}}) do
    K.px(g[1], g[2], "leaf"); K.px(g[1] - 1, g[2] - 1, "grass"); K.px(g[1] + 1, g[2] - 2, "grass"); K.px(g[1], g[2] - 2, "leaf")
  end
  K.line(14, 138, 32, 135, "stone_dk"); K.line(15, 139, 31, 136, "stone_ink"); K.px(24, 134, "stone_dk")
end)

K.save("river_crossing")

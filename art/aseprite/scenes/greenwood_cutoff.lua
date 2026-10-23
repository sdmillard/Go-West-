-- The Greenwood (Sublette) Cutoff, the dry drive (432x150).
-- From the Big Sandy the cutoff struck due west for the Green River, saving the long bend by
-- Fort Bridger at the cost of some forty to fifty miles without water or grass. Parties filled
-- every keg, rested the stock and often drove through the night. The country is rolling
-- sagebrush and greasewood with pale alkali flats; far ahead the Wyoming Range still carries
-- snow above the Green. Dead and abandoned oxen marked the road.
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 82

K.canvas(W, H, 1844)

K.layer("sky", function()
  -- a hot washed-out sky, one thin cloud, haze thick at the horizon
  K.sky(W, HORIZON, {{300, 16, 0.6}}, "cream")
  K.dither(0, HORIZON - 6, W, 4, "cream", "mist")
end)

K.layer("ranges", function()
  -- the Wyoming Range far to the west, faint blue with the last snow on its crest
  -- an uneven crest built from several rounded summits and saddles, not a row of teeth
  local tops = {{34, 11, 22}, {70, 17, 16}, {96, 13, 30}, {148, 19, 20}, {170, 15, 26}, {214, 12, 34}, {252, 9, 22}}
  K.peaks(0, 300, HORIZON - 1, HORIZON + 1, function(x)
    local h = 1
    for _, p in ipairs(tops) do
      local d = (x - p[1]) / p[3]
      h = math.max(h, p[2] / (1 + d * d * 2.2))
    end
    h = h + 0.7 * math.sin(x / 5.3) * math.min(1, h / 8)
    return h * math.max(0, math.min(1, (300 - x) / 50))
  end, 12)
  K.ridge(0, W - 1, HORIZON + 1, HORIZON + 3, function(x) return 3 + 2 * math.sin(x / 31) + math.sin(x / 9) end, "far_hill", "mist", "haze")
end)

K.layer("plain", function()
  K.rect(0, HORIZON + 2, W, H - HORIZON - 2, "clap_sh")
  -- long low swells, each a little warmer and plainer than the one behind
  K.ridge(0, W - 1, 96, 100, function(x) return 6 + 4 * math.sin(x / 53 + 1) + math.sin(x / 11) end, "sand", "cream", "clap_sh")
  K.ridge(0, W - 1, 112, 118, function(x) return 7 + 5 * math.sin(x / 71 + 3) + 1.5 * math.sin(x / 17) end, "clap_sh", "sand", "stone")
  for y = HORIZON + 2, H - 1 do
    for x = 0, W - 1 do
      if K.rnd(9) == 0 then
        local far = y < 100
        K.px(x, y, far and ((K.rnd(2) == 0) and "haze" or "stone") or ({"sage", "stone", "haze", "ochre", "stone_dk", "sand"})[K.rnd(6) + 1])
      end
    end
  end
  -- pale alkali flats: crusted white with a grey rim
  for _, a in ipairs({{330, 104, 40, 3}, {90, 124, 34, 4}, {402, 132, 24, 3}}) do
    K.ellipse(a[1], a[2], a[3], a[4], "stone_lt")
    K.ellipse(a[1] - 4, a[2], a[3] - 8, math.max(1, a[4] - 1), "white")
    for i = 1, a[3] do K.px(a[1] - a[3] + K.rnd(a[3] * 2), a[2] + a[4], "stone") end
  end
  -- sage everywhere, smaller and greyer with distance
  for i = 1, 260 do
    local x, y = K.rnd(W), 90 + K.rnd(60)
    local c = K.at(x, y)
    if c ~= "white" and c ~= "stone_lt" then
      if y > 112 then K.sage(x, y)
      else K.rect(x, y, 3, 1, "haze"); K.px(x + 1, y - 1, "stone") end
    end
  end
  -- the road: deep pale dust worn through the sage, running straight to the horizon
  local road = K.smooth({{180, 156, 10}, {196, 136, 7}, {214, 118, 4}, {236, 104, 2}, {262, 92, 1}, {292, 86, 0.5}}, 12)
  K.ribbon(road, "stone", 1)
  K.ribbon(road, "cream", 0)
  for i = 1, 120 do
    local x, y = 170 + K.rnd(90), 96 + K.rnd(54)
    if K.at(x, y) == "cream" then K.px(x, y, (K.rnd(2) == 0) and "sand" or "stone_lt") end
  end
end)

K.layer("wreckage", function()
  -- a dead ox beside the road, bloating in the sun, and the bones of an older one
  local ox, oy = 104, 142
  K.ellipse(ox, oy - 4, 13, 5, "ox_dk")
  K.ellipse(ox - 2, oy - 6, 10, 3, "ox")
  K.rect(ox - 12, oy - 2, 24, 1, "ink")
  for _, l in ipairs({{-6, 1}, {-1, 2}, {5, 1}, {9, 2}}) do K.line(ox + l[1], oy - 2, ox + l[1] + 5, oy + l[2] - 6, "deep") end
  K.rect(ox + 12, oy - 6, 5, 4, "ox_dk"); K.px(ox + 16, oy - 6, "cream"); K.px(ox + 14, oy - 7, "cream")
  K.shadow(ox - 14, oy, 32)
  -- bleached skull and ribs
  local bx, by = 320, 140
  K.rect(bx, by - 3, 6, 3, "white"); K.rect(bx + 1, by - 1, 4, 2, "stone_lt")
  K.px(bx + 1, by - 2, "ink"); K.px(bx + 4, by - 2, "ink")
  K.line(bx - 3, by - 5, bx, by - 3, "white"); K.line(bx + 9, by - 5, bx + 6, by - 3, "white")
  for i = 0, 4 do K.line(bx + 12 + i * 3, by, bx + 14 + i * 3, by - 5, (i % 2 == 0) and "white" or "stone_lt") end
  K.rect(bx + 11, by, 16, 1, "stone")
  -- a cast-off chest and a broken wheel, lightened out of a failing wagon
  K.crate(268, 132)
  K.rect(278, 131, 9, 1, "deep"); K.line(279, 131, 284, 126, "wood"); K.line(282, 131, 286, 127, "wood")
end)

K.layer("train", function()
  -- the train strung out ahead, each wagon in the dust of the one before
  local function dust(cx, cy, rx, ry)
    for i = 1, rx * ry * 3 do
      local dx, dy = K.rnd(rx * 2 + 1) - rx, K.rnd(ry * 2 + 1) - ry
      local d = (dx / rx) ^ 2 + (dy / ry) ^ 2
      if d < 1 and K.rnd(100) > d * 90 then K.px(cx + dx, cy + dy, (K.rnd(3) == 0) and "stone_lt" or "cream") end
    end
  end
  for _, w in ipairs({{258, 92, 6}, {244, 99, 8}, {228, 108, 10}}) do
    dust(w[1] - 4, w[2] - 4, w[3], 3)
    K.far_wagon(w[1], w[2], 1)
  end
  -- the near wagon, team plodding with heads down, a woman walking to spare them
  dust(160, 126, 24, 8)
  K.wagon(170, 136, 1)
  K.team(218, 135, 1, {"dark"}, {"light", true})
  K.person(156, 140, "teal", "bonnet", true)
  -- a man walking ahead with a water keg on his shoulder, shading his eyes against the glare
  K.person(256, 140, "red", "deep")
  K.barrel(259, 131)
  K.line(253, 127, 256, 128, "red")
end)

K.save("location_greenwood_cutoff")

-- Rafting the Columbia below The Dalles (432x150).
-- Until the Barlow Road opened in 1846 every wagon went down the Columbia from The Dalles, and
-- many still did after: wagons were taken off their wheels and lashed onto log rafts, or the
-- goods hired into Chinookan cedar canoes, for the float through the Gorge to the Cascades
-- portage. The river runs west between stepped basalt walls, the Oregon side wooded with
-- Douglas fir and the wind hard upstream against the current, raising whitecaps.
-- The view looks downstream with the Oregon shore on the left.
local K = dofile(app.params.kit)
local W, H = 432, 150
local VX, VY = 236, 82 -- where the river vanishes round the bend

K.canvas(W, H, 1846)

K.layer("sky", function()
  K.sky(W, VY + 6, {{40, 10, 0.8}, {176, 22, 0.7}, {330, 14, 1.0}}, "mist")
  -- far forested ridges of the Cascades closing the view downstream
  K.ridge(150, 330, VY + 2, VY + 6, function(x) return 12 + 5 * math.sin(x / 23 + 1) + 2 * math.sin(x / 7) end, "far_hill", "mist", "haze")
  K.ridge(170, 310, VY + 4, VY + 6, function(x) return 6 + 3 * math.sin(x / 13) end, "haze", "far_hill", "teal")
end)

-- Cliff walls: tall at the picture edges, dropping toward the bend. Each column is stepped
-- like the real Gorge: rimrock, a wooded or grassy bench, a lower cliff, then talus to the
-- water. Colours fade toward the haze of the far reach (aerial perspective).
local TONES = {
  shade = {{"far_hill", "haze", "mist", "haze"}, {"stone_ink", "roof", "stone_dk", "teal"}, {"roof", "roof_dk", "roof_lt", "leaf"}},
  lit   = {{"mist", "far_hill", "mist", "far_hill"}, {"stone_dk", "stone_ink", "stone", "stone"}, {"roof_lt", "roof", "stone_dk", "sage"}},
}
local function wall(x0, x1, foot, height, near, side)
  for x = x0, x1 do
    local top = math.floor(foot(x) - height(x) + 0.5)
    local bottom = math.floor(foot(x))
    local n = near(x)
    local h = bottom - top
    local b1 = top + math.floor(h * (0.26 + 0.05 * math.sin(x / 13)))
    local b2 = top + math.floor(h * (0.48 + 0.05 * math.sin(x / 17 + 2)))
    local b3 = top + math.floor(h * (0.80 + 0.04 * math.sin(x / 7)))
    local rock, dark, lit, slope
    for y = top, bottom do
      -- pick the distance band per pixel with a little jitter, so bands dither into each other
      local j = n + (K.rnd(100) - 50) / 600
      local tone = TONES[side][(j < 0.18) and 1 or ((j < 0.45) and 2 or 3)]
      rock, dark, lit, slope = tone[1], tone[2], tone[3], tone[4]
      local c = rock
      if y >= b1 and y < b2 then c = (K.rnd(6) == 0) and dark or slope
      elseif y >= b3 then c = (K.rnd(5) == 0) and lit or ((K.rnd(3) == 0) and slope or rock)
      elseif K.rnd(9) == 0 then c = dark end
      K.px(x, y, c)
    end
    -- rimrock ledges catch the light; columnar joints only now and then, broken
    K.px(x, top, lit); K.px(x, b2, lit)
    if h > 12 and K.rnd(4) == 0 then
      local y0, y1 = (K.rnd(2) == 0) and top + 1 or b2 + 1, 0
      y1 = (y0 == top + 1) and b1 - 1 or b3 - 1
      for y = y0, y1 do if K.rnd(5) > 0 then K.px(x, y, dark) end end
    end
  end
end

K.layer("walls", function()
  -- Washington side on the right, in light; grass on its benches, a few pines
  local rfoot = function(x) return VY + 4 + (x - VX) * 0.16 end
  local rheight = function(x) local t = (x - VX) / (W - VX); return 10 + 58 * t ^ 0.9 + 3 * math.sin(x / 9) end
  wall(VX + 4, W - 1, rfoot, rheight, function(x) return (x - VX) / (W - VX) end, "lit")
  for x = VX + 8, W - 1, 3 do
    local top = math.floor(rfoot(x) - rheight(x) + 0.5)
    if K.rnd(2) == 0 then K.px(x, top - 1, "sage"); K.px(x + 1, top - 1, "ochre") end
  end
  for _, c in ipairs({{300, 0.6}, {356, 0.5}, {410, 0.55}}) do
    local top = math.floor(rfoot(c[1]) - rheight(c[1]) + 0.5)
    K.conifer(c[1], top, math.floor(8 * c[2] / 0.5), "pine", "teal", "leaf")
  end
  -- Oregon side on the left, shaded and wooded, a ribbon of falls off the rim
  local lfoot = function(x) return VY + 4 + (VX - x) * 0.2 end
  local lheight = function(x) local t = (VX - x) / VX; return 12 + 72 * t ^ 0.8 + 4 * math.sin(x / 11) end
  wall(0, VX - 4, lfoot, lheight, function(x) return (VX - x) / VX end, "shade")
  for x = 0, VX - 8, 4 do
    local top = math.floor(lfoot(x) - lheight(x) + 0.5)
    local h = math.max(4, math.floor(18 * (VX - x) / VX))
    local far = (VX - x) / VX < 0.3
    K.conifer(x + K.rnd(3), top + 2, h + K.rnd(4), far and "teal" or "ink", far and "haze" or "pine", far and "far_hill" or "leaf")
    -- firs clinging to the benches below the rim
    if K.rnd(3) == 0 then
      local y = math.floor(top + (lfoot(x) - top) * 0.36)
      K.conifer(x + 2, y, math.max(3, math.floor(h * 0.6)), far and "teal" or "ink", far and "haze" or "pine", far and "far_hill" or "leaf")
    end
  end
  local fx = 166
  local top = math.floor(lfoot(fx) - lheight(fx) + 0.5)
  local bot = math.floor(lfoot(fx)) - 1
  for y = top + 1, bot do
    K.px(fx, y, "white"); K.px(fx + 1, y, (y % 3 == 0) and "light_blue" or "white")
    if K.rnd(3) == 0 then K.px(fx - 1, y, "mist") end
  end
  K.ellipse(fx, bot, 4, 1, "white")
  K.rect(fx - 6, bot - 2, 13, 1, "mist")
end)

K.layer("river", function()
  -- the river widening toward us between the two shores
  for y = VY + 4, H - 1 do
    local t = (y - VY - 4) / (H - VY - 4)
    local l = math.floor(VX - 4 - (y - VY - 4) / 0.2)
    local r = math.floor(VX + 4 + (y - VY - 4) / 0.16)
    l, r = math.max(0, l), math.min(W - 1, r)
    for x = l, r do K.px(x, y, (t < 0.12 and (x + y) % 2 == 0) and "sky_top" or "blue") end
  end
  -- gusts upstream: whitecaps, small far off and broad close to
  for i = 1, 150 do
    local y = VY + 6 + K.rnd(H - VY - 6)
    local t = (y - VY) / (H - VY)
    local x = K.rnd(W)
    if K.at(x, y) == "blue" then
      local len = 1 + math.floor(t * 5) + K.rnd(2)
      K.rect(x, y, len, 1, "sky_top")
      if t > 0.35 or K.rnd(2) == 0 then K.rect(x + 1, y - 1, math.max(1, len - 2), 1, (K.rnd(5) == 0) and "white" or "light_blue") end
    end
  end
end)

K.layer("craft", function()
  -- a cedar canoe with high carved prow, two paddlers, carrying a family's goods
  local cx, cy = 300, 112
  K.poly({{cx - 18, cy - 2}, {cx + 16, cy - 2}, {cx + 22, cy - 7}, {cx + 19, cy + 1}, {cx - 16, cy + 1}, {cx - 21, cy - 5}}, "wood")
  K.rect(cx - 16, cy - 2, 32, 1, "ochre")
  K.rect(cx - 16, cy + 1, 34, 1, "deep")
  K.px(cx + 22, cy - 8, "rust"); K.px(cx + 21, cy - 8, "rust")
  K.crate(cx - 4, cy - 2); K.barrel(cx + 5, cy - 2)
  for _, p in ipairs({{cx - 12, "red"}, {cx + 14, "teal"}}) do
    K.rect(p[1] - 1, cy - 9, 3, 7, p[2]); K.rect(p[1] - 1, cy - 12, 3, 3, "skin_dk"); K.rect(p[1] - 1, cy - 13, 3, 1, "ink")
    K.line(p[1] + 2, cy - 8, p[1] + 5, cy + 4, "deep")
  end
  K.rect(cx - 22, cy + 2, 8, 1, "white"); K.rect(cx + 18, cy + 2, 10, 1, "light_blue")
  -- a second raft further down, small with distance
  K.rect(214, 94, 20, 3, "wood"); K.rect(214, 94, 20, 1, "ochre")
  K.rect(218, 89, 10, 5, "cream"); K.rect(218, 92, 10, 2, "blue")
  K.line(233, 95, 240, 97, "deep")
  K.rect(212, 97, 24, 1, "light_blue")

  -- the near raft: two layers of logs lashed with rope, the wagon bed and bonnet aboard
  local rx, ry = 70, 136
  for i = 0, 6 do
    local y = ry - 12 + i * 2
    K.rect(rx + i, y, 118 - i * 2, 2, (i % 2 == 0) and "wood" or "rust")
    K.px(rx + i, y, "ochre"); K.px(rx + 117 - i, y, "deep")
  end
  for _, lx in ipairs({16, 52, 92}) do K.rect(rx + lx, ry - 12, 2, 13, "deep"); K.px(rx + lx, ry - 12, "sand") end
  K.rect(rx - 2, ry + 2, 124, 1, "light_blue")
  K.rect(rx - 6, ry + 1, 6, 1, "white"); K.rect(rx + 118, ry + 1, 8, 1, "white")
  for i = 0, 10 do if K.rnd(2) == 0 then K.px(rx + i * 11 + K.rnd(6), ry + 3, "white") end end
  -- wagon box and bonnet off the running gear, wheels stacked beside
  local wx = rx + 28
  K.rect(wx, ry - 22, 40, 10, "blue"); K.rect(wx, ry - 22, 40, 1, "light_blue"); K.rect(wx, ry - 13, 40, 1, "ink")
  K.poly({{wx + 1, ry - 22}, {wx - 1, ry - 32}, {wx + 5, ry - 37}, {wx + 35, ry - 37}, {wx + 41, ry - 32}, {wx + 39, ry - 22}}, "cream")
  K.poly({{wx + 1, ry - 22}, {wx - 1, ry - 32}, {wx + 5, ry - 37}, {wx + 9, ry - 37}, {wx + 5, ry - 32}, {wx + 5, ry - 22}}, "white")
  K.poly({{wx + 35, ry - 37}, {wx + 41, ry - 32}, {wx + 39, ry - 22}, {wx + 33, ry - 22}, {wx + 35, ry - 32}}, "clap_sh")
  for _, bx in ipairs({12, 22}) do K.line(wx + bx, ry - 36, wx + bx + 1, ry - 23, "sand") end
  K.wheel(wx + 52, ry - 19, 7); K.wheel(wx + 56, ry - 17, 7)
  K.barrel(rx + 6, ry - 12); K.barrel(rx + 13, ry - 12)
  -- family aboard, and two men at the long sweeps fore and aft
  K.person(rx + 22, ry - 12, "teal", "bonnet", true)
  K.person(rx + 76, ry - 12, "red", "deep")
  K.line(rx + 79, ry - 20, rx + 110, ry - 30, "deep")
  K.line(rx + 110, ry - 30, rx + 128, ry - 6, "wood")
  K.person(rx + 100, ry - 12, "blue", "roof")
  K.line(rx + 2, ry - 22, rx - 4, ry - 26, "wood")
  K.person(rx + 4, ry - 12, "rust", "deep")
  K.line(rx + 2, ry - 20, rx - 20, ry + 2, "wood")
  K.rect(rx - 24, ry + 1, 6, 1, "white")
end)

K.save("location_columbia_raft")

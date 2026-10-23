-- Weather and trail-event overlays that ui/trail_view.gd lays over the travel view, the location
-- pictures and the river crossing.
--   storm_clouds   432x56  a dark thunderhead base that tiles left to right; its ragged lower
--                          edge hangs as rain curtains. Transparent below the cloud.
--   weather_bolt    96x96  three 32x96 lightning bolts, struck from the top edge downward
--   dust_devil      64x40  four 16x40 frames of a whirlwind of dust on a hot afternoon,
--                          ground point at (8, 39)
--   trail_dust      48x12  three 16x12 puffs of kicked-up dust, growing and thinning
--   stampede_ox    104x16  four 26x16 frames of an ox at a dead run, tail up, facing right,
--                          rump on the ground line at (0, 15) like the kit's standing ox
--   flotsam         48x12  two 24x12 pieces of high-water drift: a log with a root wad, a
--                          torn-out willow; each sits on the water line at y = 9
--   rain_clouds    432x56  a grey, even overcast for a rainy day; tiles left to right
--   rain_splash     32x4   four 8x4 frames of a drop hitting the ground, the ring spreading
--   fog_bank       432x40  a ragged bank of mist, solid at its heart and dithered thin at the
--                          edges so the picture shows through; tiles left to right
--   snow_squall    432x150 one tile of wind-driven snow streaks and flakes, transparent
--                          between them; tiles both ways as it scrolls
local K = dofile(app.params.kit)

-------------------------------------------------------------------- storm clouds
K.canvas(432, 56, 1849)
K.wrap = true
K.layer("cloud", function()
  -- a solid overcast at the top, then the base breaks into heavy billows, each lit a little on
  -- its upper left by what light gets under the storm and dark on its underside
  K.rect(0, 0, 432, 20, "storm_dk")
  K.dither(0, 20, 432, 2, "storm_dk", "storm")
  local billows = {}
  local x = 0
  while x < 432 do
    local r = 13 + K.rnd(13)
    billows[#billows + 1] = {x, 18 + K.rnd(8), r, 7 + K.rnd(4)}
    x = x + r + K.rnd(8)
  end
  for _, b in ipairs(billows) do K.ellipse(b[1], b[2], b[3], b[4] + 3, "storm_dk") end
  for _, b in ipairs(billows) do K.ellipse(b[1], b[2] - 1, b[3] - 1, b[4] + 1, "storm") end
  for _, b in ipairs(billows) do
    K.ellipse(b[1] - math.floor(b[3] / 3), b[2] - 3, math.floor(b[3] / 2), math.max(2, b[4] - 3), "storm_lt")
    K.ellipse(b[1] - math.floor(b[3] / 4) + 1, b[2] - 1, math.floor(b[3] / 2), math.max(2, b[4] - 3), "storm")
    -- dithered seam where light meets shadow
    for xx = b[1] - b[3], b[1] + b[3] do if xx % 2 == 0 then K.px(xx, b[2] + b[4] - 1, "storm_dk") end end
  end
  -- second, lower rank of smaller lobes so the edge is ragged, not scalloped
  for i = 1, 40 do
    local bx, by = K.rnd(432), 28 + K.rnd(7)
    local r = 3 + K.rnd(7)
    K.ellipse(bx, by, r, 3, "storm_dk")
    K.ellipse(bx - 1, by - 1, r - 1, 1, "storm")
  end
  -- rain curtains hanging from the heaviest rolls, thinning as they fall
  for _, c in ipairs({{40, 30}, {150, 24}, {236, 36}, {340, 28}, {404, 20}}) do
    for x = c[1] - math.floor(c[2] / 2), c[1] + math.floor(c[2] / 2) do
      local base = 30
      for y = base, 55 do
        local keep = 1 - (y - base) / (56 - base)
        if (x * 3 + y) % 4 == 0 and K.rnd(100) < keep * 90 then K.px(x - math.floor((y - base) / 4), y, "storm_lt") end
      end
    end
  end
end)
K.wrap = false
K.save("storm_clouds")

-------------------------------------------------------------------- lightning
K.canvas(96, 96, 1850)
K.layer("bolts", function()
  for b = 0, 2 do
    local ox = b * 32
    local x, y = ox + 16 + (b - 1) * 4, 0
    local branch_at = 30 + b * 12
    while y < 95 do
      local nx = x + K.rnd(7) - 3
      nx = math.max(ox + 3, math.min(ox + 28, nx))
      local ny = y + 3 + K.rnd(5)
      K.line(x, y, nx, ny, "white")
      K.line(x + 1, y, nx + 1, ny, "light_blue")
      if y < branch_at and ny >= branch_at then
        -- one fork, thinner, dying out
        local bx, by = nx, ny
        local dir = (b % 2 == 0) and 1 or -1
        for i = 1, 5 do
          local mx, my = bx + dir * (1 + K.rnd(3)), by + 2 + K.rnd(4)
          if mx < ox + 1 or mx > ox + 30 then break end
          K.line(bx, by, mx, my, (i < 3) and "white" or "light_blue")
          bx, by = mx, my
        end
      end
      x, y = nx, ny
    end
  end
end)
K.save("weather_bolt")

-------------------------------------------------------------------- dust devil
K.canvas(64, 40, 1851)
K.layer("whirl", function()
  for f = 0, 3 do
    local ox = f * 16
    for y = 0, 39 do
      local up = 39 - y
      -- a funnel narrow at the ground, flaring and leaning with height
      local cx = ox + 8 + up / 14 + 1.2 * math.sin(up / 5 + f * math.pi / 2)
      local r = 0.8 + up / 7
      local spin = (up + f * 3) % 6
      for x = ox, ox + 15 do
        local d = (x + 0.5 - cx) / r
        if math.abs(d) <= 1 then
          local band = math.floor((d + 1) * 3 + spin) % 3
          local thin = up > 26 and (x + y + f) % 2 == 0
          if not thin and (band ~= 0 or up < 6) then K.px(x, y, (d < 0) and "sand" or ((band == 1) and "clap_sh" or "ochre")) end
        end
      end
    end
    -- grit skittering round the foot
    for i = 0, 3 do K.px(ox + 4 + ((i * 3 + f * 2) % 9), 38 - (i % 2), "ochre") end
  end
end)
K.save("dust_devil")

-------------------------------------------------------------------- dust puffs
K.canvas(48, 12, 1852)
K.layer("puffs", function()
  for f = 0, 2 do
    local ox = f * 16
    local r = 3 + f * 2
    for y = 0, 11 do
      for x = ox, ox + 15 do
        local dx, dy = (x + 0.5 - (ox + 8)) / r, (y + 0.5 - (11 - r * 0.7)) / (r * 0.7)
        local d = dx * dx + dy * dy
        if d <= 1 then
          local thin = (f == 2 and (x + y) % 2 == 0) or (f == 1 and d > 0.6 and (x + y) % 2 == 0)
          if not thin then K.px(x, y, (dx < -0.2 and dy < 0) and "cream" or "clap_sh") end
        end
      end
    end
  end
end)
K.save("trail_dust")

-------------------------------------------------------------------- stampeding ox
-- The kit's ox body, with the leg rows redrawn for a gallop and the tail flung up.
local BODY = {}
for r = 1, 11 do BODY[r] = K.OX_ROWS[r] end
local GALLOP = {
  { "..o.mo.......d..o.mo.....", ".o..mo........d.o..mo....", "o...do.........do...do...", "o...oo..........oo...oo.." },
  { "...omo.d........omo.d....", "...omo.d........omo.d....", "...odo..d.......odo..d...", "...oo...o.......oo...o..." },
  { "....mo..d.......mo..d....", "...mo....d.....mo....d...", "..do......d...do......d..", ".oo.......o..oo.......o.." },
  { "...omo.d........omo.d....", "..o.mo.d.......o.mo.d....", ".o..do..d.....o..do..d...", ".o..oo..o.....o..oo..o..." },
}
K.canvas(104, 16, 1853)
K.layer("ox", function()
  local map = K.OX_COATS.light
  for f = 1, 4 do
    local ox = (f - 1) * 26
    local rows = {}
    for r = 1, 11 do rows[r] = BODY[r] end
    for r = 1, 4 do rows[11 + r] = GALLOP[f][r] end
    -- body rises and falls through the stride
    local lift = (f == 3) and -1 or 0
    for r, row in ipairs(rows) do
      for c = 1, #row do
        local ch = row:sub(c, c)
        if ch == "w" then ch = "m" end
        local name = map[ch]
        if name then K.px(ox + c - 1, r - 1 + ((r <= 11) and lift or 0), name) end
      end
    end
    -- tail flung up behind the rump, switch flying
    local ty = 4 + lift
    K.line(ox + 1, ty + 2, ox, ty - 1 - (f % 2), "ox_dk")
    K.px(ox, ty - 2 - (f % 2), "ink")
  end
end)
K.save("stampede_ox")

-------------------------------------------------------------------- high-water drift
K.canvas(48, 12, 1854)
K.layer("drift", function()
  -- a cottonwood log, bark dark, with the root wad still on it
  K.rect(2, 7, 18, 3, "wood"); K.rect(2, 7, 18, 1, "ochre"); K.rect(2, 9, 18, 1, "deep")
  K.px(20, 8, "ochre"); K.px(21, 8, "sand")
  K.ellipse(4, 6, 3, 4, "deep"); K.ellipse(3, 5, 2, 3, "wood")
  for _, r in ipairs({{0, 1}, {1, 3}, {6, 2}, {7, 0}, {0, 8}}) do K.line(4, 6, r[1], r[2], "deep") end
  K.rect(1, 10, 22, 1, "light_blue"); K.px(22, 9, "white")
  -- a torn-out willow, leaves still green, half under
  local ox = 24
  K.line(ox + 4, 9, ox + 18, 7, "deep"); K.line(ox + 6, 9, ox + 14, 4, "wood")
  K.ellipse(ox + 16, 5, 5, 3, "pine"); K.ellipse(ox + 15, 4, 4, 2, "leaf"); K.px(ox + 13, 3, "grass")
  K.ellipse(ox + 9, 6, 3, 2, "leaf")
  for i = 0, 3 do K.line(ox + 4, 9, ox + 1 + i, 6 + i % 2, "deep") end
  K.rect(ox + 1, 10, 22, 1, "light_blue"); K.px(ox + 21, 9, "white")
end)
K.save("flotsam")

-------------------------------------------------------------------- rainy overcast
K.canvas(432, 56, 1855)
K.wrap = true
K.layer("overcast", function()
  -- one even grey lid of cloud, cooler and paler than a thunderhead
  K.rect(0, 0, 432, 18, "storm")
  K.dither(0, 18, 432, 2, "storm", "storm_lt")
  -- low soft rolls along its base
  local x = 0
  while x < 432 do
    local r = 18 + K.rnd(20)
    local y = 20 + K.rnd(6)
    K.ellipse(x, y, r, 7, "storm")
    K.ellipse(x - 2, y - 1, r - 2, 5, "storm_lt")
    for xx = x - r + 2, x + r - 2 do if xx % 2 == 0 then K.px(xx, y + 5, "storm") end end
    x = x + r + K.rnd(10)
  end
  -- a broken fringe of scud below the base
  for i = 1, 70 do
    local bx, by = K.rnd(432), 28 + K.rnd(6)
    K.rect(bx, by, 3 + K.rnd(9), 1, (K.rnd(2) == 0) and "storm_lt" or "storm")
  end
  -- grey veils of rain falling out of it, fading downward
  for x = 0, 431 do
    local t = x * 2 * math.pi / 432
    if math.sin(t * 19) + 0.5 * math.sin(t * 48) > 0.4 then
      for y = 30, 55 do
        if (x + y * 2) % 5 == 0 and K.rnd(100) < (56 - y) * 4 then K.px(x - math.floor((y - 30) / 5), y, "storm_lt") end
      end
    end
  end
end)
K.wrap = false
K.save("rain_clouds")

-------------------------------------------------------------------- splashes
K.canvas(32, 4, 1856)
K.layer("splash", function()
  -- the drop lands, throws up a crown, and the ring spreads and fades
  K.px(3, 3, "light_blue"); K.px(4, 3, "light_blue"); K.px(3, 2, "white")
  K.px(9, 3, "light_blue"); K.px(12, 3, "light_blue"); K.px(10, 1, "white"); K.px(11, 1, "light_blue"); K.px(10, 2, "light_blue")
  K.px(16, 3, "light_blue"); K.px(21, 3, "light_blue"); K.px(17, 2, "mist"); K.px(20, 2, "mist")
  K.px(24, 3, "mist"); K.px(30, 3, "mist")
end)
K.save("rain_splash")

-------------------------------------------------------------------- fog
K.canvas(432, 40, 1857)
K.wrap = true
K.layer("fog", function()
  -- density from overlapping slow swells; solid where thick, then ordered dither stepping down
  local function density(x, y)
    -- whole numbers of waves across the 432 px tile, so the bank repeats without a seam
    local t = x * 2 * math.pi / 432
    local mid = 20 + 4 * math.sin(t * 12) + 2 * math.sin(t * 33 + 1)
    local half = 9 + 4 * math.sin(t * 15 + 2) + 2 * math.sin(t * 62)
    return 1 - math.abs(y - mid) / math.max(1, half)
  end
  local bayer = {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}
  for y = 0, 39 do
    for x = 0, 431 do
      local d = density(x, y)
      if d > 0 and d * 18 > bayer[y % 4 + 1][x % 4 + 1] then
        K.px(x, y, (d > 0.7) and "stone_lt" or "mist")
      end
    end
  end
end)
K.wrap = false
K.save("fog_bank")

-------------------------------------------------------------------- blizzard
K.canvas(432, 150, 1858)
K.wrap = true
K.layer("snow", function()
  -- streaks blown hard from the left, falling a little as they go; flakes between
  for i = 1, 170 do
    local x, y = K.rnd(432), K.rnd(150)
    local len = 3 + K.rnd(7)
    for k = 0, len - 1 do
      local yy = (y + math.floor(k / 4)) % 150
      K.px(x + k, yy, (k == len - 1) and "white" or ((k < 2) and "mist" or "stone_lt"))
    end
  end
  for i = 1, 220 do
    local x, y = K.rnd(432), K.rnd(150)
    K.px(x, y, (K.rnd(3) == 0) and "white" or "stone_lt")
    if K.rnd(4) == 0 then K.px(x + 1, y, "white") end
  end
end)
K.wrap = false
K.save("snow_squall")

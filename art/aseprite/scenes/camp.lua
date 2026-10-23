-- Evening Emigrant Campfire Scene, 1848 (432x150 arrival/rest scene).
-- Deep twilight sky with low western sunset glow, creek-bottom timberline, unhitched covered wagon,
-- pitched canvas ridge tent, resting oxen, tripod cooking kettle, and warm radial firelight.
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 76
local FIRE_X, FIRE_Y = 212, 129

K.canvas(W, H, 1848)

local function grass_shadow(x, y, w)
  for xx = x, x + w - 1 do
    K.px(xx, y, "ink")
    if (xx % 2 == 0) then K.px(xx, y + 1, "pine") end
  end
end

----------------------------------------------------------------- 1. Deep Twilight Sky & Low Sunset Glow
K.layer("sky", function()
  K.rect(0, 0, W, 14, "ink")
  K.blend(0, 14, W, "ink", "blue")
  K.rect(0, 17, W, 18, "blue")
  K.blend(0, 35, W, "blue", "sky_top")
  K.rect(0, 38, W, 12, "sky_top")
  K.blend(0, 50, W, "sky_top", "brick_dk")
  K.rect(0, 53, W, 5, "brick_dk")
  K.blend(0, 58, W, "brick_dk", "brick")
  K.rect(0, 61, W, 4, "brick")
  K.blend(0, 65, W, "brick", "rust")
  K.rect(0, 68, W, 3, "rust")
  K.blend(0, 71, W, "rust", "ochre")
  K.rect(0, 73, W, 2, "ochre")
  K.rect(0, 75, W, 3, "gold")

  K.ellipse(82, 75, 76, 8, "ochre")
  K.ellipse(78, 76, 54, 6, "gold")
  K.ellipse(74, 76, 32, 4, "sand")
  K.ellipse(70, 76, 16, 2, "cream")

  for _, st in ipairs({
    {28,5,"cream"}, {64,11,"sand"}, {94,6,"white"}, {142,14,"sand"},
    {178,4,"cream"}, {232,9,"white"}, {276,5,"sand"}, {318,7,"cream"},
    {358,13,"sand"}, {392,5,"white"}, {418,10,"cream"}
  }) do
    K.px(st[1], st[2], st[3])
  end
  K.px(52, 19, "white"); K.px(51, 19, "cream"); K.px(53, 19, "cream")
  K.px(52, 18, "cream"); K.px(52, 20, "cream")

  local function dusk_cloud(cx, cy, s)
    local puffs = {{0,3,9,3},{8,1,9,5},{18,0,11,6},{29,2,8,4},{36,3,6,3}}
    for _, p in ipairs(puffs) do
      K.ellipse(cx + math.floor(p[1]*s), cy + p[2] + 1, math.floor(p[3]*s), p[4], "brick_lt")
    end
    for _, p in ipairs(puffs) do
      K.ellipse(cx + math.floor(p[1]*s) - 1, cy + p[2] + 2, math.max(2, math.floor(p[3]*s) - 2), math.max(1, p[4] - 2), "gold")
    end
    for _, p in ipairs(puffs) do
      K.ellipse(cx + math.floor(p[1]*s), cy + p[2] - 1, math.max(2, math.floor(p[3]*s) - 1), math.max(1, p[4] - 1), "deep")
    end
    for _, p in ipairs(puffs) do
      K.ellipse(cx + math.floor(p[1]*s) - 1, cy + p[2] - 2, math.max(1, math.floor(p[3]*s) - 3), math.max(1, p[4] - 2), "roof")
    end
  end
  dusk_cloud(28, 22, 1.3)
  dusk_cloud(296, 20, 1.4)
  dusk_cloud(184, 29, 0.85)
end)

----------------------------------------------------------------- 2. Silhouetted Prairie Hills & Creek-Bottom Trees
K.layer("horizon", function()
  for x = 0, W - 1 do
    local h1 = math.floor(6 + 4 * math.sin(x / 52.0 + 0.4) + 2 * math.cos(x / 21.0))
    for y = HORIZON - h1, HORIZON + 4 do
      K.px(x, y, (y == HORIZON - h1 and x < 155) and "rust" or "deep")
    end
  end

  for x = 0, W - 1 do
    local h2 = math.floor(3 + 3 * math.sin(x / 34.0 + 2.1) + 2 * math.sin(x / 13.0))
    for y = HORIZON + 2 - h2, HORIZON + 10 do
      K.px(x, y, "pine")
    end
  end

  local function dusk_tree(x, y, s, warm_side)
    K.rect(x - 1, y - math.floor(12 * s), 2, math.floor(12 * s), "ink")
    local clumps = {{-6,-14,5,4},{5,-15,6,4},{0,-19,7,5},{-3,-22,5,3},{4,-22,4,3}}
    for _, c in ipairs(clumps) do
      K.ellipse(x + math.floor(c[1]*s), y + math.floor(c[2]*s), math.floor(c[3]*s), math.floor(c[4]*s), "ink")
    end
    for _, c in ipairs(clumps) do
      K.ellipse(x + math.floor(c[1]*s) - 1, y + math.floor(c[2]*s) - 1, math.max(1, math.floor(c[3]*s) - 1), math.max(1, math.floor(c[4]*s) - 1), "pine")
    end
    if warm_side then
      for _, c in ipairs(clumps) do
        K.px(x + math.floor(c[1]*s) - math.floor(c[3]*s) + 1, y + math.floor(c[2]*s) - 1, "leaf")
      end
    end
  end

  dusk_tree(18, 86, 1.1, true)
  dusk_tree(42, 87, 0.9, true)
  dusk_tree(64, 86, 1.0, true)
  dusk_tree(354, 87, 1.0, false)
  dusk_tree(382, 86, 1.15, false)
  dusk_tree(412, 87, 0.95, false)
end)

----------------------------------------------------------------- 3. Evening Prairie Meadow & Warm Radial Firelight
K.layer("ground", function()
  K.rect(0, HORIZON + 8, W, H - (HORIZON + 8), "pine")
  K.blend(0, HORIZON + 8, W, "ink", "pine")
  K.dither(0, 96, W, 14, "pine", "leaf")
  K.rect(0, 110, W, H - 110, "leaf")
  K.dither(0, 136, W, H - 136, "leaf", "pine")

  for x = 90, W - 1 do
    local ry = math.floor(116 + 10 * math.sin((x - 90) / 110.0))
    if ry >= 96 and ry < H - 4 then
      K.rect(x, ry, 1, 2, "deep")
      K.rect(x, ry + 6, 1, 2, "deep")
    end
  end

  for y = 104, H - 1 do
    for x = FIRE_X - 115, FIRE_X + 115 do
      if x >= 0 and x < W then
        local dx = (x - FIRE_X) / 1.0
        local dy = (y - FIRE_Y) * 2.8
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 24 then
          K.px(x, y, ((x + y) % 2 == 0) and "gold" or "ochre")
        elseif dist < 42 then
          K.px(x, y, ((x + y) % 2 == 0) and "ochre" or "rust")
        elseif dist < 64 then
          K.px(x, y, ((x + y) % 2 == 0) and "grass" or "sage")
        elseif dist < 92 then
          if (x + y) % 2 == 0 then K.px(x, y, "grass") end
        end
      end
    end
  end

  for i = 1, 850 do
    local x = K.rnd(W)
    local y = 90 + K.rnd(H - 90)
    local dx = math.abs(x - FIRE_X)
    local dy = math.abs(y - FIRE_Y) * 2.5
    local d = math.sqrt(dx * dx + dy * dy)
    local c = "leaf"
    if d < 35 then c = (i % 2 == 0) and "sand" or "gold"
    elseif d < 65 then c = (i % 2 == 0) and "ochre" or "sage"
    elseif d < 95 then c = (i % 2 == 0) and "grass" or "leaf"
    else c = (i % 3 == 0) and "leaf" or "ink" end
    K.px(x, y, c)
  end
end)

----------------------------------------------------------------- 4. Unhitched Wagon, Resting Oxen & Canvas Ridge Tent
K.layer("camp_setup", function()
  local ox_map = {
    o="ink", d="deep", r="ox_dk", b="ox", m="ox_dk", l="rust", h="ochre",
    s="ochre", c="sand", w="cream", p="wood", u="deep", e="deep", k="ink"
  }

  local ox_bed_rows = {
    "..................w..w...",
    ".................cc..cc..",
    "...oooooo.......ooosoooo.",
    "..ollllllooooooolllklllo.",
    ".olmmmmmmmmmmmmmmllllllso",
    ".odmmmmmmmmmmmmmmmmmmswwo",
    ".oddmmmmmmmmmmmmmmddddpko",
    "..odddddddddddddddddpppo.",
    "...oooooooooooooooooooo..",
  }
  grass_shadow(45, 115, 22)
  for r, row in ipairs(ox_bed_rows) do
    for c = 1, #row do
      local cname = ox_map[row:sub(c, c)]
      if cname then K.px(44 + c - 1, 106 + r - 1, cname) end
    end
  end

  K.ox(12, 125, 1, "dark", false)
  grass_shadow(14, 125, 24)

  local wx, wy = 96, 128
  K.wagon(wx, wy, 1)
  grass_shadow(wx - 2, wy + 1, 50)
  K.wheel(wx + 10, wy - 7, 7)
  K.wheel(wx + 37, wy - 6, 6)
  K.poly({{wx + 39, wy - 36}, {wx + 47, wy - 30}, {wx + 45, wy - 18}, {wx + 37, wy - 18}, {wx + 40, wy - 30}}, "sand")
  K.line(wx + 46, wy - 30, wx + 44, wy - 18, "gold")
  K.rect(wx + 46, wy - 7, 12, 1, "leaf")
  K.line(wx + 44, wy - 6, wx + 58, wy - 1, "wood")
  K.line(wx + 44, wy - 5, wx + 58, wy, "deep")
  K.rect(wx + 56, wy - 2, 6, 3, "ochre")
  K.rect(wx + 56, wy, 6, 1, "deep")

  K.barrel(wx - 10, wy - 1)
  K.crate(wx - 20, wy)

  local tx, ty = 282, 130
  K.poly({{tx + 10, ty}, {tx + 60, ty - 4}, {tx + 78, ty + 2}, {tx + 18, ty + 3}}, "ink")
  K.poly({{tx, ty}, {tx + 20, ty - 34}, {tx + 24, ty - 34}, {tx + 12, ty}}, "sand")
  K.poly({{tx, ty}, {tx + 20, ty - 34}, {tx + 10, ty}}, "gold")
  K.line(tx, ty, tx + 20, ty - 34, "cream")

  K.poly({{tx + 10, ty}, {tx + 21, ty - 32}, {tx + 29, ty}}, "ink")
  K.poly({{tx + 12, ty}, {tx + 21, ty - 28}, {tx + 25, ty}}, "deep")
  K.rect(tx + 20, ty - 35, 2, 35, "wood")
  K.px(tx + 20, ty - 34, "gold")
  K.rect(tx + 14, ty - 4, 8, 3, "brick")
  K.rect(tx + 15, ty - 5, 6, 1, "ochre")

  K.poly({{tx + 21, ty - 34}, {tx + 54, ty - 37}, {tx + 68, ty - 4}, {tx + 29, ty}}, "clap_sh")
  K.poly({{tx + 34, ty - 35}, {tx + 54, ty - 37}, {tx + 68, ty - 4}, {tx + 44, ty - 2}}, "roof_lt")
  for _, sx in ipairs({10, 20, 30}) do
    K.line(tx + 21 + sx, ty - 34 - math.floor(sx / 10), tx + 29 + math.floor(sx * 1.2), ty - math.floor(sx / 8), "ochre")
  end
  K.line(tx + 20, ty - 34, tx + 54, ty - 37, "cream")

  for i = 0, 3 do
    local gx = tx + 32 + i * 11
    local gy = ty - math.floor(i * 1.2)
    K.line(gx, gy - 3, gx + 4, gy + 2, "ochre")
    K.rect(gx + 4, gy + 1, 1, 2, "wood")
  end
end)

----------------------------------------------------------------- 5. Campfire, Tripod Kettle, Wispy Smoke & Emigrants
K.layer("campfire_and_figures", function()
  local fx, fy = FIRE_X, FIRE_Y

  K.poly({{fx - 16, fy + 2}, {fx - 4, fy - 2}, {fx - 2, fy + 1}, {fx - 14, fy + 4}}, "deep")
  K.poly({{fx + 16, fy + 2}, {fx + 4, fy - 2}, {fx + 2, fy + 1}, {fx + 14, fy + 4}}, "deep")
  K.rect(fx - 11, fy, 22, 3, "ink")
  K.ellipse(fx, fy, 9, 2, "red")
  K.ellipse(fx, fy, 6, 1, "gold")

  local flame_rows = {
    "........r...r........",
    ".......ro...or.......",
    "....r..rog.gor.......",
    "...ro.rogg.ggor..r...",
    "...roorggggggoorro...",
    "..roogggssssgggorro..",
    "..rooggssccssggooro..",
    ".rrogggsccccsgggoorr.",
    ".roogggscwwwcsgggorro",
    ".rooggsswwwwwssggorro",
    "..roogsswwwwwssgooro.",
    "...roooswwwwwsoooro..",
  }
  local flame_map = {
    r="red", o="rust", g="gold", s="sand", c="cream", w="white"
  }
  for r, row in ipairs(flame_rows) do
    for c = 1, #row do
      local cname = flame_map[row:sub(c, c)]
      if cname then K.px(fx - 10 + c - 1, fy - 13 + r, cname) end
    end
  end

  for _, st in ipairs({{-14, 2, 4, 2}, {-8, 3, 4, 2}, {-2, 4, 5, 2}, {5, 4, 4, 2}, {11, 3, 4, 2}, {15, 1, 3, 2}}) do
    K.ellipse(fx + st[1], fy + st[2], st[3], st[4], "roof_dk")
    K.ellipse(fx + st[1], fy + st[2], st[3] - 1, st[4] - 1, "roof_lt")
    K.px(fx + st[1], fy + st[2] - 1, "gold")
    K.px(fx + st[1] - 1, fy + st[2] - 1, "ochre")
  end

  local ax, ay = fx + 1, fy - 35
  K.line(ax, ay, fx + 5, fy + 1, "roof_dk")
  K.line(ax, ay, fx - 19, fy + 4, "ink")
  K.line(ax + 1, ay + 2, fx - 17, fy + 4, "roof_lt")
  K.line(ax, ay, fx + 20, fy + 4, "ink")
  K.line(ax - 1, ay + 2, fx + 18, fy + 4, "roof_lt")
  K.line(ax, ay + 1, ax, fy - 24, "roof_lt")
  K.px(ax, fy - 25, "gold")

  local kx, ky = fx + 1, fy - 18
  K.line(kx - 5, ky - 3, kx, ky - 6, "roof_lt")
  K.line(kx + 5, ky - 3, kx, ky - 6, "roof_lt")
  K.ellipse(kx, ky, 6, 4, "ink")
  K.rect(kx - 6, ky - 3, 13, 2, "ink")
  K.rect(kx - 5, ky - 2, 11, 4, "roof_dk")
  K.rect(kx - 5, ky - 3, 10, 1, "roof_lt")
  K.rect(kx - 4, ky + 2, 9, 1, "rust")
  K.rect(kx - 3, ky + 3, 7, 1, "gold")

  for _, sp in ipairs({
    {-4, -14, "gold"}, {5, -13, "gold"}, {-3, -23, "ochre"}, {4, -26, "gold"},
    {-2, -29, "red"}, {3, -32, "ochre"}, {-4, -37, "gold"}, {1, -41, "rust"}
  }) do
    K.px(fx + sp[1], fy + sp[2], sp[3])
  end
  local wisps = {
    { 0, -24, 3, "roof_lt"}, {-1, -26, 4, "roof"},    {-2, -28, 3, "roof_lt"},
    {-1, -31, 4, "roof"},    {-3, -33, 5, "roof_dk"}, {-4, -36, 4, "roof"},
    {-6, -39, 5, "roof_dk"}, {-5, -42, 4, "roof_dk"}, {-8, -45, 5, "deep"},
    {-10,-48, 4, "deep"},    {-12,-51, 3, "deep"}
  }
  for _, w in ipairs(wisps) do
    for dx = 0, w[3] - 1 do
      if (dx + w[2]) % 2 == 0 then
        K.px(fx + w[1] + dx, fy + w[2], w[4])
      end
    end
  end

  local sx, sy = fx - 32, fy + 1
  grass_shadow(sx - 6, sy + 1, 14)
  K.rect(sx - 5, sy - 4, 12, 4, "wood")
  K.rect(sx - 5, sy - 4, 12, 1, "ochre")
  K.ellipse(sx + 7, sy - 2, 2, 2, "sand")
  K.rect(sx - 5, sy - 1, 12, 1, "deep")
  K.rect(sx + 1, sy - 5, 3, 5, "deep")
  K.rect(sx + 3, sy - 1, 3, 2, "ink")
  K.rect(sx - 2, sy - 11, 5, 7, "blue")
  K.rect(sx + 2, sy - 11, 1, 6, "light_blue")
  K.rect(sx - 1, sy - 14, 3, 3, "skin")
  K.px(sx + 1, sy - 13, "cream")
  K.rect(sx - 2, sy - 15, 5, 1, "deep")
  K.rect(sx - 1, sy - 17, 3, 2, "deep")
  K.line(sx + 2, sy - 9, sx + 7, sy - 8, "blue")
  K.px(sx + 8, sy - 8, "skin"); K.px(sx + 8, sy - 9, "cream")

  local cx2, cy2 = fx + 27, fy + 2
  K.person(cx2, cy2, "red", "bonnet", true)
  grass_shadow(cx2 - 2, cy2 + 1, 7)
  K.line(cx2 - 1, cy2 - 10, cx2 - 2, cy2 - 1, "ochre")
  K.px(cx2 - 1, cy2 - 12, "gold")
  K.line(cx2 - 1, cy2 - 8, cx2 - 5, cy2 - 11, "red")
  K.px(cx2 - 6, cy2 - 11, "skin")
  K.line(cx2 - 6, cy2 - 11, fx + 6, fy - 17, "wood")

  local cx3, cy3 = fx + 52, fy - 1
  K.person(cx3, cy3, "wood", "deep", false)
  grass_shadow(cx3 - 2, cy3 + 1, 7)
  K.line(cx3 - 1, cy3 - 10, cx3 - 1, cy3 - 5, "ochre")

  K.rect(fx - 16, fy + 4, 5, 2, "roof_lt")
  K.poly({{fx - 15, fy + 4}, {fx - 14, fy}, {fx - 12, fy}, {fx - 11, fy + 4}}, "light_blue")
  K.px(fx - 12, fy + 1, "cream")
  K.rect(fx - 14, fy - 1, 3, 1, "ink")

  for i = 0, 2 do
    K.rect(fx + 36 + i * 2, fy + 6 - i * 2, 9, 2, "wood")
    K.px(fx + 36 + i * 2, fy + 6 - i * 2, "ochre")
  end
end)

K.save("location_camp")

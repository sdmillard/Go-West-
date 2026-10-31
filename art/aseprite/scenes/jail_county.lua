-- The Jackson County jail at Independence (432x150).
-- In 1848 the county held its prisoners in a squat jail of rough-cut limestone a short walk
-- from the square: thick walls, a few small barred windows, one iron-strapped plank door, and
-- the jailer living close by. (The brick-and-stone jail that survives today was built in 1859.)
-- Behind, the brick courthouse on the square with its cupola; a muddy street; a deputy at the
-- door with a shotgun.
local K = dofile(app.params.kit)
local W, H = 432, 150
local GROUND = 112

K.canvas(W, H, 1841)

-- coursed rubble limestone: pale blocks in uneven courses, joints staggered, weathered spots
local function limestone(x, y, w, h)
  K.rect(x, y, w, h, "stone_lt")
  local row = 0
  for yy = y + 4, y + h - 1, 4 do
    K.rect(x, yy, w, 1, "stone")
    local off = (row % 2 == 0) and 0 or 5
    for xx = x + off, x + w - 1, 9 + (row % 3) do K.rect(xx, yy - 3, 1, 3, "stone") end
    row = row + 1
  end
  for i = 1, w * h / 14 do K.px(x + K.rnd(w), y + K.rnd(h), (K.rnd(3) == 0) and "stone_dk" or "white") end
end

local function barred(x, y, w, h)
  K.rect(x - 1, y - 1, w + 2, h + 2, "stone")
  K.rect(x, y, w, h, "ink")
  for xx = x + 1, x + w - 2, 2 do K.rect(xx, y, 1, h, "storm_lt") end
  K.rect(x, y + math.floor(h / 2), w, 1, "storm")
  K.rect(x - 1, y + h + 1, w + 2, 1, "stone_dk")
end

K.layer("sky", function()
  K.sky(W, GROUND - 3, {{60, 14, 0.9}, {250, 8, 0.7}, {380, 22, 1.1}}, "mist")
end)

K.layer("town", function()
  -- the courthouse on the square, two storeys of brick with a white cupola, seen past the street
  local cx, cy = 52, GROUND - 6
  K.bricks(cx, cy - 34, 74, 34)
  K.side_wall(cx + 74, cy - 34, 14, 34, "brick_dk", "brick")
  K.hip_roof(cx, cy - 34, 74, 14, 9)
  K.rect(cx + 30, cy - 52, 14, 9, "white"); K.rect(cx + 40, cy - 52, 4, 9, "stone_lt")
  K.poly({{cx + 28, cy - 52}, {cx + 37, cy - 60}, {cx + 46, cy - 52}}, "roof_dk")
  K.rect(cx + 36, cy - 64, 1, 5, "deep")
  for i = 0, 5 do K.window(cx + 5 + i * 12, cy - 30, 5, 7); K.window(cx + 5 + i * 12, cy - 16, 5, 7) end
  K.door(cx + 34, cy, 10)
  -- frame stores along the far side of the street
  K.clapboard(150, GROUND - 26, 40, 22, "cream", "clap_sh"); K.gable_roof(150, GROUND - 26, 40, 6)
  K.window(156, GROUND - 20, 6, 7); K.door(172, GROUND - 4, 12)
  K.clapboard(354, GROUND - 30, 60, 26, "sand", "ochre"); K.gable_roof(354, GROUND - 30, 60, 7)
  K.window(362, GROUND - 24, 6, 8); K.window(400, GROUND - 24, 6, 8); K.door(380, GROUND - 4, 13)
  K.elm(20, GROUND - 2, 1.0); K.elm(140, GROUND - 2, 0.8); K.elm(424, GROUND - 2, 0.9)
end)

K.layer("street", function()
  K.rect(0, GROUND - 4, W, H - GROUND + 4, "silt")
  K.dither(0, GROUND - 4, W, 2, "silt", "sage")
  -- churned mud, wheel ruts and puddles
  for _, r in ipairs({{0, 128, 432}, {0, 136, 432}}) do
    for x = r[1], r[3] - 1 do K.px(x, r[2] + math.floor(1.5 * math.sin(x / 23)), "silt_dk") end
  end
  for i = 1, 500 do
    local x, y = K.rnd(W), GROUND - 2 + K.rnd(H - GROUND + 2)
    K.px(x, y, ({"silt_dk", "silt_lt", "dirt_dk", "silt"})[K.rnd(4) + 1])
  end
  for _, p in ipairs({{120, 140, 10, 2}, {300, 132, 7, 1}, {396, 144, 12, 2}}) do
    K.ellipse(p[1], p[2], p[3], p[4], "sky"); K.rect(p[1] - p[3] + 2, p[2] - 1, p[3], 1, "light_blue")
  end
end)

K.layer("jail", function()
  -- the jail: two storeys of limestone under a low shingled hip roof, the side wall in shade
  local x0, w, top, foot = 200, 84, 70, GROUND + 2
  limestone(x0, top, w, foot - top)
  K.side_wall(x0 + w, top, 22, foot - top, "stone", "stone_dk")
  for i = 1, 90 do K.px(x0 + w + K.rnd(22), top + K.rnd(foot - top - 4), (K.rnd(2) == 0) and "stone_dk" or "stone_lt") end
  K.hip_roof(x0, top, w, 22, 12)
  K.chimney(x0 + 64, top - 9, 7)
  -- quoins at the corner and a heavy lintel and sill course
  for y = top + 2, foot - 4, 8 do K.rect(x0, y, 5, 4, "white"); K.rect(x0 + w - 5, y + 4, 5, 4, "white") end
  K.rect(x0, top + 22, w, 2, "stone")
  -- small barred windows, upper and lower; a slit in the side wall
  barred(x0 + 12, top + 7, 6, 8); barred(x0 + 66, top + 7, 6, 8)
  barred(x0 + 12, top + 29, 6, 7); barred(x0 + 66, top + 29, 6, 7)
  K.rect(x0 + w + 10, top + 9, 2, 6, "ink"); K.rect(x0 + w + 10, top + 30, 2, 5, "ink")
  -- the door: oak planks bound with strap iron, a massive stone lintel above, two steps below
  local dx = x0 + 36
  K.rect(dx - 3, foot - 23, 16, 3, "white"); K.rect(dx - 3, foot - 20, 16, 1, "stone_dk")
  K.rect(dx, foot - 19, 10, 17, "deep")
  K.rect(dx + 1, foot - 18, 8, 16, "wood")
  for xx = dx + 3, dx + 7, 2 do K.rect(xx, foot - 18, 1, 16, "deep") end
  for _, yy in ipairs({foot - 16, foot - 10, foot - 5}) do K.rect(dx + 1, yy, 8, 1, "storm_dk"); K.px(dx + 1, yy, "storm_lt") end
  K.px(dx + 7, foot - 12, "storm"); K.px(dx + 7, foot - 11, "ink")
  K.rect(dx - 3, foot - 2, 16, 2, "stone"); K.rect(dx - 5, foot, 20, 2, "stone_dk")
  K.shadow(x0 - 2, foot + 2, w + 26)
end)

K.layer("people", function()
  -- a hitching rail, and the deputy at the door with his shotgun
  K.rect(318, GROUND + 4, 1, 10, "deep"); K.rect(346, GROUND + 4, 1, 10, "deep"); K.rect(316, GROUND + 4, 33, 2, "wood")
  K.person(226, GROUND + 14, "deep", "roof")
  K.line(230, GROUND - 2, 234, GROUND - 13, "wood"); K.line(232, GROUND - 7, 235, GROUND - 14, "storm_dk")
  -- townsfolk passing: a woman with a basket, a man watching from across the street
  K.person(276, GROUND + 24, "teal", "bonnet", true)
  K.person(382, GROUND + 20, "rust", "deep")
  -- a farm wagon pulled up in the street
  K.wagon(110, GROUND + 30, 1)
  K.team(158, GROUND + 29, 1, {"red"}, {"light", true})
end)

K.save("location_jail_county")

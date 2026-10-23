-- Hunting & Memorial Sprites built via the Aseprite Lua pipeline:
--   1. hunt_bison.png  (80x24: 2 animation frames of 40x24, facing right)
--   2. hunt_deer.png   (54x22: 2 animation frames of 27x22, facing right)
--   3. hunt_rabbit.png (30x11: 2 animation frames of 15x11, facing right)
--   4. hunt_cover.png  (24x14: 2 variants of 12x14 — frame 0 = woodland bush, frame 1 = sagebrush clump)
--   5. hunt_hunter.png (16x18: frontier hunter in brimmed felt hat & indigo/buckskin coat)
--   6. gravestone_frame.png (432x150: prairie memorial scene with carved weathered limestone headstone,
--      sunlit upper-left bevel, urn medallion, turned earth mound & prairie wildflowers, ready for
--      ui/grave_view.gd to draw the dynamic centered inscription text over y = 38..124)
--   7. ledger_icons.png (56x8: 7 icons of 8x8 for the Wagon Ledger — food, health, cash, oxen, bullets, spares, weather)

local K = dofile(app.params.kit)

local function ground_shadow_ellipse(cx, cy, rx, ry)
  for y = -ry, ry do
    for x = -rx, rx do
      if (x * x) / (rx * rx + 0.5) + (y * y) / (ry * ry + 0.5) <= 1 then
        K.px(cx + x, cy + y, "ground_shadow")
      end
    end
  end
end

--------------------------------------------------------------------------------
-- 1. HUNT_BISON (80x24: 2 frames of 40x24, facing right)
--------------------------------------------------------------------------------
K.canvas(80, 24, 184881)
K.layer("bison", function()
  for frame = 0, 1 do
    local ox = frame * 40
    -- Ground shadow (translucent)
    ground_shadow_ellipse(ox + 20, 21, 16, 2)
    -- Shaggy tail
    K.line(ox + 2, 9, ox + 1, 14, "deep")
    K.px(ox + 1, 15, "ink")
    -- Muscular hindquarters & back (x = 4..23, y = 5..16)
    K.rect(ox + 4, 6, 20, 10, "wood")
    K.rect(ox + 5, 5, 18, 4, "ochre")
    K.rect(ox + 6, 5, 14, 2, "gold")
    K.rect(ox + 4, 14, 20, 2, "deep")
    -- Massive shaggy shoulder hump & cape (x = 20..33, y = 1..16)
    K.ellipse(ox + 26, 8, 7, 7, "deep")
    K.ellipse(ox + 25, 6, 6, 5, "wood")
    K.ellipse(ox + 24, 4, 4, 3, "ochre")
    -- Heavy lowered head & shaggy beard (x = 31..38, y = 5..16)
    K.rect(ox + 31, 6, 7, 9, "ink")
    K.rect(ox + 31, 6, 5, 6, "deep")
    K.rect(ox + 32, 14, 4, 4, "ink") -- beard
    -- Curved horn & glinting eye
    K.px(ox + 34, 4, "cream"); K.px(ox + 35, 3, "sand")
    K.px(ox + 35, 8, "gold")
    -- Four legs in alternating 2-frame gallop/stride
    local legs = (frame == 0)
      and {{6, 16, 6}, {11, 16, 5}, {25, 16, 6}, {30, 16, 5}}
      or  {{5, 16, 5}, {12, 16, 6}, {24, 16, 5}, {31, 16, 6}}
    for _, lg in ipairs(legs) do
      K.rect(ox + lg[1], lg[2], 2, lg[3], "ink")
      K.px(ox + lg[1], lg[2], "deep")
    end
  end
end)
K.save("hunt_bison")

--------------------------------------------------------------------------------
-- 2. HUNT_DEER (54x22: 2 frames of 27x22, facing right)
--------------------------------------------------------------------------------
K.canvas(54, 22, 184882)
K.layer("deer", function()
  for frame = 0, 1 do
    local ox = frame * 27
    ground_shadow_ellipse(ox + 13, 19, 10, 2)
    -- White flag tail & rump patch
    K.rect(ox + 1, 7, 2, 4, "white")
    K.px(ox + 1, 6, "cream")
    -- Sleek tan/ochre body with cream belly (x = 3..19, y = 7..14)
    K.rect(ox + 3, 7, 16, 7, "ochre")
    K.rect(ox + 4, 7, 14, 2, "gold")
    K.rect(ox + 6, 12, 11, 2, "cream")
    K.rect(ox + 3, 13, 16, 1, "wood")
    -- Graceful neck & head facing right (x = 17..25, y = 3..10)
    K.rect(ox + 17, 4, 4, 6, "ochre")
    K.rect(ox + 18, 4, 2, 5, "gold")
    K.rect(ox + 19, 3, 6, 3, "ochre")
    K.px(ox + 25, 4, "ink") -- nose
    K.px(ox + 21, 4, "ink") -- eye
    -- Ears & branching antlers (y = 0..3)
    K.px(ox + 18, 2, "wood")
    K.line(ox + 19, 2, ox + 18, 0, "cream")
    K.line(ox + 21, 2, ox + 22, 0, "cream")
    K.px(ox + 20, 1, "sand")
    -- Slender legs in 2-frame bounding stride
    local legs = (frame == 0)
      and {{4, 14, 6}, {8, 14, 5}, {15, 14, 6}, {18, 14, 5}}
      or  {{3, 14, 5}, {9, 14, 6}, {14, 14, 5}, {19, 14, 6}}
    for _, lg in ipairs(legs) do
      K.rect(ox + lg[1], lg[2], 1, lg[3], "wood")
      K.px(ox + lg[1], lg[2] + lg[3] - 1, "ink")
    end
  end
end)
K.save("hunt_deer")

--------------------------------------------------------------------------------
-- 3. HUNT_RABBIT (30x11: 2 frames of 15x11, facing right)
--------------------------------------------------------------------------------
K.canvas(30, 11, 184883)
K.layer("rabbit", function()
  for frame = 0, 1 do
    local ox = frame * 15
    ground_shadow_ellipse(ox + 7, 9, 5, 1)
    -- Fluffy cottontail
    K.rect(ox + 1, 5, 2, 2, "white")
    -- Rounded jackrabbit body (x = 3..10, y = 4..8)
    K.ellipse(ox + 6, 6, 4, 2, "sand")
    K.rect(ox + 4, 4, 5, 1, "cream")
    K.rect(ox + 4, 7, 5, 1, "ochre")
    -- Head & long black-tipped jackrabbit ears
    K.rect(ox + 9, 3, 4, 3, "sand")
    K.px(ox + 11, 4, "ink") -- eye
    K.line(ox + 9, 2, ox + 8, 0, "sand")
    K.line(ox + 11, 2, ox + 11, 0, "sand")
    K.px(ox + 8, 0, "ink"); K.px(ox + 11, 0, "ink")
    -- Hind & fore legs in 2-frame hop
    if frame == 0 then
      K.rect(ox + 3, 8, 2, 2, "wood")
      K.rect(ox + 9, 8, 2, 2, "wood")
    else
      K.rect(ox + 2, 7, 2, 2, "wood")
      K.rect(ox + 10, 7, 2, 2, "wood")
    end
  end
end)
K.save("hunt_rabbit")

--------------------------------------------------------------------------------
-- 4. HUNT_COVER (24x14: Frame 0 [0..11] = Woodland Bush, Frame 1 [12..23] = Sagebrush)
--------------------------------------------------------------------------------
K.canvas(24, 14, 184884)
K.layer("cover", function()
  -- Frame 0 (x = 0..11): Woodland shrub with trunk & layered foliage
  ground_shadow_ellipse(6, 12, 5, 1)
  K.rect(4, 8, 4, 5, "wood")
  K.rect(5, 8, 2, 5, "deep")
  K.ellipse(6, 6, 5, 4, "pine")
  K.ellipse(5, 5, 4, 3, "leaf")
  K.ellipse(4, 4, 3, 2, "grass")
  K.px(3, 3, "sage"); K.px(6, 3, "sage")

  -- Frame 1 (x = 12..23): Dryland sagebrush clump with woody stems
  ground_shadow_ellipse(18, 12, 5, 1)
  K.line(17, 12, 14, 5, "wood")
  K.line(18, 12, 18, 4, "wood")
  K.line(19, 12, 21, 5, "wood")
  K.ellipse(18, 7, 5, 4, "grass")
  K.ellipse(17, 6, 4, 3, "sage")
  K.px(15, 4, "sand"); K.px(18, 3, "sand"); K.px(20, 5, "sand")
end)
K.save("hunt_cover")

--------------------------------------------------------------------------------
-- 5. HUNT_HUNTER (16x18: Frontier hunter sprite centered at x=8, foot at y=17)
--------------------------------------------------------------------------------
K.canvas(16, 18, 184885)
K.layer("hunter", function()
  ground_shadow_ellipse(8, 16, 6, 1)
  -- Wide-brimmed frontier felt hat
  K.rect(3, 2, 10, 2, "deep")
  K.rect(5, 0, 6, 2, "wood")
  K.rect(5, 1, 6, 1, "ochre")
  -- Face & neck
  K.rect(6, 4, 4, 4, "sand")
  K.px(9, 5, "deep")
  -- Indigo coat with buckskin shoulder fringe & belt
  K.rect(5, 8, 6, 6, "blue")
  K.rect(5, 8, 2, 6, "sky_top")
  K.rect(5, 12, 6, 1, "wood")
  K.px(7, 12, "gold") -- brass belt buckle
  -- Boots & trousers
  K.rect(5, 14, 2, 3, "deep")
  K.rect(9, 14, 2, 3, "deep")
end)
K.save("hunt_hunter")

--------------------------------------------------------------------------------
-- 6. GRAVESTONE_FRAME (432x150: Prairie memorial scene with carved limestone slab)
--------------------------------------------------------------------------------
K.canvas(432, 150, 184886)
K.layer("prairie", function()
  -- The trail prairie behind the stone, read from the installed picture.
  local prairie = Image{ fromFile = app.fs.joinPath(app.fs.filePath(app.params.kit), "../pixels/prairie.png") }
  local names = {}
  for name, c in pairs(K.col) do names[c] = name end
  for y = 0, 149 do
    for x = 0, 431 do
      local name = names[prairie:getPixel(x, y)]
      if name then K.px(x, y, name) end
    end
  end
end)
K.layer("gravestone", function()
  -- Round-topped limestone headstone, the common 1840s shape. ui/grave_view.gd centres
  -- its inscription in x = 122..310 between y = 31 and 134, so that face stays plain.
  local cx, shoulder, left, right, base = 216, 36, 116, 316, 134
  local function arch(dx, inset)
    local rx, ry = 100 - inset, 28 - inset
    if math.abs(dx) > rx then return nil end
    return shoulder - math.floor(ry * math.sqrt(1 - (dx * dx) / (rx * rx)) + 0.5)
  end
  -- cast shadow to the lower right
  K.poly({{right, base + 6}, {right + 22, base + 6}, {right + 8, base - 2}}, "dirt_dk")
  for x = left + 6, right + 6 do
    local top = arch(x - cx - 6, 0)
    if top then for y = top + 4, base do K.px(x, y, "stone_ink") end end
  end
  -- side thickness, in shade
  for x = left + 2, right + 5 do
    local top = arch(x - cx - 4, 0)
    if top then for y = top + 1, base do K.px(x, y, "stone_dk") end end
  end
  -- face
  for x = left, right do
    local top = arch(x - cx, 0)
    if top then
      for y = top, base do K.px(x, y, "stone") end
      K.px(x, top, "stone_lt"); K.px(x, top + 1, "stone_lt")
    end
  end
  for y = shoulder, base do K.px(left, y, "stone_lt"); K.px(left + 1, y, "stone_lt") end
  -- smooth polished field for the lettering, with an incised border
  for x = left + 6, right - 6 do
    local top = arch(x - cx, 6)
    if top then
      for y = top, base - 6 do K.px(x, y, "stone_lt") end
      K.px(x, top, "stone_dk")
    end
  end
  for y = shoulder - 6, base - 6 do K.px(left + 6, y, "stone_dk"); K.px(right - 6, y, "stone") end
  K.rect(left + 6, base - 6, right - left - 11, 1, "stone")
  -- willow-and-urn emblem in the crown
  K.rect(cx - 3, 22, 7, 5, "stone_dk"); K.rect(cx - 2, 21, 5, 1, "stone_dk"); K.rect(cx - 1, 27, 3, 1, "stone_dk")
  K.rect(cx - 2, 23, 5, 3, "stone"); K.px(cx - 2, 23, "stone_lt")
  for i = 0, 4 do K.px(cx - 6 - i, 17 + i * 2, "stone_dk"); K.px(cx + 6 + i, 17 + i * 2, "stone_dk") end
  K.line(cx - 5, 16, cx + 5, 16, "stone_dk")
  -- weathering and lichen kept to the margins
  for i = 1, 70 do
    local x, y = left + 2 + K.rnd(right - left - 4), shoulder + K.rnd(base - shoulder)
    if x < left + 6 or x > right - 6 then K.px(x, y, (i % 3 == 0) and "sage" or "stone_dk") end
  end
  K.line(right - 4, 60, right - 1, 66, "stone_ink")
  -- plinth
  K.rect(left - 10, base, right - left + 21, 7, "stone")
  K.rect(left - 10, base, right - left + 21, 1, "stone_lt")
  K.rect(right + 5, base, 6, 7, "stone_dk")
  K.rect(left - 10, base + 6, right - left + 21, 1, "stone_ink")
  -- turned earth and prairie flowers
  K.ellipse(cx, 146, 120, 4, "wood")
  K.ellipse(cx, 146, 112, 3, "rust")
  for _, gx in ipairs({100, 107, 114, 318, 325, 333}) do
    K.line(gx, 146, gx - 2, 137, "pine")
    K.line(gx + 2, 146, gx + 4, 138, "grass")
    K.px(gx + 4, 137, "gold"); K.px(gx - 2, 136, "white")
  end
end)
K.save("gravestone_frame")

--------------------------------------------------------------------------------
-- 7. LEDGER_ICONS (56x8: 7 icons of 8x8 — food, health, cash, oxen, bullets, spares, weather)
--------------------------------------------------------------------------------
K.canvas(56, 8, 184887)
K.layer("icons", function()
  -- 0 (x=0..7): Food sack
  K.rect(1, 2, 5, 5, "ochre")
  K.rect(2, 2, 3, 4, "gold")
  K.rect(2, 0, 3, 2, "sand")
  K.rect(1, 1, 5, 1, "rust")
  -- 1 (x=8..15): Health apothecary cross
  K.rect(10, 1, 3, 5, "red")
  K.rect(9, 2, 5, 3, "red")
  K.px(10, 2, "gold")
  -- 2 (x=16..23): Cash gold eagle coin
  K.rect(17, 1, 5, 5, "ochre")
  K.rect(18, 1, 3, 5, "gold")
  K.rect(17, 2, 5, 3, "gold")
  K.px(18, 2, "white")
  -- 3 (x=24..31): Oxen horned head
  K.rect(24, 1, 2, 1, "cream")
  K.rect(29, 1, 2, 1, "cream")
  K.rect(25, 2, 5, 4, "wood")
  K.rect(26, 2, 3, 3, "rust")
  K.rect(26, 5, 3, 2, "sand")
  -- 4 (x=32..39): Bullets brass cartridge
  K.rect(33, 3, 5, 3, "gold")
  K.rect(34, 1, 3, 2, "roof_lt")
  K.rect(33, 5, 5, 1, "ochre")
  -- 5 (x=40..47): Spares wagon wheel
  K.rect(41, 1, 5, 5, "wood")
  K.rect(42, 2, 3, 3, "sand")
  K.px(43, 3, "deep")
  -- 6 (x=48..55): Weather sunburst
  K.rect(50, 2, 3, 3, "gold")
  K.px(51, 1, "cream"); K.px(51, 5, "cream")
  K.px(49, 3, "cream"); K.px(53, 3, "cream")
end)
K.save("ledger_icons")


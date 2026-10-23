-- Hunting & Memorial Sprites built via the Aseprite Lua pipeline
-- (the animated hunt animals and hunter are in hunt_animals.lua):
--   4. hunt_cover.png  (24x14: 2 variants of 12x14 — frame 0 = woodland bush, frame 1 = sagebrush clump)
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


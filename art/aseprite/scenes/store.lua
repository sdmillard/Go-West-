-- General Store & Outfitter Interior, Independence, 1848 (622x273 setup scene).
-- Informed by the Asa Knight country store reference in art/LOCATION_REFERENCES.md.
-- Note: ui/departure_view.gd places the shopping list panel over (267..622, 0..236)
-- and the footer bar over (0..622, 236..273), leaving the left bay (0..267, 0..236)
-- as the primary visible stage while keeping the full 622x273 canvas unified.
local K = dofile(app.params.kit)
local W, H = 622, 273
local FLOOR_Y = 186

K.canvas(W, H, 1848)

----------------------------------------------------------------- 1. Timber Walls, Overhead Rafters & Plank Floor
K.layer("architecture", function()
  -- Vertical beaded-plank timber wall across the full width
  K.rect(0, 0, W, FLOOR_Y, "wood")
  for x = 0, W - 1 do
    local mod = x % 12
    if mod == 0 then
      K.rect(x, 0, 1, FLOOR_Y, "deep")
    elseif mod == 1 then
      K.rect(x, 0, 1, FLOOR_Y, "ochre")
    elseif mod < 5 then
      K.rect(x, 0, 1, FLOOR_Y, "rust")
    end
  end
  -- Subtle wood grain texture
  for i = 1, 1400 do
    local gx, gy = K.rnd(W), 22 + K.rnd(FLOOR_Y - 26)
    if gx % 12 > 1 then
      K.px(gx, gy, (i % 3 == 0) and "deep" or ((i % 2 == 0) and "ochre" or "rust"))
    end
  end

  -- Heavy overhead ceiling joists & main tie beam
  K.rect(0, 0, W, 14, "ink")
  K.rect(0, 14, W, 8, "deep")
  K.rect(0, 14, W, 2, "ochre")
  K.rect(0, 21, W, 1, "ink")
  for jx = 18, W - 1, 56 do
    K.rect(jx, 0, 14, 14, "deep")
    K.rect(jx + 1, 0, 2, 14, "wood")
    K.rect(jx + 12, 0, 2, 14, "ink")
  end

  -- Chair rail / wainscoting cap along the lower wall
  K.rect(0, FLOOR_Y - 4, W, 2, "ochre")
  K.rect(0, FLOOR_Y - 2, W, 2, "ink")

  -- Wide-plank hardwood floor with receding perspective joints & wooden pegs
  K.rect(0, FLOOR_Y, W, H - FLOOR_Y, "ochre")
  local row_ys = {186, 196, 208, 222, 238, 255, 273}
  for r = 1, #row_ys - 1 do
    local y0, y1 = row_ys[r], row_ys[r + 1]
    local band_h = y1 - y0
    -- Alternating warm plank tones
    for y = y0, y1 - 1 do
      for x = 0, W - 1 do
        if (x + y) % 11 == 0 then K.px(x, y, "rust") end
        if (x * 3 + y) % 17 == 0 then K.px(x, y, "gold") end
      end
    end
    K.rect(0, y0, W, 1, "deep")
    K.rect(0, y0 + 1, W, 1, "gold")
  end
  -- Receding plank seam lines fanning out from the vanishing point (cx = 220, vy = 90)
  for bx = -120, W + 140, 34 do
    K.line(220 + math.floor((bx - 220) * 0.48), FLOOR_Y, bx, H - 1, "deep")
    K.line(220 + math.floor((bx - 220) * 0.48) + 1, FLOOR_Y, bx + 1, H - 1, "gold")
  end
end)

----------------------------------------------------------------- 2. Left Multi-Pane Store Window & Sunbeam
K.layer("window_and_shelving", function()
  -- Tall multi-pane shop window on the far left wall (x = 4..24, y = 30..136)
  K.rect(3, 28, 22, 110, "ink")
  K.rect(5, 30, 18, 106, "wood")
  for wy = 33, 117, 21 do
    K.rect(7, wy, 14, 18, "sky")
    K.rect(7, wy, 14, 6, "light_blue")
    K.rect(7, wy + 12, 14, 6, "sand")
    -- Window sash muntins
    K.rect(13, wy, 2, 18, "cream")
    K.rect(7, wy + 8, 14, 2, "cream")
    K.px(8, wy + 1, "white"); K.px(9, wy + 2, "white")
  end
  K.rect(2, 136, 24, 3, "ochre")
  K.rect(2, 136, 24, 1, "gold")

  -- Main Recessed Store Shelving Unit (x = 34..256, y = 26..152)
  local sx, sy, sw, sh = 34, 26, 222, 126
  -- Crown moulding & dark recessed cabinet back
  K.rect(sx - 3, sy - 3, sw + 6, 4, "ochre")
  K.rect(sx - 3, sy - 3, sw + 6, 1, "gold")
  K.rect(sx - 1, sy + 1, sw + 2, sh, "ink")
  K.rect(sx, sy + 2, sw, sh - 2, "deep")
  -- Vertical backing boards inside the cabinet
  for bx = sx + 8, sx + sw - 4, 8 do
    K.rect(bx, sy + 2, 1, sh - 2, "ink")
  end

  -- 3 Bays x 4 Shelf Tiers stocked with 1848 outfitting merchandise
  local bay_w = 70
  local shelf_ys = {54, 82, 110, 138}

  for bay = 0, 2 do
    local bx = sx + 4 + bay * 72

    -- Tier 1 (y = 30..53): Stoneware jugs, molasses crocks & apothecary bottles
    for i = 0, 4 do
      local jx = bx + 3 + i * 13
      if i % 2 == 0 then
        -- Stoneware jug with salt-glaze shoulder & cork
        K.rect(jx + 1, 39, 8, 14, "sand")
        K.rect(jx + 2, 37, 6, 3, "rust")
        K.rect(jx + 7, 39, 2, 14, "clap_sh")
        K.rect(jx + 2, 39, 2, 13, "cream")
        K.rect(jx + 3, 35, 4, 2, "wood")
        K.px(jx + 4, 34, "gold")
        -- Small handle loop
        K.px(jx + 8, 38, "rust"); K.px(jx + 9, 39, "rust"); K.px(jx + 8, 40, "rust")
      else
        -- Tall glass bottle (blue or green-teal) with paper label
        local bcol = (i == 1) and "blue" or "teal"
        local hcol = (i == 1) and "light_blue" or "haze"
        K.rect(jx + 2, 38, 6, 15, bcol)
        K.rect(jx + 3, 34, 4, 4, bcol)
        K.rect(jx + 3, 39, 1, 13, hcol)
        K.rect(jx + 4, 32, 2, 2, "sand")
        K.rect(jx + 3, 43, 4, 5, "cream")
        K.rect(jx + 4, 45, 2, 1, "ink")
      end
    end

    -- Tier 2 (y = 58..81): Rolled bolts of wool, ticking, calico & canvas cloth
    for i = 0, 3 do
      local cx = bx + 3 + i * 16
      local c_top = ({"red", "blue", "sage", "cream"})[i + 1]
      local c_bot = ({"blue", "gold", "brick", "teal"})[(i + bay) % 4 + 1]
      -- Bottom bolt
      K.rect(cx, 73, 14, 7, c_bot)
      K.rect(cx, 73, 14, 1, "cream")
      K.ellipse(cx + 13, 76, 2, 3, "sand")
      K.px(cx + 13, 76, "deep")
      -- Top stacked bolt
      K.rect(cx + 1, 65, 13, 7, c_top)
      K.rect(cx + 1, 65, 13, 1, "white")
      K.ellipse(cx + 13, 68, 2, 3, "cream")
      K.px(cx + 13, 68, "deep")
    end

    -- Tier 3 (y = 86..109): Tin canisters, coffee/tea caddies, ceramic bowls & spice boxes
    for i = 0, 4 do
      local tx = bx + 3 + i * 13
      if (i + bay) % 2 == 0 then
        -- Painted tin canister with brass lid
        local tcol = (i % 4 == 0) and "red" or ((i % 4 == 2) and "pine" or "blue")
        K.rect(tx + 1, 94, 9, 15, tcol)
        K.rect(tx + 2, 95, 2, 13, "ochre")
        K.rect(tx + 1, 92, 9, 2, "gold")
        K.rect(tx + 3, 98, 5, 6, "cream")
        K.rect(tx + 4, 100, 3, 2, "ink")
      else
        -- Nested ceramic bowls / stoneware crocks
        K.poly({{tx, 101}, {tx + 10, 101}, {tx + 8, 109}, {tx + 2, 109}}, "cream")
        K.rect(tx, 100, 10, 2, "blue")
        K.poly({{tx + 1, 95}, {tx + 9, 95}, {tx + 8, 100}, {tx + 2, 100}}, "sand")
        K.rect(tx + 1, 94, 8, 2, "rust")
      end
    end

    -- Tier 4 (y = 114..137): Wooden ammunition boxes, care kits, Boot boxes & folded blankets
    for i = 0, 2 do
      local kx = bx + 4 + i * 21
      K.rect(kx, 123, 18, 14, "ochre")
      K.rect(kx, 123, 18, 2, "gold")
      K.rect(kx + 15, 123, 3, 14, "rust")
      K.rect(kx + 2, 127, 11, 5, "cream")
      K.rect(kx + 4, 129, 7, 1, "ink")
      -- Smaller tin box on top
      K.rect(kx + 2, 116, 13, 7, (i == 1) and "red" or "teal")
      K.rect(kx + 2, 116, 13, 1, "sand")
    end
  end

  -- Horizontal shelf planks & Vertical cabinet stiles
  for _, y in ipairs(shelf_ys) do
    K.rect(sx, y, sw, 4, "wood")
    K.rect(sx, y, sw, 1, "gold")
    K.rect(sx, y + 3, sw, 1, "ink")
  end
  for _, vx in ipairs({sx, sx + 74, sx + 148, sx + sw - 4}) do
    K.rect(vx, sy, 5, sh, "wood")
    K.rect(vx, sy, 1, sh, "gold")
    K.rect(vx + 4, sy, 1, sh, "ink")
  end

  -- Right-side background wall shelving & peg-rail hardware (x = 280..605)
  -- Ensures the full 622x273 canvas is a complete period interior
  K.rect(280, 42, 326, 4, "deep")
  K.rect(280, 42, 326, 1, "ochre")
  for hx = 296, 590, 32 do
    K.rect(hx, 44, 2, 4, "ink")
    -- Hanging coiled ropes, canteens, and ox bows along the peg rail
    if (hx % 64 == 8) then
      K.ellipse(hx, 56, 6, 8, "ochre")
      K.ellipse(hx, 56, 3, 5, "wood")
    else
      K.ellipse(hx, 55, 5, 5, "blue")
      K.rect(hx - 1, 48, 3, 3, "gold")
    end
  end
end)

----------------------------------------------------------------- 3. Hanging Rafter Goods (Lanterns, Skillets, Ox Yoke, Baskets)
K.layer("hanging_goods", function()
  -- Woven splint baskets & brass oil lanterns hanging from the main ceiling beam
  for _, bx in ipairs({64, 138, 212}) do
    K.line(bx, 18, bx, 28, "ink")
    K.ellipse(bx, 33, 10, 5, "ochre")
    K.ellipse(bx, 32, 9, 4, "gold")
    K.rect(bx - 9, 29, 19, 2, "sand")
    for wx = bx - 7, bx + 7, 3 do K.px(wx, 32, "rust"); K.px(wx + 1, 34, "rust") end
  end

  -- Hanging cast-iron skillets & camp kettles on the left post (x = 26..32)
  for i, py in ipairs({56, 78, 100}) do
    K.line(29, py - 7, 29, py, "ink")
    K.ellipse(29, py + 3, 5, 5, "ink")
    K.ellipse(28, py + 2, 3, 3, "roof_dk")
    K.px(27, py + 1, "roof_lt")
  end

  -- Carved wooden ox-yoke hanging above the right end of the counter (x = 248)
  K.line(248, 18, 248, 29, "ink")
  K.rect(236, 29, 24, 4, "ochre")
  K.rect(236, 29, 24, 1, "gold")
  K.line(240, 33, 240, 43, "wood"); K.line(244, 33, 244, 43, "wood"); K.rect(240, 43, 5, 1, "wood")
  K.line(252, 33, 252, 43, "wood"); K.line(256, 33, 256, 43, "wood"); K.rect(252, 43, 5, 1, "wood")
end)

----------------------------------------------------------------- 4. Storekeeper, Panelled Counter, Scales & Barrels
K.layer("counter_and_stock", function()
  -- Storekeeper standing behind the counter (x = 180..206, y = 114..152)
  local kx, ky = 188, 152
  -- Head, beard, spectacles & hair
  K.rect(kx - 4, ky - 34, 9, 10, "skin")
  K.rect(kx + 2, ky - 34, 3, 10, "skin_dk")
  -- Hair & sideburns
  K.rect(kx - 5, ky - 36, 11, 3, "deep")
  K.rect(kx - 5, ky - 34, 2, 6, "deep")
  -- Full period beard
  K.poly({{kx - 4, ky - 27}, {kx + 5, ky - 27}, {kx + 3, ky - 21}, {kx - 2, ky - 21}}, "wood")
  K.rect(kx - 2, ky - 26, 4, 3, "deep")
  -- Eyes & brow
  K.px(kx - 2, ky - 31, "ink"); K.px(kx + 2, ky - 31, "ink")
  K.px(kx - 1, ky - 31, "gold"); K.px(kx + 1, ky - 31, "gold") -- brass spectacles bridge
  -- White shirt sleeves, waistcoat, and white canvas store apron
  K.rect(kx - 9, ky - 22, 19, 22, "cream")      -- rolled white sleeves
  K.rect(kx - 6, ky - 22, 13, 22, "blue")       -- waistcoat
  K.rect(kx - 4, ky - 18, 9, 18, "white")       -- apron bib
  K.rect(kx - 5, ky - 18, 1, 18, "sand")
  -- Left hand resting on the counter ledger, right arm gesturing toward the scales
  K.line(kx - 8, ky - 16, kx - 16, ky - 2, "cream")
  K.rect(kx - 18, ky - 2, 3, 2, "skin")
  K.rect(kx + 7, ky - 4, 3, 3, "skin")

  -- Long Panelled Hardwood Store Counter (x = 14..262, y = 151..192)
  local cx, cy, cw, ch = 14, 151, 248, 41
  -- Shadow cast by counter onto plank floor
  K.rect(cx + 2, cy + ch, cw, 4, "ink")
  -- Counter carcass
  K.rect(cx + 2, cy + 6, cw - 4, ch - 6, "ink")
  K.rect(cx + 4, cy + 7, cw - 8, ch - 8, "deep")
  -- Recessed fielded wood panels along the front of the counter
  for px_ = cx + 10, cx + cw - 36, 38 do
    K.rect(px_, cy + 11, 32, 24, "wood")
    K.rect(px_, cy + 11, 32, 1, "ochre")
    K.rect(px_, cy + 11, 1, 24, "ochre")
    K.rect(px_ + 31, cy + 11, 1, 24, "ink")
    K.rect(px_, cy + 34, 32, 1, "ink")
    K.rect(px_ + 3, cy + 14, 26, 18, "rust")
  end
  -- Thick scrubbed-oak countertop overhang
  K.rect(cx, cy, cw, 6, "ochre")
  K.rect(cx, cy, cw, 2, "gold")
  K.rect(cx, cy, 40, 1, "cream") -- morning window light on left countertop
  K.rect(cx, cy + 5, cw, 1, "ink")

  -- Countertop details: Brass Balance Scale, Open Ledger & Stacked Cheese/Cloth
  -- 1. Brass balance scale (x = 112, y = 136..151)
  K.rect(108, 149, 9, 2, "deep")
  K.rect(112, 138, 1, 11, "gold")
  K.line(104, 140, 120, 140, "gold")
  -- Left & right scale pans
  K.line(105, 140, 103, 146, "ochre"); K.line(105, 140, 107, 146, "ochre")
  K.rect(102, 146, 7, 2, "gold"); K.px(103, 146, "cream")
  K.line(119, 140, 117, 147, "ochre"); K.line(119, 140, 121, 147, "ochre")
  K.rect(116, 147, 7, 2, "gold")

  -- 2. Open store ledger & inkwell under the keeper's hand (x = 145..174, y = 146..151)
  K.poly({{146, 150}, {150, 146}, {172, 146}, {175, 150}}, "cream")
  K.rect(146, 150, 30, 1, "deep")
  K.line(160, 146, 160, 150, "sand")
  K.rect(151, 148, 7, 1, "blue"); K.rect(163, 148, 7, 1, "blue")
  K.rect(140, 147, 3, 4, "ink"); K.line(141, 147, 144, 142, "white") -- quill in inkwell

  -- 3. Wrapped parcel & twine spool on left counter (x = 46..72)
  K.rect(46, 144, 20, 7, "sand")
  K.rect(46, 144, 20, 2, "cream")
  K.rect(55, 144, 1, 7, "rust")
  K.rect(46, 147, 20, 1, "rust")

  -- Coopered Provision Barrels, Burlap Flour Sacks & Wooden Crates in the Foreground
  local function large_barrel(bx, by, w, h, open_top, fill_c)
    K.ellipse(bx + w / 2, by + h, w / 2 + 2, 4, "ink")
    -- Rounded coopered stave body
    K.ellipse(bx + w / 2, by + h / 2, w / 2, h / 2, "wood")
    K.rect(bx + 2, by + 3, w - 4, h - 6, "wood")
    -- Upper-left lit staves & right shaded staves
    K.rect(bx + 3, by + 3, math.floor(w * 0.35), h - 6, "rust")
    K.rect(bx + 5, by + 3, 3, h - 6, "ochre")
    K.rect(bx + w - 6, by + 3, 4, h - 6, "deep")
    -- Vertical stave seams
    for sx = bx + 5, bx + w - 5, 5 do
      K.line(sx, by + 3, sx, by + h - 4, "deep")
    end
    -- Top & bottom chime + four iron hoops
    for _, hy in ipairs({by + 5, by + 13, by + h - 13, by + h - 6}) do
      K.rect(bx + 1, hy, w - 2, 2, "ink")
      K.rect(bx + 3, hy, 6, 1, "roof_lt")
    end
    K.ellipse(bx + w / 2, by + 3, w / 2 - 1, 4, "ochre")
    if open_top and fill_c then
      K.ellipse(bx + w / 2, by + 3, w / 2 - 3, 3, fill_c)
      K.ellipse(bx + w / 2 - 1, by + 2, w / 2 - 5, 2, "white")
    else
      K.ellipse(bx + w / 2, by + 3, w / 2 - 3, 2, "sand")
    end
  end

  -- Three barrels on the left (Flour, Salt, Salt Pork) + one barrel & burlap sacks on the right
  large_barrel(20, 180, 28, 38, true, "cream")   -- Open flour barrel
  large_barrel(58, 183, 28, 38, false, nil)      -- Sealed provision barrel
  large_barrel(96, 181, 28, 38, true, "sand")    -- Cornmeal / salt barrel
  large_barrel(212, 182, 28, 38, false, nil)     -- Right counter barrel

  -- Burlap grain/bacon sacks leaning beside the barrels (x = 132..176, y = 192..220)
  K.ellipse(152, 217, 18, 4, "ink")
  K.ellipse(146, 207, 11, 9, "sand")
  K.ellipse(145, 206, 9, 7, "cream")
  K.rect(143, 196, 6, 3, "ochre")
  K.rect(142, 198, 8, 1, "red") -- tied sack neck

  K.ellipse(160, 210, 12, 8, "ochre")
  K.ellipse(159, 209, 10, 6, "sand")

  -- Wooden ammunition / hardware crate at (176, 198)
  K.rect(176, 198, 26, 20, "ink")
  K.rect(177, 199, 24, 18, "ochre")
  K.rect(177, 199, 24, 3, "gold")
  K.rect(196, 199, 5, 18, "rust")
  K.line(178, 216, 195, 200, "rust")
  K.line(179, 216, 196, 200, "gold")
end)

K.save("location_store")

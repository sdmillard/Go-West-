-- Trade room of a fur-trade post, 1848 (622x273, the trading-post store screen).
-- no seasons: build.sh --seasons skips this script (indoors, a trading counter, or its own season).
-- Laramie, Hall and Boise were adobe forts, so the walls are mud plaster under round log vigas
-- and a pole ceiling, the floor is packed earth and the light comes from one deep-set window.
-- Stock is what the posts dealt in: flour by the barrel and sack, point blankets, bolts of
-- stroud cloth, tin kettles, powder kegs, steel traps, and buffalo robes taken in trade.
-- ui/post_store_view.gd covers (267..622, 0..236) with the goods list and the bottom strip with
-- the footer, so the clerk, counter and stock all sit in the left bay (0..267, 0..236).
local K = dofile(app.params.kit)
local W, H = 622, 273
local FLOOR_Y = 188

K.canvas(W, H, 1849)

----------------------------------------------------------------- 1. Adobe walls, vigas, earth floor
K.layer("room", function()
  -- mud plaster, lighter near the window, with trowel marks and hairline cracks
  K.rect(0, 0, W, FLOOR_Y, "sand")
  for i = 1, 2600 do
    local x, y = K.rnd(W), 24 + K.rnd(FLOOR_Y - 24)
    K.px(x, y, (i % 4 == 0) and "clap_sh" or ((i % 3 == 0) and "gold" or "cream"))
  end
  for i = 1, 14 do
    local x, y = K.rnd(W), 40 + K.rnd(120)
    for s = 0, 5 + K.rnd(8) do
      x = x + K.rnd(3) - 1; y = y + 1
      K.px(x, y, "clap_sh")
    end
  end
  -- darker mud wainscot where hands, packs and boots wear the wall
  K.rect(0, FLOOR_Y - 26, W, 26, "ochre")
  for i = 1, 900 do K.px(K.rnd(W), FLOOR_Y - 26 + K.rnd(26), (i % 2 == 0) and "dirt_dk" or "gold") end
  K.rect(0, FLOOR_Y - 27, W, 1, "dirt_dk")
  -- pole ceiling (latillas) over round vigas whose ends sit in the wall
  K.rect(0, 0, W, 22, "deep")
  for x = 0, W - 1, 3 do K.rect(x, 0, 2, 12, (x % 2 == 0) and "wood" or "rust"); K.px(x, 11, "ink") end
  K.rect(0, 12, W, 2, "ink")
  for vx = 6, W - 1, 64 do
    K.rect(vx, 12, 22, 12, "ink")
    K.rect(vx + 1, 12, 20, 10, "wood")
    K.rect(vx + 3, 13, 6, 8, "ochre")
    K.rect(vx + 4, 14, 2, 6, "gold")
    K.rect(vx + 16, 13, 4, 9, "deep")
  end
  K.rect(0, 22, W, 2, "clap_sh")
  -- packed earth floor, darker toward the counter and with a worn path to the door
  K.rect(0, FLOOR_Y, W, H - FLOOR_Y, "dirt_dk")
  for y = FLOOR_Y, H - 1 do
    for x = 0, W - 1 do
      local r = K.rnd(23)
      if r == 0 then K.px(x, y, "shadow") elseif r == 1 then K.px(x, y, "ochre") end
    end
  end
  K.rect(0, FLOOR_Y, W, 2, "shadow")
  for y = FLOOR_Y + 14, H - 1 do
    local half = math.floor((y - FLOOR_Y) * 0.9)
    for x = 300 - half, 330 + half, 1 do
      if K.rnd(3) == 0 then K.px(x, y, "ochre") end
    end
  end
end)

----------------------------------------------------------------- 2. Window, door and wall gear
K.layer("openings", function()
  -- deep-set window with a pole grille and an open plank shutter
  local wx, wy = 14, 46
  K.rect(wx - 4, wy - 4, 34, 46, "clap_sh")
  K.rect(wx - 2, wy - 2, 30, 42, "stone_dk")
  K.rect(wx, wy, 26, 38, "sky")
  K.rect(wx, wy + 22, 26, 16, "far_hill")
  K.rect(wx, wy + 30, 26, 8, "sage")
  K.rect(wx, wy, 26, 6, "sky_top")
  for gx = wx + 5, wx + 22, 6 do K.rect(gx, wy, 2, 38, "deep"); K.px(gx, wy, "wood") end
  K.rect(wx - 4, wy + 40, 34, 3, "wood"); K.rect(wx - 4, wy + 40, 34, 1, "ochre")
  K.rect(wx + 30, wy - 2, 6, 44, "wood"); K.rect(wx + 30, wy - 2, 1, 44, "ochre")
  K.rect(wx + 35, wy - 2, 1, 44, "ink")
  -- window light falling across the plaster
  for i = 0, 40 do
    local y = wy + 44 + i
    for x = wx + 2 + i, wx + 22 + i do
      if (x + y) % 2 == 0 and y < FLOOR_Y - 27 then K.px(x, y, "cream") end
    end
  end
  -- far end of the room (under the goods list): the door to the placita in daylight
  K.rect(560, 70, 40, FLOOR_Y - 70, "ink")
  K.rect(562, 72, 36, FLOOR_Y - 72, "gold")
  K.rect(562, 72, 36, 40, "sky")
  K.rect(562, 150, 36, FLOOR_Y - 150, "sand")
  K.rect(556, 66, 48, 4, "wood")
  -- steel traps and a coil of rope on pegs along the back wall
  for tx = 300, 520, 44 do
    K.px(tx, 48, "ink"); K.px(tx, 49, "ink")
    K.ellipse(tx, 58, 7, 5, "stone_dk")
    K.ellipse(tx, 58, 5, 3, "sand")
    K.rect(tx, 50, 1, 4, "stone_ink")
    K.rect(tx - 1, 63, 3, 10, "stone_ink")
  end
end)

----------------------------------------------------------------- 3. Shelves of trade goods behind the counter
K.layer("shelves", function()
  local sx, sw = 62, 196
  -- rough adzed plank shelves on peg brackets
  K.rect(sx, 34, sw, 112, "deep")
  K.rect(sx + 2, 36, sw - 4, 108, "wood")
  for y = 36, 140, 3 do
    for x = sx + 2, sx + sw - 3 do if K.rnd(9) == 0 then K.px(x, y, "rust") end end
  end
  local shelf_y = {62, 92, 120, 144}
  for _, y in ipairs(shelf_y) do
    K.rect(sx - 2, y, sw + 4, 3, "ochre"); K.rect(sx - 2, y, sw + 4, 1, "gold")
    K.rect(sx - 2, y + 3, sw + 4, 1, "ink")
  end
  K.rect(sx, 34, 3, 112, "ink"); K.rect(sx + sw - 3, 34, 3, 112, "ink")
  K.rect(sx + 96, 34, 3, 112, "ink")

  -- top shelf: point blankets folded in stacks, cream with coloured head stripes
  local stripes = {{"leaf", "red", "gold", "blue"}, {"blue"}, {"red"}}
  local bx = sx + 6
  for n = 1, 7 do
    local kind = stripes[(n % 3) + 1]
    local fill = (n % 3 == 2) and "red" or ((n % 3 == 1) and "white" or "cream")
    if n == 5 then fill = "blue" end
    for layer = 0, 2 do
      local y = 62 - 7 - layer * 7
      K.rect(bx, y, 20, 7, fill); K.rect(bx, y + 6, 20, 1, "ink")
      K.px(bx, y, "white")
      if fill ~= "red" and fill ~= "blue" then
        for s, c in ipairs(kind) do K.rect(bx, y + 1 + s, 20, 1, c) end
      else
        K.rect(bx, y + 2, 20, 1, "ink")
      end
    end
    bx = bx + (n == 4 and 32 or 24)
  end

  -- second shelf: bolts of stroud cloth on end, and tin kettles
  local cloth = {"blue", "red", "blue", "red", "deep", "leaf"}
  for n, c in ipairs(cloth) do
    local x = sx + 6 + (n - 1) * 14
    K.rect(x, 70, 11, 22, c); K.rect(x, 70, 11, 1, "cream"); K.rect(x + 10, 70, 1, 22, "ink")
    K.rect(x + 2, 72, 1, 18, (c == "red") and "brick_lt" or "light_blue")
    K.rect(x, 80, 11, 1, "cream")
  end
  for n = 0, 3 do
    local x = sx + 106 + n * 22
    K.ellipse(x + 8, 84, 8, 7, "stone_dk")
    K.ellipse(x + 7, 83, 6, 5, "stone")
    K.rect(x + 4, 79, 3, 2, "stone_lt")
    K.rect(x, 76, 16, 2, "stone_ink")
    K.line(x + 1, 76, x + 8, 71, "stone_ink"); K.line(x + 15, 76, x + 8, 71, "stone_ink")
    K.rect(x + 2, 90, 12, 2, "ink")
  end

  -- third shelf: twists of tobacco, beads in paper, coffee and sugar sacks, powder horns
  for n = 0, 5 do
    local x = sx + 6 + n * 14
    K.rect(x, 104, 11, 16, "cream"); K.rect(x, 104, 11, 2, "clap_sh"); K.rect(x + 10, 104, 1, 16, "clap_sh")
    K.px(x + 3, 110, "red"); K.px(x + 6, 110, "red"); K.px(x + 4, 112, "deep")
  end
  for n = 0, 4 do
    local x = sx + 104 + n * 18
    K.rect(x, 100, 3, 20, "ochre"); K.line(x, 100, x + 10, 118, "ox_dk"); K.line(x + 1, 100, x + 11, 118, "ox")
    K.rect(x + 12, 106, 4, 14, "brick")
  end

  -- bottom shelf: powder kegs and lead bars
  for n = 0, 6 do
    local x = sx + 6 + n * 26
    K.rect(x, 130, 14, 14, "wood"); K.rect(x + 1, 130, 4, 14, "rust")
    K.rect(x, 132, 14, 1, "ink"); K.rect(x, 140, 14, 1, "ink"); K.rect(x, 129, 14, 1, "ochre")
    K.rect(x + 16, 139, 7, 5, "stone_dk"); K.rect(x + 16, 139, 7, 1, "stone")
  end

  -- a steelyard hanging from the viga over the counter
  K.rect(240, 24, 1, 34, "stone_ink")
  K.rect(226, 58, 30, 2, "stone_ink")
  K.rect(252, 60, 4, 6, "ink")
  K.line(228, 60, 224, 72, "stone_ink"); K.line(228, 60, 232, 72, "stone_ink")
  K.rect(222, 72, 12, 2, "stone_dk")
end)

----------------------------------------------------------------- 4. Clerk and counter
K.layer("counter", function()
  -- the clerk: a company man in shirtsleeves and waistcoat, with a ledger
  local kx, ky = 150, 150
  K.rect(kx - 4, ky - 36, 9, 10, "skin"); K.rect(kx + 2, ky - 36, 3, 10, "skin_dk")
  K.rect(kx - 5, ky - 38, 11, 3, "deep"); K.rect(kx - 5, ky - 36, 2, 5, "deep")
  K.rect(kx - 4, ky - 29, 9, 3, "wood")              -- short beard
  K.px(kx - 2, ky - 33, "ink"); K.px(kx + 2, ky - 33, "ink")
  K.rect(kx - 9, ky - 26, 19, 26, "cream")           -- shirt
  K.rect(kx - 6, ky - 26, 13, 26, "ink")             -- waistcoat
  K.rect(kx - 1, ky - 26, 3, 26, "white")
  K.px(kx - 3, ky - 20, "gold"); K.px(kx - 3, ky - 15, "gold")
  K.rect(kx - 2, ky - 26, 5, 2, "red")               -- neckcloth
  K.line(kx + 9, ky - 22, kx + 16, ky - 6, "cream"); K.rect(kx + 15, ky - 6, 3, 3, "skin")
  K.line(kx - 9, ky - 22, kx - 14, ky - 6, "cream"); K.rect(kx - 16, ky - 6, 3, 3, "skin")

  -- heavy plank counter, adzed and pegged
  local cx, cy, cw = 34, 150, 228
  K.rect(cx + 2, FLOOR_Y, cw, 3, "shadow")
  K.rect(cx, cy, cw, FLOOR_Y - cy, "deep")
  for y = cy + 6, FLOOR_Y - 1, 8 do
    K.rect(cx + 2, y, cw - 4, 7, "wood")
    K.rect(cx + 2, y, cw - 4, 1, "rust")
    for x = cx + 2, cx + cw - 3 do if K.rnd(11) == 0 then K.px(x, y + 3, "rust") end end
  end
  for x = cx + 20, cx + cw - 10, 52 do K.rect(x, cy + 6, 2, FLOOR_Y - cy - 6, "ink"); K.px(x, cy + 10, "gold"); K.px(x, cy + 26, "gold") end
  K.rect(cx - 2, cy, cw + 4, 6, "ochre"); K.rect(cx - 2, cy, cw + 4, 1, "gold"); K.rect(cx - 2, cy + 5, cw + 4, 1, "ink")
  K.rect(cx - 2, cy, 30, 1, "cream")
  -- ledger, inkwell and a stack of coin on the counter
  K.rect(126, 145, 20, 5, "white"); K.rect(136, 145, 1, 5, "clap_sh"); K.rect(126, 149, 20, 1, "brick_dk")
  K.rect(128, 146, 6, 1, "stone_dk"); K.rect(139, 147, 5, 1, "stone_dk")
  K.rect(112, 146, 4, 4, "ink"); K.px(113, 145, "stone")
  K.rect(172, 147, 5, 3, "gold"); K.rect(172, 146, 5, 1, "cream")
  -- a folded blanket and a beaver pelt on the counter, just traded
  K.rect(60, 142, 26, 8, "cream"); K.rect(60, 144, 26, 1, "red"); K.rect(60, 146, 26, 1, "gold"); K.rect(60, 149, 26, 1, "ink")
  K.ellipse(210, 146, 10, 4, "ox_dk"); K.ellipse(209, 145, 8, 2, "ox"); K.rect(219, 145, 4, 2, "ox_dk")
end)

----------------------------------------------------------------- 5. Floor stock in front of the counter
K.layer("floor_stock", function()
  -- buffalo robes taken in trade, piled and baled
  local function robe(x, y, w, lift)
    -- a folded robe: dark shaggy hair side out, the tanned skin edge showing at one end
    for i = 0, w - 1 do
      local sag = (i < 3 or i > w - 4) and 1 or 0
      local top = y - 7 + sag + ((i + lift) % 7 == 0 and -1 or 0)
      K.rect(x + i, top, 1, y - top, "ox_dk")
      if K.rnd(3) == 0 then K.px(x + i, top, "ox") end
      if K.rnd(4) == 0 then K.px(x + i, top + 2 + K.rnd(3), "deep") end
      if K.rnd(5) == 0 then K.px(x + i, top + 1, "ox_lt") end
    end
    K.rect(x + 1, y - 1, w - 2, 1, "deep")
    K.rect(x + w - 3, y - 6, 3, 5, "sand"); K.px(x + w - 3, y - 6, "cream"); K.px(x + w - 1, y - 2, "clap_sh")
  end
  K.rect(2, 219, 66, 3, "shadow")
  robe(4, 219, 60, 0); robe(8, 212, 55, 3); robe(3, 205, 60, 1); robe(10, 198, 48, 5)
  -- rawhide bale cords
  for _, x in ipairs({18, 46}) do K.rect(x, 190, 1, 29, "gold"); K.rect(x + 1, 190, 1, 29, "dirt_dk") end
  -- flour: a barrel and sacks marked in the company stencil
  local function barrel(x, y)
    K.rect(x, y - 24, 18, 24, "wood"); K.rect(x + 2, y - 24, 5, 24, "ochre"); K.rect(x + 14, y - 24, 4, 24, "deep")
    K.rect(x, y - 21, 18, 2, "stone_ink"); K.rect(x, y - 6, 18, 2, "stone_ink")
    K.rect(x - 1, y - 25, 20, 2, "deep"); K.rect(x + 1, y - 26, 16, 1, "cream")
    K.rect(x + 2, y, 18, 2, "shadow")
  end
  barrel(86, 216)
  barrel(108, 212)
  local function sack(x, y)
    K.ellipse(x + 9, y - 8, 10, 8, "cream")
    K.ellipse(x + 7, y - 10, 6, 5, "white")
    K.rect(x + 6, y - 18, 6, 3, "clap_sh"); K.rect(x + 7, y - 20, 4, 2, "stone_dk")
    K.rect(x + 5, y - 9, 8, 1, "blue"); K.rect(x + 7, y - 7, 4, 1, "blue")
    K.rect(x, y, 20, 2, "shadow")
  end
  sack(134, 220); sack(152, 222); sack(144, 210)
  -- a sawbuck pack saddle on its pad, by the counter's end
  K.rect(184, 216, 30, 3, "shadow")
  K.rect(186, 206, 26, 10, "red"); K.rect(186, 206, 26, 1, "brick_lt"); K.rect(186, 215, 26, 1, "brick_dk")
  K.rect(188, 209, 22, 1, "gold")
  for _, x in ipairs({191, 205}) do
    K.line(x - 4, 207, x + 3, 194, "ochre"); K.line(x - 3, 207, x + 4, 194, "deep")
    K.line(x + 4, 207, x - 3, 194, "wood"); K.line(x + 5, 207, x - 2, 194, "deep")
  end
  K.rect(190, 203, 18, 2, "wood")
  K.rect(222, 210, 8, 4, "stone_dk"); K.rect(232, 212, 8, 4, "stone_dk"); K.rect(222, 210, 8, 1, "stone_lt")
end)

K.save("location_post_store")

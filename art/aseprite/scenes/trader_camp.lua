-- A passing trading party's camp beside the road, 1848 (622x273, the passing-traders counter screen).
-- no seasons: build.sh --seasons skips this script (indoors, a trading counter, or its own season).
-- Parties out of Fort Laramie, Bridger's post and Taos met the trains with a light wagon and pack
-- mules: flour, powder and lead, blankets, tin kettles and buffalo robes, laid out on a robe for the
-- emigrants to look over. They wanted clothing, ammunition and footsore oxen to fatten and resell.
-- ui/post_store_view.gd covers (244..622, 0..236) with the two goods panels and the bottom strip with
-- the footer, so the trader, his wagon, goods and mules all sit in the left bay (0..244, 0..236).
local K = dofile(app.params.kit)
local W, H = 622, 273
local HORIZON = 112

K.canvas(W, H, 1848)

----------------------------------------------------------------- 1. Sky, far bluffs, sage flat
K.layer("land", function()
  K.sky(W, HORIZON, {{40, 18, 1.6}, {170, 34, 1.1}, {420, 22, 1.4}}, "mist")
  -- low buff bluffs on the far side of the flat
  local bl = function(x) return 10 + 6 * math.max(0, math.sin(x / 37 + 0.6)) + 2 * math.sin(x / 11) end
  K.ridge(0, W - 1, HORIZON, HORIZON, bl, "clap_sh", "cream", "stone_dk")
  -- the flat itself: dry grass going to sage, lighter in the distance
  K.rect(0, HORIZON, W, H - HORIZON, "sage")
  for y = HORIZON, H - 1 do
    for x = 0, W - 1 do
      local r = K.rnd(math.max(4, 40 - math.floor((y - HORIZON) / 5)))
      if r == 0 then K.px(x, y, "grass") elseif r == 1 then K.px(x, y, "gold") elseif r == 2 and y > 150 then K.px(x, y, "clap_sh") end
    end
  end
  K.rect(0, HORIZON, W, 1, "far_hill")
  -- the wagon road, worn to bare dirt, running back toward the bluffs
  for y = HORIZON + 4, H - 1 do
    local t = (y - HORIZON) / (H - HORIZON)
    local cx = math.floor(330 - 140 * t)
    local half = math.floor(4 + 60 * t)
    for x = cx - half, cx + half do
      if K.rnd(4) ~= 0 then K.px(x, y, "dirt_dk") else K.px(x, y, "ochre") end
    end
  end
  -- sagebrush clumps, small in the distance and larger near
  for i = 1, 70 do
    local y = HORIZON + 4 + K.rnd(H - HORIZON - 4)
    local x = K.rnd(W)
    if y < 160 then K.sage(x, y) else K.sage(x, y); K.sage(x + 3, y + 1) end
  end
  -- a far wagon train coming up the road
  K.far_wagon(318, HORIZON + 8, -1)
  K.far_wagon(342, HORIZON + 7, -1)
end)

----------------------------------------------------------------- 2. Mules picketed behind the wagon
local function mule(x, y, coat, lit, facing)
  -- about 40 px long; (x, y) = hind hoof at ground level. Deep barrel, short upright mane,
  -- a heavy plain head and long thick ears: a mule, not a horse or a deer.
  local f = facing
  local function at(dx) return x + dx * f end
  local function box(dx, yy, w, h, c) K.rect(math.min(at(dx), at(dx + w - 1)), yy, w, h, c) end
  box(-2, y + 1, 42, 2, "shadow")
  -- legs, thick, with dark hocks and small hooves
  for _, dx in ipairs({1, 6, 26, 31}) do box(dx, y - 14, 3, 14, coat); box(dx, y - 4, 3, 3, "ink"); box(dx, y, 3, 1, "ink") end
  -- barrel and hindquarters
  K.ellipse(at(17), y - 20, 17, 8, coat)
  K.ellipse(at(15), y - 24, 13, 3, lit)
  K.ellipse(at(4), y - 22, 6, 7, coat)
  -- neck rising to the head
  K.poly({{at(27), y - 26}, {at(33), y - 38}, {at(38), y - 36}, {at(34), y - 17}}, coat)
  K.line(at(28), y - 27, at(33), y - 38, "ink")
  -- long heavy head angled down, pale muzzle
  K.poly({{at(33), y - 40}, {at(38), y - 41}, {at(44), y - 28}, {at(40), y - 25}}, coat)
  box(41, y - 29, 3, 3, "ox_lt")
  K.px(at(37), y - 37, "ink")
  -- the ears: long, thick, set wide
  box(33, y - 48, 2, 8, coat); box(36, y - 47, 2, 7, coat)
  box(33, y - 48, 1, 6, "ink"); box(37, y - 47, 1, 6, "ink")
  -- tufted tail
  K.line(at(0), y - 24, at(-3), y - 12, "ink"); box(-4, y - 12, 3, 4, "ink")
  -- halter rope to the picket line
  K.line(at(40), y - 27, at(46), y - 33, "clap_sh")
end

K.layer("mules", function()
  -- picket line between two stakes
  K.line(150, 150, 238, 146, "clap_sh"); K.rect(150, 146, 1, 6, "wood"); K.rect(238, 142, 1, 6, "wood")
  mule(206, 156, "ox_dk", "ox", -1)
  mule(244, 152, "stone_ink", "stone_dk", -1)
  -- pack saddles stacked by the stake
  K.rect(214, 158, 22, 2, "shadow")
  K.rect(216, 150, 18, 8, "red"); K.rect(216, 150, 18, 1, "brick_lt")
  K.line(218, 150, 222, 143, "wood"); K.line(232, 150, 228, 143, "wood"); K.rect(221, 143, 8, 1, "wood")
end)

----------------------------------------------------------------- 3. The trader's light wagon, tailgate down
K.layer("wagon", function()
  local x, y = 18, 196              -- ground line under the wheels
  K.rect(x - 4, y + 1, 128, 4, "wagon_shadow")
  -- running gear and reach
  K.rect(x + 8, y - 26, 104, 4, "deep")
  -- box bed, plank sides, seen three-quarter with the tail toward us on the right
  K.rect(x, y - 54, 116, 28, "wood")
  for yy = y - 52, y - 28, 6 do K.rect(x + 1, yy, 114, 1, "rust") end
  K.rect(x, y - 54, 116, 2, "ochre"); K.rect(x, y - 27, 116, 1, "ink")
  K.rect(x + 112, y - 54, 4, 28, "deep")
  -- canvas cover rolled back on its bows so the goods show
  for _, bx in ipairs({10, 34, 58}) do
    K.line(x + bx, y - 54, x + bx + 4, y - 80, "wood"); K.line(x + bx + 4, y - 80, x + bx + 18, y - 82, "wood")
  end
  K.rect(x + 6, y - 86, 64, 8, "cream"); K.rect(x + 6, y - 86, 64, 2, "white"); K.rect(x + 6, y - 79, 64, 1, "clap_sh")
  for bx = x + 10, x + 66, 9 do K.rect(bx, y - 86, 1, 8, "sand") end
  -- goods still in the bed: barrels, a crate and blanket bales
  K.barrel(x + 72, y - 54); K.barrel(x + 80, y - 54)
  K.rect(x + 88, y - 64, 20, 10, "ochre"); K.rect(x + 88, y - 64, 20, 1, "gold"); K.line(x + 88, y - 55, x + 107, y - 64, "rust")
  K.rect(x + 12, y - 62, 22, 8, "cream"); K.rect(x + 12, y - 59, 22, 1, "red"); K.rect(x + 12, y - 56, 22, 1, "blue")
  K.rect(x + 36, y - 60, 18, 6, "blue"); K.rect(x + 36, y - 58, 18, 1, "light_blue")
  -- big wheels: hind under the tail, front under the seat
  K.wheel(x + 92, y - 16, 16)
  K.wheel(x + 26, y - 13, 13)
  -- tongue propped on the ground, toward the mules
  K.line(x - 2, y - 20, x - 16, y - 2, "wood")
  -- tailgate let down on chains as a counter
  K.rect(x + 116, y - 30, 22, 4, "ochre"); K.rect(x + 116, y - 30, 22, 1, "gold"); K.rect(x + 116, y - 27, 22, 1, "deep")
  K.line(x + 115, y - 50, x + 136, y - 30, "stone_dk")
  -- goods set out on the tailgate: a tin kettle, lead bars and a powder horn
  K.rect(x + 120, y - 37, 8, 7, "stone"); K.rect(x + 120, y - 37, 8, 1, "stone_lt"); K.rect(x + 127, y - 36, 2, 3, "stone_dk")
  K.line(x + 121, y - 39, x + 127, y - 39, "stone_dk")
  K.rect(x + 130, y - 32, 6, 2, "stone_dk"); K.rect(x + 130, y - 34, 6, 2, "stone_ink")
end)

----------------------------------------------------------------- 4. Goods spread on a robe, and the trader
K.layer("goods", function()
  -- a buffalo robe laid hair-down, the tanned side painted with a simple border
  K.poly({{24, 214}, {150, 210}, {162, 232}, {14, 236}}, "sand")
  K.poly({{28, 216}, {146, 212}, {156, 230}, {20, 233}}, "clap_sh")
  for x = 30, 148, 6 do K.px(x, 215, "red"); K.px(x - 6, 232, "red") end
  K.line(14, 236, 24, 214, "ox_dk"); K.line(150, 210, 162, 232, "ox_dk")
  -- flour sacks
  local function sack(x, y)
    K.ellipse(x + 8, y - 7, 9, 7, "cream"); K.ellipse(x + 6, y - 9, 5, 4, "white")
    K.rect(x + 5, y - 16, 6, 3, "clap_sh"); K.rect(x + 6, y - 18, 4, 2, "stone_dk")
    K.rect(x + 4, y - 7, 8, 1, "blue")
  end
  sack(30, 228); sack(46, 226)
  -- a keg of powder, a box of balls and caps
  K.rect(66, 212, 14, 14, "wood"); K.rect(68, 212, 4, 14, "ochre"); K.rect(66, 215, 14, 1, "stone_ink"); K.rect(66, 222, 14, 1, "stone_ink")
  K.rect(65, 211, 16, 2, "deep"); K.rect(72, 216, 3, 3, "ink")
  K.rect(86, 218, 14, 8, "ochre"); K.rect(86, 218, 14, 1, "gold"); K.rect(88, 220, 10, 4, "stone_ink")
  for bx = 89, 97, 2 do K.px(bx, 221, "stone_lt"); K.px(bx, 223, "stone") end
  -- folded point blankets and a bolt of red stroud
  K.rect(104, 214, 22, 10, "cream"); K.rect(104, 216, 22, 1, "red"); K.rect(104, 218, 22, 1, "gold"); K.rect(104, 220, 22, 1, "blue"); K.rect(104, 223, 22, 1, "clap_sh")
  K.rect(108, 208, 16, 6, "red"); K.rect(108, 208, 16, 1, "brick_lt"); K.rect(108, 213, 16, 1, "brick_dk")
  -- a coil of rope and a spare wheel leaning on the robe's edge
  K.ellipse(136, 226, 6, 3, "gold"); K.ellipse(136, 226, 3, 1, "clap_sh")
  K.wheel(150, 218, 10)
  -- a sack of salt and twists of tobacco
  K.ellipse(60, 232, 5, 3, "white"); K.rect(58, 228, 4, 2, "clap_sh")
  K.rect(122, 230, 8, 2, "wood"); K.rect(124, 229, 4, 1, "rust")

  -- the trader: a mountain man in a fringed buckskin shirt, slouch hat and leggings, with his rifle
  local px_, gy = 186, 224
  K.rect(px_ - 9, gy + 1, 22, 3, "wagon_shadow")
  -- moccasins and leggings
  K.rect(px_ - 5, gy - 2, 5, 2, "deep"); K.rect(px_ + 2, gy - 2, 5, 2, "deep")
  K.rect(px_ - 4, gy - 22, 4, 20, "ox_dk"); K.rect(px_ + 2, gy - 22, 4, 20, "ox_dk")
  K.rect(px_ - 4, gy - 22, 1, 20, "ox"); for yy = gy - 20, gy - 4, 3 do K.px(px_ - 5, yy, "ochre"); K.px(px_ + 6, yy, "ochre") end
  -- buckskin shirt with fringe at the hem and sleeves, a belt with a knife
  K.rect(px_ - 7, gy - 44, 15, 23, "ochre"); K.rect(px_ - 7, gy - 44, 4, 23, "gold"); K.rect(px_ + 5, gy - 44, 3, 23, "rust")
  for xx = px_ - 7, px_ + 7, 2 do K.px(xx, gy - 21, "gold"); K.px(xx + 1, gy - 20, "rust") end
  K.rect(px_ - 7, gy - 28, 15, 2, "deep"); K.rect(px_ + 3, gy - 30, 2, 6, "stone_dk")
  -- arms: one at the hip, one holding the rifle upright
  K.rect(px_ - 10, gy - 42, 3, 14, "ochre"); K.rect(px_ - 10, gy - 28, 3, 3, "skin")
  for yy = gy - 40, gy - 30, 3 do K.px(px_ - 11, yy, "gold") end
  K.rect(px_ + 8, gy - 42, 3, 12, "rust"); K.rect(px_ + 9, gy - 31, 3, 3, "skin")
  K.rect(px_ + 12, gy - 54, 2, 54, "wood"); K.rect(px_ + 12, gy - 54, 1, 30, "stone_ink"); K.rect(px_ + 11, gy - 6, 4, 6, "wood")
  -- head: weathered face, full beard, long hair, broad slouch hat
  K.rect(px_ - 4, gy - 54, 9, 10, "skin"); K.rect(px_ + 2, gy - 54, 3, 10, "skin_dk")
  K.rect(px_ - 4, gy - 48, 9, 5, "appearance_hair"); K.rect(px_ - 2, gy - 50, 5, 1, "skin")
  K.px(px_ - 2, gy - 52, "ink"); K.px(px_ + 2, gy - 52, "ink")
  K.rect(px_ - 6, gy - 54, 2, 9, "appearance_hair")
  K.rect(px_ - 9, gy - 56, 19, 2, "deep"); K.rect(px_ - 5, gy - 61, 11, 5, "deep"); K.rect(px_ - 5, gy - 58, 11, 1, "ink")
  -- powder horn on its strap
  K.line(px_ - 6, gy - 44, px_ + 6, gy - 28, "deep"); K.rect(px_ + 4, gy - 31, 5, 3, "cream")
end)

K.save("location_trader_camp")

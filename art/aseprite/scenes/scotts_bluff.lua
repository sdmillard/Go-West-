-- Scotts Bluff & Robidoux Pass Approach (432x150).
-- Historical reference: NPS Robidoux Pass & WESTERN_REFERENCES.md.
-- Massive stratified sandstone/siltstone bluff walls barring the North Platte river edge,
-- forcing 1848 wagons to detour south around the pass gap (no later 1850s Mitchell Pass cut).
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184810)

----------------------------------------------------------------- 1. Sky & Distant Ridge
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 12, "light_blue")
  K.blend(0, 71, W, "light_blue", "mist")
  K.rect(0, 74, W, 12, "mist")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  for x = 0, W - 1 do
    local hy = 68 + math.floor(4 * math.sin(tau * x / 432.0 + 0.5) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 96 do
      K.px(x, y, (y == hy) and "mist" or "far_hill")
    end
  end
end)

----------------------------------------------------------------- 2. Prairie Floor & Robidoux Pass Detour Trail
K.layer("prairie_and_trail", function()
  K.rect(0, 94, W, 14, "sage")
  K.dither(0, 104, W, 6, "sage", "grass")
  K.rect(0, 110, W, 40, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Robidoux Pass wagon road curving from lower-left up through the central saddle gap (x ~ 225, y ~ 102)
  K.poly({{112, 150}, {154, 118}, {222, 100}, {238, 102}, {182, 132}, {162, 150}}, "ochre")
  K.poly({{122, 150}, {160, 120}, {224, 101}, {234, 102}, {176, 132}, {152, 150}}, "gold")
  K.line(118, 149, 224, 101, "rust")
  K.line(156, 149, 236, 102, "rust")
  K.line(117, 149, 223, 101, "sand")

  for i = 1, 700 do
    local x = K.rnd(W)
    local y = 96 + K.rnd(54)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    elseif cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    end
  end
end)

----------------------------------------------------------------- 3. Scotts Bluff Escarpments & Wagon
K.layer("escarpments_and_wagon", function()
  local function massif(x0, x1, top_y, step_y, base_y, ridge_x)
    for y = top_y, base_y do
      local lx, rx
      if y <= step_y then
        local dy = y - top_y
        lx = x0 - math.floor(dy * 0.45) - ((y % 4 == 0) and 1 or 0)
        rx = x1 + math.floor(dy * 0.52) + ((y % 3 == 0) and 1 or 0)
      else
        local dy1 = step_y - top_y
        local dy2 = y - step_y
        lx = x0 - math.floor(dy1 * 0.45 + dy2 * 1.25 + 2 * math.sin(y * 0.35))
        rx = x1 + math.floor(dy1 * 0.52 + dy2 * 1.35 + 2 * math.cos(y * 0.31))
      end

      local ridge = ridge_x + math.floor((y - top_y) * 0.22)
      for x = lx, rx do
        local lit = (x <= ridge)
        local c
        if y <= top_y + 2 then
          c = lit and "cream" or "sand"
        elseif y <= step_y then
          local band = (y + ((x % 11 == 0) and 1 or 0)) % 6
          if band == 0 then
            c = lit and "cream" or "sand"
          elseif band == 3 then
            c = lit and "ochre" or "rust"
          else
            c = lit and "sand" or "ochre"
          end
          if (x - x0) % 13 == 0 and y > top_y + 4 then
            c = lit and "rust" or "wood"
          end
        else
          local ty = y - step_y
          local fan = math.floor((x - ridge_x) * 3 / math.max(6, ty + 5))
          if ty % 6 == 0 then
            c = lit and "sand" or "ochre"
          elseif fan % 3 == 0 then
            c = lit and "rust" or "wood"
          else
            c = lit and "ochre" or "rust"
          end
        end
        if y < base_y - 1 or ((x + y) % 2 == 0) then
          K.px(x, y, c)
        end
      end
    end
  end

  -- Left massif (Main Scotts Bluff escarpment + lower eastern shoulder)
  massif(46,  122, 42, 68, 104, 96)
  massif(118, 166, 62, 78, 105, 144)

  -- Right massif across the Robidoux Pass gap
  massif(268, 336, 46, 70, 104, 304)
  massif(332, 384, 64, 80, 105, 358)

  -- Sparse Rocky Mountain ponderosa pines dotting the bluff benches
  for _, px_x in ipairs({54, 134, 158, 276, 348, 374}) do
    local py = (px_x < 200) and 68 or 70
    if px_x > 125 and px_x < 200 then py = 84 end
    if px_x > 340 then py = 86 end
    K.conifer(px_x, py, 11, "ink", "pine", "leaf")
  end

  -- Arriving wagon & driver heading toward the Robidoux Pass detour
  K.wagon(24, 143, 1)
  K.person(82, 142, "blue", "wood", false)
end)

K.save("location_scotts_bluff")

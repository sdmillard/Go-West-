-- Horses and mules for the travel screen (384x308): seven rows of eight 48x44 frames, all
-- walking right. Hooves touch y = 39 in each frame. The rows are:
--   1 bay saddle horse, man riding        5 bay pack horse under a sawbuck pack
--   2 chestnut horse, woman riding        6 pack mule
--   3 dun horse, man and child doubled    7 mule, man riding
--   4 gray horse, haltered and led bare
-- The walk is the four-beat gait (near hind, near fore, far hind, far fore, a quarter cycle
-- apart), the body dips as each hind foot takes the weight and the head nods with the stride.
local K = dofile(app.params.kit)
local FW, FH, FRAMES = 48, 44, 8
local ROWS = 7
K.canvas(FW * FRAMES, FH * ROWS, 1848)

local GROUND = 36

-- coats: o outline, d shade, m body, l lit, h highlight, p points (mane, tail, lower legs)
local COATS = {
  bay      = {d="ox_dk", m="ox", l="rust", h="ochre", p="ink", hoof="deep", muzzle="deep"},
  chestnut = {d="ox", m="rust", l="ochre", h="gold", p="brick_dk", hoof="deep", muzzle="ox_dk", blaze=true},
  dun      = {d="ochre", m="gold", l="sand", h="cream", p="deep", hoof="ink", muzzle="ox_dk", stripe=true},
  gray     = {d="stone_dk", m="stone", l="stone_lt", h="white", p="stone_ink", hoof="deep", muzzle="stone_ink"},
  mule     = {d="deep", m="ox_dk", l="ox", h="ox_lt", p="ink", hoof="ink", muzzle="sand", mule=true},
}

---------------------------------------------------------------- body mask
-- A mask of the trunk, neck and head is filled from simple shapes, then painted with a
-- one-pixel outline and light from the upper left.
local function new_mask() return {} end
local function set(m, x, y) m[y] = m[y] or {}; m[y][x] = true end
local function has(m, x, y) return m[y] ~= nil and m[y][x] == true end
local function m_ellipse(m, cx, cy, rx, ry)
  for y = math.floor(cy - ry), math.ceil(cy + ry) do
    for x = math.floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (x - cx) / (rx + 0.5), (y - cy) / (ry + 0.5)
      if dx * dx + dy * dy <= 1 then set(m, x, y) end
    end
  end
end
local function m_poly(m, pts)
  local miny, maxy = math.huge, -math.huge
  for _, p in ipairs(pts) do miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2]) end
  for y = math.floor(miny), math.ceil(maxy) do
    local xs = {}
    for i = 1, #pts do
      local a, b = pts[i], pts[i % #pts + 1]
      if (a[2] <= y + 0.5 and b[2] > y + 0.5) or (b[2] <= y + 0.5 and a[2] > y + 0.5) then
        xs[#xs + 1] = a[1] + (y + 0.5 - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
      end
    end
    table.sort(xs)
    for i = 1, #xs - 1, 2 do
      for x = math.ceil(xs[i] - 0.5), math.floor(xs[i + 1] - 0.5) do set(m, x, y) end
    end
  end
end

-- paint a mask: outline where a neighbour is empty, lit band along the top edge,
-- shade along the bottom, and a soft highlight on the left of the top line
local function paint(m, ox, oy, c)
  for y, row in pairs(m) do
    for x in pairs(row) do
      local edge = not (has(m, x - 1, y) and has(m, x + 1, y) and has(m, x, y - 1) and has(m, x, y + 1))
      local name
      if edge then name = "ink"
      elseif not has(m, x, y - 2) then name = c.h
      elseif not has(m, x, y - 3) then name = c.l
      elseif not has(m, x, y + 2) or not has(m, x, y + 3) then name = c.d
      else name = c.m end
      K.px(ox + x, oy + y, name)
    end
  end
end

---------------------------------------------------------------- legs
-- One leg's pose at phase t: three quarters of the cycle on the ground with the hoof sliding
-- back, then a quick swing forward with the joint folded (the same model as the oxen).
local function pose(t)
  t = t % 1
  if t < 0.75 then
    return math.floor(4 - 8 * (t / 0.75) + 0.5), 0
  end
  local u = (t - 0.75) / 0.25
  return math.floor(-4 + 8 * u + 0.5), math.floor(3 * math.sin(u * math.pi) + 0.5)
end

-- a two-pixel leg, coat colour above the joint and the points colour below it
local function leg(fx, top_x, top_y, hoof_dx, lift, hind, far, c, bob)
  local mid = far and c.d or c.m
  local low = far and "ink" or c.p
  if c.mule then low = far and "ink" or c.d end
  local hoof_x = top_x + hoof_dx
  local hoof_y = (top_y - 25) + GROUND - lift  -- top_y carries the row's offset
  -- the hock juts back on a hind leg; a lifted foreleg folds at the knee
  local jx = hind and (top_x - 1 + math.floor(hoof_dx / 3)) or (top_x + math.floor(hoof_dx / 2) + (lift > 0 and 1 or 0))
  local jy = top_y + 5 - (lift > 1 and 1 or 0)
  K.line(fx + top_x, top_y + bob, fx + jx, jy, "ink")
  K.line(fx + top_x + 1, top_y + bob, fx + jx + 1, jy, mid)
  K.line(fx + top_x + 2, top_y + bob, fx + jx + 2, jy, "ink")
  K.line(fx + jx, jy, fx + hoof_x, hoof_y - 2, "ink")
  K.line(fx + jx + 1, jy, fx + hoof_x + 1, hoof_y - 2, low)
  K.line(fx + jx + 2, jy, fx + hoof_x + 2, hoof_y - 2, "ink")
  -- pastern and hoof
  K.rect(fx + hoof_x, hoof_y - 1, 3, 2, c.hoof)
  K.px(fx + hoof_x, hoof_y, "ink"); K.px(fx + hoof_x + 3, hoof_y, "ink")
  if not far then K.px(fx + hoof_x + 1, hoof_y - 1, low == "ink" and "deep" or low) end
end

---------------------------------------------------------------- one animal
local function animal(fx, fy, frame, coat)
  local c = COATS[coat]
  local cyc = (frame - 1) / FRAMES
  local bob = (math.cos(cyc * 4 * math.pi) < -0.3) and 1 or 0
  -- the head nods down as each forefoot lands
  local nod = (math.cos(cyc * 4 * math.pi + 1.2) > 0.4) and 1 or 0
  local by = fy + bob

  -- ground shadow
  for y = -1, 1 do for x = -17, 17 do
    if (x * x) / (17.5 * 17.5) + (y * y) / 2.2 <= 1 then K.px(fx + 23 + x, fy + GROUND + 1 + y, "ground_shadow") end
  end end

  local hn_d, hn_l = pose(cyc)
  local fn_d, fn_l = pose(cyc + 0.75)
  local hf_d, hf_l = pose(cyc + 0.5)
  local ff_d, ff_l = pose(cyc + 0.25)

  -- far legs first, a pixel behind the near ones
  leg(fx, 13, fy + 25, hf_d, hf_l, true, true, c, bob)
  leg(fx, 29, fy + 25, ff_d, ff_l, false, true, c, bob)

  -- tail: a horse's long switch, or a mule's thin tail with a tuft
  local sway = math.floor(1.3 * math.sin(cyc * 2 * math.pi) + 0.5)
  if c.mule then
    K.line(fx + 6, by + 18, fx + 5 + sway, by + 26, c.d)
    K.line(fx + 5, by + 18, fx + 4 + sway, by + 26, "ink")
    K.rect(fx + 3 + sway, by + 26, 3, 4, "ink")
    K.px(fx + 4 + sway, by + 27, "deep")
  else
    K.poly({{fx + 6, by + 17}, {fx + 8, by + 17}, {fx + 6 + sway, by + 27}, {fx + 5 + sway, by + 31}, {fx + 3 + sway, by + 30}, {fx + 4, by + 22}}, c.p)
    K.line(fx + 6, by + 18, fx + 5 + sway, by + 29, c.p == "ink" and "deep" or "ink")
    K.px(fx + 7, by + 17, "ink")
  end

  -- trunk, neck and head
  local m = new_mask()
  m_ellipse(m, 21, 21, 11, 4)       -- barrel
  m_ellipse(m, 11, 20.5, 5, 4.5)    -- haunch and croup
  m_ellipse(m, 30, 20.5, 4.5, 4.5)  -- shoulder and chest
  m_poly(m, {{8, 24}, {12, 26}, {16, 25}})   -- stifle
  m_poly(m, {{27, 25}, {33, 26}, {34, 22}})  -- forearm root
  local n = nod
  if c.mule then
    -- straighter, thinner neck, a long heavy head
    m_poly(m, {{27, 17}, {31, 14}, {35, 11 + n}, {38, 10 + n}, {38, 14 + n}, {35, 18 + n}, {33, 22}})
    m_poly(m, {{35, 10 + n}, {38, 9 + n}, {44, 15 + n}, {45, 18 + n}, {42, 19 + n}, {39, 17 + n}, {36, 13 + n}})
  else
    -- arched crest from the withers up to the poll
    m_poly(m, {{26, 17}, {28, 14}, {32, 11 + n}, {36, 9 + n}, {38, 10 + n}, {38, 14 + n}, {35, 18 + n}, {34, 22}})
    m_poly(m, {{35, 9 + n}, {38, 8 + n}, {43, 13 + n}, {45, 16 + n}, {43, 17 + n}, {40, 16 + n}, {36, 13 + n}})
  end
  paint(m, fx, by, c)

  -- mane along the crest, forelock, ears and face
  if c.mule then
    for i = 0, 7 do K.px(fx + 28 + i, by + 14 - math.floor(i * 0.5) + (i > 4 and n or 0), "ink") end
    -- long ears standing up together: the far one dark behind, the near one with a lit inside
    K.rect(fx + 35, by + 3 + n, 2, 6, "ink"); K.px(fx + 35, by + 2 + n, "ink")
    K.rect(fx + 37, by + 2 + n, 3, 7, "ink"); K.px(fx + 38, by + 1 + n, "ink")
    K.rect(fx + 38, by + 3 + n, 1, 5, c.m); K.px(fx + 38, by + 4 + n, c.h)
  else
    for i = 0, 9 do
      local x = 27 + i
      local y = math.floor(15.5 - i * 0.65) + (i > 4 and n or 0)
      K.px(fx + x, by + y, c.p); K.px(fx + x, by + y + 1, i % 3 == 0 and c.p or c.d)
    end
    K.px(fx + 38, by + 9 + n, c.p); K.px(fx + 39, by + 10 + n, c.p)   -- forelock
    K.px(fx + 36, by + 6 + n, "ink"); K.px(fx + 37, by + 7 + n, "ink"); K.px(fx + 36, by + 7 + n, c.d) -- ear
  end
  if c.stripe then for x = 9, 24 do K.px(fx + x, by + 17 - (x > 20 and 1 or 0), c.p) end end
  if c.blaze then K.line(fx + 40, by + 11 + n, fx + 44, by + 15 + n, "white") end
  -- eye, nostril and muzzle
  K.px(fx + 40, by + 11 + n, "ink")
  K.rect(fx + 43, by + 15 + n, 2, 2, c.muzzle)
  if c.mule then K.rect(fx + 42, by + 16 + n, 3, 2, c.muzzle) end
  K.px(fx + 44, by + 15 + n, "ink")

  -- near legs over the trunk
  leg(fx, 11, fy + 25, hn_d, hn_l, true, false, c, bob)
  leg(fx, 31, fy + 25, fn_d, fn_l, false, false, c, bob)

  return {bob = bob, nod = nod, by = by}
end

---------------------------------------------------------------- tack and riders
local function halter(fx, by, n, lead)
  K.line(fx + 39, by + 10 + n, fx + 41, by + 15 + n, "wood")
  K.line(fx + 41, by + 15 + n, fx + 44, by + 14 + n, "wood")
  if lead then
    -- slack lead rope hanging forward off the frame toward the horse ahead
    K.line(fx + 42, by + 16 + n, fx + 45, by + 20, "sand"); K.line(fx + 46, by + 20, fx + 47, by + 18, "sand")
  end
end

local function bridle(fx, by, n, hand_x, hand_y)
  K.line(fx + 38, by + 9 + n, fx + 40, by + 15 + n, "ink")
  K.px(fx + 42, by + 16 + n, "stone")                      -- bit ring
  K.line(fx + 42, by + 15 + n, fx + hand_x, by + hand_y, "deep") -- reins
end

-- saddle with a blanket edge, girth and stirrup leather
local function saddle(fx, by, blanket)
  K.rect(fx + 16, by + 16, 11, 4, blanket)
  K.rect(fx + 16, by + 19, 11, 1, "ink")
  K.px(fx + 16, by + 16, "cream")
  K.rect(fx + 17, by + 14, 9, 3, "wood")
  K.rect(fx + 17, by + 14, 9, 1, "rust")
  K.rect(fx + 15, by + 13, 2, 2, "deep")   -- cantle
  K.rect(fx + 25, by + 12, 2, 3, "deep")   -- pommel and horn
  K.px(fx + 26, by + 11, "wood")
  K.line(fx + 22, by + 20, fx + 22, by + 25, "deep")  -- girth
end

-- saddlebags behind the cantle
local function bags(fx, by)
  K.rect(fx + 11, by + 15, 5, 6, "ox_dk"); K.rect(fx + 11, by + 15, 5, 1, "wood")
  K.rect(fx + 11, by + 20, 5, 1, "ink"); K.px(fx + 13, by + 17, "gold")
  K.rect(fx + 12, by + 13, 4, 2, "cream"); K.px(fx + 12, by + 13, "white")  -- blanket roll
end

-- seated rider; sx is the seat x, by the bobbed body origin, rb the rider's own lag
local function rider(fx, by, frame, kind, sx)
  local t = (frame - 1) / FRAMES * 4 * math.pi
  local rb = (math.cos(t + 0.6) < -0.3) and 1 or 0  -- the rider lags the horse a little
  local y = by + rb
  local coat = kind == "woman" and "red" or (kind == "child" and "sage" or "blue")
  local lit = kind == "woman" and "brick_lt" or (kind == "child" and "cream" or "light_blue")
  local small = kind == "child"
  local top = small and 6 or 2
  if kind == "woman" then
    -- riding astride with the skirt falling over the near side
    K.poly({{fx + sx - 1, y + 12}, {fx + sx + 4, y + 12}, {fx + sx + 5, y + 21}, {fx + sx, y + 21}}, "red")
    K.line(fx + sx - 1, y + 13, fx + sx, y + 20, "brick_lt")
    K.rect(fx + sx, y + 21, 6, 1, "brick_dk")
    K.rect(fx + sx + 4, y + 22, 2, 1, "ink")
  elseif small then
    K.line(fx + sx + 1, y + 13, fx + sx + 2, y + 18, "wood")
    K.px(fx + sx + 2, y + 19, "ink")
  else
    -- thigh forward to the knee, shin down to the stirrup, boot
    K.line(fx + sx, y + 13, fx + sx + 4, y + 16, "wood"); K.line(fx + sx, y + 14, fx + sx + 4, y + 17, "deep")
    K.line(fx + sx + 4, y + 17, fx + sx + 3, y + 23, "wood"); K.line(fx + sx + 5, y + 17, fx + sx + 4, y + 23, "deep")
    K.rect(fx + sx + 3, y + 24, 4, 1, "ink"); K.px(fx + sx + 3, y + 23, "ink")
    K.px(fx + sx + 2, y + 25, "stone")  -- stirrup
  end
  -- torso, leaning slightly into the walk
  local tw = small and 3 or 5
  local th = small and 6 or 9
  K.rect(fx + sx - 1, y + top + 4, tw, th, coat)
  K.rect(fx + sx - 1, y + top + 4, 1, th, lit)
  K.rect(fx + sx - 1 + tw, y + top + 5, 1, th - 1, "ink")
  if not small and kind ~= "woman" then K.rect(fx + sx - 1, y + top + 11, tw, 1, "wood") end
  -- head and hat
  local hx = fx + sx
  K.rect(hx, y + top, 3, 4, "skin"); K.px(hx + 2, y + top + 2, "skin_dk"); K.px(hx + 3, y + top + 1, "skin")
  K.px(hx, y + top, "appearance_hair")
  if kind == "woman" then
    K.rect(hx - 2, y + top - 2, 5, 3, "cream"); K.rect(hx - 2, y + top + 1, 2, 3, "cream"); K.px(hx + 3, y + top - 1, "sand")
  elseif small then
    K.rect(hx - 1, y + top - 1, 4, 1, "appearance_hair")
  else
    K.rect(hx - 2, y + top - 1, 7, 1, "deep"); K.rect(hx - 1, y + top - 3, 4, 2, "deep"); K.px(hx - 1, y + top - 3, "wood")
  end
  -- near arm forward to the reins
  local hand_x, hand_y = sx + 5, (small and 12 or 12) + rb
  K.line(fx + sx, y + top + 5, fx + hand_x, by + hand_y, kind == "woman" and "red" or coat)
  K.line(fx + sx + 1, y + top + 5, fx + hand_x + 1, by + hand_y, kind == "woman" and "brick_dk" or "ink")
  K.px(fx + hand_x + 1, by + hand_y + 1, "skin")
  return hand_x + 1, hand_y + 1
end

-- sawbuck pack saddle with two side packs lashed under a diamond hitch and a top bundle
local function pack(fx, by, mule)
  local x0 = mule and 14 or 13
  K.rect(fx + x0 + 1, by + 16, 15, 4, "teal")  -- saddle pad
  -- near-side pannier, canvas over a box
  -- (about 175 lb a side load, so the packs sit low and modest on the back)
  K.rect(fx + x0, by + 14, 14, 8, "sand")
  K.rect(fx + x0, by + 14, 14, 1, "cream")
  K.rect(fx + x0, by + 14, 1, 8, "cream")
  K.rect(fx + x0 + 13, by + 15, 1, 7, "silt")
  K.rect(fx + x0, by + 21, 14, 1, "silt_dk")
  K.rect(fx + x0 - 1, by + 14, 1, 8, "ink"); K.rect(fx + x0 + 14, by + 14, 1, 8, "ink")
  K.rect(fx + x0, by + 22, 14, 1, "ink")
  -- top bundle: a rolled tent and a kettle
  K.rect(fx + x0 + 2, by + 11, 10, 3, "ox_white"); K.rect(fx + x0 + 2, by + 11, 10, 1, "white")
  K.rect(fx + x0 + 1, by + 11, 1, 3, "ink"); K.rect(fx + x0 + 12, by + 11, 1, 3, "ink"); K.rect(fx + x0 + 2, by + 10, 10, 1, "ink")
  K.rect(fx + x0 + 9, by + 8, 3, 2, "ink"); K.px(fx + x0 + 10, by + 8, "storm")
  -- sawbuck crosstrees
  K.line(fx + x0 + 5, by + 8, fx + x0 + 7, by + 11, "wood"); K.line(fx + x0 + 7, by + 8, fx + x0 + 5, by + 11, "wood")
  -- diamond hitch
  K.line(fx + x0, by + 18, fx + x0 + 7, by + 14, "wood"); K.line(fx + x0 + 7, by + 14, fx + x0 + 13, by + 18, "wood")
  K.line(fx + x0, by + 18, fx + x0 + 7, by + 21, "wood"); K.line(fx + x0 + 7, by + 21, fx + x0 + 13, by + 18, "wood")
  -- cinch, breeching round the rump and breast collar
  K.line(fx + x0 + 9, by + 24, fx + x0 + 9, by + 25, "deep")
  K.line(fx + x0 - 1, by + 18, fx + 7, by + 21, "deep")
  K.line(fx + x0 + 15, by + 18, fx + 34, by + 21, "deep")
end

---------------------------------------------------------------- rows
local function row(r, coat, dress)
  local fy = (r - 1) * FH + 3 -- headroom for the riders' hats
  for f = 1, FRAMES do
    local fx = (f - 1) * FW
    local a = animal(fx, fy, f, coat)
    local by, n = a.by, a.nod
    if dress == "man" or dress == "woman" or dress == "double" or dress == "mule_rider" then
      saddle(fx, by, dress == "woman" and "blue" or "red")
      if dress == "man" or dress == "mule_rider" then bags(fx, by) end
      if dress == "double" then rider(fx, by, f, "child", 15) end
      local hx, hy = rider(fx, by, f, dress == "woman" and "woman" or "man", 21)
      bridle(fx, by, n, hx, hy)
    elseif dress == "pack" or dress == "mule_pack" then
      pack(fx, by, dress == "mule_pack")
      halter(fx, by, n, true)
    else
      halter(fx, by, n, true)
    end
  end
end

K.layer("horses", function()
  row(1, "bay", "man")
  row(2, "chestnut", "woman")
  row(3, "dun", "double")
  row(4, "gray", "bare")
  row(5, "bay", "pack")
  row(6, "mule", "mule_pack")
  row(7, "mule", "mule_rider")
end)

K.save("horses")

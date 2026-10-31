-- Original 1848 isometric tactical combat assets.
-- Project palette, 2:1 isometric projection, integer grid, binary alpha.
-- Outputs:
--   tactical_tiles  (192x32: six 32x32 diamond ground/highlight cells)
--   tactical_cover  (192x64: two rows of six 32x32 half-cover and full-cover props)
--   tactical_units  (192x96: three rows of six 32x32 isometric rifleman poses & smoke)
local K = dofile(app.params.kit)

-- Helper: fill an isometric 32x16 diamond centered at (cx, cy)
local function iso_diamond(cx, cy, c_fill, c_lit, c_shade)
  for dy = -7, 7 do
    local span = (7 - math.abs(dy)) * 2
    local y = cy + dy
    K.line(cx - span, y, cx + span - 1, y, c_fill)
    if c_lit and dy <= 0 then
      K.px(cx - span, y, c_lit)
      K.px(cx - span + 1, y, c_lit)
    end
    if c_shade and dy >= 0 then
      K.px(cx + span - 1, y, c_shade)
      K.px(cx + span - 2, y, c_shade)
    end
  end
end

local function iso_outline(cx, cy, c)
  K.line(cx, cy - 7, cx - 14, cy, c)
  K.line(cx - 14, cy, cx, cy + 7, c)
  K.line(cx, cy + 7, cx + 14, cy, c)
  K.line(cx + 14, cy, cx, cy - 7, c)
end

-- ============================================================================
-- 1. TACTICAL TILES (192x32, six 32x32 cells)
-- ============================================================================
K.canvas(192, 32, 184880)
K.layer("isometric ground diamonds", function()
  -- Cell 0: Dry prairie dirt
  iso_diamond(16, 16, "silt", "sand", "dirt_dk")
  iso_outline(16, 16, "silt_dk")
  for _, p in ipairs({{-6,-2,"dirt_dk"},{4,-3,"sand"},{-3,2,"silt_dk"},{5,1,"dirt_dk"},{0,-4,"sand"},{-2,4,"dirt_dk"}}) do
    K.px(16 + p[1], 16 + p[2], p[3])
  end

  -- Cell 1: Packed post yard / wheel-rutted earth
  iso_diamond(48, 16, "silt_dk", "silt", "dirt_dk")
  iso_outline(48, 16, "dirt_dk")
  K.line(40, 14, 54, 20, "dirt_dk")
  K.line(42, 12, 56, 18, "dirt_dk")
  K.px(45, 16, "deep"); K.px(51, 15, "silt")

  -- Cell 2: Store / Ferry timber planks
  iso_diamond(80, 16, "wood", "rust", "deep")
  iso_outline(80, 16, "deep")
  K.line(74, 13, 86, 19, "deep")
  K.line(78, 11, 88, 16, "deep")
  K.line(71, 15, 82, 20, "deep")
  K.px(77, 15, "ink"); K.px(83, 17, "ink")

  -- Cell 3: Prairie grass & sage verge
  iso_diamond(112, 16, "grass", "sage", "pine")
  iso_outline(112, 16, "pine")
  for _, g in ipairs({{-5,0},{2,-2},{-2,3},{6,1}}) do
    local gx, gy = 112 + g[1], 16 + g[2]
    K.px(gx, gy, "pine"); K.px(gx, gy - 1, "leaf"); K.px(gx + 1, gy, "pine")
  end

  -- Cell 4: Retreat / Exit zone tile
  iso_diamond(144, 16, "ochre", "gold", "rust")
  iso_outline(144, 16, "gold")
  K.line(140, 16, 144, 14, "brick_dk")
  K.line(144, 14, 148, 16, "brick_dk")
  K.line(140, 18, 144, 16, "red")
  K.line(144, 16, 148, 18, "red")

  -- Cell 5: Cursor / Move / LOS highlight diamond
  iso_outline(176, 16, "white")
  K.line(176, 10, 164, 16, "gold")
  K.line(164, 16, 176, 22, "gold")
  K.line(176, 22, 188, 16, "gold")
  K.line(188, 16, 176, 10, "gold")
end)
K.save("tactical_tiles")

-- ============================================================================
-- 2. TACTICAL COVER (192x64, 6 cols x 2 rows of 32x32 cells)
--Modelled in 3D ground coordinates (s = NE, c = SE, h = up) and rendered through
-- the same 2:1 isometric depth buffer as crossing_sprites.lua.
-- Row 0: Half cover (counter, barrels, crate, boulder, log breastwork, chest+wheel)
-- Row 1: Full cover (adobe/log wall, stacked crates+barrel, covered wagon, tent, water tun, tree)
-- ============================================================================
K.canvas(192, 64, 184881)

local AX, AY = 0.894, 0.447
local Z, OX, OY
local function begin3d(ox, oy)
  Z, OX, OY = {}, ox, oy
end

local function pt(s, c, h, col)
  local x = math.floor(OX + (s + c) * AX + 0.5)
  local y = math.floor(OY + (c - s) * AY - h + 0.5)
  local d = (c - s) * AY + h
  local key = (y + 1000) * 4096 + (x + 1000)
  local e = Z[key]
  if not e or d >= e[1] then
    Z[key] = {d, col, x, y}
  end
end

local function flush3d(fx, fy, w, h)
  for _, e in pairs(Z) do
    if e[3] >= 0 and e[3] < w and e[4] >= 0 and e[4] < h then
      K.px(fx + e[3], fy + e[4], e[2])
    end
  end
end

local function seg(s0, c0, h0, s1, c1, h1, col)
  local n = math.max(2, math.floor(math.max(math.abs(s1 - s0), math.abs(c1 - c0), math.abs(h1 - h0)) * 3))
  for i = 0, n do
    local u = i / n
    pt(s0 + (s1 - s0) * u, c0 + (c1 - c0) * u, h0 + (h1 - h0) * u, col)
  end
end

local function ground_shadow(s0, s1, c0, c1)
  local ms, rs = (s0 + s1) / 2, math.max(1, (s1 - s0) / 2)
  local mc, rc = (c0 + c1) / 2, math.max(1, (c1 - c0) / 2)
  for s = s0, s1, 0.3 do
    for c = c0, c1, 0.3 do
      if ((s - ms) / rs) ^ 2 + ((c - mc) / rc) ^ 2 <= 1 then
        pt(s, c, 0, "ink")
      end
    end
  end
end

-- 3D ellipsoid shaded by surface normal (same lighting as crossing_sprites.lua)
local function blob(s0, c0, h0, rs, rc, rh, lit, mid, dark)
  for i = 0, 36 do
    local th = i / 36 * math.pi
    for j = 0, 54 do
      local ph = j / 54 * 2 * math.pi
      local ns, nc, nh = math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th)
      if h0 + rh * nh >= 0 then
        local light = nh * 0.8 - nc * 0.5 + ns * 0.1
        local col = (light > 0.42) and lit or ((light < -0.15) and dark or mid)
        pt(s0 + rs * ns, c0 + rc * nc, h0 + rh * nh, col)
      end
    end
  end
end

-- 3D axis-aligned box in (s, c, h) with top, SE-right (c1), SW-front (s0), and edge trim
local function box3d(s0, s1, c0, c1, h0, h1, top_col, sw_col, se_col, edge_col)
  for s = s0, s1, 0.3 do
    for c = c0, c1, 0.3 do
      pt(s, c, h1, top_col)
    end
  end
  for s = s0, s1, 0.3 do
    for h = h0, h1, 0.3 do
      pt(s, c0, h, sw_col)
      pt(s, c1, h, se_col)
    end
  end
  for c = c0, c1, 0.3 do
    for h = h0, h1, 0.3 do
      pt(s0, c, h, sw_col)
      pt(s1, c, h, se_col)
    end
  end
  if edge_col then
    seg(s0, c0, h1, s1, c0, h1, edge_col)
    seg(s0, c0, h1, s0, c1, h1, edge_col)
    seg(s0, c1, h1, s1, c1, h1, "deep")
    seg(s1, c0, h1, s1, c1, h1, "deep")
    seg(s0, c1, h0, s0, c1, h1, edge_col)
  end
end

-- Vertical 3D cylinder in (s, c, h) with iron hoops
local function cyl_v(s0, c0, r, h0, h1, top_col, lit, mid, dark, hoops)
  for h = h0, h1, 0.3 do
    local is_hoop = false
    if hoops then
      for _, hh in ipairs(hoops) do
        if math.abs(h - hh) < 0.45 then is_hoop = true end
      end
    end
    for k = 0, 64 do
      local a = k / 64 * 2 * math.pi
      local ns, nc = math.cos(a), math.sin(a)
      local light = -nc * 0.55 - ns * 0.35
      local col = is_hoop and "ink" or ((light > 0.2) and lit or ((light < -0.2) and dark or mid))
      pt(s0 + r * ns, c0 + r * nc, h, col)
    end
  end
  for rr = 0, r, 0.3 do
    for k = 0, 56 do
      local a = k / 56 * 2 * math.pi
      local col = (rr > r - 0.5) and "ink" or top_col
      pt(s0 + rr * math.cos(a), c0 + rr * math.sin(a), h1, col)
    end
  end
end

-- Horizontal 3D cylinder running along the s-axis (for logs and horizontal barrels)
local function cyl_s(s0, s1, c0, h0, r, end_col, lit, mid, dark, hoops)
  for s = s0, s1, 0.3 do
    local is_hoop = false
    if hoops then
      for _, sh in ipairs(hoops) do
        if math.abs(s - sh) < 0.45 then is_hoop = true end
      end
    end
    for k = 0, 56 do
      local a = k / 56 * 2 * math.pi
      local nc, nh = math.cos(a), math.sin(a)
      local light = nh * 0.75 - nc * 0.45
      local col = is_hoop and "ink" or ((light > 0.25) and lit or ((light < -0.2) and dark or mid))
      if h0 + r * nh >= 0 then
        pt(s, c0 + r * nc, h0 + r * nh, col)
      end
    end
  end
  for rr = 0, r, 0.3 do
    for k = 0, 48 do
      local a = k / 48 * 2 * math.pi
      local col = (rr > r - 0.5) and "wood" or end_col
      pt(s0, c0 + rr * math.cos(a), h0 + rr * math.sin(a), col)
      pt(s1, c0 + rr * math.cos(a), h0 + rr * math.sin(a), "deep")
    end
  end
end

-- Exact 3D wheel from crossing_sprites.lua
local function wheel(s0, c0, r, rot, far)
  for rr = 0, r, 0.25 do
    for k = 0, 90 do
      local a = k / 90 * 2 * math.pi
      local col
      if rr > r - 0.9 then col = far and "ink" or "deep"
      elseif rr > r - 1.5 then col = far and "deep" or "ochre"
      elseif rr < 0.9 then col = "ink"
      else
        local spoke = (a + rot) % (math.pi / 3)
        if spoke < 0.22 or spoke > math.pi / 3 - 0.22 then col = far and "deep" or "wood" end
      end
      if col then pt(s0 + rr * math.cos(a), c0, r + rr * math.sin(a), col) end
    end
  end
end

-- Exact 3D prairie schooner wagon from crossing_sprites.lua (scaled to fit the 32x32 cover cell)
local function crossing_wagon(rot)
  local L, WD = 17, 5.2
  for _, side in ipairs({-1, 1}) do
    local c = side * (WD + 0.5)
    wheel(3.5, c, 4.2, rot, side < 0)
    wheel(13.5, c, 3.5, rot * 1.25, side < 0)
  end
  seg(2, 0, 3.5, 15, 0, 3.5, "deep")
  -- Blue wagon bed with pale top rail and dark stripe (same as crossing_sprites.lua)
  box3d(0, L, -WD, WD, 4, 8.5, "deep", "teal", "blue", nil)
  for s = 0, L, 0.3 do
    pt(s, WD, 8.5, "light_blue")
    pt(s, WD, 6, "teal")
    pt(s, WD, 4, "ink")
  end
  -- Canvas half-cylinder bonnet on hickory bows
  for s = 0.8, L - 0.8, 0.25 do
    for k = 0, 60 do
      local th = k / 60 * math.pi
      local cs = math.cos(th)
      local col = (cs > 0.55) and "clap_sh" or ((cs > 0.05) and "cream" or "white")
      for _, b in ipairs({4.5, 8.5, 12.5}) do
        if math.abs(s - b) < 0.3 and cs > -0.2 then col = "sand" end
      end
      pt(s, WD * cs, 8.5 + 6.8 * math.sin(th), col)
    end
  end
  -- Rear pucker opening
  for c = -WD, WD, 0.25 do
    for h = 8.5, 15.3, 0.25 do
      if (c / WD) ^ 2 + ((h - 8.5) / 6.8) ^ 2 <= 1 then
        local open = (c / 2.1) ^ 2 + ((h - 11.5) / 2.6) ^ 2
        pt(0.8, c, h, (open <= 1) and "deep" or ((open <= 1.6) and "sand" or "cream"))
      end
    end
  end
end

K.layer("half cover props", function()
  -- Col 0: Store counter / timber barricade (waist-high, 1 tile long)
  begin3d(16, 22)
  box3d(-5.5, 5.5, -2.8, 2.8, 0, 5.2, "sand", "gold", "rust", "cream")
  box3d(-6.0, 6.0, -3.2, 3.2, 5.2, 6.4, "cream", "gold", "ochre", "white")
  flush3d(0, 0, 32, 32)

  -- Col 1: Supply barrels (waist-high standing barrel + small horizontal cask)
  begin3d(16, 22)
  cyl_s(-0.5, 4.5, 1.8, 2.3, 2.3, "sand", "gold", "ochre", "rust", {1.0, 3.2})
  cyl_v(-2.0, -1.2, 2.9, 0, 6.8, "sand", "gold", "ochre", "rust", {2.0, 5.0})
  flush3d(32, 0, 32, 32)

  -- Col 2: Nailed cargo crate (proportional waist-high 1x1 crate)
  begin3d(16, 22)
  box3d(-4.0, 4.0, -4.0, 4.0, 0, 6.5, "cream", "gold", "rust", "sand")
  seg(-3.5, 4.1, 0.8, 3.5, 4.1, 5.8, "deep")
  seg(-4.1, -3.5, 0.8, -4.1, 3.5, 5.8, "ochre")
  flush3d(64, 0, 32, 32)

  -- Col 3: Prairie basalt boulder (waist-high 3D rock outcrop, no flat shadow plate)
  begin3d(16, 22)
  blob(0, 0, 1.5, 4.8, 4.0, 3.8, "stone_lt", "storm", "storm_dk")
  blob(-1.8, 1.2, 1.2, 3.4, 3.0, 2.8, "white", "stone_lt", "storm")
  flush3d(96, 0, 32, 32)

  -- Col 4: Stacked 3D round logs on the isometric angle (low breastwork)
  begin3d(16, 22)
  cyl_s(-5.5, 5.5, -1.6, 1.9, 1.9, "cream", "gold", "ochre", "wood", nil)
  cyl_s(-5.5, 5.5, 1.6, 1.9, 1.9, "sand", "ochre", "rust", "deep", nil)
  cyl_s(-5.0, 5.0, 0, 4.5, 1.8, "cream", "gold", "ochre", "rust", nil)
  flush3d(128, 0, 32, 32)

  -- Col 5: Small strongbox & spare wagon wheel leaning on SE flank
  begin3d(16, 22)
  box3d(-4.2, 3.2, -3.6, 1.8, 0, 5.2, "cream", "gold", "rust", "sand")
  wheel(0.4, 2.8, 3.8, 0.2, false)
  flush3d(160, 0, 32, 32)
end)

K.layer("full cover walls and obstacles", function()
  -- Col 0: Adobe / log wall segment (proportional wall thickness, head-high)
  begin3d(16, 22)
  box3d(-5.8, 5.8, -3.4, 3.4, 0, 11.5, "cream", "silt_lt", "dirt_dk", "white")
  for h = 3.0, 9.5, 3.0 do
    seg(-5.8, 3.5, h, 5.8, 3.5, h, "deep")
    seg(-5.9, -3.4, h, -5.9, 3.4, h, "silt")
  end
  flush3d(0, 32, 32, 32)

  -- Col 1: Stacked freight crate + upright barrel on top
  begin3d(16, 22)
  box3d(-4.6, 4.6, -4.6, 4.6, 0, 6.2, "sand", "ochre", "deep", "cream")
  cyl_v(0, 0, 3.0, 6.2, 12.0, "cream", "gold", "ochre", "rust", {8.0, 10.5})
  flush3d(32, 32, 32, 32)

  -- Col 2: The River Crossing Prairie Schooner Wagon (from crossing_sprites.lua)
  begin3d(8, 25)
  crossing_wagon(0)
  flush3d(64, 32, 32, 32)

  -- Col 3: Army / Emigrant canvas wedge tent
  begin3d(16, 22)
  for s = -5.2, 5.2, 0.25 do
    for h = 0, 11.5, 0.25 do
      local span = 4.6 * (1 - h / 11.5)
      pt(s, -span, h, (h > 10.8) and "white" or "cream")
      pt(s, span, h, "sand")
    end
  end
  for c = -4.6, 4.6, 0.25 do
    local max_h = 11.5 * (1 - math.abs(c) / 4.6)
    for h = 0, max_h, 0.25 do
      local is_door = (math.abs(c) < 1.5 and h < 6.2)
      pt(-5.2, c, h, is_door and "deep" or ((c < 0) and "cream" or "silt"))
    end
  end
  flush3d(96, 32, 32, 32)

  -- Col 4: Heavy timber mooring piling / stockade post (slender column)
  begin3d(16, 22)
  cyl_v(0, 0, 3.4, 0, 12.5, "cream", "gold", "ochre", "deep", {3.0, 7.5, 10.8})
  flush3d(128, 32, 32, 32)

  -- Col 5: Cottonwood tree (slender trunk + 3D normal-shaded foliage canopy, no ground plate)
  begin3d(16, 22)
  cyl_v(0, 0, 2.2, 0, 10.5, "wood", "ochre", "wood", "deep", nil)
  blob(0, 0, 12.8, 6.5, 6.5, 4.8, "leaf", "grass", "pine")
  blob(-1.8, -1.4, 14.2, 4.2, 4.2, 3.2, "sage", "leaf", "grass")
  flush3d(160, 32, 32, 32)
end)
K.save("tactical_cover")

-- ============================================================================
-- 3. TACTICAL UNITS (192x96, 6 cols x 3 rows of 32x32 cells)
-- Uses traveler_palette.gd colors (skin/skin_dk, appearance_hair, blue/light_blue/teal)
-- Row 0: Facing NE (up-right) — Ready, Aim, Fire, Reload, Crouch, Downed
-- Row 1: Facing SW (down-left) — Ready, Aim, Fire, Reload, Crouch, Downed
-- Row 2: Soldier Uniform SW (Ready, Aim, Fire, Reload) + Smoke 1 & Smoke 2
-- ============================================================================
K.canvas(192, 96, 184882)

local function draw_unit(col_idx, row_idx, dir, pose, soldier)
  local ox = col_idx * 32
  local oy = row_idx * 32
  local coat_mid = soldier and "sky" or "blue"
  local coat_lit = soldier and "light_blue" or "light_blue"
  local coat_shd = soldier and "blue" or "teal"
  local hat_col  = soldier and "storm_dk" or "appearance_hair"
  local pants    = soldier and "storm" or "roof"

  if pose == "downed" then
    -- Fallen body on ground
    K.ellipse(ox + 16, oy + 22, 9, 4, "deep")
    K.rect(ox + 8, oy + 19, 12, 5, coat_mid)
    K.rect(ox + 9, oy + 19, 6, 3, coat_lit)
    K.rect(ox + 19, oy + 20, 6, 4, pants)
    K.ellipse(ox + 7, oy + 20, 3, 2, "skin")
    K.rect(ox + 23, oy + 16, 4, 2, hat_col)
    K.line(ox + 9, oy + 25, ox + 22, oy + 24, "wood")
    return
  end

  local crouch = (pose == "crouch")
  local dy = crouch and 4 or 0

  -- Ground shadow
  K.ellipse(ox + 16, oy + 27, 6, 2, "ink")

  -- Boots & trousers
  if crouch then
    K.rect(ox + 12, oy + 22, 8, 5, pants)
    K.rect(ox + 11, oy + 26, 4, 2, "ink")
    K.rect(ox + 17, oy + 25, 4, 2, "ink")
  else
    K.rect(ox + 12, oy + 20, 3, 7, pants)
    K.rect(ox + 17, oy + 20, 3, 7, pants)
    K.rect(ox + 12, oy + 26, 3, 2, "ink")
    K.rect(ox + 17, oy + 26, 3, 2, "ink")
  end

  -- Coat / Torso
  K.rect(ox + 11, oy + 12 + dy, 10, 8 - math.floor(dy/2), coat_mid)
  K.rect(ox + 11, oy + 12 + dy, 5, 7 - math.floor(dy/2), coat_lit)
  K.rect(ox + 17, oy + 13 + dy, 4, 7 - math.floor(dy/2), coat_shd)
  if soldier then
    -- White crossbelt
    K.line(ox + 12, oy + 12 + dy, ox + 19, oy + 19 + dy, "ox_white")
    K.line(ox + 19, oy + 12 + dy, ox + 12, oy + 19 + dy, "ox_white")
  else
    -- Powder horn strap
    K.line(ox + 12, oy + 12 + dy, ox + 19, oy + 18 + dy, "ochre")
  end

  -- Head & 1848 Hat
  local hy = oy + 6 + dy
  K.rect(ox + 13, hy + 2, 6, 4, "skin")
  K.px(ox + 18, hy + 4, "skin_dk")
  if dir > 0 then
    K.px(ox + 17, hy + 3, "ink")
  else
    K.px(ox + 14, hy + 3, "ink")
  end
  -- Broad-brimmed plains hat or army forage cap
  if soldier then
    K.rect(ox + 12, hy, 8, 2, hat_col)
    K.line(ox + 11, hy + 2, ox + 20, hy + 2, "ink")
    K.px(ox + 15, hy + 1, "gold")
  else
    K.line(ox + 10, hy + 2, ox + 21, hy + 2, hat_col)
    K.rect(ox + 12, hy, 8, 2, hat_col)
    K.line(ox + 12, hy + 1, ox + 19, hy + 1, "ochre")
  end

  -- 1848 Hawken / Plains Muzzleloader Rifle
  if pose == "ready" or pose == "crouch" then
    if dir > 0 then
      K.line(ox + 10, oy + 18 + dy, ox + 25, oy + 11 + dy, "wood")
      K.line(ox + 16, oy + 15 + dy, ox + 27, oy + 10 + dy, "storm_dk")
      K.px(ox + 14, oy + 16 + dy, "skin"); K.px(ox + 19, oy + 14 + dy, "skin")
    else
      K.line(ox + 21, oy + 14 + dy, ox + 7, oy + 20 + dy, "wood")
      K.line(ox + 15, oy + 17 + dy, ox + 5, oy + 21 + dy, "storm_dk")
      K.px(ox + 17, oy + 16 + dy, "skin"); K.px(ox + 11, oy + 18 + dy, "skin")
    end
  elseif pose == "aim" or pose == "fire" then
    if dir > 0 then
      -- Stock at shoulder, long barrel aimed NE
      K.line(ox + 14, oy + 14, ox + 28, oy + 9, "storm_dk")
      K.line(ox + 12, oy + 15, ox + 21, oy + 12, "wood")
      K.px(ox + 16, oy + 14, "skin"); K.px(ox + 20, oy + 12, "skin")
      if pose == "fire" then
        K.rect(ox + 28, oy + 7, 3, 3, "gold")
        K.px(ox + 29, oy + 8, "white")
        K.px(ox + 27, oy + 6, "red"); K.px(ox + 30, oy + 10, "brick_lt")
      end
    else
      -- Stock at shoulder, long barrel aimed SW
      K.line(ox + 17, oy + 14, ox + 3, oy + 19, "storm_dk")
      K.line(ox + 19, oy + 13, ox + 10, oy + 16, "wood")
      K.px(ox + 15, oy + 15, "skin"); K.px(ox + 11, oy + 16, "skin")
      if pose == "fire" then
        K.rect(ox + 1, oy + 18, 3, 3, "gold")
        K.px(ox + 2, oy + 19, "white")
        K.px(ox + 4, oy + 21, "red"); K.px(ox + 1, oy + 17, "brick_lt")
      end
    end
  elseif pose == "reload" then
    -- Rifle grounded vertically, ramrod raised overhead
    local rx = dir > 0 and (ox + 21) or (ox + 10)
    K.line(rx, oy + 11, rx, oy + 26, "wood")
    K.line(rx + 1, oy + 10, rx + 1, oy + 22, "storm_dk")
    -- Ramrod in raised hand
    K.line(rx + 1, oy + 3, rx + 1, oy + 11, "sand")
    K.rect(rx, oy + 5, 2, 2, "skin")
    K.px(ox + 16, oy + 15, "skin")
  end
end

K.layer("ne squad poses", function()
  local poses = {"ready", "aim", "fire", "reload", "crouch", "downed"}
  for i, p in ipairs(poses) do
    draw_unit(i - 1, 0, 1, p, false)
  end
end)

K.layer("sw defender poses", function()
  local poses = {"ready", "aim", "fire", "reload", "crouch", "downed"}
  for i, p in ipairs(poses) do
    draw_unit(i - 1, 1, -1, p, false)
  end
end)

K.layer("soldier poses and powder smoke", function()
  local poses = {"ready", "aim", "fire", "reload"}
  for i, p in ipairs(poses) do
    draw_unit(i - 1, 2, -1, p, true)
  end
  -- Col 4: Dense black-powder smoke cloud
  local sx, sy = 4 * 32, 2 * 32
  K.ellipse(sx + 15, sy + 17, 8, 6, "stone")
  K.ellipse(sx + 13, sy + 15, 6, 5, "stone_lt")
  K.ellipse(sx + 18, sy + 14, 5, 4, "cream")
  K.ellipse(sx + 12, sy + 13, 4, 3, "white")
  -- Col 5: Dissipating smoke & hit spark
  sx = 5 * 32
  K.ellipse(sx + 11, sy + 13, 5, 3, "stone_lt")
  K.ellipse(sx + 20, sy + 10, 4, 3, "mist")
  K.ellipse(sx + 16, sy + 22, 4, 3, "red")
  K.px(sx + 16, sy + 22, "gold"); K.px(sx + 14, sy + 20, "brick_lt")
end)
K.save("tactical_units")

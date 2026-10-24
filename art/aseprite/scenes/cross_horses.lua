-- Horses and mules for the river crossing, in the same three-quarter (2:1 isometric) view as
-- art/aseprite/scenes/crossing_sprites.lua, travelling up and to the right across the river.
-- Built point by point through the same depth buffer; rows cut at a water level leave the
-- river showing through. Anchor: the ground point under the rear of the animal, (12, 34).
--   cross_horses   384x320  eight 48x40 frames per row; rows:
--     1 saddle horse and rider walking (landing or ferry deck)   5 pack horse wading
--     2 the same wading, water to the belly                      6 pack horse swimming
--     3 the same swimming, rider in to the waist                 7 pack mule walking
--     4 pack horse walking                                       8 pack mule swimming
local K = dofile(app.params.kit)
local FRAMES = 8
local AX, AY = 0.894, 0.447

local Z, OX, OY, CUT
local function begin(ox, oy, cut) Z, OX, OY, CUT = {}, ox, oy, cut or -99 end
local function pt(s, c, h, col)
  if h < CUT then return end
  if CUT > -99 and h < CUT + 0.55 then col = "light_blue" end
  local x = math.floor(OX + (s + c) * AX + 0.5)
  local y = math.floor(OY + (c - s) * AY - h + 0.5)
  local d = (c - s) * AY + h
  local key = (y + 1000) * 4096 + (x + 1000)
  local e = Z[key]
  if not e or d >= e[1] then Z[key] = {d, col, x, y} end
end
local function flush(fx, fy, w, h)
  for _, e in pairs(Z) do
    if e[3] >= 0 and e[3] < w and e[4] >= 0 and e[4] < h then K.px(fx + e[3], fy + e[4], e[2]) end
  end
end
local function seg(s0, c0, h0, s1, c1, h1, col)
  local n = math.max(2, math.floor(math.max(math.abs(s1 - s0), math.abs(c1 - c0), math.abs(h1 - h0)) * 3))
  for i = 0, n do local u = i / n; pt(s0 + (s1 - s0) * u, c0 + (c1 - c0) * u, h0 + (h1 - h0) * u, col) end
end
-- an ellipsoid shaded by its surface normal: lit from the upper left
local function blob(s0, c0, h0, rs, rc, rh, lit, mid, dark)
  for i = 0, 40 do
    local th = i / 40 * math.pi
    for j = 0, 60 do
      local ph = j / 60 * 2 * math.pi
      local ns, nc, nh = math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th)
      local light = nh * 0.8 - nc * 0.5 + ns * 0.1
      local col = (light > 0.45) and lit or ((light < -0.15) and dark or mid)
      pt(s0 + rs * ns, c0 + rc * nc, h0 + rh * nh, col)
    end
  end
end
local function box(s0, s1, c0, c1, h0, h1, top, right, back)
  for s = s0, s1, 0.3 do for c = c0, c1, 0.3 do pt(s, c, h1, top) end end
  for s = s0, s1, 0.3 do for h = h0, h1, 0.3 do pt(s, c1, h, right); pt(s, c0, h, right) end end
  for c = c0, c1, 0.3 do for h = h0, h1, 0.3 do pt(s0, c, h, back); pt(s1, c, h, back) end end
end
local function ground_shadow(s0, s1, rc)
  if CUT > -99 then return end
  local m, r = (s0 + s1) / 2, (s1 - s0) / 2
  for s = s0, s1, 0.3 do for c = -rc, rc, 0.3 do
    if ((s - m) / r) ^ 2 + (c / rc) ^ 2 <= 1 then pt(s, c, 0, "ground_shadow") end
  end end
end


local COATS = {
  bay = {"rust", "ox", "ox_dk", points = "ink"},
  dun = {"sand", "gold", "ochre", points = "deep"},
  mule = {"ox", "ox_dk", "deep", points = "ink", mule = true},
}

-- s forward, c toward the viewer, h up. The barrel sits high on long legs.
local function animal(t, coat, swim)
  local p = COATS[coat]
  local bob = (math.cos(t * 4 * math.pi) > 0) and 0 or 0.4
  if not swim then ground_shadow(-7, 9, 3) end
  local neck_h = swim and 1.5 or 0
  -- legs first: a four-beat walk, or a slow paddling stroke when swimming
  for _, l in ipairs({{4.5, 1.3, 0}, {4.5, -1.3, 0.5}, {-4.5, 1.3, 0.25}, {-4.5, -1.3, 0.75}}) do
    local ph = (t + l[3]) * 2 * math.pi
    local swing = (swim and 2.6 or 1.8) * math.sin(ph)
    local lift = swim and 3 or math.max(0, math.cos(ph)) * 1.1
    seg(l[1], l[2], 7 + bob, l[1] + swing * 0.4, l[2], 3.5 + lift * 0.5, p[2])
    seg(l[1] + swing * 0.4, l[2], 3.5 + lift * 0.5, l[1] + swing, l[2], lift, p.points)
    pt(l[1] + swing, l[2], lift, "ink")
  end
  -- barrel, croup and chest
  blob(0, 0, 9 + bob, 6.2, 2.3, 2.5, p[1], p[2], p[3])
  blob(-4.5, 0, 9.6 + bob, 2.6, 2.2, 2.2, p[1], p[2], p[3])
  blob(4.6, 0, 9.4 + bob, 2.4, 2.1, 2.4, p[1], p[2], p[3])
  -- neck rising forward, head angled down to the muzzle
  for k = 0, 6 do
    local u = k / 6
    blob(5.5 + 2.6 * u, 0, 10.5 + bob + neck_h + 3.2 * u, 1.6 - 0.3 * u, 1.3, 1.6 - 0.3 * u, p[1], p[2], p[3])
  end
  local hs, hh = 9.2, 14 + bob + neck_h
  blob(hs + 1.4, 0, hh - 0.6, 2.0, 1.0, 1.0, p[1], p[2], p[3])
  blob(hs + 3.0, 0, hh - 1.2, 0.9, 0.9, 0.8, p.mule and "sand" or p[2], p.mule and "silt_lt" or p[3], p[3])
  pt(hs + 1.2, 1.0, hh - 0.2, "ink") -- eye
  if p.mule then
    for _, side in ipairs({-0.6, 0.6}) do seg(hs + 0.2, side, hh + 0.6, hs - 0.6, side, hh + 3.6, (side > 0) and p[2] or p[3]) end
  else
    for _, side in ipairs({-0.6, 0.6}) do seg(hs + 0.2, side, hh + 0.6, hs + 0.1, side, hh + 1.8, p[3]) end
    -- mane along the crest
    for k = 0, 8 do local u = k / 8; pt(5.4 + 3.4 * u, 0.4, 12.4 + bob + neck_h + 3 * u, p.points) end
  end
  -- tail
  if p.mule then
    seg(-6.8, 0, 9.5 + bob, -7.6, 0, 6, p[3]); seg(-7.6, 0, 6, -7.8, 0, 4.5, "ink")
  else
    seg(-6.8, 0, 10 + bob, -8, 0, 5.5, p.points); seg(-6.8, 0.4, 10 + bob, -7.8, 0.4, 6, p.points)
  end
  return bob
end

local function saddle_and_rider(t, bob, swim)
  -- red blanket and saddle, the rider sitting up with the reins forward
  box(-2.2, 2.2, -2.4, 2.4, 11.2 + bob, 11.7 + bob, "red", "brick_dk", "brick_dk")
  box(-1.4, 1.8, -1.6, 1.6, 11.7 + bob, 12.4 + bob, "wood", "deep", "deep")
  local rb = bob + ((math.cos(t * 4 * math.pi + 0.6) < -0.3) and 0.3 or 0)
  local lean = swim and 0.8 or 0
  -- legs down each flank (lost under water when swimming)
  for _, side in ipairs({-1, 1}) do
    seg(0.4, side * 2.3, 12.4 + rb, 1.4, side * 2.6, 9.5 + rb, (side > 0) and "wood" or "deep")
    seg(1.4, side * 2.6, 9.5 + rb, 1.0, side * 2.6, 7.2 + rb, (side > 0) and "wood" or "deep")
  end
  box(-0.9 + lean, 1.1 + lean, -1.2, 1.2, 12.4 + rb, 16.4 + rb, "light_blue", "blue", "teal")
  blob(0.3 + lean, 0, 17.6 + rb, 0.9, 0.9, 1.0, "skin", "skin", "skin_dk")
  box(-0.9 + lean, 1.5 + lean, -1.3, 1.3, 18.4 + rb, 18.7 + rb, "deep", "deep", "ink") -- hat brim
  box(-0.4 + lean, 1.0 + lean, -0.7, 0.7, 18.7 + rb, 19.6 + rb, "wood", "deep", "deep")
  seg(1.1 + lean, 1.2, 14.6 + rb, 3.6, 1.0, 13.4 + rb, "blue") -- near arm to the reins
  seg(3.6, 1.0, 13.4 + rb, 10.4, 0.8, 13.6 + bob + (swim and 1.5 or 0), "deep") -- reins
end

local function pack(bob, mule)
  local s0 = mule and 0.2 or 0
  box(s0 - 3, s0 + 3, -2.4, 2.4, 11.2 + bob, 11.6 + bob, "teal", "teal", "pine") -- pad
  for _, side in ipairs({-1, 1}) do
    local c0, c1 = side * 2.4, side * 3.7
    box(s0 - 2.8, s0 + 2.6, math.min(c0, c1), math.max(c0, c1), 8.4 + bob, 11.8 + bob, "cream", "sand", "silt")
  end
  box(s0 - 2, s0 + 2, -1.8, 1.8, 11.8 + bob, 13.0 + bob, "white", "ox_white", "stone")
  -- diamond hitch over the top and the near pannier
  seg(s0 - 2, 1.9, 13.0 + bob, s0 + 2, -1.9, 13.0 + bob, "wood"); seg(s0 + 2, 1.9, 13.0 + bob, s0 - 2, -1.9, 13.0 + bob, "wood")
  seg(s0 - 2.8, 3.75, 10.1 + bob, s0, 3.75, 11.8 + bob, "wood"); seg(s0, 3.75, 11.8 + bob, s0 + 2.6, 3.75, 10.1 + bob, "wood")
  seg(s0 - 2.8, 3.75, 10.1 + bob, s0, 3.75, 8.4 + bob, "wood"); seg(s0, 3.75, 8.4 + bob, s0 + 2.6, 3.75, 10.1 + bob, "wood")
end

local function wake(f)
  for i = 0, 5 do pt(-8 - i * 1.2, ((i + f) % 2 == 0) and 2.4 or -2.4, 6.1, (i < 2) and "white" or "light_blue") end
  pt(12.6, 0, 6.1, "white"); pt(12, 1.6, 6.1, "white")
end

K.canvas(384, 320, 1848)
K.layer("horses", function()
  local rows = {
    {"bay", "rider", nil}, {"bay", "rider", 3.6}, {"bay", "rider", 6},
    {"bay", "pack", nil}, {"bay", "pack", 3.6}, {"bay", "pack", 6},
    {"mule", "pack", nil}, {"mule", "pack", 6},
  }
  for r, spec in ipairs(rows) do
    for f = 1, FRAMES do
      local t = (f - 1) / FRAMES
      local swim = spec[3] == 6
      begin(12, 34, spec[3])
      local bob = animal(t, spec[1], swim)
      if spec[2] == "rider" then saddle_and_rider(t, bob, swim) else pack(bob, spec[1] == "mule") end
      if swim then wake(f) end
      flush((f - 1) * 48, (r - 1) * 40, 48, 40)
    end
  end
end)
K.save("cross_horses")

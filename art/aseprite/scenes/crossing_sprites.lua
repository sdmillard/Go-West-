-- River crossing sprites in a three-quarter (2:1 isometric) view, travelling up and to the right
-- across a diagonal river. Each piece is modelled as solid shapes in ground coordinates and
-- rendered point by point through a depth buffer, so wheels, bonnet and oxen overlap correctly.
--   s = forward (screen up-right), c = to the right (screen down-right, toward the viewer), h = up.
-- Every frame has an anchor: the ground point under the rear centre of the piece. ui/trail_view.gd
-- places frames by that anchor. Rows cut off at a water level leave the river showing through.
--   cross_wagon     512x192  eight 64x48 frames per row, anchor (10, 42)
--                            rows: wagon and team / the same wading / wagon alone / wagon floating
--   cross_swim_ox   256x24   eight 32x24 frames, anchor (8, 19): an ox swimming, head held up
--   cross_raft      72x40    one frame, anchor (14, 32): plank ferry, deck 2 px above the water
--   cross_ferryman  256x40   eight 32x40 frames, anchor (12, 30): working a setting pole
--   cross_people    128x40   eight 16x20 frames, anchor (8, 17): rows man / woman, walking
--   cross_swimmer   128x36   eight 16x12 frames, anchor (6, 8): rows man / woman / in trouble
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

---------------------------------------------------------------- wagon and team
local L, WD = 24, 6
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

local function wagon(rot)
  ground_shadow(-2, L + 2, 8)
  for _, side in ipairs({-1, 1}) do
    local c = side * (WD + 0.6)
    wheel(5, c, 5, rot, side < 0); wheel(19, c, 4, rot * 1.25, side < 0)
  end
  seg(3, 0, 4, 21, 0, 4, "deep")
  -- the bed: blue box with a pale top rail and a dark stripe
  box(0, L, -WD, WD, 5, 10, "deep", "blue", "teal")
  for s = 0, L, 0.3 do pt(s, WD, 10, "light_blue"); pt(s, WD, 7, "teal"); pt(s, WD, 5, "ink") end
  -- the bonnet: a canvas half-cylinder on hickory bows, shaded on its far flank
  for s = 1, L - 1, 0.25 do
    for k = 0, 60 do
      local th = k / 60 * math.pi
      local cs = math.cos(th)
      local col = (cs > 0.55) and "clap_sh" or ((cs > 0.05) and "cream" or "white")
      for _, b in ipairs({6, 12, 18}) do if math.abs(s - b) < 0.3 and cs > -0.2 then col = "sand" end end
      pt(s, WD * cs, 10 + 8 * math.sin(th), col)
    end
  end
  -- the rear pucker: the end of the cover drawn in around a dark opening
  for c = -WD, WD, 0.25 do
    for h = 10, 18, 0.25 do
      if (c / WD) ^ 2 + ((h - 10) / 8) ^ 2 <= 1 then
        local open = (c / 2.4) ^ 2 + ((h - 13.5) / 3) ^ 2
        pt(1, c, h, (open <= 1) and "deep" or ((open <= 1.6) and "sand" or "cream"))
      end
    end
  end
end

local COATS = {light = {"ox_lt", "ox", "ox_dk"}, red = {"ochre", "rust", "ox_dk"}, dark = {"ox", "ox_dk", "deep"}}
local function ox(s0, c0, t, coat, head_up)
  local p = COATS[coat]
  local bob = (math.cos(t * 4 * math.pi) > 0) and 0 or 0.4
  blob(s0, c0, 7 + bob, 7, 2.6, 3, p[1], p[2], p[3])
  blob(s0 + 4, c0, 9 + bob, 2.5, 2.2, 1.6, p[1], p[2], p[3]) -- withers hump
  local hh = head_up and 10 or 7.5
  blob(s0 + 8.5, c0, hh + bob, 2.2, 1.8, 1.8, p[1], p[2], p[3])
  blob(s0 + 10.3, c0, hh - 0.6 + bob, 1.1, 1.2, 1.1, "ox_lt", "ox_lt", "deep")
  for _, side in ipairs({-1, 1}) do
    seg(s0 + 8.5, c0 + side * 1.4, hh + 1.4 + bob, s0 + 9.3, c0 + side * 2.6, hh + 2.6 + bob, "cream")
  end
  -- four legs in a walking gait: diagonal pairs move together
  for i, l in ipairs({{4.5, 1.5, 0}, {4.5, -1.5, 0.5}, {-4.5, 1.5, 0.5}, {-4.5, -1.5, 0}}) do
    local ph = (t + l[3]) * 2 * math.pi
    local swing = 1.8 * math.sin(ph)
    local lift = math.max(0, math.cos(ph)) * 0.9
    seg(s0 + l[1], c0 + l[2], 5 + bob, s0 + l[1] + swing, c0 + l[2], lift, p[3])
    pt(s0 + l[1] + swing, c0 + l[2], lift, "ink")
  end
  seg(s0 - 6.5, c0, 8, s0 - 7.5, c0, 4, p[3]) -- tail
end

local function team(t)
  local s0 = L + 16
  seg(L, 0, 4, s0 + 7, 0, 8.5, "wood") -- tongue up to the yoke
  ox(s0, -3.6, (t + 0.5) % 1, "dark")
  ox(s0, 3.6, t, "red")
  seg(s0 + 7, -6.5, 9.5, s0 + 7, 6.5, 9.5, "wood")
  for _, c in ipairs({-3.6, 3.6}) do seg(s0 + 7, c, 9.5, s0 + 7.5, c, 6.5, "ochre") end -- bows
end

K.canvas(512, 192, 1848)
K.layer("wagon", function()
  for f = 1, FRAMES do
    local t = (f - 1) / FRAMES
    local rot = -(f - 1) * math.pi / 12
    local fx = (f - 1) * 64
    begin(10, 42); wagon(rot); team(t); flush(fx, 0, 64, 48)
    begin(10, 42, 3.5); wagon(rot); team(t); flush(fx, 48, 64, 48)
    begin(10, 42); wagon(rot); seg(L, 0, 4, L + 9, 0, 0.5, "wood"); flush(fx, 96, 64, 48)
    begin(10, 42, 6.5); wagon(0); flush(fx, 144, 64, 48)
  end
end)
K.save("cross_wagon")

K.canvas(256, 24, 1848)
K.layer("swimming ox", function()
  for f = 1, FRAMES do
    local t = (f - 1) / FRAMES
    begin(8, 19, 4.6)
    ox(0, 0, t, "red", true)
    -- a wake trailing back from the shoulders
    for i = 0, 5 do pt(-8 - i * 1.2, ((i + f) % 2 == 0) and 2 or -2, 4.7, (i < 2) and "white" or "light_blue") end
    pt(11.5, 0, 4.7, "white"); pt(11, 1.5, 4.7, "white")
    flush((f - 1) * 32, 0, 32, 24)
  end
end)
K.save("cross_swim_ox")

---------------------------------------------------------------- ferry
local RL, RW = 56, 13
K.canvas(72, 40, 1848)
K.layer("raft", function()
  begin(14, 32, 0)
  -- plank deck laid across log stringers, rails at the ends, posts at the corners
  for s = 0, RL, 0.3 do
    for c = -RW, RW, 0.3 do
      local seam = (s % 4) < 0.35
      pt(s, c, 2, seam and "rust" or (((math.floor(s / 4) + math.floor((c + RW) / 9)) % 3 == 0) and "gold" or "ochre"))
    end
    for h = 0.6, 2, 0.3 do pt(s, RW, h, "wood"); pt(s, -RW, h, "wood") end
  end
  for c = -RW, RW, 0.3 do for h = 0.6, 2, 0.3 do pt(0, c, h, "deep"); pt(RL, c, h, "deep") end end
  for _, s in ipairs({0.5, RL - 0.5}) do for _, c in ipairs({-RW + 0.5, RW - 0.5}) do seg(s, c, 2, s, c, 5, "deep") end end
  for _, s in ipairs({0.5, RL - 0.5}) do seg(s, -RW, 4.5, s, RW, 4.5, "wood") end
  flush(0, 0, 72, 40)
end)
K.save("cross_raft")

local function person(s0, c0, h0, t, shirt, woman, moving)
  local sw = moving and 1.3 * math.sin(t * 2 * math.pi) or 0
  local bob = (moving and math.abs(math.sin(t * 2 * math.pi)) < 0.5) and 0.4 or 0
  if woman then
    for h = 0, 5, 0.25 do
      local r = 1.7 - h * 0.12
      for k = 0, 40 do local a = k / 40 * 2 * math.pi; pt(s0 + r * math.cos(a), c0 + r * math.sin(a), h0 + h + bob, (math.sin(a) > 0.4) and "brick_dk" or shirt) end
    end
    seg(s0 + sw * 0.5 + 1, c0 + 1, h0, s0 + sw * 0.5 + 1.6, c0 + 1, h0, "ink")
  else
    for _, l in ipairs({{-1, sw}, {1, -sw}}) do
      seg(s0, c0 + l[1] * 0.7, h0 + 5 + bob, s0 + l[2], c0 + l[1] * 0.7, h0, (l[1] > 0) and "wood" or "deep")
      pt(s0 + l[2] + 0.6, c0 + l[1] * 0.7, h0, "ink")
    end
  end
  box(s0 - 0.8, s0 + 0.8, c0 - 1.2, c0 + 1.2, h0 + 5 + bob, h0 + 9 + bob, shirt, shirt, shirt)
  for s = s0 - 0.8, s0 + 0.8, 0.3 do pt(s, c0 + 1.2, h0 + 9 + bob, woman and "brick_lt" or "light_blue") end
  -- arms swinging opposite the legs
  for _, a in ipairs({{-1.6, -sw}, {1.6, sw}}) do seg(s0, c0 + a[1], h0 + 9 + bob, s0 + a[2] * 0.7, c0 + a[1], h0 + 5.5 + bob, shirt) end
  blob(s0 + 0.2, c0, h0 + 10.6 + bob, 1.2, 1.2, 1.3, "skin", "skin", "skin_dk")
  if woman then
    blob(s0 - 0.4, c0, h0 + 11.1 + bob, 1.2, 1.3, 1.1, "white", "cream", "sand")
  else
    for k = 0, 40 do local a = k / 40 * 2 * math.pi; for r = 0, 2.2, 0.3 do pt(s0 + r * math.cos(a), c0 + r * math.sin(a), h0 + 11.6 + bob, "deep") end end
    blob(s0, c0, h0 + 12.4 + bob, 1.1, 1.1, 0.8, "wood", "deep", "deep")
  end
end

K.canvas(256, 40, 1848)
K.layer("ferryman", function()
  for f = 1, FRAMES do
    local t = (f - 1) / FRAMES
    begin(12, 30, -2)
    local pushing = t < 0.625
    local u = pushing and (t / 0.625) or ((t - 0.625) / 0.375)
    person(0, 0, 0, 0, "red", false, false)
    -- setting pole: planted and walked aft while pushing, lifted and swung forward to recover
    local tip_s = pushing and (4 - 14 * u) or (-10 + 14 * u)
    local tip_h = pushing and -9 or (-1 + 3 * math.sin(u * math.pi))
    local top_s, top_h = 1.5 - (pushing and u * 2 or 2 - 2 * u), 13
    seg(top_s, 2.2, top_h, tip_s, 4.5, tip_h, "wood")
    seg(top_s + 0.3, 2.2, top_h, tip_s + 0.3, 4.5, tip_h, "ochre")
    pt(top_s - 0.1, 2.0, 8.5, "skin"); pt(top_s - 0.6, 2.0, 6.5, "skin")
    flush((f - 1) * 32, 0, 32, 40)
  end
end)
K.save("cross_ferryman")

K.canvas(128, 40, 1848)
K.layer("people", function()
  for f = 1, FRAMES do
    local t = (f - 1) / FRAMES
    begin(8, 17); person(0, 0, 0, t, "blue", false, true); flush((f - 1) * 16, 0, 16, 20)
    begin(8, 17); person(0, 0, 0, t, "red", true, true); flush((f - 1) * 16, 20, 16, 20)
  end
end)
K.save("cross_people")

---------------------------------------------------------------- swimmers
local function swimmer(t, kind)
  local shirt = (kind == 2) and "red" or "blue"
  local trouble = kind == 3
  local hh = trouble and (0.5 + 0.6 * math.sin(t * 4 * math.pi)) or 0.9
  blob(0, 0, -0.4, 3.6, 1.4, 1.0, shirt, shirt, "teal")
  if kind == 1 then box(-2, 0.5, -1, 1, 0.4, 1.4, "ochre", "wood", "wood") end -- a pack carried high
  blob(3.2, 0, hh, 1.2, 1.1, 1.2, "skin", "skin", "skin_dk")
  if kind == 2 then blob(2.8, 0, hh + 0.6, 1.4, 1.4, 1.0, "white", "cream", "sand")
  else blob(3.0, 0, hh + 0.8, 1.0, 1.0, 0.6, "deep", "deep", "ink") end
  if trouble then
    local wave = (t * 8) % 2 < 1 and 0 or 0.8
    seg(2.4, 1.4, 0.6, 3.0 + wave, 1.8, 6, "skin")
    for i = 0, 3 do pt(-3 + i * 2.2, ((i + math.floor(t * 8)) % 2 == 0) and 2.5 or -2.5, 0.1 + (i % 2), "white") end
  else
    for _, side in ipairs({-1, 1}) do
      local a = (t + (side > 0 and 0 or 0.5)) * 2 * math.pi
      local hs, hh2 = 3 + 3 * math.cos(a), 1.6 * math.sin(a)
      seg(2, side * 1.2, 0.3, hs, side * 1.8, hh2, "skin")
      if math.abs(hh2) < 0.5 then pt(hs, side * 1.8, 0.1, "white") end
    end
    -- kicking: a splash behind that alternates sides
    pt(-4.2, (math.floor(t * 8) % 2 == 0) and 0.8 or -0.8, 0.1, "white")
  end
end
K.canvas(128, 36, 1848)
K.layer("swimmers", function()
  for f = 1, FRAMES do
    local t = (f - 1) / FRAMES
    for kind = 1, 3 do
      begin(6, 8, 0); swimmer(t, kind); flush((f - 1) * 16, (kind - 1) * 12, 16, 12)
    end
  end
end)
K.save("cross_swimmer")

-- Hunting sprites with full run cycles, all facing right (ui/hunt_view.gd mirrors them).
-- Each animal sheet is eight frames wide at the species' hitbox size from data/hunting.json,
-- in three rows: walking (before any shot), running flat out (after the first shot), and down.
--   hunt_bison   320x72  (40x24 frames)  buffalo: a four-beat walk and a rocking gallop
--   hunt_deer    216x66  (27x22 frames)  mule deer: a walk, then stotting on all four feet
--   hunt_rabbit  120x33  (15x11 frames)  jackrabbit: easy hops, then long bounds, ears laid back
--   hunt_hunter  128x36  (16x18 frames)  rows: standing (breathing), walking; feet at (8, 17)
--   hunt_smoke   128x16  (16x16 frames)  a black-powder puff that billows, drifts up and thins
local K = dofile(app.params.kit)
local FRAMES = 8

local function shadow(cx, cy, rx)
  for x = -rx, rx do
    K.px(cx + x, cy, "ground_shadow")
    if math.abs(x) < rx - 2 then K.px(cx + x, cy + 1, "ground_shadow") end
  end
end

-- a two-part leg from hip (x, y) through a knee to the hoof
local function leg(x, y, kx, ky, fx, fy, c, hoof)
  K.line(x, y, kx, ky, c); K.line(x + 1, y, kx + 1, ky, c)
  K.line(kx, ky, fx, fy, c)
  K.px(fx, fy, hoof or "ink")
end

-- hoof position for one leg: a stance sweep backward, then a lifted swing forward
local function stride(t, reach, lift)
  t = t % 1
  if t < 0.6 then return math.floor(reach - 2 * reach * (t / 0.6) + 0.5), 0 end
  local u = (t - 0.6) / 0.4
  return math.floor(-reach + 2 * reach * u + 0.5), math.floor(lift * math.sin(u * math.pi) + 0.5)
end

---------------------------------------------------------------- buffalo
local function bison(ox, oy, frame, gait)
  local t = (frame - 1) / FRAMES
  local run = gait == 2
  local down = gait == 3
  local rise = 0
  if run then rise = (math.sin(t * 2 * math.pi) > 0.3) and -1 or 0 end
  local by = oy + rise + (down and 5 or 0)
  shadow(ox + 20, oy + 22, 16)
  -- legs behind the body: far side first, darker
  if not down then
    local reach, lift = run and 5 or 3, run and 3 or 2
    local ph = run and {0, 0.12, 0.5, 0.62} or {0, 0.5, 0.75, 0.25}
    local legs = {{9, true, ph[2]}, {28, true, ph[4]}, {7, false, ph[1]}, {26, false, ph[3]}}
    for _, l in ipairs(legs) do
      local dx, up = stride(t + l[3], reach, lift)
      local hip = l[1]
      local c = l[2] and "ink" or "deep"
      leg(ox + hip, by + 15, ox + hip + math.floor(dx / 2), by + 18 - math.floor(up / 2), ox + hip + dx, oy + 21 - up, c)
    end
  end
  -- tail, lifted when running
  if run then K.line(ox + 4, by + 7, ox + 1, by + 4, "deep"); K.px(ox + 1, by + 3, "ink")
  else K.line(ox + 3, by + 8, ox + 2, by + 13, "deep"); K.px(ox + 2, by + 14, "ink") end
  -- short-haired hindquarters and barrel
  K.ellipse(ox + 12, by + 11, 9, 5, "ox_dk")
  K.ellipse(ox + 11, by + 9, 7, 2, "ox")
  K.rect(ox + 6, by + 15, 14, 1, "deep")
  -- the great shaggy hump and cape over the shoulders and forelegs
  K.ellipse(ox + 25, by + 9, 8, 7, "wood")
  K.ellipse(ox + 24, by + 6, 6, 4, "rust")
  K.ellipse(ox + 23, by + 4, 3, 2, "ochre")
  for i = 0, 5 do K.px(ox + 19 + i * 2, by + 15 + (i % 2), "wood") end -- ragged lower edge of the cape
  -- heavy head carried low, beard and short black horns
  local hx, hy = ox + 31, by + (down and 9 or 7)
  K.rect(hx, hy, 6, 7, "deep"); K.rect(hx + 1, hy, 4, 3, "ox_dk")
  K.rect(hx + 6, hy + 4, 2, 3, "ink")
  K.rect(hx + 1, hy + 7, 4, 3, "deep") -- beard
  K.px(hx + 3, hy - 1, "ink"); K.px(hx + 4, hy - 2, "stone_dk")
  if down then K.rect(hx + 3, hy + 2, 2, 1, "ink") else K.px(hx + 4, hy + 2, "gold") end
  if down then
    -- folded legs showing under the body
    K.rect(ox + 8, oy + 21, 6, 1, "ink"); K.rect(ox + 24, oy + 21, 6, 1, "ink")
  end
end

K.canvas(320, 72, 184881)
K.layer("bison", function()
  for f = 1, FRAMES do for g = 1, 3 do bison((f - 1) * 40, (g - 1) * 24, (g == 3) and 1 or f, g) end end
end)
K.save("hunt_bison")

---------------------------------------------------------------- mule deer
local function deer(ox, oy, frame, gait)
  local t = (frame - 1) / FRAMES
  local run = gait == 2
  local down = gait == 3
  -- stotting: all four feet leave the ground together, body high in the air
  local air = run and math.floor(4 * math.abs(math.sin(t * 2 * math.pi)) + 0.5) or 0
  local by = oy - air + (down and 7 or 0)
  shadow(ox + 13, oy + 20, run and (10 - air) or 10)
  if not down then
    if run then
      -- legs tucked in the air, stiff and straight on the ground
      local tuck = air > 1
      for _, l in ipairs({{7, "rust"}, {16, "rust"}, {5, "wood"}, {14, "wood"}}) do
        if tuck then leg(ox + l[1], by + 13, ox + l[1] + 2, by + 16, ox + l[1], by + 19, l[2])
        else K.line(ox + l[1], by + 13, ox + l[1], oy + 20, l[2]); K.px(ox + l[1], oy + 20, "ink") end
      end
    else
      local ph = {0.25, 0.75, 0, 0.5}
      local hips = {{7, "rust"}, {17, "rust"}, {5, "wood"}, {15, "wood"}}
      for i, l in ipairs(hips) do
        local dx, up = stride(t + ph[i], 2, 2)
        leg(ox + l[1], by + 13, ox + l[1] + math.floor(dx / 2) + ((i % 2 == 0) and 1 or -1), by + 16 - up, ox + l[1] + dx, oy + 20 - up, l[2])
      end
    end
  end
  -- body: grey-brown winter coat, pale belly, the white rump patch and black-tipped tail
  K.ellipse(ox + 11, by + 10, 8, 3, "ochre")
  K.rect(ox + 5, by + 8, 12, 1, "gold")
  K.rect(ox + 6, by + 12, 10, 1, "cream")
  K.ellipse(ox + 3, by + 9, 2, 2, "white")
  K.px(ox + 1, by + (run and 7 or 9), "ink")
  -- neck and head held high, the big mule ears
  local hx, hy = ox + 20, by + (down and 6 or 2)
  K.poly({{ox + 16, by + 8}, {hx, hy + 2}, {hx + 2, hy + 4}, {ox + 18, by + 11}}, "ochre")
  K.rect(hx, hy, 4, 3, "ochre"); K.rect(hx + 4, hy + 1, 2, 2, "clap_sh"); K.px(hx + 5, hy + 1, "ink")
  K.px(hx + 2, hy, "ink")
  K.rect(hx - 1, hy - 2, 2, 2, "wood"); K.px(hx + 1, hy - 2, "wood") -- ears
  -- antlers forking twice, as on a mule deer buck
  K.line(hx + 1, hy - 1, hx + 2, hy - 4, "sand"); K.px(hx + 3, hy - 3, "sand"); K.px(hx + 1, hy - 4, "cream")
  if down then
    K.rect(ox + 6, oy + 20, 5, 1, "wood"); K.rect(ox + 14, oy + 20, 5, 1, "wood")
    K.px(hx + 2, hy, "deep")
  end
end

K.canvas(216, 66, 184882)
K.layer("deer", function()
  for f = 1, FRAMES do for g = 1, 3 do deer((f - 1) * 27, (g - 1) * 22, (g == 3) and 1 or f, g) end end
end)
K.save("hunt_deer")

---------------------------------------------------------------- jackrabbit
local function rabbit(ox, oy, frame, gait)
  local t = (frame - 1) / FRAMES
  local run = gait == 2
  local down = gait == 3
  local hop = run and 3 or 1
  local u = (t * (run and 2 or 1)) % 1
  local air = down and 0 or math.floor(hop * math.max(0, math.sin(u * 2 * math.pi)) + 0.5)
  local stretch = (air > 0) and 1 or 0
  local by = oy - air
  shadow(ox + 7, oy + 10, 4)
  if down then
    K.ellipse(ox + 7, oy + 8, 5, 2, "sand"); K.rect(ox + 3, oy + 7, 8, 1, "cream")
    K.rect(ox + 11, oy + 7, 3, 2, "sand"); K.px(ox + 13, oy + 8, "ink")
    K.line(ox + 11, oy + 6, ox + 8, oy + 5, "sand"); K.px(ox + 8, oy + 5, "ink")
    return
  end
  -- long hind feet pushing off, forefeet reaching
  if air > 0 then
    K.rect(ox + 1, by + 7, 3, 1, "wood"); K.rect(ox + 11, by + 7, 2, 1, "wood")
  else
    K.rect(ox + 3, oy + 9, 3, 1, "wood"); K.rect(ox + 9, oy + 9, 2, 1, "wood")
  end
  K.ellipse(ox + 6 + stretch, by + 6, 4 + stretch, 2, "sand")
  K.rect(ox + 4, by + 4, 5, 1, "cream"); K.rect(ox + 4, by + 7, 5, 1, "ochre")
  K.rect(ox + 2, by + 5, 1, 2, "white")
  K.rect(ox + 9 + stretch, by + 3, 4, 3, "sand"); K.px(ox + 11 + stretch, by + 4, "ink")
  -- ears: up while walking, laid back flat when running
  if run then
    K.line(ox + 9 + stretch, by + 3, ox + 5 + stretch, by + 2, "sand"); K.px(ox + 5 + stretch, by + 2, "ink")
    K.line(ox + 10 + stretch, by + 2, ox + 6 + stretch, by + 1, "clap_sh")
  else
    K.line(ox + 10, by + 2, ox + 9, by - 1 + ((frame % 4 == 0) and 1 or 0), "sand"); K.px(ox + 9, by - 1, "ink")
    K.line(ox + 11, by + 2, ox + 11, by - 1, "clap_sh"); K.px(ox + 11, by - 1, "ink")
  end
end

K.canvas(120, 33, 184883)
K.layer("rabbit", function()
  for f = 1, FRAMES do for g = 1, 3 do rabbit((f - 1) * 15, (g - 1) * 11 + 1, (g == 3) and 1 or f, g) end end
end)
K.save("hunt_rabbit")

---------------------------------------------------------------- hunter
-- Side view facing right, rifle carried by the engine (it follows the aim). Feet at (8, 17).
local function hunter(ox, oy, frame, walking)
  local t = (frame - 1) / FRAMES
  local sw = walking and math.floor(3 * math.sin(t * 2 * math.pi) + 0.5) or 0
  local bob = (walking and math.abs(math.sin(t * 2 * math.pi)) < 0.5) and 1 or 0
  local breathe = (not walking and frame > 4) and 1 or 0
  shadow(ox + 8, oy + 17, 5)
  -- legs: far leg darker, boots
  K.line(ox + 7, oy + 11, ox + 7 - sw, oy + 16, "deep"); K.rect(ox + 7 - sw, oy + 16, 2, 1, "ink")
  K.line(ox + 8, oy + 11, ox + 8 + sw, oy + 16, "wood"); K.rect(ox + 8 + sw, oy + 16, 3, 1, "ink")
  local y = oy + bob
  -- fringed buckskin hunting frock over a blue shirt, powder horn on a strap
  K.rect(ox + 5, y + 6, 6, 6, "ochre"); K.rect(ox + 5, y + 6, 2, 6, "gold")
  K.rect(ox + 10, y + 7 + breathe, 1, 5 - breathe, "rust")
  for i = 0, 2 do K.px(ox + 5 + i * 2, y + 12, "sand") end
  K.rect(ox + 8, y + 6, 2, 2, "blue")
  K.line(ox + 6, y + 6, ox + 9, y + 10, "deep"); K.px(ox + 9, y + 11, "cream")
  K.rect(ox + 5, y + 10, 6, 1, "wood")
  -- head in profile under a wide felt hat
  K.rect(ox + 7, y + 2, 3, 4, "skin"); K.px(ox + 10, y + 3, "skin"); K.px(ox + 9, y + 3, "ink")
  K.rect(ox + 6, y + 2, 1, 3, "deep")
  K.rect(ox + 4, y + 1, 9, 1, "deep"); K.rect(ox + 6, y - 1, 5, 2, "wood"); K.rect(ox + 6, y, 5, 1, "deep")
  -- the near arm, reaching forward to the rifle's fore-end
  K.line(ox + 8, y + 7, ox + 11, y + 9, "rust"); K.px(ox + 12, y + 9, "skin")
end

K.canvas(128, 36, 184885)
K.layer("hunter", function()
  for f = 1, FRAMES do
    hunter((f - 1) * 16, 1, f, false)
    hunter((f - 1) * 16, 19, f, true)
  end
end)
K.save("hunt_hunter")

---------------------------------------------------------------- smoke
K.canvas(128, 16, 184887)
K.layer("smoke", function()
  for f = 1, FRAMES do
    local ox = (f - 1) * 16
    local u = (f - 1) / (FRAMES - 1)
    local r = 2 + math.floor(4 * u + 0.5)
    local cy = 12 - math.floor(5 * u + 0.5)
    for _, p in ipairs({{0, 0, 1}, {-2, 1, 0.7}, {2, 1, 0.7}, {1, -2, 0.6}}) do
      local pr = math.max(1, math.floor(r * p[3] + 0.5))
      for y = -pr, pr do for x = -pr, pr do
        if x * x + y * y <= pr * pr + 0.5 then
          local px, py = ox + 8 + p[1] * math.floor(r / 2 + 0.5) + x, cy + p[2] + y
          -- the puff thins out into a dither as it drifts away
          if u < 0.45 or (u < 0.8 and (px + py) % 2 == 0) or (px % 2 == 0 and py % 2 == 0) then
            K.px(px, py, (y < 0 and x < 0) and "white" or ((f <= 2) and "cream" or "stone_lt"))
          end
        end
      end end
    end
    if f == 1 then K.px(ox + 8, 12, "gold"); K.px(ox + 9, 12, "white") end
  end
end)
K.save("hunt_smoke")

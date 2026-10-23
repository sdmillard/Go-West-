-- 4-frame emigrant wagon sprite sheet (384x64, four 96x64 frames).
-- 1848 prairie schooner / heavy farm wagon with boat-edged blue/wood bed, iron hardware,
-- lashed rear water barrel, swinging tar bucket under the axle, billowing canvas tilt over
-- hickory bows, front driver seat, wagon tongue, and rotating spoked wheels (rear r=9, front r=7).
local K = dofile(app.params.kit)
local W, H = 384, 64

K.canvas(W, H, 1848)

local function circle(cx, cy, r, c)
  local limit = r * r - 1
  for y = -r, r do
    for x = -r, r do
      if x * x + y * y <= limit then K.px(cx + x, cy + y, c) end
    end
  end
end

local function draw_wheel(cx, cy, r, frame)
  -- Smooth round outer iron tire & wooden felloe ring (no cardinal 1px spikes)
  circle(cx, cy, r, "ink")
  circle(cx, cy, r - 1, "ochre")
  K.px(cx - r + 2, cy - r + 2, "gold")
  K.px(cx - r + 1, cy - r + 3, "gold")
  -- Cut out interior between felloe and hub so spokes are distinct
  circle(cx, cy, r - 2, "deep")
  -- 6 rotating wooden spokes (stepping 15 degrees per frame across 4 frames)
  for s = 0, 5 do
    local ang = s * (math.pi / 3.0) + (frame - 1) * (math.pi / 12.0)
    for rad = 2, r - 2 do
      local sx = cx + math.floor(math.cos(ang) * rad + 0.5)
      local sy = cy + math.floor(math.sin(ang) * rad + 0.5)
      K.px(sx, sy, (rad < r - 3) and "gold" or "ochre")
    end
  end
  -- Iron-banded wooden nave (hub)
  K.rect(cx - 2, cy - 2, 5, 5, "ink")
  K.rect(cx - 1, cy - 1, 3, 3, "sand")
  K.px(cx, cy, "rust")
end

local function draw_wagon_frame(fx, frame)
  -- 1. Translucent ground shadow (alpha 0x88 = 0.5333, matching test_art.gd)
  for y = -3, 3 do
    for x = -34, 34 do
      if (x*x)/(34*34 + 0.5) + (y*y)/(3*3 + 0.5) <= 1 then
        K.px(fx + 37 + x, 56 + y, "wagon_shadow")
      end
    end
  end

  local sway = (frame == 2) and 1 or ((frame == 4) and -1 or 0)

  -- 2. Undercarriage: hounds, reach pole, axles, and swinging tar/grease bucket
  K.rect(fx + 14, 48, 42, 2, "ink")
  K.rect(fx + 16, 47, 38, 1, "deep")
  -- Swinging tar bucket hung under the center reach pole
  local bx = fx + 34 + sway
  K.line(fx + 34, 48, bx, 50, "ink")
  K.rect(bx - 2, 50, 4, 4, "ink")
  K.rect(bx - 1, 51, 2, 2, "deep")
  K.px(bx - 1, 50, "roof_lt")

  -- 3. Wagon tongue & doubletree hardware extending forward to oxen (x+58..x+87, y=41..43)
  K.rect(fx + 58, 42, 29, 2, "wood")
  K.rect(fx + 59, 41, 27, 1, "gold")
  K.rect(fx + 58, 43, 29, 1, "deep")
  -- Hound stays & iron clevis at tongue tip
  K.line(fx + 56, 45, fx + 64, 42, "deep")
  K.rect(fx + 85, 41, 2, 3, "ink")
  K.px(fx + 86, 40, "roof_lt")

  -- 4. Canvas Tilt / Bonnet (arched over 5 hickory bows, with upper-left sun lighting)
  -- Outer dark silhouette
  K.poly({
    {fx + 7,  38}, {fx + 6,  23}, {fx + 10, 12}, {fx + 17, 6},
    {fx + 49, 6},  {fx + 57, 12}, {fx + 61, 23}, {fx + 59, 38}
  }, "deep")
  -- Shaded right/lower canvas body
  K.poly({
    {fx + 8,  37}, {fx + 8,  23}, {fx + 11, 13}, {fx + 18, 7},
    {fx + 48, 7},  {fx + 55, 13}, {fx + 59, 23}, {fx + 57, 37}
  }, "clap_sh")
  -- Warm mid-canvas tone
  K.poly({
    {fx + 8,  36}, {fx + 8,  23}, {fx + 11, 13}, {fx + 18, 7},
    {fx + 45, 7},  {fx + 51, 14}, {fx + 53, 24}, {fx + 52, 36}
  }, "sand")
  -- Sunlit upper-left canvas expanse
  K.poly({
    {fx + 9,  34}, {fx + 9,  22}, {fx + 12, 13}, {fx + 18, 8},
    {fx + 42, 8},  {fx + 46, 15}, {fx + 47, 34}
  }, "cream")
  -- Brightest crown highlight (upper left)
  K.poly({
    {fx + 12, 19}, {fx + 14, 12}, {fx + 19, 8},
    {fx + 37, 8},  {fx + 39, 13}, {fx + 36, 19}
  }, "white")

  -- Front canvas hood opening (dark interior glimpse on the right front edge)
  K.poly({{fx + 55, 14}, {fx + 59, 23}, {fx + 57, 36}, {fx + 53, 36}, {fx + 55, 24}}, "deep")
  K.poly({{fx + 56, 17}, {fx + 58, 23}, {fx + 56, 35}, {fx + 54, 35}}, "ink")

  -- Hickory bow ribs & natural canvas folds between hoops
  for _, bow_x in ipairs({17, 27, 37, 47}) do
    local top_y = (bow_x == 17 or bow_x == 47) and 9 or 8
    K.line(fx + bow_x, top_y, fx + bow_x - 1, 36, "ochre")
    K.line(fx + bow_x + 1, top_y + 1, fx + bow_x, 36, (bow_x < 40) and "white" or "cream")
  end

  -- Bottom canvas hem & rope tie-down grommets along the top of the wagon bed
  K.rect(fx + 9, 35, 48, 2, "sand")
  K.rect(fx + 9, 37, 49, 1, "ochre")
  for gx = 12, 54, 5 do
    K.px(fx + gx, 36, "deep")
    K.px(fx + gx + 1, 37, "gold")
  end

  -- 5. Hardwood Wagon Box / Bed (stepped panels, iron corner straps & side tool box)
  -- Outer frame outline
  K.rect(fx + 7, 38, 53, 10, "ink")
  -- Upper rave rail (painted emigrant blue with light_blue top highlight)
  K.rect(fx + 8, 38, 51, 1, "light_blue")
  K.rect(fx + 8, 39, 51, 3, "blue")
  K.rect(fx + 8, 42, 51, 1, "teal")
  -- Lower hardwood bed panel (seasoned oak/chestnut wood & rust)
  K.rect(fx + 9, 43, 49, 2, "rust")
  K.rect(fx + 9, 45, 49, 2, "wood")
  K.rect(fx + 9, 47, 49, 1, "ochre")

  -- Vertical wooden stakes / iron tie-rods along the wagon box
  for _, sx in ipairs({15, 24, 34, 44, 52}) do
    K.rect(fx + sx, 38, 2, 9, "deep")
    K.px(fx + sx, 39, "gold")
    K.px(fx + sx, 44, "ochre")
  end

  -- Angled side jockey/tool box mounted at mid-bed
  K.rect(fx + 27, 40, 8, 5, "deep")
  K.rect(fx + 28, 41, 6, 3, "wood")
  K.rect(fx + 28, 41, 6, 1, "ochre")
  K.px(fx + 31, 42, "gold") -- brass latch

  -- Front driver footboard & seat at front of bed
  K.rect(fx + 57, 33, 6, 3, "wood")
  K.rect(fx + 57, 33, 6, 1, "gold")
  K.line(fx + 59, 36, fx + 62, 40, "deep")

  -- 6. Lashed Wooden Water Barrel on the rear bracket
  K.rect(fx + 2, 31, 7, 14, "ink")
  K.rect(fx + 3, 32, 5, 12, "wood")
  K.rect(fx + 3, 32, 2, 12, "rust")
  K.rect(fx + 4, 32, 1, 12, "ochre")
  -- Barrel top & iron hoops
  K.rect(fx + 3, 31, 5, 1, "sand")
  K.rect(fx + 2, 34, 7, 1, "ink")
  K.rect(fx + 2, 38, 7, 1, "ink")
  K.rect(fx + 2, 42, 7, 1, "ink")

  -- 7. Spoked Wheels: Larger rear wheel (r=9 at y=50), smaller front wheel (r=7 at y=52)
  draw_wheel(fx + 19, 50, 9, frame)
  draw_wheel(fx + 51, 52, 7, frame)
end

K.layer("wagon", function()
  for f = 1, 4 do
    draw_wagon_frame((f - 1) * 96, f)
  end
end)

K.save("wagon")

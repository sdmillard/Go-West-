-- Swimming ox for floated-wagon crossings (384x24): eight 48x24 frames, swimming right,
-- at the same scale as the 48x32 travel oxen. Only the line of the back, the head and horns
-- show above the water (surface y = 16); the nose is held up and the head heaves with each
-- stroke of the legs. ui/trail_view.gd draws the water itself.
local K = dofile(app.params.kit)
local W, H = 384, 24
local FRAMES = 8
local WL = 16

K.canvas(W, H, 1848)

local function ox(fx, frame)
  local t = (frame - 1) / FRAMES
  local heave = (math.sin(t * 2 * math.pi) > 0) and 0 or 1
  local wl = WL
  -- submerged barrel and paddling legs, seen through the water
  K.rect(fx + 8, wl + 1, 24, 4, "teal")
  local p = frame % 4
  K.line(fx + 28, wl + 4, fx + 31 + ((p < 2) and 3 or -1), wl + 7, "teal")
  K.line(fx + 24, wl + 4, fx + 25 + ((p < 2) and -1 or 3), wl + 7, "teal")
  K.line(fx + 11, wl + 4, fx + 8 + ((p < 2) and -2 or 2), wl + 7, "teal")
  -- the back and the withers hump just clear the surface
  K.rect(fx + 7, wl - 2, 24, 2, "ox_dk"); K.rect(fx + 10, wl - 2, 12, 1, "ox")
  K.rect(fx + 24, wl - 4 + heave, 7, 2, "ox_dk"); K.rect(fx + 25, wl - 4 + heave, 4, 1, "ox")
  K.px(fx + 6, wl - 1, "ox_dk") -- tail head
  -- neck and head held high, muzzle up
  local hx, hy = fx + 32, wl - 9 + heave
  K.poly({{fx + 29, wl - 4 + heave}, {hx + 2, hy + 2}, {hx + 5, hy + 4}, {fx + 34, wl}}, "ox_dk")
  K.rect(hx, hy, 8, 6, "ox"); K.rect(hx, hy, 8, 1, "ox_lt")
  K.rect(hx + 1, hy + 5, 7, 1, "ox_dk")
  K.rect(hx + 8, hy + 1, 3, 4, "ox_dk"); K.rect(hx + 10, hy + 1, 1, 2, "ink"); K.px(hx + 9, hy + 4, "deep")
  K.px(hx + 4, hy + 2, "ink"); K.px(hx + 4, hy + 1, "ox_lt")
  -- horns curving forward and up, and an ear
  K.px(hx + 1, hy - 1, "cream"); K.px(hx, hy - 2, "cream"); K.px(hx + 1, hy - 3, "cream")
  K.px(hx + 5, hy - 1, "cream"); K.px(hx + 6, hy - 2, "cream"); K.px(hx + 6, hy - 3, "cream")
  K.rect(hx - 2, hy + 1, 2, 2, "ox_dk")
  -- surface: a bow wave at the chest and a wake along the back
  for x = fx + 3, fx + 44 do if (x + frame) % 3 ~= 0 then K.px(x, wl, "light_blue") end end
  K.rect(fx + 35, wl - 1, 4, 1, "white"); K.px(fx + 39, wl, "white"); K.px(fx + 37, wl - 2 + heave, "white")
  K.rect(fx + ((frame % 2 == 0) and 1 or 4), wl + 1, 4, 1, "white")
end

K.layer("oxen", function()
  for f = 1, FRAMES do ox((f - 1) * 48, f) end
end)

K.save("swim_ox")

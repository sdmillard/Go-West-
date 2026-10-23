-- Swimming emigrants for river crossings (192x48): three rows of eight 24x16 frames.
-- Row 1 a man with a pack, row 2 a woman in a bonnet, row 3 a swimmer in trouble.
-- All swim to the right. The water surface is y = 10 in each frame; what lies under it is
-- drawn in teal so it reads through clear water. ui/trail_view.gd draws the water itself.
local K = dofile(app.params.kit)
local W, H = 192, 48
local FRAMES = 8
local WL = 10

K.canvas(W, H, 1848)

local function swimmer(fx, fy, frame, kind)
  local t = (frame - 1) / FRAMES
  local wl = fy + WL
  local struggle = kind == 3
  local bob = struggle and math.floor(1.5 + 1.5 * math.sin(t * 4 * math.pi) + 0.5) or ((math.sin(t * 2 * math.pi) > 0.4) and 1 or 0)
  local shirt = (kind == 2) and "red" or "blue"
  -- body and kicking legs under the surface
  K.rect(fx + 4, wl + 1, 11, 2, "teal")
  local kick = (frame % 2 == 0) and 0 or 2
  K.line(fx + 4, wl + 1, fx, wl + kick, "teal"); K.line(fx + 4, wl + 2, fx + 1, wl + 3 - kick, "teal")
  -- back and shoulders breaking the surface
  K.rect(fx + 9, wl - 1 + bob, 7, 1 + (bob > 0 and 0 or 1), shirt)
  if kind == 1 then K.rect(fx + 8, wl - 3 + bob, 5, 2, "wood"); K.rect(fx + 8, wl - 3 + bob, 5, 1, "ochre") end
  -- head
  local hy = wl - 5 + bob
  K.rect(fx + 15, hy, 4, 4, "skin"); K.px(fx + 18, hy + 2, "skin_dk")
  if kind == 2 then
    K.rect(fx + 14, hy - 1, 4, 3, "cream"); K.px(fx + 14, hy + 2, "cream")
  else
    K.rect(fx + 15, hy, 3, 1, "deep"); K.px(fx + 15, hy + 1, "deep")
  end
  -- arms
  local sx, sy = fx + 16, wl - 1 + bob
  if struggle then
    -- one arm thrown up, the other slapping the water
    local wave = (frame % 4 < 2) and 0 or 1
    K.line(sx, sy, sx + 2 + wave, fy + 1 + wave, "skin")
    K.px(sx + 2 + wave, fy + wave, "skin")
    K.rect(fx + 19, wl - 1, 3, 1, "white")
    for i = 0, 2 do K.px(fx + 6 + i * 6 + (frame % 3), wl - 2 - ((frame + i) % 2), "white") end
  else
    -- overarm stroke: the hand circles forward over the water and pulls back under it
    local a = t * 2 * math.pi
    local hx = math.floor(sx + 3 + 4 * math.cos(a) + 0.5)
    local hy2 = math.floor(wl - 1 - 3 * math.sin(a) + 0.5)
    local c = (hy2 >= wl) and "teal" or "skin"
    K.line(sx, sy, hx, hy2, c)
    if math.abs(hy2 - wl) <= 1 then K.px(hx, wl - 1, "white"); K.px(hx + 1, wl - 2, "white") end
  end
  -- the surface line pushed up around the body, and a wake behind
  for x = fx + 3, fx + 21 do
    if (x + frame) % 3 ~= 0 then K.px(x, wl, "light_blue") end
  end
  K.px(fx + 20, wl - 1, "white")
  K.rect(fx + 1 + kick, wl, 3, 1, "white")
end

K.layer("swimmers", function()
  for f = 1, FRAMES do
    for kind = 1, 3 do swimmer((f - 1) * 24, (kind - 1) * 16, f, kind) end
  end
end)

K.save("swimmer")

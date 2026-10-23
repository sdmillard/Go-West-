-- Elder God Encounter Sprite (72x80, transparent background).
-- Drawn in ui/trail_view.gd at (51, 48) when encounter == "elder_god".
local K = dofile(app.params.kit)
local W, H = 72, 80

K.canvas(W, H, 171)

K.layer("elder", function()
  -- Bat-like dorsal wing membranes behind the cephalopod cranium
  K.poly({{14, 24}, {2, 10}, {4, 28}, {1, 38}, {10, 44}, {18, 40}}, "ink")
  K.poly({{14, 25}, {4, 13}, {6, 27}, {3, 36}, {10, 42}, {17, 39}}, "pine")
  K.line(14, 24, 3, 12, "teal")
  K.line(13, 30, 5, 27, "teal")

  K.poly({{57, 24}, {69, 10}, {67, 28}, {70, 38}, {61, 44}, {53, 40}}, "ink")
  K.poly({{57, 25}, {67, 13}, {65, 27}, {68, 36}, {61, 42}, {54, 39}}, "pine")
  K.line(57, 24, 68, 12, "teal")
  K.line(58, 30, 66, 27, "teal")

  -- Seven writhing abyssal tentacles descending from the maw (y = 36..78)
  local roots = {10, 18, 26, 35, 44, 52, 60}
  for i, rx in ipairs(roots) do
    local dir = (i <= 3) and -1 or ((i == 4) and 0 or 1)
    for dy = 0, 38 do
      local t = dy / 38.0
      local wave = math.floor(3.5 * math.sin(t * math.pi * 2.0 + i * 0.9) + dir * t * 5.0)
      local tx = rx + wave
      local ty = 38 + dy
      local w = math.max(1, math.floor(4.5 * (1.0 - t * 0.72)))
      K.rect(tx - w, ty, w * 2 + 1, 1, "ink")
      K.rect(tx - w + 1, ty, math.max(1, w * 2 - 1), 1, "pine")
      if w >= 2 then
        K.rect(tx - w + 1, ty, math.max(1, w - 1), 1, "teal")
      end
      -- Bioluminescent sage suckers along the curling underside
      if dy > 6 and dy % 5 == 0 then
        K.px(tx + ((dir >= 0) and w or -w), ty, "sage")
      end
    end
  end

  -- Bulbous ridged cephalopod cranium (x = 12..59, y = 2..46)
  K.poly({{12, 38}, {11, 20}, {19, 6}, {35, 2}, {52, 7}, {60, 22}, {57, 40}, {43, 48}, {26, 47}}, "ink")
  K.poly({{14, 37}, {13, 20}, {20, 7}, {35, 3}, {51, 8}, {58, 22}, {55, 39}, {42, 46}, {26, 45}}, "pine")
  K.poly({{17, 34}, {16, 20}, {23, 9}, {35, 5}, {48, 10}, {54, 23}, {50, 37}, {39, 43}, {26, 41}}, "teal")
  -- Upper-left eldritch dome highlight & cranial plates
  K.poly({{21, 19}, {27, 10}, {36, 8}, {43, 14}, {33, 23}}, "haze")
  K.poly({{25, 14}, {30, 10}, {35, 10}, {32, 16}}, "mist")
  -- Cranial ridges
  for _, ry in ipairs({15, 20, 25}) do
    K.line(18, ry, 28, ry - 3, "pine")
    K.line(42, ry - 2, 52, ry + 1, "ink")
  end

  -- Brow ridges & burning eldritch golden eyes (primary + secondary lateral eyes)
  K.poly({{19, 26}, {31, 28}, {30, 34}, {21, 32}}, "ink")
  K.poly({{39, 28}, {51, 26}, {49, 32}, {40, 34}}, "ink")
  -- Left primary eye
  K.rect(22, 28, 7, 3, "gold")
  K.rect(23, 29, 5, 2, "cream")
  K.px(25, 29, "white")
  -- Right primary eye
  K.rect(41, 28, 7, 3, "gold")
  K.rect(42, 29, 5, 2, "cream")
  K.px(44, 29, "white")
  -- Smaller secondary lateral eyes
  K.rect(16, 25, 2, 2, "gold"); K.px(16, 25, "white")
  K.rect(52, 25, 2, 2, "gold"); K.px(52, 25, "white")
end)

K.save("elder")

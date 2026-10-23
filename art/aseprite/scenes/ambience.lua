-- Small looping sprites that ui/scene_ambience.gd lays over the location pictures.
--   ambient_smoke  96x24  eight 12x24 frames: a wisp of chimney or cook-fire smoke rising and
--                         drifting east on the breeze. The source is at (6, 23); it loops seamlessly.
--   ambient_flag  112x16  eight 14x8 frames per row, flying from a staff at x = 0:
--                         row 1 the Hudson's Bay Company red ensign (Fort Hall),
--                         row 2 the 1848 United States flag (the American Fur Company at Fort Laramie)
--   ambient_bird   56x5   eight 7x5 frames: a distant bird flapping, then gliding
local K = dofile(app.params.kit)
local FRAMES = 8

K.canvas(96, 24, 1848)
K.layer("smoke", function()
  for f = 1, FRAMES do
    local ox = (f - 1) * 12
    -- a continuous wisp whose wobble travels upward; one wobble period is eight frames
    for rise = 0, 22 do
      local y = 22 - rise
      local cx = ox + 5 + rise / 7 + 1.3 * math.sin(rise / 3.5 - (f - 1) / FRAMES * 2 * math.pi) * math.min(1, rise / 6)
      local r = 0.6 + rise / 12
      for px = ox, ox + 11 do
        local d = math.abs(px + 0.5 - cx)
        if d <= r then
          local thin = (rise > 10 and (px + y + f) % 2 == 1) or (rise > 17 and (px + 2 * y) % 3 ~= 0)
          if not thin then K.px(px, y, (px + 0.5 < cx) and "stone_lt" or "mist") end
        end
      end
    end
  end
end)
K.save("ambient_smoke")

K.canvas(112, 16, 1848)
K.layer("flags", function()
  for f = 1, FRAMES do
    local ox = (f - 1) * 14
    for row = 0, 1 do
      local oy = row * 8
      for x = 0, 12 do
        -- a travelling ripple: the fly end waves more than the hoist
        local wave = math.floor((x / 12) * 1.6 * math.sin((x / 4) - (f - 1) / FRAMES * 2 * math.pi) + 0.5)
        for y = 0, 5 do
          local c
          if row == 0 then
            c = "red"
            if x < 6 and y < 3 then c = ((x == 2) or (y == 1)) and "white" or "blue" end
          else
            c = (y % 2 == 0) and "red" or "white"
            if x < 5 and y < 3 then c = ((x + y) % 2 == 0) and "white" or "blue" end
          end
          local py = oy + 1 + y + wave
          if py >= oy and py < oy + 8 then K.px(ox + 1 + x, py, c) end
        end
      end
      K.px(ox, oy, "wood")
    end
  end
end)
K.save("ambient_flag")

K.canvas(56, 5, 1848)
K.layer("bird", function()
  local wings = {{-2, -1}, {-1, -1}, {0, 0}, {1, 1}, {0, 0}, {-1, 0}, {-1, 0}, {-1, 0}}
  for f = 1, FRAMES do
    local ox = (f - 1) * 7
    local w = wings[f]
    K.px(ox + 3, 2, "ink")
    K.px(ox + 2, 2 + w[2], "ink"); K.px(ox + 4, 2 + w[2], "ink")
    K.px(ox + 1, 2 + w[1], "deep"); K.px(ox + 5, 2 + w[1], "deep")
    if w[1] == -2 then K.px(ox + 1, 1, "deep"); K.px(ox + 5, 1, "deep") end
  end
end)
K.save("ambient_bird")

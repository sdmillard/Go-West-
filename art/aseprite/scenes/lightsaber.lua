-- Found Lightsaber Encounter Sprite (40x16, transparent background).
-- Drawn in ui/trail_view.gd at (83, 120) when encounter == "found_lightsaber".
local K = dofile(app.params.kit)
local W, H = 40, 16

K.canvas(W, H, 197)

K.layer("lightsaber", function()
  -- Subtle translucent ground shadow under the hilt
  K.rect(3, 13, 11, 1, "ground_shadow")

  -- Pommel cap (x = 2..3, y = 7..12)
  K.rect(2, 7, 2, 6, "ink")
  K.rect(2, 8, 2, 3, "mist")
  K.px(2, 8, "white")

  -- Ribbed alloy grip & activation box (x = 4..10, y = 7..12)
  K.rect(4, 7, 7, 6, "ink")
  K.rect(4, 8, 7, 3, "haze")
  K.rect(4, 8, 7, 1, "mist")
  for _, gx in ipairs({5, 7, 9}) do
    K.rect(gx, 8, 1, 4, "ink")
  end
  -- Copper/gold activation switch & brass neck ring
  K.rect(7, 6, 3, 2, "gold")
  K.px(8, 6, "cream")
  K.rect(10, 8, 1, 4, "ochre")
  K.px(10, 8, "gold")

  -- Flared emitter shroud (x = 11..13, y = 6..13)
  K.rect(11, 6, 3, 8, "ink")
  K.rect(11, 7, 2, 6, "sand")
  K.rect(11, 7, 2, 2, "cream")
  K.px(11, 7, "white")

  -- Ignited plasma blade with blue magnetic aura & brilliant white core (x = 13..38, y = 7..12)
  K.rect(13, 7, 24, 6, "blue")
  K.rect(37, 8, 2, 4, "blue")
  K.rect(13, 8, 24, 4, "sky")
  K.rect(37, 9, 2, 2, "sky")
  K.rect(13, 8, 23, 3, "light_blue")
  K.rect(13, 9, 24, 2, "white")
  K.px(37, 9, "light_blue")
end)

K.save("lightsaber")

-- Open Prairie Travel Background (432x150).
-- Composited behind travel_horizon (at y=65) and travel_ground (at y=100) during plains travel,
-- and also visible directly at y=0..80 (sky, clouds, far bluffs).
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 73421)

K.layer("sky", function()
  K.rect(0, 0, W, 18, "blue")
  K.blend(0, 18, W, "blue", "sky_top")
  K.rect(0, 21, W, 18, "sky_top")
  K.blend(0, 39, W, "sky_top", "sky")
  K.rect(0, 42, W, 16, "sky")
  K.blend(0, 58, W, "sky", "light_blue")
  K.rect(0, 61, W, 12, "light_blue")
  K.blend(0, 73, W, "light_blue", "mist")
  K.rect(0, 76, W, 10, "mist")

  K.cloud(28, 22, 1.35)
  K.cloud(116, 41, 0.75)
  K.cloud(182, 16, 1.05)
  K.cloud(314, 24, 1.55)
end)

K.layer("distant_range", function()
  -- Far atmospheric prairie bluffs (periodic across 432px)
  local tau = math.pi * 2.0
  for x = 0, W - 1 do
    local y_far = 66 + math.floor(4 * math.sin(tau * x / 432.0) + 3 * math.cos(tau * x / 144.0 + 0.6))
    for y = y_far, 96 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
    local y_mid = 73 + math.floor(3 * math.cos(tau * x / 216.0) + 2 * math.sin(tau * x / 108.0 + 1.2))
    for y = y_mid, 102 do
      K.px(x, y, (y == y_mid) and "haze" or "teal")
    end
  end
end)

K.layer("prairie_floor", function()
  K.rect(0, 90, W, 60, "sage")
  K.blend(0, 100, W, "sage", "grass")
  K.rect(0, 103, W, 47, "grass")
  for i = 1, 900 do
    local x = K.rnd(W)
    local y = 92 + K.rnd(58)
    K.px(x, y, (i % 3 == 0) and "gold" or ((i % 2 == 0) and "leaf" or "sage"))
  end
  -- Road band for static/fallback consistency
  K.rect(0, 113, W, 26, "ochre")
  K.rect(0, 113, W, 2, "sand")
  K.rect(0, 137, W, 2, "dirt_dk")
end)

K.save("prairie")

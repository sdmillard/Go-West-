-- Little Sandy River Crossing & Parting of the Ways (432x150).
-- Historical reference: 1848 trail context (Sublette Cutoff vs. Fort Bridger route).
-- Shallow high-desert stream winding across the sagebrush plain, with the forking
-- wagon traces and a rustic wooden junction signpost.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184816)

----------------------------------------------------------------- 1. Sky & Distant Wind River Foothills
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  for x = 0, W - 1 do
    local hy = 65 + math.floor(4 * math.sin(tau * x / 432.0 + 0.3) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 88 do
      K.px(x, y, (y == hy) and "mist" or "far_hill")
    end
  end
end)

----------------------------------------------------------------- 2. High Sagebrush Plain & Little Sandy Creek
K.layer("plain_and_stream", function()
  K.rect(0, 86, W, 14, "sage")
  K.dither(0, 96, W, 6, "sage", "grass")
  K.rect(0, 102, W, 48, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Shallow sandy channel of the Little Sandy River winding across the plain
  K.poly({{0, 105}, {165, 94}, {432, 106}, {432, 118}, {162, 107}, {0, 119}}, "sand")
  K.poly({{0, 107}, {165, 96}, {432, 108}, {432, 116}, {162, 105}, {0, 117}}, "sky_top")
  K.poly({{0, 109}, {165, 98}, {432, 110}, {432, 114}, {162, 103}, {0, 115}}, "sky")
  for x = 12, W - 12, 18 do
    local wy = 112 - math.floor(11 * math.sin(math.pi * x / W))
    K.rect(x, wy, 4, 1, (x % 36 == 0) and "white" or "light_blue")
  end

  -- Forking wagon road ("Parting of the Ways"): main Fort Bridger branch + right Sublette Cutoff
  K.poly({{194, 150}, {197, 118}, {262, 92}, {274, 93}, {218, 122}, {222, 150}}, "ochre")
  K.poly({{198, 150}, {201, 118}, {264, 92}, {270, 93}, {214, 122}, {216, 150}}, "gold")
  -- Left fork towards Fort Bridger
  K.poly({{197, 118}, {148, 92}, {158, 92}, {208, 118}}, "ochre")
  K.line(197, 149, 200, 118, "rust")
  K.line(217, 149, 214, 120, "rust")
  K.line(200, 118, 265, 92, "rust")
  K.line(214, 120, 272, 93, "rust")
  K.line(199, 118, 152, 92, "rust")

  for i = 1, 700 do
    local x = K.rnd(W)
    local y = 86 + K.rnd(64)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    elseif cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    end
  end
end)

----------------------------------------------------------------- 3. Fork Signpost & Arriving Wagon
K.layer("signpost_and_wagon", function()
  -- Rustic wooden junction signpost at the fork between the two branches
  K.shadow(186, 120, 8)
  K.rect(189, 108, 2, 12, "wood")
  K.poly({{183, 109}, {191, 109}, {191, 112}, {183, 112}, {181, 110}}, "sand")
  K.poly({{189, 111}, {197, 111}, {199, 112}, {197, 114}, {189, 114}}, "ochre")

  K.wagon(24, 143, 1)
  K.person(82, 142, "blue", "wood", false)
end)

K.save("location_little_sandy")

-- Elm Grove Campground (432x150).
-- Historical reference: Joel Palmer's 1845 journal & 1848 eastern Kansas prairie context.
-- Rolling tallgrass prairie swells, two notable elm trees shading the campground,
-- pitched canvas wedge tent, parked emigrant wagon, grazing oxen, and small cooking fire.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 145)

----------------------------------------------------------------- 1. Sky
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")
  K.blend(0, 73, W, "light_blue", "mist")
  K.rect(0, 76, W, 8, "mist")

  K.cloud(40, 18, 1.35)
  K.cloud(296, 14, 1.45)
end)

----------------------------------------------------------------- 2. Rolling Tallgrass Prairie Hills
K.layer("prairie_hills", function()
  for x = 0, W - 1 do
    local y_far = 66 + math.floor(4 * math.sin(tau * x / 432.0 + 0.3) + 2 * math.cos(tau * x / 144.0))
    for y = y_far, 88 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
    local y_mid = 76 + math.floor(5 * math.cos(tau * x / 432.0 + 0.9) + 2 * math.sin(tau * x / 108.0))
    for y = y_mid, 102 do
      K.px(x, y, (y == y_mid) and "gold" or ((y < y_mid + 5) and "sage" or "grass"))
    end
  end

  -- Shallow prairie swale / creek draw where the two elms stand
  K.poly({{0, 96}, {140, 92}, {290, 95}, {432, 90}, {432, 150}, {0, 150}}, "grass")
  K.dither(0, 92, W, 5, "sage", "grass")
  K.dither(0, 138, W, 12, "grass", "pine")
end)

----------------------------------------------------------------- 3. Trail & Landmark Elm Trees
K.layer("trees_and_trail", function()
  -- Dusty Santa Fe / Oregon Trail branch curving across the campground
  K.poly({{0, 120}, {148, 116}, {302, 113}, {432, 110}, {432, 142}, {296, 145}, {140, 148}, {0, 150}}, "ochre")
  K.poly({{0, 125}, {148, 121}, {302, 118}, {432, 115}, {432, 134}, {296, 137}, {140, 140}, {0, 142}}, "gold")
  for x = 0, W - 1 do
    local top = 120 - math.floor(x * 10 / W)
    local bot = 148 - math.floor(x * 6 / W)
    K.px(x, top, "sand")
    K.px(x, bot, "rust")
    if (x % 16) < 12 then
      K.px(x, top + 8, "rust"); K.px(x, top + 9, "dirt_dk")
      K.px(x, top + 19, "rust"); K.px(x, top + 20, "dirt_dk")
    end
  end

  -- Prairie grass & road pebble texture
  for i = 1, 900 do
    local x = K.rnd(W)
    local y = 84 + K.rnd(66)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    else
      K.px(x, y, (i % 3 == 0) and "sage" or ((i % 2 == 0) and "leaf" or "gold"))
    end
  end

  -- The two Elm Grove trees (a large spreading American elm on the left, smaller companion elm on the right)
  K.shadow(54, 115, 56)
  K.elm(82, 114, 2)
  -- Exposed lower branches where earlier emigrants trimmed limbs for firewood
  K.line(80, 96, 66, 86, "wood")
  K.line(84, 92, 98, 83, "wood")

  K.shadow(320, 101, 28)
  K.elm(334, 100, 1)
end)

----------------------------------------------------------------- 4. Encampment: Tent, Wagon, Oxen & Figures
K.layer("camp", function()
  -- Grazing oxen unhitched in the tallgrass behind the tent
  K.ox(122, 108, 1, "light", true)
  K.ox(362, 107, -1, "red", false)

  -- Pitched canvas wedge tent beside the large elm
  K.tent(174, 122, 24, 30)

  -- Small evening cooking fire & kettle tripod between tent and wagon
  K.shadow(207, 130, 14)
  K.rect(209, 128, 10, 2, "wood")
  K.poly({{212, 128}, {214, 122}, {216, 128}}, "gold")
  K.poly({{213, 128}, {214, 124}, {215, 128}}, "cream")
  K.line(208, 129, 214, 119, "ink")
  K.line(220, 129, 214, 119, "ink")
  K.ellipse(214, 125, 2, 2, "ink")

  -- Emigrant figures tending camp
  K.person(226, 128, "blue", "wood", false)
  K.person(144, 126, "rust", "bonnet", true)

  -- Parked covered wagon on the right
  K.wagon(254, 132, -1)

  -- Foreground tallgrass tufts along the bottom border
  for x = 6, W - 6, 18 do
    local h = 5 + (x % 4)
    K.line(x, 149, x - 1, 149 - h, "pine")
    K.line(x + 2, 149, x + 3, 150 - h, "leaf")
    K.px(x - 1, 148 - h, "gold")
  end
end)

K.save("location_elm_grove")

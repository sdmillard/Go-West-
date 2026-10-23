-- The Great Platte River Valley (432x150).
-- Historical reference: NPS "The Platte Experience" & Joel Palmer's 1845 journal.
-- Broad, flat floodplain with shallow braided channels weaving around sandy shoals
-- and a low wooded island ("Grand Island" character). No mountains or later army posts.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 246)

----------------------------------------------------------------- 1. Wide Prairie Sky & Low Horizon Bluffs
K.layer("sky_and_horizon", function()
  K.sky(W, 76, {{30, 20, 0.85}, {214, 12, 1.25}, {380, 26, 0.7}})

  -- Very low, flat Platte valley horizon bluffs
  for x = 0, W - 1 do
    local hy = 69 + math.floor(2 * math.sin(tau * x / 432.0 + 0.4) + 1.5 * math.cos(tau * x / 144.0))
    for y = hy, 76 do
      K.px(x, y, (y == hy) and "mist" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Braided Channels, Sandbars & Wooded Island
K.layer("braided_platte", function()
  -- Broad sandy floodplain floor (y = 76..136)
  K.rect(0, 76, W, 60, "sand")
  K.dither(0, 76, W, 3, "cream", "sand")

  -- "A mile wide and an inch deep": many shallow channels splitting and rejoining across
  -- the sand, thinner with distance, separated by bars of wet and dry sand.
  local function channel(pts) K.river(K.smooth(pts, 10), false) end
  channel({{-10, 82, 1}, {90, 81, 1.5}, {200, 83, 1}, {330, 80, 1.5}, {440, 81, 1}})
  channel({{-10, 90, 2}, {70, 87, 1.5}, {150, 91, 2.5}, {250, 88, 1.5}, {340, 91, 2}, {440, 87, 1.5}})
  channel({{60, 87, 0.5}, {110, 94, 1.5}, {190, 103, 1}, {260, 103, 1.5}, {300, 100, 0.5}})
  channel({{-10, 113, 4}, {60, 108, 3}, {150, 111, 4.5}, {240, 106, 3}, {330, 109, 4}, {440, 103, 3}})
  channel({{150, 111, 1}, {200, 118, 2}, {270, 117, 1.5}, {320, 112, 1}})
  channel({{-10, 124, 2}, {50, 122, 1.5}, {100, 118, 1}})

  -- Low grassy/sandy mid-river island with cottonwood trees
  K.poly({{150, 97}, {178, 92}, {250, 93}, {290, 97}, {246, 101}, {166, 101}}, "ochre")
  K.poly({{158, 97}, {182, 93}, {246, 94}, {280, 97}, {242, 100}, {170, 100}}, "sage")
  K.poly({{170, 97}, {190, 94}, {238, 95}, {266, 97}, {236, 99}, {180, 99}}, "grass")
  for _, tx in ipairs({184, 204, 236}) do K.willow(tx, 98, 1) end
  K.elm(220, 97, 1)
end)

----------------------------------------------------------------- 3. South Bank Trail & Wagon
K.layer("south_bank", function()
  -- South bank prairie terrace & sandy wagon road (y = 122..150)
  K.poly({{0, 134}, {168, 114}, {320, 120}, {432, 124}, {432, 150}, {0, 150}}, "ochre")
  K.poly({{0, 138}, {172, 120}, {320, 125}, {432, 129}, {432, 150}, {0, 150}}, "grass")
  K.dither(0, 136, W, 4, "ochre", "grass")

  -- Sandy wheel ruts along the Great Platte River Road
  for x = 0, W - 1 do
    local ry = 134 - math.floor(14 * math.sin(math.pi * x / W))
    K.px(x, ry, "dirt_dk"); K.px(x, ry - 1, "gold")
    K.px(x, ry + 6, "dirt_dk"); K.px(x, ry + 5, "gold")
    if K.rnd(3) > 0 then K.px(x, ry + 3, "ochre") end
  end

  -- Sand, pebble & bunchgrass texture
  for i = 1, 750 do
    local x = K.rnd(W)
    local y = 76 + K.rnd(74)
    local cur = K.at(x, y)
    if cur == "sand" or cur == "ochre" then
      K.px(x, y, (i % 3 == 0) and "cream" or ((i % 2 == 0) and "gold" or "rust"))
    elseif cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or "gold")
    end
  end

  -- Emigrant wagon & ox team halted on the south bank overlooking the braided river
  K.wagon(324, 141, -1)
  K.team(282, 141, -1, {"light", true}, {"dark", false})
  K.person(246, 142, "blue", "sand", false)
end)

K.save("location_platte")

-- South Platte River Crossing (432x150).
-- Historical reference: 1848 trail journals (California Crossing / Lower California Crossing).
-- Broad, treeless sandy river with shifting mid-stream quicksand bars where teams had to
-- keep moving continuously so the wheels wouldn't sink.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184807)

----------------------------------------------------------------- 1. Sky & Treeless High-Plains Bluffs
K.layer("sky_and_bluffs", function()
  K.sky(W, 82, {{60, 26, 0.7}, {170, 12, 1.0}, {330, 20, 1.2}})

  for x = 0, W - 1 do
    local y_far = 65 + math.floor(4 * math.sin(tau * x / 432.0 + 0.2) + 2 * math.cos(tau * x / 144.0))
    for y = y_far, 82 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
    local y_mid = 74 + math.floor(3 * math.cos(tau * x / 432.0 + 0.9) + 2 * math.sin(tau * x / 108.0))
    for y = y_mid, 92 do
      K.px(x, y, (y == y_mid) and "gold" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Broad South Platte Channel & Shifting Sandbars
K.layer("river_and_sandbars", function()
  -- The whole bed is sand, half a mile across: a broad shallow sheet of water in braided
  -- runs, bars of wet sand between them where wheels would sink if a team stopped.
  K.poly({{0, 88}, {432, 79}, {432, 136}, {0, 146}}, "sand")
  for i = 1, 700 do K.px(K.rnd(W), 80 + K.rnd(64), (K.rnd(3) == 0) and "cream" or "gold") end
  local function run(pts) K.river(K.smooth(pts, 10), false) end
  run({{-10, 93, 2}, {110, 90, 3}, {240, 88, 2}, {440, 83, 2}})
  run({{-10, 104, 5}, {80, 101, 6}, {180, 105, 4}, {300, 98, 6}, {440, 94, 5}})
  run({{120, 103, 1}, {170, 110, 2}, {240, 112, 3}, {320, 106, 2}, {380, 100, 1}})
  run({{-10, 124, 7}, {90, 118, 6}, {200, 123, 8}, {320, 116, 6}, {440, 111, 7}})
  run({{60, 120, 1}, {120, 130, 2}, {190, 132, 2}, {250, 124, 1}})
  -- wet sand beside the water
  for i = 1, 1500 do
    local x, y = K.rnd(W), 82 + K.rnd(60)
    if K.at(x, y) ~= "sky" and K.at(x, y) ~= "sky_top" and K.at(x, y) ~= "blue" and K.at(x, y) ~= "white" and K.at(x, y) ~= "light_blue" then
      local wet = false
      for _, d in ipairs({-2, 2}) do local c = K.at(x, y + d); if c == "blue" or c == "sky_top" then wet = true end end
      if wet then K.px(x, y, "ochre") end
    end
  end
end)

----------------------------------------------------------------- 3. Near Bank, Ford Approach & Wagon
K.layer("near_bank", function()
  -- Near bank grass & sandy ford ramp
  K.poly({{0, 138}, {432, 128}, {432, 150}, {0, 150}}, "sand")
  K.poly({{0, 141}, {432, 132}, {432, 150}, {0, 150}}, "grass")

  -- Ford approach road cutting diagonally into the river
  K.poly({{188, 126}, {226, 125}, {308, 150}, {234, 150}}, "ochre")
  K.poly({{196, 126}, {218, 125}, {292, 150}, {248, 150}}, "gold")
  K.line(194, 127, 246, 149, "rust")
  K.line(216, 126, 290, 149, "rust")

  for i = 1, 450 do
    local x = K.rnd(W)
    local y = 128 + K.rnd(22)
    local cur = K.at(x, y)
    if cur == "grass" then
      K.px(x, y, (i % 3 == 0) and "sage" or ((i % 2 == 0) and "leaf" or "gold"))
    else
      K.px(x, y, (i % 3 == 0) and "cream" or "rust")
    end
  end

  -- Arriving wagon & driver preparing the team for the wide sandy ford
  K.wagon(24, 143, 1)
  K.team(82, 142, 1, {"light", true}, {"red", false})
  K.person(118, 141, "blue", "sand", false)
end)

K.save("location_south_platte")

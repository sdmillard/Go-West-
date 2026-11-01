-- River Corridor Travel Background (432x150).
-- Used when approaching river crossings along the trail.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 73422)
K.wrap = true

----------------------------------------------------------------- 1. Sky
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
end)

K.layer("clouds", function()
  K.cloud(32, 20, 1.3)
  K.cloud(168, 15, 1.0)
  K.cloud(308, 23, 1.5)
end)

----------------------------------------------------------------- 2. Distant Bluffs & Braided River Valley
K.layer("river_valley", function()
  for x = 0, W - 1 do
    local y_far = 61 + math.floor(4 * math.sin(tau * x / 432.0 + 0.5) + 3 * math.cos(tau * x / 144.0))
    for y = y_far, 90 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
  end

  -- Braided river channel glinting across the upper valley (y = 70..88)
  K.rect(0, 70, W, 2, "sand")
  K.rect(0, 72, W, 16, "sky")
  K.rect(0, 72, W, 2, "sky_top")
  -- Horizontal water ripples & glints (instead of uniform point noise)
  for y = 73, 87 do
    for x = 0, W - 1, 9 do
      local rx = (x + y * 5) % W
      if (x + y) % 3 == 0 then
        K.rect(rx, y, 3 + (y % 3), 1, (y % 4 == 0) and "white" or "light_blue")
      elseif (x + y) % 5 == 0 then
        K.rect(rx, y, 2, 1, "sky_top")
      end
    end
  end

  -- Wooded cottonwood islands & braided sandbars
  K.poly({{52, 79}, {112, 76}, {154, 80}, {118, 83}, {48, 81}}, "sand")
  K.poly({{60, 78}, {108, 75}, {142, 79}, {66, 80}}, "sage")
  K.poly({{262, 81}, {338, 77}, {386, 81}, {332, 84}, {258, 83}}, "sand")
  K.poly({{274, 80}, {332, 76}, {372, 80}, {278, 82}}, "sage")
  -- Subtle water shadow under the sandbars
  K.rect(52, 82, 96, 1, "sky_top")
  K.rect(262, 84, 118, 1, "sky_top")
end)

----------------------------------------------------------------- 3. Textured Prairie Bank, Trail & Foreground River Bend
K.layer("prairie_and_channel", function()
  K.rect(0, 88, W, 12, "sage")
  K.dither(0, 96, W, 6, "sage", "grass")
  K.rect(0, 102, W, 48, "grass")

  -- Textured prairie road leading toward the river ford
  K.rect(0, 112, W, 1, "sand")
  K.rect(0, 113, W, 26, "ochre")
  K.rect(0, 124, W, 4, "gold")
  K.rect(0, 139, W, 1, "rust")
  for x = 0, W - 1, 16 do
    K.rect(x, 121, 11, 1, "rust")
    K.rect(x + 3, 132, 11, 1, "rust")
  end

  for i = 1, 650 do
    local x = K.rnd(W)
    local y = 88 + K.rnd(62)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    else
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end

  -- Sandy/gravelly river bank & ford margin curving in on the right
  K.poly({{340, 88}, {358, 99}, {340, 112}, {314, 125}, {282, 150}, {432, 150}, {432, 88}}, "sand")
  K.poly({{344, 88}, {362, 99}, {344, 112}, {318, 125}, {286, 150}, {432, 150}, {432, 88}}, "ochre")
  -- Foreground river channel
  K.poly({{348, 88}, {366, 99}, {348, 112}, {322, 125}, {292, 150}, {432, 150}, {432, 88}}, "blue")
  K.poly({{353, 88}, {370, 99}, {353, 112}, {327, 125}, {297, 150}, {432, 150}, {432, 88}}, "sky_top")
  K.poly({{358, 88}, {375, 99}, {358, 112}, {332, 125}, {303, 150}, {432, 150}, {432, 88}}, "sky")

  -- Ripples & foam wakes in the foreground river channel
  for i = 1, 75 do
    local y = 90 + K.rnd(58)
    local min_x = math.max(302, 360 - math.floor((y - 90) * 0.92))
    local x = min_x + K.rnd(math.max(1, 426 - min_x))
    K.rect(x, y, 3 + K.rnd(6), 1, (i % 4 == 0) and "white" or ((i % 2 == 0) and "light_blue" or "sky_top"))
  end

  -- Riparian sedges & cattail reeds along the water's edge
  for _, pt in ipairs({{346, 92}, {360, 102}, {342, 114}, {324, 124}, {306, 136}, {292, 146}}) do
    for dx = -4, 2, 2 do
      K.line(pt[1] + dx, pt[2], pt[1] + dx - 1, pt[2] - 5, "pine")
      K.px(pt[1] + dx - 1, pt[2] - 6, "leaf")
    end
  end
end)

-- winter: the road is trodden to mud through the snow
K.season_extra = {
  {season="winter", y0=100, y1=150, map={ochre="silt", gold="silt_lt", sand="stone_lt", rust="silt_dk", leaf="white"}},
}
K.save("river")
K.save_layers({sky = "river_sky", clouds = "river_clouds", river_valley = "river_far", prairie_and_channel = "river_floor"})

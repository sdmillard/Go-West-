-- Upper North Platte River Crossing (432x150).
-- Historical reference: 1848 trail journals (Mormon Ferry / Deer Creek / Red Buttes).
-- Swift mountain-fed river channel bordered by sagebrush hills and reddish sandstone bluffs.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184812)

----------------------------------------------------------------- 1. Sky & Upper Platte Bluffs
K.layer("sky_and_bluffs", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(40, 16, 1.35)
  K.cloud(300, 14, 1.4)

  -- Distant Casper Mountain / Laramie range silhouette
  for x = 0, W - 1 do
    local y_far = 56 + math.floor(5 * math.sin(tau * x / 432.0 + 0.3) + 3 * math.cos(tau * x / 144.0))
    for y = y_far, 78 do
      K.px(x, y, (y == y_far) and "mist" or "far_hill")
    end
  end

  -- Rolling sagebrush hills & Red Buttes sandstone escarpments along the north shore
  K.poly({{0, 74}, {102, 63}, {178, 79}, {264, 65}, {356, 74}, {432, 68}, {432, 92}, {0, 96}}, "sage")
  local function red_butte(cx, top_y, base_y, top_w, base_w)
    for y = top_y, base_y do
      local t = (y - top_y) / math.max(1, base_y - top_y)
      local hw = math.floor(top_w + t * (base_w - top_w))
      for x = cx - hw, cx + hw do
        local lit = (x <= cx)
        local c = lit and "ochre" or "rust"
        if y == top_y then c = "sand" elseif y % 4 == 0 then c = lit and "sand" or "ochre" end
        if y < base_y or ((x + y) % 2 == 0) then K.px(x, y, c) end
      end
    end
  end
  red_butte(102, 62, 78, 16, 34)
  red_butte(264, 64, 78, 14, 30)
end)

----------------------------------------------------------------- 2. Swift North Platte Channel
K.layer("river", function()
  -- Far gravel bank
  K.poly({{0, 90}, {432, 80}, {432, 84}, {0, 94}}, "sand")

  -- Deep swift mountain-fed channel (48px wide)
  K.poly({{0, 93}, {432, 82}, {432, 130}, {0, 141}}, "blue")
  K.poly({{0, 96}, {432, 85}, {432, 126}, {0, 137}}, "sky_top")
  K.poly({{0, 101}, {432, 90}, {432, 120}, {0, 131}}, "sky")

  -- Swift current riffles & foam wakes (randomized)
  for i = 1, 95 do
    local rx = 6 + K.rnd(W - 16)
    local ry = 85 + K.rnd(52)
    local cur = K.at(rx, ry)
    if cur == "sky" or cur == "sky_top" or cur == "blue" then
      K.rect(rx, ry, 4 + (i % 4), 1, (i % 3 == 0) and "white" or "light_blue")
    end
  end
end)

----------------------------------------------------------------- 3. Near Bank, Trail & Wagon
K.layer("near_bank", function()
  K.poly({{0, 138}, {432, 127}, {432, 150}, {0, 150}}, "sand")
  K.poly({{0, 141}, {432, 131}, {432, 150}, {0, 150}}, "grass")

  -- Diagonal wagon road approaching the crossing
  K.poly({{196, 126}, {228, 125}, {304, 150}, {236, 150}}, "ochre")
  K.poly({{202, 126}, {220, 125}, {290, 150}, {248, 150}}, "gold")
  K.line(200, 127, 246, 149, "rust")
  K.line(218, 126, 288, 149, "rust")

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

  K.wagon(24, 143, 1)
  K.person(82, 142, "blue", "wood", false)
end)

K.save("location_north_platte")

-- Green River Crossing (432x150).
-- Historical reference: 1848 trail journals (Lombard / Mormon Ferry & Names Hill).
-- Deep, swift emerald-teal river channel bordered by stratified Green River shale bluffs
-- and groves of river-bottom cottonwoods.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184817)

----------------------------------------------------------------- 1. Sky & Stratified Green River Shale Bluffs
K.layer("sky_and_bluffs", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 20, "light_blue")

  K.cloud(40, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Flat-topped stratified Green River shale/sandstone bluffs along the far horizon
  for x = 0, W - 1 do
    local by = 58 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 3 * math.cos(tau * x / 144.0))
    for y = by, 84 do
      local c = "clap_sh"
      if y == by then
        c = "cream"
      elseif y % 4 == 0 then
        c = "sand"
      elseif y % 4 == 2 then
        c = "ochre"
      end
      K.px(x, y, c)
    end
  end

  -- Sagebrush river bench & cottonwood groves along the far bank
  K.poly({{0, 80}, {180, 76}, {432, 72}, {432, 92}, {0, 96}}, "sage")
  for _, tx in ipairs({24, 56, 348, 392}) do
    K.elm(tx, 89, 1)
  end
end)

----------------------------------------------------------------- 2. Emerald-Teal Green River Channel
K.layer("green_river", function()
  -- Fill entire lower canvas so no transparent pixels can ever occur
  K.rect(0, 80, W, 70, "pine")

  -- Far gravel shoreline
  K.poly({{0, 91}, {432, 80}, {432, 83}, {0, 94}}, "sand")

  -- Deep swift emerald-teal river channel
  K.poly({{0, 93}, {432, 82}, {432, 142}, {0, 150}}, "pine")
  K.poly({{0, 96}, {432, 85}, {432, 138}, {0, 147}}, "teal")
  K.poly({{0, 102}, {432, 91}, {432, 130}, {0, 139}}, "far_hill")

  -- Swirling green-water eddies & whitewater riffles (randomized so no diagonal columns)
  for i = 1, 110 do
    local rx = 6 + K.rnd(W - 16)
    local ry = 86 + K.rnd(58)
    local cur = K.at(rx, ry)
    if cur == "teal" or cur == "far_hill" then
      K.rect(rx, ry, 4 + (i % 4), 1, (i % 3 == 0) and "white" or "mist")
    end
  end
end)

----------------------------------------------------------------- 3. Near Sandy Landing Bank & Wagon
K.layer("near_bank", function()
  -- Near bank extending all the way across the bottom edge (wider on the left landing)
  K.poly({{0, 126}, {96, 129}, {178, 144}, {432, 138}, {432, 150}, {0, 150}}, "sand")
  K.poly({{0, 130}, {90, 133}, {172, 146}, {432, 141}, {432, 150}, {0, 150}}, "ochre")
  K.poly({{0, 136}, {72, 139}, {148, 150}, {0, 150}}, "grass")

  for i = 1, 350 do
    local x = K.rnd(W)
    local y = 128 + K.rnd(22)
    local cur = K.at(x, y)
    if cur == "grass" then
      K.px(x, y, (i % 2 == 0) and "sage" or "gold")
    elseif cur == "sand" or cur == "ochre" then
      K.px(x, y, (i % 2 == 0) and "cream" or "rust")
    end
  end

  -- Mooring stake & arriving emigrant wagon on the left bank
  K.rect(108, 132, 2, 9, "wood")
  K.wagon(24, 143, 1)
  K.person(84, 141, "blue", "sand", false)
end)

K.save("location_green_river")

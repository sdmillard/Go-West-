-- Parallax Scrolling Horizon Layer (432x50, seamless horizontal tile).
-- Drawn at y=65 in ui/trail_view.gd over prairie.png / river.png.
-- Top pixels above the ridge line stay transparent so the sky and far bluffs show through.
local K = dofile(app.params.kit)
local W, H = 432, 50
local tau = math.pi * 2.0

K.canvas(W, H, 973)

K.layer("horizon", function()
  for x = 0, W - 1 do
    -- Seamless periodic hill profiles (matching at x=0 and x=432)
    local h_back = 12 + math.floor(4 * math.sin(tau * x / 432.0) + 3 * math.cos(tau * x / 216.0) + 1.5 * math.sin(tau * x / 108.0))
    local h_mid  = 21 + math.floor(3 * math.cos(tau * x / 432.0 + 0.8) + 2 * math.sin(tau * x / 144.0))

    -- Distant teal ridge with sunlit sage/haze upper-left crest
    local slope_back = math.cos(tau * x / 432.0)
    for y = h_back, H - 1 do
      local c = "teal"
      if y == h_back then
        c = (slope_back > 0) and "haze" or "teal"
      elseif y < h_back + 3 and slope_back > 0.15 then
        c = "sage"
      elseif y > h_back + 5 then
        c = "pine"
      end
      K.px(x, y, c)
    end

    -- Rolling mid-distance prairie hills in sage & grass
    local slope_mid = -math.sin(tau * x / 432.0 + 0.8)
    for y = h_mid, H - 1 do
      local c = "sage"
      if y == h_mid and slope_mid > 0 then
        c = "gold"
      elseif y >= h_mid + 7 and y <= h_mid + 10 then
        c = ((x + y) % 2 == 0) and "grass" or "sage"
      elseif y > h_mid + 10 then
        c = "grass"
      end
      K.px(x, y, c)
    end
  end

  -- Distant creek-bottom cottonwood/elm copses tucked into the valleys
  for _, tx in ipairs({28, 36, 152, 162, 170, 294, 304, 398}) do
    local ty = 22 + (tx % 3)
    K.ellipse(tx, ty, 4, 3, "pine")
    K.ellipse(tx - 1, ty - 1, 3, 2, "leaf")
    K.px(tx - 2, ty - 2, "sage")
  end

  -- Prairie bunchgrass & wildflower texture across the lower hillside (y = 28..49)
  for i = 1, 360 do
    local x = K.rnd(W)
    local y = 28 + K.rnd(22)
    local c = (i % 4 == 0) and "gold" or ((i % 3 == 0) and "leaf" or "grass")
    K.px(x, y, c)
    if x + 1 < W and i % 2 == 0 then K.px(x + 1, y, "grass") end
  end
end)

-- the wooded ridge (teal over pine) greys under snow and turns with the grass in autumn
K.season_extra = {
  {season="winter", map={teal="stone", pine="stone_dk"}},
  {season="autumn", region="plains", map={teal="silt", pine="silt_dk"}},
  {season="autumn", region="tallgrass", map={teal="rust", pine="brick"}},
}
K.save("travel_horizon")

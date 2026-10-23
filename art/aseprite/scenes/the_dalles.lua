-- The Dalles of the Columbia River (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Broad, deep-blue Columbia River constricted by dark volcanic basalt rock reefs
-- and islands with whitewater rapids foaming around their bases, where emigrants had to
-- choose between rafting the Columbia Gorge or taking the Barlow Road over Mount Hood.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184830)

----------------------------------------------------------------- 1. Sky & Columbia River Gorge Cliffs
K.layer("sky_and_gorge", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  -- Columbia Gorge basalt palisades along the Washington north shore
  for x = 0, W - 1 do
    local by = 58 + math.floor(4 * math.sin(tau * x / 432.0 + 0.3) + 2 * math.cos(tau * x / 144.0))
    for y = by, 78 do
      local c = (y == by) and "mist" or ((y < by + 6) and "far_hill" or "teal")
      K.px(x, y, c)
    end
    local cy = 70 + math.floor(3 * math.cos(tau * x / 432.0 + 0.8))
    for y = cy, 92 do
      K.px(x, y, (y == cy) and "gold" or "sage")
    end
  end
end)

----------------------------------------------------------------- 2. Columbia River & Basalt Reef Islands
K.layer("columbia_river", function()
  -- Fill lower canvas so no transparent pixels can occur
  K.rect(0, 82, W, 68, "blue")

  -- Far gravel bank
  K.poly({{0, 91}, {432, 80}, {432, 83}, {0, 94}}, "sand")

  -- Wide, deep Columbia River channel (62px wide)
  K.poly({{0, 93}, {432, 82}, {432, 144}, {0, 150}}, "blue")
  K.poly({{0, 97}, {432, 86}, {432, 139}, {0, 148}}, "sky_top")
  K.poly({{0, 103}, {432, 92}, {432, 132}, {0, 142}}, "sky")

  -- Jagged dark volcanic basalt reefs jutting out of the Columbia rapids (varied heights & widths)
  local reefs = {
    {15, 89, 28},
    {68, 92, 24},
    {116, 88, 30},
    {169, 91, 26},
    {220, 87, 31},
    {272, 93, 25},
    {322, 89, 29},
    {374, 91, 27},
  }
  for _, rf in ipairs(reefs) do
    local x, peak_y, rw = rf[1], rf[2], rf[3]
    local px_top = x + math.floor(rw * 0.36)
    local sh_x   = x + math.floor(rw * 0.78)
    -- Shaded right basalt cliff
    K.poly({{x, 118}, {px_top, peak_y}, {sh_x, peak_y + 14}, {x + rw, 126}, {x - 2, 126}}, "deep")
    -- Sunlit upper-left basalt facet
    K.poly({{x, 118}, {px_top, peak_y}, {px_top + 4, peak_y + 15}, {px_top + 2, 125}, {x - 2, 125}}, "wood")
    -- Horizontal basalt ledge fissures (clipped within rock width at ly)
    for ly = peak_y + 10, 122, 6 do
      local t = (ly - peak_y) / (125.0 - peak_y)
      local lx = x + math.floor((1.0 - t) * (px_top - x)) + 2
      local rx = px_top + math.floor(t * (x + rw - px_top)) - 3
      if rx > lx then
        K.rect(lx, ly, rx - lx, 1, "ink")
      end
    end
    K.line(x, 118, px_top, peak_y, "ochre")
    -- Foaming whitewater collar & standing waves crashing against the basalt reef
    K.rect(x - 3, 124, rw + 5, 2, "white")
    K.rect(x + 1, 126, rw - 1, 1, "light_blue")
  end

  -- Current eddies & rapids across the channel
  for i = 1, 85 do
    local rx = 6 + K.rnd(W - 16)
    local ry = 86 + K.rnd(56)
    local cur = K.at(rx, ry)
    if cur == "blue" or cur == "sky_top" or cur == "sky" then
      K.rect(rx, ry, 4 + (i % 4), 1, (i % 3 == 0) and "white" or "light_blue")
    end
  end
end)

----------------------------------------------------------------- 3. Sandy Boat Landing & Arriving Wagon
K.layer("landing_and_wagon", function()
  -- Sandy boat/raft landing beach on the lower left & southern shore
  K.poly({{0, 126}, {148, 125}, {204, 150}, {0, 150}}, "sand")
  K.poly({{0, 130}, {142, 128}, {192, 150}, {0, 150}}, "ochre")
  K.poly({{190, 144}, {432, 138}, {432, 150}, {190, 150}}, "sand")

  -- Timber logs lashed into a river raft at the water's edge (x = 112..148, y = 123..128)
  for lx = 114, 142, 4 do
    K.rect(lx, 123, 3, 6, "wood")
    K.px(lx, 123, "sand")
  end
  K.rect(112, 125, 34, 1, "deep")

  K.wagon(24, 143, 1)
  K.person(84, 141, "blue", "sand", false)
end)

K.save("location_the_dalles")

-- Wakarusa River Crossing (432x150).
-- Historical reference: NPS Bluejacket Crossings of the Wakarusa River archival photo.
-- Wooded ravine channel enclosed by irregular horizontal limestone ledges & shelves,
-- overhanging bur oaks/elms, shallow rocky riffle ford, and emigrant wagon on the left bank.
-- No later bridge, ferry, or inn is shown.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 248)

----------------------------------------------------------------- 1. Sky & Ravine Canopy
K.layer("sky_and_woods", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 14, "light_blue")

  K.cloud(48, 17, 1.3)
  K.cloud(304, 13, 1.4)

  -- Dense riparian woodland enclosing the Wakarusa valley
  for x = 0, W - 1 do
    local wy = 54 + math.floor(4 * math.sin(x * 0.04) + 3 * math.cos(x * 0.09))
    for y = wy, 78 do
      K.px(x, y, (y < wy + 3) and "sage" or ((y < wy + 9) and "leaf" or "pine"))
    end
  end
  K.rect(0, 74, W, 76, "leaf")
  K.dither(0, 72, W, 6, "pine", "leaf")
end)

----------------------------------------------------------------- 2. Wakarusa Creek Channel & Riffles
K.layer("channel", function()
  -- Deep shaded creek water flowing from upper center-left toward lower center-right
  K.poly({{126, 68}, {218, 70}, {272, 102}, {296, 150}, {94, 150}, {148, 102}}, "blue")
  K.poly({{134, 68}, {210, 70}, {262, 102}, {284, 150}, {106, 150}, {156, 102}}, "sky_top")
  K.poly({{144, 68}, {200, 70}, {248, 102}, {268, 150}, {122, 150}, {166, 102}}, "sky")

  -- Shallow limestone riffle bars & whitewater foam across the ford (y = 104..132)
  for y = 72, 148, 2 do
    local t = (y - 72) / 76.0
    local lx = math.floor(134 - t * 26)
    local rx = math.floor(210 + t * 72)
    local is_ford = (y >= 106 and y <= 128)
    local step = is_ford and 13 or 19
    for x = lx + 6, rx - 8, step do
      local wx = x + ((y * 7 + x * 3) % 9) - 4
      if wx > lx + 3 and wx < rx - 6 then
        K.rect(wx, y, is_ford and (3 + (y % 3)) or 2, 1, is_ford and "white" or "light_blue")
        if is_ford and ((wx + y) % 3 == 0) then
          K.rect(wx + 1, y + 1, 2, 1, "sand") -- submerged limestone cobbles at the ford
        end
      end
    end
  end
end)

----------------------------------------------------------------- 3. Stepped Horizontal Limestone Ledges
K.layer("limestone_banks", function()
  -- Left & right banks built from irregular, stratified horizontal limestone shelves
  for y = 74, 144, 8 do
    local t = (y - 74) / 70.0
    -- Left bank ledges stepping down toward the creek
    local l_edge = math.floor(136 - t * 32 + 6 * math.sin(y * 0.35))
    K.poly({
      {0, y},
      {l_edge - 4, y},
      {l_edge + 4, y + 3},
      {l_edge - 2, y + 7},
      {0, y + 7}
    }, "sand")
    -- Sunlit upper limestone cap & horizontal bedding joint
    K.rect(0, y, math.max(1, l_edge - 4), 1, "cream")
    K.rect(0, y + 3, math.max(1, l_edge), 2, "ochre")
    K.rect(0, y + 5, math.max(1, l_edge - 2), 2, "wood")
    K.rect(0, y + 7, math.max(1, l_edge - 4), 1, "deep")
    -- Vertical limestone fracture joints
    for jx = 18 + (y % 11), l_edge - 8, 22 do
      K.rect(jx, y + 1, 1, 6, "wood")
      K.px(jx + 1, y + 1, "cream")
    end

    -- Right bank ledges in deeper afternoon shade
    local r_edge = math.floor(214 + t * 72 + 5 * math.cos(y * 0.4))
    K.poly({
      {r_edge, y},
      {W, y},
      {W, y + 7},
      {r_edge - 5, y + 7},
      {r_edge - 2, y + 3}
    }, "ochre")
    K.rect(r_edge, y, W - r_edge, 1, "sand")
    K.rect(r_edge - 2, y + 3, W - r_edge + 2, 2, "rust")
    K.rect(r_edge - 4, y + 5, W - r_edge + 4, 2, "wood")
    K.rect(r_edge - 5, y + 7, W - r_edge + 5, 1, "deep")
    for jx = r_edge + 12 + (y % 9), W - 10, 24 do
      K.rect(jx, y + 1, 1, 6, "deep")
    end
  end

  -- Notched dirt-and-gravel wagon cut descending the left bank to the water's edge
  K.poly({{48, 118}, {86, 118}, {132, 138}, {96, 144}}, "ochre")
  K.line(52, 120, 124, 138, "rust")
  K.line(68, 119, 130, 136, "sand")

  -- Moss, leaf litter & grass tufts on top of the limestone shelves
  for x = 0, 118, 4 do
    K.rect(x, 73 + (x % 3), 3, 2, (x % 8 == 0) and "grass" or "leaf")
  end
  for x = 226, W - 4, 4 do
    K.rect(x, 73 + (x % 3), 3, 2, (x % 8 == 0) and "sage" or "pine")
  end
end)

----------------------------------------------------------------- 4. Overhanging Oaks, Elms & Waiting Wagon
K.layer("trees_and_wagon", function()
  -- Back-rank ravine trees
  for _, tx in ipairs({98, 138, 252, 308}) do
    K.elm(tx, 76, 1)
  end
  -- Large overhanging bur oaks / elms framing left and right limestone bluffs
  K.elm(34, 96, 2)
  K.elm(376, 94, 2)

  -- Emigrant wagon halted on the upper left bank while driver scouts the steep limestone notch
  K.wagon(12, 124, 1)
  K.person(82, 126, "blue", "wood", false)
end)

K.save("location_wakarusa")

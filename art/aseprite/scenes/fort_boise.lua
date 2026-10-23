-- Old Fort Boise at the Boise & Snake River Confluence (432x150).
-- Historical reference: NPS old-post account & WESTERN_REFERENCES.md.
-- Depicts the Hudson's Bay Company adobe trading post near the Boise/Snake river confluence.
-- The 1863 military Fort Boise complex is explicitly omitted.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184822)

----------------------------------------------------------------- 1. Desert Sky & Distant Owyhee Bluffs
K.layer("sky_and_bluffs", function()
  K.rect(0, 0, W, 16, "sky_top")
  K.blend(0, 16, W, "sky_top", "sky")
  K.rect(0, 19, W, 18, "sky")
  K.blend(0, 37, W, "sky", "light_blue")
  K.rect(0, 40, W, 16, "light_blue")
  K.blend(0, 56, W, "light_blue", "sand")
  K.rect(0, 59, W, 30, "sand")

  K.cloud(42, 16, 1.35)
  K.cloud(304, 14, 1.4)

  for x = 0, W - 1 do
    local by = 60 + math.floor(5 * math.sin(tau * x / 432.0 + 0.4) + 3 * math.cos(tau * x / 144.0))
    for y = by, 88 do
      local c = "rust"
      if y == by then
        c = "sand"
      elseif y % 5 == 0 then
        c = "ochre"
      elseif y % 5 == 2 then
        c = "wood"
      end
      K.px(x, y, c)
    end
  end
end)

----------------------------------------------------------------- 2. Snake & Boise River Confluence & Desert Plain
K.layer("confluence_and_plain", function()
  -- Sun-baked alkali & sand plain
  K.rect(0, 86, W, 64, "sand")
  K.dither(0, 86, W, 4, "ochre", "sand")

  -- Broad Snake River channel sweeping behind and right of the post
  K.poly({{0, 102}, {197, 105}, {432, 78}, {432, 98}, {216, 125}, {0, 122}}, "sky_top")
  K.poly({{0, 104}, {197, 107}, {432, 80}, {432, 96}, {216, 123}, {0, 120}}, "sky")

  -- Boise River branch joining from the foreground
  K.poly({{244, 150}, {218, 112}, {236, 110}, {272, 150}}, "blue")
  K.poly({{248, 150}, {221, 112}, {232, 110}, {268, 150}}, "sky_top")

  for i = 1, 55 do
    local rx = 8 + K.rnd(W - 18)
    local ry = 80 + K.rnd(68)
    local cur = K.at(rx, ry)
    if cur == "sky" or cur == "sky_top" or cur == "blue" then
      K.rect(rx, ry, 4 + (i % 3), 1, (i % 3 == 0) and "white" or "light_blue")
    end
  end

  -- Desert sagebrush & trail texture
  for i = 1, 600 do
    local x = K.rnd(W)
    local y = 88 + K.rnd(62)
    local cur = K.at(x, y)
    if cur == "sand" then
      K.px(x, y, (i % 4 == 0) and "sage" or ((i % 2 == 0) and "ochre" or "cream"))
    end
  end
  for _, sx in ipairs({36, 124, 168, 318, 366, 408}) do
    local sy = 128 + (sx % 15)
    K.ellipse(sx, sy, 5, 1, "sage")
    K.px(sx - 1, sy - 1, "leaf")
  end
end)

----------------------------------------------------------------- 3. Old Fort Boise Adobe Quadrangle
K.layer("fort_boise", function()
  K.shadow(100, 106, 210)

  -- Main buff adobe curtain wall (x = 113..296, y = 68..104)
  K.rect(113, 68, 183, 36, "sand")
  K.rect(113, 68, 183, 2, "cream")
  for row = 73, 101, 5 do
    K.rect(113, row, 183, 1, "ochre")
    for col = 118 + ((row % 10 == 0) and 5 or 0), 290, 11 do
      K.rect(col, row - 4, 1, 4, "clap_sh")
    end
  end
  for vx = 120, 288, 9 do
    K.rect(vx, 72, 2, 2, "wood")
  end

  -- Left corner adobe bastion (x = 102..128, y = 57..106)
  K.rect(102, 57, 26, 49, "ochre")
  K.rect(102, 57, 13, 49, "sand")
  K.rect(101, 55, 28, 3, "wood")
  K.rect(101, 55, 28, 1, "gold")
  for row = 62, 102, 6 do
    K.rect(102, row, 13, 1, "ochre")
    K.rect(115, row, 13, 1, "rust")
  end
  K.rect(108, 65, 2, 5, "deep"); K.rect(118, 65, 2, 5, "deep")

  -- Right corner adobe bastion (x = 281..307, y = 59..106)
  K.rect(281, 59, 26, 47, "sand")
  K.rect(294, 59, 13, 47, "ochre")
  K.rect(280, 57, 28, 3, "wood")
  K.rect(280, 57, 28, 1, "gold")
  for row = 64, 102, 6 do
    K.rect(281, row, 13, 1, "ochre")
    K.rect(294, row, 13, 1, "rust")
  end
  K.rect(287, 67, 2, 5, "deep"); K.rect(297, 67, 2, 5, "deep")

  -- Central Fort Boise entrance gate
  K.rect(194, 82, 20, 22, "wood")
  K.rect(192, 80, 24, 2, "deep")
  K.rect(197, 84, 14, 20, "deep")
  K.rect(199, 85, 10, 19, "ink")
end)

----------------------------------------------------------------- 4. Foreground Wagon
K.layer("wagon", function()
  K.wagon(24, 143, 1)
  K.person(84, 142, "blue", "sand", false)
end)

K.save("location_fort_boise")

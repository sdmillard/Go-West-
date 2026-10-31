-- Salmon Falls of the Snake (432x150).
-- Here the Snake runs in a deep canyon of dark basalt and drops over a series of low falls and
-- rapids where the salmon crowd. Shoshone families came every summer to spear and trap them
-- and dry them on racks; emigrants came down to trade for fresh and dried salmon. Willow
-- brush shelters stand by the racks. Original composition, everyday fishing work.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184890)

local function rack(x, y, w)
  K.rect(x, y - 14, 1, 14, "wood"); K.rect(x + w, y - 14, 1, 14, "wood"); K.rect(x + w // 2, y - 14, 1, 14, "wood")
  for _, yy in ipairs({y - 13, y - 8}) do
    K.rect(x, yy, w + 1, 1, "deep")
    for xx = x + 1, x + w - 1, 3 do K.rect(xx, yy + 1, 2, 4, "brick_lt"); K.px(xx, yy + 1, "red") end
  end
end
local function brush_lodge(x, y)
  K.ellipse(x, y - 6, 9, 7, "ochre"); K.rect(x - 10, y - 1, 21, 2, "ochre")
  for i = -8, 8, 2 do K.line(x + i, y, x + i // 2, y - 12, (i % 4 == 0) and "wood" or "silt") end
  K.rect(x - 2, y - 6, 5, 6, "deep")
end

K.layer("sky", function()
  K.sky(W, 52, {{80, 8, 0.6}, {300, 14, 0.8}}, "mist")
end)

K.layer("canyon", function()
  -- the far wall: a broken basalt rim over steep talus fans, deep in shadow
  local rim = function(x) return 44 + math.floor(4 * math.sin(x / 23) + 3 * math.sin(x / 9 + 1)) end
  for x = 0, W - 1 do
    local r = rim(x)
    for y = r, 96 do
      local h = (x * 73 + y * 151 + (x // 3) * 37) % 13
      local c
      if y < r + 2 then c = "rust"
      elseif y < r + 22 + (x * 5) % 4 then c = (h == 0 and "ink") or (h < 4 and "roof_dk") or ((x % 4 == 0) and "roof_dk") or "roof"
      else c = (h < 3 and "stone_dk") or (h < 6 and "silt_dk") or (h == 12 and "roof") or "silt" end
      K.px(x, y, c)
    end
  end
  -- talus fans spilling from gullies in the rim
  for _, f in ipairs({{40, 18}, {130, 24}, {230, 16}, {330, 22}, {410, 14}}) do
    K.line(f[1], 48, f[1], 66, "ink")
  end
  for i = 1, 200 do local x, y = K.rnd(W), 70 + K.rnd(26); K.px(x, y, ({"stone_dk", "roof", "sage", "silt_dk"})[i % 4 + 1]) end
end)

K.layer("river", function()
  -- the river and its falls: a step of white water across the channel
  K.rect(0, 96, W, 22, "blue")
  for i = 1, 120 do local x, y = K.rnd(W), 97 + K.rnd(20); K.rect(x, y, 2 + K.rnd(5), 1, (i % 3 == 0) and "light_blue" or "sky_top") end
  for x = 0, W - 1 do
    local lip = 104 + math.floor(2 * math.sin(x / 11))
    for y = lip, lip + 4 + (x % 3) do K.px(x, y, ((x + y) % 4 == 0) and "light_blue" or "white") end
  end
  for _, b in ipairs({{70, 104, 5}, {180, 106, 4}, {260, 103, 6}, {350, 105, 4}}) do K.ellipse(b[1], b[2], b[3], 2, "roof"); K.ellipse(b[1] - 1, b[2] - 1, b[3] - 2, 1, "roof_lt") end
  -- the near bank: sand and boulders with grass along the water
  K.rect(0, 118, W, H - 118, "sand")
  K.rect(0, 118, W, 2, "grass")
  for i = 1, 700 do K.px(K.rnd(W), 120 + K.rnd(30), ({"silt_lt", "sand", "silt", "clap_sh"})[i % 4 + 1]) end
  K.boulder(410, 132, 6, 4)
  -- the near canyon wall rising at the left edge, framing the camp
  K.poly({{0, 30}, {14, 34}, {30, 60}, {40, 100}, {52, 150}, {0, 150}}, "roof")
  for y = 30, 149 do for x = 0, 52 do
    if K.at(x, y) == "roof" then local h = (x * 73 + y * 151 + (x // 3) * 37) % 11; if h == 0 then K.px(x, y, "ink") elseif h < 3 or x % 5 == 0 then K.px(x, y, "roof_dk") end end
  end end
  K.line(0, 30, 14, 34, "rust")
end)

K.layer("camp", function()
  -- the fishing camp: drying racks full of split salmon, brush lodges, people at work
  rack(140, 132, 30); rack(190, 130, 24); rack(240, 134, 30)
  brush_lodge(104, 134); brush_lodge(300, 132)
  -- a fisherman on a rock at the falls with a long spear; a woman splitting fish
  K.person(260, 102, "ochre", "deep", false); K.rect(259, 86, 5, 3, "deep"); K.rect(260, 89, 3, 3, "skin_dk")
  K.line(256, 88, 250, 108, "wood")
  K.person(212, 144, "rust", "deep", true); K.rect(211, 128, 5, 3, "deep"); K.rect(212, 131, 3, 3, "skin_dk")
  K.rect(218, 142, 8, 2, "wood"); K.rect(219, 141, 4, 1, "brick_lt")
  K.person(126, 142, "cream", "deep", false); K.rect(125, 126, 5, 3, "deep"); K.rect(126, 129, 3, 3, "skin_dk")
  -- an emigrant come down the trail to trade, a sack of flour over his shoulder
  K.person(352, 144, "blue", "roof"); K.rect(346, 130, 6, 5, "cream")
end)

K.save("location_salmon_falls")

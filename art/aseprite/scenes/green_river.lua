-- Green River crossing (432x150).
-- On the southern road toward Bridger's post the Green runs deep, cold and swift between
-- banded bluffs of grey-green and buff clay, its banks lined with cottonwoods. In high water
-- it could not be forded; wagon beds were caulked and floated across while the stock swam.
local K = dofile(app.params.kit)
local W, H = 432, 150
local N, S = 104, 130

K.canvas(W, H, 184839)

K.layer("sky", function()
  K.sky(W, 100, {{260, 12, 0.9}, {40, 22, 0.6}}, "mist")
end)

K.layer("bluffs", function()
  -- flat-topped badland bluffs in coloured bands
  local bl = function(x) return 26 + 10 * math.max(0, math.sin(x / 44 + 1)) + 3 * math.sin(x / 13) + ((x % 23 < 3) and -2 or 0) end
  K.ridge(0, W - 1, N, N, bl, "clap_sh", "cream", "stone_dk")
  local bands = {"stone", "clap_sh", "teal", "clap_sh", "sand", "stone_dk", "clap_sh"}
  for x = 0, W - 1 do
    local top = math.floor(N - bl(x) + 0.5)
    for y = top + 2, N do
      local b = bands[(math.floor((y + math.sin(x / 30) * 2) / 4) % #bands) + 1]
      K.px(x, y, b)
    end
    -- erosion runnels darken the faces turned from the light
    if bl(x + 1) < bl(x - 1) then for y = top + 1, top + 6 do K.px(x, y, "stone_dk") end end
  end
  for _, g in ipairs({{38, 4}, {92, -3}, {170, 5}, {236, -4}, {318, 3}, {380, -5}}) do
    local top = math.floor(N - bl(g[1]) + 0.5)
    for y = top + 2, N - 1 do K.px(math.floor(g[1] + g[2] * math.sin((y - top) / 6)), y, "stone_dk") end
  end
end)

K.layer("river", function()
  K.rect(0, N, W, S - N + 2, "teal")
  for y = N, S + 2 do
    for x = 0, W - 1 do
      if (y < N + 2) or ((x * 5 + y * 7) % 41 == 0) then K.px(x, y, "pine") end
      if (x * 3 + y * 11) % 53 == 0 then K.px(x, y, "haze") end
    end
  end
  for i = 1, 90 do
    local x, y = K.rnd(W), N + 3 + K.rnd(S - N)
    K.rect(x, y, 3 + K.rnd(6), 1, (K.rnd(3) == 0) and "white" or "haze")
  end
  -- cottonwoods on the far bank
  for _, t in ipairs({{24, 106}, {60, 105}, {140, 106}, {300, 105}, {340, 106}, {404, 105}}) do K.elm(t[1], t[2], 1) end
end)

K.layer("near bank", function()
  K.poly({{0, S + 2}, {150, S}, {300, S + 3}, {431, S}, {431, 150}, {0, 150}}, "clap_sh")
  K.poly({{0, S + 5}, {150, S + 3}, {300, S + 6}, {431, S + 3}, {431, 150}, {0, 150}}, "sage")
  for i = 1, 600 do
    local x, y = K.rnd(W), S + K.rnd(20)
    local c = K.at(x, y)
    if c == "sage" then K.px(x, y, ({"grass", "gold", "clap_sh", "teal"})[i % 4 + 1])
    elseif c == "clap_sh" then K.px(x, y, (i % 2 == 0) and "stone" or "sand") end
  end
  K.elm(20, 150, 2)
end)

K.layer("figures", function()
  -- a caulked wagon bed floating across, poled by two men; the oxen swim behind it
  local bx, by = 200, 116
  K.poly({{bx, by - 6}, {bx + 40, by - 6}, {bx + 38, by}, {bx + 2, by}}, "blue")
  K.rect(bx, by - 6, 40, 1, "light_blue"); K.rect(bx + 1, by - 3, 38, 1, "teal")
  K.rect(bx + 6, by - 11, 10, 5, "cream"); K.rect(bx + 20, by - 10, 8, 4, "ochre"); K.barrel(bx + 30, by - 6)
  K.rect(bx - 4, by + 1, 48, 1, "white"); K.rect(bx + 44, by - 1, 6, 1, "haze")
  K.person(bx + 4, by - 6, "red", "deep"); K.line(bx + 2, by - 18, bx - 6, by + 2, "wood")
  K.person(bx + 36, by - 6, "blue", "roof"); K.line(bx + 40, by - 18, bx + 46, by + 2, "wood")
  for i = 0, 2 do
    local x = 262 + i * 12
    K.rect(x, by - 2, 8, 2, "ox_dk"); K.px(x + 8, by - 3, "ox_dk"); K.px(x + 9, by - 4, "ox_lt")
    K.rect(x - 2, by, 13, 1, "haze"); K.px(x + 10, by - 2, "white")
  end
  -- wheels and running gear left on the bank to follow, a woman minding the camp
  K.wheel(330, 140, 7); K.wheel(346, 141, 6)
  K.rect(320, 146, 40, 2, "deep")
  K.person(300, 146, "teal", "bonnet", true)
  K.ox(380, 146, -1, "light", true)
end)

K.save("location_green_river")

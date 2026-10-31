-- Big Vermilion crossing (432x150).
-- A wooded creek in eastern Kansas prairie, cut deep into red-brown clay. Its banks were steep,
-- and wagons were eased down on locked wheels or held back with ropes, then pulled up the far
-- side by doubled teams. Elm, oak and walnut crowd the bottom; open prairie rolls beyond.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 184807)

local LIP = function(x) return 96 + math.floor(2 * math.sin(x / 29) + math.sin(x / 11)) end
local creek = {{-10, 119, 4}, {80, 120, 4}, {160, 118, 5}, {240, 121, 5}, {330, 119, 5}, {440, 121, 5}}

K.layer("sky", function()
  K.sky(W, 76, {{70, 16, 0.9}, {330, 10, 0.7}}, "mist")
end)

K.layer("prairie", function()
  K.ridge(0, W - 1, 0, 100, function(x) return -(70 + 3 * math.sin(x / 59) + 2 * math.sin(x / 19)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 104, function(x) return -(80 + 4 * math.sin(x / 41 + 1) + math.sin(x / 9)) end, "sage", "clap_sh", "grass")
  K.rect(0, 92, W, H - 92, "grass")
  for i = 1, 1100 do
    local x, y = K.rnd(W), 84 + K.rnd(H - 84)
    if K.at(x, y) == "grass" or K.at(x, y) == "sage" then K.px(x, y, ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end
  end
end)

K.layer("cut", function()
  -- the far wall of the trench in raw red clay, layered and gullied, down to the water;
  -- the near bank's lip just shows below
  for x = 0, W - 1 do
    local top = LIP(x)
    for y = top, 118 do
      local c = ((y - top) % 4 == 0) and "brick_dk" or "brick"
      if y == top then c = "grass" elseif y == top + 1 then c = "rust" end
      K.px(x, y, c)
    end
    if (x * 13) % 17 == 0 then K.line(x, top + 2, x + 1, 117, "brick_dk") end
    if (x * 5) % 9 == 0 then K.line(x, top + 3, x, top + 8 + x % 5, "brick_lt") end
    if (x * 7) % 11 == 0 then K.px(x, top + 3 + x % 6, "brick_lt") end
  end
  local water = K.smooth(creek)
  K.ribbon(water, "silt_dk", 1)
  K.river(water, false)
  for x = 0, W - 1 do K.rect(x, 125 + math.floor(math.sin(x / 13)), 1, 4, "brick_dk"); K.px(x, 124 + math.floor(math.sin(x / 13)), "silt") end
  K.rect(0, 129, W, H - 129, "grass")
  for i = 1, 700 do K.px(K.rnd(W), 129 + K.rnd(H - 129), ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end
  -- the road: down a gouged slot in the near bank, across the riffle, up a slot in the far wall
  K.poly({{300, 150}, {318, 150}, {244, 124}, {232, 124}}, "dirt_dk")
  K.poly({{304, 150}, {313, 150}, {242, 125}, {236, 125}}, "silt")
  K.poly({{172, 118}, {188, 118}, {164, LIP(164) - 1}, {150, LIP(150) - 1}}, "dirt_dk")
  K.poly({{175, 118}, {184, 118}, {161, LIP(161)}, {154, LIP(154)}}, "silt")
  local up = K.smooth({{156, 94, 2}, {120, 90, 2}, {60, 88, 1}, {-6, 87, 1}})
  K.ribbon(up, "rust", 1); K.ribbon(up, "ochre", 0)
  for i = 1, 30 do local x = 186 + K.rnd(50); K.rect(x, 117 + K.rnd(5), 2, 1, "white") end
end)

K.layer("timber", function()
  -- elm, oak and walnut along both rims; brush hanging over the far wall
  for _, t in ipairs({{10, 1}, {28, 0.8}, {70, 1}, {124, 0.8}, {214, 1}, {232, 0.7}, {290, 1}, {356, 1}, {372, 0.8}, {420, 1}}) do K.elm(t[1], LIP(t[1]) + 1, t[2]) end
  for _, w in ipairs({{100, 110, 1}, {200, 108, 1}, {276, 110, 1}, {360, 108, 1}}) do K.willow(w[1], w[2], w[3]) end
  K.elm(30, 154, 2); K.elm(404, 156, 2)
  K.willow(150, 130, 1); K.willow(220, 132, 1)
end)

K.layer("figures", function()
  -- a wagon easing down the near bank with its wheels chained, two men on a rope behind it;
  -- the next waits on the prairie; on the far side a team doubled up hauls the last one out
  K.wagon(262, 140, -1)
  K.team(248, 135, -1, {"dark"}, {"red", true})
  K.line(286, 132, 300, 142, "clap_sh")
  K.person(300, 146, "blue", "deep"); K.person(310, 148, "rust", "roof")
  K.wagon(372, 148, -1)
  K.person(392, 148, "teal", "bonnet", true)
  K.far_wagon(126, 91, -1)
end)

K.save("location_big_vermilion")

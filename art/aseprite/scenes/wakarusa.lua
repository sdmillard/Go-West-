-- Wakarusa River crossing (432x150).
-- The Wakarusa was the first real crossing out of Independence: a small, muddy stream in a
-- timbered ravine with steep, slick banks. Diarists describe letting wagons down the bank
-- with ropes and doubling teams to haul them up the far side. No later bridge, ferry or
-- inn is shown.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 248)

local creek = {{318, 88, 2}, {300, 96, 3}, {276, 106, 5}, {248, 114, 6}, {218, 124, 7}, {186, 134, 9}, {166, 146, 11}, {140, 158, 13}}
local function shifted(pts, dx, dw)
  local out = {}
  for i, q in ipairs(pts) do out[i] = {q[1] + dx, q[2], q[3] + dw * (i / #pts)} end
  return K.smooth(out)
end

-- an oak or elm with a dark under-canopy and sunlit upper left
local function tree(x, y, s, far)
  local dk, md, lt = "pine", "leaf", "grass"
  if far then dk, md, lt = "teal", "grass", "sage" end
  K.rect(x - 1, y - 12 * s, 2 + s, 12 * s, far and "wood" or "deep")
  K.px(x - 1, y - 8 * s, "wood")
  K.line(x, y - 9 * s, x - 5 * s, y - 14 * s, "deep"); K.line(x + 1, y - 10 * s, x + 6 * s, y - 15 * s, "deep")
  local clumps = {{-7, -16, 7, 5}, {6, -18, 8, 6}, {0, -23, 9, 6}, {-5, -27, 6, 4}, {5, -28, 6, 4}}
  for _, c in ipairs(clumps) do K.ellipse(x + c[1] * s, y + c[2] * s, c[3] * s, c[4] * s, dk) end
  for _, c in ipairs(clumps) do K.ellipse(x + c[1] * s - 1, y + c[2] * s - 1, c[3] * s - 2, c[4] * s - 2, md) end
  for _, c in ipairs(clumps) do K.ellipse(x + c[1] * s - 2 * s, y + c[2] * s - 2 * s, math.max(1, c[3] * s - 5), math.max(1, c[4] * s - 4), lt) end
end

K.layer("sky", function()
  K.sky(W, 74, {{228, 12, 0.8}, {12, 26, 0.6}}, "mist")
end)

K.layer("prairie", function()
  -- open prairie rolling away above the ravine
  K.ridge(0, W - 1, 0, 96, function(x) return -(66 + 3 * math.sin(x / 47) + 2 * math.sin(x / 15)) end, "sage", "far_hill", "grass")
end)

K.layer("timber", function()
  -- a line of timber marking the creek, thickest where the ravine deepens
  -- a continuous mass of crowns, with a few taller trees standing out of it
  for x = -4, W + 4, 6 do
    local y = 74 + math.floor(3 * math.sin(x / 23) + K.rnd(3))
    if not (x > 304 and x < 328) then K.ellipse(x, y, 8, 8, "pine"); K.ellipse(x - 1, y - 1, 6, 6, "leaf") end
  end
  for x = -4, W + 4, 6 do
    local y = 72 + math.floor(3 * math.sin(x / 23) + K.rnd(3))
    if not (x > 304 and x < 328) then K.ellipse(x - 2, y - 2, 4, 3, "grass"); K.px(x - 4, y - 4, "sage") end
  end
  for _, t in ipairs({{40, 84}, {104, 86}, {176, 84}, {252, 88}, {370, 84}, {420, 86}}) do tree(t[1], t[2], 1, true) end
  K.rect(0, 82, W, 14, "grass")
  for i = 1, 300 do K.px(K.rnd(W), 82 + K.rnd(14), (i % 2 == 0) and "leaf" or "sage") end
end)

K.layer("ravine", function()
  -- grass on both banks, the cut of the ravine, slick mud, then the creek
  K.rect(0, 94, W, H - 94, "grass")
  for i = 1, 900 do
    local x, y = K.rnd(W), 94 + K.rnd(H - 94)
    K.px(x, y, ({"leaf", "sage", "grass", "gold"})[i % 4 + 1])
    if i % 3 == 0 then K.px(x, y - 1, "sage") end
  end
  K.ribbon(shifted(creek, 4, 12), "wood", 7)
  K.ribbon(shifted(creek, -2, 10), "rust", 6)
  K.ribbon(shifted(creek, -4, 5), "ochre", 4)
  K.ribbon(shifted(creek, 1, 4), "deep", 3)
  -- the water: low, muddy and slow
  local water = K.smooth(creek)
  K.ribbon(water, "teal", 0)
  local inner = {}
  for i, q in ipairs(water) do inner[i] = {q[1] - 1, q[2], q[3] * 0.5} end
  K.ribbon(inner, "haze", 0)
  for i = 1, 40 do
    local x, y = 110 + K.rnd(220), 88 + K.rnd(62)
    if K.at(x, y) == "teal" then K.rect(x, y, 2 + K.rnd(3), 1, "light_blue") end
  end
  -- muddy wheel tracks down both banks to the ford
  for _, t in ipairs({{{440, 104, 5}, {380, 106, 5}, {310, 116, 5}, {262, 124, 4}, {232, 130, 3}},
                      {{176, 138, 4}, {150, 130, 5}, {104, 128, 6}, {44, 134, 7}, {-10, 142, 8}}}) do
    local track = K.smooth(t)
    K.ribbon(track, "wood", 1)
    K.ribbon(track, "rust", -1)
    local rut = {}
    for i, q in ipairs(track) do rut[i] = {q[1], q[2], 0.5} end
    K.ribbon(rut, "deep", 0)
  end
  -- slick, shining mud and exposed roots on the cut banks
  for i = 1, 220 do
    local x, y = K.rnd(W), 90 + K.rnd(60)
    local c = K.at(x, y)
    if c == "rust" then K.px(x, y, (i % 3 == 0) and "ochre" or "wood")
    elseif c == "wood" then K.px(x, y, (i % 2 == 0) and "deep" or "rust")
    elseif c == "deep" and i % 4 == 0 then K.px(x, y, "gold") end
  end
end)

K.layer("trees", function()
  -- big timber leaning over the ravine on both banks
  for _, t in ipairs({{132, 112, 1}, {268, 104, 1}, {352, 100, 1}, {396, 106, 1}, {84, 116, 1}, {212, 98, 1}}) do tree(t[1], t[2], t[3]) end
  tree(28, 148, 2)
  tree(414, 150, 2)
  -- underbrush along the cut
  for _, w in ipairs({{106, 132, 1}, {152, 124, 1}, {242, 108, 1}, {300, 94, 1}, {326, 92, 1}, {182, 148, 2}, {232, 140, 1}}) do K.willow(w[1], w[2], w[3]) end
end)

K.layer("figures", function()
  -- a wagon mired at the ford, team straining up the far bank with a double hitch
  K.wagon(176, 136, -1)
  K.team(164, 132, -1, {"dark"}, {"red", true})
  K.team(130, 128, -1, {"light"}, {"dark", true})
  K.line(136, 117, 160, 121, "deep")
  for i = 0, 6 do K.px(178 + i * 6, 137 + (i % 2), "haze") end
  -- teamster with a whip on the far bank, a man shoving the rear wheel
  K.person(116, 124, "blue", "deep")
  K.line(118, 112, 106, 106, "deep")
  K.person(224, 136, "red", "roof")
  -- the next wagon waiting at the top of the near bank, rope ready to let it down
  K.wagon(346, 110, -1)
  K.team(336, 110, -1, {"red"}, {"light", true})
  K.line(394, 102, 404, 110, "cream")
  K.person(404, 112, "teal", "deep")
  K.person(392, 114, "rust", "bonnet", true)
end)

K.save("location_wakarusa")

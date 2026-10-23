-- Scotts Bluff and the way to Robidoux Pass (432x150).
-- The bluff is a long badland massif some 800 feet above the North Platte: pale Brule clay
-- and Gering sandstone walls on gullied aprons, broken into buttresses. In 1848 wagons could
-- not pass between the bluff and the river, so the road bends south toward Robidoux Pass, a
-- gap in the cedar-dotted Wildcat Hills (the Mitchell Pass road came in 1850).
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 100

K.canvas(W, H, 1849)

K.layer("sky", function()
  K.sky(W, HORIZON, {{70, 16, 1.1}, {236, 8, 0.8}, {360, 24, 0.9}})
  K.ridge(0, W - 1, HORIZON - 2, HORIZON, function(x) return 4 + 2 * math.sin(x / 29) + math.sin(x / 7) end, "far_hill", "mist", "haze")
end)

K.layer("wildcat_hills", function()
  -- the Wildcat Hills to the south, with the notch of Robidoux Pass
  local function hill(x)
    local notch = math.max(0, 1 - math.abs(x - 112) / 18)
    local fade = math.max(0, math.min(1, (250 - x) / 70))
    return (22 + 7 * math.sin(x / 23) + 3 * math.sin(x / 7 + 2) - 17 * notch) * fade
  end
  K.ridge(0, 250, 100, 104, hill, "sage", "gold", "teal")
  for i = 1, 70 do
    local x = K.rnd(200)
    local top = 100 - hill(x)
    local y = math.floor(top + 2 + K.rnd(math.max(1, 100 - top - 2)))
    K.px(x, y, "pine"); K.px(x, y - 1, "leaf"); if K.rnd(2) == 0 then K.px(x + 1, y, "pine") end
  end
end)

K.layer("bluff", function()
  -- far western buttresses, then the main mass and the eastern spur nearest the road
  K.butte({cx = 372, crown = 30, top = 36, shoulder = 58, base = 102, foot = 76, seed = 4})
  K.butte({cx = 300, crown = 34, top = 26, shoulder = 52, base = 104, foot = 96, seed = 2})
  K.butte({cx = 236, crown = 10, top = 46, shoulder = 64, base = 104, foot = 44, seed = 7})
end)

K.layer("plain", function()
  K.rect(0, 103, W, H - 103, "sage")
  K.dither(0, 103, W, 3, "far_hill", "sage")
  K.rect(0, 114, W, H - 114, "grass")
  K.dither(0, 110, W, 4, "sage", "grass")
  for i = 1, 900 do
    local x, y = K.rnd(W), 104 + K.rnd(H - 104)
    K.px(x, y, (K.rnd(3) == 0) and "gold" or ((y > 125 and K.rnd(2) == 0) and "leaf" or "sage"))
  end
  for i = 1, 24 do K.sage(10 + K.rnd(W - 20), 116 + K.rnd(32)) end
  -- the road swings south, away from the bluff, toward the pass
  local road = K.smooth({{440, 140, 7}, {300, 134, 6}, {190, 122, 4}, {130, 108, 2}, {112, 102, 1}}, 10)
  K.ribbon(road, "ochre", 1)
  K.ribbon(road, "gold", -2)
end)

K.layer("travelers", function()
  K.far_wagon(150, 113, -1)
  K.far_wagon(178, 118, -1)
  K.wagon(296, 140, -1)
  K.team(282, 139, -1, {"dark"}, {"red", true})
  K.person(350, 140, "blue", "deep", false)
end)

K.save("location_scotts_bluff")

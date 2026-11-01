-- Green Springs Mountain (432x150).
-- The summit of the Applegates' Cascade road: a little meadow among tall pines and firs with
-- good springs welling up in the grass. West, past the timber, the Siskiyous and the Rogue
-- country lie blue below; the road plunges off the edge toward Jenny Creek.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185227)

K.layer("sky", function()
  K.sky(W, 90, {{150, 10, 0.8}, {380, 18, 0.6}}, "mist")
end)

K.layer("distance", function()
  -- the Siskiyous far off to the southwest, through a gap in the timber
  K.ridge(0, W - 1, 0, 90, function(x) return -(56 - 8 * math.sin(x / 43) - 4 * math.sin(x / 17 + 1) - 2 * math.sin(x / 6)) end, "far_hill", "mist", "haze")
  K.ridge(0, W - 1, 0, 92, function(x) return -(68 - 5 * math.sin(x / 29 + 2)) end, "haze", "far_hill", "teal")
end)

K.layer("timber", function()
  -- dense timber framing the meadow on both sides, thinning to the gap in the middle
  for x = 2, W, 5 do
    local gap = math.abs(x - 230) < 60
    if not gap or (x % 15 == 0) then
      local h = gap and 16 or (30 + (x * 7) % 18)
      K.conifer(x, 92 + (x * 3) % 6, h)
    end
  end
end)

K.layer("meadow", function()
  -- dark undergrowth at the timber's edge
  for x = 0, W - 1 do
    local gap = math.abs(x - 230) < 54
    local top = gap and 92 or (84 + math.floor(3 * math.sin(x / 5) + 2 * math.sin(x / 2.1)))
    for y = top, 94 do K.px(x, y, ((x * 7 + y * 3) % 5 == 0) and "leaf" or "pine") end
  end
  K.rect(0, 94, W, H - 94, "grass")
  for i = 1, 1600 do K.px(K.rnd(W), 92 + K.rnd(H - 92), ({"leaf", "sage", "grass", "gold", "leaf"})[i % 5 + 1]) end
  -- springs: small clear pools with a trickle running off
  for _, p in ipairs({{170, 118, 7, 2}, {260, 128, 5, 2}, {120, 132, 4, 1}}) do
    K.ellipse(p[1], p[2], p[3] + 2, p[4] + 1, "leaf"); K.ellipse(p[1], p[2], p[3], p[4], "blue"); K.rect(p[1] - p[3] // 2, p[2] - 1, math.max(1, p[3] // 2), 1, "light_blue")
  end
  local run = K.smooth({{170, 120, 1}, {200, 132, 1}, {230, 140, 1}, {260, 150, 2}})
  K.ribbon(run, "blue", 0)
  local road = K.smooth({{440, 112, 3}, {360, 114, 3}, {280, 112, 3}, {200, 108, 3}, {140, 104, 2}, {80, 104, 2}, {20, 110, 2}, {-10, 118, 3}})
  K.ribbon(road, "rust", 1); K.ribbon(road, "ochre", 0)
end)

K.layer("near", function()
  for _, t in ipairs({{14, 150, 64}, {46, 140, 50}, {400, 148, 60}, {426, 138, 46}, {370, 132, 40}, {80, 126, 34}}) do K.conifer(t[1], t[2], t[3]) end
end)

K.layer("figures", function()
  K.wagon(220, 110, -1)
  K.team(206, 106, -1, {"dark"}, {"red"})
  K.person(178, 120, "teal", "bonnet", true)
  K.ox(300, 134, -1, "light"); K.ox(140, 140, 1, "dark")
  K.tent(330, 120, 10, 14)
end)

K.save("location_green_springs")

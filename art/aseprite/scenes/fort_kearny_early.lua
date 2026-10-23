-- Fort Kearny site before construction (432x150).
-- Before June 1848 nothing stood here but open ground on the south bank of the Platte, across
-- from the long timbered Grand Island. The river is a mile wide, braided and shallow, "too thick
-- to drink and too thin to plough". Emigrants camp on the bottom; there is no post yet.
local K = dofile(app.params.kit)
local W, H = 432, 150

K.canvas(W, H, 184838)

K.layer("sky", function()
  K.sky(W, 96, {{20, 20, 0.7}, {176, 10, 1.1}, {350, 26, 0.6}}, "mist")
end)

K.layer("far shore", function()
  -- low sand hills beyond the river, and the cottonwoods of Grand Island
  K.ridge(0, W - 1, 0, 92, function(x) return -(84 + 2 * math.sin(x / 37)) end, "far_hill", "mist", "haze")
  for x = 0, W - 1, 4 do
    local h = 5 + math.floor(3 * math.abs(math.sin(x / 11)) + K.rnd(3))
    K.ellipse(x, 90 - h, 4, h, "teal"); K.ellipse(x - 1, 89 - h, 2, math.max(1, h - 2), "grass")
  end
  K.rect(0, 89, W, 3, "teal")
end)

K.layer("platte", function()
  -- braided channels between bars of pale sand
  K.rect(0, 92, W, 22, "sand")
  for _, c in ipairs({{94, 1}, {100, 2}, {107, 2}}) do
    local pts = {}
    for i = 0, 8 do pts[#pts + 1] = {i * 56 - 6, c[1] + math.floor(3 * math.sin(i * 1.3 + c[1])), c[2] + (i % 3 == 0 and 1 or 0)} end
    K.river(K.smooth(pts), false)
  end
  for i = 1, 200 do
    local x, y = K.rnd(W), 92 + K.rnd(22)
    if K.at(x, y) == "sand" then K.px(x, y, (i % 3 == 0) and "clap_sh" or "cream") end
  end
end)

K.layer("bottom", function()
  -- open grass bottom on the south bank: nothing built here yet
  K.rect(0, 113, W, H - 113, "grass")
  K.rect(0, 113, W, 1, "sand")
  for i = 1, 1600 do
    local x, y = K.rnd(W), 114 + K.rnd(36)
    K.px(x, y, ({"sage", "leaf", "gold", "grass"})[i % 4 + 1])
    if y > 130 and i % 3 == 0 then K.px(x, y - 1, "sage") end
  end
  local road = K.smooth({{-6, 128, 2}, {100, 126, 3}, {220, 130, 4}, {330, 136, 5}, {440, 144, 7}})
  K.ribbon(road, "ochre", 1); K.ribbon(road, "sand", 0)
end)

K.layer("camp", function()
  -- an emigrant camp: wagons drawn up, a cook fire of buffalo chips, stock grazing
  K.far_wagon(60, 122, 1)
  K.far_wagon(86, 121, 1)
  K.tent(146, 124, 8, 10)
  K.wagon(196, 140, 1)
  K.tent(258, 138, 12, 16)
  -- fire and kettle on a tripod
  local fx, fy = 290, 142
  K.line(fx - 4, fy, fx, fy - 9, "deep"); K.line(fx + 4, fy, fx, fy - 9, "deep")
  K.rect(fx - 2, fy - 4, 4, 3, "ink")
  K.rect(fx - 3, fy - 1, 6, 1, "red"); K.px(fx - 1, fy - 2, "gold"); K.px(fx + 1, fy - 2, "red")
  K.px(fx, fy - 12, "mist"); K.px(fx + 1, fy - 15, "mist"); K.px(fx, fy - 18, "light_blue")
  K.person(278, 144, "red", "bonnet", true)
  K.person(304, 145, "blue", "deep")
  K.ox(350, 146, -1, "light", true)
  K.ox(386, 142, 1, "red")
  K.ox(120, 136, 1, "dark")
end)

K.save("location_fort_kearny_early")

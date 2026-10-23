-- Deschutes River crossing (432x150).
-- Palmer (1845) and others describe the Deschutes near its mouth as swift and rocky, running
-- in a gorge between rimrock walls; emigrants forded on the bars or paid Indian canoemen to
-- ferry their goods. The view looks up the canyon past a rapid to a gravel bar where a wagon
-- waits its turn, while a canoe works across the current.
local K = dofile(app.params.kit)
local W, H = 432, 150
local VX, VY = 216, 70 -- where the river disappears round the bend

K.canvas(W, H, 184829)

local function lerp(a, b, t) return a + (b - a) * math.max(0, math.min(1, t)) end

-- One canyon wall drawn column by column: a band of columnar basalt under the rim, a talus
-- slope, a second lower flow of basalt, and more talus down to `foot`.
-- `palette` = {basalt_dk, basalt, basalt_lt, talus_dk, talus, talus_lt}.
local function wall(x0, x1, rim, foot, palette)
  for x = x0, x1 do
    local top, bottom = math.floor(rim(x) + 0.5), math.floor(foot(x) + 0.5)
    local depth = math.abs(x - VX)
    local band = math.floor(3 + 0.09 * depth + math.sin(x / 23))
    local ledge = top + band + math.floor(6 + 0.16 * depth + 2 * math.sin(x / 37 + 1))
    local ledge_h = math.floor(2 + 0.05 * depth)
    for y = top, bottom do
      local c
      local in_rim = y < top + band
      local in_ledge = y >= ledge and y < ledge + ledge_h
      if in_rim or in_ledge then
        local k = (x + math.floor(y / 9)) % 4
        c = (k == 0) and palette[1] or ((k == 1) and palette[3] or palette[2])
        if y == top or y == ledge then c = palette[3] end
      elseif y == top + band or y == ledge + ledge_h then
        c = palette[1]
      else
        -- talus: smooth with streaks running down the slope, a few loose stones
        local streak = math.sin(x / 3.3 + y / 40) + 0.6 * math.sin(x / 1.7)
        c = (streak > 1.0) and palette[6] or ((streak < -1.1) and palette[4] or palette[5])
        if K.rnd(40) == 0 then c = palette[1] end
      end
      K.px(x, y, c)
    end
    K.px(x, top - 1, "sage")
    if K.rnd(3) == 0 then K.px(x, top - 2, "grass") end
  end
end

K.layer("sky", function()
  K.sky(W, 60, {{120, 10, 0.8}, {356, 20, 1.0}}, "mist")
end)

K.layer("plateau", function()
  -- the flat Columbia plateau beyond the gorge, hazy with distance
  K.ridge(0, W - 1, 0, 76, function(x) return -(54 + 2 * math.sin(x / 50) + math.sin(x / 13)) end, "far_hill", "mist", "haze")
  K.ridge(150, 290, 0, 76, function(x) return -(58 + 3 * math.sin(x / 19)) end, "clap_sh", "sand", "ochre")
  -- far bend of the canyon, a smaller pair of walls
  wall(170, 214, function(x) return lerp(58, 62, (x - 170) / 44) end, function(x) return lerp(76, 70, (x - 170) / 44) end,
       {"roof", "roof_lt", "stone_dk", "rust", "ochre", "clap_sh"})
  wall(218, 268, function(x) return lerp(62, 57, (x - 218) / 50) end, function(x) return lerp(70, 76, (x - 218) / 50) end,
       {"roof_lt", "stone_dk", "stone", "ochre", "clap_sh", "sand"})
end)

K.layer("walls", function()
  -- west wall faces away from the light; east wall catches it
  wall(0, VX, function(x) return lerp(34, 63, (x / VX) ^ 1.3) end,
       function() return H - 1 end,
       {"roof_dk", "roof", "roof_lt", "deep", "wood", "rust"})
  wall(VX + 1, W - 1, function(x) return lerp(63, 30, ((x - VX) / (W - VX)) ^ 0.75) end,
       function() return H - 1 end,
       {"roof", "roof_lt", "stone_dk", "rust", "ochre", "gold"})
  -- gullies and fallen blocks on the talus
  for _, g in ipairs({{52, 72, 8}, {132, 84, -5}, {316, 74, 6}, {384, 64, -7}}) do
    for y = g[2], g[2] + 34 do
      local x = math.floor(g[1] + g[3] * math.sin((y - g[2]) / 12))
      K.px(x, y, "deep"); K.px(x + 1, y, (g[1] < VX) and "roof_dk" or "rust")
    end
  end
  for i = 1, 60 do
    local x, y = K.rnd(W), 60 + K.rnd(90)
    local c = K.at(x, y)
    if c == "wood" or c == "rust" then K.rect(x, y, 2, 1, "roof_dk")
    elseif c == "ochre" or c == "gold" then K.rect(x, y, 2, 1, "roof"); K.px(x, y - 1, "stone") end
  end
  for i = 1, 40 do
    local x, y = K.rnd(W), 70 + K.rnd(80)
    local c = K.at(x, y)
    if c == "ochre" or c == "wood" or c == "rust" or c == "gold" then K.sage(x, y) end
  end
end)

K.layer("river", function()
  local course = K.smooth({{VX, VY, 3}, {210, 84, 9}, {224, 104, 20}, {214, 126, 38}, {222, 150, 62}})
  K.ribbon(course, "roof_dk", 2)
  K.ribbon(course, "blue", 0)
  local inner = {}
  for i, q in ipairs(course) do inner[i] = {q[1] - q[3] * 0.1, q[2], q[3] * 0.55} end
  K.ribbon(inner, "sky_top", 0)
  -- broken white water on the rapids, heaviest at two ledges
  for i = 1, 900 do
    local y = VY + 2 + K.rnd(H - VY - 2)
    local x = K.rnd(W)
    local ledge = (math.abs(y - 100) < 6) or (math.abs(y - 128) < 9)
    if K.at(x, y) == "blue" or K.at(x, y) == "sky_top" then
      if ledge and K.rnd(2) == 0 then
        K.rect(x, y, 2 + K.rnd(4), 1, (K.rnd(3) == 0) and "light_blue" or "white")
      elseif K.rnd(5) == 0 then
        K.rect(x, y, 1 + math.floor((y - VY) / 20), 1, "light_blue")
      end
    end
  end
  -- black boulders splitting the current, foam piling on their upstream side
  for _, b in ipairs({{206, 100, 3, 2}, {232, 99, 2, 1}, {190, 129, 5, 2}, {246, 127, 4, 2}, {222, 131, 3, 1}, {176, 144, 4, 2}, {268, 142, 5, 2}}) do
    K.rect(b[1] - b[3] - 1, b[2] - b[4] - 1, b[3] * 2 + 3, 1, "white")
    K.ellipse(b[1], b[2], b[3], b[4], "ink")
    K.ellipse(b[1] - 1, b[2] - 1, math.max(1, b[3] - 1), math.max(0, b[4] - 1), "roof")
    K.rect(b[1] - b[3], b[2] + b[4] + 1, b[3] * 2 + 1, 1, "light_blue")
  end
end)

K.layer("bar", function()
  -- gravel bar on the near west bank
  K.poly({{40, 150}, {64, 134}, {130, 128}, {190, 132}, {204, 150}}, "clap_sh")
  K.poly({{50, 150}, {72, 137}, {130, 132}, {184, 135}, {196, 150}}, "sand")
  for i = 1, 200 do
    local x, y = 50 + K.rnd(150), 130 + K.rnd(20)
    if K.at(x, y) == "sand" or K.at(x, y) == "clap_sh" then K.px(x, y, ({"stone", "stone_dk", "ochre", "white"})[i % 4 + 1]) end
  end
  K.rect(190, 141, 12, 1, "white")
end)

K.layer("figures", function()
  -- wagon waiting on the bar, team unhitched to drink, a man watching the canoe
  K.wagon(66, 142, 1)
  K.team(120, 142, 1, {"red"}, {"light", true})
  K.person(176, 140, "red", "deep")
  K.person(58, 143, "blue", "bonnet", true)
  -- dugout canoe crossing with goods, two paddlers
  local cx, cy = 252, 116
  K.poly({{cx - 18, cy - 2}, {cx + 16, cy - 2}, {cx + 12, cy + 1}, {cx - 15, cy + 1}}, "wood")
  K.rect(cx - 16, cy - 2, 31, 1, "ochre")
  K.rect(cx - 14, cy + 1, 26, 1, "deep")
  K.rect(cx - 4, cy - 5, 7, 3, "cream"); K.rect(cx + 3, cy - 4, 2, 2, "clap_sh")
  for _, p in ipairs({{cx - 11, "rust"}, {cx + 9, "red"}}) do
    K.rect(p[1], cy - 7, 3, 5, p[2])
    K.rect(p[1], cy - 10, 3, 3, "skin_dk"); K.rect(p[1], cy - 11, 3, 1, "ink")
  end
  K.line(cx - 13, cy - 6, cx - 16, cy + 3, "deep")
  K.line(cx + 12, cy - 6, cx + 15, cy + 3, "deep")
  K.rect(cx - 22, cy + 2, 8, 1, "white"); K.rect(cx + 14, cy + 2, 6, 1, "white")
end)

K.save("location_deschutes")

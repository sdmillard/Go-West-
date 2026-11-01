-- High Rock Canyon (432x150).
-- The road threads a narrow canyon between walls of red and grey volcanic rock, banded and
-- broken into ledges, with a little creek, grass and willows in its bottom. The walls shelter
-- a camp from the wind, and give cover to anyone who wants to shoot into one.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185163)

local function hash(x, y, k)
  local v = (x * 374761393 + y * 668265263 + k * 1274126177) & 0x7fffffff
  v = ((v ~ (v >> 13)) * 1103515245) & 0x7fffffff
  return (v ~ (v >> 16)) & 0xffff
end
-- a canyon wall of volcanic tuff and lava: irregular beds of red-brown and grey that pinch
-- and swell, broken into blocky ledges and cut by joints; lit or in shade
local function wall(x0, x1, top, foot, lit, seed)
  local LIT = {"brick", "brick_lt", "stone", "rust", "stone_dk", "brick", "silt"}
  local SHADE = {"brick_dk", "brick", "stone_dk", "roof", "stone_ink", "brick_dk", "roof_dk"}
  for x = x0, x1 do
    local t = top(x)
    for y = t, foot(x) do
      -- bed boundaries wander with x so the layers are not ruled lines
      local warp = 5 * math.sin(x / 23 + seed) + 3 * math.sin(x / 7.3 + seed * 2) + 2 * math.sin(y / 11 + x / 31)
      local bed = math.floor((y + warp) / 9)
      local pal = lit and LIT or SHADE
      local c = pal[(bed * 3 + seed) % #pal + 1]
      local h = hash(x // 3, y // 2, seed)
      if h % 11 == 0 then c = pal[(bed * 3 + seed + 1) % #pal + 1] end
      if h % 37 == 0 then c = lit and "stone_lt" or "ink" end
      -- here and there a ledge: lit lip, dark undercut (short, not full-width)
      local fr = (y + warp) % 9
      if fr < 1 and hash(x // 12, bed, seed + 5) % 3 == 0 then c = lit and "sand" or "brick" end
      if fr >= 1 and fr < 2 and hash(x // 12, bed, seed + 5) % 3 == 0 then c = "ink" end
      if y < t + 2 then c = lit and "clap_sh" or "brick" end
      K.px(x, y, c)
    end
  end
  -- joints: wandering dark cracks
  for i = 1, (x1 - x0) // 14 do
    local x = x0 + K.rnd(x1 - x0)
    local y0 = top(x) + 3
    local len = 10 + K.rnd(30)
    for y = y0, math.min(foot(x) - 2, y0 + len) do if K.rnd(5) ~= 0 then K.px(x + math.floor(math.sin(y / 5 + i) * 1.5), y, "ink") end end
  end
end

K.layer("sky", function()
  K.sky(W, 70, {{200, 8, 0.7}}, "mist")
  K.rect(0, 70, W, H - 70, "silt")
end)

K.layer("far", function()
  -- the canyon winding away: a far rim in haze
  K.ridge(120, 320, 0, 90, function(x) return -(46 + 6 * math.sin(x / 17)) end, "far_hill", "mist", "haze")
  K.rect(150, 60, 140, 40, "far_hill")
  wall(150, 290, function(x) return 56 + math.floor(4 * math.sin(x / 13)) end, function(x) return 100 end, true, 7)
end)

K.layer("walls", function()
  -- left wall in sun, right wall in shade, both towering out of the frame's top corners
  wall(0, 170, function(x) return math.floor(4 + (x / 170) ^ 1.6 * 80 + 4 * math.sin(x / 11)) end, function(x) return 120 - x // 8 end, true, 1)
  wall(270, W - 1, function(x) return math.floor(4 + ((W - 1 - x) / 162) ^ 1.6 * 78 + 4 * math.sin(x / 9)) end, function(x) return 124 - (W - x) // 9 end, false, 3)
  -- talus at the feet
  for x = 0, W - 1 do
    local ft = (x < 216) and (112 - x // 10) or (102 + (x - 216) // 9)
    for y = ft, ft + 10 do if K.rnd(3) ~= 0 then K.px(x, y, ({"stone", "stone_dk", "brick", "silt"})[K.rnd(4) + 1]) end end
  end
end)

K.layer("bottom", function()
  -- the canyon floor: grass in the bottom, the creek and the road side by side
  for y = 100, H - 1 do
    local half = 30 + (y - 100) * 3.4
    K.rect(math.floor(216 - half), y, math.floor(2 * half), 1, "grass")
  end
  for i = 1, 900 do local x, y = K.rnd(W), 100 + K.rnd(50); if K.at(x, y) == "grass" then K.px(x, y, ({"leaf", "sage", "gold", "grass"})[i % 4 + 1]) end end
  local creek = K.smooth({{214, 98, 1}, {206, 110, 2}, {190, 124, 2}, {160, 138, 3}, {120, 150, 3}})
  K.ribbon(creek, "leaf", 1); K.river(creek, false)
  local road = K.smooth({{222, 98, 1}, {230, 112, 2}, {246, 128, 4}, {280, 142, 5}, {320, 152, 6}})
  K.ribbon(road, "silt", 1); K.ribbon(road, "clap_sh", 0)
  for _, w in ipairs({{196, 112, 1}, {176, 128, 1}, {138, 142, 2}}) do K.willow(w[1], w[2], w[3]) end
  for _, b in ipairs({{300, 124, 5, 2}, {110, 128, 6, 3}, {350, 140, 7, 3}}) do K.boulder(b[1], b[2], b[3], b[4]) end
end)

K.layer("figures", function()
  K.wagon(248, 136, -1)
  K.team(234, 132, -1, {"dark"}, {"red"})
  K.far_wagon(222, 106, -1)
  K.person(300, 140, "blue", "hat")
  K.ox(170, 140, 1, "light")
end)

-- winter: snow on the pale desert ground as well as the grass
K.season_extra = {{season="winter", y0=96, y1=150, map={silt="stone_lt", clap_sh="white"}}}
K.save("location_high_rock_canyon")

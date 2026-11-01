-- Black Rock (432x150).
-- A dark point of volcanic rock stands over boiling springs at the edge of the playa. Steam
-- drifts off the pools, the hot water spreads into warm green creeks, and the white flat of
-- the playa runs off east under bare hills where Paiute watchers sit.
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 185151)

-- steam: soft dithered puffs swelling and thinning as they drift east on the wind
local function steam(x, y, h)
  local n = h // 4
  for i = 0, n do
    local cx, cy = x + i * 2 + math.floor(math.sin(i + x)), y - i * 4
    local r = 2 + i // 2
    for yy = cy - r, cy + r do
      for xx = cx - r - 1, cx + r + 1 do
        local dx, dy = (xx - cx) / (r + 1), (yy - cy) / r
        local d = dx * dx + dy * dy
        if d <= 1 then
          local v = (xx * 374761393 + yy * 668265263) & 0x7fffffff
          v = ((v ~ (v >> 13)) * 1274126177) & 0x7fffffff
          local hsh = (v ~ (v >> 16)) & 0xff
          local keep = (i > n // 2) and 70 or 130
          if d < 0.35 and i < n // 2 then keep = 210 end
          if hsh < keep then K.px(xx, yy, (hsh < keep // 2) and "white" or "cream") end
        end
      end
    end
  end
end

K.layer("sky", function()
  K.sky(W, 74, {{60, 8, 0.6}, {300, 16, 0.8}}, "mist")
end)

K.layer("land", function()
  -- far bare ranges across the playa
  K.ridge(0, W - 1, 0, 88, function(x) return -(64 - 6 * math.abs(math.sin(x / 41)) - 3 * math.sin(x / 13 + 1)) end, "far_hill", "mist", "haze")
  -- the playa: white, flat, with a faint shimmer line
  K.rect(0, 82, W, H - 82, "stone_lt")
  K.rect(0, 84, W, 1, "cream")
  for i = 1, 900 do K.px(K.rnd(W), 84 + K.rnd(H - 84), ({"cream", "white", "clap_sh", "stone_lt"})[i % 4 + 1]) end
  for y = 92, 148, 9 do K.rect(K.rnd(W), y, 20 + K.rnd(40), 1, "clap_sh") end
end)

K.layer("rock", function()
  -- Black Rock point: dark basalt hill, lit west face, rust stains
  K.ridge(0, 210, 0, 112, function(x)
    local t = (x - 20) / 190
    return -(108 - 72 * math.max(0, math.sin(math.pi * math.min(1, math.max(0, t)))) ^ 0.7 + 3 * math.sin(x / 7))
  end, "roof_dk", "roof_lt", "ink")
  for i = 1, 900 do
    local x, y = K.rnd(210), 36 + K.rnd(76)
    local c = K.at(x, y)
    if c == "roof_dk" then K.px(x, y, ({"roof", "ink", "rust", "roof", "roof_dk"})[i % 5 + 1]) end
  end
  -- broken faces: lit ledges on the west slopes, dark clefts, rusty seams
  for i = 1, 70 do
    local x, y = 10 + K.rnd(200), 40 + K.rnd(66)
    if K.at(x, y) and K.at(x, y - 4) and K.at(x, y - 4) ~= "sky" and K.at(x, y - 4):sub(1, 4) == "roof" or K.at(x, y - 4) == "ink" or K.at(x, y - 4) == "rust" then
      local w = 3 + K.rnd(8)
      local lit = (x < 120) and "roof_lt" or "roof"
      K.rect(x, y, w, 1, lit); K.rect(x + 1, y + 1, w, 1, "ink")
      if K.rnd(3) == 0 then K.line(x + w, y + 1, x + w + 2, y + 6, "ink") end
    end
  end
  -- talus apron of dark blocks spilling onto the playa
  for x = 0, 236 do
    local top = 104 + math.floor(4 * math.sin(x / 13) + 2 * math.sin(x / 5))
    local foot = 113 + math.floor(3 * math.sin(x / 17)) - math.max(0, (x - 200) // 3)
    for y = top, foot do if K.rnd(5) ~= 0 then K.px(x, y, ({"roof", "roof_dk", "stone_dk", "roof_lt", "ink"})[K.rnd(5) + 1]) end end
  end
end)

K.layer("springs", function()
  -- the boiling pools and warm creeks with green growth along them
  local creek = K.smooth({{160, 120, 2}, {220, 128, 3}, {290, 136, 3}, {380, 142, 4}, {440, 146, 4}})
  K.ribbon(creek, "grass", 3); K.ribbon(creek, "leaf", 1); K.river(creek, false)
  for _, p in ipairs({{150, 118, 9, 3}, {120, 124, 6, 2}, {186, 114, 5, 2}}) do
    K.ellipse(p[1], p[2], p[3] + 2, p[4] + 1, "silt_lt")
    K.ellipse(p[1], p[2], p[3], p[4], "sea"); K.ellipse(p[1] - 1, p[2], p[3] - 3, math.max(1, p[4] - 1), "light_blue")
  end
  steam(150, 114, 40); steam(122, 121, 26); steam(186, 112, 22)
  for i = 1, 300 do local x, y = 100 + K.rnd(300), 118 + K.rnd(32); if K.at(x, y) == "stone_lt" and K.rnd(3) == 0 then K.px(x, y, "sage") end end
end)

K.layer("figures", function()
  K.wagon(250, 140, -1)
  K.team(236, 136, -1, {"dark"}, {"light", true})
  K.ox(320, 136, 1, "red"); K.ox(350, 142, -1, "light") -- drinking at the cooled creek
  K.person(300, 144, "blue", "hat")
  K.far_wagon(410, 104, -1)
  -- Paiute watchers on the hills across the playa
  K.rect(352, 80, 1, 3, "deep"); K.rect(357, 81, 1, 3, "deep")
end)

K.save("location_black_rock")

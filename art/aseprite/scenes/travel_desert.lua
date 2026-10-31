-- Regional High-Desert / Sagebrush Plain Travel Scene (432x150).
-- Used when terrain == "desert" (Great Divide Basin / Green River / Snake River Plain).
-- Every layer tiles horizontally (K.wrap) and is also written on its own, so trail_view.gd
-- scrolls clouds, the far bench, the buttes and basin, and the trail strip (y = 100..150)
-- at different speeds. The flattened picture backs the hunting screen.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 1850)
K.wrap = true

----------------------------------------------------------------- 1. Sun-bleached Desert Sky
K.layer("sky", function()
  K.rect(0, 0, W, 16, "sky_top")
  K.blend(0, 16, W, "sky_top", "sky")
  K.rect(0, 19, W, 20, "sky")
  K.blend(0, 39, W, "sky", "light_blue")
  K.rect(0, 42, W, 16, "light_blue")
  K.blend(0, 58, W, "light_blue", "mist")
  K.rect(0, 61, W, 10, "mist")
  K.blend(0, 71, W, "mist", "sand")
  K.rect(0, 74, W, 16, "sand")
end)

K.layer("clouds", function()
  K.cloud(42, 16, 1.35)
  K.cloud(298, 14, 1.45)
end)

----------------------------------------------------------------- 2. Stepped Rimrock Buttes & Alkali Basin
K.layer("far", function()
  -- Far hazy badlands bench
  for x = 0, W - 1 do
    local hy = 68 + math.floor(3 * math.sin(tau * x / 432.0 + 0.5) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 88 do
      K.px(x, y, (y == hy) and "sand" or "clap_sh")
    end
  end
end)

K.layer("mid", function()

  -- Stepped Western sandstone mesa/butte with vertical cliff wall + eroded talus skirt
  local function butte(x0, x1, top_y, base_y, shoulder_x, notch_x)
    local cliff_bot = top_y + math.floor((base_y - top_y) * 0.46)
    for y = top_y, base_y do
      local dy = y - top_y
      local lx, rx
      if y <= cliff_bot then
        -- Steep near-vertical rimrock cap
        lx = x0 - math.floor(dy * 0.35) - ((y % 4 == 0) and 1 or 0)
        rx = x1 + math.floor(dy * 0.42) + ((y % 3 == 0) and 1 or 0)
      else
        -- Flaring talus apron below the cliff bench
        local ty = y - cliff_bot
        local c_dy = cliff_bot - top_y
        lx = x0 - math.floor(c_dy * 0.35 + ty * 1.35 + 1.5 * math.sin(y * 0.4))
        rx = x1 + math.floor(c_dy * 0.42 + ty * 1.45 + 1.5 * math.cos(y * 0.35))
      end

      -- Internal spur ridge separating sunlit left face from shaded right face
      local ridge = shoulder_x + math.floor((y - top_y) * 0.25 + 2 * math.sin(y * 0.3))

      for x = lx, rx do
        -- Optional erosional notch along top rim
        if y < top_y + 3 and math.abs(x - notch_x) <= (top_y + 2 - y) then
          -- skip notch pixel
        else
          local lit = (x <= ridge)
          local c
          if y <= top_y + 1 then
            c = lit and "cream" or "sand"
          elseif y <= cliff_bot then
            -- Stratified vertical sandstone cliff bands
            local band = (y + ((x % 7 == 0) and 1 or 0)) % 6
            if band == 0 then
              c = lit and "sand" or "ochre"
            elseif band == 3 then
              c = lit and "rust" or "wood"
            else
              c = lit and "ochre" or "rust"
            end
            if x == ridge or x == ridge + 1 then c = "gold" end
          else
            -- Talus apron with radiating scree cones & horizontal sandstone ledges
            local ty = y - cliff_bot
            local fan = math.floor((x - shoulder_x) * 4 / math.max(6, ty + 6))
            if ty % 6 == 0 then
              c = lit and "sand" or "ochre"
            elseif fan % 3 == 0 then
              c = lit and "rust" or "wood"
            elseif fan % 3 == 1 and lit then
              c = (ty % 2 == 0) and "sand" or "ochre"
            else
              c = lit and "ochre" or "rust"
            end
          end
          K.px(x, y, c)
        end
      end
    end
  end

  -- Three asymmetric rimrock mesas/buttes across the basin
  butte(34,  96,  50, 88, 62,  76)
  butte(188, 236, 55, 88, 208, 218)
  butte(324, 392, 47, 88, 354, 368)
  -- Smaller eroded pinnacle beside the middle butte
  butte(252, 266, 62, 88, 258, 260)

  -- Sun-baked basin floor & alkali washes (y = 88..99)
  K.rect(0, 88, W, 12, "sand")
  K.dither(0, 88, W, 3, "clap_sh", "sand")
  -- Subtle dry alkali pan streaks on the desert floor
  for _, pan in ipairs({{112, 91, 46}, {272, 92, 38}}) do
    K.rect(pan[1], pan[2], pan[3], 2, "cream")
    K.rect(pan[1] + 6, pan[2] - 1, pan[3] - 12, 1, "cream")
  end
  for i = 1, 280 do
    local x = K.rnd(W)
    local y = 89 + K.rnd(11)
    K.px(x, y, (i % 4 == 0) and "sage" or ((i % 2 == 0) and "ochre" or "clap_sh"))
  end
end)

----------------------------------------------------------------- 3. Horizontally Tileable Desert Trail (y = 100..150)
K.layer("ground", function()
  K.rect(0, 100, W, 50, "sand")
  K.dither(0, 100, W, 4, "clap_sh", "sand")

  for x = 0, W - 1 do
    local wave = math.floor(1.8 * math.sin(tau * x / 432.0) + 1.0 * math.cos(tau * x / 216.0))
    local top = 112 + wave
    local bot = 139 + wave

    K.px(x, top - 1, "cream")
    K.rect(x, top, 1, bot - top, "ochre")
    K.rect(x, top + 11, 1, 5, "gold")
    K.px(x, bot, "rust")

    local rut1 = top + 9
    local rut2 = top + 21
    if (x % 18) ~= 0 then
      K.px(x, rut1 - 1, "cream"); K.px(x, rut1, "rust"); K.px(x, rut1 + 1, "dirt_dk")
    end
    if ((x + 9) % 18) ~= 0 then
      K.px(x, rut2 - 1, "cream"); K.px(x, rut2, "rust"); K.px(x, rut2 + 1, "dirt_dk")
    end
  end

  -- Desert grit, alkali patches & dry pebbles
  for i = 1, 1100 do
    local x = K.rnd(W)
    local y = 100 + K.rnd(50)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    else
      K.px(x, y, (i % 4 == 0) and "cream" or ((i % 2 == 0) and "ochre" or "clap_sh"))
    end
  end

  -- Dry sagebrush bushes & desert rocks along the margins of the track
  local function sage_bush(sx, sy)
    K.shadow(sx - 4, sy + 1, 9)
    K.ellipse(sx, sy - 2, 4, 2, "leaf")
    K.ellipse(sx - 1, sy - 3, 3, 2, "sage")
    K.px(sx, sy, "wood"); K.px(sx - 2, sy - 4, "clap_sh")
  end
  for _, sx in ipairs({18, 62, 108, 154, 204, 252, 302, 354, 402}) do
    sage_bush(sx, 107 + (sx % 3))
  end
  for _, sx in ipairs({34, 86, 136, 188, 238, 286, 336, 384, 420}) do
    sage_bush(sx, 146 - (sx % 3))
  end
end)

-- winter: snow lies on the flats and the mesa tops; the road is trodden to mud
K.season_extra = {
  {season="winter", y0=100, y1=150, map={ochre="silt", gold="silt_lt", sand="white", clap_sh="stone_lt", rust="silt_dk", cream="white"}},
  {season="winter", map={sand="white", clap_sh="stone_lt"}},
}
K.save("travel_desert")
K.save_layers({sky = "travel_desert_sky", clouds = "travel_desert_clouds", far = "travel_desert_far", mid = "travel_desert_mid", ground = "travel_desert_ground"})

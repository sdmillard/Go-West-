-- Regional Mountain Travel Scene (432x150).
-- Used when terrain == "mountains". The layers are also written on their own and every one
-- tiles horizontally (K.wrap), so ui/trail_view.gd scrolls them at different speeds:
-- clouds, the far range, the near peaks and timber, and the trail strip (y = 100..150) that
-- matches the wagon & oxen at y = 103..139. The flattened picture backs the hunting screen.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 1849)
K.wrap = true

----------------------------------------------------------------- 1. High Alpine Sky
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 18, "sky")
  K.blend(0, 58, W, "sky", "light_blue")
  K.rect(0, 61, W, 24, "light_blue")
end)

K.layer("clouds", function()
  K.cloud(34, 18, 1.3)
  K.cloud(194, 14, 1.1)
  K.cloud(328, 20, 1.4)
end)

----------------------------------------------------------------- 2. Craggy Granite Peaks & Snow Couloirs
local function mountain(cx, top_y, base_y, w_left, w_right, style)
    for y = top_y, base_y do
      local t = (y - top_y) / math.max(1, (base_y - top_y))
      local jag_l = math.floor(2.5 * math.sin(y * 0.27 + cx * 0.1) + 1.5 * math.cos(y * 0.53))
      local jag_r = math.floor(2.5 * math.cos(y * 0.23 + cx * 0.13) + 1.5 * math.sin(y * 0.47))
      local lx = cx - math.floor(w_left * (t ^ 0.90)) + jag_l
      local rx = cx + math.floor(w_right * (t ^ 0.92)) + jag_r
      local ridge = cx + math.floor((w_right - w_left) * 0.18 * t + 4.0 * math.sin(y * 0.19 + cx))
      local sec_ridge = lx + math.floor((ridge - lx) * 0.52 + 2.0 * math.cos(y * 0.31))

      for x = lx, rx do
        local c
        if style == "far" then
          c = (x <= ridge) and "haze" or "far_hill"
          if t < 0.26 and x <= ridge and ((x + y) % 2 == 0) then
            c = "mist"
          end
        else
          if x <= ridge then
            -- Sunlit upper-left granite face with craggy snowfields & couloir fingers
            local couloir1 = math.abs((x - lx) - math.floor((ridge - lx) * 0.32)) <= 2
            local couloir2 = math.abs((x - lx) - math.floor((ridge - lx) * 0.72)) <= 2
            local snow_line = 0.28 + 0.10 * math.sin(x * 0.35 + cx) + ((couloir1 or couloir2) and 0.22 or 0.0)
            if t < snow_line then
              c = (x <= lx + 3 or x == ridge) and "white" or "cream"
            elseif x <= sec_ridge then
              c = ((x + y * 2) % 5 == 0) and "mist" or "light_blue"
            else
              c = ((x + y) % 4 == 0) and "light_blue" or "haze"
            end
          else
            -- Shaded right granite face with slate-blue arêtes and shadow gullies
            local rel = (x - ridge) / math.max(1, rx - ridge)
            if t < 0.22 and x <= ridge + 3 then
              c = "mist"
            elseif rel < 0.46 + 0.10 * math.sin(y * 0.25) then
              c = "sky_top"
            elseif rel < 0.54 + 0.10 * math.sin(y * 0.25) then
              c = ((x + y) % 2 == 0) and "sky_top" or "blue"
            else
              c = "blue"
            end
          end
        end
        K.px(x, y, c)
      end
    end
  end

K.layer("far", function()
  -- Far background range (hazy blue-slate)
  mountain(38,  34, 88, 56, 62, "far")
  mountain(168, 28, 88, 74, 78, "far")
  mountain(296, 30, 88, 70, 74, "far")
  mountain(404, 36, 88, 54, 48, "far")
end)

K.layer("mid", function()
  -- Prominent foreground Wind River / Rocky Mountain peaks
  mountain(98,  16, 92, 82, 88, "near")
  mountain(232, 20, 92, 78, 84, "near")
  mountain(354, 18, 92, 80, 78, "near")

  -- Wooded subalpine foothills & dense timberline (y = 74..99)
  for x = 0, W - 1 do
    local fh = 77 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 3 * math.cos(tau * x / 144.0))
    for y = fh, 99 do
      K.px(x, y, (y < fh + 2) and "far_hill" or ((y < fh + 7) and "teal" or "pine"))
    end
  end
  -- Layered subalpine firs along the base of the mountains
  for tx = 6, W - 6, 12 do
    local ty = 90 + (tx % 5)
    local th = 11 + (tx % 5)
    K.conifer(tx, ty, th, "ink", "pine", "teal")
  end
  for tx = 12, W - 8, 17 do
    local ty = 96 + (tx % 4)
    local th = 14 + (tx % 6)
    K.conifer(tx, ty, th, "ink", "pine", "leaf")
  end
end)

----------------------------------------------------------------- 3. Horizontally Tileable Mountain Trail (y = 100..150)
K.layer("ground", function()
  K.rect(0, 100, W, 50, "sage")
  K.dither(0, 100, W, 4, "pine", "sage")
  K.rect(0, 104, W, 46, "grass")
  K.dither(0, 142, W, 8, "grass", "pine")

  for x = 0, W - 1 do
    local wave = math.floor(2.0 * math.sin(tau * x / 432.0) + 1.0 * math.cos(tau * x / 216.0))
    local top = 112 + wave
    local bot = 139 + wave

    -- Rocky mountain road bed (granite gravel & ochre earth)
    K.px(x, top - 1, "sand")
    K.px(x, top, "clap_sh")
    K.rect(x, top + 1, 1, bot - top - 2, "ochre")
    K.rect(x, top + 11, 1, 5, "clap_sh")
    K.px(x, bot - 1, "rust")
    K.px(x, bot, "deep")

    -- Dual wheel ruts
    local rut1 = top + 9
    local rut2 = top + 21
    if (x % 16) ~= 0 then
      K.px(x, rut1 - 1, "sand"); K.px(x, rut1, "deep"); K.px(x, rut1 + 1, "rust")
    end
    if ((x + 8) % 16) ~= 0 then
      K.px(x, rut2 - 1, "sand"); K.px(x, rut2, "deep"); K.px(x, rut2 + 1, "rust")
    end
  end

  -- Alpine gravel, pine needles & rocky outcrops along the trail margins
  for i = 1, 1100 do
    local x = K.rnd(W)
    local y = 100 + K.rnd(50)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "clap_sh" then
      K.px(x, y, (i % 3 == 0) and "sand" or ((i % 2 == 0) and "roof_lt" or "rust"))
    else
      K.px(x, y, (i % 3 == 0) and "pine" or ((i % 2 == 0) and "sage" or "leaf"))
    end
  end

  for _, bx in ipairs({24, 96, 184, 276, 358, 412}) do
    K.boulder(bx, 107 + (bx % 3), 4, 2)
  end
  for _, bx in ipairs({48, 146, 232, 324, 396}) do
    K.boulder(bx, 145, 5, 2)
  end
end)

-- winter: the road is trodden to mud through the snow
K.flat_snow = true
K.season_extra = {
  {season="winter", y0=100, y1=150, map={ochre="silt", sand="stone_lt", clap_sh="stone_lt", rust="silt_dk", leaf="white", pine="stone_lt"}},
}
K.save("travel_mountains")
K.save_layers({sky = "travel_mountains_sky", clouds = "travel_mountains_clouds", far = "travel_mountains_far", mid = "travel_mountains_mid", ground = "travel_mountains_ground"})

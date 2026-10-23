-- Devil's Gate on the Sweetwater River (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Sheer, narrow 300-foot dark granite gorge cleft through the Sweetwater Rocks ridge
-- by the Sweetwater River, while the wagon road detours around the lower right shoulder.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184814)

----------------------------------------------------------------- 1. Sky & Distant Sweetwater Range
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 12, "light_blue")
  K.blend(0, 71, W, "light_blue", "mist")
  K.rect(0, 74, W, 14, "mist")

  K.cloud(38, 16, 1.35)
  K.cloud(308, 14, 1.4)

  for x = 0, W - 1 do
    local hy = 68 + math.floor(4 * math.sin(tau * x / 432.0 + 0.4) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 92 do
      K.px(x, y, (y == hy) and "mist" or "far_hill")
    end
  end
end)

----------------------------------------------------------------- 2. Sweetwater Plain & Devil's Gate Granite Gorge
K.layer("granite_cleft", function()
  K.rect(0, 92, W, 14, "sage")
  K.dither(0, 102, W, 6, "sage", "grass")
  K.rect(0, 108, W, 42, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Left granite cliff wall of Devil's Gate (x = 42..192, y = 20..112)
  for y = 20, 112 do
    local t = (y - 20) / 92.0
    local lx = math.floor(68 - t * 26 + 3 * math.sin(y * 0.22))
    local rx = math.floor(178 + t * 14 + 2 * math.cos(y * 0.35))
    if y < 38 then
      lx = math.floor(124 - (y - 20) * 3.1)
      rx = math.floor(142 + (y - 20) * 2.0)
    end
    local ridge = lx + math.floor((rx - lx) * 0.58 + 3 * math.sin(y * 0.18))
    local sec_ridge = lx + math.floor((ridge - lx) * 0.45 + 2 * math.cos(y * 0.25))
    for x = lx, rx do
      -- Luminance order (light -> dark): sand -> clap_sh -> ox_lt -> wood -> roof_lt -> roof -> deep -> ink
      local c
      if x <= sec_ridge then
        c = (y % 8 == 0) and "ox_lt" or "clap_sh"
        if x <= lx + 2 then c = "sand" end
      elseif x <= ridge then
        c = (y % 7 == 0) and "roof_lt" or "ox_lt"
      else
        -- Sheer vertical shadow wall inside the gorge cleft
        c = (x > rx - 6) and "ink" or ((y % 6 == 0) and "roof" or "deep")
      end
      if y < 110 or ((x + y) % 2 == 0) then K.px(x, y, c) end
    end
  end

  -- Right granite cliff wall of Devil's Gate (x = 208..348, y = 22..112)
  for y = 22, 112 do
    local t = (y - 22) / 90.0
    local lx = math.floor(218 - t * 10 + 2 * math.sin(y * 0.31))
    local rx = math.floor(306 + t * 42 + 3 * math.cos(y * 0.24))
    if y < 40 then
      lx = math.floor(252 - (y - 22) * 1.9)
      rx = math.floor(272 + (y - 22) * 1.9)
    end
    local ridge = lx + math.floor((rx - lx) * 0.36 + 3 * math.cos(y * 0.19))
    for x = lx, rx do
      local c
      if x <= lx + 5 then
        c = "deep"
      elseif x <= ridge then
        c = (y % 7 == 0) and "ox_lt" or "clap_sh"
      else
        c = (x > ridge + 18) and ((y % 6 == 0) and "roof" or "deep") or ((y % 8 == 0) and "roof_lt" or "wood")
      end
      if y < 110 or ((x + y) % 2 == 0) then K.px(x, y, c) end
    end
  end

  -- Scrubby pines clinging to the granite ledges
  for _, pt in ipairs({{82, 48}, {148, 38}, {246, 40}, {314, 56}, {336, 86}}) do
    K.conifer(pt[1], pt[2], 11, "ink", "pine", "leaf")
  end
end)

----------------------------------------------------------------- 3. Sweetwater River Emerging from the Chasm & Detour Road
K.layer("river_and_road", function()
  -- Sweetwater River boiling out of the narrow dark chasm (x = 188..212 at y = 86)
  K.poly({{190, 86}, {210, 86}, {238, 150}, {168, 150}}, "blue")
  K.poly({{193, 86}, {207, 86}, {232, 150}, {174, 150}}, "sky_top")
  K.poly({{196, 86}, {204, 86}, {224, 150}, {182, 150}}, "sky")

  -- Whitewater rapids & foam surging out of the granite gate
  for y = 88, 148, 3 do
    local t = (y - 86) / 64.0
    local cx = 200 + math.floor(3 * math.sin(y * 0.25))
    local hw = math.floor(5 + t * 18)
    K.rect(cx - hw + 2, y, 4 + (y % 4), 1, "white")
    if y % 6 == 0 then
      K.rect(cx + 2, y + 1, 5, 1, "light_blue")
    end
  end

  -- Wagon detour road climbing around the lower right shoulder of the ridge
  K.poly({{302, 150}, {346, 114}, {372, 84}, {384, 86}, {366, 122}, {352, 150}}, "ochre")
  K.poly({{312, 150}, {350, 116}, {374, 85}, {380, 86}, {362, 122}, {344, 150}}, "gold")
  K.line(308, 149, 374, 85, "rust")
  K.line(346, 149, 381, 86, "rust")

  for i = 1, 600 do
    local x = K.rnd(W)
    local y = 94 + K.rnd(56)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end

  -- Parked wagon & emigrant peering into the granite chasm
  K.wagon(24, 143, 1)
  K.person(156, 132, "blue", "sand", false)
end)

K.save("location_devils_gate")

-- Independence Rock ("The Register of the Desert") on the Sweetwater (432x150).
-- Historical reference: Joel Palmer's 1845 journal & WESTERN_REFERENCES.md.
-- Massive rounded turtle-back granite exfoliation dome rising from the Sweetwater plain,
-- with exfoliation joints, carved/painted emigrant inscriptions, and the Sweetwater River in front.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184813)

----------------------------------------------------------------- 1. Sky & Sweetwater Rocks Horizon
K.layer("sky", function()
  K.rect(0, 0, W, 16, "blue")
  K.blend(0, 16, W, "blue", "sky_top")
  K.rect(0, 19, W, 18, "sky_top")
  K.blend(0, 37, W, "sky_top", "sky")
  K.rect(0, 40, W, 16, "sky")
  K.blend(0, 56, W, "sky", "light_blue")
  K.rect(0, 59, W, 12, "light_blue")
  K.blend(0, 71, W, "light_blue", "mist")
  K.rect(0, 74, W, 10, "mist")

  K.cloud(40, 16, 1.35)
  K.cloud(304, 14, 1.4)

  for x = 0, W - 1 do
    local hy = 66 + math.floor(4 * math.sin(tau * x / 432.0 + 0.5) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 88 do
      K.px(x, y, (y == hy) and "mist" or "far_hill")
    end
  end
end)

----------------------------------------------------------------- 2. Sweetwater Plain & Independence Rock Granite Dome
K.layer("granite_dome", function()
  -- Sagebrush & alkali plain behind the Sweetwater River
  K.rect(0, 88, W, 24, "sage")
  K.dither(0, 106, W, 6, "sage", "grass")
  K.rect(0, 112, W, 38, "grass")

  -- Massive rounded granite exfoliation dome (x = 72..362, y = 44..116)
  local cx, cy, rx, ry = 217, 108, 146, 62
  for y = 46, 114 do
    local dy = (y - cy) / ry
    local span = math.sqrt(math.max(0.0, 1.0 - dy * dy))
    -- Slightly asymmetric turtle-back profile with a broad saddle dip in the middle-right
    local x0 = cx - math.floor(rx * span)
    local x1 = cx + math.floor(rx * span)
    for x = x0, x1 do
      local dx = (x - cx) / rx
      local saddle = math.floor(4 * math.exp(-((dx - 0.15) * 4.5) ^ 2))
      if y >= 46 + saddle then
        -- Smooth upper-left sunlight across the rounded granite dome
        -- Luminance order (light -> dark): cream -> sand -> clap_sh -> ox_lt -> wood -> roof_lt -> deep
        local light = -dx * 0.58 - dy * 0.48
        local dither = ((x + y) % 2 == 0) and 0.04 or -0.04
        local v = light + dither
        local c
        if v > 0.34 then
          c = "cream"
        elseif v > 0.14 then
          c = "sand"
        elseif v > -0.10 then
          c = "clap_sh"
        elseif v > -0.28 then
          c = "ox_lt"
        else
          c = "roof_lt"
        end
        -- Subtle granite grain speckles
        if (x * 7 + y * 13) % 29 == 0 then
          c = (v > 0) and "sand" or "wood"
        end
        K.px(x, y, c)
      end
    end
  end

  -- Prominent weathered granite crevices & drainage seams down the dome face
  for _, seam in ipairs({{124, 62, 136, 112}, {178, 52, 188, 113}, {234, 54, 246, 113}, {288, 60, 302, 112}}) do
    K.line(seam[1], seam[2], seam[3], seam[4], "wood")
    K.line(seam[1] + 1, seam[2], seam[3] + 1, seam[4], "deep")
    K.line(seam[1] - 1, seam[2] + 2, seam[3] - 1, seam[4], "sand")
  end

  -- Tiny suggestion of tar/red-paint emigrant names registered near the base of the rock
  for _, nx in ipairs({146, 158, 198, 212, 256}) do
    K.rect(nx, 104 + (nx % 3), 4, 1, (nx % 2 == 0) and "rust" or "deep")
    K.rect(nx + 1, 106 + (nx % 3), 3, 1, "cream")
  end

  -- Granite boulders & talus at the base of the dome
  for _, bx in ipairs({88, 142, 206, 268, 336}) do
    K.boulder(bx, 113 + (bx % 2), 5, 2)
  end
end)

----------------------------------------------------------------- 3. Sweetwater River, Trail & Wagon
K.layer("sweetwater_and_wagon", function()
  -- Wagon trail curving past the base of Independence Rock
  K.poly({{184, 114}, {210, 114}, {304, 150}, {236, 150}}, "ochre")
  K.poly({{190, 114}, {204, 114}, {288, 150}, {248, 150}}, "gold")

  -- Sweetwater River channel winding across the foreground (y = 128..141)
  K.rect(0, 128, W, 1, "sand")
  K.rect(0, 129, W, 12, "sky_top")
  K.rect(0, 131, W, 8, "sky")
  for x = 8, W - 8, 16 do
    K.rect(x, 132 + (x % 5), 5, 1, (x % 3 == 0) and "white" or "light_blue")
  end
  K.rect(0, 141, W, 1, "sand")

  for i = 1, 550 do
    local x = K.rnd(W)
    local y = 90 + K.rnd(60)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    end
  end

  -- Emigrant wagon & figures examining the inscriptions at the rock's base
  K.person(164, 115, "rust", "sand", false)
  K.person(172, 116, "blue", "bonnet", true)
  K.wagon(24, 143, 1)
end)

K.save("location_independence_rock")

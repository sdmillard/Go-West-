-- Courthouse and Jail Rocks ("Solitary Tower") (432x150).
-- Historical reference: History Nebraska & Joel Palmer's 1845 journal.
-- The paired Brule siltstone/sandstone monoliths rising from the Pumpkin Creek / North Platte
-- plain: broad stepped castle-like Courthouse Rock on the left, narrower Jail Rock on the right.
local K = dofile(app.params.kit)
local W, H = 432, 150
local tau = math.pi * 2.0

K.canvas(W, H, 184809)

----------------------------------------------------------------- 1. High-Plains Sky & Distant Ridge
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

  K.cloud(38, 17, 1.3)
  K.cloud(308, 13, 1.45)

  for x = 0, W - 1 do
    local hy = 69 + math.floor(3 * math.sin(tau * x / 432.0 + 0.4) + 2 * math.cos(tau * x / 144.0))
    for y = hy, 88 do
      K.px(x, y, (y == hy) and "mist" or "far_hill")
    end
  end
end)

----------------------------------------------------------------- 2. High Prairie Plain & Trail
K.layer("prairie", function()
  K.rect(0, 88, W, 16, "sage")
  K.dither(0, 100, W, 6, "sage", "grass")
  K.rect(0, 106, W, 44, "grass")
  K.dither(0, 140, W, 10, "grass", "pine")

  -- Wagon road curving across the plain toward Chimney Rock
  K.poly({{176, 100}, {204, 100}, {310, 150}, {232, 150}}, "ochre")
  K.poly({{182, 100}, {198, 100}, {292, 150}, {248, 150}}, "gold")
  K.line(180, 101, 244, 149, "rust")
  K.line(196, 101, 294, 149, "rust")
  K.line(179, 101, 243, 149, "sand")
  K.line(195, 101, 293, 149, "sand")

  for i = 1, 800 do
    local x = K.rnd(W)
    local y = 90 + K.rnd(60)
    local cur = K.at(x, y)
    if cur == "grass" or cur == "sage" then
      K.px(x, y, (i % 3 == 0) and "leaf" or ((i % 2 == 0) and "sage" or "gold"))
    elseif cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 3 == 0) and "sand" or "rust")
    end
  end
end)

----------------------------------------------------------------- 3. Courthouse Rock & Jail Rock Monoliths + Wagon
K.layer("monoliths_and_wagon", function()
  local function monolith(cx, top_y, sh_y, base_y, top_w, sh_w, base_w, ridge_off)
    for y = top_y, base_y do
      local hw
      if y <= sh_y then
        local t = (y - top_y) / math.max(1, sh_y - top_y)
        hw = math.floor(top_w + t * (sh_w - top_w) * 0.35)
        if y == sh_y - 6 or y == sh_y then hw = hw + 3 end
      else
        local t = (y - sh_y) / math.max(1, base_y - sh_y)
        hw = math.floor(sh_w + (t ^ 1.15) * (base_w - sh_w))
      end
      local lx = cx - hw - math.floor(1.5 * math.sin(y * 0.35))
      local rx = cx + hw + math.floor(1.5 * math.cos(y * 0.31))
      local ridge = cx + ridge_off + math.floor((y - top_y) * 0.14)

      for x = lx, rx do
        local lit = (x <= ridge)
        local c
        if y <= top_y + 2 then
          c = lit and "white" or "cream"
        elseif y <= sh_y then
          local band = (y + ((x % 9 == 0) and 1 or 0)) % 6
          if band == 0 then
            c = lit and "cream" or "sand"
          elseif band == 3 then
            c = lit and "ochre" or "rust"
          else
            c = lit and "sand" or "ochre"
          end
          if (x - cx) % 11 == 0 and y > top_y + 4 then
            c = lit and "ochre" or "rust"
          end
        else
          local ty = y - sh_y
          local fan = math.floor((x - cx) * 3 / math.max(5, ty + 4))
          if ty % 5 == 0 then
            c = lit and "cream" or "sand"
          elseif fan % 3 == 0 then
            c = lit and "ochre" or "rust"
          else
            c = lit and "sand" or "ochre"
          end
        end
        -- Feather the bottom 2 rows of the talus into the sage prairie
        if y < base_y - 1 or ((x + y) % 2 == 0) then
          K.px(x, y, c)
        end
      end
    end
  end

  -- Courthouse Rock (left, broad massive cupola-like sandstone bluff + western buttress)
  monolith(132, 36, 70, 102, 24, 34, 58, 4)
  monolith(90,  62, 78, 101, 10, 15, 26, 2)

  -- Jail Rock (right, narrower freestanding tower across the saddle gap)
  monolith(278, 42, 74, 101, 11, 16, 36, 2)

  -- Parked emigrant wagon & scout admiring the twin landmarks
  K.wagon(24, 143, 1)
  K.person(82, 142, "blue", "sand", false)
end)

K.save("location_courthouse_rock")

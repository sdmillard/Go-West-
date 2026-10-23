-- Chimney Rock, North Platte Valley, 1848 (432x150 landmark arrival scene).
-- Stratified Brule clay & Gering sandstone spire rising from a gullied conical base,
-- flanked by North Platte badland bluffs, braided river valley, and emigrant train on the road.
local K = dofile(app.params.kit)
local W, H = 432, 150
local HORIZON = 86

K.canvas(W, H, 1848)

----------------------------------------------------------------- 1. Sky
K.layer("sky", function()
  K.rect(0, 0, W, 20, "sky_top")
  K.blend(0, 20, W, "sky_top", "sky")
  K.rect(0, 23, W, 24, "sky")
  K.blend(0, 47, W, "sky", "light_blue")
  K.rect(0, 50, W, 20, "light_blue")
  K.blend(0, 70, W, "light_blue", "mist")
  K.rect(0, 73, W, HORIZON - 73 + 4, "mist")

  K.cloud(26, 18, 1.3)
  K.cloud(112, 34, 0.7)
  K.cloud(296, 15, 1.4)
  K.cloud(382, 36, 0.8)
end)

----------------------------------------------------------------- 2. Distant North Platte Valley & Badland Escarpments
K.layer("valley_and_bluffs", function()
  for x = 0, W - 1 do
    local ridge = math.floor(6 + 3 * math.sin(x / 42.0) + 2 * math.cos(x / 17.0))
    for y = HORIZON - ridge, HORIZON + 2 do
      K.px(x, y, (y == HORIZON - ridge) and "mist" or "far_hill")
    end
  end

  local function draw_bluff_range(x0, x1, base_y, profile_fn)
    for x = x0, x1 do
      local top_y, ridge_x = profile_fn(x)
      if top_y < base_y then
        for y = top_y, base_y do
          local lit = (x < ridge_x)
          local cliff_zone = (y < top_y + math.floor((base_y - top_y) * 0.45))
          local c
          if lit then
            c = cliff_zone and "sand" or "gold"
            if y == top_y or y == top_y + 1 then c = "cream" end
            if y % 5 == 0 then c = "cream"
            elseif y % 5 == 1 then c = "ochre" end
          else
            c = cliff_zone and "rust" or "wood"
            if y % 5 == 0 then c = "ochre"
            elseif y % 5 == 1 then c = "deep" end
          end
          K.px(x, y, c)
        end
        if ((x * 7 + top_y) % 19 == 0) and top_y + 2 < base_y - 8 then
          local c_len = 3 + (x % 4)
          for gy = top_y + 2, math.min(base_y - 6, top_y + 2 + c_len) do
            K.px(x + ((gy > top_y + 4) and 1 or 0), gy, (x < ridge_x) and "ochre" or "deep")
          end
        end
      end
    end
  end

  draw_bluff_range(0, 128, 92, function(x)
    if x < 54 then
      return 64 + math.floor(2 * math.sin(x * 0.15)), 38
    elseif x < 72 then
      local t = (x - 54) / 18.0
      return math.floor(65 + 9 * math.sin(t * math.pi)), 62
    elseif x < 98 then
      return 68, 86
    else
      return 68 + math.floor((x - 98) * 0.8), 86
    end
  end)

  draw_bluff_range(296, W - 1, 92, function(x)
    if x < 326 then
      return 92 - math.floor((x - 296) * 0.75), 348
    elseif x < 378 then
      return 69 + ((x > 354) and 2 or 0), 354
    elseif x < 406 then
      return 73, 392
    else
      return 73 + math.floor((x - 406) * 0.65), 392
    end
  end)

  K.rect(0, 91, W, 5, "sand")
  K.blend(0, 93, W, "sand", "sage")
end)

----------------------------------------------------------------- 3. Chimney Rock (Conical Pedestal & Spire)
K.layer("chimney_rock", function()
  local cx = 210
  local base_y = 101
  local cone_top_y = 49
  local spire_top_y = 11

  for y = cone_top_y, base_y do
    local t = (y - cone_top_y) / (base_y - cone_top_y)
    local half_w = math.floor(9 + 16 * t + 53 * (t * t))
    local left_x = cx - half_w - math.floor(2 * t * math.sin(y * 0.35))
    local right_x = cx + half_w + math.floor(3 * t * math.cos(y * 0.27))
    local ridge_x = cx + 2 + math.floor(7 * t + 2 * math.sin(y * 0.22))

    for x = left_x, right_x do
      local c = "ochre"
      if x <= ridge_x then
        if x - left_x <= 2 then
          c = "cream"
        elseif x < left_x + math.floor((ridge_x - left_x) * 0.48) then
          c = "sand"
        elseif x < ridge_x - 3 then
          c = "gold"
        else
          c = "ochre"
        end
      else
        if x - ridge_x <= 5 then
          c = "rust"
        elseif x < right_x - 6 then
          c = "wood"
        else
          c = "rust"
        end
      end

      if y % 6 == 0 then
        c = (x <= ridge_x) and "cream" or "ochre"
      elseif y % 6 == 1 then
        c = (x <= ridge_x) and "ochre" or "deep"
      end

      K.px(x, y, c)
    end

    for _, g in ipairs({{-0.52, "rust", "gold"}, {-0.22, "ochre", "cream"}, {0.18, "deep", "rust"}, {0.48, "deep", "wood"}}) do
      local gx = cx + math.floor(g[1] * half_w * 0.85) + math.floor(math.sin(y * 0.4 + g[1]*10))
      if gx > left_x + 3 and gx < right_x - 3 and t > 0.14 then
        K.px(gx, y, g[2])
        K.px(gx - 1, y, g[3])
      end
    end
  end

  for y = spire_top_y, 50 do
    local t = (y - spire_top_y) / (50 - spire_top_y)
    local left_w = math.floor(3 + 6 * (t ^ 1.4) + ((y % 9 == 0) and 1 or 0))
    local right_w = math.floor(3 + 6 * (t ^ 1.4) + ((y % 11 == 0) and 1 or 0))
    local lx = cx - left_w
    local rx = cx + right_w

    for x = lx, rx do
      local c = "gold"
      if x == lx or x == lx + 1 then
        c = (y < 24) and "white" or "cream"
      elseif x < cx then
        c = "sand"
      elseif x <= cx + 2 then
        c = "gold"
      elseif x < rx - 1 then
        c = "rust"
      else
        c = "wood"
      end

      if y % 6 == 0 then
        c = (x < cx) and "cream" or "deep"
      elseif y % 6 == 3 and x > cx then
        c = "ox_dk"
      end

      K.px(x, y, c)
    end

    if y >= spire_top_y + 4 and y <= 48 then
      local fx = cx + 1 + ((y > 31) and 1 or 0)
      K.px(fx, y, "deep")
      K.px(fx - 1, y, "ochre")
    end
  end

  K.rect(cx - 3, spire_top_y - 1, 3, 1, "cream")
  K.px(cx - 2, spire_top_y - 2, "white")
  K.px(cx + 1, spire_top_y - 1, "sand")

  for i = 1, 180 do
    local tx = cx - 84 + K.rnd(168)
    local ty = base_y - 3 + K.rnd(7)
    K.px(tx, ty, (i % 3 == 0) and "sage" or ((i % 2 == 0) and "ochre" or "sand"))
  end
end)

----------------------------------------------------------------- 4. Prairie Floor & Overland Trail
K.layer("prairie_and_road", function()
  K.rect(0, 95, W, H - 95, "sage")
  K.blend(0, 102, W, "sage", "grass")
  K.rect(0, 105, W, H - 105, "grass")
  K.blend(0, 128, W, "grass", "leaf")
  K.rect(0, 131, W, H - 131, "leaf")

  for i = 1, 1100 do
    local x = K.rnd(W)
    local y = 96 + K.rnd(H - 96)
    local c = (y < 110) and ((i % 3 == 0) and "sand" or "grass")
           or ((i % 4 == 0) and "gold" or ((i % 3 == 0) and "sage" or "leaf"))
    K.px(x, y, c)
    if y > 120 and i % 7 == 0 then K.px(x, y - 1, "sage") end
  end

  local function road_center(t)
    return math.floor(88 + 205 * (t ^ 0.85) + 12 * math.sin(t * 3.1))
  end

  for y = 102, H - 1 do
    local t = (y - 102) / (H - 1 - 102)
    local road_cx = road_center(t)
    local half_w = math.floor(7 + 34 * t)
    local lx = road_cx - half_w
    local rx = road_cx + half_w

    K.rect(lx - 3, y, 3, 1, (y % 2 == 0) and "sand" or "sage")
    K.rect(rx + 1, y, 3, 1, (y % 2 == 0) and "ochre" or "grass")

    for x = lx, rx do
      local c = "ochre"
      if x < lx + math.floor(half_w * 0.35) then c = "sand"
      elseif x > rx - math.floor(half_w * 0.25) then c = "dirt_dk" end
      K.px(x, y, c)
    end

    for _, rut_off in ipairs({-0.55, -0.15, 0.22, 0.58}) do
      local rx_pos = road_cx + math.floor(rut_off * half_w)
      K.px(rx_pos, y, "dirt_dk")
      if y % 2 == 0 then K.px(rx_pos + 1, y, "rust") end
      if t > 0.35 then K.px(rx_pos - 1, y, "gold") end
    end
  end

  for i = 1, 450 do
    local x = K.rnd(W)
    local y = 102 + K.rnd(H - 102)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "sand" then
      K.px(x, y, (i % 3 == 0) and "gold" or ((i % 2 == 0) and "rust" or "cream"))
    end
  end
end)

----------------------------------------------------------------- 5. Emigrant Train & Foreground Details
K.layer("figures_and_foreground", function()
  -- Distant lead wagon on the upper curve of the trail
  K.shadow(105, 110, 24)
  K.rect(108, 103, 16, 4, "blue")
  K.poly({{108, 103}, {107, 97}, {110, 94}, {122, 94}, {125, 97}, {124, 103}}, "cream")
  K.poly({{108, 103}, {107, 97}, {110, 94}, {113, 94}, {111, 103}}, "white")
  K.ellipse(111, 107, 3, 3, "deep"); K.px(111, 107, "ochre")
  K.ellipse(121, 107, 3, 3, "deep"); K.px(121, 107, "ochre")
  K.rect(94, 104, 8, 4, "ox_dk"); K.rect(93, 103, 3, 2, "sand"); K.px(93, 102, "white")
  K.rect(95, 108, 1, 2, "ink"); K.rect(100, 108, 1, 2, "ink")
  K.line(102, 106, 108, 106, "deep")

  -- Main foreground emigrant wagon halted on the trail heading west (facing -1)
  K.wagon(254, 134, -1)
  K.team(238, 133, -1, {"dark"}, {"red", false})
  K.team(206, 131, -1, {"dark"}, {"light", true})
  K.line(254, 127, 188, 124, "deep")
  K.line(254, 128, 188, 125, "wood")

  -- Emigrants paused on the road, looking & pointing up at Chimney Rock
  K.person(168, 129, "blue", "deep", false)
  K.line(170, 121, 174, 117, "blue")
  K.px(175, 116, "skin")

  K.person(160, 131, "red", "bonnet", true)
  K.person(238, 137, "wood", "roof", false)

  local function boulder(bx, by, rx, ry)
    K.shadow(bx - rx, by + ry, rx * 2 + 2)
    K.ellipse(bx, by, rx, ry, "rust")
    K.ellipse(bx - 1, by - 1, rx - 1, ry - 1, "ochre")
    K.ellipse(bx - 2, by - 2, math.max(1, rx - 3), math.max(1, ry - 2), "sand")
    K.rect(bx - rx, by + ry - 1, rx * 2, 1, "deep")
  end
  boulder(28, 141, 7, 4)
  boulder(40, 144, 4, 2)
  boulder(388, 142, 6, 3)

  for _, sx in ipairs({14, 52, 84, 348, 372, 408}) do
    for dx = -4, 4, 2 do
      local h = 4 + K.rnd(4)
      K.line(sx + dx, 148, sx + dx + (dx < 0 and -1 or 1), 148 - h, "pine")
      K.px(sx + dx, 148 - h, "sage")
      K.px(sx + dx, 147 - h, "gold")
    end
  end
end)

K.save("location_chimney_rock")

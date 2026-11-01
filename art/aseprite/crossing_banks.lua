-- Regional banks for the river crossing world (720x300), shared by the scenes
-- river_crossing_sage, river_crossing_pine and river_crossing_oak. The plain
-- river_crossing.lua is the cottonwood prairie of Kansas and the Platte.
-- Same three-quarter view and the same NEAR and FAR bank outlines as river_crossing.lua
-- (and NEAR_BANK / FAR_BANK in ui/trail_view.gd, which clips the water to them). The water
-- stays transparent: trail_view fills and animates it.
--   sage  the Humboldt, the Snake, the Bear on Hensley's cutoff: pale alkali ground,
--         sagebrush and rabbitbrush, willow thickets at the water, rimrock on the far bank
--   pine  the Klamath and the White River below Mount Hood: ponderosa pine and fir over
--         short grass, grey boulder bars instead of sand
--   oak   the Rogue and the Umpqua: tawny cured grass with round white oaks, fir behind
return function(K, country, seed)
  local W, H = 720, 300
  local NEAR = {{0, 178}, {25, 189}, {50, 204}, {75, 212}, {100, 220}, {125, 237}, {150, 248}, {175, 269}, {200, 275}, {225, 288}, {250, 295}, {260, 300}, {0, 300}}
  local FAR = {{330, 0}, {360, 21}, {390, 26}, {420, 43}, {450, 62}, {480, 77}, {510, 90}, {540, 99}, {570, 125}, {600, 136}, {630, 150}, {660, 161}, {690, 182}, {720, 200}, {720, 0}}
  K.canvas(W, H, seed)

  local function shore(pts, n, x)
    for i = 1, n - 1 do
      local a, b = pts[i], pts[i + 1]
      if x >= a[1] and x <= b[1] then return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1]) end
    end
  end
  -- distance in rows from the water's edge, and which bank
  local function from_water(x, y)
    local sy = (x < 300) and shore(NEAR, 12, x) or shore(FAR, 14, x)
    return sy and math.abs(y - sy) or 99
  end

  -- colours of the wet edge, the beach and the ground beyond, by country
  local LOOK = {
    sage = {edge = "silt_dk", wet = "silt", beach = {"silt_lt", "silt_lt", "clap_sh", "sand"},
            ground = {"silt_lt", "silt_lt", "clap_sh", "sand", "sage", "silt_lt", "clap_sh", "stone"}},
    pine = {edge = "stone_ink", wet = "stone_dk", beach = {"stone", "stone_lt", "stone", "stone_dk", "sand"},
            ground = {"grass", "grass", "sage", "leaf", "grass", "silt", "sage"}},
    oak = {edge = "dirt_dk", wet = "clap_sh", beach = {"sand", "clap_sh", "sand", "gold"},
           ground = {"gold", "silt_lt", "gold", "sand", "ochre", "silt_lt", "sage", "gold"}},
  }
  local look = LOOK[country]

  K.layer("banks", function()
    K.poly(NEAR, "sage"); K.poly(FAR, "sage")
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        if K.at(x, y) == "sage" then
          local d = from_water(x, y)
          local r = K.rnd(23)
          if d < 2 then K.px(x, y, look.edge)
          elseif d < 4 then K.px(x, y, look.wet)
          elseif d < 10 + 3 * math.sin(x / 17) then K.px(x, y, look.beach[r % #look.beach + 1])
          else K.px(x, y, look.ground[r % #look.ground + 1]) end
        end
      end
    end
    -- the trail: a worn band of bare ground with a deeper rut along each wheel track
    local function ruts(x0, y0, x1, y1)
      for o = -7, 7 do
        local c = (math.abs(o) == 5) and "dirt_dk" or ((math.abs(o) == 4 or math.abs(o) == 6) and "ochre" or "gold")
        if country == "pine" and c == "gold" then c = "silt_lt" end
        if math.abs(o) < 7 or K.rnd(2) == 0 then K.line(x0 + o, y0 + o / 2, x1 + o, y1 + o / 2, c) end
      end
    end
    ruts(40, 307, 110, 272)
    ruts(520, 70, 680, -10)
    local function dry(x, y) local c = K.at(x, y); for _, g in ipairs(look.ground) do if c == g then return from_water(x, y) > 12 end end end
    if country == "sage" then
      -- sagebrush and yellow rabbitbrush scattered over the dry ground
      for i = 1, 420 do
        local x, y = 4 + K.rnd(W - 8), 4 + K.rnd(H - 4)
        if dry(x, y) then
          if K.rnd(4) == 0 then K.px(x, y, "gold"); K.px(x - 1, y - 1, "ochre"); K.px(x + 1, y - 1, "gold"); K.px(x, y - 2, "sand")
          else K.sage(x, y) end
        end
      end
    elseif country == "pine" then
      -- grey boulders strewn over the bars and the grass
      for i = 1, 90 do
        local x, y = 4 + K.rnd(W - 8), 4 + K.rnd(H - 4)
        local d = K.at(x, y) and from_water(x, y) or 0
        if d > 3 and d < 40 then
          local rw = 1 + K.rnd(3)
          K.ellipse(x, y, rw, math.max(1, rw - 1), "stone_dk"); K.ellipse(x - 1, y - 1, math.max(1, rw - 1), math.max(0, rw - 2), "stone")
          K.px(x - rw + 1, y - 1, "stone_lt")
        end
      end
      for i = 1, 200 do
        local x, y = K.rnd(W), K.rnd(H)
        if dry(x, y) then K.px(x, y, "leaf"); K.px(x - 1, y - 1, "grass"); K.px(x + 1, y - 1, "sage") end
      end
    else
      -- tufts of cured grass, a few still green
      for i = 1, 320 do
        local x, y = K.rnd(W), K.rnd(H)
        if dry(x, y) then K.px(x, y, (i % 5 == 0) and "grass" or "ochre"); K.px(x - 1, y - 1, "gold"); K.px(x + 1, y - 1, (i % 3 == 0) and "sage" or "sand") end
      end
    end
  end)

  K.layer("trees", function()
    local trees
    if country == "sage" then
      -- no timber: willow thickets at the water's edge only
      trees = {{372, 20, "willow"}, {440, 52, "willow"}, {530, 92, "willow"}, {610, 132, "willow"}, {676, 168, "willow"},
               {404, 34, "willow"}, {24, 196, "willow"}, {70, 220, "willow"}, {118, 240, "willow"}, {214, 290, "willow"}}
    elseif country == "pine" then
      trees = {{352, 10, "pine", 34}, {404, 6, "pine", 40}, {470, 22, "fir", 30}, {520, 30, "pine", 36}, {600, 44, "pine", 42},
               {660, 60, "fir", 34}, {700, 96, "pine", 38}, {560, 8, "fir", 28}, {640, 16, "pine", 30}, {696, 140, "fir", 26},
               {16, 226, "pine", 40}, {46, 262, "fir", 34}, {94, 282, "pine", 30}, {8, 296, "fir", 30}, {176, 300, "pine", 26}}
    else
      trees = {{372, 12, "oak", 1}, {446, 30, "oak", 1}, {520, 40, "fir", 32}, {596, 56, "oak", 1}, {650, 84, "oak", 1},
               {700, 122, "fir", 30}, {560, 16, "fir", 26}, {650, 26, "oak", 1}, {480, 66, "willow"}, {676, 164, "willow"},
               {22, 214, "oak", 1}, {50, 262, "oak", 1}, {80, 236, "willow"}, {140, 294, "oak", 1}, {206, 298, "willow"}}
    end
    table.sort(trees, function(a, b) return a[2] < b[2] end)
    for _, t in ipairs(trees) do
      if t[3] == "willow" then K.willow(t[1], t[2], 1)
      elseif t[3] == "oak" then K.elm(t[1], t[2], t[4])
      elseif t[3] == "pine" then K.conifer(t[1], t[2], t[4], "ink", "pine", "leaf")
      else K.conifer(t[1], t[2], t[4], "ink", "pine", "teal") end
    end
    -- driftwood fetched up on the near beach, a snag on the far one
    K.line(170, 270, 186, 276, "stone_dk"); K.line(171, 271, 185, 277, "stone_ink")
    K.line(612, 141, 626, 146, "stone_dk"); K.px(618, 140, "stone_dk")
  end)

  K.save("river_crossing_" .. country)
end

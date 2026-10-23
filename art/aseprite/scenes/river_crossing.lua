-- River crossing world for the travel screen (720x300), seen in the same three-quarter view as
-- the crossing sprites. The river runs diagonally from upper left to lower right between the
-- near bank (lower left) and the far bank (upper right). The water is left transparent:
-- ui/trail_view.gd fills it (clear for fords, floats and swimming, muddy for ferries), animates
-- the current, and pans a 432x150 view across this picture as the party crosses.
-- NEAR and FAR must match NEAR_BANK and FAR_BANK in trail_view.gd, which clips water to them.
local K = dofile(app.params.kit)
local W, H = 720, 300
local NEAR = {{0, 178}, {25, 189}, {50, 204}, {75, 212}, {100, 220}, {125, 237}, {150, 248}, {175, 269}, {200, 275}, {225, 288}, {250, 295}, {260, 300}, {0, 300}}
local FAR = {{330, 0}, {360, 21}, {390, 26}, {420, 43}, {450, 62}, {480, 77}, {510, 90}, {540, 99}, {570, 125}, {600, 136}, {630, 150}, {660, 161}, {690, 182}, {720, 200}, {720, 0}}

K.canvas(W, H, 184841)

-- shoreline height at x, interpolated along the first points of a bank outline
local function shore(pts, n, x)
  for i = 1, n - 1 do
    local a, b = pts[i], pts[i + 1]
    if x >= a[1] and x <= b[1] then return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1]) end
  end
end

K.layer("banks", function()
  K.poly(NEAR, "sage"); K.poly(FAR, "sage")
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local c = K.at(x, y)
      if c == "sage" then
        local sy = (x < 300) and shore(NEAR, 12, x) or shore(FAR, 14, x)
        local d = sy and math.abs(y - sy) or 99
        local r = K.rnd(23)
        if d < 2 then K.px(x, y, "dirt_dk")
        elseif d < 4 then K.px(x, y, "clap_sh")
        elseif d < 10 + 3 * math.sin(x / 17) then K.px(x, y, (r < 4) and "cream" or ((r < 7) and "clap_sh" or "sand"))
        elseif d < 13 + 3 * math.sin(x / 17) then K.px(x, y, (r % 2 == 0) and "sand" or "gold")
        else K.px(x, y, (r < 3) and "grass" or ((r < 5) and "gold" or ((r < 6) and "leaf" or "sage"))) end
      end
    end
  end
  -- the trail: two ruts down to each landing, worn bare
  local function ruts(x0, y0, x1, y1)
    -- a worn band of bare ground with a deeper rut along each wheel track
    for o = -7, 7 do
      local c = (math.abs(o) == 5) and "dirt_dk" or ((math.abs(o) == 4 or math.abs(o) == 6) and "ochre" or "gold")
      if math.abs(o) < 7 or K.rnd(2) == 0 then K.line(x0 + o, y0 + o / 2, x1 + o, y1 + o / 2, c) end
    end
  end
  ruts(40, 307, 110, 272)
  ruts(520, 70, 680, -10)
  -- grass tufts and sage scattered on both banks
  for i = 1, 260 do
    local x, y = K.rnd(W), K.rnd(H)
    if K.at(x, y) == "sage" or K.at(x, y) == "grass" then
      K.px(x, y, "leaf"); K.px(x - 1, y - 1, "grass"); K.px(x + 1, y - 1, "grass")
    end
  end
end)

K.layer("trees", function()
  -- cottonwoods and willows standing back from the water, drawn far to near
  local trees = {
    {360, 8, "elm"}, {420, 12, "elm"}, {470, 28, "willow"}, {600, 40, "elm"}, {640, 70, "elm"},
    {690, 110, "willow"}, {700, 150, "elm"}, {580, 20, "willow"}, {660, 30, "elm"},
    {20, 210, "elm"}, {12, 260, "willow"}, {60, 235, "willow"}, {150, 290, "elm"}, {200, 298, "willow"},
  }
  table.sort(trees, function(a, b) return a[2] < b[2] end)
  for _, t in ipairs(trees) do
    if t[3] == "elm" then K.elm(t[1], t[2], 1) else K.willow(t[1], t[2], 1) end
  end
  -- driftwood fetched up on the near beach, a snag on the far one
  K.line(170, 270, 186, 276, "stone_dk"); K.line(171, 271, 185, 277, "stone_ink")
  K.line(612, 141, 626, 146, "stone_dk"); K.px(618, 140, "stone_dk")
end)

K.save("river_crossing")

-- Parallax Scrolling Ground & Road Layer (432x50, seamless horizontal tile).
-- Drawn at y=100 in ui/trail_view.gd (spanning screen y=100..150).
-- The wagon wheels and oxen walk along y=20..36 (screen y=120..136).
local K = dofile(app.params.kit)
local W, H = 432, 50
local tau = math.pi * 2.0

K.canvas(W, H, 974)

K.layer("ground", function()
  -- Upper verge (y=0..12), dusty wagon road (y=12..39), and foreground grass strip (y=39..49)
  K.rect(0, 0, W, H, "grass")
  K.dither(0, 0, W, 3, "sage", "grass")
  K.dither(0, 43, W, 7, "grass", "leaf")

  for x = 0, W - 1 do
    -- Gentle periodic wave so left (x=0) and right (x=431) join without a step
    local wave = math.floor(1.8 * math.sin(tau * x / 432.0) + 1.0 * math.cos(tau * x / 216.0))
    local top = 12 + wave
    local bot = 39 + wave

    -- Sandy grass verge along the top & bottom road shoulders
    K.px(x, top - 1, (x % 2 == 0) and "sage" or "grass")
    K.px(x, top, "sand")

    -- Main compacted dirt road bed
    K.rect(x, top + 1, 1, bot - top - 2, "ochre")
    -- Horizontal crown highlight down the center of the track (between the wheel ruts)
    K.rect(x, top + 12, 1, 4, "gold")
    if (x % 2) == 0 then
      K.px(x, top + 11, "gold")
      K.px(x, top + 16, "gold")
    end

    -- Lower road shoulder shadow
    K.px(x, bot - 1, "rust")
    K.px(x, bot, "dirt_dk")

    -- Two continuous parallel wagon wheel ruts with sunlit upper lips & shaded troughs
    local rut1 = top + 9
    local rut2 = top + 21
    if (x % 18) ~= 0 then
      K.px(x, rut1 - 1, "gold")
      K.px(x, rut1, "dirt_dk")
      K.px(x, rut1 + 1, "rust")
    end
    if ((x + 9) % 18) ~= 0 then
      K.px(x, rut2 - 1, "gold")
      K.px(x, rut2, "dirt_dk")
      K.px(x, rut2 + 1, "rust")
    end
  end

  -- Texture pebbles on the road and prairie grass tufts on the verges
  for i = 1, 1300 do
    local x = K.rnd(W)
    local y = K.rnd(H)
    local cur = K.at(x, y)
    if cur == "ochre" or cur == "gold" then
      K.px(x, y, (i % 4 == 0) and "sand" or ((i % 2 == 0) and "rust" or "gold"))
    else
      K.px(x, y, (i % 4 == 0) and "sage" or ((i % 3 == 0) and "gold" or "leaf"))
    end
  end

  -- Foreground grass blades & small trailside stones framing the bottom edge (y=41..49)
  for _, gx in ipairs({12, 48, 88, 134, 178, 224, 268, 314, 362, 404}) do
    for b = -3, 3, 2 do
      local bx = (gx + b) % W
      local h = 4 + (bx % 3)
      K.line(bx, 49, bx + (b < 0 and -1 or 1), 49 - h, "pine")
      K.px(bx, 49 - h, "sage")
      if b == -1 then K.px(bx, 48 - h, "gold") end
    end
  end
  for _, sx in ipairs({29, 112, 202, 292, 384}) do
    K.ellipse(sx, 45, 3, 1, "deep")
    K.ellipse(sx - 1, 44, 2, 1, "sand")
  end
end)

K.save("travel_ground")

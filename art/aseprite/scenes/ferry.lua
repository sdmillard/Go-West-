-- Ferry pieces for river crossings: the flatboat (ferry_raft, 128x24) and a ferryman poling
-- it (ferryman, 256x48: eight 32x48 frames).
-- Emigrant ferries were plank decks laid across two dugout canoes or a scow, worked across
-- with setting poles. The deck top is y = 0 on the raft; the ferryman's feet stand on it at
-- y = 27, and his pole reaches down past the hull to the river bottom.
local K = dofile(app.params.kit)
local FRAMES = 8

K.canvas(128, 24, 1848)
K.layer("raft", function()
  -- two dugout hulls, rounded at bow and stern
  for _, hy in ipairs({8, 15}) do
    K.ellipse(62, hy + 3, 60, 3, "deep")
    K.rect(6, hy + 1, 112, 1, "wood")
    K.rect(10, hy + 5, 104, 1, "ink")
  end
  -- plank deck lashed across them
  K.rect(1, 0, 122, 10, "ochre")
  K.rect(1, 0, 122, 1, "gold")
  for x = 1, 122, 9 do K.rect(x, 0, 1, 10, "rust") end
  for x = 5, 120, 9 do K.px(x, 1, "sand"); K.px(x + 3, 6, "sand") end
  K.rect(1, 9, 122, 1, "wood")
  -- cross beams and lashing where the deck rides on the hulls
  for _, x in ipairs({6, 40, 82, 116}) do K.rect(x, 9, 3, 4, "deep"); K.px(x + 1, 10, "sand") end
  -- low rails fore and aft so the stock do not step off
  K.rect(0, -0, 2, 10, "wood"); K.rect(122, 0, 2, 10, "wood")
end)
K.save("ferry_raft")

K.canvas(256, 48, 1848)
K.layer("ferryman", function()
  for f = 1, FRAMES do
    local fx = (f - 1) * 32
    local t = (f - 1) / FRAMES
    local feet = 27
    -- push for five frames walking the pole aft, then lift and swing it forward
    local pushing = t < 0.625
    local u = pushing and (t / 0.625) or ((t - 0.625) / 0.375)
    local lean = pushing and math.floor(1 + 3 * u + 0.5) or math.floor(4 - 3 * u + 0.5)
    local hip_x = fx + 14
    local hip_y = feet - 8
    -- legs braced, rear leg straightening as he pushes
    K.line(hip_x, hip_y, hip_x - 2 - math.floor(lean / 2), feet - 1, "deep")
    K.line(hip_x + 2, hip_y, hip_x + 4, feet - 1, "wood")
    K.rect(hip_x - 3 - math.floor(lean / 2), feet - 1, 3, 1, "ink"); K.rect(hip_x + 4, feet - 1, 3, 1, "ink")
    -- body leaning into the pole
    local sx, sy = hip_x + lean, hip_y - 7
    K.poly({{hip_x - 1, hip_y}, {hip_x + 3, hip_y}, {sx + 3, sy}, {sx - 1, sy}}, "brick_lt")
    K.line(hip_x - 1, hip_y, sx - 1, sy, "red")
    K.rect(hip_x - 1, hip_y, 5, 1, "wood")
    -- head and hat
    K.rect(sx, sy - 4, 3, 4, "skin"); K.px(sx + 2, sy - 2, "skin_dk")
    K.rect(sx - 1, sy - 5, 5, 1, "deep"); K.rect(sx, sy - 7, 3, 2, "deep")
    -- the setting pole: planted and swept aft while pushing, lifted clear while recovering
    local top_x, top_y, tip_x, tip_y
    if pushing then
      top_x, top_y = sx + 4, sy - 2 - lean
      tip_x, tip_y = math.floor(fx + 22 - 18 * u + 0.5), 47
    else
      top_x, top_y = sx + 3, sy - 4
      tip_x, tip_y = math.floor(fx + 4 + 20 * u + 0.5), math.floor(40 - 6 * math.sin(u * math.pi) + 0.5)
    end
    K.line(top_x, top_y, tip_x, tip_y, "wood")
    K.line(top_x + 1, top_y, tip_x + 1, tip_y, "ochre")
    -- hands on the pole
    local hand_y = sy + 2
    local function on_pole(y) return math.floor(top_x + (tip_x - top_x) * (y - top_y) / (tip_y - top_y) + 0.5) end
    K.px(on_pole(hand_y), hand_y, "skin"); K.px(on_pole(hand_y + 3), hand_y + 3, "skin")
    K.line(sx + 1, sy + 1, on_pole(hand_y), hand_y, "red")
    -- a ripple where a planted pole meets the water
    if pushing then K.rect(math.floor(tip_x - 2 + (top_x - tip_x) * 0.35), 39, 4, 1, "cream") end
  end
end)
K.save("ferryman")

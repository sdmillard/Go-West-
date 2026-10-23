-- 1990s Beige Toyota Corolla Encounter Sprite (80x40, transparent background).
-- Drawn in ui/trail_view.gd either as a roadside encounter or as the player's vehicle.
local K = dofile(app.params.kit)
local W, H = 80, 40

K.canvas(W, H, 165)

K.layer("corolla", function()
  -- Translucent ground shadow matching test_art.gd (45372f88)
  K.ellipse(40, 35, 36, 3, "wagon_shadow")

  -- Outer dark silhouette of the 1990s compact 4-door sedan (facing right)
  K.poly({
    {3, 24}, {5, 19}, {14, 18}, {23, 9}, {50, 9},
    {61, 18}, {74, 20}, {77, 24}, {77, 31}, {3, 31}
  }, "ink")

  -- Main beige/champagne metallic body shell ("sand" with "cream" upper highlight & "clap_sh" lower panel)
  K.poly({
    {5, 23}, {6, 20}, {15, 19}, {24, 10}, {49, 10},
    {60, 19}, {73, 21}, {75, 24}, {75, 29}, {5, 29}
  }, "sand")
  -- Sunlit roof, hood & trunk deck highlights
  K.rect(25, 10, 24, 2, "cream")
  K.rect(27, 10, 18, 1, "white")
  K.rect(6, 19, 9, 1, "cream")
  K.line(60, 19, 73, 21, "cream")
  K.rect(6, 22, 68, 2, "cream")

  -- Front & rear passenger windows with B-pillar and C-pillar trim
  K.poly({{17, 19}, {25, 12}, {36, 12}, {36, 19}}, "deep")
  K.poly({{19, 18}, {25, 13}, {35, 13}, {35, 18}}, "blue")
  K.line(25, 13, 33, 13, "light_blue")
  K.line(21, 16, 25, 13, "mist")

  K.poly({{39, 12}, {48, 12}, {58, 19}, {39, 19}}, "deep")
  K.poly({{40, 13}, {48, 13}, {56, 18}, {40, 18}}, "blue")
  K.line(40, 13, 47, 13, "light_blue")
  K.line(42, 16, 46, 13, "mist")

  -- Side mirror (colour-keyed housing)
  K.rect(55, 17, 3, 2, "ink")
  K.px(56, 17, "sand")

  -- Black side protective rub strip & door seams
  K.rect(12, 25, 54, 1, "deep")
  K.line(23, 19, 23, 29, "ochre")
  K.line(37, 12, 37, 29, "ochre")
  K.line(54, 19, 54, 29, "ochre")
  -- Recessed door handles
  K.rect(26, 21, 3, 1, "deep")
  K.rect(41, 21, 3, 1, "deep")

  -- Trail-weathered rust rocker panel & bumpers
  K.rect(10, 28, 56, 2, "ochre")
  K.rect(24, 29, 28, 1, "rust")
  -- Rear & front black moulded bumpers
  K.rect(2, 26, 7, 4, "ink"); K.rect(3, 27, 5, 1, "deep")
  K.rect(71, 26, 7, 4, "ink"); K.rect(72, 27, 5, 1, "deep")

  -- Taillight cluster (red/amber) & wraparound halogen headlight + amber corner lamp
  K.rect(4, 21, 3, 3, "red")
  K.px(4, 21, "gold")
  K.rect(72, 22, 4, 2, "white")
  K.px(71, 22, "gold")

  -- Dark wheel wells & 14-inch steel wheels with silver 7-hole hubcaps
  for _, wx in ipairs({17, 62}) do
    K.ellipse(wx, 30, 8, 7, "ink")
    K.ellipse(wx, 31, 6, 6, "deep")
    K.ellipse(wx, 31, 5, 5, "ink")
    K.ellipse(wx, 31, 3, 3, "mist")
    K.px(wx - 2, 30, "white")
    K.px(wx, 29, "deep"); K.px(wx, 33, "deep")
    K.px(wx - 2, 31, "deep"); K.px(wx + 2, 31, "deep")
    K.px(wx, 31, "ink")
  end
end)

K.save("corolla")

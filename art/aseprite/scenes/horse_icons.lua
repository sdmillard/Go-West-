-- Store icons for horse travel (80x16): five 16x16 icons drawn pixel by pixel.
--   0 saddle horse (a bay's head)   1 mule (long ears, mealy muzzle)   2 riding saddle
--   3 sawbuck pack saddle on its pad   4 saddlebags
-- The riding saddle is the high-horned Spanish (Mexican) tree that most emigrants and traders
-- rode by 1848; the pack saddle is the plain sawbuck of crossed wooden bucks over a blanket.
local K = dofile(app.params.kit)
K.canvas(80, 16, 1848)

local function icon(n, rows, colours)
  for y, row in ipairs(rows) do
    for x = 1, #row do
      local c = colours[row:sub(x, x)]
      if c then K.px(n * 16 + x - 1, y - 1, c) end
    end
  end
end

K.layer("icons", function()
  -- the bay: ears pricked, black mane down the crest, white star, nostril and dark muzzle
  icon(0, {
    "......o.o.......",
    ".....omoplo.....",
    ".....omlmppo....",
    "....omllmmppo...",
    "...omlwlmmmppo..",
    "..omllemmmmmppo.",
    ".omllmmmmmmmmppo",
    "omllmmmmmmmmmmpo",
    "odmmmmoommmmmmpo",
    "oddndo..ommmmmmo",
    "odddo...ommmmmmo",
    ".ooo....ommmmmdo",
    "........ommmmmdo",
    "........odmmmddo",
    "........oddddddo",
    ".........oooooo.",
  }, {o="ink", m="ox", l="rust", d="ox_dk", p="ink", e="ink", w="white", n="ink"})
  -- the mule: long ears, roached mane, pale mealy muzzle and eye ring
  icon(1, {
    "....o....o......",
    "....oo..oho.....",
    "....omo.oho.....",
    "....omo.omo.....",
    "....omooomo.....",
    "....ommmmmpo....",
    "...omlmmmmmpo...",
    "..omlsemmmmmpo..",
    ".omlmmmmmmmmmpo.",
    "osmmmmmmmmmmmmpo",
    "ossnso.ommmmmmpo",
    "osssso..ommmmmmo",
    ".oooo...ommmmmdo",
    "........odmmmddo",
    "........oddddddo",
    ".........oooooo.",
  }, {o="ink", m="ox_dk", l="ox", d="deep", p="ink", h="ox_lt", s="sand", e="ink", n="deep"})
  -- the riding saddle: tall horn, deep seat, high cantle, square skirt and a wooden stirrup
  icon(2, {
    "................",
    "..ooo...........",
    "..ogo...........",
    "...oo........oo.",
    "...oho......ogo.",
    "...ohho....ohho.",
    "..ohhhhooooohhdo",
    "..ohgggggggghhdo",
    ".ommmmmmmmmmmmdo",
    ".ommmmmmmmmmmmdo",
    ".omdddmmmmmdddmo",
    ".oooooomoooooooo",
    "......omo.......",
    ".....owwwo......",
    ".....ow.wo......",
    ".....ooooo......",
  }, {o="ink", h="ochre", g="gold", m="rust", d="ox", w="wood"})
  -- the sawbuck: two crossed bucks joined by side bars, over a striped blanket and cinch
  icon(3, {
    "................",
    "................",
    ".wo...wowo...wo.",
    "..wo.wo..wo.wo..",
    "...wwo....wwo...",
    "..wo.wo..wo.wo..",
    ".wo...wowo...wo.",
    ".oooooooooooooo.",
    ".owwwwwwwwwwwwdo",
    ".oddddddddddddo.",
    "orrrrrrrrrrrrrro",
    "occcccccccccccco",
    "orrrrrrrrrrrrrro",
    "oooooommmooooooo",
    "......omo.......",
    "......ooo.......",
  }, {o="ink", w="wood", d="deep", r="red", c="cream", m="ochre"})
  -- the saddlebags: a pair of leather pouches on a cross strap, flaps buckled down
  icon(4, {
    "................",
    "................",
    "..oooooooooooo..",
    ".ohhhhhhhhhhhhho",
    ".oooooooooooooo.",
    ".ohhhho..ohhhho.",
    ".ommmmo..ommmmo.",
    ".omgmmo..omgmmo.",
    ".ommmmo..ommmmo.",
    ".odddmo..odddmo.",
    ".ommmmo..ommmmo.",
    ".ommmmo..ommmmo.",
    ".ommmdo..ommmdo.",
    ".odddddo.odddddo",
    "..ooooo...ooooo.",
    "................",
  }, {o="ink", h="ochre", m="rust", d="ox", g="gold"})
end)

K.save("horse_icons")

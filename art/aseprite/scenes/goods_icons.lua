-- Store icons for trade goods (240x16): one 16x16 icon per kind of goods, drawn pixel by pixel.
-- Matches horse_icons.lua and the weapon icons: ink outline, game palette, lit from the upper left.
-- Order (index: goods):
--   0 food: a tied flour sack
--   1 bullets: three lead balls on a patch
--   2 care kit: a physic bottle and a bandage roll
--   3 clothes: a folded shirt on folded trousers
--   4 oxen: an ox's head, horns spread
--   5 wheel: iron tire, felloes, twelve spokes and a hub
--   6 axle: hickory axletree, iron skeins at the ends
--   7 tongue: the wagon pole with its iron ring
--   8 salt: a keg heaped white
--   9 wagon: a covered wagon from the side
--   10 fruit/grain: a basket of apples and greens
--   11 dried fruit: apple rings strung on a cord
--   12 hide: a stretched skin
--   13 leather goods: a fringed buckskin glove
--   14 keepsake: a pocket watch
local K = dofile(app.params.kit)
K.canvas(240, 16, 1848)

local function icon(n, rows, colours)
  for y, row in ipairs(rows) do
    for x = 1, #row do
      local c = colours[row:sub(x, x)]
      if c then K.px(n * 16 + x - 1, y - 1, c) end
    end
  end
end

K.layer("icons", function()
  -- food: a tied flour sack
  icon(0, {
    "................",
    "......o..o......",
    ".....ogoogo.....",
    "......orro......",
    ".....occcco.....",
    "....occcccco....",
    "...occcccccco...",
    "..occcccccccso..",
    "..occwcwcwccso..",
    "..occcccccccso..",
    "..occcwcwcccso..",
    "..occcccccccso..",
    "..occcccccccso..",
    "..ocssssssssso..",
    "...oooooooooo...",
    "................",
  }, {o="ink", g="gold", r="rust", c="cream", s="sand", w="ochre"})
  -- bullets: three lead balls on a patch
  icon(1, {
    "................",
    "................",
    "................",
    "................",
    "......ooo.......",
    ".....oLSSo......",
    ".....oSSSo......",
    ".....oSSDo......",
    "....oooooooo....",
    "...oLSSooLSSo...",
    "...oSSSooSSSo...",
    "...oSSDooSSDo...",
    "..ooooooooooo...",
    ".owwwwwwwwwwwo..",
    "..ooooooooooo...",
    "................",
  }, {o="ink", L="stone_lt", S="stone", D="stone_dk", w="wood"})
  -- care kit: a physic bottle and a bandage roll
  icon(2, {
    "................",
    "...ooo..........",
    "...owo..........",
    "...ooo..........",
    "...oto..........",
    "..ottto.........",
    ".otlttto........",
    ".otlttto........",
    ".occccco..ooo...",
    ".ocwcwcooobbbo..",
    ".occcccoobbsbbo.",
    ".otltttoobsosbo.",
    ".otttdtoobbsbbo.",
    ".otttdto.obbbo..",
    "..ooooo...ooo...",
    "................",
  }, {o="ink", w="wood", t="teal", l="haze", d="pine", c="cream", b="white", s="stone"})
  -- clothes: a folded shirt on folded trousers
  icon(3, {
    "................",
    "................",
    "................",
    "....oooooooo....",
    "...obbbccbbbo...",
    "..obbbbccbbbbo..",
    "..obLbbbbbbbbo..",
    "..obbbbcbbbbbo..",
    "..oBBBBBBBBBBo..",
    "..oooooooooooo..",
    "..ommmmmmmmmmo..",
    "..omRmmmmmmmmo..",
    "..ommmmmmmmmmo..",
    "..oddddddddddo..",
    "..oooooooooooo..",
    "................",
  }, {o="ink", b="sky", B="blue", L="light_blue", c="cream", m="wood", R="rust", d="deep"})
  -- oxen: an ox's head, horns spread
  icon(4, {
    "................",
    "................",
    "oo............oo",
    "ocoo........ooco",
    ".occoo....oocco.",
    "..ooccooooccoo..",
    "...oommmmmmoo...",
    "..ommmmmmmmmmo..",
    "..oomomWWmomoo..",
    "...ommmWWmmmo...",
    "....ommWWmmo....",
    "....ommmmmmo....",
    "....oLLLLLLo....",
    "....oLoLLoLo....",
    ".....oLLLLo.....",
    "......oooo......",
  }, {o="ink", c="cream", m="ox", W="ox_white", L="ox_lt"})
  -- wheel: iron tire, felloes, twelve spokes and a hub
  icon(5, {
    ".......oo.......",
    "....oooSSooo....",
    "...oSSwwwwSSo...",
    "..oSwwomoowwSo..",
    ".oSwommm.mmowSo.",
    ".oSwm.mmmm.mwSo.",
    ".owommoooommowo.",
    "oSwo..ohho..owSo",
    "oSwmmmohhommmwSo",
    ".owommoooommowo.",
    ".oSwm.m.mm.mwSo.",
    ".oSwomm.mmmowSo.",
    "..oSwwoomowwSo..",
    "...oSSwwwwSSo...",
    "....oooSSooo....",
    ".......oo.......",
  }, {o="ink", S="stone_dk", w="wood", m="ochre", h="rust"})
  -- axle: hickory axletree, iron skeins at the ends
  icon(6, {
    "................",
    "................",
    "................",
    "................",
    "................",
    "..oooooooooooo..",
    "oooggggggggggooo",
    "oSSmmmmmmmmmmSSo",
    "oSDmmmmmmmmmmDSo",
    "ooommmmmmmmmmooo",
    "..oddddddddddo..",
    "..oooooooooooo..",
    "................",
    "................",
    "................",
    "................",
  }, {o="ink", g="ochre", m="rust", d="wood", S="stone", D="stone_dk"})
  -- tongue: the wagon pole with its iron ring
  icon(7, {
    "............oo..",
    "...........oSSo.",
    "...........oSmo.",
    "..........ooooo.",
    ".........oomdo..",
    "........oomdo...",
    ".......oomdo....",
    "......oomdo.....",
    ".....oomdo......",
    "....oomdo.......",
    "...oomdo........",
    "..oomdo.........",
    ".oomdo..........",
    "oomdo...........",
    "omdo............",
    ".oo.............",
  }, {o="ink", m="ochre", d="wood", S="stone_dk"})
  -- salt: a keg heaped white
  icon(8, {
    "................",
    "................",
    "......oooo......",
    "....ooWWWWoo....",
    "...oWWWWWWWWo...",
    "..oooooooooooo..",
    "..owmwwwwwwwdo..",
    "..oSSSSSSSSSSo..",
    ".owmwwwwwwwwwdo.",
    ".owmwwwwwwwwwdo.",
    ".owmwwwwwwwwwdo.",
    "..oSSSSSSSSSSo..",
    "..owmwwwwwwwdo..",
    "..owmwwwwwwwdo..",
    "...oooooooooo...",
    "................",
  }, {o="ink", W="white", w="rust", m="ochre", d="wood", S="stone_dk"})
  -- wagon: a covered wagon from the side
  icon(9, {
    "................",
    "................",
    "...oooooooooo...",
    "..occcccccccco..",
    ".occcccccccccco.",
    ".ocsccscccsccco.",
    ".occcccccccccco.",
    ".ocsccscccsccco.",
    "oooooooooooooooo",
    "ommmmmmmmmmmmmmo",
    "oddddddddddddddo",
    "oooooooooooooooo",
    "..oo........oo..",
    ".owwo......owwo.",
    ".owwo......owwo.",
    "..oo........oo..",
  }, {o="ink", c="cream", s="sand", m="rust", d="wood", w="ochre", S="stone_dk"})
  -- fruit/grain: a basket of apples and greens
  icon(10, {
    "................",
    "................",
    "................",
    "....oo..oo..oo..",
    "...oRRooRRooGGo.",
    "...oRroRRroGgGo.",
    "..oooooooooooooo",
    "..owgwgwgwgwgwo.",
    "..ogwgwgwgwgwgo.",
    "...owgwgwgwgwo..",
    "...ogwgwgwgwgo..",
    "....owgwgwgwo...",
    "....oooooooo....",
    "................",
    "................",
    "................",
  }, {o="ink", R="red", r="brick_lt", G="grass", g="gold", w="ochre"})
  -- dried fruit: apple rings strung on a cord
  icon(11, {
    "................",
    "................",
    "oddddddddddddddo",
    "..d.d..d..d.d...",
    ".oood.ooo.dooo..",
    "ogghoogghooggho.",
    "og.goog.goog.go.",
    "ohggoohggoohggo.",
    ".oood.ooo.dooo..",
    "...ooo...ooo....",
    "..oggho.oggho...",
    "..og.go.og.go...",
    "..ohggo.ohggo...",
    "...ooo...ooo....",
    "................",
    "................",
  }, {o="ink", d="wood", g="gold", h="ochre"})
  -- hide: a stretched skin
  icon(12, {
    "................",
    "..oo........oo..",
    ".ommo......ommo.",
    "..ommoooooommo..",
    "...ommmmmmmmo...",
    "...ommllmmmmo...",
    "..ommmlmmmmmmo..",
    "..ommmmmmmmmmo..",
    "..ommmmmmmmmdo..",
    "...ommmmmmmmo...",
    "...ommmmmmmdo...",
    "..ommmoooommmo..",
    ".ommo......ommo.",
    "..oo........oo..",
    "................",
    "................",
  }, {o="ink", m="ochre", l="gold", d="rust"})
  -- leather goods: a fringed buckskin glove
  icon(13, {
    "................",
    ".....o.o........",
    "....omomo.o.....",
    "....omomoomo....",
    "..o.omomomomo...",
    ".omoommmmmmmo...",
    ".ommommmmmmmo...",
    "..ommmmmmmmmo...",
    "...ommmmmmmmo...",
    "....ommmmmmo....",
    "....oddddddo....",
    "....oscscsco....",
    "....os.s.s.o....",
    "....o.o.o.oo....",
    "................",
    "................",
  }, {o="ink", m="ochre", d="rust", s="sand", c="ochre"})
  -- keepsake: a pocket watch
  icon(14, {
    ".......oo.......",
    "......ogho......",
    "......o..o......",
    ".......oo.......",
    ".....ooggoo.....",
    "....ooggggoo....",
    "...oogccccgoo...",
    "...ogccocccgo...",
    "..oocccoccccoo..",
    "..ogcccoooccgo..",
    "..ooccccccccoo..",
    "...ogccccccgo...",
    "...oogccccgoo...",
    "....ooggggoo....",
    ".....oooooo.....",
    "................",
  }, {o="ink", g="gold", h="ochre", c="cream"})
end)

K.save("goods_icons")

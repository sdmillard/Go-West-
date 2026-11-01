-- Front and back covers of THE OVERLAND GUIDE (each 608 x 320, on the same grid as
-- guide_book.lua). Paging back past page 1 closes the book onto its front board, which lies
-- where the right-hand page was; paging past the last page shows the back board on the left.
-- The game prints the gold title lettering itself (ui/guide_book.gd); the art carries the
-- tooling, the spine and a stamped wagon vignette inside an oval cartouche.
-- no seasons
local K = dofile(app.params.kit)
local W, H = 608, 320
local BY, BH, BW = 2, 310, 280 -- board top, height, width

local function leather(x0, y0, w, h)
  K.rect(x0, y0, w, h, "wood")
  for y = y0, y0 + h - 1 do
    for x = x0, x0 + w - 1 do
      local r = K.rnd(19)
      if r == 0 then K.px(x, y, "deep") elseif r == 1 or r == 2 then K.px(x, y, "shadow") end
    end
  end
  -- worn edges: light from the upper left
  K.rect(x0, y0, w, 1, "ink"); K.rect(x0, y0 + h - 1, w, 1, "ink")
  K.rect(x0, y0, 1, h, "ink"); K.rect(x0 + w - 1, y0, 1, h, "ink")
  K.rect(x0 + 1, y0 + 1, w - 2, 1, "rust"); K.rect(x0 + 1, y0 + 1, 1, h - 2, "rust")
  K.rect(x0 + 1, y0 + h - 2, w - 2, 1, "deep"); K.rect(x0 + w - 2, y0 + 1, 1, h - 2, "deep")
end

local function frame(x0, y0, w, h, inset, c)
  K.rect(x0 + inset, y0 + inset, w - inset * 2, 1, c)
  K.rect(x0 + inset, y0 + h - inset - 1, w - inset * 2, 1, c)
  K.rect(x0 + inset, y0 + inset, 1, h - inset * 2, c)
  K.rect(x0 + w - inset - 1, y0 + inset, 1, h - inset * 2, c)
end

local function fleuron(cx, cy, c, lt)
  K.px(cx, cy, lt)
  for _, d in ipairs({{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) do K.px(cx + d[1], cy + d[2], c) end
  for _, d in ipairs({{-2, -2}, {2, -2}, {-2, 2}, {2, 2}}) do K.px(cx + d[1], cy + d[2], c) end
  for _, d in ipairs({{-3, 0}, {3, 0}, {0, -3}, {0, 3}}) do K.px(cx + d[1], cy + d[2], c) end
end

-- the rounded spine with raised bands, sx = left column, 14 wide
local function spine(sx)
  local bands = {"deep", "wood", "rust", "ochre", "rust", "wood", "wood", "shadow", "shadow", "wood", "deep", "deep", "roof_dk", "ink"}
  for i, c in ipairs(bands) do K.rect(sx + i - 1, BY, 1, BH, c) end
  for _, y in ipairs({40, 46, 120, 126, 196, 202, 270, 276}) do
    for i = 1, 14 do
      local c = (i <= 4) and "gold" or ((i <= 10) and "ochre" or "rust")
      K.px(sx + i - 1, y, c)
    end
  end
  K.rect(sx, BY, 14, 1, "ink"); K.rect(sx, BY + BH - 1, 14, 1, "ink")
end

-- page edges showing past the board, as the closed book is seen a little from the side
local function page_edge(x0, y0, h, w)
  for i = 0, w - 1 do K.rect(x0 + i, y0, 1, h, (i % 2 == 0) and "cream" or "clap_sh") end
end

------------------------------------------------------------------ front
K.canvas(W, H, 1848)
local FX = 286
K.layer("pages", function()
  page_edge(FX + BW, BY + 4, BH - 6, 3)
  K.rect(FX + BW + 3, BY + 4, 1, BH - 6, "deep")
end)
K.layer("board", function()
  leather(FX, BY, BW, BH)
  frame(FX, BY, BW, BH, 8, "ochre")
  frame(FX, BY, BW, BH, 11, "gold")
  for _, c in ipairs({{FX + 18, BY + 18}, {FX + BW - 19, BY + 18}, {FX + 18, BY + BH - 19}, {FX + BW - 19, BY + BH - 19}}) do
    fleuron(c[1], c[2], "ochre", "gold")
  end
  -- oval cartouche for the vignette
  local cx, cy = FX + BW // 2, 148
  for a = 0, 719 do
    local t = a * math.pi / 360
    K.px(math.floor(cx + 56 * math.cos(t) + 0.5), math.floor(cy + 36 * math.sin(t) + 0.5), "gold")
    K.px(math.floor(cx + 52 * math.cos(t) + 0.5), math.floor(cy + 32 * math.sin(t) + 0.5), "ochre")
  end
  -- rules under the title and above the imprint
  for x = FX + 60, FX + BW - 61 do
    if x % 2 == 0 then K.px(x, 62, "ochre") end
    if x % 2 == 0 then K.px(x, 234, "ochre") end
  end
  fleuron(cx, 62, "ochre", "gold"); fleuron(cx, 234, "ochre", "gold")
end)
K.layer("spine", function() spine(FX - 12) end)
-- the vignette: an emigrant wagon struck in gold line, as a binder's stamp would cut it
local function ring(cx, cy, r, c)
  for a = 0, 359, 4 do
    local t = a * math.pi / 180
    K.px(math.floor(cx + r * math.cos(t) + 0.5), math.floor(cy + r * math.sin(t) + 0.5), c)
  end
end
K.layer("gold vignette", function()
  local x, y = FX + BW // 2 - 31, 170 -- wagon and tongue are 62 wide
  -- bonnet
  K.line(x + 2, y - 18, x, y - 30, "gold"); K.line(x, y - 30, x + 7, y - 37, "gold")
  K.line(x + 7, y - 37, x + 42, y - 37, "gold"); K.line(x + 42, y - 37, x + 49, y - 30, "gold")
  K.line(x + 49, y - 30, x + 47, y - 18, "gold")
  for _, bx in ipairs({12, 21, 30, 39}) do K.line(x + bx, y - 36, x + bx + 1, y - 19, "ochre") end
  K.line(x + 44, y - 29, x + 44, y - 21, "ochre") -- the puckered opening
  -- bed
  K.rect(x, y - 18, 50, 1, "gold"); K.rect(x + 2, y - 11, 46, 1, "gold")
  K.line(x, y - 18, x + 2, y - 11, "gold"); K.line(x + 49, y - 18, x + 47, y - 11, "gold")
  K.rect(x + 3, y - 15, 44, 1, "ochre")
  -- wheels with spokes: large behind, small in front
  for _, w in ipairs({{x + 11, y - 7, 7}, {x + 39, y - 6, 6}}) do
    ring(w[1], w[2], w[3], "gold")
    K.line(w[1] - w[3] + 2, w[2], w[1] + w[3] - 2, w[2], "ochre")
    K.line(w[1], w[2] - w[3] + 2, w[1], w[2] + w[3] - 2, "ochre")
    K.px(w[1], w[2], "gold")
  end
  -- tongue and a strip of stamped ground
  K.line(x + 48, y - 7, x + 62, y - 5, "gold")
  for gx = FX + BW // 2 - 38, FX + BW // 2 + 38 do if gx % 3 ~= 0 then K.px(gx, y + 1, "ochre") end end
end)
K.save("guide_book_front")

------------------------------------------------------------------ back
K.canvas(W, H, 1849)
local BX = 2 + 4
K.layer("pages", function()
  page_edge(BX - 4, BY + 4, BH - 6, 3)
  K.rect(BX - 5, BY + 4, 1, BH - 6, "deep")
end)
K.layer("board", function()
  leather(BX, BY, BW, BH)
  -- blind tooling (no gold) on the back board, with a single small gold device
  frame(BX, BY, BW, BH, 8, "deep")
  frame(BX, BY, BW, BH, 11, "shadow")
  for _, c in ipairs({{BX + 18, BY + 18}, {BX + BW - 19, BY + 18}, {BX + 18, BY + BH - 19}, {BX + BW - 19, BY + BH - 19}}) do
    fleuron(c[1], c[2], "deep", "shadow")
  end
  fleuron(BX + BW // 2, 156, "ochre", "gold")
end)
K.layer("spine", function() spine(BX + BW - 2) end)
K.save("guide_book_back")

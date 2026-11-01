-- THE OVERLAND GUIDE as an open book (608 x 320), drawn behind ui/guide_book.gd.
-- Calf binding with gold tooling, two parchment pages bowing into the gutter, page-block
-- edges, and a red silk ribbon down the spine. The chapter tabs, text, page numbers and the
-- buttons on the bottom band are drawn by the game on top. Geometry is mirrored in
-- ui/guide_book.gd (COVER, LEFT_PAGE, RIGHT_PAGE, BAND); keep the two in step.
-- no seasons
local K = dofile(app.params.kit)
local W, H = 608, 320
K.canvas(W, H, 1847)

local CW, CH = 564, 312         -- cover
local PY, PH = 10, 276          -- page top and height
local LX, RX, PW = 12, 284, 268 -- left page x, right page x, page width
local SPINE = 280               -- gutter columns 280..283

-- how far a page dips at column x: pages bow down into the gutter
local function dip(x)
  local d = math.min(math.abs(x - (SPINE - 1)), math.abs(x - (SPINE + 4)))
  if x >= SPINE and x < SPINE + 4 then return 4 end
  if d < 4 then return 3 elseif d < 10 then return 2 elseif d < 22 then return 1 end
  return 0
end

K.layer("cover", function()
  K.rect(0, 0, CW, CH, "wood")
  -- grain: a sparse mottle of darker and lighter calf
  for y = 0, CH - 1 do
    for x = 0, CW - 1 do
      local r = K.rnd(19)
      if r == 0 then K.px(x, y, "deep") elseif r == 1 or r == 2 then K.px(x, y, "shadow") end
    end
  end
  -- gold-tooled fillet just inside the edge of the boards
  K.rect(3, 3, CW - 6, 1, "ochre"); K.rect(3, 3, 1, 287, "ochre"); K.rect(CW - 4, 3, 1, 287, "ochre")
  -- worn, rounded corners and a dark outer edge
  K.rect(0, 0, CW, 1, "ink"); K.rect(0, CH - 1, CW, 1, "ink")
  K.rect(0, 0, 1, CH, "ink"); K.rect(CW - 1, 0, 1, CH, "ink")
  for _, c in ipairs({{0, 0}, {CW - 1, 0}, {0, CH - 1}, {CW - 1, CH - 1}}) do
    K.px(c[1], c[2], "ink")
  end
  -- rubbed highlight along the top and left (light from the upper left)
  K.rect(1, 1, CW - 2, 1, "rust"); K.rect(1, 1, 1, CH - 2, "rust")
  K.rect(1, CH - 2, CW - 2, 1, "deep"); K.rect(CW - 2, 1, 1, CH - 2, "deep")
  -- the bottom band, where the gold-stamped controls sit
  K.rect(4, 292, CW - 8, 1, "deep")
  K.rect(4, 293, CW - 8, 1, "shadow")
  -- gold fillet round the band and the cover edge
  K.rect(4, 296, CW - 8, 1, "ochre"); K.rect(4, CH - 5, CW - 8, 1, "ochre")
  K.rect(4, 296, 1, CH - 300, "ochre"); K.rect(CW - 5, 296, 1, CH - 300, "ochre")
  -- small stamped diamonds along the band
  for x = 150, 418, 12 do
    if x < SPINE - 6 or x > SPINE + 8 then
      K.px(x, 303, "ochre"); K.px(x - 1, 304, "ochre"); K.px(x + 1, 304, "ochre"); K.px(x, 305, "ochre")
    end
  end
  -- corner fleurons in the band
  for _, cx in ipairs({10, CW - 11}) do
    K.px(cx, 303, "gold"); K.px(cx - 1, 304, "ochre"); K.px(cx + 1, 304, "ochre"); K.px(cx, 305, "gold")
    K.px(cx, 304, "gold")
  end
end)

K.layer("page block", function()
  -- the stacked edges of the leaves under each page: outer side and foot
  for i = 0, 3 do
    local c = (i % 2 == 0) and "sand" or "clap_sh"
    K.rect(LX - 4 + i, PY + 3, 1, PH, c)           -- left fore-edge
    K.rect(RX + PW + 3 - i, PY + 3, 1, PH, c)      -- right fore-edge
  end
  for x = LX - 4, RX + PW + 3 do
    if x < SPINE or x >= SPINE + 4 then
      local base = PY + PH + dip(x)
      for i = 0, 3 do K.px(x, base + i, (i % 2 == 0) and "clap_sh" or "sand") end
      K.px(x, base + 4, "shadow")
    end
  end
  -- the block's shadow on the leather
  K.rect(LX - 5, PY + 4, 1, PH + 2, "deep")
  K.rect(RX + PW + 4, PY + 4, 1, PH + 2, "deep")
end)

K.layer("pages", function()
  for x = LX, RX + PW - 1 do
    if x < SPINE or x >= SPINE + 4 then
      local top = PY + dip(x)
      local bottom = PY + PH - 1 + dip(x)
      K.rect(x, top, 1, bottom - top + 1, "cream")
      K.px(x, top, "sand"); K.px(x, bottom, "clap_sh")
    end
  end
  -- outer page edges
  K.rect(LX, PY, 1, PH, "sand"); K.rect(RX + PW - 1, PY, 1, PH, "sand")
  -- gutter: the paper darkens as it curves into the spine
  local function shade(x0, step)
    for i = 0, 11 do
      local x = x0 + i * step
      local top, bottom = PY + dip(x) + 1, PY + PH - 2 + dip(x)
      for y = top, bottom do
        if i < 2 then K.px(x, y, "clap_sh")
        elseif i < 5 then if (x + y) % 2 == 0 then K.px(x, y, "clap_sh") else K.px(x, y, "sand") end
        elseif i < 8 then K.px(x, y, "sand")
        elseif i < 11 then if (x + y) % 2 == 0 then K.px(x, y, "sand") end
        elseif (x + y) % 4 == 0 then K.px(x, y, "sand") end
      end
    end
  end
  shade(SPINE - 1, -1)
  shade(SPINE + 4, 1)
  -- faint warm light on the left page's outer half, from the upper left
  for y = PY + 1, PY + PH - 2 do
    for x = LX + 1, LX + 3 do if (x + y) % 2 == 0 then K.px(x, y, "white") end end
  end
  -- foxing: a few age spots, kept to the margins so they never sit under the text
  for _ = 1, 26 do
    local side = K.rnd(4)
    local x, y
    if side == 0 then x, y = LX + 2 + K.rnd(8), PY + 6 + K.rnd(PH - 12)
    elseif side == 1 then x, y = RX + PW - 10 + K.rnd(8), PY + 6 + K.rnd(PH - 12)
    elseif side == 2 then x, y = LX + 14 + K.rnd(PW * 2 - 30), PY + PH - 6 + K.rnd(3)
    else x, y = LX + 14 + K.rnd(PW * 2 - 30), PY + 3 + K.rnd(3) end
    if x < SPINE - 14 or x > SPINE + 17 then K.px(x, y, "sand") end
  end
  -- the stitching at the head and foot of the gutter
  for _, y in ipairs({PY + 5, PY + PH - 3}) do
    K.rect(SPINE, y, 4, 1, "stone_dk")
  end
  K.rect(SPINE, PY + 4, 4, 1, "ink"); K.rect(SPINE, PY + 3, 4, 1, "deep")
  -- a ruled rule under each running head and above each folio
  for _, x0 in ipairs({LX + 14, RX + 14}) do
    for x = x0, x0 + PW - 29 do
      K.px(x, PY + 17, (x % 2 == 0) and "ochre" or "sand")
      K.px(x, PY + PH - 20, (x % 2 == 0) and "ochre" or "sand")
    end
  end
end)

K.layer("ribbon", function()
  -- red silk marker laid down the gutter and out over the band
  local x = SPINE
  for y = PY + 6, PY + PH + 3 do
    K.px(x, y, "brick_dk"); K.px(x + 1, y, "red"); K.px(x + 2, y, "brick"); K.px(x + 3, y, "brick_dk")
  end
  -- it bends over the foot of the page block and hangs past the binding
  for y = PY + PH + 4, H - 4 do
    local off = (y > 300) and 1 or 0
    K.px(x + off, y, "brick_dk"); K.px(x + 1 + off, y, "red"); K.px(x + 2 + off, y, "brick_lt"); K.px(x + 3 + off, y, "brick_dk")
  end
  -- forked tail
  K.px(x + 1, H - 3, "brick_dk"); K.px(x + 4, H - 3, "brick_dk")
  K.px(x + 1, H - 2, "red"); K.px(x + 4, H - 2, "brick")
  K.px(x + 1, H - 1, "brick_dk"); K.px(x + 4, H - 1, "brick_dk")
end)

K.save("guide_book")

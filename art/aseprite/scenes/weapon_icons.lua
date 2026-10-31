-- Store and inventory icons for arms (96x16): six 16x16 icons in simulation/armory.gd key order:
--   0 rifle (half-stock plains rifle)   1 shotgun (double-barrelled muzzle-loader)
--   2 single-shot percussion pistol     3 Colt revolver (Dragoon: brass guard, loading lever)
--   4 Bowie-pattern knife               5 trade hatchet
-- Each is drawn in colour, then ringed with a one-pixel ink outline like the other item icons.
local K = dofile(app.params.kit)
K.canvas(96, 16, 1848)

-- a 45-degree stroke from (x, y) up and to the right, n pixels long, in one colour
local function diag(x, y, n, c)
  for i = 0, n - 1 do K.px(x + i, y - i, c) end
end

local function outline(n)
  local edge = {}
  for y = 0, 15 do
    for x = n * 16, n * 16 + 15 do
      if K.at(x, y) == nil then
        for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
          local ax, ay = x + d[1], y + d[2]
          if ax >= n * 16 and ax < n * 16 + 16 and ay >= 0 and ay < 16 and K.at(ax, ay) ~= nil then edge[#edge + 1] = {x, y}; break end
        end
      end
    end
  end
  for _, p in ipairs(edge) do K.px(p[1], p[2], "ink") end
end

K.layer("icons", function()
  -- rifle: long octagonal barrel, half stock, brass patchbox and butt plate
  local o = 0
  diag(o + 0, 15, 6, "wood"); diag(o + 1, 15, 5, "ochre"); diag(o + 0, 14, 4, "wood")
  K.px(o + 0, 15, "gold"); K.px(o + 1, 13, "gold")
  diag(o + 6, 9, 10, "storm_dk"); diag(o + 5, 9, 5, "wood")
  K.px(o + 6, 10, "gold"); K.px(o + 5, 8, "storm_dk")
  outline(0)

  -- shotgun: shorter, two barrels side by side, heavier stock
  o = 16
  diag(o + 1, 14, 5, "wood"); diag(o + 1, 13, 5, "wood"); diag(o + 2, 14, 5, "ochre"); diag(o + 1, 12, 3, "deep")
  diag(o + 6, 9, 6, "storm_dk"); diag(o + 6, 8, 6, "storm"); diag(o + 7, 9, 5, "storm_lt")
  K.px(o + 6, 10, "gold"); K.px(o + 5, 8, "storm_dk"); K.px(o + 5, 7, "storm_dk")
  outline(1)

  -- single-shot pistol: round barrel, ramrod beneath, birds-head grip, brass cap
  o = 32
  K.rect(o + 5, 6, 9, 2, "storm_dk"); K.rect(o + 5, 6, 9, 1, "storm_lt")
  K.rect(o + 5, 8, 8, 1, "wood")
  K.rect(o + 2, 7, 4, 3, "wood"); K.rect(o + 1, 9, 3, 4, "wood"); K.px(o + 2, 8, "ochre"); K.px(o + 1, 12, "gold")
  K.px(o + 5, 5, "storm_dk"); K.px(o + 6, 9, "gold"); K.px(o + 6, 10, "gold"); K.px(o + 5, 10, "gold")
  outline(2)

  -- Colt revolver: long barrel, fluted cylinder, loading lever, brass guard, walnut grip
  o = 48
  K.rect(o + 8, 5, 7, 2, "storm_dk"); K.rect(o + 8, 5, 7, 1, "storm_lt")
  K.rect(o + 9, 7, 5, 1, "storm")
  K.rect(o + 4, 4, 4, 4, "storm"); K.rect(o + 5, 4, 1, 4, "storm_lt"); K.rect(o + 7, 4, 1, 4, "storm_dk")
  K.rect(o + 3, 5, 1, 3, "storm_dk"); K.px(o + 3, 3, "storm_dk"); K.px(o + 2, 4, "storm_dk")
  K.rect(o + 1, 8, 3, 5, "wood"); K.rect(o + 2, 8, 2, 1, "ochre"); K.px(o + 1, 12, "deep")
  K.px(o + 5, 8, "gold"); K.px(o + 5, 9, "gold"); K.px(o + 4, 9, "gold"); K.px(o + 4, 8, "storm_dk")
  outline(3)

  -- Bowie knife: broad clip-point blade, brass guard, wooden grip
  o = 64
  diag(o + 6, 11, 6, "stone"); diag(o + 6, 10, 6, "stone_lt"); diag(o + 7, 11, 5, "white")
  K.px(o + 12, 5, "stone_lt"); K.px(o + 12, 4, "stone_lt")
  K.px(o + 4, 10, "gold"); K.px(o + 5, 11, "gold"); K.px(o + 6, 12, "gold"); K.px(o + 5, 10, "gold")
  diag(o + 1, 14, 4, "wood"); diag(o + 2, 14, 3, "ochre")
  outline(4)

  -- trade hatchet: hickory haft, iron head with a bright edge
  o = 80
  diag(o + 2, 14, 9, "wood"); diag(o + 3, 14, 8, "ochre")
  K.rect(o + 9, 3, 2, 3, "stone_dk"); K.px(o + 9, 3, "stone")
  K.rect(o + 11, 3, 1, 3, "stone_dk"); K.rect(o + 12, 2, 1, 5, "stone_dk"); K.rect(o + 13, 2, 1, 5, "stone_lt")
  outline(5)
end)

K.save("weapon_icons")

-- 8-frame oxen travel sprite sheet (384x32, eight 48x32 frames).
-- Devon/Shorthorn draft ox with shoulder hump (withers), deep barrel & brisket, dewlap,
-- wooden neck yoke + curved hickory ox-bow + iron hitch ring, and an 8-frame four-beat walk
-- (near hind, near fore, far hind, far fore, a quarter cycle apart, as cattle walk).
local K = dofile(app.params.kit)
local W, H = 384, 32
local FRAMES = 8

K.canvas(W, H, 1848)

local function paint_grid(ox, oy, rows, map)
  for r, row in ipairs(rows) do
    for c = 1, #row do
      local ch = row:sub(c, c)
      local cname = map[ch]
      if cname then K.px(ox + c - 1, oy + r - 1, cname) end
    end
  end
end

local function draw_hind_leg(fx, hip_x, hock_dx, hoof_dx, lift_y, is_far)
  local c_out = "ink"
  local c_mid = is_far and "deep" or "ox_dk"
  local c_lit = is_far and "deep" or "ox"
  local hx = fx + hip_x + hock_dx
  local fx_hoof = fx + hip_x + hoof_dx
  local y_hoof = 27 - lift_y

  -- Upper gaskin (y=18..20)
  K.rect(fx + hip_x, 18, 4, 2, c_mid)
  if not is_far then K.rect(fx + hip_x + 1, 18, 2, 2, c_lit) end
  K.px(fx + hip_x, 18, c_out); K.px(fx + hip_x + 3, 18, c_out)

  -- Hock joint (y=20..22)
  K.rect(hx, 20, 3, 3, c_mid)
  if not is_far then K.px(hx + 1, 20, c_lit); K.px(hx + 1, 21, c_lit) end
  K.px(hx, 20, c_out); K.px(hx + 2, 21, c_out)

  -- Cannon bone from hock (hx+1, 22) to hoof (fx_hoof+1, y_hoof)
  K.line(hx, 22, fx_hoof, y_hoof - 1, c_out)
  K.line(hx + 1, 22, fx_hoof + 1, y_hoof - 1, c_mid)
  K.line(hx + 2, 22, fx_hoof + 2, y_hoof - 1, c_out)

  -- Cloven hoof
  K.rect(fx_hoof, y_hoof, 3, 2, "ink")
  if not is_far then K.px(fx_hoof + 2, y_hoof, "deep") end
end

local function draw_front_leg(fx, sh_x, knee_dx, hoof_dx, lift_y, is_far)
  local c_out = "ink"
  local c_mid = is_far and "deep" or "ox_dk"
  local c_lit = is_far and "deep" or "ox"
  local kx = fx + sh_x + knee_dx
  local fx_hoof = fx + sh_x + hoof_dx
  local y_hoof = 27 - lift_y

  -- Forearm (y=19..21)
  K.rect(fx + sh_x, 19, 3, 3, c_mid)
  if not is_far then K.px(fx + sh_x + 1, 19, c_lit); K.px(fx + sh_x + 1, 20, c_lit) end
  K.px(fx + sh_x, 19, c_out); K.px(fx + sh_x + 2, 19, c_out)

  -- Knee joint (y=21..22 when lifted, 22..23 when planted)
  local ky = 22 - (lift_y > 0 and 1 or 0)
  K.rect(kx, ky, 3, 2, c_mid)
  if not is_far then K.px(kx + 1, ky, c_lit) end
  K.px(kx, ky, c_out); K.px(kx + 2, ky, c_out)

  -- Cannon bone to hoof (tucks back under bent knee when lifted)
  K.line(kx, ky + 1, fx_hoof, y_hoof - 1, c_out)
  K.line(kx + 1, ky + 1, fx_hoof + 1, y_hoof - 1, c_mid)
  K.line(kx + 2, ky + 1, fx_hoof + 2, y_hoof - 1, c_out)

  -- Cloven hoof
  K.rect(fx_hoof, y_hoof, 3, 2, "ink")
  if not is_far then K.px(fx_hoof + 2, y_hoof, "deep") end
end

local function draw_ox_frame(fx, frame)
  -- Ground shadow (translucent ellipse, matching test_art.gd alpha rule)
  for y = -2, 2 do
    for x = -20, 20 do
      if (x*x)/(20*20 + 0.5) + (y*y)/(2*2 + 0.5) <= 1 then
        K.px(fx + 23 + x, 29 + y, "ground_shadow")
      end
    end
  end

  -- the body dips twice per stride, as each hind foot takes the weight
  local cyc = (frame - 1) / FRAMES
  local bob = (math.cos(cyc * 4 * math.pi) < -0.3) and 1 or 0

  -- One leg's pose at phase t: three quarters of the cycle on the ground, the hoof sliding
  -- back as the body passes over it, then a quick swing forward with the joint folded.
  local function leg(base, t, hind)
    t = t % 1
    local hoof, lift, joint
    if t < 0.75 then
      hoof = math.floor(4 - 8 * (t / 0.75) + 0.5); lift = 0
      joint = (hoof < -2) and -1 or 0
    else
      local u = (t - 0.75) / 0.25
      hoof = math.floor(-4 + 8 * u + 0.5); lift = math.floor(3 * math.sin(u * math.pi) + 0.5)
      joint = hind and -1 or ((u < 0.6) and 3 or 1)
    end
    return {base, joint, hoof, lift}
  end
  local p = {
    hn = leg(9, cyc, true), fn = leg(30, cyc + 0.75, false),
    hf = leg(12, cyc + 0.5, true), ff = leg(27, cyc + 0.25, false),
  }

  -- 1. Far legs (behind torso)
  draw_hind_leg(fx, p.hf[1], p.hf[2], p.hf[3], p.hf[4], true)
  draw_front_leg(fx, p.ff[1], p.ff[2], p.ff[3], p.ff[4], true)

  -- 2. Tail (hanging from the high tailhead with a gentle walk sway)
  local sway = math.floor(1.4 * math.sin(cyc * 2 * math.pi) + 0.5)
  local tx = fx + 5
  K.rect(tx, 10 + bob, 2, 3, "ink")
  K.px(tx + 1, 10 + bob, "ox_dk")
  for ty = 13, 19 do
    local sx = (ty >= 16) and sway or 0
    K.px(tx - 1 + sx, ty + bob, "ink")
    K.px(tx + sx, ty + bob, "ox_dk")
  end
  K.rect(tx - 2 + sway, 20 + bob, 3, 3, "ink")
  K.px(tx - 1 + sway, 20 + bob, "deep")
  K.px(tx - 1 + sway, 23 + bob, "ink")

  -- 3. Torso: powerful draft-ox silhouette with high shoulder hump (withers),
  -- deep rounded ribcage/barrel, gentle rear flank tuck, and low brisket
  local body_rows = {
    ".....................oooooo........",
    "......oooooo.......oolllllloo......",
    "....oollllllooooooollhlllllllo.....",
    "...ollhhhhhhllllllllhhllllllmlo....",
    "..olmmhhhhhhllllllllllllllllmmmo...",
    "..ommmmmmmmmmmmmmmmmmllllllmmmmmo..",
    "..ommmmmmmmmmmmmmmmmmmllmmmmmmmmo..",
    "..ommmmmmmmmmmmbbmmmmmmmmbmmmmmmmo.",
    "..obmmmmmmmmmmmbrmmmmmmmbrmmmmmmbo.",
    "..obbmmmmmmmmmmrrbbbbbbbrrmmmmmmdo.",
    "...ordmmmmmmmmmrrdddddddrrbbmmmddo.",
    "...oordddddddddddddddddddddddddddo.",
    "....oooddddddooooooooooooddddddddo.",
    ".....ooooooooo..........ooooooooo..",
  }
  local body_map = {
    o="ink", d="deep", r="ox_dk", b="ox", m="rust", l="ochre", h="gold"
  }
  paint_grid(fx + 4, 6 + bob, body_rows, body_map)

  -- 4. Near legs (in front of torso edge, seamlessly tied into thigh & shoulder)
  draw_hind_leg(fx, p.hn[1], p.hn[2], p.hn[3], p.hn[4], false)
  draw_front_leg(fx, p.fn[1], p.fn[2], p.fn[3], p.fn[4], false)

  -- Seamless muscle blend where near legs meet the haunch and forequarter
  K.rect(fx + p.hn[1], 16 + bob, 4, 3, "ox_dk")
  K.rect(fx + p.hn[1] + 1, 15 + bob, 2, 3, "ox")
  K.rect(fx + p.fn[1], 17 + bob, 3, 3, "ox_dk")
  K.rect(fx + p.fn[1] + 1, 16 + bob, 2, 3, "ox")

  -- 5. Side-profile bovine head, sweeping horns, ear, brow ridge, muzzle & dewlap
  K.px(fx + 40, 5 + bob, "sand")
  K.px(fx + 41, 4 + bob, "sand")
  K.px(fx + 42, 3 + bob, "cream")
  K.px(fx + 43, 2 + bob, "white")

  local head_rows = {
    ".......w......",
    "......wc......",
    ".....cc.......",
    "....ccs.......",
    "..ooosoooo....",
    ".ukkoollllo...",
    ".ouuollhlllo..",
    "...oolllklllo.",
    "...odlllllllso",
    "..oddmmmmmswwo",
    "..odddddddppko",
    "...odddddpppo.",
    "....oodddddoo.",
    ".....oooooo...",
  }
  local head_map = {
    o="ink", d="deep", u="ox_dk", m="rust", l="ochre", h="gold",
    s="sand", c="cream", w="cream", p="wood", k="ink"
  }
  paint_grid(fx + 32, 2 + bob, head_rows, head_map)

  -- 6. Carved wooden neck yoke, curved hickory ox-bow & iron hitch ring
  K.rect(fx + 31, 5 + bob, 4, 3, "deep")
  K.rect(fx + 32, 5 + bob, 2, 2, "gold")
  K.px(fx + 31, 6 + bob, "ochre"); K.px(fx + 33, 7 + bob, "wood")
  K.line(fx + 32, 8 + bob, fx + 33, 16 + bob, "ochre")
  K.line(fx + 33, 8 + bob, fx + 34, 16 + bob, "wood")
  K.rect(fx + 32, 16 + bob, 3, 2, "deep")
  K.rect(fx + 30, 13 + bob, 2, 2, "ink")
  K.px(fx + 30, 13 + bob, "sand")
end

K.layer("oxen", function()
  for f = 1, FRAMES do
    draw_ox_frame((f - 1) * 48, f)
  end
end)

K.save("oxen")

-- Walking emigrants for the travel screen (128x48): two rows of eight 16x24 frames.
-- Row 1 is a man in a blue shirt and slouch hat, row 2 a woman in a red dress and bonnet.
-- Both walk to the right, with legs, arms and a small bob in step. Feet touch y = 23.
local K = dofile(app.params.kit)
local W, H = 128, 48
local FRAMES = 8

K.canvas(W, H, 1848)

-- a limb from (x0, y0) to (x1, y1) two pixels wide, outlined on its trailing side
local function limb(x0, y0, x1, y1, c, edge)
  K.line(x0, y0, x1, y1, c)
  K.line(x0 + 1, y0, x1 + 1, y1, edge or c)
end

local function figure(fx, fy, frame, woman)
  local t = (frame - 1) / FRAMES * 2 * math.pi
  local bob = (math.abs(math.sin(t)) > 0.7) and 0 or 1   -- highest at mid-stride
  local swing = math.sin(t)
  local hip_x, hip_y = fx + 7, fy + 14 + bob
  -- shadow under the feet
  for x = fx + 3, fx + 12 do K.px(x, fy + 23, "ground_shadow") end
  -- far leg and arm first, darker
  local far_foot = math.floor(hip_x + 3 * -swing + 0.5)
  local near_foot = math.floor(hip_x + 3 * swing + 0.5)
  local far_lift = (swing > 0.3) and 1 or 0
  local near_lift = (swing < -0.3) and 1 or 0
  if not woman then
    limb(hip_x, hip_y, far_foot, fy + 22 - far_lift, "deep", "ink")
    K.rect(far_foot, fy + 22 - far_lift, 3, 1, "ink")
  else
    K.rect(far_foot, fy + 22 - far_lift, 2, 1, "ink")
  end
  local shoulder_x, shoulder_y = fx + 7, fy + 8 + bob
  limb(shoulder_x, shoulder_y, math.floor(shoulder_x + 3 * swing + 0.5), fy + 14 + bob, woman and "brick_dk" or "teal", "ink")
  -- body
  if woman then
    -- skirt swings a pixel with the stride
    local hem = math.floor(swing + 0.5)
    K.poly({{fx + 5, fy + 9 + bob}, {fx + 10, fy + 9 + bob}, {fx + 12 + hem, fy + 21}, {fx + 3 + hem, fy + 21}}, "red")
    K.line(fx + 5, fy + 10 + bob, fx + 4 + hem, fy + 20, "brick_lt")
    K.rect(fx + 3 + hem, fy + 21, 10, 1, "brick_dk")
    K.rect(fx + 5, fy + 15 + bob, 6, 1, "cream") -- apron string
  else
    K.rect(fx + 5, fy + 8 + bob, 5, 7, "blue")
    K.rect(fx + 5, fy + 8 + bob, 1, 7, "light_blue")
    K.rect(fx + 9, fy + 9 + bob, 1, 6, "ink")
    K.rect(fx + 5, fy + 14 + bob, 5, 1, "wood")   -- belt
  end
  -- near leg
  if not woman then
    limb(hip_x - 1, hip_y, near_foot - 1, fy + 22 - near_lift, "wood", "deep")
    K.rect(near_foot - 1, fy + 22 - near_lift, 3, 1, "ink")
  else
    K.rect(near_foot - 1, fy + 22 - near_lift, 2, 1, "ink")
  end
  -- head and hat
  K.rect(fx + 6, fy + 4 + bob, 3, 4, "skin"); K.px(fx + 8, fy + 6 + bob, "skin_dk"); K.px(fx + 9, fy + 5 + bob, "skin")
  if woman then
    K.rect(fx + 4, fy + 2 + bob, 5, 3, "cream"); K.rect(fx + 4, fy + 5 + bob, 2, 3, "cream")
    K.px(fx + 9, fy + 3 + bob, "sand")
  else
    K.rect(fx + 4, fy + 3 + bob, 7, 1, "deep"); K.rect(fx + 5, fy + 1 + bob, 4, 2, "deep"); K.px(fx + 5, fy + 1 + bob, "wood")
  end
  K.px(fx + 6, fy + 4 + bob, "appearance_hair")
  -- near arm swings opposite the near leg
  limb(shoulder_x - 1, shoulder_y + 1, math.floor(shoulder_x - 1 - 3 * swing + 0.5), fy + 14 + bob, woman and "red" or "blue", woman and "brick_dk" or "teal")
  K.px(math.floor(shoulder_x - 1 - 3 * swing + 0.5), fy + 15 + bob, "skin")
end

K.layer("walkers", function()
  for f = 1, FRAMES do
    figure((f - 1) * 16, 0, f, false)
    figure((f - 1) * 16, 24, f, true)
  end
end)

K.save("walker")

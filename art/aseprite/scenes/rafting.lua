-- Original Cascades rafting review pack. Project palette, 2:1 projection, binary alpha.
-- Cells: rafting_obstacles 128x96: four 32x32 frames, rows rock/log/debris.
-- Obstacle water-contact anchor (16,22); foam is part of the water, not a hitbox ring.
local K=dofile(app.params.kit)
local function rock(x,y,f)
 local shift=({0,1,0,-1})[f+1]
 K.poly({{x+6,y+22},{x+9,y+17},{x+23,y+16},{x+27,y+21},{x+21,y+26},{x+11,y+25}},'blue')
 K.poly({{x+8,y+20},{x+9,y+14},{x+15,y+8},{x+21,y+10},{x+24,y+18},{x+21,y+23},{x+13,y+24}},'storm_dk')
 K.poly({{x+9,y+14},{x+15,y+8},{x+21,y+10},{x+17,y+15},{x+11,y+17}},'storm_lt')
 K.poly({{x+11,y+17},{x+17,y+15},{x+21,y+10},{x+22,y+18},{x+18,y+22},{x+13,y+22}},'storm')
 K.line(x+12,y+12,x+15,y+10,'stone_lt');K.line(x+15,y+16,x+17,y+17,'storm_dk')
 K.line(x+7,y+22,x+10,y+24,'light_blue');K.line(x+11,y+25,x+16,y+25,'mist')
 K.line(x+19+shift,y+24,x+24+shift,y+22,'white');K.px(x+25+shift,y+20,'mist')
 K.line(x+8+shift,y+28,x+13+shift,y+26,'light_blue')
end
local function log(x,y,f)
 K.poly({{x+2,y+17},{x+6,y+14},{x+28,y+25},{x+25,y+28},{x+18,y+26}},'blue')
 K.poly({{x+3,y+15},{x+6,y+12},{x+29,y+23},{x+28,y+26},{x+25,y+27},{x+3,y+17}},'roof_dk')
 K.poly({{x+4,y+13},{x+7,y+12},{x+29,y+23},{x+26,y+25}},'rust')
 K.line(x+5,y+13,x+25,y+23,'ochre');K.line(x+7,y+17,x+24,y+25,'wood')
 K.line(x+11,y+16,x+16,y+18,'gold');K.line(x+18,y+22,x+23,y+24,'deep')
 K.ellipse(x+27,y+24,2,2,'ochre');K.px(x+27,y+24,'wood');K.px(x+28,y+25,'sand')
 K.line(x+15,y+18,x+16,y+14,'wood');K.line(x+16,y+14,x+18,y+13,'roof_dk')
 local q=f%3;K.line(x+4+q,y+20,x+9+q,y+22,'light_blue');K.line(x+17-q,y+27,x+22-q,y+29,'mist')
end
local function debris(x,y,f)
 local d=({0,1,0,-1})[f+1]
 K.line(x+5,y+13+d,x+23,y+22+d,'wood');K.line(x+6,y+12+d,x+24,y+21+d,'ochre')
 K.line(x+10,y+23-d,x+25,y+16-d,'wood');K.line(x+11,y+22-d,x+26,y+15-d,'gold')
 K.line(x+3,y+25,x+9,y+22,'light_blue');K.line(x+24,y+26,x+28,y+24,'mist')
end
K.canvas(128,96,184856)
K.layer('basalt facets and eddies',function()for f=0,3 do rock(f*32,0,f)end end)
K.layer('bark endgrain and whitewater',function()for f=0,3 do log(f*32,32,f)end end)
K.layer('wreck timbers',function()for f=0,3 do debris(f*32,64,f)end end)
K.save('rafting_obstacles')
K.canvas(128,16,184857)
K.layer('broken current crests',function()
 for f=0,3 do
  local x=f*32;local d=f%3
  K.line(x+3+d,11,x+12+d,7,'light_blue');K.line(x+13+d,7,x+18+d,8,'mist')
  K.line(x+8-d,13,x+16-d,9,'white');K.line(x+21-d,6,x+27-d,3,'light_blue')
  K.px(x+6+d,9,'mist');K.px(x+23-d,9,'light_blue')
 end
end)
K.save('rafting_foam')
K.canvas(72,48,184858)
local function pos(s,c,h)return 2+2*s+2*c,29-s+c-(h or 0)end
K.layer('waterline',function()
 K.poly({{1,31},{45,9},{71,22},{27,45}},'blue')
 K.line(5,33,24,43,'light_blue');K.line(31,42,46,34,'mist');K.line(54,29,68,22,'light_blue')
end)
K.layer('lashed timber deck',function()
 for c=0,12,2 do
  local x,y=pos(0,c);local a,b=pos(22,c)
  K.line(x,y+2,a,b+2,'roof_dk');K.line(x,y+1,a,b+1,'wood')
  K.line(x,y,a,b,'rust');K.line(x,y-1,a,b-1,'ochre')
  if c%4==0 then K.line(x+5,y-3,a-7,b+2,'gold')end
  K.ellipse(x,y,1,1,'ochre');K.px(x,y,'wood')
 end
 for _,s in ipairs({4,18})do
  local x,y=pos(s,0);local a,b=pos(s,12)
  K.line(x,y-2,a,b-2,'deep');K.line(x,y-3,a,b-3,'sand')
  for c=0,12,2 do local u,v=pos(s,c);K.px(u,v-2,'wood')end
 end
end)
K.layer('knots and pole',function()
 local x,y=pos(4,12);K.rect(x-1,y-4,3,2,'gold');K.px(x,y-3,'deep')
 K.line(12,32,53,12,'wood');K.line(12,31,53,11,'sand');K.rect(10,31,5,2,'ochre')
end)
K.save('rafting_raft')

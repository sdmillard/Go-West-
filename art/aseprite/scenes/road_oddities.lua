-- Missing Unhinged road sprites only. Existing blade, sedan, bison and wagons are reused.
-- no seasons
local K = dofile(app.params.kit)

K.canvas(28, 36, 2281)
K.layer("cabinet", function()
  -- A plain red cabinet: packets behind lit glass, coin slot, delivery flap.
  K.poly({{3,4},{7,1},{25,1},{25,32},{22,35},{3,35}},"ink")
  K.rect(4,4,18,29,"red")
  K.poly({{22,4},{24,2},{24,31},{22,33}},"brick_dk")
  K.rect(5,5,16,2,"brick_lt")
  K.rect(6,8,11,17,"deep"); K.rect(7,9,9,15,"blue")
  for row=0,2 do
    for col=0,1 do
      local x,y=8+col*4,10+row*5
      K.rect(x,y,3,3,({"gold","cream","teal"})[row+1]); K.px(x,y,"white")
    end
    K.line(7,14+row*5,15,14+row*5,"stone_ink")
  end
  K.line(7,9,7,22,"glass")
  K.rect(19,11,2,1,"white"); K.rect(19,14,2,3,"ink")
  K.rect(19,19,2,3,"stone")
  K.rect(7,27,13,4,"ink"); K.rect(8,27,11,1,"stone_ink")
  K.rect(5,34,3,2,"ink"); K.rect(19,34,3,2,"ink")
end)
K.save("road_vending_machine")

K.canvas(28, 44, 2282)
K.layer("booth", function()
  -- Glass panels and a receiver, without a carrier's logo.
  K.poly({{3,6},{9,2},{25,2},{25,39},{20,43},{3,43}},"ink")
  K.poly({{5,8},{10,5},{23,5},{23,38},{19,41},{5,41}},"blue")
  K.rect(5,9,14,31,"light_blue")
  K.poly({{20,9},{23,7},{23,38},{20,40}},"teal")
  K.rect(5,4,15,5,"cream"); K.line(7,6,18,6,"storm")
  K.rect(5,9,2,32,"stone_lt"); K.rect(18,9,2,33,"stone")
  K.line(7,27,17,27,"stone")
  K.rect(10,14,7,12,"storm_dk"); K.rect(13,17,3,4,"stone")
  K.rect(9,15,2,7,"ink")
  K.rect(10,15,3,2,"ink"); K.rect(10,20,3,2,"ink")
  K.line(10,22,10,25,"ink"); K.line(10,25,14,25,"ink")
  K.px(14,23,"gold"); K.rect(16,30,1,4,"cream")
  K.line(8,10,8,23,"glass"); K.line(9,10,9,16,"white")
  K.poly({{4,41},{20,41},{24,38},{24,40},{20,43},{4,43}},"stone_ink")
end)
K.save("road_phone_booth")

K.canvas(64, 12, 2283)
K.layer("frogs", function()
  -- Four poses: tucked, falling with legs out, landing, then a little hop.
  for f=0,3 do
    local x,y=f*16+7, f==3 and 4 or 6
    K.ellipse(x,y,4,2,"leaf")
    K.ellipse(x,y-1,3,1,"sage")
    K.rect(x+2,y-3,3,3,"leaf")
    K.px(x+3,y-3,"gold"); K.px(x+3,y-2,"ink")
    if f==1 or f==3 then
      K.line(x-3,y+1,x-6,y+3,"leaf"); K.line(x-6,y+3,x-3,y+4,"leaf")
      K.line(x+2,y+1,x+5,y+3,"leaf")
    else
      K.px(x-3,y+2,"sage"); K.line(x-4,y+3,x-1,y+3,"leaf")
      K.line(x+2,y+2,x+4,y+2,"leaf")
    end
  end
end)
K.save("road_frogs")

-- A review-only contact sheet with a traveler beside each upright object for scale.
local preview=K.canvas(432,150,2284)
K.layer("country", function()
  K.sky(432,90,{{50,12,0.7},{250,17,0.6}},"mist")
  K.rect(0,90,432,60,"sand")
  for i=1,120 do K.px(K.rnd(432),92+K.rnd(58),"sage") end
end)
local out=app.params.out
local pixels=app.params.kit:gsub("lib.lua$","../pixels/")
local sheet=Image(432,150,ColorMode.RGB)
sheet:drawImage(Image{fromFile=out.."/road_vending_machine.png"},Point(70,103))
sheet:drawImage(Image{fromFile=out.."/road_phone_booth.png"},Point(200,95))
local walker=Image(Image{fromFile=pixels.."walker.png"},Rectangle(0,0,16,24))
sheet:drawImage(walker,Point(45,115)); sheet:drawImage(walker,Point(175,115))
local frogs=Image{fromFile=out.."/road_frogs.png"}
for i=0,9 do
  sheet:drawImage(Image(frogs,Rectangle((i%4)*16,0,16,12)),Point(290+(i*31)%120,55+(i*23)%85))
end
preview:newCel(preview:newLayer(),preview.frames[1],sheet,Point(0,0))
K.save("road_oddities_review")

-- Review the frogs as weather, under the existing rain-cloud art, not as a roadside object.
local weather=K.canvas(432,150,2285)
K.layer("weather",function()
  K.rect(0,0,432,96,"storm_lt"); K.rect(0,96,432,54,"sand")
  K.poly({{0,91},{45,80},{100,91},{175,76},{260,87},{350,78},{431,89},{431,99},{0,99}},"far_hill")
  K.rect(0,126,432,12,"silt_lt")
end)
local base=Image(weather)
base:drawImage(Image{fromFile=pixels.."rain_clouds.png"},Point(0,0))
base:drawImage(Image(Image{fromFile=pixels.."wagon.png"},Rectangle(0,0,96,64)),Point(137,75))
base:drawImage(walker,Point(259,113))
local layer=weather.layers[1]
for f=0,15 do
  local frame=f==0 and weather.frames[1] or weather:newFrame()
  frame.duration=0.10
  local picture=base:clone()
  for i=0,29 do
    local x=(i*67-f*2)%416
    local y=32+(i*43+f*9)%106 -- cloud base to ground, keeping each sprite inside the view
    picture:drawImage(Image(frogs,Rectangle(((i+f)%2)*16,0,16,12)),Point(x,y))
  end
  for i=0,11 do
    local x=(i*71+13)%416
    local hop=(i+f)%4==3 and -3 or 0
    picture:drawImage(Image(frogs,Rectangle((2+(i+f)%2)*16,0,16,12)),Point(x,133+(i*7)%5+hop))
  end
  layer:cel(frame).image=picture
end
weather:saveCopyAs(out.."/road_frog_weather_review.gif")

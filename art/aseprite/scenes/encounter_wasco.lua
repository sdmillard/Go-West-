-- Approved Wasco trading landing (October 27, 2026). Original composition, not a reconstruction of a named house.
-- References and uncertainty: docs/NATIVE_ENCOUNTER_ART_BRIEF.md.
local K = dofile(app.params.kit)
K.canvas(432, 150, 184831)
K.layer("river country", function()
  K.sky(432, 63, {{85,12,0.9},{291,7,1.1}}, "mist")
  K.ridge(0,431,0,75,function(x) return -(47+6*math.sin(x/58)+3*math.sin(x/17)) end,"far_hill","mist","haze")
  K.rect(0,65,432,43,"blue")
  for i=1,130 do local x,y=K.rnd(432),68+K.rnd(37); K.rect(x,y,3+K.rnd(11),1,(i%3==0) and "light_blue" or "sky") end
  -- Low basalt shelves in the Columbia, not the modern dammed river.
  for _,r in ipairs({{10,76,77},{175,70,67},{320,81,93}}) do
    K.poly({{r[1],r[2]+4},{r[1]+9,r[2]},{r[1]+r[3]-12,r[2]-2},{r[1]+r[3],r[2]+5}},"roof")
    K.line(r[1]+10,r[2],r[1]+r[3]-13,r[2]-2,"stone_dk")
    K.rect(r[1]+7,r[2]+7,r[3]-10,1,"light_blue")
  end
end)
K.layer("landing", function()
  K.poly({{0,96},{50,99},{120,106},{245,97},{332,101},{431,94},{431,149},{0,149}},"sand")
  K.poly({{0,118},{64,112},{140,120},{267,110},{363,115},{431,110},{431,149},{0,149}},"silt")
  for i=1,600 do local x,y=K.rnd(432),116+K.rnd(34);K.px(x,y,(i%3==0) and "silt_dk" or "silt_lt") end
  K.line(0,96,50,99,"light_blue");K.line(50,99,120,106,"light_blue")
  K.line(120,106,245,97,"light_blue");K.line(245,97,332,101,"light_blue");K.line(332,101,431,94,"light_blue")
  K.willow(13,116,0.65)
end)
K.layer("provisions and work", function()
  -- Plain drying rack and wrapped parcels; no ceremonial or sacred designs.
  K.line(54,128,54,105,"wood");K.line(113,126,113,103,"deep")
  K.line(51,106,117,104,"ochre");K.line(52,109,116,107,"wood")
  for x=60,105,9 do K.line(x,107,x,117,"rust");K.line(x+1,108,x+1,117,"cream");K.px(x,118,"deep") end
  -- Simple dugout silhouette tied at the shallow landing.
  K.poly({{280,100},{289,106},{339,106},{353,98},{339,102},{293,103}},"deep")
  K.line(283,100,345,100,"ochre");K.line(317,101,332,94,"wood")
  K.line(285,101,270,114,"cream")
  K.poly({{145,131},{200,127},{214,140},{157,145}},"cream")
  K.line(145,131,200,127,"clap_sh")
  for _,p in ipairs({{161,133},{176,132},{192,130}}) do
    K.rect(p[1],p[2],10,6,"ochre");K.line(p[1],p[2],p[1]+9,p[2],"cream")
    K.line(p[1]+5,p[2],p[1]+5,p[2]+5,"wood")
  end
  for _,p in ipairs({{129,131},{226,142},{246,137}}) do
    K.ellipse(p[1],p[2],6,4,"wood");K.ellipse(p[1],p[2]-3,6,2,"ochre")
    K.line(p[1]-4,p[2],p[1]+4,p[2],"clap_sh")
    K.px(p[1]-3,p[2]-4,"red");K.px(p[1],p[2]-4,"deep")
  end
  K.crate(363,132);K.barrel(382,136)
end)
K.layer("people", function()
  -- Clothing is deliberately plain at this scale; garment details require reference review.
  local function traveler(x,y,coat,skin)
    K.person(x,y,coat,"deep",false)
    K.rect(x-1,y-16,5,3,"deep")
    K.rect(x,y-13,3,3,skin)
    K.line(x+2,y-14,x+3,y-9,"deep")
  end
  traveler(135,126,"teal","skin_dk")
  traveler(207,126,"red","skin_dk")
  traveler(80,133,"cream","skin_dk")
  K.person(236,128,"blue","roof",false)
  traveler(315,120,"ochre","skin_dk")
end)
K.save("encounter_the_dalles")

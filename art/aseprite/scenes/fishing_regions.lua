-- Regional draft scenery only; no access, species or fishing-rule changes.
local kit=app.params.kit
local out=app.params.out
local specs={
 {id='prairie',label='Wooded prairie',seed=1801,ground='grass',water='teal',rim='sand'},
 {id='platte',label='Open Platte',seed=1802,ground='sage',water='silt',rim='sand'},
 {id='green',label='Green River',seed=1803,ground='silt',water='teal',rim='silt_lt'},
 {id='snake',label='Snake River',seed=1804,ground='ochre',water='blue',rim='silt_lt'},
 {id='boise',label='Boise confluence',seed=1805,ground='sage',water='teal',rim='sand'},
 {id='umatilla',label='Umatilla',seed=1806,ground='grass',water='blue',rim='stone'},
 {id='john_day',label='John Day',seed=1807,ground='ochre',water='teal',rim='stone_lt'},
 {id='deschutes',label='Deschutes',seed=1808,ground='silt',water='blue',rim='stone_ink'},
}
local native={}
for _,s in ipairs(specs) do
 local K=dofile(kit);local spr=K.canvas(432,150,s.seed)
 K.layer('01 sky and distant country',function()
  K.rect(0,0,432,150,'mist')
  K.sky(432,65,{{57,16,0.7},{203,10,0.6},{352,24,0.8}})
  if s.id=='prairie' then
   K.poly({{0,59},{44,52},{90,58},{140,49},{190,56},{240,51},{292,55},{340,49},{390,54},{432,51},{432,84},{0,84}},'far_hill')
  elseif s.id=='platte' then
   K.poly({{0,68},{60,66},{115,67},{190,64},{240,66},{310,63},{370,65},{432,64},{432,82},{0,82}},'far_hill')
  elseif s.id=='green' then
   K.poly({{0,64},{43,51},{67,50},{89,36},{129,35},{149,47},{185,56},{217,51},{250,56},{280,43},{308,42},{331,51},{360,53},{393,43},{432,48},{432,85},{0,85}},'far_hill')
  elseif s.id=='snake' or s.id=='deschutes' then
   K.poly({{0,44},{35,38},{66,44},{98,57},{132,60},{171,52},{210,49},{249,54},{287,45},{331,33},{371,32},{405,43},{432,42},{432,84},{0,84}},'far_hill')
  elseif s.id=='boise' then
   K.poly({{0,65},{44,62},{81,54},{128,51},{169,57},{210,55},{250,61},{292,58},{335,53},{379,57},{432,54},{432,84},{0,84}},'far_hill')
  elseif s.id=='umatilla' then
   K.poly({{0,51},{47,43},{93,48},{142,32},{188,39},{219,31},{263,42},{312,35},{362,44},{404,40},{432,46},{432,86},{0,86}},'haze')
   K.poly({{0,68},{47,58},{91,64},{129,53},{180,62},{225,50},{270,59},{317,52},{370,60},{432,51},{432,86},{0,86}},'far_hill')
  else
   K.poly({{0,53},{29,47},{59,52},{94,39},{120,45},{151,58},{183,53},{220,47},{254,51},{291,39},{323,43},{364,32},{392,38},{432,31},{432,86},{0,86}},'far_hill')
  end
 end)
 K.layer('02 far shore landforms',function()
  K.rect(0,82,432,9,s.rim)
  if s.id=='prairie' then
   K.rect(0,67,432,16,'grass');for i=1,42 do local x=K.rnd(432);K.elm(x,76+K.rnd(6),0.35+K.rnd(3)*0.08) end
   K.rect(0,81,432,2,'pine');K.rect(0,83,432,1,'sand')
  elseif s.id=='platte' then
   K.poly({{0,74},{80,72},{140,76},{210,70},{283,73},{348,69},{432,73},{432,85},{0,85}},'sage')
   for _,x in ipairs({27,44,61,321,337}) do K.elm(x,77,0.35) end
   K.rect(0,82,432,3,'sand')
  elseif s.id=='green' then
   K.poly({{0,70},{40,62},{67,63},{90,56},{135,55},{161,63},{183,72},{240,74},{278,66},{312,59},{356,60},{383,68},{432,66},{432,88},{0,88}},'silt')
   K.poly({{90,56},{135,55},{161,63},{151,71},{128,67},{113,75},{98,67}},'silt_dk')
   K.line(91,56,134,55,'silt_lt');K.line(280,67,310,61,'sand')
   for i=1,60 do local x=K.rnd(432);local y=68+K.rnd(12);if K.at(x,y)=='silt' then K.rect(x,y,3,1,'silt_lt') end end
  elseif s.id=='snake' or s.id=='deschutes' then
   local high=s.id=='deschutes'
   local pts=high and {{0,47},{42,49},{73,58},{109,63},{150,75},{201,77},{251,70},{288,57},{320,47},{365,42},{399,48},{432,44},{432,91},{0,91}} or {{0,61},{34,57},{71,62},{105,69},{150,73},{199,75},{248,71},{282,62},{321,59},{359,62},{400,56},{432,60},{432,88},{0,88}}
   K.poly(pts,'roof_lt')
   for i=1,145 do local x=K.rnd(432);local y=(high and 45 or 57)+K.rnd(40);if K.at(x,y)=='roof_lt' then K.rect(x,y,1,4+K.rnd(8),'roof_dk');K.px(x-1,y,'stone_ink') end end
   K.poly({{0,78},{60,76},{112,81},{161,80},{213,84},{273,79},{337,78},{390,75},{432,78},{432,90},{0,90}},'silt')
   for i=1,35 do K.sage(K.rnd(432),83+K.rnd(5)) end
  elseif s.id=='boise' then
   K.rect(0,72,432,14,'sage')
   for _,x in ipairs({10,29,53,77,101,132,163,195,222,304,326,351,377,408}) do K.elm(x,80+K.rnd(3),0.35+K.rnd(3)*0.07) end
   K.poly({{432,74},{388,77},{348,80},{315,84},{251,88},{243,92},{306,87},{358,85},{405,83},{432,82}},'light_blue')
  elseif s.id=='umatilla' then
   K.poly({{0,75},{36,69},{79,72},{121,63},{166,70},{211,68},{254,74},{310,67},{360,71},{397,65},{432,69},{432,90},{0,90}},'grass')
   for _,x in ipairs({7,24,43,88,103,130,157,326,347,379,401,422}) do K.conifer(x,80,13+K.rnd(9),'pine','leaf','grass') end
   for _,x in ipairs({193,211,231,271}) do K.elm(x,84,0.4) end
  else
   K.poly({{0,64},{35,58},{70,65},{105,70},{148,75},{196,77},{234,71},{270,57},{306,51},{342,48},{371,41},{403,43},{432,38},{432,90},{0,90}},'ochre')
   K.poly({{270,57},{306,51},{342,48},{371,41},{403,43},{432,38},{432,49},{401,53},{370,50},{344,60},{305,60},{285,68}},'rust')
   K.line(274,58,307,52,'gold');K.line(345,49,371,42,'sand');K.line(375,57,430,51,'wood')
   for i=1,30 do K.sage(K.rnd(432),79+K.rnd(8)) end
  end
 end)
 K.layer('03 water and currents',function()
  -- Leave the distant bank visible; open target area is always centered on (288,110).
  K.poly({{0,88},{90,86},{181,88},{248,90},{328,87},{432,85},{432,150},{0,150}},s.water)
  K.line(0,88,90,86,s.rim);K.line(90,86,181,88,s.rim);K.line(328,87,431,85,s.rim)
  if s.id=='platte' then
   K.poly({{134,96},{166,92},{205,94},{227,97},{190,99},{150,99}},'sand')
   K.line(150,97,199,95,'cream');K.poly({{343,102},{369,97},{415,96},{432,98},{432,102},{375,104}},'silt_lt')
  elseif s.id=='boise' then
   K.poly({{190,95},{220,91},{254,92},{268,96},{247,100},{209,101}},'sand');K.rect(219,94,24,1,'sage')
  end
  for i=1,200 do local x=K.rnd(432);local y=91+K.rnd(59);if not(x>266 and x<311 and y>99 and y<122) and K.at(x,y)==s.water then K.rect(x,y,2+K.rnd(6),1,s.id=='platte' and ({'silt_lt','sand','silt_dk'})[1+K.rnd(3)] or ({'sky','light_blue','haze'})[1+K.rnd(3)]) end end
  if s.id=='deschutes' then for _,a in ipairs({{169,98},{342,125},{385,100}}) do K.ellipse(a[1],a[2],5,2,'roof');K.line(a[1]-7,a[2]+2,a[1]+9,a[2]+2,'cream');K.line(a[1]+4,a[2]+4,a[1]+13,a[2]+4,'light_blue') end end
 end)
 K.layer('04 near shore and clear standing place',function()
  K.poly({{0,79},{30,82},{55,88},{73,96},{86,107},{88,117},{98,128},{113,140},{119,150},{0,150}},'deep')
  K.poly({{0,78},{29,81},{54,87},{72,95},{83,107},{83,117},{94,129},{107,140},{113,150},{0,150}},s.rim)
  K.poly({{0,78},{28,80},{51,85},{68,94},{78,105},{77,117},{88,131},{99,141},{105,150},{0,150}},s.ground)
  -- Fixed sandy shelf under angler's feet at (64,138).
  K.poly({{0,109},{23,114},{40,127},{58,130},{73,130},{82,139},{88,150},{41,150},{30,135},{12,123},{0,122}},'sand')
  K.line(36,136,53,142,'silt_lt')
  for i=1,120 do local x=K.rnd(104);local y=83+K.rnd(67);if K.at(x,y)==s.ground then K.rect(x,y,2,1,({'sage','gold','silt_dk'})[1+K.rnd(3)]) end end
  if s.id=='prairie' then K.elm(16,110,1.5)
  elseif s.id=='umatilla' then K.conifer(13,114,53,'pine','leaf','grass');K.conifer(31,105,32,'pine','leaf','grass')
  elseif s.id=='boise' then K.elm(12,110,1.1);K.willow(39,99,1.1)
  elseif s.id=='platte' then K.willow(13,98,0.8)
  else for _,a in ipairs({{11,96},{35,101},{78,124},{97,146}}) do K.sage(a[1],a[2]) end end
  for _,a in ipairs({{27,94},{82,124},{98,145}}) do
   K.ellipse(a[1],a[2],4,2,'stone_ink');K.ellipse(a[1]-1,a[2]-1,3,2,s.id=='deschutes' and 'roof_lt' or 'stone');K.rect(a[1]-3,a[2]-2,2,1,'stone_lt')
  end
  for _,a in ipairs({{78,108},{90,129},{108,149}}) do local x,y=a[1],a[2];K.line(x,y,x-1,y-7,'leaf');K.line(x+1,y,x+3,y-5,'sage');K.px(x-2,y-8,'gold') end
 end)
 local name='fishing_riverbank_'..s.id
 K.save(name);native[#native+1]=spr
 spr:resize(1296,450);spr:saveCopyAs(out..'/preview/'..name..'_x3.png');spr:resize(432,150)
end
-- Two columns, four rows, in the order of specs. No labels painted into game assets.
local board=Sprite(864,600,ColorMode.RGB);local img=Image(864,600,ColorMode.RGB)
for i,spr in ipairs(native) do img:drawSprite(spr,1,Point(((i-1)%2)*432,math.floor((i-1)/2)*150)) end
board:newCel(board.layers[1],1,img);board:resize(1728,1200);board:saveCopyAs(out..'/preview/fishing-regions-board.png')
-- Verify outputs directly from saved native images.
local palette=dofile(kit).col
local allowed={};for _,c in pairs(palette) do allowed[c]=true end
for _,s in ipairs(specs) do
 local a=app.open(out..'/fishing_riverbank_'..s.id..'.png');assert(a.width==432 and a.height==150)
 local pixels=a.cels[1].image
 for p in pixels:pixels() do assert(app.pixelColor.rgbaA(p())==255,'Background alpha');assert(allowed[p()],'Off-palette pixel') end
 assert(pixels:getPixel(64,138)==palette.sand,'Angler standing spot')
 assert(pixels:getPixel(288,110)==palette[s.water],'Clear bobber water')
 a:close()
end
print('Verified eight native 432x150 opaque regional backgrounds.')

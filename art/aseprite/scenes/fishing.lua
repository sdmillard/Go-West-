-- Draft fishing art. Run with real Aseprite and --script-param kit=.../lib.lua
local K=dofile(app.params.kit)
local out=app.params.out
local bank=K.canvas(432,150,1848)
K.layer('sky',function() K.sky(432,57,{{42,17,0.8},{186,12,0.65},{350,23,0.9}}) end)
K.layer('far bank',function()
 K.poly({{0,58},{37,52},{85,57},{134,51},{175,55},{222,48},{270,52},{324,48},{372,52},{432,47},{432,76},{0,76}},'far_hill')
 K.poly({{0,66},{52,63},{96,66},{140,60},{193,63},{249,59},{303,63},{363,58},{432,61},{432,77},{0,77}},'grass')
 for x=7,432,19 do K.elm(x,66+K.rnd(5),0.35+K.rnd(3)*0.05) end
 K.rect(0,72,432,3,'pine');K.rect(0,75,432,1,'sand')
end)
K.layer('open water',function()
 K.rect(0,76,432,74,'blue');K.rect(0,77,432,7,'teal')
 for i=1,215 do local x=K.rnd(432);local y=79+K.rnd(71);local n=2+K.rnd(6);if not(x>263 and x<309 and y>99 and y<122) then K.rect(x,y,n,1,({'light_blue','sky','teal'})[1+K.rnd(3)]) end end
 for _,a in ipairs({{179,86,23},{325,94,18},{204,131,21},{370,119,13},{310,141,28}}) do K.rect(a[1],a[2],a[3],1,'haze');K.rect(a[1]+5,a[2]+2,a[3]-8,1,'sky') end
end)
K.layer('near bank',function()
 K.poly({{0,77},{32,80},{57,87},{75,94},{88,105},{91,115},{99,125},{115,135},{125,150},{0,150}},'deep')
 K.poly({{0,76},{32,79},{57,85},{74,93},{86,104},{86,115},{96,126},{109,136},{116,150},{0,150}},'ochre')
 K.poly({{0,75},{29,78},{53,83},{70,92},{81,103},{80,116},{90,128},{102,139},{106,150},{0,150}},'grass')
 K.poly({{0,105},{26,109},{42,120},{61,127},{76,130},{85,140},{92,150},{33,150},{27,134},{10,121},{0,120}},'dirt_dk')
 K.poly({{0,105},{26,110},{40,123},{57,129},{74,131},{81,137},{87,150},{43,150},{33,135},{15,121},{0,119}},'sand')
 for i=1,200 do local x=K.rnd(103);local y=80+K.rnd(70);if K.at(x,y)=='grass' then K.rect(x,y,2,1,({'sage','leaf','gold'})[1+K.rnd(3)]) end end
 for _,a in ipairs({{30,90},{61,103},{81,123},{99,145}}) do K.ellipse(a[1],a[2],5,2,'stone_ink');K.ellipse(a[1]-1,a[2]-1,4,2,'stone');K.rect(a[1]-3,a[2]-2,3,1,'stone_lt') end
end)
K.layer('cottonwood and reeds',function()
 K.elm(17,110,1.6)
 for _,a in ipairs({{79,104},{91,126},{111,148},{8,148},{24,143}}) do
  local x,y=a[1],a[2];K.line(x,y,x-1,y-10,'leaf');K.line(x+2,y,x+4,y-7,'grass');K.line(x-2,y,x-5,y-5,'sage');K.rect(x-2,y-12,2,4,'wood');K.px(x-2,y-12,'gold')
 end
end)
K.save('fishing_riverbank')

-- Small sprites use the same named palette, with full RGBA transparency.
local C=K.col
local im,ww,hh
local function px(x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and y>=0 and x<ww and y<hh then im:drawPixel(x,y,C[c]) end end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end end
local function line(x,y,x2,y2,c) local n=math.max(math.abs(x2-x),math.abs(y2-y));if n==0 then px(x,y,c);return end;for i=0,n do px(math.floor(x+(x2-x)*i/n+0.5),math.floor(y+(y2-y)*i/n+0.5),c) end end
local function ellipse(x,y,rx,ry,c) for yy=-ry,ry do for xx=-rx,rx do if xx*xx/(rx*rx+0.5)+yy*yy/(ry*ry+0.5)<=1 then px(x+xx,y+yy,c) end end end end
local function fish(x,y,f)
 local dy=f%2;line(x,y+2+dy,x+3,y+4,'teal');line(x,y+6-dy,x+3,y+4,'teal');ellipse(x+7,y+4,5,2,'teal');rect(x+4,y+3,6,1,'sage');rect(x+5,y+5,6,1,'cream');px(x+11,y+3,'ink');px(x+7,y+1,'grass');px(x+8,y+6,'ochre')
end
local sources={}
local function sprite(name,w,h,cols,rows,draw,tags)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name=name
 sources[name]={}
 local sheet=Image(w*cols,h*rows,ColorMode.RGB)
 for f=0,cols*rows-1 do
  if f>0 then s:newEmptyFrame() end
  ww=w;hh=h;im=Image(w,h,ColorMode.RGB);draw(f%cols,math.floor(f/cols));sources[name][f+1]=im:clone()
  s:newCel(s.layers[1],s.frames[f+1],im,Point(0,0));s.frames[f+1].duration=0.16
  sheet:drawImage(im,Point(f%cols*w,math.floor(f/cols)*h))
 end
 for r,label in ipairs(tags or {}) do local t=s:newTag((r-1)*cols+1,r*cols);t.name=label end
 s:saveAs(out..'/'..name..'.aseprite');sheet:saveAs(out..'/'..name..'.png')
 return s
end
local angler=sprite('fishing_angler',32,32,4,4,function(f,row)
 local lean=({0,0,-1,-1})[row+1];local x=11+lean
 -- Fixed boot registration: ground contact at local (12,30).
 rect(8,28,5,3,'deep');rect(15,28,6,3,'deep');rect(10,22,3,6,'wood');rect(15,22,3,6,'wood');rect(10,22,1,5,'rust')
 rect(x-3,14,9,10,'blue');rect(x-3,14,3,8,'light_blue');rect(x+4,16,2,8,'teal');rect(x-2,23,7,1,'deep');rect(x-1,14,3,1,'cream')
 rect(x-1,8,6,6,'skin');rect(x+3,10,3,2,'skin');rect(x+3,12,2,2,'skin_dk');px(x+4,9,'ink');rect(x-2,8,2,5,'appearance_hair')
 rect(x-2,4,7,4,'wood');rect(x-1,4,4,1,'ochre');rect(x-4,8,12,1,'deep');rect(x-3,7,10,1,'gold')
 local handx,handy,tipx,tipy=20,18,30,7
 if row==0 then local poses={{14,14,4,2},{17,13,17,1},{21,15,30,3},{21,18,31,12}};local p=poses[f+1];handx,handy,tipx,tipy=p[1],p[2],p[3],p[4]
 elseif row==1 then handy=18+math.floor(f/2);tipy=8+math.floor(f/2)
 elseif row==2 then handx=19;handy=15-f;tipx=29-f*2;tipy=4
 else handx=21;handy=13;tipx=27;tipy=2 end
 line(x+3,16,handx-2,handy,'teal');line(x+2,15,handx-2,handy-1,'light_blue');rect(handx-1,handy-1,3,3,'skin');px(handx+1,handy+1,'skin_dk')
 line(handx,handy,tipx,tipy,'wood');line(handx,handy-1,tipx,tipy-1,'gold')
 if row==3 then line(tipx,tipy,28,18,'cream');fish(19,16+f%2,f) end
end,{'cast','wait','strike','land'})
local bobber=sprite('fishing_bobber',8,8,4,3,function(f,r)
 local y=r==0 and (2+math.floor(f/2)) or r==1 and (2+f%2) or (3+f)
 if r<2 or f<2 then line(3,y-1,3,y+2,'wood');rect(2,y,3,2,'red');rect(2,y+2,3,1,'cream') end
 line(0,6,2,6,'light_blue');line(5,6,7,6,'light_blue');if r==1 then px(f%2,4,'haze') end
 if r==2 then px(2+f%3,4-f%2,'light_blue');px(5,3+f%2,'haze') end
end,{'idle','nibble','bite'})
local splash=sprite('fishing_splash',16,16,4,1,function(f)
 local a=({2,4,6,7})[f+1];local top=({7,2,4,8})[f+1]
 line(8-a,12,8-2,13,'light_blue');line(10,13,math.min(15,8+a),12,'haze');line(8-a,11,6,10,'sky');line(10,10,math.min(15,8+a),11,'light_blue')
 if f<3 then line(6,10,5-f,top,'light_blue');line(10,10,12+f,top+1,'haze');line(8,9,8,top+2,'white');px(3,top+1,'haze');px(13,top,'light_blue') end
end,{'splash'})
local catch=sprite('fishing_catch',16,8,2,1,function(f) fish(0,-1,f) end,{'flop'})

-- Preview only: no gameplay or timing rules are embedded in these composites.
local demo=Sprite(432,150,ColorMode.RGB);demo.layers[1].name='Draft composition'
for f=0,31 do
 if f>0 then demo:newEmptyFrame() end
 local pic=Image(432,150,ColorMode.RGB);pic:drawSprite(bank,1)
 local row=math.floor(f/8);local af=math.floor(f/2)%4
 pic:drawImage(sources.fishing_angler[row*4+af+1],Point(52,108))
 if row>=1 and row<=2 then
  im=pic;ww=432;hh=150
  local tx,ty=82,115+math.floor(af/2)
  if row==2 then tx=81-af*2;ty=111 end
  line(tx,ty,288,110,'cream')
  local br=row==2 and 2 or (f%8>4 and 1 or 0);pic:drawImage(sources.fishing_bobber[br*4+af+1],Point(285,104))
 end
 if (row==0 and f%8>=4) or (row==2 and f%8<4) then pic:drawImage(sources.fishing_splash[af+1],Point(280,99)) end
 demo:newCel(demo.layers[1],demo.frames[f+1],pic);demo.frames[f+1].duration=0.14
end
demo:saveAs(out..'/fishing-demo.aseprite');demo:resize(864,300);demo:saveCopyAs(out..'/preview/fishing-demo.gif')
for _,name in ipairs({'fishing_riverbank','fishing_angler','fishing_bobber','fishing_splash','fishing_catch'}) do
 local s=app.open(out..'/'..name..'.png');s:resize(s.width*3,s.height*3);s:saveCopyAs(out..'/preview/'..name..'_x3.png');s:close()
end
print('Fishing draft assets, tagged animation sources, sheets and preview GIF complete.')

-- Original livestock drafts. Aseprite Lua, named project palette only.
local K=dofile(app.params.kit);local C=K.col;local out=app.params.out
local im,W,H,active
local function px(x,y,c) x=math.floor(x+0.5);y=math.floor(y+0.5);if x>=0 and y>=0 and x<W and y<H then im:drawPixel(x,y,C[c]) end end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end end
local function line(x,y,u,v,c) local n=math.max(1,math.ceil(math.max(math.abs(u-x),math.abs(v-y))*2));for i=0,n do px(x+(u-x)*i/n,y+(v-y)*i/n,c) end end
local function ell(x,y,rx,ry,lit,mid,dark)
 for yy=-ry,ry do for xx=-rx,rx do if xx*xx/(rx*rx+0.1)+yy*yy/(ry*ry+0.1)<=1 then px(x+xx,y+yy, yy<-ry*0.25 and lit or (yy>ry*0.5 and dark or mid)) end end end
end
local function setlayer(s,name) local l=s:newLayer();l.name=name;return l end
local cache={}
local function make(name,w,h,rows,cols,paint,tags)
 local s=Sprite(w,h,ColorMode.RGB);s:deleteLayer(s.layers[1]);local body=setlayer(s,'anatomy');local detail=setlayer(s,'coat and details')
 local sheet=Image(w*cols,h*rows,ColorMode.RGB);cache[name]={}
 for r=0,rows-1 do for f=0,cols-1 do
  local idx=r*cols+f+1;if idx>1 then s:newEmptyFrame() end
  local flat=Image(w,h,ColorMode.RGB)
  for pass=1,2 do W=w;H=h;im=Image(w,h,ColorMode.RGB);paint(f,r,pass);s:newCel(pass==1 and body or detail,idx,im);flat:drawImage(im) end
  cache[name][idx]=flat;sheet:drawImage(flat,Point(f*w,r*h));s.frames[idx].duration=1/12
 end end
 for r,tag in ipairs(tags) do local t=s:newTag((r-1)*cols+1,r*cols);t.name=tag end
 s:saveAs(out..'/'..name..'.aseprite');sheet:saveAs(out..'/'..name..'.png')
 local v=app.open(out..'/'..name..'.png');v:resize(v.width*3,v.height*3);v:saveCopyAs(out..'/preview/'..name..'_x3.png');v:close()
 print('built '..name..' '..w*cols..'x'..h*rows)
end
local function travel(kind,f,row,pass)
 local t=f/8*2*math.pi;local walk=row==1;local cow=kind=='cow';local goat=kind=='goat'
 local bob=walk and (f%4==2 and 1 or 0) or 0
 if not cow and not goat then
  local peck=not walk and f>=3 and f<=5;local hx=peck and 29 or 28;local hy=peck and 36 or 31
  if pass==1 then
   for _,a in ipairs({{22,0},{26,math.pi}}) do local shift=walk and math.floor(math.sin(t+a[2])*1.5) or 0;line(a[1],36,a[1]+shift,39,'ochre');line(a[1]+shift,39,a[1]+shift+2,39,'gold') end
   ell(24,34,5,3,'cream','sand','ochre');line(20,33,18,30,'deep');line(20,34,18,32,'rust');ell(hx,hy,2,2,'white','cream','sand');line(27,34,hx,hy,'cream')
  else line(22,33,25,34,'ochre');line(22,34,24,35,'gold');px(hx+1,hy,'ink');px(hx+3,hy+1,'gold');rect(hx-1,hy-3,3,1,'red');px(hx+1,hy+2,'red') end
  return
 end
 local y=(cow and 25 or 29)+bob;local left=cow and 10 or 15;local right=cow and 32 or 30
 if pass==1 then
  -- Far legs darker, near legs lit. Four-beat motion, never sliding the whole body.
  for _,leg in ipairs({{left+4,0.5,true},{right-3,0.75,true},{left+2,0,false},{right-5,0.25,false}}) do
   local ph=t+leg[2]*2*math.pi;local swing=walk and math.sin(ph)*(cow and 2 or 1.5) or 0;local lift=walk and math.max(0,math.cos(ph))*2 or 0
   line(leg[1],y+3,leg[1]+swing*0.5,34,leg[3] and 'stone_ink' or 'stone');line(leg[1]+swing*0.5,34,leg[1]+swing,38-lift,leg[3] and 'deep' or 'stone_dk');rect(math.floor(leg[1]+swing),38-math.floor(lift),2,2,'deep')
  end
  ell((left+right)/2,y,(right-left)/2,cow and 6 or 4,cow and 'ox_white' or 'cream',cow and 'stone_lt' or 'sand','stone_dk')
  ell(right-1,y-1,3,5,cow and 'ox_white' or 'cream',cow and 'stone_lt' or 'sand','stone_dk')
  local heady=y-(cow and 4 or 5)+(not walk and f>=4 and f<=5 and 1 or 0)
  ell(right+3,heady,3,cow and 4 or 3,'cream','stone_lt','stone_dk');ell(right+6,heady+2,3,2,'sand','silt_lt','stone_dk')
  line(left,y-3,left-3,y+4,'stone_dk');line(left-3,y+4,left-3+(f>=4 and 1 or 0),y+8,'deep')
  if cow then ell(left+11,y+6,3,2,'skin','skin','skin_dk');px(left+10,y+9,'skin_dk');px(left+13,y+9,'skin_dk') end
 else
  if cow then
   ell(16,y-2,4,3,'rust','ox','ox_dk');ell(25,y+1,3,3,'ox','ox_dk','deep');rect(11,y-2,2,3,'ox')
  else line(18,y-3,23,y-3,'white');line(right+5,y,right+4,y+5,'cream');px(right+4,y+6,'stone_dk');line(left,y-3,left-2,y-6,'cream') end
  local hy=y-(cow and 4 or 5)+(not walk and f>=4 and f<=5 and 1 or 0)
  line(right+1,hy-3,right,hy-5,'stone_dk');line(right+4,hy-3,right+3,hy-5,'ochre');line(right+1,hy-1,right-1,hy,'stone_dk');px(right+4,hy,'ink');px(right+8,hy+2,'deep');px(right+6,hy-2,'cream')
  if not walk and f>=6 then line(right-1,hy-1,right-2,hy-2,'stone_lt') end
 end
end
for _,kind in ipairs({'cow','goat','chicken'}) do make('livestock_'..kind,48,44,2,8,function(f,r,p) travel(kind,f,r,p) end,{'idle','walk_right'}) end

-- Crossing coordinates mirror cross_horses.lua: s forward, c toward viewer,
-- h up; projection axes (.894,.447), anchor (12,34), wade 3.6 / swim 6.
local z,cut
local function pt(s,c,h,col)
 if h<cut then return end;if cut>-99 and h<cut+0.55 then col='light_blue' end
 local x=math.floor(12+(s+c)*0.894+0.5);local y=math.floor(34+(c-s)*0.447-h+0.5)
 local key=y*100+x;local d=(c-s)*0.447+h;if not z[key] or d>=z[key].d then z[key]={d=d,x=x,y=y,c=col} end
end
local function seg(s,c,h,u,v,w,col) local n=math.ceil(math.max(math.abs(s-u),math.abs(c-v),math.abs(h-w))*3)+1;for i=0,n do local a=i/n;pt(s+(u-s)*a,c+(v-c)*a,h+(w-h)*a,col) end end
local function blob(s,c,h,rs,rc,rh,lit,mid,dark,patch)
 for i=0,32 do local th=i/32*math.pi;for j=0,48 do local ph=j/48*2*math.pi;local ns,nc,nh=math.sin(th)*math.cos(ph),math.sin(th)*math.sin(ph),math.cos(th);local l=nh*0.8-nc*0.5+ns*0.1;local col=l>0.45 and lit or (l< -0.15 and dark or mid)
 if patch and ((ns< -0.15 and nh>0.05) or (ns>0.2 and nh<0.3 and nc>0.3)) then col=l>0.45 and 'rust' or 'ox_dk' end
 pt(s+rs*ns,c+rc*nc,h+rh*nh,col) end end
end
for _,kind in ipairs({'cow','goat'}) do
 make('cross_livestock_'..kind,48,40,3,8,function(f,r,pass)
  if pass==2 then return end
  local cow=kind=='cow';local scale=cow and 1 or 0.72;local t=f/8*math.pi*2;cut=({-99,3.6,6})[r+1];z={}
  local function b(s,c,h,rs,rc,rh,lit,mid,dark,patch) blob(s*scale,c*scale,h*scale,rs*scale,rc*scale,rh*scale,lit,mid,dark,patch) end
  local function g(s,c,h,u,v,w,col) seg(s*scale,c*scale,h*scale,u*scale,v*scale,w*scale,col) end
  for _,a in ipairs({{-5,-1.4,0.5},{4,-1.4,0.75},{-5,1.4,0},{4,1.4,0.25}}) do local ph=t+a[3]*math.pi*2;local sw=math.sin(ph)*1.7;local lift=math.max(0,math.cos(ph))*1.5;g(a[1],a[2],7,a[1]+sw*0.5,a[2],3,'stone_dk');g(a[1]+sw*0.5,a[2],3,a[1]+sw,a[2],lift,'deep') end
  b(0,0,9,6.8,2.7,3.1,'cream','stone_lt','stone_dk',cow)
  b(5.5,0,11,2,1.7,3,'cream','stone_lt','stone_dk');b(8,0,13,2,1.4,2,'cream','stone_lt','stone_dk');b(10,0,12,1.8,1.3,1.1,'sand','silt_lt','stone_dk')
  g(7.3,-0.7,14.5,6.8,-0.7,16.5,'ochre');g(8.1,0.9,14.5,7.5,0.9,16.4,'stone_dk');g(7,1.2,13.8,6,2.6,13,'stone_dk');pt(9*scale,1.4*scale,13*scale,'ink')
  g(-7,0,10,-8,0,5,'stone_dk');g(-8,0,5,-8.5,0,3.5,'deep')
  if cow then b(-1,0,5.7,2,1.5,1.2,'skin','skin','skin_dk') else g(9,0,11,8.5,0,9,'cream');g(-6.5,0,10,-8,0,12,'cream') end
  -- Same waterline convention as horses, but trim goat relative to its smaller body.
  for _,e in pairs(z) do px(e.x,e.y,e.c) end
  if r>0 then local yy=math.floor(34-cut);line(5,yy+2,11,yy+3,'light_blue');line(17,yy-2,24,yy-3,'light_blue');if r==2 then px(26,yy-4,'cream') end end
 end,{'walk','wade','swim'})
end
make('livestock_coop',32,32,1,1,function(f,r,p)
 if p==1 then
  rect(3,12,23,15,'deep');rect(4,12,20,13,'wood');rect(5,13,18,10,'ink');line(3,12,8,7,'gold');line(8,7,28,7,'gold');line(28,7,25,12,'rust');rect(8,8,19,3,'ochre');rect(4,24,22,3,'rust');rect(4,24,22,1,'gold')
 else
  -- Dark ventilation gaps between slats, no wire mesh or modern fittings.
  for x=5,23,4 do rect(x,13,2,11,'ochre');rect(x,13,1,10,'gold') end
  line(25,13,28,9,'wood');line(25,20,28,16,'wood');line(25,26,28,22,'wood');rect(27,10,2,14,'deep');rect(4,12,22,2,'sand');rect(10,26,3,2,'deep');rect(22,26,3,2,'deep');rect(13,5,7,1,'deep');px(13,6,'wood');px(19,6,'wood')
 end
end,{'coop'})
make('livestock_icons',16,16,1,3,function(f,r,p)
 if p==1 then
  if f==0 then
   -- Broad cow face, horizontal ears, short horns, square muzzle.
   rect(4,4,8,7,'stone_dk');rect(5,3,6,8,'cream');rect(2,5,3,2,'rust');rect(11,5,3,2,'rust')
   line(5,3,3,1,'ochre');line(10,3,12,1,'ochre')
   rect(4,10,8,4,'silt_lt');rect(5,10,6,1,'sand');rect(6,14,4,1,'stone_dk')
  elseif f==1 then
   -- Narrow goat profile, tall swept horns, angular muzzle, hanging beard.
   line(8,5,5,0,'stone_ink');line(10,4,8,0,'ochre');line(8,5,6,1,'sand')
   rect(6,5,5,7,'sand');rect(7,4,4,5,'cream');rect(10,8,4,3,'cream');rect(10,11,3,1,'stone_dk')
   line(6,6,2,5,'stone_dk');line(6,7,3,6,'sand');line(10,11,9,15,'stone_ink');line(11,12,10,14,'sand')
  else
   -- Hen head: rounded cheek, comb, beak and wattle; no body.
   rect(4,9,5,6,'ochre');rect(5,8,4,6,'sand');ell(8,7,4,4,'white','cream','sand')
   rect(5,3,6,2,'red');rect(6,1,2,3,'red');rect(9,2,2,2,'red')
   line(12,7,15,8,'gold');line(15,8,12,9,'ochre');rect(10,11,2,3,'red')
  end
 else
  if f==0 then rect(5,4,2,4,'ox');px(6,6,'ink');px(9,6,'ink');px(6,12,'deep');px(9,12,'deep');rect(6,13,4,1,'silt_dk')
  elseif f==1 then px(10,7,'ink');px(13,9,'deep');line(7,8,7,11,'white')
  else px(10,6,'ink');px(9,6,'white');line(6,9,8,10,'stone_lt') end
 end
end,{'cow_goat_chicken'})

-- Animation and scale review compositions. Foreground remains editable on its own layer.
local horse=app.open(app.params.pixels..'/horses.png').cels[1].image
local ox=app.open(app.params.pixels..'/oxen.png').cels[1].image
local wagon=app.open(app.params.pixels..'/wagon.png').cels[1].image
local function crop(img,x,y,w,h) local v=Image(w,h,ColorMode.RGB);v:drawImage(img,Point(-x,-y));return v end
local scale=Sprite(256,70,ColorMode.RGB);local bg=Image(256,70,ColorMode.RGB);bg:clear(C.sand)
bg:drawImage(crop(ox,0,0,48,32),Point(3,22));bg:drawImage(crop(horse,0,132,48,44),Point(52,10))
for i,n in ipairs({'cow','goat','chicken'}) do bg:drawImage(cache['livestock_'..n][1],Point(55+i*49,10)) end
scale:newCel(scale.layers[1],1,bg);scale:resize(768,210);scale:saveCopyAs(out..'/preview/scale-ox-horse-cow-goat-chicken.png')
local demo=Sprite(432,450,ColorMode.RGB);demo.layers[1].name='Backgrounds';local fore=demo:newLayer();fore.name='Separate livestock overlays'
for f=0,7 do
 if f>0 then demo:newEmptyFrame() end
 local b=Image(432,450,ColorMode.RGB)
 for row=0,2 do
  for y=0,149 do for x=0,431 do b:drawPixel(x,y+row*150,C[y<65 and 'sky' or y<86 and 'far_hill' or row==2 and 'blue' or 'grass']) end end
  for x=0,431 do b:drawPixel(x,120+row*150,C[row==2 and 'light_blue' or 'sand']) end
 end
 local a=Image(432,450,ColorMode.RGB)
 -- Traveling chickens are in the coop; a loose hen appears only in the camp row.
 for i,n in ipairs({'cow','goat','chicken'}) do if n~='chicken' then a:drawImage(cache['livestock_'..n][9+f],Point(52+i*72,82)) end;a:drawImage(cache['livestock_'..n][f+1],Point(52+i*72,232)) end
 a:drawImage(crop(wagon,(f%8)*96,0,96,64),Point(313,65))
 a:drawImage(cache.livestock_coop[1],Point(369,81))
 a:drawImage(crop(wagon,0,0,96,64),Point(313,215));a:drawImage(cache.livestock_coop[1],Point(369,231))
 for r=0,2 do for i,n in ipairs({'cow','goat'}) do a:drawImage(cache['cross_livestock_'..n][r*8+f+1],Point(40+r*130+(i-1)*47,385)) end end
 demo:newCel(demo.layers[1],f+1,b);demo:newCel(fore,f+1,a);demo.frames[f+1].duration=1/12
end
demo:saveAs(out..'/livestock-compositions.aseprite');demo:resize(864,900);demo:saveCopyAs(out..'/preview/livestock-compositions.gif')
print('Livestock draft set complete.')


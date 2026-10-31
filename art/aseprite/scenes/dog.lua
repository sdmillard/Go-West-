-- Original farm-shepherd-type design; historical type, not a registered 1848 breed. Integer clusters, project palette, no resampling.
local K=dofile(app.params.kit); local C=K.col; local out=app.params.out
-- See docs/DOG_ART.md for historical basis, cell layout and approval.
-- Rebuilds independently; no downloaded reference image is needed.
local W,H=48,44
local function mask() return {} end
local function dot(m,x,y) x=math.floor(x+0.5);y=math.floor(y+0.5);m[y]=m[y] or {};m[y][x]=true end
local function has(m,x,y) return m[y] and m[y][x] end
local function box(m,x,y,w,h) for yy=y,y+h-1 do for xx=x,x+w-1 do dot(m,xx,yy) end end end
local function ellipse(m,cx,cy,rx,ry)
 for y=math.floor(cy-ry),math.ceil(cy+ry) do for x=math.floor(cx-rx),math.ceil(cx+rx) do
  if ((x-cx)/(rx+.25))^2+((y-cy)/(ry+.25))^2<=1 then dot(m,x,y) end
 end end
end
local function stroke(m,x,y,u,v,width)
 local n=math.max(1,math.ceil(math.max(math.abs(u-x),math.abs(v-y))*2))
 for i=0,n do local xx=math.floor(x+(u-x)*i/n+.5);local yy=math.floor(y+(v-y)*i/n+.5);box(m,xx,yy,width,width) end
end
local im
local function px(x,y,c) if x>=0 and x<W and y>=0 and y<H then im:drawPixel(x,y,C[c]) end end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end end
local function paint(m,light,mid,shade,edge)
 for y,row in pairs(m) do for x in pairs(row) do
  local lower=not has(m,x,y+1);local top=not has(m,x,y-1)
  px(x,y,(lower and shade) or (top and light) or mid)
  if edge and not has(m,x+1,y) and y>25 then px(x,y,shade) end
 end end
end
local poses={};local spr=Sprite(W,H,ColorMode.RGB);spr.layers[1].name='far legs and tail';spr:newLayer().name='body and near legs';spr:newLayer().name='head and coat markings'
local sheet=Image(W*8,H*3,ColorMode.RGB)
local footx={{0,-1,-2,-1,0,2,3,2},{0,2,3,2,0,-1,-2,-1}}
local lift={{0,0,0,0,1,2,2,1},{1,2,2,1,0,0,0,0}}
for row=0,2 do for f=0,7 do
 local idx=row*8+f+1;if idx>1 then spr:newEmptyFrame() end
 local walk=row==1;local sit=row==2;local bob=walk and ((f==2 or f==6) and 1 or 0) or 0
 local headbob=(not walk and (f==4 or f==5)) and 1 or 0
 local hx,hy=32,15+bob+headbob;local by=23+bob
 local flat=Image(W,H,ColorMode.RGB)
 for pass=1,3 do
  im=Image(W,H,ColorMode.RGB)
  if pass==1 then
   local tail=mask()
   if sit then stroke(tail,15,35,10,38,2);stroke(tail,10,38,5+(f%4==2 and 1 or 0),37,2)
   else local wag=({0,1,2,1,0,-1,-2,-1})[f+1];stroke(tail,12,23+bob,9,28+bob,3);stroke(tail,9,28+bob,7,33+wag,3);stroke(tail,7,33+wag,4,33+wag,2) end
   paint(tail,'roof','ink','roof_dk')
   local far=mask()
   if sit then stroke(far,27,30,28,37,2);box(far,28,38,4,2)
   else
    for _,leg in ipairs({{17,2,true},{27,1,false}}) do
     local a=walk and footx[leg[2]][f+1] or 0;local l=walk and lift[leg[2]][f+1] or 0
     stroke(far,leg[1],26+bob,leg[1]+(leg[3] and -1 or 1),34,3)
     stroke(far,leg[1]+(leg[3] and -1 or 1),34,leg[1]+a,37-l,2);box(far,leg[1]+a,38-l,4,2)
    end
   end
   paint(far,'stone_ink','roof_dk','ink')
  elseif pass==2 then
   local m=mask()
   if sit then
    ellipse(m,19,33,6,5);ellipse(m,24,26,5,10);stroke(m,26,27,26,37,3);box(m,26,38,5,2)
    ellipse(m,18,35,4,3);box(m,16,38,7,2)
   else
    ellipse(m,20,by,9,5);ellipse(m,27,by-1,4,6);ellipse(m,14,by+2,4,4)
    -- Rounded hindquarter into a broad thigh and angled hock, not a one-pixel stick.
    local a=walk and footx[1][f+1] or 0;local l=walk and lift[1][f+1] or 0
    ellipse(m,15,by+3,3,4);stroke(m,15,28,12+a,33-l,3);stroke(m,12+a,33-l,15+a,37-l,2);box(m,15+a,38-l,4,2)
    a=walk and footx[2][f+1] or 0;l=walk and lift[2][f+1] or 0
    stroke(m,27,26+bob,28,33,3);stroke(m,28,33,28+a,37-l,2);box(m,28+a,38-l,4,2)
   end
   paint(m,'roof','ink','roof_dk',true)
   if not sit then
    -- Broken light clusters suggest the rough dark coat without outlining each hair.
    for _,p in ipairs({{14,-3},{18,-4},{23,-3},{12,0},{17,1},{21,2}}) do
     if has(m,p[1],by+p[2]) then px(p[1],by+p[2],'roof') end
    end
   end
   -- Chest ruff and cream socks are broad connected clusters.
   rect(28,23+bob,3,6,'stone_lt');rect(28,26+bob,2,4,'ox_white');px(27,28+bob,'stone_lt');px(26,27+bob,'stone_lt')
   if sit then rect(26,36,3,3,'stone_lt');rect(27,38,4,2,'ox_white')
   else
    local a=walk and footx[2][f+1] or 0;local l=walk and lift[2][f+1] or 0
    rect(28+a,36-l,2,3,'stone_lt');rect(28+a,38-l,4,2,'ox_white')
    a=walk and footx[1][f+1] or 0;l=walk and lift[1][f+1] or 0;rect(15+a,38-l,4,2,'stone_lt')
   end
  else
   local head=mask();ellipse(head,29,21+bob,4,7);ellipse(head,hx,hy,5,4);box(head,33,hy+1,7,3);box(head,35,hy+3,4,2)
   paint(head,'roof','ink','roof_dk')
   rect(31,hy-3,3,1,'roof');rect(32,hy-2,3,1,'stone_ink')
   rect(35,hy+2,5,2,'stone_lt');rect(34,hy+3,4,2,'ox_white');rect(39,hy+1,2,2,'ink');rect(36,hy+5,4,1,'deep')
   -- Folded ear and moderately broad muzzle; no exaggerated show-dog features.
   local ear=mask();ellipse(ear,28,hy,3,3);box(ear,27,hy+1,3,4);box(ear,28,hy-3,2,2)
   paint(ear,'roof','ink','roof_dk');px(29,hy-4,'roof');px(30,hy-3,'roof');rect(27,hy,2,2,'roof_dk')
   if f==6 and not walk then px(34,hy,'ox_dk') else px(34,hy,'ink');px(33,hy-1,'stone_lt') end
   if not walk and (f==3 or f==4) then rect(37,hy+6,1,2,'skin_dk') end
  end
  spr:newCel(spr.layers[pass],idx,im);flat:drawImage(im)
 end
 poses[idx]=flat;sheet:drawImage(flat,Point(f*W,row*H));spr.frames[idx].duration=1/12
end end
for row,tag in ipairs({'idle','walk_right','sit'}) do local t=spr:newTag((row-1)*8+1,row*8);t.name=tag end
spr:saveAs(out..'/dog.aseprite');sheet:saveAs(out..'/dog.png')
local s=app.open(out..'/dog.png');s:resize(s.width*3,s.height*3);s:saveCopyAs(out..'/preview/dog_x3.png');s:close()
local allowed={};for _,c in pairs(C) do allowed[c]=true end
for p in sheet:pixels() do local a=app.pixelColor.rgbaA(p());assert(a==0 or a==255);assert(a==0 or allowed[p()]) end
assert(#spr.frames==24 and sheet.width==384 and sheet.height==132)
print('PASS dog: 24 layered frames, fixed baseline, project palette, crisp alpha')

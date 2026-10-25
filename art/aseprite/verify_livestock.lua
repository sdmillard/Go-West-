local K=dofile(app.params.kit);local out=app.params.out
local allowed={};for _,c in pairs(K.col) do allowed[c]=true end
local contracts={{'livestock_cow',48,44,8,2},{'livestock_goat',48,44,8,2},{'livestock_chicken',48,44,8,2},{'livestock_coop',32,32,1,1},{'cross_livestock_cow',48,40,8,3},{'cross_livestock_goat',48,40,8,3},{'livestock_icons',16,16,3,1}}
for _,v in ipairs(contracts) do
 local name,w,h,cols,rows=table.unpack(v)
 local png=app.open(out..'/'..name..'.png');assert(png.width==w*cols and png.height==h*rows,'Sheet dimensions '..name)
 local source=png.cels[1].image;local visible=0
 for p in source:pixels() do local c=p();local alpha=app.pixelColor.rgbaA(c);assert(alpha==0 or alpha==255,'Partial alpha');assert(alpha==0 or allowed[c],'Off palette');if alpha>0 then visible=visible+1 end end
 assert(visible>0,'Empty sheet');png:close()
 local s=app.open(out..'/'..name..'.aseprite');assert(s.width==w and s.height==h and #s.frames==cols*rows,'Animation dimensions');assert(#s.layers==2,'Editable layers')
 for _,f in ipairs(s.frames) do assert(math.abs(f.duration-1/12)<0.001,'Frame duration') end
 if cols==8 then
  local function hash(f) local flat=Image(w,h,ColorMode.RGB);flat:drawSprite(s,f);local z=0;for p in flat:pixels() do z=(z*31+p())%2147483647 end;return z end
  local seen={};local offset=name:sub(1,5)=='cross' and 0 or 8;for f=1,8 do seen[hash(offset+f)]=true end
  local n=0;for _ in pairs(seen) do n=n+1 end;assert(n>=4,'Too few distinct walking frames')
 end
 if name:sub(1,5)=='cross' then
  local flat=Image(w,h,ColorMode.RGB);flat:drawSprite(s,1);for p in flat:pixels() do assert(p()~=K.col.light_blue,'Water in walk row') end
 end
 s:close();print('PASS '..name..': layout, layers, alpha, palette, duration and motion')
end

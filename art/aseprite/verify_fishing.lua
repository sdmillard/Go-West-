local K=dofile(app.params.kit)
local out=app.params.out
local contracts={{'fishing_riverbank',432,150,1},{'fishing_angler',128,128,16},{'fishing_bobber',32,24,12},{'fishing_splash',64,16,4},{'fishing_catch',32,8,2}}
local allowed={};for _,v in pairs(K.col) do allowed[v]=true end
for _,a in ipairs(contracts) do
 local s=app.open(out..'/'..a[1]..'.png');assert(s.width==a[2] and s.height==a[3],a[1]..' dimensions')
 local img=s.cels[1].image
 for p in img:pixels() do local c=p();local alpha=app.pixelColor.rgbaA(c);assert(alpha==0 or alpha==255,'Partial alpha');assert(alpha==0 or allowed[c],'Off-palette pixel') end
 s:close();local anim=app.open(out..'/'..a[1]..'.aseprite');assert(#anim.frames==a[4],a[1]..' animation count');anim:close()
 print('PASS '..a[1]..': sheet size, animation count, palette and crisp alpha')
end
local old=app.open(app.params.old)
local new=app.open(out..'/fishing_riverbank.png')
local compare=Sprite(432,300,ColorMode.RGB)
local img=Image(432,300,ColorMode.RGB);img:drawSprite(old,1,Point(0,0));img:drawSprite(new,1,Point(0,150))
compare:newCel(compare.layers[1],1,img);compare:resize(864,600);compare:saveCopyAs(out..'/preview/old-above-new-below.png')

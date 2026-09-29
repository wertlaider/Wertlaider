local base="https://raw.githubusercontent.com/wertlaider/Wertlaider/main/modules/"
local mods={"core","macros","autoplace","autoactions","misc","webhook","ui"}
for _,m in ipairs(mods)do
local ok,src=pcall(function()return game:HttpGet(base..m..".lua",true)end)
if ok and src and #src>50 then
local fn,err=loadstring(src)
if fn then
pcall(fn)
end
end
end

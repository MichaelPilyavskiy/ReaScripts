-- @description Set render format to Video MP4 MJPEG
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
 

  function main()
    --[[r, rend = GetSetProjectInfo_String(0, 'RENDER_FORMAT', '', false)
    rend = dec(rend)
    t = {}
    s = ''
    for i = 1, rend:len() do
      t[#t+1] = rend:sub(i,i):byte()
      s = s..',\n'..'['..(i-4)..']='..rend:sub(i,i):byte()
    end]]
    local form_conf = {
[1]=3,  -- mp4
[2]=0,
[3]=0,
[4]=0,
[5]=2, -- mjpeg
[6]=0,
[7]=0,
[8]=0,
[9]=0,
[10]=8,
[11]=0,
[12]=0,
[13]=3,
[14]=0,
[15]=0,
[16]=0,
[17]=128,
[18]=0,
[19]=0,
[20]=0,
[21]=128,
[22]=7,
[23]=0,
[24]=0,
[25]=56,
[26]=4,
[27]=0,
[28]=0,
[29]=0,
[30]=0,
[31]=240,
[32]=65,
[33]=1,
[34]=0,
[35]=0,
[36]=0,
[37]=95,
[38]=0,
[39]=0,
[40]=0
}
    
    local out_str = ''
    for i = 1, #form_conf do if not form_conf[i] then form_conf[i] = 0 end out_str = out_str..tostring(form_conf[i]):char() end
    GetSetProjectInfo_String(0, 'RENDER_FORMAT', enc('PMFF'..out_str), true)
  end  
  ---------------------------------------------------------------------- 
  function enc(data)  -- http://lua-users.org/wiki/BaseSixtyFour
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end
  -- decoding
  function dec(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      data = string.gsub(data, '[^'..b..'=]', '')
      return (data:gsub('.', function(x)
          if (x == '=') then return '' end
          local r,f='',(b:find(x)-1)
          for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
          return r;
      end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
          if (#x ~= 8) then return '' end
          local c=0
          for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
          return string.char(c)
      end))
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
  local ret, ret2 = CheckFunctions('VF_CheckReaperVrs') 
  if ret then ret2 = VF_CheckReaperVrs(5.974) end
  if ret and ret2 then main() end
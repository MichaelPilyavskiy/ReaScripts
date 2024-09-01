-- @description Set render format to Video MP4 MJPEG
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
 

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
  if VF_CheckReaperVrs(5.974) then main() end
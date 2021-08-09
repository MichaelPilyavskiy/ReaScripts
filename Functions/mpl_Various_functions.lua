-- @description Various_functions
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @about Functions for using with scripts written by MPL.
-- @version 2.10
-- @provides
--    mpl_Various_functions_v1.lua
--    mpl_Various_functions_v2.bin
--    mpl_Various_functions_GUI.lua
--    mpl_Various_functions_MOUSE.lua
-- @changelog
--    #fix typo
  
    --------------------------------------------------
    function VF_LoadLibraries()
      local info = debug.getinfo(1,'S');  
      local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
      dofile(script_path .. "mpl_Various_functions_GUI.lua")
      dofile(script_path .. "mpl_Various_functions_MOUSE.lua")
    end
    --------------------------------------------------      
    function VF2_LoadVFv2_DecodeBinary(sysID,response)
      local info = debug.getinfo(1,'S');  
      local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) .. "mpl_Various_functions_v2.bin"
      local f = io.open(script_path,'r')
      if f then 
        local content = f:read('a')
        f:close()
        content = VF2_LoadVFv2_DecodeBinary_Sub(content,sysID,response)
        funct2run = load(content)
        funct2run()
       else
        reaper.MB('mpl_Various_functions_v2 not found', 'MPL VariousFunctions', 0)
      end
    end  
    --------------------------------------------------------------------    
    function VF2_DecodeBinaryMixString(sysID,response)
      local t_mix = {}
      local i = 0 local incr = 0
      for char in sysID:gmatch('.') do  i = i + 1  if i%2==1 then incr = string.sub(response,i,i):byte() - char:byte() else incr = - incr end t_mix[#t_mix+1] = string.sub(response,i,i):byte()-(char:byte()+incr) end 
      local t_out = {47,43}
      local offs=57 local cnt_end=48 for i = offs, cnt_end, -1 do t_out[#t_out+1] = i + t_mix[math.max(1,math.min(i,#t_mix))] end
      offs=122 cnt_end=97 for i = offs, cnt_end, -1 do t_out[#t_out+1] = i+ t_mix[math.max(1,math.min(i,#t_mix))] end
      offs=90 cnt_end=65 for i = offs, cnt_end, -1 do t_out[#t_out+1] = i+ t_mix[math.max(1,math.min(i,#t_mix))] end
      local b = '' for i = 1, #t_out do b=b..string.char(t_out[i]) end
      return b
    end
    --------------------------------------------------  
    function VF2_LoadVFv2_DecodeBinary_Sub(data,sysID,response)
        local b=VF2_DecodeBinaryMixString(sysID,response)
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
    --------------------------------------------------    
    function VF2_LoadVFv1()
      local info = debug.getinfo(1,'S');  
      local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) .. "mpl_Various_functions_v1.lua"
      local f = io.open(script_path,'r')
      if f then 
        local content = f:read('a')
        f:close()
        funct2run = load(content)
        funct2run()
       else
        reaper.MB('mpl_Various_functions_v1 not found', 'MPL VariousFunctions', 0)
      end
    end
    --------------------------------------------------
    function VF2_GetSystemID()
      --[[local fh = assert(io.popen'wmic csproduct get uuid')
      if not fh then fh = assert(io.popen'wmic csproduct get UUID') end
      if not fh then return '' end
      local result = fh:read'*a'
      fh:close()
      result = string.gsub(result,'UUID',"")
      return result:match"^%s*(.*)":match"(.-)%s*$"]]
      return reaper.genGuid(''):gsub('%p','')
    end
    --------------------------------------------------------------------
    function VF2_CheckResponseOffset(input, response)
      local input_chsum1 = 0 for char in input:gmatch('.') do input_chsum1=input_chsum1+string.byte(char) end
      local input_chsum2 = 0 for char in response:gmatch('.') do input_chsum2=input_chsum2+string.byte(char) end
      return input_chsum1==input_chsum2 and input~=response
    end
    --------------------------------------------------
    function VF2_LoadVFv2()
      local sysID = reaper.GetExtState('MPL_Scripts', 'sysID')
      if not sysID or sysID == '' then sysID = VF2_GetSystemID() reaper.SetExtState('MPL_Scripts', 'sysID',sysID, true) end
      local response = reaper.GetExtState('MPL_Scripts', 'response')
      if response == '' then 
        local ret = MB('You updated "VariousFunction" package to version 2. Since version 2.0 this package is paid. You can reinstall and prevent from updates last available free version (v1.31) via ReaPack or purchase v2 for $30. If you purchased my scripts or donated in the past, please contact me via email m.pilyavskiy@gmail.com\n\nDo you want to purchase package?', '' ,4)
        if ret == 6 then 
          local retval, retvals_csv = reaper.GetUserInputs( 'Purchasing VariousFunctions v2', 4, '1. Copy System ID,2.Send it to:,3.Pay $30 via Paypal,4:Enter response(1-3days):,extrawidth=200', sysID..',m.pilyavskiy@gmail.com,https://www.paypal.com/paypalme/donate2mpl,' )
          --local t = {} for val in retvals_csv:gmatch('[^,]+') do t[#t+1] = val end
          --local resp = t[4]:gsub('%s','')
          local resp = retvals_csv:match('.-%,.-%,.-%,(.*)')
          if not resp then MB('No response entered','',0) return end
          local check_offset = VF2_CheckResponseOffset(sysID,resp)
          if check_offset then  
            reaper.SetExtState('MPL_Scripts', 'response',resp, true)
            MB('SystemID - Response pair was successfully passed','MPL Various functions',0)
           else
            MB('Checksum mismatch. Contact m.pilyavskiy@gmail.com','MPL Various functions',0)
          end
        end
       else
        local check_offset = VF2_CheckResponseOffset(sysID,response)
        if check_offset then 
          VF2_LoadVFv2_DecodeBinary(sysID,response)
         else
          MB('Checksum mismatch. Contact m.pilyavskiy@gmail.com','MPL Various functions',0)
        end
      end 
    end
    --------------------------------------------------
    VF2_LoadVFv1() 
    VF2_LoadVFv2()
    


-- @description Various_functions_Purchase
-- @author MPL
-- @noindex

--------------------------------------------------------------------
  function VF_CheckResponseOffset(input, response)
    local input_chsum1 = 0 for char in input:gmatch('.') do input_chsum1=input_chsum1+string.byte(char) end
    local input_chsum2 = 0 for char in response:gmatch('.') do input_chsum2=input_chsum2+string.byte(char) end
    return input_chsum1==input_chsum2 and input~=response
  end
  --------------------------------------------------
  function VF_InputResponse()
    local sysID = VF_GetSystemID()
    local retval, resp = reaper.GetUserInputs( 'Purchasing VariousFunctions v2', 1, 'Response code,extrawidth=200', '' )
    if not retval then return end
    if not resp or resp == ''  then MB('No response entered','',0) return end
    local check_offset = VF_CheckResponseOffset(sysID,resp)
    if check_offset then  
      reaper.SetExtState('MPL_Scripts', 'response',resp, true)
      MB('SystemID - Response pair was successfully passed','MPL Various functions',0)
     else
      MB('Checksum mismatch. Contact m.pilyavskiy@gmail.com','MPL Various functions',0)
    end
  end
  --------------------------------------------------------------------    
  function VF_DecodeBinaryMixString(sysID,response)
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
  function VF_LoadVFv2_DecodeBinary_Sub(data,sysID,response)
      local b=VF_DecodeBinaryMixString(sysID,response)
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
  function VF_GetSystemID()
    local sysID = reaper.GetExtState('MPL_Scripts', 'sysID')
    if not sysID or sysID == '' then 
      sysID = reaper.genGuid(''):gsub('%p','')
      --[[local fh = assert(io.popen'wmic csproduct get uuid')
      if not fh then fh = assert(io.popen'wmic csproduct get UUID') end
      if not fh then return '' end
      local result = fh:read'*a'
      fh:close()
      result = string.gsub(result,'UUID',"")
      return result:match"^%s*(.*)":match"(.-)%s*$"]]
      reaper.SetExtState('MPL_Scripts', 'sysID',sysID, true) 
    end
  return sysID
  end
  --------------------------------------------------      
  function VF_LoadVFv2_DecodeBinary(sysID,response)
    local info = debug.getinfo(1,'S');  
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) .. "mpl_Various_functions_v2.bin"
    local f = io.open(script_path,'r')
    if f then 
      local content = f:read('a')
      f:close()
      content = VF_LoadVFv2_DecodeBinary_Sub(content,sysID,response)
      funct2run = load(content)
      funct2run()
     else
      reaper.MB('mpl_Various_functions_v2 not found', 'MPL VariousFunctions', 0)
    end
  end 



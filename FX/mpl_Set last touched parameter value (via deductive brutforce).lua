-- @description Set last touched parameter value (via deductive brutforce)
-- @version 1.03
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
  ------------------------------------------------------- 
  function VF_BFpluginparam(find_Str, tr, fx, param) 
    if not find_Str then return end
    local find_Str_val = find_Str:match('[%d%-%.]+')
    if not (find_Str_val and tonumber(find_Str_val)) then return end
    local find_val =  tonumber(find_Str_val)
    
    local iterations = 300
    local mindiff = 10^-14
    local precision = 10^-7
    local min, max = 0,1
    for i = 1, iterations do -- iterations
      local param_low = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min) 
      local param_mid = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min + (max-min)/2) 
      local param_high = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, max)  
      if find_val <= param_low then return min  end
      if find_val == param_mid and math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      if find_val >= param_high then return max end
      if find_val > param_low and find_val < param_mid then 
        min = min 
        max = min + (max-min)/2 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
       else
        min = min + (max-min)/2 
        max = max 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      end
    end
    
  end
  -------------------------------------------------------  
  function VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision)
    for value_precise = min, max, precision do
      local param_form = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, value_precise)  
      if find_val == param_form then  return value_precise end
    end
    return min + (max-min)/2 
  end 
  -------------------------------------------------------  
  function VF_BFpluginparam_GetFormattedParamInternal(tr, fx, param, val)
    local param_n
    if val then TrackFX_SetParamNormalized( tr, fx, param, val ) end
    local _, buf = TrackFX_GetFormattedParamValue( tr , fx, param, '' )
    --local param_str = buf:match('%-[%d%.]+') or buf:match('[%d%.]+')
    local param_str = buf:match('[%d%a%-%.]+')
    if param_str then param_n = tonumber(param_str) end
    if not param_n and param_str:lower():match('%-inf') then param_n = - math.huge
    elseif not param_n and param_str:lower():match('inf') then param_n = math.huge end
    return param_n
  end
  
  -------------------------------------------------------
  function main() local ReaperVal
    local retval, tracknum, fx, param = GetLastTouchedFX()
    if not retval then return end
    local tr = CSurf_TrackFromID( tracknum, false )    
    local retval, find = reaper.GetUserInputs( '', 1, 'value', ({TrackFX_GetFormattedParamValue( tr , fx, param, '' )})[2] )
    if not retval then return end
    ReaperVal =  VF_BFpluginparam(find, tr, fx, param)   
    if ReaperVal then TrackFX_SetParamNormalized( tr, fx, param, ReaperVal ) end
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true) then main() end 
  
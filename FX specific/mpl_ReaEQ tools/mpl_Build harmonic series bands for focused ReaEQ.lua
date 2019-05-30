-- @description Build harmonic series bands for focused ReaEQ
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    # header
  
  
  
  -- NOT reaper NOT gfx
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  -----------------------------------------------------------------------------
   function lim(val, min,max) --local min,max 
     if not min or not max then min, max = 0,1 end 
     return math.max(min,  math.min(val, max) ) 
   end
  -----------------------------------------------------------------------------
  function MPL_BuildEQReduce(freq, gain, slope, linkBW, linkgain)
    if not (freq and gain and slope) then return end
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX()
    if not (retval ==1 and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    local num_params = TrackFX_GetNumParams( tr, fx )
    local linkBW_str = ''
    local linkgain_str = ''
    local bands_cnt = math.floor((num_params - 2)/3)
    for param = 1, num_params - 2, 3 do
      local band_id = math.floor(param/3)
      TrackFX_SetNamedConfigParm( tr, fx, 'BANDTYPE'..band_id, 2 )
      local gain_new = lim(gain + band_id * slope, 0.01,0.99)
      TrackFX_SetParamNormalized( tr, fx,  param,gain_new) -- -2.0dB gain
      local startQdenom = 40
      TrackFX_SetParamNormalized( tr, fx, param+1, lim(1/(startQdenom* (band_id+1)), 0.01, 1)) -- 0.5 Q
      local ConvertedF = F2ReaEQVal(freq * (band_id+1) )
      TrackFX_SetParamNormalized( tr, fx, param-1, ConvertedF) -- freq
      if param > 1 then 
      
        if linkBW then 
          linkBW_str = linkBW_str..'\n'..
        -- Q
[[      <PROGRAMENV ]]..(param+1)..[[ 0
        PARAMBASE 0
        LFO 0
        LFOWT 1 1
        AUDIOCTL 0
        AUDIOCTLWT 1 1
        PLINK 1 0:0 2 0
        MODWND 0
      >      
]]        
        end
        
        if linkgain then
          local scale = 1
          local offset = 0
          linkBW_str = linkBW_str..'\n'..
        -- Q
[[      <PROGRAMENV ]]..(param)..[[ 0
        PARAMBASE 0
        LFO 0
        LFOWT 1 1
        AUDIOCTL 0
        AUDIOCTLWT 1 1
        PLINK 1 0:0 ]]..scale..' '..offset..[[ 
        MODWND 0
      >      
]]   
      end
      end
    end
    
    local out_chunk
    if linkBW or linkgain then 
      local out_chunk = Link(tr, fx, linkBW_str) -- link bandQ
      SetTrackStateChunk( tr, out_chunk, true ) 
    end
  end
  ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end
  -----------------------------------------------------------------------------
  function Link(tr, fx, build_str, chunk) local chunk
    if not chunk then 
      retval, chunk = GetTrackStateChunk( tr, '', false )
    end
    local fxGUID = TrackFX_GetFXGUID( tr, fx )
    --local build_str = ''
    local chunk = chunk:gsub(literalize(fxGUID)..'.-WAK', fxGUID..build_str..'WAK')
    return chunk
  end
  ----------------------------------------------------------------------------- 
  function ReaEQVal2F(x) 
    local curve = (math.exp(math.log(401)*x) - 1) * 0.0025
    local freq = (24000 - 20) * curve + 20
    return freq
  end
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ----------------------------------------------------------------------------- 
  function ParseDbVol(out_str_toparse)
    if not out_str_toparse or not out_str_toparse:match('%d') then return 0 end
    if out_str_toparse:find('1.#JdB') then return 0 end
    out_str_toparse = out_str_toparse:lower():gsub('db', '')
    local out_val = tonumber(out_str_toparse)
    if not out_val then return end
    out_val = lim(out_val, -150, 12)
    out_val = WDL_DB2VAL(out_val)
    if out_val <= 1 then out_val = out_val / 2 else out_val = 0.5 + out_val / 8 end
    return out_val
  end
  ----------------------------------------------------------------------------- 
  function F2ReaEQVal(F) 
    local curve =  (F - 20) / (24000 - 20)
    local x = (math.log((curve +0.0025) / 0.0025,math.exp(1) ))/math.log(401)
    return x
  end
  ----------------------------------------------------------------------------- 
  local def_params = '50,-150,0.01,Y,N'
  local extstate = GetExtState('MPL_BUILDHARMSERREAEQ', 'params')
  if extstate ~= '' then def_params = extstate end
  local retval, str = GetUserInputs('Build harmonic bands', 5, 'Base frequency(Hz) (def=50),Gain Reduction(dB) (def=-150),Gain increment/decrement (dB),Link banwidth (Y/N),Link gain (Y/N)', def_params)
  if retval then 
    local t, freq, gain, slope, linkbands, linkgain = {}, _, 0, 0.01, true, false
    for val in str:gmatch('[^,]+') do  t[#t+1] = val end
    if t[1] then freq = t[1] else return end
    if t[2] then gain = ParseDbVol(t[2]) end
    if t[3] then slope = t[3] end
    if t[4] then linkbands = t[4]:lower() == 'y' end
    if t[5] then linkgain = t[5]:lower() == 'y' end
    if freq and gain and slope then 
      SetExtState( 'MPL_BUILDHARMSERREAEQ', 'params', table.concat(t, ','), true )
    end
    MPL_BuildEQReduce(freq, lim(gain, 0,1), slope, linkbands, linkgain)
  end
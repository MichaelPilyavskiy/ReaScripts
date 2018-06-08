-- @description Add spectral edit at specified frequency
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # use external functions


  -- NOT gfx NOT reaper
  local scr_title = 'Add spectral edit at specified frequency'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  
  -------------------------------------------------------
  function AddSpectralEditIntoTable(data, tk_id, SR, item_pos, item_len, loopS, loopE, F_base, F_Area, gain_dB)
    if not data[tk_id+1] then return end
    if not data[tk_id+1].edits then data[tk_id+1].edits = {} end
    
      
    -- obey time selection
    local pos, len = 0, item_len
    if loopE - loopS > 0.001 then 
      if loopS >= item_pos and loopS <= item_pos + item_len then pos = loopS- item_pos end
      if loopE >= item_pos and loopE <= item_pos + item_len then 
        len = loopE - loopS 
       else
        len = item_pos + item_len - loopS
      end
    end
    local freq_L = math.max(0, F_base-F_Area)
    local freq_H = math.min(SR, F_base+F_Area)
    
    
    data[tk_id+1].edits [ #data[tk_id+1].edits + 1] = 
      {pos = pos,
       len = len,
       gain = 10^(gain_dB/20),
       fadeinout_horiz = 0,
       fadeinout_vert = 0,
       freq_low = freq_L,
       freq_high = freq_H,
       chan = -1, -- -1 all 0 L 1 R
       bypass = 0, -- bypass&1 solo&2
       gate_threshold = 0,
       gate_floor = 0,
       compress_threshold = 1,
       compress_ratio = 1,
       unknown1 = 1,
       unknown2 = 1,
       fadeinout_horiz2 = 0, 
       fadeinout_vert2 = 0}
  end
  -------------------------------------------------------

    
  function GetParams()
    local ES_str = GetExtState( 'MPL_'..scr_title, 'inputs' )
    local def_str if ES_str == '' then def_str = '12000,1000,-20' else def_str = ES_str end
    local ret, str = GetUserInputs(scr_title, 3, 'Base frequency (Hz),Frequency area (Hz),Gain (dB)',def_str )
    if not ret then return end
    SetExtState( 'MPL_'..scr_title, 'inputs',str , true )
    t = {} for val in str:gmatch('[^%,]+') do if tonumber(val) then t[#t+1] = tonumber(val) end end
    if #t < 3 then return end
    local F_base = t[1]
    local F_Area = t[2]
    local gain_dB = t[3] 
    return true, F_base, F_Area, gain_dB
  end
  --F_base, F_Area, gain_dB = 10000, 1000, -20
  -------------------------------------------------------  
  function main(F_base, F_Area, gain_dB)
    local loopS, loopE = GetSet_LoopTimeRange2( 0, false, 0, -1, -1, false )
    for i = 1, CountSelectedMediaItems(0) do 
      local item = GetSelectedMediaItem(0,i-1)
      local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local tk = GetActiveTake( item )
      local src =  GetMediaItemTake_Source( tk )
      local SR = GetMediaSourceSampleRate( src )
      local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
      local ret, data = GetSpectralData(item)    
      AddSpectralEditIntoTable(data, tk_id, SR, item_pos, item_len, loopS, loopE, F_base, F_Area, gain_dB)
      if ret then SetSpectralData(item, data) end
    end
  end
 ------------------------------------------------------- 
  
  SEfunc_path = GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
  local f = io.open(SEfunc_path, 'r')
  if f then
    f:close()
    dofile(SEfunc_path)
    local ret, F_base, F_Area, gain_dB = GetParams()
    if ret then
      Undo_BeginBlock() 
      main(F_base, F_Area, gain_dB)
      Undo_EndBlock( scr_title, -1 )
    end
   else
    MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
  end
  

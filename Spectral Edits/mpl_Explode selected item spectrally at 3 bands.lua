-- @description Explode selected item spectrally at 3 bands
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   + init

  -- NOT gfx NOT reaper
  local scr_title = 'Explode selected item spectrally at 3 bands'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s)  if not s then return end  ShowConsoleMsg(s..'\n') end  
  ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end
  -------------------------------------------------------
  function SetSpectralData(item, SE)
    if not item then return end
    local chunk = ({GetItemStateChunk( item, '', false )})[2]
    chunk = chunk:gsub('SPECTRAL_CONFIG.-\n', '')
    chunk = chunk:gsub('SPECTRAL_EDIT.-\n', '')
    local open
    local t = {} 
    for line in chunk:gmatch('[^\r\n]+') do t[#t+1] = line end
    local tk_cnt = 0 
    for i = 1, #t do
      if t[i]:match('<SOURCE') then 
        tk_cnt = tk_cnt + 1 
        open = true 
      end
      if open and t[i]:match('>') then
      
        local add_str = ''
        add_str = add_str..'SPECTRAL_EDIT '
              ..SE.pos..' '
              ..SE.len..' '
              ..SE.gain..' '
              ..SE.fadeinout_horiz..' '
              ..SE.fadeinout_vert..' '
              ..SE.freq_low..' '
              ..SE.freq_high..' '
              ..SE.chan..' '
              ..SE.bypass..' '
              ..SE.gate_threshold..' '
              ..SE.gate_floor..' '
              ..SE.compress_threshold..' '
              ..SE.compress_ratio..' '
              ..SE.unknown1..' '
              ..SE.unknown2..' '
              ..SE.fadeinout_horiz2..' '
              ..SE.fadeinout_vert2..' '
              ..'\n'
          add_str = add_str..'SPECTRAL_CONFIG '..SE.FFT_sz ..'\n'
     
        
        
        t[i] = t[i]..'\n'..add_str
        open = false
      end
    end   
    
    local out_chunk = table.concat(t, '\n')
    SetItemStateChunk( item, out_chunk, false )
    UpdateItemInProject( item )
  end
  -------------------------------------------------------
  function GenSE( SR, item_len, freq_L, freq_H )
    --local freq_L = math.max(0, freq_L)
    --local freq_H = math.min(SR, freq_H)
    local ES = 
      {FFT_sz = 1024,
       pos = 0,
       len = item_len,
       gain = 1,--10^(gain_dB/20),
       fadeinout_horiz = 0,
       fadeinout_vert = 0,
       freq_low = freq_L,
       freq_high = freq_H,
       chan = -1, -- -1 all 0 L 1 R
       bypass = 2, -- bypass&1 solo&2
       gate_threshold = 0,
       gate_floor = 0,
       compress_threshold = 1,
       compress_ratio = 1,
       unknown1 = 0,
       unknown2 = 0,
       fadeinout_horiz2 = 0, 
       fadeinout_vert2 = 0}
    return ES
  end
  -------------------------------------------------------
  Undo_BeginBlock() 
  for i = 1, CountSelectedMediaItems(0) do 
    local item = GetSelectedMediaItem(0,i-1)
    local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local tk = GetActiveTake( item )
    local SR = GetMediaSourceSampleRate( GetMediaItemTake_Source( tk ) )
    local chunk = ({GetItemStateChunk( item, '', false )})[2]
    
    -- get params
      local ES_str = GetExtState( 'MPL_'..scr_title, 'inputs' )
      local def_str if ES_str == '' then def_str = '500,13000' else def_str = ES_str end
      local ret, str = GetUserInputs(scr_title, 2, 'LowMid crossover frequency, MidHigh crossover frequency',def_str )
      if not ret then return end
      SetExtState( 'MPL_'..scr_title, 'inputs',str , true )
      t = {} for val in str:gmatch('[^%,]+') do if tonumber(val) then t[#t+1] = tonumber(val) end end
      if #t < 2 then return end
      local freq_L = t[1]
      local freq_H = t[2]
    
    item_track = GetMediaItem_Track( item )
     
    it1 = AddMediaItemToTrack( item_track )
    SetItemStateChunk( it1, chunk, false )
    it2 = AddMediaItemToTrack( item_track )
    SetItemStateChunk( it2, chunk, false )
    
        
    local SE = GenSE( SR, item_len, 0, freq_L-1 )
    SetSpectralData(item, SE)
    local SE = GenSE( SR, item_len, freq_L, freq_H-1 )
    SetSpectralData(it1, SE)
    local SE = GenSE( SR, item_len, freq_H, math.floor(SR/2))
    SetSpectralData(it2, SE)
    
    SelectAllMediaItems( 0, false )
    
    --Main_OnCommand(40543, 0)--Take: Implode items on same track into takes
    
  end
  Undo_EndBlock( scr_title, -1 )
  
  
-- @description Explode selected item spectrally at 3 bands
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use external functions
--    + Explode new items to new tracks

  -- NOT gfx NOT reaper
  local scr_title = 'Explode selected item spectrally at 3 bands'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 

  -------------------------------------------------------
  function GenSE( SR, item_len, freq_L, freq_H,tkID )
    
    --local freq_L = math.max(0, freq_L)
    --local freq_H = math.min(SR, freq_H)
    local ES = {}
    ES[tkID] = {edits ={
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
       fadeinout_vert2 = 0}}}
    return ES
  end
  -------------------------------------------------------
  function main()
    for i = 1, CountSelectedMediaItems(0) do 
      local item = GetSelectedMediaItem(0,i-1)
      local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local tk = GetActiveTake( item )
      local tkID = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' ) + 1
      local SR = GetMediaSourceSampleRate( GetMediaItemTake_Source( tk ) )
      local chunk = ({GetItemStateChunk( item, '', false )})[2]
      
      -- get params
        local ES_str = GetExtState( 'MPL_'..scr_title, 'inputs' )
        local def_str if ES_str == '' then def_str = '500,13000' else def_str = ES_str end
        local ret, str = GetUserInputs(scr_title, 2, 'LowMid crossover frequency, MidHigh crossover frequency',def_str )
        if not ret then return end
        SetExtState( 'MPL_'..scr_title, 'inputs',str , true )
        local t = {} for val in str:gmatch('[^%,]+') do if tonumber(val) then t[#t+1] = tonumber(val) end end
        if #t < 2 then return end
        local freq_L = t[1]
        local freq_H = t[2]
      
      -- get track
        local item_track = GetMediaItem_Track( item )
        par_ID =  CSurf_TrackToID( item_track, false )
        
      -- add items
        local it1 = AddMediaItemToTrack( item_track )
        SetItemStateChunk( it1, chunk, false )
        local it2 = AddMediaItemToTrack( item_track )
        SetItemStateChunk( it2, chunk, false )
        
      -- app SE
        local SE = GenSE( SR, item_len, 0, freq_L-1,tkID )
        SetSpectralData(item, SE)
        
        local SE2 = GenSE( SR, item_len, freq_L, freq_H-1, tkID )
        SetSpectralData(it1, SE2)
        InsertTrackAtIndex( par_ID, false )  
        local desttr = CSurf_TrackFromID( par_ID+1, false )      
        MoveMediaItemToTrack( it1, desttr )
        
        local SE3 = GenSE( SR, item_len, freq_H, math.floor(SR/2), tkID)
        SetSpectralData(it2, SE3)
        InsertTrackAtIndex( par_ID+1, false )  
        local desttr2 = CSurf_TrackFromID( par_ID+2, false )  
        MoveMediaItemToTrack( it2, desttr2 )
        
        
        UpdateArrange()
    end
  end
  
  
  --------------------------------------------------------
  SEfunc_path = GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
  local f = io.open(SEfunc_path, 'r')
  if f then
    f:close()
    dofile(SEfunc_path)
    Undo_BeginBlock()
    main()
    Undo_EndBlock( scr_title, -1 )
   else
    MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
  end
  
  
    

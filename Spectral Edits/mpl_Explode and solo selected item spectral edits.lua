-- @description Explode selected item spectral edits
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  -- NOT gfx NOT reaper
  local scr_title = 'Explode and solo selected item spectral edits'
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
    
      local item = GetSelectedMediaItem(0,0)
      local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local tk = GetActiveTake( item )
      local tkID = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' ) + 1
      local chunk = ({GetItemStateChunk( item, '', false )})[2]
      
      ret, data = GetSpectralData(item)
      if not ret or not data[tkID] or not data[tkID].edits then return end
      
      local data0 = CopyTable(data)
      for i =1, #data0[tkID].edits do 
        --data0[tkID].edits[i].bypass = 1 
        data0[tkID].edits[i].gain = 0 
      end
      SetSpectralData(item, data0)
      
      --get track
        local item_track = GetMediaItem_Track( item )
        local par_ID =  CSurf_TrackToID( item_track, false )
        
      for i =1, #data[tkID].edits do      
        InsertTrackAtIndex( par_ID+i-1, false )  
        local desttr = CSurf_TrackFromID( par_ID+i, false ) 
        local it = AddMediaItemToTrack( desttr )
        SetItemStateChunk( it, chunk, false )
        local data0 = CopyTable(data)
        for j =1, #data[tkID].edits do 
          if  j == i then 
            data0[tkID].edits[j].bypass = 2 
            --data0[tkID].edits[j].pos = 0
           else 
            data0[tkID].edits[j] = nil 
          end
        end
        SetSpectralData(it, data0)
        local it_pos = GetMediaItemInfo_Value( it, 'D_POSITION' )
        local prate = GetMediaItemTakeInfo_Value( tk, 'D_PLAYRATE' ) 
        local soffs = GetMediaItemTakeInfo_Value( tk, 'D_STARTOFFS' )
        SetMediaItemInfo_Value( it, 'D_POSITION', it_pos +  (data[tkID].edits[i].pos - soffs)/prate)
        SetMediaItemInfo_Value( it, 'D_LENGTH', data[tkID].edits[i].len/prate)
        local tk0 = GetActiveTake( it )
        SetMediaItemTakeInfo_Value( tk0, 'D_STARTOFFS', data0[tkID].edits[i].pos)
      end
      
        
      UpdateArrange()
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
  
  
    

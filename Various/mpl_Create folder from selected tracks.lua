-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Create folder from selected tracks
-- @changelog
--    + init

    local name = 'Create folder from selected tracks'
    for key in pairs(reaper) do _G[key]=reaper[key]  end 
    -----------------------------------------------------------
    function Action(id) Main_OnCommand(id, 0) end
    -----------------------------------------------------------
    function main()    
      -- check for sel tr count
        if CountSelectedTracks(0) == 0 then return end
        
      -- collect chunks
      -- rename tracks as FX
        local ch_t ,insert_id= {}
        for i = 1, CountSelectedTracks(0) do
          local tr = GetSelectedTrack(0,i-1)
          if i == 1 then insert_id =  CSurf_TrackToID( tr, false ) end
          local instr_id = TrackFX_GetInstrument( tr )
          if instr_id >=0 then
            local fx_name = ({TrackFX_GetFXName( tr, instr_id, '' )})[2]
            if fx_name:match('%:') then fx_name = fx_name:match('%:.*'):sub(3) end
            GetSetMediaTrackInfo_String( tr, "P_NAME", fx_name, true)
          end  
          ch_t [#ch_t+1] = ({GetTrackStateChunk( tr, '', false )})[2]      
        end      
        
      -- add folder track
      -- name folder track
        local retval, new_name = GetUserInputs( 'mpl_Create folder', 1, 'New folder name:,extrawidth=150', 'Folder' )
        if not retval then return end 
        for i = CountSelectedTracks(0), 1, -1 do DeleteTrack( GetSelectedTrack(0,i-1) ) end
        InsertTrackAtIndex( insert_id-1, false )
        local fold_tr = reaper.CSurf_TrackFromID( insert_id, false )
        GetSetMediaTrackInfo_String( fold_tr, "P_NAME", new_name, true)
                
      -- get back removed tracks
        local last_tr
        for i = #ch_t, 1, -1 do
          InsertTrackAtIndex( insert_id, false )
          local cur_tr = reaper.CSurf_TrackFromID( insert_id+1, false )
          reaper.SetTrackStateChunk( cur_tr, ch_t[i], false )
          --SetMediaTrackInfo_Value( cur_tr, 'B_MAINSEND', 1 ) 
          if i == #ch_t then last_tr = cur_tr end
        end
        
      -- deal with parent/child structure
        SetMediaTrackInfo_Value( fold_tr, 'I_FOLDERDEPTH', 1 )
        SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH', -1 )
        
      -- update GUI
        TrackList_AdjustWindows( false )
    end
    
    
    defer(main)
    Undo_OnStateChangeEx( name, -1, -1 )
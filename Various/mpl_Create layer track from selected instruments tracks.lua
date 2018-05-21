-- @version 1.06
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Create layer track from selected instruments tracks
-- @changelog
--    # fix msg vsr



    local name = 'Create layer track from selected tracks'
    for key in pairs(reaper) do _G[key]=reaper[key]  end 
    -----------------------------------------------------------
    function Action(id) Main_OnCommand(id, 0) end
    -----------------------------------------------------------
    function main()    
      -- check for sel tr count
        tr_cnt = CountTracks(0)
        seltr_cnt = CountSelectedTracks(0)
        if seltr_cnt == 0 then return end
        
      -- get insertion place: 
      -- before first selected track if it placed on 1st level
      -- if selected track not on first level, insert above closest 1st level track
      -- otherwise put after lowest track
      
        local tr = GetSelectedTrack(0,0)
        insert_id = CSurf_TrackToID( tr, false )         

      -- add/name folder track
        local retval, new_name = GetUserInputs( 'mpl_Create layer track', 1, 'New layer name:,extrawidth=150', 'InstrumentLayer' )
        if not retval then return end 
        InsertTrackAtIndex( insert_id-1, false )
        local fold_tr = CSurf_TrackFromID( insert_id, false )
        GetSetMediaTrackInfo_String( fold_tr, "P_NAME", new_name, true)    
        
     -- move tracks
        ReorderSelectedTracks(insert_id, 1) 

      -- add MIDI track
        InsertTrackAtIndex( insert_id, false )
        local midi_tr = reaper.CSurf_TrackFromID( insert_id+1, false )
        GetSetMediaTrackInfo_String( midi_tr, "P_NAME", 'MIDI', true) 
        SetMediaTrackInfo_Value( midi_tr, 'B_MAINSEND', 0 ) 
        local bits_set=tonumber('111111'..'00000',2)       
        SetMediaTrackInfo_Value( midi_tr, 'I_RECINPUT', 4096+bits_set ) -- set input to all MIDI
        SetMediaTrackInfo_Value( midi_tr, 'I_RECMON', 1) -- monitor input
        SetMediaTrackInfo_Value( midi_tr, 'I_RECARM', 1) -- arm track
        SetMediaTrackInfo_Value( midi_tr, 'I_RECMODE',0) -- record MIDI out        

      -- add MIDI only receive from MIDI track
        for i = insert_id+1, insert_id+1+seltr_cnt do
          local dest_tr = GetTrack(0,i-1)
          SetMediaTrackInfo_Value( dest_tr, 'B_MAINSEND', 1 ) 
          local new_send = CreateTrackSend( midi_tr, dest_tr )
          reaper.SetTrackSendInfo_Value( midi_tr, 0, new_send, 'I_SRCCHAN',-1 )
          reaper.SetTrackSendInfo_Value( midi_tr, 0, new_send, 'I_MIDIFLAGS', 0 )
        end
    end
    
    if APIExists( 'ReorderSelectedTracks' ) then
      Undo_BeginBlock()
      main()
      Undo_EndBlock( name, -1 )
     else
      MB('Require REAPER 5.90rc7+','Error',0)
    end

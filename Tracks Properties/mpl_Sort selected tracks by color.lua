-- @description Sort selected tracks by color
-- @version 1.4
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + mod from Sort all tracks by color
--    # put selected tracks after fisrst selected track
--    # rebuild with ReorderSelectedTracks(), require REAPER 5.90rc7+
 
  local script_title = "Sort all tracks by color"
  for key in pairs(reaper) do _G[key]=reaper[key]  end
  function main()
  
    -- collect selected tracks
      tr_t = {}
      local cnt_seltr = CountSelectedTracks(0)
      if cnt_seltr == 0 then return end
      local tr = GetSelectedTrack(0,0)
      local insert_id = CSurf_TrackToID( tr, false ) 
              
      for i =1, cnt_seltr do
        local tr = GetSelectedTrack(0,i-1)
        tr_t[#tr_t+1] = {GUID = GetTrackGUID( tr ),
                        col = GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')}   
      end
    -- sort by col      
      table.sort(tr_t, function(a,b) return a.col<b.col end )
    
    for i = 1, #tr_t do
      local tr = BR_GetMediaTrackByGUID( 0, tr_t[i].GUID )
      SetOnlyTrackSelected( tr )
      ReorderSelectedTracks(insert_id, 0)
    end
    
  end

------------------------------------------------------------------------------




    if APIExists( 'ReorderSelectedTracks' ) then
      Undo_BeginBlock()
      main()
      Undo_EndBlock( script_title, -1 )
     else
      MB('Require REAPER 5.70rc7+','Error',0)
    end
-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Toggle show tracks if edit cursor crossing any of their items
-- @website http://forum.cockos.com/member.php?u=70694


  function main(state)
    curpos = reaper.GetCursorPosition()
    for i_tr = 1, reaper.CountTracks(0) do
      local tr = reaper.GetTrack(0,i_tr-1) 
      local show = state
      for i_it = 1,  reaper.CountTrackMediaItems( tr) do
        local it = reaper.GetTrackMediaItem( tr, i_it-1 )
        if it then 
          it_pos = reaper.GetMediaItemInfo_Value( it, 'D_POSITION' )
          it_len = reaper.GetMediaItemInfo_Value( it, 'D_LENGTH' )                   
          if it_pos <= curpos and it_pos + it_len >= curpos then show = 1 break end
        end
      end
      
      reaper.SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', show )
      reaper.SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', show )  
    end
  end
  
  is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
  state = reaper.GetToggleCommandState( cmdID )
  if state == -1 then state = 0 end
  reaper.SetToggleCommandState( sectionID, cmdID, math.abs(1-state) )
  
  main(state)
  reaper.TrackList_AdjustWindows( false )
  reaper.UpdateArrange()
-- @description Transport Play Stop (obey longest negative track offset)
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Triggers play by edit cursor shifted to a maximum negative offset for tracks in project
-- @version 1.01
-- @changelog
--    # multiply shift by 2


if reaper.GetPlayState()&1==1 then 
    reaper.OnStopButtonEx(0 )
    --reaper.OnPauseButtonEx( 0 )
   else
    local SR = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
     play_offs= 0
    for i =1, reaper.CountTracks(0) do
      local tr = reaper.GetTrack(0,i-1)
      local offs = reaper.GetMediaTrackInfo_Value( tr, 'D_PLAY_OFFSET' )
      local offs_flag = reaper.GetMediaTrackInfo_Value( tr, 'I_PLAY_OFFSET_FLAG' )
      if offs_flag&1~=1 then 
        if offs_flag&2==2 then play_offs=math.min(play_offs,offs/SR) else play_offs=math.min(play_offs,offs) end
      end
    end
    cur_pos = reaper.GetCursorPositionEx( 0 )
    reaper.PreventUIRefresh( 1 )
    reaper.SetEditCurPos2( 0, cur_pos+play_offs*2, false, true )
    reaper.OnPlayButtonEx( 0 )
    reaper.SetEditCurPos2( 0, cur_pos, false, false )
    reaper.PreventUIRefresh( -1 )
  end
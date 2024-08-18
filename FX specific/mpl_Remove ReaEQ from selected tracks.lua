-- @description Remove ReaEQ from selected tracks
-- @version 1.01
-- @author MPL
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  ----------------------------------------------------------------------
  function main() 
    local fxname = 'ReaEQ' 
    for i =1, CountSelectedTracks(0) do 
      local track = GetSelectedTrack(0,i-1)
      for fx = TrackFX_GetCount( track ), 1, -1 do
        local retval, buf = TrackFX_GetFXName( track, fx-1 )
        match  = buf:lower():match(fxname:lower())~=nil
        if match then TrackFX_Delete(track, fx-1) end
      end
    end
  end    
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Remove ReaEQ from selected tracks', 2 )
  end 

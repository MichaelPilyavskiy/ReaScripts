-- @description Insert focused FX to selected tracks
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
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
  ---------------------------------------------------
  function main()
    local ret, tracknumber, _, fxnumberOut = reaper.GetFocusedFX()
    if ret == 0 then return end
    local track = reaper.CSurf_TrackFromID(tracknumber, false)
    local _, fxname = reaper.TrackFX_GetFXName( track, fxnumberOut, '' )
    
    if fxname:find('/') then 
      fxname = fxname:reverse()
      fxname = fxname:sub(0,fxname:find('/') - 1)
      fxname = fxname:reverse()
     else
      fxname = fxname:match('%:.+'):sub(3)
    end
    
    for sel_tr = 1,  reaper.CountSelectedTracks( 0 ) do
      sel_track = reaper.GetSelectedTrack( 0, sel_tr-1 )
      if sel_track ~= track then reaper.TrackFX_AddByName( sel_track, fxname, false, -1 ) end
    end
  end
  
  if VF_CheckReaperVrs(6,true) then main() end

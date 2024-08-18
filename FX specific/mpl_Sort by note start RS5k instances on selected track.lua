-- @description Sort by note start RS5k instances on selected track
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
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

  
  --NOT gfx NOT reaper
--------------------------------------------------------------------
  function main()
    local track = GetSelectedTrack(0,0)
    if not track then return end 
    local t = {}
    local cntfx =  TrackFX_GetCount(track) 
    for fx = 1, cntfx do
      local retval, buf = reaper.TrackFX_GetParamName(  track, fx-1, 3,'' )
      if retval and buf:match('Note range start') then
        local MIDIpitch = math.floor(TrackFX_GetParamNormalized( track, fx-1, 3)*128) 
        t[#t+1]=MIDIpitch..'_'..fx
      end
    end  
    table.sort(t) 
    for i=1, #t do local src_fx = tonumber(t[i]:match('%d+_(%d+)')) TrackFX_CopyToTrack( track, src_fx-1, track, cntfx+i, false ) end 
    for i=cntfx, 1,-1 do TrackFX_Delete( track, i-1 ) end 
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)  then 
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Sort by note start RS5k instances on selected track', 0xFFFFFF )
  end
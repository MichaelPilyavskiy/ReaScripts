-- @description Show existing envelopes for last touched FX
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # update for use with REAPER 7.19
--    # SWS extension not required
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function main()
    local retval, tracknumberOut, fxnumberOut =  GetLastTouchedFX()
    if not retval then return end
    local tr =  CSurf_TrackFromID( tracknumberOut, false )
    if not tr then return end
    for parameterindex = 1, TrackFX_GetNumParams( tr, fxnumberOut ) do
      local env = GetFXEnvelope( tr, fxnumberOut, parameterindex-1, false )  
      if env then reaper.GetSetEnvelopeInfo_String( env, 'VISIBLE', 1, 1 ) end
    end
    reaper.TrackList_AdjustWindows( false )
  end
    


primaryvrs = reaper.GetAppVersion():match('[%d%.]+')
if primaryvrs and tonumber(primaryvrs) and tonumber(primaryvrs) >=7.19 then
  local script_title = "Show existing envelopes for last touched FX"
  reaper.Undo_BeginBlock() 
  main()
  reaper.Undo_EndBlock(script_title, 0xFFFFFFFF)
 else
  reaper.MB('This script requires REAPER 7.19+','Error',0)
end

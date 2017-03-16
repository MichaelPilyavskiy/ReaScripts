-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Insert 1 measure long automation item for last touched parameter
-- @changelog
--    + init

  local script_title = 'Insert 1 measure long automation item for last touched parameter'
    
  
  function main() 
    local retval, tracknum, fxnum, paramnum = reaper.GetLastTouchedFX()
    if not retval then return end    
    local track =  reaper.CSurf_TrackFromID( tracknum, false )
    if not track then return end
        
    AI_pos = reaper.GetCursorPosition()
    local cur_pos_beats, cur_pos_measures =  reaper.TimeMap2_timeToBeats( 0, AI_pos )
    AI_len = reaper.TimeMap2_beatsToTime( 0, cur_pos_beats, cur_pos_measures+1 ) - AI_pos
    local fx_env = reaper.GetFXEnvelope( track, fxnum, paramnum, true )
    if not fx_env then return end
    AI_poolid = reaper.InsertAutomationItem( fx_env, -1, AI_pos, AI_len ) -- add pool to RPP with negative srclen, not visible in project
    
    reaper.GetSetAutomationItemInfo( fx_env, AI_poolid, 'D_POSITION', AI_pos, true ) -- crashing
    reaper.GetSetAutomationItemInfo( fx_env, AI_poolid, 'D_LENGTH', AI_len, true ) -- crashing
    
    reaper.TrackList_AdjustWindows( false )
    reaper.UpdateArrange()    
  end
  
  function vrs_check()
    local appvrs = reaper.GetAppVersion()
    appvrs = appvrs:match('[%d%p]+')
    if not appvrs or not tonumber(appvrs) or tonumber(appvrs) < 5.40 then return else return true end 
  end
  
  if vrs_check() then 
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock(script_title, 1)
   else
    reaper.MB('Script works with REAPER 5.40+', 'Error', 0)
  end
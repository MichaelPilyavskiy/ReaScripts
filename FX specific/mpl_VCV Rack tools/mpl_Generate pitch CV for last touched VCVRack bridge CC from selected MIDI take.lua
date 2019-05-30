-- @description Generate pitch CV for last touched VCVRack bridge CC from selected MIDI take
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--   #header


  local vrs = 'v1.0'
  --NOT gfx NOT reaper
 --------------------------------------------------------------------
  function main()
      
    -- get parameter
      local retval, tracknum, fxnum, paramnum = GetLastTouchedFX()
      if not retval then return end    
      local track =  CSurf_TrackFromID( tracknum, false )
      if not track then return end
      
    -- get take
      local item =GetSelectedMediaItem(0,0)
      if not item then return end
      local take = GetActiveTake(item)
      if not take or not TakeIsMIDI(take) then return end
      
    -- get boundary
      pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
            
    -- clear envelope
      local proj_len = GetProjectLength( 0 )
      local env = GetFXEnvelope( track, fxnum, paramnum, true ) 
      DeleteEnvelopePointRange( env, pos, pos+len )
    
    -- loop through notes  
      local retval, notecnt, ccevtcnt, textsyxevtcnt = MIDI_CountEvts( take )
      for noteidx = 1, notecnt do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = MIDI_GetNote( take, noteidx-1 )
        local pnt_time = MIDI_GetProjTimeFromPPQPos( take, startppqpos )
        InsertEnvelopePoint( env, 
                                    pnt_time, 
                                    pitch/120,--value, 
                                    1,--shape, 
                                    0,--tensi on, 
                                    false,--selected, 
                                    true --noSortIn 
                                    )            
      end
      Envelope_SortPoints(env)
      UpdateArrange()
      
      
    --[[local pat_len = TimeMap2_beatsToTime( 0, pat_len )
    pool_id = InsertAutomationItem( env, -1, curpos, pat_len )
    TrackList_AdjustWindows(false)]]
    
  end 
   
---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        return true
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
  ---------------------------------------------------
  function CheckReaperVrs(rvrs) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0)
      return
     else
      return true
    end
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('Action') 
  local ret2 = CheckReaperVrs(5.95)    
  if ret and ret2 then main() end
-- @description Link TCP MCP folder collapsed state (running in background)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

-- Used X-Raym template: https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua



  local last_PCC, PCC
  ---------------------------------------------------
  function eugen27771_GetTrackStateChunk(track)
    if not track then return end
    local fast_str, track_chunk
    fast_str = reaper.SNM_CreateFastString("")
    if reaper.SNM_GetSetObjectState(track, fast_str, false, false) then track_chunk = reaper.SNM_GetFastString(fast_str) end
    reaper.SNM_DeleteFastString(fast_str)
    return track_chunk
  end
  ---------------------------------------------------
  function CheckClickableMCPFolder()
    if reaper.GetToggleCommandState( 41154 ) == 0 then reaper.Main_OnCommand(41154,0) end
  end
  -----------------------------------------------------
  function PerformTriggerCheck() local ret
    PCC = reaper.GetProjectStateChangeCount( 0 )
    if not last_PCC or last_PCC ~= PCC then ret = true end
    last_PCC = PCC
    return ret
  end
  -----------------------------------------------------
  function RunFolderMCPTCPCollapseStateLink()
    local trig_linkcheck = PerformTriggerCheck()
    if trig_linkcheck then LinkMCPTCP() end
    reaper.defer(RunFolderMCPTCPCollapseStateLink)
  end
  -----------------------------------------------------
  function LinkMCPTCP()
    local track, contextOut = reaper.BR_TrackAtMouseCursor()
    if not track then return end
    local tr_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    if tr_depth ~=1 then return end 
    if contextOut == 0 then -- link MCP to TCP
      local TCP_state = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
      ShowChildrenInMCP(track, TCP_state==0 or TCP_state==1)
     else -- link TCP to MCP
      local MCP_state = ShowChildrenInMCP(track, _, true)
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT", MCP_state and 0 or 2)
    end
  end
  -----------------------------------------------------
  function ShowChildrenInMCP(tr, is_show, return_state)
    local tr_chunk = eugen27771_GetTrackStateChunk(tr)
    local BUSCOMP_var1 = tonumber(tr_chunk:match('BUSCOMP (%d+)'))
    local BUSCOMP_var2 = tonumber(tr_chunk:match('BUSCOMP %d+ (%d+)'))
    if return_state then return BUSCOMP_var2==0 end
    local tr_chunk_out = tr_chunk:gsub('BUSCOMP '..BUSCOMP_var1..' %d+', 'BUSCOMP '..BUSCOMP_var1..' '..(is_show and 0 or 1))
    if BUSCOMP_var2 ~= (is_show and 0 or 1) then reaper.SetTrackStateChunk(tr, tr_chunk_out,true) end
  end
  -----------------------------------------------------
  function ToolbarButtonOn()
    local _, _, sec, cmd = reaper.get_action_context()
    reaper.SetToggleCommandState( sec, cmd, 1)
    reaper.RefreshToolbar2( sec, cmd )
  end
  function ToolbarButtonOff()
    local _, _, sec, cmd = reaper.get_action_context()
    reaper.SetToggleCommandState( sec, cmd, 0)
    reaper.RefreshToolbar2( sec, cmd )
  end  
  ----------------------------------------------------- 
  CheckClickableMCPFolder()
  ToolbarButtonOn()
  RunFolderMCPTCPCollapseStateLink()
  reaper.atexit( ToolbarButtonOff )
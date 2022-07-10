-- @description Set MCP collapsed states from TCP
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # a branch from unstable script mpl_Link TCP MCP folder collapsed state (running in background)
--    # avoid SWS dependency
--    # avoid chunking as much as possible


  -----------------------------------------------------
  function ShowChildrenInMCP(tr, flagMCP_IN)
    local retval, tr_chunk = GetTrackStateChunk( tr, '', true ) -- reduced chunk for chucking states
    local flagTCP, flagMCP = tr_chunk:match('BUSCOMP (%d+) (%d+)')
    flagTCP, flagMCP = tonumber(flagTCP), tonumber(flagMCP)
    if flagMCP == flagMCP_IN then return end
    
    local retval, tr_chunk = GetTrackStateChunk( tr, '', false ) -- full chunk
    local tr_chunk_out = tr_chunk:gsub('BUSCOMP %d+ %d+', 'BUSCOMP '..flagTCP..' '..flagMCP_IN)
    if BUSCOMP_var2 ~= (is_show and 0 or 1) then reaper.SetTrackStateChunk(tr, tr_chunk_out,true) end
  end
  -----------------------------------------------------
  function main()
    local cnt = CountTracks( 0 )
    local tr,is_fold
    for trackidx = 1, cnt do
      track = GetTrack( 0, trackidx-1 )
      is_fold = GetMediaTrackInfo_Value( track, 'I_FOLDERDEPTH' )==1
      local TCP_state = GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT")
      local flagMCP_IN = 1
      if TCP_state==0 or TCP_state==1  then flagMCP_IN = 0 end
      ShowChildrenInMCP(track, flagMCP_IN)
    end 
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.0) if ret then local ret2 = VF_CheckReaperVrs(5.9,true) if ret2 then  main() end end 
  
  
  
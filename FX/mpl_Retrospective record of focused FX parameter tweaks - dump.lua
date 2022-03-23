-- @description Retrospective record of focused FX parameter tweaks - dump
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  local fpath = reaper.GetResourcePath()..'/mpl_FXRetrospectiveLog.txt'
  history = {}
  
  function main()
    local curpos =  reaper.GetCursorPosition()
    history = table.load(fpath)
    if not history then return end
    -- normalize ts
      local max_ts = 0 for i = 1, #history do max_ts = math.max(max_ts,history[i].ts ) end
      for i = 1, #history do history[i].ts  = history[i].ts  - max_ts end
      
    -- envelope
      local sortt = {}
      for i = 1, #history do 
        local retfx, tr, fxid = VF_GetFXByGUID(history[i].fxGUID)
        if retfx then
          local fx_env = GetFXEnvelope( tr, fxid, history[i].paramid, true )
          local time = curpos + history[i].ts
          if history[i].playpos  then time = history[i].playpos end
          InsertEnvelopePointEx( fx_env, -1, time, history[i].val, 0, 0, 0, true )
          sortt[fx_env] = true
        end
      end
       
      for envptr in pairs(sortt) do Envelope_SortPoints( envptr ) end
      reaper.UpdateArrange()
      --reaper.UpdateTimeline()
      --reaper.CSurf_SetTrackListChange()
      reaper.TrackList_AdjustWindows( false )
      
    --[[ clear history
      history = {}
      table.save(history, fpath)]]
      
      reaper.gmem_write(1,1 ) -- trigger for defer script to clear
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.0) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then gmem_attach('mpl_retrospectrec' ) main() end end
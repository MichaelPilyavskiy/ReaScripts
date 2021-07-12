-- @description Toggle between normal and supercollapsed selected folders state
-- @version 1.0
-- @author MPL
-- @changelog
--  init 

  function main()
    local tr = GetSelectedTrack(0,0)
    local state = GetMediaTrackInfo_Value( tr, 'I_FOLDERCOMPACT' )
    if state > 0 then state = 0 else state = 2 end
    SetMediaTrackInfo_Value( tr, 'I_FOLDERCOMPACT',state )
    
    for seltrackidx = 1,  CountSelectedTracks( 0 ) do
      local tr = GetSelectedTrack( 0, seltrackidx-1 ) 
      if GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH') == 1 then
        SetMediaTrackInfo_Value( tr, 'I_FOLDERCOMPACT',state )
      end
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_ShiftRegions') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then 
      Undo_BeginBlock2( 0 )
      main()
      Undo_EndBlock2( 0, 'Toggle between normal and supercollapsed selected folders state', -1 )
    end
  end
-- @description Set track offset in seconds
-- @version 1.0
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init


function main()
local retval, retvals_csv = reaper.GetUserInputs( 'Set track offset in seconds)', 1, 'offset (in seconds)', 0 )
if retval and tonumber(retvals_csv) then
  for i = 1, reaper.CountSelectedTracks(0) do
    tr = reaper.GetSelectedTrack(0,i-1)
    reaper.SetMediaTrackInfo_Value( tr, 'I_PLAY_OFFSET_FLAG', 0 )
    reaper.SetMediaTrackInfo_Value( tr, 'D_PLAY_OFFSET', tonumber(retvals_csv) ) 
  end
end
end


  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_LoadVFv2') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then 
      Undo_BeginBlock2( 0 )
      main()
      Undo_EndBlock2( 0, 'Set track offset in seconds', -1 )
    end
  end
  
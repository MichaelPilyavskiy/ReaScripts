-- @description TalkBack Track 1 (MIDI CC and OSC only)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @changelog
--    + init


  --NOT gfx NOT reaper
  function main()
    local tr = GetTrack(0,0)
    if not tr then return end
    
    local is_new_value, filename, sec, cmd, mode, resolution, val = get_action_context()

    -- toolbar state
    local state = GetToggleCommandStateEx( sec, cmd )
    if state < 0 then state = 0 end
    SetToggleCommandState( sec, cmd, math.abs(1-state) )
    RefreshToolbar2( sec, cmd )
    
    SetMediaTrackInfo_Value( tr, 'B_MUTE', state )
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
----------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then main() end
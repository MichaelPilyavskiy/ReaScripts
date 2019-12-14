-- @description Toggle set midi routing mode for all selected tracks sends
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
 
mode = 0
-- mode = 0 toggle
-- mode = 1 turn on
-- mode = 2 turn off

 function main()
    for i = 1, reaper.CountSelectedTracks(0) do SetMIDIFlags(reaper.GetSelectedTrack(0,i-1)) end
  end
---------------------------------------------------------------------  
  function SetMIDIFlags(tr)
    for i = 1, reaper.GetTrackNumSends( tr, 0 ) do
      if i == 1 then def_flag = GetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS' )&1024 end
      if def_flag == 0 then
        val = GetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS' ) 
        if val&1024 == 0 then SetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS', val + 1024) end
       else
        val = GetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS' ) 
        if val&1024 == 1024 then SetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS', val - 1024)     end  
      end
    end
    return 
  end
  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
  local ret, ret2 = CheckFunctions('VF_CheckReaperVrs') 
  if ret then ret2 = VF_CheckReaperVrs(5.0) end
  if ret and ret2 then main() end
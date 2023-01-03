-- @description Chord voicing - clear internal data
-- @version 1.0
-- @author MPL
-- @provides [main=main,midi_editor] .
-- @changelog
--  + init

  -- [[debug search filter: NOT function NOT reaper NOT gfx NOT VF]]
  ----------------------------------------------------------------------  
  function main(take)
    if not take or not TakeIsMIDI(take) then return end   
    GetSetMediaItemInfo_String(  GetMediaItemTake_Item( take ), 'P_EXT:mplchords', '',true )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) if ret then local ret2 = VF_CheckReaperVrs(5.32,true) if ret2 then 
    Undo_BeginBlock()
    local ME = reaper.MIDIEditor_GetActive()
    if ME then
      --take = reaper.MIDIEditor_GetTake(ME)
      for takeindex = 1, 100 do
        local take = MIDIEditor_EnumTakes( ME, takeindex-1, true) 
        if not take then break end
        main(take) 
      end
     else
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item) 
        if take then main(take) end
      end
    end
    Undo_EndBlock('Chord voicing - randomize', 0xFFFFFFFF)
  end end
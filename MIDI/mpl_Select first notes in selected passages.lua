-- @description Select first notes in selected passages
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335  
-- @changelog
--    + init
 
  ----------------------------------------------------------------------      
  function CheckForRegions(regions, st, en)
    for region = 1, #regions do
      local regst = regions[region].regst
      local regen = regions[region].regen
      if (st >=regst and st <=regen)
        or (en >=regst and en <=regen)
        or (st<=regst and en>= regen) then
        return region
      end
    end
  end
  ----------------------------------------------------------------------      
  function main()
    local midieditor = MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    if not take then return end
    t = {}
    regions = {}
    local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
    for noteidx = 1,notecnt do
      local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, noteidx-1 )
      if selected then 
        t[#t+1]=startppqpos
        local reg = CheckForRegions(regions, startppqpos, endppqpos)
        if not reg then
          regions[#regions+1] = {regst=startppqpos,regen=endppqpos}
         else
          regions[reg].regst = math.min(startppqpos,regions[reg].regst)
          regions[reg].regen = math.max(endppqpos,regions[reg].regen)
        end
      end
    end
    
    for noteidx = 1,notecnt do
      local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, noteidx-1 )
      local reg = CheckForRegions(regions, startppqpos, endppqpos)
      MIDI_SetNote( take, noteidx-1, regions[reg].regst == startppqpos, muted, startppqpos, endppqpos, chan, pitch, vel, true )
    end
    
    MIDI_Sort(take) 
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  -------------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.18) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then main() end end
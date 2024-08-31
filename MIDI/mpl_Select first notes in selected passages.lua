-- @description Select first notes in selected passages
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335  
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
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
 -------------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true)  then main() end 
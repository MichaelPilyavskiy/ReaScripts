-- @description Chord voicing - clear internal data
-- @version 1.01
-- @author MPL
-- @provides [main=main,midi_editor] .
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

  -- [[debug search filter: NOT function NOT reaper NOT gfx NOT VF]]
  ----------------------------------------------------------------------  
  function main(take)
    if not take or not TakeIsMIDI(take) then return end   
    GetSetMediaItemInfo_String(  GetMediaItemTake_Item( take ), 'P_EXT:mplchords', '',true )
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.32,true) then 
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
  end
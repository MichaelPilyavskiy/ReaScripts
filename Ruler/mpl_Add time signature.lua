-- @description Add time signature
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Add 1 to 4 time signature.lua
--    [main] . > mpl_Add 2 to 4 time signature.lua
--    [main] . > mpl_Add 3 to 4 time signature.lua
--    [main] . > mpl_Add 4 to 4 time signature.lua
--    [main] . > mpl_Add 5 to 4 time signature.lua
--    [main] . > mpl_Add 6 to 4 time signature.lua
--    [main] . > mpl_Add 7 to 4 time signature.lua
--    [main] . > mpl_Add 3 to 8 time signature.lua
--    [main] . > mpl_Add 5 to 8 time signature.lua
--    [main] . > mpl_Add 6 to 8 time signature.lua
--    [main] . > mpl_Add 7 to 8 time signature.lua
--    [main] . > mpl_Add 9 to 8 time signature.lua
--    [main] . > mpl_Add 10 to 8 time signature.lua
--    [main] . > mpl_Add 11 to 8 time signature.lua
--    [main] . > mpl_Add 12 to 8 time signature.lua
--    [main] . > mpl_Add 13 to 8 time signature.lua
--    [main] . > mpl_Add 14 to 8 time signature.lua
--    [main] . > mpl_Add 15 to 8 time signature.lua
--    [main] . > mpl_Add 3 to 16 time signature.lua
--    [main] . > mpl_Add 5 to 16 time signature.lua
--    [main] . > mpl_Add 7 to 16 time signature.lua
--    [main] . > mpl_Add 9 to 16 time signature.lua
--    [main] . > mpl_Add 10 to 16 time signature.lua
--    [main] . > mpl_Add 11 to 16 time signature.lua
--    [main] . > mpl_Add 12 to 16 time signature.lua
--    [main] . > mpl_Add 13 to 16 time signature.lua
--    [main] . > mpl_Add 14 to 16 time signature.lua
--    [main] . > mpl_Add 15 to 16 time signature.lua
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
  --------------------------------------------------------------------  
 
  --NOT gfx NOT reaper
  function main(num, denom)
    if not (num and denom) then return end
    num= tonumber(num)
    denom= tonumber(denom)
    if not (num and denom) then return end 
    local curpos = GetCursorPositionEx(0 )
    SetTempoTimeSigMarker( 0, -1, curpos, -1, -1, -1, num, denom, false )
    UpdateTimeline()
  end  
---------------------------------------------------------------------
  local scr_name = ({reaper.get_action_context()})[2]
  local num, denom = scr_name:match('Add (%d+) to (%d+) time signature')
  if VF_CheckReaperVrs(5.95) then main(num, denom) end
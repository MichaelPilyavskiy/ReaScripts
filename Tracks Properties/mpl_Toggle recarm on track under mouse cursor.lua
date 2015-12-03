--[[
   * ReaScript Name: Toggle recarm on track under mouse cursor
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
_, _, _ = reaper.BR_GetMouseCursorContext()
track = reaper.BR_GetMouseCursorContext_Track()
if track ~= nil then  
  if reaper.GetMediaTrackInfo_Value(track, 'I_RECARM') == 0 then
    reaper.ClearAllRecArmed()
    reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',1)
   else
    reaper.ClearAllRecArmed()
    reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',0)
  end  
end

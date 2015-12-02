--[[
   * Trim master fader to 0dB signal
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URL: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  script_title = "Trim master fader to 0dB signal"
  reaper.Undo_BeginBlock()
  
  track = reaper.GetMasterTrack(0)
      if track ~= nil then
        peak = reaper.Track_GetPeakInfo(track, 1)
        if peak > 1 then
          vol = reaper.GetMediaTrackInfo_Value(track, 'D_VOL')
          reaper.SetMediaTrackInfo_Value(track, 'D_VOL',vol-(peak-1))
        end
      end
  
  reaper.UpdateArrange()
  
  
  reaper.Undo_EndBlock(script_title,0)

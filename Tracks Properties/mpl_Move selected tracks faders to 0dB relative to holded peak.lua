-- @version 1.0
-- @author MPL
-- @description Move selected tracks faders to 0dB relative to holded peak
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release
--    # "Trim master/sel.tracks fader to 0dB peak" seems doesn`t work as expected, recoded to more smooth behaviour

  local d_volume = 0.2 -- shift in dB
  
    
  local threshold_switch = -0.5 -- linear threshold
  function dBFromVal(val) return 20*math.log(val, 10) end
  function ValFromdB(dB_val) return 10^(dB_val/20) end
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end
  function main()
    --local track = reaper.GetMasterTrack(0)
    
    for i = 1,  reaper.CountSelectedTracks2( 0, true ) do
      local track =  reaper.GetSelectedTrack2( 0, i-1, true )
      local peakL = reaper.Track_GetPeakHoldDB(track, 0, false)
      local peakR = reaper.Track_GetPeakHoldDB(track, 1, false)
      peak_max = math.max(peakL, peakR)
      reaper.Track_GetPeakHoldDB(track, 0, true)
      reaper.Track_GetPeakHoldDB(track, 1, true)
      
      if peak_max > threshold_switch then 
        local add
        if peak_max < 0 then add = d_volume else add = -d_volume end
        local cur_vol = reaper.GetMediaTrackInfo_Value(track, 'D_VOL')
        local cur_vol_db = dBFromVal(cur_vol)
        new_vol = ValFromdB(cur_vol_db + add)
        --msg(d_volume)
        --msg(cur_vol_db)
        reaper.SetMediaTrackInfo_Value(track, 'D_VOL',new_vol)
      end
    end
    
  end
  
  
  local script_title = "Move selected tracks faders to 0dB relative to holded peak"
  reaper.Undo_BeginBlock()
  main()
  reaper.UpdateArrange()
  reaper.Undo_EndBlock(script_title,0)
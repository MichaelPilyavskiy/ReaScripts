-- @description Warp grid to selected item stretch markers
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + denominator ratio

  -- NOT gfx NOT reaper
  local scr_title = 'AutoWarp to item stretch markers'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function msg(s) if s then  ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  function CollectTimeCode(item)
    if not item then return end
    local item_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
    local timecode_markers = {}
    local take = GetActiveTake(item)
    if not take then return end
    if TakeIsMIDI(take) then return end     
    timecode_markers[1] = item_pos
    for i = 1,  GetTakeNumStretchMarkers( take) do
      local retval, pos = GetTakeStretchMarker( take, i-1)
      timecode_markers[#timecode_markers+1] = pos+item_pos
    end
    return timecode_markers
  end
  ---------------------------------------------------
  function ClearTimeSignatureMarkers()
    for i = CountTempoTimeSigMarkers( 0 ), 1, -1 do reaper.DeleteTempoTimeSigMarker( 0, i-1 ) end
    UpdateArrange()
    UpdateTimeline()
  end
  ---------------------------------------------------
  function math_q(val) if ({math.modf(val)})[2] > 0.5 then return math.ceil(val) else return math.floor(val) end end
  ---------------------------------------------------
  function TempoFit(t0,t1,allow_partial_measure, tempo0, timesigdenum0, denomratio)  
    local tempo0_onebeattime = 60/tempo0
    local timediff = t1-t0
    beats_diff= math_q(timediff/(tempo0_onebeattime/denomratio))   
    if allow_partial_measure then
      timesigdenum = beats_diff
     else
      beats_diff = math_q(beats_diff/timesigdenum0*denomratio )*timesigdenum0*denomratio
    end    
    if ({math.modf(beats_diff/timesigdenum0)})[2] == 0 then timesigdenum = timesigdenum0 end    
    local timeofonebeat = timediff/beats_diff
    local tempo = 60/timeofonebeat   
    AddTempoTimeSigMarker( 0, t0, tempo/denomratio, timesigdenum, 4*denomratio, false )    
  end
  ---------------------------------------------------  
  function AutoWarpGrid()
    local item = GetSelectedMediaItem(0,0)  
    local t = CollectTimeCode(item)
    if t and #t > 2 then
      local cur_tempo =  Master_GetTempo()
      retUI, str = GetUserInputs(scr_title,4,'Desired tempo,Time signature numerator,Denominator ratio (1,2,4),Allow partial measure (Y/N)',cur_tempo..',4,1,Y')
      if retUI then
        val_t = {}
        for val in str:gmatch('[^,]+') do val_t[#val_t+1] = val end
        if #t < 4 
          or not tonumber(val_t[1]) 
          or not tonumber(val_t[2])
          or not tonumber(val_t[3]) then return end
        local desired_tempo = tonumber(val_t[1])
        local timesig_num = tonumber(val_t[2])
        local denom_ratio = tonumber(val_t[3])
        local allow_partial_measure = val_t[4]:lower():match('y')
        Undo_BeginBlock()
        SetMediaItemInfo_Value( item, 'C_BEATATTACHMODE', 2 )
        ClearTimeSignatureMarkers()
        for i = 1, #t-1 do TempoFit(t[i], t[i+1], allow_partial_measure, desired_tempo, timesig_num, denom_ratio) end
        Undo_EndBlock( 'AutoWarp', 0 )
      end
    end
  end
  
  AutoWarpGrid()
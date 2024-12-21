-- @description Float RS5k instance by last clicked MIDI editor note
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix range math, https://t.me/mplscripts_chat/5532

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
  function main_sub(tr,base_pitch)
    if not tr then return end
    local ret = FloatRs5kbyPitch(base_pitch,tr) if ret then return true end 
    for sendidx = 1, GetTrackNumSends( tr, 0 ) do
      local flags = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_MIDIFLAGS' )
      if flags >= 0 then
        local dest_tr= GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
        local ret = FloatRs5kbyPitch(base_pitch,dest_tr) if ret then return true end
      end
    end
  end
 --------------------------------------------------------------------
  function main(base_pitch)
    local midieditor = reaper.MIDIEditor_GetActive()
    if not midieditor then return end
    local take = reaper.MIDIEditor_GetTake( midieditor )
    local tr = reaper.GetMediaItemTake_Track( take )
    if tr then main_sub(tr,base_pitch) end
  end
  --------------------------------------------------------------------
  function FloatRs5kbyPitch(base_pitch, track)
    for fx = 1,  TrackFX_GetCount( track ) do
      local retval, buf = reaper.TrackFX_GetParamName( track, fx-1, 2 )
      if buf =='Gain for minimum velocity' then -- validate fx is rs5k
        local nrangest = TrackFX_GetParamNormalized( track, fx-1, 3 ) -- note range start
        local nrangeendd = TrackFX_GetParamNormalized( track, fx-1, 4 ) -- note range end
        if math.floor( nrangest *128) <= base_pitch and  math.floor(nrangeendd *128) >= base_pitch then -- https://t.me/mplscripts_chat/5532
          reaper.TrackFX_SetOpen( track, fx-1, true )
          reaper.SetOnlyTrackSelected( track )
          return true
        end
      end
    end
      
  end 
  ----------------------------------------------------------------------
  function getlastnote()
    local midieditor = reaper.MIDIEditor_GetActive()
    local active_note_row = reaper.MIDIEditor_GetSetting_int( midieditor, 'active_note_row' )
    return active_note_row
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6.64,true)  then 
     base_pitch = getlastnote()
    if base_pitch then main(base_pitch) end
  end 
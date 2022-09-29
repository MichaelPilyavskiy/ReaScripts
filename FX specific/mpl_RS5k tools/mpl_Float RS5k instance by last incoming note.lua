-- @description Float RS5k instance by last incoming note
-- @version 1.03
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    # fix math for detecting rs5k note
--    + Select founded track


  local vrs = 'v1.03'
 --------------------------------------------------------------------
  function main_sub(tr)
    if not tr then return end
    local arm = GetMediaTrackInfo_Value( tr, 'I_RECARM' )
    if arm==1 then 
      local ret = FloatRs5kbyPitch(base_pitch,tr) if ret then return true end 
      for sendidx = 1, GetTrackNumSends( tr, 0 ) do
        local flags = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_MIDIFLAGS' )
        if flags >= 0 then
          local dest_tr= GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
          local ret = FloatRs5kbyPitch(base_pitch,dest_tr) if ret then return true end
        end
      end
    end
  end
 --------------------------------------------------------------------
  function main()
    -- selected track
    local tr = GetSelectedTrack(0,0)
    if tr then 
      local ret = main_sub(tr)
      if ret then return end
    end
    
    -- all tracks search
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local ret = main_sub(tr)
      if ret then return end
    end
    
  end
  --------------------------------------------------------------------
  function FloatRs5kbyPitch(base_pitch, track)
    for fx = 1,  TrackFX_GetCount( track ) do
      local retval, buf = reaper.TrackFX_GetParamName( track, fx-1, 2 )
      if buf =='Gain for minimum velocity' then -- validate fx is rs5k
        local nrangest = TrackFX_GetParamNormalized( track, fx-1, 3 ) -- note range start
        local nrangeendd = TrackFX_GetParamNormalized( track, fx-1, 4 ) -- note range end
        if math.floor( nrangest *128) == base_pitch and  math.floor(nrangeendd *128) == base_pitch then 
          reaper.TrackFX_SetOpen( track, fx-1, true )
          reaper.SetOnlyTrackSelected( track )
          return true
        end
      end
    end
      
  end 
  ----------------------------------------------------------------------
  function getlastnote()
    local retval, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    if retval ~= 0 then --and tsval > -SR*waittime then
      if (devIdx & 0x10000) == 0 or devIdx == 0x1003e then -- should works without this after REAPER6.39rc2, so thats just in case
        local isNoteOn = rawmsg:byte(1)>>4 == 0x9
        local isNoteOff = rawmsg:byte(1)>>4 == 0x8
        if isNoteOn or isNoteOff then 
          return rawmsg:byte(2)
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.18) if ret then local ret2 = VF_CheckReaperVrs(6.64,true) if ret2 then 
     base_pitch = getlastnote()
    if base_pitch then main(base_pitch) end
  end end
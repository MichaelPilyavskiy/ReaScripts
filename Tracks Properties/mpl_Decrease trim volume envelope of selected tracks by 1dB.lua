-- @description Decrease trim volume envelope of selected tracks by 1dB
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # change header
  
  increment_dB = -1

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function Init_TrimVolume(tr)
    local env = GetTrackEnvelopeByName( tr, 'Trim Volume' )
    if not env then 
      local init_chunk = [[
      <VOLENV3
      EGUID ]]..genGuid()..'\n'..[[
      ACT 0 -1
      VIS 1 1 1
      LANEHEIGHT 0 0
      ARM 1
      DEFSHAPE 0 -1 -1
      VOLTYPE 1
      PT 0 1 0
      >
      ]]  
      local retval, trchunk = GetTrackStateChunk( tr, '', false )
      local outchunk = trchunk:gsub('<TRACK','<TRACK\n'..init_chunk)
      SetTrackStateChunk( tr, outchunk, false )
      TrackList_AdjustWindows( false )
      env = GetTrackEnvelopeByName( tr, 'Trim Volume' )
      GetSetEnvelopeInfo_String( env  , 'ACTIVE', 1, 1 )
      return env
     else
      GetSetEnvelopeInfo_String( env  , 'ACTIVE', 1, 1 )
      return env
    end
  end
  ------------------------------------------------------------------------------------------------------
  function main()
    for i = 1, CountSelectedTracks(-1) do
      local track = GetSelectedTrack(-1,i-1)
      local envelope = Init_TrimVolume(track)
      if envelope then 
        scalmode = GetEnvelopeScalingMode( envelope )
        for ptidx = 1, CountEnvelopePoints( envelope ) do
          local retval, time, value, shape, tension, selected = GetEnvelopePoint( envelope, ptidx-1 )
          value = ScaleFromEnvelopeMode(scalmode, value)
          value_dB = WDL_VAL2DB(value) + increment_dB
          value = WDL_DB2VAL(value_dB)
          value = ScaleToEnvelopeMode(scalmode, value)
          SetEnvelopePoint( envelope, ptidx-1, time, value, shape, tension, selected, true )
        end
        Envelope_SortPoints( envelope )
      end 
    end
  end
------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return v end
  end
---------------------------------------------------------------------
  main()
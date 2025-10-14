-- @description Build 4 points segment of take envelope under mouse cursor based on audio source
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init from "Change gain of item audio segment under mouse cursor"
     
  local analyze_time_max = 8 -- seconds
  local window_sec = 0.03
  local threshold_dB = -20
  local time_fade = 0.02 -- seconds, don`t make it bigger than window_sec * 2
  local normalizeTo = 2 -- 0=LUFS-I, 1=RMS-I, 2=peak, 3=true peak, 4=LUFS-M max, 5=LUFS-S max
  local val_set = 0.8 -- envelope value
  --local hideenv = true

  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
------------------------------------------------------------------------------------------------------
  function VF_GetPositionUnderMouseCursor() 
    local x,y = reaper.GetMousePosition()
    local mouse_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1) -- get 
    local arr_start, arr_end = reaper.GetSet_ArrangeView2(0, false, 0, 0) -- get
    if mouse_pos >= arr_start and mouse_pos <= arr_end then return mouse_pos end
  end
------------------------------------------------------------------------------------------------------  
  function VF_GetItemTakeUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local item , take = reaper.GetItemFromPoint( screen_x, screen_y, true )
    return item , take
  end  
------------------------------------------------------------------------------------------------------
  function VF_Action(s)  Main_OnCommand(NamedCommandLookup(s), 0) end   
------------------------------------------------------------------------------------------------------  
  function init_takeenv(take)
    for envidx = 1,  CountTakeEnvelopes( take ) do 
      local tkenv = GetTakeEnvelope( take, envidx-1 ) 
      local retval, envname = reaper.GetEnvelopeName(tkenv ) 
      if envname == 'Volume' then env = tkenv break end 
    end 
    if not (env and ValidatePtr2( 0, env, 'TrackEnvelope*' )) then 
      VF_Action(40693) -- Take: Toggle take volume envelope 
      for envidx = 1,  CountTakeEnvelopes( take ) do 
        local tkenv = GetTakeEnvelope( take, envidx-1 ) 
        local retval, envname = reaper.GetEnvelopeName(tkenv ) 
        if envname == 'Volume' then env = tkenv break end 
      end 
    end
    
    if env and hideenv then retval, stringNeedBig = reaper.GetSetEnvelopeInfo_String( env, 'VISIBLE', '0', true ) end
    --GetSetEnvelopeInfo_String( env, 'ACTIVE', '1', true )
    return env
  end
------------------------------------------------------------------------------------------------------  
function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ---------------------------------------------------
  function msg(s) 
    if not s then return end 
    if type(s) == 'boolean' then
      if s then s = 'true' else  s = 'false' end
    end
    ShowConsoleMsg(s..'\n') 
  end 
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return v end
  end
  -----------------------------------------------------
  function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
------------------------------------------------------------------------------------------------------  
  function main()
    local mousepos = VF_GetPositionUnderMouseCursor() 
    local item , take = VF_GetItemTakeUnderMouseCursor() 
    if not (item and take and mousepos) then return end 
    local source = GetMediaItemTake_Source( take )
    
    if GetTakeNumStretchMarkers( take ) > 0 then MB('Take with stretch markers aren`t supported','Error', 0) return end
    local D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    local D_PLAYRATE = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    if D_STARTOFFS~= 0 then MB('Take with startoffset not equal 0 aren`t supported','Error', 0) return end
    if D_PLAYRATE~= 1 then MB('Take with play rate not equal 1 aren`t supported','Error', 0) return end
    
    local envelope = init_takeenv(take)
    if not envelope then return end  
    if hideenv then GetSetEnvelopeInfo_String( env, 'VISIBLE', '0', true ) end
    local envelopemode = GetEnvelopeScalingMode( env )
    
    local itpos = GetMediaItemInfo_Value( item, 'D_POSITION' ) 
    local source_pos_mid = math.max(0,mousepos - itpos)
    
    -- loop block to the both sides until find threshold-based boundaries 
    local normalizeTarget = 0
    --local pos_st, pos_end
    for pos = source_pos_mid-window_sec, source_pos_mid -analyze_time_max/2,-window_sec do
      local norm = reaper.CalculateNormalization( source, normalizeTo, normalizeTarget, pos, pos+window_sec )
      local peak = -WDL_VAL2DB(norm)
      if peak < threshold_dB then pos_st = pos break end
    end
    for pos = source_pos_mid, source_pos_mid +analyze_time_max/2-window_sec,window_sec do
      local norm = reaper.CalculateNormalization( source, normalizeTo, normalizeTarget, pos, pos+window_sec )
      local peak = -WDL_VAL2DB(norm)
      if peak < threshold_dB then pos_end = pos break end
    end
    
    if not (pos_st or pos_end) then MB('Phrase under '..threshold_dB..'dB boundaries not found','Error', 0) return end
    if not pos_st then pos_st = source_pos_mid -analyze_time_max/2 end
    if not pos_end then pos_end = source_pos_mid +analyze_time_max/2 end
    
    if pos_end - pos_st < time_fade*2 then return end --  MB('Phrase boundaries less than defined fade','Error', 0)
    
    startsegm=pos_st
    endsegm=pos_end
    
    local SR = VF_GetProjectSampleRate()
    local retval, startsegm_value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( envelope, startsegm, SR, 1 )
    local retval, endsegm_value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( envelope, endsegm, SR, 1 ) 
    reaper.DeleteEnvelopePointRange( envelope, startsegm-0.001, endsegm+0.001 )
    reaper.InsertEnvelopePoint(  envelope, startsegm, startsegm_value, 0, 0, 0, false )
    reaper.InsertEnvelopePoint(  envelope, endsegm, endsegm_value, 0, 0, 0, false )
    
    
    reaper.InsertEnvelopePoint(  envelope, startsegm + time_fade, reaper.ScaleToEnvelopeMode(envelopemode, val_set), 0, 0, 0, false )
    reaper.InsertEnvelopePoint(  envelope, endsegm - time_fade, reaper.ScaleToEnvelopeMode(envelopemode, val_set), 0, 0, 0, false )
    
      
  end 
  main()
  
  
      
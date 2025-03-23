-- @description Change gain of item audio segment under mouse cursor
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
     
  local analyze_time = 2 -- seconds
  local threshold_dB = -40
  local time_fade = 0.05 -- seconds
  local hideenv = true
  
  DATA = { val = 1 }
  -----------------------------------------------------
  function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset  
  DATA.SR = VF_GetProjectSampleRate()
  
  
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
    return env
  end
------------------------------------------------------------------------------------------------------ 
function get_audiodata(take, mousepos, analyze_time, starttime_sec)
  
  local samplerate = DATA.SR
  local numchannels = 1
  local numsamplesperchannel = samplerate * analyze_time
  local samplebuffer  = new_array(numsamplesperchannel) 
  local track = GetMediaItemTake_Track( take ) 
  local accessor = CreateTrackAudioAccessor( track )
  GetAudioAccessorSamples( accessor, samplerate, numchannels, starttime_sec, numsamplesperchannel, samplebuffer )

  local t = {}
  local i = 0
  local rms_step = 0.02
  local rms_step_spls = math.floor(rms_step * samplerate )
  for spl = 1, numsamplesperchannel-rms_step_spls, rms_step_spls do
    local rms = 0
    i = i + 1
    for i2 = spl, spl + rms_step_spls do
      rms = rms + math.abs(samplebuffer[i2])
    end
    rms = rms / rms_step_spls
    t[i] = {  pos_offset = spl / samplerate,
              rms = rms
            }
  end
  samplebuffer.clear()
  DestroyAudioAccessor( accessor )
  

  return t
end
------------------------------------------------------------------------------------------------------  
function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
------------------------------------------------------------------------------------------------------  
function get_thresholdboundary(threshold_dB, t)
  local threshold = WDL_DB2VAL(threshold_dB)
  
  local sz = #t
  local center = math.floor(sz/2)
  local min_offs, max_offs
  
  -- get minimum
  for i = center, 1, -1 do
    if t[i].rms < threshold then
      min_offs = t[i].pos_offset
      break
    end
  end
  -- get max
  for i = center, sz do
    if t[i].rms < threshold then
      max_offs = t[i].pos_offset
      break
    end
  end  
  
  return min_offs, max_offs
end
------------------------------------------------------------------------------------------------------  
  function main()
    DATA.valid = false
    
    local mousepos = VF_GetPositionUnderMouseCursor() 
    local item , take = VF_GetItemTakeUnderMouseCursor() 
    if not (item and take and mousepos) then return end
    local env = init_takeenv(take)
    if not env then return end 
    DATA.env = env
    
    DATA.envmode = GetEnvelopeScalingMode( env )
    local itpos = GetMediaItemInfo_Value( item, 'D_POSITION' ) 
    local starttime_sec = mousepos - analyze_time/2
    --retval, stringNeedBig = reaper.GetSetEnvelopeInfo_String( env, 'ACTIVE', '0', true )
    if hideenv then retval, stringNeedBig = reaper.GetSetEnvelopeInfo_String( env, 'VISIBLE', '0', true ) end
    local t = get_audiodata(take, mousepos, analyze_time, starttime_sec)
    --retval, stringNeedBig = reaper.GetSetEnvelopeInfo_String( env, 'ACTIVE', '1', true )
    if not t then return end 
    min_offs, max_offs = get_thresholdboundary(threshold_dB,t)
    if not (min_offs and max_offs) then return end
    if max_offs - min_offs < 0.1 then return end
    
    DATA.startsegm=starttime_sec-itpos+min_offs
    DATA.endsegm=starttime_sec-itpos+max_offs
    DATA.valid = true
    
  end 
  main()
  
  
  
  
  package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  local ImGui = require 'imgui' '0.9.3'
  local ctx = ImGui.CreateContext('My script')
  ctx_font = ImGui.CreateFont('Arial', 16) ImGui.Attach(ctx, ctx_font)
  local function loop()
    size_w, size_h = 50, 200
    pos_x, pos_y = reaper.GetMousePosition()
    reaper.ImGui_SetNextWindowSize( ctx, size_w, size_h, reaper.ImGui_Cond_Appearing() )
    reaper.ImGui_SetNextWindowPos( ctx, pos_x-size_w/2, pos_y-size_h/2, reaper.ImGui_Cond_Appearing(), 0,0 )
    window_flags = 
      reaper.ImGui_WindowFlags_NoScrollbar()|
      reaper.ImGui_WindowFlags_NoDecoration()
      
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,5)   
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding,3)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,10) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,20)
    ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,0x1F)
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,  0x0000005F )
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive,  0x000000FF )
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0xFFFFFF0F)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0xFFFFFF0F)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0xFFFFFF0F)
    
    ImGui.PushFont(ctx, ctx_font) 
    
    local visible, open = ImGui.Begin(ctx, 'My window', true, window_flags) 
    if visible then
      
      if DATA.valid then 
      
        local retval, v = reaper.ImGui_VSliderDouble( ctx, '##sl', size_w, size_h,DATA.val, 0, 1.5,  '%.2f' , reaper.ImGui_SliderFlags_None() )
        if retval then 
          DATA.val = v
          local retval, startsegm_value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( DATA.env, DATA.startsegm, DATA.SR, 1 )
          local retval, endsegm_value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( DATA.env, DATA.endsegm, DATA.SR, 1 ) 
          reaper.DeleteEnvelopePointRange( DATA.env, DATA.startsegm-0.001, DATA.endsegm+0.001 )
          reaper.InsertEnvelopePoint(  DATA.env, DATA.startsegm, startsegm_value, 0, 0, 0, false )
          reaper.InsertEnvelopePoint(  DATA.env, DATA.endsegm, endsegm_value, 0, 0, 0, false )
          
          
          reaper.InsertEnvelopePoint(  DATA.env, DATA.startsegm + time_fade, startsegm_value*DATA.val, 0, 0, 0, false )
          reaper.InsertEnvelopePoint(  DATA.env, DATA.endsegm - time_fade, endsegm_value*DATA.val, 0, 0, 0, false )
          
        end
        if reaper.ImGui_IsItemDeactivated( ctx ) then
          trig_close = true
        end
      end
      
      
      ImGui.End(ctx)
    end
    ImGui.PopStyleVar(ctx, 5)
    ImGui.PopStyleColor(ctx, 6)
    
    ImGui.PopFont(ctx) 
    
    if open and not trig_close then reaper.defer(loop) end
  end
  
  if DATA.valid then
    reaper.defer(loop)
  end
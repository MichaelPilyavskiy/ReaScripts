-- @description Peak follower tools
-- @version 1.10
-- @author MPL
-- @about Generate envelope from audio data
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Gate: add invert check
--    + Gate: add hold control


    
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.10
    DATA.extstate.extstatesection = 'PeakFollowTools'
    DATA.extstate.mb_title = 'Peak follower tools'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  400,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          FPRESET1= 'CkNPTkZfRkZUX21heD0wLjQ3ODY2NjY2NjY2NjY3CkNPTkZfRkZUX21pbj0wLjM4MDU0MTY2NjY2NjY3CkNPTkZfRkZUc3o9MTAyNApDT05GX05BTUU9W2ZhY3RvcnldIGRlLWVzc2VyCkNPTkZfYm91bmRhcnk9MApDT05GX2J5cGFzcz0wCkNPTkZfY29tcF9SYXRpbz0yCkNPTkZfY29tcF9hdHRhY2s9MApDT05GX2NvbXBfa25lZT0wCkNPTkZfY29tcF9sb29rYWhlYWQ9MApDT05GX2NvbXBfcmVsZWFzZT0wLjEKQ09ORl9jb21wX3RocmVzaG9sZD0wLjkyMwpDT05GX2Rlc3Q9MQpDT05GX2dhdGVfdGhyZXNob2xkPTAuNTM4CkNPTkZfbW9kZT0wCkNPTkZfbm9ybWFsaXplPTAKQ09ORl9vZmZzZXQ9MApDT05GX291dF9pbnZlcnQ9MQpDT05GX291dF9vZmZzPS0wLjAyCkNPTkZfb3V0X3NjYWxlPTAuMDgKQ09ORl9yZWR1Y2VzYW1ldmFsdWVzPTEKQ09ORl9yZWR1Y2VzYW1ldmFsdWVzX21pbmRpZmY9MC4xCkNPTkZfcmVtb3ZldGtlbnZ2b2w9MQpDT05GX3NjYWxlPTMuNQpDT05GX3Ntb290aGJsb2NrPTE1CkNPTkZfd2luZG93PTAuMDEyCkNPTkZfd2luZG93b3ZlcmxhcD02CkNPTkZfemVyb2JvdW5kYXJ5PTE=',
                          FPRESET2= 'CkNPTkZfRkZUX21heD0xCkNPTkZfRkZUX21pbj0wCkNPTkZfRkZUc3o9LTEKQ09ORl9OQU1FPXNsb3cgY29tcHJlc3Npb24tMTVkQgpDT05GX2JvdW5kYXJ5PTAKQ09ORl9ieXBhc3M9MApDT05GX2NvbXBfUmF0aW89NS4xMTExMTExMTExMTExCkNPTkZfY29tcF9hdHRhY2s9MC4xNDg2MTExMTExMTExMQpDT05GX2NvbXBfa25lZT0wCkNPTkZfY29tcF9sb29rYWhlYWQ9MApDT05GX2NvbXBfcmVsZWFzZT0wLjkxOTQ0NDQ0NDQ0NDQ0CkNPTkZfY29tcF90aHJlc2hvbGQ9MC43MzEzMzMzMzMzMzMzNApDT05GX2Rlc3Q9MQpDT05GX2dhdGVfdGhyZXNob2xkPTAuNTM4CkNPTkZfbW9kZT0yCkNPTkZfbm9ybWFsaXplPTAKQ09ORl9vZmZzZXQ9MApDT05GX291dF9pbnZlcnQ9MApDT05GX291dF9vZmZzPTAKQ09ORl9vdXRfc2NhbGU9MQpDT05GX3JlZHVjZXNhbWV2YWx1ZXM9MQpDT05GX3JlZHVjZXNhbWV2YWx1ZXNfbWluZGlmZj0wLjEKQ09ORl9yZW1vdmV0a2VudnZvbD0xCkNPTkZfc2NhbGU9MQpDT05GX3Ntb290aGJsb2NrPTEKQ09ORl93aW5kb3c9MC4wNTY0ODMzMzMzMzMzMzMKQ09ORl93aW5kb3dvdmVybGFwPTEKQ09ORl96ZXJvYm91bmRhcnk9MQ==',
                          -- mode
                          CONF_bypass = 0,
                          CONF_mode = 0, -- 0 peak follower 1 gate 2 compressor 3 fft deessed 4 rms peak difference
                          CONF_boundary = 0, -- 0 item edges 1 time selection
                          
                          -- audio data
                          CONF_removetkenvvol = 1, -- remove take vol
                          CONF_window = 0.02,
                          CONF_windowoverlap = 1,
                          CONF_FFTsz = -1,
                          CONF_FFT_min = 0,
                          CONF_FFT_max = 1,
                          CONF_normalize = 0,
                          CONF_scale = 1,
                          CONF_offset = 0,
                          CONF_smoothblock = 1,
                          
                          
                          -- gate
                          CONF_gate_threshold = 0.538,
                          CONF_gate_inv=0,
                          CONF_gate_hold = 0,
                          
                          -- comp
                          CONF_comp_threshold = 0.923, -- linear
                          CONF_comp_attack = 0, -- s
                          CONF_comp_release = 0.1, -- s
                          CONF_comp_Ratio = 2, -- 1:2 to 1:20, >20 == inf
                          CONF_comp_knee = 0,-- 0...20db
                          CONF_comp_lookahead = 0,--  s
                          
                          -- dest
                          CONF_dest = 1, -- 0 AI track vol 1 take vol env
                          
                          -- output
                          CONF_reducesamevalues = 1, -- do not add point if previous point has same value
                          CONF_reducesamevalues_mindiff = 0.1, -- db
                          CONF_zeroboundary = 1, -- zero reset for boundaries
                          CONF_out_invert = 0, 
                          CONF_out_scale = 1, 
                          CONF_out_offs = 0, 
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          UI_processoninit = 0,
                          
                          }
                          
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets()  
    if DATA.extstate.UI_initatmouse&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    
    if DATA.extstate.UI_processoninit == 1 then
      DATA2:Process()
    end
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    --DATA.GUI.default_scale = 2
    
    -- init main stuff
      DATA.GUI.custom_mainbuth = 30*DATA.GUI.default_scale
      DATA.GUI.custom_texthdef = 23
      DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
      DATA.GUI.custom_mainsepx = gfx.w/DATA.GUI.default_scale--(gfx.w/DATA.GUI.default_scale)*0.4-- *DATA.GUI.default_scale--400*DATA.GUI.default_scale--
      DATA.GUI.custom_mainbutw = 0.5*(gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*3) --(gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*3
      DATA.GUI.custom_scrollw = 10
      DATA.GUI.custom_frameascroll = 0.05
      DATA.GUI.custom_default_framea_normal = 0.1
      DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
      DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset*3) 
    
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
    -- buttons
      DATA.GUI.buttons = {} 
      DATA.GUI.buttons.app = {  x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Generate',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              Undo_BeginBlock()
                                              DATA2:Process()
                                              Undo_EndBlock( DATA.extstate.mb_title..' - process', 0 )
                                            end} 
      DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbutw,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_short = (DATA.extstate.CONF_NAME or '[untitled]'),
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA:GUIbut_preset() end}                                             
                       
      DATA.GUI.buttons.Rsettings = { x=gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx,
                            y=DATA.GUI.custom_mainbuth + DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainsepx,
                            h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth - DATA.GUI.custom_offset,
                            txt = 'Settings',
                            --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            frame_a = 0,
                            offsetframe = DATA.GUI.custom_offset,
                            offsetframe_a = 0.1,
                            ignoremouse = true,
                            }
      DATA:GUIBuildSettings()
      
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end
  ---------------------------------------------------------------------------------------------------------------------  
  function DATA2:GetEditAIbyEdges(env, AIpos, AIend)  
    local qerr = 0.1
    for AI_idx = 1, CountAutomationItems( env ) do
      local pos = GetSetAutomationItemInfo( env, AI_idx-1, 'D_POSITION', 0, 0 )
      local len = GetSetAutomationItemInfo( env, AI_idx-1, 'D_LENGTH', 0, 0 )
      if (pos > AIpos-qerr and pos < AIend+qerr ) 
          or (pos+len > AIpos-qerr and pos+len < AIend+qerr ) 
          or (pos < AIpos-qerr and pos+len > AIend+qerr )  
       then
        GetSetAutomationItemInfo( env, AI_idx-1, 'D_POSITION', AIpos, 1 )
        GetSetAutomationItemInfo( env, AI_idx-1, 'D_LENGTH', AIend-AIpos, 1 )
        GetSetAutomationItemInfo( env, AI_idx-1, 'D_POOL_QNLEN',  TimeMap_timeToQN_abs( 0, AIend )-TimeMap_timeToQN_abs( 0, AIpos ), 1 ) 
        return AI_idx-1
      end
    end
  end
  ---------------------------------------------------------------------------------------------------------------------  
  function DATA2:Process_GenerateAI(item) 
    
    -- get boundary
      local ret, boundary_start, boundary_end, i_pos = DATA2:Process_GetBoundary(item)
      if not ret then return end
      
    -- destination
      local env
      local AI_idx = -1
      if DATA.extstate.CONF_dest == 0 then -- track vol AI
        local track = GetMediaItem_Track(item)
        env =  GetTrackEnvelopeByName( track, 'Volume' )
        if not ValidatePtr2( 0, env, 'TrackEnvelope*' ) then 
          SetOnlyTrackSelected(track)
          Main_OnCommand(40406,0) -- show vol envelope
          env =  GetTrackEnvelopeByName( track, 'Volume' )
        end
        AI_idx = DATA2:GetEditAIbyEdges(env, boundary_start, boundary_end)  
        if not AI_idx then AI_idx = InsertAutomationItem( env, -1, boundary_start, boundary_end-boundary_start )end
      end
      -- take env
      if DATA.extstate.CONF_dest == 1 then 
        local take = GetActiveTake(item)
        if not take then return end
        for envidx = 1,  CountTakeEnvelopes( take ) do local tkenv = GetTakeEnvelope( take, envidx-1 ) local retval, envname = reaper.GetEnvelopeName(tkenv ) if envname == 'Volume' then env = tkenv break end end
        if not ValidatePtr2( 0, env, 'TrackEnvelope*' ) then 
          VF_Action(40693) -- Take: Toggle take volume envelope 
          for envidx = 1,  CountTakeEnvelopes( take ) do 
            local tkenv = GetTakeEnvelope( take, envidx-1 ) 
            local retval, envname = reaper.GetEnvelopeName(tkenv ) 
            if envname == 'Volume' then env = tkenv break end 
          end 
        end
      end
            
            
    -- apply points
      if not env then return end
      --local cntpts = CountEnvelopePointsEx( env, AI_idx )
      --DeleteEnvelopePointEx( env, AI_idx,  cntpts )
      --Envelope_SortPointsEx( env, AI_idx )
      
      
      return true, env, AI_idx
  end
  -------------------------------------------------------------------
  function DATA2:Process_GetBoundary(item)
    local i_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local i_len = GetMediaItemInfo_Value( item, 'D_LENGTH' ) 
    local boundary_start = i_pos
    local boundary_end = i_pos + i_len
    if DATA.extstate.CONF_boundary == 1 then
      local tsstart, tsend = GetSet_LoopTimeRange2( 0, false, 0, 0, 0, 0 )
      if tsend - tsstart < 0.1 then return end
      boundary_start = tsstart
      boundary_end = tsend
    end
    return true, boundary_start, boundary_end, i_pos
  end
  -------------------------------------------------------------------  
  function DATA2:Process_GetAudioData(item)
    local window_sec = DATA.extstate.CONF_window
    
    -- init 
      if not (item and window_sec) then return end  
      local take =  reaper.GetActiveTake( item )
      if TakeIsMIDI( take ) then return end  
      
      if DATA.extstate.CONF_removetkenvvol == 1 then
        local env = reaper.GetTakeEnvelopeByName(take, 'Volume')
        if env then
          reaper.DeleteEnvelopePointRange( env, 0, math.huge )
          reaper.Envelope_SortPoints( env )
        end
      end
      
      local track = GetMediaItem_Track(item)
      local accessor = CreateTrackAudioAccessor( track ) 
      local id = 0
      local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      local bufsz = math.ceil(window_sec * SR_spls)
      local data = {}
      
      local ret, boundary_start, boundary_end = DATA2:Process_GetBoundary(item)
      if not ret then return end
      
    -- compressor 
      if DATA.extstate.CONF_mode==2 then -- compressor/deeeser
        local bufsz = SR_spls
        for pos = boundary_start, boundary_end, 1 do 
          local samplebuffer = new_array(bufsz);
          GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
          for i = 1, bufsz do data[id+i] = samplebuffer[i] end
          id=id+bufsz
          samplebuffer.clear()
        end
        reaper.DestroyAudioAccessor( accessor )
        return data
      end
      
      
    -- peak follower in RMS mode
      if DATA.extstate.CONF_FFTsz==-1 then 
        for pos = boundary_start, boundary_end, window_sec/DATA.extstate.CONF_windowoverlap do 
          local samplebuffer = new_array(bufsz);
          GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
          local sum = 0 
          for i = 1, bufsz do 
            local val = math.abs(samplebuffer[i]) 
            sum = sum + val 
          end 
          samplebuffer.clear()
          id = id + 1
          data[id] = sum / bufsz -- get RMS
        end
        reaper.DestroyAudioAccessor( accessor )
      end

      -- peak follower in FFT mode
      if DATA.extstate.CONF_FFTsz~=-1 then 
        local fftsz = DATA.extstate.CONF_FFTsz
        local bufsz = fftsz *2
        --local window_sec = fftsz / SR_spls
        for pos = boundary_start, boundary_end, window_sec/DATA.extstate.CONF_windowoverlap do 
          local samplebuffer = new_array(bufsz);
          GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
          samplebuffer.fft_real(fftsz, true)
          local sum = 0 
          local cnt = 0
          local fftst = math.max(1,math.ceil(DATA.extstate.CONF_FFT_min*fftsz))
          local fftend = math.floor(DATA.extstate.CONF_FFT_max*fftsz)
          for i = fftst, fftend do 
            local val = math.abs(samplebuffer[i]) 
            sum = sum + val 
          end 
          samplebuffer.clear()
          id = id + 1
          data[id] = sum / (fftend-fftst)
        end
        reaper.DestroyAudioAccessor( accessor )
      end
      
      if DATA.extstate.CONF_normalize ==1 then
        local max_val = 0
        for i = 1, #data do max_val = math.max(max_val, data[i]) end -- abs all values 
        for i = 1, #data do data[i] = (data[i]/max_val) end -- normalize 
      end
      
      for i = 1, #data do data[i] = data[i]^DATA.extstate.CONF_scale + DATA.extstate.CONF_offset end
      local block =DATA.extstate.CONF_smoothblock
      if block > 1 then
        local data0 = CopyTable(data)
        for i = block+1, #data do 
          avg = 0
          for j = i-block, i do avg = avg + data0[j] end
          data[i] = avg /block
        end
      end
      
    return data
  end
  -------------------------------------------------------------------
  function DATA2:Process_InsertData_Gate(t, boundary_start, boundary_end, offs, env, AI_idx) 
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    local scaling_mode = GetEnvelopeScalingMode( env )
    local gateDb = (math.floor(SLIDER2DB((DATA.extstate.CONF_gate_threshold*1000))*10)/10)
    local output = {}
    local window_sec = DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap
    --if DATA.extstate.CONF_FFTsz~=-1 then  window_sec = DATA.extstate.CONF_FFTsz / SR_spls end 
    local gate_on,last_gate_on
    for i = 1, #t do   
      local tpos = (i-1)*window_sec+boundary_start-offs 
      local val = ScaleToEnvelopeMode( scaling_mode, t[i] ) 
      local valdB = SLIDER2DB(val)
      if valdB > gateDb then 
        setval = 1 
        gate_on = i
       else 
        setval = 0 
      end
      
      if DATA.extstate.CONF_gate_hold > 0 then
        if setval == 0 and gate_on and i-gate_on< DATA.extstate.CONF_gate_hold then setval = 1 end
      end
      
      last_gate_on = gate_on
      if DATA.extstate.CONF_gate_inv == 1 then setval = 1- setval end
      output[#output+1] = {tpos=tpos,val=setval}
        
    end
    return output
  end
  -------------------------------------------------------------------
  function DATA2:Process_InsertData_PF(t, boundary_start, boundary_end, offs, env, AI_idx)
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    local scaling_mode = GetEnvelopeScalingMode( env )
    local output = {}
    local val_norm
    local window_sec = DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap
    --if DATA.extstate.CONF_FFTsz~=-1 then  window_sec = DATA.extstate.CONF_FFTsz / SR_spls end 
    for i = #t-1,1,-1 do  
      local tpos = (i-1)*window_sec+boundary_start-offs
      output[#output+1] = {tpos=tpos,val=t[i]}
    end 
    return output
  end  
  -------------------------------------------------------------------
  function DATA2:Process_InsertData_Compressor(t, boundary_start, boundary_end, offs, env, AI_idx)
    -- init functions
    local dbc = 20/math.log(10);
    function int(x) return x|0 end;
    function db2ratio(d) return math.exp(math.log(10)/20*d) end; 
    function ratio2db(r) return math.log(math.abs(r))*dbc end
    function spline2(mu,dv1,dv2) return mu*dv1 + mu*mu*0.5*(dv2-dv1); end
    function derivative (mu, dv1, dv2) return dv1 + mu * (dv2 - dv1); end
    
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    local scaling_mode = GetEnvelopeScalingMode( env )
    local threshold_db = (math.floor(SLIDER2DB((DATA.extstate.CONF_comp_threshold*1000))*10)/10)
    local thresh_r = db2ratio(threshold_db);
    local att_ms = math.floor(DATA.extstate.CONF_comp_attack*1000)
    local rel_ms = math.floor(DATA.extstate.CONF_comp_release*1000)
    local lookahead_ms =DATA.extstate.CONF_comp_lookahead
    local Grelease = math.exp(-3/(rel_ms / 1000 * SR_spls));
    local Girelease = 1-Grelease;
    local ratio = DATA.extstate.CONF_comp_Ratio
    local iratio if ratio > 40 then iratio = 0 else iratio = 1 / ratio end
    local knee = DATA.extstate.CONF_comp_knee
    local rms_ms = DATA.extstate.CONF_window*1000
    local RMScoeff = math.exp(-1/(rms_ms / 1000 * SR_spls));
    local RMSicoeff = 1-RMScoeff;
    local kneeL = threshold_db - knee/2;
    local kneeR = threshold_db + knee/2;
    
    --[[
    desc:LT_Comp
    A ReaComp "clone" hacked together by ashcat_lt
    mostly from SaulT's code
    ]]
    
    -- methods
      local innitvar= {} 
      function innitvar:new()
        local obj= {}
        setmetatable(obj, self)
        self.__index = self; return obj
      end 
      function innitvar:attack_set(att_ms)
        self.attack = math.exp(-3/(att_ms / 1000 * SR_spls));
        self.iattack = 1-self.attack;
      end
      function innitvar:RMS(input)
        self.rms_s = ((self.rms_s or 0) * RMScoeff) + (RMSicoeff * input);
        return math.sqrt(self.rms_s);
      end 
      function innitvar:att_rel(input)
        if attacking == 1 then
          self.coeff = self.attack;
          self.icoeff = self.iattack;
         else
          self.coeff = Grelease;
          self.icoeff = Girelease;
        end
        self.output = ((self.output or 0 ) * self.coeff) + (self.icoeff * input);
        return self.output
      end
      function innitvar:process(input)
        in0 = ratio2db(input);
        if in0 <= kneeL then self.out = in0 end
        if in0 >= kneeR then self.out = threshold_db + (in0 -threshold_db) * iratio end
        if in0 > kneeL and in0 < kneeR then
          self.mu = (in0 - kneeL)/knee;  
          self.out = kneeL + spline2(self.mu,1,iratio)*knee;
        end
        if self.out then 
          diff = self.out - in0;
          return db2ratio(diff)
        end
      end
    
    
    -- init table values
      att_rel0 = innitvar:new()
      att_rel0:attack_set(att_ms); 
      process0 =  innitvar:new()
    
    -- compressor
      local gain_t = {}
      tsz = #t
      local rms_out0 = 0
      for i = 1, tsz do
        main_inputL = t[i]; 
        rms_in = main_inputL;
        rms_out0 = (rms_out0 * RMScoeff) + (RMSicoeff * math.abs(rms_in))
        rms_out =  math.sqrt(rms_out0); 
        if math.abs(rms_out) >= thresh_r then attacking = 1 else attacking =0 end 
        ar_out = att_rel0:att_rel (rms_out); 
        proc_gain = process0:process(ar_out);
        if not proc_gain then proc_gain = 1 end
        proc_outputL = main_inputL*proc_gain; 
        spl0 = proc_outputL;
        gain_t[i] = proc_gain
      end
     
    -- add points
      
      --wind_spls = 1
      local wind_spls = math.ceil(DATA.extstate.CONF_window/2 * SR_spls) 
      local output = {}
      local spl_time = 1/SR_spls
      for i = 1, tsz, wind_spls do  
        local val = ScaleToEnvelopeMode( scaling_mode, gain_t[i] ) 
        tpos = boundary_start + i*spl_time-offs+lookahead_ms
        if tpos > 0 then --and val >= 0 and val <= 1000 then
          output[#output+1] = {tpos=tpos,val=VF_lim(gain_t[i])}
        end
      end
      
      
    return output
  end  
  -------------------------------------------------------------------
  function DATA2:Process_InsertData_reduceSameVal(output)
    local sz = #output  
    -- reduce pts with same values
      if DATA.extstate.CONF_reducesamevalues == 1 then
        local last_val = 0
        local trigval
        for i = 1, sz-1 do  
          local val = output[i].val
          local valnext = output[i+1].val
          if last_val == val and valnext == val then output[i].ignore = true end 
          last_val = val
        end
      end
  end
  -------------------------------------------------------------------
  function DATA2:Process_InsertData(item, env, AI_idx, t)
    local scaling_mode = GetEnvelopeScalingMode( env )
    
    -- get boundary
      local ret, boundary_start, boundary_end, i_pos = DATA2:Process_GetBoundary(item)
      if not ret then return end
      
    -- init vars
      
      local offs = 0 if DATA.extstate.CONF_dest == 1 then  offs = i_pos end -- compensate points for AI
    
    -- clear
      DeleteEnvelopePointRangeEx( env, AI_idx, boundary_start-offs, boundary_end-offs )  
      
    -- do window shift
      local wind_offs = 0--window_ms
      
    -- get output points
      local output = {}
      if DATA.extstate.CONF_mode ==0 or DATA.extstate.CONF_mode == 4 then output = DATA2:Process_InsertData_PF(t, boundary_start, boundary_end, offs, env, AI_idx) end -- peak follow 
      if DATA.extstate.CONF_mode ==1 then output = DATA2:Process_InsertData_Gate(t,  boundary_start, boundary_end, offs, env, AI_idx) end-- gate
      if DATA.extstate.CONF_mode ==2 then output = DATA2:Process_InsertData_Compressor(t,  boundary_start, boundary_end, offs, env, AI_idx) end-- gate 
      if DATA.extstate.CONF_bypass == 1 then output = nil end
       
    -- add points
      if output then 
        DATA2:Process_InsertData_reduceSameVal(output)
        local valout
        local sz = #output  
        for i = 1, sz do if output[i] and (not output[i].ignore or output[i].ignore==false) then 
          valout = VF_lim(output[i].val*DATA.extstate.CONF_out_scale - DATA.extstate.CONF_out_offs)
          local valout = ScaleToEnvelopeMode( scaling_mode, valout) 
          if DATA.extstate.CONF_out_invert ==1 then valout = 1000- valout end
          InsertEnvelopePointEx( env, AI_idx, output[i].tpos, valout, 0, 0, 0, true ) 
        end end 
        Envelope_SortPointsEx( env, AI_idx ) 
      end
      
      
    -- boundary
      if DATA.extstate.CONF_zeroboundary == 1 then
        local ptidx = GetEnvelopePointByTimeEx(env, AI_idx, #t*DATA.extstate.CONF_window+boundary_start-offs )
        if ptidx then
          local retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, AI_idx, ptidx )
          reaper.SetEnvelopePointEx(  env, AI_idx, ptidx, time,     ScaleToEnvelopeMode( scaling_mode, 1 ) , shape, tension, selected, true )
        end
      end
      
    -- sort 2nd pass
      Envelope_SortPointsEx( env, AI_idx ) 
  end
  ----------------------------------------------------------------------
  function DATA2:Process()
  
    if DATA.extstate.CONF_mode==0 
      or DATA.extstate.CONF_mode==1
      or DATA.extstate.CONF_mode==2
     then
      for i = 1,  CountSelectedMediaItems( 0 ) do
        local item = GetSelectedMediaItem(0,i-1)
        local t0 = DATA2:Process_GetAudioData(item)
        local ret, env, AI_idx =  DATA2:Process_GenerateAI(item)
        if ret then DATA2:Process_InsertData(item, env, AI_idx, t0) end
      end  
    end
    
    if DATA.extstate.CONF_mode==4 then
      local audio = {}
      if CountSelectedMediaItems( 0 ) == 2 then
        local item1 = GetSelectedMediaItem(0,0)
        local item2 = GetSelectedMediaItem(0,1)
        local t0 = DATA2:Process_GetAudioData(item1)
        local t1 = DATA2:Process_GetAudioData(item2)
         tdiff = {}
        local min = math.huge
        for i = 1, #t0 do 
          if t0[i] and  t1[i]  then
            tdiff[i] = t0[i] - t1[i] 
            min = math.min(min, tdiff[i] )
          end
        end
        for i = 1, #tdiff do tdiff[i] = tdiff[i] - min end
        local ret, env, AI_idx =  DATA2:Process_GenerateAI(item2)
        if ret then DATA2:Process_InsertData(item2, env, AI_idx, tdiff) end
      end  
    end
    
  end
  ----------------------------------------------------------------------
  function DATA2:ProcessAtChange(DATA)
    if DATA.extstate.UI_appatchange&1==1 then DATA2:Process() end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 200
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset

    local  t = 
    { 
      {str = 'Global' ,                       group = 1, itype = 'sep'}, 
        {str = 'Bypass',                      group = 1, itype = 'check', confkey = 'CONF_bypass', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Mode' ,                       group = 1, itype = 'readout', level = 1,  confkey = 'CONF_mode', menu = { 
          [0]='Peak follower', 
          [1]='Gate', 
          [2] = 'Compressor (by ashcat_lt & SaulT)',
          [4] = 'Peak fol. difference', 
          --[3] = 'Deesser (by Liteon)', 
          },readoutw_extw=readoutw_extw, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Boundaries' ,                 group = 1, itype = 'readout', level = 1,  confkey = 'CONF_boundary', menu = { [0]='Item edges', [1]='Time selection'},readoutw_extw=readoutw_extw, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
      {str = 'Audio data reader' ,            group = 3, itype = 'sep'},
        {str = 'Clear take volume envelope before' ,             group = 3, itype = 'check', confkey = 'CONF_removetkenvvol', level = 1}, 
        {str = 'FFT size' ,                   group = 3, itype = 'readout', level = 1,  confkey = 'CONF_FFTsz', func_onrelease = function() DATA2:ProcessAtChange(DATA) end, menu = { 
          [-1]='[disabled]', 
          [1024]='1024', 
          [2048] ='2048'},
          hide=DATA.extstate.CONF_mode==2
        },
        {str = 'FFT min freq' ,                 group = 3, itype = 'readout', confkey = 'CONF_FFT_min', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return math.floor(x*SR_spls/2)..'Hz' end, 
          val_format_rev = function(x) return VF_lim(x/(SR_spls/2),0,SR_spls) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_FFTsz==-1 or  DATA.extstate.CONF_mode==2
          }, 
        {str = 'FFT max freq' ,                 group = 3, itype = 'readout', confkey = 'CONF_FFT_max', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return math.floor(x*SR_spls/2)..'Hz' end, 
          val_format_rev = function(x) return VF_lim(x/(SR_spls/2),0,SR_spls) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_FFTsz==-1 or  DATA.extstate.CONF_mode==2
          },        
        {str = 'RMS Window' ,                 group = 3, itype = 'readout', confkey = 'CONF_window', level = 1, 
          val_min = 0.001, 
          val_max = 0.4, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(x*1000)/1000)..'s' end, 
          val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_mode==2,--  or DATA.extstate.CONF_FFTsz~=-1
          },
       {str = 'Window overlap' ,                 group = 3, itype = 'readout', confkey = 'CONF_windowoverlap', level = 1, val_isinteger = true,
         val_min = 1, 
         val_max = 16, 
         val_res = 0.05, 
         val_format = function(x) return x..'x' end, 
         val_format_rev = function(x) return VF_lim(math.floor(tonumber(x) or 1), 1,16) end, 
         func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
         hide=DATA.extstate.CONF_mode==2,--  or DATA.extstate.CONF_FFTsz~=-1
         },         
          
        {str = 'Normalize envelope' ,          group = 3, itype = 'check', confkey = 'CONF_normalize', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2,}, 
        {str = 'Scale envelope x^[0.5...4]' ,              group = 3, itype = 'readout', val_min = 0.5, val_max = 4, val_res = 0.05, confkey = 'CONF_scale', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2,
          val_format = function(x) return math.floor(x*1000)/1000 end, 
          val_format_rev = function(x) return tonumber(x) end, }, 
        {str = 'Offset' ,              group = 3, itype = 'readout', val_min = -1, val_max = 1, val_res = 0.05, confkey = 'CONF_offset', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2,
          val_format = function(x) return math.floor(x*1000)/1000 end, 
          val_format_rev = function(x) return tonumber(x) end, },    
        {str = 'Smooth' ,              group = 3, itype = 'readout', val_min = 1, val_max = 15, val_res = 0.05, confkey = 'CONF_smoothblock', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode==2, val_isinteger = true,
          val_format = function(x) return (math.floor(1000*x*DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap)/1000)..'s' end, 
          val_format_rev = function(x) return math.floor(tonumber(x/(DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap))) end, },             
  
                    
          
      {str = 'Mode parameters' ,     group = 2, itype = 'sep'},
      
        -- gate 
        {str = 'Threshold' ,             group = 2, itype = 'readout', confkey = 'CONF_gate_threshold', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(SLIDER2DB((x*1000))*10)/10)..'dB' end, 
          val_format_rev = function(x) return VF_lim(DB2SLIDER(x)/1000, 0,1000) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=1},
        {str = 'Invert' ,             group = 2, itype = 'check', confkey = 'CONF_gate_inv', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode~=1},          
        {str = 'Hold' ,              group = 3, itype = 'readout', val_min = 1, val_max = 40, val_res = 0.05, confkey = 'CONF_gate_hold', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide=DATA.extstate.CONF_mode~=1, val_isinteger = true,
          val_format = function(x) return (math.floor(1000*x*DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap)/1000)..'s' end, 
          val_format_rev = function(x) return math.floor(tonumber(x/(DATA.extstate.CONF_window/DATA.extstate.CONF_windowoverlap))) end, },  
          
          
        -- compressor
        {str = 'Threshold' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_threshold', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(SLIDER2DB((x*1000))*10)/10)..'dB' end, 
          val_format_rev = function(x) return VF_lim(DB2SLIDER(x)/1000, 0,1000) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},   
        {str = 'Lookahead / delay' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_lookahead', level = 1, 
          val_res = 0.05, 
          val_min = -0.05,
          val_max = 0.05,
          val_format = function(x) return (math.floor(x*10000)/10)..'ms' end, 
          val_format_rev = function(x) return VF_lim((tonumber(x) or 0)/1000, -0.05,0.05) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},           
        {str = 'Attack' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_attack', level = 1, 
          val_res = 0.05, 
          val_min = 0,
          val_max = 0.5,
          val_format = function(x) return (math.floor(x*10000)/10)..'ms' end, 
          val_format_rev = function(x) return VF_lim((tonumber(x) or 0), 0,500)/1000 end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},             
        {str = 'Release' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_release', level = 1, 
          val_res = 0.05, 
          val_min = 0,
          val_max = 5,
          val_format = function(x) return (math.floor(x*10000)/10)..'ms' end, 
          val_format_rev = function(x) return VF_lim((tonumber(x) or 0), 0,500)/1000 end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},             
        {str = 'Ratio' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_Ratio', level = 1, 
          val_res = 0.05, 
          val_min = 1,
          val_max = 41,
          val_format = function(x) if x == 41 then return '-inf' else return (math.floor(x*10)/10)..' : 1' end end ,
          val_format_rev = function(x) 
            local y= x:match('[%d%.]+')
            if not y then return 2 end
            y = tonumber(y)
            if y then return VF_lim(y, 1,21) end 
          end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},            
        {str = 'Knee' ,             group = 2, itype = 'readout', confkey = 'CONF_comp_knee', level = 1, 
          val_res = 0.05, 
          val_min = 0,
          val_max = 20,
          val_format = function(x) return (math.floor(x*10)/10)..'dB' end, 
          val_format_rev = function(x) return VF_lim(      math.floor((tonumber(x) or 0)*10)/10      , 0,20) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=2},        
        {str = 'RMS Window' ,                 group = 3, itype = 'readout', confkey = 'CONF_window', level = 1, 
          val_min = 0.002, 
          val_max = 0.4, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(x*1000))..'ms' end, 
          val_format_rev = function(x) return tonumber(x:match('[%d%.]+')/1000) end,
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          hide=DATA.extstate.CONF_mode~=2
          },          
          
          
      {str = 'Destination' ,                    group = 4, itype = 'sep'},
        {str = 'Track volume env AI' ,          group = 4, itype = 'check', confkey = 'CONF_dest', level = 1, isset = 0, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Take volume env' ,              group = 4, itype = 'check', confkey = 'CONF_dest', level = 1, isset = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
      {str = 'Output' ,                         group = 6, itype = 'sep'},
        {str = 'Reduce points with same values',group = 6, itype = 'check', confkey = 'CONF_reducesamevalues', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Invert points',                 group = 6, itype = 'check', confkey = 'CONF_out_invert', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Scale x*[0...1]' ,              group = 3, itype = 'readout', val_min = 0, val_max = 1, val_res = 0.05, confkey = 'CONF_out_scale', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
            val_format = function(x) return math.floor(x*1000)/1000 end, 
            val_format_rev = function(x) return tonumber(x) end, },    
        {str = 'Offset' ,              group = 3, itype = 'readout', val_min = -1, val_max = 1, val_res = 0.05, confkey = 'CONF_out_offs', level = 1,func_onrelease = function() DATA2:ProcessAtChange(DATA) end,
          val_format = function(x) return math.floor(x*1000)/1000 end, 
          val_format_rev = function(x) return tonumber(x) end, },          
          --[[{str = 'Minimum value difference' ,     group = 6, itype = 'readout', confkey = 'CONF_reducesamevalues_mindiff', 
            val_format = function(x) return (math.floor(x*1000)/1000)..'dB' end, 
            val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end,
            level = 2, val_res = 0.05, val_min = 0, val_max = 5, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,hide=DATA.extstate.CONF_reducesamevalues~=1}, ]]
        {str = 'Reset boundary edges',          group = 6, itype = 'check', confkey = 'CONF_zeroboundary', level = 1, func_onrelease = function()DATA2:ProcessAtChange(DATA)  end},
      {str = 'UI options' ,                     group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,             group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse' ,             group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        --{str = 'Show tootips' ,               group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Process on settings change',    group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        {str = 'Process on initialization',     group = 5, itype = 'check', confkey = 'UI_processoninit', level = 1},
    } 
    return t
    
  end
  --[[-----------------------------------------------------------------
  fun ction D ATA2:Process_InsertData_Deeser(t, boundary_start, boundary_end, offs, env, AI_idx)
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    local scaling_mode = GetEnvelopeScalingMode( env )
     --// (C) 2009, Lubomir I. Ivanov
     --// Includes optimized version of Linkwitz-Riley (LR2) filters
     --// by T. Lossius - ttblue project
     
     -- deeser
       local b1_s0 = 0
       local b2_s0 = 0
       local d_b1_s0 = 0
       local d_b2_s0 = 0
       local a0_s0_lp = 0
       local a1_s0_lp = 0
       local a2_s0_lp = 0
       local d_a0_s0_lp = 0
       local d_a1_s0_lp = 0
       local d_a2_s0_lp = 0
       local s0_lp_l_xm0 = 0
       local s0_lp_l_xm1 = 0
       local a0_s0_hp = 0
       local a1_s0_hp = 0
       local a2_s0_hp = 0
       local d_a0_s0_hp = 0
       local d_a1_s0_hp = 0
       local d_a2_s0_hp = 0
       local s0_hp_l_xm0 = 0
       local s0_hp_l_xm1 = 0
       local tgt_b1_s0 = 0
       local src_b1_s0 = 0
       local tgt_b2_s0 = 0
       local src_b2_s0 = 0
       local tgt_a0_s0_lp = 0
       local src_a0_s0_lp = 0
       local tgt_a1_s0_lp = 0
       local src_a1_s0_lp = 0
       local tgt_a2_s0_lp = 0
       local src_a2_s0_lp = 0
       local tgt_a0_s0_hp = 0
       local src_a0_s0_hp = 0
       local tgt_a1_s0_hp = 0
       local src_a1_s0_hp = 0
       local tgt_a2_s0_hp = 0
       local src_a2_s0_hp = 0
       local s0_hp_l_in = 0
       local s0_hp_l_output = 0
       local cband_l = 0
       local dtl = 0
       local envl = 0
       local att = 0
       local rel = 0
       local thr = 0
       local e10 = 0
       local k = 0 
       local k2 = 0 
       local k22 = 0 
       local sum_l = 0 
       local s0_lp_l_in = 0 
       local s0_lp_l_output = 0 
       local out = 0 
       local tmpk = 0 
       local wc = 0 
       local wc2 = 0 
       local wc22 = 0 
       local wck2 = 0 
       local outl = 0 
       
       
       -- sliders
       local target = 1; --1<0,1,1{Bandpass,Hipass}>Target Type
       local fc = 4000;--slider4:4000<1500,12000,1>Frequency (Hz)
       local bw  = 1.5; -- slider5:1.5<0.1,3.1,0.0005>Bandwidth (Oct)
       local thr_dB = -50-- slider6:-65<-80,0,0.01>Threshold (dB)
       local ratctrl = 11--slider7:11<1,20,0.01>Ratio
       local thr = 10^( 2 * (thr_dB/80+1) - 2); 
       local rat = (ratctrl-1)/19;
       local timeconst = 0 -- slider8:0<0,1,1{A: 3 es - R: 50 ms,A: 30 es - R: 100 ms,A: 100 es - R: 300 ms}>Time Constants
       
       
       local n = 0;
       local sqrt2 = math.sqrt(2);
       local s2 = sqrt2/2;
       local cgain = 1;
       local cdenorm = 10^-30;
       local e10 = 10^-10;
       
      --//comp
      if timeconst == 0 then
        att = 10^(-0.002 - 3.97772619*(0/100));
        rel = 10^(-3.11 - 1.8698*(21.20/100));
       elseif timeconst == 1 then
        att = 10^(-0.002 - 3.97772619*(9.71/100));
        rel = 10^(-3.11 - 1.8698*(37.19/100));
       elseif timeconst == 2 then
        att = 10^(-0.002 - 3.97772619*(20.97/100));
        rel = 10^(-3.11 - 1.8698*(62.61/100));
      end
       
     -- crossover type: 2 or 3 bands
     if target == 0 then
      fh = math.min((fc + fc*bw/2),20000);
      --// high-band split - s1 (at fh)
      fpi = math.pi*fh;
      wc = 2*fpi;
      wc2 = wc*wc;
      wc22 = 2*wc2;
      k = wc/math.tan(fpi/SR_spls);
      k2 = k*k;
      k22 = 2*k2;
      wck2 = 2*wc*k; 
      tmpk = (k2+wc2+wck2);
      tgt_b1_s1 = (-k22+wc22)/tmpk;
      tgt_b2_s1 = (-wck2+k2+wc2)/tmpk;
      --// low-pass (s1)
      tgt_a0_s1_lp = (wc2)/tmpk;
      tgt_a1_s1_lp = (wc22)/tmpk;
      tgt_a2_s1_lp = (wc2)/tmpk;
     --// high-pass (s1)
      tgt_a0_s1_hp = (k2)/tmpk;
      tgt_a1_s1_hp = (-k22)/tmpk;
      tgt_a2_s1_hp = (k2)/tmpk;
      --// prepare for s0
      fl = fc - fc*bw/4;
      fpi = math.pi*fl; 
     else 
      fpi = math.pi*fc;
    end
    
    --// low-band split - s0 (case: at 'fc' or 'fl')
    -- // s0 is always processed (2 band split)
      wc = 2*fpi;
      wc2 = wc*wc;
      wc22 = 2*wc2;
      k = wc/math.tan(fpi/SR_spls);
      k2 = k*k;
      k22 = 2*k2;
      wck2 = 2*wc*k; 
      tmpk = (k2+wc2+wck2);
      tgt_b1_s0 = (-k22+wc22)/tmpk;
      tgt_b2_s0 = (-wck2+k2+wc2)/tmpk;
      --// low-pass (s0)
      tgt_a0_s0_lp = (wc2)/tmpk;
      tgt_a1_s0_lp = (wc22)/tmpk;
      tgt_a2_s0_lp = (wc2)/tmpk;
      --// high-pass (s0)
      tgt_a0_s0_hp = (k2)/tmpk;
      tgt_a1_s0_hp = (-k22)/tmpk;
      tgt_a2_s0_hp = (k2)/tmpk;
     
      
      local gain_t = {}
      local tsz = #t
      local spl0 = 0
      local samplesblock = 1024
      
      
      -- main loop
      for i = 1, tsz do
        spl0 = t[i]; 
        -- // s0, b
        b1_s0 = b1_s0 + d_b1_s0;
        b2_s0 = b2_s0 + d_b2_s0;
        -- // s0, lp 
        a0_s0_lp = a0_s0_lp + d_a0_s0_lp;
        a1_s0_lp = a1_s0_lp + d_a1_s0_lp;
        a2_s0_lp = a2_s0_lp + d_a2_s0_lp;
        s0_lp_l_in = spl0;
        s0_lp_l_output = a0_s0_lp*s0_lp_l_in + s0_lp_l_xm0;
        s0_lp_l_xm0 = a1_s0_lp*s0_lp_l_in - b1_s0*s0_lp_l_output + s0_lp_l_xm1;
        s0_lp_l_xm1 = a2_s0_lp*s0_lp_l_in - b2_s0*s0_lp_l_output;
        -- // s0, hp 
        a0_s0_hp = a0_s0_hp + d_a0_s0_hp;
        a1_s0_hp = a1_s0_hp + d_a1_s0_hp;
        a2_s0_hp = a2_s0_hp + d_a2_s0_hp;
        s0_hp_l_in = spl0;
        s0_hp_l_output = a0_s0_hp*s0_hp_l_in + s0_hp_l_xm0;
        s0_hp_l_xm0 = a1_s0_hp*s0_hp_l_in - b1_s0*s0_hp_l_output + s0_hp_l_xm1;
        s0_hp_l_xm1 = a2_s0_hp*s0_hp_l_in - b2_s0*s0_hp_l_output;
        s0_hp_l_output = s0_hp_l_output * -1;
        --// s1, b
        if target == 0 then
          b1_s1 = b1_s1 + d_b1_s1;
          b2_s1 = b2_s1 + d_b2_s1;
          --  // s1, lp 
          a0_s1_lp = a0_s1_lp + d_a0_s1_lp;
          a1_s1_lp = a1_s1_lp + d_a1_s1_lp;
          a2_s1_lp = a2_s1_lp + d_a2_s1_lp;
          s1_lp_l_in = s0_hp_l_output;
          s1_lp_l_output = a0_s1_lp*s1_lp_l_in + s1_lp_l_xm0;
          s1_lp_l_xm0 = a1_s1_lp*s1_lp_l_in - b1_s1*s1_lp_l_output + s1_lp_l_xm1;
          s1_lp_l_xm1 = a2_s1_lp*s1_lp_l_in - b2_s1*s1_lp_l_output;
          --  // s1, hp 
          a0_s1_hp = a0_s1_hp+ d_a0_s1_hp;
          a1_s1_hp = a1_s1_hp+ d_a1_s1_hp;
          a2_s1_hp = a2_s1_hp + d_a2_s1_hp;
          s1_hp_l_in = s0_hp_l_output;
          s1_hp_l_output = a0_s1_hp*s1_hp_l_in + s1_hp_l_xm0;
          s1_hp_l_xm0 = a1_s1_hp*s1_hp_l_in - b1_s1*s1_hp_l_output + s1_hp_l_xm1;
          s1_hp_l_xm1 = a2_s1_hp*s1_hp_l_in - b2_s1*s1_hp_l_output;
          s1_hp_l_output = s1_hp_l_output * -1;
          --// set process band (cband)
          cband_l = s1_lp_l_output;
         else
          cband_l = s0_hp_l_output;
        end
        
        -- // compressor 
        dtl = math.abs(cband_l);
        if (dtl > envl) then envl = envl + att*(dtl - envl) else envl = envl*(1 - rel); end
        if (envl > thr) then 
          cgainl = 1+(rat*  ( (envl/thr)-1) ); 
          g_reset = 0;
         else
          cgainl = 1; g_reset = 1;
        end
        if (envl < e10) then envl = 0 end
        
        -- // monitor or sum bands
        if target == 0 then 
          sum_l = s0_lp_l_output+cband_l/cgainl+s1_hp_l_output;
         else
          sum_l = s0_lp_l_output+cband_l/cgainl;
        end
        outl = sum_l+cdenorm;
        
        
        -- @block
        --// interpolate *all* coefficients here 
        -- // s0 b
        d_b1_s0 = (tgt_b1_s0-src_b1_s0)/samplesblock;
        b1_s0 = src_b1_s0;
        src_b1_s0 = tgt_b1_s0;
        d_b2_s0 = (tgt_b2_s0-src_b2_s0)/samplesblock;
        b2_s0 = src_b2_s0;
        src_b2_s0 = tgt_b2_s0;
        --// s0 a lp
        d_a0_s0_lp = (tgt_a0_s0_lp-src_a0_s0_lp)/samplesblock;
        a0_s0_lp = src_a0_s0_lp;
        src_a0_s0_lp = tgt_a0_s0_lp;
        d_a1_s0_lp = (tgt_a1_s0_lp-src_a1_s0_lp)/samplesblock;
        a1_s0_lp = src_a1_s0_lp;
        src_a1_s0_lp = tgt_a1_s0_lp;
        d_a2_s0_lp = (tgt_a2_s0_lp-src_a2_s0_lp)/samplesblock;
        a2_s0_lp = src_a2_s0_lp;
        src_a2_s0_lp = tgt_a2_s0_lp;
        --// s0 a hp
        d_a0_s0_hp = (tgt_a0_s0_hp-src_a0_s0_hp)/samplesblock;
        a0_s0_hp = src_a0_s0_hp;
        src_a0_s0_hp = tgt_a0_s0_hp;
        d_a1_s0_hp = (tgt_a1_s0_hp-src_a1_s0_hp)/samplesblock;
        a1_s0_hp = src_a1_s0_hp;
        src_a1_s0_hp = tgt_a1_s0_hp;
        d_a2_s0_hp = (tgt_a2_s0_hp-src_a2_s0_hp)/samplesblock;
        a2_s0_hp = src_a2_s0_hp;
        src_a2_s0_hp = tgt_a2_s0_hp;
        --// s1
        if target == 0 then
          --// s1 b
          d_b1_s1 = (tgt_b1_s1-src_b1_s1)/samplesblock;
          b1_s1 = src_b1_s1;
          src_b1_s1 = tgt_b1_s1;
          d_b2_s1 = (tgt_b2_s1-src_b2_s1)/samplesblock;
          b2_s1 = src_b2_s1;
          src_b2_s1 = tgt_b2_s1;
          --// s1 a lp
          d_a0_s1_lp = (tgt_a0_s1_lp-src_a0_s1_lp)/samplesblock;
          a0_s1_lp = src_a0_s1_lp;
          src_a0_s1_lp = tgt_a0_s1_lp;
          d_a1_s1_lp = (tgt_a1_s1_lp-src_a1_s1_lp)/samplesblock;
          a1_s1_lp = src_a1_s1_lp;
          src_a1_s1_lp = tgt_a1_s1_lp;
          d_a2_s1_lp = (tgt_a2_s1_lp-src_a2_s1_lp)/samplesblock;
          a2_s1_lp = src_a2_s1_lp;
          src_a2_s1_lp = tgt_a2_s1_lp;
          --// s1 a hp
          d_a0_s1_hp = (tgt_a0_s1_hp-src_a0_s1_hp)/samplesblock;
          a0_s1_hp = src_a0_s1_hp;
          src_a0_s1_hp = tgt_a0_s1_hp;
          d_a1_s1_hp = (tgt_a1_s1_hp-src_a1_s1_hp)/samplesblock;
          a1_s1_hp = src_a1_s1_hp;
          src_a1_s1_hp = tgt_a1_s1_hp;
          d_a2_s1_hp = (tgt_a2_s1_hp-src_a2_s1_hp)/samplesblock;
          a2_s1_hp = src_a2_s1_hp;
          src_a2_s1_hp = tgt_a2_s1_hp;
        end
             
        diff = spl0 - outl;
        spl0 = outl;
        
        gain_t[i] = math.max(diff,0)
      end
      
      
      
    -- add points 
      --wind_spls = 1
      local wind_spls = math.ceil(DATA.extstate.CONF_window/2 * SR_spls) 
      local output = {}
      local spl_time = 1/SR_spls
      for i = 1, tsz, wind_spls do  
        local val = ScaleToEnvelopeMode( scaling_mode, gain_t[i] ) 
        tpos = boundary_start + i*spl_time-offs--+lookahead_ms
        if tpos > 0 and val >= 0 and val <= 1000 then
          output[#output+1] = {tpos=tpos,val=val,valnorm = gain_t[i]}
        end
      end
      
      
    return output
  end]]
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.05) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end
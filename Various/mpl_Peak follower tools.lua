-- @description Peak follower tools
-- @version 1.02
-- @author MPL
-- @about Generate envelope from audio data
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # code cleanup, require mpl_VariousFunction 3.0+
--    + Output/allow to reduce points with same values
--    + GUI (VF3): allow to hide settings blocks
--    + GUI (VF3): doubleclick on readout reset it to default
--    + GUI (VF3): rightclick on readout to type it manually (if available)

    
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.02
    DATA.extstate.extstatesection = 'PeakFollowTools'
    DATA.extstate.mb_title = 'Peak follower tools'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  500,
                          wind_h =  500,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          CONF_window = 0.05,
                          CONF_mode = 0, -- 0 peak follower 1 gate
                          CONF_boundary = 0, -- 0 item edges 1 time selection
                          CONF_dest = 0, -- 0 AI track vol 1 take vol env
                          CONF_reducesamevalues = 1, -- do not add point if previous point has same value
                          CONF_zeroboundary = 1, -- zero reset for boundaries
                          
                          -- gate
                          CONF_gate_threshold = 0.4,
                          
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          
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
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    --DATA.GUI.default_scale = 2
    
    -- init main stuff
      DATA.GUI.custom_mainbuth = 30
      DATA.GUI.custom_texthdef = 23
      DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
      DATA.GUI.custom_mainsepx = gfx.w--(gfx.w/DATA.GUI.default_scale)*0.4-- *DATA.GUI.default_scale--400*DATA.GUI.default_scale--
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
  function DATA2:Process_CalcpointsAI(item)
    local window_sec = DATA.extstate.CONF_window
    -- init 
      if not (item and window_sec) then return end  
      local take =  reaper.GetActiveTake( item )
      if TakeIsMIDI( take ) then return end  
      local track = GetMediaItem_Track(item)
      local accessor = CreateTrackAudioAccessor( track )
      local data = {}
      local id = 0
      local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      local bufsz = math.ceil(window_sec * SR_spls)
      
      local ret, boundary_start, boundary_end = DATA2:Process_GetBoundary(item)
      if not ret then return end
      
    -- loop stuff 
      for pos = boundary_start, boundary_end, window_sec do 
        local samplebuffer = new_array(bufsz);
        GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
        local sum = 0 
        for i = 1, bufsz do 
          local val = math.abs(samplebuffer[i]) 
          sum = sum + val 
        end 
        samplebuffer.clear()
        id = id + 1
        data[id] = sum / bufsz
      end
      reaper.DestroyAudioAccessor( accessor )
      local max_val = 0
      for i = 1, #data do max_val = math.max(max_val, data[i]) end -- abs all values 
      for i = 1, #data do data[i] = (data[i]/max_val) end -- normalize 
        
    return data
  end
  -------------------------------------------------------------------
  function DATA2:Process_InsertData(item, env, AI_idx, t)
    -- get boundary
      local ret, boundary_start, boundary_end, i_pos = DATA2:Process_GetBoundary(item)
      if not ret then return end
      
    -- init vars
      local scaling_mode = GetEnvelopeScalingMode( env )
      local window_ms = DATA.extstate.CONF_window
      local offs = 0 if DATA.extstate.CONF_dest == 1 then  offs = i_pos end -- compensate points for AI
    
    -- clear
      DeleteEnvelopePointRangeEx( env, AI_idx, boundary_start-offs, boundary_end-offs ) 
    
    -- filter same points
      local t_skip = {} -- table for skip adding points
      if DATA.extstate.CONF_reducesamevalues == 1 then
        for i = #t-1,2,-1 do  
          local val = t[i]
          local nextval = t[i+1]
          local prevval = t[i-1]
          if val==nextval and val==prevval then t_skip[i] = true end
        end
      end
      
    -- do window shift
      local wind_offs = 0--window_ms
    -- add -- peak follow
      if DATA.extstate.CONF_mode ==0 then 
        local last_val = math.huge
        local trig_remove
        for i = #t-1,1,-1 do  
          if not t_skip[i]then
            local val = ScaleToEnvelopeMode( scaling_mode, t[i] ) 
            local tpos = (i-1)*window_ms+boundary_start-offs+wind_offs
            InsertEnvelopePointEx( env, AI_idx, tpos,  val, 0, 0, 0, true )
          end
        end
      end
                  
    -- add -- gate
      if DATA.extstate.CONF_mode ==1 then
        for i = #t, 1, -1 do   
          if not t_skip[i]then
            local val =  t[i]
            if val > DATA.extstate.CONF_gate_threshold then val = 1 else val = 0 end
            val = ScaleToEnvelopeMode( scaling_mode, val ) 
            local tpos = (i-1)*window_ms+boundary_start-offs+wind_offs
            InsertEnvelopePointEx( env, AI_idx, tpos,  val, 0, 0, 0, true )
          end
        end
      end
      
    -- sort
      Envelope_SortPointsEx( env, AI_idx ) 
      
    -- boundary
      if DATA.extstate.CONF_zeroboundary == 1 then
        --InsertEnvelopePointEx( env, AI_idx, boundary_start-offs,  reaper.ScaleToEnvelopeMode( scaling_mode,t[1] ), 0, 0, 0, true )
        local ptidx = GetEnvelopePointByTimeEx(env, AI_idx, #t*window_ms+boundary_start-offs )
        if ptidx then
          local retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, AI_idx, ptidx )
          reaper.SetEnvelopePointEx(  env, AI_idx, ptidx, time, 0, shape, tension, selected, true )
        end
      end
      
    -- sort 2nd pass
      Envelope_SortPointsEx( env, AI_idx ) 
    
    --[[ filter same points
      if DATA.extstate.CONF_reducesamevalues ==1 then
        local cnt =  CountEnvelopePointsEx( env, AI_idx )
        local last_value = math.huge
        for ptidx = cnt,1,-1 do
          local retval, time, value, shape, tension, selected = GetEnvelopePointEx(env, AI_idx, ptidx-1 )
          if value == last_value then 
            DeleteEnvelopePointEx(env, AI_idx, ptidx-1 )   
          end
          last_value=value
        end
      end
    -- sort
    Envelope_SortPointsEx( env, AI_idx )]]
  end
  ----------------------------------------------------------------------
  function DATA2:Process()
    for i = 1,  CountSelectedMediaItems( 0 ) do
      local item = GetSelectedMediaItem(0,i-1)
      local t = DATA2:Process_CalcpointsAI(item)
      local ret, env, AI_idx =  DATA2:Process_GenerateAI(item)
      if ret then DATA2:Process_InsertData(item, env, AI_idx, t) end
    end  
  end
  ----------------------------------------------------------------------
  function DATA2:ProcessAtChange(DATA)
    if DATA.extstate.UI_appatchange&1==1 then DATA2:Process() end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local  t = 
    { 
      {str = 'Mode' ,                         group = 1, itype = 'sep'},
        {str = 'Peak follower' ,              group = 1, itype = 'check', confkey = 'CONF_mode', level = 1, isset = 0},
        {str = 'Gate' ,                       group = 1, itype = 'check', confkey = 'CONF_mode', level = 1, isset = 1},
      {str = 'Boundaries' ,                   group = 2, itype = 'sep'},
        {str = 'Item edges' ,                 group = 2, itype = 'check', confkey = 'CONF_boundary', level = 1, isset = 0},
        {str = 'Time selection' ,             group = 2, itype = 'check', confkey = 'CONF_boundary', level = 1, isset = 1},
      {str = 'Audio data parameters' ,        group = 3, itype = 'sep'},
        {str = 'RMS Window' ,                 group = 3, itype = 'readout', confkey = 'CONF_window', level = 1, 
          val_min = 0.002, 
          val_max = 0.4, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(x*1000)/1000)..'s' end, 
          val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Gate threshold' ,             group = 3, itype = 'readout', confkey = 'CONF_gate_threshold', level = 1, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(x*1000)/10)..'%' end, 
          func_onrelease = function() DATA2:ProcessAtChange(DATA) end, 
          hide=DATA.extstate.CONF_mode~=1},
      {str = 'Destination' ,                  group = 4, itype = 'sep'},
        {str = 'Track volume env AI' ,        group = 4, itype = 'check', confkey = 'CONF_dest', level = 1, isset = 0},
        {str = 'Take volume env' ,            group = 4, itype = 'check', confkey = 'CONF_dest', level = 1, isset = 1},
      {str = 'Output' ,                       group = 6, itype = 'sep'},
        {str = 'Reduce points with same values',group = 6, itype = 'check', confkey = 'CONF_reducesamevalues', level = 1, func_onrelease = function() if DATA.extstate.UI_appatchange&1==1 then DATA2:Process() end end},
        {str = 'Reset boundary edges to zero',group = 6, itype = 'check', confkey = 'CONF_zeroboundary', level = 1, func_onrelease = function() if DATA.extstate.UI_appatchange&1==1 then DATA2:Process() end end},
      {str = 'UI options' ,                   group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,           group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse' ,           group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        --{str = 'Show tootips' ,               group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Process on settings change',  group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.0) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end

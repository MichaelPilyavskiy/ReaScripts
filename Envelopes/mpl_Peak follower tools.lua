-- @description Peak follower tools
-- @version 1.01
-- @author MPL
-- @about Generate envelope from audio data
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix potential leakage
--    + Add gate mode

    
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.01
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
                          
                          -- gate
                          CONF_gate_threshold = 0.4,
                          
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          
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
    GUI:init()
    GUI_RESERVED_initbuttons(GUI)
    RUN()
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_shortcuts(GUI)
    -- left/right arrow move main knob
    -- G/g get ref/dub
    -- R/r get ref
    -- D/d get dub
    
    if GUI.char> 0 then 
      
    end
    
    if GUI.char <= 0 or DATA.extstate.UI_enableshortcuts == 0 then return end
    
    if GUI.char == 32 then -- space
      VF_Action(40044)
    end
    
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_initbuttons(GUI)
    if not GUI.layers then GUI.layers = {} end
    --GUI.default_scale = 2
    
    GUI.custom_mainbuth = 30
    GUI.custom_texthdef = 23
    GUI.custom_offset = math.floor(GUI.default_scale*GUI.default_txt_fontsz/2)
    GUI.custom_mainsepx = gfx.w--(gfx.w/GUI.default_scale)*0.4-- *GUI.default_scale--400*GUI.default_scale--
    GUI.custom_mainbutw = 0.5*(gfx.w/GUI.default_scale-GUI.custom_offset*3) --(gfx.w/GUI.default_scale - GUI.custom_mainsepx)-GUI.custom_offset*3
    GUI.custom_scrollw = 10
    GUI.custom_frameascroll = 0.05
    GUI.custom_default_framea_normal = 0.1
    GUI.custom_spectralw = GUI.custom_mainbutw*3 + GUI.custom_offset*2
    GUI.custom_layerset= 21
    GUI.custom_datah = (gfx.h/GUI.default_scale-GUI.custom_mainbuth-GUI.custom_offset*3) 
    
    
    
    GUI.buttons = {} 
      GUI.buttons.app = {  x=GUI.custom_offset,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = 'Generate',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            onmouseclick =  function() 
                                              Undo_BeginBlock()
                                              DATA2:Process()
                                              Undo_EndBlock( DATA.extstate.mb_title..' - process', 0 )
                                            end} 
      GUI.buttons.preset = { x=GUI.custom_offset*2+GUI.custom_mainbutw,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            onmouseclick =  function() 
                                              -- form presets menu    
                                                local presets_t = {
                                                  {str = 'Reset all settings to default',
                                                    func = function() 
                                                              DATA.extstate.current_preset = nil
                                                              GUI.buttons.preset.txt = 'Preset: default'
                                                              DATA:ExtStateRestoreDefaults() 
                                                              GUI.firstloop = 1 
                                                              DATA.UPD.onconfchange = true 
                                                              GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                            end},
                                                  {str = 'Save current preset',
                                                  func = function() 
                                                            local id 
                                                            if DATA.extstate.current_preset then id = DATA.extstate.current_preset end
                                                            local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                                                            if not retval then return end
                                                            if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                                                            DATA:ExtStateStorePreset(id) 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  }, 
                                                  {str = 'Rename current preset',
                                                  func = function() 
                                                            local id 
                                                            if not DATA.extstate.current_preset then return else id = DATA.extstate.current_preset end
                                                            local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                                                            if not retval then return end
                                                            if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                                                            DATA:ExtStateStorePreset(id) 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '')
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  },                                                   
                                                  {str = 'Save current preset as new',
                                                  func = function() 
                                                            local id 
                                                            local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                                                            if not retval then return end
                                                            if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                                                            DATA:ExtStateStorePreset() 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  },     
                                                  {str = 'Remove current preset',
                                                  func = function()
                                                            if DATA.extstate.current_preset then 
                                                              DATA:ExtStatePresetRemove(DATA.extstate.current_preset)
                                                              DATA.extstate.presets[DATA.extstate.current_preset] = nil
                                                              DATA.extstate.current_preset = nil
                                                            end
                                                            local id 
                                                            DATA:ExtStateGetPresets()
                                                            GUI.buttons.preset.refresh = true 
                                                            GUI.firstloop = 1 
                                                            DATA.UPD.onconfchange = true 
                                                            GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                          end
                                                  },                                                    
                                                  {str = ''},
                                                  {str = '#Preset list'},
                                                                  }
                                              -- add preset list    
                                                for i = 1, #DATA.extstate.presets do
                                                  local state = DATA.extstate.current_preset and DATA.extstate.current_preset == i
                                                  
                                                  presets_t[#presets_t+1] = { str = DATA.extstate.presets[i].CONF_NAME or '[no name]',
                                                                              func = function()  
                                                                                        DATA:ExtStateApplyPreset(DATA.extstate.presets[i]) 
                                                                                        DATA.extstate.current_preset = i
                                                                                        GUI.buttons.preset.refresh = true 
                                                                                        GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '')
                                                                                        GUI.firstloop = 1 
                                                                                        DATA.UPD.onconfchange = true 
                                                                                        GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                                                                      end,
                                                                              state = state,
                                                  
                                                    
                                                                              }
                                                end
                                              -- form table
                                                GUI:menu(presets_t)  
                                            end}                                             
                                                        
    -- settings
      GUI.buttons.settings = { x=gfx.w/GUI.default_scale - GUI.custom_mainsepx,
                            y=GUI.custom_mainbuth + GUI.custom_offset,
                            w=GUI.custom_mainsepx,
                            h=gfx.h/GUI.default_scale-GUI.custom_mainbuth - GUI.custom_offset,
                            --txt = 'Settings',
                            --txt_fontsz = GUI.default_txt_fontsz3,
                            --offsetframe = GUI.custom_offset,
                            frame_a = GUI.custom_default_framea_normal,
                            ignoremouse = true,
                            }
  
      local offs = GUI.custom_offset
      GUI.buttons.settingslist = { x=GUI.buttons.settings.x +offs*2,
                            y=GUI.buttons.settings.y+offs*2,
                            w=GUI.buttons.settings.w-offs*5-GUI.custom_scrollw,
                            h=GUI.buttons.settings.h-offs*4  , 
                            txt = 'list',
                            frame_a = 1,
                            layer = GUI.custom_layerset,
                            hide = true,
                            ignoremouse = true,}  
      GUI.buttons.settingslist_mouse = { x=GUI.buttons.settings.x +offs*2, -- for scrolling
                            y=GUI.buttons.settings.y+offs*2,
                            w=GUI.buttons.settings.w-offs*5-GUI.custom_scrollw,
                            h=GUI.buttons.settings.h-offs*4  , 
                            txt = 'list',
                            frame_a = 1,
                            --layer = GUI.custom_layerset,
                            hide = true,
                            --ignoremouse = true,
                            onwheeltrig = function() 
                                            local dir = 1
                                            local layer= GUI.custom_layerset
                                            if GUI.wheel_dir then dir = -1 end
                                            GUI.layers[layer].scrollval = VF_lim(GUI.layers[layer].scrollval - 0.1 * dir)
                                            --GUI.buttons[key].refresh = true
                                            if GUI.buttons.settings_scroll then 
                                              GUI.buttons.settings_scroll.refresh = true
                                              GUI.buttons.settings_scroll.val = GUI.layers[layer].scrollval
                                            end
                                          end,}                               
      GUI:quantizeXYWH(GUI.buttons.settingslist)
      
      if not GUI.layers[GUI.custom_layerset] then GUI.layers[GUI.custom_layerset] = {} end
      GUI.layers[GUI.custom_layerset].scrollval=0
      
      GUI.buttons.settings_scroll = { x=GUI.buttons.settings.x+GUI.buttons.settings.w-GUI.custom_scrollw-offs*2,
                            y=GUI.buttons.settings.y+offs*2,
                            w=GUI.custom_scrollw,
                            h=GUI.buttons.settings.h-offs*4,
                            frame_a = GUI.custom_frameascroll,
                            frame_asel = GUI.custom_frameascroll,
                            val = 0,
                            val_res = -1,
                            slider_isslider = true,
                            hide = GUI.compactmode==1,
                            ignoremouse = GUI.compactmode==1,
                            onmousedrag = function() GUI.layers[GUI.custom_layerset].scrollval = GUI.buttons.settings_scroll.val end
                            }
                            
                            
      GUI.layers[GUI.custom_layerset].a=1
      GUI.layers[GUI.custom_layerset].hide = GUI.compactmode==1
      GUI.layers[GUI.custom_layerset].layer_x = GUI.buttons.settingslist.x
      GUI.layers[GUI.custom_layerset].layer_y = GUI.buttons.settingslist.y
      GUI.layers[GUI.custom_layerset].layer_yshift = 0
      GUI.layers[GUI.custom_layerset].layer_w = GUI.buttons.settingslist.w+1
      GUI.layers[GUI.custom_layerset].layer_h = GUI.buttons.settingslist.h
      GUI.layers[GUI.custom_layerset].layer_hmeasured = GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
 
      
    
    for but in pairs(GUI.buttons) do GUI.buttons[but].key = but end
  end
  ---------------------------------------------------------------------  
  function GUI_settingst(GUI, DATA, boundaryobj, scrollobj) 
  
    local function GUI_settingst_confirmval(GUI, DATA, key,txt,confkey, val, major_confirm, ignoreCONF_appatchange) 
      if key and GUI.buttons[key] then GUI.buttons[key].txt = txt GUI.buttons[key].refresh = true  end
      if confkey then DATA.extstate[confkey] = val end 
      boundaryobj.refresh = true 
      if major_confirm then 
        GUI:generatelisttable( GUI_settingst(GUI, DATA, boundaryobj) )
        DATA.UPD.onconfchange = true
        DATA:ExtStateStorePreset(0) 
        boundaryobj.refresh = true 
        if DATA.extstate.UI_appatchange&1==1 and not ignoreCONF_appatchange then 
          DATA2:Process()
        end
      end
    end
    
    
    local function GUI_settingst_getcheck(menuitem,confname, col, protect, val)
      local active = true
      if protect then active = VF_isregist&2==2 end
      return { str = menuitem,
        level = 1,
        txt_col = col,
        onmouserelease = function() 
          if not val then GUI_settingst_confirmval(GUI, DATA, nil,nil,confname, math.abs(1-DATA.extstate[confname]) , true, nil )  else GUI_settingst_confirmval(GUI, DATA, nil,nil,confname, val , true, nil ) end
        end,                          
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults(confname) GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil , true, nil )  end,                          
        ischeck = true,
        state = DATA.extstate[confname]==(val or 1),
        active = active,
        ignoremouse = not active,
      }
    end
    
    
      
      
    local  t = 
    {
      { str = 'Mode' , issep = true }, 
        GUI_settingst_getcheck('Peak follower', 'CONF_mode', nil, nil, 0),  
        GUI_settingst_getcheck('Gate', 'CONF_mode', nil, nil, 1),  
      { str = 'Boundaries' , issep = true }, 
        GUI_settingst_getcheck('Item edges', 'CONF_boundary', nil, nil, 0),  
        GUI_settingst_getcheck('Time selection', 'CONF_boundary', nil, nil, 1), 
        
      { str = 'Audio data parameters' , issep = true },         
      { customkey = 'settings_wind',
        str = 'RMS Window',
        level = 1,
        isvalue = true,
        val = VF_FormatToNormValue(DATA.extstate.CONF_window, 0.002, 0.4),
        val_res = 0.1,
        valtxt =  DATA.extstate.CONF_window..'s',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_windval',VF_NormToFormatValue(GUI.buttons['settings_windval'].val, 0.002, 0.4, 3)..'s' , 'CONF_window', VF_NormToFormatValue(GUI.buttons['settings_windval'].val, 0.002, 0.4, 3), nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_window') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
      },      
      { customkey = 'settings_gtshresh',
        str = 'Gate threshold',
        level = 1,
        isvalue = true,
        val = DATA.extstate.CONF_gate_threshold,
        val_res = 0.1,
        valtxt =  VF_NormToFormatValue(DATA.extstate.CONF_gate_threshold, 0,100)..'%',
        onmousedrag = function() GUI_settingst_confirmval(GUI, DATA, 'settings_gtshreshval',VF_NormToFormatValue(GUI.buttons['settings_gtshreshval'].val, 0,100)..'%', 'CONF_gate_threshold', GUI.buttons['settings_gtshreshval'].val, nil, nil  ) end,
        onmouserelease = function() GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_gate_threshold') GUI_settingst_confirmval(GUI, DATA, nil,nil,nil,nil,true, nil ) end,
        active = DATA.extstate.CONF_mode==1,
        ignoremouse = DATA.extstate.CONF_mode~=1,
      }, 
      
      { str = 'Destination' , issep = true },  
        GUI_settingst_getcheck('Track volume env AI', 'CONF_dest', nil, nil, 0), 
        GUI_settingst_getcheck('Take volume env', 'CONF_dest', nil, nil, 1), 
      
      { str = 'UI options' , issep = true }, 
        GUI_settingst_getcheck('Enable shortcuts', 'UI_enableshortcuts'),   
        GUI_settingst_getcheck('Init UI at mouse position', 'UI_initatmouse'),  
        GUI_settingst_getcheck('Show tootips', 'UI_showtooltips'),  
        GUI_settingst_getcheck('Process on settings tweak', 'UI_appatchange'),  
 
    }
    
    return 
    {
    t=t, 
    boundaryobj = boundaryobj,
    tablename = 'settings',
    layer = boundaryobj.layer,
    scrollobj = scrollobj
    }
    
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
      
    -- add -- peak follow
      if DATA.extstate.CONF_mode ==0 then 
        for i = 1, #t do  InsertEnvelopePointEx( env, AI_idx, (i-1)*window_ms+boundary_start-offs,  reaper.ScaleToEnvelopeMode( scaling_mode, t[i] ), 0, 0, 0, true )  end
      end
    -- add -- gate
      if DATA.extstate.CONF_mode ==1 then
        for i = 1, #t do   
          local val = t[i]
          if val > DATA.extstate.CONF_gate_threshold then val = 1 else val = 0 end
          InsertEnvelopePointEx( env, AI_idx, (i-1)*window_ms+boundary_start-offs,  reaper.ScaleToEnvelopeMode( scaling_mode,val ), 0, 0, 0, true )  
        end
      end
    
    -- sort
    Envelope_SortPointsEx( env, AI_idx )
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
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.84) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end
-- @description Transient shaper
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
   DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.00
    DATA.extstate.extstatesection = 'MPLEBTRANSSHAPE'
    DATA.extstate.mb_title = 'MPL Transient shaper'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  300,
                          wind_h =  153,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          CONF_mode = 0,
                          
                          --CONF_attack_sec = 0,
                          CONF_attack_khsTS = 0,
                          CONF_pump_khsTS = 0,
                          CONF_sustain_khsTS = 0,
                          CONF_rate_khsTS = 1,
                          
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
    
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_GetItems()
    DATA2.items = {}
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem(0,i-1)
      local tk = GetActiveTake(it)
      if tk then 
        local env_ptr = reaper.GetTakeEnvelopeByName( tk, 'Volume' )
        if not env_ptr then 
          DATA2:Process_ActivateTakeVolEnvelope(it,tk)
          local env_ptr = reaper.GetTakeEnvelopeByName( tk, 'Volume' )
          DeleteEnvelopePointRangeEx( env_ptr, -1, 0, math.huge )
          SetEnvelopePointEx( env_ptr, -1, 0, 
            0.1, --pos
            0,--valueIn, 
            0,--shapeIn, 
            0,--tensionIn, 
            0,--selectedIn, 
            true)--noSortIn )
          Envelope_SortPointsEx( env_ptr, -1 )
        end
        if env_ptr then
          DATA2.items[#DATA2.items+1] = {
                          it_ptr = it,
                          tk_ptr = tk,
                          transients = {0},
                          toggle_env = toggle_env,
                          env_ptr=env_ptr
                        }
        end
      end
    end
    DATA2.getstate = true
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Process_ActivateTakeVolEnvelope(item,take)
    local ID = GetMediaItemTakeInfo_Value( take, 'IP_TAKENUMBER' )
    if not item then return end
    -- get
      local chunksrc = ({GetItemStateChunk( item, '', false )})[2]
      local chunk = 'TAKE\n'..chunksrc:match('NAME.*'):gsub('TAKE[%s-]','ENDTAKE\nTAKE '):sub(0,-3)..'ENDTAKE'
      local item_t  = {itemchunk = chunksrc:match('(.-)NAME'), takes = {}} 
      for takeblock in chunk:gmatch('TAKE(.-)ENDTAKE') do 
        local tkid = #item_t.takes+1
        item_t.takes[tkid] = {}
        if takeblock:match('%sSEL%s') then item_t.takes[tkid].selected = true end
        takeblock = takeblock:gsub('%sSEL%s','') 
        item_t.takes[tkid].chunk=takeblock 
      end 
    -- handle active take
      local found_active = false
      for tkid = 1, #item_t.takes do if item_t.takes[tkid].selected == true then item_t.active_take = tkid found_active = true break end end
      if not found_active then item_t.active_take = 1 item_t.takes[1].selected = true end
      
    -- set
      local out_chunk = item_t.itemchunk
      for tkid = 1, #item_t.takes do
        local tkchunksrc = item_t.takes[tkid].chunk:gsub('SPECTRAL_.-[\r\n]','')
        local issel = '' if tkid > 1 and item_t.takes[tkid].selected then  issel = ' SEL' end
        local head = 'TAKE'..issel..'\n'
        if tkid == 1 then head = '' end
        if item_t.takes[tkid].selected then
        
tk_env_chunk = [[       
<VOLENV
EGUID {]]..genGuid( )..[[}
ACT 1 -1
VIS 1 1 1
LANEHEIGHT 0 0
ARM 0
DEFSHAPE 0 -1 -1
VOLTYPE 1
PT 0 1 0
>]]
          tkchunksrc = tkchunksrc..'\n'..tk_env_chunk
        end
        out_chunk = out_chunk..'\n\n'..head..tkchunksrc 
      end
      out_chunk = out_chunk..'\n>'
      
    SetItemStateChunk( item, out_chunk, false )
    UpdateItemInProject( item )
  end
  ------------------------------------------------------------------------------------------  
  function DATA2:Process_SetItemsEnvelopes()
    local attack_max = 0.1 -- at negative attack
    local linear_zero = WDL_DB2VAL(0)
    local pump_mid_pos = 0.1
    
    if not DATA2.items then return end
    for i = 1, #DATA2.items do
      local env = DATA2.items[i]. env_ptr
      local scaling_mode = GetEnvelopeScalingMode( env )
      local linear_zero_scaled = ScaleToEnvelopeMode( scaling_mode, linear_zero )
      DeleteEnvelopePointRangeEx( env, -1, 0, math.huge )
      
      -- init at zero
      SetEnvelopePointEx( env, -1, 0, 
        0, --pos
        ScaleToEnvelopeMode( scaling_mode, 0.01 ),--valueIn, 
        0,--shapeIn, 
        0,--tensionIn, 
        0,--selectedIn, 
        true)--noSortIn )
      
      -- attack
        local attacktime_s
        if DATA.extstate.CONF_attack_khsTS <0 then attacktime_s = math.abs(DATA.extstate.CONF_attack_khsTS)*attack_max else attacktime_s = 10*10^-14 end
        local attack_val = ScaleToEnvelopeMode( scaling_mode, linear_zero )
        if DATA.extstate.CONF_attack_khsTS >=0 then attack_val = ScaleToEnvelopeMode( scaling_mode, 1+DATA.extstate.CONF_attack_khsTS ) end
        InsertEnvelopePointEx( env, -1, 
          DATA.extstate.CONF_rate_khsTS*attacktime_s, --pos
          attack_val,--valueIn, 
          3,--shapeIn, 
          -0.05,--tensionIn, 
          0,--selectedIn, 
          true)--noSortIn )
      
      --pump_mid_pos
        InsertEnvelopePointEx( env, -1, 
          DATA.extstate.CONF_rate_khsTS*(attacktime_s + pump_mid_pos), --pos
          ScaleToEnvelopeMode( scaling_mode, linear_zero+DATA.extstate.CONF_pump_khsTS ),--valueIn, 
          2,--shapeIn, 
          0,--tensionIn, 
          1,--selectedIn, 
          true)--noSortIn ) 
      
      -- sustain
        InsertEnvelopePointEx( env, -1, 
          DATA.extstate.CONF_rate_khsTS*(attacktime_s + pump_mid_pos*2), --pos
          ScaleToEnvelopeMode( scaling_mode, linear_zero+DATA.extstate.CONF_sustain_khsTS ),--valueIn, 
          0,--shapeIn, 
          0,--tensionIn, 
          0,--selectedIn, 
          true)--noSortIn ) 
          
      Envelope_SortPointsEx( env, -1 )
    end
    
    
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init_knob(DATA, t)
    local function vars_form_def(f) if f then return (VF_math_Qdec(f,2)*100)..'%' else return '' end end
    local function vars_formrev_def(v) return tonumber(v)/100 end
    if not t.vars_form then t.vars_form = vars_form_def end
    if not t.vars_formrev then t.vars_formrev = vars_formrev_def end
    DATA.GUI.buttons[t.key] = { x=t.x,
                          y=t.y,
                          w=t.w,
                          h=t.h,
                          txt = t.key..': '..t.vars_form(DATA.extstate[t.confval]),
                          knob_isknob = true,
                          knob_showvalueright = true,
                          val_res = 0.25,
                          val = DATA.extstate[t.confval],
                          frame_a = DATA.GUI.default_framea_normal,
                          val_min = t.val_min,
                          val_max = t.val_max,
                          frame_asel = DATA.GUI.default_framea_normal,
                          back_sela = 0,
                          onmouseclick =    function() DATA2:Process_GetItems() end,
                          onmousedrag =     function() 
                              DATA.extstate[t.confval] = DATA.GUI.buttons[t.key].val
                              DATA.GUI.buttons[t.key].txt = t.key..': '..t.vars_form(DATA.extstate[t.confval])
                              DATA2:Process_SetItemsEnvelopes()
                              DATA.GUI.buttons[t.key].refresh = true
                            end,
                          onmouserelease  = function() 
                              DATA.GUI.buttons[t.key].txt = t.key..': '..t.vars_form(DATA.extstate[t.confval])
                              DATA.extstate[t.confval] = DATA.GUI.buttons[t.key].val 
                              DATA2:Process_SetItemsEnvelopes()
                              Undo_OnStateChange2( 0, 'mpl_Envelope based transient shaper' )  
                              DATA.GUI.buttons[t.key].refresh = true
                              DATA.UPD.onconfchange = true
                            end,
                          onmousereleaseR  = function() 
                            local retval, retvals_csv = GetUserInputs(t.key, 1, '', t.vars_form(DATA.extstate[t.confval]))
                            if not retval then return end
                            
                            local val  = retvals_csv:match('[%d%.%-]+')
                            if not val then return end
                            val =tonumber(val)
                            if not val then return end
                            val =t.vars_formrev(val)
                            
                            DATA.extstate[t.confval] = val 
                            DATA.UPD.onconfchange = true
                            DATA.GUI.buttons[t.key].val = val
                            DATA.GUI.buttons[t.key].txt = t.key..': '..t.vars_form(DATA.extstate[t.confval])
                            DATA.GUI.buttons[t.key].refresh = true
                            DATA2:Process_SetItemsEnvelopes()
                            Undo_OnStateChange2( 0, 'mpl_Envelope based transient shaper' ) 
                          end ,
                          onmousedoubleclick =   function() --reset
                                                  val = t.default_val 
                                                  DATA.extstate[t.confval] = t.default_val 
                                                  DATA.UPD.onconfchange = true
                                                  DATA.GUI.buttons[t.key].val = val
                                                  DATA.GUI.buttons[t.key].txt = t.key..': '..t.vars_form(DATA.extstate[t.confval])
                                                  DATA.GUI.buttons[t.key].refresh = true
                                                  DATA2:Process_SetItemsEnvelopes()
                                                  Undo_OnStateChange2( 0, 'mpl_Envelope based transient shaper' ) 
                                              end,
                          onwheeltrig = function() 
                                          --[[local mult = 0
                                          if not DATA.GUI.wheel_trig then return end
                                          if DATA.GUI.wheel_dir then mult =1 else mult = -1 end
                                          if not DATA2.getstate then DATA2:Process_GetItems()   end
                                          DATA2.val1 = VF_lim(DATA2.val1 - 0.01*mult, 0,1)
                                          DATA.GUI.buttons[t.key].txt = 100*VF_math_Qdec(DATA2.val1,2)..'%'
                                          DATA.GUI.buttons[t.key].val  = DATA2.val1
                                          if DATA.extstate.CONF_act_appbuttoexecute ==0 then 
                                            DATA2:Execute() 
                                            Undo_OnStateChange2( 0, 'QuantizeTool' )  
                                          end 
                                          DATA.GUI.buttons[t.key].refresh = true
                                          DATA.UPD.onconfchange = true]]
                                        end
                        }   
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    --DATA.GUI.default_scale = 2
    
    -- init main stuff
      DATA.GUI.custom_mainbuth = 30*DATA.GUI.default_scale
      DATA.GUI.custom_texthdef = 23
      DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
      DATA.GUI.custom_mainsepx = gfx.w/DATA.GUI.default_scale--(gfx.w/DATA.GUI.default_scale)*0.4-- *DATA.GUI.default_scale--400*DATA.GUI.default_scale--
      DATA.GUI.custom_mainbutw = gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2 --(gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*3
      DATA.GUI.custom_scrollw = 10
      DATA.GUI.custom_frameascroll = 0.05
      DATA.GUI.custom_default_framea_normal = 0.1
      DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
      DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset*3) 
    
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
      DATA.GUI.buttons = {} 
      local knobw = (DATA.GUI.custom_mainbutw)
      
      --[[
      function vars_form_attack(f) if f then return math.floor(1000*  VF_math_Qdec(2*f^2,3)   )..'ms' else return '' end end
      function vars_formrev_attack(v) return math.sqrt((tonumber(v)/1000)/2) end
      function vars_form_attack(f) if f then return math.floor(1000*  VF_math_Qdec(2*f^2,3)   )..'ms' else return '' end end
      function vars_formrev_attack(v) return math.sqrt((tonumber(v)/1000)/2) end
      function vars_form_pump(f) if f then return VF_math_Qdec(f,2)..'dB' else return '' end end
      function vars_formrev_pump(v) return tonumber(v) end
      function vars_form_sustain(f) if f then return VF_math_Qdec(f,2)..'dB' else return '' end end
      function vars_formrev_sustain(v) return tonumber(v) end
      function vars_form_rate(f) if f then return VF_math_Qdec(f,2)..'x' else return '' end end
      function vars_formrev_rate(v) return tonumber(v) end
      ]]
      -- attack
      GUI_RESERVED_init_knob(DATA, {key = 'Attack',
                                    confval = 'CONF_attack_khsTS',
                                    default_val = 0,
                                    val_min = -1,
                                    val_max = 1,
                                    x=DATA.GUI.custom_offset,
                                    y=DATA.GUI.custom_offset,
                                    w =knobw,
                                    h=DATA.GUI.custom_mainbuth,
                                    vars_form = vars_form_attack,
                                    vars_formrev =vars_formrev_attack,
                                    })
      -- pump
      GUI_RESERVED_init_knob(DATA, {key = 'Pump',
                                    confval = 'CONF_pump_khsTS',
                                    default_val = 0,
                                    val_min = -1,
                                    val_max = 1,
                                    x=DATA.GUI.custom_offset,
                                    y=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth,
                                    w =knobw,
                                    h=DATA.GUI.custom_mainbuth,
                                    vars_form = vars_form_pump,
                                    vars_formrev =vars_formrev_pump,
                                    })    

      -- sustain
      GUI_RESERVED_init_knob(DATA, {key = 'Sustain',
                                    confval = 'CONF_sustain_khsTS',
                                    default_val = 0,
                                    val_min = -1,
                                    val_max = 1,
                                    x=DATA.GUI.custom_offset,
                                    y=DATA.GUI.custom_offset*3+DATA.GUI.custom_mainbuth*2,
                                    w =knobw,
                                    h=DATA.GUI.custom_mainbuth,
                                    vars_form = vars_form_sustain,
                                    vars_formrev =vars_formrev_sustain,
                                    })                                       
      -- speed
      GUI_RESERVED_init_knob(DATA, {key = 'Rate',
                                    confval = 'CONF_rate_khsTS',
                                    default_val = 0,
                                    val_min = 0,25,
                                    val_max = 2,
                                    x=DATA.GUI.custom_offset,
                                    y=DATA.GUI.custom_offset*4+DATA.GUI.custom_mainbuth*3,
                                    w =knobw,
                                    h=DATA.GUI.custom_mainbuth,
                                    vars_form = vars_form_rate,
                                    vars_formrev =vars_formrev_rate,
                                    })   
                                    
                                    
      --[[DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_short = (DATA.extstate.CONF_NAME or '[untitled]'),
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA:GUIbut_preset() end}     ]]  
                            

      Rsettings_y = DATA.GUI.custom_offset*4+DATA.GUI.custom_mainbuth*4
      Rsettings_h = gfx.h/DATA.GUI.default_scale-  Rsettings_y
      DATA.GUI.buttons.Rsettings = { x=0,
                            y= Rsettings_y,
                            w=DATA.GUI.custom_mainsepx,
                            h=Rsettings_h,
                            txt = '',
                            --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            frame_a = 0,
                            --offsetframe = DATA.GUI.custom_offset,
                            --offsetframe_a = 0.1,
                            ignoremouse = true,
                            }
      DATA:GUIBuildSettings()
      
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = (gfx.w/DATA.GUI.default_scale)*0.7*DATA.GUI.default_scale
    local SR_spls =tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    
                          
    local  t = 
    {
      {str = 'Mode' ,                          group = 1, itype = 'readout', confkey = 'CONF_mode', level = 0, menu={[0]='kiloHearts Transient Shaper'},readoutw_extw = readoutw_extw},
          -----------------------------------------  
          
    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.16) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end
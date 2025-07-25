-- @description RS5k StepSequencer
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @noindex


reaper.set_action_options(1 )



    
--------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < 6.73 then return reaper.MB('This script require REAPER 6.73+','',0) end
    --local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.9.3.2'
    
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          ------ 4.43 RS5k manager START ------------
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 800,
          viewport_posH = 300, 
          viewport_dockID = 0,
          
          
          -- rs5k on add
          CONF_onadd_float = 0,
          CONF_onadd_obeynoteoff = 1,
          CONF_onadd_customtemplate = '',
          CONF_onadd_renametrack = 1,
          CONF_onadd_copytoprojectpath = 0, 
          CONF_onadd_copysubfoldname = 'RS5kmanager_samples' ,
          CONF_onadd_newchild_trackheightflags = 0, -- &1 folder collapsed &2 folder supercollapsed &4 hide tcp &8 hide mcp
          CONF_onadd_newchild_trackheight = 0,
          CONF_onadd_whitekeyspriority = 0,
          CONF_onadd_ordering = 0, -- 0 sorted by note 1 at the top 2 at the bottom
          CONF_onadd_takeparentcolor = 0,
          CONF_onadd_autosetrange = 0,
          CONF_onadd_renameinst = 0,
          CONF_onadd_renameinst_str = 'RS5k',
          CONF_onadd_autoLUFSnorm = -14, 
          CONF_onadd_autoLUFSnorm_toggle = 0, 
          CONF_onadd_sysexmode = 0,
          
          CONF_onadd_ADSR_flags = 0,--&1 A &2 D &4 S &8 R
          CONF_onadd_ADSR_A = 0,
          CONF_onadd_ADSR_D = 15,
          CONF_onadd_ADSR_S = 0,
          CONF_onadd_ADSR_R = 0.02,
          
          -- midi bus 
          CONF_midiinput = 63, -- 63 all 62 midi kb
          CONF_midichannel = 0, -- 0 == all channels 
          CONF_midioutput = -1, 
          
          -- sampler
          CONF_cropthreshold = -60, -- db
          CONF_crop_maxlen = 30,
          CONF_default_velocity = 120,
          CONF_stepmode = 0,
          CONF_stepmode_transientahead = 0.01,
          CONF_stepmode_keeplen = 1, 
          
          -- UI
          UI_transparency = 0.9,
          UI_processoninit = 0,
          UI_addundototabclicks = 0,
          UI_clickonpadselecttrack = 1, 
          UI_clickonpadscrolltomixer = 1,
          UI_incomingnoteselectpad = 0,
          UI_defaulttabsflags = 1|4|8, --1=drumrack   2=device  4=sampler 8=padview 16=macro 32=database 64=midi map 128=children chain
          UI_pads_sendnoteoff = 1,
          UI_drracklayout = 0,
          UIdatabase_maps_current = 1,
          UI_padcustomnames = '',
          UI_padcustomnamesB64 = '', -- patch for 4.57
          UI_padautocolors = '',
          UI_padautocolorsB64 = '',-- patch for 4.57
          CONF_showplayingmeters = 1,
          CONF_showpadpeaks = 1,
          --UI_optimizedockerusage = 0,
          UI_colRGBA_paddefaultbackgr = 0x606060FF ,
          UI_colRGBA_paddefaultbackgr_inactive = 0x6060603F,
          UI_col_tinttrackcoloralpha = 0x7F,
          UI_allowshortcuts = 1,
          
          -- other 
          CONF_autorenamemidinotenames = 1|2, 
          CONF_trackorderflags = 0,  -- ==0 sort by date ascending, ==2 sort by date descending, ==3 sort by note ascending, ==4 sort by note descending
          CONF_autoreposition = 0, --0 off
          
          -- 3rd party
          CONF_plugin_mapping_b64 = '', 
          
          -- database 
          CONF_ignoreDBload = 0, 
          CONF_database_map1 = '',
          CONF_database_map2 = '',
          CONF_database_map3 = '',
          CONF_database_map4 = '',
          CONF_database_map5 = '',
          CONF_database_map6 = '',
          CONF_database_map7 = '',
          CONF_database_map8 = '',
          
          
          -- actions
          CONF_importselitems_removesource = 0,
          
          -- auto color
          CONF_autocol = 0, -- 1 sort by note 

          
          -- loop check
          CONF_loopcheck = 1, 
          CONF_loopcheck_minlen = 2,
          CONF_loopcheck_maxlen = 8,
          CONF_loopcheck_filter = 'bd,bass,kick',
          
          ------ 4.43 RS5k manager END ------------
          
          
          -- seq
          CONF_seq_random_probability = 0.5,
          CONF_seq_force_GUIDbasedsharing = 0,
          CONF_seq_treat_mouserelease_as_majorchange  = 0,
          CONF_seq_patlen_extendchildrenlen = 0,
          CONF_seq_instrumentsorder = 1,
          CONF_seq_stuffMIDItoLP = 0,  
          CONF_seq_defaultstepcnt = 16,
          CONF_seq_env_clamp = 1, -- 0 == allow env points on empty steps
          CONF_seq_steplength = 0.25,
         }
        
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          
          seq_functionscall = true,
          scheduler = {},
          
          upd = true,
          upd2 = {
            refreshpeaks = true,
          },
          ES_key = 'MPL_RS5K manager',
          UI_name = 'RS5K StepSequencer', 
          version = 4, -- for ext state save
          bandtypemap = {  
                  [-1] = 'Off',
                  [3] = 'Low pass' ,
                  [0] = 'Low shelf',
                  [1] = 'High shelf' ,
                  [8] = 'Band' ,
                  [4] = 'High pass' ,
                  --[5] = 'All pass' ,
                  --[6] = 'Notch' ,
                  --[7] = 'Band pass' ,
                  --[10] = 'Parallel BP' ,
                  --[9] = 'Band alt' ,
                  --[2] = 'Band alt2' ,
                  },
          playingnote = -1,
          playingnote_trigTS = 0,
          MIDI_inputs = {},
          MIDI_outputs = {},
          lastMIDIinputnote = {},
          reaperDB = {},
          MIDIOSC = {}, 
          actions_popup = {},
          VCA_mode = 0,
          plugin_mapping = {},
          settings_cur_note_database =0,
          padcustomnames = {},
          padautocolors = {},
          padcustomnames_selected_id = 1,
          padautocolors_selected_id = 1,
          
          loopcheck_trans_area_frame = 10, 
          loopcheck_testdraw = 0, 
          
          min_steplength = 2^-5, --0,03125
          max_steplength = 2^0, -- 1
          
          peakscache = {},
          boundarystep = {
            [0] = {str='1ms',val=0.001},
            [1] = {str='5ms',val=0.005},
            [2] = {str='10ms',val=0.01},
            [3] = {str='20ms',val=0.02},
            [4] = {str='100ms',val=0.1},
            [4] = {str='200ms',val=0.2},
            [5] = {str='1/8 beat',val=-0.125},
            [6] = {str='1/4 beat',val=-0.25},
            [7] = {str='1/2 beat',val=-0.5},
            [8] = {str='beat',val=-1},
            [9] = {str='bar',val=-4},
            [10] = {str='next transient',val=-100},
          },
          
          seq = {} ,
          
          allow_space_to_play = true, 
          allow_container_usage = app_vrs >=7.06,
          MIDIhandler = 'RS5k_manager MIDI_handler',
          
          seq_param_selectorID = 1,
          seq_param_selector = { 
            {param = 'velocity', str= 'Velocity',default=120/127, maxval = 1, minval = 1/127},
            {param = 'offset', str= 'Offset',default=0, maxval = 0.95, minval = -0.95},
            {param = 'split', str= 'Split',default=1, maxval = 8, minval = 1},
            {param = 'steplen_override', str= 'Length',default=1, maxval = 4, minval = 0.1},
            {param = 'meta', str= 'Meta'},
            {param = 'trackenv', str= 'Track'},
            {param = 'trackFXenv', str= 'FX'},
          },
          
          seq_param_selector_metaID = 1,
          seq_param_selector_meta = { 
            {param = 'meta_pitch', str= 'Pitch',default=64, minval = 64-24, maxval = 64+24},
            {param = 'meta_probability', str= 'Probability',default=1, minval = 0, maxval = 1},
          }, 
          
          seq_param_selector_trackenvID = 1,
          seq_param_selector_trackenv = {},
          
          seq_param_selector_trackFXenvID = 1,
          seq_param_selector_trackFXenv = {},
          
          seq_horiz_scroll = 0,
          seq_patlen_extendchildrenlen = 0,
          seq_UI_inlineH_area = 285,
          seq_init_Yscroll = 0,
          seq_LPstepseqmode = 0,
          
          }
  DATA.UI_name_vrs = DATA.UI_name--..' '..StepSequencer_vrs
  
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
      -- font
        font='Arial',
        font1sz=15,
        font2sz=14,
        font3sz=13,
        font4sz=12,
        font5sz=11,
      -- mouse
        hoverdelay = 0.8,
        hoverdelayshort = 0.5,
      -- size / offset
        spacingX = 4,
        spacingY = 3,
      -- colors / alpha
        main_col = 0x7F7F7F, -- grey
        textcol = 0xFFFFFF, -- white
        textcol_a_enabled = 1,
        textcol_a_disabled = 0.5,
        but_hovered = 0x878787,
        windowBg = 0x303030,
          }
  
    -- size
    UI.w_min = 640
    UI.h_min = 300
    UI.settingsfixedW = 450
    UI.actionsbutW = 60
    UI.settings_itemW = 180 
    UI.settings_indent  = 10
    UI.knob_resY = 150
    UI.sampler_peaksH = 60
    UI.sampler_peaksfullH = 30
    UI.controls_minH = 40
    UI.adsr_rectsz = 10
    UI.scrollbarsz = 10
    
    -- colors
    UI.col_maintheme = 0x00B300 
    UI.col_red = 0xB31F0F  
    UI.colRGBA_selectionrect = 0xF0F0F0<<8|0x9F  
    --EXT.UI_colRGBA_paddefaultbackgr = 0x7070705F  
    --EXT.UI_colRGBA_paddefaultbackgr_inactive = 0x60606040
    UI.colRGBA_ADSRrect = 0x00AF00DF
    UI.colRGBA_ADSRrectHov = 0x00FFFFFF 
    UI.padplaycol = 0x00FF00 
    UI.knob_handle = 0xc8edfa
    UI.knob_handle_normal = UI.knob_handle
    UI.knob_handle_vca =0xFF0000
    UI.knob_handle_vca2 =0xFFFF00
    UI.col_popup = 0x005300 
    
    -- various
    UI.tab_context = '' -- for context menu
    
    -- mouse
    UI.dragY_res = 10
    
    -- seq
    UI.seq_stepW = 24
    UI.seq_padH = 28
    UI.seq_separatorH = 3
    UI.seq_padnameW = 120
    UI.seq_activestep_reducesz = 2 
    UI.seq_audiolevelW = 5 
    UI.seq_stepreduceW = 2 
    UI.seq_steprounding = 2
    UI.seq_maxstepcnt = 1024
    
  
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_Step(note_t, x0,y0)  
    if not note_t then return end 
    
    local note= note_t.noteID 
    if not (DATA.seq and DATA.seq.ext and DATA.seq.ext.children and DATA.seq.ext.children[note] and DATA.seq.ext.children[note].step_cnt) then return end
    
    
    if not DATA.seq.ext.patternlen then return end
    
    function __f_draw_Seq_Step() end
    ImGui.SetCursorPosX(ctx, UI.calc_seqXL_steps)
    if x0 and y0 then ImGui.SetCursorPos(ctx, x0,y0) end
    
    -- loop steps
    local stepcol_1 = 0xFFFFFF00
    local stepcol_2 = 0x3FDF3F30
    local stepcol_inactive = 0x4F4F4F1F
    local step_cnt = DATA.seq.ext.children[note].step_cnt
    if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen end
    for activestep = DATA.seq.stepoffs+1, DATA.seq.ext.patternlen do
      -- colors/state
        local stepcol = stepcol_1
        if (activestep-1)%8> 3 then stepcol = stepcol_2 end
        if activestep > step_cnt then stepcol = stepcol_inactive end
        
      -- body
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,UI.seq_steprounding) 
        ImGui.Button(ctx, '##stepseq'..note..'step'..activestep, UI.seq_stepW,UI.seq_padH)  
        ImGui.PopStyleColor(ctx)
        ImGui.PopStyleVar(ctx) 
        x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
        x2, y2 = reaper.ImGui_GetItemRectMax( ctx ) 
        ImGui.DrawList_AddRectFilled( UI.draw_list, x1, y1,x2-1, y2-1, stepcol|0x1F, UI.seq_steprounding, ImGui.DrawFlags_None )
      
      -- separator
        if activestep%16==1 then
          ImGui.DrawList_AddLine( UI.draw_list, x1, y1+1,x1, y2-2, stepcol|0x7F, 1 )
        end
        
      -- fill step 
        local hstep = (y2-y1)-UI.seq_activestep_reducesz*4
        local wstep = (x2-x1)-UI.seq_activestep_reducesz*4
        if DATA.seq.ext and DATA.seq.ext.children and DATA.seq.ext.children[note] and DATA.seq.ext.children[note].steps then
          local activestep_fill = activestep
          if activestep > step_cnt then activestep_fill = 1+(activestep-1)%step_cnt end
          
          if DATA.seq.ext.children[note].steps[activestep_fill] and DATA.seq.ext.children[note].steps[activestep_fill].val and DATA.seq.ext.children[note].steps[activestep_fill].val > 0 then
            local val = DATA.seq.ext.children[note].steps[activestep_fill].val
            local velocity = DATA.seq.ext.children[note].steps[activestep_fill].velocity
            if velocity then val = velocity end
            local width = 1
            if DATA.seq.ext.children[note].steps[activestep_fill].steplen_override then width = math.max(0.2,DATA.seq.ext.children[note].steps[activestep_fill].steplen_override) end
            
            ImGui.DrawList_AddRectFilled( UI.draw_list, 
              x1+UI.seq_activestep_reducesz*2,
              y1+UI.seq_activestep_reducesz*2 + hstep-hstep*val,
              x1+UI.seq_activestep_reducesz*2 + wstep*width,
              y2-UI.seq_activestep_reducesz*2, 
              stepcol|0x6F, UI.seq_steprounding, ImGui.DrawFlags_None )
          end
        end  
        
      -- split val
        if activestep <= step_cnt and DATA.seq.ext and DATA.seq.ext.children and DATA.seq.ext.children[note] and DATA.seq.ext.children[note].steps and DATA.seq.ext.children[note].steps[activestep] and DATA.seq.ext.children[note].steps[activestep].split then
          local split = math_q(DATA.seq.ext.children[note].steps[activestep].split)
          if split ~=1 then
            ImGui.DrawList_AddText( UI.draw_list, x1+UI.seq_activestep_reducesz, y1+UI.seq_activestep_reducesz, 0xFFFFFFFF, split )
          end
        end

      -- offset val
        if activestep <= step_cnt and DATA.seq.ext and DATA.seq.ext.children and DATA.seq.ext.children[note] and DATA.seq.ext.children[note].steps and DATA.seq.ext.children[note].steps[activestep] and DATA.seq.ext.children[note].steps[activestep].offset and DATA.seq.ext.children[note].steps[activestep].offset~=0 then
          local offset = DATA.seq.ext.children[note].steps[activestep].offset
          local fullwstep = (x2-x1)-UI.seq_activestep_reducesz*4
          local xpos = x1 + UI.seq_activestep_reducesz*2 + fullwstep/2+ offset * fullwstep/2
          ImGui.DrawList_AddLine( UI.draw_list, 
            xpos,
            y2-UI.seq_activestep_reducesz*2-1,
            xpos,
            y2-UI.seq_activestep_reducesz*2-5, 
            stepcol|0x9F,2 )
        end
        
      -- play cursor
        if DATA.seq.active_step and DATA.seq.active_step[note] and DATA.seq.active_step[note] == activestep then
          midx = x1 + (x2-x1)/2 
          midy = y1 + UI.seq_padH/2 
          ImGui.DrawList_AddCircleFilled( UI.draw_list, midx, midy, 4, stepcol|0x9F, 0 )
        end        
        
      -- handle mouse
        local trig_change
        if activestep <= step_cnt then
          if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_AllowWhenBlockedByPopup ) and ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Left, 0 ) then 
            trig_change = 1
           elseif ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_AllowWhenBlockedByPopup ) and ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Right, 0 ) then
            trig_change = 0
          end
          
          if trig_change then 
            if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
            if not DATA.seq.ext.children[note].steps[activestep] then DATA.seq.ext.children[note].steps[activestep] = {} end
            
            DATA.seq.ext.children[note].steps[activestep].val = trig_change
            
            local mx, my = reaper.ImGui_GetMousePos( ctx )
            DATA.temp_holdmode_mx=mx
            DATA.temp_holdmode_my=my
            DATA.temp_holdmode_note=note
            DATA.temp_holdmode_value = trig_change
            DATA.temp_holdmode = note 
            DATA.temp_holdmode_stepline = math.floor((activestep-1)/16)
            DATA.temp_holdmode_step = activestep
            if DATA.parent_track.ext.PARENT_LASTACTIVENOTE~=note then 
              DATA.parent_track.ext.PARENT_LASTACTIVENOTE=note
              gmem_write(1025,10 ) -- push a trigger to refresh Rack
              DATA:WriteData_Parent() 
            end
          end     
          
        end
        
        
      ImGui.SameLine(ctx)
      --ImGui.Dummy(ctx,UI.spacingY,0)
    end
    
    
    -- handle mouse over sequencer
    UI.draw_Seq_Step_handlemouse()
    ImGui.SameLine(ctx)
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_Step_handlemouse()   
    if not (DATA.temp_holdmode_value and DATA.temp_holdmode and DATA.temp_holdmode_stepline and DATA.temp_holdmode_step ) then return end
    
    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) or ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Right) then 
      DATA.temp_holdmode_value =nil
      DATA.temp_holdmode =nil
      DATA.temp_holdmode_stepline = nil
      DATA.temp_holdmode_step = nil
      --DATA:_Seq_Print()
      DATA.upd2.seqprint = true
      --DATA.upd = true
      if DATA.parent_track.ext.PARENT_LASTACTIVENOTE~=DATA.temp_holdmode_note then 
        DATA.parent_track.ext.PARENT_LASTACTIVENOTE=DATA.temp_holdmode_note
        DATA:WriteData_Parent() 
      end
      return
    end
    
    local dx, dy = reaper.ImGui_GetMouseDelta( ctx )
    if dx == 0 then return end
    
    local active_note = DATA.temp_holdmode 
    local xsteps = UI.calc_seqX + UI.calc_seqXL_steps
    local mx, my = reaper.ImGui_GetMousePos( ctx )
    --[[local v = (mx-xsteps) /(UI.calc_seqW_steps_window)
    local normval = math.floor(16 * v) + 1
    local step2 = VF_lim(normval,1,16)]]
    local dx = mx - DATA.temp_holdmode_mx
    local step1 = DATA.temp_holdmode_step
    local step2 = math_q(step1 + dx/UI.seq_stepW)
    --[[msg('=')
    msg(dx)
    msg(step1)
    msg(step2)]]
    local s1,s2 = step1, step2
    if step2<step1 then s1,s2 = step2, step1 end
    
    local step_cnt = DATA.seq.ext.children[active_note].step_cnt
    if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen end
    s2=math.min(s2, step_cnt)
    
    if not DATA.seq.ext.children[active_note] then DATA.seq.ext.children[active_note] = {} end
    if not DATA.seq.ext.children[active_note].steps then DATA.seq.ext.children[active_note].steps = {} end 
    for step = s1,s2 do
      local out = DATA.temp_holdmode_value
      if not DATA.seq.ext.children[active_note].steps[step] then DATA.seq.ext.children[active_note].steps[step] = {} end
      
      -- set step to 0 remove data -DO NOT USE
      --[[if out == 0 and DATA.seq.ext.children[active_note].steps[step] then 
        DATA.seq.ext.children[active_note].steps[step] = nil 
       elseif not (DATA.seq.ext.children[active_note].steps[step].val and DATA.seq.ext.children[active_note].steps[step].val == out)  then  
        DATA.seq.ext.children[active_note].steps[step].val = out 
        local minor_change = true
        DATA.upd2.seqprint = true
        DATA.upd2.seqprint_minor = true
      end]]
      
      
      if not (DATA.seq.ext.children[active_note].steps[step].val and DATA.seq.ext.children[active_note].steps[step].val == out)  then  
        DATA.seq.ext.children[active_note].steps[step].val = out 
        local minor_change = true
        --DATA:_Seq_Print(nil, minor_change)
        DATA.upd2.seqprint = true
        DATA.upd2.seqprint_minor = minor_change
      end
      
    end 
    
    
  end  
  --------------------------------------------------------------------------------  
  function UI.transparentButton(ctx, str_id, w,h)
    ImGui.PushFont(ctx, DATA.font4) 
    UI.draw_setbuttonbackgtransparent()
    ImGui.Button(ctx, str_id, w,h)
    UI.Tools_unsetbuttonstyle()
    ImGui.PopFont(ctx) 
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_ctrls(note_t)
    
    --function __f_draw_Seq_ctrls() end
    local note= note_t.noteID
    if not (DATA.seq and DATA.seq.ext and DATA.seq.ext.children and DATA.seq.ext.children[note] and DATA.seq.ext.children[note].step_cnt) then return end
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,1,1) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,1, 1) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX, 1)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
    ImGui.PushFont(ctx, DATA.font4) 
    
    -- mute
      local ismute = note_t and note_t.B_MUTE and note_t.B_MUTE == 1
      if ismute==true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF0F0FF0 ) end
      if note_t and ImGui.Button(ctx,'M##rackpad_mute'..note,UI.calc_seq_ctrl_butW,UI.seq_padH-1 ) then SetMediaTrackInfo_Value( note_t.tr_ptr, 'B_MUTE', note_t.B_MUTE~1 ) DATA.upd = true end  --UI.calc_seq_ctrl_butH
      if ismute==true then ImGui.PopStyleColor(ctx) end
      ImGui.SameLine(ctx)
      
    -- solo
      local issolo = note_t and note_t.I_SOLO and note_t.I_SOLO > 0 
      if issolo == true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x00FF0FF0 ) end
      if note_t and ImGui.Button(ctx,'S##rackpad_solo'..note,UI.calc_seq_ctrl_butW,UI.seq_padH-1 ) then
        if note_t and note_t.tr_ptr then 
          local outval = 2 if note_t.I_SOLO>0 then outval = 0 end SetMediaTrackInfo_Value( note_t.tr_ptr, 'I_SOLO', outval ) DATA.upd = true
        end 
      end   
      if issolo == true then ImGui.PopStyleColor(ctx) end
      ImGui.SameLine(ctx)
      
      
    -- step_cnt
      local xabsstepcnt, yabsstepcnt = reaper.ImGui_GetCursorScreenPos(ctx)
      local step_cnt = DATA.seq.ext.children[note].step_cnt
      if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen end
      local floor = true
      local default = -1
      local retval, v, deact,rightclick,mousewheel = UI.VDragInt( ctx, '##step_cnt'..note, UI.calc_seq_ctrl_butW, UI.seq_padH-1, step_cnt, 1, DATA.seq.ext.patternlen,  step_cnt, ImGui.SliderFlags_None, floor, default)
      if retval and DATA.seq.ext.children[note].step_cnt ~= v then
        DATA.seq.ext.children[note].step_cnt = v
      end
      if deact==true then DATA:_Seq_Print() end
      if rightclick == true then ImGui.OpenPopup( ctx, 'step_cnt'..note, ImGui.PopupFlags_None )  end
      if mousewheel then
        if mousewheel > 0 then DATA.seq.ext.children[note].step_cnt = VF_lim(step_cnt * 2,1,DATA.seq.ext.patternlen) else DATA.seq.ext.children[note].step_cnt = VF_lim(math.floor(step_cnt / 2),1,DATA.seq.ext.patternlen) end
        DATA:_Seq_Print()
      end
      ImGui.SameLine(ctx) 
      ImGui.SetItemTooltip(ctx,'Step count')
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,2)   
      ImGui.PushFont(ctx, DATA.font1) 
      if reaper.ImGui_BeginPopup(ctx,'step_cnt'..note) then
        local posx,posy = ImGui.GetCursorPos(ctx)
        local set
        ImGui.Indent(ctx,10)
        ImGui.SeparatorText(ctx,'Step count')
        local num = {-1,4,8,16,24,32,64,128}
        for i = 1, #num do
          local setnum = num[i]
          local str = setnum..' steps'
          if setnum == -1 then str = 'Follow pattern length' end
          if DATA.seq.ext.patternlen >=setnum or setnum == -1 then
            if ImGui.Selectable(ctx, str, setnum == DATA.seq.ext.children[note].step_cnt, reaper.ImGui_SelectableFlags_None(), 150) then set = setnum end 
          end
        end
        if set then
          DATA.seq.ext.children[note].step_cnt = set
          DATA:_Seq_Print()
          reaper.ImGui_CloseCurrentPopup(ctx)
        end
        
        ImGui.SeparatorText(ctx,'Actions')
        local allow_print_to_full = DATA.seq.ext.children[note].step_cnt ~= -1 and DATA.seq.ext.children[note].step_cnt < DATA.seq.ext.patternlen 
        if allow_print_to_full~=true then ImGui.BeginDisabled(ctx, true)  end
          if ImGui.Selectable(ctx, 'Print to full pattern length', nil, reaper.ImGui_SelectableFlags_None(), 150) then DATA:_Seq_FillNoteStepsToFullLength(note) end  
        if allow_print_to_full~=true then ImGui.EndDisabled(ctx)  end
        
        
        ImGui.Unindent(ctx,10)
        ImGui.Dummy(ctx,0,UI.spacingY)
        reaper.ImGui_EndPopup(ctx)
      end
      ImGui.PopFont(ctx) 
      ImGui.PopStyleVar(ctx)      
      
      
    -- step_cnt step_len LED
      if DATA.seq.ext.children[note].steplength~=0.25 then
        local tri_sz =5
        ImGui_DrawList_AddTriangleFilled( UI.draw_list, xabsstepcnt-tri_sz+UI.calc_seq_ctrl_butW, yabsstepcnt, xabsstepcnt+UI.calc_seq_ctrl_butW, yabsstepcnt, xabsstepcnt+UI.calc_seq_ctrl_butW, yabsstepcnt+tri_sz, 0x00FF00FF )
      end   

      -- track vol
      local note_layer_t = DATA.children[note]
      if not (DATA.children[note].TYPE_DEVICE and DATA.children[note].TYPE_DEVICE == true) then 
        if DATA.children[note].layers and DATA.children[note].layers[1] then note_layer_t = DATA.children[note].layers[1] end
      end
      if note_layer_t and note_layer_t.D_VOL then 
        local curposx_abs, curposy_abs = reaper.ImGui_GetCursorScreenPos(ctx)
        UI.draw_knob(
          {str_id = '##spl_trvol'..note,
          is_micro_knob = true,
          val = math.min(1,note_layer_t.D_VOL/2), 
          default_val = 0.5,
          x = curposx_abs, 
          y = curposy_abs,
          w = UI.calc_seq_ctrl_butW,
          h = UI.seq_padH-1,
          name = 'Volume',
          val_form = note_layer_t.D_VOL_format,
          appfunc_atclick = function(v)   end,
          appfunc_atdrag = function(v)  
            note_layer_t.D_VOL =v *2
            SetMediaTrackInfo_Value( note_layer_t.tr_ptr, 'D_VOL', v *2 )
          end,
          })
        ImGui.SameLine(ctx)
        local curposx_abs, curposy_abs = reaper.ImGui_GetCursorScreenPos(ctx)
        UI.draw_knob(
          {str_id = '##spl_trpan'..note,
          is_micro_knob = true,
          centered = true,
          val = note_layer_t.D_PAN, 
          val_max = 1, 
          val_min = -1, 
          default_val = 0,
          x = curposx_abs, 
          y = curposy_abs,
          w = UI.calc_seq_ctrl_butW,
          h = UI.seq_padH-1,
          name = 'Volume',
          val_form = note_layer_t.D_PAN_format,
          appfunc_atclick = function(v)   end,
          appfunc_atdrag = function(v)  
            note_layer_t.D_PAN =v
            SetMediaTrackInfo_Value( note_layer_t.tr_ptr, 'D_PAN', v )
          end,
          })          
      end
      ImGui.SameLine(ctx)
      
      
      
    -- name  
      -- define txt
        local note_format = VF_Format_Note(note,note_t)
        if note_format then
          if EXT.UI_drracklayout == 2 then note_format = note_format..' ('..note..')' end
          if DATA.padcustomnames[note] and DATA.padcustomnames[note] ~= '' then note_format = DATA.padcustomnames[note] end
          if  DATA.parent_track.padcustomnames_overrides and DATA.parent_track.padcustomnames_overrides[note] and DATA.parent_track.padcustomnames_overrides[note] ~= '' then note_format = DATA.parent_track.padcustomnames_overrides[note] end
         else
          note_format = ''
        end
        
        
        --if DATA.padcustomnames[note] and DATA.padcustomnames[note] ~= '' then note_format = DATA.padcustomnames[note] end
        --if  DATA.parent_track.padcustomnames_overrides and DATA.parent_track.padcustomnames_overrides[note] and DATA.parent_track.padcustomnames_overrides[note] ~= '' then note_format = DATA.parent_track.padcustomnames_overrides[note] end
        
        
        local str_maxlen = 20
        if note_format:len()> str_maxlen then note_format = '...'..note_format:sub(-str_maxlen) end
      -- define color
        local color
        if note_t and note_t.I_CUSTOMCOLOR then 
          color = ImGui.ColorConvertNative(note_t.I_CUSTOMCOLOR) 
          color = color & 0x1000000 ~= 0 and (color << 8) | EXT.UI_col_tinttrackcoloralpha-- https://forum.cockos.com/showpost.php?p=2799017&postcount=6
        end 
        if not color then color = EXT.UI_colRGBA_paddefaultbackgr end
        -- if not color then color = EXT.UI_colRGBA_paddefaultbackgr end 
      
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, color)
      local name_localx = reaper.ImGui_GetCursorPosX(ctx)
      
      -- fill name
      --local x1,y1= ImGui_GetCursorScreenPos(ctx)
      --ImGui.DrawList_AddRectFilled( UI.draw_list, x1,y1,x1 + UI.seq_padnameW,y1+UI.seq_padH-1, color or EXT.UI_colRGBA_paddefaultbackgr , 10, ImGui.DrawFlags_None )
      
      ImGui.Button(ctx,note_format..'##rackpad_name'..note,UI.seq_padnameW,UI.seq_padH-1 )
      local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
      local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
      if color then ImGui.PopStyleColor(ctx) end
       DATA.children[note].seq_yA={}
       DATA.children[note].seq_yA[0] = y1 -- print for note_seq_params popup
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
        DATA.temp_stepline = 0
        gmem_write(1025,10 ) -- push a trigger to refresh Rack
        ImGui.OpenPopup( ctx, 'note_seq_params'..note, ImGui.PopupFlags_None ) 
      end
      
    -- LED database / defice
      if DATA.children[note] then
        local offs = 5
        local ledyspace = 2
        local sz = 4
        local ledx= x1+offs--sz
        local ledy= y1+offs 
        if DATA.children[note].SYSEXMOD == true then                      ImGui.DrawList_AddRectFilled( UI.draw_list, ledx, ledy, ledx+sz, ledy+sz, 0xF0FF50FF, 0, ImGui.DrawFlags_None) ledy=ledy+offs+ledyspace end
      end          
          
          
      UI.draw_Rack_Pads_controls_handlemouse(note_t,note, 'seq_pad')
      
    -- peaks 
      if  DATA.children[note] and DATA.children[note].layers and  DATA.children[note].layers[1] and  DATA.peakscache[note] and  DATA.peakscache[note].peaks_arr  then 
        local is_pad_peak = true
        local dim = true
        UI.draw_peaks('padseq'..note, note_t,  x1, y1, x2-x1, y2-y1,DATA.peakscache[note].peaks_arr, is_pad_peak, dim) 
      end
    -- selection 
      if (DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE  == note) then 
        ImGui.DrawList_AddRect( UI.draw_list, x1, y1+1, x2, y2-1, UI.colRGBA_selectionrect, 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
      end  
    -- levels
      local peak_w = UI.seq_audiolevelW
      local xP = x1 + UI.seq_padnameW + 1
      local yP = y1+1
      local hP = y2-y1-3
      if DATA.children[note] and DATA.children[note].peaksRMS_L and (DATA.children[note].peaksRMS_L>0.001 or DATA.children[note].peaksRMS_R >0.001 )then
        local val = math.min((DATA.children[note].peaksRMS_L+DATA.children[note].peaksRMS_R)/2,1)
        ImGui.DrawList_AddRectFilled( UI.draw_list, xP, yP+hP - hP*val+1 , xP+peak_w, yP+hP, UI.col_maintheme<<8|0xFF, 0, ImGui.DrawFlags_RoundCornersTop) 
        if val > 0.9 then ImGui.DrawList_AddLine( UI.draw_list, xP, yP+1 , xP+peak_w, yP+1, 0xFF0000FF, 1) end 
      end
      
      
    ImGui.PopStyleVar(ctx, 4) 
    ImGui.PopFont(ctx) 
    
    -- inline 
      UI.draw_Seq_ctrls_inline(note_t)    
    
      
    --ImGui.Dummy(ctx,0,UI.spacingY) 
    
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_ctrls_inline_handlemouse(note_t)
    local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
    local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
    
    local note = note_t.noteID
    local parameter, maxval, minval, default_val, parameter_parent = UI.draw_Seq_ctrls_inline_getactiveparam()
    
    
      --reaper.ImGui_CloseCurrentPopup(ctx)
    if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left) or ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) and not ImGui.IsKeyDown(ctx,ImGui.Mod_Alt) then
      local x, y = reaper.ImGui_GetMousePos( ctx )
      DATA.temp_seq_params =
        {x = x,--(x-x1) / (x2-x1),
         y = y,--(y-y1) / (y2-y1),
         }
    end
    
    if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left) and ImGui.IsKeyDown(ctx,ImGui.Mod_Alt) then 
      local x, y = reaper.ImGui_GetMousePos( ctx )
      local x_norm = VF_lim((x-x1) / (x2-x1)) 
      local active_step = math.ceil(x_norm * UI.calc_seqW_steps_visible + DATA.seq.stepoffs)
      
      if parameter:match('env_') then 
        DATA.seq.ext.children[note].steps[active_step][parameter] = nil
       else 
        DATA.seq.ext.children[note].steps[active_step][parameter] = default_val
      end
      
      DATA.seq.ext.children[note].steps[0][parameter] = 0
      DATA:_Seq_Print()
    end
    
    if (ImGui.IsMouseDown( ctx, ImGui.MouseButton_Left ) or ImGui.IsMouseDown( ctx, ImGui.MouseButton_Right )) 
      and DATA.temp_seq_params and not ImGui.IsKeyDown(ctx,ImGui.Mod_Alt)
      --and (ImGui.IsMouseDragging( ctx, ImGui.MouseButton_Left, 0 ) or ImGui.IsMouseDragging( ctx, ImGui.MouseButton_Right, 0 )) 
      then
      local dx, dy = reaper.ImGui_GetMouseDelta( ctx )
      if dx ~= 0 or dy~=0 then
        local x, y = reaper.ImGui_GetMousePos( ctx )
        --DATA.temp_seq_params.dx = DATA.temp_seq_params.x - x
        --DATA.temp_seq_params.dy = DATA.temp_seq_params.y - y 
        DATA.temp_seq_params.x1_norm = VF_lim((DATA.temp_seq_params.x-x1) / (x2-x1))
        DATA.temp_seq_params.x2_norm = VF_lim((x-x1) / (x2-x1))
        DATA.temp_seq_params.y1_norm = 1-VF_lim((DATA.temp_seq_params.y-y1) / (y2-y1))
        DATA.temp_seq_params.y2_norm = 1-VF_lim((y-y1) / (y2-y1)) 
        UI.draw_Seq_ctrls_inline_appstuff(note_t,ImGui.IsMouseDown( ctx, ImGui.MouseButton_Right )) 
        
      end
    end
    
    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) or ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Right) then 
      DATA:_Seq_Print()
      DATA.temp_seq_params = nil
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_ctrls_inline_tools(note_t, posx,posy) 
    if not note_t then return end
    local note= note_t.noteID
    
    local butw = (UI.seq_padnameW-UI.spacingX*2)/3
    local butw_3x = UI.seq_padnameW
    local butw_15x = (UI.seq_padnameW-UI.spacingX)/2
    ImGui.PushFont(ctx,DATA.font3)
    
    -- fill ------------------------------------
    ImGui.SeparatorText(ctx, 'Fill')
    if ImGui.Button(ctx,'Fill each 2 steps', butw_3x) then DATA:_Seq_Fill(note, '10') DATA:_Seq_Print() end 
    if ImGui.Button(ctx,'Fill each 4 steps', butw_3x) then DATA:_Seq_Fill(note, '1000') DATA:_Seq_Print() end  
    if ImGui.Button(ctx,'Fill each 8 steps', butw_3x) then DATA:_Seq_Fill(note, '10000000') DATA:_Seq_Print() end 
    
    -- tools ------------------------------------
    ImGui.SeparatorText(ctx, 'Steps')
    
    -- shift
      UI.draw_setbuttonbackgtransparent()
      ImGui.Button(ctx, 'Shift',butw)
      UI.Tools_unsetbuttonstyle()
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, '<',butw) then DATA:_Seq_ModifyTools(note, 0, 1)  end ImGui.SameLine(ctx)
      if ImGui.Button(ctx, '>',butw) then DATA:_Seq_ModifyTools(note, 0, -1) end
      -- random ------------------------------------
      if ImGui.Button(ctx, 'Rand', butw_15x) then DATA:_Seq_ModifyTools(note, 2) end ImGui.SameLine(ctx)
      local formatIn = math.floor(EXT.CONF_seq_random_probability*100)..'%%'
      reaper.ImGui_SetNextItemWidth(ctx,butw_15x)
      local retval, v = reaper.ImGui_SliderDouble( ctx, '##randseqnote', EXT.CONF_seq_random_probability, 0.05, 0.95, formatIn, reaper.ImGui_SliderFlags_None() )
      if retval then EXT.CONF_seq_random_probability = v end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
      if ImGui.Button(ctx, 'Flip', butw_3x) then DATA:_Seq_ModifyTools(note, 1) end
    
    -- step len combo ------------------------------------
    ImGui.SeparatorText(ctx, 'Step length')
      local steplength = DATA.seq.ext.children[note].steplength
      local default = 0.25
      steplength = math.floor(steplength*100000)/100000 
      local steplength_format = ''
      local names_map = 
        {
          {sep='Straigth'},
          {v=0.5,s='1/2'},
          {v=0.25,s='1/4'},
          {v=0.125,s='1/8'},
          {v=0.0625,s='1/16'},
          {v=0.03125,s='1/32'},
          {sep='Triplets'},
          {v=0.33333,s='1/4T'},
          {v=0.16666,s='1/8T'},
          {v=0.08333,s='1/16T'},
          {v=0.04166,s='1/32T'}
        }
      for i = 1, #names_map do if names_map[i].v == steplength then steplength_format = names_map[i].s end end 
      local ctrl_posXstlen, ctrl_posYstlen = ImGui.GetCursorPos(ctx)
      reaper.ImGui_SetNextItemWidth(ctx,butw_15x)
      if ImGui_BeginCombo( ctx, '##steplength'..note, steplength_format, reaper.ImGui_ComboFlags_NoArrowButton()|ImGui.ComboFlags_HeightLargest ) then -- reaper.ImGui_ComboFlags_NoPreview() 
        for i = 1, #names_map do 
          if names_map[i].s then 
            if ImGui.Selectable(ctx,names_map[i].s) then DATA.seq.ext.children[note].steplength = names_map[i].v DATA:_Seq_Print() end
          end
          if names_map[i].sep then
            reaper.ImGui_SeparatorText(ctx, names_map[i].sep)
          end
        end 
        ImGui_EndCombo( ctx )
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx,'Reset##steplenreset',butw_15x)then DATA.seq.ext.children[note].steplength = 0.25 DATA:_Seq_Print() end
      
    -- Actions
    ImGui.PushFont(ctx,DATA.font2)
    ImGui.SeparatorText(ctx, 'Actions')
    --if ImGui.Button(ctx, 'Clear all', butw_3x) then DATA:_Seq_Clear() end 
    if ImGui.BeginMenu( ctx, ' Actions', true ) then
      ImGui.SeparatorText(ctx, 'Pattern general')
      if ImGui.Button(ctx, 'Clear all',-1) then DATA:_Seq_Clear() end  
      UI.draw_chokecombo(note)
      ImGui.SeparatorText(ctx, 'Pad')
      local SysEx_status = DATA.children[note] and DATA.children[note].SYSEXMOD == true 
      if ImGui.Checkbox(ctx, 'SysEx mode',SysEx_status) then if SysEx_status == true then DATA:Action_RS5k_SYSEXMOD_OFF(note) else DATA:Action_RS5k_SYSEXMOD_ON(note) end   end
      ImGui.SameLine(ctx )UI.HelpMarker([[
ON:
- add sysex handler JSFX to child track
- turn sample into freely configurable mode
- set pitch start to -64
- set pitch end to 64
- set note start to 0
- set note end to 127
- refresh internal data, this restrict changing start/end note in RS5k

OFF:
- remove sysex handler
- turn sample into Sample mode
- set note start to [note]
- set note end to [note]
- refresh internal data, this allow changing start/end note in RS5k
]])

      if ImGui.Button(ctx, 'Remove pad content',-1) then
        DATA:Sampler_RemovePad(note) 
      end
      ImGui.EndMenu( ctx )
    end
    ImGui.PopFont(ctx)
    
    local parameter, maxval, minval, default_val, parameter_parent, parameterstr = UI.draw_Seq_ctrls_inline_getactiveparam()
    
    -- globals
      ImGui.SeparatorText(ctx, parameterstr) 
      if default_val and DATA.seq.ext.children[note].steps then
        if ImGui.Button(ctx, 'Reset##resparamvalues') then --,-UI.spacingX
          if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
          for step in pairs( DATA.seq.ext.children[note].steps) do DATA.seq.ext.children[note].steps[step][parameter] = default_val end
          DATA:_Seq_Print() 
        end
      end
      ImGui.SameLine(ctx)
      if default_val and DATA.seq.ext.children[note].steps then
        if ImGui.Button(ctx, 'Random##randparamvalues') then --,-UI.spacingX
          if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
          for step in pairs( DATA.seq.ext.children[note].steps) do DATA.seq.ext.children[note].steps[step][parameter] = math.random() * (maxval - minval) + minval end
          DATA:_Seq_Print() 
        end
      end   
    
    -- fx
      if parameter_parent == 'trackFXenv' then
        if ImGui.Button(ctx, '+ Add last touched',110) then 
          DATA:_Seq_AddLastTouchedFX() 
        end
        
        if ImGui.Button(ctx, 'Remove',110) then DATA:_Seq_FXremove(note, parameter)  end
        
        
      end
    
    reaper.ImGui_PopFont(ctx)
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_ctrls_inline(note_t) 
    function __f_draw_Seq_ctrls_inline() end
    
    if not note_t then return end
    local note= note_t.noteID
    if not (note and DATA.children[note] and DATA.children[note].seq_yA) then return end
    
    local parameter = DATA.seq_param_selector[DATA.seq_param_selectorID].param
    local width_area = DATA.display_w-UI.calc_seqXL_padname - UI.scrollbarsz-- UI.calc_seqW_steps + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX
    local seq_yA = DATA.children[note].seq_yA[DATA.temp_stepline] or DATA.children[note].seq_yA[0]
    if  seq_yA+DATA.seq_UI_inlineH_area  > DATA.display_viewport_h then
      ImGui.SetNextWindowPos( ctx, UI.calc_seqX + UI.calc_seqXL_padname, seq_yA -UI.seq_padH-DATA.seq_UI_inlineH_area-15  , ImGui.Cond_Always, 0, 0 )--
     else
      ImGui.SetNextWindowPos( ctx, UI.calc_seqX + UI.calc_seqXL_padname, seq_yA , ImGui.Cond_Always, 0, 0 )--
    end
    ImGui.SetNextWindowSize( ctx, width_area, 0, ImGui.Cond_Always )
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,2)  
    
    if ImGui.BeginPopup(ctx,'note_seq_params'..note) then
      local posx,posy = ImGui.GetCursorPos(ctx)
       
      if ImGui.BeginChild(ctx, '##childinlinetools'..note, UI.seq_padnameW+UI.spacingX, 0, ImGui.ChildFlags_None,ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then--|reaper.ImGui_ChildFlags_AutoResizeY()
        
          
        -- name  
          ImGui.PushFont(ctx, DATA.font4) 
          -- define txt
            local note_format = VF_Format_Note(note,note_t)
            if DATA.padcustomnames[note] and DATA.padcustomnames[note] ~= '' then note_format = DATA.padcustomnames[note] end
            local str_maxlen = 20
            if note_format:len()> str_maxlen then note_format = '...'..note_format:sub(-str_maxlen) end
          -- define color
            local color
            if note_t and note_t.I_CUSTOMCOLOR then 
              color = ImGui.ColorConvertNative(note_t.I_CUSTOMCOLOR) 
              color = color & 0x1000000 ~= 0 and (color << 8) | EXT.UI_col_tinttrackcoloralpha-- https://forum.cockos.com/showpost.php?p=2799017&postcount=6
            end 
            if not color then color = EXT.UI_colRGBA_paddefaultbackgr end
            -- if not color then color = EXT.UI_colRGBA_paddefaultbackgr end 
            ImGui.PushStyleColor(ctx, ImGui.Col_Button, color)
            ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, color)
            ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, color|0xFF)
          -- button
            ImGui.Button(ctx,note_format..'##rackpad_name'..note,UI.seq_padnameW,UI.seq_padH-1 )
            local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
            local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
            if color then ImGui.PopStyleColor(ctx,3) end
             DATA.children[note].seq_yA={}
             DATA.children[note].seq_yA[0] = y1 -- print for note_seq_params popup
            if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) or ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
              DATA.temp_stepline = 0
              reaper.ImGui_CloseCurrentPopup(ctx)
            end
          
            
          ImGui.PopFont(ctx) 
          
           
          
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX,UI.spacingY) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,UI.spacingX,UI.spacingY) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY)
        UI.draw_Seq_ctrls_inline_tools(note_t) 
        
        ImGui.PopStyleVar(ctx,4)
        reaper.ImGui_EndChild(ctx)
      end 
      
      UI.draw_Seq_Step(note_t, posx + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX, posy )  
      UI.draw_Seq_ctrls_inline_drawstuff(note_t, posx, posy+ UI.seq_padH) 
      ImGui.Dummy(ctx,0,UI.spacingY)
      ImGui.Dummy(ctx,UI.seq_padnameW+UI.spacingX*2,0)ImGui.SameLine(ctx)
      UI.draw_Seq_horizscroll()  
      ImGui.Dummy(ctx,0,UI.spacingY)
      reaper.ImGui_EndPopup(ctx)
    end
    ImGui.PopStyleVar(ctx)
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_ctrls_inline_drawstuff(note_t, posx, posy)
    
    local reset_w = 80
    local note = note_t.noteID
    local harea = DATA.seq_UI_inlineH_area
    
    local parameter, maxval, minval, default_val, parameter_parent = UI.draw_Seq_ctrls_inline_getactiveparam()
    
    local parameter = DATA.seq_param_selector[DATA.seq_param_selectorID].param
    local default_val = DATA.seq_param_selector[DATA.seq_param_selectorID].default 
    local maxval = DATA.seq_param_selector[DATA.seq_param_selectorID].maxval  or 1
    local minval = DATA.seq_param_selector[DATA.seq_param_selectorID].minval  or 0
    local parameter_parent = parameter
    
    -- handle meta 
    if parameter == 'meta' then
      parameter = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].param
      default_val = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].default 
      maxval = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].maxval  or 1
      minval = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].minval  or 0
    end
    
    -- handle trackenv
    if parameter == 'trackenv' and DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID]  then
      parameter = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].param
      default_val = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].default 
      maxval = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].maxval  or 1
      minval = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].minval  or 0
    end
    
    -- handle trackenv
    if parameter == 'trackFXenv' and DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID]  then
      parameter = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].param
      default_val = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].default 
      maxval = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].maxval  or 1
      minval = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].minval  or 0
    end
    
    -- work area
    ImGui.SetCursorPos(ctx, posx + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX, posy + UI.spacingY)
    
    
    --ImGui.Button(ctx,'active_area',-1,harea)
    ImGui.InvisibleButton(ctx,'active_area',-1,harea)
    local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
    local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
    UI.draw_Seq_ctrls_inline_handlemouse(note_t) 
    ImGui.Dummy(ctx,0,UI.spacingY)
    
    
    -- patch for missing sysex_handler JSFX
    local misiingsysex = 
      ( parameter_parent == 'meta' and 
        (
          parameter == 'meta_pitch' or 
          parameter == 'meta_probability'
        )
      ) and DATA.children[note].SYSEXHANDLER_isvalid~=true
      
      
      
      
    if misiingsysex then  
      ImGui.SetCursorPosX(ctx, posx + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX)
     
      ImGui.DrawList_AddText( UI.draw_list, x1+ 10, y1+50, 0xFFFFFFBF, 
[[Not available. Drag anywhere in this area to:
- add sysex handler JSFX to child track
- turn sample into freely configurable mode
- set pitch start to -64
- set pitch end to 64
- set note start to 0
- set note end to 127

SysEx handler JSFX basically replace incoming 
pitch to sequencer pitch defined in inline editor.

It also used for advanced sequencing parameters.
]]

)


    end
    
    -- parameter tabs
    ImGui.SetCursorPosX(ctx, posx + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX)
    if ImGui.BeginTabBar( ctx, 'paraminlinetabs', ImGui.TabItemFlags_None|ImGui.TabBarFlags_FittingPolicyResizeDown ) then
      for i = 1, #DATA.seq_param_selector do
        local formatIn = DATA.seq_param_selector[i].str
        if ImGui.BeginTabItem( ctx, formatIn..'##inlinetabs', false, ImGui.TabItemFlags_None ) then DATA.seq_param_selectorID = i  ImGui.EndTabItem( ctx)  end 
      end
      ImGui.EndTabBar( ctx)
    end
    
    if parameter_parent == 'meta' and misiingsysex ~= true then
      ImGui.SetCursorPosX(ctx, posx + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX)
      if ImGui.BeginTabBar( ctx, 'paraminlinetabs_meta', ImGui.TabItemFlags_None|ImGui.TabBarFlags_FittingPolicyResizeDown ) then
        for i = 1, #DATA.seq_param_selector_meta do
          local formatIn = DATA.seq_param_selector_meta[i].str
          if ImGui.BeginTabItem( ctx, formatIn..'##inlinetabs_meta', false, ImGui.TabItemFlags_None ) then DATA.seq_param_selector_metaID = i  ImGui.EndTabItem( ctx)  end 
        end
        ImGui.EndTabBar( ctx)
      end
    end
     
    if parameter_parent == 'trackenv' then
      ImGui.SetCursorPosX(ctx, posx + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX)
      if ImGui.BeginTabBar( ctx, 'paraminlinetabs_trackenv', ImGui.TabItemFlags_None|ImGui.TabBarFlags_FittingPolicyResizeDown ) then
        for i = 1, #DATA.seq_param_selector_trackenv do
          local formatIn = DATA.seq_param_selector_trackenv[i].str
          if ImGui.BeginTabItem( ctx, formatIn..'##inlinetabs_trackenv', false, ImGui.TabItemFlags_None ) then DATA.seq_param_selector_trackenvID = i  ImGui.EndTabItem( ctx)  end 
        end
        ImGui.EndTabBar( ctx)
      end
    end
    
    if parameter_parent == 'trackFXenv' then
      ImGui.SetCursorPosX(ctx, posx + UI.seq_audiolevelW + UI.seq_padnameW + UI.spacingX)
      local preview = ''
      if DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID] then
        preview = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].str
      end
      reaper.ImGui_SetNextItemWidth(ctx,-1)
      if ImGui.BeginCombo( ctx, '##paraminlinetabs_trackFXenvcomb', preview, reaper.ImGui_ComboFlags_None() ) then
        for i = 1, #DATA.seq_param_selector_trackFXenv do 
          if i~= DATA.seq_param_selector_trackFXenvID then
            local formatIn = DATA.seq_param_selector_trackFXenv[i].str
            if ImGui.Selectable( ctx, formatIn..'##inlinetabs_trackFXenv', false, ImGui.TabItemFlags_None ) then DATA.seq_param_selector_trackFXenvID = i  end 
          end
        end
        ImGui.EndCombo( ctx )
      end
    end
    
    
    -- STEPS
    local stepw = UI.seq_stepW
    local hfull = (y2-y1)
  
    -- steps active
    local stepcol_1 = 0xBFBFBF00
    local stepcol_2 = 0x3FDF3F00 
        
    for step = 1+DATA.seq.stepoffs, DATA.seq.ext.patternlen do
      local stepcol = stepcol_1
      if (step-1)%8> 3 then stepcol = stepcol_2 end 
      local xpos = x1 + (stepw) * (step-DATA.seq.stepoffs-1) 
      ImGui.DrawList_AddRectFilled( UI.draw_list, xpos,y1,xpos + stepw -1 ,y2, stepcol|0x0F, UI.seq_steprounding, ImGui.DrawFlags_None )
    end
    
    -- values
    -- draw velocity / offset
      local mousex, mousey = reaper.ImGui_GetMousePos( ctx )
      local hstep = (y2-y1)
      local hstep_half = (y2-y1)*0.5
      
       
      for step = 1+DATA.seq.stepoffs, DATA.seq.ext.patternlen do
        local stepcol = stepcol_1
        if (step-1)%8> 3 then stepcol = stepcol_2 end
        local activestep = step 
        
        local allow_env_on_empty_steps = 
          DATA.seq.ext.children
          and note
          and DATA.seq.ext.children[note]
          and DATA.seq.ext.children[note].steps
          and activestep
          and DATA.seq.ext.children[note].steps[activestep]
          and DATA.seq.ext.children[note].steps[activestep].val 
          and DATA.seq.ext.children[note].steps[activestep].val == 1
        if EXT.CONF_seq_env_clamp == 0 then  
          if parameter_parent:match('env') then allow_env_on_empty_steps = true end
        end
        
        
        if DATA.seq.ext.children[note].steps and DATA.seq.ext.children[note].steps[activestep] and DATA.seq.ext.children[note].steps[activestep].val  and default_val and allow_env_on_empty_steps == true then 
          local val = default_val
          if DATA.seq.ext.children[note].steps and DATA.seq.ext.children[note].steps[activestep] and DATA.seq.ext.children[note].steps[activestep][parameter] then val = DATA.seq.ext.children[note].steps[activestep][parameter] end 
          local xpos = x1 + (stepw) * (step-1-DATA.seq.stepoffs)
          
          local val_norm = (val - minval) / (maxval - minval)
          local ypos = y1
          
          local istrackpanenv = 
              (DATA.seq_param_selectorID ==6 
                and DATA.seq_param_selector_trackenvID 
                and DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].param 
                and DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].param == 'env_pan'
               )
          
          if    DATA.seq_param_selectorID == 1 -- velocity
            or  DATA.seq_param_selectorID == 3 -- split
            or  DATA.seq_param_selectorID == 4 -- len
            or  (DATA.seq_param_selectorID == 5 and DATA.seq_param_selector_metaID == 2) -- meta_probability 
            or  (DATA.seq_param_selectorID == 6 and istrackpanenv ~= true)-- track env
            or  DATA.seq_param_selectorID == 7-- track env
            then 
            
            hstep = (y2-y1)*val_norm
            ypos = math.min(y2-1, y1 + hfull - hstep)
            ImGui.DrawList_AddRectFilled( UI.draw_list, xpos,ypos,xpos + stepw -1 ,y2, stepcol|0x6F, UI.seq_steprounding, ImGui.DrawFlags_None )
           elseif 
                DATA.seq_param_selectorID == 2  -- offset
            or  (DATA.seq_param_selectorID == 5 and DATA.seq_param_selector_metaID == 1) -- meta_pitch 
            or  istrackpanenv == true
            then
            if val_norm > 0.5 then 
              ypos1 = y1 + hstep_half - hstep_half* (val_norm-0.5)*2
              ypos2 = y1 + hstep_half 
             else
              ypos1 = y1 + hstep_half
              ypos2 = ypos1  + (hstep_half - hstep_half*val_norm*2)
            end
            -- patch for missing sysex_handler JSFX
            
              
            if misiingsysex~=true then  
              ImGui.DrawList_AddRectFilled( UI.draw_list, xpos,ypos1,xpos + stepw -1 ,ypos2, stepcol|0x6F, UI.seq_steprounding, ImGui.DrawFlags_None )
            end
          end
          
          -- draw formatted  values
          local txt=val 
          local txyy = math.max(ypos-20,y1)
          if DATA.seq_param_selectorID == 1  then  --velocity
            txt=math.floor(val*127) 
           elseif DATA.seq_param_selectorID == 2  then --offst
             txt=math.floor(val*100)..'%'
           elseif DATA.seq_param_selectorID == 3  then -- split
             txt=math_q(val)        
           elseif DATA.seq_param_selectorID ==4  then --step len
             txt=math.floor(val*100)..'%'   
           elseif DATA.seq_param_selectorID ==5 and DATA.seq_param_selector_metaID ==1 then --meta_pitch
             txt=math_q(val-64)    
           elseif DATA.seq_param_selectorID ==5 and DATA.seq_param_selector_metaID ==2 then --meta_probability
             txt=math.floor(val*100)..'%'  
           elseif (DATA.seq_param_selectorID == 6  and istrackpanenv ~= true) then --track env
             txt=math.floor(val*100)..'%'      
           elseif istrackpanenv == true then --track pan
             if val > 0 then txt= math.floor(val*100)..'L'               
               elseif val < 0 then txt= math.floor(-val*100)..'R'               
               elseif val == 0 then txt='C'
             end
           elseif DATA.seq_param_selectorID ==7 then --fx
             txt=math.floor(val*100)..'%'               
          end
          mousediff = VF_lim(255-math.floor(math.abs(mousex-xpos) ),0,255)--+ math.abs(mousey-ypos)
          
          ImGui.PushFont(ctx, DATA.font5) 
          ImGui.DrawList_AddText( UI.draw_list, xpos, txyy, 0xFFFFFF00|mousediff, txt ) 
          ImGui.PopFont(ctx) 
        end
      end
      
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_ctrls_inline_getactiveparam()
    -- define min/max
    local parameter = DATA.seq_param_selector[DATA.seq_param_selectorID].param
    local parameterstr = DATA.seq_param_selector[DATA.seq_param_selectorID].str
    local maxval = DATA.seq_param_selector[DATA.seq_param_selectorID].maxval or 1
    local minval = DATA.seq_param_selector[DATA.seq_param_selectorID].minval or 0 
    local default_val = DATA.seq_param_selector[DATA.seq_param_selectorID].default or 0  
    local parameter_parent = parameter
    
    -- handle meta
    if parameter_parent == 'meta' then
      parameter = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].param
      default_val = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].default 
      maxval = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].maxval  or 1
      minval = DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].minval  or 0
      parameterstr = 'Meta: '..DATA.seq_param_selector_meta[DATA.seq_param_selector_metaID].str
    end
    
    -- handle trackenv
    if parameter_parent == 'trackenv' and DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID] then
      parameter = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].param
      default_val = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].default 
      maxval = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].maxval  or 1
      minval = DATA.seq_param_selector_trackenv[DATA.seq_param_selector_trackenvID].minval  or 0
      parameterstr = 'Track envelope'
    end
    
    -- handle trackFXenv
    if parameter_parent == 'trackFXenv' and DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID] then
      parameter = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].param
      default_val = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].default 
      maxval = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].maxval  or 1
      minval = DATA.seq_param_selector_trackFXenv[DATA.seq_param_selector_trackFXenvID].minval  or 0
      parameterstr = 'FX envelope'
    end 
    
    return parameter, maxval, minval, default_val, parameter_parent, parameterstr
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_ctrls_inline_appstuff(note_t, rightbutton)
    local note = note_t.noteID 
    local patlen = DATA.seq.ext.patternlen
    local parameter, maxval, minval, default_val, parameter_parent = UI.draw_Seq_ctrls_inline_getactiveparam()
    
   
    
    
    -- patch for missing sysex_handler JSFX
    local misiingsysex = 
      ( parameter_parent == 'meta' and 
        (
          parameter == 'meta_pitch' or 
          parameter == 'meta_probability'
        )
      ) and DATA.children[note].SYSEXHANDLER_isvalid~=true
      
    if misiingsysex then DATA:Action_RS5k_SYSEXMOD_ON(note) end
    
    -- define active step start/stop
    local active_step = math.ceil(DATA.temp_seq_params.x2_norm * UI.calc_seqW_steps_visible + DATA.seq.stepoffs)
    local active_step_init = math.ceil(DATA.temp_seq_params.x1_norm * UI.calc_seqW_steps_visible + DATA.seq.stepoffs)
    local invert
    if active_step_init > active_step and rightbutton== true  then 
      invert = true
      local temp_val = active_step
      active_step = active_step_init
      active_step_init = temp_val
    end
    
    local step_cnt = DATA.seq.ext.children[note].step_cnt
    if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen end
    active_step = math.min(active_step, step_cnt)
    
    -- left click to directly set value
    if rightbutton~= true then
      if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
      if not DATA.seq.ext.children[note].steps[active_step] then DATA.seq.ext.children[note].steps[active_step] = {} end
      local out = DATA.temp_seq_params.y2_norm
      out = out* (maxval - minval)  + minval
      DATA.seq.ext.children[note].steps[active_step][parameter] = VF_lim(out, minval,maxval)
      -- preint step 0 for extended features
      if not DATA.seq.ext.children[note].steps[0] then DATA.seq.ext.children[note].steps[0] = {} end
      DATA.seq.ext.children[note].steps[0][parameter] = 0
    end
    
    -- right click to set area
    if rightbutton== true then 
      if active_step_init ~= active_step then
        if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end 
        for step = active_step_init, active_step do
          if not DATA.seq.ext.children[note].steps[step] then DATA.seq.ext.children[note].steps[step] = {} end
          local out1 = DATA.temp_seq_params.y1_norm
          local out2 = DATA.temp_seq_params.y2_norm 
          local scale = (step-active_step_init) / (active_step - active_step_init)
          local out = out1 + (out2- out1) * scale
          if invert ==true then out = out2 + (out1- out2) * scale end
          out = out* (maxval - minval)  + minval
          DATA.seq.ext.children[note].steps[step][parameter] = VF_lim(out, minval,maxval)
          -- preint step 0 for extended features
          if not DATA.seq.ext.children[note].steps[0] then DATA.seq.ext.children[note].steps[0] = {} end
          DATA.seq.ext.children[note].steps[0][parameter] = 0
        end
       else
        local out = DATA.temp_seq_params.y2_norm
        out = out* (maxval - minval)  + minval
        DATA.seq.ext.children[note].steps[active_step][parameter] = VF_lim(out, minval,maxval)
        -- preint step 0 for extended features
        if not DATA.seq.ext.children[note].steps[0] then DATA.seq.ext.children[note].steps[0] = {} end
        DATA.seq.ext.children[note].steps[0][parameter] = 0
        
      end
    end
     
    
    DATA:_Seq_Print(nil, true) 
    
    
    -- enable obey note off is tweaking step length
    if parameter_parent == 'steplen_override' then DATA:Action_SetObeyNoteOff(note) end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_startup() 
    reaper.ImGui_SetCursorPos(ctx,0 ,UI.calc_itemH + UI.spacingY)
        ImGui.TextWrapped(ctx,
            [[ 
        Basic step sequencer flow: 
            1. Select MIDI item placed in RS5k manager MIDI bus track. Or create it:]]) --ImGui.SameLine(ctx) 
            ImGui.Dummy(ctx,30,0) ImGui.SameLine(ctx)
            if ImGui.Button(ctx, 'Insert new pattern') then 
              Undo_BeginBlock2(DATA.proj)
              DATA:_Seq_Insert() 
              Undo_EndBlock2(DATA.proj, 'Insert new pattern', 0xFFFFFFFF)
              DATA.upd = true
            end
            
            ImGui.TextWrapped(ctx,  
  [[          2. Once MIDI item is selected, RS5k manager are ready to read and write sequencer data.
  
            ]])
            
            
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_horizscroll(is_thin)  
    -- horiz scroll
    local yoffs = -1
    ImGui.SetNextItemWidth(ctx, -1)
    local format = ''
    if DATA.seq.stepoffs and DATA.seq.ext.patternlen and UI.calc_seqW_steps_visible then 
      local maxval = (math.min(DATA.seq.stepoffs+UI.calc_seqW_steps_visible-1,DATA.seq.ext.patternlen))
      maxval = math.max(maxval,16)
      format = (DATA.seq.stepoffs+1)..'-'..maxval..' steps' 
    end
    local bw= -1 
    local xres  = UI.calc_seqW_steps
    if is_thin == true then 
      xres = DATA.display_w
      bw = - 15 
    end
    -- button base
    ImGui.InvisibleButton(ctx, '#scrollseq',bw, UI.scrollbarsz)
    -- draw rect / handle
    local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
    local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
    ImGui.DrawList_AddRectFilled( UI.draw_list, x1, y1+yoffs, x2, y2+yoffs, 0x191919FF, 5, reaper.ImGui_DrawFlags_None() )
    local handle_red = 3
    local minx = x1+handle_red
    local handle_w = 50
    local maxx = x2-handle_red*2 - handle_w
    minx = minx + (maxx - minx) * DATA.seq_horiz_scroll 
    ImGui.DrawList_AddRectFilled( UI.draw_list, minx, y1+yoffs+handle_red, minx + handle_w, y2+yoffs-handle_red, 0x595959FF, 5, reaper.ImGui_DrawFlags_None() )
    if DATA.seq.active_pat_step and DATA.seq.ext.patternlen and DATA.seq.ext.patternlen >= 32 then 
      for i = 1, DATA.seq.ext.patternlen, 16 do
        local xsep = math.floor(x1+handle_red+(x2-x1-handle_red*2) * ((i -1)/ DATA.seq.ext.patternlen))
        ImGui.DrawList_AddLine( UI.draw_list, xsep, y1+yoffs, xsep, y2+yoffs, 0x00FF004F, 1 )
      end
      minx = x1+handle_red
      local playcur_w = xres / DATA.seq.ext.patternlen
      local maxx = x2-handle_red*2 - handle_w
      minx = minx + (maxx - minx) * ((DATA.seq.active_pat_step -1)/ DATA.seq.ext.patternlen)
      ImGui.DrawList_AddRectFilled( UI.draw_list, minx, y1+yoffs+handle_red, minx + playcur_w, y2+yoffs-handle_red, 0x00FF008F, 5, reaper.ImGui_DrawFlags_None() )
    end
    
    if ImGui.IsItemClicked(ctx,ImGui.MouseButton_Left) then
      DATA.temp_horscroll_val = DATA.seq_horiz_scroll
      DATA.temp_horscroll_mx = reaper.ImGui_GetMousePos(ctx)
    end
    if ImGui.IsItemActive(ctx) then
      local mx,my =  reaper.ImGui_GetMousePos(ctx)
      DATA.seq_horiz_scroll = VF_lim(DATA.temp_horscroll_val + (mx - DATA.temp_horscroll_mx)/xres,0,0.99)
      DATA:_Seq_RefreshHScroll()
      reaper.ImGui_DrawList_AddText( UI.draw_list, x2-60, y1+yoffs-1, 0xFFFFFFFF, format )
    end
    if reaper.ImGui_IsItemDeactivated(ctx) then DATA:_Seq_RefreshHScroll() end
    
 
    
    
    --local ret, v = ImGui.SliderDouble(ctx,'##horizscroll',DATA.seq_horiz_scroll,0,0.99,format,ImGui.SliderFlags_None)
    
  end
    -------------------------------------------------------------------------------- 
  function UI.draw_Seq()   
    local mdx, mdy = reaper.ImGui_GetMouseDelta( ctx )
    if mdx ~= 0 and mdy ~=0 then DATA.temp_ismousewheelcontrol_hovered = nil end -- reset on move
    
    local ctrls_w = 100
    -- startup
      if not (DATA.parent_track and DATA.parent_track.valid == true and DATA.seq and DATA.seq.valid == true and DATA.seq.tk_ptr ) then
        UI.draw_Seq_startup() 
        return
      end

      
    -- UI name
      ImGui.SameLine(ctx)
      ImGui.BeginDisabled(ctx, true) ImGui.Text(ctx, DATA.UI_name_vrs)ImGui.EndDisabled(ctx)

    -- new
      if ImGui.Button(ctx, 'New') then 
        Undo_BeginBlock2(DATA.proj)
        DATA:_Seq_Insert() 
        Undo_EndBlock2(DATA.proj, 'Insert new pattern', 0xFFFFFFFF)
        DATA.upd = true
      end
      
      
    -- pattern rename
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, 150)
      local tkname = DATA.seq.tkname
      if tkname == '' then tkname = '[untitled pattern]' end
      local retval, buf = ImGui.InputText( ctx, '##tkname', tkname, reaper.ImGui_InputTextFlags_None() )
      if ImGui.IsItemActive(ctx) and DATA.allow_space_to_play == true then DATA.allow_space_to_play = false end
      if retval then 
        DATA.seq.tkname = buf
        GetSetMediaItemTakeInfo_String( DATA.seq.tk_ptr, 'P_NAME', DATA.seq.tkname, true )
      end

    
    -- patternlen 
      local patternlen = DATA.seq.ext.patternlen 
      ImGui.SameLine(ctx)  
      reaper.ImGui_SetCursorPosX(ctx,DATA.display_w-ctrls_w*2-UI.spacingX*3)
      ImGui.SetNextItemWidth(ctx, ctrls_w)
      --local retval, v = ImGui.SliderDouble  ( ctx, '##Swing_pat', DATA.seq.ext.swing, 0, 1, 'Swing '..math.floor(DATA.seq.ext.swing*100)..'%%', reaper.ImGui_SliderFlags_None() ) 
      local retval, v = ImGui.DragInt    ( ctx, '##patternlen', DATA.seq.ext.patternlen, 0.1, 1, UI.seq_maxstepcnt, 'Length '..DATA.seq.ext.patternlen, reaper.ImGui_SliderFlags_None() )
      if retval then DATA.seq.ext.patternlen = v DATA:_Seq_SetItLength_Beats(DATA.seq.ext.patternlen) end
      if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then DATA:_Seq_Print() end 
      if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) then ImGui.OpenPopup( ctx, 'patterlen', ImGui.PopupFlags_None )  end
      
      -- mousewheel
      local vertical, horizontal = ImGui.GetMouseWheel( ctx )
      local mousewheel = ImGui.IsItemHovered(ctx) and vertical ~= 0
      if mousewheel then mousewheel = math.abs(vertical)/vertical end 
      if mousewheel then
        if mousewheel > 0 then DATA.seq.ext.patternlen = VF_lim(DATA.seq.ext.patternlen * 2,1,UI.seq_maxstepcnt) else DATA.seq.ext.patternlen = VF_lim(math.floor(DATA.seq.ext.patternlen / 2),1,UI.seq_maxstepcnt) end
        DATA:_Seq_SetItLength_Beats(DATA.seq.ext.patternlen) 
        DATA:_Seq_Print()
      end
      ImGui.SameLine(ctx) 
      ImGui.SetItemTooltip(ctx,'Pattern length')
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,2)   
      if reaper.ImGui_BeginPopup(ctx,'patterlen') then
        local posx,posy = ImGui.GetCursorPos(ctx)
        ImGui.SeparatorText(ctx,'Step count')
        local set
        if ImGui.Selectable(ctx, '16 steps', DATA.seq.ext.patternlen==16) then set = 16 end 
        if ImGui.Selectable(ctx, '32 steps', DATA.seq.ext.patternlen==32) then set = 32 end
        if ImGui.Selectable(ctx, '64 steps', DATA.seq.ext.patternlen==64) then set = 64 end 
        if ImGui.Selectable(ctx, '128 steps', DATA.seq.ext.patternlen==128) then set = 128 end
        if ImGui.Selectable(ctx, '1024 steps', DATA.seq.ext.patternlen==1024) then set = 1024 end
        ImGui.SeparatorText(ctx,'Options')
        if ImGui.Checkbox(ctx, 'Change children step count', EXT.CONF_seq_patlen_extendchildrenlen&1==1) then EXT.CONF_seq_patlen_extendchildrenlen=EXT.CONF_seq_patlen_extendchildrenlen~1 EXT:save()end  
        if set then
          DATA.seq.ext.patternlen = set
          DATA:_Seq_SetItLength_Beats(DATA.seq.ext.patternlen)
          DATA:_Seq_Print()
          reaper.ImGui_CloseCurrentPopup(ctx)
        end
        ImGui.SeparatorText(ctx,'Actions')
        if ImGui.Selectable(ctx, 'Print to full pattern length', nil, reaper.ImGui_SelectableFlags_None(), 180) then DATA:_Seq_FillNoteStepsToFullLength(note) end  
        
        ImGui.Dummy(ctx,0,UI.spacingY)
        reaper.ImGui_EndPopup(ctx)
      end
      ImGui.PopStyleVar(ctx)
      
      
      
    
    -- swing
    ImGui.SameLine(ctx) 
    ImGui.SetNextItemWidth(ctx, ctrls_w)
    --local retval, v = ImGui.SliderDouble  ( ctx, '##Swing_pat', DATA.seq.ext.swing, 0, 1, 'Swing '..math.floor(DATA.seq.ext.swing*100)..'%%', reaper.ImGui_SliderFlags_None() ) 
    local retval, v = ImGui.DragDouble    ( ctx, '##Swing_pat', DATA.seq.ext.swing, 0.001, 0, 1, 'Swing '..math.floor(DATA.seq.ext.swing*100)..'%%', reaper.ImGui_SliderFlags_None() ) 
    if retval then DATA.seq.ext.swing = v end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then DATA:_Seq_Print() end
    
    ImGui.SetCursorPosX(ctx,UI.calc_seqXL_padname+UI.spacingX*3 + UI.seq_padnameW)
     
    
    
    -- draw main stuff
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0,0) 
    local xoffs_abs = UI.calc_seqX
    local yoffs_abs = UI.calc_seqY+UI.calc_itemH+UI.spacingY
    
    
    ImGui.SetCursorScreenPos(ctx,xoffs_abs,yoffs_abs)  
    
    local xL,yL = ImGui.GetCursorPos(ctx)
    local xA,yA = ImGui.GetCursorScreenPos(ctx)
    UI.draw_Seq_StepProgress(xL,yL, xA+UI.calc_seqXL_steps,yA) 
    
    local flagscroll = 0
    if UI.anypopupopen == true or DATA.temp_ismousewheelcontrol_hovered == true then flagscroll = ImGui.WindowFlags_NoScrollWithMouse end
    if ImGui.BeginChild( ctx, 'seq', 0, -UI.spacingY-UI.scrollbarsz, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None|flagscroll ) then-- --|ImGui.WindowFlags_MenuBar |ImGui.ChildFlags_Border  ---UI.calc_itemH - 
      
      ImGui.Dummy(ctx,0,UI.spacingY)
      
      -- ascending order
      local note_start = 127
      local note_end = 0
      local incr = -1
      if EXT.CONF_seq_instrumentsorder == 1 then
        note_start = 0
        note_end = 127
        incr = 1
      end
      
      -- loop notes
      for note = note_start,note_end,incr  do
        if DATA.children[note] then 
          if ImGui.BeginChild( ctx, 'seqchildnote'..note, 0, 0,ImGui.ChildFlags_None|ImGui.ChildFlags_AutoResizeY) then   --|ImGui.ChildFlags_Border 
            local y_local = ImGui.GetCursorPosY(ctx)
            UI.draw_Seq_ctrls(DATA.children[note]) 
            ImGui.SetCursorPosY(ctx, y_local)
            UI.draw_Seq_Step(DATA.children[note])
            ImGui.EndChild( ctx)
          end
        end
      end
      
      -- handle refresh after drop @ UI.Drop_UI_interaction_pad(note) 
      if DATA.upd2.refreshscroll then  
        if DATA.upd2.refreshscroll == 1 then 
          DATA.upd2.refreshscroll = DATA.upd2.refreshscroll + 1 -- forward next frame
         elseif DATA.upd2.refreshscroll == 2 then 
          if EXT.CONF_seq_instrumentsorder == 0 then
            ImGui.SetScrollY( ctx, 0) 
           else
            ImGui.SetScrollY( ctx, ImGui.GetScrollMaxY( ctx )+4000) 
          end
          DATA.upd2.refreshscroll = nil 
        end 
      end
      
      -- seq_init_Yscroll
      if DATA.seq_init_Yscroll == 0 then
        DATA.seq_init_Yscroll  = DATA.seq_init_Yscroll  + 1 -- forward next frame
       elseif DATA.seq_init_Yscroll == 1 then
        if EXT.CONF_seq_instrumentsorder == 0 then ImGui.SetScrollY( ctx, ImGui.GetScrollMaxY( ctx )+4000)  end
        DATA.seq_init_Yscroll = 2
      end
      
      
      ImGui.EndChild( ctx)
    end
    
    if ImGui.BeginDragDropTarget( ctx ) then  
      UI.Drop_UI_interaction_pad(-1) 
      DATA.upd = true
      ImGui_EndDragDropTarget( ctx )
    end
    
      
    ImGui.PopStyleVar(ctx,2)
    ImGui.Dummy(ctx,0,0)
    
    
    UI.draw_Seq_horizscroll(true) 
    
    
    -- draw Rack button
      local manageravailable
      if DATA.manager_ID then manageravailable = true end
      local xoffs = 200
      local yoffs = 4
      local wbut = 100
      ImGui.SetCursorPos(ctx,xoffs,yoffs)
      if ImGui.InvisibleButton(ctx, 'mode', wbut, 20) then 
        if manageravailable == true then Main_OnCommand(DATA.manager_ID,0) end 
      end
      x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
      x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
      local checkbox_h = 16
      local checkbox_r = math.floor(checkbox_h / 2)
      local center_x = x1
      local center_y = math.floor(y1 + (y2-y1)/2 )-1
      local colfill = 0xF0F0F04F
      if manageravailable == true and ImGui_IsItemHovered(ctx) then colfill = 0xF0F0F09F end
      ImGui.DrawList_AddCircle( UI.draw_list, center_x, center_y, checkbox_r, 0xF0F0F07F, 0, 2 )
      ImGui.DrawList_AddCircleFilled( UI.draw_list, center_x, center_y, checkbox_r-3, colfill, 0 ) 
      ImGui.SetCursorPos(ctx,xoffs+checkbox_r+ UI.spacingX,yoffs+1)
      if manageravailable == true then ImGui.Text(ctx, 'Rack') else ImGui.TextDisabled(ctx, 'Rack') end
      
  end  
  --------------------------------------------------------------------------------  
  function UI.draw_Seq_StepProgress(xL,yL, xA,yA) 
    --DATA.seq.active_pat_step
    if not DATA.seq  then  end
    
    local patternlen = DATA.seq.ext.patternlen
    
    if DATA.seq.active_pat_step then
      local step =  DATA.seq.active_pat_step
      step= step - DATA.seq.stepoffs--%16
      --if step == 0 then step = 16 end
      local x1 = xA + (step-1) * UI.seq_stepW
      ImGui.DrawList_AddRectFilled( UI.draw_list, x1,yA+UI.spacingY,x1+UI.seq_stepW,yA+UI.spacingY*2,  0XFFFFFF6F, 5,flagsIn ) 
    end
    
  end

  --------------------------------------------------------------------------------  
  function UI.Tools_setbuttonbackg(col)   
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, col or 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, col or 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, col or 0 )
  end
    --------------------------------------------------------------------------------  
  function UI.Tools_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end 
  -------------------------------------------------------------------------------- 
  function UI.Tools_RGBA(col, a_dec) return col<<8|math.floor(a_dec*255) end  
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open) 
    function __f_styledef() end
      UI.anypopupopen = ImGui.IsPopupOpen( ctx, 'mainRCmenu', ImGui.PopupFlags_AnyPopup|ImGui.PopupFlags_AnyPopupLevel )
      
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      --window_flags = window_flags | ImGui.WindowFlags_MenuBar
      --window_flags = window_flags | ImGui.WindowFlags_NoMove()
      --window_flags = window_flags | ImGui.WindowFlags_NoResize
      window_flags = window_flags | ImGui.WindowFlags_NoCollapse
      window_flags = window_flags | ImGui.WindowFlags_NoNav
      --window_flags = window_flags | ImGui.WindowFlags_NoBackground
      --window_flags = window_flags | ImGui.WindowFlags_NoDocking
      --window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument
      --open = false -- disable the close button
    
    
    -- rounding
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,5)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding,3)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,10)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding,5)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,10)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding,9)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabRounding,4)   
    -- Borders
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize,0)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize,0) 
    -- spacing
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.spacingX*2,UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,UI.spacingX, UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX, UI.spacingY)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,4,0)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing,20)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,UI.scrollbarsz)
    -- size
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,20)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,UI.w_min,UI.h_min)
    -- align
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,0,0.5)
      
    -- alpha
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha,0.98)
      ImGui.PushStyleColor(ctx, ImGui.Col_Border,           UI.Tools_RGBA(0x000000, 0.3))
    -- colors
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.main_col, 0.2))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.but_hovered, 0.8))
      ImGui.PushStyleColor(ctx, ImGui.Col_DragDropTarget,   UI.Tools_RGBA(0xFF1F5F, 0.6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,          UI.Tools_RGBA(0x1F1F1F, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,    UI.Tools_RGBA(UI.main_col, .6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,   UI.Tools_RGBA(UI.main_col, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,           UI.Tools_RGBA(UI.main_col, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive,     UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,    UI.Tools_RGBA(UI.main_col, 0.98) )
      ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,          UI.Tools_RGBA(0x303030, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip,       UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered,UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,       UI.Tools_RGBA(UI.col_maintheme, 0.6) )
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, UI.Tools_RGBA(UI.col_maintheme, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_Tab,              UI.Tools_RGBA(UI.main_col, 0.37) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected,       UI.Tools_RGBA(UI.col_maintheme, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered,       UI.Tools_RGBA(UI.col_maintheme, 0.8) )
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,             UI.Tools_RGBA(UI.textcol, UI.textcol_a_enabled) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg,          UI.Tools_RGBA(UI.main_col, 0.7) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive,    UI.Tools_RGBA(UI.main_col, 0.95) )
      ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,         UI.Tools_RGBA(UI.windowBg, EXT.UI_transparency))
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      DATA.display_viewport_w, DATA.display_viewport_h = ImGui.Viewport_GetSize(main_viewport) 
      
      --ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      --ImGui.SetNextWindowDockID( ctx, EXT.viewport_dockID)
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font2) 
      DATA.titlename_reduced = ''
      if DATA.parent_track and DATA.parent_track.name and DATA.parent_track.IP_TRACKNUMBER_0based then 
        --DATA.titlename = '[Track '..math.floor(DATA.parent_track.IP_TRACKNUMBER_0based+1)..'] '..DATA.parent_track.name..' // '..DATA.UI_name..' '..rs5kman_vrs 
        DATA.titlename_reduced = DATA.parent_track.name
      end
      
      local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) --
      if rv then
        local Viewport = ImGui.GetWindowViewport(ctx)
        DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
        DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
        DATA.display_x_work, DATA.display_y_work = ImGui.Viewport_GetWorkPos(Viewport)
        -- hidingwindgets
        DATA.display_whratio = DATA.display_w / DATA.display_h
        UI.hide_padoverview = false
        UI.hide_tabs = false 
        if DATA.display_whratio < 1.7 then UI.hide_padoverview = true end
        if DATA.display_w < UI.settingsfixedW * 1.8 then UI.hide_tabs = true end
        --if DATA.display_w > UI.settingsfixedW * 5 then UI.hide_tabs = true end
        
        -- calc stuff for childs
        UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
        UI.calc_itemH = calcitemh + frameh * 2
        
        
        
        
        
         
         -- seq
        UI.calc_seqX = DATA.display_x + UI.spacingX
        UI.calc_seqY = DATA.display_y + UI.calc_itemH + UI.spacingY*2
        UI.calc_seqW = DATA.display_w
        
        if UI.hide_padoverview == true then  UI.calc_seqW = UI.calc_rackW end 
        UI.calc_seq_ctrl_butW = math.floor(UI.seq_padH*0.7)
        UI.calc_seq_ctrl_butH = UI.calc_seq_ctrl_butW  
        UI.calc_seqXL_padname = (UI.calc_seq_ctrl_butW + UI.spacingX)*5
        UI.calc_seqXL_steps = UI.calc_seqXL_padname +UI.seq_padnameW  + UI.seq_audiolevelW + UI.spacingX 
        UI.calc_seqW_steps = DATA.display_w - UI.calc_seqXL_steps
        
        UI.calc_seqW_steps_window = UI.seq_stepW*16
        UI.calc_seqW_steps_visible = math.floor(UI.calc_seqW_steps/UI.seq_stepW)
        
        -- peaks patch (otherwise it will not draw peaks)
        UI.calc_rack_padw = UI.seq_padnameW
        
        -- get drawlist
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        
        
        -- draw stuff
        DATA.allow_space_to_play = true
        UI.draw() 
        UI.draw_popups()  
        ImGui.Dummy(ctx,0,0)  
        if EXT.UI_allowshortcuts==1 then
          if DATA.allow_space_to_play == true then if ImGui.IsKeyPressed(ctx, ImGui.Key_Space) then 
            --if DATA.mainstate_manager ~= true and DATA.mainstate_seq == true then
              if GetPlayState()&1==1 then CSurf_OnStop() else CSurf_OnPlay() end end 
            --end
          end
        end
        
        ImGui.End(ctx)
      end 
     
     
    -- pop
      ImGui.PopStyleVar(ctx, 22) 
      ImGui.PopStyleColor(ctx, 23) 
      ImGui.PopFont( ctx ) 
    
    -- shortcuts
      
      if UI.anypopupopen == true then 
        if ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false ) then DATA.trig_closepopup = true end 
       else 
        if ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false ) then return end
      end
      
        
    return open
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_loop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    
    DATA:CollectData_Always()
    
    if DATA.upd == true then  DATA:CollectData()  end 
    DATA.upd = false 
     
    if DATA.upd_TCP == true then  
      TrackList_AdjustWindows( false ) 
      DATA.upd_TCP = false
    end
    
    
    -- draw UI
    if not reaper.ImGui_ValidatePtr( ctx, 'ImGui_Context*') then UI.MAIN_definecontext() end
    UI.open = UI.MAIN_styledefinition(true) 
     
    DATA:CollectData2() 
     
    -- handle xy
    DATA:handleViewportXYWH()
    
    -- data
    if UI.open  and not DATA.trig_stopdefer then defer(UI.MAIN_loop) else  
      gmem_write(1027, 0) -- rs5k stepseq state
      --DATA:Auto_StuffSysex_sub('on release') -- send keys layout to launchpad
    end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext()
    
    EXT:load() 
    
    -- imgUI init
    ctx = ImGui.CreateContext(DATA.UI_name) 
    -- fonts
    DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
    DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
    DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
    DATA.font4 = ImGui.CreateFont(UI.font, UI.font4sz) ImGui.Attach(ctx, DATA.font4)  
    DATA.font5 = ImGui.CreateFont(UI.font, UI.font5sz) ImGui.Attach(ctx, DATA.font5)  
     
    -- config
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
    
    
    -- run loop
    defer(UI.MAIN_loop)
  end
  
  -------------------------------------------------------------------------------- 
  function UI.draw_popups_pad()
    if DATA.trig_context == 'pad' and DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE  then 
      ImGui.SeparatorText(ctx, 'Pad '..DATA.parent_track.ext.PARENT_LASTACTIVENOTE)
      -- Remove
      local note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE 
      ImGui.Indent(ctx, 10)
      if ImGui.Button(ctx, 'Remove pad content',-1) then
        DATA:Sampler_RemovePad(note) 
        ImGui.CloseCurrentPopup(ctx) 
      end
      ImGui.Unindent(ctx, 10) 
      --Import
      ImGui.SeparatorText(ctx, 'Import media items')
      ImGui.Indent(ctx, 10)
      if ImGui.Button(ctx, 'Import selected items, starting this pad',0) then
        DATA:Sampler_ImportSelectedItems()
        ImGui.CloseCurrentPopup(ctx) 
      end
      if ImGui.Checkbox(ctx, 'Remove source item from track', EXT.CONF_importselitems_removesource==1) then EXT.CONF_importselitems_removesource=EXT.CONF_importselitems_removesource~1 EXT:save() end
      ImGui.Unindent(ctx, 10) 
      -- import last touched fx
      ImGui.SeparatorText(ctx, 'Import FX to pad')
      ImGui.Indent(ctx, 10) 
      UI.draw_3rdpartyimport_context(note)  
      ImGui.Unindent(ctx, 10)
    end
  end
  -------------------------------------------------------------------------------- 
  function UI.draw_popups() 
    function __f_popups() end
    if DATA.trig_openpopup then 
      ImGui.OpenPopup( ctx, 'mainRCmenu', ImGui.PopupFlags_None )
      DATA.trig_context = DATA.trig_openpopup 
      DATA.trig_openpopup = nil
    end
    
  
    local round = 4
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign, 0,0.5)
    
  
    -- draw content
    -- (from reaimgui demo) Always center this window when appearing
    --local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
    local windw = 300--DATA.display_w*0.3
    local windh = 300--DATA.display_h*0.5
    local center_x, center_y = ImGui.GetMouseClickedPos( ctx,ImGui.MouseButton_Right  )
    --ImGui.SetNextWindowPos(ctx, center_x+windw/2-25, center_y+windh/2-10, ImGui.Cond_Appearing, 0.5, 0.5)
    ImGui.SetNextWindowPos(ctx, center_x-25, center_y-10, ImGui.Cond_Appearing, 0, 0)
    ImGui.SetNextWindowSize(ctx, 0, 0, ImGui.Cond_Always)
    if ImGui.BeginPopup(ctx, 'mainRCmenu',ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border) then 
       
      UI.draw_popups_pad() 
      if DATA.trig_closepopup == true then ImGui.CloseCurrentPopup(ctx) DATA.trig_closepopup = nil end
      ImGui.EndPopup(ctx)
    end 
  
    ImGui.PopStyleVar(ctx, 5)
  end  
    ------------------------------------------------------------------------------ 
  function UI.draw_knob(knob_t)
    local debug = 0
    local x,y,w,h = knob_t.x,knob_t.y,knob_t.w,knob_t.h
    local name  = knob_t.name 
    local disabled  = knob_t.disabled 
    local centered  = knob_t.centered 
    local val_form  = knob_t.val_form or '' 
    local str_id  = knob_t.str_id 
    local draw_macro_index  = knob_t.draw_macro_index 
    local is_micro_knob  = knob_t.is_micro_knob 
    local yoffsarc  = knob_t.yoffsarc  or 0
    
    local val_max = knob_t.val_max or 1
    local val_min = knob_t.val_min or 0
    
    ImGui.SetCursorScreenPos(ctx,x,y) 
    local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX, UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,UI.spacingY) 
    
    -- size 
      local knobname_h = UI.calc_itemH
      local knobctrl_h = h- knobname_h-      UI.spacingY
      if not knob_t.customfont then ImGui.PushFont(ctx, DATA.font3) else ImGui.PushFont(ctx, knob_t.customfont)  end
      if knob_t.is_small_knob == true then  
        knobname_h = UI.calc_itemH
        knobctrl_h = h- knobname_h-UI.spacingY -UI.calc_itemH
      end
      if is_micro_knob== true then
        knobname_h = 0
        knobctrl_h = h
        yoffsarc = 1
      end
    -- name background 
    
      if is_micro_knob~= true then
        local color
        if knob_t and knob_t.I_CUSTOMCOLOR then 
          color = ImGui.ColorConvertNative(knob_t.I_CUSTOMCOLOR) 
          color = color & 0x1000000 ~= 0 and (color << 8) | 0xFF-- https://forum.cockos.com/showpost.php?p=2799017&postcount=6
        end
        if knob_t and knob_t.colfill_rgb then color = (knob_t.colfill_rgb << 8) | 0xFF end
        if color then 
          ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+knobname_h, color, 5, ImGui.DrawFlags_RoundCornersTop)
         else 
          if knob_t.active_name == true then
            ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+knobname_h, EXT.UI_colRGBA_paddefaultbackgr, 5, ImGui.DrawFlags_RoundCornersTop) 
           else
            ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+knobname_h, EXT.UI_colRGBA_paddefaultbackgr_inactive, 5, ImGui.DrawFlags_RoundCornersTop) 
          end
        end   
      end
    
    -- draw_macro_index
      if draw_macro_index and is_micro_knob~= true then
        local szidx = 8
        ImGui.DrawList_AddTriangleFilled( UI.draw_list, 
          x+w-szidx, y+knobname_h, 
          x+w-1, y+knobname_h, 
          x+w-1, y+knobname_h+szidx, 
          0x00FF00F0)
      end
    
    -- frame / selection  
      if knob_t.is_selected == true  then 
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, UI.colRGBA_selectionrect, 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
       else
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, 0x0000005F              , 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
      end  
      
      
      if debug ~= 1 then UI.Tools_setbuttonbackg() end
      
      
      local local_pos_x, local_pos_y = ImGui.GetCursorPos( ctx )
      
    -- name  
      if is_micro_knob~= true then
        ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y )
        ImGui.Button(ctx,'##slider_name'..str_id,w ,knobname_h ) 
        if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left)then
          if knob_t.appfunc_atclick_name then knob_t.appfunc_atclick_name() end
        end
        if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right)then
          if knob_t.appfunc_atclick_nameR then knob_t.appfunc_atclick_nameR() end
        end
      end
      
    -- control
      ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y+knobname_h )
      ImGui.Button(ctx,'##slider_name2'..str_id,w ,knobctrl_h) 
      UI.draw_knob_handlelatchstate(knob_t)
      local item_w, item_h = reaper.ImGui_GetItemRectSize( ctx )
      
      
       
    
    local val =  0
    if knob_t.val and knob_t.val then val = knob_t.val end
    if not val then return end
    local norm_val = (val - val_min) / (val_max - val_min)
    local draw_list = UI.draw_list
    local roundingIn = 0
    local col_rgba = 0xF0F0F0FF
    
    local radius = math.floor(math.min(item_w, item_h )/2)
    local radius_draw = math.floor(0.8 * radius)
    local center_x = curposx + item_w/2--radius
    local center_y = curposy + item_h/2  + knobname_h - yoffsarc
    local ang_min = -220
    local ang_max = 40
    local val_norm = (val -val_min)/ (val_max - val_min)
    
    local ang_val = ang_min + math.floor((ang_max - ang_min)*val_norm)
    local radiusshift_y = (radius_draw- radius)
    
    -- filled arc
    ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
    ImGui.DrawList_PathStroke(draw_list, 0xF0F0F02F,  ImGui.DrawFlags_None, 2)
    
    if not disabled == true then 
      -- value
      local radius_draw2 = radius_draw
      local radius_draw3 = radius_draw-6
      if centered ~= true then 
        -- back arc
        ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
        --ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2) 
        -- value
        --ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
        ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
        ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
        --ImGui.DrawList_PathClear(draw_list)
       else
        -- right arc
        if norm_val > 0.5 then 
          ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(-90),math.rad(ang_val+1))
          ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val+1)))
          ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
          --ImGui.DrawList_PathClear(draw_list)
         else
          ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val+1)))
          ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_val+1), math.rad(-90))
          
          ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
          --ImGui.DrawList_PathClear(draw_list)
        end
      end
    end
    
    -- text
      if is_micro_knob~= true then
        ImGui.SetCursorPos( ctx, local_pos_x+UI.spacingX, local_pos_y+UI.spacingY )
        ImGui.TextWrapped( ctx, name )
      end
      
    if disabled ~= true and is_micro_knob~= true then 
    -- format value
      ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y+h-UI.calc_itemH-UI.spacingY )
      local formatval_str_id = '##slider_formatval'..str_id
      if not (DATA.knob_strid_input and DATA.knob_strid_input  == formatval_str_id ) then 
        ImGui.Button(ctx,val_form..formatval_str_id,w ,UI.calc_itemH )
       else
        ImGui.SetNextItemWidth(ctx ,w)
        ImGui.SetKeyboardFocusHere( ctx, 0 )
        local retval, buf = ImGui.InputText( ctx, formatval_str_id, val_form, ImGui.InputTextFlags_None|ImGui.InputTextFlags_AutoSelectAll|ImGui.InputTextFlags_EnterReturnsTrue )
        if retval then
          if knob_t.parseinput then knob_t.parseinput(buf) end
          DATA.knob_strid_input = nil
        end
        
      end
      if knob_t.parseinput and ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui.IsMouseDoubleClicked( ctx, ImGui.MouseButton_Left ) then
        DATA.knob_strid_input = '##slider_formatval'..str_id
      end
      
    end
    
    
    
    
    ImGui.SetCursorScreenPos(ctx, curposx, curposy)
    ImGui.Dummy(ctx,knob_t.w,  knob_t.h)
    if debug ~= 1 then UI.Tools_unsetbuttonstyle() end
    ImGui.PopStyleVar(ctx,2) 
    ImGui.PopFont(ctx) 
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_knob_handlelatchstate(t)  
    local paramval = t.val or 0
    local val_max = t.val_max or 1
    local val_min = t.val_min or 0
    
    
    if ImGui_IsMouseDoubleClicked( ctx, ImGui.MouseButton_Left ) and ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) then
      if t.default_val then t.appfunc_atdrag(t.default_val) end
    end
    
    -- trig
    if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
      DATA.temp_latchstate = paramval  
      if t.appfunc_atclick then t.appfunc_atclick() end
      return 
    end
    
    if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
      DATA.temp_latchstate = paramval 
      if t.appfunc_atclickR then t.appfunc_atclickR() end
      return 
    end

    
    -- drag
    if  ImGui.IsItemActive( ctx ) then
      local x, y = ImGui.GetMouseDragDelta( ctx )
      local outval = DATA.temp_latchstate - y/(t.knob_resY or UI.knob_resY)  
      outval = math.max(val_min,math.min(outval,val_max))
      local dx, dy = ImGui.GetMouseDelta( ctx )
      if dy~=0 then
        if t.appfunc_atdrag then t.appfunc_atdrag(outval) end
      end
    end
    
    if ImGui.IsItemDeactivated( ctx )then
      if t.appfunc_atrelease then t.appfunc_atrelease() DATA.upd = true end
    end
    
    
    local vertical, horizontal = ImGui.GetMouseWheel( ctx )
    if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None )  and vertical ~= 0 then
      local outval = paramval + (math.abs(vertical)/vertical)/(t.knob_resY or UI.knob_resY)
      outval = math.max(val_min,math.min(outval,val_max))
      if t.appfunc_atdrag then t.appfunc_atdrag(outval) end
    end
  end
  -------------------------------------------------------------------------------- 
  function UI.HelpMarker(desc)
    ImGui.TextDisabled(ctx, '(?)')
    if ImGui.BeginItemTooltip(ctx) then
      ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
      ImGui.Text(ctx, desc)
      ImGui.PopTextWrapPos(ctx)
      ImGui.EndTooltip(ctx)
    end
  end
  
--------------------------------------------------------------------------------  
  function UI.draw()  
    if DATA.VCA_mode == 0 then 
      UI.knob_handle  = UI.knob_handle_normal 
     elseif DATA.VCA_mode == 1 then 
      UI.knob_handle = UI.knob_handle_vca
     elseif DATA.VCA_mode == 2 then 
      UI.knob_handle = UI.knob_handle_vca2       
    end
    
    local closew
    if (DATA.parent_track and DATA.parent_track.valid == true) and UI.calc_padoverviewW and UI.hide_padoverview ~= true then closew = UI.calc_padoverviewW-UI.spacingX*2  end
    if ImGui.Button(ctx, 'X',closew) then DATA.trig_stopdefer = true end 
    
    UI.draw_Seq() 
    
    if DATA.temp_loopslice_askforadd then -- autoslice_confirmation
      if not DATA.temp_loopslice_askforadd.triggerpopup then
        ImGui.OpenPopup( ctx, 'autoslice_confirmation', ImGui.PopupFlags_None )
        DATA.temp_loopslice_askforadd.triggerpopup = true
      end
    end
    
    if DATA.temp_loopslice_askforadd and DATA.temp_loopslice_askforadd.loop_t then
      local mousex, mousey = ImGui.GetMousePos( ctx )
      local out_w = 200
      local posx =  mousex-out_w/2 -- middle
      local posy = mousey-UI.calc_itemH*4 -- add as single button
      ImGui.SetNextWindowPos( ctx,posx, posy, ImGui.Cond_Once )
      ImGui.SetNextWindowSize( ctx, out_w, 0, ImGui.Cond_Always )
      if ImGui.BeginPopupModal( ctx, 'autoslice_confirmation', true, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border ) then
        local loop_t=  DATA.temp_loopslice_askforadd.loop_t
        local note=  DATA.temp_loopslice_askforadd.note
        local filename=  DATA.temp_loopslice_askforadd.filename
        local slice_cnt = #loop_t
        ImGui.Dummy(ctx,0, UI.spacingY)
        ImGui.Text(ctx, 'Loop is detected,\n'..slice_cnt..' slices found')
        
        if ImGui.Button(ctx, 'Slice to pads', -1) then
          DATA.temp_loopslice_askforadd.confirmed = true
          DATA:Auto_LoopSlice()
          ImGui.CloseCurrentPopup( ctx )
        end
        
        if ImGui.Button(ctx, 'Add as single sample', -1) then
          DATA.temp_loopslice_askforadd = nil
          DATA:DropSample(filename, note, {layer=1})
          ImGui.CloseCurrentPopup( ctx )
        end        
        
        if ImGui.Button(ctx, 'Cancel', -1) then
          DATA.temp_loopslice_askforadd = nil
          ImGui.CloseCurrentPopup( ctx )
        end
        
        ImGui.SeparatorText(ctx, 'Slicing options')
        
        if DATA.temp_loopslice_askforadd  then
          if ImGui.Checkbox(ctx, 'Create MIDI take', DATA.temp_loopslice_askforadd.createMIDI) then 
            DATA.temp_loopslice_askforadd.createMIDI = not DATA.temp_loopslice_askforadd.createMIDI 
            if DATA.temp_loopslice_askforadd.createMIDI == true then DATA.temp_loopslice_askforadd.createPattern = false end
          end
          if DATA.temp_loopslice_askforadd.createMIDI == true then 
            if ImGui.Checkbox(ctx, 'Stretch to project bpm', DATA.temp_loopslice_askforadd.stretchmidi) then DATA.temp_loopslice_askforadd.stretchmidi = not DATA.temp_loopslice_askforadd.stretchmidi end
          end
          if ImGui.Checkbox(ctx, 'Create sequencer pattern', DATA.temp_loopslice_askforadd.createPattern) then 
            DATA.temp_loopslice_askforadd.createPattern = not DATA.temp_loopslice_askforadd.createPattern 
            if DATA.temp_loopslice_askforadd.createPattern == true then DATA.temp_loopslice_askforadd.createMIDI = false end
          end
          
          
          
        end
        
        
        
        ImGui.EndPopup(ctx)
      end
    end
    
    if DATA.loopcheck_testdraw == 1 then
      reaper.ImGui_SetCursorPos(ctx, 1000,50)
      if DATA.temp_CDOE_arr then reaper.ImGui_PlotHistogram(ctx, 'arrtemp', DATA.temp_CDOE_arr, 0, '', 0, 1, 700, 100) end
      reaper.ImGui_SetCursorPos(ctx, 1000,150)
      if DATA.temp_CDOE_arr2 then reaper.ImGui_PlotHistogram(ctx, 'arrtemp', DATA.temp_CDOE_arr2, 0, '', 0, 1, 700, 100) end
    end
    
    
  end
  --------------------------------------------------------------------------------
  function UI.draw_peaks (id,note_layer_t,plotx_abs,ploty_abs,w,h, arr, is_pad_peak, dim) 
    if EXT.CONF_showpadpeaks == 0 and not id:match('cur') then return end
    if not arr then return end
    local note = note_layer_t.noteID
    
    local size = arr.get_alloc()
    local size_new = math.floor(size/2)
    if size_new < 0 then return end
     
    local peakscol =  0xFFFFFF7F
    if dim then peakscol =  0xFFFFFF25 end
    local last_xpos =plotx_abs
    for i = 1, size_new do
      local xpos = math.floor(plotx_abs + w * i/size_new )
      if xpos ~= last_xpos then
        local ypos =  math.floor(ploty_abs + h/2 * (1- arr[i]))
        local ypos2 =  math.floor(ploty_abs + h/2 * (1- arr[i+size_new]))
        ImGui_DrawList_AddRectFilled( UI.draw_list, last_xpos, ypos, xpos+1, ypos2, peakscol, 0, ImGui.DrawFlags_None )
      end
      last_xpos = xpos
    end
    
    -- show loop in sampler mode
    if is_pad_peak ~= true then
      local loop = note_layer_t.instrument_loop
      if loop >0 then
        local loopoffs = note_layer_t.instrument_loopoffs_norm
        ImGui_DrawList_AddRectFilled( UI.draw_list, plotx_abs+w*loopoffs, ploty_abs, plotx_abs+w, ploty_abs+h-3, 0x00FF001F, 0, ImGui.DrawFlags_None )
      end
    end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent() 
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,0) 
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,0) 
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,0) 
  end
  --------------------------------------------------------------------------------   
  function _main_LoadLibraries()
    local info = debug.getinfo(1,'S');  
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    local fp = script_path .. "mpl_RS5K_manager_functions.lua"
    if reaper.file_exists(fp)~= true then return end
    dofile(fp)
    return true
  end
  -------------------------------------------------------------------------------- 
  function UI.draw_chokecombo(note)
    
    if DATA.allow_container_usage ~= true then ImGui.BeginDisabled(ctx, true) end
    
    ImGui.SeparatorText(ctx, 'Choke setup')
    local preview = 'Cut by '
    for note_src in spairs(DATA.children) do
      if DATA.MIDIbus.choke_setup[note] and DATA.MIDIbus.choke_setup[note][note_src] and DATA.MIDIbus.choke_setup[note][note_src].exist == true then
        preview = preview..note_src..' '
      end
    end
    -- clear
    if ImGui.Button(ctx, 'Clear',-1) then 
      if (DATA.MIDIbus and DATA.MIDIbus.choke_setup and DATA.MIDIbus.choke_setup[note]) then 
        for note_src in pairs(DATA.MIDIbus.choke_setup[note]) do
          if DATA.MIDIbus.choke_setup[note][note_src].exist == true then DATA.MIDIbus.choke_setup[note][note_src].mark_for_remove = true end
        end
        DATA:Choke_Write()
      end
    end
    
    reaper.ImGui_SetNextItemWidth(ctx,-1)
    if ImGui.BeginCombo(ctx, '##choke_combo',preview) then 
      for note_src in spairs(DATA.children) do
        if note_src ~= note then 
          local padname = DATA.children[note_src].P_NAME
          local state = DATA.MIDIbus.choke_setup[note] and DATA.MIDIbus.choke_setup[note][note_src] and DATA.MIDIbus.choke_setup[note][note_src].exist == true
          if ImGui.Checkbox(ctx, note_src..' - '..padname..'##choke'..note_src..'note'..note, state) then
            if state == true then -- exist
              DATA.MIDIbus.choke_setup[note][note_src].mark_for_remove = true
             else
              if not DATA.MIDIbus.choke_setup[note] then DATA.MIDIbus.choke_setup[note] = {} end
              if not DATA.MIDIbus.choke_setup[note][note_src] then DATA.MIDIbus.choke_setup[note][note_src] = {add = true} end 
            end
            DATA:Choke_Write()
          end
        end
      end
      ImGui.EndCombo(ctx)
    end
    if DATA.allow_container_usage ~= true then ImGui.EndDisabled(ctx) end
  end
  -----------------------------------------------------------------------------------------  
  function _main() 
    local ret = _main_LoadLibraries() 
    
    -- get rack ID
    for idx =0, 1000000 do
      local retval, name = reaper.kbd_enumerateActions( section, idx )
      if not ( retval and retval~= 0) then return end
      if name:match('mpl_') and name:match('RS5k') and name:match('manager') then
        DATA.manager_ID = retval
        break
      end
    end
    
    local loadtest = time_precise()
    gmem_attach('RS5K_manager')
    gmem_write(1027, 1) -- rs5k stepseq opened
    DATA.REAPERini = VF_LIP_load( reaper.get_ini_file()) 
    
    
    UI.MAIN_definecontext() -- + EXT:load
    
    DATA:CollectDataInit_MIDIdevices() 
    DATA:CollectDataInit_LoadCustomPadStuff()
    DATA:CollectDataInit_EnumeratePlugins()
  end   
    ---------------------------------------------------------------------  
  _main()
  

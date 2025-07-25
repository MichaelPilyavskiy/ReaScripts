-- @description RS5k manager
-- @version 4.68
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Script for handling ReaSamplomatic5000 data on group of connected tracks
-- @provides
--    [main] mpl_RS5k_StepSequencer.lua
--    [main] mpl_RS5k_manager_Database_NewKit.lua
--    [main] mpl_RS5k_manager_Database_Lock.lua
--    [main] mpl_RS5k_manager_Sampler_PreviousSample.lua
--    [main] mpl_RS5k_manager_Sampler_NextSample.lua
--    [main] mpl_RS5k_manager_Sampler_RandSample.lua 
--    [main] mpl_RS5k_manager_DrumRack_Solo.lua
--    [main] mpl_RS5k_manager_DrumRack_Mute.lua 
--    [main] mpl_RS5k_manager_DrumRack_Clear.lua
--    [jsfx] mpl_RS5k_manager_MacroControls.jsfx
--    [jsfx] mpl_RS5K_manager_MIDIBUS_choke.jsfx
--    [jsfx] mpl_RS5K_manager_sysex_handler.jsfx
--    mpl_RS5K_manager_functions.lua
-- @changelog
--    # External actions: fix reset state
--    # External actions: fix error on missing selected note


rs5kman_vrs = '4.68'


-- TODO
--[[  
      
      seq
        if pattern has same GUId than oth er BUT not pooled or pool is diffent https://forum.cockos.com/showthread.php?p=2866575
        groups
        launchpad interaction
        
      sampler/sample
        hot record from master bus 
         
      auto
        auto switch midi bus record arm if playing with another rack 
        autocolor by content
        
      on sample add
        wildcards - device name
        wildcards - children - #notenuber #noteformat #samplename
        wildcards - samples path 
        
      layout
        step seq mode + input write step + scroll control over programming mode
          
      sampler/fx
        compressor
        transient shaper
        
      sampler/send tab - add sends to reverb, delay inside based on existing send tracks (predefine using sends folder name)
      
      sampler/global tweaks
        better handle global tweaks
        
      sampler/device
        FPC style rangesplit  
        
      autoslice
        set minimal length
        do not allow slices with low RMS (glue with previeos slice)
        
      autolufs
        use as a compensation
]]

    
--------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < 6.73 then return reaper.MB('This script require REAPER 6.73+','',0) end
    --local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require reaimgui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.9.3.2'
    
    --[[
      gmem 1025: actions 
        / 10=DATA.upd refresh rack
        / 11=DATA.upd refresh steseq // use 1030 instead
      gmem 1026: read-only - rs5k manager opened state 
      gmem 1027: read-only - rs5k stepseq opened state
      gmem 1028: force stepseq read extstate
      gmem 1029: incoming note for launchpad step seq
      gmem 1030: DATA.upd refresh steseq
    ]]
    
    
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 800,
          viewport_posH = 300, 
          viewport_dockID = 0,
          
          INI_fix = 0,
          
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
          CONF_onadd_ADSR_flags = 0,--&1 A &2 D &4 S &8 R
          CONF_onadd_ADSR_A = 0,
          CONF_onadd_ADSR_D = 15,
          CONF_onadd_ADSR_S = 0,
          CONF_onadd_ADSR_R = 0.02,
          CONF_onadd_sysexmode = 0,
          
          -- midi bus
          CONF_midiinput = 63, -- 63 all 62 midi kb
          CONF_midioutput = -1, 
          CONF_midichannel = 0, -- 0 == all channels 
          
          -- sampler
          CONF_cropthreshold = -60, -- db
          CONF_crop_maxlen = 30,
          CONF_default_velocity = 120,
          CONF_stepmode = 0,
          CONF_stepmode_transientahead = 0.01,
          CONF_stepmode_keeplen = 1, 
          
          -- UI
          
          UI_transparency = 1,
          UI_processoninit = 0,
          UI_addundototabclicks = 0,
          UI_clickonpadselecttrack = 1,
          UI_clickonpadscrolltomixer = 0,
          UI_clickonpadplaysample = 0, --
          UI_incomingnoteselectpad = 0,
          UI_defaulttabsflags = 1|4|8, --1=drumrack   2=device  4=sampler 8=padview 16=macro 32=database 64=midi map 128=children chain
          UI_pads_sendnoteoff = 1,
          UI_drracklayout = 0,
          UI_drracklayout_custommapB64 = '',
          UI_drracklayout_customID = 0,
          UIdatabase_maps_current = 1,
          UI_padcustomnames = '',
          UI_padcustomnamesB64 = '', -- patch for 4.57
          UI_padautocolors = '',
          UI_padautocolorsB64 = '',-- patch for 4.57
          CONF_showplayingmeters = 1,
          CONF_showpadpeaks = 1,
          --UI_optimizedockerusage = 0,
          UI_colRGBA_paddefaultbackgr = 0x1C1C1C7F ,
          UI_colRGBA_paddefaultbackgr_inactive = 0x6060603F,
          UI_col_tinttrackcoloralpha = 0x7F,
          UI_colRGBA_padctrl = 0x4F4F4FFF,
          UI_colRGBA_smplrbackgr = 0xFFFFFF2F,
          UI_allowshortcuts = 1, -- allow space to play
          
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
          --CONF_loopcheck_smoothend_use = 1,
          --CONF_loopcheck_smoothend = 0.005,
          
          -- seq
          CONF_seq_random_probability = 0.5,
          CONF_seq_force_GUIDbasedsharing = 0,
          CONF_seq_treat_mouserelease_as_majorchange  = 0, 
          CONF_seq_patlen_extendchildrenlen = 0,
          CONF_seq_instrumentsorder = 1, 
          CONF_seq_stuffMIDItoLP = 0, 
          CONF_seq_defaultstepcnt = 16, -- -1 follow pattern length
          CONF_seq_env_clamp = 1, -- 0 == allow env points on empty steps
          CONF_seq_steplength = 0.25,
         }
        
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          
          scheduler = {},
          
          
          upd = true,
          upd2 = {
            refreshpeaks = true,
          },
          ES_key = 'MPL_RS5K manager',
          UI_name = 'RS5K manager', 
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
          
          
          allow_space_to_play = true,
          allow_container_usage = app_vrs >=7.06,
          MIDIhandler = 'RS5k_manager MIDI_handler',
          }
  DATA.UI_name_vrs = DATA.UI_name..' '..rs5kman_vrs
  
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
    UI.w_min = 530
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
    UI.colRGBA_selectionrect = 0x00B300BF  
    UI.colRGBA_ADSRrect = 0x00AF00DF
    UI.colRGBA_ADSRrectHov = 0x00FFFFFF 
    UI.padplaycol = 0x00FF00 
    UI.knob_handle = 0xc8edfa
    UI.knob_handle_normal = UI.knob_handle
    UI.knob_handle_vca =0xFF0000
    UI.knob_handle_vca2 =0xFFFF00
    UI.col_popup = 0x005300 
    UI.def_colRGBA_paddefaultbackgr = 0x1C1C1C7F
    UI.def_colRGBA_paddefaultbackgr_inactive = 0x6060603F
    UI.def_colRGBA_padctrl = 0x4F4F4FFF
    UI.colRGBA_smplrbackgr = 0xFFFFFF2F
    -- various
    UI.tab_context = '' -- for context menu
    
    -- mouse
    UI.dragY_res = 10
    
    
  
  
  --------------------------------------------------------------------------------  
  function UI.transparentButton(ctx, str_id, w,h)
    ImGui.PushFont(ctx, DATA.font4) 
    UI.draw_setbuttonbackgtransparent()
    ImGui.Button(ctx, str_id, w,h)
    UI.Tools_unsetbuttonstyle()
    ImGui.PopFont(ctx) 
  end

  --------------------------------------------------------------------------------  
  function UI.Tools_setbuttonbackg(col)   
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, col or 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, col or 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, col or 0 )
  end
  --UI.Tools_setbuttonbackg()
  --UI.Tools_unsetbuttonstyle()
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
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha,1)
      ImGui.PushStyleColor(ctx, ImGui.Col_Border,           UI.Tools_RGBA(0x000000, 0.3))
    -- colors
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.main_col, 0.2))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.but_hovered, 0.8))
      ImGui.PushStyleColor(ctx, ImGui.Col_DragDropTarget,   UI.Tools_RGBA(0xFF1F5F, 0.6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,          UI.Tools_RGBA(0x1F1F1F, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,    UI.Tools_RGBA(UI.main_col, .6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,   UI.Tools_RGBA(UI.main_col, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,           UI.Tools_RGBA(UI.main_col, 0.3) )
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
        
        -- calc settings
        UI.calc_settingsW = UI.settingsfixedW 
        if UI.hide_tabs == true then UI.calc_settingsW = 0 end 
        
        -- calc padoverview
        UI.calc_padoverviewH = DATA.display_h- UI.spacingY*3- UI.calc_itemH
        UI.calc_padoverview_cellside = UI.calc_padoverviewH/32  
        UI.calc_padoverviewW = UI.calc_padoverview_cellside * 4 + UI.spacingX*2
        if UI.calc_padoverviewW < 30 or UI.calc_padoverviewW > 60 or EXT.UI_drracklayout == 2 then UI.hide_padoverview = true end
        if EXT.UI_drracklayout == 1 then --keys
          UI.calc_padoverview_cellside = UI.calc_padoverviewH /22
          UI.calc_padoverviewW = UI.calc_padoverview_cellside * 7 + UI.spacingX*2
        end 
        if UI.hide_padoverview == true and EXT.UI_drracklayout ~= 2 then UI.calc_padoverviewW = 0 end
        if UI.hide_padoverview == true and EXT.UI_drracklayout == 2 then UI.calc_padoverviewW = 28 end
         
        -- rack
        local rack_max_width = 500
        local rack_min_height = 250
        UI.calc_rackX = DATA.display_x + UI.spacingX + UI.calc_padoverviewW
        UI.calc_rackY = DATA.display_y + UI.spacingY 
        if ImGui_IsWindowDocked( ctx ) then UI.calc_rackY = DATA.display_y + UI.spacingY end
        if EXT.UI_drracklayout == 2  then rack_max_width = 600 end --launch
        UI.calc_rackW = math.min(DATA.display_w - UI.calc_settingsW - UI.calc_padoverviewW,rack_max_width)
        UI.calc_rackH = math.max(math.floor(DATA.display_h  -UI.spacingY )-1,rack_min_height)
        
        UI.calc_rack_padw = math.floor((UI.calc_rackW-UI.spacingX*3) / 4)
        UI.calc_rack_padh = math.floor((UI.calc_rackH-UI.spacingY*3) / 4)
        if EXT.UI_drracklayout == 1 then --keys
          UI.calc_rack_padw = math.floor((UI.calc_rackW) / 7)-- -UI.spacingX
          UI.calc_rack_padh = math.floor((UI.calc_rackH) / 4)
        end
        UI.calc_rack_padctrlW = UI.calc_rack_padw / 3 
        UI.calc_rack_padctrlH = UI.calc_rack_padh*0.3
        UI.calc_rack_padnameH = UI.calc_rack_padh-UI.calc_rack_padctrlH 
        
        
        if EXT.UI_drracklayout == 2 then
          local ID = EXT.UI_drracklayout_customID
          if DATA.custom_layouts[ID] then
            local cell_cnt_max = DATA.custom_layouts[ID].cell_cnt_max
            local col_cnt = DATA.custom_layouts[ID].col_cnt
            local row_cnt = DATA.custom_layouts[ID].row_cnt   
            if col_cnt * row_cnt>cell_cnt_max then row_cnt = math.ceil(cell_cnt_max / col_cnt) end
            
            local rackx = UI.calc_rackX
            local racky = UI.calc_rackY
            UI.calc_rack_padw = (UI.calc_rackW-UI.spacingX) / col_cnt
            UI.calc_rack_padh = (UI.calc_rackH-UI.spacingY) / row_cnt
            UI.calc_rack_padctrlH = UI.calc_rack_padh*0.3
            UI.calc_rack_padnameH = UI.calc_rack_padh-UI.calc_rack_padctrlH 
            if UI.calc_rack_padctrlH < 30 then
              UI.calc_rack_padctrlH = 0
              UI.calc_rack_padnameH = UI.calc_rack_padh
            end
            UI.calc_rack_padctrlW = UI.calc_rack_padw / 3 
          end
        end
        
        
        
        
        -- settings
        UI.calc_settingsX = UI.calc_rackW + UI.calc_padoverviewW + UI.spacingX*2
        UI.calc_settingsY = UI.spacingY*2 + UI.calc_itemH
        
        -- small knob controls
        UI.calc_knob_w_small = math.floor((UI.calc_settingsW - UI.spacingX*9) / 8) 
        UI.calc_knob_h_small = 90--math.floor((DATA.display_h  - UI.calc_itemH*3-UI.spacingY*7 - UI.sampler_peaksH)/2)
        -- small macro controls
        UI.calc_macro_w = math.floor((UI.calc_settingsW - UI.spacingX*7) / 4)
        UI.calc_macro_h = 65--math.floor((DATA.display_h - UI.spacingY*4 - UI.calc_itemH*3) / 4)
        
        -- sampler 
        UI.calc_sampler4ctrl_W = math.floor((UI.calc_settingsW - UI.spacingX*5) / 4) 
         
        
        
        -- get drawlist
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        
        
        -- draw stuff
        DATA.allow_space_to_play = true
        UI.draw() 
        UI.draw_popups()  
        ImGui.Dummy(ctx,0,0)  
        if EXT.UI_allowshortcuts==1 then
          if DATA.allow_space_to_play == true then if ImGui.IsKeyPressed(ctx, ImGui.Key_Space) then if GetPlayState()&1==1 then CSurf_OnStop() else CSurf_OnPlay() end end end
        end
        
        
        
        if DATA.parent_track and DATA.parent_track.valid == true and UI.hide_tabs ~= true  then
          ImGui.SetCursorPos(ctx,UI.calc_settingsX,UI.spacingY)
          ImGui.BeginDisabled(ctx, true) ImGui.Text(ctx, DATA.UI_name_vrs)ImGui.EndDisabled(ctx)
          ImGui.SameLine(ctx)
          ImGui.Dummy(ctx,5,0)
          ImGui.SameLine(ctx)
          ImGui.Text(ctx, DATA.titlename_reduced)
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
     
    --[[if DATA.upd_TCP == true then  
      TrackList_AdjustWindows( false ) 
      DATA.upd_TCP = false
    end]]
    
    
    -- draw UI
    if not reaper.ImGui_ValidatePtr( ctx, 'ImGui_Context*') then UI.MAIN_definecontext() end
    UI.open = UI.MAIN_styledefinition(true) 
    
    
    DATA:CollectData2() 
    
    
    -- handle xy
    DATA:handleViewportXYWH()
    
    -- data
    if UI.open  and not DATA.trig_stopdefer then defer(UI.MAIN_loop) else
      gmem_write(1026, 0) -- rs5k manager opened
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
  function UI.draw_Rack_PadOverview() 
    if UI.hide_padoverview == true then return end
    
    
    ImGui.SetCursorPosY(ctx,UI.spacingY*2 + UI.calc_itemH)
    
    local ovrvieww = UI.calc_padoverview_cellside*4
    if EXT.UI_drracklayout == 1 then ovrvieww = UI.calc_padoverview_cellside*7 end
    --ImGui.InvisibleButton(ctx, '##padoverview',ovrvieww,-1)
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0)
    local val = 0
    if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_DRRACKSHIFT then val = DATA.parent_track.ext.PARENT_DRRACKSHIFT /127 end
    local retval, v = ImGui.VSliderDouble( ctx, '##padoverview', ovrvieww,UI.calc_padoverviewH, val, 0, 1, '', ImGui.SliderFlags_None)
    ImGui.PopStyleColor(ctx,5)
    if retval then UI.Layout_PadOverview_handlemouse(v) end
    local x, y = ImGui.GetItemRectMin(ctx)
    local w, h = ImGui.GetItemRectSize(ctx) 
    if EXT.UI_drracklayout == 0 then UI.Layout_PadOverview_generategrid_pads(x+1,y,w,h) end 
    if EXT.UI_drracklayout == 1 then UI.Layout_PadOverview_generategrid_keys(x+1,y,w,h) end 
    --if EXT.UI_drracklayout == 2 then UI.Layout_PadOverview_generategrid_launchpad(x+1,y,w,h) end 
  end
  --------------------------------------------------------------------------------
  function UI.Layout_PadOverview_handlemouse(v)  
    if not (DATA.parent_track and DATA.parent_track.ext) then return end
    -- pads 
    if EXT.UI_drracklayout == 0 or EXT.UI_drracklayout == 2 then
      local activerow = math.floor(v*33)
      local qblock = 4
      if activerow < 1 then activerow = 0 end
      for block = 0, 6 do if activerow >=block*4+1 and activerow <(block*4)+4+1 then activerow =block*4+1 end end
      activerow = math.min(activerow, 28)
      local out_offs = math.floor(activerow*4)
      if out_offs ~= DATA.parent_track.ext.PARENT_DRRACKSHIFT then 
        DATA.parent_track.ext.PARENT_DRRACKSHIFT = out_offs
        DATA:WriteData_Parent()
      end
    end
     
    -- keys
    if EXT.UI_drracklayout == 1 then 
      local out_offs = 127-math.floor((1-v)*127) 
      out_offs = 12 * math.floor(out_offs/12)
      if out_offs ~= DATA.parent_track.ext.PARENT_DRRACKSHIFT then 
        DATA.parent_track.ext.PARENT_DRRACKSHIFT = out_offs
        DATA:WriteData_Parent()
      end
    end
  end
  -----------------------------------------------------------------------------  
  function UI.Layout_PadOverview_generategrid_pads(x,y,w,h)
    if not DATA.children then return end
    local refnote = 127
    for note = 0, 127 do 
      -- handle col
      local blockcol = 0x757575
      if 
        (note >=0 and note<=3)or
        (note >=20 and note<=35)or
        (note >=52 and note<=67)or
        (note >=84 and note<=99)or
        (note >=116 and note<=127) 
      then blockcol =0xD5D5D5 end
      
      
      local backgr_fill2 = 0.6 
      if DATA.children[note] then backgr_fill2 = 0.8  blockcol = 0xf3f6f4 end
      if DATA.playingnote and DATA.playingnote == note  then blockcol = 0xffe494 backgr_fill2 = 0.9 end
      
      
      if note%4 == 0 then x_offs = x end
      local p_min_x = x_offs
      local p_min_y = y+h - UI.calc_padoverview_cellside*(1+(math.floor(note/4)))
      local p_max_x = p_min_x+UI.calc_padoverview_cellside-1
      local p_max_y = p_min_y+UI.calc_padoverview_cellside-1
      ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, blockcol<<8|math.floor(backgr_fill2*0xFF), 0, ImGui.DrawFlags_None )
      ImGui_SetCursorScreenPos( ctx, p_min_x, p_min_y )
      ImGui_InvisibleButton( ctx, '##padnote'..note, UI.calc_padoverview_cellside, UI.calc_padoverview_cellside )
      if ImGui.BeginDragDropTarget( ctx ) then  
        --UI.Drop_UI_interaction_padoverview() 
        UI.Drop_UI_interaction_pad(note) 
        ImGui_EndDragDropTarget( ctx )
      end
      x_offs = x_offs + UI.calc_padoverview_cellside
    end
    
    -- selection
    if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_DRRACKSHIFT then
      local row_cnt = math.floor(127/4)
      local activerow = DATA.parent_track.ext.PARENT_DRRACKSHIFT  / 4
      local p_min_x = x
      local p_min_y = y+h - w-UI.calc_padoverview_cellside*(activerow)
      local p_max_x = p_min_x+w-1
      local p_max_y = p_min_y+w
      ImGui.DrawList_AddRect( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, UI.colRGBA_selectionrect, 0, ImGui.DrawFlags_None, 2 )
    end
    
  end
  -----------------------------------------------------------------------------  
  function UI.Layout_PadOverview_generategrid_launchpad(x,y,w,h)
    if not DATA.children then return end
    local refnote = 127
    for note = 0, 127 do 
      -- handle col
      local blockcol = 0x757575
     --[[ if 
        (note >=0 and note<=3)or
        (note >=20 and note<=35)or
        (note >=52 and note<=67)or
        (note >=84 and note<=99)or
        (note >=116 and note<=127) 
      then blockcol =0xD5D5D5 end]]
      if note %12==0 then blockcol =0xD5D5D5 end
      
      local backgr_fill2 = 0.4 
      if DATA.children[note] then backgr_fill2 = 0.8  blockcol = 0xf3f6f4 end
      if DATA.playingnote and DATA.playingnote == note  then blockcol = 0xffe494 backgr_fill2 = 0.7 end
      
      
      if note%4 == 0 then x_offs = x end
      local p_min_x = x_offs
      local p_min_y = y+h - UI.calc_padoverview_cellside*(1+(math.floor(note/4)))
      local p_max_x = p_min_x+UI.calc_padoverview_cellside-1
      local p_max_y = p_min_y+UI.calc_padoverview_cellside-1
      ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, blockcol<<8|math.floor(backgr_fill2*0xFF), 0, ImGui.DrawFlags_None )
      ImGui_SetCursorScreenPos( ctx, p_min_x, p_min_y )
      ImGui_InvisibleButton( ctx, '##padnote'..note, UI.calc_padoverview_cellside, UI.calc_padoverview_cellside )
      if ImGui.BeginDragDropTarget( ctx ) then  
        --UI.Drop_UI_interaction_padoverview() 
        UI.Drop_UI_interaction_pad(note) 
        ImGui_EndDragDropTarget( ctx )
      end
      x_offs = x_offs + UI.calc_padoverview_cellside
    end
    
    -- selection
    if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_DRRACKSHIFT then
      local row_cnt = math.floor(127/4)
      local activerow = DATA.parent_track.ext.PARENT_DRRACKSHIFT  / 4
      local p_min_x = x
      local p_min_y = y+h - w-UI.calc_padoverview_cellside*(activerow)
      local p_max_x = p_min_x+w-1
      local p_max_y = p_min_y+w
      ImGui.DrawList_AddRect( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, UI.colRGBA_selectionrect, 0, ImGui.DrawFlags_None, 1 )
    end
    
  end
  
  -----------------------------------------------------------------------------  
  function UI.Layout_PadOverview_generategrid_keys(x_offs0,y_offs0,w,h) 
  
    for note = 0, 127 do 
      -- handle col
      local blockcol = 0x757575
      if 
        (
          note%12 == 0
          or note%12 == 2
          or note%12 == 4
          or note%12 == 5
          or note%12 == 7
          or note%12 == 9
          or note%12 == 11
          
        ) 
      then blockcol =0xD5D5D5 end
      
      
      local backgr_fill2 = 0.4 
      if DATA.children[note] then backgr_fill2 = 0.8  blockcol = 0xf3f6f4 end
      if DATA.playingnote and DATA.playingnote == note  then blockcol = 0xffe494 backgr_fill2 = 0.7 end
      
      local x_offs = x_offs0
      local isblack
      if note%12 == 0 then x_offs = x_offs0 end
      if note%12 == 1 then x_offs = x_offs0+UI.calc_padoverview_cellside*0.5 isblack = true end
      if note%12 == 2 then x_offs = x_offs0+UI.calc_padoverview_cellside*1 end
      if note%12 == 3 then x_offs = x_offs0+UI.calc_padoverview_cellside*1.5 isblack = true end
      if note%12 == 4 then x_offs = x_offs0+UI.calc_padoverview_cellside*2 end
      if note%12 == 5 then x_offs = x_offs0+UI.calc_padoverview_cellside*3 end
      if note%12 == 6 then x_offs = x_offs0+UI.calc_padoverview_cellside*3.5 isblack = true end
      if note%12 == 7 then x_offs = x_offs0+UI.calc_padoverview_cellside*4 end
      if note%12 == 8 then x_offs = x_offs0+UI.calc_padoverview_cellside*4.5 isblack = true end
      if note%12 == 9 then x_offs = x_offs0+UI.calc_padoverview_cellside*5 end
      if note%12 == 10 then x_offs = x_offs0+UI.calc_padoverview_cellside*5.5 isblack = true end
      if note%12 == 11 then x_offs = x_offs0+UI.calc_padoverview_cellside*6 end
      local oct = math.floor(note/12)
      local y_offs = y_offs0 +h  - (UI.calc_padoverview_cellside*2) * oct-UI.calc_padoverview_cellside
      if isblack then y_offs = y_offs - UI.calc_padoverview_cellside end
      local p_min_x = x_offs
      local p_min_y = y_offs
      local p_max_x = p_min_x+UI.calc_padoverview_cellside-1
      local p_max_y = p_min_y+UI.calc_padoverview_cellside-1
      ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, blockcol<<8|math.floor(backgr_fill2*0xFF), 0, ImGui.DrawFlags_None )
      ImGui_SetCursorScreenPos( ctx, p_min_x, p_min_y )
      ImGui_InvisibleButton( ctx, '##padnote'..note, UI.calc_padoverview_cellside, UI.calc_padoverview_cellside )
      if ImGui.BeginDragDropTarget( ctx ) then  
        --UI.Drop_UI_interaction_padoverview() 
        UI.Drop_UI_interaction_pad(note) 
        ImGui_EndDragDropTarget( ctx )
      end
    end
    
    -- selection
    if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_DRRACKSHIFT then
      local activerow = DATA.parent_track.ext.PARENT_DRRACKSHIFT/12
      local activerecth = UI.calc_padoverview_cellside*2
      
      local p_min_x = x_offs0
      local p_min_y = y_offs0+(10-activerow)*activerecth-1
      local p_max_x = p_min_x+w-1
      local p_max_y = p_min_y+activerecth
      ImGui.DrawList_AddRect( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y,UI.colRGBA_selectionrect, 0, ImGui.DrawFlags_None, 1 )
    end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_settings_combo(extkey, mapt, str_id, name, extw)
    ImGui.SetNextItemWidth(ctx, extw or UI.settings_itemW )
    if ImGui.BeginCombo( ctx, name..str_id, mapt[EXT[extkey] ], ImGui.ComboFlags_None ) then--|ImGui.ComboFlags_NoArrowButton
      for key in spairs(mapt) do 
        if ImGui.Selectable( ctx, mapt[key]..str_id..key, EXT[extkey] == key, ImGui.SelectableFlags_None) then EXT[extkey] = key EXT:save() DATA.upd = true end
      end
      ImGui.EndCombo( ctx)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_flow_COMBO(t)
    local trig_action
    local preview_value
    if t.hide == true then return end
    if type(EXT[t.extstr]) == 'number' then 
      for key in pairs(t.values) do 
        local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(key)})[2] == 0 
        if type(key) == 'number' and key ~= 0 and ((isint==true and EXT[t.extstr]&key==key) or EXT[t.extstr]==key) then preview_value = t.values[key] break end 
      end
     elseif type(EXT[t.extstr]) == 'string' then 
      preview_value = EXT[t.extstr] 
    end
    if not preview_value and t.values[0] then preview_value = t.values[0] end 
    ImGui.SetNextItemWidth( ctx, t.extw or -1 )
    if ImGui.BeginCombo( ctx, t.key, preview_value ) then
      for id in spairs(t.values) do
        local selected 
        if type(EXT[t.extstr]) == 'number' then 
          
          local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(id)})[2] == 0 
          selected = ((isint==true and id&EXT[t.extstr]==EXT[t.extstr]) or id==EXT[t.extstr])  and EXT[t.extstr]~= 0 
        end
        if type(EXT[t.extstr]) == 'string' then selected = EXT[t.extstr]==id end
        
        if ImGui.Selectable( ctx, t.values[id],selected  ) then
          EXT[t.extstr] = id
          trig_action = true
          EXT:save()
          if EXT.CONF_applylive == 1 then DATA:Process() end
        end
      end
      ImGui.EndCombo(ctx)
    end
    
    -- reset
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
      trig_action = true
      if EXT.CONF_applylive == 1 then DATA:Process() end
    end  
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
    return  trig_action
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_Actions()

    -------------- General
    ImGui.SeparatorText(ctx, 'General')
    ImGui.Indent(ctx, 10)
    -- stick current track 
      local stickstate = DATA.parent_track and DATA.parent_track.ext_load == true
      if DATA.parent_track and DATA.parent_track.trGUID then
        if ImGui.Checkbox( ctx, 'Stick current rack to this project', stickstate) then 
          if DATA.parent_track.ext_load == true then 
            SetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID','')
            DATA.upd = true
           else
            SetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID',DATA.parent_track.trGUID )
            DATA.upd = true
          end
        end
      end
      ImGui.SameLine(ctx)
      UI.HelpMarker('This rack will be always displayed even if selected track is not related to this rack.\nThis also ignores other racks in project.')
    -- fix GUID
      local fixavailable = ''
      local available_extGUID = not (DATA.parent_track and DATA.parent_track.valid == true and DATA.parent_track.ext.PARENT_GUID_INTERNAL)
      if available_extGUID == true then fixavailable = '[not available] ' end
      if available_extGUID ~= true then ImGui.BeginDisabled(ctx, true) end
      if ImGui.Selectable( ctx, fixavailable..'Fix GUID of parent track', EXT.CONF_lastmacroaction==1, reaper.ImGui_SelectableFlags_None(), 0, 0 ) then 
        GetSetMediaTrackInfo_String( DATA.parent_track.ptr, 'GUID', DATA.parent_track.ext.PARENT_GUID_INTERNAL, true )
        DATA.upd = true
      end 
      ImGui.SameLine(ctx) UI.HelpMarker('Use this if rack doesn`t handled by RS5k manager after import template')
      if available_extGUID ~= true then ImGui.EndDisabled(ctx) end
    ImGui.Unindent(ctx, 10)
  
  
    -------------- MIDI
    ImGui.SeparatorText(ctx, 'MIDI')
    ImGui.Indent(ctx, 10) 
    -- explode take
      if ImGui.Selectable( ctx, 'Explode MIDI bus take to children') then DATA:Action_ExplodeTake() end
    ImGui.Unindent(ctx, 10)


    --[[------------ LP
    ImGui.SeparatorText(ctx, 'LaunchPad')
      ImGui.Indent(ctx, 10)  
      if ImGui.Checkbox( ctx, 'Drum layout', EXT.CONF_seq_sendsysextoLP==0) then       
        DATA:Launchpad_StuffSysex('F0h 00h 20h 29h 02h 0Dh 00h 04h F7h'  ) 
        EXT.CONF_seq_sendsysextoLP = EXT.CONF_seq_sendsysextoLP~1 EXT:save()
        if DATA.MIDIbus.valid == true and DATA.MIDIbus.tr_ptr then SetMediaTrackInfo_Value( DATA.MIDIbus.tr_ptr, 'I_MIDIHWOUT', EXT.CONF_midioutput<<5) end
        DATA.upd = true
      end --  Drum layout
      ImGui.SameLine(ctx) ImGui.Dummy(ctx, 20, 0) ImGui.SameLine(ctx)
      if EXT.CONF_seq_sendsysextoLP == 1 then reaper.ImGui_BeginDisabled(ctx, true )  end
      if ImGui.Checkbox( ctx, 'Enable monitoring', DATA.MIDIbus.valid == true and DATA.MIDIbus.I_RECMON>0) then       DATA:Launchpad_StuffSysex(nil,1 ) DATA.upd = true end --  Drum layout
      if EXT.CONF_seq_sendsysextoLP == 1 then reaper.ImGui_EndDisabled(ctx )  end
      ImGui.Indent(ctx,10)ImGui.TextDisabled(ctx, '+ MIDI bus: disable monitoring, set MIDI HW output')ImGui.Unindent(ctx,10)
      
      if ImGui.Checkbox( ctx, 'Programmer mode + enable send sequencer data to LP', EXT.CONF_seq_sendsysextoLP==1) then   
        DATA:Launchpad_StuffSysex('F0h 00h 20h 29h 02h 0Dh 00h 7Fh F7h'  ) 
        EXT.CONF_seq_sendsysextoLP = EXT.CONF_seq_sendsysextoLP~1 EXT:save()
        if DATA.MIDIbus.valid == true and DATA.MIDIbus.tr_ptr then SetMediaTrackInfo_Value( DATA.MIDIbus.tr_ptr, 'I_MIDIHWOUT', -1) end
        DATA.upd = true
      end --  Programmer mode layout
      ImGui.Indent(ctx,10)ImGui.TextDisabled(ctx, '+ MIDI bus: disable monitoring, unset MIDI HW output')ImGui.Unindent(ctx,10)
            ]]
            
      ImGui.Unindent(ctx, 10)
      
    
  end 
--------------------------------------------------------------------------------  
  function UI.draw_tabs_settings_database()
    if ImGui.CollapsingHeader(ctx, 'Database maps') then
      ImGui.Indent(ctx,UI.settings_indent)

      -- database
      if DATA.database_maps then 
        -- ImGui.SeparatorText(ctx, 'Database maps') -- ImGui.Text(ctx, 'Database maps') 
        --ImGui.Indent(ctx, UI.settings_indent)
        ImGui.SetNextItemWidth(ctx, UI.settings_itemW )
        
        if DATA.temp_rename == true then 
          local retval, buf = reaper.ImGui_InputText( ctx, '##dbcurname', DATA.database_maps[EXT.UIdatabase_maps_current].dbname, ImGui.InputTextFlags_AutoSelectAll|ImGui.InputTextFlags_EnterReturnsTrue )
          if ImGui.IsItemActive(ctx) and DATA.allow_space_to_play == true then DATA.allow_space_to_play = false end
          if retval and buf ~= '' then 
            DATA.temp_rename = false
            DATA.database_maps[EXT.UIdatabase_maps_current].dbname = buf
            DATA:Database_Save()
          end
         else
         
          if ImGui.BeginCombo( ctx, '##Loaddatabasemap', DATA.database_maps[EXT.UIdatabase_maps_current].dbname, ImGui.ComboFlags_None ) then--|ImGui.ComboFlags_NoArrowButton
            for i = 1, 8 do
              if ImGui.Selectable( ctx, DATA.database_maps[i].dbname..'##dbmapsel'..i, i == EXT.UIdatabase_maps_current, ImGui.SelectableFlags_None) then EXT.UIdatabase_maps_current = i EXT:save() end
            end
            ImGui.EndCombo( ctx)
          end
        end
        ImGui.SameLine(ctx) UI.HelpMarker('Database map defines which database is linked to which note') 
        ImGui.SameLine(ctx) if ImGui.Button(ctx, 'Rename') then DATA.temp_rename = true  end
        ImGui.SameLine(ctx) if ImGui.Button(ctx, 'Save') then DATA:Database_Save()  end
        ImGui.SetNextItemWidth(ctx, 100 )
        local note_format = 'Note '..DATA.settings_cur_note_database..': '..VF_Format_Note(DATA.settings_cur_note_database)
        if ImGui.BeginCombo( ctx, '##dbselectnote', note_format, ImGui.ComboFlags_None ) then
          for note = 0, 127 do
             local note_format = 'Note '..note..': '..VF_Format_Note(note)
            if ImGui.Selectable( ctx, note_format, false, ImGui.SelectableFlags_None) then 
              DATA.settings_cur_note_database = note
            end
          end 
          ImGui.EndCombo( ctx )
        end
        ImGui.SameLine(ctx) 
        ImGui.SetNextItemWidth(ctx, -1)
        local preview = ''
        if DATA.database_maps
          and EXT.UIdatabase_maps_current
          and DATA.database_maps[EXT.UIdatabase_maps_current]
          and DATA.database_maps[EXT.UIdatabase_maps_current].map
          and DATA.settings_cur_note_database
          and DATA.database_maps[EXT.UIdatabase_maps_current].map[DATA.settings_cur_note_database]
          and DATA.database_maps[EXT.UIdatabase_maps_current].map[DATA.settings_cur_note_database].dbname then
          preview = DATA.database_maps[EXT.UIdatabase_maps_current].map[DATA.settings_cur_note_database].dbname
        end
        if ImGui.BeginCombo( ctx, '##dbselect', preview, ImGui.ComboFlags_None ) then
          for dbname in pairs(DATA.reaperDB) do
            if ImGui.Selectable( ctx, dbname, false, ImGui.SelectableFlags_None) then 
              if not  DATA.database_maps[EXT.UIdatabase_maps_current] then  DATA.database_maps[EXT.UIdatabase_maps_current] = {} end
              if not  DATA.database_maps[EXT.UIdatabase_maps_current].map then  DATA.database_maps[EXT.UIdatabase_maps_current].map = {} end
              if not  DATA.database_maps[EXT.UIdatabase_maps_current].map[DATA.settings_cur_note_database] then  DATA.database_maps[EXT.UIdatabase_maps_current].map[DATA.settings_cur_note_database] = {} end
              DATA.database_maps[EXT.UIdatabase_maps_current].map[DATA.settings_cur_note_database].dbname = dbname
              local ignore_current_rack = true
              DATA:Database_Save(ignore_current_rack)
            end
          end
          ImGui.EndCombo( ctx )
        end
        if ImGui.Button(ctx, 'Load to all rack') then 
          DATA:Validate_MIDIbus_AND_ParentFolder() 
          Undo_BeginBlock2(DATA.proj )
          DATA:Database_Load() 
          Undo_EndBlock2( DATA.proj , 'Load database to all rack', 0xFFFFFFFF )
        end
        
        ImGui.SameLine(ctx) if ImGui.Button(ctx, 'Load to selected pad only') then 
          DATA:Validate_MIDIbus_AND_ParentFolder() 
          Undo_BeginBlock2(DATA.proj )
          DATA:Database_Load(true)
          Undo_EndBlock2( DATA.proj , 'Load database to selected pad only', 0xFFFFFFFF )
        end
        
        
        --ImGui.Unindent(ctx, UI.settings_indent)
      end
      if ImGui.Checkbox( ctx, 'Do not load database',            EXT.CONF_ignoreDBload == 1 ) then EXT.CONF_ignoreDBload =EXT.CONF_ignoreDBload~1 EXT:save() end
      ImGui.SameLine(ctx)
      UI.HelpMarker('May increase loading time, but you wont be able to use databases')
      ImGui.Text( ctx, 'Current loading time: '..(math.floor(10000*DATA.loadtest)/10000)..'s')
      
      
      
      ImGui.Unindent(ctx,UI.settings_indent)
    end  
  end
--------------------------------------------------------------------------------  
  function UI.draw_tabs_settings_onsampleadd()
    if ImGui.CollapsingHeader(ctx, 'On sample add') then   
      ImGui.Indent(ctx,UI.settings_indent)
      
      
      if ImGui.CollapsingHeader(ctx, 'FX instance##On sample add_fx') then   
        ImGui.Indent(ctx, UI.settings_indent)
        if ImGui.Checkbox( ctx, 'Rename instance',                                        EXT.CONF_onadd_renameinst == 1 ) then EXT.CONF_onadd_renameinst =EXT.CONF_onadd_renameinst~1 EXT:save() end 
                if EXT.CONF_onadd_renameinst == 1 then
                  ImGui_SetNextItemWidth(ctx, UI.settings_itemW) 
                  local ret, buf = ImGui.InputText( ctx, 'instance name',                    EXT.CONF_onadd_renameinst_str, ImGui.InputTextFlags_EnterReturnsTrue) 
                  if ret then 
                    EXT.CONF_onadd_renameinst_str =buf 
                    EXT:save() 
                  end
                  ImGui.SameLine(ctx)
                  UI.HelpMarker(
        [[Supported wildcards:
          #note - note number
          #layer - layer number
        ]])
                end
        if ImGui.Checkbox( ctx, 'Float RS5k instance',                                    EXT.CONF_onadd_float == 1 ) then EXT.CONF_onadd_float =EXT.CONF_onadd_float~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Set obey notes-off',                                     EXT.CONF_onadd_obeynoteoff == 1 ) then EXT.CONF_onadd_obeynoteoff =EXT.CONF_onadd_obeynoteoff~1 EXT:save() end 
        if ImGui.Checkbox( ctx, 'Set Gain to normalized LUFS',                                     EXT.CONF_onadd_autoLUFSnorm_toggle == 1 ) then EXT.CONF_onadd_autoLUFSnorm_toggle =EXT.CONF_onadd_autoLUFSnorm_toggle~1 EXT:save() end 
        if EXT.CONF_onadd_autoLUFSnorm_toggle == 1 then 
          ImGui.SameLine(ctx)
          reaper.ImGui_SetNextItemWidth(ctx, 100)
          local normformat = EXT.CONF_onadd_autoLUFSnorm ..'dB' 
          local ret, v = ImGui.SliderInt( ctx, 'Normalize to LUFS##normlufsslider',                          EXT.CONF_onadd_autoLUFSnorm, -23, 0, normformat, ImGui.SliderFlags_None ) 
          if ret then EXT.CONF_onadd_autoLUFSnorm = v end 
          if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
        end
        -- adsr
        if ImGui.Checkbox( ctx, '##CONF_onadd_ADSR_flags_a',                                    EXT.CONF_onadd_ADSR_flags&1 == 1 ) then EXT.CONF_onadd_ADSR_flags =EXT.CONF_onadd_ADSR_flags~1 EXT:save() end ImGui.SameLine(ctx)
        if EXT.CONF_onadd_ADSR_flags&1~=1 then ImGui.BeginDisabled(ctx, true) end
        local ret, v = ImGui.SliderDouble( ctx, 'Attack##CONF_onadd_ADSR_A',            EXT.CONF_onadd_ADSR_A*2, 0, 0.1, '%.3f sec', ImGui.SliderFlags_None ) if ret then EXT.CONF_onadd_ADSR_A = VF_lim(v/2,0,2) end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
        if EXT.CONF_onadd_ADSR_flags &1~=1 then ImGui.EndDisabled(ctx) end
        
        if ImGui.Checkbox( ctx, '##CONF_onadd_ADSR_flags_d',                                    EXT.CONF_onadd_ADSR_flags&2 == 2) then EXT.CONF_onadd_ADSR_flags =EXT.CONF_onadd_ADSR_flags~2 EXT:save() end ImGui.SameLine(ctx)
        if EXT.CONF_onadd_ADSR_flags&2~=2 then ImGui.BeginDisabled(ctx, true) end
        local ret, v = ImGui.SliderDouble( ctx, 'Decay##CONF_onadd_ADSR_D',            EXT.CONF_onadd_ADSR_D, 0, 15, '%.3f sec', ImGui.SliderFlags_None ) if ret then EXT.CONF_onadd_ADSR_D = VF_lim(v,0,15) end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
        if EXT.CONF_onadd_ADSR_flags &2~=2 then ImGui.EndDisabled(ctx) end
        
        if ImGui.Checkbox( ctx, '##CONF_onadd_ADSR_flags_s',                                    EXT.CONF_onadd_ADSR_flags&4 == 4 ) then EXT.CONF_onadd_ADSR_flags =EXT.CONF_onadd_ADSR_flags~4 EXT:save() end ImGui.SameLine(ctx)
        if EXT.CONF_onadd_ADSR_flags&4~=4 then ImGui.BeginDisabled(ctx, true) end
        local format_sus =  20*math.log(EXT.CONF_onadd_ADSR_S*2, 10)..'dB'
        local ret, v = ImGui.SliderDouble( ctx, 'Sustain##CONF_onadd_ADSR_S',            EXT.CONF_onadd_ADSR_S, 0, 0.5, format_sus, ImGui.SliderFlags_None ) if ret then EXT.CONF_onadd_ADSR_S = VF_lim(v/2,0,0.5) end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
        if EXT.CONF_onadd_ADSR_flags &4~=4 then ImGui.EndDisabled(ctx) end
        
        if ImGui.Checkbox( ctx, '##CONF_onadd_ADSR_flags_r',                                    EXT.CONF_onadd_ADSR_flags&8 == 8 ) then EXT.CONF_onadd_ADSR_flags =EXT.CONF_onadd_ADSR_flags~8 EXT:save() end ImGui.SameLine(ctx)
        if EXT.CONF_onadd_ADSR_flags&8~=8 then ImGui.BeginDisabled(ctx, true) end
        local ret, v = ImGui.SliderDouble( ctx, 'Release##CONF_onadd_ADSR_R',            EXT.CONF_onadd_ADSR_R*2, 0, 0.5, '%.3f sec', ImGui.SliderFlags_None ) if ret then EXT.CONF_onadd_ADSR_R = VF_lim(v/2,0,2) end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
        if EXT.CONF_onadd_ADSR_flags &8~=8 then ImGui.EndDisabled(ctx) end
        
        ImGui.Unindent(ctx, UI.settings_indent)
      end
      
      
      if ImGui.CollapsingHeader(ctx, 'Track##On sample add_Track') then   
        ImGui.Indent(ctx, UI.settings_indent)
        if ImGui.Checkbox( ctx, 'Rename track',                                           EXT.CONF_onadd_renametrack == 1 ) then EXT.CONF_onadd_renametrack =EXT.CONF_onadd_renametrack~1 EXT:save() end 
        ImGui_SetNextItemWidth(ctx, UI.settings_itemW) 
        local ret, buf = ImGui.InputText( ctx, 'Custom template file',                    EXT.CONF_onadd_customtemplate, ImGui.InputTextFlags_EnterReturnsTrue) 
        if ret then 
          EXT.CONF_onadd_customtemplate =buf 
          EXT:save() 
        end
        ImGui.SameLine(ctx)
        UI.HelpMarker('Path to file')
        UI.draw_tabs_settings_combo('CONF_onadd_ordering',{[0]='Sort by note',[1]='To the top', [2]='To the bottom'},'##settings_childorder', 'New reg child order')  
        if ImGui.Checkbox( ctx, 'Set child color from parent color',                                     EXT.CONF_onadd_takeparentcolor == 1 ) then EXT.CONF_onadd_takeparentcolor =EXT.CONF_onadd_takeparentcolor~1 EXT:save() end 
        if ImGui.Checkbox( ctx, 'Enable sysex mode for new childs',                                     EXT.CONF_onadd_sysexmode == 1 ) then EXT.CONF_onadd_sysexmode =EXT.CONF_onadd_sysexmode~1 EXT:save() end 
        ImGui.SameLine(ctx) UI.HelpMarker('This setting require StepSequencer restart')
        ImGui.Unindent(ctx, UI.settings_indent)
        
        
      end
      
      
      if ImGui.CollapsingHeader(ctx, 'Various##On sample add_Various') then     
        ImGui.Indent(ctx, UI.settings_indent)
        if ImGui.Checkbox( ctx, 'Copy samples to project path',                           EXT.CONF_onadd_copytoprojectpath == 1 ) then EXT.CONF_onadd_copytoprojectpath =EXT.CONF_onadd_copytoprojectpath~1 EXT:save() end 
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx,'Open path') then 
          local prpath = reaper.GetProjectPathEx( 0 )
          prpath = prpath..'/'..EXT.CONF_onadd_copysubfoldname..'/'
          RecursiveCreateDirectory( prpath, 0 )
          VF_Open_URL(prpath) 
        end
        if ImGui.Checkbox( ctx, 'Drop to white keys only',                                EXT.CONF_onadd_whitekeyspriority == 1 ) then EXT.CONF_onadd_whitekeyspriority =EXT.CONF_onadd_whitekeyspriority~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Auto-set velocity range option enabled for new devices',                                     EXT.CONF_onadd_autosetrange == 1 ) then EXT.CONF_onadd_autosetrange =EXT.CONF_onadd_autosetrange~1 EXT:save() end 
        ImGui.Unindent(ctx, UI.settings_indent)
      end
        
        
        
        ImGui.Unindent(ctx,UI.settings_indent)
    end  
  end
--------------------------------------------------------------------------------  
  function UI.draw_tabs_settings_tcpmcp()
    if ImGui.CollapsingHeader(ctx, 'TCP / MCP auto collapsing') then 
      ImGui.Indent(ctx,UI.settings_indent)
    
        if ImGui.Checkbox( ctx, 'Collapse parent folder',                                 EXT.CONF_onadd_newchild_trackheightflags&1==1 ) then 
          EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~1  if EXT.CONF_onadd_newchild_trackheightflags&2==2 then EXT.CONF_onadd_newchild_trackheightflags = EXT.CONF_onadd_newchild_trackheightflags~2 end
          EXT:save() 
          DATA:Auto_TCPMCP(true)
          DATA.upd = true 
        end
        if ImGui.Checkbox( ctx, 'Supercollapse parent folder',                            EXT.CONF_onadd_newchild_trackheightflags&2==2 ) then 
          EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~2  if EXT.CONF_onadd_newchild_trackheightflags&1==1 then EXT.CONF_onadd_newchild_trackheightflags = EXT.CONF_onadd_newchild_trackheightflags~1 end
          EXT:save() 
          DATA:Auto_TCPMCP(true)
          DATA.upd = true 
        end
        if ImGui.Checkbox( ctx, 'Hide children TCP',                                      EXT.CONF_onadd_newchild_trackheightflags&4==4 ) then EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~4 EXT:save() DATA:Auto_TCPMCP(true) DATA.upd = true end
        if ImGui.Checkbox( ctx, 'Hide children MCP',                                      EXT.CONF_onadd_newchild_trackheightflags&8==8 ) then EXT.CONF_onadd_newchild_trackheightflags =EXT.CONF_onadd_newchild_trackheightflags~8 EXT:save() DATA:Auto_TCPMCP(true) DATA.upd = true end
        
        ImGui_SetNextItemWidth(ctx, UI.settings_itemW)  
        local formatin = '%dpx' if EXT.CONF_onadd_newchild_trackheight == 0 then formatin = 'default' end
        local ret, v = ImGui.SliderInt( ctx, 'New child track height',                    EXT.CONF_onadd_newchild_trackheight, 0, 300, formatin, ImGui.SliderFlags_None ) if ret then EXT.CONF_onadd_newchild_trackheight = v end
        if ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
      
      ImGui.Unindent(ctx,UI.settings_indent)
    end  
  end
  
  
--------------------------------------------------------------------------------  
  function UI.draw_tabs_settings_MIDI()
    if ImGui.CollapsingHeader(ctx, 'MIDI bus') then 
      ImGui.Indent(ctx,UI.settings_indent)
      
      --ImGui.SeparatorText(ctx, 'MIDI bus')  
        --ImGui.Indent(ctx, UI.settings_indent)
        UI.draw_tabs_settings_combo('CONF_midiinput',DATA.MIDI_inputs,'##settings_drracklayout_midiin', 'MIDI bus default input') 
        UI.draw_tabs_settings_combo('CONF_midioutput',DATA.MIDI_outputs,'##settings_drracklayout_midiout', 'MIDI bus default output') 
        ImGui.SetNextItemWidth(ctx, UI.settings_itemW) 
        local chanformat = 'Channel '..EXT.CONF_midichannel if EXT.CONF_midichannel == 0 then chanformat = 'All channels' end
        local ret, v = ImGui.SliderInt( ctx, 'MIDI bus channel',                          EXT.CONF_midichannel, 0, 16, chanformat, ImGui.SliderFlags_None ) if ret then EXT.CONF_midichannel = v EXT:save() end
        if ImGui.Button(ctx, 'Initialize MIDI bus') then DATA:Validate_MIDIbus_AND_ParentFolder() end
        if ImGui.Checkbox( ctx, 'Auto rename MIDI bus MIDI notes',                                EXT.CONF_autorenamemidinotenames&1==1 ) then EXT.CONF_autorenamemidinotenames =EXT.CONF_autorenamemidinotenames~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Auto rename devices and children MIDI notes',                    EXT.CONF_autorenamemidinotenames&2==2 ) then EXT.CONF_autorenamemidinotenames =EXT.CONF_autorenamemidinotenames~2 EXT:save() end
        --ImGui.Unindent(ctx, UI.settings_indent)
        
        ImGui.Unindent(ctx,UI.settings_indent)
    end  
  end
--------------------------------------------------------------------------------  
  function UI.draw_tabs_settings_UI()
    if ImGui.CollapsingHeader(ctx, 'UI interaction') then 
      ImGui.Indent(ctx,UI.settings_indent)
        
        if ImGui.Checkbox( ctx, 'Click on pad select track',                              EXT.UI_clickonpadselecttrack == 1 ) then EXT.UI_clickonpadselecttrack =EXT.UI_clickonpadselecttrack~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Click on pad scroll mixer',                              EXT.UI_clickonpadscrolltomixer == 1 ) then EXT.UI_clickonpadscrolltomixer =EXT.UI_clickonpadscrolltomixer~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Click on pad play sample',                              EXT.UI_clickonpadplaysample == 1 ) then EXT.UI_clickonpadplaysample =EXT.UI_clickonpadplaysample~1 EXT:save() end
        ImGui_SetNextItemWidth(ctx, UI.settings_itemW) 
        local ret, v = ImGui.SliderInt( ctx, 'Default playing velocity',                  EXT.CONF_default_velocity, 1, 127, '%d', ImGui.SliderFlags_None ) if ret then EXT.CONF_default_velocity = v EXT:save() end
        if ImGui.Checkbox( ctx, 'Releasing mouse on pad send NoteOff',                             EXT.UI_pads_sendnoteoff == 1 ) then EXT.UI_pads_sendnoteoff =EXT.UI_pads_sendnoteoff~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Active note follow incoming note',                       EXT.UI_incomingnoteselectpad == 1 ) then EXT.UI_incomingnoteselectpad =EXT.UI_incomingnoteselectpad~1 EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('May be CPU hungry')
        if ImGui.Checkbox( ctx, 'Show meters on pads',            EXT.CONF_showplayingmeters == 1 ) then EXT.CONF_showplayingmeters =EXT.CONF_showplayingmeters~1 EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('May be CPU hungry')
        if ImGui.Checkbox( ctx, 'Show peaks on pads',            EXT.CONF_showpadpeaks == 1 ) then EXT.CONF_showpadpeaks =EXT.CONF_showpadpeaks~1 EXT:save() end
        ImGui.SameLine(ctx)
        UI.HelpMarker('May be CPU hungry')
        
        -- custom note names
        local curname = string.format('%02d', DATA.padcustomnames_selected_id)
        if DATA.padcustomnames[i] then name = DATA.padcustomnames[i] end
        --ImGui.Text(ctx, 'Custom pad names')
        if ImGui.CollapsingHeader(ctx, 'Custom pad names') then 
          
          ImGui.Indent(ctx, UI.settings_indent)
          reaper.ImGui_SetNextItemWidth( ctx, 50 )
          if ImGui.BeginCombo( ctx, '##custompadnames',curname, ImGui.ComboFlags_None ) then--|ImGui.ComboFlags_NoArrowButton
            for i = 0,127 do
              local name = string.format('%02d', i)
              if DATA.padcustomnames[i] then name = name..' - '..DATA.padcustomnames[i] end
              if ImGui.Selectable( ctx, name..'##custpadname'..i, i == DATA.padcustomnames_selected_id, ImGui.SelectableFlags_None) then DATA.padcustomnames_selected_id = i end
            end
            ImGui.EndCombo( ctx)
          end
          ImGui.SameLine(ctx)
          local retval, buf = ImGui_InputText( ctx, '##custpadnameinput'..DATA.padcustomnames_selected_id, DATA.padcustomnames[DATA.padcustomnames_selected_id], ImGui_InputTextFlags_None() )
          if retval then 
            buf = buf:gsub('[^%a%d%s%-]+','')
            DATA.padcustomnames[DATA.padcustomnames_selected_id] = buf
          end
          if ImGui_IsItemDeactivatedAfterEdit( ctx ) then
            local outstr = ''
            for i = 0, 127 do outstr=outstr..i..'='..'"'..(DATA.padcustomnames[i] or '')..'" ' end
            EXT.UI_padcustomnamesB64 = VF_encBase64(outstr)
            EXT:save() 
          end
          
          if ImGui.Button(ctx, 'General MIDI bank') then --
            EXT.UI_padcustomnamesB64 = VF_encBase64([[
          27="High Q or Filter Snap"
          28="Slap Noise"
          29="Scratch Push"
          30="Scratch Pull"
          31="Drum sticks"
          32="Square Click"
          33="Metronome Click"
          34="Metronome Bell"
          82="Shaker"
          83="Jingle Bell"
          84="Belltree"
          85="Castanets"
          86="Mute Surdo"
          87="Open Surdo"
          
          35="Acoustic Bass Drum or Low Bass Drum"
          36="Electric Bass Drum or High Bass Drum"
          37="Side Stick"
          38="Acoustic Snare"
          39="Hand Clap"
          40="Electric Snare or Rimshot"
          41="Low Floor Tom"
          42="Closed Hi-hat"
          43="High Floor Tom"
          44="Pedal Hi-hat"
          45="Low Tom"
          46="Open Hi-hat"
          47="Low-Mid Tom"
          48="High-Mid Tom"
          49="Crash Cymbal 1"
          50="High Tom"
          51="Ride Cymbal 1"
          52="Chinese Cymbal"
          53="Ride Bell"
          54="Tambourine"
          55="Splash Cymbal"
          56="Cowbell"
          57="Crash Cymbal 2"
          58="Vibraslap"
          59="Ride Cymbal 2"
          60="High Bongo"
          61="Low Bongo"
          62="Mute High Conga"
          63="Open High Conga"
          64="Low Conga"
          65="High Timbale"
          66="Low Timbale"
          67="High Agogô"
          68="Low Agogô"
          69="Cabasa"
          70="Maracas"
          71="Short Whistle"
          72="Long Whistle"
          73="Short Güiro"
          74="Long Güiro"
          75="Claves"
          76="High Woodblock"
          77="Low Woodblock"
          78="Mute Cuíca"
          79="Open Cuíca"
          80="Mute Triangle"
          81="Open Triangle"
  ]]          )
            EXT:save()
            DATA:CollectDataInit_LoadCustomPadStuff()
          end        
          if ImGui.Button(ctx, 'Clear custom pad names') then 
            EXT.UI_padcustomnamesB64 = ''
            EXT:save()
            DATA:CollectDataInit_LoadCustomPadStuff()
          end
          
          ImGui.Unindent(ctx, UI.settings_indent)
        end
        
        
        if ImGui.Checkbox( ctx, 'Allow space to play',                              EXT.UI_allowshortcuts == 1 ) then EXT.UI_allowshortcuts =EXT.UI_allowshortcuts~1 EXT:save() end
        ImGui.Unindent(ctx,UI.settings_indent)
    end  
  end
    --------------------------------------------------------------------------------
  function UI.draw_tabs_settings_Theming()    
    if ImGui.CollapsingHeader(ctx, 'Theming') then 
      ImGui.Indent(ctx,UI.settings_indent)
      -- main backgr alpha
      ImGui_SetNextItemWidth(ctx, UI.settings_itemW)
      local retval, v = ImGui.SliderDouble( ctx, 'Background transparency', EXT.UI_transparency, 0, 1, math.floor(EXT.UI_transparency*100)..'%%', ImGui.SliderFlags_None )
      if retval then EXT.UI_transparency = v end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      --trackcol tint
      ImGui_SetNextItemWidth(ctx, UI.settings_itemW)
      local retval, v = ImGui.SliderInt( ctx, 'Tint track color to pads', EXT.UI_col_tinttrackcoloralpha, 0, 255, math.floor(100*EXT.UI_col_tinttrackcoloralpha/255)..'%%', ImGui.SliderFlags_None )
      if retval then EXT.UI_col_tinttrackcoloralpha = v end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      
      --Active pad default
      local retval, col_rgba = ImGui.ColorEdit4( ctx, 'Active pad default', EXT.UI_colRGBA_paddefaultbackgr, ImGui.ColorEditFlags_AlphaBar|ImGui.ColorEditFlags_NoInputs )  
      if retval then EXT.UI_colRGBA_paddefaultbackgr = col_rgba end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      ImGui.SameLine(ctx)if ImGui.Button(ctx, 'Reset##res_Active pad default') then EXT.UI_colRGBA_paddefaultbackgr = UI.def_colRGBA_paddefaultbackgr EXT:save() end
      --Inactive pad default
      local retval, col_rgba = ImGui.ColorEdit4( ctx, 'Inactive pad default', EXT.UI_colRGBA_paddefaultbackgr_inactive, ImGui.ColorEditFlags_AlphaBar|ImGui.ColorEditFlags_NoInputs )  
      if retval then EXT.UI_colRGBA_paddefaultbackgr_inactive = col_rgba end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      ImGui.SameLine(ctx)if ImGui.Button(ctx, 'Reset##res_Inactive pad default') then EXT.UI_colRGBA_paddefaultbackgr_inactive = UI.def_colRGBA_paddefaultbackgr_inactive EXT:save() end
      --ctrls
      local retval, col_rgba = ImGui.ColorEdit4( ctx, 'Pad buttons backgr', EXT.UI_colRGBA_padctrl, ImGui.ColorEditFlags_AlphaBar |ImGui.ColorEditFlags_NoInputs)  
      if retval then EXT.UI_colRGBA_padctrl = col_rgba end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      ImGui.SameLine(ctx)if ImGui.Button(ctx, 'Reset##res_Pad buttons backgr') then EXT.UI_colRGBA_padctrl = UI.def_colRGBA_padctrl EXT:save() end
      --ctrls
      local retval, col_rgba = ImGui.ColorEdit4( ctx, 'Sampler peaks backgr', EXT.UI_colRGBA_smplrbackgr, ImGui.ColorEditFlags_AlphaBar|ImGui.ColorEditFlags_NoInputs )  
      if retval then EXT.UI_colRGBA_smplrbackgr = col_rgba end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      ImGui.SameLine(ctx)if ImGui.Button(ctx, 'Reset##res_Sampler peaks backgr') then EXT.UI_colRGBA_smplrbackgr = UI.colRGBA_smplrbackgr EXT:save() end      
      
      
      
        
      ImGui.Unindent(ctx,UI.settings_indent)
    end    
  end
    --------------------------------------------------------------------------------
  function UI.draw_tabs_settings_AutoColor()
    if ImGui.CollapsingHeader(ctx, 'Auto color child tracks') then 
      ImGui.Indent(ctx,UI.settings_indent)
      local t = {
        [0]='Off',
        [1]='By note',
        --[2]='By name',
        }
      
      local curname = t[EXT.CONF_autocol]
      if ImGui.BeginCombo( ctx, '##CONF_autocol_selector',curname, ImGui.ComboFlags_None ) then--|ImGui.ComboFlags_NoArrowButton
        for i in pairs(t) do
          local name = t[i]
          if ImGui.Selectable( ctx, name..'##CONF_autocol_selector'..i, i == EXT.CONF_autocol, ImGui.SelectableFlags_None) then EXT.CONF_autocol = i EXT:save() end
        end
        ImGui.EndCombo( ctx)
      end
      
      -- by note
      if EXT.CONF_autocol == 1 then
        
        -- reset all
        ImGui.SameLine(ctx)
        if ImGui.Selectable( ctx, 'Reset ALL##CONF_autocol_selectorresetall', ImGui.SelectableFlags_None) then  
          DATA.padautocolors = {}
          EXT.UI_padautocolorsB64 = '' 
          EXT:save() 
          DATA.upd = true
        end
        
        
        -- custom pad auto colors selector
        local curname = DATA.padautocolors_selected_id
        if  DATA.children and DATA.children[DATA.padautocolors_selected_id] and DATA.children[DATA.padautocolors_selected_id].P_NAME then curname = DATA.padautocolors_selected_id..' '..DATA.children[DATA.padautocolors_selected_id].P_NAME end
        ImGui.Text(ctx, 'Custom pad colors')
        ImGui.Indent(ctx, UI.settings_indent)
        
        reaper.ImGui_SetNextItemWidth( ctx, 200 )
        if ImGui.BeginCombo( ctx, '##padautocolors',curname, ImGui.ComboFlags_None ) then--|ImGui.ComboFlags_NoArrowButton
          for i = 0,127 do
            local name = i
            if  DATA.children and DATA.children[i] and DATA.children[i].P_NAME then name = i..' '..DATA.children[i].P_NAME end
            --if DATA.padautocolors[i] then name = name..' - '..DATA.padautocolors[i] end
            if ImGui.Selectable( ctx, name..'##coloreditpad_autoname'..i, i == DATA.padautocolors_selected_id, ImGui.SelectableFlags_None) then DATA.padautocolors_selected_id = i end
          end
          ImGui.EndCombo( ctx)
        end
        
        
        ImGui.Unindent(ctx, UI.settings_indent)
        ImGui.SameLine(ctx)
        
        -- color input
        local colext = DATA.padautocolors[DATA.padautocolors_selected_id]
        if colext then colext = tonumber(colext) end
        local col_rgba  = colext or 0
        if col_rgba then 
          local retval, col_rgba = ImGui.ColorEdit4( ctx, '##coloreditpad_auto', col_rgba, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs)--|ImGui.ColorEditFlags_NoAlpha )
          if retval then 
            DATA.padautocolors[DATA.padautocolors_selected_id]  = col_rgba
            DATA.upd = true
          end
          if ImGui_IsItemDeactivatedAfterEdit( ctx ) then
            local outstr = ''
            for i = 0, 127 do outstr=outstr..i..'='..'"'..(DATA.padautocolors[i] or '')..'" ' end
            EXT.UI_padautocolorsB64 = VF_encBase64(outstr )
            EXT:save() 
          end
        end
        ImGui.SameLine(ctx)
        
        -- reset color
        if ImGui.Selectable( ctx, 'Reset##CONF_autocol_selectorreset', ImGui.SelectableFlags_None) then 
          DATA.padautocolors[DATA.padautocolors_selected_id]  = 0
          local outstr = ''
          for i = 0, 127 do outstr=outstr..i..'='..'"'..(DATA.padautocolors[i] or '')..'" ' end
          EXT.UI_padautocolorsB64 = VF_encBase64(outstr )
          EXT:save() 
          DATA.upd = true
        end
        
      end
      ImGui.Unindent(ctx,UI.settings_indent)
    end  
  end
    --------------------------------------------------------------------------------
  function UI.draw_tabs_settings_Autoslice()
    if ImGui.CollapsingHeader(ctx, 'Auto slice loop on pad drop') then 
      ImGui.Indent(ctx,UI.settings_indent)
      
      if ImGui.Checkbox( ctx, 'Use Autoslice',                             EXT.CONF_loopcheck == 1 ) then EXT.CONF_loopcheck =EXT.CONF_loopcheck~1 EXT:save() end
      local retval, v, buf
      if EXT.CONF_loopcheck&1==0 then goto skipset end
      
      -- min
       retval, v = ImGui.SliderDouble( ctx, 'Minimum loop length##CONF_loopcheck_minlen', EXT.CONF_loopcheck_minlen, 0.5, EXT.CONF_loopcheck_maxlen, '%.4fsec', ImGui.SliderFlags_None )
      if retval then EXT.CONF_loopcheck_minlen = v end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then EXT.CONF_loopcheck_minlen = 2 EXT:save() end
      -- min
       retval, v = ImGui.SliderDouble( ctx, 'Maximum loop length##CONF_loopcheck_maxlen', EXT.CONF_loopcheck_maxlen, EXT.CONF_loopcheck_minlen, 16, '%.4fsec', ImGui.SliderFlags_None )
      if retval then EXT.CONF_loopcheck_maxlen = v end if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save()  end
      if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then EXT.CONF_loopcheck_maxlen = 8 EXT:save() end      
      
      -- filt 
      retval, buf = reaper.ImGui_InputText( ctx, 'Filter', EXT.CONF_loopcheck_filter, reaper.ImGui_InputTextFlags_None() )ImGui.SameLine(ctx) UI.HelpMarker('Do not auto slice samples containing words in name')
      if retval then EXT.CONF_loopcheck_filter = buf end
      if ImGui.IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
      
      
      
      
      ::skipset::
      ImGui.Unindent(ctx,UI.settings_indent)
    end  
  end
  --------------------------------------------------------------------------------    
  function UI.draw_tabs_settings_StepSequencer()
    if ImGui.CollapsingHeader(ctx, 'Step Sequencer') then  
      ImGui.Indent(ctx,UI.settings_indent)
      
      if ImGui.Checkbox( ctx, 'Share data to same pattern GUIDs',                             EXT.CONF_seq_force_GUIDbasedsharing == 1 ) then EXT.CONF_seq_force_GUIDbasedsharing =EXT.CONF_seq_force_GUIDbasedsharing~1 EXT:save() end
      ImGui.SameLine(ctx) UI.HelpMarker('This setting require StepSequencer restart')
      
      if ImGui.Checkbox( ctx, 'Use ascending order of intruments',                             EXT.CONF_seq_instrumentsorder == 1 ) then EXT.CONF_seq_instrumentsorder =EXT.CONF_seq_instrumentsorder~1 EXT:save() end
      ImGui.SameLine(ctx) UI.HelpMarker('This setting require StepSequencer restart')
      
      if ImGui.Checkbox( ctx, 'Clamp envelopes at active steps only',                             EXT.CONF_seq_env_clamp == 1 ) then EXT.CONF_seq_env_clamp =EXT.CONF_seq_env_clamp~1 EXT:save() end
      ImGui.SameLine(ctx) UI.HelpMarker('This setting require StepSequencer restart')
      
      local map  ={
        [-1] = 'Follow pattern length',
        [16] = '16 steps'
      }
      --ImGui.SetNextItemWidth(ctx, -1)
      if ImGui.BeginCombo( ctx, 'Default steps count##defcntsteps', map[EXT.CONF_seq_defaultstepcnt], ImGui.ComboFlags_None ) then
        for val in pairs(map) do
          if ImGui.Selectable( ctx, map[val], false, ImGui.SelectableFlags_None) then 
            EXT.CONF_seq_defaultstepcnt = val
            EXT:save()
          end
        end
        ImGui.EndCombo( ctx )
      end
      
      
     -- 
      
      ImGui.Unindent(ctx,UI.settings_indent)
    end  
  
  end
  --------------------------------------------------------------------------------    
  function UI.draw_tabs_settings_RackLayout()
    if ImGui.CollapsingHeader(ctx, 'Rack Layout') then 
      ImGui.Indent(ctx,UI.settings_indent)
      
      DATA.temp_ignore_incomingevent = true
      UI.draw_tabs_settings_combo('UI_drracklayout',{[0]='[factory] Default / 8x4 pads',[1]='[factory] 2 octaves keys',[2]='Custom'},'##settings_drracklayout', 'DrumRack layout', 200) 
      
        if EXT.UI_drracklayout == 2 then 
        
          local ID = EXT.UI_drracklayout_customID
          if not DATA.custom_layouts[ID]  then DATA:Layout_Init(ID) end
          
          ImGui.SeparatorText(ctx, 'Note placement')
          
          -- cell cnt
          local retval, v = ImGui.SliderDouble( ctx, 'Cell count limit##cell_cnt_max', DATA.custom_layouts[ID].cell_cnt_max, 1, 64, DATA.custom_layouts[ID].cell_cnt_max, ImGui.SliderFlags_None )
          if retval then DATA.custom_layouts[ID].cell_cnt_max = math_q(v) end if ImGui.IsItemDeactivatedAfterEdit(ctx) then DATA:Layout_SaveCustomLayouts()   end
          if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then DATA.custom_layouts[ID].cell_cnt_max = nil DATA:Layout_Init(ID,true) DATA:Layout_SaveCustomLayouts()  end

          -- row_cnt
          local retval, v = ImGui.SliderDouble( ctx, 'Rows##row_cnt', DATA.custom_layouts[ID].row_cnt, 1, 8, DATA.custom_layouts[ID].row_cnt, ImGui.SliderFlags_None )
          if retval then DATA.custom_layouts[ID].row_cnt = math_q(v) end if ImGui.IsItemDeactivatedAfterEdit(ctx) then DATA:Layout_SaveCustomLayouts()   end
          if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then DATA.custom_layouts[ID].row_cnt = nil DATA:Layout_Init(ID,true) DATA:Layout_SaveCustomLayouts()  end

          -- col_cnt
          local retval, v = ImGui.SliderDouble( ctx, 'Columns##col_cnt', DATA.custom_layouts[ID].col_cnt, 1, 8, DATA.custom_layouts[ID].col_cnt, ImGui.SliderFlags_None )
          if retval then DATA.custom_layouts[ID].col_cnt = math_q(v) end if ImGui.IsItemDeactivatedAfterEdit(ctx) then DATA:Layout_SaveCustomLayouts()   end
          if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then DATA.custom_layouts[ID].col_cnt = nil DATA:Layout_Init(ID,true) DATA:Layout_SaveCustomLayouts()  end
           
          
          if ImGui.Checkbox( ctx, 'Top to bottom',                             DATA.custom_layouts[ID].toptobottom == 1 ) then DATA.custom_layouts[ID].toptobottom =DATA.custom_layouts[ID].toptobottom~1  DATA:Layout_SaveCustomLayouts() end
          
          --ImGui.SeparatorText(ctx, 'Notes mapping')
          
          -- startnote
          local retval, v = ImGui.SliderDouble( ctx, 'Start note##cell_cnt_max', DATA.custom_layouts[ID].startnote, 0, 127, DATA.custom_layouts[ID].startnote, ImGui.SliderFlags_None )
          if retval then DATA.custom_layouts[ID].startnote = math_q(v) end if ImGui.IsItemDeactivatedAfterEdit(ctx) then DATA:Layout_SaveCustomLayouts()   end
          if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then DATA.custom_layouts[ID].startnote = nil DATA:Layout_Init(ID,true) DATA:Layout_SaveCustomLayouts()  end
          -- block by X
          local retval, v = ImGui.SliderDouble( ctx, 'BlockX##blockX', DATA.custom_layouts[ID].blockX, 1, 8, DATA.custom_layouts[ID].blockX, ImGui.SliderFlags_None )
          if retval then DATA.custom_layouts[ID].blockX = math_q(v) end if ImGui.IsItemDeactivatedAfterEdit(ctx) then DATA:Layout_SaveCustomLayouts()   end
          if ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then DATA.custom_layouts[ID].blockX = nil DATA:Layout_Init(ID,true) DATA:Layout_SaveCustomLayouts()  end          
          
          ImGui.SeparatorText(ctx, 'Mapping overrides')
          -- remove
          if ImGui.Button(ctx, 'Remove overrides' ) then  
            DATA.custom_layouts[ID].mapping_override  = {} 
            DATA:Layout_SaveCustomLayouts()
          end
          -- remove
          if DATA.lastMIDIinputnote and tonumber(DATA.lastMIDIinputnote) and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then 
            if ImGui.Button(ctx, 'Map note '..DATA.lastMIDIinputnote..' to pad '..DATA.parent_track.ext.PARENT_LASTACTIVENOTE ) then  
              if not DATA.custom_layouts[ID].mapping_override then DATA.custom_layouts[ID].mapping_override  = {}  end
              local note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE
              DATA.custom_layouts[ID].mapping_override[note] = DATA.lastMIDIinputnote
              DATA.custom_layouts[ID].mapping_override[DATA.lastMIDIinputnote] = -1
              DATA:Layout_SaveCustomLayouts()
            end
           else
            
            UI.HelpMarker('Press note on keyboard to get mapping source')
          end
          
          
          
          
          
        end
      -- 
      
      ImGui.Unindent(ctx, UI.settings_indent)
      
    end  
  
  end
  ---------------------------------------------------------------------------------------------------------------------------------    
  function UI.Launchpad_drumrackhelp()
            ImGui.Indent(ctx,10)
            ImGui.BeginDisabled(ctx,true) ImGui.TextWrapped(ctx, [[
Launchpad setuplooks like this:
    1. make sure Launchpad is presented in REAPER Preference / Audio / MIDI outputs 
    2. enable it
    3. restart script
    
Then,
    if you using Drum Rack only
    4a. open RS5k manager/Settings/MIDI Bus and select your MIDIOUT LaunchPad output
    4b. Turn OFF sending MIDI feedback from step sequencer
    
    if you using Step Sequencer as well
    4a. open RS5k manager/Settings/MIDI Bus and select your MIDIOUT LaunchPad output
    4b. Turn ON sending MIDI feedback from step sequencer
    
This setting will be used for newly created MIDI buses. So if you already have rack ready to play, you can apply pre-defined LaunchPad output manually in MIDI bus track routing or here:]])ImGui.EndDisabled(ctx)
      
      
      
      local buttxt = 'Set MIDI Hardware output for MIDI bus'
      if EXT.CONF_midioutput == -1 then 
        ImGui.BeginDisabled(ctx,true) 
        buttxt = '[no MIDI Hardware output for MIDI bus set]'
      end
      if ImGui.Button(ctx, buttxt) then 
        if DATA.MIDIbus.valid == true and DATA.MIDIbus.tr_ptr then SetMediaTrackInfo_Value( DATA.MIDIbus.tr_ptr, 'I_MIDIHWOUT', EXT.CONF_midioutput<<5) end
      end
      if EXT.CONF_midioutput == -1 then ImGui.EndDisabled(ctx) end
      
      
      
      ImGui.BeginDisabled(ctx,true) ImGui.TextWrapped(ctx, [[
      
You can then light up pads using just "normal" MIDI output.
MIDI bus will send same MIDI it sends to tracks, which will light up related pads.


BUT if you use step sequencer you have to turn this MIDI Hardware output OFF. Other
    ]]) ImGui.EndDisabled(ctx)
    
    
    ImGui.Unindent(ctx,10)
  end
  
  ---------------------------------------------------------------------------------------------------------------------------------    
  function UI.draw_tabs_settings_Launchpad()
    if ImGui.CollapsingHeader(ctx, 'Launchpad') then 
      ImGui.Indent(ctx,UI.settings_indent)
      --[[--local retval, p_visible = reaper.ImGui_CollapsingHeader( ctx, 'Drum Rack setup' )
      --if retval then UI.Launchpad_drumrackhelp() end
      UI.Launchpad_drumrackhelp()]]
      ImGui.Unindent(ctx,UI.settings_indent)
    end   
  end      
  --------------------------------------------------------------------------------    
    function UI.draw_tabs_settings()
    
    UI.tab_current = 'Settings'
    if not UI.tab_last or (UI.tab_last and UI.tab_last ~= UI.tab_current ) then EXT.UI_activeTab = UI.tab_current EXT:save() end
    
    UI.tab_last = UI.tab_current 
    if ImGui.BeginChild( ctx, '##settingscontent',-1, 0, ImGui.ChildFlags_None, ImGui.WindowFlags_None ) then --|ImGui.ChildFlags_Border- --|ImGui.WindowFlags_NoScrollWithMouse
      
      
      UI.draw_tabs_settings_database()
      UI.draw_tabs_settings_onsampleadd()
      UI.draw_tabs_settings_tcpmcp()
      UI.draw_tabs_settings_MIDI()
      UI.draw_tabs_settings_UI()
      UI.draw_tabs_settings_RackLayout()
      UI.draw_tabs_settings_Theming()
      UI.draw_tabs_settings_AutoColor()
      UI.draw_tabs_settings_Autoslice()
      UI.draw_tabs_settings_StepSequencer() 
      --UI.draw_tabs_settings_Launchpad() 
      
      
      ImGui.EndChild( ctx)
    end
    
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_Rack()  
    
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end
    UI.draw_Rack_PadOverview() 
    --
    ImGui.SameLine(ctx) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0,0) 
    
    ImGui.SetCursorScreenPos(ctx,UI.calc_rackX,UI.calc_rackY)
    if ImGui.BeginChild( ctx, 'rack', UI.calc_rackW, 0, ImGui.ChildFlags_None, ImGui.WindowFlags_None |ImGui.WindowFlags_NoScrollbar ) then--|ImGui.ChildFlags_Border --|ImGui.WindowFlags_MenuBar
      UI.draw_Rack_Pads()  
      ImGui.EndChild( ctx)
    end
    ImGui.PopStyleVar(ctx,2)
  end 
  --------------------------------------------------------------------------------  
  function UI.Layout_Pads() 
    if EXT.UI_drracklayout ~= 0 then return end
    local cell_cnt_max = 16
    local yoffs = UI.calc_rackY  + UI.calc_rack_padh*3 + UI.spacingY*3--+ UI.calc_rackH
    local xoffs= UI.calc_rackX
    local padID0 = 0
    for note = 0+DATA.parent_track.ext.PARENT_DRRACKSHIFT, cell_cnt_max-1+DATA.parent_track.ext.PARENT_DRRACKSHIFT do
      UI.draw_Rack_Pads_controls(DATA.children[note], note, xoffs, yoffs, UI.calc_rack_padw, UI.calc_rack_padh) 
      xoffs = xoffs + UI.calc_rack_padw + UI.spacingX
      if padID0%4==3 then 
        xoffs = UI.calc_rackX 
        yoffs = yoffs - UI.calc_rack_padh - UI.spacingY
      end
      padID0 = padID0 + 1
    end
  end
  --------------------------------------------------------------------------------  
  function UI.Layout_Custom()  
    
    if EXT.UI_drracklayout ~= 2 then return end
    local ID = EXT.UI_drracklayout_customID
    if not DATA.custom_layouts[ID] then return end
    
    local cell_cnt_max = DATA.custom_layouts[ID].cell_cnt_max
    local col_cnt = DATA.custom_layouts[ID].col_cnt
    local row_cnt = DATA.custom_layouts[ID].row_cnt 
    local startnote = DATA.custom_layouts[ID].startnote 
    local toptobottom = DATA.custom_layouts[ID].toptobottom 
    local blockX = DATA.custom_layouts[ID].blockX 
    
    local rackx = UI.calc_rackX
    local racky = UI.calc_rackY
    local rackw = UI.calc_rackW
    local rackh = UI.calc_rackH
    local padw = UI.calc_rack_padw
    local padh = UI.calc_rack_padh
    
    local real_cell_cnt_max = math.min(cell_cnt_max, col_cnt * row_cnt) 
    local row_cnt_real = row_cnt
    if col_cnt * row_cnt>cell_cnt_max then row_cnt_real = math.ceil(cell_cnt_max / col_cnt) end
    
    local mapping = {}
    for pad = 1, cell_cnt_max do 
      mapping[pad] = pad + startnote-1 
      local note = mapping[pad]
      if DATA.custom_layouts[ID].mapping_override and DATA.custom_layouts[ID].mapping_override[note] then mapping[pad] = DATA.custom_layouts[ID].mapping_override[note] end
    end
    
    local padx_init = rackx
    local pady_init = racky
    local xpos0basedID = 0
    local xpos0basedID_blockoffset = 0
    local ypos0basedID = 0
    if toptobottom == 0 then pady_init = racky + rackh - padh - UI.spacingY end
    for pad = 1, cell_cnt_max do  
      if ypos0basedID == row_cnt_real then
        xpos0basedID_blockoffset = xpos0basedID_blockoffset + blockX
        ypos0basedID = 0
      end
      local padx = padx_init + padw * (xpos0basedID   + xpos0basedID_blockoffset)
      local pady = pady_init + padh * ypos0basedID
      if toptobottom == 0 then pady = pady_init- padh * ypos0basedID end 
      local mapped_note = mapping[pad] 
      if (xpos0basedID  + xpos0basedID_blockoffset) < col_cnt then
        if mapped_note <128 then
          UI.draw_Rack_Pads_controls(DATA.children[mapped_note], mapped_note, padx, pady, padw, padh) 
        end
      end
      xpos0basedID = xpos0basedID + 1
      if xpos0basedID%blockX == 0 then 
        xpos0basedID = 0
        ypos0basedID = ypos0basedID + 1 
      end
      
    end
    
    
    
    --[[local padID0 = 0
    local xpos0basedID_shift = 0
    local ypos0basedID_shift = 0
    for pad = 1, cell_cnt_max do  
    
      local xpos0basedID = padID0%col_cnt
      local padx = rackx + padw * xpos0basedID  
      local ypos0basedID = math.floor(padID0 / col_cnt) + ypos0basedID_shift
      local pady = racky + padh * ypos0basedID
      
      if toptobottom == 0 then
        pady = racky + rackh - padh * (1+ypos0basedID ) - UI.spacingY
      end
      
      
       
      padID0 = padID0 + 1
    end
    ]]
    

    --[[local padID0 = 0
    local xpos0basedID_shift = 0
    local ypos0basedID_shift = 0
    for pad = 1, cell_cnt_max do  
    
      local xpos0basedID = padID0%col_cnt
      local padx = rackx + padw * xpos0basedID  
      local ypos0basedID = math.floor(padID0 / col_cnt) + ypos0basedID_shift
      local pady = racky + padh * ypos0basedID
      
      if toptobottom == 0 then
        pady = racky + rackh - padh * (1+ypos0basedID ) - UI.spacingY
      end
      
      local mapped_note = mapping[pad] 
      UI.draw_Rack_Pads_controls(DATA.children[mapped_note], mapped_note, padx, pady, padw, padh) 
      padID0 = padID0 + 1
    end
    ]]
    
    
  end
  --------------------------------------------------------------------------------  
  function UI.Layout_Keys() 
    if EXT.UI_drracklayout ~= 1 then return end
    
    local cell_cnt_max = 24
      
    local xoffs0 = UI.calc_rackX
    --local yoffs0 = UI.calc_rackY + UI.calc_rackH - UI.calc_rack_padh
    local yoffs0 = UI.calc_rackY  + UI.calc_rack_padh*3 --+ UI.spacingY*3
    local padID0 = 0
    local oct = -1
    local xoffs, yoffs
    for note = DATA.parent_track.ext.PARENT_DRRACKSHIFT, cell_cnt_max-1+DATA.parent_track.ext.PARENT_DRRACKSHIFT do
      xoffs = xoffs0
      yoffs = yoffs0
      local note_oct = note%12
      if note_oct ==0 then oct = oct + 1 end
      if oct == 1 then yoffs = yoffs - UI.calc_rack_padh*2 end
      if note_oct == 0 then xoffs = xoffs0 end
      if note_oct == 1 then xoffs = xoffs0+0.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
      if note_oct == 2 then xoffs = xoffs0+1*UI.calc_rack_padw end
      if note_oct == 3 then xoffs = xoffs0+1.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
      if note_oct == 4 then xoffs = xoffs0+UI.calc_rack_padw*2 end
      if note_oct == 5 then xoffs = xoffs0+UI.calc_rack_padw*3 end
      if note_oct == 6 then xoffs = xoffs0+3.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
      if note_oct == 7 then xoffs = xoffs0+UI.calc_rack_padw*4 end
      if note_oct == 8 then xoffs = xoffs0+4.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
      if note_oct == 9 then xoffs = xoffs0+UI.calc_rack_padw*5 end
      if note_oct == 10 then xoffs = xoffs0+5.5*UI.calc_rack_padw yoffs=yoffs-UI.calc_rack_padh end
      if note_oct == 11 then xoffs = xoffs0+UI.calc_rack_padw*6 end
      if note >= 0 and note <=127 then UI.draw_Rack_Pads_controls(DATA.children[note], note, xoffs, yoffs, UI.calc_rack_padw, UI.calc_rack_padh) end
      padID0=padID0+1
    end
      
    
  end
    --------------------------------------------------------------------------------  
    function UI.draw_Rack_Pads() 
      
      if not (DATA.parent_track and DATA.parent_track.valid == true) then return end
      
      --ImGui.DrawList_AddRectFilled( UI.draw_list, UI.calc_rackX, UI.calc_rackY, UI.calc_rackX+UI.calc_rackW, UI.calc_rackY+UI.calc_rackH, 0xFFFFFFA0, 0, 0 )
      UI.Layout_Pads() 
      UI.Layout_Keys() 
      UI.Layout_Custom() 
      
      
    end
  --------------------------------------------------------------------------------  
  function UI.draw_Rack_Pads_controls(note_t,note, x,y,w,h) 
    local min_h = UI.controls_minH
    -- name background 
      local color
      if note_t and note_t.I_CUSTOMCOLOR then 
        color = ImGui.ColorConvertNative(note_t.I_CUSTOMCOLOR) 
        color = color & 0x1000000 ~= 0 and (color << 8) |  EXT.UI_col_tinttrackcoloralpha-- https://forum.cockos.com/showpost.php?p=2799017&postcount=6
      end
      
      --[[if EXT.CONF_autocol == 1 and DATA.children[note] and DATA.padautocolors and DATA.padautocolors[note] then 
        color = (DATA.padautocolors[note]>>8)  | 0x1000000
        color = color & 0x1000000 ~= 0 and (color << 8) | 0xFF-- https://forum.cockos.com/showpost.php?p=2799017&postcount=6
      end]]
            
      local h_name = h
      if h > min_h then h_name = UI.calc_rack_padnameH end
      if color then 
        ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+h, color, 5, ImGui.DrawFlags_RoundCornersTop) 
       else 
        if note_t then
          ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+h, EXT.UI_colRGBA_paddefaultbackgr, 5, ImGui.DrawFlags_RoundCornersTop)
         else
          ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y, x+w-1, y+h, EXT.UI_colRGBA_paddefaultbackgr_inactive, 5, ImGui.DrawFlags_RoundCornersTop) 
        end
      end
    
    -- LED database / defice
      if note_t then
        local offs = 5
        local ledyspace = 2
        local sz = 5
        local ledx= x+w-offs-sz
        local ledy= y+offs 
        if note_t.TYPE_DEVICE==true then                      ImGui.DrawList_AddRectFilled( UI.draw_list, ledx, ledy, ledx+sz, ledy+sz, 0x00FF50FF, 0, ImGui.DrawFlags_None) ledy=ledy+offs+ledyspace end
        if note_t.has_setDB then                              ImGui.DrawList_AddRectFilled( UI.draw_list, ledx, ledy, ledx+sz, ledy+sz, 0x0090FFFF, 0, ImGui.DrawFlags_None) ledy=ledy+offs+ledyspace end
        if note_t.has_setDB and note_t.has_setDBlocked then   ImGui.DrawList_AddRectFilled( UI.draw_list, ledx, ledy, ledx+sz, ledy+sz, 0xFF5000FF, 0, ImGui.DrawFlags_None) ledy=ledy+offs+ledyspace end
        if DATA.MIDIbus and DATA.MIDIbus.choke_setup and DATA.MIDIbus.choke_setup[note] then   
                                                              ImGui.DrawList_AddRectFilled( UI.draw_list, ledx, ledy, ledx+sz, ledy+sz, 0xFFFF00FF, 0, ImGui.DrawFlags_None) ledy=ledy+offs+ledyspace end
      end
      
    -- peaks 
      if EXT.UI_drracklayout ~= 2 and 
        DATA.children[note] and
        DATA.children[note].layers and 
        DATA.children[note].layers[1] and 
        DATA.peakscache[note] and 
        DATA.peakscache[note].peaks_arr  then 
        local is_pad_peak = true 
        local dim
        local ypeaks = y+UI.calc_itemH
        local hpeaks = UI.calc_rack_padnameH-UI.calc_itemH
        UI.draw_peaks('pad'..note, note_t, x + UI.spacingX, ypeaks, w-UI.spacingX*2 , hpeaks,DATA.peakscache[note].peaks_arr, is_pad_peak, dim) 
      end
    
    -- controls background 
      if h > min_h and UI.calc_rack_padctrlH > 0 then ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y+UI.calc_rack_padnameH, x+w-1, y+h-1, EXT.UI_colRGBA_padctrl, 5, ImGui.DrawFlags_RoundCornersBottom ) end
      
    -- controls background
      --ImGui.DrawList_AddRectFilled( UI.draw_list, x+1, y+UI.calc_rack_padnameH, x+w-1, y+h-1, 0xFFFFFF1F, 5, ImGui.DrawFlags_RoundCornersBottom )
    
    -- frame / selection 
      if (DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE  == note) then 
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, UI.colRGBA_selectionrect, 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
       else
        ImGui.DrawList_AddRect( UI.draw_list, x, y, x+w, y+h, 0x0000005F              , 5, ImGui.DrawFlags_None|ImGui.DrawFlags_RoundCornersAll, 1 )
      end
      
    
    ImGui.SetCursorScreenPos( ctx, x, y )  
    if ImGui.BeginChild( ctx, '##rackpad'..note, w, h, ImGui.ChildFlags_None , ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then--|ImGui.ChildFlags_Border
      local note_format = VF_Format_Note(note,note_t)
      if note_format then
        if EXT.UI_drracklayout == 2 then note_format = note_format..' ('..note..')' end
        if DATA.padcustomnames[note] and DATA.padcustomnames[note] ~= '' then note_format = DATA.padcustomnames[note] end
        if  DATA.parent_track.padcustomnames_overrides and DATA.parent_track.padcustomnames_overrides[note] and DATA.parent_track.padcustomnames_overrides[note] ~= '' then note_format = DATA.parent_track.padcustomnames_overrides[note] end
       else
        note_format = ''
      end
      UI.Tools_setbuttonbackg() 
      
      -- name 
        ImGui.PushFont(ctx, DATA.font3) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX, UI.spacingY)
        local local_pos_x, local_pos_y = ImGui.GetCursorPos( ctx )
        ImGui.SetCursorPos( ctx, local_pos_x+UI.spacingX, local_pos_y+UI.spacingY )
        ImGui.Button(ctx,'##rackpad_name'..note,UI.calc_rack_padw -UI.spacingX *2+1,UI.calc_rack_padnameH-UI.spacingY*2 ) 
        UI.draw_Rack_Pads_controls_handlemouse(note_t,note)
        
        ImGui.SetCursorPos( ctx, local_pos_x+UI.spacingX, local_pos_y+UI.spacingY )
        ImGui.TextWrapped( ctx, note_format )
        
        ImGui.PopStyleVar(ctx)
        ImGui.PopFont(ctx) 
        
      if h > min_h and UI.calc_rack_padctrlH > 0 then 
      -- mute
        ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y +UI.calc_rack_padnameH)
        local ismute = note_t and note_t.B_MUTE and note_t.B_MUTE == 1
        if ismute==true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF0F0FF0 ) end
        if note_t and ImGui.Button(ctx,'M##rackpad_mute'..note,UI.calc_rack_padctrlW,UI.calc_rack_padctrlH ) then SetMediaTrackInfo_Value( note_t.tr_ptr, 'B_MUTE', note_t.B_MUTE~1 ) DATA.upd = true end  
        if ismute==true then ImGui.PopStyleColor(ctx) end
        ImGui.SameLine(ctx)
        
      -- play
        ImGui.InvisibleButton(ctx,'P##rackpad_playinv'..note,UI.calc_rack_padctrlW,UI.calc_rack_padctrlH )
        if ImGui.IsItemActivated( ctx ) then  DATA:Sampler_StuffNoteOn(note)  end
        if ImGui.IsItemDeactivated( ctx ) and EXT.UI_pads_sendnoteoff == 1 then DATA:Sampler_StuffNoteOn(note, 0, true) end
        
        local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
        local x2, y2 = reaper.ImGui_GetItemRectMax( ctx ) 
        --UI.textcol col_green
        local col = UI.textcol 
        if DATA.lastMIDIinputnote and DATA.lastMIDIinputnote == note then 
          col = UI.padplaycol
        end
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, col<<8|0xFF)
        ImGui.SetCursorScreenPos( ctx, x1+(x2-x1)/2-UI.calc_itemH/2, y1+(y2-y1)/2-UI.calc_itemH/2 )
        if note_t then ImGui.ArrowButton(ctx,'P##rackpad_play'..note ,ImGui.Dir_Right )end
        ImGui.PopStyleColor(ctx)
        
      -- solo
        ImGui.SetCursorScreenPos( ctx, x1+UI.calc_rack_padctrlW, y1 )
        local issolo = note_t and note_t.I_SOLO and note_t.I_SOLO > 0 
        if issolo == true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x00FF0FF0 ) end
        if note_t and ImGui.Button(ctx,'S##rackpad_solo'..note,UI.calc_rack_padctrlW,UI.calc_rack_padctrlH ) then
          if note_t and note_t.tr_ptr then 
            local outval = 2 if note_t.I_SOLO>0 then outval = 0 end SetMediaTrackInfo_Value( note_t.tr_ptr, 'I_SOLO', outval ) DATA.upd = true
          end 
        end   
        if issolo == true then ImGui.PopStyleColor(ctx) end
      end
      UI.Tools_unsetbuttonstyle()
      ImGui.EndChild( ctx)
    end
    
    UI.draw_Rack_Pads_controls_levels(note_t,note, x,y,w,h) 
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_Rack_Pads_controls_levels(note_t,note, x,y,w,h)
    local peak_w = 5
    if not (DATA.children[note] and DATA.children[note].peaksRMS_L) then return end
    local peaksRMS_L = DATA.children[note].peaksRMS_L  
    local peaksRMS_R = DATA.children[note].peaksRMS_R 
    
    local peakH = UI.calc_rack_padnameH-UI.calc_itemH
    local peakLx = x+w-peak_w*2
    local peakLy = y+UI.calc_itemH+peakH*(1-math.min(peaksRMS_L,1))
    ImGui.DrawList_AddRectFilled( UI.draw_list, peakLx, peakLy , peakLx+peak_w, y+UI.calc_rack_padnameH, UI.col_maintheme<<8|0xFF, 0, ImGui.DrawFlags_RoundCornersTop)
    if peaksRMS_L >0.9 then ImGui.DrawList_AddLine( UI.draw_list, peakLx, y+UI.calc_itemH , peakLx+peak_w, y+UI.calc_itemH, 0xFF0000FF, 1) end
    
    local peakH = UI.calc_rack_padnameH-UI.calc_itemH
    local peakRx = x+w-peak_w-2
    local peakRy = y+UI.calc_itemH+peakH*(1-math.min(peaksRMS_R,1))
    ImGui.DrawList_AddRectFilled( UI.draw_list, peakRx, peakRy , peakRx+peak_w, y+UI.calc_rack_padnameH, UI.col_maintheme<<8|0xFF, 0, ImGui.DrawFlags_RoundCornersTop)
    if peaksRMS_R >0.9 then ImGui.DrawList_AddLine( UI.draw_list, peakRx, y+UI.calc_itemH , peakRx+peak_w, y+UI.calc_itemH, 0xFF0000FF, 1) end
  end
  
  -------------------------------------------------------------------------------- 
  function UI.draw_popups_macro()
    if DATA.trig_context == 'macro' and DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO  then 
      local macroID = DATA.parent_track.ext.PARENT_LASTACTIVEMACRO
      ImGui.SeparatorText(ctx, 'Macro '..macroID)
      -- name
      local custom_name = ''
      if DATA.parent_track.ext and DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[macroID] and DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name then custom_name = DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name end
      local retval, buf = ImGui.InputText( ctx, 'Macro name', custom_name, ImGui.InputTextFlags_None )--ImGui.InputTextFlags_EnterReturnsTrue
      if retval then 
        if not DATA.parent_track.ext.PARENT_MACROEXT then DATA.parent_track.ext.PARENT_MACROEXT = {} end
        if not DATA.parent_track.ext.PARENT_MACROEXT[macroID] then DATA.parent_track.ext.PARENT_MACROEXT[macroID] = {} end
        if buf == '' then DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name = nil else DATA.parent_track.ext.PARENT_MACROEXT[macroID].custom_name = buf end
        DATA:WriteData_Parent() 
      end
      -- col rgb
      local col_current = 0
      if DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[macroID] and DATA.parent_track.ext.PARENT_MACROEXT[macroID].col_rgb then
        col_current = DATA.parent_track.ext.PARENT_MACROEXT[macroID].col_rgb
      end
      local retval, col_rgb = ImGui_ColorEdit3( ctx, 'Macro '..macroID..' color', col_current, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs|ImGui.ColorEditFlags_NoAlpha )
      if retval then
        if not DATA.parent_track.ext.PARENT_MACROEXT then DATA.parent_track.ext.PARENT_MACROEXT = {} end
        if not DATA.parent_track.ext.PARENT_MACROEXT[macroID] then DATA.parent_track.ext.PARENT_MACROEXT[macroID] = {} end
        DATA.parent_track.ext.PARENT_MACROEXT[macroID].col_rgb = col_rgb
        DATA:WriteData_Parent() 
        --ImGui.CloseCurrentPopup(ctx) 
      end
      
      ImGui.SeparatorText(ctx, 'Parameter links')
      if ImGui.Button(ctx,'Add last touched parameter',-1) then 
        Undo_BeginBlock2(DATA.proj )
        DATA:Macro_AddLink()
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Macro - add link', 0xFFFFFFFF )
      end
      if ImGui.Button(ctx,'Clear all links',-1) then 
        Undo_BeginBlock2(DATA.proj )
        DATA:Macro_ClearLink()
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Macro - clear links', 0xFFFFFFFF )
      end 
      ImGui.SeparatorText(ctx, 'MIDI/OSC bindings') 
      
      local retval1, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
      local str = ''
      local valid
      if retval1 then 
        local midi2 = rawmsg:byte(2)
        local midi1 = rawmsg:byte(1)  
        if midi1 and midi2 and  midi1&0xB0==0xB0 then valid = true str = 'CC chan'..(1+(midi1&0x0F)*15)..' / CC#'
         --elseif midi1&0x90==0x90 then valid = true str = 'NoteOn '..(1+(midi1&0x0F)*15)..' / Pitch'
         --elseif midi1&0x80==0x80 then valid = true str = 'NoteOn '..(1+(midi1&0x0F)*15)..' / Pitch'
        end
        if str ~='' then str = str..' '..midi2 end
      end
      
      if valid~= true then str = '[not found/not available]' end
      if valid == true then
        if ImGui.Button(ctx,'Bind to: '..str,-1) then DATA:Action_LearnController(DATA.parent_track.ptr, DATA.parent_track.macro.pos, macroID) end 
       else
        ImGui.BeginDisabled(ctx, true)ImGui.Button(ctx,'Bind to: '..str,-1) ImGui.EndDisabled(ctx)
      end
      if ImGui.Button(ctx,'Open native "Learn" window',-1) then
        TrackFX_SetNamedConfigParm(DATA.parent_track.ptr, DATA.parent_track.macro.pos,'last_touched' ,macroID) 
        Main_OnCommand(41144,0) -- FX: Set MIDI learn for last touched FX parameter
      end
      if ImGui.Button(ctx,'Clear bindings',-1) then 
        local clear = true
        DATA:Action_LearnController(DATA.parent_track.ptr, DATA.parent_track.macro.pos, macroID,clear )
      end 
      
      
    end
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
      for note_src in pairs(DATA.MIDIbus.choke_setup[note]) do
        if DATA.MIDIbus.choke_setup[note][note_src].exist == true then DATA.MIDIbus.choke_setup[note][note_src].mark_for_remove = true end
      end
      DATA:Choke_Write()
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
  -------------------------------------------------------------------------------- 
  function UI.draw_popups_pad()
    if DATA.trig_context == 'pad' and DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE  then 
      ImGui.SeparatorText(ctx, 'Pad '..DATA.parent_track.ext.PARENT_LASTACTIVENOTE)
      
      -- local Rename
      ImGui.Indent(ctx, 10)
      local retval, buf = ImGui_InputText( ctx, '##custpadnameinputparent', DATA.parent_track.padcustomnames_overrides[DATA.parent_track.ext.PARENT_LASTACTIVENOTE], ImGui_InputTextFlags_None() )
      if retval then 
        DATA.parent_track.padcustomnames_overrides[DATA.parent_track.ext.PARENT_LASTACTIVENOTE] = buf
        DATA:WriteData_Parent() 
        DATA.upd = true
      end
      ImGui.Unindent(ctx, 10) 
      
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
      
      -- choke
      UI.draw_chokecombo(note)
    end
  end
  -------------------------------------------------------------------------------- 
  function UI.draw_popups() 
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
      UI.draw_popups_macro() 
      UI.draw_popups_rs5k_ctrl()
      
      if DATA.trig_closepopup == true then ImGui.CloseCurrentPopup(ctx) DATA.trig_closepopup = nil end
      ImGui.EndPopup(ctx)
    end 
  
    ImGui.PopStyleVar(ctx, 5)
  end  
  -------------------------------------------------------------------------------- 
  function UI.draw_popups_rs5k_ctrl()  
    
    if not (DATA.trig_context == 'rs5k_ctrl' and DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE) then return end 
    
    local note =  DATA.parent_track.ext.PARENT_LASTACTIVENOTE
    local layer =  DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER 
    
    if not (DATA.parent_track.macro and DATA.parent_track.macro.sliders) then 
      reaper.ImGui_TextDisabled(ctx, 'Macro links')
      return 
    end
    
    
    local track, fx, param
    if DATA.children[note] and DATA.children[note].layers and DATA.children[note].layers[layer] then
      track =    DATA.children[note].layers[layer].tr_ptr
      fx = DATA.children[note].layers[layer].instrument_pos
    end 
    
    if DATA.trig_openpopup_context == 'gain' then param = DATA.children[note].layers[layer].instrument_volID end 
    if DATA.trig_openpopup_context == 'attack' then param = DATA.children[note].layers[layer].instrument_attackID end
    if DATA.trig_openpopup_context == 'decay' then param = DATA.children[note].layers[layer].instrument_decayID end 
    if DATA.trig_openpopup_context == 'sustain' then param = DATA.children[note].layers[layer].instrument_sustainID end 
    if DATA.trig_openpopup_context == 'release' then param = DATA.children[note].layers[layer].instrument_releaseID end
    
    local destslider
    for slider in pairs(DATA.parent_track.macro.sliders) do
      if DATA.parent_track.macro.sliders[slider].links then 
        for link in pairs(DATA.parent_track.macro.sliders[slider].links) do
          local t = DATA.parent_track.macro.sliders[slider].links[link].note_layer_t
          if t.noteID == note and t.layerID == layer then
            local param_dest = DATA.parent_track.macro.sliders[slider].links[link].param_dest
            if param_dest == param  then
              destslider = slider
              break
            end
          end
        end
      end
    end
    
    if destslider then
      ImGui.SeparatorText(ctx, 'Pad '..DATA.parent_track.ext.PARENT_LASTACTIVENOTE..': '..DATA.trig_openpopup_context)  
      if ImGui.Button(ctx,'Remove from macro '..destslider) then 
        Undo_BeginBlock2(DATA.proj )
        TrackFX_SetNamedConfigParm(track, fx, 'param.'..param..'plink.active', 0)
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Remove link', 0xFFFFFFFF ) 
        ImGui.CloseCurrentPopup(ctx)
      end 
    end
    
    ImGui.SeparatorText(ctx, 'Link to macro')
    for macro = 1, DATA.parent_track.ext.PARENT_MACROCNT do
      if not destslider or (destslider and macro ~= destslider) then
        if ImGui.Selectable(ctx,'Link to macro '..macro) then 
          TrackFX_SetNamedConfigParm( track, fx, 'last_touched',param )
          DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = macro
          DATA:Macro_AddLink()
          ImGui.CloseCurrentPopup(ctx)
        end
      end
    end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_Sampler_trackparams()
    local butw = 40
    local butw_3x = (butw)*3+UI.spacingX*2
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end
    
    local note_layer_t,note,layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end 
    if DATA.children[note].TYPE_DEVICE then note_layer_t = DATA.children[note] end
    
    
    curposx_abs, curposy_abs = reaper.ImGui_GetCursorScreenPos(ctx)
    
    UI.draw_knob(
      {str_id = '##spl_trvol',
      is_small_knob = true,
      val = math.min(1,note_layer_t.D_VOL/2), 
      default_val = 0.5,
      x = curposx_abs, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Volume',
      val_form = note_layer_t.D_VOL_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v)  
        note_layer_t.D_VOL =v *2
        note_layer_t.D_VOL_format =  DATA:CollectData_FormatVolume(note_layer_t.D_VOL)  
        SetMediaTrackInfo_Value( note_layer_t.tr_ptr, 'D_VOL', v *2 )
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if tonumber(str_in) then 
          local out  = VF_lim(WDL_DB2VAL( tonumber(str_in)),0,2)
          SetMediaTrackInfo_Value( note_layer_t.tr_ptr, 'D_VOL',out )
          DATA.upd = true
        end
      end,
      })

      
      
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs()
    if UI.hide_tabs == true then return end
    if not (DATA.parent_track and DATA.parent_track.ext) then return end
    
    ImGui.SetCursorPos(ctx, UI.calc_settingsX,UI.calc_settingsY)
    --local xabs,yabs = ImGui.GetCursorScreenPos(ctx)
    --ImGui.SetCursorScreenPos(ctx,xabs,UI.calc_settingsY)
    
    local tabW = -1
    local cur_w = DATA.display_w - ImGui.GetCursorPosX(ctx)
    if cur_w > UI.settingsfixedW then tabW = UI.settingsfixedW end
    if ImGui.BeginChild( ctx, 'tabs', tabW, 0, ImGui.ChildFlags_None , ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then --|ImGui.ChildFlags_Border
      if ImGui.BeginTabBar( ctx, 'tabsbar', ImGui.TabItemFlags_None ) then
        
        function __f_tabs() end
        
        
        if ImGui.BeginTabItem( ctx, 'Sampler', false, ImGui.TabItemFlags_None ) then UI.tab_context = 'Sampler' UI.draw_tabs_Sampler()  ImGui.EndTabItem( ctx)  end 
        if ImGui.BeginTabItem( ctx, 'Macro', false, ImGui.TabItemFlags_None ) then UI.tab_context = 'Macro' UI.draw_tabs_macro() ImGui.EndTabItem( ctx)  end 
        if ImGui.BeginTabItem( ctx, 'Settings', false, ImGui.TabItemFlags_None ) then UI.tab_context = 'Settings' UI.draw_tabs_settings() ImGui.EndTabItem( ctx)  end 
        if ImGui.BeginTabItem( ctx, 'Actions', false, ImGui.TabItemFlags_None ) then UI.tab_context = 'Actions' UI.draw_tabs_Actions() ImGui.EndTabItem( ctx)  end 
        
           
        -- draw seq button
          local steseqavailable
          if DATA.stepseq_ID then steseqavailable = true end
          local xoffs = 300
          local wbut = 100
          ImGui.SetCursorPos(ctx,xoffs,0)
          if ImGui.InvisibleButton(ctx, 'mode', wbut, 20) then if steseqavailable == true then Main_OnCommand(DATA.stepseq_ID,0) else ReaPack_BrowsePackages( 'RS5k_StepSequencer' ) end end
          x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
          x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
          local checkbox_h = 16
          local checkbox_r = math.floor(checkbox_h / 2)
          local center_x = x1
          local center_y = math.floor(y1 + (y2-y1)/2 )-1
          local colfill = 0xF0F0F04F
          if steseqavailable == true and ImGui_IsItemHovered(ctx) then colfill = 0xF0F0F09F end
          ImGui.DrawList_AddCircle( UI.draw_list, center_x, center_y, checkbox_r, 0xF0F0F07F, 0, 2 )
          ImGui.DrawList_AddCircleFilled( UI.draw_list, center_x, center_y, checkbox_r-3, colfill, 0 ) 
          ImGui.SetCursorPos(ctx,xoffs+checkbox_r+ UI.spacingX,2)
          if steseqavailable == true then ImGui.Text(ctx, 'StepSequencer') else ImGui.TextDisabled(ctx, 'StepSequencer') end
            
        
        
        ImGui.EndTabBar( ctx)
      end
      
        
      ImGui.Dummy(ctx,0,0)
      
      
      ImGui.EndChild( ctx)
    end
  end 
  --------------------------------------------------------------------------------  
  function UI.Link(txt, url)
    local color = ImGui.GetStyleColor(ctx, ImGui.Col_CheckMark)
    ImGui.Button(ctx, txt)
    if ImGui.IsItemClicked(ctx) then
      VF_Open_URL(url)
    elseif ImGui.IsItemHovered(ctx) then
      ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_macro()
    if not DATA.parent_track.valid == true then return end
    
    local MACRO_GUID = DATA.parent_track.ext.PARENT_MACRO_GUID   
    if not (MACRO_GUID and MACRO_GUID~='') then 
      if ImGui.Button(ctx, 'Init macro on parent track') then DATA:Macro_InitChildrenMacro() end
      return 
    end
    
    
    if not (DATA.parent_track.macro and DATA.parent_track.macro.sliders) then return end
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,0,0)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0,0)  
    local macro_w = UI.calc_knob_w_small
    local macro_h = UI.calc_macro_h
    local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
    local lane_in_row = 8
    for sliderID = 1, 16 do--#DATA.parent_track.macro.sliders do 
      if DATA.parent_track.macro.sliders[sliderID] then 
        local x = curposx + (macro_w+UI.spacingX) * ((sliderID-1)%lane_in_row)
        local y = curposy + (macro_h+UI.spacingY) * math.floor((sliderID-1)/lane_in_row)
        local colfill_rgb 
        if DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[sliderID] and DATA.parent_track.ext.PARENT_MACROEXT[sliderID].col_rgb then colfill_rgb = DATA.parent_track.ext.PARENT_MACROEXT[sliderID].col_rgb end
          
        local name = 'Macro '..sliderID
        if DATA.parent_track.ext.PARENT_MACROEXT and DATA.parent_track.ext.PARENT_MACROEXT[sliderID] and DATA.parent_track.ext.PARENT_MACROEXT[sliderID].custom_name then name = DATA.parent_track.ext.PARENT_MACROEXT[sliderID].custom_name end
          
        UI.draw_knob(
          {str_id = '##slider'..sliderID,
          is_selected = (DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO  == sliderID),
          val = DATA.parent_track.macro.sliders[sliderID].val,
          x = x, 
          y = y,
          w =macro_w,
          h = macro_h,
          colfill_rgb = colfill_rgb,
          name = name, 
          customfont = DATA.font4,
          active_name = DATA.parent_track.macro.sliders[sliderID].has_links ,
          appfunc_atclick = function(v) 
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent()  
                                end,
          appfunc_atclickR = function(v) 
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent()  
                                  DATA.upd = true
                                  if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'macro' end
                                end,
          appfunc_atdrag = function(v) DATA.parent_track.macro.sliders[sliderID].val = v TrackFX_SetParamNormalized( DATA.parent_track.ptr, DATA.parent_track.macro.pos, sliderID, v )   end,
          appfunc_atclick_name= function()
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent() 
                                end,
          appfunc_atclick_nameR= function()
                                  DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = sliderID
                                  DATA:WriteData_Parent()  
                                  DATA.upd = true
                                  if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'macro' end
                                end,            
          }) 
        ImGui.SameLine(ctx)
      end
    end
    
    
    
    
    ImGui.PopStyleVar(ctx,2)
    ImGui.SetCursorScreenPos(ctx,curposx, curposy+UI.calc_macro_h*2+UI.spacingY*2)
    UI.draw_tabs_macro_links()
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_macro_links_SetParams(UI_min,UI_max,link_t,note_layer_t)
    TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.offset', 0)  
    TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'mod.baseline', UI_min) 
    
    local ret, baseline = TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'mod.baseline')  baseline = tonumber(baseline)
    local ret, scale = TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale')  scale = tonumber(scale)
    
    if baseline + scale < 0 or baseline + scale > 1 then 
      UI_max = VF_lim(baseline + scale)
      TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale', UI_max - baseline)  
     else
      TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale', UI_max - baseline)  
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tabs_macro_links()
    local indent= 20
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY)  
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX,UI.spacingY)  
    --ImGui.SetCursorPos(ctx, 0,0)
    
      
      
    -- link list
    if ImGui.BeginChild( ctx, 'macrolinks', 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then--|ImGui.ChildFlags_Border --|ImGui.WindowFlags_MenuBar-- |ImGui.WindowFlags_NoScrollbar -- UI.calc_rackW
    
      
      
      
      if (DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO) then
        
        local macroID = DATA.parent_track.ext.PARENT_LASTACTIVEMACRO
        if DATA.parent_track.macro.sliders[macroID] and DATA.parent_track.macro.sliders[macroID].links then
          for linkID = 1, #DATA.parent_track.macro.sliders[macroID].links do

          local link_t = DATA.parent_track.macro.sliders[macroID].links[linkID] 
          local note_layer_t= link_t.note_layer_t
          local note = note_layer_t.noteID or 0
          local layer = note_layer_t.layerID or 1
          local P_NAME = note_layer_t.P_NAME or ''
          
          --[[ name
          UI.Tools_setbuttonbackg()
          ImGui.Button(ctx, P_NAME..' [N'..note..' L'..layer..'] - '..DATA.parent_track.macro.sliders[macroID].links[linkID].param_name)
          UI.Tools_unsetbuttonstyle()]]
          
          local linkname = P_NAME..' [N'..note..' L'..layer..'] - '..DATA.parent_track.macro.sliders[macroID].links[linkID].param_name
          
            if ImGui.TreeNode(ctx, linkname, ImGui.TreeNodeFlags_None) then  
              
              --ImGui.Indent(ctx,indent)
            
              --[[ offset
              ImGui.SetNextItemWidth(ctx, 80)
              local formatIn = math.floor(link_t.plink_offset*100)..'%%'
              local retval, v = ImGui_SliderDouble( ctx, 'Offset##offs'..linkID, link_t.plink_offset, -1, 1, formatIn )
              if retval then TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.offset', v) DATA.upd = true end 
              
              -- scale
              ImGui.SameLine(ctx)
              ImGui.SetNextItemWidth(ctx, 80)
              local formatIn = math.floor(link_t.plink_scale*100)..'%%'
              local retval, v = ImGui_SliderDouble( ctx, 'Scale##scale'..linkID, link_t.plink_scale, -1, 1, formatIn )
              if retval then TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.scale', v) DATA.upd = true end     
              ImGui.SameLine(ctx)]]
              
              
              
              -- min
              ImGui.SetNextItemWidth(ctx, 80)
              local retval, v = ImGui_SliderDouble( ctx, 'Min##UI_min'..linkID, link_t.UI_min, 0, 1, '%.3f' )
              if retval then
                v = VF_lim(v,link_t.UI_max)
                UI.draw_tabs_macro_links_SetParams(v,link_t.UI_max,link_t,note_layer_t)
                DATA.upd = true 
              end 
              -- max
              ImGui.SameLine(ctx)
              ImGui.SetNextItemWidth(ctx, 80)
              local retval, v = ImGui_SliderDouble( ctx, 'Max##UI_max'..linkID, link_t.UI_max, 0, 1, '%.3f' )
              if retval then 
                v = VF_lim(v)
                UI.draw_tabs_macro_links_SetParams(link_t.UI_min,v,link_t,note_layer_t)
                DATA.upd = true 
              end 
              
              -- min format
              local buf = link_t.UI_min 
              local noteT = link_t.note_layer_t
              local track = noteT.tr_ptr
              local retval, buf1 = reaper.TrackFX_FormatParamValue( track, link_t.fx_dest, link_t.param_dest, link_t.UI_min )
              if retval then 
                ImGui.SetNextItemWidth(ctx, 80)
                local retval, v = ImGui.InputText( ctx, 'Min##UI_minformat'..linkID, buf1, ImGui.InputTextFlags_None )
                if retval and v ~= '' then 
                  local valout = VF_BFpluginparam(v, track, link_t.fx_dest, link_t.param_dest)
                  if valout then 
                    UI.draw_tabs_macro_links_SetParams(valout,link_t.UI_max,link_t,note_layer_t)
                  end
                end
              end
              -- max format
              local buf = link_t.UI_max
              local noteT = link_t.note_layer_t
              local track = noteT.tr_ptr
              local retval, buf1 = reaper.TrackFX_FormatParamValue( track, link_t.fx_dest, link_t.param_dest, link_t.UI_max )
              if retval then 
                ImGui.SameLine(ctx)
                ImGui.SetNextItemWidth(ctx, 80)
                local retval, v = ImGui.InputText( ctx, 'Max##UI_maxformat'..linkID, buf1, ImGui.InputTextFlags_None )
                if retval and v ~= '' then 
                  local valout = VF_BFpluginparam(v, track, link_t.fx_dest, link_t.param_dest)
                  if valout then 
                    UI.draw_tabs_macro_links_SetParams(link_t.UI_min,valout,link_t,note_layer_t)
                  end
                end
              end
              
              
              
              -- remove
              if ImGui.Button(ctx, 'Remove##rem'..linkID) then
                Undo_BeginBlock2(DATA.proj )
                TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'plink.active', 0)
                Undo_EndBlock2( DATA.proj , 'RS5k manager - Remove link', 0xFFFFFFFF ) 
                DATA.upd = true
              end
              
              -- Mod
              ImGui.SameLine(ctx)
              if ImGui.Button(ctx, 'Mod##modshow'..linkID) then
                TrackFX_SetNamedConfigParm(note_layer_t.tr_ptr, link_t.fx_dest, 'param.'..link_t.param_dest..'mod.visible', 1)
              end            
            
              --ImGui.Unindent(ctx,indent)
              ImGui.TreePop(ctx)
            end
          end
        end
      end 
      
      
      ImGui.Dummy(ctx,0,10)
      
      ImGui.EndChild( ctx)
    end
    ImGui.PopStyleVar(ctx,2)
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
  function UI.HelpMarker(desc, tooltip_code)
    ImGui.TextDisabled(ctx, '(?)')
    if ImGui.BeginItemTooltip(ctx) then
      if tooltip_code then 
        tooltip_code()
       else
        ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
        ImGui.Text(ctx, desc)
        ImGui.PopTextWrapPos(ctx)
      end
      ImGui.EndTooltip(ctx)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_startup()  
    if not (DATA.parent_track and DATA.parent_track.valid == true) then 
      ImGui.TextWrapped(ctx,
          [[ 
      RS5k manager quick tips: 
          1. Select parent track. It will be parent track for drum rack. Or create it:]]) --ImGui.SameLine(ctx) 
          ImGui.Dummy(ctx,30,0) ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'Insert new parent track') then 
            Undo_BeginBlock2(-1)
            InsertTrackInProject(-1, 0,0) 
            local tr = GetTrack(-1,0)
            GetSetMediaTrackInfo_String( tr, 'P_NAME', 'RS5k manager', true )
            reaper.SetOnlyTrackSelected( tr )
            Undo_EndBlock2(-1, 'Insert RS5k manager parent track', 0xFFFFFFFF)
            DATA.upd = true
          end
          
          ImGui.TextWrapped(ctx,  
[[          2. Once parent track is selected, drum rack is ready for adding samples to it.
          3. Drop sample to pads from OS browser or MediaExplorer to pad.  
          4. RS5k manager will automatically initialize all needed routing setup.
          ]])
          ImGui.TextWrapped(ctx,
          [[
          For bug reports:
            - make sure you are running the latest version of RS5k manager]]..' (you are running version '..rs5kman_vrs..' currently)'..
            [[
            
            - please attach FULL text of error (including error line number) and steps to reproduce.
          ]])
          
          
          UI.Link('Forum thread', 'https://forum.cockos.com/showthread.php?t=207971')
          ImGui.SameLine(ctx) 
          ImGui.SetNextItemWidth(ctx, -1) 
          ImGui.InputText(ctx,'##forumlink','https://forum.cockos.com/showthread.php?t=207971', ImGui.InputTextFlags_AutoSelectAll)
          
          UI.Link('Telegram chat', 'https://t.me/mplscripts_chat')
          ImGui.SameLine(ctx) 
          ImGui.SetNextItemWidth(ctx, -1) 
          ImGui.InputText(ctx,'##telegrchat','https://t.me/mplscripts_chat', ImGui.InputTextFlags_AutoSelectAll)
          
    end
  end
  
--------------------------------------------------------------------------------  
  function UI.draw()  
    
    DATA.temp_ignore_incomingevent = false
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
    
    UI.draw_startup()
    UI.draw_Rack() 
    UI.draw_tabs()
    
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
  function UI.draw_tabs_Sampler_Startup()
    -- database
    if DATA.database_maps then 
        ImGui.Dummy(ctx, 0, 20)
        ImGui.Indent(ctx, 10)
        reaper.ImGui_TextWrapped(ctx, 'Drop any sample from MediaExplorer or OS explorer to pads to start a control over rack.Curently there is no any selected pad. Select any pad contain sample to edit pad controls.\n\n\nFor advanced users:\nIf you made a setup of database maps (see Settings/Database maps), you can load database to pads.')
        ImGui.SetNextItemWidth(ctx, UI.settings_itemW )
        
        if DATA.temp_rename == true then 
          local retval, buf = reaper.ImGui_InputText( ctx, '##dbcurname', DATA.database_maps[EXT.UIdatabase_maps_current].dbname, ImGui.InputTextFlags_AutoSelectAll|ImGui.InputTextFlags_EnterReturnsTrue )
          if ImGui.IsItemActive(ctx) and DATA.allow_space_to_play == true then DATA.allow_space_to_play = false end
          if retval and buf ~= '' then 
            DATA.temp_rename = false
            DATA.database_maps[EXT.UIdatabase_maps_current].dbname = buf
            DATA:Database_Save()
          end
         else
         
          if ImGui.BeginCombo( ctx, '##Loaddatabasemap', DATA.database_maps[EXT.UIdatabase_maps_current].dbname, ImGui.ComboFlags_None ) then--|ImGui.ComboFlags_NoArrowButton
            for i = 1, 8 do
              if ImGui.Selectable( ctx, DATA.database_maps[i].dbname..'##dbmapsel'..i, i == EXT.UIdatabase_maps_current, ImGui.SelectableFlags_None) then EXT.UIdatabase_maps_current = i EXT:save() end
            end
            ImGui.EndCombo( ctx)
          end
        end
        ImGui.SameLine(ctx)
        
        
        if ImGui.Button(ctx, 'Load to all rack') then 
          DATA:Validate_MIDIbus_AND_ParentFolder() 
          Undo_BeginBlock2(DATA.proj )
          DATA:Database_Load() 
          Undo_EndBlock2( DATA.proj , 'Load database to all rack', 0xFFFFFFFF )
        end
        
        
        if DATA.parent_track.ext.PARENT_LASTACTIVENOTE == -1 then reaper.ImGui_BeginDisabled(ctx, true) end
        ImGui.SameLine(ctx) if ImGui.Button(ctx, 'Load to selected pads') then 
          DATA:Validate_MIDIbus_AND_ParentFolder() 
          Undo_BeginBlock2(DATA.proj )
          DATA:Database_Load(true)
          Undo_EndBlock2( DATA.proj , 'Load database to selected pad only', 0xFFFFFFFF )
        end
        if DATA.parent_track.ext.PARENT_LASTACTIVENOTE == -1 then reaper.ImGui_EndDisabled(ctx) end
        
        ImGui.Unindent(ctx, 10)
      end
      
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler()
    local note_layer_t, note, layer = DATA:Sampler_GetActiveNoteLayer() if not (note_layer_t) then UI.draw_tabs_Sampler_Startup() return end 
    local fxbutw = 40
    -- name
    local name = DATA.children[note].P_NAME
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0,0.5)
    UI.Tools_setbuttonbackg()
    ImGui.SetNextItemWidth(ctx, 170)
    if DATA.children[note].TYPE_DEVICE == true then ImGui.SetNextItemWidth(ctx, 170) end
    local retval, buf = reaper.ImGui_InputText( ctx, '##sampler_activename', name, ImGui.InputTextFlags_EnterReturnsTrue )
    if retval then
      if DATA.children[note].TYPE_DEVICE == true then 
        GetSetMediaTrackInfo_String( DATA.children[note].tr_ptr, 'P_NAME', buf, true )
       else
        GetSetMediaTrackInfo_String( note_layer_t.tr_ptr, 'P_NAME', buf, true )
      end
      DATA.upd = true
    end
    UI.Tools_unsetbuttonstyle()
    ImGui.PopStyleVar(ctx)
    if ImGui.BeginDragDropTarget( ctx ) then  
      UI.Drop_UI_interaction_sampler() 
      ImGui_EndDragDropTarget( ctx )
    end
    
    -- tooltip full name
    if note_layer_t and note_layer_t.instrument_filename then ImGui.SetItemTooltip(ctx, note_layer_t.instrument_filename) end
    
    -- device fx
      if DATA.children[note].TYPE_DEVICE == true then 
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'FX##device_fx',fxbutw) then TrackFX_Show( DATA.children[note].tr_ptr,0, 1 ) end
      end
    
    ImGui.SameLine(ctx)
    local col_rgb  = DATA.children[note].I_CUSTOMCOLOR 
    
    col_rgb = ImGui.ColorConvertNative(col_rgb)
    local col_rgba = (col_rgb << 8) | 0xFF--col_rgb & 0x1000000 ~= 0 and 
    if col_rgb & 0x1000000 == 0 then col_rgba = 0x5F5F5FFF end
    --local r, g, b = reaper.ColorFromNative( col_rgb )
    --local col_rgba = r<<24|g<<16|b<<8|0xFF
    if col_rgba then 
      local retval, col_rgba = ImGui.ColorEdit4( ctx, '##coloreditpad', col_rgba, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs)--|ImGui.ColorEditFlags_NoAlpha )
      if retval then 
        local r, g, b = (col_rgba>>24)&0xFF, (col_rgba>>16)&0xFF, (col_rgba>>8)&0xFF
        col_rgb = ColorToNative( r, g, b )
        DATA.children[note].I_CUSTOMCOLOR  = col_rgb
        local tr_ptr = DATA.children[note].tr_ptr
        SetMediaTrackInfo_Value( tr_ptr, 'I_CUSTOMCOLOR', col_rgb|0x1000000 )
        if DATA.children[note].layers then 
          for layerid = 1, #DATA.children[note].layers do
            local tr_ptr = DATA.children[note].layers[layerid].tr_ptr
            SetMediaTrackInfo_Value( tr_ptr, 'I_CUSTOMCOLOR', col_rgb|0x1000000 )
          end
        end
        DATA.upd = true
      end
    end
    
    ImGui.SameLine(ctx)
    
    -- layer selector
    local layerselectW = 150
    if DATA.children[note] and DATA.children[note].TYPE_DEVICE==true and layer ~= 0 then
      ImGui.SameLine(ctx)
      preview_value = string.format('%02d',layer)..' '..note_layer_t.P_NAME
      ImGui.SetNextItemWidth(ctx, layerselectW)
      if ImGui.BeginCombo( ctx, '##layerselect', preview_value, ImGui.ComboFlags_None ) then
        for layerID = 1, #DATA.children[note].layers do
          if ImGui.Selectable(ctx, string.format('%02d',layerID)..' '..DATA.children[note].layers[layerID].P_NAME..'##layers_selectorNsame'..layerID,layerID == layer, ImGui.SelectableFlags_None) then
            DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = layerID
            DATA:WriteData_Parent()
            DATA.upd = true
          end
        end
        ImGui.EndCombo( ctx )
      end 
      ImGui.SameLine(ctx)
     else
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx,layerselectW,0)
      ImGui.SameLine(ctx)
    end
      
    -- fx
    if layer ~= 0 then 
      if ImGui.Button(ctx, 'FX##sampler_fx',-1) then TrackFX_Show( note_layer_t.tr_ptr, note_layer_t.instrument_pos or 0, 1 ) end
     else
      ImGui.Dummy(ctx,0,0)
    end
    
    -- peaks
   --UI.Tools_setbuttonbackg()
    local plotx, ploty = ImGui.GetCursorPos( ctx)
    local plotx_abs, ploty_abs = ImGui.GetCursorScreenPos( ctx )
    if ImGui.BeginDisabled(ctx, true) then 
      --ImGui.Button(ctx, '[drop area]##sampler_peaks',-1, UI.sampler_peaksH) 
      ImGui.EndDisabled(ctx)
    end
    local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
    local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
    --if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left) and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then DATA:Sampler_StuffNoteOn(DATA.parent_track.ext.PARENT_LASTACTIVENOTE) end
    --if ImGui.IsItemDeactivated(ctx) and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then DATA:Sampler_StuffNoteOn(DATA.parent_track.ext.PARENT_LASTACTIVENOTE, 0 , true) end
    
    local is_slice = note_layer_t.instrument_samplestoffs and (not (note_layer_t.instrument_samplestoffs<0.01 and note_layer_t.instrument_sampleendoffs>0.99))
    local yoffs_peaksfull = 0
    
    
    -- peaks full
    if is_slice==true then
      local peaksX =plotx_abs+UI.adsr_rectsz/2
      local peaksY =ploty_abs
      local peaksW =UI.settingsfixedW
      local peaksH =UI.sampler_peaksfullH
      UI.draw_peaks('curfull',note_layer_t,peaksX-UI.spacingX, peaksY,peaksW, peaksH, note_layer_t.peaks_arr_samplerfull, true )
      yoffs_peaksfull = peaksH + UI.spacingY
      UI.draw_tabs_Sampler_BoundaryEdges(note_layer_t, plotx_abs, ploty_abs,x2,ploty_abs+UI.sampler_peaksfullH)
    end
    
    -- peaks normal
    local peaksX =plotx_abs+UI.adsr_rectsz/2
    local peaksY =ploty_abs +yoffs_peaksfull
    local peaksW =UI.settingsfixedW-UI.adsr_rectsz
    local peaksH =UI.sampler_peaksH
    UI.draw_peaks('cur',note_layer_t,peaksX, peaksY,peaksW, peaksH, note_layer_t.peaks_arr_sampler )    
    --UI.Tools_unsetbuttonstyle(plotx_abs, ploty_abs,-1, UI.sampler_peaksH)
    -- handle click to peaks for play
    local cl_x, cl_y = reaper.ImGui_GetMouseClickedPos( ctx, ImGui.MouseButton_Left )
    if ImGui.IsAnyItemHovered( ctx )~=true and ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Left,0 ) and cl_x >=peaksX and cl_x<=peaksX+peaksW and cl_y >=peaksY and cl_y<=peaksY+peaksH then 
      if DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then DATA:Sampler_StuffNoteOn(DATA.parent_track.ext.PARENT_LASTACTIVENOTE) end
    end
    UI.draw_tabs_Sampler_ADSR(note_layer_t, plotx_abs, ploty_abs+yoffs_peaksfull,x2,ploty_abs+UI.sampler_peaksH+yoffs_peaksfull)
    
    --
    ImGui.SetCursorPos( ctx, plotx, ploty+UI.sampler_peaksH+yoffs_peaksfull )
    UI.draw_tabs_Sampler_tabs()
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_ADSR(note_layer_t, x10,y10,x20,y20) 
    if note_layer_t.ISRS5K ~= true then return end
    local rect_sz = UI.adsr_rectsz
    local x1,y1,x2,y2 = x10+rect_sz,y10+rect_sz,x20-rect_sz,y20-rect_sz -- effective area
    ImGui.PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 1)
    ImGui.PushStyleColor(ctx, reaper.ImGui_Col_Button(), UI.colRGBA_ADSRrect)
    ImGui.PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), UI.colRGBA_ADSRrectHov)
    ImGui.PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), UI.colRGBA_ADSRrectHov)
    
    -- test
    ImGui.DrawList_AddRectFilled( UI.draw_list, x10,y10,x20,y20, EXT.UI_colRGBA_smplrbackgr, 2, ImGui.DrawFlags_None )
    
    
    --ImGui.DrawList_AddRectFilled( UI.draw_list, x1,y1,x2,y2, 0xFFFFFF0F, 2, ImGui.DrawFlags_None )
    
    -- attack
    UI.draw_tabs_Sampler_ADSR_points(note_layer_t, x10,y10,x20,y20) 
    
    ImGui.PopStyleVar(ctx)
    ImGui.PopStyleColor(ctx,3)
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_BoundaryEdges(note_layer_t, x10,y10,x20,y20) 
    if note_layer_t.ISRS5K ~= true then return end
    local note = note_layer_t.noteID
    -- backgr fill
    ImGui.DrawList_AddRectFilled( UI.draw_list, x10,y10,x20,y20, 0xFFFFFF0C, 2, ImGui.DrawFlags_None )
    
    -- backgr work area
    local samplestoffs = note_layer_t.instrument_samplestoffs
    local sampleendoffs = note_layer_t.instrument_sampleendoffs
    local w = x20-x10
    local pos1=  math.floor(x10+w*samplestoffs)
    local pos2=  math.floor(x10+w*sampleendoffs )
    local rect_sz = UI.adsr_rectsz
    
    ImGui.DrawList_AddRectFilled( UI.draw_list,pos1,y10,pos2,y20, 0x00FF001F, 2, ImGui.DrawFlags_None )
    
    ImGui.DrawList_AddTriangleFilled(  UI.draw_list, 
      pos1, y10, 
      pos1+rect_sz, y10, 
      pos1, y10+rect_sz, 
      UI.colRGBA_ADSRrect )
      
      
    ImGui.DrawList_AddTriangleFilled(  UI.draw_list, 
      pos2-rect_sz, y20, 
      pos2, y20-rect_sz, 
      pos2, y20,  
      UI.colRGBA_ADSRrect )
    
    
    UI.draw_setbuttonbackgtransparent()
    local x1,y1,x2,y2 = x10+rect_sz,y10+rect_sz,x20-rect_sz,y20-rect_sz -- effective area
    ImGui.SetCursorScreenPos( ctx, pos1, y10 )
    ImGui.Button(ctx, '##adsr_stoffs', UI.adsr_rectsz, UI.adsr_rectsz) 
    if ImGui.IsItemClicked( ctx ) then 
      DATA.temp_sampleboundary_st = note_layer_t.instrument_samplestoffs
    end
    if ImGui.IsItemActive( ctx ) then
      local x, y = reaper.ImGui_GetMouseDragDelta( ctx, x1, y1, ImGui.MouseButton_Left, 0 )
      local deltaX = x/(x2-x1)
      note_layer_t.instrument_samplestoffs = VF_lim(deltaX + DATA.temp_sampleboundary_st,0,note_layer_t.instrument_sampleendoffs)
      TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_samplestoffsID, note_layer_t.instrument_samplestoffs )    
      DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      DATA.peakscache[note]  = nil
    end 
    
    ImGui.SetCursorScreenPos( ctx, pos2-UI.adsr_rectsz, y20-UI.adsr_rectsz ) 
    ImGui.Button(ctx, '##adsr_enoffs', UI.adsr_rectsz, UI.adsr_rectsz)
    if ImGui.IsItemClicked( ctx ) then 
      DATA.temp_sampleboundary_end = note_layer_t.instrument_sampleendoffs
    end
    if ImGui.IsItemActive( ctx ) then
      local x, y = reaper.ImGui_GetMouseDragDelta( ctx, x1, y1, ImGui.MouseButton_Left, 0 )
      local deltaX = x/(x2-x1)
      note_layer_t.instrument_sampleendoffs = VF_lim(deltaX + DATA.temp_sampleboundary_end,note_layer_t.instrument_samplestoffs,1)
      TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sampleendoffsID, note_layer_t.instrument_sampleendoffs )   
      DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      DATA.peakscache[note]  = nil
    end
    
    UI.Tools_unsetbuttonstyle()
    
    UI.Tools_setbuttonbackg(0x00FF005F)
    local midbutW = pos2-pos1-UI.adsr_rectsz*2
    local midbutH = 10
    if midbutW > 5 then
      ImGui.SetCursorScreenPos( ctx, pos1+UI.adsr_rectsz, y10 + (y20-y10- midbutH )/2 ) 
      ImGui.Button(ctx, '##adsr_midoffs', midbutW, midbutH)
      if ImGui.IsItemClicked( ctx ) then 
        DATA.temp_sampleboundary_len = note_layer_t.instrument_sampleendoffs - note_layer_t.instrument_samplestoffs
        DATA.temp_sampleboundary_st = note_layer_t.instrument_samplestoffs
      end
      if ImGui.IsItemActive( ctx ) and DATA.temp_sampleboundary_len then
        --local mousex, mousey = reaper.ImGui_GetMousePos( ctx )
        local x, y = reaper.ImGui_GetMouseDragDelta( ctx, x1, y1, ImGui.MouseButton_Left, 0 )
        local deltaX = x/(x2-x1)
        
        DATA.temp_sampleboundary_len = note_layer_t.instrument_sampleendoffs - note_layer_t.instrument_samplestoffs
        
        local samplestoffs_out = VF_lim(DATA.temp_sampleboundary_st + deltaX,0,note_layer_t.instrument_sampleendoffs)
        local sampleendoffs_out = VF_lim(samplestoffs_out + DATA.temp_sampleboundary_len,note_layer_t.instrument_samplestoffs,1)
        local len = sampleendoffs_out - samplestoffs_out
        if DATA.temp_sampleboundary_len ==len then
          note_layer_t.instrument_samplestoffs = samplestoffs_out
          note_layer_t.instrument_sampleendoffs =sampleendoffs_out
          
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_samplestoffsID, note_layer_t.instrument_samplestoffs )   
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sampleendoffsID, note_layer_t.instrument_sampleendoffs )   
          DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
          
          DATA.peakscache[note]  = nil
        end
      end
    end
    UI.Tools_unsetbuttonstyle()
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_ADSR_point_getpos(x1,y1,x2,y2, xpos, ypos, centered)  
    if not xpos then return end
    if not centered then 
      return x1 + (x2-x1-UI.adsr_rectsz)*xpos, y1 + (y2-y1-UI.adsr_rectsz)*(1-ypos)
     else
      return x1 + (x2-x1-UI.adsr_rectsz)*xpos+UI.adsr_rectsz/2, y1 + (y2-y1-UI.adsr_rectsz)*(1-ypos)+UI.adsr_rectsz/2
    end
  end
    --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_ADSR_points(note_layer_t, x1,y1,x2,y2)  
    local note,layer = note_layer_t.noteID, layerID 
    local samplelen =note_layer_t.SAMPLELEN
    
    if not note_layer_t.instrument_attack_norm then return end
    -- delay
    local xpos = 0--note_layer_t.instrument_samplestoffs
    local ypos = 0 
    local xpos_del, ypos_del = UI.draw_tabs_Sampler_ADSR_point_getpos(x1,y1,x2,y2, xpos, ypos) 
    if not xpos_del then return end
    
    
    -- attack
    local att_mult = 10
    local xpos = note_layer_t.instrument_attack_norm *att_mult
    local ypos = 0.8--note_layer_t.instrument_vol  
    local xpos_att, ypos_att = UI.draw_tabs_Sampler_ADSR_point_getpos(x1,y1,x2,y2, xpos, ypos) 
    local attoffs = (xpos_del-x1)
    xpos_att = xpos_att + attoffs
    ImGui.SetCursorScreenPos( ctx, xpos_att, ypos_att )
    ImGui.Button(ctx, '##adsr_attvol', UI.adsr_rectsz, UI.adsr_rectsz)
    if ImGui.IsItemActive( ctx ) then
    
      local mousex, mousey = reaper.ImGui_GetMousePos( ctx )
      local v = VF_lim( ( mousex - x1 - attoffs ) / (x2-x1),0,1 )---note_layer_t.instrument_samplestoffs
      note_layer_t.instrument_attack = v * note_layer_t.instrument_attack_max
      TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID,note_layer_t.instrument_attack/att_mult )  
      
      --[[note_layer_t.instrument_vol = 1-VF_lim((mousey - y1)/(y2-y1))
      TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, note_layer_t.instrument_vol )   
      ]]
      DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values 
    end        
    
    -- delay - attack line 
    ImGui.DrawList_AddLine( UI.draw_list,xpos_del + UI.adsr_rectsz/2, ypos_del + UI.adsr_rectsz/2,xpos_att + UI.adsr_rectsz/2, ypos_att + UI.adsr_rectsz/2, UI.colRGBA_ADSRrect, 2 )
        
    -- decay
    local delmult = 1
    local susult = 2
    local xpos = note_layer_t.instrument_decay_norm *delmult
    local ypos = note_layer_t.instrument_sustain*susult*0.8
    local xpos_dec, ypos_dec = UI.draw_tabs_Sampler_ADSR_point_getpos(x1,y1,x2,y2, xpos, ypos) 
    xpos_dec = xpos_att + xpos * (x2-x1)
    ImGui.SetCursorScreenPos( ctx, xpos_dec, ypos_dec ) 
    ImGui.Button(ctx, '##adsr_decsus', UI.adsr_rectsz, UI.adsr_rectsz )
    if ImGui.IsItemActive( ctx ) then
    
      local mousex, mousey = reaper.ImGui_GetMousePos( ctx )
      local offs = note_layer_t.instrument_attack_norm*att_mult --+ note_layer_t.instrument_samplestoffs
      local v = VF_lim( ( mousex - x1 ) / (x2-x1), offs,1)
      v = v - offs
      note_layer_t.instrument_decay = v * note_layer_t.instrument_decay_max
      TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v*note_layer_t.instrument_decay_max/delmult )  
      
      local v2 = 1-VF_lim((mousey - y1)/(y2-y1))
      note_layer_t.instrument_sustain =v2
      TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v2/susult ) 
      
      DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values 
    end          
    
    -- attack - decay line 
    ImGui.DrawList_AddLine( UI.draw_list,xpos_att + UI.adsr_rectsz/2, ypos_att + UI.adsr_rectsz/2, xpos_dec + UI.adsr_rectsz/2, ypos_dec + UI.adsr_rectsz/2, UI.colRGBA_ADSRrect, 2 )
    
    
    -- release
    local xpos = note_layer_t.instrument_release_norm 
    local ypos = 0 
    local xpos_rel, ypos_rel = UI.draw_tabs_Sampler_ADSR_point_getpos(x1,y1,x2,y2, xpos, ypos) 
    xpos_rel = xpos_rel + (note_layer_t.instrument_attack_norm*att_mult  + note_layer_t.instrument_decay_norm*delmult) * (x2-x1)--+ note_layer_t.instrument_samplestoffs
    ImGui.SetCursorScreenPos( ctx, xpos_rel, ypos_rel )
    ImGui.Button(ctx, '##adsr_rel', UI.adsr_rectsz, UI.adsr_rectsz)
    if ImGui.IsItemActive( ctx ) then
      local mousex, mousey = reaper.ImGui_GetMousePos( ctx )
      
      local offs = note_layer_t.instrument_attack_norm*att_mult  + note_layer_t.instrument_decay_norm*delmult--+ note_layer_t.instrument_samplestoffs
      local v = VF_lim( ( mousex - x1 ) / (x2-x1), offs,1)
      v = v - offs
      note_layer_t.instrument_release = v * note_layer_t.instrument_release_max
      TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID,note_layer_t.instrument_release )  
      
      DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
    end
    
    -- delay - attack line 
    ImGui.DrawList_AddLine( UI.draw_list,xpos_dec + UI.adsr_rectsz/2, ypos_dec + UI.adsr_rectsz/2, xpos_rel + UI.adsr_rectsz/2, ypos_rel + UI.adsr_rectsz/2, UI.colRGBA_ADSRrect, 2 )
    
    
    
    -- loop offs
    if note_layer_t.instrument_loop == 1 then
      local loopoffs = note_layer_t.instrument_loopoffs_norm
      local rect_sz = UI.adsr_rectsz
      local pos1 = x1+(x2-x1) * loopoffs + UI.spacingX
      ImGui.DrawList_AddTriangleFilled(  UI.draw_list, 
        pos1-rect_sz, y1, 
        pos1, y1, 
        pos1, y1+rect_sz, 
        UI.colRGBA_ADSRrect )
        
      UI.draw_setbuttonbackgtransparent()
      ImGui.SetCursorScreenPos( ctx, pos1-rect_sz, y1 )
      ImGui.Button(ctx, '##adsr_loopoffs', UI.adsr_rectsz, UI.adsr_rectsz) 
      UI.Tools_unsetbuttonstyle()
      if ImGui.IsItemActive( ctx ) then
        local mousex, mousey = reaper.ImGui_GetMousePos( ctx )
        note_layer_t.instrument_loopoffs_norm = VF_lim((mousex - x1)/(x2-x1))
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_loopoffsID, note_layer_t.instrument_loopoffs_norm*note_layer_t.instrument_loopoffs_max )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end 
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
    if dim then peakscol =  0xFFFFFF35 end
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
  function UI.draw_tabs_Sampler_tabs()
    --if reaper.ImGui_BeginChild(ctx, '##draw_tabs_Sampler_tabs', 0, 140) then
      if ImGui.BeginTabBar( ctx, 'tabsbar_sampler', ImGui.TabItemFlags_None ) then 
        
        
        local note_layer_t = DATA:Sampler_GetActiveNoteLayer()
        if note_layer_t then
          if note_layer_t.ISRS5K then
            
            if ImGui.BeginTabItem( ctx, 'General', false, ImGui.TabItemFlags_None ) then        UI.draw_tabs_Sampler_tabs_rs5kcontrols()ImGui.EndTabItem( ctx) end
            if ImGui.BeginTabItem( ctx, 'Sample', false, ImGui.TabItemFlags_None ) then         UI.draw_tabs_Sampler_tabs_sample()      ImGui.EndTabItem( ctx) end 
            
            if ImGui.BeginTabItem( ctx, 'Boundary', false, ImGui.TabItemFlags_None ) then       UI.draw_tabs_Sampler_tabs_boundary()    ImGui.EndTabItem( ctx) end 
            if ImGui.BeginTabItem( ctx, 'FX', false, ImGui.TabItemFlags_None ) then             UI.draw_tabs_Sampler_tabs_FX()          ImGui.EndTabItem( ctx) end   
            if ImGui.BeginTabItem( ctx, 'Device', false, ImGui.TabItemFlags_None ) then         UI.draw_tabs_Sampler_tabs_device()      ImGui.EndTabItem( ctx) end
           else
            if ImGui.BeginTabItem( ctx, 'General (3rd party)', false, ImGui.TabItemFlags_None ) then        UI.draw_tabs_Sampler_tabs_3rdpartycontrols()ImGui.EndTabItem( ctx) end
            if ImGui.BeginTabItem( ctx, 'FX', false, ImGui.TabItemFlags_None ) then             UI.draw_tabs_Sampler_tabs_FX()          ImGui.EndTabItem( ctx) end 
            if ImGui.BeginTabItem( ctx, 'Device', false, ImGui.TabItemFlags_None ) then         UI.draw_tabs_Sampler_tabs_device()      ImGui.EndTabItem( ctx) end
          end
          if ImGui.BeginTabItem( ctx, 'Track', false, ImGui.TabItemFlags_None ) then UI.draw_tabs_Sampler_trackparams()  ImGui.EndTabItem( ctx)   end  
        end
        
                  
        ImGui.EndTabBar( ctx)
      end
      --reaper.ImGui_EndChild(ctx)
   -- end
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_tabs_boundary()
    local note_layer_t = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if note_layer_t.TYPE_DEVICE== true then return end
    
    
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
    
    -- loop
    local retval, v = ImGui.Checkbox( ctx, 'Loop', note_layer_t.instrument_loop==1 )
    if retval then TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 12, note_layer_t.instrument_loop~1 ) DATA.upd = true end      
    -- instrument_noteoff
    local retval, v = ImGui.Checkbox( ctx, 'Obey note-off', note_layer_t.instrument_noteoff==1 )
    if retval then TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 11, note_layer_t.instrument_noteoff~1 ) DATA.upd = true end  
    
    -- slice bpm
    local looptempo = note_layer_t.SAMPLEBPM or ''
    if looptempo == 0 then looptempo = reaper.Master_GetTempo() end
    reaper.ImGui_SetNextItemWidth(ctx, 50)
    local retval, buf = reaper.ImGui_InputText( ctx, 'BPM##tempo', looptempo, reaper.ImGui_InputTextFlags_None()|reaper.ImGui_InputTextFlags_CharsDecimal() )
    if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then  
      local track = note_layer_t.tr_ptr
      DATA:WriteData_Child(track, {
        SET_SAMPLEBPM = tonumber(buf),
      }) 
      DATA.upd = true
    end
    
    
    ImGui.SetCursorScreenPos(ctx, curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*2, curposy_abs)
    if ImGui.BeginChild(ctx,'tabsbar_sampler_boundarychild', 0,0,reaper.ImGui_ChildFlags_Border()) then
      if ImGui.BeginTabBar( ctx, '##tabsbar_sampler_boundary', ImGui.TabItemFlags_None ) then 
        
        -- start offset
        if ImGui.BeginTabItem( ctx, 'Start offset##sampler_boundary_Start', false, ImGui.TabItemFlags_None ) then
          local formatIn = DATA.boundarystep[EXT.CONF_stepmode].str
          reaper.ImGui_SetNextItemWidth(ctx, 100)
          local retval, v = reaper.ImGui_SliderInt( ctx, 'Step##shiftboundary', EXT.CONF_stepmode, 0, #DATA.boundarystep, formatIn, ImGui.SliderFlags_None )
          if retval then EXT.CONF_stepmode = v end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
          if EXT.CONF_stepmode == 10 then
            ImGui.SameLine(ctx)
            reaper.ImGui_SetNextItemWidth(ctx, 100)
            local retval, v = reaper.ImGui_SliderDouble( ctx, 'ahead##shiftboundary_ahead', EXT.CONF_stepmode_transientahead, 0, 0.1, '%.3f sec', ImGui.SliderFlags_None )
            if retval then EXT.CONF_stepmode_transientahead = v end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
          end
          local retval, v = ImGui.Checkbox( ctx, 'Keep slice length', EXT.CONF_stepmode_keeplen==1 )
          if retval then EXT.CONF_stepmode_keeplen=EXT.CONF_stepmode_keeplen~1 EXT:save() end  
          
          if EXT.CONF_stepmode ~= 10 then
            if ImGui.Button(ctx, '< Start##movestoffslefthome') then 
              local dir = -1
              DATA:Action_ShiftOffset(note_layer_t, 2, dir) 
            end 
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, '< Move left##movestoffsleft') then  
              local dir = -1
              DATA:Action_ShiftOffset(note_layer_t, 0, dir) 
            end
            ImGui.SameLine(ctx)
          end 
          if ImGui.Button(ctx, 'Move right >##movestoffsright') then 
            local dir = 1
            DATA:Action_ShiftOffset(note_layer_t, 0, dir) 
          end 
          
          ImGui.EndTabItem( ctx) 
        end
        
        -- end offset
        if ImGui.BeginTabItem( ctx, 'End offset##sampler_boundary_end', false, ImGui.TabItemFlags_None ) then
          local formatIn = DATA.boundarystep[EXT.CONF_stepmode].str
          reaper.ImGui_SetNextItemWidth(ctx, 100)
          local retval, v = reaper.ImGui_SliderInt( ctx, 'Step##shiftboundaryenf', EXT.CONF_stepmode, 0, #DATA.boundarystep, formatIn, ImGui.SliderFlags_None )
          if retval then EXT.CONF_stepmode = v end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
          if EXT.CONF_stepmode == 10 then
            ImGui.SameLine(ctx)
            reaper.ImGui_SetNextItemWidth(ctx, 100)
            local retval, v = reaper.ImGui_SliderDouble( ctx, 'ahead##shiftboundary_ahead', EXT.CONF_stepmode_transientahead, 0, 0.1, '%.3f sec', ImGui.SliderFlags_None )
            if retval then EXT.CONF_stepmode_transientahead = v end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end
          end
          local retval, v = ImGui.Checkbox( ctx, 'Keep slice length', EXT.CONF_stepmode_keeplen==1 )
          if retval then EXT.CONF_stepmode_keeplen=EXT.CONF_stepmode_keeplen~1 EXT:save() end  
          
          if EXT.CONF_stepmode ~= 10 then
            if ImGui.Button(ctx, '< Move left##movestoffsleftend') then  
              local dir = -1
              DATA:Action_ShiftOffset(note_layer_t, 1, dir) 
            end
            ImGui.SameLine(ctx)
          end 
          if ImGui.Button(ctx, 'Move right >##movestoffsrightend') then 
            local dir = 1
            DATA:Action_ShiftOffset(note_layer_t, 1, dir) 
          end 
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'End >##moveendoffsrighttoend') then 
            local dir = 1
            DATA:Action_ShiftOffset(note_layer_t, 3, dir) 
          end 
          ImGui.EndTabItem( ctx) 
        end
        
        
        -- tools
        if ImGui.BeginTabItem( ctx, 'Tools##sampler_boundary_Tools', false, ImGui.TabItemFlags_None ) then 
          -- crop sample
          local toolongsample =  note_layer_t.SAMPLELEN and note_layer_t.SAMPLELEN > EXT.CONF_crop_maxlen
          if toolongsample then ImGui.BeginDisabled(ctx,true) end
          if ImGui.Button( ctx, 'Crop sample') then DATA:Action_CropToAudibleBoundaries(note_layer_t) end 
          ImGui.SameLine(ctx)
          ImGui.SetNextItemWidth(ctx, 90) 
          local ret, v = ImGui.SliderDouble( ctx, 'Threshold##cropsplthresh', EXT.CONF_cropthreshold, -80, -10, '%.0f dB', ImGui.SliderFlags_None ) 
          if ret then EXT.CONF_cropthreshold = v end if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then EXT:save() end  -- Sampler: Crop threshold
          if toolongsample then ImGui.EndDisabled(ctx) end 
          
          ImGui.EndTabItem( ctx) 
        end
        ImGui.EndTabBar( ctx)
      end
      ImGui.EndChild(ctx)
    end
  end
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_tabs_sample()
    local note_layer_t = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if note_layer_t.TYPE_DEVICE== true then return end
    
    ImGui.Dummy(ctx,0,0)
    
    if ImGui.Button(ctx, '< Previous spl',UI.calc_sampler4ctrl_W) then DATA:Sampler_NextPrevSample(note_layer_t, 1) end 
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Next spl >',UI.calc_sampler4ctrl_W) then DATA:Sampler_NextPrevSample(note_layer_t, 0) end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Random spl',UI.calc_sampler4ctrl_W) then DATA:Sampler_NextPrevSample(note_layer_t, 2) end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'MediaExplorer',UI.calc_sampler4ctrl_W) then  DATA:Sampler_ShowME() ImGui.CloseCurrentPopup(ctx) end
    
    
    -- database stuff
    local retval, v = ImGui.Checkbox( ctx, 'Use database', note_layer_t.SET_useDB&1==1 )
    if retval then 
      DATA:CollectDataInit_ParseREAPERDB()
      DATA:WriteData_Child(note_layer_t.tr_ptr, { SET_useDB = note_layer_t.SET_useDB~1, SET_useDB_lastID = 0, })  
      DATA.upd = true 
    end 
    
    
    if note_layer_t.SET_useDB&1==1 then  
      -- select db
      ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth(ctx, -1)
      if ImGui.BeginCombo( ctx, '##dbselect', note_layer_t.SET_useDB_name, ImGui.ComboFlags_None ) then
        for dbname in pairs(DATA.reaperDB) do
          if ImGui.Selectable( ctx, dbname, false, ImGui.SelectableFlags_None) then 
            DATA:WriteData_Child(note_layer_t.tr_ptr, {SET_useDB_name = dbname})  
            DATA.upd = true 
          end
        end
        ImGui.EndCombo( ctx )
      end
      
      -- lock
      local retval, v = ImGui.Checkbox( ctx, 'Lock from "New random kit" action', note_layer_t.SET_useDB&2==2 )
      if retval then 
        DATA:WriteData_Child(note_layer_t.tr_ptr, {SET_useDB = note_layer_t.SET_useDB~2})  
        DATA.upd = true 
      end
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx,UI.spacingX,40)
      --ImGui.SameLine(ctx)
      
      -- new kit
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFF000050)
      if ImGui.Button(ctx, 'New random database kit',-30) then  
        Undo_BeginBlock2(DATA.proj )
        DATA:Sampler_NewRandomKit()
        Undo_EndBlock2( DATA.proj , 'RS5k manager - New kit', 0xFFFFFFFF )
      end
      ImGui.PopStyleColor(ctx)
      ImGui.SameLine(ctx)
      UI.HelpMarker('Randomize ALL samples linked to databases in current rack') 
    end
    
  end
  -----------------------------------------------------------------------------------------  
  function UI.draw_tabs_Sampler_tabs_FX()
    local note_layer_t, note = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if note_layer_t.TYPE_DEVICE== true then return end
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
     
    UI.draw_knob(
      {str_id = '##note_layer_fx_reaeq_cut',
      is_small_knob = true,
      val = note_layer_t.fx_reaeq_cut,
      x = curposx_abs, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Freq',
      --knob_resY = 10000,
      val_form = note_layer_t.fx_reaeq_cut_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        DATA:Validate_InitFilterDrive(note_layer_t) 
        if note_layer_t.fx_reaeq_pos then 
          note_layer_t.fx_reaeq_cut =v 
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 0, v ) 
          DATA:CollectData_Children_FXParams(note_layer_t)  
        end
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 0)
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 0, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    
    UI.draw_knob(
      {str_id = '##note_layer_fx_reaeq_gain', 
      is_small_knob = true,
      val =note_layer_t.fx_reaeq_gain,
      x = curposx_abs + UI.calc_knob_w_small + UI.spacingX, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Gain',
      --knob_resY = 10000,
      disabled = (note_layer_t.fx_reaeq_bandtype == -1  or note_layer_t.fx_reaeq_bandtype == 3 or note_layer_t.fx_reaeq_bandtype == 4),
      val_form = note_layer_t.fx_reaeq_gain_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        DATA:Validate_InitFilterDrive(note_layer_t) 
        if note_layer_t.fx_reaeq_pos then 
          note_layer_t.fx_reaeq_gain =v 
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 1, v ) 
          DATA:CollectData_Children_FXParams(note_layer_t)  
        end
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 1)
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 1, v )  
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })

    -- filter
    ImGui.SetCursorScreenPos(ctx,curposx_abs, curposy_abs+ UI.calc_knob_h_small+UI.spacingY)
    
    ImGui.SetNextItemWidth(ctx, UI.calc_knob_w_small*2+UI.spacingX)
    local preview_value = 'Filter OFF'
    if note_layer_t.fx_reaeq_bandenabled == true  then  preview_value = DATA.bandtypemap[note_layer_t.fx_reaeq_bandtype] end
    if ImGui.BeginCombo( ctx, '##filter', preview_value, ImGui.ComboFlags_None ) then
      for band_type_val in spairs(DATA.bandtypemap) do
        local label = DATA.bandtypemap[band_type_val]
        if ImGui.Selectable( ctx, label, p_selected, ImGui.SelectableFlags_None ) then
          DATA:Validate_InitFilterDrive(note_layer_t) 
          if note_layer_t.fx_reaeq_pos then 
            if band_type_val == -1 then 
              TrackFX_SetNamedConfigParm( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 'BANDENABLED0', 0 )
             else
              TrackFX_SetNamedConfigParm( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 'BANDTYPE0', band_type_val )
              TrackFX_SetNamedConfigParm( note_layer_t.tr_ptr, note_layer_t.fx_reaeq_pos, 'BANDENABLED0', 1 )
            end
          end
          DATA.upd = true
        end
      end
      ImGui.EndCombo( ctx)
    end
  
    UI.draw_knob(
      {str_id = '##note_layer_fx_ws_drive', 
      is_small_knob = true,
      val =note_layer_t.fx_ws_drive,
      default_val = 0,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*2, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Drive',
      --knob_resY = 10000,
      val_form = note_layer_t.fx_ws_drive_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        DATA:Validate_InitFilterDrive(note_layer_t) 
        if note_layer_t.fx_ws_pos then 
          note_layer_t.fx_ws_drive =v 
          TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.fx_ws_pos, 0, v ) 
          DATA:CollectData_Children_FXParams(note_layer_t)  
        end
      end,
      })
    
    
    
    
  end
    ----------------------------------------------------------------------------------------- 
  function UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(x,y,note_layer_t,key)
    if not (note_layer_t and note_layer_t.instrument_fx_name) then return end
    local fx_name = note_layer_t.instrument_fx_name
    local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
    
    if not retval then return end
    
    ImGui.SetCursorScreenPos(ctx, x,y)
    if ImGui.Button(ctx, 'Link##'..key, UI.calc_knob_w_small) then
      if not DATA.plugin_mapping[fx_name] then DATA.plugin_mapping[fx_name] = {} end
      DATA.plugin_mapping[fx_name][key] = parm
      DATA:CollectDataInit_PluginParametersMapping_Set() 
      DATA.upd = true
    end
    --
    --DATA.plugin_mapping
  end
    ----------------------------------------------------------------------------------------- 
  function UI.draw_tabs_Sampler_tabs_3rdpartycontrols()
    local note_layer_t,note,layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if not note_layer_t.instrument_pos then return end
    if note_layer_t.ISRS5K then return end
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
    
    UI.draw_knob(
      {str_id = '##spl_vol',
      is_small_knob = true,
      val = note_layer_t.instrument_vol,
      x = curposx_abs, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Gain',
      val_form = note_layer_t.instrument_vol_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v)  
        if not note_layer_t.instrument_volID then return end
        note_layer_t.instrument_vol =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not note_layer_t.instrument_volID then return end
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID)
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_volID')
    
    local xpos = curposx_abs + UI.calc_knob_w_small + UI.spacingX
    UI.draw_knob(
      {str_id = '##note_layer_tune',
      is_small_knob = true,
      val = note_layer_t.instrument_tune,
      x = xpos, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Tune',
      knob_resY = 10000,
      val_form = note_layer_t.instrument_tune_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_tuneID then return end
        note_layer_t.instrument_tune =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_tuneID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      })  
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(xpos,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_tuneID')
    
    UI.draw_knob(
      {str_id = '##note_layer_instrument_attack',
      is_small_knob = true,
      val = note_layer_t.instrument_attack,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Attack',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_attack_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_attackID then return end
        note_layer_t.instrument_attack =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v)    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_attackID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*3,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_attackID')
    
    UI.draw_knob(
      {str_id = '##note_layer_instrument_decay',
      is_small_knob = true,
      val = note_layer_t.instrument_decay,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*4, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Decay',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_decay_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_decayID then return end
        note_layer_t.instrument_decay =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_decayID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*4,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_decayID')
        
    UI.draw_knob(
      {str_id = '##note_layer_instrument_sustain',
      is_small_knob = true,
      val = note_layer_t.instrument_sustain,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*5, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Sustain',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_sustain_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_sustainID then return end
        note_layer_t.instrument_sustain =v
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v)    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_sustainID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*5,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_sustainID')
    
    UI.draw_knob(
      {str_id = '##note_layer_instrument_release',
      is_small_knob = true,
      val = note_layer_t.instrument_release,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*6, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Release',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_release_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        if not note_layer_t.instrument_releaseID then return end
        note_layer_t.instrument_release =v
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        if not note_layer_t.instrument_releaseID then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      }) 
    UI.draw_tabs_Sampler_tabs_3rdpartycontrols_store(curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*6,curposy_abs+UI.calc_knob_h_small+UI.spacingY,note_layer_t,'instrument_releaseID')
  end  
    ----------------------------------------------------------------------------------------- 
  function UI.draw_tabs_Sampler_tabs_rs5kcontrols_tune(note_layer_t, val)
    local note_layer_t,note,layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    
    local out = note_layer_t.instrument_tune + val/160 
    note_layer_t.instrument_tune =v 
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, out )    
    DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
    
  end
    ----------------------------------------------------------------------------------------- 
  function UI.draw_tabs_Sampler_tabs_rs5kcontrols()
    local note_layer_t,note,layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
    if not note_layer_t.instrument_pos then return end
    if not note_layer_t.ISRS5K then return end
    local curposx_abs, curposy_abs = ImGui.GetCursorScreenPos(ctx)
    
    UI.draw_knob(
      {str_id = '##spl_vol',
      is_small_knob = true,
      val = note_layer_t.instrument_vol, 
      default_val = 0.5,
      x = curposx_abs, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Gain',
      val_form = note_layer_t.instrument_vol_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v)  
        note_layer_t.instrument_vol =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values 
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID)
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_volID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      appfunc_atclickR = function(v) if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'rs5k_ctrl' DATA.trig_openpopup_context = 'gain' end  end,
      draw_macro_index = note_layer_t['instrument_volID_MACRO'],
      })
      
    UI.draw_knob(
      {str_id = '##note_layer_tune',
      is_small_knob = true,
      val = note_layer_t.instrument_tune, 
      default_val = 0.5,
      x = curposx_abs + UI.calc_knob_w_small + UI.spacingX, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Tune',
      knob_resY = 10000,
      val_form = note_layer_t.instrument_tune_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_tune =v 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_tuneID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      draw_macro_index = note_layer_t['instrument_tuneID_MACRO'],
      })  
    
    -- tune stuff
      local labelw = 40
      ImGui.SetCursorScreenPos(ctx, curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*2, curposy_abs + UI.spacingY)
      if ImGui.Button(ctx, '-##oct-') then UI.draw_tabs_Sampler_tabs_rs5kcontrols_tune(note_layer_t,-12) end
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, 'oct', labelw)
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, '+##oct+') then UI.draw_tabs_Sampler_tabs_rs5kcontrols_tune(note_layer_t,12) end
      
      ImGui.SetCursorScreenPos(ctx, curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*2, curposy_abs + UI.calc_knob_h_small*1/3 + UI.spacingY)
      if ImGui.Button(ctx, '-##semi-') then UI.draw_tabs_Sampler_tabs_rs5kcontrols_tune(note_layer_t,-1) end
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, 'semi', labelw)
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, '+##semi+') then UI.draw_tabs_Sampler_tabs_rs5kcontrols_tune(note_layer_t,1) end
      
      ImGui.SetCursorScreenPos(ctx, curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*2, curposy_abs + UI.calc_knob_h_small*2/3 + UI.spacingY)
      if ImGui.Button(ctx, '-##cent-') then UI.draw_tabs_Sampler_tabs_rs5kcontrols_tune(note_layer_t,-0.01) end
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, 'cent', labelw)
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, '+##cent+') then UI.draw_tabs_Sampler_tabs_rs5kcontrols_tune(note_layer_t,0.01) end
    
    
    ImGui.SetCursorScreenPos(ctx, curposx_abs , curposy_abs + UI.calc_knob_h_small +  UI.spacingY)
    
    --if ImGui.Checkbox(ctx, 'Tweak ALL samples ',(DATA.VCA_mode or 0 )&1==1) then DATA.VCA_mode = (DATA.VCA_mode or 0 )~1 end
    --if ImGui.Checkbox(ctx, 'Tweak ony current pad layers',(DATA.VCA_mode or 0 )&2==2 or (DATA.VCA_mode or 0 )&1==1) then DATA.VCA_mode = (DATA.VCA_mode or 0 )~2 end
    
    local attmult = 10
    UI.draw_knob(
      {str_id = '##note_layer_instrument_attack',
      is_small_knob = true,
      val = math.min(1,note_layer_t.instrument_attack_norm*attmult), 
      default_val = 0,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*4, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Attack',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_attack_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_attack =v /note_layer_t.instrument_attack_max
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v*note_layer_t.instrument_attack_max/attmult )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_attackID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      appfunc_atclickR = function(v) if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'rs5k_ctrl' DATA.trig_openpopup_context = 'attack' end  end,
      draw_macro_index = note_layer_t['instrument_attackID_MACRO'],
      }) 
    
    local delmult = 40
    UI.draw_knob(
      {str_id = '##note_layer_instrument_decay',
      is_small_knob = true,
      val = math.min(note_layer_t.instrument_decay*delmult,1),
      default_val = 0.5,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*5, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Decay',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_decay_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_decay =v  / delmult
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v/delmult )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_decayID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      appfunc_atclickR = function(v) if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'rs5k_ctrl' DATA.trig_openpopup_context = 'decay' end  end,
      draw_macro_index = note_layer_t['instrument_decayID_MACRO'],
      }) 

        
    UI.draw_knob(
      {str_id = '##note_layer_instrument_sustain',
      is_small_knob = true,
      val =  math.min(1,note_layer_t.instrument_sustain*2),
      default_val = 0.5,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*6, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Sustain',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_sustain_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_sustain =v
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v/2)    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_sustainID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      appfunc_atclickR = function(v) if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'rs5k_ctrl' DATA.trig_openpopup_context = 'sustain' end  end,
      draw_macro_index = note_layer_t['instrument_sustainID_MACRO'],
      }) 


    UI.draw_knob(
      {str_id = '##note_layer_instrument_release',
      is_small_knob = true,
      val = note_layer_t.instrument_release_norm,
      default_val = 0.01,
      x = curposx_abs + (UI.calc_knob_w_small + UI.spacingX)*7, 
      y = curposy_abs,
      w = UI.calc_knob_w_small,
      h = UI.calc_knob_h_small,
      name = 'Release',
      --knob_resY = 10000,
      val_form = note_layer_t.instrument_release_format,
      appfunc_atclick = function(v)   end,
      appfunc_atdrag = function(v) 
        note_layer_t.instrument_release =v /note_layer_t.instrument_release_max
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v*note_layer_t.instrument_release_max )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      parseinput = function(str_in)
        if not str_in then return end
        local v = VF_BFpluginparam(str_in, note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID) 
        TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, note_layer_t.instrument_releaseID, v )    
        DATA:CollectData_Children_InstrumentParams(note_layer_t,true) -- minor refresh formatted values
      end,
      appfunc_atclickR = function(v) if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = 'rs5k_ctrl' DATA.trig_openpopup_context = 'release' end  end,
      draw_macro_index = note_layer_t['instrument_releaseID_MACRO'],
      }) 
            
  end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent() 
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,0) 
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,0) 
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,0) 
  end
  ---------------------------------------------------------------------  
  function UI.Drop_UI_interaction_device(note, layer) 
    -- validate is file or pad dropped
    local retval, count = ImGui.AcceptDragDropPayloadFiles( ctx, 127, ImGui.DragDropFlags_None )
    if not retval then return end
      
    Undo_BeginBlock2(DATA.proj )
    for i = 1, count do 
      local retval, filename = reaper.ImGui_GetDragDropPayloadFile( ctx, i-1 )
      if not retval then return end 
      DATA:DropSample(filename, note + i-1, {layer=layer})
    end 
    Undo_EndBlock2( DATA.proj , 'RS5k manager - drop samples to pads', 0xFFFFFFFF ) 
  
  end
  
  ---------------------------------------------------------------------  
  function UI.Drop_UI_interaction_sampler() 
    -- validate is file or pad dropped
    local retval, count = ImGui.AcceptDragDropPayloadFiles( ctx, 1, ImGui.DragDropFlags_None )
    if not retval then return end
    
    -- drop on sampler
    if DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER then  
      local retval, filename = reaper.ImGui_GetDragDropPayloadFile( ctx, 0 )
      if retval then 
        local note_layer_t, note, layer = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end
        DATA:DropSample(filename, note, {layer=layer})
      end
    end
  end   
  --------------------------------------------------------------------------------
  function UI.draw_tabs_Sampler_tabs_device()
    local note_layer_t, note, layer0 = DATA:Sampler_GetActiveNoteLayer() if not note_layer_t then return end  
    
    
    if not (DATA.children[note] and DATA.children[note].TYPE_DEVICE== true) then ImGui.BeginDisabled(ctx, true) end
      local retval, v = ImGui.Checkbox( ctx, 'Auto-set velocity ranges on add layer', DATA.children[note].TYPE_DEVICE_AUTORANGE )
      if retval then 
        local tr = DATA.children[note].tr_ptr
        local out = 0
        if v == true then out = 1 end
        DATA:WriteData_Child(tr, {SET_MarkType_TYPE_DEVICE_AUTORANGE = out}) 
        DATA.upd = true
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Refresh##autosetvelrange', 80) then DATA:Auto_Device_RefreshVelocityRange(note) end
    if not (DATA.children[note] and DATA.children[note].TYPE_DEVICE== true) then ImGui.EndDisabled(ctx) end
    
    ImGui.SameLine(ctx)
    -- device drop
    ImGui.Button(ctx, '[Drop layers here]', -1)
    if ImGui.BeginDragDropTarget( ctx ) then  
      local cntlayers = 0
      if DATA.children[note] and DATA.children[note].layers then cntlayers = #DATA.children[note].layers end
      UI.Drop_UI_interaction_device(note, cntlayers + 1)   
      ImGui_EndDragDropTarget( ctx )
    end
    
    if ImGui.BeginChild( ctx, 'device' ,0,-UI.spacingY) then--,ImGui.ChildFlags_None, ImGui.WindowFlags_NoScrollWithMouse
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,5)
      
      
      local name_w = 185
      local slider_w = 60
      
      
      --- layers list
      for layer = 1, #DATA.children[note].layers do
        
        local posx,posy = ImGui.GetCursorPos(ctx)
        local layer_t = DATA.children[note].layers[layer]
        
        -- name
        ImGui.SetNextItemWidth(ctx, name_w)
        if ImGui.Checkbox(ctx, '##layer'..layer, layer == layer0) then
          DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = layer
          DATA:WriteData_Parent()
          DATA.upd = true
        end
        ImGui.SameLine(ctx)
        UI.draw_setbuttonbackgtransparent() 
        ImGui.Button(ctx, layer_t.P_NAME..'##layerbut'..layer,  name_w-30)
        ImGui.PopStyleColor(ctx,3)
        
        -- D_VOL
        ImGui.SetCursorPos(ctx,posx+name_w,posy)
        ImGui.SetNextItemWidth(ctx, slider_w)
        local formatIn = layer_t.D_VOL_format
        local retval, v = reaper.ImGui_SliderDouble( ctx, '##layervol'..layer, layer_t.D_VOL, 0, 2, formatIn, ImGui.SliderFlags_None )
        if retval then SetMediaTrackInfo_Value( layer_t.tr_ptr, 'D_VOL',v ) DATA.upd = true end
        ImGui.SameLine(ctx)
        
        -- D_PAN
        ImGui.SetNextItemWidth(ctx, slider_w)
        local formatIn = layer_t.D_PAN_format
        local retval, v = reaper.ImGui_SliderDouble( ctx, '##layerpan'..layer, layer_t.D_PAN, -1,1, formatIn, ImGui.SliderFlags_None )
        if retval then SetMediaTrackInfo_Value( layer_t.tr_ptr, 'D_PAN',v ) DATA.upd = true end
        ImGui.SameLine(ctx)
        
        -- solo
        if layer_t.I_SOLO>0 then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x00FF00FF ) end
        if ImGui.Button(ctx, 'S##layerS'..layer, 23)  then 
          Undo_BeginBlock2(DATA.proj )
          local outval = 2 if layer_t.I_SOLO>0 then outval = 0 end SetMediaTrackInfo_Value( layer_t.tr_ptr, 'I_SOLO', outval ) DATA.upd = true
          Undo_EndBlock2( DATA.proj , 'RS5k manager - Solo pad', 0xFFFFFFFF ) 
        end 
        if layer_t.I_SOLO>0 then ImGui.PopStyleColor(ctx ) end
          
        -- mute
        ImGui.SameLine(ctx)
        if layer_t.B_MUTE>0 then ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFF0000FF ) end
        if ImGui.Button(ctx, 'M##layerM'..layer, 23)  then
          Undo_BeginBlock2(DATA.proj )
          SetMediaTrackInfo_Value( layer_t.tr_ptr, 'B_MUTE', layer_t.B_MUTE~1 ) DATA.upd = true
          Undo_EndBlock2( DATA.proj , 'RS5k manager - Mute pad', 0xFFFFFFFF )         
        end
        if layer_t.B_MUTE>0 then ImGui.PopStyleColor(ctx ) end
        
        -- remove
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'X##layerem'..layer, -1) then DATA:Sampler_RemovePad(note,layer) end
        
      end
      
      
      -- device drop FX
      local cntlayers = 0
      if DATA.children[note] and DATA.children[note].layers then cntlayers = #DATA.children[note].layers end
      local drop_data = {layer = cntlayers + 1}
      UI.draw_3rdpartyimport_context(note,drop_data) 
      
      
      ImGui.PopStyleVar(ctx,2)  
      ImGui.EndChild( ctx)
    end
  end
  --------------------------------------------------------------------------------   
  function _main_LoadLibraries()
    local info = debug.getinfo(1,'S');  
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]]) 
    dofile(script_path .. "mpl_RS5K_manager_functions.lua")
  end
  -----------------------------------------------------------------------------------------  
  function mpl_FixExtStateINI()
    -- IO
      local val = reaper.GetExtState( 'MPL_Scripts', 'INI_fix' )
      val = tonumber(val) or 0
      if val==1 then return end -- if this configuration is not fixed yet
      
      local fn = reaper.get_ini_file():lower()
      local fn_ext = fn:gsub('reaper%.ini', 'reaper-extstate.ini' )
      if not reaper.file_exists(fn_ext) then return end
      local content
      local f=io.open(fn_ext,'rb')
      if f then
        content = f:read('a')
        f:close()
      end
      if not content then return end 
    
    -- print chunk to table
      t = {} local i = 0 for line in content:gmatch('[^\r\n]+') do i=i+1 t[i]=line end local sz=#t
    
    -- modify chunk
      lines_cache = {}
      for i = sz,1,-1 do
        local cond
        local line = t[i] 
        local line_exist
        if lines_cache[line] then line_exist = true end
        lines_cache[line] = true
        local line_is_section = line:match('%[(.-)%]')~=nil and line:match('=') == nil
        local emptyline = line:match('%s+')==line
        local key,value = line:match('([%_%a%d]+)%=(.*)')
        local missedkv = not (key and value) and line~='[MPL_RS5K manager]'
        local key_is_number = key and key:match('[%_%d]+')==key 
        if (emptyline==true or missedkv==true or key_is_number == true or line_exist == true) and line_is_section~=true then table.remove(t,i) end
      end 
      local chunk_new = table.concat(t,'\n')  
    
    -- backup
      local fn_ext_backup = fn_ext..'-backup'
      if not reaper.file_exists(fn_ext_backup) then
        local f=io.open(fn_ext_backup,'wb')
        if f then
          f:write(content)
          f:close()
        end
      end
    
    -- write chunk_new
      local f=io.open(fn_ext,'wb')
      if f then
        content = f:write(chunk_new)
        f:close()
      end
    
    reaper.SetExtState( 'MPL_Scripts', 'INI_fix', 1, false  ) -- refresh state
    reaper.SetExtState( 'MPL_Scripts', 'INI_fix', 1, true  ) -- print persistently 
    
    
  end
  ------------------------------------------------------------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end 
  -----------------------------------------------------------------------------------------  
  function _main() 
    _main_LoadLibraries()
    
    -- get sequencer ID
    for idx =0, 1000000 do
      local retval, name = reaper.kbd_enumerateActions( section, idx )
      if not ( retval and retval~= 0) then return end
      if name:match('mpl_') and name:match('RS5k') and name:match('StepSeq') then
        DATA.stepseq_ID = retval
        break
      end
    end
    
    -- load functions
    
    
    local loadtest = time_precise()
    
    gmem_attach('RS5K_manager')
    gmem_write(1026, 1) -- rs5k manager opened
    
    DATA.REAPERini = VF_LIP_load( reaper.get_ini_file()) 
    DATA:CollectDataInit_MIDIdevices()  
    DATA:CollectDataInit_ParseREAPERDB()  
    DATA.loadtest = time_precise() - loadtest -- measure load databases
    
    UI.MAIN_definecontext()   -- + EXT:load
    
    -- after EXT:load
    DATA:CollectDataInit_PluginParametersMapping_Get() 
    DATA:CollectDataInit_ReadDBmaps()
    DATA:CollectDataInit_LoadCustomPadStuff()
    DATA:CollectDataInit_LoadCustomLayouts()
    DATA:CollectDataInit_EnumeratePlugins()
    --mpl_FixExtStateINI()
  end 
    -----------------------------------------------------------------------------------------       
  _main()
   

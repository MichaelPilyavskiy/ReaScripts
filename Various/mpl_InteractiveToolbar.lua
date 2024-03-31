-- @description InteractiveToolbar
-- @version 2.33
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about This script displaying some information about different objects, also allow to edit them quickly without walking through menus and windows. For widgets editing purposes see Menu > Help.
-- @provides
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_basefunc.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_GUI.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_DataUpdate.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_MOUSE.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Item.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Envelope.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Persist.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Track.lua
--    mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_MIDIEditor.lua
-- @changelog
--    + Widgets / Item: #itemcomlen difference between fisrt and last of selected items

    local vrs = '2.33'

    local info = debug.getinfo(1,'S');
    local script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
    
    
    
  function RefreshExternalLibs()
    wheel_override = 1
    -- lua example by Heda -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Files/Require%20external%20files%20for%20the%20script.lua
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_basefunc.lua")
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_GUI.lua")
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_DataUpdate.lua")
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_MOUSE.lua") 
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Item.lua")
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Envelope.lua")
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Persist.lua")
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_Track.lua")
    dofile(script_path .. "mpl_InteractiveToolbar_functions/mpl_InteractiveToolbar_Widgets_MIDIEditor.lua")
  end
  RefreshExternalLibs()
  
  
  -- NOT reaper NOT gfx
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  local conf = {} 
  local scr_title = 'InteractiveToolbar'
   data = {conf_path = script_path:gsub('\\ ','/') .. "mpl_InteractiveToolbar_Config.ini",
          vrs = vrs,
          scr_title=scr_title,
          masterdata = {ptr =  GetMasterTrack(reaper.EnumProjects(-1))}}
   
  local mouse = {}
  local obj = {}
  local  widgets = {    -- map types to data.obj_type_int order
              types_t ={'EmptyItem',
                        'MIDIItem',
                        'AudioItem',
                        'MultipleItem',
                        nil,--'EnvelopePoint',
                        nil,--'MultipleEnvelopePoints',
                        'Envelope',
                        'Track', 
                        'MIDIEditor',
                        'Persist'
                        }
                  }
  local cycle_cnt,clock = 0
  --local SCC, SCC_trig, lastSCC
  local lastcur_pos
  local last_FormTS
  local lastTS_st, lastTSend
  local lastint_playstate
  local last_Sel_env 
  local last_ProjGid
  local last_gfxx, last_gfxy, last_gfxw, last_gfxh, last_dock
  local widgets_def = {}
  local lastTapTS
  ---------------------------------------------------
  
  
  function Config_DefaultStr()
    return [[
//Configuration for MPL Interactive Toolbar
[EmptyItem]
order=#color #position #length #itemcomlen
[MIDIItem]
order=#color #buttons#snap #position #leftedge #endedge #length #offset #vol #transpose #pan #srclen #rate #itemcomlen
buttons=#lock #loop #mute 
[AudioItem]
order=#color #buttons #snap #position #leftedge #endedge #length #offset #fadein #fadeout #vol #transpose #pan #srclen #rate #itemcomlen
buttons=#lock #preservepitch #loop #mute #chanmode #srcreverse #bwfsrc #timebase 
[MultipleItem]
order=#color #buttons #position #leftedge #endedge #length #offset #fadein #fadeout #vol #transpose #pan #srclen #rate #itemcomlen
buttons=#lock #preservepitch #chanmode #loop #srcreverse #mute   
[Envelope]
order=#floatfx #position #value #AIlooplen
[Track]
order=#color #fxcontrols #buttons #vol #pan #fxlist #sendto #delay #troffs #chsendmixer #chrecvmixer #freeze
buttons=#polarity #parentsend #midiin #audioin #numchan
[MIDIEditor]
order=#position #notelen #CCval #notepitch #notevel #midichan
[Persist]
order=#swing #grid #timesellen #timeselend #timeselstart #timeselLeftEdge #lasttouchfx #transport #bpm #clock #tap #master #mastermeter #masterchan #chordlive #mchancnt
]]
  end  
  ---------------------------------------------------
  function ExtState_Def() 
    return {ES_key = 'MPL_'..scr_title,
            scr_title = 'InteractiveToolbar',
            wind_x =  50,
            wind_y =  50,
            wind_w =  200,
            wind_h =  300,
            dock =    0,
            lastdockID = 0,
            
            runnatAPI = 0,
            dock_orientation = 0,
            
            GUI_font1 = 17,
            GUI_font2 = 15,
            GUI_font3 = 32, -- clock
            GUI_font4 = 14, -- grid rel / line
            GUI_colortitle =      16768407, -- blue
            GUI_background_col =  16777215, -- white
            GUI_background_alpha = 0.18,
            GUI_contextname_w = 200, --px
            ruleroverride = -1,
            pitch_format = 0,
            oct_shift = 2,
            always_use_x_axis = 0,
            use_context_specific_conditions = 0,
            persist_clock_showtimesec = 0,
            scaling = 1,
            state_contrast = 0.75,
             
            MM_doubleclick = 0,
            MM_rightclick = 0,
            MM_grid_rightclick = 0,
            MM_grid_doubleclick = 0,
            MM_grid_ignoreleftdrag = 0,
            MM_grid_default_reset_grid = 0.25,
            MM_grid_default_reset_MIDIgrid = 0.25,
            
            tap_quantize = 0,
            trackfxctrl_use_brutforce = 0, 
            ignore_context = 0,
            --use_aironCS = 0, -- track
            --use_aironCS_item = 0, 
            use_custom_color_editor = '', 
            timiselwidgetsformatoverride = -2,
            master_buf = 100,
            relative_it_len = 0,
            trackvol_slider = 1,
            miditake_forceMEcontext = 0,
            
            
            actiononchangecontext_item = '',
            actiononchangecontext_itemM = '',
            actiononchangecontext_itemA = '',
            actiononchangecontext_track = '',
            actiononchangecontext_env = '',
            actiononchangecontext_ME = '',
            actiononchangecontext_no = '',
            
            defsend_chansrc = 0,
            defsend_chandest = 0,
            
            customname_map = '"TimeSelLEdge=TS L Edge" "TimeSelEnd=TS End" "TimeSelLen=TS Len" "TimeSelStart=TS Pos"',
            }
            
  end
  ---------------------------------------------------
  function Run() 
    -- global clock/cycle
      clock = os.clock()
      cycle_cnt = cycle_cnt+1      
    -- update dynamic data
      DataUpdate2(data, mouse, widgets, obj, conf)
    -- check is something happen 
      SCC =  GetProjectStateChangeCount( 0 )       
      SCC_trig = (lastSCC and lastSCC ~= SCC) or cycle_cnt == 1
      lastSCC = SCC       
      
      
      --if not SCC_trig and HasCurPosChanged() then msg(11)  SCC_trig = true end
      if not SCC_trig and HasTimeSelChanged() then SCC_trig = true end -- and (lastSCC_trig and lastSCC_trig == false) 
      if not SCC_trig and HasRulerFormChanged() then SCC_trig = true end    
      if not SCC_trig and HasPlayStateChanged() then SCC_trig = true end 
      if not SCC_trig and HasSelEnvChanged() then SCC_trig = true end  
      if not SCC_trig and HasGridChanged() then SCC_trig = true end      
      local ret =  HasWindXYWHChanged(obj) 
      
      
      if ret == 1 then  
        redraw = 2  
        if conf.dock > 0 then conf.lastdockID = conf.dock end 
        ExtState_Save(conf)  
       elseif  ret == 2 then  
        if conf.dock > 0 then conf.lastdockID = conf.dock end 
        ExtState_Save(conf)  
      end
    -- perf mouse
      local SCC_trig2 = MOUSE(obj,mouse, clock) 
      
      if gmem_read(1) == 1 then
        gmem_write(1, 0)
        SCC_trig = true
      end
      
    -- produce update if yes
      if redraw == 2 or SCC_trig2 then 
        DataUpdate(data, mouse, widgets, obj, conf) redraw = 1 
       elseif SCC_trig then 
        DataUpdate(data, mouse, widgets, obj, conf)
        redraw = 1      
      end 
      
    -- data constant upd
      data.playcur_pos =  GetPlayPositionEx( 0 )
      local playcur_pos_format =  format_timestr_pos( data.playcur_pos, '', data.ruleroverride )
      local playcur_pos_format2 =  format_timestr_pos( data.playcur_pos, '', 0 )
      if data.persist_clock_showtimesec >0 then -- SEE GUI_Main
        data.playcur_pos_format = playcur_pos_format..' / '..playcur_pos_format2
       else
        data.playcur_pos_format = playcur_pos_format
      end
      
      lastSCC_trig = SCC_trig
      
    -- perf GUI 
      GUI_Main(obj, cycle_cnt, redraw, data, clock, conf)
      redraw = 0 
    -- perform shortcuts
      GUI_shortcuts(gfx.getchar())
    -- defer cycle   
      force_exit = force_exit or reaper.gmem_read(1000) == 1
      if gfx.getchar() >= 0 and not force_exit then reaper.gmem_write(1000,0) defer(Run) else atexit(gfx.quit) end  
  end


  ---------------------------------------------------------------------
  function main()
    ExtState_Load(conf) 
      local OS = reaper.GetOS()
      font_coeff = 1
      scale = 1
      gfx.init('MPL InteractiveToolbar',conf.wind_w, conf.wind_h,  conf.dock , conf.wind_x, conf.wind_y)
    --[[https://forum.cockos.com/showpost.php?p=2493416&postcount=40
      scale, gfx.ext_retina, font_coeff = 1, 1, 1 -- init with 1 
      gfx.init('MPL InteractiveToolbar',conf.wind_w, conf.wind_h,  conf.dock , conf.wind_x, conf.wind_y)
      if scale ~= gfx.ext_retina then -- dpi changed (either initially or from the user moving the window or the OS changing
        scale = gfx.ext_retina
        font_coeff = (1+scale)*0.5
        -- Resize manually gfx window, if not MacOS
        if OS ~= "OSX64" and OS ~= "OSX32" and OS ~= "macOS-arm64" then
          gfx.init('MPL InteractiveToolbar',conf.wind_w*scale, conf.wind_h*scale,  conf.dock , conf.wind_x, conf.wind_y)
        end
      end]]
    
    
    obj = Obj_init(conf)
    Config_ParseIni(data.conf_path, widgets)
    Run()
  end 
  ---------------------------------------------------   
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.57) if ret then local ret2 = VF_CheckReaperVrs(5.97,true) if ret2 then reaper.gmem_attach('MPLInterToolbar')  main() end end

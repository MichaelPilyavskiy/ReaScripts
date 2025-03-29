-- @description Randomize Track FX parameters
-- @version 3.54
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=233358
-- @changelog
--    # allow resize window




vrs = 3.54
--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3.2'
     
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 640,
          viewport_posH = 480, 
          
          -- filter
          CONF_defaultkeywords = '',
          CONF_defaultkeywords_use = 0,
          CONF_defaultuntitled_pass = 0,
          CONF_defaultstrings_pass = 1,
          CONF_defaulttoggle_pass = 1,
          
          CONF_defaultkeywordsexclude = '',
          CONF_defaultkeywordsexclude_use = 0,
          
          -- other 
          CONF_smooth = 0, -- seconds
          
          CONF_pluginfilter_b64 = '',
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          ES_key = 'mpl_randomizefxparams',
          UI_name = 'Randomize FX parameters', 
          upd = true, 
          
          FX = {},
          morphstate = 0,
          morph_value = 0,
          morph_value2 = 0,
          
          FX_filter = {},
          currentsnapshot = 0,
          sourcesnapshot = 0,
          
          srcstr='', 
          srcid=0, 
          deststr='', 
          destid = 0,
          
          }
          
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
            -- font
              font='Arial',
              font1sz=15,
              font2sz=13,
            -- mouse
              hoverdelay = 0.8,
              hoverdelayshort = 0.8,
            -- size / offset
              spacingX = 4,
              spacingY = 3,
            -- colors / alpha
              main_col = 0x7F7F7F, -- grey
              textcol = 0xFFFFFF,
              textcol_a_enabled = 1,
              textcol_a_disabled = 0.5,
              but_hovered = 0x878787,
              windowBg = 0x303030,
          }


    UI.col_maintheme = 0x00B300 
    UI.w_min = 530
    UI.h_min = 300          
    UI.main_buth = 60
  
  
  
  
  
  
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
    
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      window_flags = window_flags | ImGui.WindowFlags_MenuBar
      --window_flags = window_flags | ImGui.WindowFlags_NoMove()
      --window_flags = window_flags | ImGui.WindowFlags_NoResize
      window_flags = window_flags | ImGui.WindowFlags_NoCollapse
      --window_flags = window_flags | ImGui.WindowFlags_NoNav()
      --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
      window_flags = window_flags | ImGui.WindowFlags_NoDocking
      window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings()
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
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
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,20)
    -- size
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,20)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,UI.w_min,UI.h_min)
    -- align
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,0.5,0.5)
      
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
      ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,         UI.Tools_RGBA(UI.windowBg, 1))
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      --ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      w,h = 480,430
      --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font1) 
      local rv,open = ImGui.Begin(ctx, DATA.UI_name..' '..vrs..'##'..DATA.UI_name, open, window_flags) 
      if rv then
        local Viewport = ImGui.GetWindowViewport(ctx)
        DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
        DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
        DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
        
      -- calc stuff for childs
        UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
        UI.calc_itemH = calcitemh + frameh * 2
        UI.calc_butW = math.floor(DATA.display_w - UI.spacingX*3)/2
        UI.calc_table_paramnameW = math.floor((DATA.display_w - UI.spacingX*2)/3)
        UI.calc_table_valW = math.floor(((DATA.display_w - UI.spacingX*2) - ((DATA.display_w - UI.spacingX*2)/3)) / 3)
        UI.calc_butW_print = (UI.calc_butW- UI.spacingX) / 2
      -- draw stuff
        UI.draw()
        ImGui.Dummy(ctx,0,0) 
        ImGui.End(ctx)
      end 
      
      ImGui.PopStyleVar(ctx, 22) 
      ImGui.PopStyleColor(ctx, 23) 
      ImGui.PopFont( ctx ) 
      if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
    
      return open
  end
  -------------------------------------------------------------------------------- 
  function UI.Tools_RGBA(col, a_dec)if not col then return 0 else return col<<8|math.floor(a_dec*255) end  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_UIloop() 
    DATA.clock = os.clock()
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
     
    if DATA.morphstate == 1 then DATA:Action_Morph_SetParameters() end
    
    if DATA.upd == true then DATA:CollectData() end 
    DATA.upd = false
    
    -- draw UI
    if not reaper.ImGui_ValidatePtr( ctx, 'ImGui_Context*') then UI.MAIN_definecontext() end
    UI.open = UI.MAIN_styledefinition(true) 
    
    -- handle xy
    DATA:handleViewportXYWH()
    -- data
    if UI.open then defer(UI.MAIN_UIloop) end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext()
    
    EXT:load() 
    
    -- imgUI init
    ctx = ImGui.CreateContext(DATA.UI_name) 
    -- fonts
    DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
    DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
    --DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
    -- config
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
    
    
    -- run loop
    defer(UI.MAIN_UIloop)
  end
  -------------------------------------------------------------------------------- 
  function EXT:save() 
    if not DATA.ES_key then return end 
    for key in pairs(EXT) do 
      if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
        SetExtState( DATA.ES_key, key, EXT[key], true  ) 
      end 
    end 
    EXT:load()
  end
  -------------------------------------------------------------------------------- 
  function EXT:load() 
    if not DATA.ES_key then return end
    for key in pairs(EXT) do 
      if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
        if HasExtState( DATA.ES_key, key ) then 
          local val = GetExtState( DATA.ES_key, key ) 
          EXT[key] = tonumber(val) or val 
        end 
      end  
    end 
    DATA.upd = true
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleViewportXYWH()
    if not (DATA.display_x and DATA.display_y) then return end 
    if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
    if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
    if not DATA.display_w_last then DATA.display_w_last = DATA.display_w end
    if not DATA.display_h_last then DATA.display_h_last = DATA.display_h end
    
    if  DATA.display_x_last~= DATA.display_x 
      or DATA.display_y_last~= DATA.display_y 
      or DATA.display_w_last~= DATA.display_w 
      or DATA.display_h_last~= DATA.display_h 
      then 
      DATA.display_schedule_save = os.clock() 
    end
    if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
      EXT.viewport_posX = DATA.display_x
      EXT.viewport_posY = DATA.display_y
      EXT.viewport_posW = DATA.display_w
      EXT.viewport_posH = DATA.display_h
      EXT:save() 
      DATA.display_schedule_save = nil 
    end
    DATA.display_x_last = DATA.display_x
    DATA.display_y_last = DATA.display_y
    DATA.display_w_last = DATA.display_w
    DATA.display_h_last = DATA.display_h
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
    local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
    local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
  end
  --------------------------------------------------------------------------------  
  function UI.draw_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent() 
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0 )
  end
  --------------------------------------------------------------------------------  
  function UI.draw_menu() 
    if ImGui.BeginMenuBar( ctx ) then
      if ImGui.BeginMenu( ctx, '   Settings   ##Settings' ) then
      
        local retval, v = ImGui.SliderDouble( ctx, 'Smooth transition', EXT.CONF_smooth, 0, 10, '%.2fs', ImGui.SliderFlags_None)
        if retval then EXT.CONF_smooth = v EXT:save() end
        
        ImGui.SeparatorText(ctx, 'Filter defaults')
        -- keywords
        local retval, v = reaper.ImGui_Checkbox( ctx, '##defkeywords_use', EXT.CONF_defaultkeywords_use==1 ) if retval then 
          local out = 0
          if v == true then out = 1 end
          EXT.CONF_defaultkeywords_use = out
          EXT:save()
        end
        ImGui.SameLine(ctx)
        -- keywords string
        local retval, buf = reaper.ImGui_InputText( ctx, 'keywords exist##deffiltertxt', EXT.CONF_defaultkeywords, ImGui.InputTextFlags_None )
        if retval then 
          EXT.CONF_defaultkeywords = buf
          EXT:save()
        end
        -- empty / untitled / reserv
        local retval, v = reaper.ImGui_Checkbox( ctx, 'Pass untitled##defuntitled_pass', EXT.CONF_defaultuntitled_pass==1 ) if retval then 
          local out = 0
          if v == true then out = 1 end
          EXT.CONF_defaultuntitled_pass = out
          EXT:save()
        end 

        -- empty / untitled / reserv
        local retval, v = reaper.ImGui_Checkbox( ctx, 'Pass strings##defuntitled_pass', EXT.CONF_defaultstrings_pass==1 ) if retval then 
          local out = 0
          if v == true then out = 1 end
          EXT.CONF_defaultstrings_pass = out
          EXT:save()
        end 

        -- toggle
        local retval, v = reaper.ImGui_Checkbox( ctx, 'Pass toggle##deftoggle_pass', EXT.CONF_defaulttoggle_pass==1 ) if retval then 
          local out = 0
          if v == true then out = 1 end
          EXT.CONF_defaulttoggle_pass = out
          EXT:save()
        end
        
        
        ImGui.EndMenu( ctx )
      end
      
      
      -- plug data
      local txt = '[open plugin, then press "Print"]'
      
      
      if DATA.FX and DATA.FX.trname and DATA.FX.FXname_short and DATA.FX.cnt_params_filtered and DATA.FX.cnt_params and DATA.FX.cnt_params_active then 
        txt = DATA.FX.trname..' | '..DATA.FX.FXname_short..' | '..DATA.FX.cnt_params..' parameters, '..DATA.FX.cnt_params_filtered..' filtered, '..DATA.FX.cnt_params_active..' active'
      end
      ImGui.Text(ctx, txt) 
      
      ImGui.EndMenuBar( ctx )
    end
  end
  --------------------------------------------------------------------------------  
  function DATA:Filter_Change(i, v, randmin, randmax) 
    local plugname = DATA.FX.FXname
    if not DATA.FX_filter[plugname] then DATA.FX_filter[plugname] = {} end
    if not DATA.FX_filter[plugname][i] then DATA.FX_filter[plugname][i] = {} end 
    if type(DATA.FX_filter[plugname][i]) == 'number' then DATA.FX_filter[plugname][i] = {val = DATA.FX_filter[plugname][i]} end
    
    if v == true then
      DATA.FX_filter[plugname][i].val = nil
     elseif v == false then
      DATA.FX_filter[plugname][i].val = 0
    end
    
    if randmin and randmax then 
      DATA.FX_filter[plugname][i].randmin = randmin 
      DATA.FX_filter[plugname][i].randmax = randmax
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_list()  
    if not (DATA.FX and DATA.FX.valid == true) then return end
    local plugname = DATA.FX.FXname
    ImGui.PushFont(ctx, DATA.font2) 
    if ImGui.BeginChild( ctx, '##paramlist', -1, -1, ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then
      UI.calc_table_valW = math.floor(((DATA.display_w - UI.spacingX*2) - ((DATA.display_w - UI.spacingX*2)/3)) / 3)
      local outer_size_w = 0
      local outer_size_h = 0
      local inner_width = 0
      if ImGui.BeginTable(ctx, '##paramlisttable', 4, ImGui.TableFlags_None|ImGui.TableFlags_SizingFixedFit|ImGui.TableFlags_SizingStretchProp, outer_size_w, outer_size_h, inner_width) then
        ImGui.TableSetupColumn(ctx, 'Param name', ImGui.TableColumnFlags_None, UI.calc_table_paramnameW, 0)
        ImGui.TableSetupColumn(ctx, 'Value (format)', ImGui.TableColumnFlags_None, UI.calc_table_valW, 1)
        ImGui.TableSetupColumn(ctx, 'Rand min', ImGui.TableColumnFlags_None, UI.calc_table_valW, 2)
        ImGui.TableSetupColumn(ctx, 'Rand max', ImGui.TableColumnFlags_None, UI.calc_table_valW, 3)
        ImGui.TableHeadersRow(ctx)
        local sz = #DATA.FX.params
        for i = 1, sz do
          if DATA.FX.params[i].match_filter ~=true  then goto skipnextparam end
          
          ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None, 0)
          ImGui.TableSetColumnIndex(ctx,0)
          if DATA.FX.params[i].ignore==true then ImGui.BeginDisabled( ctx, true ) end 
          local ret, v = ImGui.Checkbox(ctx, DATA.FX.params[i].name , DATA.FX.params[i].active == true)
          if ret then
            DATA:Filter_Change(i, v) 
            DATA:Filter_Save() 
            DATA:Action_PrintPluginState_UpdateFXData()  
            DATA:Filter_RefreshCountActive()
          end
          if DATA.FX.params[i].ignore==true then ImGui.EndDisabled( ctx) end
          
          ImGui.TableSetColumnIndex(ctx,1)
          local value_init = math.floor(DATA.FX.params[i].value_init*1000)/1000
          ImGui.Text(ctx,DATA.FX.params[i].formatparam..' / '..value_init)
          
          
          ImGui.TableSetColumnIndex(ctx,2)
          local v1 = 0
          if DATA.FX_filter[plugname] and DATA.FX_filter[plugname][i] and type(DATA.FX_filter[plugname][i]) == 'table' and DATA.FX_filter[plugname][i].randmin then v1 = DATA.FX_filter[plugname][i].randmin end
          local v_speed = 1.0
          local v_min = 0
          local v_max= 1
          local format = "%.3f"
          local retval, v1 = ImGui.SliderDouble(ctx, '##paramlisttable_limitsmin'..i, v1,  v_min, v_max, format, ImGui.SliderFlags_None)
          if retval then 
            if not DATA.FX_filter[plugname]then DATA.FX_filter[plugname]= {} end
            if not DATA.FX_filter[plugname][i] then DATA.FX_filter[plugname][i] = {} end
            if type(DATA.FX_filter[plugname][i]) == 'number' then DATA.FX_filter[plugname][i] = {} end
            DATA:Filter_Change(i, nil, v1,DATA.FX_filter[plugname][i].randmax or 1) 
          end
          if ImGui.IsItemDeactivatedAfterEdit( ctx ) then DATA:Filter_Save()  end
          
          ImGui.TableSetColumnIndex(ctx,3)
          local v1 = 1
          if DATA.FX_filter[plugname] and DATA.FX_filter[plugname][i] and type(DATA.FX_filter[plugname][i]) == 'table' and DATA.FX_filter[plugname][i].randmax then v1 = DATA.FX_filter[plugname][i].randmax end
          local v_speed = 1.0
          local v_min = 0
          local v_max= 1
          local format = "%.3f"
          local retval, v1 = ImGui.SliderDouble(ctx, '##paramlisttable_limitsmax'..i, v1,  v_min, v_max, format, ImGui.SliderFlags_None)
          if retval then 
            if not DATA.FX_filter[plugname]then DATA.FX_filter[plugname]= {} end
            if not DATA.FX_filter[plugname][i] then DATA.FX_filter[plugname][i] = {} end
            if type(DATA.FX_filter[plugname][i]) == 'number' then DATA.FX_filter[plugname][i] = {} end
            DATA:Filter_Change(i, nil, DATA.FX_filter[plugname][i].randmin or 0, v1) 
          end
          if ImGui.IsItemDeactivatedAfterEdit( ctx ) then DATA:Filter_Save()  end
          
          --[[if DATA.FX.params[i].value_morph and DATA.FX.params[i].value_morph[1] then 
            ImGui.TableSetColumnIndex(ctx,2)
            local val  = math.floor(DATA.FX.params[i].value_morph[1]*1000)/1000
            ImGui.Text(ctx,val)
          end
          
          if DATA.FX.params[i].value_morph and DATA.FX.params[i].value_morph[2] then 
            ImGui.TableSetColumnIndex(ctx,3)
            local val  = math.floor(DATA.FX.params[i].value_morph[2]*1000)/1000
            ImGui.Text(ctx,val)
          end]]
          
          
          
          ::skipnextparam::
        end
        
        ImGui.EndTable(ctx)
      end
      
      ImGui.EndChild( ctx)
    end
    ImGui.PopFont(ctx)
  end
  --------------------------------------------------------------------------------  
  function UI.draw()  
    UI.draw_menu()  
    
    if ImGui.Button(ctx, 'Print state A',UI.calc_butW_print,UI.main_buth) then DATA:Action_PrintPluginState(1) DATA.morph_value2 = 0 end
    ImGui.SameLine(ctx) if ImGui.Button(ctx, 'Print state B',UI.calc_butW_print,UI.main_buth) then DATA:Action_PrintPluginState(2) DATA.morph_value2 = 1 end
    ImGui.SameLine(ctx) if ImGui.Button(ctx, 'Morph',UI.calc_butW,UI.main_buth) then DATA:Action_Morph() end
    
    ImGui_SetNextItemWidth( ctx, UI.calc_butW )
    local retval, v = ImGui.SliderDouble( ctx, '##manchangestate', DATA.morph_value2, 0, 1, 'State morph: %.2f%', ImGui.SliderFlags_None)
    if retval then 
      DATA.morph_value2= v 
      
      DATA.srcstr = 'value_print'
      DATA.srcid = 1
      DATA.deststr = 'value_print'
      DATA.destid = 2
      
      DATA:Action_Morph_SetParameters(true, true) 
    end
    
    
    ImGui.SameLine(ctx) 
    ImGui_SetNextItemWidth( ctx, UI.calc_butW )
    local retval, v = ImGui.SliderDouble( ctx, '##manchange', DATA.morph_value, 0, 1, 'Morph change: %.2f%', ImGui.SliderFlags_None)
    if retval then DATA.morph_value = v DATA:Action_Morph_SetParameters(true) end
    
    UI.draw_filter() 
    
    UI.draw_list()  
  end
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:Action_ApplyFilter_SelectAll(bool)
    if not (DATA.FX and DATA.FX.valid==true) then return end  
    for i = 1,DATA.FX.cnt_params do 
      if DATA.FX.params[i].match_filter == true then DATA:Filter_Change(i, bool)  end
    end
    DATA:Filter_Save() 
    DATA:Action_PrintPluginState_UpdateFXData()
  end
  ---------------------------------------------------------------------------------------------------------------------
  function UI.draw_filter() 
    if not (DATA.FX and DATA.FX.valid==true) then return end 
     
    local FXname = DATA.FX.FXname
    if not DATA.FX_filter[FXname] then DATA.FX_filter[FXname] = {} end
    
    local colW = 150
    if ImGui.BeginChild( ctx, '##filtersection', 0, 150, ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then
      
      ImGui.Text(ctx,'Filter')
      
      local posx, posy = ImGui.GetCursorPos(ctx)
      if ImGui.Button(ctx, 'Show all', colW) then 
        for i = 1,DATA.FX.cnt_params do DATA.FX.params[i].match_filter =true end 
        DATA:Filter_RefreshCountActive() 
      end
      if ImGui.Button(ctx, 'Select all', colW) then 
        DATA:Action_ApplyFilter_SelectAll(true) 
        DATA:Filter_RefreshCountActive() 
      end
      if ImGui.Button(ctx, 'Unselect all', colW) then 
        DATA:Action_ApplyFilter_SelectAll(false) 
        DATA:Filter_RefreshCountActive() 
      end
      
      -- keywords
      local retval, v = reaper.ImGui_Checkbox( ctx, '##keywords_use', (DATA.FX_filter[FXname].keywords_use or EXT.CONF_defaultkeywords_use)==1 ) if retval then 
        local out = 0
        if v == true then out = 1 end
        DATA.FX_filter[FXname].keywords_use = out
        DATA:Filter_Save()
        DATA:Action_FilterParams()
      end 
      ImGui.SameLine(ctx)
      -- keywords string
      local retval, buf = reaper.ImGui_InputText( ctx, ' keywords exist##filtertxt', (DATA.FX_filter[FXname].keywords or EXT.CONF_defaultkeywords), ImGui.InputTextFlags_None )
      if retval then 
        if not DATA.FX_filter[FXname] then DATA.FX_filter[FXname]  = {} end
        DATA.FX_filter[FXname].keywords = buf
        DATA:Filter_Save()
        DATA:Action_FilterParams()
      end
      ImGui.SameLine(ctx)UI.HelpMarker('Parameter shown in list if its name contains one of the listed words.\n\nSpace separated,\ncase insensitive,\npunctuation ignored except "_" handled as space for multiword parameter names')

      -- keywords exclude
      local retval, v = reaper.ImGui_Checkbox( ctx, '##excludekeywords_use', (DATA.FX_filter[FXname].keywordsexclude_use or EXT.CONF_defaultkeywordsexclude_use)==1 ) if retval then 
        local out = 0
        if v == true then out = 1 end
        DATA.FX_filter[FXname].keywordsexclude_use = out
        DATA:Filter_Save()
        DATA:Action_FilterParams()
      end 
      ImGui.SameLine(ctx)
      -- keywords string
      local retval, buf = reaper.ImGui_InputText( ctx, ' keywords exclude##excludefiltertxt', (DATA.FX_filter[FXname].keywordsexclude or EXT.CONF_defaultkeywordsexclude), ImGui.InputTextFlags_None )
      if retval then 
        if not DATA.FX_filter[FXname] then DATA.FX_filter[FXname]  = {} end
        DATA.FX_filter[FXname].keywordsexclude = buf
        DATA:Filter_Save()
        DATA:Action_FilterParams()
      end
      ImGui.SameLine(ctx)UI.HelpMarker('Parameter shown in list if its name NOT contains one of the listed words.\n\nSpace separated,\ncase insensitive,\npunctuation ignored except "_" handled as space for multiword parameter names')
      
      
      -- empty / untitled / reserv
      ImGui.SetCursorPos(ctx, posx + colW+UI.spacingX, posy)
      local retval, v = reaper.ImGui_Checkbox( ctx, 'Pass untitled##untitled_pass', (DATA.FX_filter[FXname].untitled_pass or EXT.CONF_defaultuntitled_pass)==1 ) if retval then 
        local out = 0
        if v == true then out = 1 end
        DATA.FX_filter[FXname].untitled_pass = out
        DATA:Filter_Save()
        DATA:Action_FilterParams()
      end 
      ImGui.SameLine(ctx)UI.HelpMarker('Filter out empty parameter names, "reserv", "untitled", "resvd"')
      -- strings
      ImGui.SetCursorPosX(ctx, posx + colW+UI.spacingX)
      local retval, v = reaper.ImGui_Checkbox( ctx, 'Pass strings##string_pass', (DATA.FX_filter[FXname].strings_pass or EXT.CONF_defaultstrings_pass)==1 ) if retval then 
        local out = 0
        if v == true then out = 1 end
        DATA.FX_filter[FXname].strings_pass = out
        DATA:Filter_Save()
        DATA:Action_FilterParams()
      end 
      ImGui.SameLine(ctx)UI.HelpMarker('Filter out parameters that contain more than 2 character string')      
      -- CONF_defaulttoggle_pass
      ImGui.SetCursorPosX(ctx, posx + colW+UI.spacingX)
      local retval, v = reaper.ImGui_Checkbox( ctx, 'Pass toggle##toggle_pass', (DATA.FX_filter[FXname].toggle_pass or EXT.CONF_defaulttoggle_pass)==1 ) if retval then 
        local out = 0
        if v == true then out = 1 end
        DATA.FX_filter[FXname].toggle_pass = out
        DATA:Filter_Save()
        DATA:Action_FilterParams()
      end 
      ImGui.SameLine(ctx)UI.HelpMarker('Filter out parameters that analyzed as toggle')        
      
      
      ImGui.EndChild( ctx)
    end
  end
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:Action_FilterParams()
    if not (DATA.FX and DATA.FX.valid==true) then return end
    DATA.FX.cnt_params_filtered = 0
    local FXname = DATA.FX.FXname
    
    -- keywords
    local parse_globalfilt = {}
    local keywords_use = EXT.CONF_defaultkeywords_use
    if DATA.FX_filter and DATA.FX_filter[FXname] and DATA.FX_filter[FXname].keywords_use then keywords_use = DATA.FX_filter[FXname].keywords_use end
    local keywords = ''
    if DATA.FX_filter and DATA.FX_filter[FXname] and DATA.FX_filter[FXname].keywords then keywords = DATA.FX_filter[FXname].keywords end
    if keywords then 
      for word in keywords:gmatch('[^%s]+') do parse_globalfilt[#parse_globalfilt+1] = word end 
    end
    if keywords == '' then keywords_use = 0 end -- ignore empty string
    
    
    
    -- keywordsexclude
    local parse_globalfiltexclude = {}
    local keywordsexclude_use = EXT.CONF_defaultkeywordsexclude_use
    if DATA.FX_filter and DATA.FX_filter[FXname] and DATA.FX_filter[FXname].keywordsexclude_use then keywordsexclude_use = DATA.FX_filter[FXname].keywordsexclude_use end
    local keywordsexclude = ''
    if DATA.FX_filter and DATA.FX_filter[FXname] and DATA.FX_filter[FXname].keywordsexclude then keywordsexclude = DATA.FX_filter[FXname].keywordsexclude end
    if keywordsexclude then 
      for word in keywordsexclude:gmatch('[^%s]+') do parse_globalfiltexclude[#parse_globalfiltexclude+1] = word end 
    end
    if keywordsexclude == '' then keywordsexclude_use = 0 end -- ignore empty string
    
    for i = 1,DATA.FX.cnt_params do 
      local match_filter = true 
      local bufparam_check = DATA.FX.params[i].name
      local formatparam_check = DATA.FX.params[i].formatparam
      local istoggle = DATA.FX.params[i].istoggle
      
      
      
      
      -- untitled
      local untitled_pass = EXT.CONF_defaultuntitled_pass
      if DATA.FX_filter and DATA.FX_filter[FXname] and DATA.FX_filter[FXname].untitled_pass then untitled_pass = DATA.FX_filter[FXname].untitled_pass end
      if untitled_pass == 0 and 
          (
            bufparam_check:gsub('_','') == '' 
            or bufparam_check == ''
            or bufparam_check:match('reserv')
            or bufparam_check:match('untitled')
            or bufparam_check:match('resvd')
          )
          then 
        match_filter = false
      end 
      
      -- strings_pass
      local strings_pass = EXT.CONF_defaultstrings_pass
      if DATA.FX_filter and DATA.FX_filter[FXname] and DATA.FX_filter[FXname].strings_pass then strings_pass = DATA.FX_filter[FXname].strings_pass end
      if strings_pass == 0 and 
          (
            formatparam_check:match('%a%a%a')~=nil
          )
          then 
        match_filter = false
      end 

      -- strings_pass
      local toggle_pass = EXT.CONF_defaulttoggle_pass
      if DATA.FX_filter and DATA.FX_filter[FXname] and DATA.FX_filter[FXname].toggle_pass then toggle_pass = DATA.FX_filter[FXname].toggle_pass end
      if toggle_pass == 0 and 
          (
            istoggle == true
          )
          then 
        match_filter = false
      end 
      
      
      if keywords_use==1 then 
        match_filter = false
        for word = 1, #parse_globalfilt do
          local excludefilt = parse_globalfilt[word]:lower()
          excludefilt = excludefilt:gsub('_', ' ')
          if bufparam_check:lower():match(excludefilt) then 
            match_filter = true 
            break
          end
        end 
      end
      
      if keywordsexclude_use==1 then 
        for word = 1, #parse_globalfiltexclude do
          local excludefilt = parse_globalfiltexclude[word]:lower()
          excludefilt = excludefilt:gsub('_', ' ')
          if bufparam_check:lower():match(excludefilt) then 
            match_filter = false 
            break
          end
        end  
      end
      
      
      DATA.FX.params[i].match_filter = match_filter
      if match_filter ~= true then  DATA.FX.cnt_params_filtered = DATA.FX.cnt_params_filtered  + 1 end
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
  ---------------------------------------------------------------------------------------------------------------------
  function VF_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end
  ------------------------------------------------------------------------------------------------------
  function VF_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      data = string.gsub(data, '[^'..b..'=]', '')
      return (data:gsub('.', function(x)
          if (x == '=') then return '' end
          local r,f='',(b:find(x)-1)
          for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
          return r;
      end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
          if (#x ~= 8) then return '' end
          local c=0
          for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
              return string.char(c)
      end))
  end
-----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
function table.exportstring( s ) return string.format("%q", s) end

--// The Save Function
function table.savestring(  tbl )
local outstr = ''
  local charS,charE = "   ","\n"

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  outstr = outstr..'\n'..( "return {"..charE )

  for idx,t in ipairs( tables ) do
     outstr = outstr..'\n'..( "-- Table: {"..idx.."}"..charE )
     outstr = outstr..'\n'..( "{"..charE )
     local thandled = {}

     for i,v in ipairs( t ) do
        thandled[i] = true
        local stype = type( v )
        -- only handle value
        if stype == "table" then
           if not lookup[v] then
              table.insert( tables, v )
              lookup[v] = #tables
           end
           outstr = outstr..'\n'..( charS.."{"..lookup[v].."},"..charE )
        elseif stype == "string" then
           outstr = outstr..'\n'..(  charS..table.exportstring( v )..","..charE )
        elseif stype == "number" then
           outstr = outstr..'\n'..(  charS..tostring( v )..","..charE )
        end
     end

     for i,v in pairs( t ) do
        -- escape handled values
        if (not thandled[i]) then
        
           local str = ""
           local stype = type( i )
           -- handle index
           if stype == "table" then
              if not lookup[i] then
                 table.insert( tables,i )
                 lookup[i] = #tables
              end
              str = charS.."[{"..lookup[i].."}]="
           elseif stype == "string" then
              str = charS.."["..table.exportstring( i ).."]="
           elseif stype == "number" then
              str = charS.."["..tostring( i ).."]="
           end
        
           if str ~= "" then
              stype = type( v )
              -- handle value
              if stype == "table" then
                 if not lookup[v] then
                    table.insert( tables,v )
                    lookup[v] = #tables
                 end
                 outstr = outstr..'\n'..( str.."{"..lookup[v].."},"..charE )
              elseif stype == "string" then
                 outstr = outstr..'\n'..( str..table.exportstring( v )..","..charE )
              elseif stype == "number" then
                 outstr = outstr..'\n'..( str..tostring( v )..","..charE )
              end
           end
        end
     end
     outstr = outstr..'\n'..( "},"..charE )
  end
  outstr = outstr..'\n'..( "}" )
  return outstr
end

--// The Load Function
function table.loadstring( str )
if str == '' then return end
  local ftables,err = load( str )
  if err then return _,err end
  local tables = ftables()
  for idx = 1,#tables do
     local tolinki = {}
     for i,v in pairs( tables[idx] ) do
        if type( v ) == "table" then
           tables[idx][i] = tables[v[1]]
        end
        if type( i ) == "table" and tables[i[1]] then
           table.insert( tolinki,{ i,tables[i[1]] } )
        end
     end
     -- link indices
     for _,v in ipairs( tolinki ) do
        tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
     end
  end
  return tables[1]
end  
  ----------------------------------------------------------------------------------------- 
  function DATA:Filter_Load()
    local str = VF_decBase64(EXT.CONF_pluginfilter_b64)
    DATA.FX_filter = table.loadstring(str) or {} 
    
  end
  ----------------------------------------------------------------------------------------- 
  function DATA:Filter_RefreshCountActive()
    DATA.FX.cnt_params_active = DATA.FX.cnt_params
    if (DATA.FX and DATA.FX.valid== true) then
      local FXname = DATA.FX.FXname
      if DATA.FX_filter[FXname] then
        for pid in pairs(DATA.FX_filter[FXname]) do
          if DATA.FX_filter[FXname][pid] and type(DATA.FX_filter[FXname][pid]) == 'table' and DATA.FX_filter[FXname][pid].val and DATA.FX_filter[FXname][pid].val == 0 then
            DATA.FX.cnt_params_active = DATA.FX.cnt_params_active - 1
          end
        end
      end
    end
  end
  ----------------------------------------------------------------------------------------- 
  function DATA:Filter_Save()
    local outstr = table.savestring(DATA.FX_filter)
    EXT.CONF_pluginfilter_b64 = VF_encBase64(outstr)
    EXT:save() 
  end
  ----------------------------------------------------------------------------------------- 
  function main() 
    UI.MAIN_definecontext()  -- ext:load 
    DATA:Collectata_GetFocusedFXData() 
    DATA:Action_PrintPluginState_PrintParameters(1)
    DATA:Action_FilterParams()
    DATA:Filter_RefreshCountActive()
  end  
  ---------------------------------------------------
  function VF_GetFXByGUID(GUID, tr, proj)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(proj or 0) do
        local tr = GetTrack(proj,trid-1)
        local fxcnt_main = TrackFX_GetCount( tr ) 
        local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
        for fx = 1, fxcnt do
          local fx_dest = fx
          if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
          if TrackFX_GetFXGUID( tr, fx-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx-1 end 
        end
      end  
     else
      if not (ValidatePtr2(proj or 0, tr, 'MediaTrack*')) then return end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end    
  end
  ---------------------------------------------------
  function VF_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
  end
  --------------------------------------------------------------------  
  function DATA:CollectData() 
    if not (DATA.FX and DATA.FX.valid == true) then 
      DATA:Collectata_GetFocusedFXData() 
    end
  end
  
  ---------------------------------------------------------------------  
  function DATA:Action_Morph()
    DATA:Collectata_ValidFocusedFXData()
    if not (DATA.FX and DATA.FX.valid == true) then return end
    if DATA.currentsnapshot == 0 then 
      DATA.sourcesnapshot = 0
      DATA.currentsnapshot = 1
     elseif DATA.currentsnapshot == 1 then 
      DATA.sourcesnapshot = 1
      DATA.currentsnapshot = 2
     elseif DATA.currentsnapshot == 2 then 
      DATA.sourcesnapshot = 2
      DATA.currentsnapshot = 1      
    end
    
    DATA:Action_Morph_GenerateRandomSnapshot() 
    local srcstr = 'value_morph'
    local srcid = DATA.sourcesnapshot
    local deststr = 'value_morph'
    local destid = DATA.currentsnapshot
    
    
    if DATA.sourcesnapshot == 0  then
      srcstr = 'value_print'
      srcid = 1
    end
    
    
    DATA.srcstr, DATA.srcid, DATA.deststr, DATA.destid = srcstr, srcid, deststr, destid
    
    DATA:Action_Morph_SetParameters() 
  end
  ----------------------------------------------------------------------  
  function DATA:Action_Morph_SetParameters(ignore_morph, useval2) 
    
    local srcstr, srcid, deststr, destid = DATA.srcstr, DATA.srcid, DATA.deststr, DATA.destid
    
    if not (DATA.FX.cnt_params and DATA.FX.params) then return end 
    if EXT.CONF_smooth > 0 and not ignore_morph == true then
    
      if DATA.morphstate == 0 then
        DATA.morphstate_TS = os.clock()
        DATA.morphstate = 1
        return
      end
      
      if DATA.morphstate == 1 then
        DATA.morph_value = (os.clock() - DATA.morphstate_TS) / EXT.CONF_smooth
        DATA.morph_value = VF_lim(DATA.morph_value)
        if DATA.morph_value == 1 then DATA.morphstate = 0 end
      end      
    end
    
    if not (EXT.CONF_smooth ==0 or ignore_morph == true or (EXT.CONF_smooth > 0  and DATA.morphstate == 1)) then return end
    
    for paramid = 1, DATA.FX.cnt_params do  
      if DATA.FX.params[paramid].ignore == true then goto nextparam end
      if DATA.FX.params[paramid].active ~= true then goto nextparam end
      if not (DATA.FX.params[paramid] and DATA.FX.params[paramid][srcstr] and DATA.FX.params[paramid][srcstr][srcid]) then return end
      local init_value = DATA.FX.params[paramid][srcstr][srcid]
      local dest_value = DATA.FX.params[paramid][deststr][destid]
      if dest_value then
        local out_val = init_value + ((dest_value - init_value) * (DATA.morph_value or 1)) 
        if useval2 then out_val = init_value + ((dest_value - init_value) * (DATA.morph_value2 or 1)) end
        _G[DATA.FX.func_str..'SetParamNormalized'](DATA.FX.ptr, DATA.FX.fxnum, paramid-1, out_val)
      end
      ::nextparam::
    end 
  end
  ---------------------------------------------------------------------  
  function DATA:Action_Morph_GenerateRandomSnapshot()
    local snapshot_id = DATA.currentsnapshot 
    local plugname = DATA.FX.FXname
    
    if not (DATA.FX.cnt_params and DATA.FX.params) then return end
    for paramid = 1, DATA.FX.cnt_params do
      if  DATA.FX.params[paramid].ignore == true then goto nextparam end
      if  DATA.FX.params[paramid].active ~= true then goto nextparam end
      
      local randmin = 0
      local randmax = 1 
      if DATA.FX_filter[plugname] and DATA.FX_filter[plugname][paramid] and type(DATA.FX_filter[plugname][paramid]) == 'table' and DATA.FX_filter[plugname][paramid].randmin and DATA.FX_filter[plugname][paramid].randmax then 
        randmin = DATA.FX_filter[plugname][paramid].randmin
        randmax = DATA.FX_filter[plugname][paramid].randmax 
      end
      
      local outv = 1
      if DATA.FX.params[paramid].istoggle == false then
        --outv = DATA.FX.params[paramid].minval + math.random() * (DATA.FX.params[paramid].maxval-DATA.FX.params[paramid].minval)
        outv = randmin + math.random() * (randmax - randmin)
       else
        local out = math.random()
        outv = 1
        if out<0.5 then outv = 0 end
      end 
      if not DATA.FX.params[paramid].value_morph then DATA.FX.params[paramid].value_morph = {} end
      if not DATA.FX.params[paramid].value_morph[snapshot_id] then DATA.FX.params[paramid].value_morph[snapshot_id] = {} end
      DATA.FX.params[paramid].value_morph[snapshot_id]= outv 
      ::nextparam::
    end
  end
  --------------------------------------------------------------------  
  function DATA:Collectata_ValidFocusedFXData()
    
    local retval, trackidx, itemidx, takeidx, fxnum, parm = reaper.GetTouchedOrFocusedFX( 1 )
    if not retval then DATA.FX.valid = false return end
    local tr = GetTrack(-1, trackidx)
    if trackidx == -1 then tr = GetMasterTrack(-1) end
    local it = GetMediaItem( -1, itemidx ) 
    local func_str = 'TrackFX_'
    local ptr = tr 
    local ret, trname = GetTrackName(tr)
    local fx_GUID = _G[func_str..'GetFXGUID'](ptr, fxnum&0xFFFF)    
    if DATA.FX.fx_GUID and DATA.FX.fx_GUID == fx_GUID then return true else DATA.FX.valid = false return end
    
  end
  --------------------------------------------------------------------  
  function DATA:Action_PrintPluginState(stateID)
    DATA:Collectata_ValidFocusedFXData()
    if not (DATA.FX and DATA.FX.valid== true)  then DATA:Collectata_GetFocusedFXData() end
    DATA:Action_PrintPluginState_PrintParameters(stateID)
  end
  --------------------------------------------------------------------  
  function DATA:Action_PrintPluginState_UpdateFXData() 
    if not (DATA.FX and DATA.FX.FXname) then return end 
    if not (DATA.FX_filter) then return end 
    local buf = DATA.FX.FXname
          
    for i = 1, #DATA.FX.params do 
      if DATA.FX.params[i].ignore ~= true then 
        local active = true
          
        if DATA.FX_filter[buf] and DATA.FX_filter[buf][i] then 
          if type(DATA.FX_filter[buf][i]) == 'number' then DATA.FX_filter[buf][i] = {val = DATA.FX_filter[buf][i]} end
          if DATA.FX_filter[buf][i].val and DATA.FX_filter[buf][i].val == 0 then active = false end
        end
        DATA.FX.params[i].active = active
      end
    end
  end
  --------------------------------------------------------------------  
  function DATA:Collectata_GetFocusedFXData() -- also update to current params
    
    DATA:Filter_Load() -- load ext state of filter per plugin 
    
    -- get main stuff
    local retval, trackidx, itemidx, takeidx, fxnum, parm = reaper.GetTouchedOrFocusedFX( 1 )
    if not retval then return end
    local tr = GetTrack(-1, trackidx)
    if trackidx == -1 then tr = GetMasterTrack(-1) end
    
    local it = GetMediaItem( -1, itemidx ) 
    local func_str = 'TrackFX_'
    local ptr = tr 
    
    local ret, trname = GetTrackName(tr)
    local fx_GUID = _G[func_str..'GetFXGUID'](ptr, fxnum&0xFFFF)    
    local retval, buf = _G[func_str..'GetFXName'](ptr, fxnum&0xFFFF)
    local cnt_params = _G[func_str..'GetNumParams'](ptr, fxnum&0xFFFF)
    
    DATA.FX.ptr = ptr
    DATA.FX.func_str = func_str
    DATA.FX.cnt_params = cnt_params
    DATA.FX.cnt_params_filtered = 0
    DATA.FX.ptr = ptr
    DATA.FX.fx_GUID = fx_GUID
    DATA.FX.FXname_short = VF_ReduceFXname(buf)
    DATA.FX.fxnum = fxnum
    DATA.FX.FXname = buf
    DATA.FX.trname = trname
    DATA.FX.params = {}
    DATA.FX.fxnum = fxnum&0xFFFF
    
    
    local param_bypass = _G[DATA.FX.func_str..'GetParamFromIdent']( DATA.FX.ptr, DATA.FX.fxnum, ':bypass' )
    local param_wet = _G[DATA.FX.func_str..'GetParamFromIdent']( DATA.FX.ptr, DATA.FX.fxnum, ':wet' )
    local param_delta = _G[DATA.FX.func_str..'GetParamFromIdent']( DATA.FX.ptr, DATA.FX.fxnum, ':delta' )  
    
    for i = 1, cnt_params do
      local valuenorm, minval, maxval = _G[func_str..'GetParam'](ptr, fxnum, i-1) 
      local value = _G[func_str..'GetParamNormalized'](ptr, fxnum, i-1) 
      
      local retval, bufparam = _G[func_str..'GetParamName'](ptr, fxnum, i-1) 
      local retval, formatparam = _G[func_str..'GetFormattedParamValue'](ptr, fxnum, i-1) 
      local retval, step, smallstep, largestep, istoggle = _G[func_str..'GetParameterStepSizes'](ptr, fxnum, i-1) 
      
      local system =  (param_bypass == i-1 or param_wet == i-1 or param_delta == i-1)
      local active = true 
      
      if DATA.FX_filter[buf] and DATA.FX_filter[buf][i] and type(DATA.FX_filter[buf][i]) == 'table' and DATA.FX_filter[buf][i].val and DATA.FX_filter[buf][i].val == 0 then active = false end
      if system == true then active = false end
      DATA.FX.params[i] =
        { value_init = value,
          minval = minval,
          maxval = maxval,
          name=bufparam,
          formatparam=formatparam,
          istoggle=istoggle,
          ignore =system,
          active = active,
          match_filter = true,
          
          
        }
    end 
    
    DATA.FX.valid= true
  end  
  --------------------------------------------------------------------    
  function DATA:Action_PrintPluginState_PrintParameters(stateID0)
    if not (DATA.FX and DATA.FX.valid==true) then return end
    local stateID = stateID0 or 1
    for i = 1, DATA.FX.cnt_params do
      local value = _G[DATA.FX.func_str..'GetParamNormalized'](DATA.FX.ptr, DATA.FX.fxnum, i-1) 
      if not DATA.FX.params[i].value_print then DATA.FX.params[i].value_print = {} end
      DATA.FX.params[i].value_print[stateID] = value
    end 
    
  end
  ------------------------------------------------------------------  
  main()  
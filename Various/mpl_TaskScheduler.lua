-- @description TaskScheduler
-- @version 2.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Ported to ReaImGui

  --------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
    local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.9.2'
    
    
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 640,
          viewport_posH = 480, 
          
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          ES_key = 'MPL_TaskScheduler',
          UI_name = 'Task Scheduler', 
          
          upd = true, 
          list = {},
          action_table={},
          }
          
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
            -- font
              font='Arial',
              font1sz=14,
              font2sz=14,
              font3sz=12,
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


  UI.addevent_w = 200
  UI.commandcol_w = -1
  
  
  
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  -------------------------------------------------------------------------------- 
  function ImGui.PushStyle(key, value, value2)  
    if not (ctx and key and value) then return end
    local iscol = key:match('Col_')~=nil
    local keyid = ImGui[key]
    if not iscol then 
      ImGui.PushStyleVar(ctx, keyid, value, value2)
      if not UI.pushcnt_var then UI.pushcnt_var = 0 end
      UI.pushcnt_var = UI.pushcnt_var + 1
    else 
      if not value2 then
        ReaScriptError( key ) 
       else
        ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
        if not UI.pushcnt_col then UI.pushcnt_col = 0 end
        UI.pushcnt_col = UI.pushcnt_col + 1
      end
    end 
  end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_var()  
    if not (ctx) then return end
    ImGui.PopStyleVar(ctx, UI.pushcnt_var)
    UI.pushcnt_var = 0
  end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_col()  
    if not (ctx) then return end
    ImGui.PopStyleColor(ctx, UI.pushcnt_col)
    UI.pushcnt_col = 0
  end 
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
    
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
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
        ImGui.PushStyle('StyleVar_FrameRounding',5)   
        ImGui.PushStyle('StyleVar_GrabRounding',3)  
        ImGui.PushStyle('StyleVar_WindowRounding',10)  
        ImGui.PushStyle('StyleVar_ChildRounding',5)  
        ImGui.PushStyle('StyleVar_PopupRounding',0)  
        ImGui.PushStyle('StyleVar_ScrollbarRounding',9)  
        ImGui.PushStyle('StyleVar_TabRounding',4)   
      -- Borders
        ImGui.PushStyle('StyleVar_WindowBorderSize',0)  
        ImGui.PushStyle('StyleVar_FrameBorderSize',0) 
      -- spacing
        ImGui.PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
        ImGui.PushStyle('StyleVar_FramePadding',10,UI.spacingY) 
        ImGui.PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
        ImGui.PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
        ImGui.PushStyle('StyleVar_ItemInnerSpacing',4,0)
        ImGui.PushStyle('StyleVar_IndentSpacing',20)
        ImGui.PushStyle('StyleVar_ScrollbarSize',10)
      -- size
        ImGui.PushStyle('StyleVar_GrabMinSize',20)
        ImGui.PushStyle('StyleVar_WindowMinSize',w_min,h_min)
      -- align
        ImGui.PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
        ImGui.PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      -- alpha
        ImGui.PushStyle('StyleVar_Alpha',0.98)
        ImGui.PushStyle('Col_Border',UI.main_col, 0.3)
      -- colors
        ImGui.PushStyle('Col_Button',UI.main_col, 0.2) --0.3
        ImGui.PushStyle('Col_ButtonActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
        ImGui.PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
        ImGui.PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
        ImGui.PushStyle('Col_FrameBgActive',UI.main_col, .6)
        ImGui.PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
        ImGui.PushStyle('Col_Header',UI.main_col, 0.5) 
        ImGui.PushStyle('Col_HeaderActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
        ImGui.PushStyle('Col_PopupBg',0x303030, 0.9) 
        ImGui.PushStyle('Col_ResizeGrip',UI.main_col, 1) 
        ImGui.PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
        ImGui.PushStyle('Col_SliderGrab',UI.butBg_green, 0.4) 
        ImGui.PushStyle('Col_Tab',UI.main_col, 0.37) 
        ImGui.PushStyle('Col_TabHovered',UI.main_col, 0.8) 
        ImGui.PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
        ImGui.PushStyle('Col_TitleBg',UI.main_col, 0.7) 
        ImGui.PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
        ImGui.PushStyle('Col_WindowBg',UI.windowBg, 1)
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      ImGui.SetNextWindowSize(ctx, 640, h, ImGui.Cond_Appearing)
      
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font1) 
      local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
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
        
      -- draw stuff
        UI.draw()
        ImGui.Dummy(ctx,0,0) 
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
        ImGui.End(ctx)
       else
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
      end 
      ImGui.PopFont( ctx ) 
      if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
    
      return open
  end
  ---------------------------------------------------------------------
  function DATA:ActivateTask() 
    for evtID = 1, #DATA.list do
      local perform_condition = DATA:ActivateTask_GetTimeCondition(evtID)  
      if perform_condition==true then -- trigger if difference less than 1 second
        local actionID = DATA.list[evtID].evtID
        if not tonumber(actionID) or (tonumber(actionID) and tonumber(actionID) > 0) then -- native actions/extension actions
          Main_OnCommand(tonumber(actionID),0)
         elseif tonumber(actionID) and tonumber(actionID) < 0 then -- custom actions
          local actionID=tonumber(actionID)
          if actionID == -1 and DATA.list[evtID].stringargs then -- play custom tab
            local tabID = VF_GetProjIDByPath(DATA.list[evtID].stringargs)
            if tabID then OnPlayButtonEx( tabID ) end
          end
        end
      end
    end
  end
  ---------------------------------------------------
  function VF_GetProjIDByPath(projfn)
    for idx  = 0, 1000 do
      retval, projfn0 = reaper.EnumProjects( idx )
      if not retval then return end
      if projfn == projfn0 then return idx end
    end
  end
  ------------------------------------------------------------------------------------------------------
  function Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
  --------------------------------------------------- 
  function DATA:ActivateTask_GetTimeCondition(evtID) 
    -- repeating forever or until some time
      local allow_on_infinite_repeat = true
      if DATA.list[evtID].infinite_repeat == true and DATA.list[evtID].infinite_repeat == false and DATA.list[evtID].timeshed_repeatuntil_time and DATA.list[evtID].timeshed_repeatuntil_time >= DATA.TS_time then return end
      
    -- handle every day repeat
      local day_fits = false
      local everyday_mask = DATA.list[evtID].timeshed_repeat_everyday
      if everyday_mask>=0 then -- everyday repeat
        local day_fits = (
                      (DATA.TS_datetime_t.wday==1 and everyday_mask&64==64)
                      or (DATA.TS_datetime_t.wday==2 and everyday_mask&1==1)
                      or (DATA.TS_datetime_t.wday==3 and everyday_mask&2==2)
                      or (DATA.TS_datetime_t.wday==4 and everyday_mask&4==4)
                      or (DATA.TS_datetime_t.wday==5 and everyday_mask&8==8)
                      or (DATA.TS_datetime_t.wday==6 and everyday_mask&16==16)
                      or (DATA.TS_datetime_t.wday==7 and everyday_mask&32==32)
                    )
        if day_fits~=true then return end
      end 
      
    -- init trigger
      if DATA.list[evtID].timeshed == DATA.TS_time and DATA.list[evtID].state ~= 1 then 
        DATA.list[evtID].triggerTS= os.clock() 
        DATA.list[evtID].state = 1 
        return true
      end 
      
    -- is trigger closer than 1 sec
      if DATA.list[evtID].state == 1 then
        if os.clock() - DATA.list[evtID].triggerTS < 1 then 
          return 
         else
          DATA.list[evtID].state = 0
        end 
      end
  end
  ---------------------------------------------------  
  function DATA:GetActionTable()
    for i = 0, 200000 do
      --local id, actname = reaper.CF_EnumerateActions( 0, i, '' )
      local id, actname = reaper.kbd_enumerateActions( 0, i )
      if not id or id < -1 then break end
      DATA.action_table[id] = actname
    end
  end
  ---------------------------------------------------------------------------------------------------------------------
  function GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end  
  -------------------------------------------------------------------------------- 
  function DATA:CurrentList_Parse_sub(evtID, timeshed, flags, stringargs, comment)  
    if not (evtID and timeshed) then return end
    local retval, desc = reaper.GetActionShortcutDesc( 0, evtID, 0 )
    
    -- handle custom actions 
      if tonumber(evtID) then evtID = tonumber(evtID) end
      local evtname = evtID
      local evtID_native = NamedCommandLookup(evtID )
      if DATA.action_table[evtID_native] then evtname = DATA.action_table[evtID_native] end
      if evtname == '' then evtname = '<none>' end
      if tonumber(evtID) and evtID <0 then 
        if evtID == -1 then
          evtname = ''
          evtname_arg = ''
          if not stringargs then 
            evtname_arg = '<broken data>' 
           else
            local ID = VF_GetProjIDByPath(stringargs)
            if not ID or not stringargs then 
              evtname_arg = '<project not found> '..stringargs
             else
              local shortname = GetShortSmplName(stringargs)
              if not shortname then 
                evtname_arg = '<project not found, broken argument>'
               else
                evtname_arg =shortname-- '<tab '..(ID+1)..'> '..
              end
            end
          end
          evtname = evtname..evtname_arg
        end 
      end
      
    -- handle timeshedule
      --local timeshed_out = 0
      local timeshed_repeat_flags = 0
      local timeshed_repeatuntil_time = 0


      local val_t = {} for val in timeshed:gmatch('[^|]+') do val_t[#val_t+1] =val end
      local timeshed_out = tonumber(val_t[1])--+60*60*3
      if val_t[2] then 
        timeshed_repeat_flags = tonumber(val_t[2])
        timeshed_repeat = timeshed_repeat_flags&1==1
        infinite_repeat = timeshed_repeat_flags&2==2
        timeshed_repeatuntil_time = math.max(0,tonumber(val_t[3]))
        timeshed_repeat_everyday = tonumber(val_t[4])
      end
      
      DATA.list[#DATA.list+1] = {line = line,
                              evtID = evtID,
                              evtID_native= evtID_native,
                              desc=desc,
                              timeshed=timeshed_out,
                              
                              timeshed_repeat=timeshed_repeat,
                              infinite_repeat = infinite_repeat, 
                              timeshed_repeat_everyday=timeshed_repeat_everyday,
                              
                              flags=tonumber(flags),
                              stringargs=stringargs,
                              comment=comment,
                              timeshed_datetime_t = os.date("*t",timeshed_out), 
                              evtname=evtname,
                              
                              timeshed_repeatuntil_time = timeshed_repeatuntil_time,
                              timeshed_repeatuntil_time_t = os.date("*t",timeshed_repeatuntil_time),  
                              
                              --timeshed_format = os.date('*t', timeshed),
                              }
                              
      
    
  end
  -------------------------------------------------------------------------------- 
  function DATA:CurrentList_Parse()  
    local f = io.open(DATA.cur_tasklist, 'rb')
    if not f then
      f= io.open(DATA.cur_tasklist, 'wb')
      f:write('//MPL TaskScheduler current task list')
      f:close()
      
      f = io.open(DATA.cur_tasklist, 'rb')
    end
    
    if f then 
      local content = f:read('a')
      f:close()
      DATA.list = {}
      for line in content:gmatch('[^\r\n]+') do 
        if line:match('EVT ') then
          evtID, timeshed, flags, stringargs, comment = line:match('EVT (.-) ([%d|%-]+) ([%d]+) %[%[(.-)%]%] %[%[(.-)%]%]')
          DATA:CurrentList_Parse_sub(evtID, timeshed, flags, stringargs, comment) 
        end
      end
    end
  end  
  
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Always()
    DATA.TS_time = os.time() 
    DATA.TS_date = os.date('%c', DATA.TS_time) 
    DATA.TS_datetime_t = os.date("*t",DATA.TS_time)
    DATA:ActivateTask()  
  end

  -------------------------------------------------------------------------------- 
  function UI.MAIN_UIloop() 
    DATA:CollectData_Always()
    DATA:handleProjUpdates()
    
    if DATA.shed_remove then 
      table.remove(DATA.list,DATA.shed_remove)
      DATA:CurrentList_Store() 
      DATA.shed_remove = nil
    end
    
    -- draw UI
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
    DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
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
  function UI.draw_addevent()  
    ImGui.Text(ctx, 'Command ID:')
    local retval, buf = ImGui.InputText( ctx, '##Command ID', DATA.temp_commandID, ImGui.InputTextFlags_None)
    if retval then DATA.temp_commandID = buf end
    
    ImGui.Text(ctx, 'Date:')
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##day', DATA.temp_Day, ImGui.ComboFlags_None ) then
      for i = 1, 31 do if ImGui.Selectable( ctx, i, DATA.temp_Day==i, ImGui.SelectableFlags_None) then DATA.temp_Day = i end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##month', DATA.temp_Month, ImGui.ComboFlags_None ) then
      for i = 1, 12 do if ImGui.Selectable( ctx, i, DATA.temp_Month==i, ImGui.SelectableFlags_None) then DATA.temp_Month = i end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 80)
    if ImGui.BeginCombo( ctx, '##year', DATA.temp_Year, ImGui.ComboFlags_None ) then
      for i = 2025, 2100 do if ImGui.Selectable( ctx, i, DATA.temp_Year==i, ImGui.SelectableFlags_None) then DATA.temp_Year = i end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.Text(ctx, 'Time:')
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##Hour', DATA.temp_Hour, ImGui.ComboFlags_None ) then
      for i = 0, 24 do if ImGui.Selectable( ctx, i, DATA.temp_Hour==i, ImGui.SelectableFlags_None) then DATA.temp_Hour = i end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##Minute', DATA.temp_Minute, ImGui.ComboFlags_None ) then
      for i = 0, 60 do if ImGui.Selectable( ctx, i, DATA.temp_Minute==i, ImGui.SelectableFlags_None) then DATA.temp_Minute = i end end
      ImGui.EndCombo( ctx)
    end
 
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##Second', DATA.temp_Second, ImGui.ComboFlags_None ) then
      for i = 0, 60 do if ImGui.Selectable( ctx, i, DATA.temp_Second==i, ImGui.SelectableFlags_None) then DATA.temp_Second = i end end
      ImGui.EndCombo( ctx)
    end
    
    
    ImGui.Text(ctx, 'Comment:')
    local retval, buf = ImGui.InputText( ctx, '##Comment', DATA.temp_Comment, ImGui.InputTextFlags_None)
    if retval then DATA.temp_Comment = buf end
    
    if ImGui.Button(ctx, 'Add event',-1) then DATA:Event_Add() end
  end
  --------------------------------------------------------------------------------  
  function UI.draw()  
    
    if ImGui.BeginChild( ctx, '##newevent', UI.addevent_w, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then 
      ImGui.Text(ctx,DATA.TS_date)
      UI.draw_addevent() 
      ImGui.EndChild( ctx)
    end
    
    ImGui.SameLine(ctx)
    if ImGui.BeginChild( ctx, '##evtlist', 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then 
      UI.draw_events() 
      ImGui.EndChild( ctx)
    end    
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent() 
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0 )
  end
    -------------------------------------------------------------------------------- 
  function UI.draw_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end
  ----------------------------------------------------------------------------------------- 
  function main() 
    
    DATA:GetActionTable()
    local info = debug.getinfo(1,'S');
    DATA.script_path = info.source:match([[^@?(.*[\/])[^\/]-$]])
    DATA.cur_tasklist = DATA.script_path .. "mpl_TaskScheduler_currentlist.tlist" 
    
    DATA:CollectData_Always()
    
    DATA.TS_time_shed_default = DATA.TS_time + 60*60*24*7 -- week further
    DATA.temp_Day     = os.date("%d",DATA.TS_time_shed_default) 
    DATA.temp_Month   = os.date("%m",DATA.TS_time_shed_default)
    DATA.temp_Year    = os.date("%Y",DATA.TS_time_shed_default)
    DATA.temp_Hour    = os.date("%H",DATA.TS_time_shed_default)
    DATA.temp_Minute  = os.date("%M",DATA.TS_time_shed_default)
    DATA.temp_Second  = os.date("%S",DATA.TS_time_shed_default)
    
    DATA:CurrentList_Parse() 
    UI.MAIN_definecontext() 
  end  
  ---------------------------------------------------  
  function DATA:CurrentList_Store()  
    local str = '//MPL TaskScheduler current task list '..DATA.TS_date
    for i = 1, #DATA.list do
      local timeshed_repeat_flags= 0 
      if DATA.list[i].timeshed_repeat and DATA.list[i].timeshed_repeat == true then timeshed_repeat_flags = 1 end
      if DATA.list[i].infinite_repeat ==true then timeshed_repeat_flags = timeshed_repeat_flags + 2 end
      
      local timeshed_repeatuntil_time = 0
      if DATA.list[i].timeshed_repeatuntil_time then timeshed_repeatuntil_time  = DATA.list[i].timeshed_repeatuntil_time end
      
      local timeshed_repeat_everyday = 127
      if DATA.list[i].timeshed_repeat_everyday then timeshed_repeat_everyday  = DATA.list[i].timeshed_repeat_everyday end
      
      local timeshed = DATA.list[i].timeshed..'|'..timeshed_repeat_flags..'|'..timeshed_repeatuntil_time..'|'..timeshed_repeat_everyday
      str = str..'\nEVT '..DATA.list[i].evtID..' '..timeshed..' '..DATA.list[i].flags..' [['..DATA.list[i].stringargs..']] [['..DATA.list[i].comment..']]' 
    end
    local f = io.open(DATA.cur_tasklist, 'wb')
    if f then
      f:write(str)
      f:close()
    end 
    
    
    DATA:CurrentList_Parse() 
  end
  -----------------------------------------------------------------------------------------
  function DATA:Event_Remove(evtID)  
    DATA.shed_remove = evtID
    --table.remove(DATA.list,evtID)
    --DATA:CurrentList_Store() 
  end
  -----------------------------------------------------------------------------------------
  function DATA:Event_Add()  
    local datetime = { year = DATA.temp_Year,
                       month = DATA.temp_Month,
                       day = DATA.temp_Day,
                       hour = DATA.temp_Hour,
                       min = DATA.temp_Minute,
                       sec = DATA.temp_Second,
                      }
    local timeshed=os.time(datetime)
    
    DATA.list[#DATA.list+1] = { evtID = tonumber(DATA.temp_commandID) or 0, 
                                timeshed = timeshed, 
                                flags=0,
                                stringargs = '',
                                comment =DATA.temp_Comment or '',
                                
                                timeshed_repeat = false,
                                infinite_repeat = true,
                                timeshed_repeatuntil_time = timeshed}
    DATA:CurrentList_Store() 
  end
  ----------------------------------------------------------------------------------------- 
  function DATA:CurrentList_Store_datefromtable(evtID,issched)
    local key_t = 'timeshed_datetime_t'
    local key_time = 'timeshed'
    if issched == true then
      key_t = 'timeshed_repeatuntil_time_t'
      key_time = 'timeshed_repeatuntil_time'
    end
    local datetime = { year =   DATA.list[evtID][key_t].year,
                       month =  DATA.list[evtID][key_t].month,
                       day =    DATA.list[evtID][key_t].day,
                       hour =   DATA.list[evtID][key_t].hour,
                       min =    DATA.list[evtID][key_t].min,
                       sec =    DATA.list[evtID][key_t].sec,
                       isdst = false,
                      }
    DATA.list[evtID][key_time]=os.time(datetime)
    DATA:CurrentList_Store()
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_events_repeat(evtID) 
     
    ImGui.SameLine(ctx) 
    local rep_preview = 'Every day' 
    local everyd_mask = DATA.list[evtID].timeshed_repeat_everyday
    if everyd_mask ~= 127 then 
      if everyd_mask == 96 then rep_preview = 'Every weekend' 
       elseif everyd_mask ~= 0 then
        rep_preview = 'Every '
        if everyd_mask&1==1 then rep_preview = rep_preview..'Mon ' end
        if everyd_mask&2==2 then rep_preview = rep_preview..'Tue ' end
        if everyd_mask&4==4 then rep_preview = rep_preview..'Wed ' end
        if everyd_mask&8==8 then rep_preview = rep_preview..'Thu ' end
        if everyd_mask&16==16 then rep_preview = rep_preview..'Fri ' end
        if everyd_mask&32==32 then rep_preview = rep_preview..'Sat ' end
        if everyd_mask&64==64 then rep_preview = rep_preview..'Sun' end
       elseif everyd_mask == 0 then
        rep_preview = '<days not set>'
      end
    end
     
    if ImGui.BeginCombo( ctx, '##evt_repeat'..evtID, rep_preview, ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLargest ) then
      if ImGui.Selectable( ctx, 'Monday', DATA.list[evtID].timeshed_repeat_everyday&1==1, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=DATA.list[evtID].timeshed_repeat_everyday~1
        DATA:CurrentList_Store() 
      end
      if ImGui.Selectable( ctx, 'Tuesday', DATA.list[evtID].timeshed_repeat_everyday&2==2, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=DATA.list[evtID].timeshed_repeat_everyday~2
        DATA:CurrentList_Store() 
      end          
      if ImGui.Selectable( ctx, 'Wednesday', DATA.list[evtID].timeshed_repeat_everyday&4==4, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=DATA.list[evtID].timeshed_repeat_everyday~4
        DATA:CurrentList_Store() 
      end   
      if ImGui.Selectable( ctx, 'Thursday', DATA.list[evtID].timeshed_repeat_everyday&8==8, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=DATA.list[evtID].timeshed_repeat_everyday~8
        DATA:CurrentList_Store() 
      end  
      if ImGui.Selectable( ctx, 'Friday', DATA.list[evtID].timeshed_repeat_everyday&16==16, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=DATA.list[evtID].timeshed_repeat_everyday~16
        DATA:CurrentList_Store() 
      end  
      if ImGui.Selectable( ctx, 'Saturday', DATA.list[evtID].timeshed_repeat_everyday&32==32, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=DATA.list[evtID].timeshed_repeat_everyday~32
        DATA:CurrentList_Store() 
      end
      if ImGui.Selectable( ctx, 'Sunday', DATA.list[evtID].timeshed_repeat_everyday&64==64, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=DATA.list[evtID].timeshed_repeat_everyday~64
        DATA:CurrentList_Store() 
      end
      ImGui.Separator(ctx)
      if ImGui.Selectable( ctx, 'All', false, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=127
        DATA:CurrentList_Store() 
      end
      if ImGui.Selectable( ctx, 'None', false, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=0
        DATA:CurrentList_Store() 
      end  
      if ImGui.Selectable( ctx, 'Weekend', false, ImGui.SelectableFlags_None) then 
        DATA.list[evtID].timeshed_repeat_everyday=96
        DATA:CurrentList_Store() 
      end 
      ImGui.EndCombo( ctx)
    end
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_events_scheduletime(evtID, xpos,is_scheduntil) 
    local offs = 100
    
    local key_t = 'timeshed_datetime_t'
    local key_time = 'timeshed'
    local strid = ''
    if is_scheduntil == true then
      key_t = 'timeshed_repeatuntil_time_t'
      key_time = 'timeshed_repeatuntil_time'
      strid = 'sched'
    end
    
    
    -- datestart
    ImGui.SetCursorPosX(ctx,xpos)
    if not is_scheduntil then ImGui.Text(ctx, 'Schedule date:') else ImGui.Text(ctx, 'End date:') end
    ImGui.SameLine(ctx)  
    ImGui.SetCursorPosX(ctx,xpos+offs)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##evt_'..evtID..'day'..strid, DATA.list[evtID][key_t].day, ImGui.ComboFlags_None ) then
      for i = 1, 31 do if ImGui.Selectable( ctx, i, DATA.list[evtID][key_t].day==i, ImGui.SelectableFlags_None) then 
        DATA.list[evtID][key_t].day = i 
        DATA:CurrentList_Store_datefromtable(evtID,is_scheduntil)
      end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##evt_'..evtID..'month'..strid, DATA.list[evtID][key_t].month, ImGui.ComboFlags_None ) then
      for i = 1, 12 do if ImGui.Selectable( ctx, i, DATA.list[evtID][key_t].month==i, ImGui.SelectableFlags_None) then 
        DATA.list[evtID][key_t].month = i 
        DATA:CurrentList_Store_datefromtable(evtID,is_scheduntil)
      end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 80)
    if ImGui.BeginCombo( ctx, '##evt_'..evtID..'year'..strid, DATA.list[evtID][key_t].year, ImGui.ComboFlags_None ) then
      for i = 2025, 2100 do if ImGui.Selectable( ctx, i, DATA.list[evtID][key_t].year==i, ImGui.SelectableFlags_None) then 
        DATA.list[evtID][key_t].year = i 
        DATA:CurrentList_Store_datefromtable(evtID,is_scheduntil)
      end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SetCursorPosX(ctx,xpos)
    if not is_scheduntil then ImGui.Text(ctx, 'Schedule time:') else ImGui.Text(ctx, 'End time:') end
    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx,xpos+offs)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##evt_'..evtID..'Hour'..strid, DATA.list[evtID][key_t].hour, ImGui.ComboFlags_None ) then
      for i = 0, 23 do if ImGui.Selectable( ctx, i, DATA.list[evtID][key_t].hour==i, ImGui.SelectableFlags_None) then 
        DATA.list[evtID][key_t].hour = i 
        DATA:CurrentList_Store_datefromtable(evtID,is_scheduntil)
      end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##evt_'..evtID..'Minute'..strid, DATA.list[evtID][key_t].min, ImGui.ComboFlags_None ) then
      for i = 0, 59 do if ImGui.Selectable( ctx, i, DATA.list[evtID][key_t].min==i, ImGui.SelectableFlags_None) then 
        DATA.list[evtID][key_t].min = i 
        DATA:CurrentList_Store_datefromtable(evtID,is_scheduntil)
      end end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if ImGui.BeginCombo( ctx, '##evt_'..evtID..'Second'..strid, DATA.list[evtID][key_t].sec, ImGui.ComboFlags_None ) then
      for i = 0, 59 do if ImGui.Selectable( ctx, i, DATA.list[evtID][key_t].sec==i, ImGui.SelectableFlags_None) then 
        DATA.list[evtID][key_t].sec = i 
        DATA:CurrentList_Store_datefromtable(evtID,is_scheduntil)
      end end
      ImGui.EndCombo( ctx)
    end
    
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_events() 
    for evtID = 1, #DATA.list do
      if ImGui.BeginChild( ctx, '##evt'..evtID, 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border|ImGui.ChildFlags_AutoResizeY, ImGui.WindowFlags_None ) then 
        -- id
        UI.draw_setbuttonbackgtransparent() 
        ImGui.Button(ctx, evtID..'##id'..evtID)
        UI.draw_unsetbuttonstyle()
        ImGui.SameLine(ctx) 
        local xpos,ypos = ImGui.GetCursorPos(ctx)
        
        -- remove
        if ImGui.Button(ctx, 'X##idrem'..evtID) then DATA:Event_Remove(evtID) end
        ImGui.SameLine(ctx)
        
        -- command
        local modestr = ''
        local mode = {
            [0]   = 'ActionID',
            [-1]  = 'Play project'
          }
        local action = tonumber(DATA.list[evtID].evtID) or 0
        if action >= 0 then modestr = mode[0] else modestr = mode[DATA.list[evtID].evtID] end
        ImGui.SetNextItemWidth(ctx, 110)
        if ImGui.BeginCombo( ctx, '##mode', modestr, ImGui.ComboFlags_None ) then
          if ImGui.Selectable( ctx, 'ActionID##ActionID'..evtID, DATA.list[evtID].evtID>=0, ImGui.SelectableFlags_None) then DATA.list[evtID].evtID = 0 DATA:CurrentList_Store()  end
          if ImGui.Selectable( ctx, 'Play current project', DATA.list[evtID].evtID==-1, ImGui.SelectableFlags_None) then 
            DATA.list[evtID].evtID = -1 
            local retval, projfn = EnumProjects( -1 )
            DATA.list[evtID].stringargs = projfn
            DATA:CurrentList_Store()  
          end
          ImGui.EndCombo( ctx)
        end
        ImGui.SameLine(ctx) 
        local retval, buf1 = ImGui.InputText( ctx, '##evt_'..evtID..'Command ID', DATA.list[evtID].evtname, ImGui.InputTextFlags_None|ImGui.InputTextFlags_EnterReturnsTrue)
        if retval then 
          if DATA.list[evtID].evtID>=0 and tonumber(buf1 ) then 
            DATA.list[evtID].evtID= tonumber(buf1 )
            DATA:CurrentList_Store()   
          end
        end 
        
        -- comment
        ImGui.SetCursorPosX(ctx,xpos)
        ImGui.Text(ctx, 'Comment:')ImGui.SameLine(ctx)
        ImGui.SetNextItemWidth(ctx, -1)
        local retval, buf = ImGui.InputText( ctx, '##evt_'..evtID..'Comment', DATA.list[evtID].comment, ImGui.InputTextFlags_None)
        if retval then 
          DATA.list[evtID].comment = buf 
          DATA:CurrentList_Store()  
        end
  
        UI.draw_events_scheduletime(evtID, xpos)
        
        ImGui.SetCursorPosX(ctx,xpos)
        if ImGui.Checkbox(ctx, 'Repeat##evt_'..evtID..'Repeat',DATA.list[evtID].timeshed_repeat) then
          DATA.list[evtID].timeshed_repeat = not DATA.list[evtID].timeshed_repeat
          DATA:CurrentList_Store_datefromtable(evtID)
        end
        if DATA.list[evtID].timeshed_repeat == true then 
          ImGui.SameLine(ctx) 
          if ImGui.Checkbox(ctx, 'Infinite##evt_'..evtID..'Repeatuntil',DATA.list[evtID].infinite_repeat) then
            DATA.list[evtID].infinite_repeat = not DATA.list[evtID].infinite_repeat
            DATA:CurrentList_Store_datefromtable(evtID)
          end
          ImGui.SameLine(ctx) 
          UI.draw_events_repeat(evtID) 
          
          ImGui.SetCursorPosX(ctx,xpos)
          UI.draw_events_scheduletime(evtID, xpos,true)
          
        end
        
        ImGui.EndChild( ctx)
      end
    end
  end
  -----------------------------------------------------------------------------------------
  main()  
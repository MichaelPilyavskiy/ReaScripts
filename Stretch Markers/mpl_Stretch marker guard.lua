-- @description Stretch marker guard
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about Script for protecting area around stretch markers
-- @changelog
--    # fix spamming extstate





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
        viewport_posX = 0,
        viewport_posY = 0,
        viewport_posW = 600,
        viewport_posH = 480,
        
        preset_base64_user = '',
        update_presets = 1, -- grab presets ONCE from old version
        
        UI_compactmode =1,
        UI_appatchange = 0,
        
        -- global
        CONF_name = 'default',

        safety_distance = 0.005,
        max_offset = 0.2,
        perform_TS = 1, -- ==1 perfrom only at time selection
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_SMGuard',
        UI_name = 'Stretch marker guard', 
        upd = true, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
          --['Align items to edit cursor'] = 'CkNPTkZfTkFNRT1BbGlnbiBpdGVtcyB0byBlZGl0IGN1cnNvcgpDT05GX2FjdF9hY3Rpb249MQpDT05GX2FjdF9hbGlnbmRpcj0xCkNPTkZfYWN0X2NhdGNocmVmdGltZXNlbD0wCkNPTkZfYWN0X2NhdGNoc3JjdGltZXNlbD0wCkNPTkZfYWN0X2luaXRhcHA9MApDT05GX2FjdF9pbml0Y2F0Y2hyZWY9MQpDT05GX2FjdF9pbml0Y2F0Y2hzcmM9MQpDT05GX2NvbnZlcnRub3Rlb252ZWwwdG9ub3Rlb2ZmPTAKQ09ORl9lbnZzdGVwcz0wCkNPTkZfZXhjbHdpdGhpbj0wCkNPTkZfaW5jbHdpdGhpbj0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2l0ZXJhdGlvbmxpbT0zMDAwMApDT05GX29mZnNldD0wLjUKQ09ORl9yZWZfZWRpdGN1cj0xCkNPTkZfcmVmX2VudnBvaW50cz0wCkNPTkZfcmVmX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9yZWZfZ3JpZD0wCkNPTkZfcmVmX2dyaWRfc3c9MApDT05GX3JlZl9ncmlkX3ZhbD0wLjUKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj04CkNPTkZfcmVmX3BhdHRlcm5fbmFtZT1sYXN0X3RvdWNoZWQKQ09ORl9yZWZfc2VsaXRlbXM9MApDT05GX3JlZl9zZWxpdGVtc192YWx1ZT0wCkNPTkZfcmVmX3N0cm1hcmtlcnM9MApDT05GX3JlZl90aW1lbWFya2VyPTAKQ09ORl9zcmNfZW52cG9pbnRzPTAKQ09ORl9zcmNfZW52cG9pbnRzZmxhZz0xCkNPTkZfc3JjX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9zcmNfbWlkaT0wCkNPTkZfc3JjX21pZGlfbXNnZmxhZz01CkNPTkZfc3JjX21pZGlmbGFncz0xCkNPTkZfc3JjX3Bvc2l0aW9ucz0xCkNPTkZfc3JjX3NlbGl0ZW1zPTEKQ09ORl9zcmNfc2VsaXRlbXNmbGFnPTEKQ09ORl9zcmNfc3RybWFya2Vycz0w',
          },
        presets = {
          factory= {},
          user= {}, 
          },
          
        valL = 0,
        valR = 0,
        takes = {}
        }
        
        
-------------------------------------------------------------------------------- UI init variables
UI = {}
  
  UI.popups = {}
-- font  
  UI.font='Arial'
  UI.font1sz=15
  UI.font2sz=14
  UI.font3sz=12
-- style
  UI.pushcnt = 0
  UI.pushcnt2 = 0
-- size / offset
  UI.spacingX = 4
  UI.spacingY = 3
-- mouse
  UI.hoverdelay = 0.8
  UI.hoverdelayshort = 0.8
-- colors 
  UI.main_col = 0x7F7F7F -- grey
  UI.textcol = 0xFFFFFF
  UI.but_hovered = 0x878787
  UI.windowBg = 0x303030
-- alpha
  UI.textcol_a_enabled = 1
  UI.textcol_a_disabled = 0.5
  
  UI.knob_handle = 0xc8edfa
  UI.default_data_col_adv = '#00ff00' -- green
  UI.default_data_col_adv2 = '#e61919 ' -- red

  UI.indent = 20
  UI.knob_resY = 150
  
  
  UI.ctrl_w = 300
  UI.ctrl_h = 30






function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  -------------------------------------------------------------------------------- 
  function UI.GetUserInputMB_replica(mode, key, title, num_inputs, captions_csv, retvals_csv_returnfunc, retvals_csv_setfunc) 
    local round = 4
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, round)
    
      -- draw content
      -- (from reaimgui demo) Always center this window when appearing
      local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
      ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
      if ImGui.BeginPopupModal(ctx, key, nil, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border) then
      
        -- MB replika
        if mode == 0 then
          ImGui.Text(ctx, captions_csv)
          ImGui.Separator(ctx) 
        
          if ImGui.Button(ctx, 'OK', 0, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end
          
          --[[ImGui.SetItemDefaultFocus(ctx)
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'Cancel', 120, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end]]
        end
        
        -- GetUserInput replika
        if mode == 1 then
          ImGui.SameLine(ctx)
          ImGui.SetKeyboardFocusHere( ctx )
          local retval, buf = ImGui.InputText( ctx, captions_csv, retvals_csv_returnfunc(), ImGui.InputTextFlags_EnterReturnsTrue ) 
          if retval then
            retvals_csv_setfunc(retval, buf)
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end 
        end
        
        ImGui.EndPopup(ctx)
      end 
    
    
    ImGui.PopStyleVar(ctx, 4)
  end 
  
-------------------------------------------------------------------------------- 
function UI.MAIN_PushStyle(key, value, value2)  
  local iscol = key:match('Col_')~=nil
  local keyid = ImGui[key]
  if not iscol then 
    ImGui.PushStyleVar(ctx, keyid, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  local w_min = 250
  local h_min = 80
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    window_flags = window_flags | ImGui.WindowFlags_NoDocking
    --window_flags = window_flags | ImGui.WindowFlags_TopMost
    window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings() end
    --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
    --open = false -- disable the close button
  
  
    -- set style
      UI.pushcnt = 0
      UI.pushcnt2 = 0
    -- rounding
      UI.MAIN_PushStyle('StyleVar_FrameRounding',5)  
      UI.MAIN_PushStyle('StyleVar_GrabRounding',5)  
      UI.MAIN_PushStyle('StyleVar_WindowRounding',10)  
      UI.MAIN_PushStyle('StyleVar_ChildRounding',5)  
      UI.MAIN_PushStyle('StyleVar_PopupRounding',0)  
      UI.MAIN_PushStyle('StyleVar_ScrollbarRounding',9)  
      UI.MAIN_PushStyle('StyleVar_TabRounding',4)   
    -- Borders
      UI.MAIN_PushStyle('StyleVar_WindowBorderSize',0)  
      UI.MAIN_PushStyle('StyleVar_FrameBorderSize',0) 
    -- spacing
      UI.MAIN_PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
      UI.MAIN_PushStyle('StyleVar_FramePadding',5,5) 
      UI.MAIN_PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
      UI.MAIN_PushStyle('StyleVar_ItemInnerSpacing',4,0)
      UI.MAIN_PushStyle('StyleVar_IndentSpacing',20)
      UI.MAIN_PushStyle('StyleVar_ScrollbarSize',20)
    -- size
      UI.MAIN_PushStyle('StyleVar_GrabMinSize',30)
      UI.MAIN_PushStyle('StyleVar_WindowMinSize',w_min,h_min)
    -- align
      UI.MAIN_PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      --UI.MAIN_PushStyle('StyleVar_SelectableTextAlign,0,0 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextAlign,0,0.5 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextPadding,20,3 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextBorderSize,3 )
    -- alpha
      UI.MAIN_PushStyle('StyleVar_Alpha',0.98)
      --UI.MAIN_PushStyle('StyleVar_DisabledAlpha,0.6 ) 
      UI.MAIN_PushStyle('Col_Border',UI.main_col, 0.3)
    -- colors
      --UI.MAIN_PushStyle('Col_BorderShadow(),0xFFFFFF, 1)
      UI.MAIN_PushStyle('Col_Button',UI.main_col, 0.3) 
      UI.MAIN_PushStyle('Col_ButtonActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
      --UI.MAIN_PushStyle('Col_CheckMark(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true) 
      
      
      --Constant: Col_DockingEmptyBg
      --Constant: Col_DockingPreview
      --Constant: Col_DragDropTarget 
      UI.MAIN_PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
      UI.MAIN_PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
      UI.MAIN_PushStyle('Col_FrameBgActive',UI.main_col, .6)
      UI.MAIN_PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
      UI.MAIN_PushStyle('Col_Header',UI.main_col, 0.5) 
      UI.MAIN_PushStyle('Col_HeaderActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
      --Constant: Col_MenuBarBg
      --Constant: Col_ModalWindowDimBg
      --Constant: Col_NavHighlight
      --Constant: Col_NavWindowingDimBg
      --Constant: Col_NavWindowingHighlight
      --Constant: Col_PlotHistogram
      --Constant: Col_PlotHistogramHovered
      --Constant: Col_PlotLines
      --Constant: Col_PlotLinesHovered 
      UI.MAIN_PushStyle('Col_PopupBg',0x303030, 0.9) 
      UI.MAIN_PushStyle('Col_ResizeGrip',UI.main_col, 1) 
      --Constant: Col_ResizeGripActive 
      UI.MAIN_PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
      --Constant: Col_ScrollbarBg
      --Constant: Col_ScrollbarGrab
      --Constant: Col_ScrollbarGrabActive
      --Constant: Col_ScrollbarGrabHovered
      --Constant: Col_Separator
      --Constant: Col_SeparatorActive
      --Constant: Col_SeparatorHovered
      --Constant: Col_SliderGrab
      --Constant: Col_SliderGrabActive
      UI.MAIN_PushStyle('Col_Tab',UI.main_col, 0.37) 
      --UI.MAIN_PushStyle('Col_TabActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_TabHovered',UI.main_col, 0.8) 
      --Constant: Col_TabUnfocused
      --'Col_TabUnfocusedActive
      --UI.MAIN_PushStyle('Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
      --Constant: Col_TableBorderLight
      --Constant: Col_TableBorderStrong
      --Constant: Col_TableHeaderBg
      --Constant: Col_TableRowBg
      --Constant: Col_TableRowBgAlt
      UI.MAIN_PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
      --Constant: Col_TextDisabled
      --Constant: Col_TextSelectedBg
      UI.MAIN_PushStyle('Col_TitleBg',UI.main_col, 0.7) 
      UI.MAIN_PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
      --Constant: Col_TitleBgCollapsed 
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 1)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    local fixedw = 400
    local fixedh = 160
    ImGui.SetNextWindowSize(ctx, fixedw, fixedh, ImGui.Cond_Always)
    
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
      UI.calc_childH = math.floor(DATA.display_h_region - UI.calc_yoffset*6 - UI.calc_itemH*2)/3
      UI.calc_mainbut = DATA.display_w_region - UI.calc_xoffset*2
      
    -- draw stuff
      UI.draw()
      ImGui.Dummy(ctx,0,0) 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
     else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
    end 
    ImGui.PopFont( ctx ) 
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
  
    return open
end
  --------------------------------------------------------------------------------  
  function UI.MAIN_PopStyle(ctx, cnt, cnt2)
    if cnt then 
      ImGui.PopStyleVar(ctx,cnt)
      UI.pushcnt = UI.pushcnt -cnt
    end
    if cnt2 then
      ImGui.PopStyleColor(ctx,cnt2)
      UI.pushcnt2 = UI.pushcnt2 -cnt2
    end
  end
-------------------------------------------------------------------------------- 
function DATA:handleProjUpdates()
  local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
end  
-------------------------------------------------------------------------------- 
function DATA:CollectData(take)
  if take then 
    local retval, takeGUID = reaper.GetSetMediaItemTakeInfo_String( take, 'GUID', '', false ) 
    local cnt = reaper.GetNumTakeMarkers( take )
    for idx = cnt, 1, -1 do 
      local srcpos, name, color = reaper.GetTakeMarker( take, idx -1)
      if name:match('str_mark') then
        if not DATA.takes[takeGUID] then DATA.takes[takeGUID] = {} end
        DATA.takes[takeGUID][idx]={srcpos=srcpos,pos=tonumber(name:match('str_mark(.*)'))}
      end
    end
    return
  end
  
  
  local cnt_items = CountMediaItems(-1)
  for it = 1, cnt_items do
    local item = GetMediaItem( 0, it-1 )
    if not IsMediaItemSelected(item) then goto nextitem end
    local take = GetActiveTake(item)
    if TakeIsMIDI(take) then goto nextitem end
    
    local retval, takeGUID = reaper.GetSetMediaItemTakeInfo_String( take, 'GUID', '', false ) 
    local cnt = reaper.GetNumTakeMarkers( take )
    for idx = cnt, 1, -1 do 
      local srcpos, name, color = reaper.GetTakeMarker( take, idx -1)
      if name:match('str_mark') then
        if not DATA.takes[takeGUID] then DATA.takes[takeGUID] = {} end
        DATA.takes[takeGUID][idx]={srcpos=srcpos,pos=tonumber(name:match('str_mark(.*)'))}
      end
    end
    
    ::nextitem::
  end
  
end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  
  UI.open = UI.MAIN_draw(true) 
  
  UI.MAIN_shortcuts()
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) end
-------------------------------------------------------------------------------- 
function UI.MAIN()
  
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
  defer(UI.MAINloop)
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
-----------------------------------------------------------------------------------------
function VF_CopyTable(orig)--http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[VF_CopyTable(orig_key)] = VF_CopyTable(orig_value)
        end
        setmetatable(copy, VF_CopyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
--------------------------------------------------------------------------------  
function main() 
  EXT_defaults = VF_CopyTable(EXT)
  EXT:load()  
  DATA.PRESET_GetExtStatePresets()
  UI.MAIN() 
end
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
  function table.exportstring( s ) return string.format("%q", s) end 
  --// The Save Function
  function table.save(  tbl )
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
  function table.load( str )
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
--------------------------------------------------------------------- 
function DATA.PRESET_GetExtStatePresets()
  DATA.presets.factory = DATA.presets_factory
  
  local preset_base64_user = EXT.preset_base64_user
  if preset_base64_user:match('{')== nil and preset_base64_user~= '' then preset_base64_user = DATA.PRESET_decBase64(preset_base64_user) end
  DATA.presets.user = table.load(preset_base64_user) or {}
  
  -- ported from old version
  if EXT.update_presets == 1 then
    local t = {}
    for id_out=1, 32 do
      local str = GetExtState( DATA.ES_key, 'PRESET'..id_out)
      local str_dec = DATA.PRESET_decBase64(str)
      if str_dec== '' then goto nextpres end
      local tid = #t+1
      t[tid] = {str=str}
      for line in str_dec:gmatch('[^\r\n]+') do
        local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
        if key and value then
          t[tid][key]= tonumber(value) or value
        end
      end   
      local name = t[tid].CONF_NAME
      test = t[tid]
      DATA.presets.user[name] = VF_CopyTable(t[tid])
      ::nextpres::
    end
    EXT.update_presets = 0
    EXT:save()
  end
end
-------------------------------------------------------------------------------- 
function UI.MAIN_shortcuts()
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
    for key in pairs(UI.popups) do UI.popups[key].draw = false end
    ImGui.CloseCurrentPopup( ctx ) 
  end
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  reaper.Main_OnCommand(40044,0) end
end
--------------------------------------------------------------------------------  
function UI.draw_stuff()  
  if ImGui.Button(ctx, 'Reset', UI.calc_mainbut, UI.ctrl_h) then 
    DATA.valL = 0 
    DATA.valR = 0 
    reaper.Undo_BeginBlock2( -1 )
    DATA:SMguard_Apply() 
    reaper.Undo_EndBlock2( -1, 'Stretch Marker Guard', 0xFFFFFFFF )
    reaper.UpdateArrange() 
  end
  if ImGui.Button(ctx, 'Print stretch to take markers', UI.calc_mainbut, UI.ctrl_h) then DATA:SMguard_PrintToTakeMarkers() end
  ImGui.SetNextItemWidth( ctx, UI.ctrl_w) local retvalL, v = ImGui.SliderDouble(ctx, 'Left offset##Left', DATA.valL, -EXT.max_offset, 0, "%.3f", ImGui.SliderFlags_None) if retvalL then DATA.valL = v end
  retvalL = reaper.ImGui_IsItemDeactivated( ctx )
  ImGui.SetNextItemWidth( ctx, UI.ctrl_w) local retvalR, v = ImGui.SliderDouble(ctx, 'Right offset##Right', DATA.valR, 0,EXT.max_offset, "%.3f", ImGui.SliderFlags_None) if retvalR then DATA.valR = v end
  retvalR = reaper.ImGui_IsItemDeactivated( ctx )
  if retvalL or retvalR then 
    reaper.Undo_BeginBlock2( -1 )
    DATA:SMguard_Apply() 
    reaper.Undo_EndBlock2( -1, 'Stretch Marker Guard', 0xFFFFFFFF )
    reaper.UpdateArrange()
  end
end
--------------------------------------------------------------------------------
function UI.drawpopups()
  for key in pairs(UI.popups) do
    -- trig
    if UI.popups[key] and UI.popups[key].trig == true then
      UI.popups[key].trig = false
      UI.popups[key].draw = true
      ImGui.OpenPopup( ctx, key, ImGui.PopupFlags_NoOpenOverExistingPopup )
    end
    -- draw
    if UI.popups[key] and UI.popups[key].draw == true then UI.GetUserInputMB_replica(UI.popups[key].mode or 1, key, DATA.UI_name, 1, UI.popups[key].captions_csv, UI.popups[key].func_getval, UI.popups[key].func_setval) end 
  end
end
--------------------------------------------------------------------------------
function UI.draw()  
  --UI.draw_preset() 
  UI.draw_stuff()   
  UI.drawpopups()
end
--------------------------------------------------------------------- 
  function DATA.PRESET_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then  return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end
--------------------------------------------------------------------- 
function DATA.PRESET_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
--------------------------------------------------------------------- 
function DATA.PRESET_ApplyPreset(base64str, preset_name)  
  if not base64str then return end
  local  preset_t = {}
  
  local str_dec = DATA.PRESET_decBase64(base64str)
  if str_dec~= '' then 
    for line in str_dec:gmatch('[^\r\n]+') do
      local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
      if key and value and key:match('CONF_') then preset_t[key]= tonumber(value) or value end
    end   
  end 
  for key in pairs(preset_t) do
    if key:match('CONF_') then 
      local presval = preset_t[key]
      EXT[key] = tonumber(presval) or presval
    end
  end 
  
  if preset_name then EXT.CONF_NAME = preset_name end
  EXT:save() 
end
--------------------------------------------------------------------- 
function DATA.PRESET_RestoreDefaults(key, UI)
  if not key then
    for key in pairs(EXT) do
      if key:match('CONF_') or (UI and UI == true and key:match('UI_'))then
        local val = EXT_defaults[key]
        if val then EXT[key]  = val end
      end
    end
   else
    local val = EXT_defaults[key]
    if val then EXT[key]  = val end
  end
  
  EXT:save() 
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetCurrentPresetData()
  local str = ''
  for key in spairs(EXT) do if key:match('CONF_') then str = str..'\n'..key..'='..EXT[key] end end
  return DATA.PRESET_encBase64(str)
end 
--------------------------------------------------------------------------------  
function UI.draw_setbuttonbackgtransparent() 
    UI.MAIN_PushStyle('Col_Button',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonActive',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonHovered',0, 0)
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttonstyle() 
  UI.MAIN_PopStyle(ctx, nil, 3)
end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
--------------------------------------------------------------------------------  
--------------------------------------------------------------------------------  
function UI.draw_preset() 
  -- preset 
  
  local select_wsz = 250
  local select_hsz = 18--UI.calc_itemH
  UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Preset') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
  --ImGui.SetCursorPosX( ctx, DATA.display_w-UI.combo_w-UI.spacingX_wind )
  --ImGui.SetNextItemWidth( ctx, UI.combo_w )  
  local preview = EXT.CONF_name 
  
  
  
  if ImGui.BeginCombo(ctx, '##Preset', preview, ImGui.ComboFlags_HeightLargest) then 
    if ImGui.Button(ctx, 'Restore defaults') then DATA.PRESET_RestoreDefaults() end
    local retval, buf = reaper.ImGui_InputText( ctx, '##presname', DATA.preset_name )
    if retval then DATA.preset_name = buf end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Save current') then 
      local newID = DATA.preset_name--os.date()
      EXT.CONF_name = newID
      DATA.presets.user[newID] = DATA.PRESET_GetCurrentPresetData() 
      EXT.preset_base64_user =   DATA.PRESET_encBase64(table.save(DATA.presets.user))
      EXT:save() 
    end
    
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5,1)
    
    local id = 0
    for preset in spairs(DATA.presets.factory) do
      id = id + 1
      if ImGui.Selectable(ctx, '[F] '..preset..'##factorypresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.factory[preset], preset)
        EXT:save() 
      end
    end 
    local id = 0
    for preset in spairs(DATA.presets.user) do
      id = id + 1
      if ImGui.Selectable(ctx, preset..'##userpresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.user[preset], preset)
        EXT:save() 
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Remove##remove'..id,0,select_hsz) then 
        DATA.presets.user[preset] = nil
        EXT.preset_base64_user =   DATA.PRESET_encBase64(table.save(DATA.presets.user))
        EXT:save() 
      end
    end 
    
    
    
    ImGui.PopStyleVar(ctx)
    
    
    ImGui.EndCombo(ctx) 
  end  
  
  
end
------------------------------------------------------------------  
function DATA:SMguard_PrintToTakeMarkers(take)
  if take then 
    it_pos = reaper.GetMediaItemInfo_Value( reaper.GetMediaItemTake_Item( take ), 'D_POSITION' )
    tk_rate = reaper.GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    -- clear markers 
    local cnt = reaper.GetNumTakeMarkers( take )
    for idx = cnt, 1, -1 do 
      local retval, name, color = reaper.GetTakeMarker( take, idx -1)
      if name:match('str_mark') then
        DeleteTakeMarker( take, idx-1 ) 
      end
    end
    
    -- add new markers
    for ism = 1, reaper.GetTakeNumStretchMarkers( take ) do
      local _, sm_pos, sm_srcpos = reaper.GetTakeStretchMarker( take, ism -1 )  
      local pos_glob = it_pos + sm_pos / tk_rate
      SetTakeMarker( take, -1, 'str_mark'..pos_glob, sm_srcpos, 0 )
    end
    DATA:CollectData(take)
    return
  end
  
  
  local cnt_items = CountMediaItems(-1)
  for it = 1, cnt_items do
    local item = GetMediaItem( 0, it-1 )
    if not IsMediaItemSelected(item) then goto nextitem end
    local take = GetActiveTake(item)
    if TakeIsMIDI(take) then goto nextitem end
    
    it_pos = reaper.GetMediaItemInfo_Value( reaper.GetMediaItemTake_Item( take ), 'D_POSITION' )
    tk_rate = reaper.GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    
    -- clear markers 
    local cnt = reaper.GetNumTakeMarkers( take )
    for idx = cnt, 1, -1 do 
      local retval, name, color = reaper.GetTakeMarker( take, idx -1)
      if name:match('str_mark') then
        DeleteTakeMarker( take, idx-1 ) 
      end
    end
    
    -- add new markers
    for ism = 1, reaper.GetTakeNumStretchMarkers( take ) do
      local _, sm_pos, sm_srcpos = reaper.GetTakeStretchMarker( take, ism -1 )   
      local pos_glob = it_pos + sm_pos / tk_rate
      SetTakeMarker( take, -1, 'str_mark'..pos_glob, sm_srcpos, 0 )
    end
    
    
    ::nextitem::
  end
  DATA:CollectData()
end
--------------------------------------------------------------------   
function DATA:SMguard_Apply_AddSM(take, tkGUID) 
  local D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
  local D_PLAYRATE = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
  local it_pos = reaper.GetMediaItemInfo_Value( reaper.GetMediaItemTake_Item( take ), 'D_POSITION' )
  -- remove sm
    DeleteTakeStretchMarkers( take, 0, GetTakeNumStretchMarkers( take ) ) 
    
  -- add markers 
    local cnt = #DATA.takes[tkGUID]
    for idx = 1, cnt do 
      local posglob = DATA.takes[tkGUID][idx].pos
      local sm_pos = (posglob - it_pos) * D_PLAYRATE
      local srcpos = DATA.takes[tkGUID][idx].srcpos 
      
      if srcpos then 
      
        SetTakeStretchMarker( take, -1, sm_pos, srcpos) 
        
        if idx>1 and DATA.valL ~= 0 then
          local srcpos_prev = DATA.takes[tkGUID][idx-1].srcpos
          if srcpos_prev and srcpos - srcpos_prev > math.abs(DATA.valL)+math.abs(DATA.valR)+EXT.safety_distance then 
            local posglob_prev = DATA.takes[tkGUID][idx-1].pos
            local sm_pos_prev = (posglob_prev - it_pos) * D_PLAYRATE
            SetTakeStretchMarker( take, -1, sm_pos_prev+ DATA.valL , srcpos_prev+ DATA.valL )
          end
        end

        if idx<cnt and DATA.valR ~= 0  then
          local srcpos_next = DATA.takes[tkGUID][idx+1].srcpos
          if srcpos_next and srcpos_next - srcpos > math.abs(DATA.valL)+math.abs(DATA.valR)+EXT.safety_distance then 
            local posglob_next = DATA.takes[tkGUID][idx+1].pos
            local sm_pos_next = (posglob_next - it_pos) * D_PLAYRATE
            SetTakeStretchMarker( take, -1, sm_pos_next+ DATA.valR , srcpos_next+ DATA.valR )
          end
        end 
        
      end    
    end 
end
--------------------------------------------------------------------   
function DATA:SMguard_Apply()   
  local cnt_items = CountMediaItems(-1)
  for it = 1, cnt_items do
    local item = GetMediaItem( 0, it-1 )
    if not IsMediaItemSelected(item) then goto nextitem end
    local take = GetActiveTake(item)
    if TakeIsMIDI(take) then goto nextitem end
    local retval, takeGUID = reaper.GetSetMediaItemTakeInfo_String( take, 'GUID', '', false ) 
    if not DATA.takes[takeGUID] then
      DATA:SMguard_PrintToTakeMarkers(take)
      DATA:CollectData(take)
     else
      DATA:SMguard_Apply_AddSM(take, takeGUID) 
    end
    ::nextitem::
  end
end
-----------------------------------------------------------------------------------------
main()
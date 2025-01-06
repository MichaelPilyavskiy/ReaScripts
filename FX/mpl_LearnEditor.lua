-- @description LearnEditor
-- @version 3.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Ported to ReaImGui
--    # better handle aliasing
--    + Allow pin learn blocks
--    + Allow color learn blocks
--    + Allow collapse learn blocks




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
        viewport_dock = 0,
        
        CONF_dock = 0,
        
        -- global
        CONF_name = 'default',
        CONF_filtermode = 0,
        
      }

-------------------------------------------------------------------------------- INIT data
  DATA = {
        ES_key = 'MPL_LearnEditor',
        UI_name = 'Learn Editor', 
        upd = true,
        learnstate = {},
        aliasmap = {},
        }
        
        
-------------------------------------------------------------------------------- UI init variables
  UI = {}
    
    UI.popups = {}
  -- font  
    UI.font='Arial'
    UI.font1sz=15
    UI.font2sz=14
    UI.font3sz=13
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
    UI.default_data_col_adv2 = '#e61919 ' -- red
  
    UI.indent = 20
    UI.knob_resY = 120
    UI.ctrl_w_active = 15 
    UI.activecol_on = 0x0Fff0F -- green
    UI.activecol_off = 0x808080 -- yellow
    UI.indent = 20




function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
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
  local w_min = 330
  local h_min = 80
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    --window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    window_flags = window_flags | ImGui.WindowFlags_MenuBar
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    --window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    --window_flags = window_flags | ImGui.WindowFlags_NoDocking
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
      UI.MAIN_PushStyle('StyleVar_FramePadding',10,5) 
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
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0,0.5)
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
    local x, y, w, h, dock =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH,EXT.viewport_dock
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    ImGui.SetNextWindowDockID( ctx, EXT.CONF_dock , ImGui.Cond_Always )
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
      DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_dock = ImGui.GetWindowDockID( ctx )
      --if DATA.display_dock ~= EXT.CONF_dock then EXT.CONF_dock = DATA.display_dock EXT:save() msg(DATA.display_dock) end
      
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_childH = math.floor(DATA.display_h_region - UI.calc_yoffset*6 - UI.calc_itemH*2)/3
      UI.calc_mainbut = DATA.display_w_region - UI.calc_xoffset*4
      UI.calc_ctrlbut_w = math.floor((DATA.display_w_region - UI.calc_xoffset*7) / 4)
      
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
function DATA:CollectData_FilterCondition(track,fx)
  return
    -- no filter
    EXT.CONF_filtermode == 0 or 
    -- selected track
    (IsTrackSelected( track ) and EXT.CONF_filtermode==1) or
    -- opened fx
    ( TrackFX_GetOpen( track, fx ) and EXT.CONF_filtermode==2)
  
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
-------------------------------------------------------------------------------- 
function DATA:CollectData_LearnState(track, fx) 
  local retval, fxname = reaper.TrackFX_GetFXName( track, fx-1, '' )
  local parmcnt =  TrackFX_GetNumParams( track, fx-1 )
  local _, trname = GetTrackName(track)
  local fxname_short = VF_ReduceFXname(fxname)
  
  for pid =0 , parmcnt-1 do
    local retval, pname = reaper.TrackFX_GetParamName( track, fx-1, pid )
    local retval1, midi1 = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.midi1' )
    local retval1, midi2 = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.midi2' )
    local retval2, osc = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.osc' )
    midi1= tonumber(midi1)
    midi2= tonumber(midi2)
    
    local key
    local ctrl_type
    if midi1 and midi2 and (midi1~=0) then
      local midimsg = midi1+(midi2<<8)
      key = tostring(midimsg) --local key = #DATA.learnstate+1
      ctrl_type = 0
     elseif osc~='' then
      key = tostring(osc)
      ctrl_type = 1
    end
    
    
    if key and 
      (
        EXT.CONF_filtermode == 0 or 
        (IsTrackSelected( track ) and EXT.CONF_filtermode==1) or
        ( TrackFX_GetOpen( track, fx-1 ) and EXT.CONF_filtermode==2)
      )
      then
      local retval1, mode = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.mode' )
      local retval1, flags = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.learn.flags' )
      mode=tonumber(mode)
      flags=tonumber(flags)
      
      
      local format = ctrl_key or ''
      if ctrl_type == 0 and tonumber(key)then
        local ctrl_key_int = tonumber(key)
        local msg_byte1 = ctrl_key_int&0xFF
        local msg_byte2 = (ctrl_key_int>>8)&0xFF
        if msg_byte1>>4 == 0xB then
          local chan = msg_byte1&0xF
          format = 'MIDI Chan '..(chan+1)..' CC '..msg_byte2
         elseif msg_byte1>>4 == 0x9 then
          local chan = msg_byte1&0xF
          format = 'MIDI Chan '..(chan+1)..' Note '..msg_byte2
        end
       elseif ctrl_type == 1 then
        format = 'OSC '..key
      end
      
      
      if not DATA.learnstate[key] then 
        DATA.learnstate[key] = {
            ctrl_key = key,
            midi1=midi1,
            midi2=midi2,
            osc=osc,
            UI_name=format,
          } end
      
      UI_name = trname..' / '..fxname_short..' / '..pname
      
      
      DATA.learnstate[key][#DATA.learnstate[key]+1] = 
        {
          trGUID = GetTrackGUID( track),
          fxGUID = TrackFX_GetFXGUID( track, fx-1 ),
          param = pid,
          fxname=fxname,
          fxname_short = VF_ReduceFXname(fxname),
          trname=trname,
          pname = pname,
          mode=mode,
          flags=flags,
          UI_name = UI_name, 
          ctrl_type = ctrl_type,
        }
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
-------------------------------------------------------------------------------- 
function DATA:CollectData_ExtState() 
  -- ext
    DATA.learnstate_ext = {}
    local retval, str_b64 = reaper.GetProjExtState( -1, DATA.ES_key, 'LEARN_EDIT_EXT')
    local str = DATA.PRESET_decBase64(str_b64) 
    if retval then DATA.learnstate_ext = table.load(str) or {} end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData() 
  DATA:CollectData_ExtState() 
  
  DATA.learnstate = {}
  local cnt_tracks = CountTracks( 0 )
  for trackidx =0, cnt_tracks do
    local track =  GetTrack( -1, trackidx-1 )
    if not track then track = GetMasterTrack() end
    local fx_cnt = TrackFX_GetCount( track )
    local trcol =  reaper.GetTrackColor( track )
    local retval, trname = reaper.GetTrackName( track )
    local fxcnt = TrackFX_GetCount( track )
    for fx = 1, fxcnt do DATA:CollectData_LearnState(track, fx)  end
  end
  
end
--------------------------------------------------------------------- 
function DATA.PRESET_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA.alpha = math.sin(math.pi*(DATA.clock%1))
  DATA:handleProjUpdates() 

  if DATA.upd_projextstate == true then
    local out_str = table.save( DATA.learnstate_ext)
    local out_str_b64 = DATA.PRESET_encBase64(out_str) 
    SetProjExtState( -1, DATA.ES_key, 'LEARN_EDIT_EXT', out_str_b64 )
    DATA.upd_projextstate = nil
  end
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false  
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  UI.MAIN_shortcuts()
  -- handle xy
  DATA:handleViewportXYWH()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
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
--------------------------------------------------------------------------------  
function main() 
  EXT:load()  
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
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col,alpha) 
    UI.MAIN_PushStyle('Col_Button',col, (alpha or 1)*0.4 or 0.4) 
    UI.MAIN_PushStyle('Col_ButtonActive',col,alpha or  1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, (alpha or 1)*0.8 or 0.8)
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
function UI.draw_menu()  
  if ImGui.BeginMenuBar( ctx ) then
    UI.draw_setbuttoncolor(UI.main_col,0.3) 
    
    if ImGui.BeginMenu( ctx, 'Filter', true ) then
      if ImGui.MenuItem( ctx, 'No filter', nil, EXT.CONF_filtermode==0, true ) then EXT.CONF_filtermode=0 EXT:save() DATA.upd = true end
      if ImGui.MenuItem( ctx, 'Selected track', nil, EXT.CONF_filtermode==1, true ) then EXT.CONF_filtermode=1 EXT:save() DATA.upd = true end
      if ImGui.MenuItem( ctx, 'Focused FX', nil, EXT.CONF_filtermode==2, true ) then EXT.CONF_filtermode=2 EXT:save() DATA.upd = true end
      ImGui.EndMenu( ctx)
    end
    
    --[[if ImGui.BeginMenu( ctx, 'Actions', true ) then
      if ImGui.MenuItem( ctx, 'Export learn state as XML into project path', nil, nil, true ) then DATA:Actions_ExportCSV() DATA.upd = true end
      if ImGui.MenuItem( ctx, 'Import learn state from XML', nil, nil, true ) then DATA:Actions_ImportCSV() DATA.upd = true end
      ImGui.EndMenu( ctx)
    end
    ]]
    
    UI.draw_unsetbuttonstyle()
    ImGui.EndMenuBar( ctx )
  end
end
--------------------------------------------------------------------------------  
function UI.draw_learn()
  for learnkey in pairs(DATA.learnstate) do UI.draw_learn_sub(DATA.learnstate[learnkey],learnkey) end
end
--------------------------------------------------------------------------------  
function UI.draw()  
  UI.draw_menu()
  UI.draw_learn()
end
--------------------------------------------------------------------------------  
function UI.draw_learn_sub(t,learnkey)  
  local str_id = learnkey
  if not DATA.learnstate_ext[str_id] then DATA.learnstate_ext[str_id] = {} end
  if not DATA.learnstate_ext[str_id].collapsed_state then DATA.learnstate_ext[str_id].collapsed_state = 0 end
  
  -- collapsed
  local childH = 0
  local flags = ImGui.ChildFlags_None|ImGui.ChildFlags_Border|ImGui.ChildFlags_AutoResizeY
  if DATA.learnstate_ext[str_id] and DATA.learnstate_ext[str_id].collapsed_state and DATA.learnstate_ext[str_id].collapsed_state == 1 then 
    childH = UI.calc_itemH +UI.spacingY*2
    flags = ImGui.ChildFlags_None|ImGui.ChildFlags_Border
  end
  
  -- selection
  if DATA.learnstate_ext.selected_key == str_id then ImGui.PushStyleColor(ctx, ImGui.Col_Border,UI.main_col<<8|0xF0) else ImGui.PushStyleColor(ctx, ImGui.Col_Border,UI.main_col<<8|0x40) end 
  
  -- child col
  local alphachild = 0x10
  if DATA.learnstate_ext[str_id] and DATA.learnstate_ext[str_id].col_rgba then ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, DATA.learnstate_ext[str_id].col_rgba) else ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg,UI.main_col<<8|alphachild) end 
  
  if ImGui.BeginChild(ctx, str_id, 0, childH, flags, ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then
    -- active indicator 
      local actcol = UI.activecol_on --if t.PMOD['mod.active'] == 0 then actcol = UI.activecol_off end
    -- pin
      local pin = ''
      if not DATA.learnstate_ext[str_id].pin then DATA.learnstate_ext[str_id].pin = 0 end 
      if DATA.learnstate_ext[str_id].pin == 1 then pin = '^' end
      UI.draw_setbuttoncolor(actcol)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 5)
      if ImGui.Button(ctx, pin..'##active'..str_id,UI.ctrl_w_active) then end--t.PMOD['mod.active']=t.PMOD['mod.active']~1 DATA:ApplyPMOD(t) end
      ImGui.PopStyleVar(ctx)
      UI.draw_unsetbuttonstyle()
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
        DATA.learnstate_ext[str_id].pin = DATA.learnstate_ext[str_id].pin ~1
        DATA.upd_projextstate = true
        DATA.upd = true
      end 
      ImGui.SameLine(ctx)
    -- name .
      local namew = -(UI.calc_itemH+UI.spacingX)*2
      local name = t.UI_name or ''
      if DATA.learnstate_ext[str_id] and DATA.learnstate_ext[str_id].alias then name = DATA.learnstate_ext[str_id].alias end
      if not t.rename_input_mode then  
        if ImGui.Button(ctx, name..'##rename'..str_id, namew) then end --t.PMOD['mod.visible']=t.PMOD['mod.visible']~1 DATA:ApplyPMOD(t) end 
        if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then t.rename_input_mode = true end
       else
        ImGui.SetKeyboardFocusHere( ctx, 0 )
        ImGui.SetNextItemWidth(ctx,namew) 
        local retval, buf = reaper.ImGui_InputText( ctx, '##renamemodalias'..str_id, name, ImGui.InputTextFlags_EnterReturnsTrue|ImGui.InputTextFlags_AutoSelectAll )
        if retval then 
          if buf ~= '' and buf~=t.UI_name then 
            DATA.learnstate_ext[str_id].alias = buf 
           else 
            DATA.learnstate_ext[str_id].alias = nil 
          end
          DATA.upd_projextstate = true
          t.rename_input_mode = nil
          DATA.upd = true
        end
      end
      ImGui.SameLine(ctx)
      
    -- color
      
      local retval, col_rgba = reaper.ImGui_ColorEdit4( ctx, '##col', DATA.learnstate_ext[str_id].col_rgba or 0x7F7F7F0F, ImGui.ColorEditFlags_NoBorder|ImGui.ColorEditFlags_NoInputs|ImGui.ColorEditFlags_NoSidePreview)--ImGui.ColorEditFlags_NoAlpha|
      if retval then  
        DATA.learnstate_ext[str_id].col_rgba = col_rgba
        DATA.upd_projextstate = true
      end
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
        DATA.learnstate_ext[str_id].col_rgba = 0x7F7F7F0F
        DATA.upd_projextstate = true 
      end
      ImGui.SameLine(ctx)
      
    -- collapse
      if ImGui_ArrowButton( ctx, str_id..'collapse', ImGui.Dir_Down ) then 
        DATA.learnstate_ext[str_id].collapsed_state = DATA.learnstate_ext[str_id].collapsed_state~1
        DATA.upd_projextstate = true
      end  
      
    -- controls
      if DATA.learnstate_ext[str_id].collapsed_state == 0 then 
      for i = 1,#t do  UI.draw_learn_sub_links(t[i],str_id,i) end end
    
    ImGui.EndChild(ctx)
  end
  
  ImGui.PopStyleColor(ctx,2)
  
  if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then end--DATA.SetSelection(t) end
  
end
------------------------------------------------------------------------------------------------------  
function VF_GetMediaTrackByGUID(optional_proj, GUID)
  local optional_proj0 = optional_proj or -1
  for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
  local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
end 
  ------------------------------------------------------------------------------------------------------
function VF_GetFXByGUID(GUID, tr, proj)
  if not GUID then return end
  local pat = '[%p]+'
  if not tr then
    for trid = 1, CountTracks(proj or -1) do
      local tr = GetTrack(proj or-1,trid-1)
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
--------------------------------------------------------------------------------  
function DATA:RemoveLearn(ctrl_t)
  local trGUID = ctrl_t.trGUID
  local track = VF_GetMediaTrackByGUID(-1, trGUID)
  local fxGUID = ctrl_t.fxGUID
  local ret, tr, fx = VF_GetFXByGUID(fxGUID, track) 
  local pid = ctrl_t.param
  if ctrl_t.ctrl_type == 0 then 
    TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.midi1' ,'')
    TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.midi2' ,'')
   elseif ctrl_t.ctrl_type == 1 then
    TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.osc' ,'')
  end
    
  DATA.upd = true
end
--------------------------------------------------------------------------------  
function DATA:SetLastTouched(ctrl_t)
  local trGUID = ctrl_t.trGUID
  local track = VF_GetMediaTrackByGUID(-1, trGUID)
  local fxGUID = ctrl_t.fxGUID
  local ret, tr, fx = VF_GetFXByGUID(fxGUID, track) 
  local pid = ctrl_t.param
  TrackFX_SetNamedConfigParm( track, fx,'last_touched' ,pid) 
  Main_OnCommand(41144,0) -- FX: Set MIDI learn for last touched FX parameter
  DATA.upd = true
end
--------------------------------------------------------------------------------  
function DATA:SetFlags(ctrl_t,flags)
  local trGUID = ctrl_t.trGUID
  local track = VF_GetMediaTrackByGUID(-1, trGUID)
  local fxGUID = ctrl_t.fxGUID
  local ret, tr, fx = VF_GetFXByGUID(fxGUID, track) 
  local pid = ctrl_t.param
  TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.flags', flags)
  DATA.upd = true
end
--------------------------------------------------------------------------------  
function DATA:SetMode(ctrl_t,mode)
  local trGUID = ctrl_t.trGUID
  local track = VF_GetMediaTrackByGUID(-1, trGUID)
  local fxGUID = ctrl_t.fxGUID
  local ret, tr, fx = VF_GetFXByGUID(fxGUID, track) 
  local pid = ctrl_t.param
  TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.mode', mode)
  DATA.upd = true
end
--------------------------------------------------------------------------------  
function UI.draw_learn_sub_links(t,str_id,i)  
  ImGui.Indent(ctx, UI.indent)
  ImGui.PushFont(ctx, DATA.font3) 
  if ImGui.Button(ctx, t.UI_name..'##linkname'..str_id..'_'..i,-UI.calc_itemH*7-UI.spacingX) then
    DATA:SetLastTouched(t)
  end
  ImGui.SameLine(ctx) 
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
  
  -- combo
  ImGui_SetNextItemWidth( ctx, UI.calc_itemH*4 )
  local modestr = ''
  local mode = t.mode
  if mode == 0 then modestr='Absolute'
  elseif mode == 1 then modestr='127=-1,1=+1'
  elseif mode == 2 then modestr='63=-1, 65=+1'
  elseif mode == 3 then modestr='65=-1, 1=+1'
  elseif mode == 4 then modestr='toggle' end
  if ImGui.BeginCombo( ctx, '##comb'..str_id..'_'..i, modestr, ImGui.ComboFlags_None ) then
    if ImGui.Selectable( ctx, 'Absolute', mode==0, ImGui.SelectableFlags_None, 0, 0 ) then DATA:SetMode(t,0) end
    if ImGui.Selectable( ctx, 'Relative 1 (127=-1,1=+1)', mode==1, ImGui.SelectableFlags_None, 0, 0 ) then DATA:SetMode(t,1) end
    if ImGui.Selectable( ctx, 'Relative 2 (63=-1, 65=+1)', mode==2, ImGui.SelectableFlags_None, 0, 0 ) then DATA:SetMode(t,2) end
    if ImGui.Selectable( ctx, 'Relative 3 (65=-1, 1=+1)', mode==3, ImGui.SelectableFlags_None, 0, 0 ) then DATA:SetMode(t,3) end
    if ImGui.Selectable( ctx, 'Toggle (>0 = toggle)', mode==4, ImGui.SelectableFlags_None, 0, 0 ) then DATA:SetMode(t,4) end
    ImGui.EndCombo( ctx)
  end
  ImGui.SameLine(ctx) 
  
  -- remove
  if ImGui.Button(ctx, 'Remove##linknamedel'..str_id..'_'..i,UI.calc_itemH*3) then DATA:RemoveLearn(t) end
  
  -- flags
  if ImGui_Checkbox( ctx, 'Soft takeover##linknamestk'..str_id..'_'..i, t.flags&2==2 ) then DATA:SetFlags(t,t.flags~2) end
  ImGui.SameLine(ctx) 
  if ImGui_Checkbox( ctx, 'Selected track##linknameseltr'..str_id..'_'..i, t.flags&1==1 ) then DATA:SetFlags(t,t.flags~1) end
  ImGui.SameLine(ctx) 
  if ImGui_Checkbox( ctx, 'Focused FX##linknamefocfx'..str_id..'_'..i, t.flags&4==4 ) then DATA:SetFlags(t,t.flags~4) end
  ImGui.SameLine(ctx) 
  if ImGui_Checkbox( ctx, 'Visible FX##linknamevisfx'..str_id..'_'..i, t.flags&16==16 ) then DATA:SetFlags(t,t.flags~16) end
    
  ImGui.PopStyleVar(ctx)
  ImGui.PopFont(ctx)
  ImGui.Unindent(ctx, UI.indent)
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttonbackgtransparent()
  UI.MAIN_PushStyle('Col_Button',0, 0) 
  UI.MAIN_PushStyle('Col_ButtonActive',0, 0) 
  UI.MAIN_PushStyle('Col_ButtonHovered',0, 0)
end
--------------------------------------------------------------------- 
function DATA.PRESET_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttonstyle() UI.MAIN_PopStyle(ctx, nil, 3)end
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
function DATA:handleViewportXYWH()
  if EXT.CONF_dock ~=0 or DATA.display_dock ~= 0  then return end
  if not (DATA.display_x and DATA.display_y) then return end 
  if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
  if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
  if not DATA.display_w_last then DATA.display_w_last = DATA.display_w end
  if not DATA.display_h_last then DATA.display_h_last = DATA.display_h end
  if not DATA.display_dock_last then DATA.display_dock_last = DATA.display_dock end
  if  DATA.display_x_last~= DATA.display_x 
    or DATA.display_y_last~= DATA.display_y 
    or DATA.display_w_last~= DATA.display_w 
    or DATA.display_h_last~= DATA.display_h 
    or DATA.display_dock_last~= DATA.display_dock 
    then 
    
    DATA.display_schedule_save = os.clock() 
  end
  if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
    EXT.viewport_posX = DATA.display_x
    EXT.viewport_posY = DATA.display_y
    EXT.viewport_posW = DATA.display_w
    EXT.viewport_posH = DATA.display_h
    EXT.viewport_dock = DATA.display_dock
    EXT:save() 
    DATA.display_schedule_save = nil 
  end
  DATA.display_x_last = DATA.display_x
  DATA.display_y_last = DATA.display_y
  DATA.display_w_last = DATA.display_w
  DATA.display_h_last = DATA.display_h
  DATA.display_dock_last = DATA.display_dock
end
-------------------------------------------------------------------------------- 
function DATA:handleProjUpdates()
  local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 ) -- query focused fx
  local FXout = trackidx|(fxidx<<16) if (DATA.upd_lastFXout and DATA.upd_lastFXout~=FXout ) then DATA.upd = true end  DATA.upd_lastFXout = FXout
  local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
end
  ----------------------------------------------------------------------
  function DATA:Actions_ImportCSV()
    local retval, xml = reaper.GetUserFileNameForRead('', 'LearnEditor mapping', '.xml' )
    
    if not (xml and xml ~= '' ) then return end
    local f = io.open(xml, 'rb')
    local content
    if f then 
      content = f:read('a')
      f:close()
     else
      return
    end 
    if not content then return end
    
    -- parse xml
    for control in content:gmatch('(<control.-<%/control>)') do
      local ctrl_type = control:match('<ctrl_type>(.-)<%/ctrl_type>')
      local ctrl_key = control:match('<ctrl_key>(.-)<%/ctrl_key>')
      for link in control:gmatch('(<link.-<%/link>)') do
        local fxGUID = link:match('<fxGUID>(.-)<%/fxGUID>')
        local pid = link:match('<param>(.-)<%/param>')
        local mode = link:match('<mode>(.-)<%/mode>')
        local flags = link:match('<flags>(.-)<%/flags>')
        local ret,track,fx = VF_GetFXByGUID(fxGUID)
        if ret then
          if tonumber(ctrl_type) == 0 then
            local midi_int = tonumber(ctrl_key)
            TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.midi1',midi_int&0xFF )
            TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.midi2',(midi_int&0xFF00)>>8 )
           elseif tonumber(ctrl_type) == 1 then 
            TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.osc',ctrl_key )
          end
          TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.mode',mode )
          TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..'.learn.flags',flags ) 
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function DATA:Actions_ExportCSV()
    local out_fp =GetProjectPath()..'/LearnEditor_mapping.xml'
    if not DATA.learnstate then return end
    
    local str = ''
    for control in pairs(DATA.learnstate) do
      str=str..'\n<control id="'..control..'">'
      str=str..'\n  <ctrl_type>'..DATA.learnstate[control].ctrl_type..'</ctrl_type>' 
      str=str..'\n  <ctrl_key>'..DATA.learnstate[control].ctrl_key..'</ctrl_key>'
      for link = 1, #DATA.learnstate[control] do
        str=str..'\n  <link linkid="'..link..'">'
        str=str..'\n    <trGUID>'..DATA.learnstate[control][link].trGUID..'</trGUID>'
        str=str..'\n    <fxGUID>'..DATA.learnstate[control][link].fxGUID..'</fxGUID>'
        str=str..'\n    <flags>'..DATA.learnstate[control][link].flags..'</flags>'
        str=str..'\n    <mode>'..DATA.learnstate[control][link].mode..'</mode>'
        str=str..'\n    <param>'..DATA.learnstate[control][link].param..'</param>'
        str=str..'\n  </link>'
      end
      str=str..'\n</control>'
    end
    
    --str=str..'\n<LearnEditor_vrs>'..EXT.version..'</LearnEditor_vrs>'
    str=str..'\n<ts>'..os.date()..'</ts>'
    
    local f = io.open(out_fp,'wb')
    if f then 
      f:write(str)
      f:close()
    end
    MB('Export successfully to '..out_fp,DATA.UI_name,0)
  end
  ----------------------------------------------------------------------
  function DATA:ProcessUndoBlock(f, name, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)  
    Undo_BeginBlock2( 0)
    defer(f(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10))
    Undo_EndBlock2( 0, name, 0xFFFFFFFF )
  end
-----------------------------------------------------------------------------------------
main()
  
  
  
  

 
  --[[
  ---------------------------------------------------------------------  
  function DATA2:ModLearn(ctrl_t, linkid,remove, toggleflag, mode)
    local trGUID = ctrl_t[linkid].trGUID
    local track = VF_GetMediaTrackByGUID(0, trGUID)
    local fxGUID = ctrl_t[linkid].fxGUID
    local ret, tr, fx = VF_GetFXByGUID(fxGUID, track) 
    local pid = ctrl_t[linkid].param
    
    -- remove
    if remove then 
      if ctrl_t.ctrl_type == 0 then
        TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.midi1' ,'')
        TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.midi2' ,'')
       elseif ctrl_t.ctrl_type == 1 then
        TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.osc' ,'')
      end
    end
    
    if toggleflag then 
      TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.flags' ,ctrl_t[linkid].flags~toggleflag)
    end
    
    if mode then 
      TrackFX_SetNamedConfigParm( track, fx,'param.'..pid..'.learn.mode' ,mode)
    end
    
    
  end

  ----------------------------------------------------------------------
  function GUI_nodes_init(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('ctrl_') then DATA.GUI.buttons[key] = nil end end
    if not DATA.learnstate then return end
    -- calc common h
      local node_comh = 0
      for control in spairs(DATA.learnstate) do
        for link =1,#DATA.learnstate[control] do
          node_comh =node_comh + DATA.GUI.custom_node_areah
        end
      end
      node_comh =math.max(node_comh-DATA.GUI.custom_infoh - DATA.GUI.custom_node_areah,DATA.GUI.custom_gfx_hreal)
    
    local node_y_offs = (DATA2.scroll_list or 0) * (1-node_comh) + DATA.GUI.custom_infoh
    --if node_comh+DATA.GUI.custom_infoh <= DATA.GUI.custom_gfx_hreal then node_y_offs = DATA.GUI.custom_infoh end
    for control in spairs(DATA.learnstate) do
      GUI_nodes_ctrl(DATA, DATA.learnstate[control], node_y_offs)  
      for link =1,#DATA.learnstate[control] do
        node_y_offs = GUI_nodes_info(DATA, DATA.learnstate[control],link, node_y_offs) 
        GUI_nodes_modeflags(DATA, DATA.learnstate[control], link) 
      end
    end
  end
  --------------------------------------------------------------------- 
  function GUI_header_info(DATA)
    DATA.GUI.buttons.actions = { x=0,
                        y=0,
                        w=DATA.GUI.custom_gfx_wreal-1,
                        h=DATA.GUI.custom_infoh,
                        frame_a = 0,
                        --frame_asel = 0,
                        
                        txt = 'Actions / Options',
                        txt_fontsz=DATA.GUI.custom_info_txtsz,
                        onmouserelease = function() 
                          DATA:GUImenu(
                          {
                            { str = '#Filter'},
                            { str = 'No filter',
                              state =  EXT.CONF_filtermode ==0 ,
                              func = function()  
                                EXT.CONF_filtermode =0 
                                DATA_RESERVED_ONPROJCHANGE(DATA)
                                DATA.UPD.onconfchange = true
                              end
                            } ,
                            { str = 'Selected track',
                              state =  EXT.CONF_filtermode ==1 ,
                              func = function()  
                                EXT.CONF_filtermode =1 
                                DATA_RESERVED_ONPROJCHANGE(DATA)
                                DATA.UPD.onconfchange = true
                              end
                            }  ,
                            { str = 'Focused FX',
                              state =  EXT.CONF_filtermode == 2,
                              func = function()  
                                EXT.CONF_filtermode = 2
                                DATA_RESERVED_ONPROJCHANGE(DATA)
                                DATA.UPD.onconfchange = true
                              end
                            },        
                           
                            {str='|Dock',
                             func =           function()  
            local state = gfx.dock(-1)
            if state&1==1 then
              state = 0
             else
              state = EXT.dock 
              if state == 0 then state = 1 end
            end
            local title = EXT.mb_title or ''
            if EXT.version then title = title..' '..EXT.version end
            gfx.quit()
            gfx.init( title,
                      EXT.wind_w or 100,
                      EXT.wind_h or 100,
                      state, 
                      EXT.wind_x or 100, 
                      EXT.wind_y or 100)
            
            
          end
                            }
                          })

                        end
                        }
    
  end

  
  ]]
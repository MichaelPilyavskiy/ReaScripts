-- @description Render-in-place
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Based on Cubase "Render Selection" dialog port 
-- @changelog
--    + Enable sends / Render sends separately
--    # Disable glue if Render sends separately is ON
--    + Add settings for second track



    
--NOT reaper NOT gfx

local vrs = 1.02
--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end 
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3'
  
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        viewport_posX = 0,
        viewport_posY = 0,
        viewport_posW = 400,
        viewport_posH = 640,
        
        preset_base64_user = '',
        
        CONF_name = 'default',
        
        -- src
        CONF_source = 1|2|4|8|16, -- &1 razor areas -- &2 items -- &4 track at selection -- &8 track if no RA -- &16 track if no items
        
        -- source track
        CONF_unmutesends = 0,
        CONF_enablemasterfx = 0,
        
        -- render props / format 
        CONF_tail = 0, -- 0 off 1 bars 2 seconds
        CONF_tail_len = 0,
        CONF_extendtotail = 0,
        CONF_bitdepth = 1,        
        CONF_outputname = 'render', 
        CONF_outputpath = 'renderinplace', 
        CONF_source_flags = 0, -- 1 mute items under RA -- 2 mute selected items -- 4 mute tracks
        
        -- dest track
        newtrackname = 'render',
        newtrackname2 = 'sends render',
        
        -- postproc
        CONF_glue = 0,
        
        
        
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_rendsel',
        UI_name = 'Render-in-place',
        
        upd = true, 
        rend_temp = {
          cnt_RA = 0,
          cnt_items = 0,
          cnt_tracks = 0,
          },
        rend = {}, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
          --['default'] = "CkNPTkZfZ2x1ZT0wCkNPTkZfbmFtZT1kZWZhdWx0CkNPTkZfc291cmNlPTE="
          
          }
        }
        
-------------------------------------------------------------------------------- INIT UI locals
for key in pairs(reaper) do _G[key]=reaper[key] end 
--local ctx
-------------------------------------------------------------------------------- UI init variables
UI = {}
-- font  
  UI.font='Arial'
  UI.font1sz=16
  UI.font2sz=14
  UI.font3sz=12
-- style
  UI.pushcnt = 0
  UI.pushcnt2 = 0
-- size / offset
  UI.spacingX = 4
  UI.spacingX_wind = 10
  UI.spacingY = 3
  UI.spacingY_wind = 10
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
  
  
-- special 
  UI.windowBg_plugin = 0x505050
  UI.butBg_green = 0x00B300
  UI.butBg_red = 0xB31F0F
  UI.combo_w = 230
  UI.combo_w2 = 180
  UI.indent = 10











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
  local w_min = 400
  local h_min = 640
  DATA.display_scrollbarw = 20
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags|  ImGui.WindowFlags_AlwaysVerticalScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    window_flags = window_flags | ImGui.WindowFlags_NoDocking
    window_flags = window_flags | ImGui.WindowFlags_TopMost
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
      UI.MAIN_PushStyle('StyleVar_WindowPadding',UI.spacingX_wind,UI.spacingY_wind)  
      UI.MAIN_PushStyle('StyleVar_FramePadding',10,5) 
      UI.MAIN_PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_ItemSpacing',UI.spacingX*2, UI.spacingY)
      UI.MAIN_PushStyle('StyleVar_ItemInnerSpacing',4,0)
      UI.MAIN_PushStyle('StyleVar_IndentSpacing',20)
      UI.MAIN_PushStyle('StyleVar_ScrollbarSize',DATA.display_scrollbarw)
    -- size
      UI.MAIN_PushStyle('StyleVar_GrabMinSize',30)
      UI.MAIN_PushStyle('StyleVar_WindowMinSize',w_min,h_min)
    -- align
      UI.MAIN_PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_SelectableTextAlign',0.01,0.5 )
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
    ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
      DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetWorkSize(Viewport) 
      
      --DATA.display_w_child = DATA.display_w - DATA.display_scrollbarw
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
      UI.calc_itemH = calcitemh + frameh * 2
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
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false 
  DATA:Render_Queue() 
  if EXT.CONF_unmutesends&2~=2 then DATA:Render_Glue()  end
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  
  -- handle xy
  DATA:handleViewportXYWH()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
  ---------------------------------------------------------------------
  function VF_GetMediaItemByGUID(optional_proj, itemGUID)
    local optional_proj0 = optional_proj or 0
    local itemCount = CountMediaItems(optional_proj);
    for i = 1, itemCount do
      local item = GetMediaItem(0, i-1);
      local retval, stringNeedBig = GetSetMediaItemInfo_String(item, "GUID", '', false)
      if stringNeedBig  == itemGUID then return item end
    end
  end 
-------------------------------------------------------------------------------- 
function  DATA:Render_Glue() 
  local project = DATA.rend_temp.project
  if DATA.rend_temp.schedule_glue ~= true then return end 
  if not DATA.rend_temp.schedule_glue_state then DATA.rend_temp.schedule_glue_state = 0 end
  
  -- init state
    if DATA.rend_temp.schedule_glue_state == 0 then
      DATA.rend_temp.fptoremove = {} for i = 1, #DATA.rend.pieces do DATA.rend_temp.fptoremove[#DATA.rend_temp.fptoremove+1] = DATA.rend.pieces[i].outputfp end 
      -- DATA:Render_Glue_SelectOutputPieces() 
      -- Main_OnCommandEx( 40362, 0, project ) -- Item: Glue items, ignoring time selection
      
      -- set dest track solo
      SetMediaTrackInfo_Value( DATA.rend.destinationtrptr, 'I_SOLO',1) 
      -- set render params
      local outputpath,outputfile,outputfp = DATA:Render_GetFileOutput()
      local boundary_st = DATA.rend.boundary_st
      local boundary_end = DATA.rend.boundary_end
      GetSetProjectInfo( project, 'RENDER_CHANNELS', 2, true ) -- chan cnt
      GetSetProjectInfo( project, 'RENDER_STARTPOS', boundary_st, true ) -- bound start
      GetSetProjectInfo( project, 'RENDER_ENDPOS', boundary_end, true ) -- bound end
      GetSetProjectInfo_String( project, 'RENDER_FILE', outputpath, true )
      GetSetProjectInfo_String( project, 'RENDER_PATTERN', outputfile, true )  
      -- set master fx off
      DATA.rend_temp.glue_outputfp = outputfp
      local mastertr = reaper.GetMasterTrack(project) 
      SetMediaTrackInfo_Value( mastertr, 'I_FXEN',0 )
      -- render
      Main_OnCommandEx( 42230, 0, project ) -- File: Render project, using the most recent render settings, auto-close render dialog
      DATA.rend_temp.schedule_glue_state = 1
      return
    end
  
  -- processing
    if DATA.rend_temp.schedule_glue_state == 1 then
      local playstate = GetPlayStateEx( project )
      if playstate&1==1 then -- is rendering
        return
       else
        -- disable solo for dest track 
        SetMediaTrackInfo_Value( DATA.rend.destinationtrptr, 'I_SOLO',0) 
        -- restore master fx 
        if EXT.CONF_enablemasterfx&1==1 then
          local mastertr = reaper.GetMasterTrack(project) 
          SetMediaTrackInfo_Value( mastertr, 'I_FXEN', DATA.rend_temp.masterfxenabled ) 
        end
        -- insert glue render
        local t = {
          outputfp = DATA.rend_temp.glue_outputfp,
          boundary_st = DATA.rend.boundary_st,
          boundary_end = DATA.rend.boundary_end,
          } 
        DATA:Render_InsertMedia(t) 
        -- remove temporary items / files
        DATA:Render_Glue_RemoveOutputPieces()  
        if DATA.rend_temp.fptoremove then 
          for i = 1, #DATA.rend_temp.fptoremove do os.remove(DATA.rend_temp.fptoremove[i]) end 
          DATA.rend_temp.fptoremove = nil
        end 
        --reset states
        DATA.rend_temp.schedule_glue = nil
        DATA.rend_temp.schedule_glue_state = nil
        DATA:Render_Finish()
      end
    end 
  
end
-------------------------------------------------------------------------------- 
function  DATA:Render_Glue_RemoveOutputPieces()  
  local project = DATA.rend_temp.project
  SelectAllMediaItems( project, false )
  for i = 1, #DATA.rend.pieces do  
    local itemGUID = DATA.rend.pieces[i].itemGUID
    local item = VF_GetMediaItemByGUID(project, itemGUID)
    if item and reaper.ValidatePtr2(project, item, 'MediaItem*') then DeleteTrackMediaItem( reaper.GetMediaItemTrack( item ), item ) end
  end
end
-------------------------------------------------------------------------------- 
function DATA:Render_Finish()
  PreventUIRefresh( -1 )
  DATA.upd = true -- trigger resfresh
  DATA:Render_CurrentConfig_Restore() 
  Main_OnCommandEx( 40047, 0, project ) -- Peaks: Build any missing peaks 
  Undo_OnStateChange2( project, 'MPL Render-in-place' )
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) end
-------------------------------------------------------------------------------- 
function UI.MAIN() 
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
  EXT_defaults = VF_CopyTable(EXT)
  EXT:load() 
  DATA.PRESET_GetExtStatePresets()
  UI.MAIN() 
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
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
--------------------------------------------------------------------- 
function DATA.PRESET_GetCurrentPresetData()
  local str = ''
  for key in spairs(EXT) do if key:match('CONF_') then str = str..'\n'..key..'='..EXT[key] end end
  return DATA.PRESET_encBase64(str)
end 
--------------------------------------------------------------------- 
function DATA.PRESET_GetExtStatePresets()
  DATA.presets = {} 
  DATA.presets.factory = DATA.presets_factory
  DATA.presets.user = table.load( EXT.preset_base64_user ) or {}
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
function DATA.PRESET_ApplyPreset(base64str)  
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
  EXT:save() 
end
--------------------------------------------------------------------------------  
function UI.draw_preset() 
  -- preset 
  local select_wsz = 250
  local select_hsz = UI.calc_itemH
  UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Preset') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
  ImGui.SetCursorPosX( ctx, DATA.display_w-UI.combo_w-UI.spacingX_wind )
  ImGui.SetNextItemWidth( ctx, UI.combo_w )  
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
      EXT.preset_base64_user = table.save(DATA.presets.user)
      EXT:save() 
    end
    local id = 0
    for preset in spairs(DATA.presets.factory) do
      id = id + 1
      if ImGui.Selectable(ctx, '[F] '..preset..'##factorypresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.factory[preset])
        EXT:save() 
      end
    end 
    local id = 0
    for preset in spairs(DATA.presets.user) do
      id = id + 1
      if ImGui.Selectable(ctx, preset..'##userpresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.user[preset])
        EXT:save() 
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Remove##remove'..id) then 
        DATA.presets.user[preset] = nil
        EXT.preset_base64_user = table.save(DATA.presets.user)
        EXT:save() 
      end
    end 
    ImGui.EndCombo(ctx) 
  end  
end
--------------------------------------------------------------------------------  
function UI.draw_settings() 
  
  local comb_sel_x = DATA.display_w-UI.combo_w-UI.spacingX_wind*2-DATA.display_scrollbarw-UI.spacingX*2
  local comb_sel_x2 = DATA.display_w-UI.combo_w2-UI.spacingX_wind*2-DATA.display_scrollbarw-UI.spacingX*2
  local project = DATA.rend_temp.project
  if reaper.ImGui_BeginChild( ctx, '##settings',nil,nil,reaper.ImGui_ChildFlags_Border()) then
  
  
  -- Source
  ImGui.SeparatorText(ctx, 'Source')   
  if reaper.ImGui_Checkbox(ctx, 'Razor areas ('..(DATA.rend_temp.cnt_RA or 0)..')',EXT.CONF_source&1==1) then EXT.CONF_source = EXT.CONF_source~1 EXT:save() end
  if reaper.ImGui_Checkbox(ctx, 'Selected items ('..(DATA.rend_temp.cnt_items or 0)..')',EXT.CONF_source&2==2) then EXT.CONF_source = EXT.CONF_source~2 EXT:save() end  
  if reaper.ImGui_Checkbox(ctx, 'Track time selection ('..(DATA.rend_temp.cnt_tracks or 0)..')',EXT.CONF_source&4==4) then EXT.CONF_source = EXT.CONF_source~4 EXT:save() end
  if EXT.CONF_source&4==4 then 
    ImGui.Indent(ctx, UI.indent) 
    if reaper.ImGui_Checkbox(ctx, 'If no razor areas presented',EXT.CONF_source&8==8) then EXT.CONF_source = EXT.CONF_source~8 EXT:save() end  
    if reaper.ImGui_Checkbox(ctx, 'If no selected items presented',EXT.CONF_source&16==16) then EXT.CONF_source = EXT.CONF_source~16 EXT:save() end  
    ImGui.Unindent(ctx, UI.indent)
  end  
  
  -- src track prepare
  ImGui.SeparatorText(ctx, 'Preparation')
  if reaper.ImGui_Checkbox(ctx, 'Enable sends',EXT.CONF_unmutesends&1==1) then EXT.CONF_unmutesends = EXT.CONF_unmutesends~1 EXT:save() end  ImGui.SetItemTooltip(ctx, 'Unmute destination sends before render')
  if EXT.CONF_unmutesends&1==1 then
    ImGui.Indent(ctx, UI.indent) 
    if reaper.ImGui_Checkbox(ctx, 'Render sends separately',EXT.CONF_unmutesends&2==2) then EXT.CONF_unmutesends = EXT.CONF_unmutesends~2 EXT:save() end  
    ImGui.Unindent(ctx, UI.indent)
  end
  if reaper.ImGui_Checkbox(ctx, 'Enable master FX',EXT.CONF_enablemasterfx&1==1) then EXT.CONF_enablemasterfx = EXT.CONF_enablemasterfx~1 EXT:save() end
  
  
  -- Properties
  ImGui.SeparatorText(ctx, 'Render properties / format')  
  -- tail
    UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Tail mode') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx) 
    ImGui.SetNextItemWidth( ctx, UI.combo_w2 ) 
    ImGui.SetCursorPosX( ctx, comb_sel_x2 )
    local names = {
     'Off',
     'Bars.beats',
     'Seconds'}
    local preview = names[EXT.CONF_tail+1] or '' if ImGui.BeginCombo(ctx, '##tail', preview) then for i = 1, #names do if ImGui.Selectable(ctx, names[i]) then EXT.CONF_tail = i-1 EXT:save() end end ImGui.EndCombo(ctx) end 
  -- tail length
    if EXT.CONF_tail >0 then
      UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Tail length') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
      ImGui.SetNextItemWidth( ctx, UI.combo_w2 ) 
      ImGui.SetCursorPosX( ctx, comb_sel_x2 )
      local ret, buf = ImGui.InputText(ctx,'##taillen',EXT.CONF_tail_len)--, ImGui.InputTextFlags_EnterReturnsTrue) 
      if ret and tonumber(buf) then
        EXT.CONF_tail_len = tonumber(buf)
        EXT:save()
      end
      if reaper.ImGui_Checkbox(ctx, 'Extend rendered media for tail',EXT.CONF_extendtotail&1==1) then EXT.CONF_extendtotail = EXT.CONF_extendtotail~1 EXT:save() end 
    end
  -- bitdepth
    UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Bit depth') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx) 
    ImGui.SetNextItemWidth( ctx, UI.combo_w2 ) 
    ImGui.SetCursorPosX( ctx, comb_sel_x2 )
    local names = {
     '16bit PCM',
     '24bit PCM',
     '32bit FP',
     '64bit FP',
     }
    local preview = names[EXT.CONF_bitdepth] or '' if ImGui.BeginCombo(ctx, '##bitdepth', preview) then for i = 1, #names do if ImGui.Selectable(ctx, names[i]) then EXT.CONF_bitdepth = i EXT:save() end end ImGui.EndCombo(ctx) end
  -- name
    --UI.draw_setbuttonbackgtransparent() 
    if ImGui.Button(ctx, 'Sub folder') then
      local project = DATA.rend_temp.project
      local outputpath = GetProjectPathEx( project )..'/'
      if EXT.CONF_outputpath ~= '' then outputpath = outputpath..EXT.CONF_outputpath end
      outputpath = outputpath:gsub('\\','/')
      reaper.RecursiveCreateDirectory(outputpath,0)
      os.execute('start "" "'..outputpath..'"')
    end
    --UI.draw_unsetbuttonstyle() 
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth( ctx, UI.combo_w ) 
    ImGui.SetCursorPosX( ctx, comb_sel_x )
    local ret, buf = ImGui.InputText(ctx,'##custpath',EXT.CONF_outputpath)
    if ret and buf and buf ~= '' then  
      EXT.CONF_outputpath = buf:gsub('[%/%\\%:%*%?%<%>%|%"]', '') -- prevent wrong names
      EXT:save() 
    end
    -- name
    UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Filename') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth( ctx, UI.combo_w ) 
    ImGui.SetCursorPosX( ctx, comb_sel_x )
    local ret, buf = ImGui.InputText(ctx,'##custname',EXT.CONF_outputname)
    if ret and buf and buf ~= '' then  
      EXT.CONF_outputname = buf:gsub('[%/%\\%:%*%?%<%>%|%"]', '') -- prevent wrong names
      EXT:save() 
    end
    
  
  
    -- Postprocessing
    ImGui.SeparatorText(ctx, 'Postprocessing') 
    -- glue
    if EXT.CONF_unmutesends&2==2 then ImGui.BeginDisabled( ctx, true ) end
    if reaper.ImGui_Checkbox(ctx, 'Glue',EXT.CONF_glue&1==1) then EXT.CONF_glue = EXT.CONF_glue~1 EXT:save() end   ImGui.SetItemTooltip(ctx, 'Glue result + remove temp renders from disk. Not available for render sends separately.')
    if EXT.CONF_unmutesends&2==2 then ImGui.EndDisabled( ctx ) end
    -- tr name
    UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Track 1 name') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth( ctx, UI.combo_w ) 
    ImGui.SetCursorPosX( ctx, comb_sel_x )
    local ret, buf = ImGui.InputText(ctx,'##trcustname',EXT.newtrackname)
    if ret and buf then  
      EXT.newtrackname = buf:gsub('[%/%\\%:%*%?%<%>%|%"]', '') 
      EXT:save() 
    end  
    -- tr name
    UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Track 2 name') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth( ctx, UI.combo_w ) 
    ImGui.SetCursorPosX( ctx, comb_sel_x )
    local ret, buf = ImGui.InputText(ctx,'##trcustname2',EXT.newtrackname2)
    if ret and buf then  
      EXT.newtrackname2 = buf:gsub('[%/%\\%:%*%?%<%>%|%"]', '') 
      EXT:save() 
    end  
  
  
    --[[ Source event settings
      
    ImGui.SeparatorText(ctx, 'Source events')  
    if reaper.ImGui_Checkbox(ctx, 'Mute items under razor',EXT.CONF_source_flags&1==1) then EXT.CONF_source_flags = EXT.CONF_source_flags~1 EXT:save() end
    if reaper.ImGui_Checkbox(ctx, 'Mute selected items',EXT.CONF_source_flags&2==2) then EXT.CONF_source_flags = EXT.CONF_source_flags~2 EXT:save() end
    if reaper.ImGui_Checkbox(ctx, 'Mute selected tracks',EXT.CONF_source_flags&4==4) then EXT.CONF_source_flags = EXT.CONF_source_flags~4 EXT:save() end
    ]]
    reaper.ImGui_EndChild( ctx )
  end
  
end
--------------------------------------------------------------------------------  
function UI.draw() 
  ImGui.PushStyleVar(ctx,ImGui.StyleVar_WindowPadding,UI.spacingX_wind,UI.spacingY) -- limit Y indent for menus 
  -- preset
    UI.draw_preset() 
  -- render
    --ImGui.SetCursorPosX( ctx, DATA.display_w-UI.combo_w2-UI.spacingX_wind )
    if ImGui.Button(ctx, 'Render',DATA.display_w-UI.spacingX_wind*2)  then DATA:Render() end--,UI.combo_w2
  -- settings
    UI.draw_settings() 
  ImGui.PopStyleVar(ctx)
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
  local SCC =  GetProjectStateChangeCount( -1 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
end
---------------------------------------------------------------------- 
function base64_enc(data)  -- http://lua-users.org/wiki/BaseSixtyFour
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
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
-------------------------------------------------------------------------------
function DATA:Render_CurrentConfig_Store()
  local project = DATA.rend_temp.project
  local retval, RENDER_FORMAT = GetSetProjectInfo_String( project, 'RENDER_FORMAT', '', false )
  local retval, RENDER_FORMAT2 = GetSetProjectInfo_String( project, 'RENDER_FORMAT2', '', false )
  DATA.rend_temp = {RENDER_FORMAT=RENDER_FORMAT,RENDER_FORMAT2=RENDER_FORMAT2} 
end
-------------------------------------------------------------------------------
function DATA:Render_CurrentConfig_Restore()
  local project = DATA.rend_temp.project
  if not DATA.rend_temp.RENDER_FORMAT then return end
  GetSetProjectInfo_String( project, 'RENDER_FORMAT', DATA.rend_temp.RENDER_FORMAT, true )
  GetSetProjectInfo_String( project, 'RENDER_FORMAT2', DATA.rend_temp.RENDER_FORMAT2, true )
end 
-------------------------------------------------------------------------------
function DATA:CollectData_GetRazorAreas() 
  if EXT.CONF_source&1~=1 then return end -- do not collect razor if not set in source 
  
  local project = DATA.rend_temp.project
  local cnttracks = CountTracks(project)
  for i = 1, cnttracks do
    local tr = GetTrack(project,i-1) 
    local retval, trGUID = GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
    local retval, razorStr = GetSetMediaTrackInfo_String( tr, 'P_RAZOREDITS', '', false )
    if retval then 
    
      for razorLeft, razorRight, envGuid in razorStr:gmatch('([%d%.]+) ([%d%.]+) "([^"]*)"') do
        local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
        if envGuid == '' then
          DATA.rend_temp.cnt_RA = DATA.rend_temp.cnt_RA + 1
          DATA.rend.pieces[#DATA.rend.pieces + 1] = 
            { trGUID = trGUID,
              boundary_st = razorLeft,
              boundary_end = razorRight,
              mode = 1,
              state = 0,
              }
        end
      end
      
    end
  end
  
  
  
end
-------------------------------------------------------------------------------
function DATA:CollectData_GetSelectedItems()
  if EXT.CONF_source&2~=2 then return end -- do not collect if not set in source   
  
  
  local project = DATA.rend_temp.project
  local it_cnt = CountMediaItems( project )
  for i = 1, it_cnt do
    local item = GetMediaItem( project, i-1 )
    if IsMediaItemSelected( item ) then
       
      local tr = GetMediaItemTrack( item )
      local retval, trGUID = GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      local itempos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local itemlen = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      
      DATA.rend_temp.cnt_items = DATA.rend_temp.cnt_items + 1
      
      DATA.rend.pieces[#DATA.rend.pieces + 1] = 
        { trGUID = trGUID,
          boundary_st = itempos,
          boundary_end = itempos+itemlen,
          mode = 2,
          state = 0,
          }
    end
  end
end
-------------------------------------------------------------------------------
function DATA:CollectData_GetTrackSelection()
  
  local project = DATA.rend_temp.project
  
  if EXT.CONF_source&4~=4 then return end -- do not collect if not set in source  
  
  
  if EXT.CONF_source&8==8 and DATA.rend_temp.cnt_RA > 0 then return end
  if EXT.CONF_source&16==16 and DATA.rend_temp.cnt_items > 0 then return end
  
  local boundary_st, boundary_end = reaper.GetSet_LoopTimeRange2( project, false, false ,0, 0, false ) 
  local cntseltracks = CountSelectedTracks( project )
  local cntselitems = 0
  
  if boundary_end  - boundary_st < 0.1 then 
    boundary_end = reaper.GetProjectLength( project )
    boundary_st = 0
  end
   
  for i = 1, cntseltracks do
    local tr = reaper.GetSelectedTrack(project, i-1)
    local retval, trGUID = GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
    DATA.rend_temp.cnt_tracks = DATA.rend_temp.cnt_tracks + 1
    DATA.rend.pieces[#DATA.rend.pieces + 1] = 
      { trGUID = trGUID,
        boundary_st = boundary_st,
        boundary_end = boundary_end,
        mode = 4,
        state = 0,
        } 
  end
   
  
end 
-------------------------------------------------------------------------------
function DATA:Render_GetFileOutput()
  local project = DATA.rend_temp.project
  local outputpath = GetProjectPathEx( project )..'/'
  if EXT.CONF_outputpath ~= '' then outputpath = outputpath..EXT.CONF_outputpath..'/' end
  local outputfile = EXT.CONF_outputname..os.date('%d%m%y_%H%M%S') 
  local outputfp = outputpath..outputfile..'.wav'
  if file_exists(outputfp) then -- prevent files rendered in the same second be overwritten
    local msec = math.floor(1000*(reaper.time_precise()%1))
    outputfile = 'mixdown'..os.date('%d%m%y_%H%M%S') ..msec
    outputfp = outputpath..'/'..outputfile..'.wav'
  end
  return outputpath,outputfile,outputfp
end
-------------------------------------------------------------------------------
function DATA:Render_Piece_State_StoreAndSet(t) 
  local project = DATA.rend_temp.project  
  local cur_tr = VF_GetMediaTrackByGUID(project, t.trGUID)
  if not cur_tr then return end
  
  
  DATA.rend_temp.solostate = {}
  DATA.rend_temp.mutestate = {}
  DATA.rend_temp.sends = {}
  local trcnt = reaper.CountTracks( project )
  DATA.rend_temp.trcnt = trcnt
  
  
  -- store sends
  for sendidx = 1, GetTrackNumSends( cur_tr, 0 ) do
    DATA.rend_temp.sends[sendidx] = {
      ['B_MUTE'] = reaper.GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MUTE' ),
    }
  end
  
  -- store solo/mute
  for i = 1, DATA.rend_temp.trcnt do 
    local tr = GetTrack(0,i-1)
    local retval, trGUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID','',false)
    DATA.rend_temp.solostate[trGUID] = GetMediaTrackInfo_Value( tr, 'I_SOLO' ) 
    SetMediaTrackInfo_Value( tr, 'I_SOLO', 0) 
    DATA.rend_temp.mutestate[trGUID] = GetMediaTrackInfo_Value( tr, 'B_MUTE' ) 
    SetMediaTrackInfo_Value( tr, 'B_MUTE', 1) 
  end
  
  -- disable master fx
    if EXT.CONF_enablemasterfx&1==1 then
      local mastertr = reaper.GetMasterTrack(project) 
      DATA.rend_temp.masterfxenabled = GetMediaTrackInfo_Value( mastertr, 'I_FXEN' )
      SetMediaTrackInfo_Value( mastertr, 'I_FXEN',0 )
    end
   
 -- mute track
    SetMediaTrackInfo_Value( cur_tr, 'B_MUTE', 0  )
    if EXT.CONF_unmutesends&1==1 then
    
      if EXT.CONF_unmutesends&2~=2 then -- render separately
        local cntsends = GetTrackNumSends( cur_tr, 0 ) for sendidx = 1, cntsends do local P_DESTTRACK = GetTrackSendInfo_Value( cur_tr, 0, sendidx-1, 'P_DESTTRACK' ) SetMediaTrackInfo_Value( P_DESTTRACK, 'B_MUTE', 0  ) end -- enable sends
       else
        if not (t.options_sendonly and t.options_sendonly==true) then
          local cntsends = GetTrackNumSends( cur_tr, 0 ) for sendidx = 1, cntsends do local P_DESTTRACK = GetTrackSendInfo_Value( cur_tr, 0, sendidx-1, 'P_DESTTRACK' ) SetMediaTrackInfo_Value( P_DESTTRACK, 'B_MUTE', 0  ) end -- enable sends
          DATA.rend_temp.B_MAINSEND = GetMediaTrackInfo_Value( cur_tr, 'B_MAINSEND' )
          SetMediaTrackInfo_Value( cur_tr, 'B_MAINSEND',0 )
        end 
      end
      
   end
     
end
-------------------------------------------------------------------------------
function DATA:Render_Piece_State_Restore(t) 
  local project = DATA.rend_temp.project
  
  local cur_tr = VF_GetMediaTrackByGUID(project, t.trGUID)
  if not cur_tr then return end
  
  -- restore main send
    if DATA.rend_temp.B_MAINSEND then SetMediaTrackInfo_Value( cur_tr, 'B_MAINSEND', DATA.rend_temp.B_MAINSEND ) end
    
  -- restore sends
    for sendidx = 1, GetTrackNumSends( cur_tr, 0 ) do
      reaper.SetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MUTE', DATA.rend_temp.sends[sendidx].B_MUTE )
    end
  
  -- cache pointers
    local GUID_map = {} for i= 1, CountTracks(project) do 
      local tr = GetTrack(0,i-1 ) 
      local retval, trGUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID','',false) 
      GUID_map[trGUID] = tr 
    end 
  -- restore solo/mute
    for trGUID in pairs(DATA.rend_temp.solostate) do  
      local tr = GUID_map[trGUID]
      SetMediaTrackInfo_Value( tr, 'I_SOLO',DATA.rend_temp.solostate[trGUID]) 
      SetMediaTrackInfo_Value( tr, 'B_MUTE',DATA.rend_temp.mutestate[trGUID]) 
    end 
      
  -- restore master fx 
    if EXT.CONF_enablemasterfx&1==1 then
      local mastertr = reaper.GetMasterTrack(project) 
      SetMediaTrackInfo_Value( mastertr, 'I_FXEN', DATA.rend_temp.masterfxenabled )  
    end  
    
end
-------------------------------------------------------------------------------
function DATA:Render_Piece_SetRenderConfig(t) 
    local outputpath,outputfile,outputfp = DATA:Render_GetFileOutput()
    t.outputfp = outputfp 
    GetSetProjectInfo( project, 'RENDER_CHANNELS', 2, true ) -- chan cnt
    GetSetProjectInfo( project, 'RENDER_STARTPOS', t.boundary_st, true ) -- bound start
    GetSetProjectInfo( project, 'RENDER_ENDPOS', t.boundary_end, true ) -- bound end
    GetSetProjectInfo_String( project, 'RENDER_FILE', outputpath, true )
    GetSetProjectInfo_String( project, 'RENDER_PATTERN', outputfile, true ) 
    --[[
    extstate_val = 'test'
    GetSetProjectInfo_String( project, 'RENDER_METADATA', 'ID3:TXXX:ExtState|'..extstate_val, true) -- retval, buf = reaper.GetMediaFileMetadata( mediaSource, identifier )
    ]]  
end
-------------------------------------------------------------------------------
function DATA:Render_Piece(t) 
  local project = DATA.rend_temp.project 
  
  -- handle state
  if t.state == 1 then -- render action was triggered
    local playstate = GetPlayStateEx( project )
    if playstate&1==1 then -- is rendering
      return -- leave state =1 s othe following not being processed 
     else -- rendering is finished
      DATA:Render_Piece_State_Restore(t) 
      if EXT.CONF_unmutesends&2~=2 then
        DATA:Render_InsertMedia(t)
       else
        DATA:Render_InsertMedia(t,not (t.options_track2 and t.options_track2==true)) -- should be vice verse but it works
      end
      t.state = 2-- set state as processed
      return 
    end
   elseif t.state == 2 then -- already processed
    return
  end
  
  -- first time run
  DATA:Render_Piece_SetRenderConfig(t) 
  DATA:Render_Piece_State_StoreAndSet(t) 
  Main_OnCommandEx( 42230, 0, project ) -- File: Render project, using the most recent render settings, auto-close render dialog
  t.state = 1
  
end
------------------------------------------------------------------------------------------------------  
function VF_GetMediaTrackByGUID(optional_proj, GUID)
  local optional_proj0 = optional_proj or 0
  for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
  local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
end  
---------------------------------------------------
function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CopyTable(orig_key)] = CopyTable(orig_value)
        end
        setmetatable(copy, CopyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
-------------------------------------------------------------------------------  
function DATA:CollectData() 
  if DATA.rend_temp.schedule_glue == true or DATA.rend_temp.schedule == true then return end -- exit if is in progress
  local project, projfn = EnumProjects( -1 )
  DATA.rend_temp.project = project 
  DATA.rend_temp.cnt_RA = 0
  DATA.rend_temp.cnt_items = 0
  DATA.rend_temp.cnt_tracks = 0
  DATA.rend_temp.needsecond_track = nil
  
  DATA.rend.pieces = {}
  DATA:CollectData_GetRazorAreas()
  DATA:CollectData_GetSelectedItems()
  DATA:CollectData_GetTrackSelection()
  
  if DATA.rend.pieces[1] and DATA.rend.pieces[1].trGUID then DATA.rend.firsttrGUID = DATA.rend.pieces[1].trGUID end
  
  local cntpieces = #DATA.rend.pieces
  for i = 1, cntpieces do
    DATA.rend.boundary_st = math.min(DATA.rend.boundary_st or math.huge, DATA.rend.pieces[i].boundary_st)
    DATA.rend.boundary_end = math.max(DATA.rend.boundary_end or 0, DATA.rend.pieces[i].boundary_end)
    local t = DATA.rend.pieces[i]
    t.idx= i
    local cur_tr = VF_GetMediaTrackByGUID(project, t.trGUID)
    
    if EXT.CONF_unmutesends&2==2 and GetTrackNumSends( cur_tr, 0 )>0 then
      t.has_sends = true
      DATA.rend_temp.needsecond_track = true
      local newID = #DATA.rend.pieces + 1
      DATA.rend.pieces[newID] = CopyTable(t)
      t.idx= newID
      DATA.rend.pieces[newID].options_sendonly = true
      DATA.rend.pieces[newID].options_track2 = true
    end
  end 
end
-------------------------------------------------------------------------------
function DATA:Render_AddTrack() 
  local project = DATA.rend_temp.project
  if not DATA.rend.firsttrGUID then return end
  
  local firsttr = VF_GetMediaTrackByGUID(project, DATA.rend.firsttrGUID)
  local tracknum = GetMediaTrackInfo_Value( firsttr, 'IP_TRACKNUMBER')
  if tracknum < 1 then return end
  InsertTrackInProject( 0, tracknum, 0 )
  local tr = GetTrack(0,tracknum)
  local retval, trGUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID','',false)
  DATA.rend.destinationtrGUID = trGUID 
  DATA.rend.destinationtrptr = tr
  DATA.rend.destinationtrID = tracknum
  GetSetMediaTrackInfo_String(tr,'P_NAME',EXT.newtrackname,1) 
  
  if DATA.rend_temp.needsecond_track == true then
    InsertTrackInProject( 0, tracknum+1, 0 )
    local tr = GetTrack(0,tracknum+1)
    local retval, trGUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID','',false)
    DATA.rend.destinationtrGUID2 = trGUID 
    DATA.rend.destinationtrptr2 = tr
    DATA.rend.destinationtrID2 = tracknum+1
    GetSetMediaTrackInfo_String(tr,'P_NAME',EXT.newtrackname2,1) 
  end
  
  return true
end
-------------------------------------------------------------------------------
function DATA:Render_CurrentConfig_SetGlobalParams()
  local project = DATA.rend_temp.project
  
  GetSetProjectInfo( project, 'RENDER_SETTINGS', 0|512, true ) -- master mix | &512 embed metadata if format supports
  GetSetProjectInfo( project, 'RENDER_BOUNDSFLAG', 0, true ) -- custom time bounds
  GetSetProjectInfo( project, 'RENDER_SRATE', 0, true ) -- project sample rate  
  
  if EXT.CONF_tail == 0 then 
    GetSetProjectInfo( project, 'RENDER_TAILFLAG', 0, true )
   else
    GetSetProjectInfo( project, 'RENDER_TAILFLAG', 1, true )
  end
  
  local tail_len = EXT.CONF_tail_len * 1000
  if EXT.CONF_tail == 1 then tail_len = 1000 * TimeMap2_beatsToTime( project, EXT.CONF_tail_len ) end
  DATA.rend_temp.tail_len=tail_len/1000
  GetSetProjectInfo( project, 'RENDER_TAILMS', tail_len, true )
  GetSetProjectInfo( project, 'RENDER_ADDTOPROJ', 0, true ) -- do not add to project
  GetSetProjectInfo( project, 'RENDER_NORMALIZE', 0, true ) -- normalize off
  GetSetProjectInfo( project, 'RENDER_FADEIN', 0, true )
  GetSetProjectInfo( project, 'RENDER_FADEOUT', 0, true )
  --[[
   '16bit PCM',
   '24bit PCM',
   '32bit FP',
   '64bit FP',
  ]]
  local form_conf = { [1]=16, [2]=1} 
  if EXT.CONF_bitdepth == 1 then form_conf[1] = 16 
    elseif EXT.CONF_bitdepth == 2 then form_conf[1] = 24 
    elseif EXT.CONF_bitdepth == 3 then form_conf[1] = 32 
    elseif EXT.CONF_bitdepth == 4 then form_conf[1] = 64 
  end
  local out_str = '' for i = 1, #form_conf do if not form_conf[i] then form_conf[i] = 0 end out_str = out_str..tostring(form_conf[i]):char() end
  GetSetProjectInfo_String(0, 'RENDER_FORMAT', base64_enc('evaw'..out_str), true)
  GetSetProjectInfo_String(0, 'RENDER_FORMAT2', '', true) -- reset secondary format
end
-------------------------------------------------------------------------------
function DATA:Render()
  if not DATA.rend.pieces then return end
  local ret = DATA:Render_AddTrack()
  if not ret then return end
  
  PreventUIRefresh( 1 )
  DATA:Render_CurrentConfig_Store()
  DATA:Render_CurrentConfig_SetGlobalParams() 
  
  DATA.rend_temp.schedule = true -- start waiting 
  DATA.rend_temp.transportstopTS = nil -- reset TS
end

-------------------------------------------------------------------------------
function DATA:Render_Queue()  
  local project = DATA.rend_temp.project
  if DATA.rend_temp.schedule ~= true then return end
  for i = 1, #DATA.rend.pieces do  
    DATA:Render_Piece(DATA.rend.pieces[i]) 
    local t = DATA.rend.pieces[i]
    if t.state == 1 then return end -- stop following pieces render if current one is in progress 
  end
  
  DATA.rend_temp.schedule = nil 
  
  if EXT.CONF_glue&1==1 then 
    Undo_OnStateChange2( project, 'Render-in-place: prerender' )
    DATA.rend_temp.schedule_glue = true 
   else
    DATA:Render_Finish()
  end
end
-------------------------------------------------------------------------------
function DATA:Render_InsertMedia(t, secondtrack) 
  if not DATA.rend.destinationtrID then return end 
  local project = DATA.rend_temp.project
  local src = PCM_Source_CreateFromFile( t.outputfp )
  local new_item
  if secondtrack ~= true then  
    new_item = AddMediaItemToTrack( DATA.rend.destinationtrptr )
   else 
    new_item = AddMediaItemToTrack( DATA.rend.destinationtrptr2 )
  end
  local new_take = AddTakeToMediaItem( new_item )
  SetMediaItemTake_Source( new_take, src )
  SetMediaItemInfo_Value( new_item, 'D_POSITION', t.boundary_st )
  local outlen = t.boundary_end - t.boundary_st
  if DATA.rend_temp.tail_len and EXT.CONF_extendtotail == 1 then outlen = outlen + DATA.rend_temp.tail_len end
  SetMediaItemInfo_Value( new_item, 'D_LENGTH',  outlen )
  PCM_Source_BuildPeaks( src, 0 )
  reaper.UpdateItemInProject( new_item ) 
  local retval, itemGUID = reaper.GetSetMediaItemInfo_String( new_item, 'GUID', '', false )
  t.itemGUID = itemGUID
end
-------------------------------------------------------------------------------
main()
  
  
  
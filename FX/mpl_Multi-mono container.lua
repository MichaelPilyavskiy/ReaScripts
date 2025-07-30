-- @description Multi-mono container
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Convert any plugin into multi-mono container and managing it
-- @changelog
--    + initial release


--[[
  Limitations:
    - plugins should always end with "MMC - master" or "MMC - chX"
    - "MMC - master" should always exist and placed at first slot of container
]]

--------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    vrsmin = 7.06
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < vrsmin then return reaper.MB('This script require REAPER '..vrsmin..'+','',0) end
    local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.9.3.2'
    
    
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = { 
          -- UI
          CONF_chan_config = 1,
          CONF_create_autoincreasetrackch = 1, 
          CONF_link_params = 1,
         }
        
  -------------------------------------------------------------------------------- INIT data
  DATA = { 
          upd = true,
          upd2 = {},
          ES_key = 'MPL_MultiMonoContainer',
          UI_name = 'Multi-mono container', 
          plugindata = {},
          max_channels = 32, -- if you wnt to set motre you have to add high mask in DATA:Container_Build_SetPinMappings
          }
  
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
      -- font
        font='Arial',
        font1sz=16,
        font2sz=15,
        font3sz=13,
      -- mouse
        hoverdelay = 0.8,
        hoverdelayshort = 0.5,
      -- size / offset
        spacingX = 4,
        spacingY = 3,  
        frame_rounding = 3, 
        instanceW = 150,
        instaddW = 38,
        FramePaddingX = 6,
      -- colors / alpha
        main_col = 0x7F7F7F, -- grey
        textcol = 0xFFFFFF, -- white
        col_maintheme = 0x00B300 ,-- green,
        col_red = 0xB31F0F  ,
        textcol_a_enabled = 1,
        textcol_a_disabled = 0.5,
        but_hovered = 0x878787,
        windowBg = 0x303030,
        
        }
    
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  ------------------------------------------------------- 
  function VF_BFpluginparam_str2num(str) local str = str:match('[%d%-%.]+') if str then return tonumber(str) end end
  ------------------------------------------------------- 
  function VF_BFpluginparam(find_Str, tr, fx, param) 
    if not (find_Str and find_Str~= '' ) then return end
    
    local dest_val = VF_BFpluginparam_str2num(find_Str) 
    if not dest_val then return end
    
    local iterations = 100
    local min, max, mid = 0,1,0.5
    for i = 1, iterations do -- iterations
      mid = min + 0.5*(max - min) 
      TrackFX_SetParamNormalized( tr, fx, param, mid )
      local _, buf = TrackFX_GetFormattedParamValue( tr , fx, param, '' )
      local val = VF_BFpluginparam_str2num(buf) 
      if val then 
        if val <= dest_val then 
          min = mid
         else
          max = mid
        end
      end
    end
    return mid
    
  end
  
  
  ---------------------------------------------------
  function VF_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
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
      UI.anypopupopen = ImGui.IsPopupOpen( ctx, 'mainRCmenu', ImGui.PopupFlags_AnyPopup|ImGui.PopupFlags_AnyPopupLevel )
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,350,350)
      
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
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
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,UI.frame_rounding)   
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
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,UI.FramePaddingX,UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,UI.spacingX, UI.spacingY) 
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX, UI.spacingY)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,4,0)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing,20)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,10)
    -- size
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,20)
      
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
      ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,         UI.Tools_RGBA(UI.windowBg, 1))
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      
      --ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      --ImGui.SetNextWindowDockID( ctx, EXT.viewport_dockID)
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font2) 
      local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) --
      if rv then
        local Viewport = ImGui.GetWindowViewport(ctx)
        DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
        DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
        DATA.display_x_work, DATA.display_y_work = ImGui.Viewport_GetWorkPos(Viewport)
        -- hidingwindgets
        DATA.display_whratio = DATA.display_w / DATA.display_h
        
        -- calc stuff for childs
        UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
        UI.calc_itemH = calcitemh + frameh * 2
         
        -- calc container stuff
        if DATA.plugindata and DATA.plugindata.container and DATA.plugindata.container.children and #DATA.plugindata.container.children ~= 0 then 
          local cnt_inst = #DATA.plugindata.container.children
          UI.calc_instanceW = (DATA.display_w - UI.spacingX*2 - UI.spacingX * (cnt_inst-1)) / cnt_inst
        end
        UI.calc_linkW = (DATA.display_w - UI.spacingX*3) / 2
        
        -- get drawlist
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        
        -- draw stuff
        UI.draw() 
        ImGui.Dummy(ctx,0,0) 
         
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
  function DATA:CollectData2() -- do various stuff after refresh main data 
    if not (DATA.upd2 and DATA.upd2.refresh == true) then return end
    
    DATA.upd2 = {} 
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_loop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    
    --DATA:CollectData_Always() 
    if DATA.upd == true then DATA:CollectData()  end 
    DATA.upd = false  
    DATA:CollectData2() -- do various stuff after refresh main data , use DATA.upd2
    
    
    -- draw UI
    if not reaper.ImGui_ValidatePtr( ctx, 'ImGui_Context*') then UI.MAIN_definecontext() end
    UI.open = UI.MAIN_styledefinition(true) 
    
    
    -- data
    if UI.open then defer(UI.MAIN_loop) else  
      
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
    -- config
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
    
    
    -- run loop
    defer(UI.MAIN_loop)
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
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
    local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
    local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
  end
  --------------------------------------------------------------------------------  
  function DATA:CollectData()  
    DATA.plugindata.valid = false
    DATA.plugindata.container = {}
    local track
    
    local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 0 )
    if retval ~= true then return end
    if itemidx ~= -1 then return end
    if trackidx == -1 then track = reaper.GetMasterTrack(-1) else track = GetTrack(-1,trackidx) end 
    local retval, paramname = TrackFX_GetParamName( track, fxidx, parm )
    local retval, fx_name = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' )
    DATA.plugindata.fx_name = fx_name
    
    if fx_name == 'Container' then return end
    
    DATA.plugindata.valid = true
    DATA.plugindata.fxidx = fxidx
    DATA.plugindata.track = track
    DATA.plugindata.parm = parm
    DATA.plugindata.paramname = paramname
    
    
    DATA.plugindata.fx_name_reduced = VF_ReduceFXname(fx_name)
    DATA.plugindata.I_NCHAN = GetMediaTrackInfo_Value( track, 'I_NCHAN' ) 
    DATA.plugindata.cntparams = TrackFX_GetNumParams( track, fxidx ) - 3
    local retval, inputPins, outputPins = reaper.TrackFX_GetIOSize( track, fxidx ) 
    DATA.plugindata.inputPins = inputPins
    DATA.plugindata.outputPins = outputPins
    
    local retval, parent_container = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'parent_container' )
    if not tonumber(parent_container) then 
      DATA.plugindata.container.valid = false
     else
      DATA.plugindata.container.valid = true
      DATA:CollectData_MMContainer(parent_container)  
    end
    
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_MMContainer(parent_container)  
    
    DATA.plugindata.container.parent_idx = tonumber(parent_container)
    
    local track = DATA.plugindata.track
    local retval, container_count = TrackFX_GetNamedConfigParm( track, parent_container, 'container_count' )
    local container_count = tonumber(container_count) 
    
    local num_channels_desired = DATA:Container_Build_GetNumCh() 
    
    -- validate instances
    DATA.plugindata.container.children = {}
    for channel = 1, num_channels_desired do DATA.plugindata.container.children[channel] = {} end 
    for container_item = 0, container_count-1 do
      local retval, child_instance = TrackFX_GetNamedConfigParm( track, parent_container, 'container_item.'..container_item )  child_instance = tonumber(child_instance)
      local retval, fx_name = reaper.TrackFX_GetNamedConfigParm( track, child_instance, 'fx_name' )
      local retval, renamed_name = reaper.TrackFX_GetNamedConfigParm( track, child_instance, 'renamed_name' ) 
      local open = TrackFX_GetOpen( track, child_instance )
      local channel_str = renamed_name:match('MMC %- (.*)')
      local channel 
      if channel_str:match('ch(%d+)') then 
        channel_str = channel_str:match('ch(%d+)')
        if channel_str and tonumber(channel_str) then channel = tonumber(channel_str) end
       elseif channel_str == 'master' then 
        channel = 1
      end
      local fxGUID = reaper.TrackFX_GetFXGUID( track, child_instance )
      if not (fx_name == DATA.plugindata.fx_name and channel) then goto skipnextitem end
      DATA.plugindata.container.children[channel] = { 
          valid = true,
          child_instance = child_instance,
          fx_name = fx_name,
          renamed_name = renamed_name,
          open=open,
          fxGUID = fxGUID
        } 
      ::skipnextitem::
    end
    
      
    -- get unlinked params
      DATA.plugindata.container.linkoverrides = {}
      local cntparams = DATA.plugindata.cntparams
      local slaves = #DATA.plugindata.container.children
      for param = 0, cntparams-1 do
          
        local has_overrides
        for channel = 2, slaves do 
          if DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].valid == true then 
            local destID = DATA.plugindata.container.children[channel].child_instance 
            local retval, paramname = TrackFX_GetParamName( track, destID, param )
            local retval, active = TrackFX_GetNamedConfigParm( track, destID, 'param.'..param..'.plink.active' )
            local retval, offset = TrackFX_GetNamedConfigParm( track, destID, 'param.'..param..'.plink.offset' ) 
            if not DATA.plugindata.container.linkoverrides[param] then DATA.plugindata.container.linkoverrides[param] = {name = paramname} end
            local value = TrackFX_GetParamNormalized( track, destID, param )
            local retval, value_format = TrackFX_GetFormattedParamValue(  track, destID, param )
            DATA.plugindata.container.linkoverrides[param][channel] = {
              destID = destID,
              active = tonumber(active),
              offset = tonumber(offset),
              value = value,
              value_format = value_format
            }
            if active == '0' or offset ~= '0' then has_overrides = true end
          end
        end
        if not has_overrides then DATA.plugindata.container.linkoverrides[param] = nil end
      end
     
    
    --[[ get param ids 
      DATA.plugindata.container.hintID = {}
      for param = 0, cntparams-1 do
        local retval, hint_id = TrackFX_GetNamedConfigParm( track, parent_container, 'param.'..param..'.container_map.hint_id' )  
        DATA.plugindata.container.hintID[param] = tonumber(hint_id)
      end
    ]]
    
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
  function UI.draw_settings()  
    if ImGui.Checkbox(ctx, 'Auto increase track channels', EXT.CONF_create_autoincreasetrackch == 1) then EXT.CONF_create_autoincreasetrackch = EXT.CONF_create_autoincreasetrackch~1 EXT:save() end 
    if ImGui.Checkbox(ctx, 'Link parameters on build/add', EXT.CONF_link_params == 1) then EXT.CONF_link_params = EXT.CONF_link_params~1 EXT:save() end 
  end
  --------------------------------------------------------------------------------  
  function UI.draw()  
    ImGui.TextDisabled(ctx, 'Last touched plugin:')
    
    if DATA.plugindata.valid~= true then return end 
    
    ImGui.SameLine(ctx)
    ImGui.Text(ctx, DATA.plugindata.fx_name_reduced)
    
    
    UI.draw_container_chancombo() 
    
    if ImGui.BeginTabBar( ctx, '##containctrl', ImGui.TabBarFlags_None) then  
      
      if DATA.plugindata.container.valid == true then  
        if ImGui.BeginTabItem( ctx, 'Instances', false ) then UI.draw_container_stuff_instances() ImGui.EndTabItem( ctx ) end  
        if ImGui.BeginTabItem( ctx, 'Linking', false ) then UI.draw_container_stuff_linking() ImGui.EndTabItem( ctx ) end 
       else 
        if ImGui.BeginTabItem( ctx, 'Create', false ) then if ImGui.Button(ctx, 'Create multi-mono container', -1,-1) then DATA:Container_Build() end ImGui.EndTabItem( ctx )  end  
      end 
      
      if ImGui.BeginTabItem( ctx, 'Options', false ) then UI.draw_settings() ImGui.EndTabItem( ctx ) end 
      
      ImGui.EndTabBar( ctx )
    end
    
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
  function UI.draw_container_chancombo() 
 
    local preview_value = ''
    if DATA.chan_map[EXT.CONF_chan_config] then  preview_value = DATA.chan_map[EXT.CONF_chan_config].name end
    reaper.ImGui_SetNextItemWidth(ctx,-1)
    if ImGui.BeginCombo( ctx, '##createcont_chan', preview_value, ImGui.ComboFlags_HeightLargest ) then
      for idx in spairs(DATA.chan_map, function(t,a,b) return t[a].orderidx<t[b].orderidx end) do
        local name = DATA.chan_map[idx].name
        if ImGui.Selectable(ctx,name.. '##createcont_chan__'..name, idx == EXT.CONF_chan_config) then 
          EXT.CONF_chan_config = idx 
          EXT:save() 
          if DATA.plugindata.container.valid == true then 
            local chancnt = DATA.chan_map[idx].chancnt
            DATA:Container_SetChannels(chancnt, DATA.plugindata.container.parent_idx) 
          end
          DATA.upd = true  
        end
      end
      ImGui.EndCombo( ctx )
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_container_stuff_instances() 
    if ImGui.BeginChild( ctx, '##instanceslist', -1, -1, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then
      
      local chanmap = DATA.chan_map[EXT.CONF_chan_config].chan_names
      
      local num_channels_desired = DATA:Container_Build_GetNumCh() 
      
      -- used channels
      for channel = 1, DATA.max_channels do
        local match_conf = channel <= num_channels_desired
        local exists = DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].valid == true
        local open = DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].open
        
        if not (exists or match_conf) then goto nextchan end
        
        -- upd for chan 1
        if channel == 1 then
          ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x00FF2040)
          if ImGui.Button(ctx, 'Upd##upd'..channel,UI.instaddW) then DATA:Container_Instance_Refresh()  end
          ImGui.PopStyleColor(ctx)
          ImGui.SameLine(ctx)
        end
        
        -- add/del 
        if exists == true and channel ~= 1 then 
          if ImGui.Button(ctx, 'Del##del'..channel,UI.instaddW) then DATA:Container_Instance_Remove(channel)  end 
          ImGui.SameLine(ctx)
        end
        
        if exists ~= true then 
          if ImGui.Button(ctx, 'Add##add'..channel,UI.instaddW) then DATA:Container_Instance_Add(channel)   end  
          ImGui.SameLine(ctx)
        end
        
        
        -- name
        if match_conf ~= true or exists ~= true then ImGui.BeginDisabled(ctx,true) end
        local name = '['..channel..']' if chanmap and chanmap[channel] then name = name..' '..chanmap[channel] end
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0,0.5)
        if ImGui.Button(ctx, name..'##inst'..channel,UI.instanceW) then DATA:Container_ShowOnlyInstance(channel)  end 
        ImGui.PopStyleVar(ctx)
        if match_conf ~= true or exists ~= true  then ImGui.EndDisabled(ctx) end
        
        -- opened frmae
        local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
        local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
        if open == true then 
          ImGui.DrawList_AddRect( UI.draw_list, x1, y1, x2, y2, (UI.col_maintheme<<8)|0x8F, UI.frame_rounding, ImGui.DrawFlags_None, 2 )
        end
        
        
        
        ::nextchan::
      end  
      ImGui.EndChild( ctx )
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_container_stuff_linking() 
    
    local num_channels_desired = DATA:Container_Build_GetNumCh() 
    
    -- linkactions
    if ImGui.BeginCombo( ctx, 'Link actions##linkactions', '', ImGui.ComboFlags_HeightLargest|ImGui.ComboFlags_NoPreview ) then
      if ImGui.Selectable(ctx, 'Link all') then DATA:Container_Link(1) end
      if ImGui.Selectable(ctx, 'Link all except last touched') then DATA:Container_Link(1, nil, nil, DATA.plugindata.parm) end
      if ImGui.Selectable(ctx, 'Unlink all') then DATA:Container_Link(0) end
      if ImGui.Selectable(ctx, 'Unlink all except last touched') then DATA:Container_Link(0, nil, nil, DATA.plugindata.parm) end
      ImGui.EndCombo( ctx )
    end 
    
    
    -- current parameter link
    ImGui.SeparatorText(ctx,'Last touched parameter links') 
    
    local has_overrides = DATA.plugindata.container.linkoverrides[DATA.plugindata.parm]
    if ImGui.Checkbox(ctx, '##linklasttouched', has_overrides== nil) then  
      if has_overrides then DATA:Container_Link(1, true) else DATA:Container_Link(0, true) end 
    end
    ImGui.SameLine(ctx)
    
    
    local preview_value = DATA.plugindata.paramname
    reaper.ImGui_SetNextItemWidth(ctx,-1)--UI.instanceW)
    if ImGui.BeginCombo( ctx, '##linkoverrides_list', preview_value, ImGui.ComboFlags_HeightLargest ) then
      for param in spairs(DATA.plugindata.container.linkoverrides) do
        local name = DATA.plugindata.container.linkoverrides[param].name
        if ImGui.Selectable(ctx,name.. '##linkoverrides_list__'..param) then DATA:Container_Param_SetLastTouched(param) end
      end
      ImGui.EndCombo( ctx )
    end  
    
    -- per channel link
    if DATA.plugindata.container.linkoverrides[DATA.plugindata.parm] then
      local chanmap = DATA.chan_map[EXT.CONF_chan_config].chan_names
      if ImGui.BeginChild( ctx, '##linklasttouched_chanlist', -1, -1, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None ) then
        
        for linkoverride_channel = 2, num_channels_desired do  
          if not DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel] then goto skip_override_chan end
          
          local name = '['..linkoverride_channel..']'
          if chanmap and chanmap[linkoverride_channel] then name = chanmap[linkoverride_channel] end 
          local state = DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].active == 1 
          if ImGui.Checkbox(ctx, '##linklasttouched_chanlist'..linkoverride_channel, state) then   
            if state == true then DATA:Container_Link(0, true, linkoverride_channel) else DATA:Container_Link(1, true, linkoverride_channel) end
          end 
          
          ImGui.SameLine(ctx)
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0,0.5)
          ImGui.PushStyleColor(ctx, ImGui.Col_Button,0x00000000)
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,0x00000000)
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,0x00000000)
          ImGui.Button(ctx, name, UI.instanceW)
          ImGui.PopStyleVar(ctx)
          ImGui.PopStyleColor(ctx,3)
          
          if state == true then reaper.ImGui_BeginDisabled(ctx, true) end 
          ImGui.SameLine(ctx)
          local value = DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].value
          local value_format = DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].value_format
          reaper.ImGui_SetNextItemWidth(ctx,-1)
          local retval, v = reaper.ImGui_SliderDouble( ctx, '##linklasttouched_slider'..linkoverride_channel, value, 0, 1, value_format:gsub('%%','%%%%'), ImGui.SliderFlags_None|ImGui.SliderFlags_NoInput)
          if retval then 
            local destID = DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].destID
            local track = DATA.plugindata.track
            TrackFX_SetParamNormalized( track, destID, DATA.plugindata.parm, v )
            local retval, value_format = TrackFX_GetFormattedParamValue(  track, destID, DATA.plugindata.parm )
            DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].value_format = value_format
            DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].value = v
          end
          
          -- input slider
          if reaper.ImGui_IsItemClicked(ctx, ImGui.MouseButton_Right) then
            ImGui.OpenPopup( ctx, '##InputSlider'..linkoverride_channel, ImGui.PopupFlags_None )
          end
          
          
          local mousex, mousey = reaper.ImGui_GetMousePos(ctx)
          ImGui.SetNextWindowPos( ctx,  mousex+15, mousey+15, ImGui.Cond_Appearing, 0, 0 )
          if ImGui.BeginPopup( ctx, '##InputSlider'..linkoverride_channel, ImGui.PopupFlags_None ) then 
            local value_format = DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].value_format
            ImGui.SetKeyboardFocusHere(ctx)
            ImGui.SetNextItemWidth(ctx, 100)
            local retval, buf =  ImGui.InputText(ctx, '##inpformval', value_format, ImGui.InputTextFlags_EnterReturnsTrue)
            if retval and buf ~= '' then  
              local track = DATA.plugindata.track
              local destID = DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].destID
              local ret_val = VF_BFpluginparam(buf,track, destID, DATA.plugindata.parm)
              if ret_val then 
                DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].value = ret_val 
                local retval, value_format = TrackFX_GetFormattedParamValue(  track, destID, DATA.plugindata.parm )
                DATA.plugindata.container.linkoverrides[DATA.plugindata.parm][linkoverride_channel].value_format = value_format
              end
              ImGui.CloseCurrentPopup(ctx) 
            end
            ImGui.EndPopup(ctx)
          end
          
          
          if state == true then reaper.ImGui_EndDisabled(ctx) end
          
          ::skip_override_chan::
        end 
        
        ImGui.EndChild( ctx )
      end
    end
    
    
    
  end
  --------------------------------------------------------------------------------  
  function DATA:Container_Param_SetLastTouched(param)
    if DATA.plugindata.container.valid ~= true then return end
    local track = DATA.plugindata.track
    local master_fx = DATA.plugindata.container.children[1].child_instance
    TrackFX_SetNamedConfigParm( track, master_fx, 'last_touched',param  )
    DATA.upd = true
    
  end
  --------------------------------------------------------------------------------  
  function DATA:Container_Link(setval0, parm_In, chan_In, parm_In_excl)
    if DATA.plugindata.container.valid ~= true then return end
    
    --Undo_BeginBlock2(-1)
    
    -- data
    local master_fx = DATA.plugindata.container.children[1].child_instance
    local slaves = #DATA.plugindata.container.children
    local cntparams = DATA.plugindata.cntparams
    local track = DATA.plugindata.track
    local container_idx = DATA.plugindata.container.parent_idx 
    
    -- mode
    local setval = 1
    if setval0 then setval = setval0 end
    
    -- param
    local param_st  = 0
    local param_end = cntparams-1
    if parm_In then 
      param_st = DATA.plugindata.parm 
      param_end = param_st 
    end
    
    -- chan
    local chan_st = 2
    local chan_end = slaves
    if chan_In then 
      chan_st = chan_In
      chan_end = chan_st
    end
    
    for param = param_st, param_end  do
      if parm_In_excl and parm_In_excl == param then goto skipparam end
      local retval, param_map = TrackFX_GetNamedConfigParm( track, container_idx, 'container_map.get.'..master_fx..'.'..param ) 
      for channel = chan_st, chan_end do
        if DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].valid == true then
          local destID = DATA.plugindata.container.children[channel].child_instance
          TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.active', setval )
          TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.effect', 0)--container_idx )
          TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.param', param_map )
        end
      end
      ::skipparam::
    end
    DATA.upd = true 
    
    --Undo_EndBlock2(-1, 'MultiMonoContainer: change linking', 0xFFFFFFFF)
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent() 
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,0) 
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,0) 
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,0) 
  end
  ---------------------------------------------------  
  function DATA:Container_ShowOnlyInstance(channel0)   
    if DATA.plugindata.container.valid ~= true then return end
    if not DATA.plugindata.container.children then return end
    
    local track= DATA.plugindata.track 
    
    --[[
    local fxid = DATA.plugindata.container.children[idx0].child_instance
    TrackFX_Show( track, fxid, 3 )
    ]]
    
    for channel = 1, #DATA.plugindata.container.children do 
      if DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].valid == true then
        local fxid = DATA.plugindata.container.children[channel].child_instance
        TrackFX_SetOpen( track, fxid, channel == channel0 )
        if channel == channel0  then TrackFX_SetNamedConfigParm( track, fxid, 'focused', 1 )  end -- set last focused
      end
    end 
    
    if DATA.plugindata.container.children[channel0] then DATA.plugindata.container.children[channel0].open = true end
    
  end
  ---------------------------------------------------  
  function DATA:Container_Instance_Refresh()
    if DATA.plugindata.container.valid ~= true then return end
    
    local num_channels_desired = DATA:Container_Build_GetNumCh() 
     
    for channel = 2, DATA.max_channels do 
      if channel <= num_channels_desired and not (DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].valid == true) then 
        DATA:Container_Instance_Add(channel)
      end
      if channel > num_channels_desired and (DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].valid == true) then 
        DATA:Container_Instance_Remove(channel, true)
      end
    end
  end
  ---------------------------------------------------  
  function DATA:Container_Instance_Add(channel)
    if DATA.plugindata.container.valid ~= true then return end
    if DATA.plugindata.container.children[channel] and DATA.plugindata.container.children[channel].valid == true then return end -- skip if exists
    
    local track = DATA.plugindata.track
    local fx_name = DATA.plugindata.fx_name  
    local fx_name_reduced = DATA.plugindata.fx_name_reduced  
    local cntparams = DATA.plugindata.cntparams 
    local inputPins = DATA.plugindata.inputPins 
    local outputPins = DATA.plugindata.outputPins 
    local parent_container = DATA.plugindata.container.parent_idx
    
    -- duplicate master instance
      if not DATA.plugindata.container.children[1] and DATA.plugindata.container.children[1].valid == true then return end 
      local master_fx = DATA.plugindata.container.children[1].child_instance  
      local retval, container_item0 = TrackFX_GetNamedConfigParm( track, parent_container, 'container_item.0' ) 
      local destID = container_item0
      
    -- unmap params from master, otherwise it replace mapping with new instnce
      for param = cntparams-1,0,-1  do TrackFX_GetNamedConfigParm( track, parent_container, 'param.'..param..'.container_map.delete' )  end 
    
    -- duplicate instance
      TrackFX_CopyToTrack(track, master_fx, track, destID, false) 
      local retval, container_count = TrackFX_GetNamedConfigParm( track, parent_container, 'container_count' ) 
      local retval, lastItem = TrackFX_GetNamedConfigParm( track, parent_container, 'container_item.'..(container_count-1) ) 
      TrackFX_CopyToTrack(track, destID, track, lastItem, true)  
      destID  = tonumber(lastItem)
      TrackFX_SetNamedConfigParm( track, destID, 'renamed_name', fx_name_reduced..' MMC - ch'..math.floor(channel) )
      TrackFX_Show( track, destID, 0 )
    
    -- set pins
      DATA:Container_Build_SetPinMappings(channel) 
    
    -- revert mapping back
      for param = 0, cntparams-1  do
        local retval, param_map = TrackFX_GetNamedConfigParm( track, parent_container, 'container_map.add.'..master_fx..'.'..param ) 
      end
    
    -- link params 
      if EXT.CONF_link_params == 1 then
        for param = 0, cntparams-1  do
          --local retval, param_map = TrackFX_GetNamedConfigParm( track, parent_container, 'container_map.get.'..master_fx..'.'..param )  
          TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.active',  1 )
          TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.effect',  0)--master_fx )
          TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.param',   param )
        end
      end
      
    DATA.upd = true 
  end
  ---------------------------------------------------  
  function DATA:Container_Instance_Remove(channel, force_upd)
    if DATA.plugindata.container.valid ~= true then return end
    if not DATA.plugindata.container.children[channel] then return end
    
    local track = DATA.plugindata.track
    local fxid = DATA.plugindata.container.children[channel].child_instance
    TrackFX_Delete( track, fxid )
    if force_upd then DATA:CollectData() end
    DATA.upd = true 
  end
  
  ---------------------------------------------------  
  function DATA:Container_SetChannels(num_channels, container_idx) 
    local track = DATA.plugindata.track 
    TrackFX_SetNamedConfigParm( track, container_idx, 'container_nch', num_channels ) 
    TrackFX_SetNamedConfigParm( track, container_idx, 'container_nch_in', num_channels ) 
    TrackFX_SetNamedConfigParm( track, container_idx, 'container_nch_out', num_channels ) 
    if EXT.CONF_create_autoincreasetrackch == 1 and num_channels > DATA.plugindata.I_NCHAN then 
      local set_num_channels = num_channels
      if num_channels %2 == 1 then set_num_channels = num_channels + 1 end
      if set_num_channels > DATA.plugindata.I_NCHAN then SetMediaTrackInfo_Value( track, 'I_NCHAN', set_num_channels ) end
    end
  end
  ---------------------------------------------------  
  function DATA:Container_Build_GetNumCh() 
    local num_channels = DATA.chan_map[EXT.CONF_chan_config].chancnt  
    if num_channels == 0 then num_channels = DATA.plugindata.I_NCHAN end
    return num_channels
  end
  ---------------------------------------------------  
  function DATA:Container_Build()  
    Undo_BeginBlock2(-1)
    
    local track = DATA.plugindata.track 
    local fxidx = DATA.plugindata.fxidx 
    local fx_name = DATA.plugindata.fx_name 
    local fx_name_reduced = DATA.plugindata.fx_name_reduced 
    local cntparams = DATA.plugindata.cntparams 
    local outname = DATA.plugindata.fx_name
    local num_channels = DATA:Container_Build_GetNumCh() 
    
    -- add container
      local container_idx = TrackFX_AddByName( track, 'Container', false, -1000 )
      local dest_fx =  0x2000000 + 1*(TrackFX_GetCount(track)+1) + 1
      local master_fx = fxidx+1
      TrackFX_CopyToTrack( track, master_fx, track, dest_fx, true )
      master_fx = 0x2000000 + 1*(TrackFX_GetCount(track)+1) + 1
      TrackFX_SetNamedConfigParm( track, container_idx, 'renamed_name', fx_name_reduced..' MMC' )  
      TrackFX_SetNamedConfigParm( track, master_fx, 'renamed_name', fx_name_reduced..' MMC - master' ) 
      DATA:Container_SetChannels(num_channels, container_idx) 
      
    -- duplicate instances
      for chan = 1, num_channels-1 do
        master_fx = 0x2000000 + 1*(TrackFX_GetCount(track)+1) + 1
        local destID = 0x2000000 + (1+chan)*(TrackFX_GetCount(track)+1) + 1
        TrackFX_CopyToTrack(track, master_fx, track, destID, false) 
        TrackFX_SetNamedConfigParm( track, destID, 'renamed_name', fx_name_reduced..' MMC - ch'..math.floor(chan+1) )
        TrackFX_Show( track, destID, 0 )
      end
    
    -- link params 
      if EXT.CONF_link_params == 1 then 
        local master_fx = 0x2000000 + 1*(TrackFX_GetCount(track)+1) + 1
        for param = 0, cntparams-1  do
          local retval, param_map = TrackFX_GetNamedConfigParm( track, container_idx, 'container_map.add.'..master_fx..'.'..param ) 
          for chan = 1, num_channels-1 do
            local destID = 0x2000000 + (1+chan)*(TrackFX_GetCount(track)+1) + 1
            TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.active', 1 )
            TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.effect', container_idx )
            TrackFX_SetNamedConfigParm( track, destID, 'param.'..param..'.plink.param', param_map )
          end
        end
      end
      
    DATA:Container_Build_SetPinMappings() 
    
    -- move container
      TrackFX_CopyToTrack( track, container_idx, track, fxidx, true )
      
    Undo_EndBlock2(-1, 'MultiMonoContainer: build', 0xFFFFFFFF)
    
  end
  ---------------------------------------------------  
  function DATA:Container_Build_SetPinMappings(channel) 
    local inputPins = DATA.plugindata.inputPins 
    local outputPins = DATA.plugindata.outputPins 
    local track = DATA.plugindata.track 
    local num_channels = DATA:Container_Build_GetNumCh() 
    
    local ch_st = 1
    local ch_end = num_channels 
    if channel then ch_st = channel ch_end = channel end 
      
    for chan = 1, num_channels do
      local destID = 0x2000000 + (1+chan-1)*(TrackFX_GetCount(track)+1) + 1
      for pin = 1, inputPins do TrackFX_SetPinMappings( track, destID, 0, pin-1, 0, 0 ) end
      for pin = 1, outputPins do TrackFX_SetPinMappings( track, destID, 1, pin-1, 0, 0 ) end 
      TrackFX_SetPinMappings( track, destID, 0, 0, 1<<(chan-1), 0 ) 
      TrackFX_SetPinMappings( track, destID, 1, 0, 1<<(chan-1), 0 ) 
    end
    
  end
  -----------------------------------------------------------------------------------------  
  function DATA:BuildChannelMap()
    DATA.chan_map = {
    { name  = '[Track channels]',
      chancnt  = 0,
      orderidx = 1,
    },
    { name='Stereo',
      chancnt  = 2,
      orderidx = 2,
      chan_names = { 'Left', 'Right' }
    },
    { name='Quadraphonic',
      chancnt  = 4,
      orderidx = 3,
      chan_names = { 'Left front', 'Right front', 'Left sur', 'Right sur', }
    },
    { name='5.1 surround',
      chancnt  = 6,
      orderidx = 5,
      chan_names = { 'Left front', 'Right front',  'Center front', 'LFE', 'Left sur', 'Right sur', }
    },
    { name='7.1 surround',
      chancnt = 8,
      orderidx = 6,
      chan_names = { 'Left front', 'Right front',  'Center front', 'LFE', 'Left rear', 'Right rear', 'Left side', 'Right side'}
    },
    { name='7.1.2 surround',
      chancnt = 10,
      orderidx = 7,
      chan_names = { 'Left front', 'Right front',  'Center front', 'LFE', 'Left side', 'Right side', 'Left rear', 'Right rear', 'Left side H', 'Right side H'}
    },
    { name='7.1.4 surround',
      chancnt = 12,
      orderidx = 8,
      chan_names = { 'Left front', 'Right front',  'Center front', 'LFE', 'Left side', 'Right side', 'Left rear', 'Right rear', 'Left front H', 'Right front H', 'Left rear H', 'Right rear H'}
    },
    { name='9.1.4 surround',
      chancnt = 14,
      orderidx = 9,
      chan_names = { 'Left front', 'Right front',  'Center front', 'LFE', 'Left side', 'Right side', 'Left rear', 'Right rear', 'Left wide', 'Right wide', 'Left front H', 'Right front H', 'Left rear H', 'Right rear H'}
    },
    { name='9.1.6 surround',
      chancnt = 16,
      orderidx = 10,
      chan_names = { 'Left front', 'Right front',  'Center front', 'LFE', 'Left side', 'Right side', 'Left rear', 'Right rear', 'Left wide', 'Right wide', 'Left front H', 'Right front H', 'Left side H', 'Right side H', 'Left rear H', 'Right rear H'}
    }
    
    }
  end
  -----------------------------------------------------------------------------------------  
  function _main() 
    DATA:BuildChannelMap()
    UI.MAIN_definecontext()   -- + EXT:load
  end   
       
  _main()
  
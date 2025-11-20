-- @description ImportSessionData
-- @version 3.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=233358
-- @about This script allow to import tracks, items, FX etc from defined RPP project file
-- @changelog
--    # fix error on missing project



--------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    vrsmin = 7.0
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < vrsmin then return reaper.MB('This script require REAPER '..vrsmin..'+','',0) end
    local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.10'
    
    
    
  -------------------------------------------------------------------------------- ImGui overrides
  function ImGui.Custom_InvisibleButton(ctx,txt,w,h)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,0)
    ImGui.Button(ctx,txt,w,h)
    ImGui.PopStyleColor(ctx, 3)
  end
  -------------------------------------------------------------------------------- ImGui overrides
  function ImGui.Custom_Selectable(ctx,txt,w,h, state)
    local bgrcol =0
    if state == true then bgrcol = 0x5F5F5FFF end
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,bgrcol)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,bgrcol)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,bgrcol)
    ImGui.Button(ctx,txt,w,h)
    ImGui.PopStyleColor(ctx, 3)
  end
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          CONF_name = 'default',
          
          UI_enableshortcuts = 0,
          UI_initatmouse = 0,
          UI_showtooltips = 1,
          UI_groupflags = 0, -- show/hide setting flags
          UI_appatchange = 1, 
          UI_appatinit = 1,
          UI_matchatsettingsrc = 1,
          UI_hidesrchiddentracks = 1,
          
          UI_trfilter = '',
          UI_lastsrcproj = '',
          UI_ignoretracklistselection = 1,
          
          -- track params
          CONF_tr_name = 1,
          CONF_tr_VOL = 1,
          CONF_tr_PAN = 1,
          CONF_tr_FX = 1, -- &2 clear existed
          CONF_tr_it = 1, -- &2 clear existed &4relink files to full paths &4 edit cur offs &8 try fix relative path
          CONF_tr_PHASE = 1,
          CONF_tr_RECINPUT = 1,
          CONF_tr_MAINSEND = 1,
          CONF_tr_CUSTOMCOLOR = 1,
          CONF_tr_LAYOUTS = 0,
          CONF_tr_LAYOUTS = 0,
          CONF_tr_GROUPMEMBERSHIP = 0, -- &1 import &2 try to not replace current project groups
          CONF_sendlogic_flags2 = 0,
          CONF_sendlogic_desthasrec = 0,
          CONF_sendlogic_desthasnotrec = 0,
          CONF_sendlogic_desthasrec_no = 0,
          
          -- master
          --CONF_head_mast_FX = 0, OBSOLETE v3
          CONF_head_markers = 0, --&1 mark &2 replace mark &4 reg &8 replace reg &16 edit cur offs
          CONF_head_tempo = 0,--&2 edit cur offs
          CONF_head_groupnames = 0,
          -- CONF_head_rendconf = 0,OBSOLETE v3
          
          -- tr options
          CONF_resetfoldlevel = 1,
          CONF_it_buildpeaks = 1,
          
          -- match algo
          CONF_tr_matchmode = 1, -- &1==1 full match
          CONF_tr_match_preventsends = 1, 
          CONF_tr_match_automatchsendsasdest = 1, 
          
          
          preset_base64_user = '',
          update_presets = 1, -- grab presets ONCE from old version
          
          
         }
-------------------------------------------------------------------------------- INIT data
  DATA = {
        ES_key = 'ImportSessionData',
        UI_name = 'Import Session Data', 
        upd = true, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
          --['test'] = 'bnZzdGVwcz0wCkNPTkZfZXhjbHdpdGlmNmbGFnPTEKQ09ORl9zcmNfc3RybWFya2Vycz0w',
          },
        presets = {
          factory= {},
          user= {}, 
          },
        }   
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
      -- font
        font='Arial',
        font1sz=15,
        font2sz=14,
        font3sz=12,
      -- mouse
        hoverdelay = 0.8,
        hoverdelayshort = 0.5,
      -- size / offset
        spacingX = 4,
        spacingY = 3,
      -- colors / alpha
        col_main = 0x7F7F7F, -- grey
        col_text = 0xFFFFFF, -- white
        col_maintheme = 0x00B300 ,-- green,
        col_red = 0xB31F0F  ,
        col_text_a_enabled = 1,
        col_text_a_disabled = 0.5,
        col_buthovered = 0x878787,
        windowBg = 0x303030,
        
        wind_W = 800,
        wind_H = 480, 
        default_none_dest = '[none]' ,
        default_newtrackatend_dest = 'New track at the end of tracklist' ,
        default_newtrackatend1_dest = 'New track at the end of tracklist, obey structure' ,
        tracklist_W = 500,
        indent_menu = 10,
        }
    
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  -------------------------------------------------------------------------------- 
  function UI.Tools_RGBA(col, a_dec) return col<<8|math.floor(a_dec*255) end  
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
    function __b_styledef() end
      UI.anypopupopen = ImGui.IsPopupOpen( ctx, 'mainRCmenu', ImGui.PopupFlags_AnyPopup|ImGui.PopupFlags_AnyPopupLevel )
      
      
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      --window_flags = window_flags | ImGui.WindowFlags_MenuBar
      --window_flags = window_flags | ImGui.WindowFlags_NoMove()
      window_flags = window_flags | ImGui.WindowFlags_NoResize
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
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,5)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding,5)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,5)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding,5)  
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
      --ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,640,480)
      
    -- align
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,0,0.5)
      
    -- alpha
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha,1)
      ImGui.PushStyleColor(ctx, ImGui.Col_Border,           UI.Tools_RGBA(0x509050, 0.5))
    -- colors
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.col_main, 0.2))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.col_main, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.col_buthovered, 0.8))
      ImGui.PushStyleColor(ctx, ImGui.Col_DragDropTarget,   UI.Tools_RGBA(0xFF1F5F, 0.6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,          UI.Tools_RGBA(0x1F1F1F, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,    UI.Tools_RGBA(UI.col_main, .6))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,   UI.Tools_RGBA(UI.col_main, 0.7))
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,           UI.Tools_RGBA(UI.col_main, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive,     UI.Tools_RGBA(UI.col_main, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,    UI.Tools_RGBA(UI.col_main, 0.98) )
      ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,          UI.Tools_RGBA(0x303030, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip,       UI.Tools_RGBA(UI.col_main, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered,UI.Tools_RGBA(UI.col_main, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,       UI.Tools_RGBA(UI.col_maintheme, 0.6) )
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, UI.Tools_RGBA(UI.col_maintheme, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_Tab,              UI.Tools_RGBA(UI.col_main, 0.37) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected,       UI.Tools_RGBA(UI.col_maintheme, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered,       UI.Tools_RGBA(UI.col_maintheme, 0.8) )
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,             UI.Tools_RGBA(UI.col_text, UI.col_text_a_enabled) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg,          UI.Tools_RGBA(UI.col_main, 0.7) )
      ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive,    UI.Tools_RGBA(UI.col_main, 0.95) )
      ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,         UI.Tools_RGBA(UI.windowBg, 1))
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font,14) 
      
      reaper.ImGui_SetNextWindowSize(ctx, UI.wind_W, UI.wind_H)
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
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'Test')
        UI.calc_itemH = calcitemh + frameh * 2
         
        -- get drawlist
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        
        -- mod
        UI.Mod_Shift = ImGui.IsKeyDown(ctx, ImGui.Mod_Shift)
        UI.Mod_Ctrl = ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)
        UI.Mod_Alt = ImGui.IsKeyDown(ctx, ImGui.Mod_Alt)
        
        -- draw stuff
        UI.draw() 
        ImGui.Dummy(ctx,0,0) 
        
        -- reset at click in emprt space
        if reaper.ImGui_IsMouseClicked(ctx,reaper.ImGui_MouseButton_Left()) and not reaper.ImGui_IsAnyItemActive(ctx) then 
          DATA:Actions_Selection_Reset()
        end
        
        ImGui.End(ctx)
      end 
     
     
    -- pop
      ImGui.PopStyleVar(ctx, 21) 
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
    
    --DATA:CollectData_Always() 
    --if DATA.upd == true then DATA:CollectData() end 
    DATA.upd = false   
    
    -- draw UI
    if not reaper.ImGui_ValidatePtr( ctx, 'ImGui_Context*') then UI.MAIN_definecontext() end
    UI.open = UI.MAIN_styledefinition(true) 
    
    -- data
    if UI.open then defer(UI.MAIN_loop) else  
      
    end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext() 
    -- imgUI init
    ctx = ImGui.CreateContext(DATA.UI_name) 
    -- fonts
    DATA.font = ImGui.CreateFont(UI.font) ImGui.Attach(ctx, DATA.font)
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
    function __b_uidraw() end
    UI.draw_topbuttons()
    UI.draw_tabs()  
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw_tabs()   
    function __b_draw_tabs()end
    if ImGui.BeginTabBar(ctx, 'tabs', ImGui.TabBarFlags_None) then    
      ImGui.PushFont(ctx, DATA.font,13)
      UI.draw_tabs_tracks()
      UI.draw_tabs_header()
      UI.draw_tabs_settings()
      UI.draw_tabs_sendimportlogic()
      ImGui.PopFont(ctx)
      ImGui.EndTabBar(ctx) 
    end 
  end
  
  --------------------------------------------------------------------- 
  function UI.draw_tabs_tracks_list() 
    if not (DATA.srcproj and DATA.srcproj.TRACK)then return end
    local indent = 10
    local trackX2 = 240
    if ImGui.BeginChild(ctx, 'tracklist', UI.tracklist_W) then
      
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign, 0,0.5)
      for trid = 1, #DATA.srcproj.TRACK do
        if not DATA.srcproj.TRACK[trid].NAME then goto skip_track end
        if EXT.UI_hidesrchiddentracks==1 and not (DATA.srcproj.TRACK[trid].SHOWINMIX[1] == 1 and DATA.srcproj.TRACK[trid].SHOWINMIX[4] == 1 ) then goto skip_track end
        
        -- naming
          local txt = DATA.srcproj.TRACK[trid].NAME_UI
          local level = DATA.srcproj.TRACK[trid].CUST_foldlev or 0
        
        -- showcond
          local showcond = DATA:VisibleCondition(DATA.srcproj.TRACK[trid].NAME)
          if not showcond then goto skip_track end
         
        -- indent
          if level ~= 0 then ImGui.Indent(ctx, indent*level) end
        
        -- col
          local UI_col_rgba = DATA.srcproj.TRACK[trid].UI_col_rgba or 0
          if UI_col_rgba then 
            local rectsz = 20
            ImGui.InvisibleButton(ctx, '##color_src'..trid,rectsz,rectsz)
            local p_min_x, p_min_y = reaper.ImGui_GetItemRectMin( ctx )
            local p_max_x, p_max_y = reaper.ImGui_GetItemRectMax( ctx )
            ImGui.DrawList_AddRectFilled( UI.draw_list, p_min_x, p_min_y, p_max_x, p_max_y, UI_col_rgba, 2, reaper.ImGui_DrawFlags_RoundCornersAll() )
            ImGui.SameLine(ctx)
          end
        
        -- main selectable
          local selected = DATA.srcproj.TRACK[trid].UI_selected
          local curposX = reaper.ImGui_GetCursorPosX(ctx)
          ImGui.Custom_Selectable(ctx, txt, trackX2-curposX, 0, selected)--, , reaper.ImGui_SelectableFlags_None(), trackW - indent*level)
          if reaper.ImGui_IsItemClicked(ctx) then DATA:Actions_Selection_ontrackclick(trid) end
          if not dest then 
            test = DATA.srcproj.TRACK[trid]
          end
          
          if txt:len()>28 then 
            --ImGui.PushStyleColor(ctx, ImGui.Col_Border,           UI.Tools_RGBA(0x909090, 0.3))
            reaper.ImGui_SetItemTooltip( ctx, txt) 
            --ImGui.PopStyleColor(ctx)
          end
          
          
        -- dest
          ImGui.SameLine(ctx)
          reaper.ImGui_SetNextItemWidth(ctx,-1)
          UI.draw_tabs_tracks_destmenu(trid) 
          
          if level ~= 0 then ImGui.Unindent(ctx, indent*level) end 
          
          
        ::skip_track::
      end
      ImGui.PopStyleVar(ctx)
      
      ImGui.EndChild(ctx)
    end
  end
  ----------------------------------------------------------------------
  function DATA:Import2_Header_MasterFX()
    if not (DATA.srcproj and DATA.srcproj.MASTERFXLIST) then return end
    if #DATA.srcproj.MASTERFXLIST == 0  then return end  
    local master_tr = GetMasterTrack( 0 )
    local retval, cur_chunk = reaper.GetTrackStateChunk( master_tr, '', false )
    if not (DATA.srcproj.MASTERFXLIST[1] and DATA.srcproj.MASTERFXLIST[1].chunk) then return end
    local src_chunk = DATA.srcproj.MASTERFXLIST[1].chunk:gsub('MASTERFXLIST', '') 
    DATA:Import2_Header_MasterFX_AddChunkToTrack(master_tr,src_chunk) 
  end
  ---------------------------------------------------------------------
  function DATA:Import2_Header_MasterFX_AddChunkToTrack(tr, chunk) -- add empty fx chain chunk if not exists
    local _, chunk_ch = reaper.GetTrackStateChunk(tr, '', false)
    if not chunk_ch:match('FXCHAIN') then chunk_ch = chunk_ch:sub(0,-3)..'<FXCHAIN\nSHOW 0\nLASTSEL 0\n DOCKED 0\n>\n>\n' end
    if chunk then chunk_ch = chunk_ch:gsub('DOCKED %d', chunk) end
    reaper.SetTrackStateChunk(tr, chunk_ch, false)
  end 
    --------------------------------------------------------------------- 
  function DATA:Import2_Header_RefreshProject() 
    DATA:Get_DestProject()
    UpdateArrange()
    TrackList_AdjustWindows( false )
  end
  ----------------------------------------------------------------------
  function DATA:Import2_Header_Markers()   
    if not (DATA.srcproj and DATA.srcproj.MARKERS) then return end
    
    --[[  &1 markers
          &2 markersreplace
          &4 regions
          &8 regionsreplace 
          ]]
          
    -- handle replace / aka remove old regions markers
    if EXT.CONF_head_markers&1==1 or EXT.CONF_head_markers&4==4 then -- import markers or regions
      local retval, num_markers, num_regions = CountProjectMarkers( 0 )
      for i = num_markers+num_regions, 1,-1 do 
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i-1 )
        if (EXT.CONF_head_markers&2 ==2 and isrgn ==false) or (EXT.CONF_head_markers&8 ==8 and isrgn ==true) then DeleteProjectMarkerByIndex( 0, i-1 ) end
      end
    end 
     
    -- handle cursor
      local offs = 0
      if EXT.CONF_head_markers&16==16 then offs = GetCursorPosition() end
    
    -- add markers from table
    for i = 1, #DATA.srcproj.MARKERS do
      if DATA.srcproj.MARKERS[i].is_region==false and EXT.CONF_head_markers&1 == 1 then
        local pos_sec=TimeMap2_beatsToTime( 0, DATA.srcproj.MARKERS[i].pos )
        local idx = AddProjectMarker2( 0, false, pos_sec+offs, -1, DATA.srcproj.MARKERS[i].name, DATA.srcproj.MARKERS[i].id, DATA.srcproj.MARKERS[i].col )
      end
    
      -- add regions from table
      if DATA.srcproj.MARKERS[i].is_region==true and EXT.CONF_head_markers&4 == 4 then
        local pos_sec=TimeMap2_beatsToTime( 0, DATA.srcproj.MARKERS[i].pos )
        local end_sec=TimeMap2_beatsToTime( 0, DATA.srcproj.MARKERS[i].rgnend or DATA.srcproj.MARKERS[i].pos )
        local idx = AddProjectMarker2( 0, true, pos_sec+offs, end_sec+offs, DATA.srcproj.MARKERS[i].name, DATA.srcproj.MARKERS[i].id, DATA.srcproj.MARKERS[i].col )
      end
      
    end 
    reaper.UpdateTimeline()
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_header_master()
    if not (DATA.srcproj and DATA.srcproj.MASTERFXLIST_exploded) then return end
    -- master
    if ImGui.CollapsingHeader(ctx, 'Master FX', nil) then 
      ImGui.Indent(ctx, UI.indent_menu) 
        -- import master
          ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.col_red, 0.4))
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.col_red, 1))
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.col_red, 0.6))
          if ImGui.Button(ctx, 'Import/Replace Master FX') then 
            Undo_BeginBlock2( 0 )
            reaper.PreventUIRefresh( -1 )
            DATA:Import2_Header_MasterFX()
            DATA:Import2_Header_RefreshProject()
            reaper.PreventUIRefresh( 1 )
            Undo_EndBlock2( 0, 'Import session data: Master FX', 0xFFFFFFFF )
          end
          ImGui.PopStyleColor(ctx,3) 
        -- list 
          if DATA.srcproj.MASTERFXLIST_exploded and #DATA.srcproj.MASTERFXLIST_exploded > 0 then
            ImGui.PushStyleColor(ctx, ImGui.Col_Border,0x505050FF)
            ImGui.BeginDisabled(ctx,true)
            if ImGui.BeginChild(ctx, 'MASTERFXLIST_exploded',0,0, ImGui.ChildFlags_AutoResizeY|ImGui.ChildFlags_Borders ) then
              for i = 1, #DATA.srcproj.MASTERFXLIST_exploded do
                ImGui.Selectable(ctx, DATA.srcproj.MASTERFXLIST_exploded[i])
              end
              ImGui.EndChild(ctx)
            end
            ImGui.EndDisabled(ctx)
            ImGui.PopStyleColor(ctx)
          end
        
        
      ImGui.Unindent(ctx, UI.indent_menu)
     end
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_header_regions()
    if not (DATA.srcproj and DATA.srcproj.MARKERS) then return end
    -- markers/regions
    if ImGui.CollapsingHeader(ctx, 'Markers/regions') then 
      ImGui.Indent(ctx, UI.indent_menu) 
        
        -- import master
          ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.col_red, 0.4))
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.col_red, 1))
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.col_red, 0.6))
          if ImGui.Button(ctx, 'Import markers/regions') then 
            Undo_BeginBlock2( 0 )
            reaper.PreventUIRefresh( -1 )
            DATA:Import2_Header_Markers()
            DATA:Import2_Header_RefreshProject()
            reaper.PreventUIRefresh( 1 )
            Undo_EndBlock2( 0, 'Import session data: markers/regions', 0xFFFFFFFF )
          end
          ImGui.PopStyleColor(ctx,3)
        
        
        -- options
          if ImGui.Checkbox( ctx, 'Offset at edit cursor##CONF_head_markers4',      EXT.CONF_head_markers&16 == 16 ) then EXT.CONF_head_markers =EXT.CONF_head_markers~16 EXT:save() end
          if ImGui.Checkbox( ctx, 'Add markers##CONF_head_markers0',      EXT.CONF_head_markers&1 == 1 ) then EXT.CONF_head_markers =EXT.CONF_head_markers~1 EXT:save() end
          if EXT.CONF_head_markers&1 == 1 then ImGui.SameLine(ctx) if ImGui.Checkbox( ctx, 'Clear existing markers##CONF_head_markers1',      EXT.CONF_head_markers&2 == 2 ) then EXT.CONF_head_markers =EXT.CONF_head_markers~2 EXT:save() end end
          if ImGui.Checkbox( ctx, 'Add regions##CONF_head_markers2',      EXT.CONF_head_markers&4 == 4 ) then EXT.CONF_head_markers =EXT.CONF_head_markers~4 EXT:save() end
          if EXT.CONF_head_markers&4 == 4 then ImGui.SameLine(ctx)  if ImGui.Checkbox( ctx, 'Clear existing regions##CONF_head_markers3',      EXT.CONF_head_markers&8 == 8 ) then EXT.CONF_head_markers =EXT.CONF_head_markers~8 EXT:save() end end
        
        
        -- plot
          local plotbg_col = 0x4040408F
          ImGui.PushStyleColor(ctx, ImGui.Col_Button, plotbg_col)
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, plotbg_col)
          ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, plotbg_col)
          ImGui.Button(ctx, '##plot_markersregions',-1,80) -- Invisible
          ImGui.PopStyleColor(ctx,3)
          
          local p_min_x, p_min_y = reaper.ImGui_GetItemRectMin( ctx )
          local p_max_x, p_max_y = reaper.ImGui_GetItemRectMax( ctx )
          local plot_W = p_max_x - p_min_x
          
          
          for i=1, #DATA.srcproj.MARKERS do
            if DATA.srcproj.MARKERS[i].is_region ~= true and EXT.CONF_head_markers&1 == 1 then
              local UI_pos_rel = DATA.srcproj.MARKERS[i].UI_pos_rel
              local col_native = DATA.srcproj.MARKERS[i].col or 0
              local col_rgba = 0xFFFFFFFF
              if col_native ~= 0 then
                local r, g, b = reaper.ColorFromNative(col_native)
                r = math.min(255,math.floor(255*math.sqrt(r/255)))
                g = math.min(255,math.floor(255*math.sqrt(g/255)))
                b = math.min(255,math.floor(255*math.sqrt(b/255)))
                col_rgba =
                  (r <<24) |
                  (g <<16) |
                  (b <<8) |
                  0xFF
              end 
              xpos = UI_pos_rel * plot_W + p_min_x
              ImGui.DrawList_AddLine( UI.draw_list,xpos, p_min_y ,xpos, p_max_y, col_rgba, 1 )
             
             elseif DATA.srcproj.MARKERS[i].is_region == true and EXT.CONF_head_markers&4 == 4 and DATA.srcproj.MARKERS[i].UI_pos_rel2 then
              local UI_pos_rel = DATA.srcproj.MARKERS[i].UI_pos_rel
              local UI_pos_rel2 = DATA.srcproj.MARKERS[i].UI_pos_rel2
              local name = DATA.srcproj.MARKERS[i].name
              local col_native = DATA.srcproj.MARKERS[i].col or 0
              local col_rgba = 0x6060609F
              if col_native ~= 0 then
                local r, g, b = reaper.ColorFromNative(col_native)
                col_rgba =
                  (r <<24) |
                  (g <<16) |
                  (b <<8) |
                  0x9F
              end 
              xpos = UI_pos_rel * plot_W + p_min_x
              xpos2 = UI_pos_rel2 * plot_W + p_min_x
              ImGui.DrawList_AddRectFilled( UI.draw_list, xpos, p_min_y, xpos2-1, p_max_y, col_rgba, 2, reaper.ImGui_DrawFlags_RoundCornersAll() ) 
              ImGui.DrawList_AddText( UI.draw_list, xpos, p_min_y, 0xFFFFFFFF, name )
            end
          end
          
          
      ImGui.Unindent(ctx, UI.indent_menu)
     end      
  end
  
  ----------------------------------------------------------------------
  function DATA:Import2_Header_Tempo()
    if not (DATA.srcproj and DATA.srcproj.TEMPOMAP) then return end
    if EXT.CONF_head_tempo&4 == 4 then -- clear
      for markerindex = CountTempoTimeSigMarkers( 0 ), 1, -1 do DeleteTempoTimeSigMarker( 0, markerindex-1 ) end
    end
    
    -- handle cursor
      local offs = 0
      if EXT.CONF_head_tempo&2==2 then offs = GetCursorPosition() end
      
    for i = 1, #DATA.srcproj.TEMPOMAP do
      local timesig_num = 0
      local timesig_denom = 0
      local lineartempo = false
      if DATA.srcproj.TEMPOMAP[i].timesig_num and DATA.srcproj.TEMPOMAP[i].timesig_denom then 
        timesig_num = DATA.srcproj.TEMPOMAP[i].timesig_num
        timesig_denom = DATA.srcproj.TEMPOMAP[i].timesig_denom
      end
      if DATA.srcproj.TEMPOMAP[i].lineartempochange and DATA.srcproj.TEMPOMAP[i].lineartempochange==true then lineartempo = DATA.srcproj.TEMPOMAP[i].lineartempochange end
      reaper.SetTempoTimeSigMarker( 0, -1, DATA.srcproj.TEMPOMAP[i].timepos + offs, -1, -1, DATA.srcproj.TEMPOMAP[i].bpm, timesig_num, timesig_denom, lineartempo )
    end
    
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_header_tempomap()
    
    if not (DATA.srcproj and DATA.srcproj.TEMPOMAP) then return end
    if ImGui.CollapsingHeader(ctx, 'Tempo map') then 
      ImGui.Indent(ctx, UI.indent_menu) 
      
      
      -- import 
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.col_red, 0.4))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.col_red, 1))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.col_red, 0.6))
        if ImGui.Button(ctx, 'Import tempo map') then 
          Undo_BeginBlock2( 0 )
          reaper.PreventUIRefresh( -1 )
          DATA:Import2_Header_Tempo()
          DATA:Import2_Header_RefreshProject()
          reaper.PreventUIRefresh( 1 )
          Undo_EndBlock2( 0, 'Import session data: tempo map', 0xFFFFFFFF )
        end
        ImGui.PopStyleColor(ctx,3)
      
      
      -- options
        if ImGui.Checkbox( ctx, 'Offset at edit cursor##CONF_head_tempo1',      EXT.CONF_head_tempo&2 == 2 ) then EXT.CONF_head_tempo =EXT.CONF_head_tempo~2 EXT:save() end
        if ImGui.Checkbox( ctx, 'Clear existing envelope##CONF_head_tempo2',      EXT.CONF_head_tempo&4 == 4 ) then EXT.CONF_head_tempo =EXT.CONF_head_tempo~4 EXT:save() end
          
        -- list 
          if DATA.srcproj.TEMPOMAP and #DATA.srcproj.TEMPOMAP > 0 then
            ImGui.PushStyleColor(ctx, ImGui.Col_Border,0x505050FF)
            ImGui.BeginDisabled(ctx,true)
            if ImGui.BeginChild(ctx, 'TEMPOMAP_exploded',0,120, ImGui.ChildFlags_AutoResizeY|ImGui.ChildFlags_Borders ) then
              
              ImGui.TextColored(ctx,  0x50F0F0FF, 'Position in beats' )
              ImGui.SameLine(ctx)
              ImGui.Text(ctx, 'BPM' )
              ImGui.SameLine(ctx)
              ImGui.TextColored(ctx, 0x50F050FF, 'Time signature')
              
              
              for i = 1, #DATA.srcproj.TEMPOMAP do
                ImGui.TextColored(ctx,  0x50F0F0FF, DATA.srcproj.TEMPOMAP[i].timepos )
                ImGui.SameLine(ctx)
                ImGui.Text(ctx, DATA.srcproj.TEMPOMAP[i].bpm )
                ImGui.SameLine(ctx)
                ImGui.TextColored(ctx, 0x50F050FF, DATA.srcproj.TEMPOMAP[i].timesig_num..'/'..DATA.srcproj.TEMPOMAP[i].timesig_denom)
              end
              ImGui.EndChild(ctx)
            end
            ImGui.EndDisabled(ctx)
            ImGui.PopStyleColor(ctx)
          end
          
          
      ImGui.Unindent(ctx, UI.indent_menu)
    end  
  end
  ----------------------------------------------------------------------
  function DATA:Import2_Header_Groupnames()
    if not (DATA.srcproj and DATA.srcproj.GROUPNAMES) then return end
    for groupID in pairs(DATA.srcproj.GROUPNAMES) do
      GetSetProjectInfo_String( 0, 'TRACK_GROUP_NAME:'..(groupID+1), DATA.srcproj.GROUPNAMES[groupID], true )
    end
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_header_groupnames()
    if not (DATA.srcproj and DATA.srcproj.GROUPNAMES) then return end
    if ImGui.CollapsingHeader(ctx, 'Group names') then 
      ImGui.Indent(ctx, UI.indent_menu) 
      
      
      -- import 
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.col_red, 0.4))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.col_red, 1))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.col_red, 0.6))
        if ImGui.Button(ctx, 'Import group names') then 
          Undo_BeginBlock2( 0 )
          reaper.PreventUIRefresh( -1 )
          DATA:Import2_Header_Groupnames()
          DATA:Import2_Header_RefreshProject()
          reaper.PreventUIRefresh( 1 )
          Undo_EndBlock2( 0, 'Import session data: group names', 0xFFFFFFFF )
        end
        ImGui.PopStyleColor(ctx,3)
      
        -- list 
          if DATA.srcproj.GROUPNAMES  then
            ImGui.PushStyleColor(ctx, ImGui.Col_Border,0x505050FF)
            ImGui.BeginDisabled(ctx,true)
            if ImGui.BeginChild(ctx, 'group_exploded',0,120, ImGui.ChildFlags_AutoResizeY|ImGui.ChildFlags_Borders ) then
              
              for key in spairs(DATA.srcproj.GROUPNAMES) do
                ImGui.Text(ctx, key+1 )
                ImGui.SameLine(ctx)
                ImGui.TextColored(ctx, 0x50F050FF, DATA.srcproj.GROUPNAMES[key] )
              end
              ImGui.EndChild(ctx)
            end
            ImGui.EndDisabled(ctx)
            ImGui.PopStyleColor(ctx)
          end
          
          
      ImGui.Unindent(ctx, UI.indent_menu)
    end  
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_header_Various()
    if not (DATA.srcproj and DATA.srcproj.HEADER_renderconf) then return end
    if ImGui.CollapsingHeader(ctx, 'Various') then --, nil, reaper.ImGui_TreeNodeFlags_DefaultOpen()
      ImGui.Indent(ctx, UI.indent_menu) 
      
      
      -- import 
        ImGui.Custom_InvisibleButton(ctx, 'Render configuration')
        ImGui.SameLine(ctx)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.col_red, 0.4))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.col_red, 1))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.col_red, 0.6))
        if ImGui.Button(ctx, 'Import') then 
          Undo_BeginBlock2( 0 )
          reaper.PreventUIRefresh( -1 )
          if DATA.srcproj.HEADER_renderconf then GetSetProjectInfo_String( 0, 'RENDER_FORMAT', DATA.srcproj.HEADER_renderconf, 1 )  end 
          DATA:Import2_Header_RefreshProject()
          reaper.PreventUIRefresh( 1 )
          Undo_EndBlock2( 0, 'Import session data: render config', 0xFFFFFFFF )
        end
        ImGui.PopStyleColor(ctx,3)
          
          
      ImGui.Unindent(ctx, UI.indent_menu)
    end  
  end
  
  --------------------------------------------------------------------- 
  function UI.draw_tabs_header()
    local indent = UI.indent_menu
    function __b_draw_tabs_header() end
    if ImGui.BeginTabItem(ctx, 'Header') then --,false, reaper.ImGui_TabItemFlags_SetSelected()
      UI.draw_tabs_header_master()
      UI.draw_tabs_header_regions()
      UI.draw_tabs_header_tempomap()
      UI.draw_tabs_header_groupnames()
      UI.draw_tabs_header_Various()
      ImGui.EndTabItem(ctx)
    end
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_sendimportlogic()
    local indent = UI.indent_menu
    function __b_draw_tabs_sendimportlogic() end
    if ImGui.BeginTabItem(ctx, 'Track send import logic') then -- ,false, reaper.ImGui_TabItemFlags_SetSelected()
      
      local x1,y1 = reaper.ImGui_GetCursorScreenPos(ctx)
      local xav, yav = reaper.ImGui_GetContentRegionAvail( ctx )
      local x2 = x1+xav
      local y2 = y1+yav
      UI.calc_SIL_x1 = x1
      UI.calc_SIL_x2 = x2
      UI.calc_SIL_y1 = y1
      UI.calc_SIL_y2 = y2
      UI.calc_SIL_W = UI.calc_SIL_x2 - UI.calc_SIL_x1
      UI.calc_SIL_H = UI.calc_SIL_y2 - UI.calc_SIL_y1
      UI.calc_SIL_Xspacing = 20
      UI.calc_SIL_Yspacing = 10
      local cntX = 4
      local cntY = 5
      UI.calc_SIL_nodeW = (UI.calc_SIL_W - UI.calc_SIL_Xspacing*(cntX+1)) / cntX
      UI.calc_SIL_nodeH = (UI.calc_SIL_H - UI.calc_SIL_Yspacing*(cntY+1)) / cntY
      ImGui.DrawList_AddRect( UI.draw_list, x1,y1,x2,y2, 0x7070704F, 5, reaper.ImGui_DrawFlags_None(), 1 )
      
      
      UI.draw_tabs_sendimportlogic_DefineT()
      for node_key in pairs(DATA.SIL_nodes) do
        UI.draw_tabs_sendimportlogic_Node(DATA.SIL_nodes[node_key])
      end
        
      ImGui.EndTabItem(ctx)
    end
  end
  
  --------------------------------------------------------------------- 
  function UI.draw_tabs_sendimportlogic_Node(t)
    local indent = 5
    local bezier_offsX = 40
    local arrow_lenX = 7
    local arrow_lenY = 7 
    local fontsz = 12
    
    ImGui.PushFont(ctx, DATA.font, fontsz)
    local ymidnode = math.floor(UI.calc_SIL_nodeH/2) 
    local x1 = UI.calc_SIL_x1 + UI.calc_SIL_Xspacing + (UI.calc_SIL_Xspacing + UI.calc_SIL_nodeW) * t.x
    local x2 = x1 + UI.calc_SIL_nodeW
    local y1 = UI.calc_SIL_y1 + UI.calc_SIL_Yspacing + (UI.calc_SIL_Yspacing + UI.calc_SIL_nodeH) * t.y
    local y2 = y1 + UI.calc_SIL_nodeH
    nodeframecol = 0x505050FF
    ImGui.DrawList_AddRect( UI.draw_list, x1,y1,x2,y2,nodeframecol, 2, reaper.ImGui_DrawFlags_None(), 1 )
    
    local txt_col = 0xFFFFFFFF
    if t.valid ~= true then txt_col = 0xFFFFFF5F end
    ImGui.SetCursorScreenPos(ctx,x1+indent,y1+indent)
    if t.ext_key then 
      if not t.combo then 
        if  t.valid ~= true then ImGui.BeginDisabled(ctx, true) end
        if ImGui.Checkbox( ctx, '##SILnodekey'..t.key, EXT[t.ext_key]&(t.ext_key_bit) == (t.ext_key_bit) ) then EXT[t.ext_key] =EXT[t.ext_key]~(t.ext_key_bit) EXT:save() end
        if t.valid ~= true then ImGui.EndDisabled(ctx) end
        local w, h = reaper.ImGui_GetItemRectSize( ctx )
        ImGui.DrawList_AddTextEx( UI.draw_list, DATA.font, fontsz, x1+indent*2+w,y1+indent, txt_col, t.txt, UI.calc_SIL_nodeW-indent*2 )
      end
      
      if t.combo then
        ImGui.SetNextItemWidth(ctx, UI.calc_SIL_nodeW - indent*2)
        local preview = t.combo[EXT[t.ext_key]]
        if  t.valid ~= true then ImGui.BeginDisabled(ctx, true) end
        if ImGui.BeginCombo(ctx, '##SILnodekey'..t.key, preview) then
          for val in spairs(t.combo) do
            if ImGui.Selectable(ctx, t.combo[val], EXT[t.ext_key] == val) then EXT[t.ext_key] = val EXT:save() end
          end
          ImGui.EndCombo(ctx)
        end
        if t.valid ~= true then ImGui.EndDisabled(ctx) end
      end
     else
      ImGui.DrawList_AddTextEx( UI.draw_list, DATA.font, fontsz, x1+indent,y1+indent, txt_col, t.txt, UI.calc_SIL_nodeW-indent*2 )
    end
    
    if t.dest_node_t then 
      for dest_node_tID in pairs(t.dest_node_t) do
        local dest_tkey = t.dest_node_t[dest_node_tID].destkey
        local wire = t.dest_node_t[dest_node_tID].wire
        local wire_valid = t.dest_node_t[dest_node_tID].valid
        local dest_t = DATA.SIL_nodes[dest_tkey]
        
        local destx1 = UI.calc_SIL_x1 + UI.calc_SIL_Xspacing + (UI.calc_SIL_Xspacing + UI.calc_SIL_nodeW) * dest_t.x
        local desty1 = UI.calc_SIL_y1 + UI.calc_SIL_Yspacing + (UI.calc_SIL_Yspacing + UI.calc_SIL_nodeH) * dest_t.y
        local p1_x = x2
        local p1_y = y1 + ymidnode
        local p4_x = destx1
        local p4_y = desty1+ ymidnode
        local p2_x = p1_x + bezier_offsX
        local p2_y = p1_y 
        local p3_x = p4_x - bezier_offsX
        local p3_y = p4_y 
        local col_rgba = 0x7F7F7FFF
        if wire == 'yes' then col_rgba = 0x509050FF end
        if wire == 'no' then col_rgba = 0x905050FF end
        local thickness = 2
        
        if t.valid ~= true or wire_valid ~= true  then col_rgba = (col_rgba&0xF0F0F000) | 0x3F end
        ImGui.DrawList_AddBezierCubic( UI.draw_list, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y,p4_x, p4_y, col_rgba, thickness, 0 )
        ImGui.DrawList_AddLine( UI.draw_list, p4_x-arrow_lenX, p4_y-arrow_lenY, p4_x, p4_y, col_rgba, thickness )
        ImGui.DrawList_AddLine( UI.draw_list, p4_x-arrow_lenX, p4_y+arrow_lenY-1, p4_x, p4_y-1, col_rgba, thickness )
      end
    end
    ImGui.PopFont(ctx)
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_settings()
    local indent = UI.indent_menu
    function __b_draw_tabs_settings() end
    if ImGui.BeginTabItem(ctx, 'Options') then  -- ,false, reaper.ImGui_TabItemFlags_SetSelected()
      
      ImGui.SeparatorText(ctx, 'Track matching')
      ImGui.Indent(ctx, indent)
        if ImGui.Checkbox( ctx, 'Match source project tracks at initialization##UI_appatinit1', EXT.UI_appatinit&2 == 2 ) then EXT.UI_appatinit =EXT.UI_appatinit~2 EXT:save() end
        if ImGui.Checkbox( ctx, 'Match tracks on setting source##UI_matchatsettingsrc', EXT.UI_matchatsettingsrc&2 == 2 ) then EXT.UI_matchatsettingsrc =EXT.UI_matchatsettingsrc~1 EXT:save() end
        local t = {[1] = 'Exact match', [2] = 'At least one word match'}
        local preview_value = t[EXT.CONF_tr_matchmode]
        reaper.ImGui_SetNextItemWidth(ctx, 150)
        if reaper.ImGui_BeginCombo( ctx, 'Match algorithm', preview_value, reaper.ImGui_ComboFlags_HeightLargest() ) then
          for key in pairs(t) do
            if ImGui.Selectable(ctx, t[key]..'##CONF_tr_matchmode'..key) then EXT.CONF_tr_matchmode = key EXT:save() end 
          end
          reaper.ImGui_EndCombo( ctx )
        end  
        if ImGui.Checkbox( ctx, 'Do not allow auto match sends/aux children##CONF_tr_match_preventsends', EXT.CONF_tr_match_preventsends&1 == 1 ) then EXT.CONF_tr_match_preventsends =EXT.CONF_tr_match_preventsends~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Auto match sends/aux children as receives##CONF_tr_match_automatchsendsasdest', EXT.CONF_tr_match_automatchsendsasdest&1 == 1 ) then EXT.CONF_tr_match_automatchsendsasdest =EXT.CONF_tr_match_automatchsendsasdest~1 EXT:save() end
      ImGui.Unindent(ctx, indent)
      
      
      ImGui.SeparatorText(ctx, 'Various')
      ImGui.Indent(ctx, indent)
        if ImGui.Checkbox( ctx, 'Ignore tracklist selection at import##UI_ignoretracklistselection', EXT.UI_ignoretracklistselection&1 == 1 ) then EXT.UI_ignoretracklistselection =EXT.UI_ignoretracklistselection~1 EXT:save() end
        ImGui.SameLine(ctx) UI.HelpMarker('Always import all tracks marked for import')
        if ImGui.Checkbox( ctx, 'Parse source project at initialization##UI_appatinit', EXT.UI_appatinit&1 == 1 ) then EXT.UI_appatinit =EXT.UI_appatinit~1 EXT:save() end
        if ImGui.Checkbox( ctx, 'Hide src proj hidden tracks in list##UI_hidesrchiddentracks', EXT.UI_hidesrchiddentracks&2 == 2 ) then EXT.UI_hidesrchiddentracks =EXT.UI_hidesrchiddentracks~1 EXT:save() end
      ImGui.Unindent(ctx, indent)
      
      
      
      
      ImGui.EndTabItem(ctx)
    end
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_tracks() 
    if not (DATA.srcproj and DATA.srcproj.TRACK) then return end
    if ImGui.BeginTabItem(ctx, 'Tracks') then 
      
      -- buttons
      if ImGui.BeginChild(ctx, 'tracklist_actions', UI.tracklist_W,25) then --reaper.ImGui_ChildFlags_Borders()
        -- filter
        reaper.ImGui_SetNextItemWidth(ctx, 150)
        local retval, buf = reaper.ImGui_InputText( ctx, '##tracks_inputbuf', DATA.temp_inputtrackfiltbuf, reaper.ImGui_InputTextFlags_None() )
        DATA.temp_inputtrackfiltbuf = buf
        if retval then EXT.UI_trfilter = buf EXT:save() end
        if DATA.temp_inputtrackfiltbuf == '' then 
          local p_min_x, p_min_y = reaper.ImGui_GetItemRectMin( ctx )
          local p_max_x, p_max_y = reaper.ImGui_GetItemRectMax( ctx )
          ImGui.DrawList_AddText( UI.draw_list, p_min_x+UI.spacingX*3, p_min_y+UI.spacingY, UI.Tools_RGBA(UI.col_text, UI.col_text_a_disabled), 'track name filter' ) 
        end
        
        -- match
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Match',120) then 
          DATA:Tracks_SetDestination(-1, 0, nil) 
          DATA:MatchTrack() 
        end
        
        -- new track
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Set to new track',120) then 
          local cnt_selection = 0 for trid0 = 1, #DATA.srcproj.TRACK do if DATA.srcproj.TRACK[trid0].UI_selected == true then cnt_selection = cnt_selection + 1 end end
          for i = 1, #DATA.srcproj.TRACK do 
            if cnt_selection == 0 or (cnt_selection > 0 and DATA.srcproj.TRACK[i].UI_selected == true) then DATA:Tracks_SetDestination(i, 1) end
          end 
        end
        
        -- reset
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Reset',-1) then 
          local cnt_selection = 0 for trid0 = 1, #DATA.srcproj.TRACK do if DATA.srcproj.TRACK[trid0].UI_selected == true then cnt_selection = cnt_selection + 1 end end
          for i = 1, #DATA.srcproj.TRACK do 
            if cnt_selection == 0 or (cnt_selection > 0 and DATA.srcproj.TRACK[i].UI_selected == true) then DATA:Tracks_SetDestination(i, 0) end
          end 
        end
        
        ImGui.EndChild(ctx)
      end
      
      -- import
      ImGui.SameLine(ctx)
      ImGui.PushStyleColor(ctx, ImGui.Col_Button,           UI.Tools_RGBA(UI.col_red, 0.4))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     UI.Tools_RGBA(UI.col_red, 1))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    UI.Tools_RGBA(UI.col_red, 0.6))
      if ImGui.Button(ctx, 'Import',-1) then 
        Undo_BeginBlock2( 0 )
        reaper.PreventUIRefresh( -1 )
        DATA:Import2_Tracks() 
        DATA:Import2_Header_RefreshProject() 
        reaper.PreventUIRefresh( 1 )
        Undo_EndBlock2( 0, 'Import session data: tracks', 0xFFFFFFFF )
      end
      ImGui.PopStyleColor(ctx,3)
      
      -- tracklist
      UI.draw_tabs_tracks_list() 
      ImGui.SameLine(ctx)
      UI.draw_tabs_tracks_settings()  
      
      ImGui.EndTabItem(ctx)
    end
  end
  
  ---------------------------------------------------------------------  
  function UI.draw_tabs_tracks_settings()
    function __b_draw_tabs_tracks_settings() end
    local indent = UI.indent_menu
    if ImGui.BeginChild(ctx, 'tracklist_settings', -1,-1) then--, reaper.ImGui_ChildFlags_Borders()) then
       
       
      if ImGui.CollapsingHeader(ctx, 'Import properties', nil, reaper.ImGui_TreeNodeFlags_DefaultOpen()) then 
        ImGui.Indent(ctx, indent)
          if ImGui.Checkbox( ctx, 'Name##CONF_tr_name',                                 EXT.CONF_tr_name&1 == 1 ) then EXT.CONF_tr_name =EXT.CONF_tr_name~1 EXT:save() end
          if EXT.CONF_tr_name&1 == 1 then 
            ImGui.Indent(ctx, indent)
            if ImGui.Checkbox( ctx, 'If dest track name is empty##CONF_tr_name2',       EXT.CONF_tr_name&2 == 2 ) then EXT.CONF_tr_name =EXT.CONF_tr_name~2 EXT:save() end
            ImGui.Unindent(ctx, indent)
          end
          if ImGui.Checkbox( ctx, 'Volume##CONF_tr_VOL',                              EXT.CONF_tr_VOL&1 == 1 ) then EXT.CONF_tr_VOL =EXT.CONF_tr_VOL~1 EXT:save() end
          if ImGui.Checkbox( ctx, 'Pan / Width / Pan Law / Pan mode##CONF_tr_PAN',    EXT.CONF_tr_PAN&1 == 1 ) then EXT.CONF_tr_PAN =EXT.CONF_tr_PAN~1 EXT:save() end
          if ImGui.Checkbox( ctx, 'Phase##CONF_tr_PHASE',                             EXT.CONF_tr_PHASE&1 == 1 ) then EXT.CONF_tr_PHASE =EXT.CONF_tr_PHASE~1 EXT:save() end
          if ImGui.Checkbox( ctx, 'Record input / Monitoring##CONF_tr_RECINPUT',      EXT.CONF_tr_RECINPUT&1 == 1 ) then EXT.CONF_tr_RECINPUT =EXT.CONF_tr_RECINPUT~1 EXT:save() end
          if ImGui.Checkbox( ctx, 'Parent send / channels##CONF_tr_MAINSEND',         EXT.CONF_tr_MAINSEND&1 == 1 ) then EXT.CONF_tr_MAINSEND =EXT.CONF_tr_MAINSEND~1 EXT:save() end
          if ImGui.Checkbox( ctx, 'Color##CONF_tr_CUSTOMCOLOR',                       EXT.CONF_tr_CUSTOMCOLOR&1 == 1 ) then EXT.CONF_tr_CUSTOMCOLOR =EXT.CONF_tr_CUSTOMCOLOR~1 EXT:save() end
          if ImGui.Checkbox( ctx, 'Layout##CONF_tr_LAYOUTS',                          EXT.CONF_tr_LAYOUTS&1 == 1 ) then EXT.CONF_tr_LAYOUTS =EXT.CONF_tr_LAYOUTS~1 EXT:save() end
          if ImGui.Checkbox( ctx, 'Group flags##CONF_tr_GROUPMEMBERSHIP',             EXT.CONF_tr_GROUPMEMBERSHIP&1 == 1 ) then EXT.CONF_tr_GROUPMEMBERSHIP =EXT.CONF_tr_GROUPMEMBERSHIP~1 EXT:save() end
          if EXT.CONF_tr_GROUPMEMBERSHIP&1 == 1 then 
            ImGui.Indent(ctx, indent)
            if ImGui.Checkbox( ctx, 'Avoid using existing (experimental)##CONF_tr_GROUPMEMBERSHIP2',       EXT.CONF_tr_GROUPMEMBERSHIP&2 == 2 ) then EXT.CONF_tr_GROUPMEMBERSHIP =EXT.CONF_tr_GROUPMEMBERSHIP~2 EXT:save() end
            ImGui.Unindent(ctx, indent)
          end
        ImGui.Unindent(ctx, indent)
      end
      
      
      if ImGui.CollapsingHeader(ctx, 'Import items') then
        ImGui.Indent(ctx, indent)
          if ImGui.Checkbox( ctx, 'Add items##CONF_tr_it',                           EXT.CONF_tr_it&1 == 1 ) then EXT.CONF_tr_it =EXT.CONF_tr_it~1 EXT:save() end
          if EXT.CONF_tr_it&1 == 1 then 
            ImGui.Indent(ctx, indent)
            if ImGui.Checkbox( ctx, 'Fix relative paths (experimental)##CONF_tr_it4',     EXT.CONF_tr_it&16 == 16 ) then EXT.CONF_tr_it =EXT.CONF_tr_it~16 EXT:save() end
            if ImGui.Checkbox( ctx, 'Copy files (experimental)##CONF_tr_it5',             EXT.CONF_tr_it&32 == 32 ) then EXT.CONF_tr_it =EXT.CONF_tr_it~32 EXT:save() end 
            if ImGui.Checkbox( ctx, 'Offset at edit cursor##CONF_tr_it2',                 EXT.CONF_tr_it&4 == 4 ) then EXT.CONF_tr_it =EXT.CONF_tr_it~4 EXT:save() end
            if ImGui.Checkbox( ctx, 'Build any missing peaks##CONF_it_buildpeaks',        EXT.CONF_it_buildpeaks&1 == 1 ) then EXT.CONF_tr_it =EXT.CONF_it_buildpeaks~1 EXT:save() end
            ImGui.Unindent(ctx, indent)
          end
          if ImGui.Checkbox( ctx, 'Clear existing items##CONF_tr_it1',  EXT.CONF_tr_it&2 == 2 ) then EXT.CONF_tr_it =EXT.CONF_tr_it~2 EXT:save() end ImGui.SameLine(ctx) UI.HelpMarker('Valid when using matching tracks')
        ImGui.Unindent(ctx, indent)
      end
      
      
      if ImGui.CollapsingHeader(ctx, 'FX chain', nil) then
        ImGui.Indent(ctx, indent)
          if ImGui.Checkbox( ctx, 'Add track FX chain##CONF_tr_FX',                    EXT.CONF_tr_FX&1 == 1 ) then EXT.CONF_tr_FX =EXT.CONF_tr_FX~1 EXT:save() end
          --[[if EXT.CONF_tr_FX&1 == 1 then 
            ImGui.Indent(ctx, indent)
            if ImGui.Checkbox( ctx, 'FX envelopes##CONF_tr_FX2',                          EXT.CONF_tr_FX&4 == 4 ) then EXT.CONF_tr_FX =EXT.CONF_tr_FX~4 EXT:save() end
            ImGui.Unindent(ctx, indent)
          end]]
          if ImGui.Checkbox( ctx, 'Clear existing FX##CONF_tr_FX1',     EXT.CONF_tr_FX&2 == 2 ) then EXT.CONF_tr_FX =EXT.CONF_tr_FX~2 EXT:save() end ImGui.SameLine(ctx) UI.HelpMarker('Valid when using matching tracks')
        ImGui.Unindent(ctx, indent)
      end
      
      
      ImGui.EndChild(ctx)
    end
  end
  ---------------------------------------------------------------------  
  function DATA:Get_DestProject_ValidateSameSources()    -- clean up source mapping if destination has multiple sources
    local dest_GUID_used = {}
    for i= 1, #DATA.srcproj.TRACK do
      local GUIDsrc=DATA.srcproj.TRACK[i].GUID 
      if GUIDsrc then
        if DATA.srcproj.TRACK[i].destmode ==2 and DATA.srcproj.TRACK[i].dest_track_GUID then 
          if dest_GUID_used[DATA.srcproj.TRACK[i].dest_track_GUID]  then 
             DATA.srcproj.TRACK[i].destmode = 0
             DATA.srcproj.TRACK[i].dest_track_GUID = nil
           else 
            dest_GUID_used[DATA.srcproj.TRACK[i].dest_track_GUID] = GUIDsrc 
            DATA.srcproj.TRACK[i].has_source = true
          end
        end
      end
    end
  end 
  ---------------------------------------------------------------------  
  function DATA:Actions_DestMenu_SetExactDesttrackNum(trid_src,trid_dest) 
    if not DATA.srcproj.TRACK[trid_src] then return end 
    if not DATA.destproj.TRACK[trid_dest] then return end 
    
    local cnt_selection = DATA:Actions_Selection_Get()
    if cnt_selection <= 1 then
      DATA:Tracks_SetDestination(trid_src, 2, trid_dest) 
      DATA:Get_DestProject_ValidateSameSources()
     else
      for trid0 = 1, #DATA.srcproj.TRACK do if DATA.srcproj.TRACK[trid0].UI_selected then DATA:Tracks_SetDestination(trid0, 2, trid_dest) end end
      DATA:Get_DestProject_ValidateSameSources()
    end
  end 
  ---------------------------------------------------------------------  
  function DATA:Actions_DestMenu_Setmode(trid,mode,submode) 
    local cnt_selection = DATA:Actions_Selection_Get()
    local tr_ids = {}
    
    -- if menu at track + no selection
      if cnt_selection == 0 then tr_ids[#tr_ids+1] = trid end
      
    -- if menu at track + selection + track is selected
      if cnt_selection > 0 and DATA.srcproj.TRACK[trid].UI_selected == true then
        for i = 1, #DATA.srcproj.TRACK do
          if DATA.srcproj.TRACK[i].UI_selected == true then
            tr_ids[#tr_ids+1] = i
          end
        end
      end
      
    -- if menu at track + selection + track is not selected
      if cnt_selection > 0 and DATA.srcproj.TRACK[trid].UI_selected ~= true then
        tr_ids[#tr_ids+1] = trid
      end
  
     
    for i = 1,#tr_ids do
      local trid = tr_ids[i]
      DATA.srcproj.TRACK[trid].destmode = mode
      if mode ==2  then DATA.srcproj.TRACK[trid].destmode_submode = submode  end
      if mode ==0 or mode ==1 or mode ==3 then DATA:Tracks_SetDestination(trid, mode) end
      if mode ==2  then DATA:MatchTrack(trid, submode)  end
      if mode ==2 or mode ==3 then  DATA:Get_DestProject_ValidateSameSources()  end 
      if mode ==0 then
        DATA.srcproj.TRACK[trid].dest_track_GUID = nil
      end 
    end
  end 
  ----------------------------------------------------------------------
  function DATA:Tracks_IsDestinationUsed(desttrack_id)
    local destGUID = DATA.destproj.TRACK[desttrack_id].GUID 
    
    for j = 1, #DATA.srcproj.TRACK do
      if DATA.srcproj.TRACK[j].dest_track_GUID == destGUID then
        return true
      end
    end
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_tracks_destmenu(trid)  
    local dest = DATA.srcproj.TRACK[trid].dest_name_UI
    local preview = dest
    if ImGui.BeginCombo( ctx, dest, preview, ImGui.ComboFlags_HeightLargest|ImGui.ComboFlags_NoArrowButton ) then
      
      if DATA.destproject_cached ~= true then
        DATA:Get_DestProject()
        DATA:Get_DestProject_ValidateSameSources() 
        DATA.destproject_cached = true
      end
      
      ImGui.SeparatorText(ctx, 'Destination modes')
      
      if ImGui.Selectable(ctx, UI.default_none_dest..'##destcombo'..trid, DATA.srcproj.TRACK[trid].destmode == 0) then                    DATA:Actions_DestMenu_Setmode(trid,0) DATA.destproject_cached = false end
      if ImGui.Selectable(ctx, UI.default_newtrackatend_dest..'##destcombo'..trid, DATA.srcproj.TRACK[trid].destmode == 1) then           DATA:Actions_DestMenu_Setmode(trid,1) DATA.destproject_cached = false end
      if ImGui.Selectable(ctx, UI.default_newtrackatend1_dest..'##destcombo'..trid, DATA.srcproj.TRACK[trid].destmode == 3) then           DATA:Actions_DestMenu_Setmode(trid,3) DATA.destproject_cached = false end
      local state = DATA.srcproj.TRACK[trid].destmode==2 and (not DATA.srcproj.TRACK[trid].destmode_submode or (DATA.srcproj.TRACK[trid].destmode_submode and DATA.srcproj.TRACK[trid].destmode_submode==0))
      if ImGui.Selectable(ctx, 'Match by name: replace'..'##destcombo'..trid, state) then  DATA:Actions_DestMenu_Setmode(trid,2) DATA.destproject_cached = false end
      local state = DATA.srcproj.TRACK[trid].destmode==2 and DATA.srcproj.TRACK[trid].destmode_submode == 1
      if ImGui.Selectable(ctx, 'Match by name: place under matched track'..'##destcombo'..trid, state) then  DATA:Actions_DestMenu_Setmode(trid,2,1) DATA.destproject_cached = false end      
      local state = DATA.srcproj.TRACK[trid].destmode==2 and DATA.srcproj.TRACK[trid].destmode_submode == 2
      if ImGui.Selectable(ctx, 'Match by name: place under matched track as child'..'##destcombo'..trid, state) then  DATA:Actions_DestMenu_Setmode(trid,2,2) DATA.destproject_cached = false end  
      local state = DATA.srcproj.TRACK[trid].destmode==2 and DATA.srcproj.TRACK[trid].destmode_submode == 4
      if ImGui.Selectable(ctx, 'Match by name: mark only for receive'..'##destcombo'..trid, state) then  DATA:Actions_DestMenu_Setmode(trid,2,4) DATA.destproject_cached = false end  
      local state = DATA.srcproj.TRACK[trid].destmode==2 and DATA.srcproj.TRACK[trid].destmode_submode == 5
      if ImGui.Selectable(ctx, 'Match by ID'..'##destcombo'..trid, state) then  DATA:Actions_DestMenu_Setmode(trid,2,5) DATA.destproject_cached = false end
      local state = DATA.srcproj.TRACK[trid].destmode==2 and DATA.srcproj.TRACK[trid].destmode_submode == 6
      if ImGui.Selectable(ctx, 'Match by color'..'##destcombo'..trid, state) then  DATA:Actions_DestMenu_Setmode(trid,2,6) DATA.destproject_cached = false end
      
      ImGui.SeparatorText(ctx, 'Destination project track by number')
      local buf = DATA.temp_buf_destprojexactnum
      local retval, buf = ImGui.InputText( ctx, '##destcombo'..trid, buf, reaper.ImGui_InputTextFlags_CharsDecimal() ) 
      DATA.temp_buf_destprojexactnum = tonumber(buf)
      if DATA.temp_buf_destprojexactnum then
        ImGui.SameLine(ctx) 
        if ImGui.Button(ctx, 'OK') then 
          DATA:Actions_DestMenu_SetExactDesttrackNum(trid,tonumber(buf))  
          DATA.destproject_cached = false 
          ImGui.CloseCurrentPopup(ctx) 
        end  
      end
      
      ImGui.SeparatorText(ctx, 'Destination project track, select from list')
      local buf = DATA.temp_buf_destprojfilter
      local retval, buf = ImGui.InputText( ctx, 'Name filter##desttrselectorfilter'..trid, buf, reaper.ImGui_InputTextFlags_None() ) 
      DATA.temp_buf_destprojfilter = buf 
      ImGui.PushStyleColor(ctx, ImGui.Col_Border,           UI.Tools_RGBA(0xF0F0F0, 0.1))
      local has_filter = DATA.temp_buf_destprojfilter~=''
      local filt = DATA.temp_buf_destprojfilter:lower():gsub('[%p%s]','')
      if ImGui.BeginChild( ctx, '##desttrselector'..trid,0,150,reaper.ImGui_ChildFlags_Borders()) then
        for i= 1, #DATA.destproj.TRACK do
          if DATA:Tracks_IsDestinationUsed(i) == true then goto skipnestdest end
          local destname = DATA.destproj.TRACK[i].tr_name
          if has_filter==true and destname:lower():gsub('[%p%s]',''):match(filt)==nil then  goto skipnestdest end
          local str='['..i..'] '..destname..'##desttrselector'..trid..'destid'..i
          
          local state = DATA.srcproj.TRACK[trid].dest_track_GUID and DATA.srcproj.TRACK[trid].dest_track_GUID == DATA.destproj.TRACK[i].GUID
          
          if ImGui.Selectable(ctx, str, state) then 
            local cnt_selection = DATA:Actions_Selection_Get()
            if cnt_selection <= 1 then
              DATA:Tracks_SetDestination(trid, 2, i) 
              DATA:Get_DestProject_ValidateSameSources()
             else
              for trid0 = 1, #DATA.srcproj.TRACK do if DATA.srcproj.TRACK[trid0].UI_selected then DATA:Tracks_SetDestination(trid0, 2, i) end end
              DATA:Get_DestProject_ValidateSameSources()
            end
            DATA.destproject_cached = false
          end
          ::skipnestdest::
        end
        ImGui.EndChild( ctx )
      end
      ImGui.PopStyleColor(ctx)
      
      
      ImGui.SeparatorText(ctx, 'Direct import') 
      if ImGui.Selectable(ctx, 'Import FX chain to selected track##ImportFX'..trid) then DATA:Action_ImportFXToSelTrack(trid) end
      if ImGui.Selectable(ctx, 'Import items to selected track##Importitem'..trid) then DATA:Action_ImportItemsToSelTrack(trid) end
      
      
      ImGui.EndCombo( ctx)
    end
    
    
    
  end
  ---------------------------------------------------------------------  
  function DATA:Action_ImportFXToSelTrack(trid) 
    local sel_tr = GetSelectedTrack(-1,0) 
    if not sel_tr then return end
    
    local new_tr_src = DATA:Import_CreateNewTrack(false, DATA.srcproj.TRACK[trid] ) 
    local dest_cnt = TrackFX_GetCount( sel_tr ) 
    for src_fx = 1, TrackFX_GetCount( new_tr_src ) do 
      TrackFX_CopyToTrack( new_tr_src, src_fx-1, sel_tr, dest_cnt + src_fx-1, false )  
      --DATA:Import_TransferTrackData_FXchain_Envelopes(new_tr_src, sel_tr,dest_cnt,src_fx)
    end
    DeleteTrack( new_tr_src ) -- remove temporary 
  end
  ---------------------------------------------------------------------  
  function DATA:Action_ImportItemsToSelTrack(trid) 
    local sel_tr = GetSelectedTrack(-1,0) 
    if not sel_tr then return end
    
    local src_tr = DATA:Import_CreateNewTrack(false, DATA.srcproj.TRACK[trid] ) 
    local curpos = GetCursorPosition() 
    for itemidx = 1,  CountTrackMediaItems( src_tr ) do
      local item = GetTrackMediaItem( src_tr, itemidx-1 )
      local retval, chunk = reaper.GetItemStateChunk( item, '', false ) 
      local gGUID = genGuid('' ) 
      chunk = chunk:gsub('GUID (%{.-%})\n', 'GUID '..gGUID..'\n')
      chunk = DATA:Import_TransferTrackData_Items_handlesources(chunk)   
      local new_it = AddMediaItemToTrack( sel_tr )
      SetItemStateChunk( new_it, chunk, false )
    end 
    
    DeleteTrack( src_tr ) -- remove temporary 
  end
  ---------------------------------------------------------------------  
  function DATA:Actions_Selection_Reset()
    if not (DATA.srcproj and DATA.srcproj.TRACK) then return end
    for trid0 = 1, #DATA.srcproj.TRACK do DATA.srcproj.TRACK[trid0].UI_selected = false end
  end
  ---------------------------------------------------------------------  
  function DATA:Actions_Selection_Get() 
    if not (DATA.srcproj and DATA.srcproj.TRACK) then return end
    local cnt_selection = 0
    local min_id, max_id = math.huge,-1
    for trid0 = 1, #DATA.srcproj.TRACK do
      if DATA.srcproj.TRACK[trid0].UI_selected == true then 
        cnt_selection = cnt_selection + 1
        min_id = math.min(min_id, trid0)
        max_id = math.max(max_id, trid0)
      end
    end
    return cnt_selection, min_id, max_id
  end
  ---------------------------------------------------------------------  
  function DATA:Actions_Selection_ontrackclick(trid) 
    -- collect/handle selection
      if UI.Mod_Shift == true then 
        local cnt_selection, min_id, max_id = DATA:Actions_Selection_Get()  
        if cnt_selection == 1 then 
          if trid > min_id then 
            for i = min_id, trid do DATA.srcproj.TRACK[i].UI_selected = true end
           elseif trid < min_id then 
            for i = trid, min_id do DATA.srcproj.TRACK[i].UI_selected = true end
          end
         elseif cnt_selection > 1 then 
          if min_id < trid then
            for i = min_id, trid do DATA.srcproj.TRACK[i].UI_selected = true end
           elseif min_id >= trid and max_id > trid then
            for i = trid, max_id do DATA.srcproj.TRACK[i].UI_selected = true end
          end
        end
        return
      end 
      
    -- toggle current track state
      if UI.Mod_Ctrl == true then
        DATA.srcproj.TRACK[trid].UI_selected = not DATA.srcproj.TRACK[trid].UI_selected  
       else -- click to reset selection and set current track to ON
        DATA:Actions_Selection_Reset()   
        DATA.srcproj.TRACK[trid].UI_selected = true
      end 
      
      
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
  function UI.draw_preset() 
    -- preset 
    
    local select_wsz = 250
    local select_hsz = 18
    --ImGui.Custom_InvisibleButton(ctx, 'Preset')
    --ImGui.SameLine(ctx)
    
    local preview = EXT.CONF_name 
    reaper.ImGui_SetNextItemWidth(ctx,-60)
    if ImGui.BeginCombo(ctx, 'Preset##Preset', preview, ImGui.ComboFlags_HeightLargest) then 
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
          EXT.preset_base64_user = table.save(DATA.presets.user)
          EXT:save() 
        end
      end 
      
      
      
      ImGui.PopStyleVar(ctx)
      
      
      ImGui.EndCombo(ctx) 
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
  function DATA:Actions_SetSourceRPP()
    local retval, filenameNeed4096 = reaper.GetUserFileNameForRead(EXT.UI_lastsrcproj, 'Import RPP session data', '' )
    if retval then  
      EXT.UI_lastsrcproj=filenameNeed4096
      EXT:save()
      DATA:ParseSourceProject(filenameNeed4096)
      if EXT.UI_matchatsettingsrc==1 then
        DATA:Tracks_SetDestination(-1, 0, nil) 
        DATA:MatchTrack() 
      end
      
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_topbuttons() 
    -- dest
      local destprojname = DATA.destproj.fp
      ImGui.Custom_InvisibleButton(ctx, 'Dest RPP:') 
      ImGui.SameLine(ctx)
      reaper.ImGui_SetCursorPosX(ctx, 100)
      ImGui.PushFont(ctx, DATA.font, 13)
      if ImGui.Button(ctx, destprojname..'##getdestrpp',300) then DATA:Get_DestProject() end
      ImGui.PopFont(ctx)
    -- preset
      ImGui.SameLine(ctx)
      UI.draw_preset() 
    -- source
      local srcprojfp = '[not defined]' 
      if DATA.srcproj and DATA.srcproj.fp then srcprojfp = DATA.srcproj.fp end  
      ImGui.Custom_InvisibleButton(ctx, 'Source RPP:')
      ImGui.SameLine(ctx)
      ImGui.PushFont(ctx, DATA.font, 13)
            reaper.ImGui_SetCursorPosX(ctx, 100)
      if ImGui.Button(ctx, srcprojfp..'##getsrcrpp',-1) then DATA:Actions_SetSourceRPP() end
      ImGui.PopFont(ctx)
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
    DATA.presets.user = table.load( EXT.preset_base64_user ) or {}
    
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
        DATA.presets.user[name] = CopyTable(t[tid])
        ::nextpres::
      end
      EXT.update_presets = 0
      EXT:save()
    end
  end
  ---------------------------------------------------------------------------------------------------------------------
  function GetParentFolder(dir) return dir:match('(.*)[%\\/]') end  
  
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExtractChunks(content, key, output_t, tracktemplatemode)
    local t = {}
    local sep = '  '
    for block in content:gmatch('[\n\r]+'..sep..'<('..key..'.-'..')[\n\r]'..sep..'>') do t[#t +1] = {chunk=block } end
    
    if tracktemplatemode ==true  then t[#t +1] = {chunk=content:match('<(.*)>') }end
    
    if output_t then output_t = CopyTable(t) else DATA.srcproj[key] = CopyTable(t) end
  end 
  
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_GetValues(str, ignorefirst)
    local t = {}
     tout = {}
    local brack = 0
    local temp_t = {}
    for sign in str:gmatch('.') do 
      if not (sign=='"' or (sign == ' ' and brack ==0)) then temp_t[#temp_t+1] = sign end
      if sign=='"' and brack == 0 then 
        brack = brack +1 
       elseif sign=='"' and brack > 0 then 
        brack = brack -1 
      end
      if sign == ' ' and brack == 0 and #temp_t>0 then 
        tout[#tout+1] = table.concat(temp_t)
        temp_t = {}
      end
    end
    tout[#tout+1] = table.concat(temp_t)

    
    if ignorefirst then table.remove(tout,1) end 
    for i = 1, #tout do  tout[i] = tonumber(tout[i]) or tout[i] end -- convert to numbers if possible
    if #tout > 0 then return tout end
  end  
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExplodeTrackData()
    if not DATA.srcproj.TRACK then return end
    local foldlev = 0 
    local trparams = {
      'NAME',
      'ISBUS',
      'TRACK',
      'PEAKCOL',
      'SHOWINMIX',
      --'LAYOUTS',
                  }
    local foldname = ''
    for tr_idx = 1, #DATA.srcproj.TRACK do
      local chunk = DATA.srcproj.TRACK[tr_idx].chunk
      DATA.srcproj.TRACK[tr_idx].chunk_full = chunk -- used for raw data import 
      DATA.srcproj.TRACK[tr_idx].GUID = chunk:match('(%{.-%})'):upper()
      -- extract items
        DATA.srcproj.TRACK[tr_idx].ITEM = {}
        local it_id = 0
        local item_pat = '[\n\r]+    <(ITEM.-)[\n\r]+    >'
        for item_block in chunk:gmatch(item_pat) do
          it_id = it_id + 1
          DATA.srcproj.TRACK[tr_idx].ITEM [it_id] = {chunk=item_block}
        end
        chunk = chunk:gsub(item_pat,'') -- clear track chunk from items 
        DATA.srcproj.TRACK[tr_idx].chunk = chunk -- update chunk
        
      -- extract fx chain
        local fx_pat = '[\n\r]+    <(FXCHAIN.-)[\n\r]+    >'
        local fxchunk = chunk:match(fx_pat)
        if fxchunk then
          local fx_id = 0
          DATA.srcproj.TRACK[tr_idx].FXCHAIN = {['chunk'] = fxchunk}
          for fx_block in fxchunk:gmatch('(BYPASS.-WAK.-[\n\r]+)') do
            fx_id = fx_id + 1
            DATA.srcproj.TRACK[tr_idx].FXCHAIN [fx_id] = fx_block
          end
          chunk = chunk:gsub(fx_pat,'') -- clear track chunk from fx_pat
          DATA.srcproj.TRACK[tr_idx].chunk = chunk -- update chunk
        end
        
      -- extract track params
        for line in chunk:gmatch('[^\r\n]+') do
          if line:match('AUXRECV') then
            if not DATA.srcproj.TRACK[tr_idx].RECEIVES then DATA.srcproj.TRACK[tr_idx].RECEIVES = {} end
            local out_valt = DATA:ParseSourceProject_GetValues(line, true)
            local tmap = {
              {id=1,key='src_tr_id'},--field 1, int, source track index (zero based)
              {id=2,key='mode'},--0 = Post Fader (Post Pan) //    1 = Pre FX //    3 = Pre Fader (Post FX)
              {id=3,key='vol'},
              {id=4,key='pan'},
              {id=5,key='mute'},--field 5, int (bool), mute
              {id=6,key='monosum'},--//  field 6, int (bool), mono sum
              {id=7,key='phase'},--//  field 7, int (bool), invert phase
              {id=8,key='src_chan'},--//  field 8, int, source audio channels //    -1 = none, 0 = 1+2, 1 = 2+3, 2 = 3+4 etc.
              {id=9,key='dest_chan'},--//  field 9, int, dest audio channels (as source but no -1)
              {id=10,key='panlaw'},--//  field 9, int, dest audio channels (as source but no -1)
              {id=11,key='midi_chan'},--//  field 11, int, midi channels //    source = val & 0x1F (0=None), dest = floor(val / 32)
              {id=12,key='automode'},--//  field 12, int, automation mode (-1 = use track mode)
              {id=13,key='unknown_str'},
                        }
            for i=1, #tmap do out_valt[tmap[i].key] = out_valt[tmap[i].id] out_valt[tmap[i].id] = nil end
            DATA.srcproj.TRACK[tr_idx].RECEIVES[#DATA.srcproj.TRACK[tr_idx].RECEIVES+1] = out_valt
            
          end
          
          for param = 1, #trparams do
            local param_str = trparams[param]
            if line:match(' '..param_str) then
              local out_valt = DATA:ParseSourceProject_GetValues(line, true)
              if not DATA.srcproj.TRACK[tr_idx][param_str] then DATA.srcproj.TRACK[tr_idx][param_str] = CopyTable(out_valt) end
              --DATA.srcproj.TRACK[tr_idx][param_str] = CopyTable(out_valt)
            end
          end 
        end
      
      -- handle parameters map
        --DATA.srcproj.TRACK[tr_idx].GUID = DATA.srcproj.TRACK[tr_idx].TRACK[1] 
        DATA.srcproj.TRACK[tr_idx].TRACK = nil
        local name = DATA.srcproj.TRACK[tr_idx].NAME[1] 
        DATA.srcproj.TRACK[tr_idx].NAME = name
        local PEAKCOL = DATA.srcproj.TRACK[tr_idx].PEAKCOL[1] 
        DATA.srcproj.TRACK[tr_idx].PEAKCOL = PEAKCOL
        if not (DATA.srcproj.TRACK[tr_idx].SHOWINMIX and DATA.srcproj.TRACK[tr_idx].SHOWINMIX[4]) then DATA.srcproj.TRACK[tr_idx].SHOWINMIX[4]= 1 end
        
      -- handle folder level
        local cur_fold_state = DATA.srcproj.TRACK[tr_idx].ISBUS[2] or 0
        DATA.srcproj.TRACK[tr_idx].CUST_foldlev = foldlev
        if foldlev == 0 then foldname = name end
        foldlev = foldlev + cur_fold_state
        DATA.srcproj.TRACK[tr_idx].sendlogic_flags = EXT.CONF_sendlogic_flags
        DATA.srcproj.TRACK[tr_idx].foldname = foldname
    end
    
    -- handle sends
    for tr_idx = 1, #DATA.srcproj.TRACK do
      if DATA.srcproj.TRACK[tr_idx].RECEIVES then
        for recid = 1, #DATA.srcproj.TRACK[tr_idx].RECEIVES do
          local src_id = DATA.srcproj.TRACK[tr_idx].RECEIVES[recid].src_tr_id
          if DATA.srcproj.TRACK[src_id+1] then 
            if not DATA.srcproj.TRACK[src_id+1].SENDS then DATA.srcproj.TRACK[src_id+1].SENDS = {} end
            local id = #DATA.srcproj.TRACK[src_id+1].SENDS+1
            DATA.srcproj.TRACK[src_id+1].SENDS [id] = CopyTable(DATA.srcproj.TRACK[tr_idx].RECEIVES[recid])
            DATA.srcproj.TRACK[src_id+1].SENDS [id].dest_tr_id = tr_idx
            
            DATA.srcproj.TRACK[tr_idx].RECEIVES[recid].AUXRECV_SRC_GUID = DATA.srcproj.TRACK[src_id+1].GUID
            DATA.srcproj.TRACK[src_id+1].SENDS [id].AUXRECV_DEST_GUID = DATA.srcproj.TRACK[tr_idx].GUID
          end
        end
      end
    end
    
  end
  
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExtractMarkers_parse(line, pat)
    local t = {} 
    local temp
    for val in line:gmatch("%S+") do         -- based on https://stackoverflow.com/a/39757839
      if temp then
        if val:sub(#val, #val) == pat or '"' then
          print(temp.." "..val)
          temp = nil
        else
          temp = temp.." "..val
        end
      elseif val:sub(1,1) == '"' then
        temp = val
      else
        t[#t+1] = tonumber(val) or val
      end
    end
    table.remove(t,1)
    return t
  end
  
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExtractMarkers(content)
    DATA.srcproj.MARKERS = {}
    local reg_open
    local max_pos_beats = 0
    for line in content:gmatch('[^\r\n]+') do
      if line:match('MARKER') then
        local id, pos_sec, name, is_region_flags, col, val6, val7, GUID = line:match('MARKER ([%d]+) ([%d%p]+) (.-) ([%d]+) ([%d%p]+) ([%d%p]+) ([%a]+) {(.-)}')
        id = tonumber(id)
        pos_sec = tonumber(pos_sec)
        is_region_flags = tonumber(is_region_flags)
        col = tonumber(col)
        val6 = tonumber(val6)
        
        if not is_region_flags then 
          id, pos_sec, name, is_region_flags, col = line:match('MARKER ([%d]+) ([%d%p]+) (.-) ([%d]+) ([%d%p]+)')
        end
  
        if not is_region_flags then 
          id, pos_sec, name, is_region_flags = line:match('MARKER ([%d]+) ([%d%p]+) (.-) ([%d]+)')
        end
        
        id = tonumber(id)
        pos_sec = tonumber(pos_sec)
        is_region_flags = tonumber(is_region_flags)
        col = tonumber(col)
        
        
        if not is_region_flags then goto skipnextmarkerentry end
        
        local is_region = is_region_flags&1==1 
        local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos_sec)
        if name:sub(0,1)=='"' and name:sub(-1) == '"' then name = name:sub(2,-2) end
        DATA.srcproj.MARKERS[#DATA.srcproj.MARKERS+1] = 
            { id = id,
              pos = fullbeats,
              name = name,
              is_region = is_region,
              is_region_flags = is_region_flags,
              col = col,
              val6 = val6,
              val7 = val7,
              GUID = GUID, 
            }
        max_pos_beats = math.max(max_pos_beats, fullbeats)
        if is_region and not GUID then
          local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos_sec  )
          DATA.srcproj.MARKERS[#DATA.srcproj.MARKERS-1].rgnend = fullbeats 
          DATA.srcproj.MARKERS[#DATA.srcproj.MARKERS] = nil
          max_pos_beats = math.max(max_pos_beats, fullbeats)
        end  
      end
      
      ::skipnextmarkerentry::
    end 
    
    -- post for UI 
    for i = 1, #DATA.srcproj.MARKERS do
      if max_pos_beats == 0 then 
        DATA.srcproj.MARKERS[i].UI_pos_rel = 0
       else
        DATA.srcproj.MARKERS[i].UI_pos_rel = DATA.srcproj.MARKERS[i].pos / max_pos_beats
        if DATA.srcproj.MARKERS[i].rgnend then DATA.srcproj.MARKERS[i].UI_pos_rel2 = DATA.srcproj.MARKERS[i].rgnend / max_pos_beats end
      end
    end
    
  end
  
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExtractTempo(content)
    local chunk = content:match('<TEMPOENVEX(.-)>')
    if not chunk then return end
    
    DATA.srcproj.TEMPOMAP = {}
    for line in chunk:gmatch('[^\r\n]+') do
      if line:match('PT %d+') then
        local valt = {} for val in line:gmatch('[^%s]+') do valt[#valt+1] = val end
        local timepos = tonumber(valt[2])
        local bpm = tonumber(valt[3])
        local lineartempochange = tonumber(valt[4])&1==0
        local timesig_num, timesig_denom
        if valt[5] then
          local timesig = tonumber(valt[5]) or 0
          timesig_num = timesig&0xFFFF
          timesig_denom = (timesig>>16)&0xFFFF
        end
        DATA.srcproj.TEMPOMAP[#DATA.srcproj.TEMPOMAP+1] = {timepos=timepos,
                  bpm=bpm,
                  lineartempochange=lineartempochange,
                  timesig_num=timesig_num,
                  timesig_denom=timesig_denom}
      end
    end
  end
  
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExtractGroupNames(content)
    DATA.srcproj.GROUPNAMES = {}
    for line in content:gmatch('[^\r\n]+') do
      if line:match('GROUP_NAME') then
        local groupid, name = line:match('GROUP_NAME (%d+) (.*)')
        if groupid and name then 
          DATA.srcproj.GROUPNAMES[groupid] = name:match('"(.*)"') or name
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExplodeFXchunk(content, t)
    for line in content:gmatch('[^\r\n]+') do
      if 
        ( line:match('<VST') or 
          line:match('<JS') or 
          line:match('<AU') or 
          line:match('<DX') or
          line:match('<CLAP') or
          line:match('<LV')
        ) and 
        not line:match('<JS_SER') then
        
        plug_name = line:match('<[%a]+%s(.*)')
        if plug_name:sub(0,1) == '"' then 
          plug_name = plug_name:match([[%"(.-)%"]]) 
         else
          plug_name = plug_name:match('(.-)%s') 
        end
        t[#t+1] = plug_name
      end
    end
  end    
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_ExplodeHeaderData(content)
    DATA.srcproj.HEADER = content:match('(REAPER_PROJECT.-)<TRACK')
    DATA:ParseSourceProject_ExtractChunks(content, 'MASTERFXLIST', DATA.srcproj.HEADER_MASTERFXLIST)
    if DATA.srcproj.MASTERFXLIST[1] and DATA.srcproj.MASTERFXLIST[1].chunk then
      DATA.srcproj.MASTERFXLIST_exploded = {}
      DATA:ParseSourceProject_ExplodeFXchunk(DATA.srcproj.MASTERFXLIST[1].chunk, DATA.srcproj.MASTERFXLIST_exploded)
    end
    DATA:ParseSourceProject_ExtractMarkers(content)
    DATA:ParseSourceProject_ExtractTempo(content)
    DATA:ParseSourceProject_ExtractGroupNames(content)
    
    local HEADER_renderconf = content:match('<RENDER_CFG(.-)>')
    if HEADER_renderconf then DATA.srcproj.HEADER_renderconf = HEADER_renderconf:gsub('%s','') end
    
  end
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject_PostProcess()
    -- postprocess / for UI
      for trid in pairs(DATA.srcproj.TRACK) do
        DATA.srcproj.TRACK[trid].dest_name_UI = UI.default_none_dest..'##dest'..trid
        DATA.srcproj.TRACK[trid].NAME_UI = '['..trid..'] '..DATA.srcproj.TRACK[trid].NAME
        local PEAKCOL = DATA.srcproj.TRACK[trid].PEAKCOL 
        if PEAKCOL and PEAKCOL ~= 16576 then r, g, b = reaper.ColorFromNative( PEAKCOL ) end
        if r and g and b then 
          r = math.min(255,math.floor(255*math.sqrt(r/255)))
          g = math.min(255,math.floor(255*math.sqrt(g/255)))
          b = math.min(255,math.floor(255*math.sqrt(b/255)))
          local col_rgba =
            (r <<24) |
            (g <<16) |
            (b <<8) |
            0xFF
          DATA.srcproj.TRACK[trid].UI_col_rgba = col_rgba
        end
      end
  end
  ----------------------------------------------------------------------
  function DATA:ParseSourceProject(fp)
    if not fp then return end
    -- init
    DATA.srcproj = {}
    DATA.srcproj.fp = fp
    DATA.srcproj.path = GetParentFolder(fp)
    -- read file
    local f = io.open(fp, 'rb')
    if not f then return end
    local content = f:read('a')
    f:close()
    
    
    -- get chunks
      DATA.srcproj.is_tracktemplatemode = false if fp:lower():match('rtracktemplate') then DATA.srcproj.is_tracktemplatemode = true end
      DATA:ParseSourceProject_ExtractChunks(content, 'TRACK', nil, DATA.srcproj.is_tracktemplatemode)
      DATA:ParseSourceProject_ExplodeTrackData()
      DATA:ParseSourceProject_ExtractChunks(content, 'EXTENSIONS')
      DATA:ParseSourceProject_ExplodeHeaderData(content)
    
    -- postprocess / send-aux children
      for trid in pairs(DATA.srcproj.TRACK) do
        if DATA.srcproj.TRACK[trid].foldname:lower():match('send') or DATA.srcproj.TRACK[trid].foldname:lower():match('aux') then
          DATA.srcproj.TRACK[trid].prevent_from_auto_match = true
        end
      end
    
    DATA:ParseSourceProject_PostProcess()
  end
  
  ----------------------------------------------------------------------
  function DATA:Tracks_GetDestinationbyGUID(GUID) for j = 1, #DATA.destproj.TRACK do if GUID == DATA.destproj.TRACK[j].GUID then return j end end end
  ----------------------------------------------------------------------
  function DATA:Tracks_SetDestination_RefreshUI(srctrack_id) 
    if not DATA.srcproj.TRACK[srctrack_id]  then return end
    local dest = UI.default_none_dest 
    DATA.srcproj.TRACK[srctrack_id].dest_name_UI = dest
    
    if not DATA.srcproj.TRACK[srctrack_id].destmode  then return end
    if DATA.srcproj.TRACK[srctrack_id].destmode == 1 then 
      dest = '['..UI.default_newtrackatend_dest..']' 
     elseif DATA.srcproj.TRACK[srctrack_id].destmode == 3 then 
      dest = '['..UI.default_newtrackatend1_dest..']' 
     elseif DATA.srcproj.TRACK[srctrack_id].destmode == 2 then 
      if DATA.srcproj.TRACK[srctrack_id].dest_track_GUID then  
        local desttrid = DATA:Tracks_GetDestinationbyGUID(DATA.srcproj.TRACK[srctrack_id].dest_track_GUID)
        if desttrid and DATA.destproj.TRACK[desttrid] then dest = '['..desttrid..'] ' ..DATA.destproj.TRACK[desttrid].tr_name end
        if DATA.srcproj.TRACK[srctrack_id].destmode_submode == nil then dest = dest..' [replace]' end
        if DATA.srcproj.TRACK[srctrack_id].destmode_submode == 1 then dest = dest..' [under]' end
        if DATA.srcproj.TRACK[srctrack_id].destmode_submode == 2 then dest = dest..' [under, as child]' end
        if DATA.srcproj.TRACK[srctrack_id].destmode_submode == 4 then dest = dest..' [mark only]' end
      end
    end
    DATA.srcproj.TRACK[srctrack_id].dest_name_UI = dest..'##destselector'..srctrack_id
  end
  ----------------------------------------------------------------------
  function DATA:Tracks_SetDestination(srctrack_id, mode, desttrack_id)
    local output_error_code = 0
    if not ( DATA.srcproj and DATA.srcproj.TRACK and mode) then return end
    if DATA.srcproj.TRACK[srctrack_id] then  
      DATA.srcproj.TRACK[srctrack_id].destmode = mode 
      if mode == 2 then DATA.srcproj.TRACK[srctrack_id].sendlogic_flags = EXT.CONF_sendlogic_flags_matched end
      if DATA.srcproj.TRACK[srctrack_id].dest_track_GUID then
        local desttrack_id = DATA:Tracks_GetDestinationbyGUID( DATA.srcproj.TRACK[srctrack_id].dest_track_GUID)
        if desttrack_id and DATA.destproj.TRACK[desttrack_id] then 
          DATA.destproj.TRACK[desttrack_id].has_source =false 
        end
      end
      DATA.srcproj.TRACK[srctrack_id].dest_track_GUID = nil  
    end
    
    -- set for all tracks
      if srctrack_id == -1 and mode&2 ~= 2 then 
        for i = 1, #DATA.srcproj.TRACK do 
          if DATA.srcproj.TRACK[i].dest_track_GUID then
            local desttrack_id = DATA:Tracks_GetDestinationbyGUID( DATA.srcproj.TRACK[i].dest_track_GUID)
            if desttrack_id and DATA.destproj.TRACK[desttrack_id] then  
              DATA.destproj.TRACK[desttrack_id].has_source =false 
            end
          end
          DATA.srcproj.TRACK[i].dest_track_GUID = nil
          DATA.srcproj.TRACK[i].destmode = mode   
        end  
      end
      
    -- set specific track
      if mode&2==2 and desttrack_id and not DATA.destproj.TRACK[desttrack_id].has_source then
        if mode == 2 then DATA.srcproj.TRACK[srctrack_id].sendlogic_flags = EXT.CONF_sendlogic_flags_matched end
        local destGUID = DATA.destproj.TRACK[desttrack_id].GUID        -- check for already set up destination from somwwhere
        DATA.srcproj.TRACK[srctrack_id].destmode = 2
        DATA.srcproj.TRACK[srctrack_id].dest_track_GUID = DATA.destproj.TRACK[desttrack_id].GUID
        DATA.destproj.TRACK[desttrack_id].has_source =true  
      end
    
    
    
    DATA:Tracks_SetDestination_RefreshUI(srctrack_id) 
    return output_error_code -- 0 success 1 -- destination is moved 
  end      
  
  --------------------------------------------------------------------  
  function DATA:Get_DestProject()
    local  retval, projfn = EnumProjects( -1 )
    if projfn =='' then projfn = '[current / untitled]' end
    DATA.destproj = {}
    DATA.destproj.fp = projfn 
    DATA.destproj.fp_dir = GetParentFolder(projfn )
    DATA.destproj.TRACK = {}
    local folderlev = 0
    
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local GUID = GetTrackGUID( tr )
      local tr_col =  GetTrackColor( tr )
      local folderd = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' )
      
      local is_visible = GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP' ) --& GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER' )
      
      DATA.destproj.TRACK[i] = {tr_name =  ({GetTrackName( tr )})[2],
                              GUID = GUID,
                              tr_col=tr_col,
                              folderd=folderd,
                              folderlev=folderlev,
                              }
      
      folderlev = folderlev + folderd                            
    end
    
    -- define free groups
    DATA.destproj.usedtrackgroups = {}
    local t = {
    'MEDIA_EDIT_LEAD',
    'MEDIA_EDIT_FOLLOW',
    'VOLUME_LEAD',
    'VOLUME_FOLLOW',
    'VOLUME_VCA_LEAD',
    'VOLUME_VCA_FOLLOW',
    'PAN_LEAD',
    'PAN_FOLLOW',
    'WIDTH_LEAD',
    'WIDTH_FOLLOW',
    'MUTE_LEAD',
    'MUTE_FOLLOW',
    'SOLO_LEAD',
    'SOLO_FOLLOW',
    'RECARM_LEAD',
    'RECARM_FOLLOW',
    'POLARITY_LEAD',
    'POLARITY_FOLLOW',
    'AUTOMODE_LEAD',
    'AUTOMODE_FOLLOW',
    'VOLUME_REVERSE',
    'PAN_REVERSE',
    'WIDTH_REVERSE',
    'NO_LEAD_WHEN_FOLLOW',
    'VOLUME_VCA_FOLLOW_ISPREFX'}
    
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      for keyid = 1, #t do
        local groupname = t[keyid]
        local flags = reaper.GetSetTrackGroupMembership( tr, groupname, 0, 0 )
        local flags32 = reaper.GetSetTrackGroupMembershipHigh( tr, groupname, 0, 0 )
        for groupID = 1, 32 do
          local bitset = 1<<(groupID-1)
          if not DATA.destproj.usedtrackgroups[groupID] and flags ~= 0 and flags&bitset == bitset then DATA.destproj.usedtrackgroups[groupID] = true end
          if not DATA.destproj.usedtrackgroups[groupID+32] and flags32 ~= 0 and flags32&bitset == bitset then DATA.destproj.usedtrackgroups[groupID+32] = true end
        end
      end
    end
    
    DATA.destproj.usedtrackgroups_map = {}
    local skip = 0
    for groupID = 1, 64 do
      if DATA.destproj.usedtrackgroups[groupID] then skip = skip + 1 end
      if DATA.destproj.usedtrackgroups[groupID + skip] then skip = skip + 1 end
      if groupID + skip <= 64 then DATA.destproj.usedtrackgroups_map[groupID] = groupID + skip end
    end
  end
    ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end  
  -------------------------------------------------------------------- 
  function DATA:MatchTrack_Sub(tr_name, id_src, submode) 
    if not tr_name then return end
    
    if submode == 5 then -- match by ID
      if DATA.destproj.TRACK[id_src] then 
        DATA:Tracks_SetDestination(id_src, 2, id_src)
      end
      return
    end
    
    if submode == 6 then -- match by color
      local tr_col = DATA.srcproj.TRACK[id_src].PEAKCOL 
      if not tr_col then return end
      if tr_col == 16576 then return end
      for desttrid = 1,  #DATA.destproj.TRACK do 
        if DATA.destproj.TRACK[desttrid].tr_col == tr_col then 
          DATA:Tracks_SetDestination(id_src, 2, desttrid)
          return
        end
      end
      return
    end
    
    if tr_name == '' then return end
    tr_name = tostring(tr_name)
    tr_name = tr_name:lower()
    if tr_name:match('track %d+') then return end
    
    -- check for exact match
    for trid = 1,  #DATA.destproj.TRACK do 
      local tr_name_CUR =  DATA.destproj.TRACK[trid].tr_name:lower()
      if tr_name:match(literalize(tr_name_CUR)) and tr_name:match(literalize(tr_name_CUR)):len() == tr_name:len() then
        DATA:Tracks_SetDestination(id_src, 2, trid)
        return
      end
    end
    
    local t = {}
    local cnt_match0, cnt_match, last_biggestmatch = 0, 0 
    if EXT.CONF_tr_matchmode == 1 then 
      t = {tr_name:lower():gsub('%s+','')}
     else
      for word in tr_name:gmatch('[^%s]+') do t[#t+1] = literalize(word:lower():gsub('%s+','')) end  
    end
    for trid = 1,  #DATA.destproj.TRACK do 
      local tr_name_CUR =  DATA.destproj.TRACK[trid].tr_name:lower()
      if tr_name_CUR ~= '' and not tr_name_CUR:match('track %d+') then
        cnt_match0 = 0
        for i = 1, #t do if tr_name_CUR:match(t[i]) then cnt_match0 = cnt_match0 + 1 end end
        if cnt_match0 == #t then DATA:Tracks_SetDestination(id_src, 2, desttrack_id) return end
        if cnt_match0 > cnt_match then last_biggestmatch = trid end 
        cnt_match = cnt_match0
      end
    end 
    DATA:Tracks_SetDestination(id_src, 2, last_biggestmatch)--msg(last_biggestmatch)
  end
  ----------------------------------------------------------------------
  function DATA:MatchTrack(specificid, submode)
    if not DATA.srcproj.TRACK then return end
    DATA:Get_DestProject()
    
    -- specific track match
    if specificid and DATA.srcproj.TRACK[specificid] then 
      local tr_name = DATA.srcproj.TRACK[specificid].NAME 
      DATA:MatchTrack_Sub(tr_name, specificid, submode)
      return 
    end
    
    -- no specificid
    if not specificid then
      local cnt_selection = 0 
      for trid0 = 1, #DATA.srcproj.TRACK do  
        if DATA.srcproj.TRACK[trid0].UI_selected == true then cnt_selection = cnt_selection + 1 end 
      end
      
      for i = 1, #DATA.srcproj.TRACK do 
        if cnt_selection == 0 or (cnt_selection > 0 and DATA.srcproj.TRACK[i].UI_selected == true) then
          local tr_name = DATA.srcproj.TRACK[i].NAME
          
          if EXT.CONF_tr_match_preventsends == 0 or (EXT.CONF_tr_match_preventsends == 1 and DATA.srcproj.TRACK[i].prevent_from_auto_match~=true) then 
            DATA:MatchTrack_Sub(tr_name, i, submode) 
            if EXT.CONF_tr_match_automatchsendsasdest == 1 and DATA.srcproj.TRACK[i].prevent_from_auto_match==true then 
              DATA.srcproj.TRACK[i].destmode_submode = 4
              DATA.srcproj.TRACK[i].destmode = 2
              DATA:Tracks_SetDestination_RefreshUI(i) 
            end
          end
        end
      end  
    end
    
    
  end
  ---------------------------------------------------------------------  
  function DATA:VisibleCondition(trname)
    return (EXT.UI_trfilter == '' or not trname or (trname and EXT.UI_trfilter ~= '' and tostring(trname):lower():match(EXT.UI_trfilter)))
  end
  -------------------------------------------------------------------- 
  function DATA:Import_TransferTrackData_FXchain(src_tr, dest_tr)
    if not dest_tr then return end
    local dest_cnt = TrackFX_GetCount( dest_tr )
    
    if EXT.CONF_tr_FX&2==2 then -- clear existed
      for dest_fx = dest_cnt, 1, -1 do   TrackFX_Delete( dest_tr, dest_fx-1 )  end 
      dest_cnt = 0
    end
    
    if EXT.CONF_tr_FX&1==1 then
      for src_fx = 1, TrackFX_GetCount( src_tr ) do 
        TrackFX_CopyToTrack( src_tr, src_fx-1, dest_tr, dest_cnt + src_fx-1, false )  
        --if EXT.CONF_tr_FX&4==4 then DATA:Import_TransferTrackData_FXchain_Envelopes(src_tr, dest_tr,dest_cnt,src_fx) end  
      end
    end
    
  end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ----------------------------------------------------------------------
  function DATA:Import2_Tracks() 
    local cnt_selection = DATA:Actions_Selection_Get()
    
    for i = 1, #DATA.srcproj.TRACK do
      local srct = DATA.srcproj.TRACK[i]
      if not DATA:VisibleCondition(DATA.srcproj.TRACK[i].NAME) 
        or (EXT.UI_ignoretracklistselection == 0 and cnt_selection > 0 and not DATA.srcproj.TRACK[i].UI_selected) then 
        goto importnexttrack 
      end
      
      local mode = srct.destmode or 0 
      
      
      if mode == 1 then -- at the end 
        local new_tr_src = DATA:Import_CreateNewTrack(false, srct) 
        local dest_tr = DATA:Import_CreateNewTrack(true)
        DATA:Import_TransferTrackData(new_tr_src, dest_tr)
        srct.dest_track_GUID = GetTrackGUID( dest_tr )
      end
      
      if mode == 3 then -- at the end, obey structure
        local new_tr_src = DATA:Import_CreateNewTrack(false, srct) 
        local dest_tr = DATA:Import_CreateNewTrack(true)
        DATA:Import_TransferTrackData(new_tr_src, dest_tr, true)
        srct.dest_track_GUID = GetTrackGUID( dest_tr )
      end 
      
      if mode == 2 and srct.dest_track_GUID then -- replace specific track
        if not (srct.destmode_submode and (srct.destmode_submode == 3 or srct.destmode_submode == 4 )) then
          
          local new_tr_src = DATA:Import_CreateNewTrack(false, srct)
          local dest_tr 
          local srcpos_tr = VF_GetTrackByGUID(srct.dest_track_GUID)
          
          if not srct.destmode_submode then
            dest_tr = srcpos_tr
           elseif srct.destmode_submode == 1 or srct.destmode_submode ==2 then
            dest_tr = DATA:Import_CreateNewTrack(true)
          end 
          DATA:Import_TransferTrackData(new_tr_src, dest_tr) 
          --srct.dest_track_GUID = GetTrackGUID( dest_tr )
          
          if srct.destmode_submode == 1 or srct.destmode_submode ==2 then
            SetOnlyTrackSelected( dest_tr )
            makePrevFolder = 0
            if srct.destmode_submode ==2 then makePrevFolder = 1 end
            ReorderSelectedTracks(  CSurf_TrackToID( srcpos_tr, false ), makePrevFolder )
          end
          
        end
      end
      
      
      ::importnexttrack::
    end
    
    DATA:Import2_Tracks_Receives() 
    
    if EXT.CONF_buildpeaks == 1 then Action(40047) end -- Peaks: Build any missing peaks
  end
  
  -------------------------------------------------------------------- 
  function DATA:Import_CreateNewTrack(needblank, srct)
    InsertTrackAtIndex( CountTracks( 0 ), false )
    local new_tr = GetTrack(0, CountTracks( 0 )-1)
    if needblank then return new_tr end
    local new_chunk = srct.chunk_full
    local gGUID = genGuid('' ) 
    new_chunk = new_chunk:gsub('TRACK[%s]+.-\n', 'TRACK '..gGUID..'\n')
    new_chunk = new_chunk:gsub('AUXRECV .-\n', '\n')
    SetTrackStateChunk( new_tr, new_chunk, false )
    
    return new_tr,gGUID
  end
  
  -------------------------------------------------------------------- 
  function DATA:Import_TransferTrackData(src_tr, dest_tr, obeystructure) -- AND remove track
    if not (src_tr and dest_tr) then return end
    if EXT.CONF_tr_name&1==1 then   
      local retval, P_NAMEdest = reaper.GetSetMediaTrackInfo_String( dest_tr, 'P_NAME', '', false ) 
      if EXT.CONF_tr_name&2~=2 or (EXT.CONF_tr_name&2==2 and P_NAMEdest=='' ) then 
        DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'P_NAME') 
      end
    end
    
    
    if EXT.CONF_tr_VOL == 1 then          DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_VOL') end
    if EXT.CONF_tr_PAN == 1 then 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_PAN') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_WIDTH') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_DUALPANL') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_DUALPANR') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_PANMODE') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'D_PANLAW') 
    end
    if EXT.CONF_tr_PHASE== 1 then         DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'B_PHASE') end
    if EXT.CONF_tr_CUSTOMCOLOR== 1 then   DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_CUSTOMCOLOR') end
    if EXT.CONF_tr_GROUPMEMBERSHIP&1== 1 then   DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'GROUPMEMBERSHIP') end
    if EXT.CONF_tr_LAYOUTS== 1 then   DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'P_MCP_LAYOUT') 
                                                DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'P_TCP_LAYOUT') end
    if obeystructure then   DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_FOLDERDEPTH') end
    if EXT.CONF_tr_RECINPUT  == 1 then    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECINPUT') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECMODE') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECMON') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'I_RECMONITEMS') 
    end
    if EXT.CONF_tr_MAINSEND  == 1 then    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'B_MAINSEND') 
                                                    DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, 'C_MAINSEND_OFFS') 
    end
    if EXT.CONF_tr_FX> 0 then             DATA:Import_TransferTrackData_FXchain(src_tr, dest_tr) end
    if EXT.CONF_tr_it> 0 then             DATA:Import_TransferTrackData_Items(src_tr, dest_tr) end
    
    DeleteTrack( src_tr ) -- remove temporary
  end 
  
  -------------------------------------------------------------------- 
  function DATA:Import_TransferTrackData_SetTrVal(src_tr, dest_tr, key)
    if not dest_tr then return end
    if key=='GROUPMEMBERSHIP'  then 
      local t = {
      'MEDIA_EDIT_FOLLOW',
      'MEDIA_EDIT_LEAD',
      'VOLUME_LEAD',
      'VOLUME_FOLLOW',
      'VOLUME_VCA_LEAD',
      'VOLUME_VCA_FOLLOW',
      'PAN_LEAD',
      'PAN_FOLLOW',
      'WIDTH_LEAD',
      'WIDTH_FOLLOW',
      'MUTE_LEAD',
      'MUTE_FOLLOW',
      'SOLO_LEAD',
      'SOLO_FOLLOW',
      'RECARM_LEAD',
      'RECARM_FOLLOW',
      'POLARITY_LEAD',
      'POLARITY_FOLLOW',
      'AUTOMODE_LEAD',
      'AUTOMODE_FOLLOW',
      'VOLUME_REVERSE',
      'PAN_REVERSE',
      'WIDTH_REVERSE',
      'NO_LEAD_WHEN_FOLLOW',
      'VOLUME_VCA_FOLLOW_ISPREFX'}
      local reapervrs = GetAppVersion():match('[%d%.]+')
      if reapervrs then reapervrs = tonumber(reapervrs) end 
      if reapervrs and reapervrs <= 6.11 then for i = 1, #t do t[i] = t[i]:gsub('LEAD', 'MASTER'):gsub('FOLLOW', 'SLAVE') end end
      
      for i = 1, #t do 
        -- bits 1-32
        local flags = GetSetTrackGroupMembership( src_tr,  t[i], 0, 0 ) 
        local flags32 = GetSetTrackGroupMembershipHigh( src_tr,  t[i], 0, 0 )
        local ouflags = flags
        local ouflags32 = flags32
        
        if EXT.CONF_tr_GROUPMEMBERSHIP&2==2 then 
          ouflags = 0 
          ouflags32= 0
          for i = 1, 32  do 
            local bitset = 1<<(i-1)
            local outgroup = DATA.destproj.usedtrackgroups_map[i] 
            local outbit = 1<<(outgroup-1)
            if flags&bitset == bitset then ouflags = ouflags|outbit end
            
            local bitset32 = 1<<(i-1)
            local outgroup32 = DATA.destproj.usedtrackgroups_map[i+32] 
            if outgroup32 then
              local outbit32 = 1<<(outgroup32-1)
              if flags32&bitset32 == bitset32 then ouflags32 = ouflags32|outbit32 end
            end
          end
         --[[else
          ouflags = flags
          ouflags32 = flags32]]
        end
        
        GetSetTrackGroupMembership( dest_tr,  t[i], ouflags, 0xFFFFFFFF )
        GetSetTrackGroupMembershipHigh( dest_tr,  t[i], ouflags32, 0xFFFFFFFF ) 
      end
      
     elseif (key=='P_NAME'  or  key=='P_TCP_LAYOUT'  or  key=='P_MCP_LAYOUT' ) then
     
      local retval, stringNeedBig = GetSetMediaTrackInfo_String( src_tr, key, '', 0 )
      GetSetMediaTrackInfo_String( dest_tr, key, stringNeedBig, 1 )
      if DATA.srcproj.is_tracktemplatemode == true then
        GetSetMediaTrackInfo_String( dest_tr, key, DATA.srcproj.TRACK[1].NAME, 1 )
      end
      
     else 
      local val = GetMediaTrackInfo_Value( src_tr,key )
      SetMediaTrackInfo_Value( dest_tr, key, val )  
    end
  end
  
  
  -------------------------------------------------------------------- 
  function DATA:Import_TransferTrackData_FXchain_Envelopes(src_tr, dest_tr,dest_cnt,src_fx)
    for envidx = 1, reaper.CountTrackEnvelopes( src_tr ) do
      local env = reaper.GetTrackEnvelope( src_tr, envidx-1 )
      local retval, fxindex, paramindex = reaper.Envelope_GetParentTrack( env )   
      if fxindex == src_fx-1 then
        local retval, chunk = reaper.GetEnvelopeStateChunk( env, '', false )
        local dest_env = reaper.GetFXEnvelope( dest_tr, dest_cnt + src_fx-1, paramindex, true )
        if dest_env then  reaper.SetEnvelopeStateChunk( dest_env, chunk, false ) end
      end
    end
  end
  
  -------------------------------------------------------------------- 
  function DATA:Import_TransferTrackData_Items_handlesources(chunk)  
    if not (EXT.CONF_tr_it&16 == 16 or EXT.CONF_tr_it&32 == 32) then return chunk end
    -- cache chunk
    local t = {}
    for line in chunk:gmatch('[^\r\n]+') do t[#t+1]=line end
    -- search for paths 
      for i = 1, #t do
        local line = t[i]
        if line:match('FILE ') then  
          line = line:match('FILE (.*)')
          if DATA.destproj.fp_dir then line = line:gsub(literalize(DATA.destproj.fp_dir)..'[%\\%/]', '') end
          if line:match('%"(.-)%"') then line = line:match('%"(.-)%"') end
          
          if not file_exists( line ) then
            local src_projpath = DATA.srcproj.path..'/' 
            local test = src_projpath..line 
            if reaper.GetOS():lower():match('win') then test = test:gsub('/','\\') end
            
            if file_exists( test ) then  
              local output_file = test
              local proj_path = GetParentFolder(DATA.destproj.fp)
              if EXT.CONF_tr_it&32 == 32 and proj_path then
                local srcfp = test
                local destfp = proj_path..'/'..line
                output_file = destfp
                CopyFile(srcfp,destfp)
              end  
              if reaper.GetOS():lower():match('win') then output_file = output_file:gsub('/','\\') end
              t[i] = 'FILE "'..output_file..'" 1'
            end
          end
            
        end
      end
    
    chunk = table.concat(t,'\n')
    return chunk
  end
  
  ----------------------------------------------------------------------
  function DATA:Tracks_HasDestinationAim(GUID)
    if not GUID then return end
    for i = 1, #DATA.srcproj.TRACK do
      if GUID == DATA.srcproj.TRACK[i].GUID and 
        (
          (DATA.srcproj.TRACK[i].destmode and DATA.srcproj.TRACK[i].destmode&1==1) or 
          (DATA.srcproj.TRACK[i].destmode and DATA.srcproj.TRACK[i].destmode==2 and DATA.srcproj.TRACK[i].dest_track_GUID)
        ) then return true,DATA.srcproj.TRACK[i] end
    end
    
  end 
  ----------------------------------------------------------------------
  function DATA:Tracks_GetSourcebyGUID(GUID) 
    for j = 1, #DATA.srcproj.TRACK do 
      if GUID == DATA.srcproj.TRACK[j].GUID then return j end 
    end 
  end
  
  ----------------------------------------------------------------------
  function DATA:Import2_Tracks_CheckExistingSend( tr,dest_tr)
    if not (tr and dest_tr) then return end
    for sendidx = 1,reaper.GetTrackNumSends( tr, 0 ) do
      local dest = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      if dest == dest_tr then return true,sendidx-1  end
    end
  end
  
    -------------------------------------------------------------------- 
  function CopyFile(old_path, new_path) 
    local old_file = io.open(old_path, "rb")
    if not old_file then return end
    local new_file = io.open(new_path, "wb")
    if not new_file then return end
    
    local content = old_file:read('a')
    new_file:write(content)
    
    old_file:close()
    new_file:close()
  end
  
    -------------------------------------------------------------------- 
  function DATA:Import_TransferTrackData_Items(src_tr, dest_tr) 
    local curpos = GetCursorPosition() 
    if EXT.CONF_tr_it&2 == 2 then -- remove dest tr items
      for itemidx = CountTrackMediaItems( dest_tr ), 1, -1 do 
        local item = GetTrackMediaItem( dest_tr, itemidx-1 )
        DeleteTrackMediaItem(  dest_tr, item) 
      end
    end
    
    if EXT.CONF_tr_it&1 == 1 then -- import tr items / replace GUID
      for itemidx = 1,  CountTrackMediaItems( src_tr ) do
        local item = GetTrackMediaItem( src_tr, itemidx-1 )
        local retval, chunk = reaper.GetItemStateChunk( item, '', false ) 
        local gGUID = genGuid('' ) 
        chunk = chunk:gsub('GUID (%{.-%})\n', 'GUID '..gGUID..'\n')
        chunk = DATA:Import_TransferTrackData_Items_handlesources(chunk)   
        local new_it = AddMediaItemToTrack( dest_tr )
        SetItemStateChunk( new_it, chunk, false )  
        if EXT.CONF_tr_it&4 == 4 then -- shift by edit cur
          local it_pos = GetMediaItemInfo_Value( new_it, 'D_POSITION' )
          SetMediaItemInfo_Value( new_it, 'D_POSITION', it_pos+curpos )
        end  
      end
    end 
    
  end  
  ------------------------------------------------------------------------------------------------------  
  function VF_GetMediaTrackByGUID(optional_proj, GUID)
    local optional_proj0 = optional_proj or 0
    for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
    local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
  end 
  -------------------------------------------------------------------- 
  function DATA:Import2_Tracks_Receives_params(new_tr, sendidx,auxt)  
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_VOL', auxt.vol )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MUTE', auxt.mute )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_PHASE', auxt.phase )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MONO', auxt.monosum )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PAN', auxt.pan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PANLAW', tonumber(auxt.panlaw) or -1 )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SENDMODE', auxt.mode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SRCCHAN', auxt.src_chan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_DSTCHAN', auxt.dest_chan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_AUTOMODE', auxt.automode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_MIDIFLAGS', auxt.midi_chan )
  end
  ----------------------------------------------------------------------
  function DATA:Import2_Tracks_Receives()
    if EXT.CONF_sendlogic_flags2&1==0 then return end
    for tr_id = 1, #DATA.srcproj.TRACK do
      local srct = DATA.srcproj.TRACK[tr_id]
      if srct.mode == 0 then goto skiptr end
      if not srct.dest_track_GUID then goto skiptr end
      if not (srct.SENDS and #srct.SENDS > 0) then goto skiptr end
      DATA:Import2_Tracks_Receives_sub(srct)
      ::skiptr::
    end
  end 
  ----------------------------------------------------------------------
  function DATA:Import2_Tracks_Receives_sub(srct)
    function _b__REC_Import2_Tracks_Receives_sub() end
    local destproj_sendsrc_tr = VF_GetMediaTrackByGUID(0,srct.dest_track_GUID)
     
    for sendid = 1, #srct.SENDS do
      -- get source project send destination
      --local srcproj_senddest_tr_t
      local AUXRECV_DEST_GUID = srct.SENDS[sendid].AUXRECV_DEST_GUID
      for tr_id = 1, #DATA.srcproj.TRACK do
        local GUID = DATA.srcproj.TRACK[tr_id].GUID
        if GUID == AUXRECV_DEST_GUID then
          srcproj_senddest_tr_t = DATA.srcproj.TRACK[tr_id]
          --if DATA.srcproj.TRACK[tr_id].dest_track_GUID then   end --  msg(srct.NAME) msg(DATA.srcproj.TRACK[tr_id].NAME) 
          break
        end
      end
      
      -- dest receive exist in destination project
      if srcproj_senddest_tr_t then  
        if srcproj_senddest_tr_t.dest_track_GUID then  -- if matched for import OR HAS IMPORTED DURUNG importing other track
          local dest_tr = VF_GetMediaTrackByGUID(0,srcproj_senddest_tr_t.dest_track_GUID)
          local ret, sendID = DATA:Import2_Tracks_CheckExistingSend( destproj_sendsrc_tr,dest_tr) 
          if ret~= true and EXT.CONF_sendlogic_desthasrec==1 then
            local sendidx = CreateTrackSend( destproj_sendsrc_tr,dest_tr)
            DATA:Import2_Tracks_Receives_params(destproj_sendsrc_tr, sendidx, srct.SENDS[sendid]) 
          end 
          if ret== true and EXT.CONF_sendlogic_desthasrec_no==1 then
            DATA:Import2_Tracks_Receives_params(destproj_sendsrc_tr, sendidx, srct.SENDS[sendid]) 
          end 
          
         else
          
          if EXT.CONF_sendlogic_desthasnotrec==1 then
            local new_tr_rec = DATA:Import_CreateNewTrack(false,srcproj_senddest_tr_t) 
            local dest_tr = DATA:Import_CreateNewTrack(true)
            DATA:Import_TransferTrackData(new_tr_rec, dest_tr)
            srcproj_senddest_tr_t.dest_track_GUID = GetTrackGUID( dest_tr ) 
            local sendidx = CreateTrackSend( destproj_sendsrc_tr,dest_tr)
            DATA:Import2_Tracks_Receives_params(destproj_sendsrc_tr, sendidx, srct.SENDS[sendid]) 
          end
        end 
         
      end
      
      
      
    end
    
    if not tr then return end
  end
  --------------------------------------------------------------------- 
  function UI.draw_tabs_sendimportlogic_DefineT()
    function _b__REC_draw_tabs_sendimportlogic_DefineT() end
    DATA.SIL_nodes = {} 
    
    DATA.SIL_nodes['hasreceive'] = {
      x = 0,
      y = 0,
      valid = true,
      txt = 'Import sends?',
      ext_key = 'CONF_sendlogic_flags2',
      ext_key_bit = 1, 
      dest_node_t = 
        {
          {destkey='receiveexistinproject',wire='yes',valid = EXT.CONF_sendlogic_flags2&1==1}
        },
    }
    
    DATA.SIL_nodes['receiveexistinproject'] = {
      x = 1,
      y = 0,
      txt = 'Marked receives exist in destination project or imported during importing other source track?',
      ext_key = nil,
      valid = EXT.CONF_sendlogic_flags2&1==1,
      dest_node_t = 
        {
          {destkey='receiveexistinproject_hassendalready',wire='yes',valid = EXT.CONF_sendlogic_flags2&1==1},
          {destkey='CONF_sendlogic_desthasnotrec',wire='no',valid = EXT.CONF_sendlogic_flags2&1==1}
        },
    }
    
    DATA.SIL_nodes['receiveexistinproject_hassendalready'] = {
      x = 2,
      y = 0,
      txt = 'Has send setup already?',
      ext_key = nil,
      valid = EXT.CONF_sendlogic_flags2&1==1,
      dest_node_t = 
        {
          {destkey='CONF_sendlogic_desthasrec',wire='yes',valid = EXT.CONF_sendlogic_flags2&1==1},
          {destkey='CONF_sendlogic_desthasrec_no',wire='no',valid = EXT.CONF_sendlogic_flags2&1==1}
        },
    }
    
    DATA.SIL_nodes['CONF_sendlogic_desthasrec'] = {
      x = 3,
      y = 0,
      txt = '',
      ext_key = 'CONF_sendlogic_desthasrec',
      combo = {
        [0] = 'Do nothing',
        [1] = 'Port send parameters',
      },
      valid = EXT.CONF_sendlogic_flags2&1==1,
    }
    
    DATA.SIL_nodes['CONF_sendlogic_desthasrec_no'] = {
      x = 3,
      y = 1,
      txt = '',
      ext_key = 'CONF_sendlogic_desthasrec_no',
      combo = {
        [0] = 'Do nothing',
        [1] = 'Add new receive',
      },
      valid = EXT.CONF_sendlogic_flags2&1==1,
    }
    
    DATA.SIL_nodes['CONF_sendlogic_desthasnotrec'] = {
      x = 2,
      y = 1,
      txt = '',
      ext_key = 'CONF_sendlogic_desthasnotrec',
      combo = {
        [0] = 'Do nothing',
        [1] = 'Add track + create send',
      },
      valid = EXT.CONF_sendlogic_flags2&1==1,
    }
    
    
      
    for node_key in pairs(DATA.SIL_nodes) do DATA.SIL_nodes[node_key].key = node_key end 
  end
  -----------------------------------------------------------------------------------------  
  function _main() 
    EXT_defaults = CopyTable(EXT)
    EXT:load()  
    DATA.PRESET_GetExtStatePresets() 
    if EXT.UI_appatinit&1==1 then 
      DATA:ParseSourceProject(EXT.UI_lastsrcproj)  
      if EXT.UI_appatinit&2==2 then
        DATA:Tracks_SetDestination(-1, 0, nil) 
        DATA:MatchTrack()  
      end 
    end
    DATA:Get_DestProject() 
    UI.MAIN_definecontext()
  end   
       
  _main()
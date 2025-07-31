-- @description VisualMixer
-- @version 3.10
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Very basic Izotope Neutron Visual mixer port to REAPER environment
-- @changelog
--    # restrict marque selection when draggin width


vrs = 3.10

  --------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end
  app_vrs = tonumber(reaper.GetAppVersion():match('[%d%.]+'))
  check_vrs = 6.0
  if app_vrs < check_vrs then return reaper.MB('This script require REAPER '..check_vrs..'+','',0) end
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaimGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3.2'
    
    
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          
          viewport_posX =  100,
          viewport_posY =  100,
          viewport_posW =  800,
          viewport_posH =  600,
          dock =    0, 
          
          
          -- global
          CONF_NAME = 'default',
          CONF_snapshcnt = 8, -- cnt snapshot
          CONF_scalecent = 0.7, -- center scale
          CONF_tr_rect_px = 50, -- size of track, px
          CONF_invertYscale = 0, 
          CONF_follow_env = 0,
          
          -- actions
          CONF_action = 0, 
          CONF_randsymflags = 0, 
          CONF_normlufsdb = -25,--dB
          CONF_normlufswait = 5,--sec
          CONF_spreadflags = 0,
          CONF_lufswaitMAP = 5,
          CONF_allowshortcuts = 1, 
          
          -- global
          --CONF_csurf = 0,
          CONF_snapshrecalltime = 0.5,
          
          UI_groupflags = 0,
          UI_appatchange = 0,
          UI_initatmouse = 0,
          UI_enableshortcuts = 1,
          UI_sidegrid = 0,
          UI_backgrcol = '#333333',
          UI_showtracknames = 1,
          UI_showtracknames_flags = 1,
          UI_showicons = 1,
          UI_showtopctrl_flags = 1|2|4, 
            UI_extcontrol1dest = 0,--1=fisrt send volume
          UI_extendcenter = 0.3,
          UI_expandpeaks =1,
          UI_showscalenumbers =1,
          UI_ignoregrouptracks =0,
          UI_forcewidthmode = 1,
          
          CONF_quantizevolume = 1,
          CONF_quantizepan = 5,
          CONF_handlealltracks = 0,
          
          UI_windowBgRGB = 0x303030,
          
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          ES_key = 'MPL_VisualMixer',
          UI_name = 'VisualMixer', 
          upd = true, 
          
          tracks = {},
          
          selectedtracks={},
          marquee={},
          latchctrls={},
          arrangemaps={},
          
          Recall_timer = 0,
           
          actionnames = {
            [0] = 'Rand Chaos',
            [1] = 'Rand Sym',
            [2] = 'Normalize LUFS',
            [3] = 'Reset volume and pan',
            [4] = 'Spread center area',
            [5] = 'Arrange by map',
          } ,
          
          touch_state = false, -- block constant refresh on touch
          currentsnapshotID = 1,
          info_txt = '',
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
              font3sz=10,
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
              --windowBg = 0x303030,
          }
          
    UI.w_min = 640
    UI.h_min = 300  
    UI.col_maintheme = 0x00B300 
    UI.areaspace = 10
    UI.knob_handle = 0xc8edfa    
    UI.knob_resY = 150
    
    
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent(colRGBA0, alphamult)
    local colRGBA = 0
    if colRGBA0 then colRGBA = colRGBA0 << 8 end
    local mult = alphamult or 1
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, colRGBA|math.floor(mult * 0x7F) )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, colRGBA|math.floor(mult * 0xFF) )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, colRGBA|math.floor(mult * 0xBF) )
  end
    --------------------------------------------------------------------------------  
  function UI.draw_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end
    --------------------------------------------------------------------------------  
  function UI.Tools_RGBA(col, a_dec) if col then return col<<8|math.floor(a_dec*255) end   end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
    
    -- window_flags
      local window_flags = ImGui.WindowFlags_None
      --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
      window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
      window_flags = window_flags | ImGui.WindowFlags_MenuBar
      
      -- restrict moving window except header drag
      local click_x, click_y = reaper.ImGui_GetMouseClickedPos( ctx, ImGui.MouseButton_Left )
      if DATA.display_x and DATA.display_y and DATA.display_w and  DATA.display_h and  UI.calc_itemH and 
        click_x >=DATA.display_x and click_x <=DATA.display_x + DATA.display_w and 
        click_y >=DATA.display_y+UI.calc_itemH and click_y <=DATA.display_y + DATA.display_h then
        window_flags = window_flags | ImGui.WindowFlags_NoMove
      end
      
      --window_flags = window_flags | ImGui.WindowFlags_NoResize
      window_flags = window_flags | ImGui.WindowFlags_NoCollapse
      --window_flags = window_flags | ImGui.WindowFlags_NoNav
      --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
      --window_flags = window_flags | ImGui.WindowFlags_NoDocking
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
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,10)
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
      ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,         UI.Tools_RGBA(EXT.UI_windowBgRGB, 0.99))      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      --ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font1) 
      local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) --..' '..vrs..'##'..DATA.UI_name
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
        
        
      -- get drawlist
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        
        UI.calc_workarea_xabs = DATA.display_x + UI.calc_xoffset
        UI.calc_workarea_yabs = DATA.display_y + UI.calc_yoffset + UI.calc_itemH*3
        UI.calc_workarea_w = DATA.display_w - 2*UI.calc_xoffset
        UI.calc_workarea_h =  DATA.display_h -2* UI.calc_yoffset - UI.calc_itemH*3
        UI.calc_extendcenter = EXT.UI_extendcenter*UI.calc_workarea_w 
        
      -- marque selection
        UI.MOUSE_marqsel()
        
      -- draw stuff
        UI.draw()
        ImGui.Dummy(ctx,0,0) 
        ImGui.End(ctx)
      end 
      
      -- pop
        ImGui.PopStyleVar(ctx, 22) 
        ImGui.PopStyleColor(ctx, 23) 
        ImGui.PopFont( ctx ) 
      if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then reaper.Main_OnCommand( 40044, 0 ) end
      
      
      if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
      
      if EXT.CONF_allowshortcuts == 1 then 
        if  ImGui.IsKeyPressed( ctx, ImGui.Key_G,false )  then DATA:WriteData_ResetGain() end
        if  ImGui.IsKeyPressed( ctx, ImGui.Key_P,false )  then DATA:WriteData_ResetPan() end
        if  ImGui.IsKeyPressed( ctx, ImGui.Key_M,false )  then DATA:WriteData_Actions_SoloMute(0) end
        if  ImGui.IsKeyPressed( ctx, ImGui.Key_S,false )  then DATA:WriteData_Actions_SoloMute(1) end
      end
      
      return open
  end
  
  ------------------------------------------------------------------------------------------------------
  function DATA:Snapshot_Recall_persist()
    local ID = DATA.Recall_newID
    local oldID = DATA.Recall_oldID
    local Recall_state = DATA.Recall_state
    for GUID in pairs(DATA.Snapshots[ID]) do
      if GUID:match('{') then
        local tr = DATA.Snapshots[ID][GUID].tr_ptr
        if not tr then 
          tr = VF_GetTrackByGUID(GUID)
          DATA.Snapshots[ID][GUID].tr_ptr = tr
        end
        if tr then
          SetTrackSelected( tr, true )
          if DATA.Snapshots[oldID][GUID] then
            SetMediaTrackInfo_Value( tr, 'D_PAN', DATA.Snapshots[oldID][GUID].pan + (DATA.Snapshots[ID][GUID].pan - DATA.Snapshots[oldID][GUID].pan)*Recall_state)
            SetMediaTrackInfo_Value( tr, 'D_VOL', DATA.Snapshots[oldID][GUID].vol + (DATA.Snapshots[ID][GUID].vol - DATA.Snapshots[oldID][GUID].vol)*Recall_state)
            SetMediaTrackInfo_Value( tr, 'D_WIDTH', DATA.Snapshots[oldID][GUID].width + (DATA.Snapshots[ID][GUID].width - DATA.Snapshots[oldID][GUID].width)*Recall_state)
            SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5)
          end
        end
      end
    end
  end
  ----------------------------------------------------------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do 
      local tr = GetTrack(reaproj or 0,i-1)
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end 
  end
  ------------------------------------------------------------------------------------------------------
  function DATA:Snapshot_Recall(ID,oldID)
    if not (ID and DATA.Snapshots and DATA.Snapshots[ID] and DATA.Snapshots[oldID]) then return end 
    Action(40297) -- unselect all tracks
    if oldID and EXT.CONF_snapshrecalltime > 0 then 
      DATA.Recall_timer = EXT.CONF_snapshrecalltime
      DATA.Recall_newID = ID
      DATA.Recall_oldID = oldID
      for GUID in pairs(DATA.Snapshots[ID]) do     if GUID:match('{') then DATA.Snapshots[ID][GUID].tr_ptr = nil end end
      for GUID in pairs(DATA.Snapshots[oldID]) do  if GUID:match('{') then DATA.Snapshots[oldID][GUID].tr_ptr = nil end end
      return 
    end
    
    reaper.Undo_BeginBlock2( 0 )
    for GUID in pairs(DATA.Snapshots[ID]) do
      if GUID:match('{') then
        local tr = VF_GetTrackByGUID(GUID)
        if tr then
          SetTrackSelected( tr, true )
          SetMediaTrackInfo_Value( tr, 'D_PAN', DATA.Snapshots[ID][GUID].pan)
          SetMediaTrackInfo_Value( tr, 'D_VOL', DATA.Snapshots[ID][GUID].vol)
          SetMediaTrackInfo_Value( tr, 'D_WIDTH', DATA.Snapshots[ID][GUID].width)
          SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5)
        end
      end
    end
    reaper.Undo_EndBlock2( 0, 'Visual mixer shapshot recall', 0xFFFFFFFF )
  end
  ---------------------------------------------------
  function Action(s,section,midieditor,flag,proj) 
    if not flag then flag = 0 end 
    if not proj then proj = 0 end 
    if not section then 
      Main_OnCommandEx(NamedCommandLookup(s), flag, proj) 
     elseif section == 32060 and midieditor then -- midi ed
      MIDIEditor_OnCommand( midieditor, NamedCommandLookup(s) )
    end
  end
  ----------------------------------------------------------------------
  function DATA:CollectData_InitTracks(force)
    if not force and (DATA.tracks and not DATA.upd) then return end
    --DATA.tracks = {}
    
    local fcollect = CountSelectedTracks
    local fcollectsub = GetSelectedTrack
    if EXT.CONF_handlealltracks == 1 then
      fcollect = CountTracks
      fcollectsub = GetTrack
    end
    
    for i = 1, fcollect(0) do 
      local tr = fcollectsub(0,i-1)
      local I_FOLDERDEPTH = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH')
      if (I_FOLDERDEPTH == 1 and EXT.UI_ignoregrouptracks ==1) then goto skip end
      
      local GUID = GetTrackGUID( tr ) 
      
      
      --name
      local retval, trname = GetTrackName( tr, '' ) 
      --if trname:match('(.-)%s+') then trname = trname:match('(.-)%s+') end -- exclude space at the end
      
      local retval, icon_fp = reaper.GetSetMediaTrackInfo_String( tr, 'P_ICON', '', false ) if icon_fp =='' then icon_fp = nil end if icon_fp and not file_exists(icon_fp) then icon_fp = nli end
      local solo = GetMediaTrackInfo_Value( tr, 'I_SOLO')
      local mute = GetMediaTrackInfo_Value( tr, 'B_MUTE')
      local ret, center_area = GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_VISMIX_centerarea', '', false )
      center_area = tonumber(center_area) or 0.5 
      
      local ext1 = 0
      local ret,str = GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_VISMIX_ext1', 0, false )
      if ret and tonumber(str ) then ext1 = tonumber(str ) end
      
      local icon_image
      if EXT.UI_showicons == 1 and icon_fp then icon_image = ImGui.CreateImage( icon_fp ) ImGui.Attach( ctx, icon_image ) end
      
      if not DATA.tracks[GUID] then DATA.tracks[GUID] = {} end
      DATA.tracks[GUID].ptr = tr
      DATA.tracks[GUID].icon_fp=icon_fp
      DATA.tracks[GUID].icon_image=icon_image
      DATA.tracks[GUID].I_FOLDERDEPTH = I_FOLDERDEPTH
      DATA.tracks[GUID].name = trname
      DATA.tracks[GUID].col =  GetTrackColor( tr )
      DATA.tracks[GUID].solo=solo>0
      DATA.tracks[GUID].mute=mute>0
      DATA.tracks[GUID].center_area =center_area
      DATA.tracks[GUID].ext1 = ext1
      
      ::skip::
    end
    
    -- validate lost pointers
      local ptr_remove = {}
      for GUID in pairs(DATA.tracks) do
        local tr = DATA.tracks[GUID].ptr
        if not ValidatePtr(tr, 'MediaTrack*') then ptr_remove[GUID] = true end
      end 
      for GUID in pairs(ptr_remove) do DATA.tracks[GUID] = nil end
    
  end
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 end 
    return v 
  end
  ---------------------------------------------------------------------- 
  function DATA:CollectData_Always_UpdatePeaks()
    local max_peak_cnt = math.max(30,EXT.CONF_tr_rect_px)
    if not DATA.tracks then return end
    for GUID in pairs(DATA.tracks) do
      if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') then
        if not DATA.tracks[GUID].peakR then 
          DATA.tracks[GUID].peakR = {} 
          DATA.tracks[GUID].peakL = {} 
        end
        local id = #DATA.tracks[GUID].peakL +1
        table.insert(DATA.tracks[GUID].peakL, 1 , Track_GetPeakInfo( DATA.tracks[GUID].ptr,0 ))
        table.insert(DATA.tracks[GUID].peakR, 1 , Track_GetPeakInfo( DATA.tracks[GUID].ptr,1 ))
        if #DATA.tracks[GUID].peakL > max_peak_cnt then 
          table.remove(DATA.tracks[GUID].peakL, #DATA.tracks[GUID].peakL)
          table.remove(DATA.tracks[GUID].peakR, #DATA.tracks[GUID].peakL)
        end
      end
    end
  end
  -------------------------------------------------------------------------------- 
  function  DATA:CollectData_Always()
    local trig_upd_s = 0.05
    
    if DATA.Recall_timer and DATA.Recall_timer > 0 then
      DATA.Recall_timer = math.max(DATA.Recall_timer - 0.04,0)
      DATA.Recall_state = 1-(DATA.Recall_timer / EXT.CONF_snapshrecalltime)
      if DATA.Recall_state <1 then DATA:Snapshot_Recall_persist() else DATA:Snapshot_Recall(DATA.Recall_newID) end
    end
    
    DATA.upd_TS = os.clock()
    if not DATA.last_upd_TS then DATA.last_upd_TS = DATA.upd_TS end
    if DATA.upd_TS - DATA.last_upd_TS > trig_upd_s or trig then 
      DATA.last_upd_TS = DATA.upd_TS
     else
      return
    end
    
    if DATA.LUFSnormMeasureRUN == true then DATA:Action_NormalizeLUFS_persist() end 
    
    
    
    DATA:CollectData_Always_UpdatePositions() 
    DATA:CollectData_Always_UpdatePeaks()  
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Always_UpdatePositions()  
    if DATA.touch_state == true then return end
    local playpos = reaper.GetPlayPositionEx( -1 )
    for GUID in pairs( DATA.tracks) do 
      local tr =  DATA.tracks[GUID].ptr
      
      -- pan
      local pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
      local width = GetMediaTrackInfo_Value( tr, 'D_WIDTH')
      if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then 
         local L= GetMediaTrackInfo_Value( tr, 'D_DUALPANL')
         local R= GetMediaTrackInfo_Value( tr, 'D_DUALPANR')
         pan = math.max(math.min((R+L)/2, 1), -1)
      end  
      if not (GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 5 or GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 6) and EXT.UI_forcewidthmode ~=1 then width = nil end
      if EXT.CONF_follow_env == 1 then
        local panenv = GetTrackEnvelopeByChunkName( tr, '<PANENV2' )
        if panenv then
          local retval, bool_val = GetSetEnvelopeInfo_String( panenv, 'ACTIVE', '', 0 ) 
          if bool_val == '1' then  
            local pointpos = playpos
            if GetPlayStateEx( -1 )&1~=1 then 
              pointpos = GetCursorPositionEx( -1 )
            end
            local retval, value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( panenv, pointpos, 1, 1 )
            pan = -ScaleFromEnvelopeMode( GetEnvelopeScalingMode( panenv ) , value ) 
          end
        end
      end
      
      
      -- vol 
      local vol = GetMediaTrackInfo_Value( tr, 'D_VOL') 
      if EXT.CONF_follow_env == 1 then
        local volenv = GetTrackEnvelopeByChunkName( tr, '<VOLENV2' )
        if volenv then
          local retval, bool_val = GetSetEnvelopeInfo_String( volenv, 'ACTIVE', '', 0 ) 
          if bool_val == '1' then  
            local pointpos = playpos
            if GetPlayStateEx( -1 )&1~=1 then pointpos = GetCursorPositionEx( -1 ) end
            local retval, value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( volenv, pointpos, 1, 1 )
            vol = ScaleFromEnvelopeMode( GetEnvelopeScalingMode( volenv ) , value ) 
          end
        end
      end
      
      local vol_dB = WDL_VAL2DB(vol) 
      
      -- pos XYWH
      local wsz, hsz = EXT.CONF_tr_rect_px, EXT.CONF_tr_rect_px
      local xpos = math.floor(UI.Scale_GetXPosFromPan (pan,GUID)-wsz/2)
      local ypos = math.floor(UI.Scale_GetYPosFromdB  (vol_dB)-hsz/2)
      
      DATA.tracks[GUID].vol_dB = vol_dB
      DATA.tracks[GUID].vol = vol
      DATA.tracks[GUID].pan = pan
      DATA.tracks[GUID].width = width
      DATA.tracks[GUID].xpos = xpos
      DATA.tracks[GUID].ypos = ypos
      DATA.tracks[GUID].wsz = wsz
      DATA.tracks[GUID].hsz = hsz
      DATA.tracks[GUID].valid = true
    end
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData()
    DATA:CollectData_InitTracks()
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_UIloop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))

    if DATA.upd == true then  DATA:CollectData()  end 
    DATA.upd = false 
    DATA:CollectData_Always()
    
    
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
  function UI.draw()  
    UI.draw_area() 
    UI.draw_menu() 
    UI.draw_tracks() 
  end
  -----------------------------------------------------------------------------  
  function UI.format_pan(pan)
    local pan_txt  = math.floor(pan*100)
    if pan_txt < 0 then 
      pan_txt = math.abs(pan_txt)..'%L' 
     elseif pan_txt > 0 then 
      pan_txt = math.abs(pan_txt)..'%R' 
     else 
      pan_txt = 'center' 
    end
    return pan_txt
  end
  -----------------------------------------------
  function UI.draw_area_SoloMuteFX_ctrls(xabs, yabs) 
    if not DATA.activeGUID then return end 
    local GUID = DATA.activeGUID
    if not DATA.tracks[GUID] then return end
    ImGui.SetCursorScreenPos(ctx, xabs, yabs)
    
    -- solo
      local solo = DATA.tracks[GUID].solo
      if solo == true then UI.draw_setbuttonbackgtransparent(0x00A505) end  
      if ImGui.Button( ctx, 'S##'..GUID ) then 
        DATA:WriteData_Actions_SoloMute(1)
      end
      if solo == true then UI.draw_unsetbuttonstyle() end

    -- mute
      ImGui.SameLine(ctx)
      local mute = DATA.tracks[GUID].mute
      if mute == true then UI.draw_setbuttonbackgtransparent(0xA50005) end 
      if ImGui.Button( ctx, 'M##'..GUID) then 
        DATA:WriteData_Actions_SoloMute(0)
      end
      if mute == true then UI.draw_unsetbuttonstyle() end
      
    -- FX
      ImGui.SameLine(ctx)
      if ImGui.Button( ctx, 'FX##'..GUID, ctrlbutW  , ctrlbutH ) then  
        TrackFX_Show( DATA.tracks[GUID].ptr, 0, 1 ) 
      end
    
    
    -- res vol
      ImGui.SameLine(ctx)
      if ImGui.Button( ctx, 'Gain##Gain'..GUID, ctrlbutW  , ctrlbutH ) then 
        DATA:WriteData_ResetGain()
      end
      ImGui.SameLine(ctx)
      if ImGui.Button( ctx, 'Pan##Pan'..GUID, ctrlbutW  , ctrlbutH ) then 
        DATA:WriteData_ResetPan()
      end       
  end
  -----------------------------------------------
  function DATA:WriteData_Actions_SoloMute(mode)
    local activeGUID = DATA.activeGUID
    -- mute
    if mode == 0 then
      local mute = 1
      if DATA.tracks[activeGUID] and DATA.tracks[activeGUID].mute == true then mute = 0 end 
      for GUID in pairs(DATA.tracks) do
        if (activeGUID and GUID == activeGUID) or DATA.tracks[GUID].selected == true then 
          DATA:WriteData_TrParam(GUID, 'B_MUTE', mute)
        end
      end  
    end
    
    -- solo
    if mode == 1 then 
      local solo = 2
      if DATA.tracks[activeGUID] and DATA.tracks[activeGUID].solo == true then solo = 0 end
      for GUID in pairs(DATA.tracks) do
        if (activeGUID and GUID == activeGUID) or DATA.tracks[GUID].selected == true then 
          DATA:WriteData_TrParam(GUID, 'I_SOLO', solo)
        end
      end
    end
    
    DATA.upd = true
  end
  -----------------------------------------------
  function DATA:WriteData_ResetGain()
    local activeGUID = DATA.activeGUID
    for GUID in pairs(DATA.tracks) do
      if DATA.tracks[GUID].selected == true or (activeGUID and GUID == activeGUID) then 
        DATA:WriteData_TrParam(GUID, 'D_VOL', 1)   
      end
    end 
    
    DATA.upd = true 
  end
  -----------------------------------------------
  function DATA:WriteData_ResetPan() 
    local activeGUID = DATA.activeGUID
    for GUID in pairs(DATA.tracks) do
      if DATA.tracks[GUID].selected == true or (activeGUID and GUID == activeGUID) then 
        DATA:WriteData_Pan(GUID, 0, 0)  
        GetSetMediaTrackInfo_String( DATA.tracks[GUID].ptr, 'P_EXT:MPL_VISMIX_centerarea', 0.5, true )   
        DATA.tracks[GUID].center_area = 0.5
      end
    end 
    DATA.upd = true 
  end
  -----------------------------------------------
  function UI.draw_area_scale() 
    local lineh = 1
    local col_upr_left = 0xFFFFFF00
    local col_upr_right = 0xFFFFFF1F
    ImGui.PushFont(ctx, DATA.font2) 
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFFFF3F)
    local t_val = {
      12, 
      --6, 
      --4, 
      0, 
      --3, 
      --6, 
      -12, 
      --8, 
      --24, 
      --18, 
      --48 
      -80
      }  
      
    -- values
    for i =1 , #t_val do
      local ypos = UI.Scale_GetYPosFromdB(t_val[i])
      local txt = t_val[i]..'dB'
      
      reaper.ImGui_SetCursorScreenPos(ctx,UI.calc_workarea_xabs,ypos)
      ImGui.Text(ctx, txt)
      
      ImGui.DrawList_AddRectFilledMultiColor( UI.draw_list, 
        UI.calc_workarea_xabs,
        ypos, 
        UI.calc_workarea_xabs + UI.calc_workarea_w/2,
        ypos+lineh,
        col_upr_left, 
        col_upr_right, 
        col_upr_right, 
        col_upr_left )
        
      ImGui.DrawList_AddRectFilledMultiColor( UI.draw_list, 
        UI.calc_workarea_xabs+ UI.calc_workarea_w/2,
        ypos, 
        UI.calc_workarea_xabs + UI.calc_workarea_w,
        ypos+lineh,
        col_upr_right, 
        col_upr_left, 
        col_upr_left, 
        col_upr_right)  
    end
    
    ImGui.PopStyleColor(ctx)
    ImGui.PopFont(ctx)
  end
  
  -----------------------------------------------
  function UI.draw_area() 
    local info_x = DATA.display_x
    local info_y = DATA.display_y + UI.calc_yoffset + UI.calc_itemH*2
    UI.draw_area_scale() 
    UI.draw_area_SoloMuteFX_ctrls(info_x + UI.spacingX, info_y)
    
    -- info
    local winfo = 0.3*UI.calc_workarea_w 
    ImGui.SetCursorScreenPos(ctx, UI.calc_workarea_xabs + UI.calc_workarea_w /2-winfo/2, info_y )
    UI.draw_setbuttonbackgtransparent() 
    ImGui.Button( ctx, DATA.info_txt..'##infoText', winfo,0 )
    UI.draw_unsetbuttonstyle()
    
    -- center area
    if EXT.UI_extendcenter > 0 then 
      ImGui.DrawList_AddRectFilled( UI.draw_list, UI.calc_workarea_xabs+UI.calc_workarea_w/2 - UI.calc_extendcenter/2, UI.calc_workarea_yabs, UI.calc_workarea_xabs+UI.calc_workarea_w/2+ UI.calc_extendcenter/2, UI.calc_workarea_yabs + UI.calc_workarea_h-10, 0xFFFFFF0A, 10, ImGui.DrawFlags_None ) -- workarea
    end
    ImGui.DrawList_AddLine( UI.draw_list, UI.calc_workarea_xabs+UI.calc_workarea_w/2, UI.calc_workarea_yabs, UI.calc_workarea_xabs+UI.calc_workarea_w/2, UI.calc_workarea_yabs + UI.calc_workarea_h, 0xFFFFFF2F, 1 )
    
    -- marqsel
    if DATA.marqsel_x1 and DATA.marqsel_y1 and DATA.marqsel_x2 and DATA.marqsel_y2 then
      ImGui.DrawList_AddRectFilled( UI.draw_list, math.min(DATA.marqsel_x1,DATA.marqsel_x2), math.min(DATA.marqsel_y1,DATA.marqsel_y2), math.max(DATA.marqsel_x1,DATA.marqsel_x2), math.max(DATA.marqsel_y1,DATA.marqsel_y2), 0xFFFFFF4A, 2, ImGui.DrawFlags_None ) -- workarea
    end
    
  end
  -----------------------------------------------
  function UI.Scale_GetXPosFromPan(pan, GUID)  
    if not UI.calc_workarea_w then return 0 end
    local area = UI.calc_workarea_w - EXT.CONF_tr_rect_px
    if pan then 
      local outx = 0
      if EXT.UI_extendcenter  == 0 then outx = UI.calc_workarea_xabs + EXT.CONF_tr_rect_px/2 + area * (pan + 1) / 2 end
      if EXT.UI_extendcenter  > 0  then 
        if pan == 0 then 
          outx = UI.calc_workarea_xabs + UI.calc_workarea_w/2
          if GUID and DATA.tracks[GUID] and DATA.tracks[GUID].center_area then 
            areaoff = UI.calc_extendcenter * DATA.tracks[GUID].center_area
            outx = outx - UI.calc_extendcenter/2 + areaoff
          end
         elseif pan >0 then 
          outx = UI.calc_workarea_xabs + UI.calc_workarea_w/2 + UI.calc_extendcenter /2 + pan * ((UI.calc_workarea_w-UI.calc_extendcenter)/2-EXT.CONF_tr_rect_px/2)         
         elseif pan <0 then 
          outx = UI.calc_workarea_xabs + (1+pan) * ((UI.calc_workarea_w-UI.calc_extendcenter)/2-EXT.CONF_tr_rect_px/2)+EXT.CONF_tr_rect_px/2
        end 
      end
      return outx 
    end
  end 
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  -----------------------------------------------
  function UI.Scale_GetYPosFromdB(db_val) 
    if not UI.calc_workarea_yabs then return 0 end
    local y_calc= UI.calc_workarea_yabs + UI.areaspace
    if not db_val then return 0 end 
    local linearval = 1-UI.Scale_Convertion(db_val)
    if EXT.CONF_invertYscale == 1 then linearval = UI.Scale_Convertion(db_val) end 
    local area = UI.calc_workarea_h - EXT.CONF_tr_rect_px
    return linearval *  area + y_calc
  end
  --------------------------------------------------- 
  function UI.Scale_Convertion(db_val, linear_val)
    local log1 = 20
    local log2 = 40
    local scale_cent = EXT.CONF_scalecent
    local scale_lim_low = -120
    local scale_lim_high = 14
    
    if db_val then 
      local y
      if db_val >= 0 then 
        y = VF_lim(1 - (1-scale_cent) * (scale_lim_high-db_val)/scale_lim_high, 0, 1)
       elseif db_val <= scale_lim_low then 
        y = 0      
       elseif db_val >scale_lim_low and db_val < 0 then 
        y = log1^(db_val/log2) *scale_cent
      end
      if not y then y = 0 end
      return y
    end
    
    if linear_val then 
      local dB
      if not linear_val then return 0 end
      if linear_val >= scale_cent then 
        dB = scale_lim_high*(linear_val - scale_cent) / (1-scale_cent)      
       else     
        dB = log2*math.log(linear_val/scale_cent, log1)
      end
      return dB    
    end
    
  end 
  ----------------------------------------------------------------------------- 
  function UI.draw_tracks_mainbody_peaks(GUID,color0)  
    local cnt = #DATA.tracks[GUID].peakL
    local peakvalL,peakvalR,peakval
    local alpha = 0xFF
    local color = 0xFFFFFF<<8|alpha
    if color0 then color = color0<<8|alpha end
    for i = 1, cnt  do
      peakvalL = DATA.tracks[GUID].peakL[i] 
      peakvalR = DATA.tracks[GUID].peakR[i]
      peakval = 0.99*VF_lim((math.abs(peakvalL) + math.abs(peakvalR)) /2)
      local xpos = DATA.tracks[GUID].xpos+DATA.tracks[GUID].wsz - DATA.tracks[GUID].wsz*i/cnt
      ImGui.DrawList_AddLine(UI.draw_list, 
        xpos,
        DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2 - peakval * DATA.tracks[GUID].hsz/2, 
        xpos,
        DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2, 
        color, 1)
      ImGui.DrawList_AddLine(UI.draw_list, 
        xpos,
        DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2 + peakval * DATA.tracks[GUID].hsz/2, 
        xpos,
        DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2, 
        color, 1)      
    end
  end
--------------------------------------------------------------------------------  
function UI.draw_tracks_mainbody_handleselection(GUID0, x,y) 
  for GUID in pairs(DATA.tracks) do
    if GUID ~= GUID0 then
      if DATA.tracks[GUID].selected == true then 
        local outx = DATA.tracks[GUID].xpos + x
        local outy = DATA.tracks[GUID].ypos + y
        DATA:WriteData_Volume(GUID, outy) 
        DATA:WriteData_Pan(GUID,outx) 
      end
    end
  end
end
  -------------------------------------------------------------------------------  
    function UI.draw_tracks_mainbody(GUID)   
    if not DATA.tracks[GUID].valid then return end
    
    local color = DATA.tracks[GUID].col
    color = ImGui.ColorConvertNative(color) 
    color = color & 0x1000000 ~= 0 and color  -- | 0xFFhttps://forum.cockos.com/showpost.php?p=2799017&postcount=6 
    
    ImGui.SetCursorScreenPos(ctx, DATA.tracks[GUID].xpos,DATA.tracks[GUID].ypos)
    
    --ImGui.Button(ctx, '##trackrectback'..GUID,DATA.tracks[GUID].wsz,DATA.tracks[GUID].hsz ) 
    ImGui.SetCursorScreenPos(ctx, DATA.tracks[GUID].xpos,DATA.tracks[GUID].ypos)
    ImGui.DrawList_AddRectFilled( UI.draw_list, DATA.tracks[GUID].xpos,DATA.tracks[GUID].ypos,  DATA.tracks[GUID].xpos+DATA.tracks[GUID].wsz,DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz,0xFFFFFF3F, 5 )--color<<8|0x3F
    
    if color then UI.draw_setbuttonbackgtransparent(color, 0.5) end
    ImGui.Button(ctx, '##trackrect'..GUID,DATA.tracks[GUID].wsz,DATA.tracks[GUID].hsz ) 
    if color then UI.draw_unsetbuttonstyle()end 
    
    UI.MOUSE_trackbody(GUID) 
    
    UI.draw_tracks_mainbody_selection(GUID) 
    UI.draw_tracks_mainbody_LED(GUID) 
    UI.draw_tracks_mainbody_icon(GUID) 
    UI.draw_tracks_mainbody_peaks(GUID,color) 
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tracks_mainbody_selection(GUID) 
    --if DATA.activeGUID and DATA.activeGUID == GUID then
    if DATA.tracks[GUID].selected == true then
      local sideline=  4
      ImGui.DrawList_AddRect(UI.draw_list, DATA.tracks[GUID].xpos,DATA.tracks[GUID].ypos,  DATA.tracks[GUID].xpos+DATA.tracks[GUID].wsz,DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz, 0xFFFFFF9F, 5 ) 
      ImGui.DrawList_AddLine(UI.draw_list, DATA.tracks[GUID].xpos+DATA.tracks[GUID].wsz,DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2, DATA.tracks[GUID].xpos+DATA.tracks[GUID].wsz + sideline,DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2, 0xFFFFFFFF, 1)
      ImGui.DrawList_AddLine(UI.draw_list, DATA.tracks[GUID].xpos,DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2, DATA.tracks[GUID].xpos- sideline,DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz/2, 0xFFFFFFFF, 1)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_tracks_mainbody_icon(GUID) 
    local icon_image = DATA.tracks[GUID].icon_image
    if icon_image then ImGui_DrawList_AddImage( UI.draw_list , icon_image,  DATA.tracks[GUID].xpos,DATA.tracks[GUID].ypos,  DATA.tracks[GUID].xpos+DATA.tracks[GUID].wsz,DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz, 0, 0, 1, 1, 0xFFFFFFFF ) end
  end 
  --------------------------------------------------------------------------------  
  function UI.draw_tracks_mainbody_LED(GUID) 
    -- LED
    local offsX = 3
    local offsY = 3
    local sz = 8
    if DATA.tracks[GUID].solo == true then
      ImGui.DrawList_AddRectFilled( UI.draw_list, DATA.tracks[GUID].xpos+offsX,DATA.tracks[GUID].ypos+offsY,  DATA.tracks[GUID].xpos+offsX+sz,DATA.tracks[GUID].ypos+offsY+sz, 0x00FF008F, 2 )
      offsY = offsY + sz + 2
    end
    if DATA.tracks[GUID].mute == true then
      ImGui.DrawList_AddRectFilled( UI.draw_list, DATA.tracks[GUID].xpos+offsX,DATA.tracks[GUID].ypos+offsY,  DATA.tracks[GUID].xpos+offsX+sz,DATA.tracks[GUID].ypos+offsY+sz, 0xFF00008F, 2 )
    end
    --[[if DATA.tracks[GUID].selected == true then
      ImGui.DrawList_AddRectFilled( UI.draw_list, DATA.tracks[GUID].xpos+offsX,DATA.tracks[GUID].ypos+offsY,  DATA.tracks[GUID].xpos+offsX+sz,DATA.tracks[GUID].ypos+offsY+sz, 0xF0FF0F8F, 2 )
    end]]
  end
  ----------------------------------------------------------------------  
  function DATA:WriteData_Width(GUID, width)
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end 
    if GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 6 then
      SetMediaTrackInfo_Value( tr, 'D_WIDTH',width)
      DATA.tracks[GUID].width = width
      DATA:WriteData_Pan(GUID)
     elseif GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 5 then
      SetTrackUIWidth( tr, width, false, false,1|2)
      DATA.tracks[GUID].width = width
     else
      if EXT.UI_forcewidthmode ==1 then
        SetTrackUIWidth( tr, width, false, false,1|2)
        SetMediaTrackInfo_Value( tr, 'I_PANMODE',5 )
        DATA.tracks[GUID].width = width
      end
    end
    return width
  end
--------------------------------------------------------------------------------  
  function UI.draw_tracks_controls(GUID) 
    if not DATA.tracks[GUID].valid then return end
    local ctrlbutW = DATA.tracks[GUID].wsz/3
    local ctrlbutH = 15
    
    -- width control
      local widthsliderH = 0
      if DATA.tracks[GUID].width then 
        widthsliderH = 5
        UI.draw_setbuttonbackgtransparent() 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,1)  
        ImGui.SetCursorScreenPos(ctx, DATA.tracks[GUID].xpos, DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz)
        ImGui.Button(ctx,'##width'..GUID,DATA.tracks[GUID].wsz,widthsliderH)
        if ImGui.IsItemHovered( ctx ) then  
          DATA.info_txt = 'Width: '..(math.floor(100*DATA.tracks[GUID].width))..'%'
        end
        if ImGui.IsItemActivated( ctx ) then 
          DATA.touch_val = DATA.tracks[GUID].width
          DATA.touch_x, DATA.touch_y = reaper.ImGui_GetMousePos( ctx )
        end
        if ImGui.IsItemActive( ctx ) then
          DATA.marqsel_x1 = nil
          DATA.info_txt = 'Width: '..(math.floor(100*DATA.tracks[GUID].width))..'%'
          DATA.touch_state = true
          local x, y = reaper.ImGui_GetMouseDragDelta( ctx, DATA.touch_x, DATA.touch_y, reaper.ImGui_MouseButton_Left(), 0 )
          local out = DATA.touch_val +  x*0.03
          DATA:WriteData_Width(GUID, VF_lim(out,0,1)) 
        end
        if ImGui.IsItemDeactivated( ctx ) then  
          Undo_BeginBlock2( 0 )
          DATA:Snapshot_WriteTracksInfo() 
          DATA:Snapshot_Write() 
          DATA.touch_state = false
          Undo_EndBlock2( -1, 'Visual Mixer - change track width',0xFFFFFFF )
        end 
        ImGui.PopStyleVar(ctx)
        ImGui.DrawList_AddRectFilled( UI.draw_list, 
          DATA.tracks[GUID].xpos, 
          DATA.tracks[GUID].ypos+ DATA.tracks[GUID].hsz, 
          DATA.tracks[GUID].xpos + DATA.tracks[GUID].wsz, 
          DATA.tracks[GUID].ypos + DATA.tracks[GUID].hsz + widthsliderH, 
          0xFFFFFF30, 0, ImGui.DrawFlags_None )
        ImGui.DrawList_AddRectFilled( UI.draw_list, 
          DATA.tracks[GUID].xpos + DATA.tracks[GUID].wsz/2 - DATA.tracks[GUID].width * DATA.tracks[GUID].wsz/2, 
          DATA.tracks[GUID].ypos+ DATA.tracks[GUID].hsz, 
          DATA.tracks[GUID].xpos + DATA.tracks[GUID].wsz/2+DATA.tracks[GUID].width * DATA.tracks[GUID].wsz/2, 
          DATA.tracks[GUID].ypos + DATA.tracks[GUID].hsz + widthsliderH, 
          0xFFFFFF70, 0, ImGui.DrawFlags_None )
        UI.draw_unsetbuttonstyle()
      end
    
    -- name
      ImGui.PushFont(ctx, DATA.font2) 
      ImGui.SetCursorScreenPos(ctx, DATA.tracks[GUID].xpos, DATA.tracks[GUID].ypos+DATA.tracks[GUID].hsz + widthsliderH)
      local posx = ImGui.GetCursorPosX( ctx )
      ImGui.PushTextWrapPos( ctx, posx + DATA.tracks[GUID].wsz)
      ImGui.Text( ctx, DATA.tracks[GUID].name )
      ImGui.PopTextWrapPos( ctx )
      ImGui.PopFont(ctx) 
      
  end 
  ----------------------------------------------------------------------  
  function DATA:WriteData_TrParam(GUID, parmname, newvalue)
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    SetMediaTrackInfo_Value( tr, parmname, newvalue )
  end  
--------------------------------------------------------------------------------  
    function UI.draw_tracks() 
    if not (DATA and DATA.tracks) then return end   
    
    for GUID in pairs(DATA.tracks) do
      UI.draw_tracks_mainbody(GUID)  
      UI.draw_tracks_controls(GUID)
    end
    
  end
--------------------------------------------------------------------------------  
function UI.draw_flow_CHECK(t)
  local trig_action
  local byte = t.confkeybyte or 0
  if reaper.ImGui_Checkbox( ctx, t.key, EXT[t.extstr]&(1<<byte)==(1<<byte) ) then 
    EXT[t.extstr] = EXT[t.extstr]~(1<<byte) 
    trig_action = true 
    EXT:save()  
    if EXT.CONF_applylive == 1 then DATA:Process() end
  end
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    trig_action = true 
    if EXT.CONF_applylive == 1 then DATA:Process() end
  end
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_flow_SLIDER(t) 
  local trig_action
    ImGui.SetNextItemWidth( ctx, 150 )
    local retval, v
    local format = t.format
    if type(format)=='function' then format = format(EXT[t.extstr]) end
    if t.int or t.block then 
      retval, v = reaper.ImGui_SliderInt ( ctx, t.key..'##'..t.extstr, math.floor(EXT[t.extstr]), t.min, t.max, format )
      if retval then trig_action = true end
     elseif t.percent then
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr]*100, t.percent_min or 0, t.percent_max or 100, t.format or '%.1f%%' )
      if retval then trig_action = true end
     else  
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr], t.min, t.max, format )
      if retval then trig_action = true end
    end 
    
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
      trig_action = true
      if EXT.CONF_applylive == 1 then DATA:Process() end
     else
      if retval then 
        if t.percent then EXT[t.extstr] = v /100 else EXT[t.extstr] = v  end
        EXT:save() 
      end
    end 
    if ImGui.IsItemDeactivatedAfterEdit( ctx ) then 
      if EXT.CONF_applylive == 1 then DATA:Process() end
    end
    
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
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
  ImGui.SetNextItemWidth( ctx, 280 )
  if t.extw then ImGui.SetNextItemWidth( ctx, t.extw ) end
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
  ------------------------------------------------------------------------------------------------------
  function DATA:Snapshot_Reset(ID)  
    if not DATA.Snapshots[ID] then return end
    for GUID in pairs(DATA.Snapshots[ID]) do
      local tr = VF_GetTrackByGUID(GUID)
      if tr then
        SetTrackSelected( tr, true )
        SetMediaTrackInfo_Value( tr, 'D_PAN', 0)
        SetMediaTrackInfo_Value( tr, 'D_VOL', 1)
        SetMediaTrackInfo_Value( tr, 'D_WIDTH', 1)
        SetMediaTrackInfo_Value( tr, 'I_PANMODE', 0)
      end
    end
  end
  ------------------------------------------------------------------------------------------------------
  function DATA:Snapshot_Read()
    DATA.Snapshots = {}
    
    --DATA.currentsnapshotID = 1
    local retval, curshot = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT_CURRENT'  )
    if curshot and tonumber(curshot) then  DATA.currentsnapshotID = tonumber(curshot) end
    
    for ID = 1, EXT.CONF_snapshcnt do
      local retval, s_state = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID  )
      if retval and s_state ~= '' then
        DATA.Snapshots[ID] = {}
        local retval, s_col = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'col'  )
        if retval and s_col ~= '' then 
          if s_col == '-1' then s_col = nil end
          DATA.Snapshots[ID].col = s_col 
        end
        local retval, txt = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'txt'  )
        if retval then DATA.Snapshots[ID].txt = txt or '' end
        for line in s_state:gmatch('[^\r\n]+') do
          local t = {}
          for val in line:gmatch('[^%s]+') do t [#t+1] = val end
          if #t == 4 then
            local GUID = t[1]
            if GUID then 
              DATA.Snapshots[ID][GUID] = {
                                  vol = tonumber(t[2]),
                                  pan = tonumber(t[3]),
                                  width = tonumber(t[4]),
                                  }
            end
          end      
        end
        
      end
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
  ----------------------------------------------------------------------------------------- 
  function UI.draw_settings() 
    
      if ImGui.BeginMenu(ctx, '  Settings  ') then 
        ImGui.SeparatorText(ctx, 'General')
        UI.draw_flow_SLIDER({['key']='Snapshot smooth transition',                        ['extstr'] = 'CONF_snapshrecalltime',                  ['format']=function(x) return (math.floor(x*1000)/1000)..'s' end,    ['min']=0,  ['max']=2}) 
        UI.draw_flow_CHECK({['key']='Collect all tracks instead selected only',           ['extstr'] = 'CONF_handlealltracks'}) 
        
        
        ImGui.SeparatorText(ctx, 'UI appearance')
        UI.draw_flow_CHECK({['key']='Show track names',                                   ['extstr'] = 'UI_showtracknames'}) 
        if EXT.UI_showtracknames == 1 then ImGui.SameLine(ctx) UI.draw_flow_CHECK({['key']='if there aren`t icons',                               ['extstr'] = 'UI_showtracknames_flags',confkeybyte  =0})  end
        UI.draw_flow_CHECK({['key']='Show track icons',                                   ['extstr'] = 'UI_showicons'}) 
        --[[ImGui.Text(ctx, 'Top controls: ')
          ImGui.SameLine(ctx) UI.draw_flow_CHECK({['key']='Solo',                         ['extstr'] = 'UI_showtopctrl_flags', confkeybyte  =0}) 
          ImGui.SameLine(ctx) UI.draw_flow_CHECK({['key']='Mute',                         ['extstr'] = 'UI_showtopctrl_flags', confkeybyte  =1}) 
          ImGui.SameLine(ctx) UI.draw_flow_CHECK({['key']='FX',                           ['extstr'] = 'UI_showtopctrl_flags', confkeybyte  =2}) 
          ImGui.SameLine(ctx) UI.draw_flow_CHECK({['key']='external_1',                   ['extstr'] = 'UI_showtopctrl_flags', confkeybyte  =3}) 
        if EXT.UI_showtopctrl_flags&8==8 then 
          UI.draw_flow_COMBO({['key']='External_1',                                       ['extstr'] = 'UI_extcontrol1dest',               ['values'] = {[0]='none',[1]='first send level' } })  
        end]]
        UI.draw_flow_CHECK({['key']='Show scale numbers',                                 ['extstr'] = 'UI_showscalenumbers'}) 
        UI.draw_flow_CHECK({['key']='Hide group tracks',                                  ['extstr'] = 'UI_ignoregrouptracks'}) 
        UI.draw_flow_CHECK({['key']='Always show/set width',                                  ['extstr'] = 'UI_forcewidthmode'}) 
        UI.draw_flow_CHECK({['key']='Allow shortcuts',                                  ['extstr'] = 'CONF_allowshortcuts', tooltip='S=solo\nM=mute\nG=reset gain\nP=reset pan' }) 
        
        
        
        ImGui.SeparatorText(ctx, 'UI behaviour')
        UI.draw_flow_COMBO({['key']='Quantize volume',                                    ['extstr'] = 'CONF_quantizevolume',               ['values'] = {[0]='Off',[1]='0.1dB',[2]='0.01dB'  } })  
        UI.draw_flow_COMBO({['key']='Quantize pan',                                    ['extstr'] = 'CONF_quantizepan',               ['values'] = {[0]='Off',[1]='1%',[5]='5%',[10]='10%'  } })  
        UI.draw_flow_COMBO({['key']='Extend center',                                    ['extstr'] = 'UI_extendcenter',               ['values'] = {[0]='Disabled', [0.3] = '30% area',[0.5] = '50% area'} })   
        UI.draw_flow_CHECK({['key']='Invert Y',                                           ['extstr'] = 'CONF_invertYscale'}) 
        UI.draw_flow_CHECK({['key']='Follow envelopes',                                           ['extstr'] = 'CONF_follow_env'}) 
        
        local retval, col_rgb = ImGui.ColorEdit3( ctx, 'Background color', EXT.UI_windowBgRGB, ImGui.ColorEditFlags_NoAlpha )
        if retval then EXT.UI_windowBgRGB = col_rgb  EXT:save() end
        ImGui.SameLine(ctx) if ImGui.Selectable(ctx, 'Reset##rescolback') then EXT.UI_windowBgRGB = 0x303030 EXT:save() end
        
        ImGui.EndMenu( ctx )
      end
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_menu()  
    if ImGui.BeginMenuBar( ctx ) then
      UI.draw_settings() 
      UI.draw_menu_controls()   
      UI.draw_menu_actions()
      UI.draw_menu_snapshots()
      ImGui.EndMenuBar( ctx )
    end
  end
--------------------------------------------------------------------------------  
function UI.draw_plugin_handlelatchstate(t)  
  local paramval = EXT[t.param_key]
  local itemhovered , itemlatched
  -- trig
  --if  ImGui.IsItemActivated( ctx ) then 
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
    local normval = paramval
    if t.val_min and t.val_max then normval = (paramval - t.val_min) / (t.val_max - t.val_min) end
    DATA.latchstate = normval 
    if t.appfunc_atclick then t.appfunc_atclick() end
    return 
  end
   
  -- drag
  if  ImGui.IsItemActive( ctx ) then
    itemlatched = true
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local normval = DATA.latchstate - y/UI.knob_resY
    normval = math.max(0,math.min(normval,1))
    local outval = normval
    if t.val_min and t.val_max then 
      outval = normval * (t.val_max - t.val_min) + t.val_min 
    end 
    local dx, dy = ImGui.GetMouseDelta( ctx )
    if dy~=0 then EXT[t.param_key] = outval EXT:save() DATA.upd = true end 
  end 
   
end  
  -------------------------------------------------------------------------------- 
  function UI.draw_knob(t,valkey) 
    local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
    local butid = '##knob'..t.butGUID..t.param_key
    UI.draw_setbuttonbackgtransparent() 
    ImGui.Button( ctx, butid, t.w or 0, t.h or 0)
    UI.draw_unsetbuttonstyle()
    local item_w, item_h = reaper.ImGui_GetItemRectSize( ctx )
    local item_w2, item_h2 = 0,0
    UI.draw_plugin_handlelatchstate(t)  
    
    ImGui.SameLine(ctx)
    UI.draw_setbuttonbackgtransparent() 
    ImGui.Button( ctx, t.name..butid..'name')
    UI.draw_unsetbuttonstyle()
    item_w2, item_h2 = reaper.ImGui_GetItemRectSize( ctx )
    item_w2 = item_w2 + UI.spacingX
    
    local val = EXT[t.param_key]
    
    if t.val_min and t.val_max then val = (val - t.val_min) / (t.val_max - t.val_min) end
    
    if not val then return end
    local draw_list = ImGui.GetForegroundDrawList(ctx)
    local roundingIn = 0
    local col_rgba = 0xF0F0F0FF
    local controlsalpha = 0xFF
    local circlealpha = 0x2F
    if t.disabled == true then 
      controlsalpha =0x29
      circlealpha =0x09
    end
    local radius = math.floor(math.min(item_w, item_h )/2)
    local radius_draw = math.floor(0.9 * radius)
    local center_x = curposx + item_w/2--radius
    local center_y = curposy + item_h/2
    local ang_min = -220
    local ang_max = 40
    local ang_val = ang_min + math.floor((ang_max - ang_min)*val)
    local radiusshift_y = (radius_draw- radius)
    ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
    ImGui.DrawList_PathStroke(draw_list, 0xF0F0F0<<8|circlealpha,  ImGui.DrawFlags_None, 1)
    ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
    ImGui.DrawList_PathStroke(draw_list, (t.knob_col or UI.knob_handle)<<8|controlsalpha,  ImGui.DrawFlags_None, 1)
    
    local radius_draw2 = radius_draw
    local radius_draw3 = radius_draw-5
    ImGui.DrawList_PathClear(draw_list)
    ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
    ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
    ImGui.DrawList_PathStroke(draw_list, (t.knob_col or UI.knob_handle)<<8|controlsalpha,  ImGui.DrawFlags_None, 1)
    
    
    ImGui.SetCursorScreenPos(ctx, curposx, curposy)
    --ImGui.Dummy(ctx,t.w or UI.calc_itemH,  t.h or UI.calc_itemH)
    ImGui.Dummy(ctx,item_w+item_w2,item_h)
  end
  ------------------------------------------------------------------------------------------------------
  function shuffle(tbl) -- https://gist.github.com/Uradamus/10323382
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
  end
  ---------------------------------------------------
  function DATA:Snapshot_WriteTracksInfo(ID0) 
    local ID = DATA.currentsnapshotID
    if ID0 then ID = ID0 end
    
    if not DATA.Snapshots[ID] then DATA.Snapshots[ID] = {} end
    local tremove={}
    for key in pairs(DATA.Snapshots[ID]) do if key:match('{') then tremove[#tremove+1] = key end end
    for i=1,#tremove do DATA.Snapshots[ID][tremove[i]] = nil end
    
    for GUID in pairs(DATA.tracks) do
      if not DATA.Snapshots[ID][GUID] then DATA.Snapshots[ID][GUID] = {} end 
      DATA.Snapshots[ID][GUID].vol = DATA.tracks[GUID].vol
      DATA.Snapshots[ID][GUID].pan = DATA.tracks[GUID].pan
      DATA.Snapshots[ID][GUID].width = DATA.tracks[GUID].width
    end
  end
  ---------------------------------------------------
  function DATA:Snapshot_Write()  
    for ID = 1, EXT.CONF_snapshcnt do
      if DATA.Snapshots[ID] then 
        if DATA.Snapshots[ID].col then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'col', DATA.Snapshots[ID].col  )  end
        if DATA.Snapshots[ID].txt then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID..'txt', DATA.Snapshots[ID].txt  )  end
        local str = ''
        for GUID in pairs(DATA.Snapshots[ID]) do
          if GUID:match('{') then
          str = str..
                 GUID..' '..
                 DATA.Snapshots[ID][GUID].vol..' '..
                 DATA.Snapshots[ID][GUID].pan..' '..
                 (DATA.Snapshots[ID][GUID].width or 1)..'\n'
          end
        end
        if str then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID, str  )  end 
       else
        SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID, ''  )
      end
    end
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_Spread()
   --if EXT.CONF_spreadflags &1==0 then -- simply random ext data
      local cnt_centertracks = 0
      for GUID in pairs(DATA.tracks) do if DATA.tracks[GUID].pan == 0 then cnt_centertracks = cnt_centertracks + 1 end end
      if cnt_centertracks <= 1 then return end 
      local spreadstep = 1/cnt_centertracks
      local shift = 0
      if cnt_centertracks%2==0 then 
        spreadstep = 1/(1+cnt_centertracks)
        shift = spreadstep
      end 
      if cnt_centertracks%2==1 then  shift = 0.5*spreadstep end
      for GUID in pairs(DATA.tracks) do if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') and DATA.tracks[GUID].pan == 0 then 
        GetSetMediaTrackInfo_String( DATA.tracks[GUID].ptr, 'P_EXT:MPL_VISMIX_centerarea', shift, true )
        shift = shift + spreadstep
      end end
      
    DATA:CollectData_InitTracks(true)
  end
  
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_ArrangeMap_Parse(chunk_str)
    if not chunk_str then return end
    local mapid
    for line in chunk_str:gmatch('[^\r\n]+') do
      local is_mapid = line:match('%[MAP%d+%]') ~=nil
      if is_mapid then
        local mapid_int = line:match('%[MAP(%d+)%]')
        if tonumber(mapid_int) then mapid = tonumber(mapid_int) end
      end
      if mapid and not is_mapid then
        local trid, param, val =  line:match('track(%d+)_(.-)%=(.*)')
        if trid then trid = tonumber(trid) end
        if (trid and param and val) then
          if not DATA.arrangemaps[mapid] then DATA.arrangemaps[mapid] = {} end
          if not DATA.arrangemaps[mapid][trid] then DATA.arrangemaps[mapid][trid] = {} end
          if param=='vol' then val = tonumber( val:match('[%-%.%d]+')) end
          if param=='pan' then val = tonumber( val) end
          
          if param=='name' then  
            local exclude_t = {}
            local exclude
            if val:match('NOT') then 
              exclude = val:match('NOT(.*)') 
              val = val:match('(.-)NOT') 
            end 
            local t = {} for name in val:gmatch('"(.-)"') do t[#t+1] = name end
            val = t
            if exclude then 
              exclude_t = {} 
              for name in exclude:gmatch('"(.-)"') do exclude_t[#exclude_t+1] = name end 
            end 
            if exclude_t then DATA.arrangemaps[mapid][trid].name_exclude=CopyTable(exclude_t )end
          end
          
          
          DATA.arrangemaps[mapid][trid][param]=val
        end
      end
    end
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_ArrangeMap_GetDestParams(GUID) 
    if not DATA.arrangemaps.current_map and DATA.arrangemaps[DATA.arrangemaps.current_map] then return end
    local map_t = DATA.arrangemaps[DATA.arrangemaps.current_map]
    local tr_name = DATA.tracks[GUID].name:lower()
    for trid=1, #map_t do 
      
      local match_name
      if map_t[trid].name then
        
        for nameid = 1, #map_t[trid].name do
          if tr_name:match(map_t[trid].name[nameid]:lower()) then
            match_name = true
            if map_t[trid].name_exclude then 
              for name_excludeid=1,#map_t[trid].name_exclude do
                if tr_name:match(map_t[trid].name_exclude[name_excludeid]:lower()) then
                  match_name = nil
                end
              end
            end 
            if match_name == true then break end
          end
        end
        
      end
      
      if match_name == true then 
        return true, map_t[trid].vol, map_t[trid].pan/100
      end
    end
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_ArrangeMap()
    -- no maps found / add example
    local ret, chunk_str
    if not DATA.arrangemaps or #DATA.arrangemaps == 0 then  
      ret, chunk_str = DATA:Action_ArrangeMap_Init() 
    end
    if ret and chunk_str then DATA:Action_ArrangeMap_Parse(chunk_str)  end
    DATA.arrangemaps.current_map = 1  
  end
  
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_ArrangeMap_Init()
    local fp = DATA.arrangemapsfp 
    local chunk_str
    if not file_exists(fp) then 
      chunk_str = DATA:Action_ArrangeMap_InitDefault() 
      local f = io.open(fp, 'w')
      if not f then return end
      f:write(chunk_str)
      f:close()
      --msg(chunk_str)
      --msg('write==================')
     else 
      local f = io.open(fp, 'r')
      if not f then return end
      chunk_str = f:read('a')
      f:close()
      --msg(chunk_str)
      --msg('read==================')
    end
    return true, chunk_str
  end
  ------------------------------------------------------------------------------------------------------ 
    function DATA:Action_ArrangeMap_InitDefault() 
      return 
  [[
  [MAP1]
  name="default"
  track1_name="kick","bass drum","bassdrum","bd" NOT "sub"
  track1_vol=-32dB
  track1_pan=0
  
  track2_name="subkick"
  track2_vol=-29dB
  track2_pan=0
  
  track3_name="snare1","snare","snarehigh"
  track3_vol=-36dB
  track3_pan=0
  
  track3_name="snare2","snarelow"
  track3_vol=-40dB
  track3_pan=0
  
  track4_name="tom1","hightom","high tom"
  track4_vol=-40dB
  track4_pan=-25
  
  track5_name="tom2","midtom","mid tom"
  track5_vol=-40dB
  track5_pan=15
  
  track6_name="tom3","lowtom","low tom"
  track6_vol=-40dB
  track6_pan=50
  
  track7_name="hat","close hat","cl hat"
  track7_vol=-37dB
  track7_pan=-40
  
  track8_name="oh","overheads"
  track8_vol=-40dB
  track8_pan=0
  ]]
    end
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_Reset()
    for GUID in pairs(DATA.tracks) do if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') then 
      SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_VOL', 1)
      SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_PAN', 0)
    end end
    DATA:CollectData_InitTracks(true)
    DATA:Snapshot_WriteTracksInfo() 
    DATA:Snapshot_Write()
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_Random()
    -- count tracks
      local cnttracks = 0 for GUID in pairs(DATA.tracks) do if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') then cnttracks = cnttracks + 1 end end
      if cnttracks <= 1 then return end
      
    -- build shuffled table
      
      local step = 2/(cnttracks-1)
      local t_rand = {}
      for i = 1, cnttracks do t_rand[i] = -1+step*(i-1)  end 
      for i = 1, cnttracks do 
        if EXT.CONF_randsymflags &1==1 then if t_rand[i] ~= 0 then t_rand[i] = math.abs(t_rand[i])^0.5 * t_rand[i]/math.abs(t_rand[i])  end end
        if EXT.CONF_randsymflags &2==2 then if t_rand[i] ~= 0 then t_rand[i] = math.abs(t_rand[i])*0.5 * t_rand[i]/math.abs(t_rand[i])  end end
      end
      shuffle(t_rand)
      
    -- randomize
      local id = 0
      for GUID in pairs(DATA.tracks) do if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') then 
        
        if EXT.CONF_action==0 then 
          local db_val = -20*math.random()
          SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_VOL', WDL_DB2VAL(db_val) )
          SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_PAN', math.random()*2-1 )
        end
        
        local db_val
        if EXT.CONF_action==1 then 
          id = id + 1
          local dBrange = 10
          if EXT.CONF_randsymflags&4==4 and EXT.CONF_randsymflags&32~=32 then
            db_val = -dBrange*math.abs(t_rand[id])
           elseif EXT.CONF_randsymflags&(4|32)==(4|32) then
            db_val = -dBrange-dBrange*-math.abs(t_rand[id])
           else
            db_val = -dBrange*math.random()
          end
          
          local panout = t_rand[id]
          local pan_rand = 0.1 if EXT.CONF_randsymflags&8==8 then panout = VF_lim(panout + math.random()*pan_rand-pan_rand/2,-1,1) end
          local db_rand = 1 if EXT.CONF_randsymflags&16==16 then db_val = db_val + math.random()*db_rand-db_rand/2 end
          local volout =  WDL_DB2VAL(db_val)
          SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_PAN', panout)
          SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_VOL', volout )
        end
        
      end end
      
    -- refresh
    local ID = DATA.currentsnapshotID or 1 
    DATA:CollectData_InitTracks(true)
    DATA:Snapshot_Write()
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_NormalizeLUFS_persist()
    if DATA.lufsmeasureSTOP == true then
      -- revert volumes back
      for GUID in pairs(DATA.tracks) do 
        if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') then 
          SetMediaTrackInfo_Value( DATA.tracks[GUID].ptr, 'I_VUMODE',  0 )
          SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_VOL', DATA.tracks[GUID].vol)
        end
      end
      DATA:CollectData_InitTracks(true)
      DATA:GUI_inittracks(DATA) 
      DATA.lufsmeasure = nil
      DATA.LUFSnormMeasureRUN = nil
      DATA.LUFSnormMeasureRUN_appmap = nil
      DATA.lufsmeasureSTOP = nil
      DATA.lufs_info_txt = nil
      return 
    end
    
    
      if not DATA.lufsmeasure then  
        -- init
        DATA.lufs_info_txt = '[Measuring]'
        DATA.lufsmeasure ={TS = os.clock()}
        for GUID in pairs(DATA.tracks) do 
          if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') then 
            SetMediaTrackInfo_Value( DATA.tracks[GUID].ptr, 'I_VUMODE',  16 )
            SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_VOL', 1)
          end
        end
      end
      
      
    if DATA.lufsmeasure then
      cur = os.clock()
      
      -- in progress
      local waittime_sec = EXT.CONF_normlufswait
      if DATA.LUFSnormMeasureRUN_appmap == true then waittime_sec = EXT.CONF_lufswaitMAP end 
      if  cur - DATA.lufsmeasure.TS < waittime_sec then 
        local time_elapsed = math.abs(math.floor(cur - DATA.lufsmeasure.TS - waittime_sec))
        local outtxt = '[Measuring '..time_elapsed..' sec]'
        if outtxt ~= DATA.lufs_info_txt then DATA.lufs_info_txt = outtxt end 
      end
      
      if cur - DATA.lufsmeasure.TS > waittime_sec then 
        reaper.Undo_BeginBlock2( 0 )
        DATA:Action_NormalizeLUFS_final()
        reaper.Undo_EndBlock2( 0, 'Visual mixer lufs measure', 0xFFFFFFFF )
      end
      
    end
    
  end
  ------------------------------------------------------------------------------------------------------ 
  function DATA:Action_NormalizeLUFS_final()    
    -- final refresh 
    DATA.lufs_info_txt = nil
    for GUID in pairs(DATA.tracks) do 
      if DATA.tracks[GUID].ptr and ValidatePtr2(0,DATA.tracks[GUID].ptr, 'MediaTrack*') then 
        local lufs = Track_GetPeakInfo( DATA.tracks[GUID].ptr, 1024 )
        local lufsdB = WDL_VAL2DB(lufs)  
        
        local lufs_dest = EXT.CONF_normlufsdb
        local ret = true
        local pan_dest
        local lufs_destmap, pan_destmap
        if DATA.LUFSnormMeasureRUN_appmap == true then
          ret, lufs_destmap, pan_destmap = DATA:Action_ArrangeMap_GetDestParams(GUID) 
          if ret == true then 
            lufs_dest = lufs_destmap 
            pan_dest = pan_destmap 
          end
        end
        
        if ret == true then 
          local lufs = Track_GetPeakInfo( DATA.tracks[GUID].ptr, 1024 )
          local lufsdB = WDL_VAL2DB(lufs)
          local vol = GetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_VOL')
          local vol_DB = WDL_VAL2DB(vol)
          local diff_DB = lufs_dest-lufsdB
          local out_db = vol_DB + diff_DB
          local lufsout =WDL_DB2VAL(out_db)
          SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_VOL', math.min(lufsout,3.9))
          SetMediaTrackInfo_Value( DATA.tracks[GUID].ptr, 'I_VUMODE',  0 ) 
          if pan_dest then SetMediaTrackInfo_Value(DATA.tracks[GUID].ptr, 'D_PAN', pan_dest) end
        end
      end
    end
    local ID = DATA.currentsnapshotID or 1 
    DATA:CollectData_InitTracks(true)
    DATA:Snapshot_Write()
    DATA.lufsmeasure = nil
    DATA.LUFSnormMeasureRUN = nil
    DATA.LUFSnormMeasureRUN_appmap = nil
    DATA.lufsmeasureSTOP = nil
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_menu_actions()
    local indent = 20
    -- actions
    --ImGui.SetNextItemWidth( ctx, 150 )
    local name = DATA.actionnames[EXT.CONF_action]
    if DATA.lufs_info_txt and (EXT.CONF_action == 2 or EXT.CONF_action == 5)  then name  = DATA.lufs_info_txt end
    if ImGui.Selectable(ctx, name,false, ImGui.SelectableFlags_None, 135) then
     
        if EXT.CONF_action==0 or EXT.CONF_action==1 then 
          DATA:Action_Random()
         elseif EXT.CONF_action==2 then
          if DATA.lufsmeasure then DATA.lufsmeasureSTOP = true end
          DATA.LUFSnormMeasureRUN = true
         elseif EXT.CONF_action==3 then
          DATA:Action_Reset()
         elseif EXT.CONF_action==4 then
          DATA:Action_Spread()     
         elseif EXT.CONF_action==5 then
          if DATA.lufsmeasure then DATA.lufsmeasureSTOP = true end
          DATA:Action_ArrangeMap()     
          DATA.LUFSnormMeasureRUN = true
          DATA.LUFSnormMeasureRUN_appmap = true
        end
        
    end
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth( ctx, 10 )
    if ImGui.BeginCombo( ctx, '##action', DATA.actionnames[EXT.CONF_action], ImGui.ComboFlags_None|ImGui.ComboFlags_NoPreview|ImGui.ComboFlags_HeightLargest ) then 
      
      if ImGui.Checkbox(ctx, DATA.actionnames[0],EXT.CONF_action==0) then EXT.CONF_action = 0 EXT:save() end 
      UI.HelpMarker('Randomize gain / pan chaotically')
      if ImGui.Checkbox(ctx, DATA.actionnames[1],EXT.CONF_action==1) then EXT.CONF_action = 1 EXT:save() end
        if EXT.CONF_action == 1 then  -- symmetric params
          ImGui.Indent(ctx, indent)
          if ImGui.Button(ctx, 'Reset all flags') then EXT.CONF_randsymflags = 0 EXT:save() end
          if ImGui.Checkbox(ctx, 'Pan - exclude center area',EXT.CONF_randsymflags&1==1) then EXT.CONF_randsymflags = EXT.CONF_randsymflags~1 EXT:save() end
          if ImGui.Checkbox(ctx, 'Pan - make more narrow',EXT.CONF_randsymflags&2==2) then EXT.CONF_randsymflags = EXT.CONF_randsymflags~2 EXT:save() end
          if ImGui.Checkbox(ctx, 'Slight pan deviations',EXT.CONF_randsymflags&8==8) then EXT.CONF_randsymflags = EXT.CONF_randsymflags~8 EXT:save() end
          if ImGui.Checkbox(ctx, 'Slight volume deviations',EXT.CONF_randsymflags&16==16) then EXT.CONF_randsymflags = EXT.CONF_randsymflags~16 EXT:save() end
          if ImGui.Checkbox(ctx, 'Volume follow pan',EXT.CONF_randsymflags&4==4) then EXT.CONF_randsymflags = EXT.CONF_randsymflags~4 EXT:save() end
          if EXT.CONF_randsymflags&4==4 then
            if ImGui.Checkbox(ctx, 'Inverted following',EXT.CONF_randsymflags&32==32) then EXT.CONF_randsymflags = EXT.CONF_randsymflags~32 EXT:save() end
          end
          ImGui.Unindent(ctx, indent)
      end
      UI.HelpMarker('Randomize gain / pan symmetrically')
      if ImGui.Checkbox(ctx, DATA.actionnames[2],EXT.CONF_action==2) then EXT.CONF_action = 2 EXT:save() end
        if EXT.CONF_action == 2 then  -- LUFS
          ImGui.Indent(ctx, indent)
          ImGui.SetNextItemWidth( ctx, 100 ) local retval, v = ImGui.SliderDouble( ctx, '##lufsLevel', EXT.CONF_normlufsdb, -23, -12, '%.0fdB' ) if retval then EXT.CONF_normlufsdb = v EXT:save() end
          ImGui.SetNextItemWidth( ctx, 100 ) local retval, v = ImGui.SliderDouble( ctx, '##lufswait', EXT.CONF_normlufswait, 1,10, 'Wait %.0fs' ) if retval then EXT.CONF_normlufswait = v EXT:save() end
          ImGui.Unindent(ctx, indent)
        end
      UI.HelpMarker('Calculate LUFS and normalize active tracks')  
      if ImGui.Checkbox(ctx, DATA.actionnames[3],EXT.CONF_action==3) then EXT.CONF_action = 3 EXT:save() end
      UI.HelpMarker('Reset gain and pan')
      if ImGui.Checkbox(ctx, DATA.actionnames[4],EXT.CONF_action==4) then EXT.CONF_action = 4 EXT:save() end
        --[[if EXT.CONF_action == 4 then  -- spread tracks at center
          ImGui.Indent(ctx, indent)
          if ImGui.Checkbox(ctx, 'Rearrange below 0dB',EXT.CONF_spreadflags&1==1) then EXT.CONF_spreadflags = EXT.CONF_spreadflags~1 EXT:save() end
          ImGui.Unindent(ctx, indent)
        end]]
      UI.HelpMarker('Spread center panned tracks visually tracks inside center area, the pan would be still center')
      if ImGui.Checkbox(ctx, DATA.actionnames[5],EXT.CONF_action==5) then EXT.CONF_action = 5 EXT:save() end
        if EXT.CONF_action == 5 then  -- LUFS map
          ImGui.Indent(ctx, indent)
          ImGui.SetNextItemWidth( ctx, 100 ) local retval, v = ImGui.SliderDouble( ctx, '##lufsmapwait', EXT.CONF_lufswaitMAP, 1,10, 'Wait %.0fs' ) if retval then EXT.CONF_lufswaitMAP = v EXT:save() end
          if ImGui.Button(ctx, 'Open map configuration file') then 
            local OS = reaper.GetOS()
            local fp= DATA.arrangemapsfp
            if OS == "OSX32" or OS == "OSX64" then os.execute('open "" "' .. fp .. '"') else os.execute('start "" "' .. fp .. '"') end
          end
          ImGui.Unindent(ctx, indent)
        end      
      UI.HelpMarker('Arrange track by LUFS predefined in arrangemap file')
      ImGui.EndCombo( ctx )
    end
    
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_menu_controls()
    UI.draw_knob( {
        butGUID = '##size',
        param_key = 'CONF_tr_rect_px',
        name = 'Size  ',
        val_max = 150,
        val_min = 40,
      } )
    UI.draw_knob( {
        butGUID = '##scale',
        param_key = 'CONF_scalecent',
        name = 'Scale  ',
        val_max =  0.95,
        val_min = 0.2,
      } )
    
  end  
  -------------------------------------------------------------------------------- 
  function UI.HelpMarker(desc)
    --ImGui.TextDisabled(ctx, '(?)')
    if ImGui.IsItemHovered(ctx,ImGui.HoveredFlags_DelayShort) then 
      if ImGui.BeginTooltip(ctx) then
        ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
        ImGui.Text(ctx, desc)
        ImGui.PopTextWrapPos(ctx)
        ImGui.EndTooltip(ctx)
      end
    end
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_menu_snapshots()
    local curshapshotID = (DATA.currentsnapshotID or 1)
    
    ImGui.SetNextItemWidth( ctx, 95 )
    if ImGui.BeginCombo( ctx, '##Snapshots', 'Snapshots', ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLargest) then 
      ImGui.Selectable(ctx, '[LeftClick = recall, RightClick = store]',false,reaper.ImGui_SelectableFlags_Disabled())
      if ImGui.Selectable(ctx, 'Clean all snapshots') then
        DATA.Snapshots = {}
        DATA:Snapshot_Write()  
      end
      if ImGui.Selectable(ctx, 'Clean current snapshot') then
        local ID = curshapshotID
        DATA.Snapshots[ID] = nil
        DATA:Snapshot_Write() 
      end
      if ImGui.Selectable(ctx, 'Reset current snapshot tracks') then
        local ID = curshapshotID
        DATA:Snapshot_Reset(ID)  
      end
      
      -- shap specific ID setup
      ImGui.SeparatorText(ctx, 'Snapshot #'..curshapshotID)
      
      -- col
      local col_RRGGBB = 0
      if DATA.Snapshots and DATA.Snapshots[curshapshotID] and DATA.Snapshots[curshapshotID].col then 
        local str = DATA.Snapshots[curshapshotID].col:gsub('#','')
        local col = tonumber(str,16)
        local b, g, r = ColorFromNative( col ) 
        col_RRGGBB = (r<<16)|(g<<8)|b
      end 
      
      local flags = ImGui.ColorEditFlags_None | ImGui.ColorEditFlags_NoOptions | ImGui.ColorEditFlags_NoSidePreview|ImGui.ColorEditFlags_NoLabel|ImGui.ColorEditFlags_NoInputs
      ImGui.SetNextItemWidth( ctx, 150 )
      local retval, col_rgba = ImGui.ColorPicker4( ctx, '##Set snapsh color', (col_RRGGBB<<8)|0xFF, flags  )
      if retval then
        local outhex = '#'..string.format("%06X", (col_rgba&0xFFFFFF00)>>8)  
        if not DATA.Snapshots[curshapshotID] then DATA.Snapshots[curshapshotID] = {} end 
        DATA.Snapshots[curshapshotID].col = outhex
        DATA:Snapshot_WriteTracksInfo(curshapshotID)
        DATA:Snapshot_Write()
      end
      
      if ImGui.Selectable(ctx, 'Reset snapshot color') then 
        DATA.Snapshots[curshapshotID].col = -1
        DATA:Snapshot_WriteTracksInfo(curshapshotID)
        DATA:Snapshot_Write()
      end
      
      local buf = ''
      if DATA.Snapshots[curshapshotID] and DATA.Snapshots[curshapshotID].txt then buf =  DATA.Snapshots[curshapshotID].txt end 
      local retval, buf = reaper.ImGui_InputText( ctx, 'Set toltip', buf, ImGui.InputTextFlags_AutoSelectAll )
      if retval then 
        DATA.Snapshots[curshapshotID].txt = buf
        DATA:Snapshot_WriteTracksInfo(curshapshotID)
        DATA:Snapshot_Write()
      end
      
      ImGui.EndCombo( ctx )
    end
    
    
    -- snapshot list
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,UI.spacingY) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,1, UI.spacingY)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,1)  
    
    local snapshotscnt =EXT.CONF_snapshcnt 
    for i = 1, snapshotscnt do
      local color
      if DATA.Snapshots and DATA.Snapshots[i] and DATA.Snapshots[i].col and DATA.Snapshots[i].col ~= -1 then
        color = DATA.Snapshots[i].col:gsub('%#','') 
        color =  tonumber(color,16) 
        if color then 
          --color = ImGui.ColorConvertNative(color)
          color = (color << 8) | 0x9F -- https://forum.cockos.com/showpost.php?p=2799017&postcount= 
        end
      end
      
      if i == DATA.currentsnapshotID then
        if color then color = color|0xFF else color = 0x808080FF end
      end
      
      if color then ImGui.PushStyleColor(ctx, ImGui.Col_Button, color) end 
      
      
      local write ,recall
      ImGui.Button(ctx, i..'##sshot'..i,16) 
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
        if not DATA.Snapshots[i] then write = true else recall = true end 
      end 
      
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
        write = true
      end
      
      if write == true then -- write
        DATA:Snapshot_WriteTracksInfo(i)
        DATA:Snapshot_Write()
        DATA.currentsnapshotID = i
        SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT_CURRENT', DATA.currentsnapshotID  )
        DATA.upd = true 
      end
      
      if recall == true then
        local oldID = DATA.currentsnapshotID
        DATA.currentsnapshotID = i
        SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT_CURRENT', DATA.currentsnapshotID  )
        DATA:Snapshot_Read()
        DATA:Snapshot_Recall(i,oldID)
        DATA.upd = true 
      end
      
      
      if color then ImGui.PopStyleColor(ctx,1) end
      if DATA.Snapshots[i] and DATA.Snapshots[i].txt and DATA.Snapshots[i].txt ~= '' then UI.HelpMarker(DATA.Snapshots[i].txt) end
    end
    
    ImGui.PopStyleVar(ctx,3)
  end  
  ----------------------------------------------------------------------  
  function DATA:WriteData_Volume(GUID, Yval, val0) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    
    if Yval then DATA.tracks[GUID].ypos = Yval end
    
    local hsz = DATA.tracks[GUID].hsz
    
    local val
    if not val0 then
      local y_calc= UI.calc_workarea_yabs + UI.areaspace
      local area = UI.calc_workarea_h -hsz
      val =  1-  ( Yval -  y_calc+hsz/2)/ area
      if EXT.CONF_invertYscale == 1 then val =  ( Yval -  y_calc+hsz/2)/ area end
     else
      val = val0
    end 
    
    local db_val = UI.Scale_Convertion(nil,val)
    if EXT.CONF_quantizevolume >0 then 
      local q = 10^EXT.CONF_quantizevolume
      db_val=math.floor(db_val*q)/q
    end
    local volout = VF_lim(WDL_DB2VAL(db_val),0,3.99)
    SetTrackUIVolume( tr, volout, false, false,1|2)
    
    --[[if not DATA.Snapshots[DATA.currentsnapshotID] then DATA.Snapshots[DATA.currentsnapshotID] = {} end
    if not DATA.Snapshots[DATA.currentsnapshotID][GUID] then DATA.Snapshots[DATA.currentsnapshotID][GUID] = {} end
    DATA.Snapshots[DATA.currentsnapshotID][GUID].vol = volout]]
    --if Yval then 
    
    DATA.tracks[GUID].vol = volout 
    DATA.tracks[GUID].vol_dB = WDL_VAL2DB(volout )
      
    --end
    return db_val
  end
  ---------------------------------------------------------------------  
  function DATA:WriteData_Pan(GUID, Xval, panout) 
    local tr = VF_GetTrackByGUID(GUID)
    if not tr then return end
    if not Xval then panout = DATA.tracks[GUID].pan end
    
    
    
    
    if Xval then DATA.tracks[GUID].xpos = Xval end
    
    local pan,area,wsz
    if not panout then 
      wsz = DATA.tracks[GUID].wsz
      area = UI.calc_workarea_w - wsz
      
      if EXT.UI_extendcenter  == 0  then pan = (-0.5+(Xval - UI.calc_workarea_xabs) / area )*2  end
      if EXT.UI_extendcenter  > 0  then 
        local xcent = Xval + EXT.CONF_tr_rect_px/2
        if xcent >= UI.calc_workarea_xabs+UI.calc_workarea_w/2 - UI.calc_extendcenter/2 and xcent <= UI.calc_workarea_xabs+UI.calc_workarea_w/2 + UI.calc_extendcenter/2 then  
          pan = 0 
          Xnorm = (xcent-(UI.calc_workarea_xabs+UI.calc_workarea_w/2 - UI.calc_extendcenter/2)) / UI.calc_extendcenter
          GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_VISMIX_centerarea', Xnorm, true )
          DATA.tracks[GUID].center_area = Xnorm
        end
        if xcent <= UI.calc_workarea_xabs+UI.calc_workarea_w/2 - UI.calc_extendcenter/2 then 
          pan = (Xval-UI.calc_workarea_xabs)/( (UI.calc_workarea_w-UI.calc_extendcenter)/2-EXT.CONF_tr_rect_px/2)-1 
        end
        if xcent >= UI.calc_workarea_xabs+UI.calc_workarea_w/2 + UI.calc_extendcenter/2 then
          local comw = -1+(UI.calc_workarea_w-UI.calc_extendcenter)/2 - EXT.CONF_tr_rect_px/2
          local Xnorm = xcent - (UI.calc_workarea_xabs+UI.calc_workarea_w/2 + UI.calc_extendcenter/2)
          pan = Xnorm/comw
        end
      end
      
      
     else
      pan = panout
    end
    
    
    if EXT.CONF_quantizepan >0 then 
        m = 100/EXT.CONF_quantizepan
        pan = pan*m
        pan=math.floor(pan)
        pan = pan/m
    end 
    SetTrackUIPan( tr, pan, false, false,1|2)
    if GetMediaTrackInfo_Value( tr, 'I_PANMODE' ) == 6 and DATA.tracks[GUID] and DATA.tracks[GUID].width then 
      local width = (1-math.abs(pan)) * DATA.tracks[GUID].width
      local panL = VF_lim(pan-width,-1,1)
      local panR = VF_lim(pan+width,-1,1)
      SetTrackUIPan( tr, panL, false, false,1|2)
      SetTrackUIWidth( tr, panR, false, false,1|2)
      SetMediaTrackInfo_Value( tr, 'D_DUALPANL', panL)
      SetMediaTrackInfo_Value( tr, 'D_DUALPANR', panR) 
    end
    
    DATA.tracks[GUID].pan = VF_lim(pan ,-1,1)
    
    return pan
  end
  --------------------------------------------------------------------- 
  function UI.iscross(L1x,L1y,R1x,R1y,L2x,L2y,R2x,R2y)
    return 
      (
        (L1x > L2x and L1x < R2x)
        or (R1x > L2x and R1x < R2x)
        or (L1x < L2x and R1x > R2x)
      )
      and 
      (
        (L1y > L2y and L1y < R2y)
        or (R1y > L2y and R1y < R2y)
        or (L1y < L2y and R1y > R2y)
      )      
  end
  --------------------------------------------------------------------------------  
    function UI.MOUSE_trackbody(GUID)  
      -- UI.calc_CTRL = ImGui.IsKeyPressed( ctx, ImGui.Key_LeftCtrl ) or ImGui.IsKeyPressed( ctx, ImGui.Key_RightCtrl )
      -- local kbALT = ImGui.IsKeyPressed( ctx,ImGui.Mod_Alt)
      
      
      if ImGui.IsItemActivated( ctx ) then 
        -- reset selection
        if DATA.tracks[GUID].selected ~= true then 
          for GUID in pairs(DATA.tracks) do DATA.tracks[GUID].selected = false end 
          DATA.tracks[GUID].selected = true
        end
        DATA.marqsel_x1 = nil
        DATA.activeGUID = GUID
      end
      
      if ImGui.IsItemActive( ctx ) then 
        
        DATA.touch_state = true
        local x, y = ImGui.GetMouseDelta( ctx )
        
        local outx = DATA.tracks[GUID].xpos + x
        local outy = DATA.tracks[GUID].ypos + y
        DATA:WriteData_Volume(GUID, outy) 
        DATA:WriteData_Pan(GUID,outx)  
        UI.draw_tracks_mainbody_handleselection(GUID, x,y) 
      end 
      if ImGui.IsItemDeactivated( ctx ) then  
        Undo_BeginBlock2( 0 )
        DATA:Snapshot_WriteTracksInfo() 
        DATA:Snapshot_Write() 
        DATA.touch_state = false
        Undo_EndBlock2( -1, 'Visual Mixer - change track vol/pan',0xFFFFFFF )
      end
      
      if ImGui.IsItemHovered( ctx ) then  
        DATA.info_txt = (math.floor(10*DATA.tracks[GUID].vol_dB)/10)..'dB '..UI.format_pan(DATA.tracks[GUID].pan)
      end
    end
  ------------------------------------------------------------------------------------------------------
  function UI.MOUSE_marqsel() 
    local mousex, mousey = ImGui.GetMousePos( ctx ) 
    
    
    -- click to set init
    if ImGui.IsMouseClicked( ctx, ImGui.MouseButton_Left ) then
      DATA.marqsel_x1, DATA.marqsel_y1 = mousex, mousey
    end
    
    -- tracking current position
    if DATA.marqsel_x1 and ImGui.IsMouseDown( ctx, ImGui.MouseButton_Left ) then
      DATA.marqsel_x2, DATA.marqsel_y2 = mousex, mousey
    end
    
    -- set selection at release
    if DATA.marqsel_x1 and  ImGui.IsMouseReleased( ctx, ImGui.MouseButton_Left ) and not ImGui.IsAnyItemHovered( ctx ) then --and mousey > UI.calc_workarea_yabs then
      local mindist = math.huge
      local setactiveGUID
      DATA.activeGUID = nil
      for GUID in pairs(DATA.tracks) do
        DATA.tracks[GUID].selected = UI.iscross(
          DATA.tracks[GUID].xpos,
          DATA.tracks[GUID].ypos,
          DATA.tracks[GUID].xpos + DATA.tracks[GUID].wsz,
          DATA.tracks[GUID].ypos + DATA.tracks[GUID].hsz,
          DATA.marqsel_x1, DATA.marqsel_y1, DATA.marqsel_x2, DATA.marqsel_y2)
        
        if DATA.tracks[GUID].selected == true then
          local dist = math.abs(mousex - DATA.tracks[GUID].xpos) +  math.abs(mousey - DATA.tracks[GUID].ypos)
          if dist < mindist then setactiveGUID = GUID end
          mindist = math.min(mindist, dist)
        end
      end
      
      if setactiveGUID then DATA.activeGUID = setactiveGUID end
      
      DATA.marqsel_x1, DATA.marqsel_y1, DATA.marqsel_x2, DATA.marqsel_y2 = nil,nil,nil,nil 
    end
    
  end
  ----------------------------------------------------------------------------------------- 
  function main() 
    EXT_defaults = CopyTable(EXT)
    
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val,contextstr = reaper.get_action_context()
    DATA.arrangemapsfp = filename:gsub('Mixer%.lua','Mixer_arrangemaps.ini')
    DATA:Snapshot_Read()
    
    UI.MAIN_definecontext() 
  end  
  -----------------------------------------------------------------------------------------
  main()
  
  function _main() end
  
  
  
  
  
  
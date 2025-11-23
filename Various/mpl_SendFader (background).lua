-- @description SendFader
-- @version 3.19
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # Support ReaImGui 0.10 (this fix non-Unicode fonts display)
--    # change slider background coloring a bit



  --------------------------------------------------------------------------------  init globals
    for key in pairs(reaper) do _G[key]=reaper[key] end
    app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
    if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
    local ImGui
    
    if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.10'
    
    
    
  -------------------------------------------------------------------------------- init external defaults 
  EXT = {
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 640,
          viewport_posH = 480, 
          
          CONF_definebyname = 'aux,send',
          CONF_definebygroup = 'aux,send',
          CONF_marksendint = 1,
          CONF_marksendwordsmatch = 1,
          CONF_marksendparentwordsmatch = 1,
          CONF_alwaysshowreceives = 1,-- 0 off 1 in list 2 right side 
          
          CONF_showpeaks = 1,
          --CONF_autoadjustwidth = 0,
          CONF_allowreceivefader_mode = 1,  -- &2 = allow show send list in receive mode
          CONF_allowsametrackmultsends = 0,
          CONF_showparentsend = 0,
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          ES_key = 'MPL_SendFader',
          UI_name = 'SendFader', 
          upd = true, 
          
          tweakingstate = false, 
          
          tracks  = {},
          peaks = {},
          sendtracks = {},
          receives = {},
          
          scale_map = { 
            '-40',
            '-18',
            '-6',
            '0',
            '+12',
            } ,
          VCA_faderval = 1,
          
          }
          
  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {    popups = {},
            -- font
              font='Arial',
              font2sz=13,
              font3sz=11,
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
              col_green = 0x00B300,
              
              sliderBG = 0x101010,
              active_colbutheader = 0x50F050,
              
          }
      UI.fader_scale_limratio = 0.8 
      UI.fader_scale_coeff = 30      
      UI.indent_menu = 15      
      UI.menubutw = 70
      UI.faderW = 70
      UI.GrabMinSize = 20
      UI.peaks_cnt = 4
      UI.compactmodeH = 350 
      UI.minsizeW = UI.faderW+UI.spacingX*4
      UI.minsizeW2 = UI.faderW*2+UI.spacingX*8
      
      
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x, reduce)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else 
      if reduce then 
        return string.format('%.2f', v)
       else 
        return v 
      end
    end
  end
  ----------------------------------------------------------------------------------------- 
  function main() UI.MAIN_definecontext() end  
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
      if ImGui.BeginPopupModal(ctx, key, nil, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Borders) then
      
        -- MB replika
        if mode == 0 then
          ImGui.Text(ctx, captions_csv)
          ImGui.Separator(ctx) 
        
          if ImGui.Button(ctx, 'OK', 0, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end
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
  function UI.draw_setbuttonbackgtransparent() 
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0 )
  end
  function UI.draw_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end
  -------------------------------------------------------------------------------- 
  function UI.Tools_RGBA(col, a_dec) return col<<8|math.floor(a_dec*255) end  
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)   
    
    local w_min,h_min = UI.minsizeW, 250
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
      window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings()
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
      window_flags = window_flags | ImGui.WindowFlags_HorizontalScrollbar
      --open = false -- disable the close button
    
    
      -- rounding
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,5)   
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding,3)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,10)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding,5)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,0)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding,9)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabRounding,4)   
      -- Borders
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize,0)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize,0) 
      -- spacing
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY)  
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,1,UI.spacingY) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,UI.spacingX, UI.spacingY) 
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,UI.spacingX, UI.spacingY)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,2,0)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing,20)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,20)
      -- size
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,UI.GrabMinSize)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,w_min,h_min)
      -- align
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign,0.5,0.5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,0.5,0.5)
      -- alpha
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha,0.99)
        
        
        
        
      -- colors
        ImGui.PushStyleColor(ctx, ImGui.Col_Border,       UI.Tools_RGBA(UI.main_col, 0.3))
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,       UI.Tools_RGBA(UI.main_col, 0.2))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, UI.Tools_RGBA(UI.main_col, 0.6) )
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,UI.Tools_RGBA(UI.but_hovered, 0.4))
        ImGui.PushStyleColor(ctx, ImGui.Col_DragDropTarget,UI.Tools_RGBA(0xFF1F5F, 0.6))
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,      UI.Tools_RGBA(0x1F1F1F, 0.7))
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,UI.Tools_RGBA(UI.main_col, .6))
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,UI.Tools_RGBA(UI.main_col, 0.7))
        ImGui.PushStyleColor(ctx, ImGui.Col_Header,       UI.Tools_RGBA(UI.main_col, 0.5) )
        ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, UI.Tools_RGBA(UI.main_col, 1) )
        ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,UI.Tools_RGBA(UI.main_col, 0.98)) 
        ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,      UI.Tools_RGBA(0x303030, 0.9) )
        ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip,   UI.Tools_RGBA(UI.main_col, 1) )
        ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered,UI.Tools_RGBA(UI.main_col, 1) )
        
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,   UI.Tools_RGBA(0x3D85E0 , 0.6)  )
        ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive,UI.Tools_RGBA(0x3D85E0 , 1) ) 
        local rec_cnt = 0
        if DATA.selected_track_is_receive == true then  
          ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, UI.Tools_RGBA(0x00B300 , 0.6))
          ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive,UI.Tools_RGBA(0x00B300 , 1))
          rec_cnt = 2
        end
        
        
        ImGui.PushStyleColor(ctx, ImGui.Col_Tab,          UI.Tools_RGBA(UI.main_col, 0.37) )
        ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered,   UI.Tools_RGBA(UI.main_col, 0.8) )
        ImGui.PushStyleColor(ctx, ImGui.Col_Text,         UI.Tools_RGBA(UI.textcol, UI.textcol_a_enabled) )
        ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg,      UI.Tools_RGBA(UI.main_col, 0.7) )
        ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive,UI.Tools_RGBA(UI.main_col, 0.95) )
        ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,     UI.Tools_RGBA(UI.windowBg, 1))
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      --ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      
      
      
      --[[if EXT.CONF_autoadjustwidth == 1 and  DATA.srctr and DATA.srctr.sends then
        local fullw = UI.faderW + UI.spacingX*3
        local innerspacing = UI.spacingX * (#DATA.srctr.sends)
        local add = 0 
        if EXT.CONF_alwaysshowreceives == 2 then add = fullw+UI.spacingX*2 end
        ImGui.SetNextWindowSize(ctx, math.max(fullw*2+UI.spacingX*3, fullw * #DATA.srctr.sends + innerspacing + add), h, ImGui.Cond_Always)
       else
        ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
      end]]
      
    -- init UI 
      ImGui.PushFont(ctx, DATA.font, UI.font2sz) 
      local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags)  -- DATA.UI_name..' v'..vrs..'##'..DATA.UI_name
      if rv then
        
        UI.draw_list = ImGui.GetWindowDrawList( ctx )
        local Viewport = ImGui.GetWindowViewport(ctx)
        DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
        DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
        DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
        DATA.display_w_regavail, DATA.display_h_regavail = ImGui.GetContentRegionAvail(ctx)
        
      -- calc stuff for childs
        UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
        local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
        local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'Test') 
        UI.calc_itemH = calcitemh + frameh * 2
        -- measure controls font
        ImGui.PushFont(ctx, DATA.font, UI.font3sz) 
        local calcitemw2, calcitemh2 = ImGui.CalcTextSize(ctx, 'Test')
        UI.calc_itemH2 = calcitemh2 + frameh * 2
        ImGui.PopFont(ctx)
        
        
        UI.calc_trnamew = DATA.display_w - UI.menubutw*2
        UI.calc_comboW = math.floor(UI.faderW - UI.spacingY*2)/2 
        
        UI.calc_controlsarea = UI.calc_itemH + UI.calc_itemH*8+UI.spacingY*6
        if DATA.display_h < UI.compactmodeH then  UI.calc_controlsarea =  UI.calc_itemH*1+UI.spacingY*3 end  
        UI.calc_faderH = DATA.display_h_regavail - UI.calc_controlsarea 
        
        
      -- draw stuff
        UI.draw()
        ImGui.Dummy(ctx,0,0) 
        ImGui.End(ctx)
      end 
      ImGui.PopFont( ctx ) 
      ImGui.PopStyleVar(ctx,22)
      ImGui.PopStyleColor(ctx,22+rec_cnt)
      
      -- cnt popups 
      local ppupcnt = 0 
      for key in pairs(UI.popups) do  ppupcnt = ppupcnt + 1 end 
      if ImGui.IsKeyPressed(  ctx, ImGui.Key_Escape,false )   then  if ppupcnt == 0 then return else ImGui.CloseCurrentPopup( ctx ) UI.popups = {} end end 
      
      
      return open
  end
  -----------------------------------------------------
  function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  -------------------------------------------------------------------------------- 
  function DATA:CollectData()
    DATA.SR = VF_GetProjectSampleRate()
    
    DATA:CollectData_ReadProject_ReadTracks()  
    DATA:CollectData_ReadProject_ReadTracks_Sends()
    DATA:CollectData_ReadProject_ReadReceives()  
    if DATA.selected_track_is_receive == true then 
      DATA:CollectData_ReadProject_ReadTracks_ReceiveSingle()
    end
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadTracks_ReceiveSingle_FindSendIdx(srcPtr,destPtr)
    for sendidx = 1, GetTrackNumSends( srcPtr, 0 ) do 
      if GetTrackSendInfo_Value( srcPtr, 0, sendidx-1, 'P_DESTTRACK' ) == destPtr then return sendidx -1 end
    end
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadTracks_ReceiveSingle()
    local tr = DATA.srctr.ptr
    DATA.srctr.receives = {}
    
    
    
    for sendidx = 1, GetTrackNumSends( tr, -1 ) do 
      local id = #DATA.srctr.receives+1
      
      local destPtr = tr
      local srcPtr = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'P_SRCTRACK' )
      local sendidx_from_src = DATA:CollectData_ReadProject_ReadTracks_ReceiveSingle_FindSendIdx(srcPtr,destPtr)
      if not sendidx_from_src then goto nextsend end
      
      local B_MUTE = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'B_MUTE' )
      local vol = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'D_VOL' )
      local B_MONO = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'B_MONO' )
      local D_PAN = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'D_PAN' )
      local B_PHASE = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'B_PHASE' )
      local I_SENDMODE = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'I_SENDMODE' )
      local I_AUTOMODE = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'I_AUTOMODE' )
      local I_SRCCHANsrc = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'I_SRCCHAN' )
      
      local I_SRCCHAN =     I_SRCCHANsrc&0xFFF
      local I_SRCCHAN_cnt = I_SRCCHANsrc>>10
      if I_SRCCHAN_cnt == 0 then
        I_SRCCHAN_cnt = 2
       elseif I_SRCCHAN_cnt > 1 then
        I_SRCCHAN_cnt = I_SRCCHAN_cnt * 2
      end
      
      
      local I_DSTCHAN = GetTrackSendInfo_Value( srcPtr, 0, sendidx_from_src, 'I_DSTCHAN' )
      
      local retval, destGUID = GetSetMediaTrackInfo_String( destPtr, 'GUID', '', false )
      local retval, srcGUID = GetSetMediaTrackInfo_String( srcPtr, 'GUID', '', false )
      local destI_NCHAN  = GetMediaTrackInfo_Value( destPtr, 'I_NCHAN' ) 
      local ret, destName  = reaper.GetTrackName( srcPtr ) 
      local destCol  = GetTrackColor( destPtr ) 
      
      
      local automode = GetTrackAutomationMode( srcPtr )
      local automode_global = GetGlobalAutomationOverride()
      local automode_follow
      if (automode_global ~= -1 and automode_global > 0 ) or automode > 0  then 
        automode_follow = true 
        if automode_global ~= -1 and automode_global > 0 then automode = automode_global end 
      end
      
      
      local retval, VCALOCK =GetSetMediaTrackInfo_String( srcPtr, 'P_EXT:VCALOCK', '', false ) VCALOCK = tonumber(VCALOCK) or 0
      
      DATA.srctr.receives[id] = {
            sendidx=sendidx_from_src,
            
            vol=vol, 
            B_MUTE =B_MUTE,
            B_MONO =B_MONO,
            D_PAN =D_PAN,
            B_PHASE =B_PHASE,
            I_SENDMODE =I_SENDMODE,
            I_AUTOMODE =I_AUTOMODE,
            I_DSTCHAN=I_DSTCHAN,
            I_SRCCHANsrc=I_SRCCHANsrc,
            I_SRCCHAN_cnt=I_SRCCHAN_cnt,
            I_SRCCHAN=I_SRCCHAN,
            
            destI_NCHAN=destI_NCHAN ,
            destGUID=destGUID,
            destPtr=destPtr,
            destName=destName,
            destCol=destCol,
            peaks = {},
            
            VCALOCK=VCALOCK,
            
            automode_follow=automode_follow,
            automode_env = DATA:CollectData_GetEnv(tr,destPtr),
            automode=automode,
            
            str_id = srcGUID,
            srcPtr = srcPtr,
            }
      DATA:CollectData_ReadProject_ReadTracks_Sends_readEQ(destPtr,DATA.srctr.receives[id]) 
      
      ::nextsend::
    end
    
  end 
  -------------------------------------------------------------------- 
  function DATA:Convert_Val2Fader(rea_val)
    if not rea_val then return end 
    local rea_val = VF_lim(rea_val, 0, 4)
    local val 
    local gfx_c, coeff = UI.fader_scale_limratio,UI.fader_scale_coeff 
    local real_dB = 20*math.log(rea_val, 10)
    local lin2 = 10^(real_dB/coeff)  
    if lin2 <=1 then val = lin2*gfx_c else val = gfx_c + (real_dB/12)*(1-gfx_c) end
    if val > 1 then val = 1 end
    return VF_lim(val, 0.0001, 1)
  end
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadTracks_Sends()
    local tr = DATA.srctr.ptr
    if not (tr and ValidatePtr(tr, 'Mediatrack*')) then return end
    DATA.srctr.sends = {}
    
    
    
    for sendidx = 1, GetTrackNumSends( tr, 0 ) do 
      local destPtr = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      local B_MUTE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MUTE' )
      local vol = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_VOL' )
      local B_MONO = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MONO' )
      local D_PAN = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_PAN' )
      local B_PHASE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_PHASE' )
      local I_SENDMODE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SENDMODE' )
      local I_AUTOMODE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_AUTOMODE' )
      local I_SRCCHANsrc = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SRCCHAN' )
      local I_SRCCHAN =     I_SRCCHANsrc&0xFFF
      local I_SRCCHAN_cnt = I_SRCCHANsrc>>10
      if I_SRCCHAN_cnt == 0 then
        I_SRCCHAN_cnt = 2
       elseif I_SRCCHAN_cnt > 1 then
        I_SRCCHAN_cnt = I_SRCCHAN_cnt * 2
      end
      local I_DSTCHAN = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_DSTCHAN' )
      local retval, destGUID = GetSetMediaTrackInfo_String( destPtr, 'GUID', '', false )
      local destI_NCHAN  = GetMediaTrackInfo_Value( destPtr, 'I_NCHAN' ) 
      local ret, destName  = reaper.GetTrackName( destPtr ) 
      local destCol  = GetTrackColor( destPtr ) 
      local id = #DATA.srctr.sends+1
      
      
      local retval, VCALOCK = reaper.GetSetMediaTrackInfo_String( destPtr, 'P_EXT:VCALOCK', '', false ) VCALOCK = tonumber(VCALOCK) or 0
      
      
      local automode = GetTrackAutomationMode( tr )
      local automode_global = GetGlobalAutomationOverride()
      local automode_follow
      if (automode_global ~= -1 and automode_global > 0 ) or automode > 0  then 
        automode_follow = true 
        if automode_global ~= -1 and automode_global > 0 then automode = automode_global end 
      end
      
      DATA.srctr.sends[id] = {
            
            srcPtr = DATA.srctr.ptr,
            sendidx=sendidx-1,
            
            vol=vol, 
            B_MUTE =B_MUTE,
            B_MONO =B_MONO,
            D_PAN =D_PAN,
            B_PHASE =B_PHASE,
            I_SENDMODE =I_SENDMODE,
            I_AUTOMODE =I_AUTOMODE,
            I_DSTCHAN=I_DSTCHAN,
            I_SRCCHAN=I_SRCCHAN,
            I_SRCCHANsrc = I_SRCCHANsrc, 
            I_SRCCHAN_cnt = I_SRCCHAN_cnt,
            destI_NCHAN=destI_NCHAN ,
            destGUID=destGUID,
            destPtr=destPtr,
            destName=destName,
            destCol=destCol,
            peaks = {},
            
            VCALOCK = VCALOCK,
            
            automode_follow=automode_follow,
            automode_env = DATA:CollectData_GetEnv(tr,destPtr),
            automode=automode,
            
            str_id = destGUID..id
            
            }
      DATA:CollectData_ReadProject_ReadTracks_Sends_readEQ(destPtr,DATA.srctr.sends[id]) 
    end
    
  end 
  --------------------------------------------------------------------------------  
  function DATA:CollectData_GetEnv(track,desttr0)
    for envidx = 1, CountTrackEnvelopes( track ) do
      local envelope = GetTrackEnvelope( track, envidx-1 )
      local desttr = GetEnvelopeInfo_Value( envelope, 'P_DESTTRACK' )
      if desttr == desttr0 then
        return envelope 
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadTracks_Sends_readEQ(dest_tr,t)
    t.sendEQ = {} 
        
    local fx_cnt = TrackFX_GetCount( dest_tr )
    for fx_i = 1, fx_cnt do
      local _, fx_name = TrackFX_GetFXName( dest_tr, fx_i-1, '' )
      if (fx_name == 'PreEQ' or fx_name == 'PostEQ') then 
        local HP, LP
        for paramidx = 1, TrackFX_GetNumParams(dest_tr, fx_i-1 ) do
          local _, bandtype, _, paramtype, normval = TrackFX_GetEQParam( dest_tr, fx_i-1, paramidx-1 )
          if not HP and bandtype == 0 and paramtype == 0 then HP = normval end
          if not LP and  bandtype == 5 and paramtype == 0 then LP = normval end
        end
        
        if HP and LP then 
          local val_POS = HP + (LP - HP)/2
          local val_WID = math.max(0,LP - HP)
          local key = 'pre'
          if fx_name == 'PostEQ' then key = 'post' end
          local GUID = TrackFX_GetFXGUID( dest_tr, fx_i-1)
          t.sendEQ[key] = {HP =  HP,
                        LP =  LP,
                        val_POS = val_POS,
                        val_WID = val_WID,
                        fxGUID=GUID}
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadTracks()
  
    DATA.srctr = {}
    
    local tr = GetSelectedTrack(0,0)
    if not tr then return end  
    
    local  retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
    local ret, name =  GetTrackName(tr)
    local solo  = GetMediaTrackInfo_Value( tr, 'I_SOLO' ) 
    local I_NCHAN  = GetMediaTrackInfo_Value( tr, 'I_NCHAN' ) 
    local B_MAINSEND  = GetMediaTrackInfo_Value( tr, 'B_MAINSEND' ) 
    local UIsolotxt = 'Solo'
    if GetMediaTrackInfo_Value( tr, 'B_SOLO_DEFEAT') ==1 then UIsolotxt = UIsolotxt..' [Defeat]' end 
    
    DATA.srctr = {
      ptr = tr,
      GUID=GUID, 
      name =name, 
      solo = solo,
      UIsolotxt = UIsolotxt,
      I_NCHAN = I_NCHAN,
      B_MAINSEND = B_MAINSEND,
      peaks = {},
      }    
    
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Always()
    if EXT.CONF_showpeaks == 1 then DATA:CollectData_Always_getpeaks() end
    
    DATA.timepos = GetCursorPosition()
    if GetPlayState()&1==1 then DATA.timepos =  GetPlayPosition() end
    if DATA.srctr and DATA.srctr.ptr and DATA.srctr.sends then
      
      for sendid = 1, #DATA.srctr.sends do 
        if DATA.srctr.sends[sendid].automode_follow and DATA.tweakingstate ~= true and ValidatePtr( DATA.srctr.sends[sendid].automode_env, 'TrackEnvelope*') then 
          local envelope = DATA.srctr.sends[sendid].automode_env
          local scaling_mode = GetEnvelopeScalingMode( envelope )
          local retval, value, dVdS, ddVdS, dddVdS = Envelope_Evaluate( envelope, DATA.timepos, DATA.SR, 1 ) 
          local D_VOL = ScaleFromEnvelopeMode( scaling_mode, value )
          DATA.srctr.sends[sendid].vol = D_VOL
        end
      end
      
    end
  end
  ------------------------------------------------------------------------------------------------------  
  function VF_GetMediaTrackByGUID(optional_proj, GUID)
    local optional_proj0 = optional_proj or -1
    for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
    local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
  end 
  ----------------------------------------------------------------------
  function DATA:CollectData_Always_getpeaks_sub(t, tr) 
    local max_cnt = UI.peaks_cnt
    if not (t and tr) then return end
    if reaper.ValidatePtr(tr, 'MediaTrack*') then 
      local peakL = Track_GetPeakInfo( tr, 0 )
      local peakR = Track_GetPeakInfo( tr, 1 )
      table.insert(t, 1, {DATA:Convert_Val2Fader(peakL),DATA:Convert_Val2Fader(peakR)})
      local sz = #t
      if  sz >= max_cnt then table.remove(t, max_cnt) end
      t.peaksRMS_L = 0
      t.peaksRMS_R = 0
      for i = 1, sz do if t[i] then t.peaksRMS_L = t[i][1] + t.peaksRMS_L end end
      for i = 1, sz do if t[i] then t.peaksRMS_R = t[i][2] + t.peaksRMS_R end end
      t.peaksRMS_L = t.peaksRMS_L/sz
      t.peaksRMS_R = t.peaksRMS_R/sz
    end
  end
  ----------------------------------------------------------------------
  function DATA:CollectData_Always_getpeaks()
    if DATA.srctr and DATA.srctr.ptr then 
      DATA:CollectData_Always_getpeaks_sub(DATA.srctr.peaks, DATA.srctr.ptr)
    
      for sendID = 1, #DATA.srctr.sends do 
        DATA:CollectData_Always_getpeaks_sub(DATA.srctr.sends[sendID].peaks, DATA.srctr.sends[sendID].destPtr)
      end
    end 
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_UIloop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    
    DATA:CollectData_Always()
    if DATA.upd == true then  DATA:CollectData()  end 
    DATA.upd = false
    
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
    DATA.font = ImGui.CreateFont(UI.font) ImGui.Attach(ctx, DATA.font)
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
  
  ----------------------------------------------------------------------
  function DATA:MarkSelectedTracksAsSend(set) 
    for i = 1, CountSelectedTracks(-1) do
      local tr = GetSelectedTrack(-1,i-1) 
      if tr then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', set, true )end
    end
    DATA.upd = true
  end
  -------------------------------------------------------------------- 
  function DATA:GetSendIdx(destGUID0,allowcreate)
    local destPtr
    -- get send id
    local tr = DATA.srctr.ptr
    local sendidx_out
    for sendidx = 1, GetTrackNumSends( tr, 0 ) do 
      destPtr = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      if ValidatePtr(destPtr, 'MediaTrack*') then
        local retval, destGUID = reaper.GetSetMediaTrackInfo_String( destPtr, 'GUID', '', false )
        if destGUID == destGUID0 then sendidx_out = sendidx-1 break end
      end
    end
    if not sendidx_out and allowcreate==true  then
      destPtr = VF_GetMediaTrackByGUID(0,destGUID0)
      if ValidatePtr(destPtr, 'MediaTrack*') then 
        sendidx_out = CreateTrackSend( tr, destPtr ) 
        SetTrackSendInfo_Value( tr, 0, sendidx_out, 'D_VOL', 0 )
      end
    end
    return sendidx_out,destPtr
  end
  -------------------------------------------------------------------- 
  function DATA:Convert_Fader2Val(fader_val)
    local fader_val = VF_lim(fader_val,0,1)
    local gfx_c, coeff = UI.fader_scale_limratio,UI.fader_scale_coeff 
    local val
    if fader_val <=gfx_c then
      local lin2 = fader_val/gfx_c
      local real_dB = coeff*math.log(lin2, 10)
      val = 10^(real_dB/20)
     else
      local real_dB = 12 * (fader_val  / (1 - gfx_c) - gfx_c/ (1 - gfx_c))
      val = 10^(real_dB/20)
    end
    if val > 4 then val = 4 end
    if val < 0 then val = 0 end
    return val
  end
  
  -------------------------------------------------------------------- 
  function DATA:SetData_InitReaEQ(dest_tr) 
    local haspre 
    local haspost 
    local fx_cnt = TrackFX_GetCount( dest_tr )
    for fx_i = 1, fx_cnt do
      local _, fx_name = TrackFX_GetFXName( dest_tr, fx_i-1, '' )
      if fx_name == 'PreEQ' then haspre = true end
      if fx_name == 'PostEQ' then haspost = true end
    end
    
    if not haspre then
      local new_fx_id = TrackFX_AddByName( dest_tr, 'ReaEQ', false, -1000 )
      DATA:SetData_SetReaEQLPHP(dest_tr, new_fx_id, 0, 1)
      TrackFX_SetNamedConfigParm( dest_tr, new_fx_id, 'renamed_name', 'PreEQ' )
      TrackFX_SetOpen( dest_tr, new_fx_id, false ) 
    end
    
    if not haspost then
      local new_fx_id = TrackFX_AddByName( dest_tr, 'ReaEQ', false, -1 )
      DATA:SetData_SetReaEQLPHP(dest_tr, new_fx_id, 0, 1)
      TrackFX_SetNamedConfigParm( dest_tr, new_fx_id, 'renamed_name', 'PostEQ' )
      TrackFX_SetOpen( dest_tr, new_fx_id, false ) 
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_menu_add() 
    if not(DATA.srctr and DATA.srctr.ptr) then return end
    
    if ImGui.BeginMenu( ctx, '+ ['..DATA.srctr.name..']', true ) then
      for i = 1, #DATA.receives do
        if ImGui.MenuItem( ctx, DATA.receives[i].trname, '', false, true ) then 
          CreateTrackSend( DATA.srctr.ptr, DATA.receives[i].ptr )
          DATA.upd = true 
        end
      end
      if #DATA.receives == 0 then 
        ImGui.MenuItem( ctx, '[not found, see options]', '', false, true )
      end
      --reaper.ImGui_Separator(ctx)
      --if ImGui.MenuItem( ctx, 'VCA', 'V', false, true ) then ImGui.OpenPopup(ctx, 'vcapopup', ImGui.PopupFlags_None) end
      
      ImGui.EndMenu( ctx)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_menu_options() 
    if DATA.display_w <= UI.minsizeW2 then return end 
    if ImGui.BeginMenu( ctx, 'Options', true ) then
      ImGui.SeparatorText(ctx, 'Add send definition')
      if ImGui.MenuItem( ctx, 'Show sends that marked as sends in SendFader', '', EXT.CONF_marksendint==1, true ) then EXT.CONF_marksendint=EXT.CONF_marksendint~1 EXT:save() DATA.upd = true end
      if EXT.CONF_marksendint==1 then 
        ImGui.Indent(ctx, UI.indent_menu)
        if ImGui.Button( ctx, '[Action] Mark selected tracks as receives',-1) then DATA:MarkSelectedTracksAsSend(1) DATA.upd = true end
        if ImGui.Button( ctx, '[Action] Unmark selected tracks as receives',-1) then DATA:MarkSelectedTracksAsSend(0) DATA.upd = true end
        ImGui.Unindent(ctx, UI.indent_menu)
      end
      if ImGui.MenuItem( ctx, 'Show sends match words', '', EXT.CONF_marksendwordsmatch==1, true ) then EXT.CONF_marksendwordsmatch=EXT.CONF_marksendwordsmatch~1 EXT:save() DATA.upd = true end
      if EXT.CONF_marksendwordsmatch==1 then 
        ImGui.Indent(ctx, UI.indent_menu)
        local retval, buf = ImGui.InputText( ctx, 'Send names CSV', EXT.CONF_definebyname, ImGui.InputTextFlags_EnterReturnsTrue )
        if retval then 
          if buf == '' then buf = '[none]' end
          EXT.CONF_definebyname = buf 
          EXT:save() 
          DATA.upd = true 
        end
        ImGui.Unindent(ctx, UI.indent_menu)
      end 
      if ImGui.MenuItem( ctx, 'Show sends with parent folder match words', '', EXT.CONF_marksendparentwordsmatch==1, true ) then EXT.CONF_marksendparentwordsmatch=EXT.CONF_marksendparentwordsmatch~1 EXT:save() DATA.upd = true end
      if EXT.CONF_marksendparentwordsmatch==1  then 
        ImGui.Indent(ctx, UI.indent_menu)
        local retval, buf = ImGui.InputText( ctx, 'Folder names CSV', EXT.CONF_definebygroup, ImGui.InputTextFlags_EnterReturnsTrue )
        if retval then 
          if buf == '' then buf = '[none]' end
          EXT.CONF_definebygroup = buf 
          EXT:save() 
          DATA.upd = true 
        end
        ImGui.Unindent(ctx, UI.indent_menu)
      end
      
      
      
      -- engine
        ImGui.SeparatorText(ctx, 'Engine') 
        --if ImGui.MenuItem( ctx, 'Auto adjust width', '', EXT.CONF_autoadjustwidth==1, true ) then EXT.CONF_autoadjustwidth=EXT.CONF_autoadjustwidth~1 EXT:save() DATA.upd = true end
        if ImGui.MenuItem( ctx, 'Allow ReceiveFader mode', '', EXT.CONF_allowreceivefader_mode&1==1, true ) then EXT.CONF_allowreceivefader_mode=EXT.CONF_allowreceivefader_mode~1 EXT:save() DATA.upd = true end
        if ImGui.MenuItem( ctx, 'Allow multiple sends to the same track', '', EXT.CONF_allowsametrackmultsends&1==1, true ) then EXT.CONF_allowsametrackmultsends=EXT.CONF_allowsametrackmultsends~1 EXT:save() DATA.upd = true end
      
      
      
      -- UI
        ImGui.SeparatorText(ctx, 'UI')
        if ImGui.MenuItem( ctx, 'Allow show sends in ReceiveFader mode', '', EXT.CONF_allowreceivefader_mode&2==2, true ) then EXT.CONF_allowreceivefader_mode=EXT.CONF_allowreceivefader_mode~2 EXT:save() DATA.upd = true end
        if ImGui.MenuItem( ctx, 'Show track levels', '', EXT.CONF_showpeaks==1, true ) then EXT.CONF_showpeaks=EXT.CONF_showpeaks~1 EXT:save() DATA.upd = true end
        if ImGui.MenuItem( ctx, 'Show available sends in left combo', '', EXT.CONF_alwaysshowreceives==2, true ) then EXT.CONF_alwaysshowreceives=EXT.CONF_alwaysshowreceives~2 EXT:save() DATA.upd = true end
        if ImGui.MenuItem( ctx, 'Show parent send', '', EXT.CONF_showparentsend==1, true ) then EXT.CONF_showparentsend=EXT.CONF_showparentsend~1 EXT:save() DATA.upd = true end
        --local t = { [1] = 'Hide', [0] = 'List', [2] = 'Combo', } local preview_value = 'Tracks marked for send: '..t[EXT.CONF_alwaysshowreceives]
        --if ImGui.BeginCombo( ctx, '##Marked receives', preview_value, ImGui.ComboFlags_None|ImGui.ComboFlags_NoArrowButton ) then  for val in pairs(t ) do if ImGui.Selectable( ctx, t[val]..'##markreccombo'..val, val == EXT.CONF_alwaysshowreceives, ImGui.SelectableFlags_None) then EXT.CONF_alwaysshowreceives=val EXT:save() DATA.upd = true end end ImGui.EndCombo( ctx) end
      
      ImGui.EndMenu( ctx)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_menu_solo() 
    if not(DATA.srctr and DATA.srctr.UIsolotxt ) then return end
    if DATA.display_w <= UI.minsizeW2 then return end 
    
    if DATA.srctr.solo==0 then 
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,       UI.Tools_RGBA(UI.main_col, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,UI.Tools_RGBA(UI.main_col, 0.98)) 
     else
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,       UI.Tools_RGBA(UI.active_colbutheader, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, UI.Tools_RGBA(UI.active_colbutheader, 0.9) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,UI.Tools_RGBA(UI.active_colbutheader, 0.7)) 
    end
    
    
    
    if ImGui.MenuItem( ctx, DATA.srctr.UIsolotxt, '', DATA.srctr and DATA.srctr.solo > 0, true ) then 
      local tr = DATA.srctr.ptr
      if DATA.srctr.solo==0 then 
        SetMediaTrackInfo_Value( tr, 'I_SOLO', 4 ) 
        SetTrackUISolo( tr, 4, 2 )
       else 
        SetMediaTrackInfo_Value( tr, 'I_SOLO', 0 ) 
        SetTrackUISolo( tr,0, 2 )
      end 
      TrackList_AdjustWindows( false )
      DATA.upd = true 
    end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then
      local tr = DATA.srctr.ptr
      local solod  = GetMediaTrackInfo_Value( tr, 'B_SOLO_DEFEAT' ) 
      SetMediaTrackInfo_Value( tr, 'B_SOLO_DEFEAT', solod~1 ) 
      TrackList_AdjustWindows( false )
      DATA.upd = true 
    end
    
    ImGui.PopStyleColor(ctx,3)
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_menu_parsend() 
    if DATA.display_w <= UI.minsizeW2 then return end 
    
    if DATA.srctr.B_MAINSEND==0 then 
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,       UI.Tools_RGBA(UI.main_col, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, UI.Tools_RGBA(UI.main_col, 1) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,UI.Tools_RGBA(UI.main_col, 0.98)) 
     else
      ImGui.PushStyleColor(ctx, ImGui.Col_Header,       UI.Tools_RGBA(UI.active_colbutheader, 0.5) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, UI.Tools_RGBA(UI.active_colbutheader, 0.9) )
      ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,UI.Tools_RGBA(UI.active_colbutheader, 0.7)) 
    end
    
    if ImGui.MenuItem( ctx, 'Parent send', '', DATA.srctr and DATA.srctr.B_MAINSEND ~= 0, true ) then 
      local tr = DATA.srctr.ptr
      SetMediaTrackInfo_Value( tr, 'B_MAINSEND', DATA.srctr.B_MAINSEND~1 ) 
      TrackList_AdjustWindows( false )
      DATA.upd = true 
    end
    
    ImGui.PopStyleColor(ctx,3)
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_menu()   
    if ImGui.BeginMenuBar( ctx ) then 
      UI.draw_menu_add() 
      ImGui.Dummy(ctx, 0,0)
      UI.draw_menu_solo()
      ImGui.Dummy(ctx, 0,0)
      if EXT.CONF_showparentsend == 1 then
        UI.draw_menu_parsend()
        ImGui.Dummy(ctx, 0,0)
      end
      
      UI.draw_menu_options()
      ImGui.EndMenuBar( ctx )
    end 
  end 
  --------------------------------------------------------------------------------  
  function UI.draw()  
    UI.draw_menu() 
    UI.draw_sends()   
    if ImGui_IsKeyPressed(  ctx, ImGui.Key_V,false )        then ImGui.OpenPopup(ctx, 'vcapopup', ImGui.PopupFlags_None) end
    UI.draw_VCAfader() 
    UI.draw_popups() 
  end 
  --------------------------------------------------------------------------------  
  function UI.draw_VCAfader_handlemouse(v) 
    if DATA.selected_track_is_receive then 
    
      if ImGui.IsItemActivated(ctx) then 
        DATA.temp_vca = CopyTable(DATA.srctr.receives)
       elseif ImGui.IsItemActive(ctx) and DATA.temp_vca then 
        for i = 1, #DATA.temp_vca do
          local srcPtr = DATA.temp_vca[i].srcPtr
          local sendidx = DATA.temp_vca[i].sendidx
          local src_vol = DATA.temp_vca[i].vol
          local newvalue = src_vol * v^2
          local ret, VCALOCK = GetSetMediaTrackInfo_String( srcPtr, 'P_EXT:VCALOCK', '', false ) VCALOCK = tonumber(VCALOCK) or 0
          if VCALOCK == 0 then 
            SetTrackSendInfo_Value( srcPtr,0, sendidx, 'D_VOL', VF_lim(newvalue,0,2) ) 
            DATA.srctr.receives[i].vol = newvalue
          end
          
        end
      end
      
     else
      
      if ImGui.IsItemActivated(ctx) then 
        DATA.temp_vca = CopyTable(DATA.srctr.sends)
       elseif ImGui.IsItemActive(ctx) and DATA.temp_vca then 
        for i = 1, #DATA.temp_vca do
          local srcPtr = DATA.srctr.ptr
          local sendidx = DATA.temp_vca[i].sendidx
          local src_vol = DATA.temp_vca[i].vol
          local newvalue = src_vol * v^2
          local ret, VCALOCK = GetSetMediaTrackInfo_String( srcPtr, 'P_EXT:VCALOCK', '', false ) VCALOCK = tonumber(VCALOCK) or 0
          if VCALOCK == 0 then 
            SetTrackSendInfo_Value( srcPtr, 0, sendidx, 'D_VOL', VF_lim(newvalue,0,2) ) 
            DATA.srctr.sends[i].vol = newvalue
          end
          
        end
      end
      
    end  
    
    if ImGui.IsItemDeactivatedAfterEdit(ctx) then DATA.VCA_faderval = 1 end
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_VCAfader() 
    local vca_w = UI.faderW+UI.spacingX*2
    local vca_h = 205
    ImGui_SetNextWindowPos(ctx, DATA.display_x+(DATA.display_w-vca_w)/2,DATA.display_y+(DATA.display_h-vca_h)/2, ImGui.Cond_Appearing)
    ImGui_SetNextWindowSize(ctx, vca_w,vca_h, ImGui.Cond_Always)
    if ImGui.BeginPopup(ctx, 'vcapopup', ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then
      ImGui.SeparatorText(ctx,'VCA') 
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,0x7D0F0FBF)  
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive,0xBD0F0FBF)  
      x, y = reaper.ImGui_GetContentRegionAvail( ctx )
      local retval, v = ImGui.VSliderDouble( ctx, '##mainVCA', UI.faderW, y, DATA.VCA_faderval, 0, 2, '', ImGui.SliderFlags_None)
      UI.draw_VCAfader_handlemouse(v) 
      ImGui.PopStyleColor(ctx,2)
      ImGui.EndPopup(ctx)
    end
  end
  --------------------------------------------------------------------------------  
  function UI.draw_popups()  
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
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_slider(t) 
    local str_id = t.str_id
    if not str_id then return end
    local x, y = reaper.ImGui_GetCursorScreenPos( ctx )
    local hovered 
    -- slider
    local faderval = DATA:Convert_Val2Fader(t.vol)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,UI.Tools_RGBA(UI.sliderBG, 0.8))
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,UI.Tools_RGBA(UI.sliderBG, 0.9))
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,UI.Tools_RGBA(UI.sliderBG, 1))
    local retval, v = ImGui.VSliderDouble( ctx, '##vol'..str_id, UI.faderW, UI.calc_faderH, faderval, 0, 1, '', ImGui.SliderFlags_None)
    ImGui.PopStyleColor(ctx,3)
    
    -- on left click
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then  
      DATA.temp_vca = CopyTable(DATA.srctr.sends) 
      if DATA.selected_track_is_receive == true then 
        DATA.temp_vca = CopyTable(DATA.srctr.receives) 
       else
        DATA.temp_vca = CopyTable(DATA.srctr.sends) 
      end
    end 
    
    -- on slider drag
    if retval then 
      DATA.tweakingstate = true
      local outvol = DATA:Convert_Fader2Val(v) 
      if not t.sendidx then
        CreateTrackSend( DATA.srctr.ptr, t.ptr )
        DATA.upd = true 
        return
      end
      SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'D_VOL', outvol)
      SetTrackSendUIVol( t.srcPtr, t.sendidx, outvol,0)
      t.vol = outvol
      DATA.upd = true
      hovered = true
      if t.ext_vcasel == 1 then
        if DATA.selected_track_is_receive == true then 
          UI.draw_sends_sub_slider_handlevca(t, t.sendidx_vcacheck) 
         else
          UI.draw_sends_sub_slider_handlevca(t, t.sendidx) 
        end
      end
    end
    
    
    -- is clicked right
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
      UI.popups['Set fader volume in dB'] = {
        trig = true,
        captions_csv = 'New volume in dB',
        func_getval = function()  
          local cur_dB = math.floor(  WDL_VAL2DB(t.vol) *100)/100
          return cur_dB
        end,
        
        func_setval = function(retval, retvals_csv)  
          if retval == true and  tonumber(retvals_csv) then
            local dbval = tonumber(retvals_csv)
            if not ( dbval > -90 and dbval < 12) then return end
            local outvol = WDL_DB2VAL(dbval)
            SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'D_VOL', outvol)
            SetTrackSendUIVol( t.srcPtr, t.sendidx, outvol, 1 )
            DATA.upd = true
          end
        end
      }
    end
    
    -- on release
    if ImGui.IsItemDeactivated( ctx ) then 
      DATA.tweakingstate = false
      SetTrackSendUIVol( t.srcPtr, t.sendidx, t.vol, -1 )
      sendidx_master =  t.sendidx
      -- app dest
      for i = 1, #DATA.temp_vca do
        local sendidx = DATA.temp_vca[i].sendidx
        local sendidx_vcacheck = DATA.temp_vca[i].sendidx_vcacheck
        local src_vol = DATA.temp_vca[i].vol
        if DATA.temp_vca[i].ext_vcasel == 1 and sendidx_master ~= sendidx_vcacheck then 
          SetTrackSendInfo_Value( t.srcPtr, 0, sendidx, 'D_VOL', t.vol)
          SetTrackSendUIVol(t.srcPtr, sendidx,  t.vol,-1)
        end 
      end
    end
    
    
    -- on hover
    local hovered = ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None )
    --if hovered == true then 
      UI.draw_sends_sub_slider_scale(t,x, y, UI.faderW, UI.calc_faderH) 
    --end
    
    
    -- LED
      local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
      local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
      local ledsz = 5
      local ledoffs = 5
      if t.VCALOCK and t.VCALOCK == 1 then
        ImGui.DrawList_AddRectFilled( UI.draw_list, x1+ledoffs,y1+ledoffs, x1+ledoffs+ledsz,y1+ledoffs+ledsz, 0xF95F0FBF, 2, reaper.ImGui_DrawFlags_None() )
      end
    
    -- show peaks
    if EXT.CONF_showpeaks == 1 then 
      UI.draw_sends_sub_slider_peaks(t,x, y, UI.faderW, UI.calc_faderH) 
    end
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_slider_peaks(t,x0, y0, w0, h0)
    if not (t.peaks and t.peaks.peaksRMS_L) then return end
    local x,y,w,h = x0, y0+UI.GrabMinSize/2, w0, h0-UI.GrabMinSize
    local draw_list = ImGui.GetWindowDrawList( ctx )
    --[[for i = 1, UI.peaks_cnt do
      if t.peaks[i] then
        local peak = t.peaks[i][1]
        local peakR = t.peaks[i][2]
        ImGui_DrawList_AddRectFilled( draw_list, x+5, y+h-h*peak, x+10, y+h, 0xFFFFFFF<<8|math.floor((0x20* i/UI.peaks_cnt)), 2, ImGui.DrawFlags_None )
        ImGui_DrawList_AddRectFilled( draw_list, x+10, y+h-h*peakR, x+15, y+h, 0xFFFFFFF<<8|math.floor((0x20* i/UI.peaks_cnt)), 2, ImGui.DrawFlags_None )
      end
    end]]
    local alpha = 0x60
    if t.peaks.peaksRMS_L and t.peaks.peaksRMS_L > 0.001 then ImGui_DrawList_AddRectFilled( draw_list, x+5, y+h-h*t.peaks.peaksRMS_L, x+10, y+h, 0xFFFFFF<<8|alpha, 2, ImGui.DrawFlags_None ) end
    if t.peaks.peaksRMS_R and t.peaks.peaksRMS_R > 0.001  then ImGui_DrawList_AddRectFilled( draw_list, x+10, y+h-h*t.peaks.peaksRMS_R, x+15, y+h, 0xFFFFFF<<8|alpha, 2, ImGui.DrawFlags_None ) end
    
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_slider_scale(t,x0, y0, w0, h0) 
    local x,y,w,h = x0, y0+UI.GrabMinSize/2, w0, h0-UI.GrabMinSize
    local draw_list = ImGui.GetWindowDrawList( ctx )
    --ImGui.DrawList_AddRect( draw_list, x, y, x+w, y+h, 0xFFFFFFFF, 0, 0, 1 )
    local col_rgba = 0xFFFFFF5F
    for i = 1, #DATA.scale_map do
      local t_val = tonumber(DATA.scale_map[i])
      local rea_val = WDL_DB2VAL(t_val)
      local y1 = DATA:Convert_Val2Fader(rea_val)
      local ylev = y+h*(1-y1)
      ImGui.DrawList_AddLine( draw_list, x+w-5, ylev, x+w-10, ylev, col_rgba, 1 )
      ImGui.DrawList_AddText( draw_list, x+w-45, ylev-6, col_rgba, DATA.scale_map[i]..'dB' )
    end
  end
  -----------------------------------------------------------------------------------------
  function UI.draw_sends_sub_chan(t)
    local str_id = t.str_id  if not str_id then return end
    
    
    
    --I_SRCCHAN : audio source starting channel index or -1 if audio send is disabled (&1024=mono...note that in that case, when reading index, you should do (index XOR 1024) to get starting channel index)
    --I_DSTCHAN : audio destination starting channel index (&1024=mono (and in case of hardware output &512=rearoute)...note that in that case, when reading index, you should do (index XOR (1024 OR 512)) to get starting channel index)

    -- src
    ImGui.SetNextItemWidth(ctx,UI.calc_comboW) 
    local preview_value = ''
    local mapt = {} 
    local I_SRCCHAN_cnt = t.I_SRCCHAN_cnt or 2
    for i = 0, 63, I_SRCCHAN_cnt do
      mapt[i] = ' '..(i+1)..'/'..(i+I_SRCCHAN_cnt )
      if ismono then mapt[i] = (i+1) end
    end 
    if mapt[t.I_SRCCHAN&0x1FF] then preview_value= mapt[t.I_SRCCHAN&0x1FF] end
    if t.I_SRCCHAN == -1 then preview_value  = 'none' end
    
    if ImGui.BeginCombo( ctx, '##srcch_sel'..str_id, preview_value, ImGui.ComboFlags_None|ImGui.ComboFlags_NoArrowButton ) then
      
      if t.I_SRCCHAN ~= -1 then
        local max_available_ch = DATA.srctr.I_NCHAN 
        for i = 0, max_available_ch do
          local chan
          local str = i..' channel(s)'
          if i == 0 then 
            str = 'Stereo'
            chan = 0
           elseif i == 1 then 
            str = 'Mono'
            chan = 1
           elseif i~= 0 and i ~= 1 and i > 2 and i%2==0 then 
            str = i..' chan'
            chan= i /2
          end
          if chan then
            if ImGui.Checkbox( ctx, str, (t.I_SRCCHANsrc>>10) == chan ) then
              SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'I_SRCCHAN', (t.I_SRCCHAN&0xFF)|(chan<<10))
              DATA.upd = true
            end
          end
        end
      end
      
      -- dest offs
      
      if ImGui.Selectable( ctx, 'none##srcch'..str_id..-1, t.I_SRCCHAN == -1, ImGui.SelectableFlags_None) then SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'I_SRCCHAN', -1) DATA.upd = true end
      for i = 0, 63, I_SRCCHAN_cnt do
        if ImGui.Selectable( ctx, mapt[i]..'##srcch'..str_id..i, t.I_SRCCHAN&0x1FF==i, ImGui.SelectableFlags_None) then
          local mono = 0 if ismono == true then mono =1024 end
          if t.I_SRCCHAN == -1 then t.I_SRCCHAN = i end
          if t.I_SRCCHAN&0x1FF > DATA.srctr.I_NCHAN-2 then SetMediaTrackInfo_Value( t.srcPtr, 'I_NCHAN', (t.I_SRCCHAN&0x1FF+2)|mono ) end -- increase 
          SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'I_SRCCHAN', i|mono)
          DATA.upd = true
        end
      end
      ImGui.EndCombo( ctx)
    end
    
    ImGui.SameLine(ctx)
    -- dest
    ImGui.SetNextItemWidth(ctx,UI.calc_comboW) 
    local preview_value = ''
    local mapt = {} 
    local ismono =  t.I_DSTCHAN&1024 == 1024
    if ismono == true then step = 1 end
    for i = 0, 63, I_SRCCHAN_cnt do
      mapt[i] = ' '..(i+1)..'/'..(i+I_SRCCHAN_cnt )
      if ismono then mapt[i] = (i+1) end
    end 
    if mapt[t.I_DSTCHAN&0x1FF] then preview_value= mapt[t.I_DSTCHAN&0x1FF] end
    if ImGui.BeginCombo( ctx, '##destch'..str_id, preview_value, ImGui.ComboFlags_None|ImGui.ComboFlags_NoArrowButton ) then
      -- mono
      if ImGui.Checkbox( ctx, 'Mono', t.I_DSTCHAN&1024 == 1024 ) then
        SetTrackSendInfo_Value(t.srcPtr, 0, t.sendidx, 'I_DSTCHAN', t.I_DSTCHAN~1024)
        DATA.upd = true
      end
      -- dest offs
      for i = 0, 63, I_SRCCHAN_cnt do
        if ImGui.Selectable( ctx, mapt[i]..'##destch'..str_id..i, t.I_DSTCHAN&0x1FF==i, ImGui.SelectableFlags_None) then
          local mono = 0 if ismono == true then mono =1024 end
          --if t.I_DSTCHAN&0x1FF > t.destI_NCHAN-2 then SetMediaTrackInfo_Value( t.destPtr, 'I_NCHAN', (t.I_DSTCHAN&0x1FF+2)|mono ) end -- increase 
          if i+I_SRCCHAN_cnt > t.destI_NCHAN then SetMediaTrackInfo_Value( t.destPtr, 'I_NCHAN', (i+I_SRCCHAN_cnt)|mono ) end -- increase 
          SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'I_DSTCHAN', i|mono)
          DATA.upd = true
        end
      end
      ImGui.EndCombo( ctx)
    end
    
    
    
  end
  ----------------------------------------------------------------------------------------- 
  function DATA:GoTotrack(tr)
    reaper.Main_OnCommand(40297,0) -- unselect all
    reaper.SetTrackSelected(tr, true) 
    reaper.SetMixerScroll(tr)
    reaper.Main_OnCommand(40913,0) -- arrange view to selected send  
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_destname(t)
    local str_id = t.str_id
    if not str_id then return end
    if ImGui.Button(ctx, t.destName..'##destname'..str_id,-1) then DATA:GoTotrack(t.destPtr) end
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
      UI.popups['Set new name'] = {
        trig = true,
        captions_csv = 'New name',
        func_getval = function()  
          return t.destName
        end,
        
        func_setval = function(retval, retvals_csv)  
          if retval == true then
            GetSetMediaTrackInfo_String( t.destPtr, 'P_NAME', retvals_csv, true )
            DATA.upd = true
          end
        end
        
      }
    end
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_muteremove(t)
    local str_id = t.str_id
    if not str_id then return end
    if t.B_MUTE == 1 then 
      UI.draw_setbuttoncolor(0xFF0000) 
     else
      UI.draw_setbuttoncolor(UI.main_col)
    end
    if ImGui.Button(ctx, 'Mute##destmute'..str_id,UI.calc_comboW) then SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'B_MUTE', t.B_MUTE~1) DATA.upd = true end
    ImGui.PopStyleColor(ctx,3)
    
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Del##destrem'..str_id,UI.calc_comboW) then RemoveTrackSend( t.srcPtr, 0, t.sendidx ) DATA.upd = true end
    
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_mode(t)
    local str_id = t.str_id
    if not str_id then return end
    
    ImGui.SetNextItemWidth(ctx,UI.faderW) 
    local map_t = {
      [0] = 'PostFader',
      [1] = 'PreFX',
      [3] = 'PreFader',
    }
    local preview_value= ''
    if map_t[t.I_SENDMODE] then preview_value = map_t[t.I_SENDMODE] end
    if ImGui.BeginCombo( ctx, '##srcmode'..str_id, '', ImGui.ComboFlags_None|ImGui.ComboFlags_NoArrowButton ) then
      for key in pairs(map_t) do
        if ImGui.Selectable( ctx, map_t[key]..'##srcch'..str_id..key, t.I_SENDMODE==key, ImGui.SelectableFlags_None) then
          SetTrackSendInfo_Value(  t.srcPtr, 0, t.sendidx, 'I_SENDMODE', key)
          DATA.upd = true
        end
      end
      ImGui.EndCombo( ctx)
    end
    
    -- draw mode
    local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
    local iw, ih = ImGui.GetItemRectSize( ctx )
    --ImGui.PushFont(ctx, DATA.font, UI.font3sz) 
    local txtw, txth = reaper.ImGui_CalcTextSize( ctx, preview_value)
    --ImGui.PopFont(ctx) 
    ImGui.DrawList_AddTextEx( UI.draw_list, DATA.font,  UI.font3sz, x1 + 0.5*(iw - txtw), y1 + 0.5*(ih - txth), 0xFFFFFFFF, preview_value )
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_pan(t)
    local str_id = t.str_id
    if not str_id then return end
    
    ImGui.SetNextItemWidth(ctx,UI.faderW) 
    local formatIn = 'Center' if t.D_PAN > 0.01 then formatIn = math.ceil(t.D_PAN*100)..'%%R' elseif t.D_PAN < -0.01 then formatIn = -math.floor(t.D_PAN*100)..'%%L' end 
    ImGui.PushStyleColor(ctx,ImGui.Col_SliderGrab,0) 
    ImGui.PushStyleColor(ctx,ImGui.Col_SliderGrabActive,0) 
    local absx, absy = ImGui.GetCursorScreenPos( ctx )
    local retval, v = reaper.ImGui_SliderDouble( ctx, '##pan'..str_id, t.D_PAN, -1, 1, formatIn, ImGui.SliderFlags_None )
    local bw, bh = ImGui.GetItemRectSize( ctx )
    local offs = 5
    absx = absx + offs/2
    bw = bw -offs
    ImGui.PopStyleColor(ctx,2)
    local absx = absx + 0.5*(t.D_PAN+1)*bw
    if math.abs(t.D_PAN)<0.55 then
      ImGui.DrawList_AddRectFilled( ImGui.GetWindowDrawList( ctx ),absx, absy+bh-4, absx+2, absy+bh, 0xF0F0F0BF, 1, ImGui.DrawFlags_None )
      ImGui.DrawList_AddRectFilled( ImGui.GetWindowDrawList( ctx ),absx, absy, absx+2, absy+4, 0xF0F0F0BF, 1, ImGui.DrawFlags_None )
     else
      ImGui.DrawList_AddRectFilled( ImGui.GetWindowDrawList( ctx ),absx, absy, absx+2, absy+bh, 0xF0F0F0BF, 1, ImGui.DrawFlags_None )
    end
    --[[if retval then 
      SetTrackSendInfo_Value( DATA.srctr.ptr, 0, t.sendidx, 'D_PAN', v)
      DATA.upd = true
    end]]
    
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
      DATA.temp_latchstate = t.D_PAN
    end
    if ImGui.IsItemActive( ctx ) then
      local x, y = ImGui.GetMouseDragDelta( ctx )
      local outval = DATA.temp_latchstate + x/200
      outval = math.max(-1,math.min(outval,1))
      local dx, dy = ImGui.GetMouseDelta( ctx )
      if dx~=0 then
        t.D_PAN = outval
        SetTrackSendInfo_Value(  t.srcPtr, 0, t.sendidx, 'D_PAN', outval)
        DATA.upd = true
      end
    end
    
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'D_PAN',0) DATA.upd = true end
  end
  
  -------------------------------------------------------------------- 
  function DATA:SetData_SetReaEQLPHP(tr, fx, HP_freq, LP_freq)
    -- 0Hz for LP
      TrackFX_SetEQParam( tr, fx, 
        0,--bandtype HP, 
        0,--bandidx, 
        0,-- paramtype, freq
        HP_freq, --val, 
        true)--isnorm )
    -- 0dB for HP
      TrackFX_SetEQParam( tr, fx, 
        0,--bandtype HP, 
        0,--bandidx, 
        1,-- paramtype, gain
        0, --val, 
        true)--isnorm )      
    -- 22.5fHz for LP
      TrackFX_SetEQParam( tr, fx, 
        5,--bandtype LP,
        0,--bandidx, 
        0,-- paramtype, freq
        LP_freq, --val, 
        true)--isnorm )   
    -- 0dB for LP     
      TrackFX_SetEQParam( tr, fx, 
        5,--bandtype LP,
        0,--bandidx, 
        1,-- paramtype, gain
        0, --val, 
        true)--isnorm )          
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_filt(t,ispost)
    local str_id = t.str_id  if not str_id then return end
    local UI_txt = 'PreEQ'
    if ispost then str_id=str_id..'post'  UI_txt = 'PostEQ' end
    
    -- define custom data values for filter slider
    local filtFpos = 0
    local filtFwidth = 0
    local key = 'pre'
    if ispost then key = 'post' end
    if not t.sendEQ[key] then 
      filtFpos = 0.5
      filtFwidth = 1
     else
      filtFpos = t.sendEQ[key].val_POS
      filtFwidth = t.sendEQ[key].val_WID
    end
    
    ImGui.SetNextItemWidth(ctx,UI.faderW) 
    local filtW_max = UI.faderW -- 5
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize, filtW_max*filtFwidth)
    local retval, v = reaper.ImGui_SliderDouble( ctx, '##filt'..str_id, filtFpos, 0, 1, UI_txt, ImGui.SliderFlags_None )
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left) then 
      DATA:SetData_InitReaEQ(t.destPtr) 
      DATA.temp_x, DATA.temp_y = ImGui.GetMousePos( ctx )
      DATA.temp_p = filtFpos
      DATA.temp_w = filtFwidth
    end
    if DATA.temp_w and ImGui.IsItemActive( ctx ) and t.sendEQ[key] then 
      local x, y = reaper.ImGui_GetMouseDragDelta( ctx, DATA.temp_x, DATA.temp_y, ImGui.MouseButton_Left, -1 )
      local out_pos = DATA.temp_p + x /100
      local out_width = DATA.temp_w - y /100
      
      out_width = VF_lim(out_width,0.1,1) 
      out_pos = VF_lim(out_pos,out_width/2,1-out_width/2) 
      
      if (out_width == filtFwidth and out_pos==filtFpos) then goto skip_set end
      local ret,tr, fxID = VF_GetFXByGUID(t.sendEQ[key].fxGUID, t.destPtr)
      if not ret then goto skip_set end
      DATA:SetData_SetReaEQLPHP(t.destPtr, fxID, VF_lim(out_pos-out_width/2), VF_lim(out_pos+out_width/2))
      DATA.upd=true 
      ::skip_set::
    end
    ImGui.PopStyleVar(ctx)
  end
  ----------------------------------------------------------------------------------------- 
  function VF_GetFXByGUID(GUID, tr, proj)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(proj or -1) do
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
      if not (ValidatePtr2(proj or -1, tr, 'MediaTrack*')) then return end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end    
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends() 
    if not (DATA.tracks and DATA.srctr and DATA.srctr.sends) then return end 
    
    -- show list of available sends in list
    if EXT.CONF_alwaysshowreceives == 2 and (DATA.selected_track_is_receive ~= true or (DATA.selected_track_is_receive == true and EXT.CONF_allowreceivefader_mode&2==2)) then
      for i = 1, #DATA.receives do 
        if (DATA.srctr.ptr~=DATA.receives[i].ptr ) then
          if ImGui.BeginChild(ctx,'##selector', UI.faderW, -UI.spacingY, ImGui.ChildFlags_Borders) then
            if ImGui.Button( ctx, DATA.receives[i].trname,-1) then 
              CreateTrackSend( DATA.srctr.ptr, DATA.receives[i].ptr )
              DATA.upd = true 
            end
            ImGui.EndChild(ctx)
          end
        end
        ImGui.SameLine(ctx)
      end 
    end
    
    -- show existing sends
    if DATA.selected_track_is_receive ~= true then
      for sendID = 1, #DATA.srctr.sends do 
        UI.draw_sends_sub(DATA.srctr.sends[sendID])  
        ImGui.SameLine(ctx)
      end
    end
    
    -- show receives in list
    if EXT.CONF_alwaysshowreceives == 1 and DATA.selected_track_is_receive ~= true then
      for recID = 1, #DATA.receives do 
        UI.draw_sends_sub(DATA.receives[recID]) 
        ImGui.SameLine(ctx)
      end
    end
    
    -- show receives
    if DATA.selected_track_is_receive == true then
      for sendID = 1, #DATA.srctr.receives do 
        UI.draw_sends_sub(DATA.srctr.receives[sendID]) 
        ImGui.SameLine(ctx)
      end
    end
    
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_FX_menu(t) 
    local str_id = t.str_id  if not str_id then return end
    if ImGui.Button(ctx, 'FX##destFX'..str_id,UI.calc_comboW+13) then 
      local PreEQ = TrackFX_AddByName( t.destPtr, 'PreEQ', false, 0 )
      local PostEQ = TrackFX_AddByName( t.destPtr, 'PostEQ', false, 0 )
      
      if (PreEQ == -1 and PostEQ == -1) or (PreEQ == 0 and PostEQ == 1) then  
        TrackFX_Show( t.destPtr, 0, 1 )  
       else
        if TrackFX_GetCount( t.destPtr ) > 2 then TrackFX_Show( t.destPtr, PreEQ+1, 3) else TrackFX_Show( t.destPtr, 0,1 )  end
      end
    end
    
    
    ImGui.SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx,UI.calc_comboW)
    if ImGui.BeginCombo(ctx, '##vcalock'..str_id, '', reaper.ImGui_ComboFlags_NoPreview()) then 
      if ImGui.Selectable(ctx, 'Lock from VCA control##vcalocktoggle'..str_id, t.VCALOCK == 1, ImGui.SelectableFlags_None) then
        local tr = t.destPtr
        if DATA.selected_track_is_receive == true then tr = t.srcPtr end
        GetSetMediaTrackInfo_String( tr, 'P_EXT:VCALOCK', t.VCALOCK~1, true )
        DATA.upd = true
      end
      ImGui.EndCombo(ctx)
    end
    
    
  end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttoncolor(col) 
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,col<<8|math.floor(255*0.5 ))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,col<<8|math.floor(255*1))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,col<<8|math.floor(255*0.8 ))
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub_monophase(t)
    local str_id = t.str_id
    if not str_id then return end
    
    if t.B_MONO == 1 then 
      UI.draw_setbuttoncolor(0x0FFF00) 
     else
      UI.draw_setbuttoncolor(UI.main_col)
    end
    if ImGui.Button(ctx, 'Mono##destmono'..str_id,UI.calc_comboW) then SetTrackSendInfo_Value( t.srcPtr, 0, t.sendidx, 'B_MONO', t.B_MONO~1) DATA.upd = true end
    ImGui.PopStyleColor(ctx,3)
    ImGui.SameLine(ctx)
    
    if t.B_PHASE == 1 then 
      UI.draw_setbuttoncolor(0x0FFF00) 
     else
      UI.draw_setbuttoncolor(UI.main_col)
    end
    if ImGui.Button(ctx, 'Ø##destphase'..str_id,UI.calc_comboW) then SetTrackSendInfo_Value(  t.srcPtr, 0, t.sendidx, 'B_PHASE', t.B_PHASE~1) DATA.upd = true end
    ImGui.PopStyleColor(ctx,3)
    
  end
  ----------------------------------------------------------------------------------------- 
  function UI.draw_sends_sub(t)
    local str_id = t.str_id
    if not str_id then return end
    local destCol = t.destCol
    if destCol == 0 then 
      ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, UI.main_col<<8|math.floor(0.2*255))
     else
      destCol = ImGui.ColorConvertNative(destCol)
      destCol = (destCol << 8) | math.floor(0.5*255)
      ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg,destCol)
    end
    if ImGui.BeginChild( ctx, str_id, 0, -1, ImGui.ChildFlags_AutoResizeX|ImGui.ChildFlags_AutoResizeY|ImGui.ChildFlags_Borders, ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then
      UI.draw_sends_sub_slider(t) 
      UI.draw_sends_sub_destname(t) 
      ImGui.PushFont(ctx, DATA.font, UI.font3sz) 
      if t.is_receive ~= true then
        if DATA.display_h > UI.compactmodeH then 
          UI.draw_sends_sub_chan(t)
          UI.draw_sends_sub_muteremove(t)
          UI.draw_sends_sub_mode(t)
          UI.draw_sends_sub_pan(t)
          UI.draw_sends_sub_filt(t)
          UI.draw_sends_sub_filt(t, true)
          UI.draw_sends_sub_FX_menu(t)
          UI.draw_sends_sub_monophase(t) 
        end
      end
      ImGui.PopFont(ctx) 
      ImGui.EndChild( ctx)
    end
    ImGui.PopStyleColor(ctx)
  end
  -----------------------------------------------------------------------------------------
  function DATA:CollectData_ReadProject_ReadReceives()
    local seltr = GetSelectedTrack(0,0)
    DATA.selected_track_is_receive = false
    DATA.receives = {}
    local CONF_definebygroup = tostring(EXT.CONF_definebygroup)
    local CONF_definebyname = tostring(EXT.CONF_definebyname)
    
    -- parse group names
      local names_group = {} 
      if CONF_definebygroup ~= '' then
        for word in CONF_definebygroup:gmatch('[^,]+') do names_group[#names_group+1]=word end
      end
      
    -- parse group names
      local names_track = {}
      if CONF_definebyname ~= '' then
        for word in CONF_definebyname:gmatch('[^,]+') do names_track[#names_track+1]=word end
      end   
    
    for i = 1, CountTracks(-1) do
      local tr = GetTrack(-1,i-1) 
      local ret, trname = GetTrackName(tr)
      local ispath =  GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' ) 
      
      if  ispath~=1 and
        (DATA:CollectData_ReadProject_ReadReceives_IsMarkedAsReceive(tr)  or
        DATA:CollectData_ReadProject_ReadReceives_MatchName(trname,names_track) or
        DATA:CollectData_ReadProject_ReadReceives_MatchGroupName(tr,names_group) 
        )
        and not DATA:CollectData_ReadProject_ReadReceives_Checkpointers(tr)
        --and not (GetSelectedTrack(-1,0) and tr ==GetSelectedTrack(-1,0))
       then
        
        --[[local destPtr = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
        local B_MUTE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MUTE' )
        local vol = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_VOL' )
        local B_MONO = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MONO' )
        local D_PAN = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_PAN' )
        local B_PHASE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_PHASE' )
        local I_SENDMODE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SENDMODE' )
        local I_AUTOMODE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_AUTOMODE' )
        local I_SRCCHAN = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SRCCHAN' )
        local I_DSTCHAN = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_DSTCHAN' )
        local destI_NCHAN  = GetMediaTrackInfo_Value( destPtr, 'I_NCHAN' ) 
         ]]
        local ret, destName  = reaper.GetTrackName( tr )
        local retval, destGUID = GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
        local destCol  = GetTrackColor( tr ) 
        
        
        if seltr and tr == seltr and EXT.CONF_allowreceivefader_mode&1 == 1 then DATA.selected_track_is_receive = true end
        
        DATA.receives[#DATA.receives+1] = {
            is_receive =true,
            trname=trname,
            ptr = tr,
            destCol = destCol,
            destGUID = destGUID,
            destName = destName,
            
          }
      end
    end
    
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadReceives_Checkpointers(tr)
    if not (DATA.srctr and DATA.srctr.sends) or EXT.CONF_allowsametrackmultsends == 1 then return end
    for i = 1, #DATA.srctr.sends do
      if tr == DATA.srctr.sends[i].destPtr then return true end
    end
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadReceives_IsMarkedAsReceive(tr)
    if EXT.CONF_marksendint ~= 1 then return end
    local retval, issend = reaper.GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', '', false )
    if retval and  issend and tonumber(issend) and tonumber(issend)  == 1 then return true end
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadReceives_MatchName(trname,names_track)
    if EXT.CONF_marksendwordsmatch ~= 1 then  return end
    if trname:match('Track') then return end 
    for sendnameID = 1, #names_track do 
      if trname:lower():match(names_track[sendnameID]:lower()) then return true end
    end 
  end
  ---------------------------------------------------------------------  
  function DATA:CollectData_ReadProject_ReadReceives_MatchGroupName(tr,names_group)
    if EXT.CONF_marksendparentwordsmatch ~= 1 then  return end 
    local par_track = GetParentTrack( tr ) 
    if par_track and ispath~=1 then
      local retval, parname = GetTrackName( par_track )
      for sendnameID = 1, #names_group do 
        if parname:lower():match(names_group[sendnameID]:lower()) then return true end
      end
    end
  end
  -----------------------------------------------------------------------------------------
  main()  
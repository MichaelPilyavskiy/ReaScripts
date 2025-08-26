-- @description Toggle mono processing for track under mouse cursor
-- @version 1.01
-- @author MPL
-- @about Set plugins bus size to 1 channel if available, duplicate left to right channel for last FX
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # do not process bypassed and offlines FX
--    # process last active FX to stereo instead of just last FX in chain

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion() vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then  if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end return else return true end
  end
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end
  --------------------------------------------------- 
  function main()
    local tr = VF_GetTrackUnderMouseCursor()
    if not tr then return end
    
    local retval, XYWH_tcp = reaper.GetSetMediaTrackInfo_String( tr, 'P_UI_RECT:tcp.size', '', false )
    local retval, monoproc_state = GetSetMediaTrackInfo_String( tr, 'P_EXT:mpl_monoproc_state', '', false ) 
    if not (retval and tonumber(monoproc_state) and  tonumber(monoproc_state) == 1) then 
      -- set mono
      GetSetMediaTrackInfo_String( tr, 'P_EXT:mpl_monoproc_state', '1', true )
      MonoProc_Setmono(tr)
      DrawHint(XYWH_tcp, 'Mono')
     else
      -- restore stereo
      GetSetMediaTrackInfo_String( tr, 'P_EXT:mpl_monoproc_state', '0', true )
      MonoProc_Setstereo(tr)
      DrawHint(XYWH_tcp, 'Stereo')
    end 
    
    
    
    return true
  end
  --------------------------------------------------------------------  
  function MonoProc_Setmono(tr)
    local fx_cnt = reaper.TrackFX_GetCount(tr)
    
    local last_activeFX
    local cnt_activeFX = 0
    for fxnumber = 1, fx_cnt do 
      if TrackFX_GetOffline( tr, fxnumber-1 ) == false and TrackFX_GetEnabled( tr, fxnumber-1 ) == true then
        cnt_activeFX = cnt_activeFX + 1
        last_activeFX = fxnumber -1
        local retval, inputPins, outputPins = reaper.TrackFX_GetIOSize( tr, fxnumber-1 )
        local pins = math.max(inputPins, outputPins)
        for pin = 0, pins do
          local val = 0
          if pin ==0 then val = 1 end
          reaper.TrackFX_SetPinMappings( tr, fxnumber-1, 0, pin, val, 0 )
          reaper.TrackFX_SetPinMappings( tr, fxnumber-1, 1, pin, val, 0 )
        end
        TrackFX_SetNamedConfigParm( tr, fxnumber-1, 'channel_config', 1) 
      end
    end 
     
    -- set stereo for last active FX
    if last_activeFX then 
      reaper.TrackFX_SetPinMappings( tr, last_activeFX, 1, 0, 3, 0 )
    end 
  end
  --------------------------------------------------------------------  
  function MonoProc_Setstereo(tr)
    local fx_cnt = reaper.TrackFX_GetCount(tr)
    for fxnumber = 1, fx_cnt do 
    
      if TrackFX_GetOffline( tr, fxnumber-1 ) == false and TrackFX_GetEnabled( tr, fxnumber-1 ) == true then
        TrackFX_SetNamedConfigParm( tr, fxnumber-1, 'channel_config', 2) 
        local retval, inputPins, outputPins = reaper.TrackFX_GetIOSize( tr, fxnumber-1 )
        local pins = math.max(inputPins, outputPins)
        for pin = 0, pins-1 do
          reaper.TrackFX_SetPinMappings( tr, fxnumber-1, 0, pin, 1<<pin, 0 )
          reaper.TrackFX_SetPinMappings( tr, fxnumber-1, 1, pin, 1<<pin, 0 )
        end
      end
      
    end  
  end
    function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  --------------------------------------------------------------------  
  function DrawHint(XYWH_tcp, monoproc_state)
    local x,y,w,h = XYWH_tcp:match('(%d+)%s(%d+)%s(%d+)%s(%d+)')
    local time_fadeout = 1
    package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    local ImGui = require 'imgui' '0.10'
    local ctx = ImGui.CreateContext('My script')
    local imgui_font = ImGui.CreateFont('Arial') ImGui.Attach(ctx, imgui_font)
    local startTS = reaper.time_precise()
    
    local function loop() 
      local TS = reaper.time_precise()
      alpha = time_fadeout-(TS - startTS)
      -- window_flags
        local window_flags = ImGui.WindowFlags_None
        window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
        window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
        window_flags = window_flags | ImGui.WindowFlags_NoMove
        window_flags = window_flags | ImGui.WindowFlags_NoResize
        window_flags = window_flags | ImGui.WindowFlags_NoCollapse
        window_flags = window_flags | ImGui.WindowFlags_NoNav
        window_flags = window_flags | ImGui.WindowFlags_NoBackground
        window_flags = window_flags | ImGui.WindowFlags_NoDocking
        window_flags = window_flags | ImGui.WindowFlags_TopMost
        window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
        
        reaper.ImGui_SetNextWindowPos(ctx,x,y)
        reaper.ImGui_SetNextWindowSize(ctx,w,h)
      local visible, open = ImGui.Begin(ctx, 'My window', true, window_flags)
      if visible then
        if alpha < time_fadeout and alpha > 0 then
          ImGui.PushFont(ctx, imgui_font, 20)
          ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFFFF<<8|math.floor(alpha * 255))
          local draw_list = ImGui.GetWindowDrawList( ctx )
          ImGui.DrawList_AddRectFilledMultiColor( draw_list, x, y, x+w, y+h, 0x000000FF, 0, 0, 0x001000FF )
          ImGui.Text(ctx, monoproc_state)
          ImGui.PopStyleColor(ctx)
          ImGui.PopFont(ctx)
        end
        ImGui.End(ctx)
      end
      if open then
        if TS - startTS < time_fadeout then reaper.defer(loop) end
      end
    end
    
    reaper.defer(loop)
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.43,true) then  
    Undo_BeginBlock2( 0 )
    local ret0 = main()
    if ret0 then Undo_EndBlock2( 0, 'Toggle mono processing for track under mouse cursor', 0xFFFFFFFF ) end
  end 
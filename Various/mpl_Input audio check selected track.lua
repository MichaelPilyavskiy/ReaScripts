-- @description Input audio check selected track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init



 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = { channels={},
            check_state=0,
            cnt_peaks=40
          }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '1.0'
    DATA.extstate.extstatesection = 'InputAudioCheck'
    DATA.extstate.mb_title = 'MPL InputAudioCheck'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  800,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          CONF_filtermode = 0,
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          UI_aliasmap = '', 
                          
                          }
    
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets()  
    if DATA.extstate.UI_initatmouse&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    DATA:GUIinit()
    RUN()
    DATA_RESERVED_ONPROJCHANGE(DATA)
  end
  ----------------------------------------------------------------------
  function DATA2:ProcessUndoBlock(f, name, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10) 
    Undo_BeginBlock2( 0)
    defer(f(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10))
    Undo_EndBlock2( 0, name, 0xFFFFFFFF )
  end
  -----------------------------------------------------------------------------  
  function GUI_Draw_data(DATA)
    for chan = 1, GetNumAudioInputs() do
      local x = DATA.GUI.buttons['chan'..chan].x
      local y = DATA.GUI.buttons['chan'..chan].y
      local w = DATA.GUI.buttons['chan'..chan].w
      local h = DATA.GUI.buttons['chan'..chan].h
      
      local r0 = h*0.49
      for peak = 1, #DATA2.peaks[chan] do
        r = r0 * (peak / #DATA2.peaks[chan])
        val = DATA2.peaks[chan][peak]
        gfx.a = val*1
        gfx.r = 1
        gfx.g = 0.3
        gfx.b = 0.3
        gfx.circle(x+w/2,y+h/2,r, 1, 1)
      end
    end
    
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE(DATA) 
    local tr = GetSelectedTrack(0,0)
    if not tr then return end  
    DATA2.tr_ptr = tr
    
    if DATA2.check_state == 0 then 
      if DATA2.check_trigger == true then 
        SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 0 )
        SetMediaTrackInfo_Value( tr, 'I_RECARM', 0 )
        SetMediaTrackInfo_Value( tr, 'I_NCHAN', 0 )
        DATA2.check_trigger = nil
        
        if DATA2.set_input then 
          SetMediaTrackInfo_Value( DATA2.tr_ptr, 'I_RECINPUT', DATA2.set_input )
          DATA2.set_input = nil
        end
      end
      return
    end
     
    if DATA2.check_state == 1 and DATA2.check_trigger == true then -- init run check
      SetMediaTrackInfo_Value( tr, 'I_RECARM', 1 )
      SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 2048 )
      SetMediaTrackInfo_Value( tr, 'I_NCHAN', GetNumAudioInputs() )
    end
    if not DATA2.peaks or trig_clear == true then DATA2.peaks = {} end
    for channel = 1, GetNumAudioInputs() do
      if not DATA2.peaks[channel] then DATA2.peaks[channel] = {} end
      local peak = Track_GetPeakInfo( tr, channel-1 )
      DATA2.peaks[channel][#DATA2.peaks[channel]+1] = peak
      if #DATA2.peaks[channel] > DATA2.cnt_peaks then table.remove(DATA2.peaks[channel],1) end -- wrap table
    end
    
    GUI_Draw_data(DATA)
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    
  end
  --------------------------------------------------------------------- 
  function DATA2:GetInputChannelNames()
    DATA2.channels = {}
    for channel = 1, GetNumAudioInputs() do
      DATA2.channels[channel] = GetInputChannelName( channel-1 )
    end
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init(DATA)
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play 
      if not DATA.GUI.buttons then DATA.GUI.buttons = {}  end
      
    -- get globals
      DATA.GUI.custom_gfx_hreal = math.floor(gfx.h/DATA.GUI.default_scale)
      DATA.GUI.custom_gfx_wreal = math.floor(gfx.w/DATA.GUI.default_scale)
      DATA.GUI.custom_reference = 800
      DATA.GUI.custom_Yrelation = VF_lim(math.max(DATA.GUI.custom_gfx_hreal,DATA.GUI.custom_gfx_wreal)/DATA.GUI.custom_reference, 0.1, 8) -- global W
      DATA.GUI.custom_offset =  math.floor(3 * DATA.GUI.custom_Yrelation)
      
      
      DATA.GUI.custom_infoh =  math.floor(40 * DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_info_txtsz= math.floor(15* DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_scrollw =  math.floor(20 * DATA.GUI.custom_Yrelation)
      
      DATA2:GetInputChannelNames()
      
      
      
      DATA.GUI.custom_gfx_h_effective = math.floor(DATA.GUI.custom_gfx_hreal*0.9)
      DATA.GUI.custom_gfx_checkbuth = DATA.GUI.custom_gfx_hreal-DATA.GUI.custom_gfx_h_effective
      local wnode = math.floor(DATA.GUI.custom_gfx_wreal/8)
      local hnode = math.floor(DATA.GUI.custom_gfx_h_effective/8)
      
      if DATA2.check_state==1 then backgr_col = '0xff0000' else backgr_col = '0x00b300' end
      DATA.GUI.buttons['action'] = { x=0,
                            y=0,
                            w=wnode*1.5-1,
                            h=DATA.GUI.custom_gfx_checkbuth-1,
                            txt = 'Run/Stop Check',
                            backgr_col = backgr_col,
                            backgr_fill = 0.6,
                            --txt_flags = 4,
                            txt_fontsz = DATA.GUI.custom_info_txtsz,
                            txt_a = txt_a,
                            onmouseclick = function() 
                              DATA2.check_trigger = true
                              DATA2.check_state = (DATA2.check_state or 0)~1
                              GUI_RESERVED_init(DATA)
                            end,}
                            
      local xoffs = 0
      local yoffs = 0
      for chan = 1, 64 do
        xoffs = wnode * ((chan-1)%8)
        yoffs = hnode * (math.floor(((chan-1)/8))%8)
        local txt_a
        if not DATA2.channels[chan] then txt_a = 0.1 end
        DATA.GUI.buttons['chan'..chan] = { x=xoffs,
                              y=DATA.GUI.custom_gfx_checkbuth+yoffs,
                              w=wnode-1,
                              h=hnode-1,
                              --frame_a = 0.2,
                              --[[backgr_col = '#333333',
                              backgr_fill = 1,
                              back_sela = 0,
                              
                              frame_asel = 0,]]
                              txt = DATA2.channels[chan] or chan,
                              --txt_flags = 4,
                              txt_fontsz = DATA.GUI.custom_info_txtsz,
                              txt_a = txt_a,
                              onmouseclick = function() 
                                DATA2.check_state = 0
                                DATA2.check_trigger = true
                                DATA2.set_input = chan-1
                                GUI_RESERVED_init(DATA)
                              end,}
      
      end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.0,true) if ret2 then main() end end
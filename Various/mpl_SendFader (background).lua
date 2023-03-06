-- @description SendFader
-- @version 2.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Rebuild using VariousFunctions framework
--    + Overall code cleanup, improve performance
--    # remove SWS dependency
--    + Allow to mark sends using external state right inside track chunk, so it is store with track template
--    + Allow to control multiple sends
--    - Remove solo buttons



  -- config defaults
  DATA2 = { latch_filt = {}
          }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '2.0'
    DATA.extstate.extstatesection = 'MPL_SendFader'
    DATA.extstate.mb_title = 'MPL SendFader'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  600,
                          wind_h =  480,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          
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
    DATA_RESERVED_ONPROJCHANGE(DATA)
    RUN()
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
    --for i = 1, #DATA2.sendtracks do end
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadProject_ReadSends()
    -- read sends
    DATA2.sendtracks = {}
    local id = 0
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local  retval, issend = reaper.GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', '', false )
      if retval and  issend and tonumber(issend) and tonumber(issend)  == 1 then issend = true else issend = false end
      local  retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if retval and issend==true then
        local retval, trname = GetTrackName( tr )
        id = id + 1
        DATA2.sendtracks[id] = {ptr=tr,GUID = GUID,name=trname,sendEQ={}}
        
        DATA2:ReadProject_ReadSends_readEQ(tr, DATA2.sendtracks[id].sendEQ)
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadProject_ReadSends_readEQ(dest_tr, sendEQ)
    if not sendEQ then return end
    local fx_cnt = TrackFX_GetCount( dest_tr )
    for fx_i = 1, fx_cnt do
      local _, fx_name = TrackFX_GetFXName( dest_tr, fx_i-1, '' )
      if (fx_name == 'PreEQ' or fx_name == 'PostEQ') then 
        local HP, LP
        for paramidx = 1, reaper.TrackFX_GetNumParams(dest_tr, fx_i-1 ) do
          local _, bandtype, _, paramtype, normval = reaper.TrackFX_GetEQParam( dest_tr, fx_i-1, paramidx-1 )
          if bandtype == 0 and paramtype == 0 then HP = normval end
          if bandtype == 5 and paramtype == 0 then LP = normval end
        end
        
        if HP and LP then 
          local val_POS = HP + (LP - HP)/2
          local val_WID = math.max(0,LP - HP)
          local key = 'pre'
          if fx_name == 'PostEQ' then key = 'post' end
          local GUID = TrackFX_GetFXGUID( dest_tr, fx_i-1)
          sendEQ[key] = {HP =  HP,
                        LP =  LP,
                        val_POS = val_POS,
                        val_WID = val_WID,
                        fxGUID=GUID}
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadProject()
    DATA2:ReadProject_ReadSends()
    DATA2:ReadProject_ReadTracks()
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadProject_ReadTracks()
    DATA2.tracks = {}
    DATA2.issendselected = false 
    
    local tr = GetSelectedTrack(0,0)
    if not tr then return end 
    local  retval, issend = reaper.GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', '', false )
    if retval and  issend and tonumber(issend) and tonumber(issend)  == 1 then issend = true else issend = false end
    local  retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
    local ret, name =  GetTrackName(tr)
    if issend==true then DATA2.issendselected = true return end
    
    
    -- read sends
    local sends = {}
    for sendidx = 1, GetTrackNumSends( tr, 0 ) do 
      local dest_trptr = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      local B_MUTE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MUTE' )
      local vol = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_VOL' )
      local B_MONO = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MONO' )
      local D_PAN = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_PAN' )
      local B_PHASE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_PHASE' )
      local I_SENDMODE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SENDMODE' )
      local I_AUTOMODE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_AUTOMODE' )
      if ValidatePtr(dest_trptr, 'MediaTrack*') then
        local retval, destGUID = reaper.GetSetMediaTrackInfo_String( dest_trptr, 'GUID', '', false )
        for i = 1, #DATA2.sendtracks do
          if DATA2.sendtracks[i].GUID == destGUID then
            sends[destGUID] = {
              vol=vol, 
              B_MUTE =B_MUTE,
              B_MONO =B_MONO,
              D_PAN =D_PAN,
              B_PHASE =B_PHASE,
              I_SENDMODE =I_SENDMODE,
              I_AUTOMODE =I_AUTOMODE,
              }
          end 
        end
      end
    end
    DATA2.tracks[1] = {
      ptr = tr,
      GUID=GUID,
      sends=sends,
      name =name,
      
      }
  end
  ---------------------------------------------------------------------  
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    DATA2:ReadProject()
    GUI_refresh(DATA)
  end
  ----------------------------------------------------------------------
  function DATA2:MarkSelectedTracksAsSend(set) 
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1) 
      if tr then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', set, true )end
    end
    DATA.UPD.onprojstatechange = true
  end
  ----------------------------------------------------------------------
  function GUI_RESERVED_init(DATA)
    DATA.GUI.buttons = {} 
    -- get globals
      local gfx_h = math.floor(gfx.h/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      local gfx_w = math.floor(gfx.w/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      DATA.GUI.custom_gfx_wreal = gfx_w
      DATA.GUI.custom_gfx_hreal = gfx_h 
      DATA.GUI.custom_referenceH = 300
      DATA.GUI.custom_Yrelation = math.max(gfx_h/DATA.GUI.custom_referenceH, 0.5) -- global W
      DATA.GUI.custom_Yrelation = math.min(DATA.GUI.custom_Yrelation, 1) -- global W
      DATA.GUI.custom_offset =  math.floor(2 * DATA.GUI.custom_Yrelation)
      --DATA.GUI.default_scale = 1
      
    -- init button stuff
      DATA.GUI.custom_infobuth =  math.floor(25*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_infobut_w =  math.floor(100*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_txtsz1 = math.floor(16*DATA.GUI.custom_Yrelation) -- menu
      DATA.GUI.custom_txta = 1
      DATA.GUI.custom_txta_disabled = 0.3
      DATA.GUI.custom_txt_trackinfoinit = '[track not selected]'
      DATA.GUI.custom_txt_trackinfoinit2 = '[send selected]'
      
    -- send control
      DATA.GUI.custom_sendctrl_nameh = math.floor(21*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_sendctrl_txtsz1 = math.floor(14*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_filter_centerH = math.floor(2*DATA.GUI.custom_Yrelation)
      
    -- send block
      DATA.GUI.custom_sendfaderH = DATA.GUI.custom_gfx_hreal - DATA.GUI.custom_sendctrl_nameh*8-DATA.GUI.custom_infobuth - DATA.GUI.custom_offset*3
      DATA.GUI.custom_sendfaderWmax = math.floor(80*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_sendfaderWmin = math.floor(30*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_fader_scale_lim = 0.8
      DATA.GUI.custom_fader_coeff = 30
      DATA.GUI.custom_txtsz_scalelevels = DATA:GUIdraw_txtCalibrateFont( DATA.GUI.default_txt_font, math.floor(14*DATA.GUI.custom_Yrelation), 0) 
    
    
      
    -- settings
      if not DATA.GUI.Settings_open then DATA.GUI.Settings_open = 0  end
      local x_offs = DATA.GUI.custom_offset
      DATA.GUI.buttons.settings = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_infobut_w-2,
                            h=DATA.GUI.custom_infobuth-1,
                            txt = '>',
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --frame_a = 0.3,
                            onmouseclick = function()
                              if DATA.GUI.Settings_open then DATA.GUI.Settings_open = math.abs(1-DATA.GUI.Settings_open) else DATA.GUI.Settings_open = 1 end 
                              DATA.UPD.onGUIinit = true
                            end,
                            }
      
      x_offs = x_offs + DATA.GUI.custom_infobut_w
      DATA.GUI.buttons.activetrack = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_gfx_wreal-x_offs-DATA.GUI.custom_offset*2-1,--DATA.GUI.custom_infobut_w*2-2,
                            h=DATA.GUI.custom_infobuth-1, 
                            txt = DATA.GUI.custom_txt_trackinfoinit,
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --txt_flags = 4,
                            --frame_a =0,
                            ignoremouse = true,
                            onmouseclick = function() end,
                            }      
     GUI_refresh(DATA)
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function GUI_RefreshreadOuts(DATA)
    if DATA2.tracks[1] then 
      DATA.GUI.buttons.activetrack.txt = DATA2.tracks[1].name
     else
      if DATA2.issendselected == true then 
        DATA.GUI.buttons.activetrack.txt = DATA.GUI.custom_txt_trackinfoinit2
       else
        DATA.GUI.buttons.activetrack.txt = DATA.GUI.custom_txt_trackinfoinit
      end
    end
  end
  ---------------------------------------------------------------------  
  function GUI_refresh(DATA)
    if DATA.GUI.buttons then
      GUI_MODULE_SETTINGS(DATA)
      GUI_RefreshreadOuts(DATA)
      GUI_MODULE_BuiildSends(DATA)
    end
     
    -- update buttons
    if not DATA.GUI.layers_refresh  then DATA.GUI.layers_refresh = {} end
    DATA.GUI.layers_refresh[2]=true 
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_SETTINGS(DATA)
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
      if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0 -- reset settings
      if DATA.GUI.Settings_open ==0 then return end 
      DATA.GUI.buttons.Rsettings = { x=0,
                            y=DATA.GUI.custom_infobuth + DATA.GUI.custom_offset,
                            w=gfx.w/DATA.GUI.default_scale,
                            h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_infobuth-DATA.GUI.custom_offset,
                            --txt = 'Settings',
                            frame_a = 0,
                            offsetframe = DATA.GUI.custom_offset,
                            offsetframe_a = 0.1,
                            ignoremouse = true,
                            refresh = true,
                            }
      DATA:GUIBuildSettings()
    end
    
  ---------------------------------------------------------------------  
  function GUI_MODULE_BuiildSends(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('fader_') then DATA.GUI.buttons[key] = nil end end 
    if not (DATA2.tracks[1] and DATA2.tracks[1].sends)then return end
    if DATA.GUI.Settings_open ==1 then return end 
    
    local cntsends = #DATA2.sendtracks
    local y_offs = DATA.GUI.custom_offset*2 + DATA.GUI.custom_infobuth
    local x_offs0 = DATA.GUI.custom_offset
    local faderW = math.min(DATA.GUI.custom_sendfaderWmax,(DATA.GUI.custom_gfx_wreal -DATA.GUI.custom_offset*2) /cntsends )
    local faderW = math.max(DATA.GUI.custom_sendfaderWmin,faderW)
    local faderH = DATA.GUI.custom_sendfaderH
    local faderW_scale = math.floor(faderW*0.8)
    
    for sendID = 1, cntsends do
      local destGUID = DATA2.sendtracks[sendID].GUID
      local vol = 0
      if DATA2.tracks[1].sends[destGUID] then vol = DATA2.tracks[1].sends[destGUID].vol end
      local val = DATA2:Convert_Val2Fader(vol)
      local x_offs = x_offs0 + faderW * (sendID-1)
      DATA.GUI.buttons['fader_'..sendID] = { x=x_offs+ faderW/2 - faderW_scale/2 ,
                            y=y_offs,
                            w=faderW_scale-DATA.GUI.custom_offset*2,--DATA.GUI.custom_infobut_w*2-2,
                            h=faderH-1,
                            val = val,
                            --txt = i,
                            --txt_fontsz = DATA.GUI.custom_txtsz1,
                            --txt_flags = 4,
                            frame_a =0.5,
                            onmousedrag = function() 
                              local sendIDx = DATA2:GetSendIdx(destGUID)
                              local outvol = DATA2:Convert_Fader2Val(DATA.GUI.buttons['fader_'..sendID].val)
                              SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( DATA2.tracks[1].ptr, sendIDx, outvol, 0)
                              DATA.GUI.buttons['fader_'..sendID].refresh = true
                            end,
                            onmouserelease = function() 
                              local sendIDx = DATA2:GetSendIdx(destGUID)
                              local outvol = DATA2:Convert_Fader2Val(DATA.GUI.buttons['fader_'..sendID].val)
                              SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( DATA2.tracks[1].ptr, sendIDx, outvol, 1)
                              DATA.UPD.onprojstatechange = true
                            end,
                            onmouseclickR = function()
                              local cur_dB = math.floor(  WDL_VAL2DB(DATA2.tracks[1].sends[destGUID].vol) *100)/100
                              local ret, str = GetUserInputs( 'set volume', 1, 'dB', cur_dB)
                              if not (ret and tonumber(str)) then return end
                              local dbval = tonumber(str)
                              if not ( dbval > -90 and dbval < 12) then return end
                              local sendIDx = DATA2:GetSendIdx(destGUID)
                              local outvol = WDL_DB2VAL(dbval)
                              SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( DATA2.tracks[1].ptr, sendIDx, outvol, 1 )
                              DATA.UPD.onprojstatechange = true 
                            end,
                            data = {fader_cust=true,destGUID=destGUID}
                            } 
      
      local y_offs = DATA.GUI.custom_offset*2 + DATA.GUI.custom_infobuth + faderH
      GUI_MODULE_BuiildSends_ControlStuff(DATA,sendID,destGUID,x_offs, y_offs, faderW,faderH)
    end
    
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_name(DATA,sendID,destGUID,srct,x,y,w,h) 
    local name= DATA2.sendtracks[sendID].name
    DATA.GUI.buttons['fader_'..sendID..'_name'] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = name,
      frame_a = 0,
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
    }
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_mute(DATA,sendID,destGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    if srct.B_MUTE==0 then txt_a = DATA.GUI.custom_txta_disabled  end
    DATA.GUI.buttons['fader_'..sendID..'_mute'] = { 
      x=x,--+ctrlbutw,
      y=y,
      w=w,
      h=h,
      txt = 'Mute', 
      txt_a=txt_a,
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID)
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'B_MUTE', srct.B_MUTE~1)
        DATA.UPD.onprojstatechange = true 
      end}
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_smode(DATA,sendID,destGUID,srct,x,y,w,h) 
    local modetxtx = '[unknown]'
    if srct.I_SENDMODE == 0 then modetxtx = 'PostFader'
    elseif srct.I_SENDMODE == 3 then modetxtx = 'PreFader'
    elseif srct.I_SENDMODE == 1 then modetxtx = 'PreFX'
    
    end
      
    DATA.GUI.buttons['fader_'..sendID..'_stype'] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      frame_a = 0,
      txt = modetxtx,
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      onmouserelease = function() 
        DATA:GUImenu(
          {
            {str='PostFader', func = function() local sendIDx = DATA2:GetSendIdx(destGUID) SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'I_SENDMODE', 0) DATA.UPD.onprojstatechange = true end},
            {str='PreFader', func = function() local sendIDx = DATA2:GetSendIdx(destGUID) SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'I_SENDMODE', 3) DATA.UPD.onprojstatechange = true end},
            {str='PreFX', func = function() local sendIDx = DATA2:GetSendIdx(destGUID) SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'I_SENDMODE', 1) DATA.UPD.onprojstatechange = true end},
          }
        )
      end 
    }
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_pan(DATA,sendID,destGUID,srct,x,y,w,h) 
    local val_txt = 'Center' if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'% Right' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'% Left' end 
    local destGUID = DATA2.sendtracks[sendID].GUID
    local pan = 0
    if DATA2.tracks[1].sends[destGUID] then pan = DATA2.tracks[1].sends[destGUID].pan end 
    DATA.GUI.buttons['fader_'..sendID..'_pan'] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = val_txt,
      --frame_a = 0,
      val=srct.D_PAN,
      val_centered = true,
      val_xaxis = true,
      val_res = -0.05,
      val_min = -1,
      val_max = 1,
      backgr_usevalue = true,
      backgr_col2='#FFFFFF',
      backgr_fill2 = 0.2,
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      onmousedrag = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID)
        local outpan = DATA.GUI.buttons['fader_'..sendID..'_pan'].val
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_PAN', outpan)
        SetTrackSendUIPan( DATA2.tracks[1].ptr, sendIDx, outpan, 0)
        srct.D_PAN=DATA.GUI.buttons['fader_'..sendID..'_pan'].val
        local val_txt = 'Center'   if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'% Right' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'% Left' end
        DATA.GUI.buttons['fader_'..sendID..'_pan'].txt=val_txt
        DATA.GUI.buttons['fader_'..sendID..'_pan'].refresh = true
      end,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID)
        local outpan = DATA.GUI.buttons['fader_'..sendID..'_pan'].val
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_PAN', outpan)
        SetTrackSendUIPan( DATA2.tracks[1].ptr, sendIDx, outpan, 1)
        srct.D_PAN=DATA.GUI.buttons['fader_'..sendID..'_pan'].val
        local val_txt = 'Center'   if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'% Right' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'% Left' end
        DATA.GUI.buttons['fader_'..sendID..'_pan'].txt=val_txt
        DATA.GUI.buttons['fader_'..sendID..'_pan'].refresh = true
        DATA.UPD.onprojstatechange = true
      end,
      
    }
  end
  -------------------------------------------------------------------- 
  function DATA2:SetData_SetReaEQLPHP(tr, fx, HP_freq, LP_freq)
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
  -------------------------------------------------------------------- 
  function DATA2:SetData_InitReaEQ(dest_tr, sendID) 
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
      DATA2:SetData_SetReaEQLPHP(dest_tr, new_fx_id, 0, 1)
      SetFXName(dest_tr, new_fx_id, 'PreEQ')
      TrackFX_SetOpen( dest_tr, new_fx_id, false ) 
    end
    
    if not haspost then
      local new_fx_id = TrackFX_AddByName( dest_tr, 'ReaEQ', false, -1 )
      DATA2:SetData_SetReaEQLPHP(dest_tr, new_fx_id, 0, 1)
      SetFXName(dest_tr, new_fx_id, 'PostEQ')
      TrackFX_SetOpen( dest_tr, new_fx_id, false ) 
    end
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x,y,w,h,ispost) 
    local sendIDx,dest_trptr = DATA2:GetSendIdx(destGUID)
    if not dest_trptr then return end
    
    -- define custom data values for filter slider
    local filtFpos
    local filtFwidth
    local key = 'pre'
    if ispost then key = 'post' end
    if not DATA2.sendtracks[sendID].sendEQ[key] then 
      filtFpos = 0.5
      filtFwidth = 1
     else
      filtFpos = DATA2.sendtracks[sendID].sendEQ[key].val_POS
      filtFwidth = DATA2.sendtracks[sendID].sendEQ[key].val_WID
    end
    local butkey = 'fader_'..sendID..'_'..key..'filter'
    DATA.GUI.buttons[butkey] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = key..'EQ',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      data = {slider_2dir = true,
              filtFpos=filtFpos,
              filtFwidth=filtFwidth,  },
      onmouseclick = function() 
        DATA2.latch_filt = {}
        if not DATA2.sendtracks[sendID].sendEQ[key] then 
          PreventUIRefresh( 1 )
          DATA2:SetData_InitReaEQ(dest_trptr, sendID)
          DATA2:ReadProject_ReadSends()
          PreventUIRefresh( -1 )
        end
        DATA2.latch_filt.pos = DATA2.sendtracks[sendID].sendEQ[key].val_POS
        DATA2.latch_filt.width = DATA2.sendtracks[sendID].sendEQ[key].val_WID
      end,
      onmousedrag = function() 
        if not (DATA2.latch_filt and DATA2.latch_filt.pos and DATA2.latch_filt.width) then return end
        local out_pos = DATA2.latch_filt.pos + 0.01*(DATA.GUI.dx/DATA.GUI.default_scale)
        local out_width = DATA2.latch_filt.width + 0.01*(DATA.GUI.dy/DATA.GUI.default_scale) 
        out_width = VF_lim(out_width,0.2,1) 
        out_pos = VF_lim(out_pos,out_width/2,1-out_width/2) 
        
        DATA.GUI.buttons[butkey].data.filtFpos = VF_lim(out_pos)
        DATA.GUI.buttons[butkey].data.filtFwidth = VF_lim(out_width)
        local ret,tr, fxID = VF_GetFXByGUID(DATA2.sendtracks[sendID].sendEQ[key].fxGUID, dest_trptr)
        if not ret then return end
        DATA2:SetData_SetReaEQLPHP(dest_trptr, fxID, VF_lim(out_pos-out_width/2), VF_lim(out_pos+out_width/2))
        DATA.GUI.layers_refresh[2]=true 
      end,
      onmouserelease = function()   
        if not (DATA2.latch_filt and DATA2.latch_filt.pos and DATA2.latch_filt.width) then return end
        DATA2.latch_filt = {}
        DATA2:ReadProject_ReadSends()
      end,
    }
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_FX(DATA,sendID,destGUID,srct,x,y,w,h) 
    DATA.GUI.buttons['fader_'..sendID..'_fx'] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = 'FX',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx,dest_trptr = DATA2:GetSendIdx(destGUID)
        TrackFX_Show( dest_trptr, 0, 1 )
      end,
    }
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_mono(DATA,sendID,destGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    if srct.B_MONO==0 then txt_a = DATA.GUI.custom_txta_disabled  end
    DATA.GUI.buttons['fader_'..sendID..'_mono'] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = 'Mono',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      txt_a=txt_a,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID)
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'B_MONO', srct.B_MONO~1)
        DATA.UPD.onprojstatechange = true 
      end,
    }
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff_phase(DATA,sendID,destGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    if srct.B_PHASE==0 then txt_a = DATA.GUI.custom_txta_disabled  end
    DATA.GUI.buttons['fader_'..sendID..'_phase'] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = 'Ø',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      txt_a=txt_a,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID)
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'B_PHASE', srct.B_PHASE~1)
        DATA.UPD.onprojstatechange = true 
      end,
    }
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuiildSends_ControlStuff(DATA,sendID,destGUID,x_offs, y_offs, faderW)
    local srct = DATA2.tracks[1].sends[destGUID]
    local act_w = faderW-DATA.GUI.custom_offset*2
    GUI_MODULE_BuiildSends_ControlStuff_name(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) 
    local ctrlbutw = math.floor(act_w/2) 
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh
    if srct then GUI_MODULE_BuiildSends_ControlStuff_mute(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) end
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuiildSends_ControlStuff_smode(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) end
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuiildSends_ControlStuff_pan(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) end
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuiildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuiildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1,true)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuiildSends_ControlStuff_FX(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuiildSends_ControlStuff_mono(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw-1,DATA.GUI.custom_sendctrl_nameh-1) end
    x_offs = x_offs + ctrlbutw 
    if srct then GUI_MODULE_BuiildSends_ControlStuff_phase(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw-1,DATA.GUI.custom_sendctrl_nameh-1) end
  end
  -------------------------------------------------------------------- 
  function DATA2:GetSendIdx(destGUID0)
    local dest_trptr
    -- get send id
    local tr = DATA2.tracks[1].ptr
    local sendidx_out
    for sendidx = 1, GetTrackNumSends( tr, 0 ) do 
      dest_trptr = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      if ValidatePtr(dest_trptr, 'MediaTrack*') then
        local retval, destGUID = reaper.GetSetMediaTrackInfo_String( dest_trptr, 'GUID', '', false )
        if destGUID == destGUID0 then sendidx_out = sendidx-1 break end
      end
    end
    if not sendidx_out then 
      dest_trptr = VF_GetMediaTrackByGUID(0,destGUID0)
      if ValidatePtr(dest_trptr, 'MediaTrack*') then 
        sendidx_out = CreateTrackSend( tr, dest_trptr ) 
        SetTrackSendInfo_Value( tr, 0, sendidx_out, 'D_VOL', 0 )
      end
    end
    return sendidx_out,dest_trptr
  end
  --[[
    if not sendidx_out then return end
    if not ValidatePtr(tr, 'MediaTrack*') then return end
    if paramtype == 'D_VOL' and normalized_val then SetTrackSendInfo_Value( tr, 0, sendidx_out, 'D_VOL', DATA2:Convert_Fader2Val(normalized_val)) end
    if paramtype == 'D_VOL' and reaper_val then SetTrackSendInfo_Value( tr, 0, sendidx_out, 'D_VOL', reaper_val) end
    if paramtype == 'B_MUTE' and toggle then SetTrackSendInfo_Value( tr, 0, sendidx_out, 'D_VOL', reaper_val) end
    
  end]]
  -------------------------------------------------------------------- 
  function DATA2:Convert_Fader2Val(fader_val)
    local fader_val = VF_lim(fader_val,0,1)
    local gfx_c, coeff = DATA.GUI.custom_fader_scale_lim,DATA.GUI.custom_fader_coeff 
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
  function DATA2:Convert_Val2Fader(rea_val)
    if not rea_val then return end 
    local rea_val = VF_lim(rea_val, 0, 4)
    local val 
    local gfx_c, coeff = DATA.GUI.custom_fader_scale_lim,DATA.GUI.custom_fader_coeff 
    local real_dB = 20*math.log(rea_val, 10)
    local lin2 = 10^(real_dB/coeff)  
    if lin2 <=1 then val = lin2*gfx_c else val = gfx_c + (real_dB/12)*(1-gfx_c) end
    if val > 1 then val = 1 end
    return VF_lim(val, 0.0001, 1)
  end
  ---------------------------------------------------------------------
  function GUI_RESERVED_draw_data_fader(DATA, b)
    if not b.data.destGUID then return end
    
    local x=b.x
    local y=b.y
    local w=b.w
    local h=b.h
    
    --[[local fader_norm = b.data.srct.vol
    if not fader_norm then return end
    fader_norm = DATA2:Convert_Val2Fader(fader_norm)]]
    local fader_norm = b.val
    
    -- define scale entries
      local t = { 
        '-40',
        '-18',
        '-6',
        '0',
        '+6',
        }  
    
    -- value
      DATA:GUIhex2rgb('#FFFFFF',true)
      gfx.a = 0.2
      local hfade = math.floor(h*fader_norm)
      gfx.rect(x,y+1+h-hfade,w,hfade,1)
    
    if b.w<=DATA.GUI.custom_sendfaderWmin then return end
    
    --line 
      DATA:GUIhex2rgb('#FFFFFF',true)
      gfx.a = 0.3
      gfx.line(x, y, x, y + h-1 )
    
    
    -- scale levels
      local line_w = 10
      local y_offsscale = 2
      gfx.a = 0.8
      for i = 1, #t do
        local t_val = tonumber(t[i])
        local rea_val = WDL_DB2VAL(t_val)
        local y1 = DATA2:Convert_Val2Fader(rea_val)
        if y1 < 0.004 then y1 = 0 end 
        gfx.setfont(1, DATA.GUI.default_txt_font, DATA.GUI.custom_txtsz_scalelevels)
        gfx.line(x, y+y_offsscale + h - h *y1, x+line_w/2, y+y_offsscale + h - h *y1)
        gfx.x = x + w - gfx.measurestr(t[i]..'dB') - 2
        gfx.y = y + h - h *y1- gfx.texth/2-1
        gfx.drawstr(t[i]..'dB')
      end
  end
  ---------------------------------------------------------------------
  function GUI_RESERVED_draw_data_filter(DATA, b)
    local pos = b.data.filtFpos
    local width = b.data.filtFwidth
    
    if not (pos and width )  then return end 
    local x0=b.x
    local y0=b.y
    local w=b.w
    local h0=b.h
    
    -- center line
      DATA:GUIhex2rgb('#FFFFFF',true)
      gfx.a = 0.2
      local xmid = math.ceil(x0+ pos*w)
      gfx.line(xmid,y0,xmid,y0+DATA.GUI.custom_filter_centerH)
      gfx.line(xmid,y0+h0-1,xmid,y0+h0+1-DATA.GUI.custom_filter_centerH)
      gfx.rect(xmid-w*width/2,y0,math.ceil(w*width),h0,1)
      
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_draw_data(DATA, b)
    if not b.data then return end 
    
    if b.data.slider_2dir then GUI_RESERVED_draw_data_filter(DATA, b) end
    if b.data.fader_cust then GUI_RESERVED_draw_data_fader(DATA, b) end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
    
    local  t = 
    { 
      {str = 'General' ,                                        group = 1, itype = 'sep'},
        {str = 'Preset',                                        group = 1, itype = 'button', level = 1, func_onrelease = function() DATA:GUIbut_preset() end},
        {str = '[Action] Mark selected tracks as send',         group = 1, itype = 'button', level = 1, func_onrelease = function() DATA2:MarkSelectedTracksAsSend(1) end},
        {str = '[Action] Unmark selected tracks as send',         group = 1, itype = 'button', level = 1, func_onrelease = function() DATA2:MarkSelectedTracksAsSend(0) end},
        
        --[[{str = 'Float RS5k instance',                           group = 1, itype = 'check', confkey = 'CONF_onadd_float', level = 1},
        {str = 'Set obey notes-off',                            group = 1, itype = 'check', confkey = 'CONF_onadd_obeynoteoff', level = 1},
        {str = 'Rename track',                                  group = 1, itype = 'check', confkey = 'CONF_onadd_renametrack', level = 1},
        {str = 'Copy samples to project path',                  group = 1, itype = 'check', confkey = 'CONF_onadd_copytoprojectpath', level = 1},
        {str = 'Custom track template: '..customtemplate,       group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() local retval, fp = GetUserFileNameForRead('', 'FX chain for newly dragged samples', 'RTrackTemplate') if retval then DATA.extstate.CONF_onadd_customtemplate=  fp GUI_MODULE_SETTINGS(DATA) end end},
        {str = 'Custom track template [clear]',                  group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() DATA.extstate.CONF_onadd_customtemplate=  '' GUI_MODULE_SETTINGS(DATA) end},
        
      {str = 'MIDI bus',                                        group = 2, itype = 'sep'}, 
        {str = 'MIDI bus default input',                        group = 2, itype = 'readout', confkey = 'CONF_midiinput', level = 1, menu = {[63]='All inputs',[62]='Virtual keyboard'},readoutw_extw = readoutw_extw},
        {str = 'MIDI bus channel',                        group = 2, itype = 'readout', confkey = 'CONF_midichannel', level = 1, menu = {[0]='All channels',[1]='Channel 1',[2]='Channel 2',[3]='Channel 3',[4]='Channel 4',[5]='Channel 5',[6]='Channel 6',[7]='Channel 7',[8]='Channel 8',[9]='Channel 9',[10]='Channel 10',
        [11]='Channel 11',[12]='Channel 12',[13]='Channel 13',[14]='Channel 14',[15]='Channel 15',[16]='Channel 16'},readoutw_extw = readoutw_extw},
        {str = 'Initialize MIDI bus',                           group = 2, itype = 'button', level = 1, func_onrelease = function() DATA2:TrackDataRead_ValidateMIDIbus() end},
        
      {str = 'UI',                                              group = 3, itype = 'sep'},
        {str = 'Active note follow incoming note',              group = 3, itype = 'check', confkey = 'UI_incomingnoteselectpad', level = 1},
        {str = 'Key format',                                    group = 3, itype = 'readout', confkey = 'UI_keyformat_mode', level = 1,menu = {[0]='C-C#-D',[2]='Do-Do#-Re',[7]='Russian'}},
        {str = 'Pad overview quantize',                         group = 3, itype = 'readout', confkey = 'UI_po_quantizemode', level = 1, menu = {[0]='Default',[1]='8 pads', [2]='4 pads'},readoutw_extw = readoutw_extw}, 
        {str = 'Undo tab state change',                         group = 3, itype = 'check', confkey = 'UI_addundototabclicks', level = 1,}, 
        {str = 'Drumrack: Click on pad select track',           group = 3, itype = 'check', confkey = 'UI_clickonpadselecttrack', level = 1},
      
      {str = 'Tab defaults',                                    group = 6, itype = 'sep'},
        {str = 'Drumrack',                                      group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 0},
        {str = 'Device',                                        group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 1},
        {str = 'Sampler',                                       group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 2},
        {str = 'Padview',                                       group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 3},
        --{str = 'Tab defaults: macro',                           group = 3, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 4},
        {str = 'Database',                                      group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 5},
        {str = 'MIDI / OSC learn',                              group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 6},
        {str = 'Children chain',                                group = 6, itype = 'check', confkey = 'UI_defaulttabsflags', level = 1, confkeybyte = 7},
      
      {str = 'Various',                                         group = 5, itype = 'sep'},    
        {str = 'Sampler: Crop threshold',                       group = 5, itype = 'readout', confkey = 'CONF_cropthreshold', level = 1, menu = {[-80]='-80dB',[-60]='-60dB', [-40]='-40dB',[-30]='-30dB'},readoutw_extw = readoutw_extw},
        
  ]]
        
    } 
    return t
    
  end    
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.57) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end

-- @description SendFader
-- @version 2.09
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @provides
--    mpl_SendFader_Mark selected tracks as sends.lua
-- @changelog
--    + Settings: allow to display regular sends and/or marked sends
--    # Settings: cleanup



  -- config defaults
  DATA2 = { latch_filt = {},
            tracks = {},
            sendtracks={},
            peaks={},
            scroll_x=0,
            scroll_w=1,
          }
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '2.09'
    DATA.extstate.extstatesection = 'MPL_SendFader'
    DATA.extstate.mb_title = 'MPL SendFader'
    DATA.extstate.default = 
                          {
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  600,
                          wind_h =  480,
                          dock =    0,
                          
                          FPRESET1 = 'CkNPTkZfTkFNRT1kZWZhdWx0CkNPTkZfZGVmaW5lYnlncm91cD1hdXgsc2VuZApDT05GX2RlZmluZWJ5bmFtZT1hdXgsc2VuZA==',
                          
                          CONF_NAME = 'default',
                          CONF_definebyname = 'aux,send',
                          CONF_definebygroup = 'aux,send',
                          CONF_marksendint = 1,
                          CONF_marksendregular = 1,
                          CONF_marksendwordsmatch = 1,
                          CONF_marksendparentwordsmatch = 1,
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          UI_showsendrecnamevertically = 0, 
                          
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
    DATA.GUI.shortcuts2= {
      custom = {}--{['Space']='_RSfc6990bed179e8ecd167f17a2ca833b0a3e04af7'}
                          } -- use shortcuts handling
    RUN()
  end
  ----------------------------------------------------------------------
  function GUI_RESERVED_drawDYN(DATA)
    if not DATA.GUI.buttons then return end
    
    if not DATA2.issendselected then
      for sendID = 1, #DATA2.sendtracks do 
        if DATA.GUI.buttons['fader_send'..sendID] and DATA2.peaks[sendID] and #DATA2.peaks[sendID] > 4 then
          local obj = DATA.GUI.buttons['fader_send'..sendID]
          local x=obj.x*DATA.GUI.default_scale
          local y=obj.y*DATA.GUI.default_scale
          local w=DATA.GUI.custom_meterW*DATA.GUI.default_scale--obj.w
          local h=obj.h*DATA.GUI.default_scale
          gfx.a=0.5
          local trcol = DATA2.sendtracks[sendID].col
          if trcol then 
            local r, g, b = reaper.ColorFromNative( trcol )
            gfx.set(r/255,g/255,b/255)
          end
          local sz = #DATA2.peaks[sendID]
          local L = (DATA2.peaks[sendID][sz][1] + DATA2.peaks[sendID][sz-1][1]+ DATA2.peaks[sendID][sz-2][1]+ DATA2.peaks[sendID][sz-3][1]) /4
          local R = (DATA2.peaks[sendID][sz][2] + DATA2.peaks[sendID][sz-1][2]+ DATA2.peaks[sendID][sz-2][2]+ DATA2.peaks[sendID][sz-3][2]) /4
          gfx.rect(x,y+h-h*L,w,h*L,1)
          gfx.rect(x+w,y+h-h*R,w,h*R,1)
        end
      end
    end
    
    if DATA2.issendselected ==true then
      for recGUID in pairs(DATA2.tracks[1].receives) do 
        if DATA.GUI.buttons['fader_rec'..recGUID] and DATA2.peaks[recGUID] and #DATA2.peaks[recGUID] > 4 then
          local obj = DATA.GUI.buttons['fader_rec'..recGUID]
          local x=obj.x*DATA.GUI.default_scale
          local y=obj.y*DATA.GUI.default_scale
          local w=DATA.GUI.custom_meterW*DATA.GUI.default_scale--obj.w
          local h=obj.h*DATA.GUI.default_scale
          gfx.a=0.5
          local trcol = DATA2.tracks[1].receives[recGUID].trcol
          if trcol then 
            local r, g, b = reaper.ColorFromNative( trcol )
            gfx.set(r/255,g/255,b/255)
          end
          local sz = #DATA2.peaks[recGUID]
          local L = (DATA2.peaks[recGUID][sz][1] + DATA2.peaks[recGUID][sz-1][1]+ DATA2.peaks[recGUID][sz-2][1]+ DATA2.peaks[recGUID][sz-3][1]) /4
          local R = (DATA2.peaks[recGUID][sz][2] + DATA2.peaks[recGUID][sz-1][2]+ DATA2.peaks[recGUID][sz-2][2]+ DATA2.peaks[recGUID][sz-3][2]) /4
          gfx.rect(x,y+h-h*L,w,h*L,1)
          gfx.rect(x+w,y+h-h*R,w,h*R,1)
        end
      end
    end
    
    
    
    if DATA.GUI.buttons['activetrack'] and DATA2.peaks[0] and #DATA2.peaks[0] > 4 then
      local obj = DATA.GUI.buttons['activetrack']
      local x=obj.x*DATA.GUI.default_scale
      local y=obj.y*DATA.GUI.default_scale
      local w=obj.w*DATA.GUI.default_scale--DATA.GUI.custom_meterW*DATA.GUI.default_scale--*DATA.GUI.default_scale-obj.w
      local h=obj.h*DATA.GUI.default_scale
      gfx.a=0.4
      local sz = #DATA2.peaks[0]
      local L = (DATA2.peaks[0][sz][1] + DATA2.peaks[0][sz-1][1]+ DATA2.peaks[0][sz-2][1]+ DATA2.peaks[0][sz-3][1]) /4
      local R = (DATA2.peaks[0][sz][2] + DATA2.peaks[0][sz-1][2]+ DATA2.peaks[0][sz-2][2]+ DATA2.peaks[0][sz-3][2]) /4
      local h2 = math.floor(h/2)
      gfx.rect(x,y,w*L,h2,1)
      gfx.rect(x,y+h2,w*R,h2,1)
    end
    
  end
  ----------------------------------------------------------------------
  function DATA2:DYNUPDATE_peaks()
    local max_cnt = 5
    local mult = 1/6
    
    if DATA2.issendselected and DATA2.tracks[1] and DATA2.tracks[1].receives then
      for recGUID in pairs(DATA2.tracks[1].receives) do 
        if not DATA2.peaks[recGUID] then DATA2.peaks[recGUID] = {} end
        if not DATA2.tracks[1].receives[recGUID].srcptr or (DATA2.tracks[1].receives[recGUID].srcptr and not ValidatePtr(DATA2.tracks[1].receives[recGUID].srcptr, '*MediaTrack')) then
          DATA2.tracks[1].receives[recGUID].srcptr = VF_GetMediaTrackByGUID(0,recGUID)
        end
        local tr = DATA2.tracks[1].receives[recGUID].srcptr
        local peakL = Track_GetPeakInfo( tr, 0 )
        local peakR = Track_GetPeakInfo( tr, 1 )
        DATA2.peaks[recGUID][#DATA2.peaks[recGUID]+1] = {DATA2:Convert_Val2Fader(peakL),DATA2:Convert_Val2Fader(peakR)}
        if #DATA2.peaks[recGUID] > max_cnt then table.remove(DATA2.peaks[recGUID] ,1) end
      end
    end
    
    if not DATA2.issendselected ==true then
      for sid = 1, #DATA2.sendtracks do 
        if not DATA2.peaks[sid] then DATA2.peaks[sid] = {} end
        local tr = DATA2.sendtracks[sid].ptr
        local peakL = Track_GetPeakInfo( tr, 0 )
        local peakR = Track_GetPeakInfo( tr, 1 )
        DATA2.peaks[sid][#DATA2.peaks[sid]+1] = {DATA2:Convert_Val2Fader(peakL),DATA2:Convert_Val2Fader(peakR)}
        if #DATA2.peaks[sid] > max_cnt then table.remove(DATA2.peaks[sid] ,1) end
      end
    end
    
    if DATA2.tracks[1] then 
      local tr = DATA2.tracks[1].ptr
      if not DATA2.peaks[0] then DATA2.peaks[0] = {} end
      local peakL = Track_GetPeakInfo( tr, 0 )
      local peakR = Track_GetPeakInfo( tr, 1 )
      DATA2.peaks[0][#DATA2.peaks[0]+1] =  {DATA2:Convert_Val2Fader(peakL),DATA2:Convert_Val2Fader(peakR)}
      if #DATA2.peaks[0] > max_cnt then table.remove(DATA2.peaks[0] ,1) end
    end
    
  end
  
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
    DATA2:DYNUPDATE_peaks()
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadProject_ReadSends_IsSend(tr,names_group,names_track)
    local issend
    
    -- regular send
    if DATA.extstate.CONF_marksendregular ==1 then
      local partr = GetSelectedTrack(0,0)
      if partr then
        for sendidx=1, reaper.GetTrackNumSends( tr, -1 ) do
          if reaper.GetTrackSendInfo_Value( tr, -1, sendidx-1, 'P_SRCTRACK' ) == partr then issend= true end
        end
      end
    end
    
    -- extaernal state marked
      if DATA.extstate.CONF_marksendint == 1 then
         retval, issend = reaper.GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', '', false )
        if retval and  issend and tonumber(issend) and tonumber(issend)  == 1 then issend = true else issend = false end
      end      
    
    -- check name 
      local matchname
      if DATA.extstate.CONF_marksendwordsmatch == 1 then 
        local retval, sendname = reaper.GetTrackName( tr )
        local ispath =  GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' ) 
        if ispath~=1 and not sendname:match('Track') then
          for sendnameID = 1, #names_track do 
            if sendname:lower():match(names_track[sendnameID]:lower()) then
              matchname = true break
            end
          end
        end
      end
      
    -- check fold name 
      local matchparent
      if DATA.extstate.CONF_marksendparentwordsmatch == 1 then 
        local par_track = GetParentTrack( tr ) 
        if par_track and ispath~=1 then
          local retval, parname = GetTrackName( par_track )
          for sendnameID = 1, #names_group do 
            if parname:lower():match(names_group[sendnameID]:lower()) then
              matchparent = true break
            end
          end
        end
      end
      
    return issend==true or matchname==true or matchparent==true, name
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadProject_ReadSends()
    local CONF_definebygroup = tostring(DATA.extstate.CONF_definebygroup)
    local CONF_definebyname = tostring(DATA.extstate.CONF_definebyname)
    -- parse group names
      local names_group = {cached=true} 
      if CONF_definebygroup ~= '' then
        for word in CONF_definebygroup:gmatch('[^,]+') do names_group[#names_group+1]=word end
      end
    -- parse group names
      local names_track = {} 
      if CONF_definebyname ~= '' then
        for word in CONF_definebyname:gmatch('[^,]+') do names_track[#names_track+1]=word end
      end
      
    -- read sends
    DATA2.sendtracks = {}
    local id = 0
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local issend,name,isinternal = DATA2:ReadProject_ReadSends_IsSend(tr,names_group,names_track)
      if issend == true then
        local retval, trname = GetTrackName( tr )
        id = id + 1
        local  retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
        
        local  retval, issend = reaper.GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', '', false )
        if retval and  issend and tonumber(issend) and tonumber(issend)  == 1 then issend = true else issend = false end
        if issend ==true then trname='['..trname..']' end
        DATA2.sendtracks[id] = {ptr=tr,GUID = GUID,name=trname,sendEQ={},col =  GetTrackColor( tr ),isinternal=isinternal} 
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
  function DATA2:ReadProject_ReadTracks_Sends(tr)
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
    return sends
  end
  ---------------------------------------------------------------------  
  function DATA2:ReadProject_ReadTracks_Receives(tr)
    -- read receives
    local receives = {}
    for sendidx = 1, GetTrackNumSends( tr, -1 ) do 
      local src_trptr = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'P_SRCTRACK' )
      local B_MUTE = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'B_MUTE' )
      local vol = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'D_VOL' )
      local B_MONO = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'B_MONO' )
      local D_PAN = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'D_PAN' )
      local B_PHASE = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'B_PHASE' )
      local I_SENDMODE = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'I_SENDMODE' )
      local I_AUTOMODE = GetTrackSendInfo_Value( tr, -1, sendidx-1, 'I_AUTOMODE' )
      local trcol = GetTrackColor( src_trptr )
      if ValidatePtr(src_trptr, 'MediaTrack*') then
        local retval, srcGUID = reaper.GetSetMediaTrackInfo_String( src_trptr, 'GUID', '', false )
        local retval, srcname = reaper.GetSetMediaTrackInfo_String( src_trptr, 'P_NAME', '', false )
        
        receives[srcGUID] = {
              vol=vol, 
              B_MUTE =B_MUTE,
              B_MONO =B_MONO,
              D_PAN =D_PAN,
              B_PHASE =B_PHASE,
              I_SENDMODE =I_SENDMODE,
              I_AUTOMODE =I_AUTOMODE,
              srcname = srcname,
              trcol=trcol,
              }
      end
    end
    return receives
  end
  
  
  ---------------------------------------------------------------------  
  function DATA2:ReadProject_ReadTracks()
  
    DATA2.tracks = {}
    DATA2.issendselected = false 
    
    local CONF_definebygroup = tostring(DATA.extstate.CONF_definebygroup)
    local CONF_definebyname = tostring(DATA.extstate.CONF_definebyname)
    
    -- parse group names
      local names_group = {cached=true} 
      if CONF_definebygroup ~= '' then
        for word in CONF_definebygroup:gmatch('[^,]+') do names_group[#names_group+1]=word end
      end
      
    -- parse group names
      local names_track = {} 
      if CONF_definebyname ~= '' then
        for word in CONF_definebyname:gmatch('[^,]+') do names_track[#names_track+1]=word end
      end
      
    local tr = GetSelectedTrack(0,0)
    if not tr then return end 
    local issend,name = DATA2:ReadProject_ReadSends_IsSend(tr,names_group,names_track)
    local  retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
    local ret, name =  GetTrackName(tr)
    DATA2.tracks[1] = {
      ptr = tr,
      GUID=GUID, 
      name =name,
      
      }
    
    if issend==true then 
      DATA2.issendselected = true 
      DATA2.tracks[1].receives=DATA2:ReadProject_ReadTracks_Receives(tr)
     else  
      DATA2.tracks[1].sends=DATA2:ReadProject_ReadTracks_Sends(tr)
    end 
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
      DATA.GUI.custom_scrollH =  math.floor(10 * DATA.GUI.custom_Yrelation)
      --DATA.GUI.default_scale = 1
      
    -- init button stuff
      DATA.GUI.custom_infobuth =  math.floor(25*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_infobut_w =  math.floor(100*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_txtsz1 = math.floor(16*DATA.GUI.custom_Yrelation) -- menu
      DATA.GUI.custom_txta = 1
      DATA.GUI.custom_txta_disabled = 0.3
      DATA.GUI.custom_txt_trackinfoinit = '[track not selected]'
      DATA.GUI.custom_txt_trackinfoinit2 = '[receive track selected]'
      
    -- send control
      DATA.GUI.custom_sendctrl_nameh = math.floor(21*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_sendctrl_txtsz1 = math.floor(14*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_filter_centerH = math.floor(2*DATA.GUI.custom_Yrelation)
      
    -- send block
      DATA.GUI.custom_sendfaderH = DATA.GUI.custom_gfx_hreal - DATA.GUI.custom_sendctrl_nameh*8-DATA.GUI.custom_infobuth - DATA.GUI.custom_offset*3
      if DATA.extstate.UI_showsendrecnamevertically == 1 then DATA.GUI.custom_sendfaderH = DATA.GUI.custom_gfx_hreal - DATA.GUI.custom_sendctrl_nameh*7-DATA.GUI.custom_infobuth - DATA.GUI.custom_offset*3 end
      DATA.GUI.custom_sendfaderW = math.floor(90*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_sendfaderWmin = math.floor(90*DATA.GUI.custom_Yrelation)
      DATA.GUI.custom_fader_scale_lim = 0.8
      DATA.GUI.custom_fader_coeff = 30
      DATA.GUI.custom_txtsz_scalelevels = DATA:GUIdraw_txtCalibrateFont( DATA.GUI.default_txt_font, math.floor(14*DATA.GUI.custom_Yrelation), 0) 
    
    -- main control
      --DATA.GUI.custom_vcaW = math.floor(20*DATA.GUI.custom_Yrelation)
      
    -- meters
      DATA.GUI.custom_meterW = math.floor(5*DATA.GUI.custom_Yrelation)
      
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
                            data = {fader_vca=true}
                            }   
                            
      DATA.GUI.buttons.horizscroll = { x=0,
                            y=DATA.GUI.custom_gfx_hreal-DATA.GUI.custom_scrollH,
                            w=DATA.GUI.custom_gfx_wreal-1,--DATA.GUI.custom_infobut_w*2-2,
                            h=DATA.GUI.custom_scrollH-1, 
                            data = {horslider = true},
                            frame_a =0.3,
                            val = 0,
                            val_xaxis = true,
                            val_res = -1,
                            onmousedrag = function()
                              DATA2.scroll_x = DATA.GUI.buttons.horizscroll.val
                              GUI_refresh(DATA)
                            end
                            
                            }


                            
     GUI_refresh(DATA)
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function GUI_RefreshreadOuts(DATA)
    if not (DATA2.tracks  and DATA2.tracks[1]) then return end
    if not (DATA.GUI.custom_txt_trackinfoinit2 and DATA.GUI.buttons.activetrack) then return end
    if DATA2.tracks[1] and not DATA2.issendselected == true then 
      DATA.GUI.buttons.activetrack.txt = DATA2.tracks[1].name
     else
      DATA.GUI.buttons.activetrack.txt = DATA.GUI.custom_txt_trackinfoinit2..': '..DATA2.tracks[1].name
    end
  end
  ---------------------------------------------------------------------  
  function GUI_refresh(DATA)
    if DATA.GUI.buttons then
      GUI_MODULE_SETTINGS(DATA)
      GUI_RefreshreadOuts(DATA)
      GUI_MODULE_BuildSends(DATA)
      GUI_MODULE_BuildReceives(DATA)
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
    

  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildReceives_ControlStuff(DATA,receiveGUID,x_offs0, y_offs, faderW)
    local srct = DATA2.tracks[1].receives[receiveGUID]
    local act_w = faderW-DATA.GUI.custom_offset*2
    local ctrlbutw = math.floor(act_w/2) 
    local x_offs = x_offs0
    GUI_MODULE_BuildReceives_ControlStuff_name(DATA,receiveGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1,srct.srcname) 
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh
    if srct then GUI_MODULE_BuildReceives_ControlStuff_mute(DATA,receiveGUID,srct,x_offs,y_offs,ctrlbutw,DATA.GUI.custom_sendctrl_nameh-1) end
    x_offs = x_offs + ctrlbutw 
    if srct then GUI_MODULE_BuildReceives_ControlStuff_remove(DATA,receiveGUID,srct,x_offs,y_offs,ctrlbutw,DATA.GUI.custom_sendctrl_nameh-1) end
    x_offs = x_offs0
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuildReceives_ControlStuff_smode(DATA,receiveGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) end
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuildReceives_ControlStuff_pan(DATA,receiveGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) end
    --[[y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1,true)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuildSends_ControlStuff_FX(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuildSends_ControlStuff_mono(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw-1,DATA.GUI.custom_sendctrl_nameh-1) end
    x_offs = x_offs + ctrlbutw 
    if srct then GUI_MODULE_BuildSends_ControlStuff_phase(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw-1,DATA.GUI.custom_sendctrl_nameh-1) end
    ]]
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildReceives_ControlStuff_name(DATA,receiveGUID,srct,x,y,w,h, name) 
    local key = 'fader_rec'..receiveGUID..'_name'
    DATA.GUI.buttons[key] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = name,
      frame_a = 0,
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      onmouseclick = function()
        if DATA.GUI.Alt == true then
          local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
          reaper.SetOnlyTrackSelected( srctr)
          DATA.UPD.onprojstatechange = true 
        end
      end,
    }
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildReceives_ControlStuff_mute(DATA,receiveGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    if srct.B_MUTE==0 then txt_a = DATA.GUI.custom_txta_disabled  end
    local key = 'fader_rec'..receiveGUID..'_mute'
    DATA.GUI.buttons[key] = { 
      x=x,--+ctrlbutw,
      y=y,
      w=w,
      h=h,
      txt = 'Mute', 
      txt_a=txt_a,
      txt_col = '#FF0000',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
        SetTrackSendInfo_Value( srctr, 0, sendIDx, 'B_MUTE', srct.B_MUTE~1)
        DATA.UPD.onprojstatechange = true 
      end}
      --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildReceives_ControlStuff_remove(DATA,receiveGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    local key = 'fader_rec'..receiveGUID..'_remove'
    DATA.GUI.buttons[key] = { 
      x=x,--+ctrlbutw,
      y=y,
      w=w,
      h=h,
      txt = 'X', 
      txt_a=txt_a,
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
        RemoveTrackSend(srctr, 0, sendIDx )
        DATA.UPD.onprojstatechange = true 
      end}
      --DATA.GUI.buttons[key].hide = DATA.GUI.buttons['fader_rec'..receiveGUID..'_mute'].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildReceives_ControlStuff_smode(DATA,receiveGUID,srct,x,y,w,h) 
    local modetxtx = '[unknown]'
    if srct.I_SENDMODE == 0 then modetxtx = 'PostFader'
    elseif srct.I_SENDMODE == 3 then modetxtx = 'PreFader'
    elseif srct.I_SENDMODE == 1 then modetxtx = 'PreFX'
    
    end
    local key = 'fader_rec'..receiveGUID..'_stype'
    DATA.GUI.buttons[key] = { 
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
            {str='PostFader', func = function() local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID) SetTrackSendInfo_Value( srctr, 0, sendIDx, 'I_SENDMODE', 0) DATA.UPD.onprojstatechange = true end},
            {str='PreFader', func = function() local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID) SetTrackSendInfo_Value( srctr, 0, sendIDx, 'I_SENDMODE', 3) DATA.UPD.onprojstatechange = true end},
            {str='PreFX', func = function() local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID) SetTrackSendInfo_Value( srctr, 0, sendIDx, 'I_SENDMODE', 1) DATA.UPD.onprojstatechange = true end},
          }
        )
      end 
    }
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildReceives_ControlStuff_pan(DATA,receiveGUID,srct,x,y,w,h) 
    local val_txt = 'Center' if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'%R' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'%L' end 
    local pan = 0
    if DATA2.tracks[1].receives[receiveGUID] then pan = DATA2.tracks[1].receives[receiveGUID].D_PAN end 
    local key = 'fader_rec'..receiveGUID..'_pan'
    DATA.GUI.buttons[key] = { 
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
        local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
        local outpan = DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].val
        SetTrackSendInfo_Value( srctr, 0, sendIDx, 'D_PAN', outpan)
        SetTrackSendUIPan( srctr, sendIDx, outpan, 0)
        srct.D_PAN=DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].val
        local val_txt = 'Center'   if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'%R' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'%L' end
        DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].txt=val_txt
        DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].refresh = true
      end,
      onmouserelease = function() 
        local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
        local outpan = DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].val
        if DATA.GUI.Alt == true then outpan = 0 end
        SetTrackSendInfo_Value( srctr, 0, sendIDx, 'D_PAN', outpan)
        SetTrackSendUIPan( srctr, sendIDx, outpan, 1)
        srct.D_PAN=DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].val
        local val_txt = 'Center'   if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'%R' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'%L' end
        DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].txt=val_txt
        DATA.GUI.buttons['fader_rec'..receiveGUID..'_pan'].refresh = true
        DATA.UPD.onprojstatechange = true
      end,
      onmouseclickR = function() 
        local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
        local cur_pan = math.floor( DATA2.tracks[1].receives[receiveGUID].D_PAN *100)
        local ret, outpan = GetUserInputs( 'set pan', 1, '%', cur_pan)
        if not (ret and tonumber(outpan)) then return end
        outpan = tonumber(outpan)
        if ( outpan > 100 or outpan < -100) then return end
        SetTrackSendInfo_Value( srctr, 0, sendIDx, 'D_PAN', outpan/100)
        SetTrackSendUIPan( srctr, sendIDx, outpan, 1)
        DATA.UPD.onprojstatechange = true 
      end,
    }
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_BuildReceives(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('fader_rec') then DATA.GUI.buttons[key] = nil end end 
    if not (DATA2.tracks and DATA2.tracks[1] and DATA2.tracks[1].receives) then return end
    if DATA.GUI.Settings_open ==1 then return end 
    
    local cntreceives = 0
    for receiveID in pairs(DATA2.tracks[1].receives) do cntreceives = cntreceives + 1 end
    local x_offs0 = DATA.GUI.custom_offset--*2+DATA.GUI.custom_vcaW
    local faderareaW = (DATA.GUI.custom_gfx_wreal-DATA.GUI.custom_offset*2) -- -DATA.GUI.custom_vcaW
    --local faderW = math.min(DATA.GUI.custom_sendfaderWmax, math.floor(faderareaW/cntreceives ))
    local faderW = DATA.GUI.custom_sendfaderW
    --local faderW = math.max(DATA.GUI.custom_sendfaderWmin,faderW)
    local faderH = DATA.GUI.custom_sendfaderH-DATA.GUI.custom_scrollH
    local faderW_scale = faderW--math.floor(faderW*0.8) 
    local y_offs = DATA.GUI.custom_gfx_hreal - faderH-DATA.GUI.custom_scrollH-DATA.GUI.custom_offset--DATA.GUI.custom_offset*2 + DATA.GUI.custom_infobuth
    
    
    DATA2.scroll_w = math.min(1,faderareaW / (faderW_scale * cntreceives ))
    local x_shift = -DATA2.scroll_x*((faderW_scale * cntreceives ) - faderareaW)
    if DATA2.scroll_w == 1 then x_shift = 0 end
    
    local recID = 0
    for receiveGUID in spairs(DATA2.tracks[1].receives) do
      recID = recID + 1
      local vol,trcol = 0,0
      if DATA2.tracks[1].receives[receiveGUID].vol then vol = DATA2.tracks[1].receives[receiveGUID].vol end
      if DATA2.tracks[1].receives[receiveGUID].trcol then trcol = DATA2.tracks[1].receives[receiveGUID].trcol end
      local val = DATA2:Convert_Val2Fader(vol)
      local x_offs = x_offs0 + faderW * (recID-1)
      DATA.GUI.buttons['fader_rec'..receiveGUID] = { x=x_offs+ faderW/2 - faderW_scale/2 +x_shift,
                            y=y_offs,
                            w=faderW_scale-DATA.GUI.custom_offset*2,--DATA.GUI.custom_infobut_w*2-2,
                            h=faderH-1,
                            val = val,
                            --txt = i,
                            --txt_fontsz = DATA.GUI.custom_txtsz1,
                            --txt_flags = 4,
                            frame_a =0.5,
                            onmousedrag = function() 
                              local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
                              local outvol = DATA2:Convert_Fader2Val(DATA.GUI.buttons['fader_rec'..receiveGUID].val)
                              SetTrackSendInfo_Value( srctr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( srctr, sendIDx, outvol, 0)
                              DATA.GUI.buttons['fader_rec'..receiveGUID].refresh = true
                            end,
                            onmouserelease = function() 
                              local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
                              local outvol = DATA2:Convert_Fader2Val(DATA.GUI.buttons['fader_rec'..receiveGUID].val)
                              if DATA.GUI.Alt == true then outvol = 0 end
                              SetTrackSendInfo_Value(srctr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( srctr, sendIDx, outvol, 1)
                              DATA.UPD.onprojstatechange = true
                            end,
                            onmouseclickR = function()
                              local cur_dB = math.floor(  WDL_VAL2DB(DATA2.tracks[1].receives[receiveGUID].vol) *100)/100
                              local ret, str = GetUserInputs( 'set volume', 1, 'dB', cur_dB)
                              if not (ret and tonumber(str)) then return end
                              local dbval = tonumber(str)
                              if not ( dbval > -90 and dbval < 12) then return end
                              local sendIDx,srctr = DATA2:GetReceiveIdx(receiveGUID)
                              local outvol = WDL_DB2VAL(dbval)
                              SetTrackSendInfo_Value(srctr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( srctr, sendIDx, outvol, 1 )
                              DATA.UPD.onprojstatechange = true 
                            end,
                            data = {fader_cust=true,receiveGUID=receiveGUID,trcol=trcol}
                            } 
      
      --DATA.GUI.buttons['fader_rec'..receiveGUID].hide = DATA.GUI.buttons['fader_rec'..receiveGUID].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
      local y_offs = DATA.GUI.custom_offset*2 + DATA.GUI.custom_infobuth
      GUI_MODULE_BuildReceives_ControlStuff(DATA,receiveGUID,x_offs+x_shift, y_offs, faderW,faderH)
    end
    
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_BuildSends(DATA)
    for key in pairs(DATA.GUI.buttons) do if key:match('fader_send') then DATA.GUI.buttons[key] = nil end end 
    if not (DATA2.tracks and DATA2.tracks[1] and DATA2.tracks[1].sends) then return end
    if DATA.GUI.Settings_open ==1 then return end 
    
    if not DATA2.sendtracks then return end
    local cntsends = #DATA2.sendtracks
    local y_offs = DATA.GUI.custom_offset*2 + DATA.GUI.custom_infobuth
    local x_offs0 = DATA.GUI.custom_offset--*2+DATA.GUI.custom_vcaW
    local faderareaW = (DATA.GUI.custom_gfx_wreal -DATA.GUI.custom_offset*2) ---DATA.GUI.custom_vcaW
    --local faderW = math.min(DATA.GUI.custom_sendfaderWmax, math.floor(faderareaW/cntsends ))
    --local faderW = math.max(DATA.GUI.custom_sendfaderWmin,faderW)
    local faderW =  DATA.GUI.custom_sendfaderW
    local faderH = DATA.GUI.custom_sendfaderH-DATA.GUI.custom_scrollH
    local faderW_scale = faderW--math.floor(faderW*0.8)
    
    
    DATA2.scroll_w = math.min(1,faderareaW / (faderW_scale * cntsends ))
    local x_shift = -DATA2.scroll_x*((faderW_scale * cntsends ) - faderareaW)
    if DATA2.scroll_w == 1 then x_shift = 0 end
    
    for sendID = 1, cntsends do
      local trcol = DATA2.sendtracks[sendID].col
      local destGUID = DATA2.sendtracks[sendID].GUID
      local vol = 0
      if DATA2.tracks[1].sends[destGUID] then vol = DATA2.tracks[1].sends[destGUID].vol end
      local val = DATA2:Convert_Val2Fader(vol)
      local x_offs = x_offs0 + faderW * (sendID-1)
      DATA.GUI.buttons['fader_send'..sendID] = { x=x_offs+ faderW/2 - faderW_scale/2 +x_shift,
                            y=y_offs,
                            w=faderW_scale-DATA.GUI.custom_offset*2,--DATA.GUI.custom_infobut_w*2-2,
                            h=faderH-1,
                            val = val,
                            --txt = i,
                            --txt_fontsz = DATA.GUI.custom_txtsz1,
                            --txt_flags = 4,
                            frame_a =0.5,
                            --frame_col = col,
                            onmousedrag = function() 
                              local sendIDx = DATA2:GetSendIdx(destGUID,true)
                              local outvol = DATA2:Convert_Fader2Val(DATA.GUI.buttons['fader_send'..sendID].val)
                              SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( DATA2.tracks[1].ptr, sendIDx, outvol, 0)
                              DATA.GUI.buttons['fader_send'..sendID].refresh = true
                            end,
                            onmouserelease = function() 
                              local sendIDx = DATA2:GetSendIdx(destGUID,true)
                              local outvol = DATA2:Convert_Fader2Val(DATA.GUI.buttons['fader_send'..sendID].val)
                              if DATA.GUI.Alt == true then outvol = 0 end
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
                              local sendIDx = DATA2:GetSendIdx(destGUID,true)
                              local outvol = WDL_DB2VAL(dbval)
                              SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_VOL', outvol)
                              SetTrackSendUIVol( DATA2.tracks[1].ptr, sendIDx, outvol, 1 )
                              DATA.UPD.onprojstatechange = true 
                            end,
                            data = {fader_cust=true,destGUID=destGUID,trcol=trcol}
                            } 
      
      --DATA.GUI.buttons['fader_send'..sendID].hide = DATA.GUI.buttons['fader_send'..sendID].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
      local y_offs = DATA.GUI.custom_offset*2 + DATA.GUI.custom_infobuth + faderH
      GUI_MODULE_BuildSends_ControlStuff(DATA,sendID,destGUID,x_offs+x_shift, y_offs, faderW,faderH)
    end
    
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_name(DATA,sendID,destGUID,srct,x,y,w,h, name) 
    if DATA.extstate.UI_showsendrecnamevertically ==0 then
      local key = 'fader_send'..sendID..'_name'
      DATA.GUI.buttons[key] = { 
        x=x,
        y=y,
        w=w,
        h=h,
        txt = name,
        frame_a = 0,
        txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
        onmouseclick = function()
          if DATA.GUI.Alt == true then
            local sendIDx = DATA2:GetSendIdx(destGUID,true)
            local desttr = reaper.GetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'P_DESTTRACK' )
            reaper.SetOnlyTrackSelected( desttr)
            DATA.UPD.onprojstatechange = true 
          end
        end,
        onmouseclickR = function()
          local sendIDx = DATA2:GetSendIdx(destGUID,true)
          local desttr = reaper.GetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'P_DESTTRACK' )
          local  retval, trname = reaper.GetTrackName( desttr )
          if retval then
            local retval1, retvals_csv = reaper.GetUserInputs( 'Set destination track name', 1, '', trname )
            if retval1 then GetSetMediaTrackInfo_String( desttr, 'P_NAME', retvals_csv, true ) end
          end
          DATA.UPD.onprojstatechange = true 
        end
      }
      return
    end
    --[[DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
    
    if DATA.extstate.UI_showsendrecnamevertically ==1 then
      local key = 'fader_send'..sendID..'_name'
      DATA.GUI.buttons[key] = { 
        x=DATA.GUI.buttons['fader_send'..sendID].x,
        y=DATA.GUI.buttons['fader_send'..sendID].y,
        w=DATA.GUI.buttons['fader_send'..sendID].w,
        h=DATA.GUI.buttons['fader_send'..sendID].h,
        txt = name,
        txt_vertical = true,
        frame_a = 0,
        backgr_fill = 0,
        ignoremouse = true,
        txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      }
      return
    end]]
    
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_mute(DATA,sendID,destGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    if srct.B_MUTE==0 then txt_a = DATA.GUI.custom_txta_disabled  end
    local key = 'fader_send'..sendID..'_mute'
    DATA.GUI.buttons[key] = { 
      x=x,--+ctrlbutw,
      y=y,
      w=w,
      h=h,
      txt = 'Mute', 
      txt_a=txt_a,
      txt_col = '#FF0000',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID,true)
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'B_MUTE', srct.B_MUTE~1)
        DATA.UPD.onprojstatechange = true 
      end}
      --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_remove(DATA,sendID,destGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    local key = 'fader_send'..sendID..'_remove'
    DATA.GUI.buttons[key] = { 
      x=x,--+ctrlbutw,
      y=y,
      w=w,
      h=h,
      txt = 'X', 
      txt_a=txt_a,
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID,true)
        RemoveTrackSend( DATA2.tracks[1].ptr, 0, sendIDx )
        DATA.UPD.onprojstatechange = true 
      end}
      --DATA.GUI.buttons[key].hide = DATA.GUI.buttons['fader_send'..sendID..'_mute'].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_smode(DATA,sendID,destGUID,srct,x,y,w,h) 
    local modetxtx = '[unknown]'
    if srct.I_SENDMODE == 0 then modetxtx = 'PostFader'
    elseif srct.I_SENDMODE == 3 then modetxtx = 'PreFader'
    elseif srct.I_SENDMODE == 1 then modetxtx = 'PreFX'
    
    end
    local key = 'fader_send'..sendID..'_stype'
    DATA.GUI.buttons[key] = { 
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
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_pan(DATA,sendID,destGUID,srct,x,y,w,h) 
    local val_txt = 'Center' if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'%R' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'%L' end 
    local destGUID = DATA2.sendtracks[sendID].GUID
    local pan = 0
    if DATA2.tracks[1].sends[destGUID] then pan = DATA2.tracks[1].sends[destGUID].pan end 
    local key = 'fader_send'..sendID..'_pan'
    DATA.GUI.buttons[key] = { 
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
        local sendIDx = DATA2:GetSendIdx(destGUID,true)
        local outpan = DATA.GUI.buttons['fader_send'..sendID..'_pan'].val
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_PAN', outpan)
        SetTrackSendUIPan( DATA2.tracks[1].ptr, sendIDx, outpan, 0)
        srct.D_PAN=DATA.GUI.buttons['fader_send'..sendID..'_pan'].val
        local val_txt = 'Center'   if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'%R' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'%L' end
        DATA.GUI.buttons['fader_send'..sendID..'_pan'].txt=val_txt
        DATA.GUI.buttons['fader_send'..sendID..'_pan'].refresh = true
      end,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID,true)
        local outpan = DATA.GUI.buttons['fader_send'..sendID..'_pan'].val
        if DATA.GUI.Alt == true then outpan = 0 end
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_PAN', outpan)
        SetTrackSendUIPan( DATA2.tracks[1].ptr, sendIDx, outpan, 1)
        srct.D_PAN=DATA.GUI.buttons['fader_send'..sendID..'_pan'].val
        local val_txt = 'Center'   if srct.D_PAN > 0.01 then val_txt = math.ceil(srct.D_PAN*100)..'%R' elseif srct.D_PAN < -0.01 then val_txt = -math.floor(srct.D_PAN*100)..'%L' end
        DATA.GUI.buttons['fader_send'..sendID..'_pan'].txt=val_txt
        DATA.GUI.buttons['fader_send'..sendID..'_pan'].refresh = true
        DATA.UPD.onprojstatechange = true
      end,
      onmouseclickR = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID,true)
        local cur_pan = math.floor( DATA2.tracks[1].sends[destGUID].D_PAN *100)
        local ret, outpan = GetUserInputs( 'set pan', 1, '%', cur_pan)
        if not (ret and tonumber(outpan)) then return end
        outpan = tonumber(outpan)
        if ( outpan > 100 or outpan < -100) then return end
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'D_PAN', outpan/100)
        SetTrackSendUIPan( DATA2.tracks[1].ptr, sendIDx, outpan, 1)
        DATA.UPD.onprojstatechange = true 
      end,
    }
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
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
  function GUI_MODULE_BuildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x,y,w,h,ispost) 
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
    local butkey = 'fader_send'..sendID..'_'..key..'filter'
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
        if DATA2.sendtracks[sendID].sendEQ[key].val_POS and DATA2.sendtracks[sendID].sendEQ[key].val_WID then
          DATA2.latch_filt.pos = DATA2.sendtracks[sendID].sendEQ[key].val_POS
          DATA2.latch_filt.width = DATA2.sendtracks[sendID].sendEQ[key].val_WID
        end
      end,
      onmousedrag = function() 
        if not (DATA2.latch_filt and DATA2.latch_filt.pos and DATA2.latch_filt.width) then return end
        local out_pos = DATA2.latch_filt.pos + 0.01*(DATA.GUI.dx/DATA.GUI.default_scale)
        local out_width = DATA2.latch_filt.width - 0.01*(DATA.GUI.dy/DATA.GUI.default_scale) 
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
    --DATA.GUI.buttons[butkey].hide = DATA.GUI.buttons[butkey].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_FX(DATA,sendID,destGUID,srct,x,y,w,h) 
    local key = 'fader_send'..sendID..'_fx'
    DATA.GUI.buttons[key] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = 'FX',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx,dest_trptr = DATA2:GetSendIdx(destGUID,true)
        TrackFX_Show( dest_trptr, 0, 1 )
      end,
    }
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_mono(DATA,sendID,destGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    if srct.B_MONO==0 then txt_a = DATA.GUI.custom_txta_disabled  end
    local key = 'fader_send'..sendID..'_mono'
    DATA.GUI.buttons[key] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = 'Mono',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      txt_a=txt_a,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID,true)
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'B_MONO', srct.B_MONO~1)
        DATA.UPD.onprojstatechange = true 
      end,
    }
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons[key].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff_phase(DATA,sendID,destGUID,srct,x,y,w,h) 
    local txt_a = DATA.GUI.custom_txta
    if srct.B_PHASE==0 then txt_a = DATA.GUI.custom_txta_disabled  end
    local key = 'fader_send'..sendID..'_phase'
    DATA.GUI.buttons[key] = { 
      x=x,
      y=y,
      w=w,
      h=h,
      txt = 'Ø',
      txt_fontsz =DATA.GUI.custom_sendctrl_txtsz1,
      txt_a=txt_a,
      frame_a = 0,
      onmouserelease = function() 
        local sendIDx = DATA2:GetSendIdx(destGUID,true)
        SetTrackSendInfo_Value( DATA2.tracks[1].ptr, 0, sendIDx, 'B_PHASE', srct.B_PHASE~1)
        DATA.UPD.onprojstatechange = true 
      end,
    }
    --DATA.GUI.buttons[key].hide = DATA.GUI.buttons['fader_send'..sendID..'_mono'].x < DATA.GUI.custom_vcaW + DATA.GUI.custom_offset*2
  end
  -------------------------------------------------------------------- 
  function GUI_MODULE_BuildSends_ControlStuff(DATA,sendID,destGUID,x_offs0, y_offs, faderW)
    local srct = DATA2.tracks[1].sends[destGUID]
    local act_w = faderW-DATA.GUI.custom_offset*2
    local x_offs = x_offs0
    GUI_MODULE_BuildSends_ControlStuff_name(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1,DATA2.sendtracks[sendID].name) 
    local ctrlbutw = math.floor(act_w/2) 
    if DATA.extstate.UI_showsendrecnamevertically == 0 then y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh end
    if srct then GUI_MODULE_BuildSends_ControlStuff_mute(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw,DATA.GUI.custom_sendctrl_nameh-1) end
    x_offs = x_offs + ctrlbutw 
    if srct then GUI_MODULE_BuildSends_ControlStuff_remove(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw,DATA.GUI.custom_sendctrl_nameh-1) end
    x_offs = x_offs0
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuildSends_ControlStuff_smode(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) end
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuildSends_ControlStuff_pan(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1) end
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuildSends_ControlStuff_filt(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1,true)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    GUI_MODULE_BuildSends_ControlStuff_FX(DATA,sendID,destGUID,srct,x_offs,y_offs,act_w,DATA.GUI.custom_sendctrl_nameh-1)
    y_offs = y_offs+DATA.GUI.custom_sendctrl_nameh 
    if srct then GUI_MODULE_BuildSends_ControlStuff_mono(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw-1,DATA.GUI.custom_sendctrl_nameh-1) end
    x_offs = x_offs + ctrlbutw 
    if srct then GUI_MODULE_BuildSends_ControlStuff_phase(DATA,sendID,destGUID,srct,x_offs,y_offs,ctrlbutw-1,DATA.GUI.custom_sendctrl_nameh-1) end
  end
  -------------------------------------------------------------------- 
  function DATA2:GetSendIdx(destGUID0,allowcreate)
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
    if not sendidx_out and allowcreate==true  then
      dest_trptr = VF_GetMediaTrackByGUID(0,destGUID0)
      if ValidatePtr(dest_trptr, 'MediaTrack*') then 
        sendidx_out = CreateTrackSend( tr, dest_trptr ) 
        SetTrackSendInfo_Value( tr, 0, sendidx_out, 'D_VOL', 0 )
      end
    end
    return sendidx_out,dest_trptr
  end
  -------------------------------------------------------------------- 
  function DATA2:GetReceiveIdx(srcGUID0) 
    local src_trptr = VF_GetMediaTrackByGUID(0,srcGUID0)
    if not src_trptr then return end
    local desttr = DATA2.tracks[1].ptr
    local destGUID0 = DATA2.tracks[1].GUID
    local sendidx_out
    for sendidx = 1, GetTrackNumSends( src_trptr, 0 ) do 
      local dest_trptr = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
      if ValidatePtr(dest_trptr, 'MediaTrack*') then
        local retval, destGUID = GetSetMediaTrackInfo_String( dest_trptr, 'GUID', '', false )
        if destGUID == destGUID0 then sendidx_out = sendidx-1 break end
      end
    end
    return sendidx_out,src_trptr
  end
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
    if not (b.data.destGUID or b.data.receiveGUID ) then return end
    local trcol=b.data.trcol
    
    local x=b.x*DATA.GUI.default_scale
    local y=b.y*DATA.GUI.default_scale
    local w=b.w*DATA.GUI.default_scale
    local h=b.h*DATA.GUI.default_scale
    
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
      if trcol then 
        local r, g, b = reaper.ColorFromNative( trcol )
        gfx.set(r/255,g/255,b/255)
      end
      gfx.a = 0.4
      local hfade = math.floor(h*fader_norm)
      gfx.rect(x,y+1+h-hfade,w,hfade,1)
    
    --if b.w<=DATA.GUI.custom_sendfaderWmin then return end
    
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
        gfx.line(x+1, y+y_offsscale + h - h *y1, x+line_w/2, y+y_offsscale + h - h *y1)
        gfx.x = x + w - gfx.measurestr(t[i]..'dB')-- - 2
        gfx.y = y + h - h *y1- gfx.texth/2-1
        gfx.drawstr(t[i]..'dB')
      end
  end
  ---------------------------------------------------------------------
  function GUI_RESERVED_draw_data_filter(DATA, b)
    local pos = b.data.filtFpos
    local width = b.data.filtFwidth
    
    if not (pos and width )  then return end 
    local x0=b.x*DATA.GUI.default_scale
    local y0=b.y*DATA.GUI.default_scale
    local w=b.w*DATA.GUI.default_scale
    local h0=b.h*DATA.GUI.default_scale
    
    -- center line
      DATA:GUIhex2rgb('#FFFFFF',true)
      gfx.a = 0.2
      local xmid = math.ceil(x0+ pos*w)
      gfx.line(xmid,y0,xmid,y0+DATA.GUI.custom_filter_centerH)
      gfx.line(xmid,y0+h0-1,xmid,y0+h0+1-DATA.GUI.custom_filter_centerH)
      gfx.rect(xmid-w*width/2,y0,math.ceil(w*width),h0,1)
      
  end
  ---------------------------------------------------------------------
  function GUI_RESERVED_draw_data_slider(DATA, b)
    local pos = DATA2.scroll_x
    local width = DATA2.scroll_w
    
    if not (pos and width )  then return end 
    local x=b.x*DATA.GUI.default_scale
    local y=b.y*DATA.GUI.default_scale
    local w=b.w*DATA.GUI.default_scale
    local h=b.h*DATA.GUI.default_scale
    
    x = x + w*(1-width)*pos
    w = w * width
    -- center line
      DATA:GUIhex2rgb('#FFFFFF',true)
      a_init = 0.4
      local halfw = math.ceil(w/2)
      local dxa = (1-a_init)/halfw
      gfx.gradrect(x,y,halfw,h, 1,1,1,a_init, 0, 0, 0, dxa, 0, 0, 0, 0 )
      gfx.gradrect(x+halfw,y,halfw,h, 1,1,1,1, 0, 0, 0, -dxa, 0, 0, 0, 0 )
      
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_draw_data(DATA, b)
    if not b.data then return end 
    
    if b.data.slider_2dir then GUI_RESERVED_draw_data_filter(DATA, b) end
    if b.data.fader_cust then GUI_RESERVED_draw_data_fader(DATA, b) end
    if b.data.horslider then GUI_RESERVED_draw_data_slider(DATA, b) end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
    
    local  t = 
    { 
      {str = 'General' ,                                        group = 1, itype = 'sep'},
        {str = 'Preset',                                        group = 1, itype = 'button', level = 1, func_onrelease = function() DATA:GUIbut_preset() end},
        {str = 'Dock / undock',                                 group = 1, itype = 'button', confkey = 'dock',  level = 1, func_onrelease = 
          function()  
            local state = gfx.dock(-1)
            if state&1==1 then
              state = 0
             else
              state = DATA.extstate.dock 
              if state == 0 then state = 1 end
            end
            local title = DATA.extstate.mb_title or ''
            if DATA.extstate.version then title = title..' '..DATA.extstate.version end
            gfx.quit()
            gfx.init( title,
                      DATA.extstate.wind_w or 100,
                      DATA.extstate.wind_h or 100,
                      state, 
                      DATA.extstate.wind_x or 100, 
                      DATA.extstate.wind_y or 100)
            
            
          end},
      {str = 'Sends definition' ,                                 group = 2, itype = 'sep'},   
        {str = 'Show sends that marked as sends in SendFader',    group = 2, itype = 'check', confkey = 'CONF_marksendint', level = 1},
            {str = '[Action] Mark selected tracks as send',       group = 2, itype = 'button', level = 2, hide=DATA.extstate.CONF_marksendint==0,func_onrelease = function() DATA2:MarkSelectedTracksAsSend(1) end},
            {str = '[Action] Unmark selected tracks as send',     group = 2, itype = 'button', level = 2, hide=DATA.extstate.CONF_marksendint==0, func_onrelease = function() DATA2:MarkSelectedTracksAsSend(0) end},
        {str = 'Show sends of selected track',                    group = 2, itype = 'check', confkey = 'CONF_marksendregular', level = 1},
        {str = 'Show sends match following words',                group = 2, itype = 'check', confkey = 'CONF_marksendwordsmatch', level = 1},
            {str = 'Send name: '..DATA.extstate.CONF_definebyname, group = 2, itype = 'button',level = 2, hide=DATA.extstate.CONF_marksendwordsmatch==0,  func_onrelease = function() 
              local retval, retvals_csv = GetUserInputs( 'Send name', 1, ',separator=|', DATA.extstate.CONF_definebyname )
              if retval then if retvals_csv =='' then retvals_csv = '[none]' end DATA.extstate.CONF_definebyname = retvals_csv DATA.UPD.onconfchange = true GUI_refresh(DATA) end
            end},
        {str = 'Show sends with parent match following words',    group = 2, itype = 'check', confkey = 'CONF_marksendparentwordsmatch', level = 1},
          {str = 'Folder name: '..DATA.extstate.CONF_definebygroup,group = 2, itype = 'button',level = 2, hide=DATA.extstate.CONF_marksendparentwordsmatch==0,  func_onrelease = function() 
            local retval, retvals_csv = GetUserInputs( 'Folder name', 1, ',separator=|', DATA.extstate.CONF_definebygroup )
            if retval then if retvals_csv =='' then retvals_csv = '[none]' end DATA.extstate.CONF_definebygroup = retvals_csv DATA.UPD.onconfchange = true GUI_refresh(DATA) end
          end},
      --{str = 'UI',                                              group = 3, itype = 'sep'},
        --{str = 'Show send/receive names vertically',              group = 3, itype = 'check', confkey = 'UI_showsendrecnamevertically', level = 1},  
        
        --[[{str = 'Float RS5k instance',                           group = 1, itype = 'check', confkey = 'CONF_onadd_float', level = 1},
        {str = 'Set obey notes-off',                            group = 1, itype = 'check', confkey = 'CONF_onadd_obeynoteoff', level = 1},
        
        {str = 'Copy samples to project path',                  group = 1, itype = 'check', confkey = 'CONF_onadd_copytoprojectpath', level = 1},
        {str = 'Custom track template: '..customtemplate,       group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() local retval, fp = GetUserFileNameForRead('', 'FX chain for newly dragged samples', 'RTrackTemplate') if retval then DATA.extstate.CONF_onadd_customtemplate=  fp GUI_MODULE_SETTINGS(DATA) end end},
        {str = 'Custom track template [clear]',                  group = 1, itype = 'button', confkey = 'CONF_onadd_customtemplate', level = 1, val_isstring = true, func_onrelease = function() DATA.extstate.CONF_onadd_customtemplate=  '' GUI_MODULE_SETTINGS(DATA) end},
        
      {str = 'MIDI bus',                                        group = 2, itype = 'sep'}, 
        {str = 'MIDI bus default input',                        group = 2, itype = 'readout', confkey = 'CONF_midiinput', level = 1, menu = {[63]='All inputs',[62]='Virtual keyboard'},readoutw_extw = readoutw_extw},
        {str = 'MIDI bus channel',                        group = 2, itype = 'readout', confkey = 'CONF_midichannel', level = 1, menu = {[0]='All channels',[1]='Channel 1',[2]='Channel 2',[3]='Channel 3',[4]='Channel 4',[5]='Channel 5',[6]='Channel 6',[7]='Channel 7',[8]='Channel 8',[9]='Channel 9',[10]='Channel 10',
        [11]='Channel 11',[12]='Channel 12',[13]='Channel 13',[14]='Channel 14',[15]='Channel 15',[16]='Channel 16'},readoutw_extw = readoutw_extw},
        {str = 'Initialize MIDI bus',                           group = 2, itype = 'button', level = 1, func_onrelease = function() DATA2:TrackDataRead_ValidateMIDIbus() end},
        
      {str = 'UI',                                              group = 3, itype = 'sep'},
        {str = 'Active note follow incoming note',              group = 3, itype = 'check', confkey = 'UI_showsendrecnamevertically', level = 1},
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
  local ret = VF_CheckFunctions(3.58) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end
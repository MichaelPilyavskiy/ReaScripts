-- @description InstrumentRack_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  
  ---------------------------------------------------  
  function CheckUpdates(obj, conf, refresh)
  
    -- force by proj change state
      obj.SCC =  GetProjectStateChangeCount( 0 ) 
      if not obj.lastSCC then 
        refresh.GUI_onStart = true  
        refresh.data = true
       elseif obj.lastSCC and obj.lastSCC ~= obj.SCC then 
        refresh.data = true
        refresh.GUI = true
        refresh.GUI_WF = true
      end 
      obj.lastSCC = obj.SCC
      
    -- window size
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        refresh.conf = true 
        refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        refresh.data = true
      end
  end
  ---------------------------------------------------   
  function Data_Update (conf, obj, data, refresh, mouse, data_ext) 
    --msg('upd')
    for trid = 1, CountTracks(0) do
      local tr = GetTrack(0,trid-1)
      local tr_solo = GetMediaTrackInfo_Value( tr, 'I_SOLO' )> 0
      local tr_mute = GetMediaTrackInfo_Value( tr, 'B_MUTE' )> 0
      local tr_automode = GetMediaTrackInfo_Value( tr, 'I_AUTOMODE' )
      
      local retval, tr_name = reaper.GetTrackName( tr, '' )
      local tr_isfreezed = BR_GetMediaTrackFreezeCount( tr ) > 0
      if tr_isfreezed == true then
          data[#data+1] = {name = '<Freezed>',
                            trGUID = GetTrackGUID( tr ), 
                            tr_name = tr_name,
                            tr_id = trid,
                            tr_solo = tr_solo,
                            tr_mute = tr_mute,
                            tr_isfreezed =  tr_isfreezed,
                            tr_automode = tr_automode,
                            tr_issel = IsTrackSelected( tr ),
                            }      
      end
      for fx_id =1, TrackFX_GetCount( tr ) do
        local retval, buf = TrackFX_GetFXName( tr, fx_id-1, '' )
        if buf:match('VSTi') 
          or buf:match('DXi') 
          or buf:match('AUi') 
          or buf:match('VST3i') 
          or buf:lower():match('rs5k') 
          or tr_isfreezed           
          then
          
          local  retval, presetname = TrackFX_GetPreset( tr, fx_id-1, '' )
          local fx_GUID = TrackFX_GetFXGUID( tr, fx_id-1)
          local ext_t if data_ext[fx_GUID] then ext_t = CopyTable(data_ext[fx_GUID]) end
          
          local tcp_params = {cnt = 0}
          local cnt = 0
          for tcp_id = 1, CountTCPFXParms( 0, tr ) do
            local retval, fxindex, parmidx = GetTCPFXParm( 0, tr, tcp_id-1 )
            if retval and (conf.obeyyallcontrols == 1 or (conf.obeyyallcontrols == 0 and fxindex == fx_id-1)) then
              local param_f = TrackFX_GetParamNormalized( tr, fxindex, parmidx )
              if not tcp_params[fxindex] then tcp_params[fxindex] = {} end
              cnt = cnt + 1
              tcp_params[fxindex][parmidx] = param_f
            end
          end
          
          data[#data+1] = {name = buf,
                            fx_idx= fx_id-1,
                            bypass =  TrackFX_GetEnabled(tr, fx_id-1 ),
                            GUID = fx_GUID ,
                            trGUID = GetTrackGUID( tr ), 
                            tr_ptr = tr,
                            tr_name = tr_name,
                            tr_id = trid,
                            presetname = presetname,
                            is_open =  TrackFX_GetOpen(  tr, fx_id-1),
                            is_offline = TrackFX_GetOffline(  tr, fx_id-1),
                            tr_solo = tr_solo,
                            tr_mute = tr_mute,
                            tr_isfreezed =  tr_isfreezed,
                            tr_automode = tr_automode,
                            tr_issel = IsTrackSelected( tr ),
                            ext_t=ext_t,
                            tcp_params = tcp_params,
                            }
        end
      end
    end
  end  
  ---------------------------------------------------   
  function Data_Update2 (conf, obj, data, refresh, mouse) 
    for i = 1, #data do
      local tr = data[i].tr_ptr
      if  ValidatePtr2( 0, tr, 'MediaTrack*' ) then
        if data[i].tr_peak1 then data[i].tr_peak1 = (data[i].tr_peak1 + Track_GetPeakInfo( tr, 0 ) ) / 2 else data[i].tr_peak1 = Track_GetPeakInfo( tr, 0 ) end
        if data[i].tr_peak2 then data[i].tr_peak2 = (data[i].tr_peak2 + Track_GetPeakInfo( tr, 1 ) ) / 2 else data[i].tr_peak2 = Track_GetPeakInfo( tr,1 ) end
      end
    end
  end

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
  function Data_Update (conf, obj, data, refresh, mouse) 
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
                            }      
      end
      for fx_id =1, TrackFX_GetCount( tr ) do
        local retval, buf = TrackFX_GetFXName( tr, fx_id-1, '' )
        if buf:match('VSTi') or buf:match('DXi') or buf:match('AUi') or tr_isfreezed then
          local  retval, presetname = TrackFX_GetPreset( tr, fx_id-1, '' )
          data[#data+1] = {name = buf,
                            bypass =  TrackFX_GetEnabled(tr, fx_id-1 ),
                            GUID =  TrackFX_GetFXGUID( tr, fx_id-1),
                            trGUID = GetTrackGUID( tr ), 
                            tr_name = tr_name,
                            tr_id = trid,
                            presetname = presetname,
                            is_open =  TrackFX_GetOpen(  tr, fx_id-1),
                            is_offline = TrackFX_GetOffline(  tr, fx_id-1),
                            tr_solo = tr_solo,
                            tr_mute = tr_mute,
                            tr_isfreezed =  tr_isfreezed,
                            tr_automode = tr_automode,
                            }
        end
      end
    end
  end  

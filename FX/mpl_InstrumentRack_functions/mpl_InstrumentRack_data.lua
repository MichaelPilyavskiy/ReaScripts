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
    for trid = 1, CountTracks(0) do
      local tr = GetTrack(0,trid-1)
      local retval, tr_name = reaper.GetTrackName( tr, '' )
      for fx_id =1, TrackFX_GetCount( tr ) do
        local retval, buf = TrackFX_GetFXName( tr, fx_id-1, '' )
        if buf:match('VSTi') or buf:match('DXi') or buf:match('AUi') then
          local  retval, presetname = TrackFX_GetPreset( tr, fx_id-1, '' )
          data[#data+1] = {name = buf,
                            bypass =  TrackFX_GetEnabled(tr, fx_id-1 ),
                            GUID =  TrackFX_GetFXGUID( tr, fx_id-1),
                            tr_name = tr_name,
                            tr_id = trid,
                            presetname = presetname,
                            is_open =  TrackFX_GetOpen(  tr, fx_id-1)
                            }
        end
      end
    end
  end  

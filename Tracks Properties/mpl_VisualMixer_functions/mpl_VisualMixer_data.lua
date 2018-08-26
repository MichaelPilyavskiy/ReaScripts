-- @description VisualMixer_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  function Data_Update2(conf, obj, data, refresh, mouse)
    if not data.tracks then return end
    for GUID in pairs(data.tracks) do
      if data.tracks[GUID].ptr and ValidatePtr2(0,data.tracks[GUID].ptr, 'MediaTrack*') then
        if not data.tracks[GUID].peakR then 
          data.tracks[GUID].peakR = {} 
          data.tracks[GUID].peakL = {} 
        end
        local id = #data.tracks[GUID].peakL +1
        table.insert(data.tracks[GUID].peakL, 1 , Track_GetPeakInfo( data.tracks[GUID].ptr,0 ))
        table.insert(data.tracks[GUID].peakR, 1 , Track_GetPeakInfo( data.tracks[GUID].ptr,1 ))
        if #data.tracks[GUID].peakL > obj.tr_max_rect then 
          table.remove(data.tracks[GUID].peakL, #data.tracks[GUID].peakL)
          table.remove(data.tracks[GUID].peakR, #data.tracks[GUID].peakL)
        end
      end
    end
  end
  ---------------------------------------------------
  function Data_Update(conf, obj, data, refresh, mouse)
    data.tracks = {}
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      local GUID = reaper.GetTrackGUID( tr )
      
      -- pan
      local pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
      if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then 
         local L= GetMediaTrackInfo_Value( tr, 'D_DUALPANL')
         local R= GetMediaTrackInfo_Value( tr, 'D_DUALPANR')
         pan = math.max(math.min(L+R, 1), -1)
      end
      
      -- vol 
      local vol = GetMediaTrackInfo_Value( tr, 'D_VOL')
      local vol_dB = WDL_VAL2DB(vol)
      
      --name
      local retval, trname = GetTrackName( tr, '' )
      
      
      data.tracks[GUID] = {ptr = tr,
                            pan = pan,
                           vol = vol,
                           vol_dB = vol_dB,
                           name = trname,
                           width = GetMediaTrackInfo_Value( tr, 'D_WIDTH'),
                           col =  GetTrackColor( tr )}
    end
  end
  ---------------------------------------------------   
  function Data_ApplyTrPan(GUID,pan )
    local tr=  BR_GetMediaTrackByGUID( 0, GUID )
    if tr then 
      SetMediaTrackInfo_Value( tr, 'D_PAN', pan )
      if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then 
        SetMediaTrackInfo_Value( tr, 'D_DUALPANL', pan)
        SetMediaTrackInfo_Value( tr, 'D_DUALPANR', pan)
      end    
    end
  end
  ---------------------------------------------------   
  function Data_ApplyTrVol(GUID,vol )
    local tr=  BR_GetMediaTrackByGUID( 0, GUID )
    if tr then 
      SetMediaTrackInfo_Value( tr, 'D_VOL', lim(vol,0,4))
    end
  end
  ---------------------------------------------------  
  function CheckUpdates(obj, conf, refresh)
  
    -- force by proj change state
      obj.SCC =  GetProjectStateChangeCount( 0 ) 
      if not obj.lastSCC then 
        refresh.GUI_onStart = true  
        refresh.data = true
       elseif obj.lastSCC and obj.lastSCC ~= obj.SCC then 
        --if conf.dev_mode == 1 then msg(obj.SCC..'2') end
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

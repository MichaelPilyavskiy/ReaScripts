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
  function Data_SnapshotRecall(snshstr )
    if not snshstr then return end
    Action(40297) -- unselect all tracks
    for line in snshstr:gmatch('[^\r\n]+') do
      local t = {}
      for val in line:gmatch('[^%s]+') do t [#t+1] = val end
      if #t == 4 then
        local GUID = t[1]
        local vol = tonumber(t[2])
        local pan = tonumber(t[3])
        local width = tonumber(t[4])
        local tr = BR_GetMediaTrackByGUID( 0, GUID )
        SetTrackSelected( tr, true )
        Data_ApplyTrVol(GUID, vol )
        Data_ApplyTrPan(GUID, pan )
        Data_ApplyTrWidth(GUID, width )
      end      
    end
  end
  -----------------------------------------------  
  function Data_Snapshot_FormStr(data)
    local str = ''
    for GUID in pairs(data.tracks) do
      str = str..
           GUID..' '..
           data.tracks[GUID].vol..' '..
           data.tracks[GUID].pan..' '..
           data.tracks[GUID].width..'\n'
    end
    return str
  end   
  --------------------------------------------------- 
  function Data_Update_Snapshots (conf, obj, data, refresh, mouse) 
    data.currentsnapshotID = 1
    local retval, cur_id = GetProjExtState(0, 'MPL_VisMix', 'CUR_ID' )
    if tonumber(cur_id) then data.currentsnapshotID = tonumber(cur_id) end
  end
  ---------------------------------------------------
  function Data_Snapshot_SaveExtState(data, ID, str)  
    if not ID then return end    
    if str then SetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID, str  ) end
    SetProjExtState(0, 'MPL_VisMix', 'CUR_ID', ID  )
  end
  ---------------------------------------------------
  function Data_SnapShot_GetString(data, ID)
  if not ID then return end
    local retval, s_state = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID  )
    return s_state
  end
  ---------------------------------------------------
  function Data_Snapshot_HasExist(data, ID)  
    if not ID then return end
    local retval, val = GetProjExtState(0, 'MPL_VisMix', 'SNAPSHOT'..ID )
    if retval and  val ~= '' then return true end    
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
      --[[SetMediaTrackInfo_Value( tr, 'D_PAN', pan )
      if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then 
        SetMediaTrackInfo_Value( tr, 'D_DUALPANL', pan)
        SetMediaTrackInfo_Value( tr, 'D_DUALPANR', pan)
      end]]
      CSurf_OnPanChangeEx(tr, pan, false, false)
    end
  end
  ---------------------------------------------------   
  function Data_ApplyTrVol(GUID,vol )
    local tr=  BR_GetMediaTrackByGUID( 0, GUID )
    if tr then 
      local out_vol = lim(vol,0,4)
      --SetMediaTrackInfo_Value( tr, 'D_VOL', out_vol)
      CSurf_OnVolumeChangeEx(tr, out_vol, false, false)
    end
  end
  ---------------------------------------------------   
  function Data_ApplyTrWidth(GUID, w )
    local tr=  BR_GetMediaTrackByGUID( 0, GUID )
    if tr then 
      --SetMediaTrackInfo_Value( tr, 'D_WIDTH', w)
      CSurf_OnWidthChangeEx(tr, w, false, false)
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
  

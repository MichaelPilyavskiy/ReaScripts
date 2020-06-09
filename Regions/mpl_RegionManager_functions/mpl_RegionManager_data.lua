-- @description RegionManager_data
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
        --refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        --refresh.data = true
      end
  end
  ---------------------------------------------------  
  function Data_Update(conf, obj, data, refresh, mouse)
    Data_CollectRegions(conf, obj, data, refresh, mouse)
  end
  ---------------------------------------------------    
    function Data_CollectRegions(conf, obj, data, refresh, mouse)
      local curpos = GetCursorPositionEx( 0 )
      
      data.regions = {}
      local retval, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
      local rgn_idx = 0
      for idx = 1, num_markers + num_regions do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, idx-1 )
        if isrgn == true then rgn_idx = rgn_idx + 1 end
        local pos_format = format_timestr_pos( pos, '', -1 )
        local rgnend_format = format_timestr_pos( rgnend, '', -1 )
        local rgnlen = rgnend - pos
        local rgnlen_format = format_timestr_len( rgnlen, '', pos, -1 )
        
        data.regions[idx] = {isrgn=isrgn,
                              rgnpos = pos,
                              rgnend=rgnend,
                              rgnlen=rgnlen,
                              name=name,
                              markrgnindexnumber=markrgnindexnumber,
                              color=color,
                              pos_format =pos_format,
                              rgnend_format=rgnend_format,
                              rgnlen_format=rgnlen_format,
                              rgn_idx=rgn_idx,
                              show = true}
      end
    end 
  ---------------------------------------------------   
  function Data_Update2(conf, obj, data, refresh, mouse)
    local playpos
    local plstate = GetPlayStateEx( 0 )
    if plstate>0 then 
      playpos = GetPlayPositionEx( 0 )
     else
      playpos = GetCursorPositionEx( 0 )
    end
    for idx = 1, #data.regions do
      if obj['regionname'..idx] and data.regions[idx].isrgn then 
        local val = 1
        if playpos >data.regions[idx].rgnpos and playpos < data.regions[idx].rgnend then 
          val = (playpos - data.regions[idx].rgnpos) / (data.regions[idx].rgnend-data.regions[idx].rgnpos)
        end
        obj['regionname'..idx].fill_val = val
      end
      
      local isundereditpos
      if obj['region_sel'..idx] then 
        if data.regions[idx].isrgn == false then 
          local check = math.abs(playpos-data.regions[idx].rgnpos) < 10^-14
          if check then check = 1 end
          obj['region_sel'..idx].check = check
         else
          local check = playpos>=data.regions[idx].rgnpos and playpos < data.regions[idx].rgnend
          if check then check = 1 end
          local start_ts, end_ts = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
          if math.abs(start_ts-data.regions[idx].rgnpos) < 10^-14 and math.abs(end_ts-data.regions[idx].rgnend ) < 10^-14 then check = true end
          obj['region_sel'..idx].check = check 
        end
      end
      
      
      
    end
  end
  --[[    -- reaper.EnumRegionRenderMatrix( proj, regionindex, rendertrack )Enumerate which tracks will be rendered within this region when using the region render matrix. When called with rendertrack==0, the function returns the first track that will be rendered (which may be the master track); rendertrack==1 will return the next track rendered, and so on. The function returns NULL when there are no more tracks that will be rendered within this region.]]
  --markeridx, regionidx = reaper.GetLastMarkerAndCurRegion( proj, time )--Get the last project marker before time, and/or the project region that includes time. markeridx and regionidx are returned not necessarily as the displayed marker/region index, but as the index that can be passed to EnumProjectMarkers. Either or both of markeridx and regionidx may be NULL. See EnumProjectMarkers.
  --reaper.SetRegionRenderMatrix( proj, regionindex, track, addorremove )--Add (addorremove > 0) or remove (addorremove < 0) a track from this region when using the region render matrix.
  -- reaper.AddProjectMarker2( proj, isrgn, pos, rgnend, name, wantidx, color )--Returns the index of the created marker/region, or -1 on failure. Supply wantidx>=0 if you want a particular index number, but you'll get a different index number a region and wantidx is already in use. color should be 0 (default color), or ColorToNative(r,g,b)|0x1000000
  -- reaper.SetProjectMarkerByIndex2( proj, markrgnidx, isrgn, pos, rgnend, IDnumber, name, color, flags )
  -- reaper.SetProjectMarker4( proj, markrgnindexnumber, isrgn, pos, rgnend, name, color, flags )
    
    

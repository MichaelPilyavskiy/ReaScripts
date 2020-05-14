-- @description MappingPanel_data
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
        --refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        --refresh.data = true
      end
  end
  ---------------------------------------------------
  function Data_ToggleFlags(conf, obj, data, refresh, mouse, activeknob, activeknob_slot, byte_id, is_tension, val)
    if not (data.slots[activeknob] and data.slots[activeknob][activeknob_slot]) then return end
    local tr = data.slots[activeknob][activeknob_slot].tr_pointer
    local cur_flags = TrackFX_GetParam( tr, data.slots[activeknob][activeknob_slot].JSFX_FXid, data.slots[activeknob][activeknob_slot].JSFX_paramid+conf.slot_cnt*2)
    if not is_tension then
      local output = BinaryToggle(cur_flags, byte_id) 
      TrackFX_SetParam( tr, data.slots[activeknob][activeknob_slot].JSFX_FXid, data.slots[activeknob][activeknob_slot].JSFX_paramid+conf.slot_cnt*2, output)
     else 
      cur_flags = cur_flags - (cur_flags&0x1E)
      local output = cur_flags + (math.floor(val*15)<<1)
      TrackFX_SetParam( tr, data.slots[activeknob][activeknob_slot].JSFX_FXid, data.slots[activeknob][activeknob_slot].JSFX_paramid+conf.slot_cnt*2, output)
    end
  end 
  ---------------------------------------------------
  function Data_ApplyHex(conf, obj, data, refresh, mouse, activeknob, activeknob_slot)
    if not (data.slots[activeknob] and data.slots[activeknob][activeknob_slot]) then return end
    local tr = data.slots[activeknob][activeknob_slot].tr_pointer
    local cur_hex = data.slots[activeknob][activeknob_slot].hexarray
    local out_hex = math.floor(data.slots[activeknob][activeknob_slot].hexarray_lim_min*255) + 
              (math.floor(data.slots[activeknob][activeknob_slot].hexarray_lim_max*255)<<8) + 
              (math.floor(data.slots[activeknob][activeknob_slot].hexarray_scale_min*255)<<16) + 
              (math.floor(data.slots[activeknob][activeknob_slot].hexarray_scale_max*255)<<24)
    local out_flags = 0
    if data.slots[activeknob][activeknob_slot].flags_mute == true then out_flags = 1 end 
    out_flags =out_flags + (math.floor(data.slots[activeknob][activeknob_slot].flags_tension * 15) <<1)
    out_flags =out_flags + (math.floor(data.slots[activeknob][activeknob_slot].hexarray_scale_max*255)<<9) 
    TrackFX_SetParam( tr, data.slots[activeknob][activeknob_slot].JSFX_FXid, data.slots[activeknob][activeknob_slot].JSFX_paramid+conf.slot_cnt*2, out_flags)
    TrackFX_SetParam( tr, data.slots[activeknob][activeknob_slot].JSFX_FXid, data.slots[activeknob][activeknob_slot].JSFX_paramid+conf.slot_cnt*3, out_hex)
  end 
  ---------------------------------------------------
  function Data_RemoveLink(conf, obj, data, refresh, mouse, activeknob, activeknob_slot)
    if not (data.slots[activeknob] and data.slots[activeknob][activeknob_slot] and data.slots[activeknob][activeknob_slot].trGUID) then return end
    local tr = VF_GetTrackByGUID(data.slots[activeknob][activeknob_slot].trGUID)
    local retval, trchunk = GetTrackStateChunk( tr, '', false )
    local fxGUID =  data.slots[activeknob][activeknob_slot].Slave_FXGUID
    local paramid = data.slots[activeknob][activeknob_slot].Slave_paramid
    local fxchunk = trchunk:match('FXID '..literalize(fxGUID)..'.-WAK %d')
    local existed_paramblock = fxchunk:match('<PROGRAMENV '..paramid..'.->')
    if not existed_paramblock then MB('Error. [Data_RemoveLink] existed_paramblock not found', '', 0) return end
    local existed_paramblock_mod = existed_paramblock:gsub('PLINK.-[\n\r]','')
    fxchunk_mod = fxchunk:gsub(literalize(existed_paramblock), existed_paramblock_mod)
    local trchunk = trchunk:gsub(literalize(fxchunk), fxchunk_mod)
    --ClearConsole()
    --msg(trchunk)  
    SetTrackStateChunk( tr, trchunk, false )    
  end
    ------------------------------------------------------------------
    function Data_AddLink(conf, obj, data, refresh, mouse) 
    
      if not data.LTP_hasLTP then return end
      if data.LTP_fxname:match('MappingPanel') then return end
      --if data.LTP_trGUID == data.masterJSFX_trGUID then return end -- prevent adding to track contain master
      local childtr = VF_GetTrackByGUID(data.LTP_trGUID)
      
      -- validate existing slave    -- TrackFX_AddByName( childtr, 'JS:MappingPanel_slave.jsfx', false, 1 ) -- DOESNT WORK
        local JSFXid
        for fx = 1,  TrackFX_GetCount( childtr ) do
          local retval, fxname = TrackFX_GetFXName( childtr, fx-1, '' )
          if fxname:match('MappingPanel_slave') then 
            JSFXid = fx-1 
            break 
          end
        end
        if not JSFXid then JSFXid = TrackFX_AddByName( childtr, 'JS:MappingPanel_slave.jsfx', false, 1 ) end
        if JSFXid < 0 then return end
        
        Data_AddModifyParamLink(conf, data, JSFXid)
    end
    -------------------------------------------------------------------- 
    function Data_AddModifyParamLink(conf, data, JSFXid)
      --ClearConsole()
      local tr = VF_GetTrackByGUID(data.LTP_trGUID)
      local JSFXid_GUID = TrackFX_GetFXGUID( tr, JSFXid )
      -- get free JSFX slider
        for slidefx = 0,conf.slot_cnt-1 do
          local exist
          for slot = 1, #data.slots do
            for i = 1, #data.slots[slot] do
              --msg(JSFXid_GUID)
              --msg(data.slots[slot][i].JSFX_FXGUID)
              if data.slots[slot][i].JSFX_FXGUID==JSFXid_GUID
                and slidefx == data.slots[slot][i].JSFX_paramid then 
                  exist = true
                  goto skipnextslider
              end
            end
          end
          if not exist then free_assigned_slider = slidefx break end
          ::skipnextslider::
        end
      
      --msg(free_assigned_slider)
      if not free_assigned_slider then return end
      local retval, trchunk = GetTrackStateChunk( tr, '', false )
      local fxGUID =  TrackFX_GetFXGUID( tr, data.LTP_fxnumber )
      local paramid = data.LTP_paramnumber
      local fxchunk = trchunk:match('FXID '..literalize(fxGUID)..'.-WAK %d')
      local existed_paramblock = fxchunk:match('<PROGRAMENV '..paramid..'.->')
      local fxchunk_mod = fxchunk
      if not existed_paramblock then
        fxchunk_mod = fxchunk:gsub('WAK', 
  '<PROGRAMENV '..paramid..' 0'..'\n'..
  'PLINK 1 '..JSFXid..':'..JSFXid-data.LTP_fxnumber..' '..free_assigned_slider..' 0'..
  '\n>\nWAK'
        )      
       else
        local existed_paramblock_mod = existed_paramblock:gsub('PLINK.-[\n\r]',
  'PLINK 1 '..JSFXid..':'..JSFXid-data.LTP_fxnumber..' '..free_assigned_slider..' 0\n')
        fxchunk_mod = fxchunk:gsub(literalize(existed_paramblock), existed_paramblock_mod)
      
      end
      local trchunk = trchunk:gsub(literalize(fxchunk), fxchunk_mod)
      --ClearConsole()
      --msg(trchunk)  
      SetTrackStateChunk( tr, trchunk, false )
      TrackFX_SetParam( tr, JSFXid, free_assigned_slider+conf.slot_cnt, conf.activeknob )
    end
  ------------------------------------------------------------------
  function Data_ValidateMasterJSFX(conf, obj, data, refresh, mouse)
    -- if exists
    if not data.masterJSFX_isvalid or (data.masterJSFX_isvalid and data.masterJSFX_isvalid == false) then 
      data.masterJSFX_trGUID = nil
      data.masterJSFX_FXid = nil
      goto search_masterJSFX 
     elseif data.masterJSFX_trGUID and data.masterJSFX_FXid then
      data.masterJSFX_isvalid = false
      local tr = VF_GetTrackByGUID(data.masterJSFX_trGUID)
      if tr then 
        local retval, fxname = TrackFX_GetFXName( tr, data.masterJSFX_FXid, '' )
        if fxname:match('MappingPanel_master') then
          data.masterJSFX_isvalid = true
        end
      end
    end
    
    ::search_masterJSFX::
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      for fx = 1,  TrackFX_GetCount( tr ) do
        local retval, fxname = TrackFX_GetFXName( tr, fx-1, '' )
        if fxname:match('MappingPanel_master') then
          data.masterJSFX_isvalid = true
          data.masterJSFX_trGUID = GetTrackGUID( tr )
          data.masterJSFX_FXid = fx-1
          break
        end
      end
    end
  end
  ------------------------------------------------------------------
  function Data_gmem_stuff(conf, obj, data, refresh, mouse)
    data.slots = {}
    for i = 1, conf.slot_cnt do 
      data.slots[i] = {val = gmem_read(i )}
    end
  end
  ------------------------------------------------------------------
  function Data_ValidateSlaveJSFX(conf, obj, data, refresh, mouse)
    for i = 1, CountTracks() do
      local tr = GetTrack(0,i-1)
      for fx_id = 1, TrackFX_GetCount(tr) do
        local retval, fxname = TrackFX_GetFXName( tr, fx_id-1, '' )
        if fxname:match('MappingPanel_slave') then
          Data_CollectSlaveRouting(data, conf, tr, fx_id-1)
        end
      end
    end
  end
  ------------------------------------------------------------------
  function Data_GetLastTouchedParam(conf, obj, data, refresh, mouse)
    data.LTP_hasLTP = false
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    if not retval then return end
    local tr if tracknumber == 0 then tr =  GetMasterTrack( 0 ) else tr = GetTrack(0,tracknumber-1) end
    data.LTP_hasLTP = true
    data.LTP_trGUID = GetTrackGUID( tr )
    data.LTP_trname = ({GetTrackName( tr )})[2]
    data.LTP_fxnumber = fxnumber
    data.LTP_paramnumber = paramnumber
    data.LTP_fxname =  ({TrackFX_GetFXName( tr, fxnumber, '' )})[2]
    data.LTP_paramname =  ({TrackFX_GetParamName( tr, fxnumber, paramnumber, '' )})[2]
    data.LTP_isvalid = data.LTP_fxname:match('MappingPanel') == nil
  end
  ------------------------------------------------------------------
  function Data_CollectSlaveRouting(data, conf, tr, fx_id)
    local retval, chunk = reaper.GetTrackStateChunk( tr, '', false )
    for section in chunk:gmatch('FXID.-WAK') do
      if section:match('PLINK') then
        local slaveFXGUID = section:match('%{(.-)%}')
        local ret, tr, slaveFX_id = VF_GetFXByGUID('{'..slaveFXGUID..'}', tr)
        for paramblock in section:gmatch('<(.-)>') do
          if paramblock:match('PLINK') then
            local slave_parid = tonumber(paramblock:match('PROGRAMENV (%d+)'))
            local plink_scale, plink_destfx_str, plink_param, plink_offset = paramblock:match('PLINK ([%d%p]+) ([%-%d]+.-) ([%d%p]+) ([%d%p]+)')
            plink_scale, plink_param, plink_offset = tonumber(plink_scale), tonumber(plink_param), tonumber(plink_offset) 
            if plink_destfx_str:match('%:') then -- not MIDI Link
              local plink_destfx, plink_destfx_offs = paramblock:match('PLINK [%d%p]+ ([%-%d]+)%:([%-%d]+) [%d%p]+ [%d%p]+')
              plink_destfx, plink_destfx_offs = tonumber(plink_destfx), tonumber(plink_destfx_offs)
              --msg(paramblock:match('PLINK [%d%p]+ [%-%d]+%:[%-%d]+ [%d%p]+ [%d%p]+'))
              
              -- pass data to table
              local masterlink = TrackFX_GetParam( tr, plink_destfx, plink_param+conf.slot_cnt )
              local flags = TrackFX_GetParam( tr, plink_destfx, plink_param+conf.slot_cnt*2 )
              local hexarray = TrackFX_GetParam( tr, plink_destfx, plink_param+conf.slot_cnt*3 )
              local src_slot = masterlink
              if src_slot >= 0 then 
                local masterJSFX_fxid = plink_destfx-plink_destfx_offs
                
                if not data.slots[src_slot] then data.slots[src_slot] = {} end
                
                data.slots[src_slot]  [#data.slots[src_slot]+1] = 
                  { trGUID = GetTrackGUID( tr ),
                    tr_pointer = tr,
                    trname = ({GetTrackName(tr)})[2],
                    JSFX_FXid = plink_destfx, 
                    JSFX_FXGUID = TrackFX_GetFXGUID( tr, plink_destfx ), 
                    JSFX_paramid = plink_param,
                    JSFX_param = TrackFX_GetParamNormalized( tr, plink_destfx, plink_param ),
                    Slave_FXGUID = '{'..slaveFXGUID..'}',
                    Slave_FXname =({ TrackFX_GetFXName( tr, slaveFX_id, '' )})[2],
                    Slave_FXid = slaveFX_id,
                    Slave_paramid = slave_parid,
                    Slave_paramname = ({ TrackFX_GetParamName( tr, slaveFX_id, slave_parid, '' )})[2],
                    Slave_param = TrackFX_GetParamNormalized( tr, slaveFX_id, slave_parid ),
                    Slave_paramformatted = ({TrackFX_GetFormattedParamValue( tr, slaveFX_id, slave_parid,'' )})[2],
                    flags = flags,
                    flags_mute = flags&1==1,
                    flags_tension = ((flags>>1)&0xF)/15,
                    hexarray = hexarray,
                    hexarray16 = string.format("%X", hexarray),
                    hexarray_lim_min = (hexarray&0xFF)/255,
                    hexarray_lim_max = ((hexarray>>8)&0xFF)/255,
                    hexarray_scale_min = ((hexarray>>16)&0xFF)/255,
                    hexarray_scale_max = ((hexarray>>24)&0xFF)/255,
                    hexarray_tension = ((hexarray>>32)&0xFF)/255,
                  }
                end
            end
          end
        end
      end
    end
  end
  ------------------------------------------------------------------
  function Data_GetSlaveValues(conf, obj, data, refresh, mouse)
    if not data.slots then return end
      for src_slot = 1, #data.slots do
        for child_link = 1, #data.slots[src_slot] do
          data.slots[src_slot][child_link].Slave_param = 
            TrackFX_GetParamNormalized( data.slots[src_slot][child_link].tr_pointer, 
                                        data.slots[src_slot][child_link].Slave_FXid, 
                                        data.slots[src_slot][child_link].Slave_paramid )
          data.slots[src_slot][child_link].Slave_paramformatted = 
            ({TrackFX_GetFormattedParamValue( data.slots[src_slot][child_link].tr_pointer, 
                                        data.slots[src_slot][child_link].Slave_FXid, 
                                        data.slots[src_slot][child_link].Slave_paramid,
                                        '' )     })[2]                                   
          data.slots[src_slot][child_link].JSFX_param = 
            TrackFX_GetParamNormalized( data.slots[src_slot][child_link].tr_pointer, 
                                        data.slots[src_slot][child_link].JSFX_FXid, 
                                        data.slots[src_slot][child_link].JSFX_paramid )
          local flags = TrackFX_GetParam(  data.slots[src_slot][child_link].tr_pointer,
                                              data.slots[src_slot][child_link].JSFX_FXid, 
                                              data.slots[src_slot][child_link].JSFX_paramid+conf.slot_cnt*2)                                                                                
          local hexarray = TrackFX_GetParam(  data.slots[src_slot][child_link].tr_pointer,
                                              data.slots[src_slot][child_link].JSFX_FXid, 
                                              data.slots[src_slot][child_link].JSFX_paramid+conf.slot_cnt*3)
          data.slots[src_slot][child_link].hexarray = hexarray
          data.slots[src_slot][child_link].hexarray16 = string.format("%X", hexarray)
          data.slots[src_slot][child_link].hexarray_lim_min = (hexarray&0xFF)/255
          data.slots[src_slot][child_link].hexarray_lim_max = ((hexarray>>8)&0xFF)/255
          data.slots[src_slot][child_link].hexarray_scale_min = ((hexarray>>16)&0xFF)/255
          data.slots[src_slot][child_link].hexarray_scale_max = ((hexarray>>24)&0xFF)/255
          data.slots[src_slot][child_link].flags = flags
          data.slots[src_slot][child_link].flags_tension = ((flags>>1)&0xF)/15                                         
        end
      end 
  end
  ------------------------------------------------------------------
  function Data_Update (conf, obj, data, refresh, mouse) 
    if refresh.data_minor then 
      Data_GetSlaveValues(conf, obj, data, refresh, mouse)
      refresh.data_minor = nil
      return
    end
    Data_ValidateMasterJSFX(conf, obj, data, refresh, mouse)
    Data_gmem_stuff(conf, obj, data, refresh, mouse)
    Data_ValidateSlaveJSFX(conf, obj, data, refresh, mouse)
    Data_GetLastTouchedParam(conf, obj, data, refresh, mouse)
  end

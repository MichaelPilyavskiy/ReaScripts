-- @description InfoTool_DataUpdate
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  -- mpl_InfoTool_DataUpdate.lua functions for mpl_InfoTool
  
  
  ---------------------------------------------------
  function DataUpdate(data, mouse, widgets, obj)
    --[[ 
      contexts for data.obj_type_int
        0 empty item
        1 MIDI item
        2 audio item
        3 multiple items 
    ]]
    
    data.rul_format = MPL_GetCurrentRulerFormat()
    data.SR = tonumber(reaper.format_timestr_pos(1, '', 4))
    data.FR = TimeMap_curFrameRate( 0 )
    data.obj_type = 'No object selected'
    data.obj_type_int = -1
    
    -- reset buttons data
    obj.b = {}
    
    -- item
      local item = GetSelectedMediaItem(0,0)
      if item then 
        DataUpdate_Item(data) 
        Obj_UpdateItem(data, obj, mouse, widgets)
        goto obj_upd
      end
      
    ::obj_upd::
    Obj_UpdateCom(data, mouse, obj)
  end
  ---------------------------------------------------
  function DataUpdate_Item(data, item)
    data.name = ''  
    data.it={}
    
    local obj_type
    for i = 1, CountSelectedMediaItems(0) do
      data.it[i] = {}
      local item = GetSelectedMediaItem(0,i-1)
          
      data.it[i].ptr_item = item
          
      data.it[i].item_pos = GetMediaItemInfo_Value( item, 'D_POSITION')
      data.it[i].item_len = GetMediaItemInfo_Value( item, 'D_LENGTH')
      data.it[i].snap_offs = GetMediaItemInfo_Value( item, 'D_SNAPOFFSET')
      data.it[i].item_pos_format = format_timestr_pos( data.it[i].item_pos, '', -1 ) 
      data.it[i].item_len_format = format_timestr_len( data.it[i].item_len, '', 0, -1 ) 
      data.it[i].snap_offs_format = format_timestr_len( data.it[i].snap_offs, '', 0, -1 )
                
      
      local take = GetActiveTake(item)
      if take then
        data.it[i].ptr_take = take
        local _, tk_name = GetSetMediaItemTakeInfo_String( take, "P_NAME", '', false )
        data.it[i].start_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        data.it[i].start_offs_format = format_timestr_len(data.it[i].start_offs, '', 0, -1 )
        data.it[i].name = tk_name
      end 
      
      
      if take then 
        if TakeIsMIDI(take) then 
          if obj_type then obj_type = 3 else obj_type = 1 end
         else 
          if obj_type then obj_type = 3 else obj_type = 2 end
        end
       else
        if obj_type then obj_type = 3 else obj_type = 0 end
      end
         
    end
    
    
    --  set obj type 
      if obj_type == 0 then 
          data.obj_type = 'Empty Item'
          data.obj_type_int = 0
       elseif obj_type == 1 then 
          data.obj_type = 'MIDI Item'
          data.obj_type_int = 1
       elseif obj_type == 2 then 
          data.obj_type = 'Audio Item' 
          data.obj_type_int = 2
       elseif obj_type == 3 then 
          data.obj_type = 'Items'
          data.obj_type_int = 3
      end
    
  end
  
  
  
   --[[env/AI
    env = GetSelectedEnvelope( 0 )
    if env then
      -- AI stuff        
        for ai_id  = 1, CountAutomationItems( env ) do            
          for pt = 1, CountEnvelopePointsEx( env, ai_id-1 ) do
            local _, _, _, _, _, selected = GetEnvelopePointEx( env, ai_id -1, pt-1 )
            if selected then DataUpdate_EnvPoint(env,  ai_id - 1, pt-1 ) msg(pt-1)return end
          end        
          local is_sel = GetSetAutomationItemInfo( env, ai_id-1, 'D_UISEL', -1, false )
          if is_sel > 0 then DataUpdate_AI(env, ai_id-1) return end
        end
        
      -- regular points
        for pt = 1, CountEnvelopePoints( env ) do
          local _, _, _, _, _, selected = GetEnvelopePoint( env, pt-1 )
          if selected then DataUpdate_EnvPoint(env, nil, pt-1) return end
        end
    end
  
  -- ruler evt      
    local ret = DataUpdate_Ruler(cur_pos)
    if ret then return end
    
  -- track
    local tr = GetSelectedTrack(0,0)
    if tr then DataUpdate_Track(tr) return  end]]
    --[[
    
  
  ---------------------------------------------------
  function DataUpdate_AI(env, ai_id)
    data.obj_type = ''
    data.obj_type = 'Automation item' 
    data.obj_type_int = 2
    data.name = ''
  end  
  ---------------------------------------------------
  function DataUpdate_EnvPoint(env, ai_id, pt_id)
    data.obj_type = 'Envelope point' 
    data.obj_type_int = 3
    data.name = ''
    if ai_id then       
      data.obj_type = 'AI Envelope point' 
      data.obj_type_int = 4
    end
  end   
  ---------------------------------------------------
  function DataUpdate_Ruler(cur_pos)
    -- tempo/timesig
      local tempomark = FindTempoTimeSigMarker( 0, cur_pos+0.001 )
      if tempomark > 0 then
        local retval, timeposOut, measureposOut, beatposOut, bpmOut, timesig_numOut, timesig_denomOut, lineartempoOut = GetTempoTimeSigMarker( 0, tempomark )
        local diff = math.abs(timeposOut - cur_pos)
        if diff < 0.1 then
          data.obj_type = 'Ruler event' 
          data.obj_type_int = 6
          data.name = ''
          return true      
        end
      end
      
      --markeridxOut retval, regionidxOut reaper.GetLastMarkerAndCurRegion( proj, time )
    
  end
  ---------------------------------------------------
  function DataUpdate_Track(tr)
    data.obj_type = 'Track' 
    data.obj_type_int = 5
    data.name = ''
    if tr then
      local retval, tr_name = GetTrackName( tr, '' )
      data.name = tr_name
    end
    
  end   
  
  ---------------------------------------------------
  
  ]]

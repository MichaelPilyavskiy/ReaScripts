-- @description Session view
-- @version 1.0alpha2
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about
--    Basic ableton session view port. Limitation: clip is hard snapped into scene by its length, so it is not completely free-running - it will be cut off by scene boundaries and triggerring clip triggers it from closer clip boundary, not the closest beat. Clips can`t be triggerer at exact same time.
-- @changelog
--    + HW feedback/Launchpad MK2: map Launchpad MK2



 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = {
    HWdata = {},
    retroactiveHW={},
    sheduled_actions = {},
    live = {},
    project_var = {}
    }
    
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '1.0alpha2'
    DATA.extstate.extstatesection = 'Session view'
    DATA.extstate.mb_title = 'Session view'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  800,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          CONF_templatecounttracks = 8,
                          CONF_templatecountsends = 2,
                          CONF_templatecountscenes = 8,
                          
                          CONF_scene_maxlength_measures = 256,
                          CONF_scene_space_measures = 64,
                          CONF_HWoutname ='LPMiniMK3 MIDI',
                          CONF_HWinname ='LPMiniMK3 MIDI',
                          CONF_sceneplaylistcheckclock = 0.1,
                                
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          
                          CONF_counttracksUI = 8, 
                          CONF_countscenesUI = 8,
                          
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
    
    -- read stuff
    DATA2:LiveProject_Validate()
    DATA2:LiveProject_ReadContent()
    
    --DATA.UPD = {onGUIinit=false}
    DATA2:HW_InitHardware()
    DATA2:HW_Send_ClearState()
    
    RUN()
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    DATA2.project_var.playstate = GetPlayStateEx( proj_ptr )&1==1 
    DATA2.project_var.playpos = GetPlayPosition2Ex( proj_ptr )
    
    DATA2:HW_ReceiveData()
    DATA2:SheduledActions_Perform()
    --DATA2:Scenes_HandlePlaylist()
    
    if DATA2.project_var.playstate==false and DATA2.project_var.playstate_last and DATA2.project_var.playstate_last == true then 
      DATA2:Scenes_Transport_OnStop() 
    end
    DATA2.project_var.playstate_last = DATA2.project_var.playstate
  end
  ----------------------------------------------------------------------
  function DATA2:SheduledActions_Perform()
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    local playing_position = DATA2.project_var.playpos
    
    for i=#DATA2.sheduled_actions,1,-1 do
      if playing_position - DATA2.sheduled_actions[i].pos > 0 and  playing_position - DATA2.sheduled_actions[i].pos < 0.3 then
        DATA2.sheduled_actions[i].func()
        table.remove(DATA2.sheduled_actions, i)
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA_RESERVED_ONPROJCHANGE(DATA)
    -- refresh project  state
    DATA2:LiveProject_Validate()
    if not DATA2.live.cached or (DATA2.live.cached and DATA2.live.cached == false)then 
      DATA2:LiveProject_ReadContent() 
      GUI_BuildUI(DATA)
    end
    
    -- refresh UI 
    GUI_MODULE_GRID_columns_Refresh(DATA)
    GUI_MODULE_GRID_scenes_Refresh(DATA)
    GUI_MODULE_GRID_clips_Refresh(DATA) 
    DATA.GUI.layers_refresh[2]=true -- update buttons
    
    -- refresh HW lights 
    DATA2:RefreshLights()
  end
  ---------------------------------------------------  
  function DATA2:RefreshLights()
    GUI_BuildLightObjects(DATA)
    DATA2:HW_Light_Refresh()  
  end
  ---------------------------------------------------------------------  
  function DATA2:Clip_Play_BuildScene(trID, sceneID) 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not (DATA2.live.scenes and 
            DATA2.live.scenes[sceneID] and
            DATA2.live.tracks and 
            DATA2.live.tracks[trID] and 
            DATA2.live.tracks[trID].scenes and 
            DATA2.live.tracks[trID].scenes[sceneID]
          ) then return end
    
    local trdata = DATA2.live.tracks[trID] 
    local scenepos = DATA2.live.scenes[sceneID].pos_ST
    local sceneend = DATA2.live.scenes[sceneID].pos_EN 
    
    local track = VF_GetTrackByGUID (trdata.GUID,proj_ptr) 
    if not track then return end
    local srcdata = DATA2.live.tracks[trID].scenes[sceneID]
    
    -- add first item
    local destlen = srcdata.itlen 
    local item = AddMediaItemToTrack( track )
    local take = AddTakeToMediaItem( item )
    SetMediaItemInfo_Value( item, 'D_POSITION', scenepos )
    SetMediaItemInfo_Value( item, 'D_LENGTH', destlen )
    SetMediaItemInfo_Value( item, 'B_MUTE', 1)
    SelectAllMediaItems( proj_ptr, false ) SetMediaItemInfo_Value( item, 'B_UISEL', 1) -- set only item selected
    SetMediaItemTake_Source( take, srcdata.pcmsrc )
    GetSetMediaItemInfo_String( item, 'P_EXT:MPLSESVIEW_ITEM_ISCLIP', 1, true ) -- handled by script
    GetSetMediaItemInfo_String( item, 'P_EXT:MPLSESVIEW_ITEM_SLAVE', 1, true ) -- handled by script as slave
    GetSetMediaItemInfo_String( item, 'P_EXT:MPLSESVIEW_ITEM_SCENE', sceneID, true ) -- refer to defined scene
    UpdateArrange()
    
    -- nudge
    local copies = math.floor((sceneend - scenepos) / destlen)-1
    local nudgeunits = 1 -- sec
    local value = destlen
    ApplyNudge( proj_ptr, 0, 5, nudgeunits, value, false, copies ) 
  end
  ---------------------------------------------------------------------  
  function DATA2:Clip_Play_RefreshScene(trID, sceneID, force_refresh) 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not (DATA2.live.scenes and 
            DATA2.live.scenes[sceneID] and
            DATA2.live.tracks and 
            DATA2.live.tracks[trID] and 
            DATA2.live.tracks[trID].scenes and 
            DATA2.live.tracks[trID].scenes[sceneID]
          ) then return end
          
    local trdata = DATA2.live.tracks[trID] 
    local scenepos = DATA2.live.scenes[sceneID].pos_ST
    local sceneend = DATA2.live.scenes[sceneID].pos_EN 
    local track = VF_GetTrackByGUID (trdata.GUID,proj_ptr) 
    if not track then return end 
    
    -- 
    -- check if slave items exist
    local exist 
    local cntit = CountTrackMediaItems( track )
    for itemidx = cntit, 1, -1 do
      local it = GetTrackMediaItem( track, itemidx-1 )
      local isclip = DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_ISCLIP')
      local isslave =DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_SLAVE')
      local hasscene, sceneIDext =DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_SCENE')
      if isclip and isslave and hasscene and sceneIDext == sceneID then 
        if force_refresh then
          DeleteTrackMediaItem( track, it ) 
         else 
          exist = true
          break
        end
      end
    end
    
    if not exist or force_refresh then
      DATA2:Clip_Play_BuildScene(trID, sceneID)  
      UpdateArrange()
    end
    
    --[[local pos = GetMediaItemInfo_Value( it, 'D_POSITION' )
    local len = GetMediaItemInfo_Value( it, 'D_LENGTH' )
    local iend = pos+len
    local match_scene_boundary =  
      (pos>=scenepos and pos<=sceneend)
      or (iend>=scenepos and iend<=sceneend)
      or (pos<=scenepos and iend>=sceneend)
    if match_scene_boundary then ]]
  end
  ---------------------------------------------------------------------
  function DATA2:Clip_SetState(trID, sceneID, state, cleanotherstates, addbit)
    if cleanotherstates then -- set play directly (==2) or both play/transition(==1|2)
      for sceneID_exist in pairs(DATA2.live.tracks[trID].scenes) do DATA2.live.tracks[trID].scenes[sceneID_exist].state = 0 end
    end 
    if sceneID and state then DATA2.live.tracks[trID].scenes[sceneID].state =state end 
    if addbit then DATA2.live.tracks[trID].scenes[sceneID].state =DATA2.live.tracks[trID].scenes[sceneID].state|addbit end
  end
  ---------------------------------------------------------------------  
  function DATA2:Clip_Play_Enable(trID, sceneID, pos, disable) 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not (DATA2.live.scenes and 
            DATA2.live.scenes[sceneID] and
            DATA2.live.tracks and 
            DATA2.live.tracks[trID] and 
            DATA2.live.tracks[trID].scenes and 
            DATA2.live.tracks[trID].scenes[sceneID]
          ) then return end
          
    local trdata = DATA2.live.tracks[trID] 
    --local scenepos = DATA2.live.scenes[sceneID].pos_ST
    --local sceneend = DATA2.live.scenes[sceneID].pos_EN 
    local track = VF_GetTrackByGUID (trdata.GUID,proj_ptr) 
    if not track then return end 
    
    local first_enabled_pos = math.huge
    local cntit = CountTrackMediaItems( track )
    for itemidx = cntit, 1, -1 do
      local it = GetTrackMediaItem( track, itemidx-1 )
      local isclip = DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_ISCLIP')
      local isslave =DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_SLAVE')
      local hasscene, sceneIDext =DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_SCENE')
      if isclip and isslave and hasscene and sceneIDext == sceneID then 
        local itpos =  GetMediaItemInfo_Value( it, 'D_POSITION' )
        if pos and itpos-0.01 >= pos then 
          first_enabled_pos = math.min(first_enabled_pos,itpos)
        end
        if not pos or (pos and itpos-0.01 >= pos) then 
          if disable then SetMediaItemInfo_Value( it, 'B_MUTE' ,1) else SetMediaItemInfo_Value( it, 'B_MUTE' ,0)  end
          UpdateItemInProject( it )
        end
      end
    end
    
    return first_enabled_pos
  end
  ---------------------------------------------------------------------
  function DATA2:Scenes_play_initfromstop(proj_ptr, sceneID,donottriggerfollowedscened)
    DATA2:Scenes_ClearRegions() 
    local pos = TimeMap2_beatsToTime( proj_ptr, 0, DATA2.live.scenes[sceneID].pos_ST_measures )
    local rgnend = TimeMap2_beatsToTime( proj_ptr, 0, DATA2.live.scenes[sceneID].pos_EN_measures )
    AddProjectMarker2( proj_ptr, true, pos, rgnend, 'SCENE_CURRENT S'..sceneID, -1, 0 )
    GetSet_LoopTimeRange2( proj_ptr, true, true, pos, rgnend, true )
    
    if not donottriggerfollowedscened then
      for trID in pairs(DATA2.live.tracks) do if DATA2.live.tracks[trID].scenes and DATA2.live.tracks[trID].scenes[sceneID] then DATA2:Clip_Play(trID, sceneID) end end
    end
    
    DATA2:Scenes_Transport_OnPlay(pos)
    DATA2:Scenes_SetState(sceneID, 2, true)
    DATA2:RefreshLights()
    
  end
  ---------------------------------------------------------------------  
  function DATA2:Clip_Play(trID, sceneID, allowtriggerscene) 
    if not (trID and sceneID) then return end
    
    -- trigger from stop
      local playstate = DATA2.project_var.playstate
      if playstate == false and allowtriggerscene then  
        DATA2:Clip_Play_RefreshScene(trID, sceneID) 
        DATA2:Clip_Play_Enable(trID, sceneID) 
        DATA2:Clip_SetState(trID, sceneID, 2, true) 
        -- mute other track clips in current scene
        for trID_2 in pairs(DATA2.live.tracks) do 
          for sceneID_2 in pairs(DATA2.live.tracks[trID].scenes) do
            if sceneID_2 == sceneID and trID_2 ~= trID then DATA2:Clip_Play_Enable(trID_2, sceneID_2, nil, true) end
          end
        end
        -- trigger scene
        DATA2:Scenes_play(sceneID, true)
        return
      end
      
    -- triggered from scene launch while playing
      if playstate == false and not allowtriggerscene then  
        DATA2:Clip_Play_RefreshScene(trID, sceneID) 
        DATA2:Clip_Play_Enable(trID, sceneID) 
        DATA2:Clip_SetState(trID, sceneID, 2) 
        return
      end
      
    
    -- schedule while playing
      DATA2:Clip_Play_RefreshScene(trID, sceneID) 
      local state = DATA2.live.tracks[trID].scenes[sceneID].state
      if state == 0 then 
        DATA2:Clip_SetState(trID, sceneID, 1)
        DATA2:RefreshLights()
        local first_enabled_pos = DATA2:Clip_Play_Enable(trID, sceneID, DATA2.project_var.playpos)  
        if first_enabled_pos then 
          DATA2.sheduled_actions[#DATA2.sheduled_actions+1] = {pos = first_enabled_pos, func = function() 
            DATA2:Clip_SetState(trID, sceneID, 2, true) 
            DATA2:Clip_Play_Enable(trID, sceneID) 
            DATA2:RefreshLights()
          end}
        end
      end
    
  end
  
  ---------------------------------------------------------------------  
  function DATA2:Clip_ActionSwitch(trID, sceneID, triggeredfromHW) 
    if not DATA2.live.scenes[sceneID] then return end -- make sure scene is valid
    if not DATA2.live.tracks[trID] then return end -- make sure track is valid
    local has_imported_item = DATA2.live.tracks[trID].scenes and DATA2.live.tracks[trID].scenes[sceneID]
    if has_imported_item then
      DATA2:Clip_Play(trID, sceneID, true) 
     else 
      if not triggeredfromHW then
        local f = function()DATA2:Clip_Import(trID, sceneID) end
        DATA2:ProcessUndoBlock(f, 'Import scene '..sceneID..' trID '..trID, trID, sceneID) 
      end
    end 
    --DATA.UPD.onGUIinit = true 
    DATA.UPD.onprojstatechange = true
    --DATA2.live.cached = false
  end 
  ---------------------------------------------------------------------  
  function DATA2:Clip_Import(trID, sceneID) 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    -- get source item
    local srcproj_ptr, projfn = EnumProjects(-1)
    local item = GetSelectedMediaItem( srcproj_ptr, 0 )
    if not item then return end
    local retval, chunk = reaper.GetItemStateChunk( item, '', false )
    
    -- insert item
    local tr = VF_GetTrackByGUID (DATA2.live.tracks[trID].GUID,proj_ptr)
    if not tr then return end
    local new_item = AddMediaItemToTrack( tr )
    SetItemStateChunk( new_item, chunk, false )
    SetMediaItemInfo_Value( new_item, 'B_MUTE', 1 )
    SetMediaItemInfo_Value( new_item, 'C_LOCK', 1 )
    SetMediaItemInfo_Value( new_item, 'D_POSITION', 0 ) 
    SetMediaItemInfo_Value( new_item, 'I_CUSTOMCOLOR', ColorToNative(0,0,0)|0x1000000 ) -- color black
    GetSetMediaItemInfo_String( new_item, 'P_EXT:MPLSESVIEW_ITEM_ISCLIP', 1, true ) -- handled by script
    GetSetMediaItemInfo_String( new_item, 'P_EXT:MPLSESVIEW_ITEM_MASTER', 1, true ) -- handled by script as loop source
    GetSetMediaItemInfo_String( new_item, 'P_EXT:MPLSESVIEW_ITEM_SCENE', sceneID, true ) -- refer to defined scene
    UpdateItemInProject( new_item )
    
    -- share to region
    local scene_ST = DATA2.live.scenes[sceneID].pos_ST_measures
    local scene_EN = DATA2.live.scenes[sceneID].pos_EN_measures
    local pos_sec =  TimeMap2_beatsToTime( proj_ptr, 0, scene_ST )
    --SetMediaItemInfo_Value( new_item, 'D_POSITION', pos_sec )  -- place source item u=into region start
  
    
    DATA2:LiveProject_ReadContent_SceneClipsAdd(trID,sceneID,new_item)
  end
  ---------------------------------------------------------------------  
  function DATA2:Clip_Stop(trID, sceneID) 
    DATA2:LiveProject_ExtState_Write(trID, sceneID, 0) 
    --[[msg('stop')
    msg('trID')
    msg('sceneID')]]
  end
  ---------------------------------------------------------------------  
  function DATA2:Scenes_Transport_OnStop() 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end 
    OnStopButtonEx( proj_ptr )
    DATA2:Scenes_ClearRegions()  
    DATA2:Scenes_SetState(nil,nil,true)
    for trID in pairs(DATA2.live.tracks) do DATA2:Clip_SetState(trID, nil, nil, true) end
    DATA2:HW_Light_Refresh() 
  end
  ---------------------------------------------------------------------  
  function DATA2:Scenes_GetCurrentRegion()
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not DATA2.live and DATA2.live.scenes then return end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:Scenes_SetCurrentRegion()
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not DATA2.live and DATA2.live.scenes then return end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:Scenes_ClearRegions(name_to_remove)   
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    
    local retval, num_markers, num_regions = CountProjectMarkers(proj_ptr)
    for markrgnidx = num_markers+num_regions,1,-1 do 
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers2(proj_ptr, markrgnidx-1 )
      if (isrgn and not name_to_remove) or (isrgn and name_to_remove and name:match(literalize(name_to_remove))) then DeleteProjectMarkerByIndex( proj_ptr, markrgnidx-1 ) end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:Scenes_Transport_OnPlay(pos) 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    
    if pos then SetEditCurPos2( proj_ptr, pos, true, false ) end
    OnPlayButtonEx( proj_ptr )
    GetSetRepeatEx( proj_ptr, 1 )
  end
  ---------------------------------------------------------------------
  function DATA2:Scenes_SetState(sceneID0, state, cleanotherstates,addbit)
    if cleanotherstates then -- set play directly (==2) or both play/transition(==1|2)
      for sceneID in pairs(DATA2.live.scenes) do DATA2.live.scenes[sceneID].state = 0 end
    end
    if state then DATA2.live.scenes[sceneID0].state =state end
    if addbit then DATA2.live.scenes[sceneID0].state =DATA2.live.scenes[sceneID0].state|addbit end
  end
  ---------------------------------------------------------------------
  function DATA2:Scenes_play_shedulequere(proj_ptr, sceneID, currentID) 
    local playing_position = DATA2.project_var.playpos
    DATA2:Scenes_ClearRegions() 
    
    -- set full scene as quered
      local pos = TimeMap2_beatsToTime( proj_ptr, 0, DATA2.live.scenes[sceneID].pos_ST_measures )
      local rgnend = TimeMap2_beatsToTime( proj_ptr, 0, DATA2.live.scenes[sceneID].pos_EN_measures )
      AddProjectMarker2( proj_ptr, true, pos, rgnend, 'SCENE_QUERED S'..sceneID, -1, 0 )  
      GetSet_LoopTimeRange2( proj_ptr, true, true, pos, rgnend, true ) 
    
    -- prepare clips
      for trID in pairs(DATA2.live.tracks) do 
        if DATA2.live.tracks[trID].scenes and DATA2.live.tracks[trID].scenes[sceneID] then 
          DATA2:Clip_Play_RefreshScene(trID, sceneID) 
          DATA2:Clip_Play_Enable(trID, sceneID) 
          DATA2:Clip_SetState(trID, sceneID, nil, nil, 1)
        end
      end
    
    -- chedule change at reachin start region start
      DATA2.sheduled_actions[#DATA2.sheduled_actions+1] = {pos = pos, func = function() 
        DATA2:Scenes_ClearRegions() 
        local pos = TimeMap2_beatsToTime( proj_ptr, 0, DATA2.live.scenes[sceneID].pos_ST_measures )
        local rgnend = TimeMap2_beatsToTime( proj_ptr, 0, DATA2.live.scenes[sceneID].pos_EN_measures )
        AddProjectMarker2( proj_ptr, true, pos, rgnend, 'SCENE_CURRENT S'..sceneID, -1, 0 ) 
        DATA2:Scenes_SetState(sceneID, 2, true)
        -- set scheduled scene clips clips
          for trID in pairs(DATA2.live.tracks) do 
            if DATA2.live.tracks[trID].scenes and DATA2.live.tracks[trID].scenes[sceneID] then 
              DATA2:Clip_SetState(trID, sceneID, 2, true)
            end
          end 
        -- set scheduled scene clips clips
          for trID in pairs(DATA2.live.tracks) do 
            if DATA2.live.tracks[trID].scenes and DATA2.live.tracks[trID].scenes[currentID] then 
              DATA2:Clip_SetState(trID, currentID, 0)
            end
          end           
        DATA2:RefreshLights()
      end}
    
    -- limit current to its start  
      local pos = playing_position--TimeMap2_beatsToTime( proj_ptr, 0, DATA2.live.scenes[sceneID].pos_ST_measures )
      local retval, play_measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( proj_ptr, playing_position) 
      local rgnend = TimeMap2_beatsToTime( proj_ptr, 0, play_measures+2 )--quantize to N measure
      AddProjectMarker2( proj_ptr, true, pos, rgnend, 'SCENE_CURRENT S'..sceneID, -1, 0 ) 
    
    -- set quered to prev/next by GoToRegion
      local gotomarker
      local retval, num_markers, num_regions = CountProjectMarkers(proj_ptr)
      for markrgnidx = num_markers+num_regions,1,-1 do 
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers2( proj_ptr,markrgnidx-1 )
        if isrgn==true and name:match('SCENE_QUERED')then gotomarker = markrgnindexnumber break end
      end
      if gotomarker then GoToRegion( proj_ptr, gotomarker, false)  end
    
    -- set flags
      --DATA2:Scenes_SetState(currentID, nil,nil,1)
      DATA2:Scenes_SetState(sceneID, nil,nil,1)
      DATA2:RefreshLights()
  end
  ---------------------------------------------------------------------
  function DATA2:Scenes_play(sceneID,donottriggerfollowedscened)
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not (DATA2.live and DATA2.live.scenes and DATA2.live.scenes[sceneID]) then return end
    
    local playstate = DATA2.project_var.playstate
    local currentID  for scene in pairs(DATA2.live.scenes) do if DATA2.live.scenes[scene].state == 2 then currentID = scene  break end end
    
    -- if not current region - set it as current, trigger play 
      if not playstate or (playstate and not currentID)then DATA2:Scenes_play_initfromstop(proj_ptr, sceneID,donottriggerfollowedscened)  return end 
    
    -- if has current region
    -- cut current to curpos + 2 measures
    -- if active== current, schedule retrigger
    -- if active~= current, schedule quered
      if DATA2.live.scenes[sceneID].state==0 or DATA2.live.scenes[sceneID].state&2==2 then DATA2:Scenes_play_shedulequere(proj_ptr, sceneID, currentID) return end
  end 
  
  ---------------------------------------------------------------------  
  function GUI_BuildUI(DATA)
    GUI_MODULE_SETTINGS(DATA)
    GUI_MODULE_INITFALED(DATA)  
    GUI_MODULE_GRID(DATA)
    GUI_MODULE_GRID_columns(DATA) 
    GUI_MODULE_GRID_scenes(DATA)  
    GUI_MODULE_GRID_clips(DATA)
    if not DATA.GUI.layers_refresh  then DATA.GUI.layers_refresh = {} end 
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
      DATA.GUI.custom_referenceH = 250
      DATA.GUI.custom_Yrelation = math.max(gfx_h/DATA.GUI.custom_referenceH, 0.5) -- global W
      DATA.GUI.custom_Yrelation = math.min(DATA.GUI.custom_Yrelation, 1) -- global W
      DATA.GUI.custom_offset =  math.floor(6 * DATA.GUI.custom_Yrelation)
      --DATA.GUI.default_scale = 1
    
    -- grid
      DATA.GUI.custom_gridw = DATA.GUI.custom_gfx_wreal - DATA.GUI.custom_offset*2
      DATA.GUI.custom_gridcell_w = math.floor(DATA.GUI.custom_gridw/(DATA.extstate.CONF_counttracksUI + 1))
      DATA.GUI.custom_gridcell_h = math.floor(25*DATA.GUI.custom_Yrelation) 
      DATA.GUI.custom_gridh = DATA.GUI.custom_gfx_hreal - DATA.GUI.custom_offset*3 - DATA.GUI.custom_gridcell_h 
      DATA.GUI.custom_txtsz_grid = math.floor(14*DATA.GUI.custom_Yrelation) -- grid cells
      DATA.GUI.custom_grid_x_offs = DATA.GUI.custom_offset 
      DATA.GUI.custom_grid_y_offs = DATA.GUI.custom_gridcell_h + DATA.GUI.custom_offset*2
      DATA.GUI.custom_gridcell_framea_inactive = 0.1
      DATA.GUI.custom_gridcell_framea_selcontrols = 0.3
      DATA.GUI.custom_gridcell_backgr_fillscenes = 0.1
      DATA.GUI.custom_gridcell_recttxta = 0.9
      DATA.GUI.custom_gridcell_controlw = math.floor(13*DATA.GUI.custom_Yrelation) 
      
    -- init button stuff
      DATA.GUI.custom_infobuth = DATA.GUI.custom_gridcell_h
      DATA.GUI.custom_infobut_w = DATA.GUI.custom_gridcell_w
      DATA.GUI.custom_txtsz1 = math.floor(15*DATA.GUI.custom_Yrelation) -- menu
      DATA.GUI.custom_txta = 1
      DATA.GUI.custom_txta_disabled = 0.3
      
      
      
    -- settings
      if not DATA.GUI.Settings_open then DATA.GUI.Settings_open = 0  end
      local x_offs = DATA.GUI.custom_offset
      DATA.GUI.buttons.settings = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_infobut_w-2,
                            h=DATA.GUI.custom_infobuth-1,
                            txt = '>',
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --frame_a = 1,
                            onmouseclick = function()
                              if DATA.GUI.Settings_open then DATA.GUI.Settings_open = math.abs(1-DATA.GUI.Settings_open) else DATA.GUI.Settings_open = 1 end 
                              DATA.UPD.onGUIinit = true
                            end,
                            }
      x_offs = x_offs + DATA.GUI.custom_infobut_w
      DATA.GUI.buttons.actions = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_infobut_w-2,
                            h=DATA.GUI.custom_infobuth-1,
                            txt = 'Actions',
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --frame_a = 1,
                            onmouseclick = function()
                              DATA:GUImenu(DATA2:Actions_Menu())
                              
                            end,
                            } 
      x_offs = x_offs + DATA.GUI.custom_infobut_w
      DATA.GUI.buttons.onstop = { x=x_offs,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_infobut_w-2,
                            h=DATA.GUI.custom_infobuth-1,
                            txt = 'Stop',
                            txt_fontsz = DATA.GUI.custom_txtsz1,
                            --frame_a = 1,
                            onmouseclick = function()
                              DATA2:Scenes_Transport_OnStop()
                            end,
                            }                              
                               
    GUI_BuildUI(DATA)
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ---------------------------------------------------------------------  
  function GUI_MODULE_SETTINGS(DATA)
    if not DATA.GUI.buttons then return end
      for key in pairs(DATA.GUI.buttons) do if key:match('Rsettings') then DATA.GUI.buttons[key] = nil end end
      if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {} end DATA.GUI.layers[21].a = 0 -- reset settings
      if DATA.GUI.Settings_open ==0 then return end 
      DATA.GUI.buttons.Rsettings = { x=0,
                            y=DATA.GUI.custom_infobuth + DATA.GUI.custom_offset,
                            w=gfx.w/DATA.GUI.default_scale,
                            h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_infobuth-DATA.GUI.custom_offset,
                            txt = 'Settings',
                            frame_a = 0,
                            offsetframe = DATA.GUI.custom_offset,
                            offsetframe_a = 0.1,
                            ignoremouse = true,
                            refresh = true,
                            }
      DATA:GUIBuildSettings()
    end
  ----------------------------------------------------------------------------- 
  function GUI_MODULE_INITFALED(DATA)
    if not DATA.GUI.buttons then return end
    for key in pairs(DATA.GUI.buttons) do if key:match('initfalse') then DATA.GUI.buttons[key] = nil end end
    if DATA2.proj_is_valid == true then return end
    if DATA.GUI.Settings_open ==1 then return end
    DATA.GUI.buttons['initfalse_info'] = { 
                          x=DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_infobuth + DATA.GUI.custom_offset*2,
                          w=DATA.GUI.custom_infobut_w*3,
                          h=DATA.GUI.custom_infobuth,
                          txt = '[Active live project not opened]',
                          txt_fontsz = DATA.GUI.custom_txtsz1,
                          ignoremouse = true,--frame_a =DATA.GUI.custom_framea,
                          --frame_col = '#333333',
                          onmouseclick = function() 
                          
                          end,
                          } 
                          
    local txt = 'Create'
    if DATA2.proj_is_found then txt = 'Open' else  end
    DATA.GUI.buttons['initfalse_open'] = { 
                          x=DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_infobuth*2 + DATA.GUI.custom_offset*3,
                          w=DATA.GUI.custom_infobut_w*3,
                          h=DATA.GUI.custom_infobuth,
                          txt = txt,
                          txt_fontsz = DATA.GUI.custom_txtsz1,
                          onmouseclick = function() DATA2:LiveProject_CreateOpenLiveProject() end,
                          }   
      
  end    
  --------------------------------------------------------------------- 
  function GUI_MODULE_GRID_columns_Refresh(DATA)
    if not DATA.GUI.buttons then return end
    if DATA2.proj_is_valid ~= true then return end
    if DATA.GUI.Settings_open ==1 then return end 
    for trID = 1, DATA.extstate.CONF_counttracksUI do
      local txt = ''
      local backgr_fill = 0
      local frame_a = DATA.GUI.custom_gridcell_framea_inactive
      if DATA2.live and DATA2.live.tracks and DATA2.live.tracks[trID] then 
        txt = DATA2.live.tracks[trID].name
        backgr_fill = DATA.GUI.custom_gridcell_backgr_fillscenes
        frame_a = 0.5
      end
      if DATA.GUI.buttons['grid_col_'..trID] then
        DATA.GUI.buttons['grid_col_'..trID].txt = txt
        DATA.GUI.buttons['grid_col_'..trID].backgr_fill = backgr_fill
        DATA.GUI.buttons['grid_col_'..trID].frame_a = frame_a
        DATA.GUI.buttons['grid_col_'..trID].frame_asel = frame_a
      end
    end
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_GRID_columns(DATA)
    if not DATA.GUI.buttons then return end
    if DATA2.proj_is_valid ~= true then return end
    if DATA.GUI.Settings_open ==1 then return end
    -- generate columns
      local track_display_offset = 0
      for trID = 1, DATA.extstate.CONF_counttracksUI do
        local txt = ''
        local backgr_fill = 0
        local frame_a = DATA.GUI.custom_gridcell_framea_inactive
        DATA.GUI.buttons['grid_col_'..trID] = { 
                              x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*(trID-1),
                              y=1+DATA.GUI.custom_grid_y_offs,
                              w=DATA.GUI.custom_gridcell_w-2,
                              h=DATA.GUI.custom_gridcell_h-2,
                              txt = txt,
                              txt_a = 1,
                              txt_fontsz=DATA.GUI.custom_txtsz_grid,
                              backgr_fill = backgr_fill,
                              backgr_col = '#FFFFFF',
                              frame_a = frame_a,
                              frame_asel = frame_a,
                              onmouseclick = function() DATA2:Action_TrackContextMenu(trID)  end,
                              } 
      end
      
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_GRID_clips_Refresh(DATA)
    if not (DATA2.live and DATA2.live.scenes) then return end 
    if not DATA.GUI.buttons then return end
    if DATA2.proj_is_valid ~= true then return end
    if DATA.GUI.Settings_open ==1 then return end
    -- items/clips
    for sceneID = 1, DATA.extstate.CONF_countscenesUI do
      for trID = 1, DATA.extstate.CONF_counttracksUI do 
        local activecell 
        local txtsign = '+'
        local cellname
        if DATA2.live.tracks and DATA2.live.tracks[trID] and DATA2.live.tracks[trID].scenes and DATA2.live.tracks[trID].scenes[sceneID] then activecell = DATA2.live.tracks[trID].scenes[sceneID] end
        if activecell then 
          if activecell then txtsign = '>' end
          cellname = DATA2.live.tracks[trID].scenes[sceneID].name
        end
        -- txt
        if DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L4txt'] then 
          DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L4txt'].txt = cellname
        end
        -- trig button
        if DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L3sign'] then 
          DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L3sign'].txt = txtsign
          DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L3sign'].onmouseclick = function() DATA2:Clip_ActionSwitch(trID, sceneID) end
        end
        -- frame
        if DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'] then 
          DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'].txt = txt
          DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'].onmousereleaseR = function() DATA:GUImenu(
            {
              {str = 'Refresh clip at scene',
              func = function () DATA2:Clip_Play_RefreshScene(trID, sceneID, true) end
              }
            }
          ) end
        end
        
      end
    end
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_GRID_clips(DATA)
    if not (DATA2.live and DATA2.live.scenes) then return end 
    if not DATA.GUI.buttons then return end
    if DATA2.proj_is_valid ~= true then return end
    if DATA.GUI.Settings_open ==1 then return end
    -- items/clips
    for sceneID = 1, DATA.extstate.CONF_countscenesUI do
      for trID = 1, DATA.extstate.CONF_counttracksUI do 
        local activecell 
        local txtsign = ''
        local cellname
        DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L4txt'] = { 
                          x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*(trID-1)+DATA.GUI.custom_gridcell_controlw,
                          y=1+DATA.GUI.custom_grid_y_offs+DATA.GUI.custom_gridcell_h*(sceneID),
                          w=DATA.GUI.custom_gridcell_w-2-DATA.GUI.custom_gridcell_controlw,
                          h=DATA.GUI.custom_gridcell_h-2,
                          txt = cellname,
                          txt_a = DATA.GUI.custom_gridcell_recttxta,
                          txt_fontsz=DATA.GUI.custom_txtsz_grid,
                          backgr_fill = 0,
                          frame_a = 0, 
                          txt_flags = 4,
                          ignoremouse = true,
                          } 
        DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L3sign'] = { 
                          x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*(trID-1),
                          y=1+DATA.GUI.custom_grid_y_offs+DATA.GUI.custom_gridcell_h*(sceneID),
                          w=DATA.GUI.custom_gridcell_controlw-2,
                          h=DATA.GUI.custom_gridcell_h-2,
                          txt = txtsign,
                          txt_a = DATA.GUI.custom_gridcell_recttxta,
                          txt_fontsz=DATA.GUI.custom_txtsz_grid,
                          backgr_fill = 0,
                          frame_a = 0,  
                          frame_asel = DATA.GUI.custom_gridcell_framea_selcontrols,  
                          } 
        DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'] = { 
                          x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*(trID-1),
                          y=1+DATA.GUI.custom_grid_y_offs+DATA.GUI.custom_gridcell_h*(sceneID),
                          w=DATA.GUI.custom_gridcell_w-2,
                          h=DATA.GUI.custom_gridcell_h-2,
                          txt = txt,
                          txt_a = 1,
                          txt_fontsz=DATA.GUI.custom_txtsz_grid,
                          --backgr_fill = backgr_fill,
                          frame_a = DATA.GUI.custom_gridcell_framea_inactive, 
                          frame_asel = DATA.GUI.custom_gridcell_framea_inactive,
                          
                          }                           
      end
    end
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_GRID_scenes_Refresh(DATA)
    if not (DATA2.live and DATA2.live.scenes) then return end 
    if not DATA.GUI.buttons then return end
    if DATA2.proj_is_valid ~= true then return end
    if DATA.GUI.Settings_open ==1 then return end
    
    
    -- clear
    for sceneID = 1, DATA.extstate.CONF_countscenesUI do  
      if DATA.GUI.buttons['grid_scene_'..sceneID..'L4txt'] then 
        local scenename = sceneID
        DATA.GUI.buttons['grid_scene_'..sceneID..'L4txt'].txt = '' 
      end
      if DATA.GUI.buttons['grid_scene_'..sceneID..'L3sign'] then 
        DATA.GUI.buttons['grid_scene_'..sceneID..'L3sign'].txt = '' 
      end
    end
    
    --scene triggers
    for sceneID = 1, DATA.extstate.CONF_countscenesUI do
      if DATA2.live.scenes[sceneID] then
        if DATA.GUI.buttons['grid_scene_'..sceneID..'L4txt'] then 
          local scenename = sceneID
          DATA.GUI.buttons['grid_scene_'..sceneID..'L4txt'].txt = scenename 
        end
        if DATA.GUI.buttons['grid_scene_'..sceneID..'L3sign'] then 
          DATA.GUI.buttons['grid_scene_'..sceneID..'L3sign'].txt = '>' 
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_GRID_scenes(DATA)
    if not (DATA2.live and DATA2.live.scenes) then return end 
    if not DATA.GUI.buttons then return end
    if DATA2.proj_is_valid ~= true then return end
    if DATA.GUI.Settings_open ==1 then return end
    
    DATA.GUI.buttons['grid_col_scenes'] = { 
                          x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*DATA.extstate.CONF_counttracksUI,
                          y=1+DATA.GUI.custom_grid_y_offs,
                          w=DATA.GUI.custom_gridcell_w-2,
                          h=DATA.GUI.custom_gridcell_h-2,
                          txt = 'Scenes',
                          txt_a = 1,
                          --txt_fontsz=DATA.GUI.custom_txtsz_grid,
                          backgr_fill = DATA.GUI.custom_gridcell_backgr_fillscenes,
                          backgr_col = '#FFFFFF',
                          --frame_a = frame_a,
                          onmouseclick = function()  end,
                          }
                          
    --scene triggers
    for sceneID = 1, DATA.extstate.CONF_countscenesUI do
      DATA.GUI.buttons['grid_scene_'..sceneID..'L4txt'] = { 
                          x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*(DATA.extstate.CONF_counttracksUI)+DATA.GUI.custom_gridcell_controlw,
                          y=1+DATA.GUI.custom_grid_y_offs+DATA.GUI.custom_gridcell_h*(sceneID),
                          w=DATA.GUI.custom_gridcell_w-2-DATA.GUI.custom_gridcell_controlw,
                          h=DATA.GUI.custom_gridcell_h-2,
                          txt = '',
                          txt_a = DATA.GUI.custom_gridcell_recttxta, 
                          txt_fontsz=DATA.GUI.custom_txtsz_grid,
                          backgr_fill = 0,
                          frame_a =0,
                          txt_flags = 4,
                          ignoremouse = true,
                          onmouseclick = function()  end,
                          } 
      DATA.GUI.buttons['grid_scene_'..sceneID..'L3sign'] = { 
                          x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*(DATA.extstate.CONF_counttracksUI),
                          y=1+DATA.GUI.custom_grid_y_offs+DATA.GUI.custom_gridcell_h*(sceneID),
                          w=DATA.GUI.custom_gridcell_controlw-2,
                          h=DATA.GUI.custom_gridcell_h-2,
                          txt = '', 
                          txt_a = DATA.GUI.custom_gridcell_recttxta,
                          txt_fontsz=DATA.GUI.custom_txtsz_grid,
                          backgr_fill = 0,
                          frame_a =0,
                          frame_asel = DATA.GUI.custom_gridcell_framea_selcontrols,
                          onmouseclick = function() 
                            DATA2:Scenes_play(sceneID)
                          end,
                          } 
      DATA.GUI.buttons['grid_scene_'..sceneID..'L2back'] = { 
                          x=1+DATA.GUI.custom_grid_x_offs+DATA.GUI.custom_gridcell_w*(DATA.extstate.CONF_counttracksUI),
                          y=1+DATA.GUI.custom_grid_y_offs+DATA.GUI.custom_gridcell_h*(sceneID),
                          w=DATA.GUI.custom_gridcell_w-2,
                          h=DATA.GUI.custom_gridcell_h-2,
                          txt = txt,
                          txt_a = 1,
                          txt_fontsz=DATA.GUI.custom_txtsz_grid,
                          backgr_fill = DATA.GUI.custom_gridcell_backgr_fillscenes,
                          backgr_col = '#FFFFFF',
                          frame_a = DATA.GUI.custom_gridcell_framea_inactive,
                          frame_asel = DATA.GUI.custom_gridcell_framea_inactive,
                          onmouseclick = function()  end,
                          } 
                           
    end
  
  end
  ---------------------------------------------------------------------  
  function GUI_MODULE_GRID(DATA)
    if not DATA.GUI.buttons then return end
    for key in pairs(DATA.GUI.buttons) do if key:match('grid_') then DATA.GUI.buttons[key] = nil end end
    if not DATA2.proj_is_valid then return end
    if DATA.GUI.Settings_open ==1 then return end
    -- frame
      DATA.GUI.buttons['grid_frame'] = { 
                          x=DATA.GUI.custom_grid_x_offs,
                          y=DATA.GUI.custom_grid_y_offs,
                          w=DATA.GUI.custom_gridw,
                          h=DATA.GUI.custom_gridh,
                          ignoremouse = true,
                          frame_col = '#333333',
                          frame_a = 1,
                          backgr_fill = 0.25,
                          backgr_col = '#FFFFFF',
                          onmouseclick = function() end,
                          } 
                      
      
  end
  ----------------------------------------------------------------------  
  function GUI_RESERVED_drawDYN(DATA)
    GUI_DrawLightObjects(DATA)
  end
  
  ----------------------------------------------------------------------  
  function GUI_DrawLightObjects(DATA)
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not DATA2.project_var.playstate then return end 
    local beats, play_measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( proj_ptr, DATA2.project_var.playpos ) 
    
    if not DATA.GUI.lightobj then return end 
    alphablink_Pulsing = (1-((beats%2)/2)) -- pure saw
    alphablink_Pulsing = math.sin(alphablink_Pulsing)
    alphablink_Pulsing = alphablink_Pulsing * (1-0.25) + 0.25
    local alphablink_Flashing = (beats%1)/1 if alphablink_Flashing < 0.5 then alphablink_Flashing = 1 else alphablink_Flashing = 0 end
    local alphablink 
    
    for o in pairs(DATA.GUI.lightobj) do
      local obj = DATA.GUI.lightobj[o]
      alphablink = 0--alphablink_Pulsing  
      if obj.state&2==2 then alphablink = alphablink_Pulsing end -- playing
      if obj.state&1==1 then alphablink = alphablink_Flashing end -- transition
      if obj.state==0 then alphablink = 0.1 end -- transition
      --if obj.state==-1 then alphablink = 0 end -- transition
      gfx.set(1,1,1,alphablink*0.3)
      gfx.rect(obj.x,obj.y,obj.w,obj.h,1)
    end 
    
  end
  ----------------------------------------------------------------------  
  function GUI_BuildLightObjects(DATA)
    if not DATA.GUI.buttons then return end
    if not DATA2.live.scenes then return end
    
    DATA.GUI.lightobj = {} -- reset
    for sceneID in pairs(DATA2.live.scenes) do 
      local state = DATA2.live.scenes[sceneID].state
      if DATA.GUI.buttons['grid_scene_'..sceneID..'L2back'] then
        DATA.GUI.lightobj['grid_scene_'..sceneID] = 
        { 
          x=DATA.GUI.buttons['grid_scene_'..sceneID..'L2back'].x,
          y=DATA.GUI.buttons['grid_scene_'..sceneID..'L2back'].y, 
          w=DATA.GUI.buttons['grid_scene_'..sceneID..'L2back'].w,
          h=DATA.GUI.buttons['grid_scene_'..sceneID..'L2back'].h,
          state = state
        }
      end
    end
    
    for trID in pairs(DATA2.live.tracks) do 
      if DATA2.live.tracks[trID].scenes then 
        for sceneID in pairs(DATA2.live.tracks[trID].scenes) do 
          if DATA2.live.tracks[trID].scenes[sceneID].state and DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'] then
            DATA.GUI.lightobj['grid_clip_tr_'..trID..'_scene_'..sceneID] = 
              {
                x=DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'].x,
                y=DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'].y, 
                w=DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'].w,
                h=DATA.GUI.buttons['grid_tr_'..trID..'_scene_'..sceneID..'L2back'].h,
                state = DATA2.live.tracks[trID].scenes[sceneID].state
              }
          end
        end
      end
    end
    
  end
  
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_Write_AddRegularTrack() 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    SelectProjectInstance( proj_ptr )
    InsertTrackAtIndex( CountTracks( proj_ptr ), false)
    local tr = GetTrack(proj_ptr,CountTracks( proj_ptr )-1)
    GetSetMediaTrackInfo_String(tr, 'P_NAME', 'Track'..CountTracks( proj_ptr ), true)
    GetSetMediaTrackInfo_String(tr, 'P_EXT:MPLSESVIEW_ISREG', 1, true) 
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_Write_AddSendTrack(customname) 
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    InsertTrackAtIndex( CountTracks( proj_ptr ), false)
    local tr = GetTrack(proj_ptr,CountTracks( proj_ptr )-1)
    if customname then GetSetMediaTrackInfo_String(tr, 'P_NAME', customname, true)   end
    GetSetMediaTrackInfo_String(tr, 'P_EXT:MPLSESVIEW_ISSEND', 1, true)  
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_Write_UpdateRouting()
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    
    -- collect sends
    local sends = {}
    for i = 1, CountTracks(proj_ptr) do
      local tr = GetTrack(proj_ptr,i-1)
      if DATA2:LiveProject_ReadContent_IsTrackSend(tr) then sends[#sends+1]= tr end
    end
    
    -- check if send exist
    for i = 1, CountTracks(proj_ptr) do
      local tr = GetTrack(proj_ptr,i-1)
      if DATA2:LiveProject_ReadContent_IsTrackRegular(tr) then
        
        local cntsends = reaper.GetTrackNumSends( tr, 0 ) 
        for send = 1, #sends do
          local has_send = false
          for sendidx = 1, cntsends-1 do
            destptr = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
            if destptr == sends[send] then has_send = true break end
          end
          if not has_send then
            local sendidx = CreateTrackSend(tr, sends[send]) -- add new send if not found
            SetTrackSendInfo_Value(tr, 0,sendidx, 'D_VOL', 0) -- reset send level
          end
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_WriteTemplate(proj_ptr0) 
    local proj_ptr = proj_ptr0 or DATA2.proj_ptr
    if not (proj_ptr and ValidatePtr(proj_ptr, 'ReaProject*'))  then return end
    DATA2.proj_ptr = proj_ptr
    
    -- clear stuff
      for i=CountTracks(proj_ptr), 1, -1 do DeleteTrack( GetTrack(proj_ptr,i-1) ) end
      
    -- regular tracks
      local cnttracks = DATA.extstate.CONF_templatecounttracks
      for i = 1, cnttracks do DATA2:LiveProject_Write_AddRegularTrack()  end 
    
    -- set last two as send A/B
      local cntsends = DATA.extstate.CONF_templatecountsends
      local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      for i = 1, cntsends do DATA2:LiveProject_Write_AddSendTrack('Send '..alphabet:sub(i,i)) end
     
    -- init send routing
      DATA2:LiveProject_Write_UpdateRouting()
      
    -- layout
      DATA2:LiveProject_Write_Layout()
      
      DATA2.live.cached = false 
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_Write_Layout()
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    local retval, num_markers, num_regions = CountProjectMarkers(proj_ptr)
    for markrgnidx = num_markers+num_regions,1,-1 do  DeleteProjectMarkerByIndex( proj_ptr, markrgnidx-1 ) end
    
    local scenelen = DATA.extstate.CONF_scene_maxlength_measures 
    local scenespace = DATA.extstate.CONF_scene_space_measures
    
    local pos_measure = scenelen
    for scene = 1, DATA.extstate.CONF_templatecountscenes do
      local pos_sec =  TimeMap2_beatsToTime( proj_ptr, 0, pos_measure )
      AddProjectMarker2( proj_ptr, false, pos_sec, -1, 'S'..scene..'_ST', -1, 0 )
      pos_measure=pos_measure+scenelen
      local pos_sec =  TimeMap2_beatsToTime( proj_ptr, 0, pos_measure )
      AddProjectMarker2( proj_ptr, false, pos_sec, -1, 'S'..scene..'_EN', -1, 0 )
      pos_measure=pos_measure+scenespace
    end
    UpdateTimeline()
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_CreateOpenLiveProject() 
    if not DATA2.proj_is_found then 
      if not DATA2.proj_path then return end
      local srcproj_ptr, projfn = EnumProjects(-1)
      Action(41929) -- New project tab (ignore default template) 
      local proj_ptr, projfn = EnumProjects(-1) 
      DATA2:LiveProject_WriteTemplate(proj_ptr)
      Main_SaveProjectEx(0, DATA2.proj_path..'/live.rpp', 0) 
      Action(40860) -- Close current project tab
      Action(41929) -- New project tab (ignore default template)
      Main_openProject(DATA2.proj_path..'/live.rpp')  
      DATA2:LiveProject_Validate()--if file_exists(DATA2.proj_path..'/live.rpp') then  DATA2:LiveProject_Validate() end   
      SelectProjectInstance(srcproj_ptr)
      DATA.UPD.onGUIinit = true
      DATA.UPD.onprojstatechange = true
      DATA2.live.cached = nil
     else
      local proj_ptr, projfn = EnumProjects(-1)
      Action(41929) -- New project tab (ignore default template)
      Main_openProject(DATA2.proj_path..'/live.rpp') 
      SelectProjectInstance(proj_ptr)
      DATA2:LiveProject_Validate()
      DATA.UPD.onGUIinit = true
      DATA.UPD.onprojstatechange = true
      DATA2.live.cached = nil
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_Validate(is_minor)
    if is_minor then goto minorcheck end
    -- read opened live project
      DATA2.proj_is_valid = false
      for i = 0, 1000 do
        local proj_ptr, projfn = reaper.EnumProjects( i )
        if projfn:lower():match('live%.rpp') then 
          DATA2.proj_ptr = proj_ptr
          DATA2.proj_projfn = projfn
          DATA2.proj_path = GetParentFolder(projfn)
          DATA2.proj_is_valid = true
          DATA2.proj_is_found = true
          DATA2.proj_name = GetProjectName( DATA2.proj_ptr )
        end
      end
    
    -- try to find live project in project folder
      if not DATA2.proj_is_valid then 
        local proj_ptr, projfn = EnumProjects(-1)
        if not projfn or (projfn and projfn == '' )then return end
        local projfn_path = GetParentFolder(projfn)
        DATA2.proj_path = projfn_path
        if file_exists(projfn_path..'/live.rpp') then  
          DATA2.proj_projfn = 'live.rpp' 
          DATA2.proj_is_found = true
        end
      end
    
    ::minorcheck::
    local proj_ptr =  DATA2.proj_ptr
    if (proj_ptr and ValidatePtr(proj_ptr, 'ReaProject*'))  then return true,proj_ptr end
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_ReadContent_IsTrackRegular(tr)
    if not tr then return end
    local ret, is_reg = GetSetMediaTrackInfo_String(tr, 'P_EXT:MPLSESVIEW_ISREG', 0, false) 
    if is_reg and tonumber(is_reg) and tonumber(is_reg) == 1 then return true end
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_ReadContent_IsTrackSend(tr)
    if not tr then return end
    local ret, is_reg = GetSetMediaTrackInfo_String(tr, 'P_EXT:MPLSESVIEW_ISSEND', 0, false) 
    if is_reg and tonumber(is_reg) and tonumber(is_reg) == 1 then return true end
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_ReadContent_ScenesRegions(proj)
    local retval, num_markers, num_regions = reaper.CountProjectMarkers( proj )
    for idx=1, num_markers+num_regions do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( proj, idx-1 )
      if isrgn == false and name:match('S(%d+)') then
        local sceneID = name:match('S(%d+)')
        if tonumber(sceneID) then sceneID = tonumber(sceneID) end
        if sceneID then
          if not DATA2.live.scenes[sceneID] then DATA2.live.scenes[sceneID] = {mark_index = idx-1,state=0} end
          local retval, pos_measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( proj, pos )
          if name:match('S(%d+)_ST') then 
            DATA2.live.scenes[sceneID].pos_ST_measures = pos_measures 
            DATA2.live.scenes[sceneID].pos_ST = pos 
           elseif  name:match('S(%d+)_EN') then 
            DATA2.live.scenes[sceneID].pos_EN_measures = pos_measures 
            DATA2.live.scenes[sceneID].pos_EN = pos
          end
        end
      end
    end
    
    -- validate that scene has ST/EN
    for ID=#DATA2.live.scenes, 1,-1 do if not (DATA2.live.scenes[ID].pos_ST_measures and DATA2.live.scenes[ID].pos_EN_measures) then table.remove(DATA2.live.scenes, ID) end end
  end 
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_ReadContent()
    -- validate project
      if not (DATA2.proj_ptr and ValidatePtr(DATA2.proj_ptr,'ReaProject*')) then return end
      local proj = DATA2.proj_ptr
    
    -- init
      DATA2.live = {
          tracks = {},
          sends = {},
          scenes = {},
        }
      
      DATA2:LiveProject_ReadContent_ScenesRegions(proj)
      
    -- colect tracks
      local trIDx= 0
      local sendidx= 0
      for trID = 1, CountTracks(proj) do
        local tr = GetTrack(proj, trID-1) 
        if DATA2:LiveProject_ReadContent_IsTrackRegular(tr) then 
          trIDx = trIDx +1
          local retval, trname = GetTrackName( tr )
          local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
          DATA2.live.tracks[trIDx] = {name = trname,
                                      GUID = GUID,
                                      scenes = {}}
          DATA2:LiveProject_ReadContent_SceneClips(trIDx) 
        end
        if DATA2:LiveProject_ReadContent_IsTrackSend(tr) then 
          sendidx = sendidx +1
          DATA2.live.sends[sendidx] =  {}
        end
      end
    
    -- read ext state
    DATA2.live.cached=true
  end
  ---------------------------------------------------------------------
  function DATA2:LiveProject_ReadContent_ItemExtState(it,extstate)
    local ret, state = GetSetMediaItemInfo_String( it, 'P_EXT:'..extstate, 0, false )
    if state and tonumber(state)  then 
      return tonumber(state) >= 1, tonumber(state)
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_ReadContent_SceneClipsAdd(trID,sceneID,it,take)
    if not take then take = GetActiveTake(it) end
    local retval, itname = GetSetMediaItemTakeInfo_String( take, 'P_NAME', '', false )
    local retval, GUID = GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
    local retval, itchunk = reaper.GetItemStateChunk( it, '', false )
    local itlen = GetMediaItemInfo_Value( it, 'D_LENGTH' )
    local pcmsrc = GetMediaItemTake_Source( take )
    DATA2.live.tracks[trID].scenes[sceneID] = { 
      name = itname,
      tkGUID = GUID,
      itlen=itlen,
      pcmsrc=pcmsrc,
      state = 0,
      }
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_ReadContent_SceneClips(trID)
    local ret,proj_ptr = DATA2:LiveProject_Validate(true) if not ret then return end
    if not (DATA2.live.tracks and DATA2.live.tracks[trID] and DATA2.live.tracks[trID].GUID) then return end
    DATA2.live.tracks[trID].scenes = {}
    local tr = VF_GetTrackByGUID (DATA2.live.tracks[trID].GUID,proj_ptr)
    if not tr then return end
    
    local cnt_items = CountTrackMediaItems( tr )
    for itemidx = 1, cnt_items do
      local it = GetTrackMediaItem( tr, itemidx-1 ) 
      local take = GetActiveTake(it)
      if take and DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_ISCLIP') and  DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_MASTER') and DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_SCENE') then 
        local ret, sceneID = DATA2:LiveProject_ReadContent_ItemExtState(it,'MPLSESVIEW_ITEM_SCENE')
        if ret and sceneID then DATA2:LiveProject_ReadContent_SceneClipsAdd(trID,sceneID,it,take) end
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:LiveProject_ExtState_Write(trID, sceneID, state) 
    if not (trID and sceneID) then return end 
    SetExtState( DATA.extstate.extstatesection, sceneID + (trID<<16), state, false )
  end


---------------------------------------------------------------------  
  function DATA2:HW_InitHardware()  
    -- search HW MIDI out
      local devout 
      for dev = 1, GetNumMIDIOutputs() do
        local retval, nameout = GetMIDIOutputName( dev-1, '' )
        if retval and nameout:match(DATA.extstate.CONF_HWoutname) then DATA2.HWdata.HWdevoutID =  dev-1 break end 
      end
    -- search HW MIDI in
      local devin 
      for dev = 1, GetNumMIDIInputs() do
        local retval, nameout = GetMIDIInputName( dev-1, '' )
        if retval and nameout:match(DATA.extstate.CONF_HWinname) then DATA2.HWdata.HWdevinID =  dev-1 break end 
      end
      
  end
  ----------------------------------------------------------------------  
  function DATA2:HW_Send_LightScene(sceneID, state) 
    if DATA.extstate.CONF_HWoutname == "LPMiniMK3 MIDI"  or DATA.extstate.CONF_HWoutname == 'Launchpad MK2'  then
      if sceneID <= 7 then -- limit to low button
        -- refresh scene lights
        local msgtype = 0xB0
        local chan = 0 
        if state&1==1 then chan = 1 end
        if state&2==2 then chan = 2 end
        local CC= 89-10*(sceneID-1) 
        local val = 1
        if state == 0 then val = 1 end
        local  msg1 =dec2hex(msgtype|chan)
        local msg2 = dec2hex(CC)
        local msg3 = dec2hex(val)
        local out_str = msg1..' '..msg2..' '..msg3
        DATA2:Actions_StuffMIDI(out_str) 
      end
    end
  end
  ----------------------------------------------------------------------  
  function DATA2:HW_Send_LightClip(trID, sceneID, state) 
    if DATA.extstate.CONF_HWoutname == "LPMiniMK3 MIDI" or DATA.extstate.CONF_HWoutname == 'Launchpad MK2'  then
      -- refresh scene lights
      local msgtype = 0x90
      local chan = 0 
      local note= 80 + trID - (10*(sceneID-1))
      local val = 1 
      if state&1==1 then chan = 1 end
      if state&2==2 then chan = 2 end
      local msg1 =dec2hex(msgtype|chan)
      local msg2 = dec2hex(note)
      local msg3 = dec2hex(val)
      local out_str = msg1..' '..msg2..' '..msg3
      DATA2:Actions_StuffMIDI(out_str)  
    end
  end
  ----------------------------------------------------------------------  
  function DATA2:HW_Send_ClearState(minor)
    if DATA.extstate.CONF_HWoutname == "LPMiniMK3 MIDI" or DATA.extstate.CONF_HWoutname == 'Launchpad MK2' then
      if not minor then 
        local mode = '01'   DATA2:Actions_StuffMIDI('F0 00 20 29 02 0D 10 '..mode..' F7')           -- enable DAW mode
        local layout = '00' DATA2:Actions_StuffMIDI('F0h 00h 20h 29h 02h 0Dh 00h '..layout..' F7')  -- enable Session layout 
      end
      DATA2:Actions_StuffMIDI('F0 00 20 29 02 0D 12 01 00 01 F7') -- clear state
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:HW_ReceiveData_LaunchPadMiniMK3(midimsg)
    local msgtype = midimsg:byte(1)&0xF0
    local chan = midimsg:byte(1)&0xF0
    local CC_note = midimsg:byte(2) 
    local val = midimsg:byte(3)
    --msg(msgtype) msg(chan) msg(CC_note) msg(val) msg('-')
    -- handle scenes
    for sceneID = 1, 7 do
      if msgtype == 0xB0 and CC_note == 89-10*(sceneID-1) and val == 127 then DATA2:Scenes_play(sceneID) end
      if msgtype == 0xB0 and CC_note == 19 and val == 127 then DATA2:Scenes_Transport_OnStop() end
    end
    
    for sceneID = 1, 7 do
      for trID = 1, 8 do
        if msgtype == 0x90 and CC_note == 81-10*(sceneID-1)+(trID-1) and val == 127 then 
          DATA2:Clip_ActionSwitch(trID, sceneID, true)  
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:HW_ReceiveData()
    local retval, midimsg, ts, devIdx, projPos, projLoopCnt = reaper.MIDI_GetRecentInputEvent(0)
    DATA2.retroactiveHW.msg = midimsg
    DATA2.retroactiveHW.ts = ts
    if DATA2.retroactiveHW.last_msg and DATA2.retroactiveHW.last_msg ~= DATA2.retroactiveHW.msg and DATA2.HWdata.HWdevinID == devIdx then
      if DATA.extstate.CONF_HWinname == 'LPMiniMK3 MIDI' or DATA.extstate.CONF_HWinname == 'Launchpad MK2' then DATA2:HW_ReceiveData_LaunchPadMiniMK3(midimsg) end
    end
    DATA2.retroactiveHW.last_msg = DATA2.retroactiveHW.msg
  end
  ---------------------------------------------------------------------  
  function DATA2:HW_InitHardware()  
    -- search HW MIDI out
      local devout 
      local devOUTnamecheck = DATA.extstate.CONF_HWoutname
      if DATA.extstate.CONF_HWoutname ~= 'Off' then 
        for dev = 1, GetNumMIDIOutputs() do
          local retval, nameout = GetMIDIOutputName( dev-1, '' )
          if retval and nameout:lower():match(literalize(devOUTnamecheck:lower())) then DATA2.HWdata.HWdevoutID =  dev-1 break end 
        end
      end
      
    -- search HW MIDI in
      local devin 
      local devINnamecheck = DATA.extstate.CONF_HWinname
      if DATA.extstate.CONF_HWinname ~= 'Off' then 
        for dev = 1, GetNumMIDIInputs() do
          local retval, nameout = GetMIDIInputName( dev-1, '' )
          if retval and nameout:lower():match(literalize(devOUTnamecheck:lower())) then DATA2.HWdata.HWdevinID =  dev-1 break end 
        end 
      end
  end
  ----------------------------------------------------------------------  
  function DATA2:HW_Light_Refresh() 
    DATA2:HW_Send_ClearState(true)
    if not DATA2.live.scenes then return end
    
    for sceneID in pairs(DATA2.live.scenes) do DATA2:HW_Send_LightScene(sceneID, DATA2.live.scenes[sceneID].state) end
    
    
    for trID in pairs(DATA2.live.tracks) do 
      if DATA2.live.tracks[trID].scenes then
        for sceneID in pairs(DATA2.live.tracks[trID].scenes) do 
          if DATA2.live.tracks[trID].scenes[sceneID].state then
            DATA2:HW_Send_LightClip(trID, sceneID, DATA2.live.tracks[trID].scenes[sceneID].state) 
          end
        end
      end
    end
    
  end 
  ---------------------------------------------------------------------  
  function DATA2:Actions_StuffMIDI(str) 
    if not (DATA2.HWdata and DATA2.HWdata.HWdevoutID) then return end
    local SysEx_msg = str local SysEx_msg_bin = '' for hex in SysEx_msg:gmatch('[A-F,0-9]+') do  SysEx_msg_bin = SysEx_msg_bin..string.char(tonumber(hex, 16)) end 
    SendMIDIMessageToHardware(DATA2.HWdata.HWdevoutID, SysEx_msg_bin)--, SysEx_msg_bin:len())  
  end 
  ----------------------------------------------------------------------
  function DATA2:ProcessUndoBlock(f, name, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10) 
    if not DATA2.proj_ptr  then return end
    Undo_BeginBlock2( DATA2.proj_ptr)
    defer(f(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10))
    Undo_EndBlock2( DATA2.proj_ptr, name, 0xFFFFFFFF )
  end
  
  ---------------------------------------------------------------------  
  function DATA2:Actions_Menu()
    local t= {
    
      { str = '[dev] Clear and write template to live project',
        func = function () DATA2:LiveProject_WriteTemplate()end,
        hidden = DATA2.proj_is_valid==nil,
      },
      --[[{ str = '[dev] Enable smooth seek (require SWS)',
        func = function () SNM_SetIntConfigVar('smoothseek',1) end,--https://forums.cockos.com/showpost.php?p=2409256&postcount=7
        hidden = DATA2.proj_is_valid==nil,
      },]]
    
    }  
    
    -- for all menu entries, refresh live project feedback state and UI
    for i = 1, #t do 
      local fsrc = t[i].func
      t[i].func = function() 
        DATA2:ProcessUndoBlock( fsrc, DATA.extstate.mb_title..': '..t[i].str) 
        DATA.UPD.onGUIinit = true
        DATA.UPD.onprojstatechange = true
      end
    end
    return t
  end
  
  --------------------------------------------------------------------- 
  function DATA2:Action_TrackContextMenu(trID) 
  
    -- open FX chain
    local tr
    if DATA2.live and DATA2.live.tracks and DATA2.live.tracks[trID] and DATA2.live.tracks[trID].GUID then 
      tr = VF_GetTrackByGUID (DATA2.live.tracks[trID].GUID)
      if tr then TrackFX_Show( tr, 0, 1 ) end
    end
    
    -- add new track
      if not tr then
        
      end
  end
  
  ----------------------------------------------------------------------  
  function dec2hex(dec) local pat = "%02X" return  string.format(pat, dec) end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
    
    local  t = 
    { 
      {str = 'General' ,                                           group = 1, itype = 'sep'},
        {str = '[settings/preset]',                                group = 1, itype = 'button', level = 1, func_onrelease = function() DATA:GUIbut_preset() end},
      {str = 'Hardware' ,                                          group = 2, itype = 'sep'},  
        {str = 'Input: '..DATA.extstate.CONF_HWinname,             group = 2, itype = 'button', confkey = 'CONF_HWinname', level = 1, func_onrelease = function() DATA:GUImenu(
          { 
            {str='Off',func=function() DATA.extstate.CONF_HWinname = 'Off' DATA.UPD.onGUIinit = true DATA.UPD.onconfchange = true end},
            {str='LPMiniMK3 MIDI',func=function() DATA.extstate.CONF_HWinname = 'LPMiniMK3 MIDI' DATA.UPD.onGUIinit = true DATA.UPD.onconfchange = true DATA2:HW_InitHardware() DATA2:HW_Send_ClearState() end},
            {str='Launchpad MK2',func=function() DATA.extstate.CONF_HWinname = 'Launchpad MK2' DATA.UPD.onGUIinit = true DATA.UPD.onconfchange = true DATA2:HW_InitHardware() DATA2:HW_Send_ClearState() end},
          }
        )end, readoutw_extw=readoutw_extw}, 
        {str = 'Output: '..DATA.extstate.CONF_HWoutname,             group = 2, itype = 'button', confkey = 'CONF_HWoutname', level = 1, func_onrelease = function() DATA:GUImenu(
          { 
            {str='Off',func=function() DATA.extstate.CONF_HWoutname = 'Off' DATA.UPD.onGUIinit = true DATA.UPD.onconfchange = true end},
            {str='LPMiniMK3 MIDI',func=function() DATA.extstate.CONF_HWoutname = 'LPMiniMK3 MIDI' DATA.UPD.onGUIinit = true DATA.UPD.onconfchange = true DATA2:HW_InitHardware() DATA2:HW_Send_ClearState() end},
            {str='Launchpad MK2',func=function() DATA.extstate.CONF_HWoutname = 'Launchpad MK2' DATA.UPD.onGUIinit = true DATA.UPD.onconfchange = true DATA2:HW_InitHardware() DATA2:HW_Send_ClearState() end},
          }
        )end, readoutw_extw=readoutw_extw},       

        
    } 
    return t
    
  end
  ---------------------------------------------------   
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.57) if ret then local ret2 = VF_CheckReaperVrs(6.77,true) if ret2 then main() end end

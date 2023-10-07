-- @description Toggle FX oversampling
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Toggle set to none oversampling for all project FX.lua
--    [main] . > mpl_Disable oversampling for all project FX.lua
--    [main] . > mpl_Enable 4x oversampling for all project Slate VMR.lua
--    [main] . > mpl_Disable oversampling for all project Slate VMR.lua
--    [main] . > mpl_Toggle set to none oversampling for selected track FX.lua
--    [main] . > mpl_Toggle set to 2x oversampling for all project FX.lua
--    [main] . > mpl_Toggle set to 2x oversampling for selected track FX.lua
--    [main] . > mpl_Toggle set to 4x oversampling for all project FX.lua
--    [main] . > mpl_Toggle set to 4x oversampling for selected track FX.lua
--    [main] . > mpl_Toggle set to 8x oversampling for all project FX.lua
--    [main] . > mpl_Toggle set to 8x oversampling for selected track FX.lua
-- @changelog
--    # cleanup
 

  --------------------------------------------------------------------
  function main_body_parseextstate(extstatekey)  
    -- parse ext state t
    local ret, str = GetProjExtState( 0, extstatekey, 'FXGUIDS' )
    local extstatein = {}
    if ret then
      for line in str:gmatch('[^\r\n]+') do 
        local GUID, pluginOS, chainOS = line:match('({.*}) (%d) (%d)') 
        if not GUID then  GUID, pluginOS = line:match('({.*}) (%d)')  chainOS = 0  end-- support for 1.02 and below
        extstatein[GUID] = {
          pluginOS =tonumber(pluginOS),
          chainOS= tonumber(chainOS) or 0}
      end
    end
    return extstatein
  end
  --------------------------------------------------------------------
  function main_body(sec, cmd,extstatekey, selectedtrackmode, instanceOS, state, set, plugin)
    -- ext state t
      local extstateout = {}
      local extstatein = main_body_parseextstate(extstatekey) 
    
    -- deal with selectedtrackmode
      if selectedtrackmode then 
        for i = 1, CountSelectedTracks(0) do 
          local tr = GetSelectedTrack(0,i-1) 
          main_body_tr(tr, instanceOS, state, set, plugin, extstateout, extstatein) 
        end 
       else  
        for i = 0, CountTracks(0) do 
          local tr = GetTrack(0,i-1) 
          if i == 0 then tr = GetMasterTrack(0) end 
          main_body_tr(tr, instanceOS, state, set, plugin, extstateout,extstatein) 
        end 
      end  
    
    -- store ext state / reset state
      if not set then
        if state == 0 then 
          SetButtonON(sec, cmd )
          SetExtState( extstatekey, 'STATE', 1, true )
          SetProjExtState( 0, extstatekey, 'FXGUIDS', table.concat(extstateout, '\n') )
         elseif state == 1 then  
          SetButtonOFF(sec, cmd )
          SetExtState( extstatekey, 'STATE', 0, true )
        end
      end
    
  end
  ---------------------------------------------------------------------  
  function main_body_tr_collect_fxids(track,plugin)
    local fxids = {}
    -- collect top level
      for fx_id = 1,  TrackFX_GetCount( track ) do
        local retval, fxname = TrackFX_GetNamedConfigParm( track, fx_id-1, 'fx_name' )
        local plugin_match = (retval and not plugin) or (retval and plugin and fxname~='' and fxname:lower():match(plugin:lower()))
        if plugin_match==true then fxids[#fxids+1] = fx_id-1 end
      end
    
    -- collect input fx
      for fx_id = 1,   TrackFX_GetRecCount( track ) do
        local retval, fxname = TrackFX_GetNamedConfigParm( track, 0x1000000+fx_id-1, 'fx_name' )
        local plugin_match = (retval and not plugin) or (retval and plugin and fxname~='' and fxname:lower():match(plugin:lower()))
        if plugin_match==true then fxids[#fxids+1] = 0x1000000+fx_id-1 end
      end
    return fxids
  end
  ---------------------------------------------------------------------  
  function main_body_tr(track, instanceOS, state, set, plugin, extstateout, extstatein)
    if not track then return end
    
    local fxids = main_body_tr_collect_fxids(track,plugin)
    
    -- do stuff
      for i = 1, #fxids do
        local fx_id = fxids[i]
        -- get OS state
        local retval, pluginOSenabled = TrackFX_GetNamedConfigParm( track, fx_id, 'instance_oversample_shift' ) 
        local retval, chainOSenabled = TrackFX_GetNamedConfigParm( track, fx_id, 'chain_oversample_shift' )  
        pluginOSenabled = tonumber(pluginOSenabled)
        chainOSenabled = tonumber(chainOSenabled)
        
        if set then TrackFX_SetNamedConfigParm( track, fx_id, 'instance_oversample_shift',set*instanceOS ) end 
        
        -- store
        if not set and state == 0 then  
          extstateout[#extstateout+1] = TrackFX_GetFXGUID( track, fx_id)..' '..pluginOSenabled..' '..chainOSenabled
          TrackFX_SetNamedConfigParm( track, fx_id, 'instance_oversample_shift',instanceOS )
          if instanceOS == 0 then TrackFX_SetNamedConfigParm( track, fx_id, 'chain_oversample_shift',0 ) end
        end
        
        -- restore
        if not set and state == 1 then  
          local GUID = TrackFX_GetFXGUID( track, fx_id)
          if extstatein[GUID] then 
            TrackFX_SetNamedConfigParm( track, fx_id, 'instance_oversample_shift',extstatein[GUID].pluginOS )
            TrackFX_SetNamedConfigParm( track, fx_id, 'chain_oversample_shift',extstatein[GUID].chainOS )
          end
        end
        
      end 
      
        
  end
  ---------------------------------------------------------------------  
  function SetButtonON(sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
    reaper.RefreshToolbar2( sec, cmd )
  end
  ---------------------------------------------------------------------  
  function SetButtonOFF(sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
    reaper.RefreshToolbar2( sec, cmd )
  end
  -------------------------------------------------------------------- 
  function main(sec, cmd, filename) 
    
    local extstatekey = 'MPLOVSMPLTOGGLE'
    
    -- parse selected
    local selectedtrackmode = filename:match('selected') ~= nil
    if selectedtrackmode ==true then extstatekey = extstatekey..'_SEL' end
    
    -- parse plugin
    local plugin = filename:match('Slate VMR') 
    if plugin then plugin = 'Virtual Mix Rack' end
    
    -- X oversampling 
    local instanceOS = 0
    local OS_str = filename:match('(%d)x oversampling') 
    if OS_str then 
      if tonumber(OS_str) == 2 then instanceOS = 1
      elseif tonumber(OS_str) == 4 then instanceOS = 2
      elseif tonumber(OS_str) == 8 then instanceOS = 3
      end
    end
    
    -- parse toggle
    local actiontxt = 'Toggle FX oversampling: store'
    local state = GetExtState( extstatekey, 'STATE' ) 
    if not state or (state and tonumber(state) and tonumber(state)==0) then state = 0 else state = 1 end 
    if state == 1 then actiontxt = 'Toggle FX oversampling: restore' end
    
    -- parse set
    local set
    local set1 = filename:match('Enable') ~= nil
    local set0 = filename:match('Disable')  ~= nil
    if set1 then set = 1 end
    if set0 then set = 0 end
    if set then
      if set == 1 then actiontxt = 'Enable FX oversampling' end
      if set == 0 then actiontxt = 'Disable FX oversampling' end
      state=nil
    end
     
    -- state // == 0 not stored -> store  // ==1 stored -> restore
    Undo_BeginBlock2( 0 )
    main_body(sec, cmd ,extstatekey, selectedtrackmode, instanceOS, state, set, plugin)
    Undo_EndBlock2( 0,actiontxt, 0xFFFFFFFF )
  end
  -------------------------------------------------------------------- 
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) 
  if ret then 
    local ret2 = VF_CheckReaperVrs(6.72,true)  
    local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    if ret2 then main(sec, cmd,filename) end 
  end
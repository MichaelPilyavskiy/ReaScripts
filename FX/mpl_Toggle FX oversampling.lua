-- @description Toggle FX oversampling
-- @version 1.03
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
--    # fix loop through input FX
--    # add FX chain parameter handling
--    + Add undo point, show state
 
  --NOT gfx NOT reaper
  --------------------------------------------------------------------
  function main(selectedtrackmode, instanceOS, set, plugin)
    local extstatekey = 'MPLOVSMPLTOGGLE'
    if selectedtrackmode then extstatekey = extstatekey..'_SEL' end
    local state =  GetExtState( extstatekey, 'STATE' )
    
    if not state or state == '' or tonumber(state)==0 or set then 
      
      --  
      local cnttr = CountTracks(0) if selectedtrackmode then cnttr = CountSelectedTracks(0) end
      local str = ''
      for tr_id = 0, cnttr do
        local track
        if not selectedtrackmode then 
          if tr_id ==0 then track = GetMasterTrack( 0 ) else track = GetTrack(0,tr_id-1) end
         else
          track = GetSelectedTrack( 0,tr_id-1 )
        end
        
        for fx_id = 1,  TrackFX_GetCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, fx_id-1, 'instance_oversample_shift' )
          local retval, buf2 = TrackFX_GetNamedConfigParm( track, fx_id-1, 'chain_oversample_shift' )
          local retval, fxname = TrackFX_GetNamedConfigParm( track, fx_id-1, 'fx_name' )
          
          if (retval and not plugin) or (retval and plugin and fxname~='' and fxname:lower():match(plugin:lower())) then 
            if not set then  
              local pluginOSenabled = tonumber(buf)
              local chainOSenabled = tonumber(buf2)
              str = str..'\n'..TrackFX_GetFXGUID( track, fx_id-1)..' '..pluginOSenabled..' '..chainOSenabled
              TrackFX_SetNamedConfigParm( track, fx_id-1, 'instance_oversample_shift',instanceOS )
              if instanceOS == 0 then TrackFX_SetNamedConfigParm( track, fx_id-1, 'chain_oversample_shift',0 ) end
             else  
              TrackFX_SetNamedConfigParm( track, fx_id-1, 'instance_oversample_shift',set*instanceOS )
            end
          end 
          
        end

        for fx_id = 1,   TrackFX_GetRecCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, 0x1000000+fx_id-1, 'instance_oversample_shift' )
          local retval, buf2 = TrackFX_GetNamedConfigParm( track, 0x1000000+fx_id-1, 'chain_oversample_shift' )
          if retval then 
            if not set then 
              local pluginOSenabled = tonumber(buf)
              local chainOSenabled = tonumber(buf2)
              str = str..'\n'..TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)..' '..pluginOSenabled
              TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'instance_oversample_shift',instanceOS )
              if instanceOS == 0 then TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'chain_oversample_shift',0 ) end
             else 
              TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'instance_oversample_shift',set )
            end
          end 
        end
                
        
      end
      
      if set then return end
      
      SetButtonON()
      SetExtState( extstatekey, 'STATE', 1, true )
      SetProjExtState( 0, extstatekey, 'FXGUIDS', str )
      
     else
      
      local ret, str = GetProjExtState( 0, extstatekey, 'FXGUIDS' )
      local t = {}
      for line in str:gmatch('[^\r\n]+') do 
        local GUID, pluginOS, chainOS = line:match('({.*}) (%d) (%d)') 
        if not GUID then  GUID, pluginOS = line:match('({.*}) (%d)')  chainOS = 0  end-- support for 1.02 and below
        t[GUID] = {
          pluginOS =tonumber(pluginOS),
          chainOS= tonumber(chainOS) or 0}
      end      
      
      local cnttr = CountTracks(0) if selectedtrackmode then cnttr = CountSelectedTracks(0) end
      for tr_id = 0, cnttr do
        local track
        if not selectedtrackmode then 
          if tr_id ==0 then track = GetMasterTrack( 0 ) else track = GetTrack(0,tr_id-1) end
         else
          track = GetSelectedTrack( 0,tr_id-1 )
        end
        
        for fx_id = 1,  TrackFX_GetCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, fx_id-1)
          if t[GUID] then 
            TrackFX_SetNamedConfigParm( track, fx_id-1, 'instance_oversample_shift',t[GUID].pluginOS )
            TrackFX_SetNamedConfigParm( track, fx_id-1, 'chain_oversample_shift',t[GUID].chainOS )
          end
        end
        
        for fx_id = 1,  TrackFX_GetRecCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)
          if t[GUID] then 
            TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'instance_oversample_shift',t[GUID].pluginOS )
            TrackFX_SetNamedConfigParm( track, 0x1000000+fx_id-1, 'chain_oversample_shift',t[GUID].chainOS )
          end
        end
        
      end  
      SetButtonOFF()
      SetExtState( extstatekey, 'STATE', 0, true )
    end
  end

  ---------------------------------------------------------------------  
  function SetButtonON()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
    reaper.RefreshToolbar2( sec, cmd )
  end
  ---------------------------------------------------------------------  
  function SetButtonOFF()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
    reaper.RefreshToolbar2( sec, cmd )
  end
  -------------------------------------------------------------------- 
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) 
  if ret then 
    local ret2 = VF_CheckReaperVrs(6.72,true) 
    if ret2 then 
      local selectedtrackmode = ({reaper.get_action_context()})[2]:match('selected') 
      
      local plugin = ({reaper.get_action_context()})[2]:match('Slate VMR') 
      if plugin then plugin = 'Virtual Mix Rack' end
      
      local set
      local set1 = ({reaper.get_action_context()})[2]:match('Enable') ~= nil
      local set0 = ({reaper.get_action_context()})[2]:match('Disable')  ~= nil
      if set1 then set = 1 end
      if set0 then set = 0 end
      
      local instanceOS = 0
      local OS_str = ({reaper.get_action_context()})[2]:match('(%d)x oversampling') 
      if OS_str then 
        if tonumber(OS_str) == 2 then instanceOS = 1
        elseif tonumber(OS_str) == 4 then instanceOS = 2
        elseif tonumber(OS_str) == 8 then instanceOS = 3
        end
      end
      
      local extstatekey = 'MPLOVSMPLTOGGLE'
      local state = GetExtState( extstatekey, 'STATE' ) 
      if not state then 
        state = 0 
       elseif state =='' then
        state = 0
       elseif tonumber(state) and tonumber(state)==0 then 
        state = 0
       elseif set == 0 then
        state = 0
       else 
        state = 1
      end 
      local actiontxt = 'Toggle FX oversampling: store'
      if state == 1 then actiontxt = 'Toggle FX oversampling: restore' end
      
      Undo_BeginBlock2( 0 )
      main(selectedtrackmode,instanceOS, set, plugin)
      Undo_EndBlock2( 0,actiontxt, 0xFFFFFFFF )
    end end
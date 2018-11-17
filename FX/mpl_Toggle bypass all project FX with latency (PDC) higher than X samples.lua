-- @description Toggle bypass all project FX with latency (PDC) higher than X samples
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @metapackage
-- @provides
--    [main] . > mpl_Toggle bypass all project FX with latency (PDC) higher than 256 samples.lua
--    [main] . > mpl_Toggle bypass all project FX with latency (PDC) higher than 512 samples.lua
--    [main] . > mpl_Toggle bypass all project FX with latency (PDC) higher than 1024 samples.lua
--    [main] . > mpl_Toggle bypass all project FX with latency (PDC) higher than 2048 samples.lua
--    [main] . > mpl_Toggle bypass all project FX with latency (PDC) higher than 4096 samples.lua
--    [main] . > mpl_Toggle bypass all project FX with latency (PDC) higher than 8192 samples.lua
-- @changelog
--    + support master FX
--    + support monitoring FX
--    + support input FX
--    # fix VariousFunctions checking
 
  --NOT gfx NOT reaper
  --------------------------------------------------------------------
  function main(spl_thrshld)
    local state =  GetExtState( 'MPLPDCTOGGLE', 'STATE' )
    if not state or state == '' or tonumber(state)==0 then 
      
      -- bypass 
      local str = ''
      for tr_id = 0, CountTracks(0) do
        local track
        if i ==0 then track = GetMasterTrack( 0 ) else track = GetTrack(0,tr_id-1) end
        
        for fx_id = 1,  TrackFX_GetCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, fx_id-1, 'pdc' )
          if retval and tonumber(buf) and tonumber(buf) > spl_thrshld then  
            local is_bypass = TrackFX_GetEnabled( track, fx_id-1) 
            if is_bypass then is_bypass =1 else is_bypass = 0 end       
            str = str..'\n'..TrackFX_GetFXGUID( track, fx_id-1)..' '..is_bypass
            TrackFX_SetEnabled( track, fx_id-1, false)
          end 
        end

        for fx_id = 1,   TrackFX_GetRecCount( track ) do
          local retval, buf = TrackFX_GetNamedConfigParm( track, 0x1000000+ fx_id-1, 'pdc' )
          if retval and tonumber(buf) and tonumber(buf) > spl_thrshld then  
            local is_bypass = TrackFX_GetEnabled( track, 0x1000000 + fx_id-1) 
            if is_bypass then is_bypass =1 else is_bypass = 0 end       
            str = str..'\n'..TrackFX_GetFXGUID( track, 0x1000000 + fx_id-1)..' '..is_bypass
            TrackFX_SetEnabled( track, 0x1000000 + fx_id-1, false)
          end 
        end
                
        
      end
      
      
      
      SetExtState( 'MPLPDCTOGGLE', 'STATE', 1, true )
      SetProjExtState( 0, 'MPLPDCTOGGLE', 'FXGUIDS', str )
      
     else
      
      local ret, str = GetProjExtState( 0, 'MPLPDCTOGGLE', 'FXGUIDS' )
      local t = {}
      for line in str:gmatch('[^\r\n]+') do local GUID, bypass = line:match('({.*}) (%d)') t[GUID] = tonumber(bypass) end      
      
      for tr_id = 1, CountTracks(0) do
        local track
        if i ==0 then track = GetMasterTrack( 0 ) else track = GetTrack(0,tr_id-1) end
        
        for fx_id = 1,  TrackFX_GetCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, fx_id-1)
          if t[GUID] then TrackFX_SetEnabled( track, fx_id-1, t[GUID]==1) end
        end
        
        for fx_id = 1,  TrackFX_GetRecCount( track ) do
          local GUID = TrackFX_GetFXGUID( track, 0x1000000+fx_id-1)
          if t[GUID] then TrackFX_SetEnabled( track, 0x1000000+fx_id-1, t[GUID]==1) end
        end
        
      end     
      SetExtState( 'MPLPDCTOGGLE', 'STATE', 0, true )
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)      
      if not _G[str_func] then   reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true  end      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end  
-------------------------------------------------------------------- 
  local cnt_spls = ({reaper.get_action_context()})[2]:match('([%d]+) samples')
  if not (cnt_spls and tonumber(cnt_spls)) then cnt_spls = 256 else cnt_spls = tonumber(cnt_spls) end
  
  local ret = CheckFunctions('VF_CheckReaperVrs') 
  local ret2 = VF_CheckReaperVrs(5.95)    
  if ret and ret2 then main(cnt_spls) end
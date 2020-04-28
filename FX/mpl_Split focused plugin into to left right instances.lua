-- @description Split focused plugin into to left right instances
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  -- NOT reaper NOT gfx
  function main()
    
    local retval, tracknumber, _, fx = GetFocusedFX()
    if retval ~= 1 then return end
    local tr if tracknumber == 0 then tr = GetMasterTrack(0) else tr = GetTrack(0, tracknumber-1) end
    
    -- duplicate vst
      TrackFX_CopyToTrack( tr, fx, tr, fx, false )
      local retval1, fxname = reaper.TrackFX_GetFXName( tr, fx, '' )
      SetFXName(tr, fx, MPL_ReduceFXname(fxname)..' Left')
      SetFXName(tr, fx+1, MPL_ReduceFXname(fxname)..' Right')
      
    -- set IO
      -- fx 1 in
      TrackFX_SetPinMappings( tr, fx, 0, 0, 1, 0 )
      TrackFX_SetPinMappings( tr, fx, 0, 1, 0, 0 )
      -- fx 1 out
      TrackFX_SetPinMappings( tr, fx, 1, 0, 1, 0 )
      TrackFX_SetPinMappings( tr, fx, 1, 1, 0, 0 )
      -- fx 2 in
      TrackFX_SetPinMappings( tr, fx+1, 0, 0, 0, 0 )
      TrackFX_SetPinMappings( tr, fx+1, 0, 1, 2, 0 )
      -- fx 2 out
      TrackFX_SetPinMappings( tr, fx+1, 1, 0, 0, 0 )
      TrackFX_SetPinMappings( tr, fx+1, 1, 1, 2, 0 )
        
    -- link params
      local retval2, tr_chunk = GetTrackStateChunk( tr, '', false )
      local GUID = TrackFX_GetFXGUID( tr, fx )
      local num_params = TrackFX_GetNumParams( tr, fx )
      for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
        local fxGUID = fxchunk:match('FXID (.-)\n')
        if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end
        if fxGUID == GUID then
          local link_str = (fx+1)..':'..1
          -- add parameter links
          local PM_str = ''
          for param_id = 0,  num_params-3 do
              PM_str = PM_str..
            [[<PROGRAMENV ]]..param_id..[[ 0
PARAMBASE 0
LFO 0
LFOWT 1 1
AUDIOCTL 0
AUDIOCTLWT 1 1
PLINK 1 ]]..link_str..' '..param_id..[[ 0
>]]..'\n'  
          end
          fxchunk_mod = fxchunk:gsub('WAK',PM_str..'WAK' )
          tr_chunk = tr_chunk:gsub(literalize(fxchunk), fxchunk_mod)
          --msg(tr_chunk)
          SetTrackStateChunk(tr, tr_chunk , true)
          break
        end
      end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret, ret2 = CheckFunctions('VF_SetTimeShiftPitchChange') 
    if ret then ret2 = VF_CheckReaperVrs(5.95,true) end   
    if ret and ret2 then 
      reaper.Undo_BeginBlock()
      main()
      reaper.Undo_EndBlock('Split focused plugin into to left right instances', -1)
    end  
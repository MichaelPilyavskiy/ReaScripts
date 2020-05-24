-- @description Propagate pooled FX (group 1)
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Add FX if not exist, move/remove if out of designed order, mark them as 'POOL FX <FX_name>', remove if track hasn`t slave JSFX, share TCP ctrls) 
-- @noindex
-- @changelog
--    + Remove pooled FX if not exist in master chain but still marked as pool for defined group

  --NOT gfx NOT reaper
  local group = 1
  
  function PropagatePoolFX(dest_track, src_track, jsfx_id, fx_names)
    -- copy from source/sort if not in order + put at the end of chain
      for src_fx = 1, #fx_names do
        local has_match = false
        local fxname_check = literalize('POOL FX'..group..' '..fx_names[src_fx])
        local cnt_fx = TrackFX_GetCount( dest_track )
        for fx = 1, cnt_fx do 
          local retval, fxname = TrackFX_GetFXName( dest_track, fx-1, '' )
          if fxname:match(fxname_check) then
            has_match = true 
            TrackFX_CopyToTrack( dest_track, fx-1, dest_track, cnt_fx, true )
            if fx-1<jsfx_id then jsfx_id = jsfx_id -1 end -- if pooled Fx stay before JSFX
            break
          end
        end
        if not has_match then  -- if pooled fx not found
          TrackFX_CopyToTrack( src_track, src_fx-1, dest_track, cnt_fx, false ) -- add from source
          local retval, fxname = TrackFX_GetFXName( dest_track, cnt_fx, '' )
          SetFXName(dest_track,cnt_fx, 'POOL FX'..group..' '..fxname)
        end
      end
    
    -- move pool fx after header
      local cnt_fx = TrackFX_GetCount( dest_track )
      for src_fx = 1, #fx_names do TrackFX_CopyToTrack( dest_track,cnt_fx-1, dest_track, jsfx_id+1, true ) end
      
  end
  ------------------------------------------------------------------------ 
  function RemoveUnlistedPools(track, group, fx_names)
    local jsfx_id = GetSlaveJSFXid(track, group)
    
    if not jsfx_id then
      local cnt_fx = TrackFX_GetCount( track )
      for fx = cnt_fx, 1, -1 do 
        local retval, fxname = TrackFX_GetFXName( src_track, fx-1, '' )
        if fxname:match('POOL FX'..group..' ') then
          TrackFX_Delete( track, fx-1 )
        end
      end
    end
    
    if jsfx_id then
      local cnt_fx = TrackFX_GetCount( track )
      for fx = cnt_fx, 1, -1 do 
        local retval, fxname = TrackFX_GetFXName( track, fx-1, '' )
        if fxname:match('POOL FX'..group..' ') then
          local original_name = fxname:match('POOL FX'..group..' (.*)')
          if original_name then
            local has_in_master = false
            for i =1, #fx_names do
              if original_name == fx_names[i] then 
                has_in_master = true 
                break
              end
            end
            if not has_in_master then  TrackFX_Delete( track, fx-1 ) end
          end
        end
      end
    end
  end
  ------------------------------------------------------------------------ 
  function main(group)
    -- find master
      local mastername = 'POOL FX'..group..' master'
      --local src_track
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local retval, trname = GetSetMediaTrackInfo_String( track, 'P_NAME', '', 0 )
        if trname == mastername then src_track = track break end
      end
      if not src_track then MB('Track called "'..mastername..'" not found', 'Pooled FX tools', 0) return end
    
    -- collect fx names
      local fx_names = {}
      for fx = 1,  TrackFX_GetCount( src_track ) do
        local retval, fxname = TrackFX_GetFXName( src_track, fx-1, '' )
        fx_names[#fx_names+1] = fxname
      end
      
    -- loop through tracks
      for i = 1, CountTracks(0) do 
        local track = GetTrack(0,i-1)
        if track ~= src_track then
          local jsfx_id = GetSlaveJSFXid(track, group) --local jsfx_id= TrackFX_AddByName( track, 'POOL FX slave.jsfx', false, 0 ) 
          if jsfx_id and jsfx_id >= 0 then PropagatePoolFX(track, src_track, jsfx_id, fx_names) end 
          RemoveUnlistedPools(track, group, fx_names)
        end
      end
  end
  ---------------------------------------------------------------------
  function GetSlaveJSFXid(track, group)
    for fx = 1,  TrackFX_GetCount( track ) do 
      local retval, fxname = TrackFX_GetFXName( track, fx-1, '' )
      if fxname:match('POOL FX slave')and math.floor(TrackFX_GetParamNormalized( track, fx-1, 0 )*7) == group-1 then return  fx-1 end
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      Undo_BeginBlock() 
      main(group)
      Undo_EndBlock('Propagate pooled FX (group 1)', -1) 
    end
  end
  

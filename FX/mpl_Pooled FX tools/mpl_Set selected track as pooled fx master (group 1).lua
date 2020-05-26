-- @description Set selected track as pooled fx master (group 1)
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Set track name as 'POOL FX1 master', load FX chain from \REAPER\FXChains\POOL FX1 master.RfxChain if any
-- @noindex
-- @changelog
--    # fix error if no track selelcted

  --NOT gfx NOT reaper
  group = 1
  ------------------------------------------------------------------------  
  function ExplodeRS5K_AddChunkToTrack(tr, chunk) -- add empty fx chain chunk if not exists
    local _, chunk_ch = GetTrackStateChunk(tr, '', false)
    if not chunk_ch:match('FXCHAIN') then 
        chunk_ch = chunk_ch:sub(0,-3)..[=[
<FXCHAIN
  SHOW 0
  LASTSEL 0
  DOCKED 0
>
>
]=]
    end
    if chunk then chunk_ch = chunk_ch:gsub('DOCKED %d', chunk) end
    SetTrackStateChunk(tr, chunk_ch, false)
  end  
  ------------------------------------------------------------------------ 
  function main()
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    GetSetMediaTrackInfo_String( tr, 'P_NAME', 'POOL FX'..group..' master', 1 )
    local chain_path = GetResourcePath()..'/FXChains/POOL FX'..group..' master.RfxChain'
    if  file_exists( chain_path ) then
      f = io.open(chain_path, 'r')
      if not f then return end
      local content = f:read('a')
      f:close()
      ExplodeRS5K_AddChunkToTrack(tr, content)
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
      main()
      Undo_EndBlock('Set selected track as pool fx master', -1) 
    end
  end
  

-- @description Add FXChain to selected track
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix path
 
  --NOT gfx NOT reaper
  function AddChunkToTrack(tr, chunk) -- add empty fx chain chunk if not exists
    local _, chunk_ch = reaper.GetTrackStateChunk(tr, '', false)
    if not chunk_ch:match('FXCHAIN') then chunk_ch = chunk_ch:sub(0,-3)..'<FXCHAIN\nSHOW 0\nLASTSEL 0\n DOCKED 0\n>\n>\n' end
    if chunk then chunk_ch = chunk_ch:gsub('DOCKED %d', chunk) end
    reaper.SetTrackStateChunk(tr, chunk_ch, false)
  end 
  
  function main()
    local tr = reaper.GetSelectedTrack(0,0)
    if not tr then return end
    retval, filenameNeed4096 = reaper.GetUserFileNameForRead(reaper.GetResourcePath()..'\\FXChains\\', '', '' )
    if retval and filenameNeed4096 then
      local f = io.open(filenameNeed4096,'r')
      if f then
        content = f:read('a')
        f:close()
        AddChunkToTrack(tr, content)
      end
    end
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
  local scr_name = ({reaper.get_action_context()})[2]
  local num, denom = scr_name:match('Add (%d+) to (%d+) time signature')
  local ret = CheckFunctions('VF_CheckReaperVrs') 
  if ret then 
    if VF_CheckReaperVrs(5.95) then main() end
  end
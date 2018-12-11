-- @description Reset stretch markers to source positions in selected items
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @changelog
--    + init 
  
  function main(item)
    Undo_BeginBlock() 
    for i = 1, CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem(0,i-1) 
      local take = GetActiveTake(item)
      if take and not TakeIsMIDI(take) then
        for i =reaper.GetTakeNumStretchMarkers( take ), 1, -1 do
          local retval, pos, srcpos = reaper.GetTakeStretchMarker(take, i-1)
          SetTakeStretchMarker(take,i-1,srcpos, srcpos)
        end
      end
    end
    UpdateArrange()
    Undo_EndBlock("Reset stretch markers in selected items", 0)    

    
  end

--------------------------------------------------------------------  
---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        return true
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95)    
  if ret and ret2 then main() end  
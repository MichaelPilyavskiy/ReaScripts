-- @description Set selected items timestretch mode to elastique pro, syncronized, transient optimized
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


function MPL_SetTimeShiftPitchChange(item, pshift_mode0, timestr_mode0)
  if not item then return end
  local retval, str = reaper.GetItemStateChunk( item, '', false ) 
  local timestr_mode = tonumber(str:match('PLAYRATE [%d%-%.]+ [%d%-%.]+ [%d%-%.]+ [%d%-%.]+ ([%d%-%.]+)'))
  local timestr_mode_len = string.len(tonumber(timestr_mode))
  local timestr_mode_replace = str:match('(PLAYRATE [%d%-%.]+ [%d%-%.]+ [%d%-%.]+ [%d%-%.]+ [%d%-%.]+)') 
  local pshift_mode = tonumber(str:match('PLAYRATE [%d%-%.]+ [%d%-%.]+ [%d%-%.]+ ([%d%-%.]+)'))
  local pshift_mode_len = string.len(tonumber(pshift_mode))
  local pshift_mode_replace = str:match('(PLAYRATE [%d%-%.]+ [%d%-%.]+ [%d%-%.]+ [%d%-%.]+)') 
  if pshift_mode0 then pshift_mode= pshift_mode0 end
  if timestr_mode0 then timestr_mode = timestr_mode0 end 
  str =str:gsub(timestr_mode_replace:gsub("[%.%+%-]", function(c) return "%" .. c end), timestr_mode_replace:sub(0,-timestr_mode_len-1)..timestr_mode)
  str =str:gsub(pshift_mode_replace:gsub("[%.%+%-]", function(c) return "%" .. c end), pshift_mode_replace:sub(0,-pshift_mode_len-1)..pshift_mode)
  reaper.SetItemStateChunk( item, str, false )
end

------------------------------------------------------------------------------
  function main()
    for i = 1, CountSelectedMediaItems(0) do
      item = reaper.GetSelectedMediaItem(0,i-1)
      pshift_mode =   (6<<16) -- elastique 2.2.8 pro (val = 6 )
                      + (1<<4) -- syncronized (val = 1 )
      timestr_mode = 4 -- transient optimized (val = 4 )
      MPL_SetTimeShiftPitchChange(item, pshift_mode, timestr_mode)
    end
    reaper.UpdateArrange()
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      reaper.Undo_BeginBlock()
      main()
      reaper.Undo_EndBlock('Set selected items timestretch mode to elastique pro, syncronized, transient optimized', 1)
    end  
-- @description Set selected items offset by custom defined shifts
-- @version 1.0
-- @author MPL
-- @changelog
--  init 

  function main()
    
    -- get values from text file. format is like:
    --[[
    21
    0
    -50
    2
    0
dfgds (ignored)
2.5 (ignored)
    0
    0]]
    
    
    local parsedt = GetSplValues()
    if not parsedt then return end
    
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem(0,i-1)
      local tk = GetActiveTake(it)
      if not parsedt[i] then break end
      if tk and not TakeIsMIDI(tk) then
        local src =  GetMediaItemTake_Source( tk )
        if not src then src = GetMediaSourceParent( src ) end
        local SR = GetMediaSourceSampleRate( src )
        local offs = GetMediaItemTakeInfo_Value( tk, 'D_STARTOFFS') 
        SetMediaItemTakeInfo_Value( tk, 'D_STARTOFFS', offs + parsedt[i]/SR) 
      end
    end
    
    UpdateArrange()
    
  end 
  ------------------------------------------------------------------------
  function GetSplValues()
    -- get file location
      local retval, filenameNeed4096 = GetUserFileNameForRead('', 'Set selected items offset by custom defined shifts', 'txt' ) 
      if not retval then return end 
      --filenameNeed4096 = [[C:/Users/MPL_PC/Desktop/New Text Document (2).txt]]
    
    -- get content
      local f = io.open(filenameNeed4096, 'rb')
      if not f then return end
      local content = f:read('a')
      f:close()
    -- get table
      local offst = {}
      for line in content:gmatch('[^\r\n]+') do offst[#offst+1] = tonumber(line) or 0 end
    return offst
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.30) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Set selected items offset by custom defined shifts', 4 )
  end end   
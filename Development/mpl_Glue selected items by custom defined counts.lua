-- @description Glue selected items by custom defined counts
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
    
    
    parsedt = GetSplValues()
    if not parsedt then return end
    local cntcom = 0
    local i_st = 1
    for i = 1,#parsedt do
      local cnt = parsedt[i]
      i_end  = i_st + cnt - 1
      parsedt[i] = {cnt=cnt, i_st = i_st, i_end = i_end}
      i_st = i_end + 1
    end
    
     it_t = {}
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem(0,i-1)
      local tk = GetActiveTake(it)
      if tk then 
        local retval, GUID = GetSetMediaItemTakeInfo_String( tk, 'GUID', '', 0 )
        it_t[i] = GUID
      end
    end
    
    
    -- unselect items
    for i = 1, #parsedt do
    
      --[[for i = 1,#it_t do 
        local take =  reaper.GetMediaItemTakeByGUID( 0, it_t[i] )
        if take then  reaper.SetMediaItemInfo_Value(  reaper.GetMediaItemTake_Item( take ), 'B_UISEL', 0 ) end -- unselect all
      end]]
      reaper.SelectAllMediaItems( 0, false )
      
      for i2 = parsedt[i].i_st, parsedt[i].i_end do
        local take =  reaper.GetMediaItemTakeByGUID( 0, it_t[i2] )
        if take then  reaper.SetMediaItemInfo_Value(  reaper.GetMediaItemTake_Item( take ), 'B_UISEL', 1 ) end
      end
      Action(42432)--Item: Glue items
      
    end
    UpdateArrange()
    
  end 
  ------------------------------------------------------------------------
  function GetSplValues()
    -- get file location
      local retval, filenameNeed4096 = GetUserFileNameForRead('', 'Glue selected items by custom defined counts', 'txt' ) 
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
      Undo_EndBlock2( 0, 'Glue selected items by custom defined counts', 4 )
  end end   
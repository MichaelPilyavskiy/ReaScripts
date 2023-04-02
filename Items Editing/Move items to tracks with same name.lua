-- @description Move items to tracks with same name
-- @version 1.06
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # remove SWS dependency
--   # improve parsing
  
  
  function main()
    local TR_names_t = {}
    for i = 1, CountTracks(0) do 
      local tr = GetTrack(0,i-1)
      local tr_name = ({GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false)})[2]
      if tr_name ~= '' then TR_names_t[#TR_names_t+1] = {tr=tr, tr_name=tr_name:lower()}  end
    end
    if #TR_names_t ==0 then return end
    
    local items = {}
    for i = 1, CountSelectedMediaItems(0) do 
      local retval, itGUID = reaper.GetSetMediaItemInfo_String( GetSelectedMediaItem(0,i-1), 'GUID', '', 0 )
      items[#items+1] =itGUID
    end
    if #items == 0 then return end
    
    for i = 1, #items do
      local item = VF_GetMediaItemByGUID(0,items[i])
      local take = GetActiveTake(item)
      take_name = GetTakeName(take)
      ext = take_name:reverse():match('(.-)%.')
      if ext then 
        ext = ext:reverse()
        take_name = take_name:gsub('.'..ext, '') 
      end
      for k = 1, #TR_names_t do
        if take_name:lower():match(literalize(TR_names_t[k].tr_name))  and  GetMediaItem_Track( item ) ~= TR_names_t[k].tr then MoveMediaItemToTrack(item, TR_names_t[k].tr) end
      end
    end
    UpdateArrange()
  end
  
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Move items to tracks with same name', 0xFFFFFFFF )
  end end
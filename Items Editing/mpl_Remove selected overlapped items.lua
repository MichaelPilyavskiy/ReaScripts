-- @description Remove selected overlapped items
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # remove SWS dependency

  
  function main()
    local t = {}
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )      
      local pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local retval, itGUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', 0 )
      t[#t+1] = {pos=pos,
                end_pos = pos+len,
                guid = itGUID}
    end
    
    ittoremove = {}
    for i = 1, #t do
      if t[i] then
        local pos_cur = t[i].pos
        local end_pos_cur = t[i].end_pos
        for j = 1, #t do
          if t[j] and j ~= i then
            local pos_check = t[j].pos
            local end_pos_check = t[j].end_pos
            if HasCross(pos_cur,end_pos_cur,pos_check,end_pos_check) then
              ittoremove[#ittoremove+1] = t[j].guid
              t[j] = nil
            end
          end
        end
      end
    end
    
    for i = 1, #ittoremove do
      local item = VF_GetMediaItemByGUID( 0, ittoremove[i] )
      if item then reaper.DeleteTrackMediaItem(  reaper.GetMediaItem_Track( item ), item ) end
    end
    
    reaper.UpdateArrange()
  end
  
  function HasCross(p1,p2, p3, p4)
    if  (p1<=p3 and p2>=p3) or 
        (p1<=p4 and p2>=p4) or 
        (p1>p3 and p2<p4) or
        (p1<p3 and p2>p4) then
      return true
    end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Remove selected overlapped items', 0xFFFFFFFF )
  end end
-- @description Remove selected overlapped items
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  --------------------------------------------------------------------  

  
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
  ---------------------------------------------------------------------
  function VF_GetMediaItemByGUID(optional_proj, itemGUID)
    local optional_proj0 = optional_proj or 0
    local itemCount = CountMediaItems(optional_proj);
    for i = 1, itemCount do
      local item = GetMediaItem(0, i-1);
      local retval, stringNeedBig = GetSetMediaItemInfo_String(item, "GUID", '', false)
      if stringNeedBig  == itemGUID then return item end
    end
  end 
  
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6.78,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Remove selected overlapped items', 0xFFFFFFFF )
  end 
-- @description Move items to tracks with same name
-- @version 1.08
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
  ------------------------------------------------------------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
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
    Undo_EndBlock2( 0, 'Move items to tracks with same name', 0xFFFFFFFF )
  end 
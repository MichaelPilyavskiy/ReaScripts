-- @description Move selected items to tracks on same name as items
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # prevent possible error for items with no extension in name [p=2054766]
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function main()
    TR_names_t = {}
    for i = 1, CountTracks(0) do 
      local tr = GetTrack(0,i-1)
      local tr_name = ({GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false)})[2]
      if tr_name ~= '' then TR_names_t[#TR_names_t+1] = {tr=tr, tr_name=tr_name}  end
    end
    if #TR_names_t ==0 then return end
    
    local items = {}
    for i = 1, CountSelectedMediaItems(0) do items[#items+1] = BR_GetMediaItemGUID(GetSelectedMediaItem(0,i-1)) end
    if #items == 0 then return end
    
    for i = 1, #items do
      local item = reaper.BR_GetMediaItemByGUID(0,items[i])
      local take = GetActiveTake(item)
      take_name = GetTakeName(take)
      ext = take_name:reverse():match('(.-)%.')
      if ext then 
        ext = ext:reverse()
        take_name = take_name:gsub('.'..ext, '') 
      end
      for k = 1, #TR_names_t do
        if take_name:match(TR_names_t[k].tr_name) 
          and  GetMediaItem_Track( item ) ~= TR_names_t[k].tr then          
          MoveMediaItemToTrack(item, TR_names_t[k].tr)
        end
      end
    end
    UpdateArrange()
  end
  
  Undo_BeginBlock()
  main()  
  Undo_EndBlock('Move items to tracks on same name as items', 0)

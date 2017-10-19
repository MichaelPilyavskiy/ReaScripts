-- @description Move items to edit cursor if they are same named as their parent tracks
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   + init
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function main()
    local t = {}
    for i = 1, CountSelectedMediaItems(0) do 
      t[#t+1] = GetSelectedMediaItem(0,i-1)
    end
    for i = 1, #t do
      local item = t[i]--GetSelectedMediaItem(0,i-1)
      local take = GetActiveTake(item)
      local take_name = GetTakeName(take)
      local ext = take_name:reverse():match('(.-)%.'):reverse()
      if ext then take_name = take_name:gsub('.'..ext, '') end
      local parent_tr = GetMediaItem_Track( item )
      local  parent_tr_name = ({GetSetMediaTrackInfo_String(parent_tr, 'P_NAME', '', false)})[2]
      if take_name:match(parent_tr_name) then
        SetMediaItemInfo_Value(item, 'D_POSITION',  GetCursorPosition())
      end
    end
    UpdateArrange()
  end
  
  Undo_BeginBlock()
  main()  
  Undo_EndBlock('Move items to edit cursor if they are same named as their parent tracks', 0)
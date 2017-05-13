-- @version 1.02
-- @author MPL
-- @changelog
--   # Wrong file
--   # Fix for takes without extension
  
  --[[
     * ReaScript Name: Move items to tracks on same name as items
     * Author URI: http://forum.cockos.com/member.php?u=70694
    ]]
  
  
  function main()
    TR_names_t = {}
    c_tracks = reaper.CountTracks(0)
    if c_tracks == 0 then return end
    for i = 1, c_tracks do
      track = reaper.GetTrack(0,i-1)
      if track ~= nil then
        _, tr_name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
        TR_names_t[#TR_names_t+1] = tr_name
      end
    end
    
    c_items = reaper.CountSelectedMediaItems(0)
    if c_items == 0 then return end
    items = {}
    for i = 1, c_items do
      item = reaper.GetSelectedMediaItem(0,i-1)
      items[#items+1] = reaper.BR_GetMediaItemGUID(item)
    end

    for i = 1, #items do
      item = reaper.BR_GetMediaItemByGUID(0,items[i])
      if item ~= nil then
        take = reaper.GetActiveTake(item)
        if take ~= nil then 
          take_name = reaper.GetTakeName(take)
          point_cut = take_name:reverse():find('%.')
          if point_cut ~= nil then take_name = take_name:sub(0,-point_cut-1 )
          end
          
          for k = 1, #TR_names_t do
            if take_name == TR_names_t[k] then 
              reaper.MoveMediaItemToTrack(item, reaper.CSurf_TrackFromID(k, false)) 
              reaper.SetMediaItemInfo_Value(item, 'D_POSITION', 0)   
              break 
            end
          end
        end
      end
    end
        
    reaper.UpdateArrange()
  end
  
  reaper.Undo_BeginBlock()
  main()  
  reaper.Undo_EndBlock('Move items to tracks on same name as items', 0)

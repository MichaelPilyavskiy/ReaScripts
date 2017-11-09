-- @description Cut extension from selected item names
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # fix error when nothing to cut
--    # improve extension match pattern


  local scr_title = 'Cut extension from selected item names'
  --  INIT -------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  function RemoveExt(item)
    if not item then return end
    local take = GetActiveTake(item)
    if not take then return end
    local name0 = ({GetSetMediaItemTakeInfo_String(take, 'P_NAME','', false)})[2]
    local name = name0:match('(.-)%.[%a]+')  
    --name = name0:match('(.-)%.[%a%p%(%)%d]+') for almost anything after last dot    
    if name and name ~= name0 then 
      GetSetMediaItemTakeInfo_String(take, 'P_NAME', name, 1)
      UpdateItemInProject(item)
    end
  end

  Undo_BeginBlock()
  for i = 1, CountSelectedMediaItems(0) do RemoveExt(GetSelectedMediaItem(0,i-1)) end
  Undo_EndBlock(scr_title, -1)
  

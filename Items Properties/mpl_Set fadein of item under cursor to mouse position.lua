-- @version 1.1
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Set fadein of item under cursor to mouse position
-- @changelog
--    # fix remove autofade if any
  
  function main()
    reaper.BR_GetMouseCursorContext()
    local item = reaper.BR_GetMouseCursorContext_Item()
    local pos_cur = reaper.BR_GetMouseCursorContext_Position()
    if item then
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH' )   
      reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN_AUTO', -1)
      reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN', pos_cur - pos)
      reaper.UpdateItemInProject(item)
    end
  end
  
  script_title = "Set fadein of item under cursor to mouse position"
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock(script_title, 0)

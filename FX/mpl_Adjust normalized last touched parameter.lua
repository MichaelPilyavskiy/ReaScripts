-- @description Adjust normalized last touched parameter
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Add 0.01 to normalized last touched parameter.lua
--    [main] . > mpl_Add 0.001 to normalized last touched parameter.lua
--    [main] . > mpl_Add 0.0001 to normalized last touched parameter.lua
--    [main] . > mpl_Subtract 0.01 from normalized last touched parameter.lua
--    [main] . > mpl_Subtract 0.001 from normalized last touched parameter.lua
--    [main] . > mpl_Subtract 0.0001 from normalized last touched parameter.lua
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
  function main(val, dir)
    if not dir then return end
     retval, trackid, fxid, paramid = reaper.GetLastTouchedFX()
    if retval then
      local take_id = fxid>>16
      local item_id = trackid>>16
      local trackid = trackid&0xFFFF
      local fxid = fxid&0xFFFF
      local track = reaper.GetTrack(0, trackid-1)
      if trackid == 0 then track = reaper.GetMasterTrack( 0 ) end
      if track then
        
        if item_id ~= 0 then
          local item = reaper.GetTrackMediaItem( track, item_id-1 )
          local take = reaper.GetTake( item, take_id ) 
          local value0 = reaper.TakeFX_GetParamNormalized(take, fxid, paramid)
          local newval = math.max(0,math.min(value0 + val*dir,math.huge))
          reaper.TakeFX_SetParamNormalized(take, fxid, paramid, newval) 
         else 
          local value0 = reaper.TrackFX_GetParamNormalized(track, fxid, paramid)
          local newval = math.max(0,math.min(value0 + val*dir,math.huge))
          reaper.TrackFX_SetParamNormalized(track, fxid, paramid, newval) 
        end
        
      end  
    end
  end  
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true) then 
    local val = ({reaper.get_action_context()})[2]:match('Add%s([%d%p]+%s)')
    if not val then  val = ({reaper.get_action_context()})[2]:match('Subtract%s([%d%p]+%s)') end
    val = val:match('[%d%p]+')
    if not (val and tonumber(val)) then val = 0.01 else val = tonumber(val) end
    dir = ({reaper.get_action_context()})[2]:match('Add')
    if dir then dir = 1 else dir = -1 end
    local dir_str if dir == 1 then dir_str = 'Add X to' else dir_str = 'Subtract X from' end
    local scr_title = dir_str:gsub('X', val).." last touched FX parameter"
    Undo_BeginBlock()
    main(val, dir)
    Undo_EndBlock(scr_title, 1)
  end
  
  
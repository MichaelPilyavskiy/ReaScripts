-- @description Duplicate items until end of time selection
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
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
  ---------------------------------------------------
  function main()
    local tsstart, tsend = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
    if tsend - tsstart < 0.01 then return end
    
    -- get source length
      local items_t = {}
      local bound_st, bound_end = math.huge, -math.huge
      for selitem =1,  CountSelectedMediaItems( 0 ) do
        local item = GetSelectedMediaItem( 0, selitem-1 )
        items_t[#items_t+1] = item
        local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
        local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
        bound_st = math.min(bound_st, pos)
        bound_end = math.max(bound_end, pos+len) 
      end
      local bound_len = bound_end - bound_st-10^-14
      if bound_len > 10^15 then return end
      
      
    -- get duplicates count
      local copies = math.floor((tsend - bound_st) / bound_len)-1
    
    -- share duplicates
      ApplyNudge( 0,--project, 
                  0,--nudgeflag, 
                  5,--nudgewhat, 
                  21,--nudgeunits, 
                  1,--value, 
                  0,--reverse, 
                  copies)--copies ))
    
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.975,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Duplicate items until end of time selection', 0 )
  end
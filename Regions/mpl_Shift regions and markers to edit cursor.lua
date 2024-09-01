-- @description Shift regions and markers to edit cursor
-- @version 1.01
-- @author MPL
-- @about Shift all project regions and markers. Edit cursor is going to be a start of the first region. All others shifted respectively.
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
  
  ---------------------------------------------------------------------------------------------------------------------
  function VF2_ShiftRegions(offset) 
    local regions={}
    local retval, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local rgn_idx = 0
    for idx = 1, num_markers + num_regions do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, idx-1 )
      if isrgn == true then rgn_idx = rgn_idx + 1 end 
      regions[idx] = {isrgn=isrgn,
                            pos = pos,
                            rgnend=rgnend,
                            rgnlen=rgnlen,
                            name=name,
                            markrgnindexnumber=markrgnindexnumber,
                            color=color,
                            rgn_idx=rgn_idx,
                            show = true}
    end
    -- remove all
      for idx = num_markers + num_regions, 1, -1 do reaper.DeleteProjectMarkerByIndex( 0, idx-1 ) end 
    -- add back
      for i = 1, #regions do AddProjectMarker2( 0, regions[i].isrgn, regions[i].pos+offset, regions[i].rgnend+offset, regions[i].name, regions[i].markrgnindexnumber,regions[i]. color ) end
    return true
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true) then 
    Undo_BeginBlock2( 0 )
    local  retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, 0 )
    local curpos = reaper.GetCursorPositionEx( 0 ) 
    local offset = curpos - pos
    VF2_ShiftRegions(offset) 
    Undo_EndBlock2( 0, 'Shift first region to edit cursor, others follow', -1 )
  end
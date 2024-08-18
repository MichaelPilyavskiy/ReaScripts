-- @description Convert selected envelope points to automation item
-- @version 1.01
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
  ---------------------------------------------------  
  function main() 
    local env = GetSelectedEnvelope( 0 )
    if not env then return end
    if CountEnvelopePoints( env ) == 0 then return end
    local position, endpos = math.huge, 0
    for ptidx = 1, CountEnvelopePoints( env ) do
      local retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, ptidx-1 )
      if selected == true then 
        position = math.min(position, time)
        endpos = math.max(endpos, time)
      end
    end
    
    if endpos -  position > 0 and math.abs(endpos - position) > 0.1 then InsertAutomationItem( env, -1, position, endpos -  position) end
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6,true)then
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Convert selected envelope points to automation item', 0xFFFFFFFF )
  end
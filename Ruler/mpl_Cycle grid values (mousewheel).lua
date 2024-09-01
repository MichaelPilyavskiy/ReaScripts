-- @description Cycle grid values (mousewheel)
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # VF independent
 
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
   function VF2_CycleGrid(stages)
     local _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
     stateid = reaper.GetExtState( 'mpl_cycle_grid', 'val' )
     stateid = tonumber(stateid) or 1
     if mouse_scroll == -1 then return end
     if mouse_scroll > 0 then 
       stateid = stateid + 1
      elseif mouse_scroll < 0 then 
       stateid = stateid - 1
     end
     local outval = math.min(#stages, math.max(stateid, 1))
     reaper.SetExtState( 'mpl_cycle_grid', 'val' , outval, true)
     if stages[outval] ~= 0 then
       reaper.Main_OnCommand(40754,0)      --Snapping: Enable snap
       reaper.SetProjectGrid( 0, stages[outval] )
      else
       reaper.Main_OnCommand(40753,0) -- Snapping: Disable snap
     end
   end
   --------------------------------------------------------------------  
  
  local stages = {0, 1, 1/2, 1/4, 1/8, 1/16, 1/32, 1/64, 1/128, 1/3, 1/6, 1/12, 1/24, 1/48} 
            
------------------------------------------------------------------   
  if VF_CheckReaperVrs(5.975,true) then  reaper.defer(function() VF2_CycleGrid(stages) end)  end
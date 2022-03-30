-- @version 1.01
-- @author MPL
-- @description Set project grid (MIDI CC and OSC only)
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

  
  function main()
    local _,_,_,_,_,resolution,val = reaper.get_action_context()
    if resolution < 0 or val < 0 then return end
    local new_grid = 1/(2^math.floor(7 * (val/resolution)))    
    local _, cur_grid = reaper.GetSetProjectGrid( 0, 0)
    if cur_grid ~= new_grid then  
      reaper.GetSetProjectGrid( 0, 1,new_grid ) 
      reaper.UpdateTimeline()
    end
    
  end
  
  reaper.defer(main)

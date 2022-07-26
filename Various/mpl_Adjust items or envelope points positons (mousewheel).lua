-- @description Adjust items or envelope points positons (mousewheel)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  ------------------------------------------------------------------------------------------------------
  function Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      reaper.MIDIEditor_OnCommand( ME, reaper.NamedCommandLookup(s) )
     else
      reaper.Main_OnCommand(reaper.NamedCommandLookup(s), sectionID or 0) 
    end
  end  
--------------------------------------------------------------------
  function main()
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    if val == 0 or not is_new_value then return end
    if val < 0 then  Action(40120) else Action(40119 )end
  end
 
  main()
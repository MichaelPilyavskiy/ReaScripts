-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Add or replace source of item under mouse cursor for RS5k instance on selected track
-- @noindex
-- @changelog
--    #header


  function GetRS5Kpos(track)
    local name_ref = 'reasamplomatic'
    local name_ref2= 'rs5k'
    for i = 1, reaper.TrackFX_GetCount( track ) do
     local retval, nameOut = reaper.TrackFX_GetFXName( track, i-1, '' )
      if nameOut:lower():find(name_ref) or nameOut:lower():find(name_ref2)  then return i-1 end
    end
  end
  
  function main()
    reaper.BR_GetMouseCursorContext()
    local item =  reaper.BR_GetMouseCursorContext_Item()
    if not item then return end
    local track = reaper.GetSelectedTrack(0,0)
    if not track then return end
    local take = reaper.GetActiveTake(item) 
    if not take or reaper.TakeIsMIDI(take) then return end
    local tk_src =  reaper.GetMediaItemTake_Source( take )
    local filename = reaper.GetMediaSourceFileName( tk_src, '' )        
    local rs5k_pos = GetRS5Kpos(track)
    if not rs5k_pos then 
      rs5k_pos = reaper.TrackFX_AddByName( track, 'ReaSamplOmatic5000 (Cockos)', false, -1 )       
    end
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "FILE0", filename)
    reaper.TrackFX_SetNamedConfigParm(track, rs5k_pos, "DONE","")    
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Add or replace source of item under mouse cursor for RS5k instance on selected track', 1)
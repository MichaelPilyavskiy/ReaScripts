-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Add or replace source of selected item for RS5k instance on track under mouse cursor
-- @noindex
-- @changelog
--    # update for use with REAPER 5.981+


  function GetRS5Kpos(track)
    local name_ref = 'reasamplomatic'
    local name_ref2= 'rs5k'
    for i = 1, reaper.TrackFX_GetCount( track ) do
     local retval, nameOut = reaper.TrackFX_GetFXName( track, i-1, '' )
      if nameOut:lower():find(name_ref) or nameOut:lower():find(name_ref2)  then return i-1 end
    end
  end
  
  function main()
    local item = reaper.GetSelectedMediaItem(0,0)
    if not item then return end
    local track = VF_GetTrackUnderMouseCursor()
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

---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetItemTakeUnderMouseCursor') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    script_title = "Add or replace source of selected item for RS5k instance on track under mouse cursor"
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock(script_title, 0)
  end 

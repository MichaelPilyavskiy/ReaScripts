-- @description Create send from focused FX insert
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # fix adding send to the last track in playlist

  
    
  function main()
    
    local defsendvol = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  get_ini_file() )})[2]
    local defsendflag = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  get_ini_file() )})[2]
    
    local ret, tracknumberOut, _, fxnumberOut = GetFocusedFX()
    if not ret or tracknumberOut < 1 or fxnumberOut < 0 then return end
    
    -- get src info
      local src_track = CSurf_TrackFromID( tracknumberOut, false )
    
    -- add new track
    InsertTrackAtIndex( tracknumberOut, true )
    local dest_track = GetTrack(0, tracknumberOut)
    
    -- remove old inssert fx
    new_id = CreateTrackSend( src_track, dest_track )
    SetTrackSendInfo_Value( src_track, 0, new_id, 'D_VOL', defsendvol)
    SetTrackSendInfo_Value( src_track, 0, new_id, 'I_SENDMODE', defsendflag)
    
    TrackFX_CopyToTrack( src_track, fxnumberOut, dest_track, 0, true )
  end

  ---------------------------------------------------------------------
    function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      Undo_BeginBlock()
      main()
      Undo_EndBlock('Create send from focused FX insert', -1)
    end    
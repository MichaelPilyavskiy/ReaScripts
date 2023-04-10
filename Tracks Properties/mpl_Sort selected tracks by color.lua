-- @description Sort selected tracks by color
-- @version 1.4.2
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # remove SWS dependency
 
 
 
 
  function main()
  
    -- collect selected tracks
      tr_t = {}
      local cnt_seltr = CountSelectedTracks(0)
      if cnt_seltr == 0 then return end
      local tr = GetSelectedTrack(0,0)
      local insert_id = CSurf_TrackToID( tr, false ) 
              
      for i =1, cnt_seltr do
        local tr = GetSelectedTrack(0,i-1)
        tr_t[#tr_t+1] = {GUID = GetTrackGUID( tr ),
                        col = GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')}   
      end
    -- sort by col      
      table.sort(tr_t, function(a,b) return a.col<b.col end )
    
    for i = 1, #tr_t do
      --local tr = BR_GetMediaTrackByGUID( 0, tr_t[i].GUID )
      local tr = VF_GetMediaTrackByGUID( 0, tr_t[i].GUID )
      SetOnlyTrackSelected( tr )
      ReorderSelectedTracks(insert_id, 0)
    end
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, "Sort all tracks by color", 0xFFFFFFFF )
  end end
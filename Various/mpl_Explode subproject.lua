-- @description Explode subproject
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Explode subproject track chunks into main project
-- @changelog
--    + init

  local script_title = 'Explode subproject'
  ---------------------------------------------------------------------  
  function main()
    local item = GetSelectedMediaItem(0,0)
    if not item then return end
    local parent_project = GetItemProjectContext( item )
    local take = GetActiveTake(item)
    if not take or TakeIsMIDI(take) then return end
    local src = GetMediaItemTake_Source( take )
    local fn = GetMediaSourceFileName( src, '' )
    if not fn:lower():match('.rpp') then return end
    local sub_proj = GetSubProjectFromSource( src )
    if not sub_proj then 
      Action(40859) --New project tab
      Main_openProject( fn )
      sub_proj = GetSubProjectFromSource( src )
      SelectProjectInstance(parent_project)
    end
    
    if sub_proj then ExplodeSubProj(parent_project, sub_proj, item, take, src) end
  end
  ---------------------------------------------------------------------
  function ExplodeSubProj(parent_project, sub_proj, item, take, src)
    -- collect chunks
      t_chunks = {}
      for i = 1, CountTracks(sub_proj) do
        local track = GetTrack(sub_proj,i-1)
        local retval, chunk = GetTrackStateChunk( track, '', false )
        t_chunks[#t_chunks+1] = chunk
      end

    -- get item data
      it_pos =  GetMediaItemInfo_Value( item, 'D_POSITION' )
      it_len =  GetMediaItemInfo_Value( item, 'D_LENGTH' )
      s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
      srclen = GetMediaSourceLength( src )
      shiftedpos = it_pos-s_offs
      loop_cnt = math.ceil((it_pos + it_len - shiftedpos)/srclen)
      --SetEditCurPos( shiftedpos, false, false )
    
    -- apply chunks  
      --do return end  
      local parent_track =  GetMediaItem_Track( item )
      local parent_track_id = CSurf_TrackToID( parent_track, false )
      for i = 1, #t_chunks do
        InsertTrackAtIndex( parent_track_id, false )
        track = GetTrack(parent_project, parent_track_id)
        SetTrackStateChunk( track, t_chunks[i], false )
      end
      
      for i = 1, #t_chunks do
        track = GetTrack(parent_project, parent_track_id+ i-1)
        
        it_GUIDs = {}
        for itemidx = 1, CountTrackMediaItems( track ) do
          trit = GetTrackMediaItem( track, itemidx-1 )
          it_GUIDs[#it_GUIDs+1] = BR_GetMediaItemGUID( trit )
        end
        for itemidx = 1, CountTrackMediaItems( track ) do
          trit = BR_GetMediaItemByGUID( parent_project, it_GUIDs[itemidx] )
          it_pos0 =  GetMediaItemInfo_Value( trit, 'D_POSITION' )
          SetMediaItemInfo_Value( trit, 'D_POSITION',it_pos0+shiftedpos )
          local retval, it_chunk = reaper.GetItemStateChunk( trit, '', false )
          if it_pos0+shiftedpos  < it_pos or it_pos0+shiftedpos > it_pos + it_len then 
            DeleteTrackMediaItem( track, trit )
          end 
          if loop_cnt > 1 then 
            for i = 1, loop_cnt-1 do
              local new_item =  reaper.AddMediaItemToTrack( track )
              SetItemStateChunk( new_item, it_chunk, false )
              local new_pos = it_pos0+shiftedpos+ srclen*i
              SetMediaItemInfo_Value( new_item, 'D_POSITION',new_pos)
              if new_pos  < it_pos or new_pos > it_pos + it_len then 
                DeleteTrackMediaItem( track, new_item )
              end 
            end
          end
        end
      end
      
      UpdateArrange()
  end
  ---------------------------------------------------------------------
    function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.981,true)    
    if ret and ret2 then 
      reaper.Undo_BeginBlock()
      main()
      reaper.Undo_EndBlock(script_title, 1)
    end  
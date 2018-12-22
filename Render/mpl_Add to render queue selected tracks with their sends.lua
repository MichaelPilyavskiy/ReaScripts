-- @description Add to render queue selected tracks with their sends
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix check for children track
--    # restore mute/solo/selected states
--    + Prepare message

  function main()
    local GUID_t = {}
    for i = 1, CountTracks(0) do 
      local tr= GetTrack(0, i-1)
      GUID_t[#GUID_t+1] = {tr_ptr = tr,
                            GUID = GetTrackGUID(tr) ,
                            mute = GetMediaTrackInfo_Value(tr, "B_MUTE"),
                            solo = GetMediaTrackInfo_Value(tr, "I_SOLO"),
                            is_sel = GetMediaTrackInfo_Value(tr, "I_SELECTED")
                          }
    end   
      
    PreventUIRefresh(1)
    local cnt = 0
    for i = 1, #GUID_t do
      local src_tr = BR_GetMediaTrackByGUID(0, GUID_t[i].GUID)
      if GUID_t[i].is_sel ==1 then
          cnt = cnt+1
          SetOnlyTrackSelected( src_tr )
          MuteAllTracks( true )
          SetMediaTrackInfo_Value(src_tr, "B_MUTE", 0)
          SetMediaTrackInfo_Value(src_tr, "I_SOLO", 0)
          local childs_cnt = GetTrackNumSends(src_tr, 0)
          if childs_cnt > 0 then
            for j = 1, childs_cnt do
              local child_tr = BR_GetMediaTrackSendInfo_Track(src_tr, 0, j-1, 1)
              if child_tr then 
                SetMediaTrackInfo_Value(child_tr, "I_SELECTED", 1)
                SetMediaTrackInfo_Value(child_tr, "B_MUTE", 0)
                SetMediaTrackInfo_Value(child_tr, "I_SOLO", 0)
                UpdateArrange()
                Main_OnCommand(41823, 0) -- add to render queue
              end
            end
           else
            Main_OnCommand(41823, 0) -- add to render queue
          end 
      end
    end
    
    -- restore mute/solo/sel state
    for i = 1, #GUID_t do
      local src_tr = BR_GetMediaTrackByGUID(0, GUID_t[i].GUID)
      SetMediaTrackInfo_Value(src_tr, "I_SELECTED",GUID_t[i].is_sel)
      SetMediaTrackInfo_Value(src_tr, "B_MUTE", GUID_t[i].mute)
      SetMediaTrackInfo_Value(src_tr, "I_SOLO", GUID_t[i].solo)
    end
    
    MB(cnt.." files added to render queue.", "", 0)
    UpdateArrange()
    PreventUIRefresh(-1)
  end
 

---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
---------------------------------------------------------------------
  local ret = CheckFunctions('VF_GetFXByGUID') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    local ret = MB([[
1. Set up followed render settings: 
    - "silently increment filenames" is CHECKED,
    - Render Master mix,
    - wildcards - $project (to prevent overwriting)
2. Save render settings ("Save changes and close").
3. Run script and check your render queue.    

Run script?
    ]], "", 4)
    if ret == 6 then main()  end
  end
   
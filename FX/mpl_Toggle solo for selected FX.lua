-- @description Toggle solo for selected FX
-- @version 1.1
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694 
-- @changelog
--    # perform only one FX chain (first track with opened FX chain)
  

  function main()
    for i=1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0,i-1)
      if track then 
        FX_cnt = reaper.TrackFX_GetCount( track )
        if FX_cnt > 1 then
          sel_FX = reaper.TrackFX_GetChainVisible(track)
          if  sel_FX >= 0 then 
            temp_cnt = 0
            for fx_id = 1, FX_cnt do
              if fx_id -1 ~= sel_FX then
                is_en = reaper.TrackFX_GetEnabled( track, fx_id-1 )
                if is_en then temp_cnt = temp_cnt + 1 end
              end
            end
            if temp_cnt == FX_cnt - 1 then 
              -- mute others
              for i = 1, FX_cnt do
                if i -1 ~= sel_FX then
                  reaper.TrackFX_SetEnabled( track, i-1, false )
                end
              end
             else
              -- enable all
              for i = 1, FX_cnt do
                reaper.TrackFX_SetEnabled( track, i-1, true )
              end
            end
          end
          break
        end
      end
    end
  end
  
  reaper.Undo_BeginBlock()
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0)
  main()
  reaper.Undo_EndBlock("Toggle solo for selected FX", 0)

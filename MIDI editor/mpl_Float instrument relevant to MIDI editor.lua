-- @version 1.04
-- @author MPL
-- @description Float instrument relevant to MIDI editor
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # VF independent
--    # SWS independent

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
  --------------------------------------------------------------------  


--[[
    1.2 23.02.2017
      # fix send instrument lookup (http://github.com/MichaelPilyavskiy/ReaScripts/issues/4)
    1.1 22.02.2017
      + Search instruments in send destination tracks
]]


function main()
  local act_editor = reaper.MIDIEditor_GetActive()
  if not act_editor then return end
  local take = reaper.MIDIEditor_GetTake(act_editor)
  if not take then return end
  local take_track = reaper.GetMediaItemTake_Track(take)
  
  -- search vsti on parent track
    local ret1 = FloatInstrument(take_track )
    if ret1 then return end
    
  ApplyFunctionToTrackInTree(take_track, FloatInstrument)
end
  -------------------------------------------------------------------------------     
  function FloatInstrument(track, toggle)
    local vsti_id = TrackFX_GetInstrument(track)
    if vsti_id and vsti_id >= 0 then 
      if not toggle then 
        TrackFX_Show(track, vsti_id, 3) -- float
       else
        local is_float = TrackFX_GetOpen(track, vsti_id)
        if is_float == false then TrackFX_Show(track, vsti_id, 3) else TrackFX_Show(track, vsti_id, 2) end
      end
      
      return true
    end
  end
  ---------------------------------------------------------------------
    function ApplyFunctionToTrackInTree(track, func) -- function return true stop search
      -- search tree
        local parent_track, ret2, ret3
        local track2 = track
        repeat
          parent_track = reaper.GetParentTrack(track2)
          if parent_track ~= nil then
            ret2 = func(parent_track )
            if ret2 then return end
            track2 = parent_track
          end
        until parent_track == nil    
        
      -- search sends
        local cnt_sends = GetTrackNumSends( track, 0)
        for sendidx = 1,  cnt_sends do
          dest_tr = reaper.GetTrackSendInfo_Value( track, 0, sendidx-1, 'P_DESTTRACK' )
          ret3 = func(dest_tr )
          if ret3 then return  end
        end
    end

  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6,true)then
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Float instrument relevant to MIDI Editor', 0xFFFFFFFF )
  end
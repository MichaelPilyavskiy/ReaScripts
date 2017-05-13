    --[[
   * ReaScript Name: Monitor selected track with track 1
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  function main()
      c_tracks = reaper.CountTracks(0)
      if c_tracks > 0 then  
        track = reaper.GetTrack(0,0)
        sel_track = reaper.GetSelectedTrack(0,0)
        if sel_track ~= nil and sel_track ~=  track then
        
          -- add send
            c_sends = reaper.GetTrackNumSends(sel_track, 0)
            dest_tr_exists = false
            for i =1 , c_sends do
              dest_tr = reaper.BR_GetMediaTrackSendInfo_Track(sel_track, 0, i-1, 1)
              if dest_tr == track then dest_tr_exists = true break end
            end
            if not dest_tr_exists then 
              c_receives = reaper.GetTrackNumSends(track, -1)
              for i =1, c_receives do 
                reaper.RemoveTrackSend(track, -1, i-1)
              end
              reaper.CreateTrackSend(sel_track, track) 
            end
         else
          c_receives = reaper.GetTrackNumSends(track, -1)
          for i =1, c_receives do 
            reaper.RemoveTrackSend(track, -1, i-1)
          end
        end
      end
      reaper.defer(main)
    end
    
    main()

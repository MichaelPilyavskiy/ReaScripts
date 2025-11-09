-- @description Ungroup track from all groups
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  -----------------------------------------------------------------------------------
  function ungrouptrack(tr, groupID)
    local t_groupname = {
      'MEDIA_EDIT_LEAD',
      'MEDIA_EDIT_FOLLOW',
      'VOLUME_LEAD',
      'VOLUME_FOLLOW',
      'VOLUME_VCA_LEAD',
      'VOLUME_VCA_FOLLOW',
      'PAN_LEAD',
      'PAN_FOLLOW',
      'WIDTH_LEAD',
      'WIDTH_FOLLOW',
      'MUTE_LEAD',
      'MUTE_FOLLOW',
      'SOLO_LEAD',
      'SOLO_FOLLOW',
      'RECARM_LEAD',
      'RECARM_FOLLOW',
      'POLARITY_LEAD',
      'POLARITY_FOLLOW',
      'AUTOMODE_LEAD',
      'AUTOMODE_FOLLOW',
      'VOLUME_REVERSE',
      'PAN_REVERSE',
      'WIDTH_REVERSE',
      'NO_LEAD_WHEN_FOLLOW',
      'VOLUME_VCA_FOLLOW_ISPREFX'
    }
      for groupnameID = 1, #t_groupname do
        groupname = t_groupname[groupnameID]
        if groupID<32 then 
          reaper.GetSetTrackGroupMembership( tr, groupname, 1<<(groupID-1), 0 )
         else
          reaper.GetSetTrackGroupMembershipHigh( tr, groupname, 1<<(groupID-33), 0 )
        end
      end 
  end
  -----------------------------------------------------------------------------------
  reaper.Undo_BeginBlock2(-1)
  for i = 1, reaper.CountSelectedTracks(-1) do
    local tr = reaper.GetSelectedTrack(-1,i-1)
    for groupID = 1, 128 do ungrouptrack(tr, groupID) end
  end
  reaper.Undo_EndBlock2( -1, 'Ungroup track from all groups', 0xFFFFFFFF)
  
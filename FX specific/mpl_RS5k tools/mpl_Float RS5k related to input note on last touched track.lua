-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Float RS5k related to input note on last touched track
-- @noindex
-- @changelog
--    #header
  

  function main()
    local tr = reaper.GetLastTouchedTrack()
    local retval, retvals_csv = reaper.GetUserInputs('Float RS5k related to note on last touched track',1, 'search by note', '60')
    if not retval then return end
    local s_note = tonumber(retvals_csv)
    if not s_note then return else s_note = math.floor(s_note) end
    for i = 1,  reaper.TrackFX_GetCount( tr ) do
      local param = reaper.TrackFX_GetParamNormalized( tr, i-1, 4 )
      param = math.floor(param*127)
      if param == s_note then 
        reaper.TrackFX_Show( tr, i-1, 3 )
         
      end
    end
  end


  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Float RS5k related to input note on last touched track', 1)
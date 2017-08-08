-- @version 1.0
-- @author MPL
-- @changelog
--   + init release
-- @description Apply visibility of focused FX TCP controls to instances in selected tracks
-- @website http://forum.cockos.com/member.php?u=70694

  function main()
    local retval, tracknumberOut, itemnumberOut, fxnumberOut = reaper.GetFocusedFX()
    if not  retval then return end
    local src_tr = reaper.CSurf_TrackFromID( tracknumberOut, false )
    local fx_name = ({reaper.TrackFX_GetFXName( src_tr, fxnumberOut, '' )})[2]:match('[%:].*'):sub(3)
    local t = {}
    for i = 1, reaper.CountTCPFXParms( 0, src_tr ) do
      local retval, fxindexOut, parmidxOut = reaper.GetTCPFXParm( 0, src_tr, i-1 )
      if fxindexOut == fxnumberOut then t[#t+1] = parmidxOut end
    end
    if #t < 1  then return end
    
    for i = 1, reaper.CountSelectedTracks(0) do
      local tr = reaper.GetSelectedTrack(0, i-1)
      fx_id = reaper.TrackFX_AddByName( tr, fx_name, false, 0 )
      if fx_id >= 0 then 
        for p_id = 1, #t do reaper.SNM_AddTCPFXParm( tr, fx_id, t[p_id] ) end
      end
    end
  end
  
  main()

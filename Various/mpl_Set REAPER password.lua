-- @description Set REAPER password
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

function main()
  retval, retvals_csv = reaper.GetUserInputs( 'Set new password', 1, ',extrawidth=100', '' )
  if retval then
    reaper.SetExtState( 'mpl_PRWP', 'passkey', retvals_csv, true )
  end
end

main()
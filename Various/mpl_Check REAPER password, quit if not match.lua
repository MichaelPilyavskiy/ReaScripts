-- @description Check REAPER password, quit if not match
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

function main()
  actual_pass = reaper.GetExtState( 'mpl_PRWP', 'passkey' )
  if actual_pass == '' then reaper.MB('The password is not set. Use mpl_Set REAPER password.lua', 'Error', 0) return end
  retval, retvals_csv = reaper.GetUserInputs( 'Password', 1, '*,extrawidth=100', '' )
  if not retval or retvals_csv~= actual_pass then
    reaper.Main_OnCommand( 40004, 0 )--File: Quit REAPER
  end
end

main()

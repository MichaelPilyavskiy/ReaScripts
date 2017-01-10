-- @description Reset internal windows xy positions
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release

  
  function Main()
    x = 0
    y = 0
    ------------------------------------------------  
    local t = { REAPER =
            {'wnd_',
             'transport_',
             'mixwnd_',
             'apiconsole_',
             'custommenuwnd_',
             'iconpicker_',
             'fxadd_',
             'reascriptout_',
             'ccolor_'
            } ,
          actions =
            {use_alt = true,
             'wnd_'
            },
          reascriptedit = 
            {'watch_l'
            },
          perf = 
            {use_alt = true,
             'wnd_'
            },
          midiedit = 
            {'window_'
            },
          vkb = 
            {use_alt = true,
             'wnd_'
            }        
        }
    ------------------------------------------------  
    local path =  reaper.GetResourcePath()..'\\reaper.ini'  
    for key in pairs(t) do 
      for i = 1, #t[key] do   
        if not t[key].use_alt then
          reaper.BR_Win32_WritePrivateProfileString( key, t[key][i]..'x', x, path )
          reaper.BR_Win32_WritePrivateProfileString( key, t[key][i]..'y', y, path )
         else
          reaper.BR_Win32_WritePrivateProfileString( key, t[key][i]..'left', x, path )
          reaper.BR_Win32_WritePrivateProfileString( key, t[key][i]..'top', y, path )
        end      
      end
    end
  end
  
  ret = reaper.MB(
[[Are you sure you want to reset xy positions of windows such as:
  - transport,
  - mixer,
  - API console,
  - menu customizer,
  - icon picker,
  - FX browser,
  - IDE,
  - action list,
  - performance window,
  - MIDI editor,
  - virtual keyboard ?
  
  You will not be able to revert changes. Before executing script all windows should be closed (check toggle state in related actions in Action List).
]], 'Reset internal windows xy positions', 4)
  if ret == 6 then 
    Main()
    reaper.MB('Reload REAPER for applying changes', 'Reset internal windows xy positions', 0)
  end

 reaper.Undo_BeginBlock()
limit = 1 -- message displayed after this items quantity 
script_title = 'Remove Items (confirm if > '..limit..')'

if reaper.CountSelectedMediaItems(0) > limit then
  script_title = 'Remove '..reaper.CountSelectedMediaItems(0).. ' Items'
  ret = reaper.MB('Do you wanna remove '..reaper.CountSelectedMediaItems(0)..' items?',     'Removing items', 4)
  if ret == 6 then reaper.Main_OnCommand(40006,0) end
 else 
  reaper.Main_OnCommand(40006,0)
end

reaper.Undo_EndBlock(script_title,0)

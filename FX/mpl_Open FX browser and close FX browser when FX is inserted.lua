-- @version 1.2
-- @author MPL
-- @description Open FX browser and close FX browser when FX is inserted
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # fix proper loop exit
  

function run()
  count_fx = Count_project_FX()
  if last_count_fx and last_count_fx ~= count_fx then 
    reaper.atexit(reaper.Main_OnCommand(40271, 0))    
  end
  last_count_fx = count_fx
  if isFXBr_open() then reaper.defer(run)   end
end

function isFXBr_open() return reaper.GetToggleCommandStateEx(0,40271) == 1 end

function Count_project_FX()
  local cnt = 0
  for i = 0,  reaper.CountTracks( 0, true ) do
    local track = reaper.GetTrack( 0, i-1, true )
    if i == 0 then track =  reaper.GetMasterTrack( 0 ) end
    cnt = cnt  + reaper.TrackFX_GetCount( track )
  end
  
  for i = 1,  reaper.CountMediaItems( 0 ) do
    local item = reaper.GetMediaItem( 0, i-1 )
    for tk = 1,  reaper.CountTakes( item ) do
      local take =  reaper.GetMediaItemTake( item, tk-1 )
      cnt = cnt  + reaper.TakeFX_GetCount( take )
    end
  end
  return cnt
end

if not isFXBr_open() then reaper.Main_OnCommand(40271, 0) end -- open FX browser
run()

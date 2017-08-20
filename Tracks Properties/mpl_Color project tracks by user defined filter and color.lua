-- @version 1.01
-- @author MPL
-- @description Color project tracks by user defined filter and color
-- @website http://forum.cockos.com/member.php?u=70694  
-- @changelog
--   + add voc

function SetFolderColor(tr)
  _, tr_name =  reaper.GetSetMediaTrackInfo_String( tr, 'P_NAME', '', 0 )
  
  t = {
        [1] = {
              cat = 'drums', 
              r = 10,
              g = 20,
              b = 10
              },
        [2] = {
              cat = 'bass', 
              r = 30,
              g = 80,
              b = 150
              },
        [3] = {
              cat = 'lead', 
              r = 160,
              g = 80,
              b = 40
              },
        [4] = {
              cat = 'extra', 
              r = 60,
              g = 150,
              b = 150
              },
        [5] = {
              cat = 'pad', 
              r = 160,
              g = 160,
              b = 0
              }      ,        
        [6] = {
              cat = 'aux', 
              r = 30,
              g = 30,
              b = 30
              }   ,
        [7] = {
              cat = 'voc', 
              r = 50,
              g = 30,
              b = 30
              }                          
      }
  
  for i = 1, #t do
    if tr_name:lower():find(t[i].cat) 
      and  reaper.GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' ) == 1 then 
       reaper.SetTrackSelected( tr, true )
       reaper.SetTrackColor( tr,  reaper.ColorToNative( t[i].r, t[i].g, t[i].b ) )
       reaper.Main_OnCommand(  reaper.NamedCommandLookup( '_SWS_COLCHILDREN' ), 0 ) -- set col childs
       reaper.Main_OnCommand(  40297,0) -- unselect all
       break
     end 
  end
end

-----------------------------------------------------------------------------------
function main()
  reaper.Main_OnCommand(  40297,0) -- unselect all
  for i = 1, reaper.CountTracks(0) do
    tr =  reaper.GetTrack( 0, i-1 )
    SetFolderColor(tr)
  end
  reaper.TrackList_AdjustWindows( false )
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock('Color project tracks by user defined filter and color', 0)
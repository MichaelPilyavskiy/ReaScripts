-- @description Adjust volume for top folder (MIDI, OSC, mousewheel)
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Adjust volume for top folder 1 (MIDI, OSC, mousewheel).lua
--    [main] . > mpl_Adjust volume for top folder 2 (MIDI, OSC, mousewheel).lua
--    [main] . > mpl_Adjust volume for top folder 3 (MIDI, OSC, mousewheel).lua
--    [main] . > mpl_Adjust volume for top folder 4 (MIDI, OSC, mousewheel).lua
--    [main] . > mpl_Adjust volume for top folder 5 (MIDI, OSC, mousewheel).lua
--    [main] . > mpl_Adjust volume for top folder 6 (MIDI, OSC, mousewheel).lua
--    [main] . > mpl_Adjust volume for top folder 7 (MIDI, OSC, mousewheel).lua
--    [main] . > mpl_Adjust volume for top folder 8 (MIDI, OSC, mousewheel).lua
-- @changelog
--    # fix reapack metapackage handle

   
   
  --------------------------------------------------------------------
  function Get1stlevelFolder()
    --local folderID
    local groupcnt = 0
    local depth_comn = 0
    for i = 1, reaper.CountTracks(0) do
      local tr = reaper.GetTrack(0,i-1)
      local depth = reaper.GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' )
      depth_comn = depth_comn + depth
      if depth_comn == 1 and depth == 1 then 
        groupcnt = groupcnt + 1
        if groupcnt == folderID then 
          return tr
        end
      end
    end
  end
  --------------------------------------------------------------------
  function main()
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    local dir
    val = val / resolution
    if mode > 0 then -- rel
      if val > 0 then dir = 1 elseif val <0 then dir = -1 end
    end
    
    
    local track = Get1stlevelFolder()
    if not track then return end
    
    AdjustTrackVol(track, val, dir) 
  end
  ------------------------------------------------------------------------------------------------------
  function AdjustTrackVol(track, val, dir) 
    if dir then 
      local incr = 0.1 -- dB
      local tr_vol = reaper.GetMediaTrackInfo_Value( track, 'D_VOL' )
      local tr_vol_db = WDL_VAL2DB(tr_vol)
      local tr_vol_out = math.max(WDL_DB2VAL(tr_vol_db + dir*incr),0)
      reaper.SetMediaTrackInfo_Value( track, 'D_VOL' ,tr_vol_out )
     else
      reaper.SetMediaTrackInfo_Value( track, 'D_VOL' ,val )
    end
    reaper.TrackList_AdjustWindows( false )
  end
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x, reduce)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return v  end
  end
  ------------------------------------------------------------------------------------------------------
  
  local scr_name = ({reaper.get_action_context()})[2]
   folderID = scr_name:match('mpl_Adjust volume for top folder (%d+)')
  if tonumber(folderID) then
    folderID = tonumber(folderID)
    reaper.defer(main)
  end
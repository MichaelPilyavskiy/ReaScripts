-- @description Copy selected item stretch markers
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  --------------------------------------------------------------------  

  -- NOT gfx NOT reaper
  local scr_title = 'Copy selected item stretch markers'


  -------------------------------------------------------
  function main()
    local str = ''
    local item = GetSelectedMediaItem(0,0)
    local item_pos =  reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
    
    if item then
      local take = GetActiveTake( item )
      local tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
      local tk_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' ) 
      if take then 
        local cnt =  GetTakeNumStretchMarkers( take )
        for idx = 1, cnt do
          local slope = GetTakeStretchMarkerSlope( take, idx-1 )
          local retval, pos, srcpos = reaper.GetTakeStretchMarker( take, idx-1 )
          str = str..'\n'..pos..' '..srcpos..' '..slope
        end
        SetProjExtState( 0, 'MPLSMCLIPBOARD', 'BUF', str )
        SetProjExtState( 0, 'MPLSMCLIPBOARD', 'ITPOS', item_pos)
        SetProjExtState( 0, 'MPLSMCLIPBOARD', 'TKRATE', tk_rate)
        SetProjExtState( 0, 'MPLSMCLIPBOARD', 'TKOFFS', tk_offs)
        
      end
    end
  end
  
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95) then main() end
  
  
    

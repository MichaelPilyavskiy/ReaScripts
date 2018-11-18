-- @description Copy selected item stretch markers
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # don`t use chunks, write all data directly into ExtState buffer

  -- NOT gfx NOT reaper
  local scr_title = 'Copy selected item stretch markers'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 


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
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        return true
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end

  --------------------------------------------------------
  if CheckFunctions('Action') and VF_CheckReaperVrs(5.95) then main() end
  
  
    

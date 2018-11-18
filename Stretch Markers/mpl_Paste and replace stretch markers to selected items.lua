-- @description Paste and replace stretch markers to selected items
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + improve paste formula (handle slopes, both take offsets, both take rates)
--    # don`t use chunks, parse all data directly from ProjExtState buffer

  -- NOT gfx NOT reaper
  local scr_title = 'Paste and replace stretch markers to selected items'


  -------------------------------------------------------
  function main()
    local retval, str = GetProjExtState( 0, 'MPLSMCLIPBOARD', 'BUF' )
    if retval ~= 1 then return end
    if str == '' then return end
    local item_pos = tonumber(({GetProjExtState( 0, 'MPLSMCLIPBOARD', 'ITPOS')})[2])
    local tk_rate  = tonumber(({GetProjExtState( 0, 'MPLSMCLIPBOARD', 'TKRATE')})[2])    
    local tk_offs = tonumber(({GetProjExtState( 0, 'MPLSMCLIPBOARD', 'TKOFFS')})[2])  
    
    local t = {}
    for pair in str:gmatch('[^\r\n]+') do
      local t_id = #t+1
      local pos, srcpos, slope = pair:match('([%d%.%-]+)%s([%d%.%-]+)%s([%d%.%-]+)')
      t[t_id] = {pos=tonumber(pos),srcpos=tonumber(srcpos),slope=tonumber(slope)}
    end
    
    
    for i = 1, CountSelectedMediaItems() do
      local item = GetSelectedMediaItem(0,i-1)
      local item_pos0 =  reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      if item then
        local take = GetActiveTake( item )
        if take and not TakeIsMIDI(take) then 
          local tk_rate0 = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
          local tk_offs0 = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )         
          local cnt =  GetTakeNumStretchMarkers( take )
          DeleteTakeStretchMarkers( take, 0, cnt )
          
          for i = #t , 1, -1 do
            if t[i].pos then
              local pos_ruler_src = (t[i].pos/tk_rate) + item_pos
              pos_out = (pos_ruler_src - item_pos0  )*tk_rate0 
              new_id = SetTakeStretchMarker( take, -1, pos_out )
              SetTakeStretchMarkerSlope( take, new_id, t[i].slope )
            end
          end
          
        end
      end
    end
    UpdateArrange()
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

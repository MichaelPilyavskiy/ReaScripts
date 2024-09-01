-- @description Paste and replace stretch markers to selected items
-- @version 1.04
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
  local scr_title = 'Paste and replace stretch markers to selected items'


  -------------------------------------------------------
  function main()
    local retval, str = GetProjExtState( 0, 'MPLSMCLIPBOARD', 'BUF' )
    if retval ~= 1 then return end
    if str == '' then return end
    local item_pos = tonumber(({GetProjExtState( 0, 'MPLSMCLIPBOARD', 'ITPOS')})[2])
    local tk_rate  = tonumber(({GetProjExtState( 0, 'MPLSMCLIPBOARD', 'TKRATE')})[2])    
    local tk_offs = tonumber(({GetProjExtState( 0, 'MPLSMCLIPBOARD', 'TKOFFS')})[2])  
    
     t = {}
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
              --local pos_ruler_src = (t[i].pos/tk_rate) + item_pos
              --pos_out = (pos_ruler_src - item_pos0  )*tk_rate0 
              new_id = SetTakeStretchMarker( take, -1, t[i].pos/tk_rate, t[i].srcpos/tk_rate )
              SetTakeStretchMarkerSlope( take, new_id, t[i].slope )
            end
          end
          
        end
      end
    end
    UpdateArrange()
  end
  
  
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then main() end
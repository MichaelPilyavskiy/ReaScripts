-- @description Paste and replace stretch markers to selected items
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix wrong positions

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
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.0) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then main() end end
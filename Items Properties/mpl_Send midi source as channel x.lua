--[[
   * ReaScript Name: Send midi source as channel x
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
--[[
  * Changelog:
  * v1.0 (2016-02-17)
    + Initial Release
--]]
  script_title = "Send midi source as channel x"
  reaper.Undo_BeginBlock()
  
  
  
  function main()
    
    c_sel_items = reaper.CountSelectedMediaItems(0)
    if c_sel_items == 0 then return end
    
    retval, inp_str = reaper.GetUserInputs('Send midi source as channel x', 1, 'Channel number', 1)
    if not retval then return end
    channel = tonumber(inp_str)
    if channel == nil then return end
    if channel <1 or channel > 16 then  return end
    
    for i = 1, c_sel_items do
      item = reaper.GetSelectedMediaItem(0,i-1)
      if item ~= nil then
        take = reaper.GetActiveTake(item)
        if reaper.TakeIsMIDI(take) then
          -- split chunk
            _, chunk = reaper.GetItemStateChunk(item, '')
            t = {}
            for line in chunk:gmatch('[^\n]+') do t[#t+1] = line end
          
          -- search for existing send
            for i = 1, #t do
              if t[i]:find('SOURCE MIDI') ~= nil then src_find = i end
              if t[i]:find('OUTCH') ~= nil then find = 1 find_idx = i end
              if src_find ~= nil then 
                if t[i]:find('GUID') ~= nil then guid_idx = i end
              end
            end
          
          -- replace
            if find ~= nil then 
              t[find_idx] = t[find_idx]:gsub('[%d]', channel) 
             else
              t[guid_idx] = 'OUTCH '..channel..'\n'..t[guid_idx]
            end
        end
        
        --reaper.ShowConsoleMsg(table.concat(t, '\n'))
        reaper.SetItemStateChunk(item, table.concat(t, '\n'))
        
      end
      src_find = nil
      find = nil
    end -- loop items
    reaper.UpdateArrange()
  end
  
  main()

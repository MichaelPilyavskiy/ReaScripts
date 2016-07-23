-- @version 1.0
-- @author mpl
-- @changelog
--   + init
-- @description Move focused Track FX to screen center
-- @website http://forum.cockos.com/member.php?u=70694

--[[
   * ReaScript Name: Move focused Track FX to screen center
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
  ]]
  
-------------------------------------------------
  
  function msg(s) reaper.ShowConsoleMsg(s) end
  
  function main()
    local track, fx_guid, chunk, ch_t,ch_start_id,ch_end_id, float_id
    local     retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX()
    
    if retval == 0 then return end 
    
    -- if track FX
      if retval == 1 then
        if tracknumber == 0 then 
          track = reaper.GetMasterTrack( 0 )
         else
          track = reaper.GetTrack(0, tracknumber -1 )
        end
        if track == nil then return end
         fx_guid = reaper.TrackFX_GetFXGUID( track, fxnumber )
        _, chunk = reaper.GetTrackStateChunk( track, '' )
        
        
        -- get chunk t
          ch_t = {}
          for line in chunk:gmatch('[^\r\n]+') do
            ch_t[#ch_t+1] = line
          end
          
        -- get fx_chian st
          for i = 1, #ch_t do
            if ch_t[i]: find("FXCHAIN") ~= nil then
              ch_start_id = i 
              break
            end
          end
          
        -- get fx chain end
          local level = 0 
          for i = ch_start_id, #ch_t do
          
            if ch_t[i]:find('<') then  
              level = level + 1 
            end
            
            if  ch_t[i]:find('>') then 
              level = level - 1 
            end
            
            if level == 0 then ch_end_id = i break end
          end
          
        -- get line with xywh
          local fx_id = -1
          for i = ch_start_id, ch_end_id do
            if ch_t[i] : find("FLOAT") then fx_id = fx_id + 1 end
            if fx_id == fxnumber then float_id = i break end
          end
          
          --msg(ch_t[float_id])
          param_line = ch_t[float_id]
          temp_t = {}
          for word in param_line:gmatch('[^%s]+') do
            temp_t [#temp_t+1] = tonumber(word)
          end
          
          _, _, scr_w, scr_h = reaper.my_getViewport(0,0,0,0,0,0,0,0, true)
          
          temp_t[1] = math.ceil((scr_w - temp_t[3]) /2)
          temp_t[2] = math.ceil((scr_h - temp_t[4]) /2)
          
          ch_t[float_id] = 'FLOAT '..table.concat(temp_t, ' ')
          
          chunk_out = table.concat(ch_t, '\n')
          --msg(chunk_out)
          
          reaper.SetTrackStateChunk( track, chunk_out )
      end
    
  end
  
  --msg("")
  main()
  

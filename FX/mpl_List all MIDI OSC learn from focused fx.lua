--[[
   * ReaScript Name:List all MIDI OSC learn from focused FX
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  
  function main()
    local fx_chunk, fx_chunk_t,cut_pos,tracknumber,fxnumber,
      track,trackname,fxname,chunk,countfx
    
    _, tracknumber, _, fxnumber = reaper.GetFocusedFX()
    track = reaper.GetTrack(0,tracknumber-1)
    if track ~= nil and fxnumber ~= nil then 
      _, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
      _, fxname = reaper.TrackFX_GetFXName(track, fxnumber, '')
        _, chunk = reaper.GetTrackStateChunk(track, "")
        countfx = reaper.TrackFX_GetCount(track)      
        -- split track chunk
        cut_pos = {}
        fx_chunk = {}
        for i = 1, countfx do
          cut_pos[i] = string.find(chunk, 'BYPASS',cut_pos_end)
          cut_pos_end = string.find(chunk, 'BYPASS',cut_pos[i]+20)
          if cut_pos_end == nil then
            fx_chunk[i] = string.sub(chunk, cut_pos[i])
           else
            fx_chunk[i] = string.sub(chunk, cut_pos[i], cut_pos_end-1)
          end
        end
        
        str = ''
        -- split fx chunk
        fx_chunk_t={}
        for line in fx_chunk[fxnumber+1]:gmatch("[^\r\n]+") do  table.insert(fx_chunk_t, line)  end
        for i = 1, #fx_chunk_t do
          if fx_chunk_t[i]:find('PARMLEARN') ~= nil then 
            out_t = {}
            for word in fx_chunk_t[i]:gsub('PARMLEARN ', ''):gmatch('[^%s]+') do
              if tonumber(word) ~= nil then 
                word = tonumber(word)
               else
                word = word:gsub(' ', '')
              end
              table.insert(out_t, word)
            end  

            _, par_name = reaper.TrackFX_GetParamName(track, fxnumber, out_t[1], '')            
            
            if out_t[2] == 0 then 
              midi = ''
             else
              midiChannel = 1+ out_t[2] & 0x0F
              midiCC = out_t[2] >> 8
              midi = '    MIDI Channel '..midiChannel..' CC '..midiCC
            end
            
            if out_t[4] ~= nil then
              osc = '   OSC: '..out_t[4]
             else
              osc = ''
            end
            
            str = 
            str..' Parameter #'..(out_t[1]+1)..' - '..par_name
            ..'\n'
            ..osc
            ..midi
            ..'\n'
                        
          end -- if found learn
          
          --reaper.ShowConsoleMsg(str)
          
          
        end -- loop chunk
        if str ~= nil then 
          if str == '' then str = 'Learn not found' end
          reaper.MB(str, fxname..' learn', 0) 
        end  
      
    end --if track ~= nil 
  end
  
  local script_title = "List all MIDI OSC learn from focused fx"
  reaper.Undo_BeginBlock()
  main()  
  reaper.Undo_EndBlock(script_title,0)

--[[
   * ReaScript Name: Sort all tracks by color
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.2
  ]]
 
 -- changelog:
 -- 1.2 - 9.12.2015 - fix sends deleted after sort
 -- 1.1 - 8.12.2015 - rewrited from native copy paste actions to getset chunks
 
 script_title = "Sort all tracks by color"
 
  reaper.Undo_BeginBlock()
  
function check(tr_col)
  local col_exist = false
  if #tr_colors_t > 0 then
    for j = 1, #tr_colors_t do
      col = tr_colors_t[j]
      if tr_col == col then col_exist = true end
    end
  end  
  return col_exist
end    
  
reaper.PreventUIRefresh(1)
    
if reaper.CountTracks(0) ~= nil then
  tracks_t = {}
  for i = 1,  reaper.CountTracks(0) do
    tr = reaper.GetTrack(0,i-1)
    reaper.SetMediaTrackInfo_Value(tr,'I_FOLDERDEPTH', 0) 
    _, chunk = reaper.GetTrackStateChunk(tr, '', false)
    count_sends = reaper.GetTrackNumSends(tr, 0)
    sends_t = {}
    if count_sends ~= nil then
      for k = 1, count_sends do
        send_track = reaper.BR_GetMediaTrackSendInfo_Track(tr, 0, k-1, 1)
        if send_track ~= nil then 
          function getsendinfo(send_track,param) return reaper.BR_GetSetTrackSendInfo(send_track, 0, k-1, param, false, 0) end
          sends_t[k] = {reaper.GetTrackGUID(send_track),
                    getsendinfo(send_track,'B_MUTE'),
                    getsendinfo(send_track,'B_PHASE'),
                    getsendinfo(send_track,'B_MONO'),
                    getsendinfo(send_track,'D_VOL'),
                    getsendinfo(send_track,'D_PAN'),
                    getsendinfo(send_track,'D_PANLAW'),
                    getsendinfo(send_track,'I_SENDMODE'),
                    getsendinfo(send_track,'I_SRCCHAN'),
                    getsendinfo(send_track,'I_DSTCHAN'),
                    getsendinfo(send_track,'I_MIDI_SRCCHAN'),
                    getsendinfo(send_track,'I_MIDI_DSTCHAN'),
                    getsendinfo(send_track,'I_MIDI_SRCBUS'),
                    getsendinfo(send_track,'I_MIDI_DSTBUS'),
                    getsendinfo(send_track,'I_MIDI_LINK_VOLPAN')}
        end
        
        
      end
    end
    table.insert(tracks_t, {chunk,reaper.GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR'),sends_t})        
  end
  
  table.sort(tracks_t, function(a,b) return a[2]<b[2] end )
  
  --[[reaper.Main_OnCommand(40296, 0) -- select all tracks
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_SENDS6'),0)]]
  
  for i = 1, #tracks_t do
    track = reaper.GetTrack(0,i-1)
    
    chunk_t = {}
    for line in string.gmatch(tracks_t[i][1], "[^\r\n]+") do 
      if string.find(line, 'AUXRECV') == nil then  table.insert(chunk_t, line) end
    end
    
    reaper.SetTrackStateChunk(track, table.concat(chunk_t, '\n'), true)
    
    if tracks_t[i][3] ~= nil then
      for k = 1, #tracks_t[i][3] do
        send_track = reaper.BR_GetMediaTrackByGUID(0,tracks_t[i][3][k][1])
        if send_track ~= nil then
          reaper.SNM_AddReceive(track, send_track, -1)
          function setsendinfo(send_track,param,value) reaper.BR_GetSetTrackSendInfo(send_track, 0, k-1, param, true, value) end
            setsendinfo(send_track,'B_MUTE',tracks_t[i][3][k][2])
            setsendinfo(send_track,'B_PHASE',tracks_t[i][3][k][3])
            setsendinfo(send_track,'B_MONO',tracks_t[i][3][k][4])
            setsendinfo(send_track,'D_VOL',tracks_t[i][3][k][5])
            setsendinfo(send_track,'D_PAN',tracks_t[i][3][k][6])
            setsendinfo(send_track,'D_PANLAW',tracks_t[i][3][k][7])
            setsendinfo(send_track,'I_SENDMODE',tracks_t[i][3][k][8])
            setsendinfo(send_track,'I_SRCCHAN',tracks_t[i][3][k][9])
            setsendinfo(send_track,'I_DSTCHAN',tracks_t[i][3][k][10])
            setsendinfo(send_track,'I_MIDI_SRCCHAN',tracks_t[i][3][k][11])
            setsendinfo(send_track,'I_MIDI_DSTCHAN',tracks_t[i][3][k][12])
            setsendinfo(send_track,'I_MIDI_SRCBUS',tracks_t[i][3][k][13])
            setsendinfo(send_track,'I_MIDI_DSTBUS',tracks_t[i][3][k][14])
            setsendinfo(send_track,'I_MIDI_LINK_VOLPAN',tracks_t[i][3][k][15])                     
        end
      end
    end
  end
  
end
reaper.TrackList_AdjustWindows(true)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title,0)

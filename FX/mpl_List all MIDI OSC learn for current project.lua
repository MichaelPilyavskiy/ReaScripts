-- @description List all MIDI OSC learn for current project
-- @version 1.03
-- @author mpl
-- @changelog
--   # fix wrong decoding MIDI integer
-- @website http://forum.cockos.com/member.php?u=70694
  
--------------------------------------------------------------
  function GetContent_t()
    local t = {}
    -- get project content
      local _, projfn = reaper.EnumProjects( -1, '' )
      local file = io.open(projfn, 'r')
      if not file then return end
      local content = file:read('a')
      for line in content:gmatch("[^\r\n]+") do t[#t+1] = line end
      file:close()
    -- get monitoring chain content
      local mon_chain_path = reaper.GetResourcePath()..'/reaper-hwoutfx.ini'
      local file = io.open(mon_chain_path, 'r')
      if file then
        local content = file:read('a')
        for line in content:gmatch("[^\r\n]+") do t[#t+1] = line end
        file:close()
      end
      return t
    end
    
--------------------------------------------------------------  
  function GetLearn_t(t_content)   
    if not    t_content then return end
      local cur_guid, osc, midiChannel, midiCC
      local LRN_t = {}
      for i = #t_content, 1, -1 do
        if t_content[i]:find('PARMLEARN') ~= nil then
          -- search upper closer GUID
            for j = i, 1, -1 do if t_content[j]:find('{') ~= nil then cur_guid = t_content[j]:match("%{.+%}") break end end
          -- split chunk line
            local ssv = {}
            for word in t_content[i]:gmatch('[^%s]+') do ssv[#ssv+1] = word end
            if ssv[3] ~= 0 then 
              midiChannel = 1+ ssv[3] & 0x0F
              midiCC = ssv[3] >> 8 & 0x0F
            end
            if ssv[5] then osc = ssv[4] end
          LRN_t[#LRN_t+1] = {midich = midiChannel,
                             midiCC = midiCC,
                             osc = osc,
                             GUID = cur_guid,
                             param_id = tonumber(ssv[2])}
        end          
      end
    return LRN_t
  end
--------------------------------------------------------------
  function CollectProject_GUIDs()  
    local guid_t = {}
    local track, track_name, fx_GUID,track_id,fx_cnt_in, fx_cnt,tp, fx_name,track_guid
    for tr_i = 0, reaper.CountTracks(0) do
      -- get tr inf
        if tr_i == 0 then track_id = 'Master' else track_id = 'Track#'..tr_i end
        track =  reaper.CSurf_TrackFromID( tr_i, false )
        track_guid= reaper.GetTrackGUID( track )
        _, track_name = reaper.GetSetMediaTrackInfo_String( track, 'P_NAME' , '', 0 )
        if track_name == '' then track_name = '(untitled)' end
        if tr_i == 0 then track_name ='' end
      -- get rec fx
        fx_cnt_in = reaper.TrackFX_GetRecCount( track )
          for fx_rec = 0, fx_cnt_in -1 do
            fx_GUID = reaper.TrackFX_GetFXGUID( track, 0x1000000+fx_rec )
            _, fx_name = reaper.TrackFX_GetFXName( track, 0x1000000+fx_rec, '' )
            if tr_i == 0 then tp = 'Monitoring FX' else tp = 'Input FX' end
            guid_t[#guid_t+1] = {
                      GUID = fx_GUID,
                      tp = tp,
                      FX_id = 0x1000000+fx_rec,
                      fx_name = fx_name,
                      track_id = track_id,
                      track_name = track_name,
                    track_guid = track_guid}
          end
      -- get regular fx
        fx_cnt = reaper.TrackFX_GetCount( track )
        for fx = 0, fx_cnt -1 do
          fx_GUID = reaper.TrackFX_GetFXGUID( track, fx )
          _, fx_name = reaper.TrackFX_GetFXName( track, fx, '' )
          guid_t[#guid_t+1] = {
                    GUID = fx_GUID,
                    tp = 'FX',
                    FX_id = fx,
                    fx_name = fx_name,
                    track_id = track_id,
                    track_name = track_name,
                    track_guid = track_guid}
        end 
      -- get item fx chain
        local cnt_items, item, take, fx_GUID,cnt_it_fx
        if tr_i ~= 0 then 
          cnt_items = reaper.CountTrackMediaItems( track )
          for it = 0, cnt_items-1 do
            item =  reaper.GetTrackMediaItem( track, it )
            take = reaper.GetActiveTake(item)
            if take then
              cnt_it_fx = reaper.TakeFX_GetCount( take )
              for fx = 0 , cnt_it_fx-1 do
                fx_GUID = reaper.TakeFX_GetFXGUID( take, fx )
                _, fx_name = reaper.TakeFX_GetFXName( take, fx, '' )
                guid_t[#guid_t+1] = {
                          GUID = fx_GUID,
                          tp = 'ItemFX',
                          FX_id = fx,
                          fx_name = fx_name,
                          track_id = track_id,
                          track_name = track_name,
                          track_guid = track_guid}                  
                
              end
            end
          end
        end
    end
    return  guid_t
  end
--------------------------------------------------------------     
  function ParseLearnTable(LRN_t, guid_t)
    if not LRN_t then return end
    local ret_str = ''
    local i = 1
    for i_lrn = #LRN_t, 1, -1 do
      local cur_guid =  LRN_t[i_lrn].GUID
      for i_guid = 1, #guid_t do
        if cur_guid == guid_t[i_guid].GUID then
          local ind = '   '
          local midi_str,osc_str,param_name
          if LRN_t[i_lrn].midiCC then
            midi_str = 'MIDI ch '..LRN_t[i_lrn].midich..' / MIDI CC '..LRN_t[i_lrn].midiCC..'\n' else midi_str = '' 
          end
          if LRN_t[i_lrn].osc then
            osc_str = 'OSC '..LRN_t[i_lrn].osc..'\n' else osc_str = '' 
          end
          
          if guid_t[i_guid].tp ~= 'ItemFX' then 
            local track = reaper.BR_GetMediaTrackByGUID( 0, guid_t[i_guid].track_guid )
            _, param_name =  reaper.TrackFX_GetParamName( track, guid_t[i_guid].FX_id, LRN_t[i_lrn].param_id, '' )
          end
          ret_str = ret_str
            ..'#'..i..' '
            ..midi_str
            ..osc_str
            ..ind..guid_t[i_guid].fx_name..' ('..guid_t[i_guid].tp..')\n'
            ..ind..param_name..'\n'
            ..ind..guid_t[i_guid].track_id..'   '..guid_t[i_guid].track_name..'\n'
            ..'\n'
          break
        end
        
      end
      i = i +1
    end
    
    -- remv (FX)
      ret_str = ret_str:gsub('%(FX%)', '')
    
    return ret_str
  end
  
--------------------------------------------------------------                
  function main()
    local t_content = GetContent_t()
    local LRN_t = GetLearn_t(t_content)
    local guid_t = CollectProject_GUIDs()  
    local ret_str = ParseLearnTable(LRN_t, guid_t)
    
    if not ret_str or ret_str == '' then ret_str = 'Nothing linked. \nIf it is not, try to save project before running script.' end
          
    reaper.ClearConsole()
    reaper.ShowConsoleMsg(ret_str)
  end
  ------------------------------------------- 
  
  local script_title = "List all MIDI OSC learn for current project"
  reaper.Undo_BeginBlock()
  main()  
  reaper.Undo_EndBlock(script_title,0)

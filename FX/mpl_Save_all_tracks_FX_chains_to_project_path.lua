  script_title = "Save all tracks FX chains to project path"  
  reaper.Undo_BeginBlock()
  
  project_path = reaper.GetProjectPath("")
  ret = reaper.MB('Do you wanna save your FX chains to'..'\n'..
    project_path.."\\Saved FX Chains\\ ?", 'Save all tracks FX chains', 1)
  
  function find_chain(chunk_t, searchfrom)
    for i = searchfrom, #chunk_t do
      st_find = string.find(chunk_t[i], 'BYPASS')
      if st_find == 1 then
        vst_data0 = chunk_t[i]
        j = i
        repeat  
          j = j + 1
          if string.find(chunk_t[j],'FLOATPOS') == nil 
           and string.find(chunk_t[j],'FXID') == nil then
               vst_data0 = vst_data0..'\n'..chunk_t[j] end     
               st_find2 = string.find(chunk_t[j], 'WAK')  
        until st_find2 ~= nil
        return vst_data0, j-1
      end
    end    
  end   
   
   -- collect track fx chains
   if ret == 1 then
     
     chains_t = {}
     counttrack = reaper.CountTracks(0)
     if counttrack ~= nil then
      for i = 1, counttrack do
       track = reaper.GetTrack(0,i-1)
        if track ~= nil then
          _, chunk = reaper.GetTrackStateChunk(track, '')
          chunk_t = {}
          for line in chunk:gmatch("[^\r\n]+") do  table.insert(chunk_t, line)  end
          
          -- find start of fx chain rec input of takefx
          
          for j = 1, #chunk_t do
            st_find0 = string.find(chunk_t[j], '<FXCHAIN')
            if st_find0 ~= nil then chain_exists = true end
            st_find3 = string.find(chunk_t[j], '<FXCHAIN_REC')
            if st_find3 ~= nil then end_search_id = j break
              else st_find4 = string.find(chunk_t[j], '<ITEM')
                if st_find4 ~= nil then end_search_id = j break end
            end
          end
          if end_search_id == nil then end_search_id = #chunk_t end       
          if chain_exists then 
            search_from = 1
            vst_data_com = ""
            while search_from ~= nil and search_from < end_search_id
              do vst_data, search_from = find_chain(chunk_t, search_from)
                if vst_data  ~= nil then
                  vst_data_com = vst_data_com..'\n'..vst_data  end
              end
            _, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
            if trackname == '' then 
              name = 'Track '..i
             else
              name = 'Track '..i..' '..trackname
            end
            table.insert(chains_t, {vst_data_com, name} )
          end
        end
      end     
     end
     
     -- write table to /project_folder/Saved Track FX Chains
     
     if chains_t ~= nil then
      
      reaper.RecursiveCreateDirectory(project_path..'/Saved FX Chains/', 1)
      for i = 1, #chains_t do
        chains_subt = chains_t[i]
        if chains_subt[1] ~= '' then
          file = io.open (project_path..'/Saved FX Chains/'..'/'..chains_subt[2]..'.RfxChain', 'w')
          file:write(chains_subt[1])
          io.close (file)
        end
      end
     end
  end -- if ret ==1
    
  reaper.Undo_EndBlock(script_title, 1)

--  Michael Pilyavskiy FX Chain Viewer --

fontsize  = 16

vrs = "0.011"
 
changelog =                   
[===[
            Changelog:
            
15.11.2015  0.011
            early alpha
04.11.2015  Request from RMM to GUI for FX Chain
            http://rmmedia.ru/threads/118091/page-4#post-1936560
]===]


about = 'FX Chain viewer by Michael Pilyavskiy'..'\n'..'Version '..vrs..'\n'..
[===[    
            Contacts:
   
            Soundcloud - http://soundcloud.com/mp57
            PromoDJ -  http://pdj.com/michaelpilyavskiy
            VK -  http://vk.com/michael_pilyavskiy         
            GitHub -  http://github.com/MichaelPilyavskiy/ReaScripts
            ReaperForum - http://forum.cockos.com/member.php?u=70694
  
 ]===]
 
-----------------------------------------------------------------------
 
 function F_dec(data)
     data = string.gsub(data, '[^'..b..'=]', '')
     return (data:gsub('.', function(x)
         if (x == '=') then return '' end
         local r,f='',(b:find(x)-1)
         for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
         return r;
     end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
         if (#x ~= 8) then return '' end
         local c=0
         for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
         return string.char(c)
     end))
 end
 
 function VAR_default_GUI()
    main_w = 440
    main_h = 355
    
    offset = 5
    
    font = 'Arial'
    fontsize_objects = fontsize - 2
    
    COL1 = {0.2, 0.2, 0.2}
    COL2 = {0.4, 1, 0.4} -- green
    COL3 = {1, 1, 1} -- white
    
    --[[color6_t = {0.2, 0.25, 0.22} -- back2
          color2_t = {0.5, 0.8, 1} -- blue      
          color3_t = {1, 1, 1}-- white
          color4_t = {0.8, 0.3, 0.2} -- red
          color7_t = {0.4, 0.6, 0.4} -- green dark]]
  end

-----------------------------------------------------------------------
  function F_extract_table(table,use)
    if table ~= nil then
      a = table[1]
      b = table[2]
      c = table[3]
      d = table[4]
    end  
    if use == 'rgb' then gfx.r,gfx.g,gfx.b = a,b,c end
    if use == 'xywh' then x,y,w,h = a,b,c,d end
    return a,b,c,d
  end 
  
  function GUI_plugrect(name, xywh)
      
      gfx.a = 0.5
      F_extract_table(COL3,'rgb')
      gfx.setfont(1,font,fontsize_objects)
      
      F_extract_table(xywh,'xywh')
      gfx.x,gfx.y = x,y
      gfx.roundrect(x,y,w,h,0.5,1)
      F_extract_table(COL2,'rgb')
      gfx.x = x + (w - gfx.measurestr(name))/2
      gfx.y = y + (h - fontsize_objects)/2
      gfx.drawstr(name)
      
  end
  
-----------------------------------------------------------------------  
  function GUI_chain()
    if vst_data_t ~= nil then      
      for i = 1, #vst_data_t do
        xywh = ENGINE2_get_xywh(i)
        GUI_plugrect(vst_data_t[i].name, xywh)
      end
    end
  end
  
-----------------------------------------------------------------------
  function GUI_DRAW()
    -- background --
      gfx.a = 1
      F_extract_table(COL1,'rgb')
      gfx.rect(0,0,main_w,main_h)
      
    -- track
      if track ~= nil then
        F_extract_table(COL3,'rgb')
        gfx.setfont(1,font,fontsize)
        if tracknumber > 0 then 
          if track_name ~= '' then 
            str = 'FX Chain of Track '..tracknumber.." - "..track_name
           else
            str = 'FX Chain of Track '..tracknumber
          end
         else
          str = 'FX Chain of Master Track'
        end
        strlen = gfx.measurestr(str)
        gfx.x,gfx.y = (main_w-strlen)/2,10
        gfx.drawstr(str)         
      end
      
      GUI_chain()
    gfx.update()
  end
  
-----------------------------------------------------------------------   
  function F_find_chain(chunk_t, searchfrom)
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
        return vst_data0, j+1, i
      end
    end    
  end 
  
-----------------------------------------------------------------------  
  function ENGINE1_get_data()
    ret, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX()
    if ret == 1 then -- if track chain
      if tracknumber > 0 then 
        track = reaper.GetTrack(0,tracknumber-1)
       else
        track = reaper.GetMasterTrack(0)
      end
      if track ~= nil then
        _, track_name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '',false)
        _, chunk = reaper.GetTrackStateChunk(track, '')
        chunk_t = {}
        for line in chunk:gmatch("[^\r\n]+") do  table.insert(chunk_t, line)  end 
        
          
        -- search track chunk
          
        fx_chain_end_i = #chunk_t
        for j = 1, #chunk_t do
          -- track fx chain search
            st_find0 = string.find(chunk_t[j], '<FXCHAIN')
            if st_find0 ~= nil then chain_exists = true fx_chain_start_i =j end
            st_find1 = string.find(chunk_t[j], '<FXCHAIN_REC')          
            st_find2 = string.find(chunk_t[j], '<ITEM')
            if st_find1 ~= nil or st_find2 ~= nil then fx_chain_end_i = math.min(fx_chain_end_i, j) end
          -- search num channels
            st_find3 = string.find(chunk_t[j], 'NCHAN')
            if st_find3 ~= nil then num_channels = tonumber(string.sub(chunk_t[j],6))end
        end
      end -- if track not null
    end -- if track chain
    
  end
  
----------------------------------------------------------------------  
  function ENGINE1_get_chain_plugins()
    vst_data_t = {}
    if chain_exists and fx_chain_start_i ~= nil and fx_chain_end_i ~= nil then
      search_from = 1
      while search_from ~= nil and search_from < fx_chain_end_i do 
        vst_data, search_from, start_id = F_find_chain(chunk_t, search_from)
        if vst_data ~= nil and start_id < fx_chain_end_i then 
          table.insert(vst_data_t, {vst_data}) 
        end
      end
    end
    
    if track ~= nil then
      fx_count = reaper.TrackFX_GetCount(track)
      if fx_count ~= nil then
        for i = 1, fx_count do
          _, vst_data_t[i].name = reaper.TrackFX_GetFXName(track, i-1, '')
        end
      end
    end
    
  end
  
  function ENGINE2_get_xywh(idx)
    w = gfx.measurestr(vst_data_t[idx].name) + 10
    h = fontsize_objects + 5
    x,y = 10,(fontsize_objects+15)*idx
    
    return {x,y,w,h}
  end
-----------------------------------------------------------------------
  function F_exit() gfx.quit() end
-----------------------------------------------------------------------
  function run()     
    ENGINE1_get_data()
    ENGINE1_get_chain_plugins()
    GUI_DRAW()
    char = gfx.getchar() 
    if char == 27 then exit() end     
    if char ~= -1 then reaper.defer(run) else exit() end
  end 
  
-----------------------------------------------------------------------
  
  VAR_default_GUI()
  gfx.init("mpl FX Chain viewer // ".."Version "..vrs..' DEVELOPER PREVIEW', main_w, main_h)
  reaper.atexit(F_exit) 
  
  run()
  
  
  --reaper.ShowConsoleMsg("")
  --reaper.ShowConsoleMsg(chunk)

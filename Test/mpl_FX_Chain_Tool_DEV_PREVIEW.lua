--  Michael Pilyavskiy FX Chain Tool --

fontsize_menu_name  = 16

vrs = "0.01"
 
changelog =                   
[===[
            Changelog:
            
15.11.2015  0.01
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
 
 function dec(data)
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
    COL1 = {0.2, 0.2, 0.2}
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
  
-----------------------------------------------------------------------
  function GUI_DRAW()
    -- background --
      gfx.a = 1
      F_extract_table(COL1,'rgb')
      gfx.rect(0,0,main_w,main_h)
  end
  
-----------------------------------------------------------------------   
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
        return vst_data0, j+1, i
      end
    end    
  end 
  
-----------------------------------------------------------------------  
  function  ENGINE1_get_chunk_data()
    ret, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX()
    if ret == 1 then -- if track chain
      if tracknumber > 0 then 
        track = reaper.GetTrack(0,tracknumber-1)
       else
        track = reaper.GetMasterTrack(0)
      end
      if track ~= nil then
        _, chunk = reaper.GetTrackStateChunk(track, '')
        chunk_t = {}
        for line in chunk:gmatch("[^\r\n]+") do  table.insert(chunk_t, line)  end 
          
        -- search trackfx chunk
          
        fx_chain_end_i = #chunk_t
        for j = 1, #chunk_t do
          st_find0 = string.find(chunk_t[j], '<FXCHAIN')
          if st_find0 ~= nil then chain_exists = true fx_chain_start_i =j end
          st_find1 = string.find(chunk_t[j], '<FXCHAIN_REC')          
          st_find2 = string.find(chunk_t[j], '<ITEM')
          if st_find1 ~= nil or st_find2 ~= nil then fx_chain_end_i = math.min(fx_chain_end_i, j) end
        end
           
        --[[ get plugins data
              
        if chain_exists then 
          search_from = 1
          vst_data_com = ""
          while search_from ~= nil and search_from < fx_chain_end_i do 
            vst_data, search_from, start_id = find_chain(chunk_t, search_from)
            if vst_data  ~= nil and start_id < fx_chain_end_i then vst_data_com = vst_data_com..'\n'..vst_data  end
          end
        end]]
            
            
            --        retval, string buf reaper.TrackFX_GetFXName(MediaTrack track, integer fx, string buf)
        
        ---str = dec(chunk)
        
        
        --reaper.ShowConsoleMsg("")
        --reaper.ShowConsoleMsg(chunk)
      end
    end
  end
  
-----------------------------------------------------------------------
  function exit() gfx.quit() end
-----------------------------------------------------------------------
  function run() 
    ENGINE1_get_chunk_data()
    GUI_DRAW()
    char = gfx.getchar() 
    if char == 27 then exit() end     
    if char ~= -1 then reaper.defer(run) else exit() end
  end 
  
-----------------------------------------------------------------------
  
  VAR_default_GUI()
  gfx.init("mpl FX Chain Tool // ".."Version "..vrs..' DEVELOPER PREVIEW', main_w, main_h)
  reaper.atexit(exit) 
  
  run()

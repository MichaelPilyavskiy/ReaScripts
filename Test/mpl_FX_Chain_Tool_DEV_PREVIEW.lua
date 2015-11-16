--  Michael Pilyavskiy FX Chain Tool --
test_t = {}
function test(x) table.insert(test_t, x) end
fontsize  = 16

vrs = "0.015"
 
changelog =                   
[===[
            Changelog:
16.11.2015  0.015 properly hex format           
15.11.2015  0.014 early alpha
            extracting data from chunk, basic gui
04.11.2015  Request from RMM to GUI for FX Chain
            http://rmmedia.ru/threads/118091/page-4#post-1936560
]===]


about = 'FX Chain Tool by Michael Pilyavskiy'..'\n'..'Version '..vrs..'\n'..
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
    b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
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
  
-----------------------------------------------------------------------  
  function F_wrap_txt(str, limit, indent, indent1)
    indent = indent or ""
    indent1 = indent1 or indent
    limit = limit or 72
    local here = 1-#indent1
    return indent1..str:gsub("(%s+)()(%S+)()",
                            function(sp, st, word, fi)
                              if fi-here > limit then
                                here = st - #indent
                                return "\n"..indent..word
                              end
                            end)
  end
  
-----------------------------------------------------------------------

 function VAR_default_GUI()
    main_w = 440
    main_h = 600
    
    offset = 5
    
    font = 'Arial'
    fontsize_objects = fontsize - 2
    
    COL1 = {0.2, 0.2, 0.2}
    COL2 = {0.4, 1, 0.4} -- green
    COL3 = {1, 1, 1} -- white
    
    b_get = {10,10,100,25}
    b_get_name = "Get FX chain"
    
    b_set = {10,main_h - 10 - 25,100,25}
    b_set_name = "Set FX chain"
        
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
        --strlen = gfx.measurestr(str)
        gfx.x,gfx.y = b_get[1]+ b_get[3] + 10,  b_get[2] +  (b_get[4]-fontsize)/2
        gfx.drawstr(str)         
      end
    
    -- blocks
      
    if vst_data_t ~= nil then      
      for i = 1, #vst_data_t do
        xywh = ENGINE2_get_xywh(i)
        GUI_plugrect(vst_data_t[i].name, xywh)
      end
    end
  end
  
 ----------------------------------------------------------------------- 
  function GUI_button(b_name,xywh_t, frame)
    gfx.a = 0.1
    F_extract_table(COL3,'rgb')
    F_extract_table(xywh_t,'xywh')
    gfx.rect(x,y,w,h)
    
    F_extract_table(xywh_t,'xywh')
    gfx.setfont(1,font,fontsize)
    gfx.x = x + (w - gfx.measurestr(b_name))/2
    gfx.y = y + (h - fontsize_objects)/2
    gfx.a = 1    
    gfx.drawstr(b_name)
    
    if frame then
      gfx.a = 1
      F_extract_table(COL2,'rgb')
      F_extract_table(xywh_t,'xywh')
      gfx.roundrect(x,y,w,h,false,1)
    end
    
  end
  
-----------------------------------------------------------------------
  function GUI_DRAW()
    -- background --
      gfx.a = 1
      F_extract_table(COL1,'rgb')
      gfx.rect(0,0,main_w,main_h)
    
    -- buttons
      GUI_button(b_get_name, b_get, b_get_frame)
      GUI_button(b_set_name, b_set, b_set_frame)
      
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
          -- search track fx chain exists
            st_find0 = string.find(chunk_t[j], '<FXCHAIN')
          -- search track fx chain edges
            if st_find0 ~= nil then chain_exists = true fx_chain_start_i =j end
            st_find1 = string.find(chunk_t[j], '<FXCHAIN_REC')          
            st_find2 = string.find(chunk_t[j], '<ITEM')
            if st_find1 ~= nil or st_find2 ~= nil then fx_chain_end_i = math.min(fx_chain_end_i, j) end
          -- search num channels
            st_find3 = string.find(chunk_t[j], 'NCHAN')
            if st_find3 ~= nil then num_channels = tonumber(string.sub(chunk_t[j],6))end
        end
        
        -- add fx chunk id into table
        -- add fx chunk into table
        vst_data_t = {}
        if chain_exists and fx_chain_start_i ~= nil and fx_chain_end_i ~= nil then
          search_from = 1
          while search_from ~= nil and search_from < fx_chain_end_i do 
            vst_data, search_from, start_id = F_find_chain(chunk_t, search_from)
            if vst_data ~= nil and start_id < fx_chain_end_i then 
              table.insert(vst_data_t, {['id']=start_id, ['id_end']=search_from-1, ['fullchunk']=vst_data}) 
            end
          end
        end
        
        -- add plugin names into table
        
        fx_count = reaper.TrackFX_GetCount(track)
        if fx_count ~= nil then
          for i = 1, fx_count do
            _, vst_data_t[i].name = reaper.TrackFX_GetFXName(track, i-1, '')
          end
        end
           
        -- extract base64 from JS and VST
        
        for i=1, #vst_data_t do
          -- if VST/DX
          st_find_10 = string.find(chunk_t[vst_data_t[i].id+1], '<VST')
          st_find_11 = string.find(chunk_t[vst_data_t[i].id+1], '<DX')
          if st_find_10 ~= nil or st_find_11 then
            k = 2
            vst_data_t[i].base64=''
            repeat
              vst_data_t[i].base64 = vst_data_t[i].base64..chunk_t[vst_data_t[i].id+k]
              k = k + 1
              until chunk_t[vst_data_t[1].id+k] ~= '>'
          end
          -- if JS
          st_find_13 = string.find(chunk_t[vst_data_t[i].id+1], '<JS')
          if st_find_13 ~= nil then
             if string.find(chunk_t[vst_data_t[i].id+4], '<JS_PINMAP') ~= nil then
               k = 5
               vst_data_t[i].base64=''
               repeat
                vst_data_t[i].base64 = vst_data_t[i].base64..chunk_t[vst_data_t[i].id+k]
                k = k + 1
                until chunk_t[vst_data_t[1].id+k] ~= '>'
             end
          end
        end -- loop
        
      -- get readable routing from base64
      
        for i = 1, #vst_data_t do
          if vst_data_t[i].base64 == nil then
            vst_data_t[i].routing = string.rep('0', num_channels^2) 
           else
            
            hex = {}
            str_src = vst_data_t[i].base64
            string_ret = F_dec(vst_data_t[i].base64)
            
            for m = 1, string.len(string_ret),4 do
            
              -- cut every 4 chars
              string_ret_cut = string.sub(string_ret, m,m+3)              
              
              -- string to integer
              if string.len(string_ret_cut) == 4 then
                int = (string.byte(string_ret_cut,1) <<  0) | 
                    (string.byte(string_ret_cut,2) <<  8) |
                    (string.byte(string_ret_cut,3) << 16) | 
                    (string.byte(string_ret_cut,4) << 24) 
              end   
              if int ~= nil then hex[m] = string.format('%08X',int) end
              
              
            end
          end
        end
      
        
        
      end -- if track not null
     else
      track = nil
      vst_data_t = {}
    end -- if track chain
    
  end
  
-----------------------------------------------------------------------  
  function ENGINE2_get_xywh(idx)
    w = gfx.measurestr(vst_data_t[idx].name) + 10
    h = fontsize_objects + 5
    x = 10
    y = 30+(fontsize_objects+30)*idx
    
    return {x,y,w,h}
  end
  
  -----------------------------------------------------------------------
    function MOUSE_gate(mb, b)
      local state    
      if MOUSE_match_xy(b) then       
       if mb == 1 then if LMB_state and not last_LMB_state then state = true else state = false end end
       if mb == 2 then if RMB_state and not last_RMB_state then state = true else state = false end end 
       if mb == 64 then if MMB_state and not last_MMB_state then state = true else state = false end end        
      end   
      return state
    end
  -----------------------------------------------------------------------
  function MOUSE_match_xy(b)
    if    mx > b[1] 
      and mx < b[1]+b[3]
      and my > b[2]
      and my < b[2]+b[4] then
     return true 
    end 
  end
      
  -----------------------------------------------------------------------  
  function MOUSE_get()
      LMB_state = gfx.mouse_cap&1 == 1 
      RMB_state = gfx.mouse_cap&2 == 2 
      MMB_state = gfx.mouse_cap&64 == 64  
      mx, my = gfx.mouse_x, gfx.mouse_y
          if LMB_state and not last_LMB_state then mx0,my0 = mx,my else  end
          if mx0 ~= nil and my0 ~= nil then    mx_rel,my_rel = mx0-mx, my0-my end
          
      if MOUSE_gate(1, b_get) then ENGINE1_get_data() end
      if MOUSE_match_xy(b_get) then b_get_frame = true else b_get_frame = false end
      
      if MOUSE_match_xy(b_set) then b_set_frame = true else b_set_frame = false end
      
      last_LMB_state = LMB_state    
      last_RMB_state = RMB_state
      last_MMB_state = MMB_state 
  end
  
-----------------------------------------------------------------------
  function F_exit() gfx.quit() end
  
-----------------------------------------------------------------------
  function run()    
    GUI_DRAW()
    MOUSE_get()
     
    
    --reaper.ShowConsoleMsg("")
    --reaper.ShowConsoleMsg(vst_data_t[1][1])
    
    char = gfx.getchar()
    if char == 27 then exit() end     
    if char ~= -1 then reaper.defer(run) else F_exit() end
  end 
  
-----------------------------------------------------------------------
  
  VAR_default_GUI()
  gfx.init("mpl FX Chain Tool // ".."Version "..vrs..' DEVELOPER PREVIEW', main_w, main_h)
  reaper.atexit(F_exit) 
  
  run()
  
  

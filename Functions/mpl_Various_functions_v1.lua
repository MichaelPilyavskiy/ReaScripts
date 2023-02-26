-- @description Various_functions_v1
-- @author MPL
-- @noindex  
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function VF2_LoadVFv2() return true end
  ---------------------------------------------------
  function msg(s) 
    if not s then return end 
    if type(s) == 'boolean' then
      if s then s = 'true' else  s = 'false' end
    end
    ShowConsoleMsg(s..'\n') 
  end 
  ---------------------------------------------------
  function VF_hex2rgb(s16,set)
    s16 = s16:gsub('#',''):gsub('0X',''):gsub('0x','')
    local b,g,r = ColorFromNative(tonumber(s16, 16))
    if set then
      if GetOS():match('Win') then gfx.set(r/255,g/255,b/255) else gfx.set(b/255,g/255,r/255) end
    end
    return r/255, g/255, b/255
  end
  ---------------------------------------------------
  function VF_GetProjIDByPath(projfn)
    for idx  = 0, 1000 do
      retval, projfn0 = reaper.EnumProjects( idx )
      if not retval then return end
      if projfn == projfn0 then return idx end
    end
  end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  --[[local track_guid_cache = {}; 
  function VF_GetTrackByGUID(g,proj0)--https://forum.cockos.com/showpost.php?p=2132656&postcount=10
    local proj = proj0 or 0
    local c = track_guid_cache[g];
    if c ~= nil and reaper.GetTrack(proj,c.idx) == c.ptr and reaper.GetTrackGUID(c.ptr) == g then
      -- cached!
      return c.ptr;
    end
    
    -- find guid in project
    local x = 0
    while true do
      local t = reaper.GetTrack(proj,x)
      if t == nil then
        -- not found in project, remove from cache and return error
        if c ~= nil then track_guid_cache[g] = nil end
        return nil
      end
      if g == reaper.GetTrackGUID(t) then
        -- found, add to cache
        track_guid_cache[g] = { idx = x, ptr = t }
        return t
      end
      x = x + 1
    end
  end]]
  ---------------------------------------------------
  function VF_GetFXByGUID(GUID, tr)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(0) do
        local tr = GetTrack(0,trid-1)
        for fx_id =1, TrackFX_GetCount( tr ) do
          
          if TrackFX_GetFXGUID( tr, fx_id-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_id-1 end
        end
      end  
     else
      for fx_id =1, TrackFX_GetCount( tr ) do
        if TrackFX_GetFXGUID( tr, fx_id-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_id-1 end
      end
    end    
  end
  ---------------------------------------------------
  function VF_CalibrateFont(sz, rawsz) -- https://forum.cockos.com/showpost.php?p=2066576&postcount=17
    --  rawsz starting from 2.08 used for new script to allow use raw sz values rather than table hardcoded values
   local t = { [13]=80,
                [15]=90,
                [19]=110,
                [21]=150} -- windows measured
    gfx.setfont(1, 'Calibri', sz)    
    local str_width, str_height = gfx.measurestr("MMMMMMMMMM")
    local font_factor
    if rawsz then 
      font_factor = sz*6.5 / str_width 
     else
      font_factor = t[sz]/str_width 
    end
    return math.floor(sz*font_factor)
  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  ---------------------------------------------------
  function VF_GetFormattedGrid(grid_div)
    local grid_flags, grid_division, grid_swingmode, grid_swingamt 
    if not grid_div then 
      grid_flags, grid_division, grid_swingmode, grid_swingamt  = GetSetProjectGrid( 0, false )
     else 
      grid_flags, grid_division, grid_swingmode, grid_swingamt = 0,grid_div,0,0
    end
    local is_triplet
    local denom = 1/grid_division
    local grid_str
    if denom >=2 then 
      is_triplet = (1/grid_division) % 3 == 0 
      grid_str = '1/'..math.floor(denom)
      if is_triplet then grid_str = '1/'..math.floor(denom*2/3) end
     else 
      grid_str = 1
      is_triplet = math.abs(grid_division - 0.6666) < 0.001
    end
    local grid_swingamt_format = math.floor(grid_swingamt * 100)..'%'
    return grid_division, grid_str, is_triplet, grid_swingmode, grid_swingamt, grid_swingamt_format
  end     
  
  ------------------------------------------------------------------------------------------------------
  function getKeysSortedByValue(tbl, sortFunction, param) -- https://stackoverflow.com/questions/2038418/associatively-sorting-a-table-by-value-in-lua
    local keys = {}
    for key in pairs(tbl) do table.insert(keys, key) end  
    table.sort(keys, function(a, b) return sortFunction(tbl[a][param], tbl[b][param])  end)  
    return keys
  end  

  ------------------------------------------------------------------------------------------------------
  function eugen27771_GetObjStateChunk(obj)
    
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if vrs_num >= 5.93 then 
      if  ValidatePtr2( 0, obj, 'MediaTrack*' ) then
        local retval, chunk = GetTrackStateChunk( obj, '', false )
        return chunk
      end
     else
      if not obj then return end
      local fast_str, chunk
      fast_str = SNM_CreateFastString("")
      if SNM_GetSetObjectState(obj, fast_str, false, false) then chunk = SNM_GetFastString(fast_str) end
      SNM_DeleteFastString(fast_str)  
      return chunk    
    end
    
  end 
  ------------------------------------------------------------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end  
  ------------------------------------------------------------------------------------------------------
  function deliteralize(str) 
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", '') end
  end  
  ---------------------------------------------------
  function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end 
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  --function dBFromVal(val) if val < 0.5 then return 20*math.log(val*2, 10) else return (val*12-6) end end
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x, reduce)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else 
      if reduce then 
        return string.format('%.2f', v)
       else 
        return v 
      end
    end
  end
  ------------------------------------------------------------------------------------------------------
  function GetSpectralData(item)
    --[[
    {table}
      {takeID}
        {edits}
          {editID = 
            param = value}
    ]]
    if not item then return end
    local chunk = ({GetItemStateChunk( item, '', false )})[2]
    -- parse chunk
    local tk_cnt = 0
    local SE ={}
    for line in chunk:gmatch('[^\r\n]+') do 
    
      if line:match('<SOURCE') then 
        tk_cnt =  tk_cnt +1 
        SE[tk_cnt]= {}
      end 
        
      if line:match('SPECTRAL_CONFIG') then
        local sz = line:match('SPECTRAL_CONFIG ([%d]+)')
        if sz then sz = tonumber(sz) end
        SE[tk_cnt].FFT_sz = sz
      end
            
      if line:match('SPECTRAL_EDIT%s') then  
        if not SE[tk_cnt].edits then SE[tk_cnt].edits = {} end
        local tnum = {} 
        for num in line:gmatch('[^%s]+') do if tonumber(num) then tnum[#tnum+1] = tonumber(num) end end
        
        local take = GetMediaItemTake( item, tk_cnt-1 )
        local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS'  )
        local rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE'  ) 
        

            
        SE[tk_cnt].edits [#SE[tk_cnt].edits+1] =       {pos = (tnum[1] - s_offs)/rate,
                       len = tnum[2]/rate,
                       gain = tnum[3],
                       fadeinout_horiz = tnum[4], -- knobleft/2 + knobright/2
                       fadeinout_vert = tnum[5], -- knoblower/2 + knobupper/2
                       freq_low = tnum[6],
                       freq_high = tnum[7],
                       chan = tnum[8], -- -1 all 0 L 1 R
                       bypass = tnum[9], -- bypass&1 solo&2
                       gate_threshold = tnum[10],
                       gate_floor = tnum[11],
                       compress_threshold = tnum[12],
                       compress_ratio = tnum[13],
                       unknown1 = tnum[14],
                       unknown2 = tnum[15],
                       fadeinout_horiz2 = tnum[16],  -- knobright - knobleft
                       fadeinout_vert2 = tnum[17],
                       chunk_str = line} -- knobupper - knoblower
      end
  
  
      local pat = '[%d%.]+ [%d%.]+'
      if line:match('SPECTRAL_EDIT_B') then  
        if not SE[tk_cnt].edits [#SE[tk_cnt].edits].points_bot then SE[tk_cnt].edits [#SE[tk_cnt].edits].points_bot = {} end
        for pair in line:gmatch('[^%+]+') do 
          SE[tk_cnt].edits [#SE[tk_cnt].edits].points_bot [#SE[tk_cnt].edits [#SE[tk_cnt].edits].points_bot + 1] = pair:match(pat)
        end
      end

      if line:match('SPECTRAL_EDIT_T') then  
        if not SE[tk_cnt].edits [#SE[tk_cnt].edits].points_top then SE[tk_cnt].edits [#SE[tk_cnt].edits].points_top = {} end
        for pair in line:gmatch('[^%+]+') do 
          SE[tk_cnt].edits [#SE[tk_cnt].edits].points_top [#SE[tk_cnt].edits [#SE[tk_cnt].edits].points_top + 1] = pair:match(pat)
        end
      end
                                   
    end
    return true, SE
  end
  ------------------------------------------------------------------------------------------------------
  function SetSpectralData(item, data, apply_chunk)
    --[[
    {table}
      {takeID}
        {edits}
          {editID = 
            param = value}
    ]]  
    if not item then return end
    local chunk = ({GetItemStateChunk( item, '', false )})[2]
    chunk = chunk:gsub('SPECTRAL_CONFIG.-\n', '')
    chunk = chunk:gsub('SPECTRAL_EDIT.-\n', '')
    local open
    local t = {} 
    for line in chunk:gmatch('[^\r\n]+') do t[#t+1] = line end
    local tk_cnt = 0 
    for i = 1, #t do
      if t[i]:match('<SOURCE') then 
        tk_cnt = tk_cnt + 1 
        open = true 
      end
      if open and t[i]:match('>') then
      
        local add_str = ''
        local take  =GetTake( item, tk_cnt-1 )
        if data[tk_cnt] 
          and data[tk_cnt].edits 
          and take
          and not TakeIsMIDI(take)
          then
          for edit_id in pairs(data[tk_cnt].edits) do
            if not data[tk_cnt].FFT_sz then data[tk_cnt].FFT_sz = 1024 end
            local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS'  )
            local rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE'  ) 
            if not apply_chunk then
              add_str = add_str..'SPECTRAL_EDIT '
                ..data[tk_cnt].edits[edit_id].pos*rate + s_offs..' '
                ..data[tk_cnt].edits[edit_id].len*rate..' '
                ..data[tk_cnt].edits[edit_id].gain..' '
                ..data[tk_cnt].edits[edit_id].fadeinout_horiz..' '
                ..data[tk_cnt].edits[edit_id].fadeinout_vert..' '
                ..data[tk_cnt].edits[edit_id].freq_low..' '
                ..data[tk_cnt].edits[edit_id].freq_high..' '
                ..data[tk_cnt].edits[edit_id].chan..' '
                ..data[tk_cnt].edits[edit_id].bypass..' '
                ..data[tk_cnt].edits[edit_id].gate_threshold..' '
                ..data[tk_cnt].edits[edit_id].gate_floor..' '
                ..data[tk_cnt].edits[edit_id].compress_threshold..' '
                ..data[tk_cnt].edits[edit_id].compress_ratio..' '
                ..data[tk_cnt].edits[edit_id].unknown1..' '
                ..data[tk_cnt].edits[edit_id].unknown2..' '
                ..data[tk_cnt].edits[edit_id].fadeinout_horiz2..' '
                ..data[tk_cnt].edits[edit_id].fadeinout_vert2..' '
                ..'\n'
              
              if data[tk_cnt].edits[edit_id].points_bot then
                for pt = 1, #data[tk_cnt].edits[edit_id].points_bot, 10 do
                  add_str = add_str..'SPECTRAL_EDIT_B '..table.concat(data[tk_cnt].edits[edit_id].points_bot, ' + ', pt, math.min(#data[tk_cnt].edits[edit_id].points_bot, pt + 10))
                end
                add_str = add_str..'\n'
              end

              if data[tk_cnt].edits[edit_id].points_top then
                for pt = 1, #data[tk_cnt].edits[edit_id].points_top, 10 do
                  add_str = add_str..'SPECTRAL_EDIT_T '..table.concat(data[tk_cnt].edits[edit_id].points_top, ' + ', pt,  math.min(#data[tk_cnt].edits[edit_id].points_top, pt + 10))
                end
                add_str = add_str..'\n'
              end
                            
              add_str = add_str..'SPECTRAL_CONFIG '..data[tk_cnt].FFT_sz ..'\n'
              --msg(add_str)
             else
              add_str = apply_chunk..'\nSPECTRAL_CONFIG '..data[tk_cnt].FFT_sz ..'\n'
              
            end
          end        
        end
        
        t[i] = t[i]..'\n'..add_str
        open = false
      end
    end   
    
    local out_chunk = table.concat(t, '\n')
    --ClearConsole()
    --msg(out_chunk)
    SetItemStateChunk( item, out_chunk, false )
    UpdateItemInProject( item )
  end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
  ---------------------------------------------------
  function ExtState_Load(conf)
    if conf.dontload == true then return end
    local def = ExtState_Def()
    for key in pairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end    
  end  
  ---------------------------------------------------
  function ExtState_Save(conf)
    if conf.dontload == true then return end 
    conf.dock , conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h= gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
    --for k,v in spairs(conf, function(t,a,b) return b:lower() > a:lower() end) do SetExtState(conf.ES_key, k, conf[k], true) end  
  end
  ---------------------------------------------------------------------------------------------------------------------
  function NormalizeT(t, key)
    local m = 0 
    for i = 1, #t do 
      if not key then 
        m = math.max(math.abs(t[i]),m) 
       else
        m = math.max(math.abs(t[i][key]),m) 
      end
    end
    for i = 1, #t do 
      if not key then
        t[i] = t[i] / m 
       else 
        t[i][key] = t[i][key] / m 
      end
    end
  end 
  ---------------------------------------------------------------------------------------------------------------------
  function ScaleT(t, scaling)
    for i =1, #t do t[i]= t[i]^scaling end
  end   
  ---------------------------------------------------------------------------------------------------------------------
  function SmoothT(t, smooth)
    for i = 2, #t do t[i]= t[i] - (t[i] - t[i-1])*smooth   end
  end  
  ---------------------------------------------------------------------------------------------------------------------
  function GetParentFolder(dir) return dir:match('(.*)[%\\/]') end
  ---------------------------------------------------------------------------------------------------------------------
  function VF_GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end  
  ---------------------------------------------------------------------------------------------------------------------
    function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  -------------------------------------------------------------------------------   
  function ExportSelItemsToRs5k_FormMIDItake_data()
    local MIDI = {}
    -- check for same track/get items info
      local item = reaper.GetSelectedMediaItem(0,0)
      if not item then return end
      MIDI.it_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      MIDI.it_end_pos = MIDI.it_pos + 0.1
      local proceed_MIDI = true
      local it_tr0 = reaper.GetMediaItemTrack( item )
      for i = 1, reaper.CountSelectedMediaItems(0) do
        local item = reaper.GetSelectedMediaItem(0,i-1)
        local it_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
        local it_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
        MIDI[#MIDI+1] = {pos=it_pos, end_pos = it_pos+it_len}
        MIDI.it_end_pos = it_pos + it_len
        local it_tr = reaper.GetMediaItemTrack( item )
        if it_tr ~= it_tr0 then proceed_MIDI = false break end
      end
      
    return proceed_MIDI, MIDI
  end
  -------------------------------------------------------------------------------    
  function ExportSelItemsToRs5k_AddMIDI(track, MIDI, base_pitch, do_not_increment)    
    if not MIDI then return end
      local new_it = reaper.CreateNewMIDIItemInProj( track, MIDI.it_pos, MIDI.it_end_pos )
      local new_tk = reaper.GetActiveTake( new_it )
      for i = 1, #MIDI do
        local startppqpos =  reaper.MIDI_GetPPQPosFromProjTime( new_tk, MIDI[i].pos )
        local endppqpos =  reaper.MIDI_GetPPQPosFromProjTime( new_tk, MIDI[i].end_pos )
        local pitch = base_pitch+i-1
        if do_not_increment then pitch = base_pitch end
        local ret = reaper.MIDI_InsertNote( new_tk, 
            false, --selected, 
            false, --muted, 
            startppqpos, 
            endppqpos, 
            0, 
            pitch, 
            100, 
            true)--noSortInOptional )
          --if ret then reaper.ShowConsoleMsg('done') end
      end
      reaper.MIDI_Sort( new_tk )
      reaper.GetSetMediaItemTakeInfo_String( new_tk, 'P_NAME', 'sliced loop', 1 )
      reaper.UpdateArrange()    
  end
  -------------------------------------------------------------------------------     
  function FloatInstrument(track, toggle)
    local vsti_id = TrackFX_GetInstrument(track)
    if vsti_id and vsti_id >= 0 then 
      if not toggle then 
        TrackFX_Show(track, vsti_id, 3) -- float
       else
        local is_float = TrackFX_GetOpen(track, vsti_id)
        if is_float == false then TrackFX_Show(track, vsti_id, 3) else TrackFX_Show(track, vsti_id, 2) end
      end
      
      return true
    end
  end
  ---------------------------------------------------------------------
    function ApplyFunctionToTrackInTree(track, func) -- function return true stop search
      -- search tree
        local parent_track, ret2, ret3
        local track2 = track
        repeat
          parent_track = reaper.GetParentTrack(track2)
          if parent_track ~= nil then
            ret2 = func(parent_track )
            if ret2 then return end
            track2 = parent_track
          end
        until parent_track == nil    
        
      -- search sends
        local cnt_sends = GetTrackNumSends( track, 0)
        for sendidx = 1,  cnt_sends do
          dest_tr = BR_GetMediaTrackSendInfo_Track( track, 0, sendidx-1, 1 )
          ret3 = func(dest_tr )
          if ret3 then return  end
        end
    end
    ----------------------------------------------------------------------- 
    function GetInput( conf, captions_csv, retvals_csv,floor, linew, is_string)
      if linew and tonumber(linew) then captions_csv = captions_csv..',extrawidth='..math.floor(linew) end
      local ret, str =  GetUserInputs( conf.scr_title, 1, captions_csv, retvals_csv )
      if not ret then return end
      
      if not is_string then 
        if not tonumber(str) then return end
        local out = tonumber(str)
        if floor then out = math.floor(out) end
        return out
       else
        return str
      end
      
    end
    -----------------------------------------------------------
    function BinaryCheck(value, byte_id, bool_int)
      local byte_num = 1<<byte_id
      
      if value&byte_num == byte_num then 
        if not bool_int or (bool_int and bool_int == 1) then value = value - byte_num end
       else 
        if not bool_int or (bool_int and bool_int == 0) then value = value + byte_num end
      end
      return value
    end  
    -----------------------------------------------------------
    function BinaryToggle(value, byte_id, bool_int)
      local byte_num = 1<<byte_id
      
      if value&byte_num == byte_num then 
        if not bool_int or (bool_int and bool_int == 0) then value = value - byte_num end
       else 
        if not bool_int or (bool_int and bool_int == 1) then value = value + byte_num end
      end
      return value
    end  
    -----------------------------------------------------------
    function gfx_ColHex(hex_str) -- https://gist.github.com/jasonbradley/4357406
        local hex = hex_str:gsub("#","")
        local r,g,b = tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
        if GetOS():match('Win') then gfx.set(r/255,g/255,b/255) else gfx.set(b/255,g/255,r/255)     end        
    end
  -----------------------------------------------------------------------
  function SetFXName(track, fx, new_name)
    if not new_name then return end
    local edited_line,edited_line_id, segm
    -- get ref guid
      if not track or not tonumber(fx) then return end
      local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
      if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
      local plug_type = reaper.TrackFX_GetIOSize( track, fx )
    -- get chunk t
      local chunk = eugen27771_GetObjStateChunk( track)
      local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
    -- find edit line
      local search
      for i = #t, 1, -1 do
        local t_check = t[i]:gsub('-','')
        if t_check:find(FX_GUID) then search = true  end
        if t[i]:find('<') and search and not t[i]:find('JS_SER') then
          edited_line = t[i]:sub(2)
          edited_line_id = i
          break
        end
      end
    -- parse line
      if not edited_line then return end
      local t1 = {}
      for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
      local t2 = {}
      for i = 1, #t1 do
        segm = t1[i]
        if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
        if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
      end
  
      if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
      if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST
  
      local out_line = table.concat(t2,' ')
      t[edited_line_id] = '<'..out_line
      local out_chunk = table.concat(t,'\n')
      --msg(out_chunk)
      reaper.SetTrackStateChunk( track, out_chunk, false )
  end 
  ----------------------------------------------------------------------
  function HasWindXYWHChanged(obj)  
    local  dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if not obj.last_gfxx 
        or not obj.last_gfxy 
        or not obj.last_gfxw 
        or not obj.last_gfxh 
        or not obj.last_dock then 
        obj.last_gfxx, obj.last_gfxy, obj.last_gfxw, obj.last_gfxh, obj.last_dock = wx,wy,ww,wh, dock
        return -1 
    end
    if wx ~= obj.last_gfxx or wy ~= obj.last_gfxy then retval= 2 end --- minor
    if ww ~= obj.last_gfxw or wh ~= obj.last_gfxh or dock ~= obj.last_dock then retval= 1 end --- major
    obj.last_gfxx, obj.last_gfxy, obj.last_gfxw, obj.last_gfxh, obj.last_dock = wx,wy,ww,wh,dock
    return retval
  end
  ---------------------------------------------------
  function Menu(mouse, t)
    local str, check ,hidden= '', '',''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      if t[i].hidden then hidden = '#' else hidden ='' end
      local add_str = hidden..check..t[i].str 
      str = str..add_str
      str = str..'|'
    end
    gfx.x = mouse.x
    gfx.y = mouse.y
    local ret = gfx.showmenu(str)
    local incr = 0
    if ret > 0 then 
      for i = 1, ret do 
        if t[i+incr].menu_decr == true then incr = incr - 1 end
        if t[i+incr].str:match('>') then incr = incr + 1 end
        if t[i+incr].menu_inc then incr = incr + 1 end
      end
      if t[ret+incr] and t[ret+incr].func then t[ret+incr].func() end 
     --- msg(t[ret+incr].str)
    end
  end  
  ---------------------------------------------------
  function VF_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
  end
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end
  ------------------------------------------------------------------------------------------------------
  function VF_GetItemTakeUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local item , take = reaper.GetItemFromPoint( screen_x, screen_y, true )
    return item , take
  end
  ------------------------------------------------------------------------------------------------------
  function VF_GetPositionUnderMouseCursor()
    BR_GetMouseCursorContext()
    return  BR_GetMouseCursorContext_Position()
  end
  ------------------------------------------------------------------------------------------------------
  function VF_GetEnvelopeUnderMouseCursor()
    reaper.BR_GetMouseCursorContext()
    return  BR_GetMouseCursorContext_Envelope()
  end  
  ------------------------------------------------------------------------------------------------------
  function VF_SetTimeShiftPitchChange(item, get_only, pshift_mode0, timestr_mode0, stretchfadesz)
    -- 13.07.2021 - mod all takes
    if not item then return end
    local retval, str = reaper.GetItemStateChunk( item, '', false ) 
    
    -- get first take table of values
    local playratechunk = str:match('(PLAYRATE .-\n)') 
    local t = {} for val in playratechunk:gmatch('[^%s]+') do if  tonumber(val ) then  t[#t+1] = tonumber(val )end end
    if get_only==true then return t end 
     
    if pshift_mode0 and not timestr_mode0 and not stretchfadesz then 
      for takeidx = 1,  CountTakes( item ) do
        local take =  GetTake( item, takeidx-1 )
        if ValidatePtr2( 0, take, 'MediaItem_Take*' ) then SetMediaItemTakeInfo_Value( take, 'I_PITCHMODE',pshift_mode0  ) end
      end
      return
    end
    
    -- mod all takes
    local str_mod = str
    for playratechunk in str:gmatch('(PLAYRATE .-\n)') do
      local t = {} for val in playratechunk:gmatch('[^%s]+') do if  tonumber(val ) then  t[#t+1] = tonumber(val )end end
      if pshift_mode0 then t[4]=pshift_mode0 end      
      if timestr_mode0 then t[5]=timestr_mode0 end
      if stretchfadesz then t[6]=stretchfadesz end
      local playratechunk_out = 'PLAYRATE '..table.concat(t, ' ')..'\n'
      str_mod =str_mod:gsub(playratechunk:gsub("[%.%+%-]", function(c) return "%" .. c end), playratechunk_out)
      str_mod = str_mod:gsub('PLAYRATE .-\n', playratechunk_out)
    end
    --msg(str_mod)
    reaper.SetItemStateChunk( item, str_mod, false )
  end
  ------------------------------------------------------------------------------------------------------
  function VF_GetActionCommandIDByFilename(searchfilename) -- https://forum.cockos.com/showpost.php?p=2383082&postcount=6
    local t = {}
    local content 
    local f = io.open(reaper.GetResourcePath().."/reaper-kb.ini",'r')
    if f then content = f:read('a') f:close() end
    for k in content:gmatch('[^\r\n]+') do
      if k:sub(1,3)=="SCR" then 
        local section, aid, desc, filename=k:match("SCR .- (.-) (.-) (\".-\") (.*)")
        t[#t+1] = {section=section, aid=aid, desc=desc, filename=filename}
      end
    end 
    for i = 1, #t do if t[i].filename:match(searchfilename) then return t[i].aid end end 
  end
  
  
  ------------------------------------------------------------------------------------------------------
  function VF_MenuReturnAction(MOUSE,OBJ,DATA,str_name, func0)
    return   { str = str_name,
                func = func0,
              }
  end  
  ------------------------------------------------------------------------------------------------------
  function VF_MenuReturnToggle(MOUSE,OBJ,DATA,str_name, t, value, statecheck)
    local state
    local str=''
    if t[value] then
      str=str_name
      state = t[value]&statecheck==statecheck
     else 
      str=str_name..' [undefined]'
      state = false
    end
    return {  str=str,
              state = state,
              func = function()
                        if not t[value] then return end
                        if t[value]&statecheck==statecheck then
                          t[value] = t[value] - statecheck
                         else
                          t[value] = t[value]|statecheck
                        end
                      end
              }
  end
  ------------------------------------------------------------------------------------------------------
  function VF_MenuReturnUserInput(MOUSE,OBJ,DATA, str_name, captions_csv, t, value, allowemptyresponse)
    local str = ''
    if t[value] then
      str=str_name..': '..t[value]
     else
      str=str_name..': [undefined]'
    end
    return {  str=str,
              func = function()
                        if not t[value] then return end
                        local retval, retvals_csv = reaper.GetUserInputs( str_name, 1, captions_csv, t[value] )
                        if retval  then 
                          if retvals_csv ~= '' or (retvals_csv == '' and allowemptyresponse) then
                            t[value] = tonumber(retvals_csv) or retvals_csv 
                          end
                        end
                      end
              }
  end
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_Load(conf, preset)
    -- call non - preset params
    local def = ExtState_Def()
    for key in spairs(def) do 
      --if not key:match('P[%d]+_.*') then
        local es_str = GetExtState(def.ES_key, key)
        if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
      --end
    end  
    
    for i= 0, 100 do
      local key = 'PRESET'..i
      local es_str = GetExtState(def.ES_key, key)
      if es_str ~= '' then conf[key] = es_str end      
    end
    
    -- port defaults to preset0
      local PRESET_str64 = GetExtState(def.ES_key, 'PRESET0')
      if not PRESET_str64 or PRESET_str64 =='' then VF_ExtState_Save(conf, 0)  end
    
    -- load preset: parse 
      if not preset then return end 
      local preset_t = {}
      local PRESET_str64 = GetExtState(def.ES_key, 'PRESET'..preset)
      if PRESET_str64 and PRESET_str64 ~= '' then
        local PRESET_str = VF_decBase64(PRESET_str64)
        for line in PRESET_str:gmatch('[^\r\n]+') do
          local key,value = line:match('(.-)=(.*)') 
          if key and value and key~='' and value ~='' then preset_t[key] = tonumber(value) or value end
        end 
      end
      
    -- load preset: call preset data based on inital params
      for key in spairs(def) do  
        if key:match('P_.*') then
          local pres_val = preset_t[key]
          if not pres_val then conf[key] = def[key] else conf[key] = pres_val end
        end    
      end
    
  end 
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_LoadProj(conf,extname )
    if not extname then return end
    for idx = 1, 10000 do
      local retval, key, val = reaper.EnumProjExtState( 0, extname, idx-1 )
      if not retval then break end
      conf[key] = tonumber(val) or val
    end  
  end 
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_Save(conf, preset) 
    for key in spairs(conf) do SetExtState(conf.ES_key, key, conf[key], true) end
    
    if not preset then return end
    
    local str = ''
    for key in spairs(conf) do 
      if key:match('P_(.*)') then str = str..'\n'..key:gsub('P_','')..'='..conf[key] end
    end
    SetExtState(conf.ES_key, 'PRESET'..preset, VF_encBase64(str), true)
  end
  ------------------------------------------------------------------------------------------------------
  --[[function VF_ExtState_LoadPreset(conf,preset) 
    local def = ExtState_Def()
    local PRESET_str64 = GetExtState(def.ES_key, 'PRESET'..preset)
    local PRESET_str = VF_decBase64(PRESET_str64)
    for line in PRESET_str:gmatch('[^\r\n]+') do
      local key,value = lime:match('(.-)=(.-)')
      if key and value and key~='' and value ~='' then conf[key] = tonumber(value) or value end
    end
  end]]
  ------------------------------------------------------------------------------------------------------
  --[[function VF_ExtState_SavePreset(conf,preset) 
    local str = ''
    for key in spairs(conf) do 
      if key:match('P_(.*)') then str = key..'='..conf[key]..'\n' end
    end
    SetExtState(conf.ES_key, 'PRESET'..preset, VF_encBase64(str), true)
  end]]
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_SaveProj(conf,extname) for key in spairs(conf) do SetProjExtState( 0, extname, key, conf[key] ) end end
  ------------------------------------------------------------------------------------------------------   
  function VF_Open_URL(url) if GetOS():match("OSX") then os.execute('open "" '.. url) else os.execute('start "" '.. url)  end  end    
  ------------------------------------------------------------------------------------------------------
  function VF_Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
  ------------------------------------------------------------------------------------------------------
  function VF_math_Qdec(num, pow) if not pow then pow = 3 end return math.floor(num * 10^pow) / 10^pow end
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ------------------------------------------------------------------------------------------------------
  -- encoding
  function VF_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end
  ------------------------------------------------------------------------------------------------------
  function VF_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
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
  ------------------------------------------------------------------------------------------------------  
  function VF_GetMediaTrackByGUID(optional_proj, GUID)
    local optional_proj0 = optional_proj or 0
    for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
    local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
  end  
  ---------------------------------------------------------------------
  function VF_FormatToNormValue(val, min, max)
    return (val - min) /  (max-min) 
  end
  ---------------------------------------------------------------------
  function VF_NormToFormatValue(val, min, max, quantize)
    local pow = 10^(quantize or 1) 
    if quantize ~= -1 then
      return math.floor((val * (max-min) + min) * pow) / pow
     else
      return math.floor(val * (max-min) + min)
    end
  end
  ----------------------------------------------------------------------
  function VF_GetItemGUID(item) 
    local retval, str = reaper.GetItemStateChunk( item, '', false )
    local GUID = str:match('\nIGUID%s(%{.-%})')
    return GUID
  end  
  ----------------------------------------------------------------------
  function VF_GetTakeGUID(take)
    local item =  GetMediaItemTake_Item( take )
    local retval, str = reaper.GetItemStateChunk( item, '', false )
    local GUID = str:match('\nGUID%s(%{.-%})')
    return GUID
  end
  ---------------------------------------------------------------------------------------------------------------------
  function VF_ConvertNoteOnVel0toNoteOff(take)
    local tableEvents = {}
    local s_unpack = string.unpack
    local s_pack = string.pack
    local t = 0
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local offset, flags, msg1
    while stringPos < MIDIlen-12 do
      offset, flags, msg1, stringPos = s_unpack("i4Bs4", MIDIstring, stringPos)
      t = t + 1
      if msg1:len()==3 then
        local msgb1 = msg1:byte(1)
        if msgb1&0xF0 == 0x90 and msg1:byte(3) == 0 then msgb1 =  0x80|(msg1:byte(1)&0xF) end
        
        tableEvents[t] = string.pack("i4Bi4BBB", offset, flags, 3, msgb1, msg1:byte(2), msg1:byte(3) )
        --tableEvents[t] = s_pack("i4Bs4", offset, flags, msgb1 + (msg1:byte(2)<<1) + (msg1:byte(3)>>2) )
       else
        tableEvents[t] = s_pack("i4Bs4", offset, flags, msg1)
      end
    end 
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take)   
    return true
  end
  ------------------------------------------------------------------------------------------------------
  function VF_getKeysSortedByValue(tbl, sortFunction, param) -- https://stackoverflow.com/questions/2038418/associatively-sorting-a-table-by-value-in-lua
    local keys = {}
    for key in pairs(tbl) do table.insert(keys, key) end  
    table.sort(keys, function(a, b) return sortFunction(tbl[a][param], tbl[b][param])  end)  
    return keys
  end 
  ---------------------------------------------------
  function VF_CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end 
  ---------------------------------------------------------------------
  function VF_GetMediaItemByGUID(optional_proj, itemGUID)
    local optional_proj0 = optional_proj or 0
    local itemCount = CountMediaItems(optional_proj);
    for i = 1, itemCount do
      local item = GetMediaItem(0, i-1);
      local retval, stringNeedBig = GetSetMediaItemInfo_String(item, "GUID", '', false)
      if stringNeedBig  == itemGUID then return item end
    end
  end  
  ------------------------------------------------------------------------------------------------------  
  function VF_AnalyzeItemLoudness(item) -- https://forum.cockos.com/showpost.php?p=2050961&postcount=6
    if not item then return end
    
    -- get channel count
    local take = GetActiveTake(item)
    local source = GetMediaItemTake_Source(take)
    local channelsInSource =  GetMediaSourceNumChannels(source)
    
    local windowSize = 0
    local reaperarray_peaks         = reaper.new_array(channelsInSource)
    local reaperarray_peakpositions = reaper.new_array(channelsInSource)
    local reaperarray_RMSs          = reaper.new_array(channelsInSource)
    local reaperarray_RMSpositions  = reaper.new_array(channelsInSource)
    
    -- REAPER sets initial (used) size to maximum size when creating reaper.array
    -- so we resize (set used size to 0) to make space for writing the values
    reaperarray_peaks.resize(0)
    reaperarray_peakpositions.resize(0)
    reaperarray_RMSs.resize(0)
    reaperarray_RMSpositions.resize(0)
    
    -- analyze
    local success = reaper.NF_AnalyzeMediaItemPeakAndRMS(item, windowSize, reaperarray_peaks, reaperarray_peakpositions, reaperarray_RMSs, reaperarray_RMSpositions)
    
    if success == true then
      -- convert reaper.arrays to Lua tables
      local peaksTable = reaperarray_peaks.table()
      local RMSsTable = reaperarray_RMSs.table()
      
      local peaks_com = 0
      local RMS_com = 0
      -- print results
      for i = 1, channelsInSource do
        peaks_com = peaks_com + peaksTable[i]
        RMS_com = RMS_com + RMSsTable[i]
      end
      
      peaks_com = peaks_com / channelsInSource
      RMS_com = RMS_com / channelsInSource
      
      return WDL_DB2VAL(peaks_com), WDL_DB2VAL(RMS_com)
      
    end
  end
  ------------------------------------------------------------------------------------------------------
  function VF_deliteralize(str) 
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", '') end
  end 
  
    ---------------------------------------------------
    function VF2_Action(s,section,midieditor,flag,proj) 
      if not flag then flag = 0 end 
      if not proj then proj = 0 end 
      if not section then 
        Main_OnCommandEx(NamedCommandLookup(s), flag, proj) 
       elseif section == 32060 and midieditor then -- midi ed
        MIDIEditor_OnCommand( midieditor, NamedCommandLookup(s) )
      end
    end
    
    ---------------------------------------------------
    function VF2_GetSetFXChunk(track, fx, strreplace) -- from BYPASS to WAK -- 15.05.2021
      local retval, trchunk = reaper.GetTrackStateChunk( track, '', false ) 
      local GUID = reaper.TrackFX_GetFXGUID( track, fx )
      local FXchunk_find
      for fxchunk in trchunk:gmatch('(BYPASS.-WAK %d)') do
        local fxGUID = fxchunk:match('FXID (.-)\n')
        if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end 
        if fxGUID:match(literalize(GUID):gsub('%s', '')) then  
          FXchunk_find = literalize(fxchunk)
          return fxchunk
        end
      end
      if not FXchunk_find then return end
      if strreplace then trchunk = trchunk:gsub(FXchunk_find, strreplace) reaper.SetTrackStateChunk( track, trchunk, false )end
      return FXchunk
    end 
  -------------------------------------------------------------------
    function VF2_GetMEZoom(take)
      local Hzoom
      if not take then return end
      local item =  GetMediaItemTake_Item( take )
      if not item then return end
      local _, chunk = reaper.GetItemStateChunk( item, "", false )
      
      local active_take
      for line in chunk:gmatch('[^\r\n]+') do
        if line:match('GUID (.*)') then 
           local testGUID = line:match('GUID (%{.*%})')--:gsub('[%{%}]','')
           local testtake = GetMediaItemTakeByGUID( 0, testGUID )
          if testtake and testtake == take then active_take = true end 
        end
        if active_take and line:match('CFGEDITVIEW') then 
          Hzoom = line:match('CFGEDITVIEW [%-%.%d]+ ([%-%.%d]+)')
          Hzoom=tonumber(Hzoom)
          if Hzoom then return true, Hzoom end
        end
      end
    end 
    ---------------------------------------------------------------------------------------------------------------------
    function VF2_NormalizeT(t, key)
      local m = 0 
      for i in pairs(t) do 
        if not key then 
          m = math.max(math.abs(t[i]),m) 
         else
          m = math.max(math.abs(t[i][key]),m) 
        end
      end
      for i in pairs(t) do 
        if not key then
          t[i] = t[i] / m 
         else 
          t[i][key] = t[i][key] / m 
        end
      end
    end 
    ---------------------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------------
    function VF2_ShiftRegions(offset) 
      local regions={}
      local retval, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
      local rgn_idx = 0
      for idx = 1, num_markers + num_regions do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, idx-1 )
        if isrgn == true then rgn_idx = rgn_idx + 1 end 
        regions[idx] = {isrgn=isrgn,
                              pos = pos,
                              rgnend=rgnend,
                              rgnlen=rgnlen,
                              name=name,
                              markrgnindexnumber=markrgnindexnumber,
                              color=color,
                              rgn_idx=rgn_idx,
                              show = true}
      end
      -- remove all
        for idx = num_markers + num_regions, 1, -1 do reaper.DeleteProjectMarkerByIndex( 0, idx-1 ) end 
      -- add back
        for i = 1, #regions do AddProjectMarker2( 0, regions[i].isrgn, regions[i].pos+offset, regions[i].rgnend+offset, regions[i].name, regions[i].markrgnindexnumber,regions[i]. color ) end
      return true
    end
    ---------------------------------------------------------------------------------------------------------------------
    function VF2_ConvertNoteOnVel0toNoteOff(take)
      local tableEvents = {}
      local s_unpack = string.unpack
      local s_pack = string.pack
      local t = 0
      local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
      local MIDIlen = MIDIstring:len()
      local stringPos = 1
      local offset, flags, msg1
      while stringPos < MIDIlen-12 do
        offset, flags, msg1, stringPos = s_unpack("i4Bs4", MIDIstring, stringPos)
        t = t + 1
        if msg1:len()==3 then
          local msgb1 = msg1:byte(1)
          if msgb1&0xF0 == 0x90 and msg1:byte(3) == 0 then msgb1 =  0x80|(msg1:byte(1)&0xF) end
          
          tableEvents[t] = string.pack("i4Bi4BBB", offset, flags, 3, msgb1, msg1:byte(2), msg1:byte(3) )
          --tableEvents[t] = s_pack("i4Bs4", offset, flags, msgb1 + (msg1:byte(2)<<1) + (msg1:byte(3)>>2) )
         else
          tableEvents[t] = s_pack("i4Bs4", offset, flags, msg1)
        end
      end 
      MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
      MIDI_Sort(take)   
      return true
    end
    --------------------------------------------------------------------
    function VF2_EnumeratePlugins(plugs_t)
      local res_path = GetResourcePath()
      VF2_EnumeratePlugins_Sub(plugs_t, res_path..'/reaper-vstplugins.ini', '%=.-%,.-%,(.*)', 0)
      VF2_EnumeratePlugins_Sub(plugs_t, res_path..'/reaper-vstplugins64.ini', '%=.-%,.-%,(.*)', 0)
      VF2_EnumeratePlugins_Sub(plugs_t, res_path..'/reaper-dxplugins.ini',  'Name=(.*)', 2)  
      VF2_EnumeratePlugins_Sub(plugs_t, res_path..'/reaper-dxplugins64.ini',  'Name=(.*)', 2) 
      VF2_EnumeratePlugins_Sub(plugs_t, res_path..'/reaper-auplugins.ini',  'AU%s%"(.-)%"', 3) 
      VF2_EnumeratePlugins_Sub(plugs_t, res_path..'/reaper-auplugins64.ini',  'AU%s%"(.-)%"', 3)  
      VF2_EnumeratePlugins_Sub(plugs_t, res_path..'/reaper-jsfx.ini',  'NAME (.-)%s', 4) 
    end
  --------------------------------------------------------------------
    function VF2_EnumeratePlugins_Sub(plugs_t, fp, pat, plugtype)
      -- validate file
        local f = io.open(fp, 'r')
        local content
        if f then  content = f:read('a') f:close() else return  end
        if not content then return end
        
      -- create if not exist
        if not plugs_t then plugs_t = {} end
        
      -- parse
        for line in content:gmatch('[^\r\n]+') do
          local str = line:match(pat)
          if plugtype == 4 and line:match('NAME "') then
            str = line:match('NAME "(.-)"') 
            --str = str:gsub('.jsfx','')
          end
          if str then 
            if str:match('!!!VSTi') and plugtype == 0 then plugtype = 1 end
            str = str:gsub('!!!VSTi','')
            
            -- reduced_name
              local reduced_name = str
              if plugtype == 3 then  if reduced_name:match('%:.*') then reduced_name = reduced_name:match('%:(.*)') end    end
              if plugtype == 4 then  
              
                --reduced_name = reduced_name:sub(5)
                local pat_js = '.*[%/](.*)'
                if reduced_name:match(pat_js) then reduced_name = reduced_name:match(pat_js) end    
              end
            plugs_t[#plugs_t+1] = {name = str, 
                                   reduced_name = reduced_name ,
                                   plugtype = plugtype}
          end
        end
    end  
    --------------------------------------------------------------------
    function VF2_CollectFXData() 
      --if not pluginsdata then return end
      local pluginsdata = {} -- reset
      for i = 1, CountTracks(0)  do
        local tr = GetTrack(0,i-1)
        local fxcnt = TrackFX_GetCount( tr )
        for fx=1, fxcnt do
          local retval, buf = reaper.TrackFX_GetFXName( tr, fx-1, '' )
          if not pluginsdata[buf] then pluginsdata[buf] = {} end 
          local GUID =  TrackFX_GetFXGUID( tr, fx-1 )
          pluginsdata[buf][#pluginsdata[buf]+1] =   {tr_ptr=tr,
                                  name=buf,
                                  pos=fx-1,
                                  GUID = GUID }
  
        end
      end
      return pluginsdata
    end
    ---------------------------------------------------------------------
    function VF2_GetLTP()
      local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
      local tr, trGUID, fxGUID, param, paramname, ret, fxname,paramformat
      if retval then 
        tr = CSurf_TrackFromID( tracknumber, false )
        trGUID = GetTrackGUID( tr )
        fxGUID = TrackFX_GetFXGUID( tr, fxnumber )
        retval, buf = reaper.GetTrackName( tr )
        ret, paramname = TrackFX_GetParamName( tr, fxnumber, paramnumber, '')
        ret, fxname = TrackFX_GetFXName( tr, fxnumber, '' )
        paramval = TrackFX_GetParam( tr, fxnumber, paramnumber )
        retval, paramformat = TrackFX_GetFormattedParamValue(  tr, fxnumber, paramnumber, '' )
       else 
        return
      end
      return {tr = tr,
              trtracknumber=tracknumber,
              trGUID = trGUID,
              fxGUID = fxGUID,
              trname = buf,
              paramnumber=paramnumber,
              paramname=paramname,
              paramformat = paramformat,
              paramval=paramval,
              fxnumber=fxnumber,
              fxname=fxname
              }
    end
    ---------------------------------------------------
    function VF2_ValidateFX(trGUID,fxGUID)
      if not (trGUID and fxGUID) then return end
      local tr = VF_GetTrackByGUID(trGUID)
      if not tr then return end 
      local ret, tr, fxnumber = VF_GetFXByGUID(fxGUID, tr) 
      if not ret then return end 
      return fxnumber
    end
    ---------------------------------------------------
    function VF2_CycleGrid(stages)
      local _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
      stateid = reaper.GetExtState( 'mpl_cycle_grid', 'val' )
      stateid = tonumber(stateid) or 1
      if mouse_scroll == -1 then return end
      if mouse_scroll > 0 then 
        stateid = stateid + 1
       elseif mouse_scroll < 0 then 
        stateid = stateid - 1
      end
      local outval = math.min(#stages, math.max(stateid, 1))
      reaper.SetExtState( 'mpl_cycle_grid', 'val' , outval, true)
      if stages[outval] ~= 0 then
        reaper.Main_OnCommand(40754,0)      --Snapping: Enable snap
        reaper.SetProjectGrid( 0, stages[outval] )
       else
        reaper.Main_OnCommand(40753,0) -- Snapping: Disable snap
      end
    end
    ---------------------------------------------------
    function VF2_CycleGridME(stages)
      local ME =  reaper.MIDIEditor_GetActive()
      if not ME then return end
      local _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
      stateid = reaper.GetExtState( 'mpl_cycle_grid', 'val' )
      stateid = tonumber(stateid) or 1
      if mouse_scroll == -1 then return end
      if mouse_scroll > 0 then 
        stateid = stateid + 1
       elseif mouse_scroll < 0 then 
        stateid = stateid - 1
      end
      local outval = math.min(#stages, math.max(stateid, 1))
      reaper.SetExtState( 'mpl_cycle_grid', 'val' , outval, true)
      if stages[outval] ~= 0 then
        reaper.MIDIEditor_SetSetting_int( ME, 'snap_enabled',1 )      --Snapping: Enable snap
        reaper.SetMIDIEditorGrid( 0, stages[outval]  )
       else
        reaper.MIDIEditor_SetSetting_int( ME, 'snap_enabled',0 )
      end
    end
      
  
    ----------------------------------------------------------------------
    function VF2_GetTrackSendOrderIDbyname(src_tr, namepattern)
      local max_id = 0
      for sid = 1, GetTrackNumSends( src_tr, 0 ) do
        local dest_tr = GetTrackSendInfo_Value( src_tr, 0, sid-1, 'P_DESTTRACK' )
        if dest_tr then
          local retval, buf = GetTrackName( dest_tr )
          if buf:match(namepattern) then
            local id = tonumber(buf:match(namepattern))
            if id then 
              max_id = math.max(max_id, id)
            end
          end
        end
      end
      return max_id
    end
    ----------------------------------------------------------------------
    function VF2_IsTrackSendExists(src_tr, dest_tr0)
      for sid = 1, GetTrackNumSends( src_tr, 0 ) do
        local dest_tr = GetTrackSendInfo_Value( src_tr, 0, sid-1, 'P_DESTTRACK' )
        if GetTrackGUID( dest_tr ) == GetTrackGUID( dest_tr0 ) then return true end
      end
    end
    ----------------------------------------------------------------------
    function VF2_CreateFXTrack(tr, seltr_ptrs, firsttrackid) -- seltr_ptrs for multiple tracks, see mpl_Create send from selected tracks (custom)
      
      local folder_bus
      if not tr then return end 
      
      -- add track, handle folder structure
        local tracknumberOut =  CSurf_TrackToID( tr, false ) 
        InsertTrackAtIndex( tracknumberOut, true ) 
        local prev_tr = CSurf_TrackFromID( tracknumberOut, false )
        local fdepth = GetMediaTrackInfo_Value( prev_tr, 'I_FOLDERDEPTH' ) 
        local new_tr = CSurf_TrackFromID( tracknumberOut+1, false )
        if fdepth <= 0 then
          SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH', fdepth )
          SetMediaTrackInfo_Value( prev_tr, 'I_FOLDERDEPTH', 0 )
         else
          folder_bus = true
          SetOnlyTrackSelected( new_tr )
          ReorderSelectedTracks( tracknumberOut-1, 0 )
          SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH', 0 )
        end
      -- name
        local pat = 'Fx%s(%d+)'
        local name = 'Fx '
        if folder_bus then 
          pat = 'Bus%sFX%s(%d+)' 
          name = 'Bus FX ' 
        end
        local max_id = VF2_GetTrackSendOrderIDbyname(prev_tr, pat)
        GetSetMediaTrackInfo_String( new_tr, 'P_NAME', name.. max_id+1, 1 )
        if not seltr_ptrs then 
          local ret = VF2_IsTrackSendExists(tr, new_tr)
          if not ret then CreateTrackSend( tr, new_tr )  end
         else
          for i = 1, #seltr_ptrs do
            local ret = VF2_IsTrackSendExists( seltr_ptrs[i], new_tr)
            if not ret then CreateTrackSend( seltr_ptrs[i], new_tr )  end
          end
        end
      -- color
        SetTrackColor( new_tr, tonumber('0x8d46cc') )  
      -- selection
        SetOnlyTrackSelected( new_tr )
      -- icon
        GetSetMediaTrackInfo_String( new_tr, 'P_ICON', 'fx.png', 1 )
      -- level down
        SetMediaTrackInfo_Value( new_tr, 'D_VOL',0 )
      -- TCP MCP layouts
        GetSetMediaTrackInfo_String( new_tr, 'P_TCP_LAYOUT', 'C-DPI-translated to 200% C', 1 )
        GetSetMediaTrackInfo_String( new_tr, 'P_MCP_LAYOUT', 'Track layout 200%_B', 1 )
      -- move folder before dirts track
        if folder_bus and firsttrackid then
          local ID = CSurf_TrackToID(new_tr, false)
          SetOnlyTrackSelected(new_tr)
          ReorderSelectedTracks(firsttrackid, 0)
        end
    end
    ------------------------------------------------------------------------------------------------------
    function VF2_lit(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
       if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
    end  
    
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
     local function exportstring( s ) 
          return string.format("%q", s)
       end
    
       --// The Save Function
       function table.save(  tbl,filename )
          local charS,charE = "   ","\n"
          local file,err = io.open( filename, "wb" )
          if err then return err end
    
          -- initiate variables for save procedure
          local tables,lookup = { tbl },{ [tbl] = 1 }
          file:write( "return {"..charE )
    
          for idx,t in ipairs( tables ) do
             file:write( "-- Table: {"..idx.."}"..charE )
             file:write( "{"..charE )
             local thandled = {}
    
             for i,v in ipairs( t ) do
                thandled[i] = true
                local stype = type( v )
                -- only handle value
                if stype == "table" then
                   if not lookup[v] then
                      table.insert( tables, v )
                      lookup[v] = #tables
                   end
                   file:write( charS.."{"..lookup[v].."},"..charE )
                elseif stype == "string" then
                   file:write(  charS..exportstring( v )..","..charE )
                elseif stype == "number" then
                   file:write(  charS..tostring( v )..","..charE )
                end
             end
    
             for i,v in pairs( t ) do
                -- escape handled values
                if (not thandled[i]) then
                
                   local str = ""
                   local stype = type( i )
                   -- handle index
                   if stype == "table" then
                      if not lookup[i] then
                         table.insert( tables,i )
                         lookup[i] = #tables
                      end
                      str = charS.."[{"..lookup[i].."}]="
                   elseif stype == "string" then
                      str = charS.."["..exportstring( i ).."]="
                   elseif stype == "number" then
                      str = charS.."["..tostring( i ).."]="
                   end
                
                   if str ~= "" then
                      stype = type( v )
                      -- handle value
                      if stype == "table" then
                         if not lookup[v] then
                            table.insert( tables,v )
                            lookup[v] = #tables
                         end
                         file:write( str.."{"..lookup[v].."},"..charE )
                      elseif stype == "string" then
                         file:write( str..exportstring( v )..","..charE )
                      elseif stype == "number" then
                         file:write( str..tostring( v )..","..charE )
                      end
                   end
                end
             end
             file:write( "},"..charE )
          end
          file:write( "}" )
          file:close()
       end
       
       --// The Load Function
       function table.load( sfile )
          local ftables,err = loadfile( sfile )
          if err then return _,err end
          local tables = ftables()
          for idx = 1,#tables do
             local tolinki = {}
             for i,v in pairs( tables[idx] ) do
                if type( v ) == "table" then
                   tables[idx][i] = tables[v[1]]
                end
                if type( i ) == "table" and tables[i[1]] then
                   table.insert( tolinki,{ i,tables[i[1]] } )
                end
             end
             -- link indices
             for _,v in ipairs( tolinki ) do
                tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
             end
          end
          return tables[1]
       end
       
       
function VF_spk77_getinivalue(ini_file_name, section, key) -- https://forum.cockos.com/showpost.php?p=1535873&postcount=8
  -- String functions from Haywoods DROPP Script..
  local function VF_spk77_get_ini_value_startswith(text,prefix) return string.sub(text, 1, string.len(prefix)) == prefix end
  local function VF_spk77_get_ini_value_split(s, sep) return s:match("([^" .. sep .. "]+)[" .. sep .. "]+(.+)") end
  local function VF_spk77_get_ini_value_trim(s) return s:match("^%s*(.-)%s*$")end
  
  local section_found = false
  local key_found = false
  local f = io.open(ini_file_name,'rb')
  if not f then return end
  local content = f:read('a')
  f:close()
  
  
  for line in content:gmatch('[^\r\n]+') do
    if not section_found and line:lower() == "[" .. section:lower() .. "]" then    -- Try to find the section
      section_found = true
      goto skipnextline
    end
    
    if section_found and line == "%[.*%]" then break end -- break at next section
    
    
    if section_found then
      if not VF_spk77_get_ini_value_startswith(line, ";") then
        local temp_line = line:match("([^=]+)")
        if temp_line ~= nil and VF_spk77_get_ini_value_trim(temp_line) ~= nil then
          temp_line = VF_spk77_get_ini_value_trim(temp_line)
          if temp_line:lower() == key:lower() then
            key_found = true
            
            -- Key found -> Try to get the value
            local val = ({VF_spk77_get_ini_value_split(line,"=")})[2]
            -- No value set for this key -> return an empty string
            if val == nil then val = "" end
            val = VF_spk77_get_ini_value_trim(val)
            if tonumber(val) then val = tonumber(val) end
            return val
          end
        end
      end
    end
    
    ::skipnextline::
  end
  
  -- Section was not found
  if not section_found then 
    reaper.ShowConsoleMsg("Couldn't find section: " .. section .. "\n")
    return false
  end
  if not key_found then 
    if section_found and not key_found then reaper.ShowConsoleMsg("Couldn't find key: " .. key .. "\n") end
  return false
  end
end
  -----------------------------------------------------
  function VF_TrackFX_SetEmbeddedState(track, fx0, func_perform)
    -- func_perform is like 
      --[[
       func = function(flag1,flag2) 
              local WAKflag1 = flag1
              local WAKflag2 = 2
              return WAKflag1, WAKflag2 
            end
      ]]
            
    --  0-based fx
      if not fx0 then return end
      if not track then return end
      local retval, inchunk = GetTrackStateChunk( track, '', false )
    -- parse FX
      local t,i,brackets = {},0,0
      local wak_ids = {}
      for line in inchunk:gmatch('[^\r\n]+') do
        if line:match('<FXCHAIN') then collect = true end
        if collect == true then 
          local count_brackets_open = #string.gsub(line, "[^<]", "")
          local count_brackets_close = #string.gsub(line, "[^>]", "")
          i = i + 1 
          if line:match('WAK %d') then
            wak_ids[#wak_ids+1] = i
          end
          t[i] = line 
          brackets = brackets + count_brackets_open - count_brackets_close
          if brackets == 0 then break end
        end
      end 
      local fxchunk = table.concat(t,'\n')
    
    -- mod flags
      for fx = 0,  TrackFX_GetCount( track )-1 do 
        if fx0 == -1 or (fx0 ~= -1 and fx0 == fx) then
          local wakID = wak_ids[fx+1] 
          if wakID and t[wakID] then
            local src_line = t[wakID]
            if not src_line:match('WAK [%d%-]+ [%d%-]+') then src_line = src_line..' 0' end -- backward comatibility with old reaper versions
            local flag1, flag2 = src_line:match('WAK ([%d%-]+) ([%d%-]+)')
            flag1 = tonumber(flag1)
            flag2 = tonumber(flag2)
            local flag1out, flag2out = func_perform(flag1,flag2)
            t[wakID] = 'WAK '..flag1out..' '..flag2out
          end 
        end
      end
      
      local fxchunk_mod = table.concat(t,'\n')
    
    -- apply out
      local outchunk = inchunk:gsub(literalize(fxchunk), fxchunk_mod)
      SetTrackStateChunk( track, outchunk, false )
  end
  -----------------------------------------------------
  function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  ------------------------------------------------------- 
  function VF_BFpluginparam(find_Str, tr, fx, param) 
    if not find_Str then return end
    local find_Str_val = find_Str:match('[%d%-%.]+')
    if not (find_Str_val and tonumber(find_Str_val)) then return end
    local find_val =  tonumber(find_Str_val)
    
    local iterations = 300
    local mindiff = 10^-14
    local precision = 10^-7
    local min, max = 0,1
    for i = 1, iterations do -- iterations
      local param_low = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min) 
      local param_mid = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min + (max-min)/2) 
      local param_high = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, max)  
      if find_val <= param_low then return min  end
      if find_val == param_mid and math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      if find_val >= param_high then return max end
      if find_val > param_low and find_val < param_mid then 
        min = min 
        max = min + (max-min)/2 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
       else
        min = min + (max-min)/2 
        max = max 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      end
    end
    
    
    --[[
    local BF_s, BF_e,closer_out_val = 0, 1
    local TS = os.clock()
    for step_pow = -1, pow, -1 do
      local last_param_n
      for val = BF_s, BF_e, 10^step_pow do 
        if os.clock() - TS > 5 then MB('Brutforce timeout.\nOperation cancelled.', scr_nm, 0) return end 
        local param_n = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, val)
        if param_n and not last_param_n and find <= param_n  then return val end
        if last_param_n and find > last_param_n and find <= param_n then 
          BF_s = val - 10^step_pow
          BF_e = val
          closer_out_val = val
          break
        end
        last_param_n = param_n
      end
      if not closer_out_val then return 1 end
    end
    return closer_out_val
    ]]
    
    
  end
  -------------------------------------------------------  
  function VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision)
    for value_precise = min, max, precision do
      local param_form = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, value_precise)  
      if find_val == param_form then  return value_precise end
    end
    return min + (max-min)/2 
  end 
  -------------------------------------------------------  
  function VF_BFpluginparam_GetFormattedParamInternal(tr, fx, param, val)
    local param_n
    if val then TrackFX_SetParamNormalized( tr, fx, param, val ) end
    local _, buf = TrackFX_GetFormattedParamValue( tr , fx, param, '' )
    --local param_str = buf:match('%-[%d%.]+') or buf:match('[%d%.]+')
    local param_str = buf:match('[%d%a%-%.]+')
    if param_str then param_n = tonumber(param_str) end
    if not param_n and param_str:lower():match('%-inf') then param_n = - math.huge
    elseif not param_n and param_str:lower():match('inf') then param_n = math.huge end
    return param_n
  end
    ---------------------------------------------------------------------  
  function VF_LIP_load(fileName) -- https://github.com/Dynodzzo/Lua_INI_Parser/blob/master/LIP.lua
    assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
    local file = assert(io.open(fileName, 'r'), 'Error loading file : ' .. fileName);
    local data = {};
    local section;
    for line in file:lines() do
      local tempSection = line:match('^%[([^%[%]]+)%]$');
      if(tempSection)then
        section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
        data[section] = data[section] or {};
      end
      local param, value = line:match('^([%w|_]+)%s-=%s-(.+)$');
      if(param and value ~= nil)then
        if(tonumber(value))then
          value = tonumber(value);
        elseif(value == 'true')then
          value = true;
        elseif(value == 'false')then
          value = false;
        end
        if(tonumber(param))then
          param = tonumber(param);
        end
        if data[section] then 
          data[section][param] = value;
        end
      end
    end
    file:close();
    return data;
  end
  ---------------------------------------------------------------------------------------------------------------------   
    function GetNoteStr(conf, val, mode)  -- conf.key_names
      local oct_shift = -1
      if conf.oct_shift then oct_shift = conf.oct_shift end
      local int_mode
      if mode then int_mode = mode else int_mode = conf.key_names end
      if int_mode == 0 then
        if not val then return end
        local val = math.floor(val)
        local oct = math.floor(val / 12)
        local note = math.fmod(val,  12)
        local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}
        if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end
       elseif int_mode == 1 then
        if not val then return end
        local val = math.floor(val)
        local oct = math.floor(val / 12)
        local note = math.fmod(val,  12)
        local key_names = {'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B',}
        if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end  
       elseif int_mode == 2 then
        if not val then return end
        local val = math.floor(val)
        local oct = math.floor(val / 12)
        local note = math.fmod(val,  12)
        local key_names = {'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si',}
        if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end      
       elseif int_mode == 3 then
        if not val then return end
        local val = math.floor(val)
        local oct = math.floor(val / 12)
        local note = math.fmod(val,  12)
        local key_names = {'Do', 'Re♭', 'Re', 'Mi♭', 'Mi', 'Fa', 'Sol♭', 'Sol', 'La♭', 'La', 'Si♭', 'Si',}
        if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end       
       elseif int_mode == 4 -- midi pitch
        then return val, 'MIDI pitch'
       elseif int_mode == 5 -- freq
        then return math.floor(440 * 2 ^ ( (val - 69) / 12))..'Hz'
       elseif int_mode == 6 -- empty
        then return '', 'Nothing'
       elseif int_mode == 7 then -- ru
        if not val then return end
        local val = math.floor(val)
        local oct = math.floor(val / 12)
        local note = math.fmod(val,  12)
        local key_names = {'До', 'До#', 'Ре', 'Ре#', 'Ми', 'Фа', 'Фа#', 'Соль', 'Соль#', 'Ля', 'Ля#', 'Си'}
        if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift,
                                                          'keys (RU) + octave' end  
       elseif int_mode == 8 then
        if not val then return end
        local val = math.floor(val)
        local oct = math.floor(val / 12)
        local note = math.fmod(val,  12)
        local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}
        if note and oct and key_names[note+1] then 
          return key_names[note+1]..oct+oct_shift..'\n'..val,
                  'keys + octave + MIDI pitch'
        end              
      end
  end
  ---------------------------------------------------------------------------------------------------------------------   
  function VF_GetNoteStr(val, int_mode)  -- conf.key_names
    if int_mode == 0 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct end
     elseif int_mode == 1 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct end  
     elseif int_mode == 2 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct end      
     elseif int_mode == 3 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'Do', 'Re♭', 'Re', 'Mi♭', 'Mi', 'Fa', 'Sol♭', 'Sol', 'La♭', 'La', 'Si♭', 'Si',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct end       
     elseif int_mode == 4 -- midi pitch
      then return val, 'MIDI pitch'
     elseif int_mode == 5 -- freq
      then return math.floor(440 * 2 ^ ( (val - 69) / 12))..'Hz'
     elseif int_mode == 6 -- empty
      then return '', 'Nothing'
     elseif int_mode == 7 then -- ru
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'До', 'До#', 'Ре', 'Ре#', 'Ми', 'Фа', 'Фа#', 'Соль', 'Соль#', 'Ля', 'Ля#', 'Си'}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct,
                                                        'keys (RU) + octave' end  
     elseif int_mode == 8 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}
      if note and oct and key_names[note+1] then 
        return key_names[note+1]..oct..'\n'..val,
                'keys + octave + MIDI pitch'
      end              
    end
  end
  -------------------------------------------------------  
  -- MAPPING for backwards compability --
  Open_URL = VF_Open_URL
  Action = VF_Action
  lim = VF_lim
  math_q_dec = VF_math_Qdec 
  GetShortSmplName = VF_GetShortSmplName  
  MPL_ReduceFXname = VF_ReduceFXname

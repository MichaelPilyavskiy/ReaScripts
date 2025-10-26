-- @description Paste spectral edits to selected items active take
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # obey multiple splits relative positions

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
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
--------------------------------------------------------------------
  function MPL_SpectralEdits_Manipulate(take, data)
    if TakeIsMIDI(take) then return end
    if data and data.clear then -- clear
      local CNT = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:CNT' )
      for x =CNT-1,0,-1 do
        GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:DELETE:'..x ) 
      end
    end
        
    -- read
    local SE = {} 
    local CNT = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:CNT' )
    local FFT_SIZE = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:FFT_SIZE' ) 
    for x =0, CNT-1 do
      local POSITION = GetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..x..':POSITION' )
      local LENGTH = GetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..x..':LENGTH' )
      local GAIN = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GAIN' )
      local FADE_IN = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_IN' )
      local FADE_OUT = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_OUT' )
      local FADE_LOW = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_LOW' )
      local FADE_HI = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':FADE_HI' )
      local CHAN = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':CHAN' )
      local FLAGS = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':FLAGS' )--&1=bypassed, &2=solo
      local GATE_THRESH = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GATE_THRESH' )
      local GATE_FLOOR = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':GATE_FLOOR' )
      local COMP_THRESH = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':COMP_THRESH' )
      local COMP_RATIO = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':COMP_RATIO' )
      local SELECTED = GetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..x..':SELECTED' )
      local TOPFREQ_CNT = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':TOPFREQ_CNT' )
      local TOPFREQ = {}
      for y = 0, TOPFREQ_CNT-1 do
        local TOPFREQ_POS = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':TOPFREQ_POS:'..y )
        local TOPFREQ_FREQ = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':TOPFREQ_FREQ:'..y )
        TOPFREQ[y+1] = {
          TOPFREQ_POS = TOPFREQ_POS,
          TOPFREQ_FREQ = TOPFREQ_FREQ,
        }
      end
      local BOTFREQ_CNT = GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..x..':BOTFREQ_CNT' )
      local BOTFREQ = {}
      for y = 0, BOTFREQ_CNT-1 do
        local BOTFREQ_POS = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':BOTFREQ_POS:'..y )
        local BOTFREQ_FREQ = GetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..x..':BOTFREQ_FREQ:'..y )
        BOTFREQ[y+1] = {
          BOTFREQ_POS = BOTFREQ_POS,
          BOTFREQ_FREQ = BOTFREQ_FREQ,
        }
      end 
      SE[x+1] = {
        FFT_SIZE=FFT_SIZE,
        CHAN=CHAN,
        FLAGS=FLAGS,
        SELECTED=SELECTED, 
        POSITION=POSITION,
        LENGTH=LENGTH, 
        GAIN=GAIN, 
        FADE_IN=FADE_IN,
        FADE_OUT=FADE_OUT,
        FADE_LOW=FADE_LOW,
        FADE_HI=FADE_HI, 
        GATE_THRESH=GATE_THRESH,
        GATE_FLOOR=GATE_FLOOR,
        COMP_THRESH=COMP_THRESH,
        COMP_RATIO=COMP_RATIO, 
        TOPFREQ = TOPFREQ,
        BOTFREQ = BOTFREQ,
        
      }
      --I_SPECEDIT:x:TOPFREQ_DEL:y : int * : reading or writing will delete top frequency-point y. there will always be at least one point.
      --I_SPECEDIT:x:BOTFREQ_DEL:y : int * : reading or writing will delete bottom frequency-point y. there will always be at least one point.
    end
    
    
    -- add
    local FFT_SIZE_SET
    if data and data.add_table then -- add table if specified
      local in_t = data.add_table
      local in_sz = #in_t
      
      local min_pos = math.huge
      for x = 1,in_sz do
        min_pos = math.min(min_pos, in_t[x].POSITION)
      end
      
      local curpos = GetCursorPositionEx( -1 )
      local item = reaper.GetMediaItemTake_Item( take )
      local item_pos = GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_len = GetMediaItemInfo_Value( item, "D_LENGTH" )
      
      for x = 1,in_sz do
        local newidx = GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:ADD' )
        if in_t[x].FFT_SIZE~=FFT_SIZE then FFT_SIZE_SET = in_t[x].FFT_SIZE end
        
        if curpos >= item_pos and curpos <= item_pos + item_len then
          se_pos = curpos - item_pos
          SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':POSITION', se_pos + in_t[x].POSITION - min_pos) 
         else
          SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':POSITION', in_t[x].POSITION)
        end
        
        --SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':POSITION', in_t[x].POSITION)
        SetMediaItemTakeInfo_Value( take, 'D_SPECEDIT:'..newidx..':LENGTH', in_t[x].LENGTH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GAIN', in_t[x].GAIN )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_IN', in_t[x].FADE_IN )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_OUT', in_t[x].FADE_OUT )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_LOW', in_t[x].FADE_LOW)
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':FADE_HI', in_t[x].FADE_HI )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':CHAN', in_t[x].CHAN )
        SetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':FLAGS', in_t[x].FLAGS )--&1=bypassed, &2=solo
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_THRESH', in_t[x].GATE_THRESH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':GATE_FLOOR', in_t[x].GATE_FLOOR )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_THRESH', in_t[x].COMP_THRESH )
        SetMediaItemTakeInfo_Value( take, 'F_SPECEDIT:'..newidx..':COMP_RATIO', in_t[x].COMP_RATIO )
        SetMediaItemTakeInfo_Value( take, 'B_SPECEDIT:'..newidx..':SELECTED', in_t[x].SELECTED )
        
        local botsz = #in_t[x].BOTFREQ
        for y = 1,botsz do
          local pos = in_t[x].BOTFREQ[y].BOTFREQ_POS
          local val = in_t[x].BOTFREQ[y].BOTFREQ_FREQ
          GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':BOTFREQ_ADD:'..pos..':'..val )
        end
        
        local topsz = #in_t[x].TOPFREQ
        for y = 1,topsz  do
          local pos = in_t[x].TOPFREQ[y].TOPFREQ_POS
          local val = in_t[x].TOPFREQ[y].TOPFREQ_FREQ
          GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:'..newidx..':TOPFREQ_ADD:'..pos..':'..val )
        end 
        GetMediaItemTakeInfo_Value( take, 'IP_SPECEDIT:SORT' )
      end
    end
    
    if FFT_SIZE_SET then GetMediaItemTakeInfo_Value( take, 'I_SPECEDIT:FFT_SIZE',FFT_SIZE_SET ) end -- apply fft sz if different from current
    return SE
  end
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
  function table.exportstring( s ) return string.format("%q", s) end
  
  --// The Save Function
  function table.save_tostring(  tbl )
  local outstr = ''
    local charS,charE = "   ","\n"
  
    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    outstr = outstr..'\n'..( "return {"..charE )
  
    for idx,t in ipairs( tables ) do
       outstr = outstr..'\n'..( "-- Table: {"..idx.."}"..charE )
       outstr = outstr..'\n'..( "{"..charE )
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
             outstr = outstr..'\n'..( charS.."{"..lookup[v].."},"..charE )
          elseif stype == "string" then
             outstr = outstr..'\n'..(  charS..table.exportstring( v )..","..charE )
          elseif stype == "number" then
             outstr = outstr..'\n'..(  charS..tostring( v )..","..charE )
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
                str = charS.."["..table.exportstring( i ).."]="
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
                   outstr = outstr..'\n'..( str.."{"..lookup[v].."},"..charE )
                elseif stype == "string" then
                   outstr = outstr..'\n'..( str..table.exportstring( v )..","..charE )
                elseif stype == "number" then
                   outstr = outstr..'\n'..( str..tostring( v )..","..charE )
                end
             end
          end
       end
       outstr = outstr..'\n'..( "},"..charE )
    end
    outstr = outstr..'\n'..( "}" )
    return outstr
  end
  
  --// The Load Function
  function table.load_fromstring( str )
  if str == '' then return end
    local ftables,err = load( str )
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
--------------------------------------------------------------------- 
  function encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
--------------------------------------------------------------------- 
function decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
--------------------------------------------------------------------
  function main()
    
    local strb64 = GetExtState( 'MPL_SEtools', 'buf', outstr, false )
    if strb64=='' then return end
    in_t = table.load_fromstring(decBase64(strb64))
    
    for i =1, CountSelectedMediaItems(-1) do
      local item = reaper.GetSelectedMediaItem(-1,i-1)
      if not item then return end 
      local take = GetActiveTake(item)
      if not (take and TakeIsMIDI(take)~= true) then return end 
      MPL_SpectralEdits_Manipulate(take, {add_table = in_t})
      UpdateItemInProject(item)
    end
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.31,true) then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Paste spectral edits to selected items active take", 0xFFFFFFFF)
  end   
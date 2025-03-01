-- @version 1.02
-- @author MPL
-- @description Toggle show tracks if edit cursor crossing any of their items
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + use external state




  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ----------------------------------
  function HasCrossedItems(tr, curpos)
    for i_it = 1,  CountTrackMediaItems( tr) do
      local it = GetTrackMediaItem( tr, i_it-1 )
      local it_pos = GetMediaItemInfo_Value( it, 'D_POSITION' )
      local it_len = GetMediaItemInfo_Value( it, 'D_LENGTH' )                   
      if it_pos <= curpos and it_pos + it_len >= curpos then return true end
    end  
  end
  -------------------------------------------------------
  function main_ShowTracksWithItems()  
    local curpos = GetCursorPosition(0)
    local tcp_hide_ext_str = ''
    for i_tr = 1, CountTracks(-1) do
      local tr = GetTrack(0,i_tr-1) 
      local show
       is_visibleTCP = math.floor(GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP' ))
      local is_visibleMCP = math.floor(GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER'))
      if is_visibleTCP == 0 or is_visibleMCP ==0 then tcp_hide_ext_str = tcp_hide_ext_str..'\n'.. GetTrackGUID( tr )..' '..is_visibleTCP..' '..is_visibleMCP end
      
      if is_visibleTCP==1 and HasCrossedItems(tr, curpos) then
        SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1 )
        SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP',   1 )  
       else
        SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 0 )
        SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP',   0 )
      end
      SetProjExtState(-1, 'MPL_TOGGLESHOWTRWITHITEMS', 'curpos', tcp_hide_ext_str )    
    end
    
  end
  ------------------------------------------------------- 
  function main_RestoreTracks()
    local _, ext_s = GetProjExtState(-1, 'MPL_TOGGLESHOWTRWITHITEMS', 'curpos') 
    local t = {}
    for line in ext_s:gmatch('[^\r\n]+') do
      local t2 = {} for val in line:gmatch('[^%s]+') do t2[#t2+1] = val end
      if #t2 == 3 then t[t2[1]] = {tcp=tonumber(t2[2]),mcp = tonumber(t2[3])} end
    end
    for i_tr = 1, CountTracks(-1) do
      local tr = GetTrack(-1,i_tr-1)  
      local trGUID = GetTrackGUID( tr ) 
      if t[trGUID] then
        SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', t[trGUID].mcp )
        SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP',   t[trGUID].tcp ) 
       else
        SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1 )
        SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP',   1 ) 
      end
    end
  end
  -------------------------------------------------------  
  function IsIncludeArea(tr, loop_st, loop_end)
    for i_it = 1,  CountTrackMediaItems( tr) do
      local it = GetTrackMediaItem( tr, i_it-1 )
      local it_pos = GetMediaItemInfo_Value( it, 'D_POSITION' )
      local it_len = GetMediaItemInfo_Value( it, 'D_LENGTH' ) 
      if (it_pos <= loop_st and it_pos+it_len >= loop_st) or (it_pos >= loop_st and it_pos <=loop_end) then return true end
    end
  end
  -------------------------------------------------------
  local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context() 
   _, ext_state = GetProjExtState(-1, 'MPL_TOGGLESHOWTRWITHITEMS', 'state') 
  if ext_state == '' then 
    ext_state = 0 
    SetProjExtState(-1, 'MPL_TOGGLESHOWTRWITHITEMS', 'curpos', '' )    
  end
  ext_state = tonumber(ext_state)
  SetProjExtState(-1, 'MPL_TOGGLESHOWTRWITHITEMS', 'state', math.abs(1-ext_state)  )    
  -------------------------------------------------------
  if ext_state == 0 then 
    main_ShowTracksWithItems() 
   else
    main_RestoreTracks()
  end
  TrackList_AdjustWindows( false )
  UpdateArrange()
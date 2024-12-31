-- @description Create send between selected tracks and track under mouse cursor
-- @version 1.21
-- @author MPL
-- @metapackage
-- @provides
--    [main] . > mpl_Send selected tracks to track under mouse cursor (multichannel).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, post-fader).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, pre-fx).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, post-fx).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 3-4).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 5-6).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 7-8).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 9-10).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 11-12).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 13-14).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 15-16).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 3-4 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 5-6 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 7-8 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 9-10 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 11-12 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 13-14 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 15-16 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (multichannel).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 3-4).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 5-6).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 7-8).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 9-10).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 11-12).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 13-14).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 15-16).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 3-4 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 5-6 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 7-8 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 9-10 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 11-12 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 13-14 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 15-16 to 1-2).lua
-- @website http://forum.cockos.com/showthread.php?t=188335  
-- @changelog
--    # replace missed data for default send flags by -2.0dB in postfader mode

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



  obeyparent_channels = true
  show_routing_window = false
  reset_stereo_in_multich_mode = false
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end
  ---------------------------------------------------------------------
  function GetDestTrGUID()
    local t = {}
    local src_track = VF_GetTrackUnderMouseCursor()
    if src_track then t[1] = GetTrackGUID( src_track ) end  
    return t   
  end
  ---------------------------------------------------------------------
  function GetSrcTrGUID()
    local t = {}
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      t[#t+1] = GetTrackGUID( tr )
    end  
    return t 
  end
  --------------------------------------------------------------------- 
  function Check_t(src_t, dest_t)
    for i = 1, #src_t do
      local chGUID = src_t[i]:gsub('%p', '')
      for i = #dest_t, 1, -1 do
        if dest_t[i]:gsub('%p', '') == chGUID then
          table.remove(dest_t,i)
          break
        end
      end
    end
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
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ---------------------------------------------------------------------   
  function AddSends(data_t, src_t0, dest_t0)
    local src_t, dest_t = CopyTable(src_t0), CopyTable(dest_t0)
    if data_t.source_type == false then  src_t, dest_t = CopyTable(dest_t0), CopyTable(src_t0) end
    
    -- validate mode
      if data_t.MCH_mode==false and not (data_t.src_ch and data_t.dest_ch) then return end
    
    -- loop source tracks
    for srci = 1, #src_t do
      local src_tr =  VF_GetTrackByGUID( src_t[srci] )
      local src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
      if obeyparent_channels == true then src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'C_MAINSEND_NCH') end
      
      for desti = 1, #dest_t do
        local dest_tr =  VF_GetTrackByGUID(dest_t[desti] )
        
        -- check for existing sends
          local is_exist = false
          for sendid =1,  GetTrackNumSends( src_tr, 0 ) do
            local dest_tr_check = GetTrackSendInfo_Value( src_tr, 0, sendid-1, 'P_DESTTRACK' ) 
            local dest_tr_src_ch = GetTrackSendInfo_Value( src_tr, 0, sendid-1, 'I_SRCCHAN')
            local dest_tr_dest_ch = GetTrackSendInfo_Value( src_tr, 0, sendid-1, 'I_DSTCHAN')
            
            
            if dest_tr_check == dest_tr and 
              ( 
                (data_t.MCH_mode == false and dest_tr_src_ch == data_t.src_ch-1 and dest_tr_dest_ch == data_t.dest_ch-1)
                or
                ( data_t.MCH_mode == true and dest_tr_dest_ch == 0)
              )
              then is_exist = true  break end
          end
        
        -- perform main stuff
        if not is_exist then  
          local new_id = CreateTrackSend( src_tr, dest_tr )
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', data_t.defsendvol)
          local sendmode = data_t.defsendflag
          if data_t.custom_sendmode then sendmode = data_t.custom_sendmode end
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', sendmode&255) -- obey MIDI flag
          
          if data_t.MCH_mode == true then
            local dest_tr_ch = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
            if dest_tr_ch < src_tr_ch then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end -- increase dest channel count up to src track
            
            local flags = 0
            if src_tr_ch == 1 then
              flags = 1024 
             else
              if src_tr_ch%2 ~= 0 then  src_tr_ch = src_tr_ch + 1 end
              if src_tr_ch ~= 2 then flags = src_tr_ch<<9 end
            end
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 0)
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',flags) -- always start multichannel from 1st chan
          end
          
          if data_t.MCH_mode == false then
            if GetMediaTrackInfo_Value( src_tr, 'I_NCHAN'  ) < data_t.src_ch+1 then SetMediaTrackInfo_Value( src_tr, 'I_NCHAN', data_t.src_ch+1  ) end 
            if GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN'  ) < data_t.dest_ch+1 then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', data_t.dest_ch+1  ) end  
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN', data_t.src_ch-1)
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', data_t.dest_ch-1) 
          end   
                   
        end
      end
    end
  end
  ---------------------------------------------------------------------------------------------------------------------
  function GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end 
  ---------------------------------------------------------------------  
  function Parsing_filename()
    local filename = ({reaper.get_action_context()})[2]
    local script_title = GetShortSmplName(filename):gsub('%.lua','')
    local source_type = script_title:match('Send selected tracks to track under mouse cursor') ~= nil -- true==selected tracks is source
    local channel_mode = script_title:match('%((.*)%)')
    local MCH_mode, dest_ch, src_ch = false
    if channel_mode:match('multichannel') then 
      MCH_mode = true 
     else
      src_ch = channel_mode:match('channel (%d+)') if src_ch then src_ch = tonumber(src_ch) end
      dest_ch = channel_mode:match('to (%d+)') if dest_ch then dest_ch = tonumber(dest_ch) end
    end
    
    local custom_sendmode
    if script_title:match('post%-fader') then custom_sendmode = 0 end
    if script_title:match('pre%-fx') then custom_sendmode = 1 end
    if script_title:match('post%-fx') then custom_sendmode = 3 end
    
    return source_type, MCH_mode, src_ch, dest_ch, script_title, custom_sendmode
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
      --reaper.ShowConsoleMsg("Couldn't find section: " .. section .. "\n")
      return-- false
    end
    if not key_found then 
      --if section_found and not key_found then reaper.ShowConsoleMsg("Couldn't find key: " .. key .. "\n") end
    return-- false
    end
  end
  ------------------------------------------------------------------------------------------------------
  function Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
  ---------------------------------------------------------------------  
  function main(data_t)
    Undo_BeginBlock()
    local src_GUID = GetSrcTrGUID()
    local dest_GUID = GetDestTrGUID()    
    Check_t(src_GUID,dest_GUID)
    if #src_GUID < 1 or #dest_GUID < 1 then return end
    AddSends(data_t, src_GUID,dest_GUID)
    TrackList_AdjustWindows(false)
    Undo_EndBlock(data_t.script_title, 0xFFFFFFFF) 
  end 
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true)  then 
    local defsendvol = VF_spk77_getinivalue( get_ini_file(), 'REAPER', 'defsendvol') or 0.79432823
    local defsendflag = VF_spk77_getinivalue( get_ini_file(), 'REAPER', 'defsendflag') or 256
    
    local source_type, MCH_mode, src_ch, dest_ch, script_title, custom_sendmode = Parsing_filename()
    local data_t = {source_type=source_type, MCH_mode=MCH_mode, src_ch=src_ch, dest_ch=dest_ch, script_title=script_title, defsendvol=defsendvol or 1, defsendflag=defsendflag or 256, custom_sendmode=custom_sendmode}
    main(data_t)
    if show_routing_window==true then Action(40293) end
  end 
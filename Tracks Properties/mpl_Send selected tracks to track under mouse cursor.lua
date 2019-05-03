-- @version 1.10
-- @author MPL
-- @description Send selected tracks to track under mouse cursor
-- @metapackage
-- @provides
--    [main] . > mpl_Send selected tracks to track under mouse cursor (multichannel).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2).lua
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
-- @changelog
--    + Modified for using as metapackage
-- @website http://forum.cockos.com/showthread.php?t=188335    

  
  ---------------------------------------------------------------------
  function GetDestTrGUID()
    local t = {}
    local _, segment = BR_GetMouseCursorContext()
    if segment == "track" then
      local src_track = BR_GetMouseCursorContext_Track()
      t[1] = GetTrackGUID( src_track )      
    end  
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
  ---------------------------------------------------------------------   
  function AddSends(src_t, dest_t, MCH_mode, src_ch, dest_ch, defsendvol, defsendflag)
  
    -- validate mode
      if MCH_mode==false and not (src_ch and dest_ch) then return end
    
    -- loop source tracks
    for i = 1, #src_t do
      local src_tr =  BR_GetMediaTrackByGUID( 0, src_t[i] )
      local src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
      
      for i = 1, #dest_t do
        local dest_tr =  BR_GetMediaTrackByGUID( 0, dest_t[i] )
        
        -- check for existing sends
          local is_exist = false
          for i =1,  GetTrackNumSends( src_tr, 0 ) do
            -- obsolete SWS API //  local dest_tr_check = BR_GetMediaTrackSendInfo_Track( src_tr, 0, i-1, 1 )
            local dest_tr_check = GetTrackSendInfo_Value( src_tr, 0, i-1, 'P_DESTTRACK' ) 
            if dest_tr_check == dest_tr then is_exist = true break end
          end
        
        -- perform main stuff
        if not is_exist then  
          local new_id = CreateTrackSend( src_tr, dest_tr )
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', defsendflag&255) -- obey MIDI flag
          
          if MCH_mode == true then
            local dest_tr_ch = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
            if dest_tr_ch < src_tr_ch then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end -- increase dest channel count up to src track
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 0) -- always start multichannel from 1st chan
            if dest_tr_ch == 2 then src_flag = 0 else src_flag = 0|(1024*math.floor(src_tr_ch/2)) end
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',src_flag)
          end
          
          if MCH_mode == false then
            if GetMediaTrackInfo_Value( src_tr, 'I_NCHAN'  ) < src_ch+1 then SetMediaTrackInfo_Value( src_tr, 'I_NCHAN', src_ch+1  ) end 
            if GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN'  ) < dest_ch+1 then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', dest_ch+1  ) end  
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN', src_ch-1)
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', dest_ch-1)
          end   
                   
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function main(MCH_mode, src_ch, dest_ch, script_title, defsendvol, defsendflag)
    Undo_BeginBlock()
    local src_GUID = GetSrcTrGUID()
    local dest_GUID = GetDestTrGUID()    
    Check_t(src_GUID,dest_GUID)
    if #src_GUID < 1 or #dest_GUID < 1 then return end
    AddSends(src_GUID,dest_GUID, MCH_mode, src_ch, dest_ch, defsendvol, defsendflag)
    TrackList_AdjustWindows(false)
    Undo_EndBlock(script_title, 0) 
  end 
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  ---------------------------------------------------------------------  
  function Parsing_filename()
    local filename = ({reaper.get_action_context()})[2]           --:sub(0,-6)..' to 1-2).lua'
    local script_title = filename:match('Send selected tracks to track under mouse cursor %(.*%)')
    local mode = filename:match('Send selected tracks to track under mouse cursor %((.*)%)')
    local MCH_mode, dest_ch, src_ch = false
    if mode:match('multichannel') then 
      MCH_mode = true 
     else
      src_ch = mode:match('channel (%d+)') if src_ch then src_ch = tonumber(src_ch) end
      dest_ch = mode:match('to (%d+)') if dest_ch then dest_ch = tonumber(dest_ch) end
    end
    return MCH_mode, src_ch, dest_ch, script_title
  end
  -------------------------------------------------
  local ret = CheckFunctions('VF_CheckReaperVrs') 
  local ret2 = VF_CheckReaperVrs(5.95)    
  if ret and ret2 then 
    local defsendvol = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  get_ini_file() )})[2]
    local defsendflag = ({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  get_ini_file() )})[2] 
    local MCH_mode, src_ch, dest_ch, script_title = Parsing_filename()
    main(MCH_mode, src_ch, dest_ch, script_title, defsendvol, defsendflag) 
  end
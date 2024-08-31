-- @description Normalize selected items to middle loudness between them
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--   [main] . > mpl_Normalize selected items to middle integrated LUFS between them.lua
--   [main] . > mpl_Normalize selected items to middle momentary max LUFS between them.lua
--   [main] . > mpl_Normalize selected items to middle short term max LUFS between them.lua
-- @changelog
--    # VF independent

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
  ---------------------------------------------------
  function main(loudness_val_key0)
    local loudness_val_key = loudness_val_key0 or 'LUFSI'
    if CountSelectedMediaItems(0) == 1 then return end -- do nothng at single selected item
    
    -- reset item volume
      for i =1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1) 
        SetMediaItemInfo_Value(item, "D_VOL",1)
      end
    
    -- parse stats
      local retval, stat = reaper.GetSetProjectInfo_String( 0, 'RENDER_STATS', '42437', false )
      if not retval then return end
      stat = stat:gsub('FILE','\nFILE') 
       t,id = {},0 for chunk in stat:gmatch('[^\r\n]+') do 
        local params = {}
        for kv in chunk:gmatch('[%a]+%:.-%;') do
          local key,value = kv:match('([%a]+)%:(.-);')
          if key and value then params[key] = tonumber(value) or value end
        end
        id = id + 1 t[id] = {chunk=chunk} 
        for key in pairs(params) do t[id][key] = params[key] end
      end 
      
      
    -- handle items
      if CountSelectedMediaItems(0) ~= #t then return end
      for i =1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1) 
        t[i].item_ptr = item
        t[i].item_vol = GetMediaItemInfo_Value(item, "D_VOL")
      end
      
    -- calc mid
       lufs_mid = 0
      for i = 1, #t do 
        if not t[i][loudness_val_key] then return end
        lufs_mid = lufs_mid + t[i][loudness_val_key] 
      end 
      lufs_mid = lufs_mid  / #t
    
    -- apply
      for i = 1, #t do  
        t[i].vol_DB = 20*math.log(t[i].item_vol)
        t[i].diff_DB = lufs_mid-t[i][loudness_val_key] 
        t[i].out_db = t[i].vol_DB + t[i].diff_DB
        t[i].out_val = math.exp(-t[i].diff_DB*0.115129254)
        SetMediaItemInfo_Value(t[i].item_ptr, "D_VOL",t[i].out_val)
      end
      reaper.UpdateArrange()
    
    
  end
  
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true) then 
    local scr_name = ({reaper.get_action_context()})[2]
    local loudness_val_key = 'LUFSI'
    if scr_name:match('integrated LUFS') then 
      loudness_val_key = 'LUFSI'
     elseif scr_name:match('momentary max LUFS') then 
      loudness_val_key = 'LUFSMMAX'
     elseif scr_name:match('short term max LUFS') then 
      loudness_val_key = 'LUFSSMAX'     
    end
    Undo_BeginBlock2( 0 )
    main(loudness_val_key) 
    Undo_EndBlock2( 0, 'Normalize selected items to middle loudnaess between them', 0xFFFFFFFF )
  end 

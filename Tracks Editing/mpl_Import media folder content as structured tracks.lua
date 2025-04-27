-- @description Import media folder content as structured tracks
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Scan folder media and add media items on named tracks obey paths structure
-- @changelog
--    # Сomplete rebuild
--    # better/faster recursive search function, thanks to amagalma, FeedTheCat




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
  function msg(s) 
    if not (s and type(s)~='table')then return end 
    if type(s) == 'boolean' then
      if s then s = 'true' else  s = 'false' end
    end
    ShowConsoleMsg(s..'\n') 
  end 
  -------------------------------------------------------------------
  function AddMediaToFile(new_tr, filepath)
    local curpos = GetCursorPosition()
    local item = AddMediaItemToTrack( new_tr )
    local take = AddTakeToMediaItem( item )
    if not take then return end
    local pcm_src = PCM_Source_CreateFromFileEx( filepath, false )
    if not pcm_src then return end
    SetMediaItemTake_Source( take, pcm_src )
    local retval, lengthIsQN = reaper.GetMediaSourceLength( pcm_src )
    SetMediaItemInfo_Value( item, 'D_POSITION' , curpos )
    SetMediaItemInfo_Value( item, 'D_LENGTH' , retval )
    SetOnlyTrackSelected( new_tr )
    local trname = filepath:reverse():match('(.-)[%\\/]'):reverse()
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', trname, 1 )
    SetMediaItemSelected( item, true )
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
-------------------------------------------------------------------
function GetChildFolder(dir) parent =  dir:match('(.*)[%\\/]') return dir:gsub(parent,''):gsub('[%\\/]','') end
---------------------------------------------------
function GetDirFilesRecursive(dir, files) -- https://forum.cockos.com/showpost.php?p=2464958&postcount=23
  if not depth then depth = 0 end
  depth = depth + 1
  
  local sep = package.config:sub(1,1)
  -- FeedTheCat function mod by amagalma
  local files = files or {}
  local sub_dirs = {}
  local sub_dirs_cnt = 0
  repeat
    local sub_dir = reaper.EnumerateSubdirectories(dir, sub_dirs_cnt)
    if sub_dir then
      sub_dirs_cnt = sub_dirs_cnt + 1
      sub_dirs[sub_dirs_cnt] = dir .. sep .. sub_dir
    end
  until not sub_dir
  for dir = 1, sub_dirs_cnt do
    local t = {}
    GetDirFilesRecursive(sub_dirs[dir], t)
    pathname = GetChildFolder(sub_dirs[dir])
    files[dir] = CopyTable(t)
    files[dir].pathname = pathname
    
    
    files[dir].pathdepth = depth
    
  end
  
  local file_cnt = #files
  local i = 0
  repeat
    local file = reaper.EnumerateFiles(dir, i)
    if file then
      i = i + 1
      files[file_cnt + i] = {
        fp = dir .. sep .. file,
        dir = dir,
        depth = depth}
    end
  until not file
  
  depth = depth - 1
  return files
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
-------------------------------------------------------------------  
function AddMedia(files)
  if not (files and type(files) == 'table')then return end 
  -- start of table
  
  local foldclose = 1
  if type(files) == 'table' and files.pathname then 
    local subfold = files.pathname
    local depth = files.pathdepth
    
    --------- SUBFOLD
    local flags = 0 -- flags&1 for default envelopes/FX, otherwise no enabled fx/envelopes will be added.
    InsertTrackInProject( -1, CountTracks( -1 ), flags )
    local parenttr = GetTrack(-1,CountTracks( -1 )-1)
    GetSetMediaTrackInfo_String( parenttr, 'P_NAME', subfold, 1 )
    SetMediaTrackInfo_Value( parenttr, 'I_FOLDERDEPTH', 1 )
    if last_tr and last_depth and last_depth > depth then 
      local isfold = GetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH' )==1 
      if isfold ~= true then 
        SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH', - (last_depth - depth ) )
      end
    end
    last_tr = parenttr
    last_depth = depth
  end
  
  local childtr
  for i = 1, #files do
    if (files and type(files) == 'table') then AddMedia(files[i]) end -- add another sub path
    
    if type(files[i]) == 'table' and files[i].fp then
      local shortfilename = files[i].fp
      local depth = files[i].depth
      
      ------- CHILD
      local flags = 0 -- flags&1 for default envelopes/FX, otherwise no enabled fx/envelopes will be added.
      InsertTrackInProject( -1, CountTracks( -1 ), flags )
      childtr = GetTrack(-1,CountTracks( -1 )-1)
      GetSetMediaTrackInfo_String( childtr, 'P_NAME', shortfilename, 1 )
      AddMediaToFile(childtr, shortfilename)
      if last_tr and last_depth and last_depth > depth then 
        local isfold = GetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH' )==1 
        if isfold ~= true then 
          SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH', - (last_depth - depth ) )
        end
      end
      
      last_tr = childtr
      last_depth = depth
    end
  end 
  
  
end
-----------------------------------------------------------------  
function main() 
   files = {}
  local idx = 0
  
  if VF_CheckReaperVrs(5.95,true) then
  
    local ret, dir = reaper.GetUserInputs('Paste source directory', 1, 'path,extrawidth=400', '')
    if not (ret and dir ~= '') then return end
    
    --dir = [[C:\Users\MPL\Desktop\New folder]]
    GetDirFilesRecursive(dir, files)
    
    local flags = 0 -- flags&1 for default envelopes/FX, otherwise no enabled fx/envelopes will be added.
    InsertTrackInProject( -1, CountTracks( -1 ), flags )
    local parenttr = GetTrack(-1,CountTracks( -1 )-1)
    GetSetMediaTrackInfo_String( parenttr, 'P_NAME', 'Imported media', 1 )
    SetMediaTrackInfo_Value( parenttr, 'I_FOLDERDEPTH', 1 )
    PreventUIRefresh( -1 )
    
    AddMedia(files)  
    
    Undo_BeginBlock2( 0 )
    
    PreventUIRefresh( 1 )
    Undo_EndBlock2( 0, 'Import media as track structure', 0xFFFFFFFF ) 
    
    Main_OnCommand(40245,0) -- Peaks: Build any missing peaks for selected items
  end
end  
-----------------------------------------------------------------   
  ClearConsole()
  main()
  
  
  
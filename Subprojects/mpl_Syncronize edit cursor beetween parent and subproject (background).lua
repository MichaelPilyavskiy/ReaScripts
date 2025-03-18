-- @description Syncronize edit cursor beetween parent and subproject (background)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


for key in pairs(reaper) do _G[key]=reaper[key] end   
function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
----------------------------------------------------------------
function getsubprojlocaleditcursor(subproj)
  local editcurpos = reaper.GetCursorPositionEx( subproj ) 
  local retval, num_markers, num_regions = reaper.CountProjectMarkers( subproj )
  for idx = 1, num_markers + num_regions do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers2(subproj, idx-1 ) 
    if name and name == '=START' then
      if editcurpos >=pos then return editcurpos - pos end
    end
  end
  return
end
----------------------------------------------------------------
function applyoffsettoparentproj(mainproj, subprojfp, local_editcur)
  local cnt = reaper.CountMediaItems( mainproj )
  for itemidx = 1, cnt do
    local item = reaper.GetMediaItem( mainproj, itemidx-1 )
    local take = GetActiveTake(item)
    if take then 
      source = reaper.GetMediaItemTake_Source( take )
      typebuf = reaper.GetMediaSourceType( source )
      if typebuf == 'SECTION' then
        source = reaper.GetMediaSourceParent( source )
        typebuf = reaper.GetMediaSourceType( source )
      end
      if typebuf == 'RPP_PROJECT' then
        filenamebuf = reaper.GetMediaSourceFileName( source )
        if filenamebuf:gsub('%p+','') == subprojfp:gsub('%p+',''):gsub('PROX','')  then
          D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION' )
          D_STARTOFFS = reaper.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
          srclen = reaper.GetMediaSourceLength( source )
          if D_STARTOFFS > srclen/2 then D_STARTOFFS = - (srclen - D_STARTOFFS) end
          local editcurpos_out = D_POSITION + local_editcur - D_STARTOFFS
          if editcurpos_out < D_POSITION then editcurpos_out = editcurpos_out + srclen end
          reaper.SetEditCurPos2( mainproj, editcurpos_out, true, false )
          return
        end
      end
    end
  end
end
----------------------------------------------------------------
function onchangetab(previous_proj, current_project) 
  local is_previous_subproj = false
  local prname = reaper.GetProjectName( previous_proj )
  local prpath = reaper.GetProjectPathEx( previous_proj )
  local fp = prpath..'/'..prname
  
  local test1 = fp..'-PROX'
  local test2 = fp:gsub('Audio[%\\%/]','')..'-PROX'
  local valid_fp
  if file_exists(test1) then valid_fp = test1 end
  if file_exists(test2) then valid_fp = test2 end
  
  if valid_fp then is_previous_subproj = true end 
  
  
  -- if previous tab was subproject
    if is_previous_subproj == true then 
      local_editcur = getsubprojlocaleditcursor(previous_proj)
      if not local_editcur then return end
      applyoffsettoparentproj(current_project, valid_fp, local_editcur) 
      return
    end
  
  -- if previous tab was parent
    if is_previous_subproj ~= true then 
      applyoffsettochildrenproj(previous_proj)
    end
end
----------------------------------------------------------------
function applyoffsettochildrenproj(parentproj)
  -- collect projects
  
  local editcurpos = reaper.GetCursorPositionEx( parentproj )
  local cnt = reaper.CountMediaItems( parentproj )
  for itemidx = 1, cnt do
    local item = reaper.GetMediaItem( parentproj, itemidx-1 )
    local take = GetActiveTake(item)
    if take then 
      source = reaper.GetMediaItemTake_Source( take )
      subproj = reaper.GetSubProjectFromSource( source )
      typebuf = reaper.GetMediaSourceType( source )
      if typebuf == 'SECTION' then
        source = reaper.GetMediaSourceParent( source )
        typebuf = reaper.GetMediaSourceType( source )
      end
      if typebuf == 'RPP_PROJECT' and subproj then
        D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION' )
        D_STARTOFFS = reaper.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        applyoffsettochildrenproj_sub(subproj, editcurpos - D_POSITION + D_STARTOFFS)
      end
    end
  end
end
----------------------------------------------------------------
function applyoffsettochildrenproj_sub(subproj, offset)
  local retval, num_markers, num_regions = reaper.CountProjectMarkers( subproj )
  for idx = 1, num_markers + num_regions do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers2(subproj, idx-1 ) 
    if name and name == '=START' then
      reaper.SetEditCurPos2( subproj, pos + offset, true, false )
      return
    end
  end
end
----------------------------------------------------------------
function main()
  local cur_reaproj, projfn = reaper.EnumProjects( -1 ) 
  if cur_reaproj_last and cur_reaproj_last ~= cur_reaproj then 
    onchangetab(cur_reaproj_last, cur_reaproj) 
  end
  cur_reaproj_last = cur_reaproj
  reaper.defer(main)
end
----------------------------------------------------------------
main()
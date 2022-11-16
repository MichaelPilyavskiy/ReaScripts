-- @description ReplaceFX
-- @version 1.04
-- @author MPL
-- @about Script for replacing FX by name
-- @changelog
--    # fix formatting fx name
  
  version = 1.04
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
    
            -- globals
            mb_title = 'ReplaceFX',
            ES_key = 'MPL_ReplaceFX',
            wind_x =  50,
            wind_y =  50,
            wind_w =  520,
            wind_h =  250,
            dock =    0,
            
            filter = '',
            plugintoreplace = '',
            replaceto='',
            
            modifyFXIDonly = 0,
            }
    return t
  end
  ------------------------------------------------------------------
  function VF_run_initVars_overwrite()
    DATA.conf.min_vzoom = 0.02
    --DATA.conf.v_zoom_res = 300
    DATA.conf.wind_w = 300
    DATA.conf.wind_h = 200
  end
  ------------------------------------------------------------------
  function VF_DATA_Init(MOUSEt,OBJ,DATA)
    DATA.custom = {}
    DATA.custom.plugins = {}
    VF2_EnumeratePlugins(DATA.custom.plugins) 
  end
  ------------------------------------------------------------------
  function VF_DATA_UpdateRead(MOUSE,OBJ,DATA)
    DATA.custom.FX = VF2_CollectFXData()
  end  
  --------------------------------------------------------------------  
  function MPL_ReplaceFX_replace(MOUSE,OBJ,DATA)
    local plugintoreplace = DATA.conf.plugintoreplace
    local replaceto = DATA.conf.replaceto--:gsub('%(.-%)', '') 
    if plugintoreplace == '' or replaceto=='' then return end
    VF2_CollectFXData(DATA.custom.FX) -- refresh FX right before replace
    if not DATA.custom.FX or not DATA.custom.FX[plugintoreplace] then return end  
     
    for i=1, #DATA.custom.FX[plugintoreplace] do  
      local tr = DATA.custom.FX[plugintoreplace][i].tr_ptr
      -- add new plugin
        local new_pos = TrackFX_AddByName( tr, replaceto, false, -1 )
        if new_pos == -1 then goto skipnextfx end
      -- shift under existed
        local ret, _, fxpos = VF_GetFXByGUID(DATA.custom.FX[plugintoreplace][i].GUID, tr)
        TrackFX_CopyToTrack( tr, new_pos, tr, fxpos+1, true )
      -- modify FXID only
        if DATA.conf.modifyFXIDonly == 1 then
          MPL_ReplaceFX_ModifyFXIDOnly(MOUSE,OBJ,DATA, tr, fxpos, fxpos+1) 
        end
        
      -- remove old plugin
        TrackFX_Delete( tr, fxpos )
      ::skipnextfx:: 
    end
    return true
  end
  ---------------------------------------------------
  function MPL_ReplaceFX_ModifyFXIDOnly(MOUSE,OBJ,DATA, tr, old_fx, new_fx) 
    local old_chunk = VF2_GetSetFXChunk(tr, old_fx)
    local new_chunk = VF2_GetSetFXChunk(tr, new_fx)
    
    -- take id line from new fx
      local new_chunk_t = {}
      for line in new_chunk:gmatch('[^\r\n]+') do new_chunk_t[#new_chunk_t+1] = line if #new_chunk_t > 2 then break end end
     
    -- modify old chunk with new fx id
      local old_chunk_t = {}
      for line in old_chunk:gmatch('[^\r\n]+') do old_chunk_t[#old_chunk_t+1] = line end 
      old_chunk_t[2] = new_chunk_t[2]
      
    -- apply modded chink to new fx
      VF2_GetSetFXChunk(tr, new_fx, table.concat(old_chunk_t,'\n'))
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Init(MOUSE,OBJ,DATA)
    local options_t =  {{ str = '|#Options'},    
                        { str = 'Replace only FX ID info, preserve configuration',
                          state=DATA.conf.modifyFXIDonly==1,
                          func = function() DATA.conf.modifyFXIDonly = math.abs(1-DATA.conf.modifyFXIDonly) end,
                    }}
    OBJ_Buttons_InitMenuTop(MOUSE,OBJ,DATA,options_t)
    
    local x_offs= 1
    local y_offs= DATA.GUIvars.menu_h + 5
    local wbut = gfx.w-2
    local wbut2 = math.floor(wbut/2)
    local hbut = math.floor((gfx.h-DATA.GUIvars.menu_h)/4)
    local filt = '<empty>'
    local fontsz = 17
    
    if DATA.conf.filter ~= '' then filt = DATA.conf.filter end
    local plugintoreplace = DATA.conf.plugintoreplace
    if DATA.custom.FX and (not DATA.custom.FX[plugintoreplace] or #DATA.custom.FX[plugintoreplace]== 0) then plugintoreplace = '[no plugins match]' end
    OBJ.fxinproject = {is_button = true,
              x = x_offs,
              y = hbut+y_offs,
              w = wbut,
              h = hbut,
              txt= 'Available FX in project:\n'..plugintoreplace,
              drawstr_flags = 1|4,
              fontsz = fontsz,
              func_Ltrig =  function()
                              DATA.custom.FX = VF2_CollectFXData()
                              local fxtable = {} 
                              for key in spairs(DATA.custom.FX) do
                                local filt = DATA.conf.filter
                                if filt =='' or (filt ~= '' and key:gsub('%p',''):lower():match(filt:gsub('%p',''):lower())) then 
                                  local state = key==DATA.conf.plugintoreplace
                                  fxtable[#fxtable+1] = {str = key..' ('..#DATA.custom.FX[key]..' instances)',
                                                        state=state,
                                                        func = function() DATA.conf.plugintoreplace = key end}
                                end
                              end
                              VF_MOUSE_menu(MOUSE,OBJ,DATA,fxtable)
                            end
                }       
    OBJ.filter = { is_button = true,
                x = x_offs,
                y = y_offs,
                w = wbut,
                h = hbut,
                txt= 'Filter:\n'..filt,
                drawstr_flags = 1|4,
                fontsz = fontsz,
                func_Ltrig =  function() 
                                local retval, retvals_csv = GetUserInputs( 'ReplaceFX filter', 1, '', DATA.conf.filter )
                                if retval then DATA.conf.filter = retvals_csv VF_run_UpdateAll(DATA) end 
                              end
                  }    
    OBJ.goexecute = {is_button = true,
                  x = x_offs,
                  y = hbut*3+y_offs,
                  w = wbut,
                  h = hbut,
                  txt= 'Replace',
                  drawstr_flags = 1|4,
                  fontsz = fontsz,
                  func_Ltrig =  function()  
                                  Undo_BeginBlock2( 0 )
                                  local ret = MPL_ReplaceFX_replace(MOUSE,OBJ,DATA)
                                  if ret then Undo_EndBlock2( 0, 'MPL Replace FX', 0 ) end
                                end ,
                    }   
    OBJ.replaceby = {is_button = true,
                   x = x_offs,
                   y = hbut*2+y_offs,
                   w = wbut,
                   h = hbut,
                   txt= 'Replace to:\n'.. DATA.conf.replaceto,
                   drawstr_flags = 1|4,
                   fontsz = fontsz,
                   func_Ltrig =  function()
                                   local fxtable = {}
                                   for i=1, #DATA.custom.plugins do
                                     local filt = DATA.conf.filter
                                     local key = DATA.custom.plugins[i].name
                                     local state = key ==DATA.conf.replaceto
                                     if filt =='' or (filt ~= '' and key:gsub('%p',''):lower():match(filt:gsub('%p',''):lower())) then 
                                       fxtable[#fxtable+1] = {str = key,
                                                             state=state,
                                                             func = function() DATA.conf.replaceto = key end}
                                     end
                                   end
                                   VF_MOUSE_menu(MOUSE,OBJ,DATA,fxtable)
                                 end    }    

      end
  ---------------------------------------------------------------------       
    --[[
    -- defaults
      -- but
      is_button = true,
      local x = o.x or 0
      local y = o.y or 0
      local w = o.w or 100
      local h = o.h or 100
      local grad_back_a = o.grad_back_a or 1
      local highlight = o.highlight if highlight == nil then highlight = true end
      local undermouse_frame_a = o.undermouse_frame_a or 0.4
      local undermouse_frame_col = o.undermouse_frame_col or '#FFFFFF'
      local undermouse = o.undermouse or false
      local selected = o.selected or false
      local selection_a = o.selection_a or 0.2
      -- txt
      local txt_a = o.txt_a or 0.8
      local font = o.font or 'Calibri'
      local fontsz = o.fontsz or 12
      local font_flags = o.font_flags or ''
      local txt_col = o.txt_col or '#FFFFFF'
      local txt_a = o.txt_a or 1
      local drawstr_flags = o.drawstr_flags or 0
      ]]
  function OBJ_Buttons_Update(MOUSE,OBJ,DATA) end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) 
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' 
    if  reaper.file_exists( SEfunc_path ) then
      dofile(SEfunc_path) 
      if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  
     else 
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) 
      if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end
    end   
  end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.5) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    VF_run_initVars() 
    if VF_run_initVars_overwrite then VF_run_initVars_overwrite() end
    DATA.conf.vrs = version 
    VF_run_init()  
  end end
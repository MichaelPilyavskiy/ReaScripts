-- @description ReplaceFX
-- @version 1.0
-- @author MPL
-- @changelog
--  init
  


  local vrs = 'v1.0'
  -- NOT gfx NOT reaper NOT GUI NOT MOUSE
  
  --  INIT -------------------------------------------------
   local OBJ = {refresh = {      GUIcom = true,
                            GUIback = false, 
                            GUIcontrols = false,
                            conf = false,
                            data = true,
                            test=true,
                          }
                }
  local GUI = {}
  local DATA = { conf = {} }
              
 
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
            replaceto=''
            }
    return t
  end
  ---------------------------------------------------
  function run()
    VF_MOUSE(MOUSE, OBJ)
    local project_change = DATA_CheckUPD(OBJ, DATA, GUI) 
    local refresh_GUI_int = GUI_HasWindXYWHChanged(OBJ, DATA, GUI)
    
    -- refresh triggers
      if GUI.refresh_GUI_int == 4 then -- triggers at window xy change
        OBJ.refresh.conf=true 
      end 
      if GUI.refresh_GUI_int == 3 then -- triggers at window wh change
        ExtState_Save(DATA.conf)  
        OBJ.refresh.conf=true  
        OBJ.refresh.GUIcom = true
      end 
      if project_change then -- on project change
        OBJ.refresh.data = true 
        OBJ.refresh.GUIcontrols=2 
        OBJ.refresh.GUIevents=2 
      end 
      if OBJ.refresh.GUIcom == true then -- on maj GUI update
        OBJ.refresh.GUIback=true
        OBJ.refresh.GUIcontrols=2 
        OBJ.refresh.GUIevents=2 
      end
      
    
    -- perform refresh ----
    
      if OBJ.refresh.conf == true then 
        ExtState_Save(DATA.conf) 
        OBJ.refresh.conf = false 
      end
      
      
      if OBJ.refresh.data then 
        DATA_Collect(OBJ, DATA, GUI)
        OBJ.refresh.data = false
      end

      if OBJ.refresh.GUIcom == true then
        OBJ_init(OBJ, DATA, GUI)
        OBJ.refresh.GUIcom = false
      end 
      
      if OBJ.refresh.GUIback == true then
        GUI_DrawBackground(OBJ, DATA, GUI)
        GUI_DrawBackgroundButton(OBJ, DATA, GUI)
        OBJ.refresh.GUIback = false
      end  
      
      if OBJ.refresh.GUIcontrols then
        OBJ_main(OBJ, DATA, GUI)
        GUI_DrawMain(OBJ, DATA, GUI) 
        OBJ.refresh.GUIcontrols = false
      end
      
    if OBJ.refresh.test ==true then  
      --Action_ReplaceFX(OBJ, DATA, GUI)
      OBJ.refresh.test = nil
    end
    -- draw stuff
      GUI_draw(OBJ, DATA, GUI)
      
    -- exit
      if MOUSE.char >= 0 and MOUSE.char ~= 27 then defer(run) else atexit(gfx.quit) end
  end
  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------
  function main()
    DATA.conf.dev_mode = 0
    DATA.conf.vrs = vrs
    ExtState_Load(DATA.conf)
    
    -- overwrite conf
    DATA.conf.min_vzoom = 0.02
    --DATA.conf.v_zoom_res = 300
                
    gfx.init(DATA.conf.mb_title..' '..DATA.conf.vrs,
                    300,--DATA.conf.wind_w,
                    200,--DATA.conf.wind_h,
                    DATA.conf.dock, 
                    DATA.conf.wind_x, 
                    DATA.conf.wind_y)
    
    -- init OBJ
    OBJ_SetColors(OBJ, DATA, GUI)
    
    run()  
  end
  
  --------------------------------------------------------------------  
  function Action_ReplaceFX(OBJ, DATA, GUI) 
    local plugintoreplace = DATA.conf.plugintoreplace
    local replaceto = DATA.conf.replaceto:gsub('%(.-%)', '') 
    DATA_CollectFXData(OBJ, DATA, GUI) 
    if plugintoreplace == '' or replaceto=='' then return end
    if not DATA.FX[plugintoreplace] then return end 
    Undo_BeginBlock2( 0 )
    
    for i=1, #DATA.FX[plugintoreplace] do 
      
      local tr = DATA.FX[plugintoreplace][i].tr_ptr
      -- add new plugin
        local new_pos = TrackFX_AddByName( tr, replaceto, false, -1 )
        if new_pos == -1 then goto skipnextfx end
      -- shift under existed
        local ret, _, fxpos = VF_GetFXByGUID(DATA.FX[plugintoreplace][i].GUID, tr)
        TrackFX_CopyToTrack( tr, new_pos, tr, fxpos+1, true )
      -- remove old plugin
        TrackFX_Delete( tr, fxpos )
      ::skipnextfx::
    end
    Undo_EndBlock2( 0, 'MPL Replace FX', 0 )
  end
  ---------------------------------------------------
  function DATA_CheckUPD(OBJ, DATA, GUI)
    DATA.SCC =  GetProjectStateChangeCount( 0 )
    DATA.editcurpos =  GetCursorPosition()
    local ret = (DATA.lastSCC and DATA.lastSCC~=DATA.SCC )
     or (DATA.last_editcurpos and DATA.last_editcurpos~=DATA.editcurpos )
                 
    DATA.lastSCC = DATA.SCC
    DATA.last_editcurpos=DATA.editcurpos
    return ret
  end
  ---------------------------------------------------
  function DATA_Collect(OBJ, DATA, GUI)
     DATA.plugins = {}
     local res_path = GetResourcePath()
     DATA_EnumeratePlugins_Sub(DATA.plugins, res_path, '/reaper-vstplugins.ini', '%=.-%,.-%,(.*)', 0)
     DATA_EnumeratePlugins_Sub(DATA.plugins, res_path, '/reaper-vstplugins64.ini', '%=.-%,.-%,(.*)', 0)
     DATA_EnumeratePlugins_Sub(DATA.plugins, res_path, '/reaper-dxplugins.ini',  'Name=(.*)', 2)  
     DATA_EnumeratePlugins_Sub(DATA.plugins, res_path, '/reaper-dxplugins64.ini',  'Name=(.*)', 2) 
     DATA_EnumeratePlugins_Sub(DATA.plugins, res_path, '/reaper-auplugins.ini',  'AU%s%"(.-)%"', 3) 
     DATA_EnumeratePlugins_Sub(DATA.plugins, res_path, '/reaper-auplugins64.ini',  'AU%s%"(.-)%"', 3)  
     DATA_EnumeratePlugins_Sub(DATA.plugins, res_path, '/reaper-jsfx.ini',  'NAME (.-)%s', 4)  
     
     DATA_CollectFXData(OBJ, DATA, GUI)
   end
   --------------------------------------------------------------------
   function DATA_EnumeratePlugins_Sub(plugs_t, res_path, file, pat, plugtype)
     -- validate file
       local fp = res_path..file
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
   function DATA_CollectFXData(OBJ, DATA, GUI)
     DATA.FX = {}
     for i = 1, CountTracks()  do
       local tr = GetTrack(0,i-1)
       local fxcnt = TrackFX_GetCount( tr )
       for fx=1, fxcnt do
         local retval, buf = reaper.TrackFX_GetFXName( tr, fx-1, '' )
         if not DATA.FX[buf] then DATA.FX[buf] = {} end 
         local GUID =  TrackFX_GetFXGUID( tr, fx-1 )
         DATA.FX[buf][#DATA.FX[buf]+1] = {tr_ptr=tr,
                               name=buf,
                               pos0based=fx-1,
                               GUID = GUID  }
       end
     end
   end
     ---------------------------------------------------------------------
     function OBJ_SetColors(OBJ, DATA, GUI)
       OBJ.colors = {--backgr = '#3f484d', hardcoded
       
                     
                     
                     }
     end
    ---------------------------------------------------
     function OBJ_init(OBJ, DATA, GUI)
       
         -- globals
       GUI.offs = 5 
       GUI.but_w = 100
       GUI.grad_sz = 200
       
         -- font
       GUI.fontsz = VF_CalibrateFont(21)
       GUI.fontsz2 = VF_CalibrateFont( 19)
       GUI.fontsz3 = VF_CalibrateFont( 15)
       GUI.fontsz4 = VF_CalibrateFont( 13)
       
       -- but
       OBJ.frame_a_normal = 0.2
       OBJ.frame_a_selected = 0.7
       
       
       
     end
   
    ---------------------------------------------------   
     function OBJ_main(OBJ, DATA, GUI)
       local wbut = gfx.w
       local hbut = math.floor(gfx.h/4)
       local filt = '<empty>'
       if DATA.conf.filter ~= '' then filt = DATA.conf.filter end
       OBJ.filter = {  otype = 'main',
                   grad_back = true,
                   x = 0,
                   y = 0,
                   w = wbut,
                   h = hbut,
                   txt= 'Filter:\n'..filt,
                   txt_flags = 1|4,
                   fontsz = GUI.fontsz2,
                   func_Ltrig =  function() 
                                   local retval, retvals_csv = GetUserInputs( 'ReplaceFX filter', 1, '', DATA.conf.filter )
                                   if retval then
                                     DATA.conf.filter = retvals_csv
                                     OBJ.refresh.GUIcontrols = true
                                     OBJ.refresh.data = true
                                     OBJ.refresh.conf = true 
                                   end 
                                 end
                     }
       OBJ.fxinproject = {  otype = 'main',
                   grad_back = true,
                   x = 0,
                   y = hbut,
                   w = wbut,
                   h = hbut,
                   txt= 'FX in project:\n'..DATA.conf.plugintoreplace,
                   txt_flags = 1|4,
                   fontsz = GUI.fontsz2,
                   func_Ltrig =  function()
                                   local fxtable = {}
                                   
                                   for key in spairs(DATA.FX) do
                                     local filt = DATA.conf.filter
                                     if filt =='' or (filt ~= '' and key:gsub('%p',''):lower():match(filt:gsub('%p',''):lower())) then 
                                       local state = key==DATA.conf.plugintoreplace
                                       fxtable[#fxtable+1] = {str = key..' ('..#DATA.FX[key]..' instances)',
                                                             state=state,
                                                             func = function()
                                                                       DATA.conf.plugintoreplace = key
                                                                       OBJ.refresh.GUIcontrols = true
                                                                       OBJ.refresh.data = true
                                                                       OBJ.refresh.conf = true 
                                                                     end}
                                     end
                                   end
                                   Menu(MOUSE,fxtable)
                                 end
                     }    
                     
       OBJ.replaceby = {  otype = 'main',
                   grad_back = true,
                   x = 0,
                   y = hbut*2,
                   w = wbut,
                   h = hbut,
                   txt= 'Replace to:\n'.. DATA.conf.replaceto,
                   txt_flags = 1|4,
                   fontsz = GUI.fontsz2,
                   func_Ltrig =  function()
                                   local fxtable = {}
                                   for i=1, #DATA.plugins do
                                     local filt = DATA.conf.filter
                                     local key = DATA.plugins[i].name
                                     local state = key ==DATA.conf.replaceto
                                     if filt =='' or (filt ~= '' and key:gsub('%p',''):lower():match(filt:gsub('%p',''):lower())) then 
                                       fxtable[#fxtable+1] = {str = key,
                                                             state=state,
                                                             func = function()
                                                                       DATA.conf.replaceto = key
                                                                       OBJ.refresh.GUIcontrols = true
                                                                       OBJ.refresh.data = true
                                                                       OBJ.refresh.conf = true 
                                                                     end}
                                     end
                                   end
                                   Menu(MOUSE,fxtable)
                                 end
                     }    
   OBJ.goexecute = {  otype = 'main',
                   grad_back = true,
                   x = 0,
                   y = hbut*3,
                   w = wbut,
                   h = hbut,
                   txt= 'Replace',
                   txt_flags = 1|4,
                   txt_col = '#ff3232',
                   fontsz = GUI.fontsz,
                   func_Ltrig =  function() 
                                   Action_ReplaceFX(OBJ, DATA, GUI)
                                 end
                     }                  
     end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_LoadLibraries') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then VF_LoadLibraries() main() end
  end

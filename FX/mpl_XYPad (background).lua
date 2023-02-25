-- @description XYPad
-- @version 2.02
-- @author MPL 
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # change radius of active area
  
  version = 2.02
  
  -- NOT gfx NOT reaper NOT MOUSE NOT function 
  ---------------------------------------------------        
  function VF_DATA_UpdateWrite(MOUSE,OBJ,DATA) 
    MPL_XYP_CalcPointsValues(MOUSE,OBJ,DATA)
    -- apply values
      for i = 1, DATA.conf.pointscnt do 
        if DATA.custom.points[i] and  DATA.custom.points[i].isvalid then
          local value = VF_lim(DATA.custom.points[i].OFS + DATA.custom.points[i].val * DATA.custom.points[i].SCL)
          if DATA.custom.points[i].INV == 1 then value = 1-value end
          TrackFX_SetParamNormalized( DATA.custom.points[i].TR, 
                                      DATA.custom.points[i].FXID, 
                                      DATA.custom.points[i].PID, 
                                      value)
        end
      end
    
  end 
-------------------------------------------------
  function ExtState_Def()  
    local t= {
    
            -- globals
            mb_title = 'XYPad',
            ES_key = 'MPL_XYPad',
            wind_x =  50,
            wind_y =  50,
            wind_w =  500,
            wind_h =  500,
            dock =    0, 
            
            xpos=0.5,
            ypos=0.5,
            
            pointscnt = 4,
            }
    return t
  end
  ------------------------------------------------------------------
  function VF_run_initVars_overwrite()
    DATA.confproj.FXDATA2 = ''
    DATA.confproj.FXDATA2_PLST = ''
  end
  ------------------------------------------------------------------
  function VF_DATA_Init(MOUSE,OBJ,DATA)
    DATA.custom = {points={}} 
  end
  ------------------------------------------------------------------
  function VF_DATA_UpdateAlways(MOUSE,OBJ,DATA)
    if DATA.refresh.project_change&16==16 then 
      DATA.refresh.data = DATA.refresh.data|1|2|4 
      DATA.refresh.GUI = DATA.refresh.GUI|2|4
    end
  end
  ------------------------------------------------------------------
  function VF_DATA_UpdateRead(MOUSE,OBJ,DATA)
    for i = 1, DATA.conf.pointscnt do
      DATA.custom.points[i] = {}
      local id_pat = 'PT'..tostring(i)..'_'
      if DATA.confproj[id_pat..'ENABLED'] then
        local ret = VF2_ValidateFX(DATA.confproj[id_pat..'TRGUID'],DATA.confproj[id_pat..'FXGUID'])
        if ret then 
          DATA.custom.points[i].isvalid = true
          DATA.custom.points[i].ENABLED = DATA.confproj[id_pat..'ENABLED']
          DATA.custom.points[i].FXGUID = DATA.confproj[id_pat..'FXGUID']
          DATA.custom.points[i].TRGUID = DATA.confproj[id_pat..'TRGUID']
          local tr = VF_GetTrackByGUID(DATA.custom.points[i].TRGUID)
          DATA.custom.points[i].TR = tr
          DATA.custom.points[i].PID = DATA.confproj[id_pat..'PID']
          DATA.custom.points[i].INV = DATA.confproj[id_pat..'INV']
          DATA.custom.points[i].SCL = DATA.confproj[id_pat..'SCL']
          DATA.custom.points[i].OFS = DATA.confproj[id_pat..'OFS']
          DATA.custom.points[i].FXID = DATA.confproj[id_pat..'FXID']
          DATA.custom.points[i].INITVAL = DATA.confproj[id_pat..'INITVAL']
          DATA.custom.points[i].INITVALF = DATA.confproj[id_pat..'INITVALF']
          
          
          local retval, trname = reaper.GetTrackName( tr )
          local retval, fxname = reaper.TrackFX_GetFXName( tr, DATA.custom.points[i].FXID, '' )
          local retval, paramname = reaper.TrackFX_GetParamName( tr, DATA.custom.points[i].FXID, DATA.custom.points[i].PID, '' )
          
          DATA.custom.points[i].info = trname..'/'..fxname..'/'..paramname
        end
      end
    end
  end 
  ---------------------------------------------------    
  function MPL_XYP_CalcPointsValues(MOUSE,OBJ,DATA)
    local x = DATA.conf.xpos
    local y = DATA.conf.ypos 
    for i = 1, DATA.conf.pointscnt do if DATA.custom.points[i] then DATA.custom.points[i].val = MPL_XYP_GetValue(MOUSE,OBJ,DATA,i) end end
  end
  ---------------------------------------------------      
  function MPL_XYP_GetValue(MOUSE,OBJ,DATA,i) 
    if not (OBJ.manual and OBJ.field and OBJ['Apoint'..i]) then return end
    
    local r_small = DATA.customGUI.fieldside/2-DATA.customGUI.point_sz/2
    local r_circle =DATA.customGUI.fieldside-OBJ['Apoint'..i].w--math.sqrt(r_small^2+r_small^2)
    
    local ptx = OBJ['Apoint'..i].x + OBJ['Apoint'..i].w/2
    local pty = OBJ['Apoint'..i].y + OBJ['Apoint'..i].h/2
    local xman = OBJ.manual.x +OBJ.manual.w/2-ptx
    local yman = OBJ.manual.y +OBJ.manual.h/2-pty
    local val = math.sqrt(xman^2+yman^2) / r_circle
    return 1-VF_lim(VF_math_Qdec(val,6)) 
  end
  --------------------------------------------------- 
  function MPL_XYP_PointMenu(MOUSE,OBJ,DATA,ptid) 
    local LTP_t = VF2_GetLTP(MOUSE,OBJ,DATA)
    local param_txt = '[tweak some plugin parameter]'
    local point_t
    if LTP_t then 
      param_txt =  LTP_t.trname..' / '..LTP_t.fxname..' / '..LTP_t.paramname
      param_txt = param_txt:gsub('[<>!#|]','')
      
      point_t = {ENABLED = 1,
                      FXGUID = LTP_t.fxGUID:gsub('[%{}]',''), 
                      TRGUID=LTP_t.trGUID,
                      PID=LTP_t.paramnumber,
                      FXID=LTP_t.fxnumber,
                      INV = 0,
                      OFS = 0,
                      SCL = 1,
                      INITVAL = LTP_t.paramformat,
                      INITVALF = LTP_t.paramval
                    }
                    
    end 
    return {
              { str='Get last touched parameter: '..param_txt,
                hidden = LTP_t==nil,
                  func = function() 
                            if not point_t then return end
                            for key in spairs(point_t) do DATA.confproj['PT'..ptid..'_'..key] = point_t[key] end
                          end
              },
              VF_MenuReturnToggle(MOUSE,OBJ,DATA,'Invert parameter', DATA.confproj, 'PT'..ptid..'_INV', 1),
              VF_MenuReturnUserInput(MOUSE,OBJ,DATA,'Offset', 'Offset (0-1)', DATA.confproj, 'PT'..ptid..'_OFS', 1),
              VF_MenuReturnUserInput(MOUSE,OBJ,DATA,'Scale', 'Scale (0-1)',DATA.confproj, 'PT'..ptid..'_SCL', 1),
            }
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Init(MOUSE,OBJ,DATA)
    local options_t = {{ str = '|#Options'},    
                        { str = 'Points count: 4',
                          state=DATA.conf.pointscnt==4,
                          func = function() DATA.conf.pointscnt = 4 end,
                        },
                        { str = 'Points count: 8',
                          state=DATA.conf.pointscnt==8,
                          func = function() DATA.conf.pointscnt = 8 end,
                        }                        
                      }
    OBJ_Buttons_InitMenuTop(MOUSE,OBJ,DATA,options_t)
    
    DATA.customGUI = {}
    DATA.customGUI.point_sz = 50 
    DATA.customGUI.man_sz = 20
    DATA.customGUI.activerect = 5
    DATA.customGUI.offs =5 
    DATA.customGUI.fieldside = math.min(gfx.w-DATA.customGUI.point_sz*2, gfx.h-DATA.GUIvars.menu_h-DATA.customGUI.point_sz*2)
    
    OBJ.infobar = {  is_button = true,
                   x= DATA.GUIvars.menu_w,
                   y = 0,
                   w = gfx.w-DATA.GUIvars.menu_w,
                   h = DATA.GUIvars.menu_h,
                  ignore_mouse = true,
                  fontsz = 17
                   }    
    
    OBJ.manual = {  is_button = true,
                    w =          DATA.customGUI.man_sz,
                    h =          DATA.customGUI.man_sz,
                    frame_a = 0.52,
                    grad_back_a = 1,
                    selected = true,
                    ignore_mouse = true,
                   } 
                   
    OBJ.field = {  is_button  =true,
                    x = gfx.w/2-DATA.customGUI.fieldside/2,
                    y = 0.5*DATA.GUIvars.menu_h+ (gfx.h - DATA.customGUI.fieldside)/2  ,
                    w = DATA.customGUI.fieldside,
                    h = DATA.customGUI.fieldside,
                    preventregularselection = true,
                    --undermouse_frame_a = 0,
                    grad_back_a = 0,
                    func_Ldrag = function() 
                                    DATA.conf.xpos = lim((MOUSE.x - OBJ.field.x) / OBJ.field.w)
                                    DATA.conf.ypos = lim((MOUSE.y - OBJ.field.y) / OBJ.field.h)  
                                    DATA.refresh.GUI = DATA.refresh.GUI|4 -- upd buttons
                                    DATA.refresh.data = DATA.refresh.data|8 -- app data
                                 end,
                   func_Lrelease = function() DATA.refresh.conf = DATA.refresh.conf |1  end
                   } 
                   
                   
    local angle_step =360/ DATA.conf.pointscnt
    local startangle = -135
    local r_small = DATA.customGUI.fieldside/2-DATA.customGUI.man_sz/2--+DATA.customGUI.point_sz/2
    local r_small2 = DATA.customGUI.fieldside/2+DATA.customGUI.point_sz/2
    DATA.customGUI.r_circle =math.sqrt(r_small^2+r_small^2)
    DATA.customGUI.r_circle2 =r_small2--math.sqrt(r_small2^2+r_small2^2)
    
    for i = 1, 100 do OBJ['Apoint'..i] = nil OBJ['ApointShow'..i] = nil end -- reset possible points after change points count
    for i = 1, 100 do OBJ['Apoint'..i] = nil OBJ['ApointShowActive'..i] = nil end -- reset possible points after change points count
    for i = 1, DATA.conf.pointscnt do
      local ang = math.floor(startangle-angle_step*(i-1))
      local ptx = OBJ.field.x + DATA.customGUI.fieldside/2 + DATA.customGUI.r_circle*math.sin(math.rad(ang))-DATA.customGUI.point_sz/2
      local pty = OBJ.field.y + DATA.customGUI.fieldside/2 + DATA.customGUI.r_circle*math.cos(math.rad(ang))-DATA.customGUI.point_sz/2
      OBJ['Apoint'..i] = {  --is_button = true,
                        x = ptx,
                        y = pty,
                        w = DATA.customGUI.point_sz,
                        h = DATA.customGUI.point_sz,
                        txt= i,
                        ignore_mouse = true,
                        func_Rtrig = function()  
                                       --local t = OBJ_main_PointMenu(OBJ, DATA, GUI,i)
                                       --Menu(MOUSE,t)
                                     end,
                       }
      local ptx = OBJ.field.x + DATA.customGUI.fieldside/2 + DATA.customGUI.r_circle2*math.sin(math.rad(ang))-DATA.customGUI.point_sz/2
      local pty = OBJ.field.y + DATA.customGUI.fieldside/2 + DATA.customGUI.r_circle2*math.cos(math.rad(ang))-DATA.customGUI.point_sz/2
      OBJ['ApointShow'..i] = {  is_button = true,
                        x = ptx,
                        y = pty,
                        w = DATA.customGUI.point_sz,
                        h = DATA.customGUI.point_sz,
                        selected = true,
                        preventregularselection = true,
                        txt= i,
                        fontsz = 17,
                        func_undermouse = function() 
                                            if DATA.custom.points[i] and DATA.custom.points[i].info then 
                                              DATA.custom.infobar='['..i..'] '..DATA.custom.points[i].info 
                                             else 
                                              DATA.custom.infobar='['..i..'] no attached parameter'
                                            end
                                          end,
                        func_Rtrig = function() VF_MOUSE_menu(MOUSE,OBJ,DATA,MPL_XYP_PointMenu(MOUSE,OBJ,DATA,i))  end,
                       } 
      --OBJ['ApointShow'..i].func_onptrcatch = OBJ['ApointShow'..i].func_Ltrig
      OBJ['ApointShowActive'..i] = {  is_button = true,
                        x = ptx+DATA.customGUI.activerect,
                        y = pty+DATA.customGUI.activerect,
                        w = DATA.customGUI.activerect,
                        h = DATA.customGUI.activerect,
                        selected = true,
                        selection_a = 1,
                        grad_back_a = 0,
                        func_Ltrig = function()  end,
                       }                        
                       
    end   
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Update(MOUSE,OBJ,DATA) 
    OBJ.infobar.txt = DATA.custom.infobar or ''
    -- manual update
      local man_x = OBJ.field.x+(OBJ.field.w-DATA.customGUI.man_sz)* DATA.conf.xpos
      local man_y = OBJ.field.y+(OBJ.field.h-DATA.customGUI.man_sz) * DATA.conf.ypos 
      OBJ.manual.x=man_x
      OBJ.manual.y=man_y
      
      for i = 1, DATA.conf.pointscnt do 
        if    DATA.custom.points 
          and DATA.custom.points[i] 
          and DATA.custom.points[i].val 
          then 
           OBJ['ApointShow'..i].selection_a = DATA.custom.points[i].val*0.5+0.2  
        end
        
        if OBJ['ApointShowActive'..i] then
          if DATA.custom.points[i].isvalid == true then 
            OBJ['ApointShowActive'..i].selection_a = 1
            OBJ['ApointShowActive'..i].selection_col = DATA.GUIvars.colors.green
           else 
            OBJ['ApointShowActive'..i].selection_a = 0.15
            OBJ['ApointShowActive'..i].selection_col = nil
          end
        end
        
      end
      
      
  end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' if reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end else reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.5) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    VF_run_initVars() 
    if VF_run_initVars_overwrite then VF_run_initVars_overwrite() end
    DATA.conf.vrs = version 
    VF_run_init()  
  end end  
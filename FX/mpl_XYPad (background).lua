-- @description XYPad
-- @version 2.0
-- @author MPL 
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--  + init

  


  local vrs = 'v2.0'
  -- NOT gfx NOT reaper NOT GUI NOT MOUSE NOT function
  
  --  INIT -------------------------------------------------
   local OBJ = {refresh = { GUIcom = true,
                            GUIback = false, 
                            GUIcontrols = false,
                            conf = false,
                            data = true,
                            test=true,
                          }
                }
  local GUI = {}
   DATA = {       conf = {},
                  project={}}
              
 
  ---------------------------------------------------
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
            
            mode=0, -- 0 parameters 1 all params per plugin
            pointscnt = 4,
            
            xpos=0.5,
            ypos=0.5,
            
            v_anglediff_piratio = 2,
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
        if OBJ.refresh.data == 2 then DATA_WriteProj(OBJ, DATA, GUI) OBJ.refresh.data = 1 end
        if OBJ.refresh.data == 1 then DATA_ReadProj(OBJ, DATA, GUI) end
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
        DATA_CalcPointsValues(OBJ, DATA, GUI) 
        OBJ_main(OBJ, DATA, GUI, true)--2nd pass
        GUI_DrawMain(OBJ, DATA, GUI) 
        OBJ.refresh.GUIcontrols = false
      end
      
    if OBJ.refresh.test ==true then  
      OBJ.refresh.test = nil
    end
    -- draw stuff
      GUI_draw(OBJ, DATA, GUI)
      
    -- exit
      if MOUSE.char >= 0 and MOUSE.char ~= 27 then defer(run) else atexit(gfx.quit) end
  end
  
--------------------------------------------------------------------
  function main()
    DATA.conf.dev_mode = 0
    DATA.conf.vrs = vrs
    ExtState_Load(DATA.conf)
     
    gfx.init(DATA.conf.mb_title..' '..DATA.conf.vrs,
                    DATA.conf.wind_w,
                    DATA.conf.wind_h,
                    DATA.conf.dock, 
                    DATA.conf.wind_x, 
                    DATA.conf.wind_y)
    
    -- init OBJ
    OBJ_SetColors(OBJ, DATA, GUI)
    DATA_ReadProj(OBJ, DATA, GUI)
    run()  
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
  function DATA_WriteProj(OBJ, DATA, GUI)
    local str = ''
    str = str..'\nPTCNT '..DATA.project.pointscnt
    
    -- mode 0
      for i = 1, 100 do
        if DATA.project['pt'..i] then 
          str = str..'\nPT'..i
            ..' '..DATA.project['pt'..i].enabled
            ..' {'..DATA.project['pt'..i].fxGUID:gsub('[%{%}]','')..'}'
            ..' {'..DATA.project['pt'..i].trGUID:gsub('[%{%}]','')..'}'
            ..' '..DATA.project['pt'..i].paramnumber
            ..' '..DATA.project['pt'..i].i_inv
            ..' '..DATA.project['pt'..i].i_offs
            ..' '..DATA.project['pt'..i].i_scale
        end
      end
      SetProjExtState( 0, 'MPL_XYPad', 'FXDATA2', str )
      
    -- mode 1
    local str = ''
    str = str..'\nPSTCNT '..DATA.project.plst_cnt
          
      for i = 1, 100 do
        if DATA.project['plst'..i] then 
          str = str..'\nPST'..i
            ..' '..DATA.project['plst'..i].enabled
            ..' {'..DATA.project['plst'..i].fxGUID:gsub('[%{%}]','')..'}'
            ..' {'..DATA.project['plst'..i].trGUID:gsub('[%{%}]','')..'}'
            ..' {'..DATA.project['plst'..i].param_str:gsub('[%{%}]','')..'}'
        end
      end
      SetProjExtState( 0, 'MPL_XYPad', 'FXDATA2_plst', str )
  end
  ---------------------------------------------------
  function DATA_ReadProj_IsValidData(fxGUID,trGUID,paramnumber)
    local tr = VF_GetTrackByGUID(trGUID)
    if tr then
      local ret, tr, fxnumber = VF_GetFXByGUID(fxGUID, tr) 
      if not tr then return end
      local ret, paramname 
      if paramnumber then ret, paramname = TrackFX_GetParamName( tr, fxnumber, paramnumber, '') end
      local ret, fxname = TrackFX_GetFXName( tr, fxnumber, '' )
      local retval, trname = reaper.GetTrackName( tr )
      if ret then return true,tr, fxnumber, trname,fxname,paramname  end
    end
  end
  ---------------------------------------------------
  function DATA_ReadProj(OBJ, DATA, GUI)
    DATA.project = {} 
    DATA.project.pointscnt = DATA.conf.pointscnt
    DATA.project.plst_cnt = DATA.conf.pointscnt
    DATA_ReadProj_mode0(OBJ, DATA, GUI)
    DATA_ReadProj_mode1(OBJ, DATA, GUI)
  end
  ---------------------------------------------------
  function DATA_ReadProj_mode0(OBJ, DATA, GUI)
    local retval, val = reaper.GetProjExtState(0, 'MPL_XYPad', 'FXDATA2' )
    if retval~=0 then
      for chunk in val:gmatch('[^\r\n]+') do  
        -- points chunks
          if chunk:match('PT%d+') then 
            local i,enabled,fxGUID,trGUID,paramnumber, i_inv, i_offs, i_scale = 
              chunk:match('PT(%d+) (%d+) %{(.-)%} %{(.-)%} (%d+) (%d+) (%d+) (%d+)')
            if i then 
              local isvalid, tr0, fx,trname,fxname,paramname = DATA_ReadProj_IsValidData(fxGUID,trGUID,paramnumber)
              DATA.project['pt'..i] = {
                                        enabled=tonumber(enabled),
                                        fxGUID=fxGUID,
                                        trGUID=trGUID,
                                        paramnumber=tonumber(paramnumber),
                                        
                                        p_isvalid = isvalid,
                                        p_trptr = tr0,
                                        p_fxid = fx,
                                        p_trname=trname,
                                        p_fxname=fxname,
                                        p_paramname=paramname,
                                        
                                        i_inv = tonumber(i_inv),
                                        i_offs = tonumber(i_offs),
                                        i_scale = tonumber(i_scale),
                                      } 
              
            end
          end
          
        -- various params
          if chunk:match('PTCNT (%d+)') then DATA.project.pointscnt = tonumber(chunk:match('PTCNT (%d+)')) end
        
      end
    end
  end
  ---------------------------------------------------
  function DATA_ReadProj_mode1(OBJ, DATA, GUI)
    local retval, val = reaper.GetProjExtState(0, 'MPL_XYPad', 'FXDATA2_plst')
    if retval~=0 then
      for chunk in val:gmatch('[^\r\n]+') do  
        -- points chunks
          if chunk:match('PST%d+') then 
            local i,enabled,fxGUID,trGUID, param_str = chunk:match('PST(%d+) (%d+) %{(.-)%} %{(.-)%} %{(.-)%}')
            if i then 
              local isvalid, tr0, fx,trname,fxname = DATA_ReadProj_IsValidData(fxGUID,trGUID)
              local stateparams = {}
              for val in param_str:gmatch('[^%s]+') do stateparams[#stateparams+1] = tonumber(val) end
              DATA.project['plst'..i] = {
                                        enabled=tonumber(enabled),
                                        fxGUID=fxGUID,
                                        trGUID=trGUID,
                                        param_str=param_str,
                                        
                                        p_isvalid = isvalid,
                                        p_trptr = tr0,
                                        p_fxid = fx,
                                        p_trname=trname,
                                        p_fxname=fxname,
                                        p_stateparams = stateparams
                                        
                                      } 
              
            end
          end
          
        -- various params
          if chunk:match('PSTCNT (%d+)') then DATA.project.plst_cnt = tonumber(chunk:match('PSTCNT (%d+)')) end
        
      end
    end
    
  end
  ---------------------------------------------------------------------
     function OBJ_SetColors(OBJ, DATA, GUI)
       OBJ.colors = {--backgr = '#3f484d', hardcoded
                        mode1_green = '17B025',
                        mode2_blue = '1792B0',
                        
                        pt_active = '24C800',
                        plst_active = '005EC8',

                     
                     
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
       
       OBJ.menuw = 30
       OBJ.buth = 30
       OBJ.point_sz = 30
       --[[OBJ.info_w = 150
       OBJ.info_h = 40]]
       OBJ.man_sz = 20
       
       
     end
---------------------------------------------------      
  function DATA_GetValue(OBJ, DATA, GUI,i) 
    local r =math.floor((math.min(OBJ.field.w,OBJ.field.h)-GUI.offs*2)/2) 
    local x = OBJ.manual.x - OBJ.field.w/2 - OBJ.field.x
    local y = OBJ.manual.y - OBJ.field.h/2 - OBJ.field.y
    local cur_r = math.sqrt(x^2+y^2) 
    local pt_angle = math.atan(OBJ['Apoint'..i].y- OBJ.field.h/2 - OBJ.field.y, OBJ['Apoint'..i].x- OBJ.field.w/2 - OBJ.field.x)
    local man_angle = math.atan(OBJ.manual.y - OBJ.field.y - OBJ.field.h/2, OBJ.manual.x - OBJ.field.x - OBJ.field.w/2 )
    local ang_diff = math.abs(man_angle-pt_angle)
    if ang_diff > math.pi then ang_diff = math.abs(ang_diff - math.pi*2) end
    local ang_diff_scaled = lim(ang_diff / math.pi*DATA.conf.v_anglediff_piratio)
    local radius_scale = lim(cur_r / r) 
    return radius_scale * (1- ang_diff_scaled)
  end
---------------------------------------------------        
  function DATA_Perform_Adjustment(OBJ, DATA, GUI) 
  
    if DATA.conf.mode == 0 then
      for i = 1, DATA.project.pointscnt do 
        if DATA.project['pt'..i] and DATA.project['pt'..i].p_isvalid and DATA.point_values and DATA.point_values[i] then
          local value = DATA.point_values[i]
          if DATA.project['pt'..i].i_inv == 1 then value = 1-value end
          TrackFX_SetParamNormalized( DATA.project['pt'..i].p_trptr, DATA.project['pt'..i].p_fxid, DATA.project['pt'..i].paramnumber, DATA.point_values[i])
        end
      end
    end
    
    if DATA.conf.mode == 1 then 
      local params_cnt for state = 1, DATA.project.plst_cnt do if DATA.project['plst'..state] then params_cnt = #DATA.project['plst'..state].p_stateparams break end end
      if not params_cnt then return end 
      local firstactivestate for state = 1, DATA.project.plst_cnt do if DATA.project['plst'..state] then firstactivestate = state break end end
      if not firstactivestate then return end
      
      for i = 1, params_cnt-1 do 
        local rmsval = 0
        local cnt = 0
        for state = 1, DATA.project.plst_cnt do 
          if DATA.project['plst'..state] then 
            cnt = cnt + 1
            rmsval = rmsval + DATA.project['plst'..state].p_stateparams[i]
          end
        end
        rmsval = rmsval / cnt 
        
        local val = rmsval
        for state = 1, DATA.project.plst_cnt do 
          if DATA.project['plst'..state] then 
            val = val + (DATA.project['plst'..state].p_stateparams[i] - rmsval) * DATA.point_values[state]
          end
        end
        
        -- 
        TrackFX_SetParamNormalized( DATA.project['plst'..firstactivestate].p_trptr, 
        DATA.project['plst'..firstactivestate].p_fxid, 
        i-1, 
        val) 
      end
      
    end
  end
---------------------------------------------------    
  function DATA_CalcPointsValues(OBJ, DATA, GUI)
    DATA.point_values = {}
    
    local x = DATA.conf.xpos
    local y = DATA.conf.ypos
    
    if DATA.conf.mode == 0 then 
      local cnt_active = 0
      for i = 1, DATA.project.pointscnt do if DATA.project['pt'..i] and DATA.project['pt'..i].p_isvalid then cnt_active = cnt_active + 1 end end
      if cnt_active <2 then return end
      for i = 1, DATA.project.pointscnt do 
        if DATA.project['pt'..i] and DATA.project['pt'..i].p_isvalid and OBJ['Apoint'..i]then
          DATA.point_values[i] = DATA_GetValue(OBJ, DATA, GUI,i) 
        end
      end
    end
    
    if DATA.conf.mode == 1 then 
      local cnt_active = 0
      for i = 1, DATA.project.plst_cnt do if DATA.project['plst'..i] and DATA.project['plst'..i].p_isvalid then cnt_active = cnt_active + 1 end end
      if cnt_active <2 then return end
      for i = 1, DATA.project.plst_cnt do 
        if DATA.project['plst'..i] and DATA.project['plst'..i].p_isvalid and OBJ['Apoint'..i]then DATA.point_values[i] = DATA_GetValue(OBJ, DATA, GUI,i)  end
      end 
      --if DATA.point_values then VF2_NormalizeT(DATA.point_values)  end
    end
    
  end
---------------------------------------------------   
  function OBJ_mainField(OBJ, DATA, GUI)
      OBJ.field = {  otype = 'main',
                      x = 0,
                      y = OBJ.buth,
                      w = gfx.w,
                      h = gfx.h-OBJ.buth,
                      fontsz = GUI.fontsz2,
                      frame_a = 0.3,
                      txt = '',
                      func_Ldrag2 = function() 
                                      DATA.conf.xpos = lim((MOUSE.x - OBJ.field.x) / OBJ.field.w)
                                      DATA.conf.ypos = lim((MOUSE.y - OBJ.field.y) / OBJ.field.h)
                                      
                                      DATA_CalcPointsValues(OBJ, DATA, GUI)  
                                      OBJ.refresh.GUIcontrols = true
                                      OBJ.refresh.data = true 
                                      DATA_Perform_Adjustment(OBJ, DATA, GUI)  
                                   end,
                     func_onrelease = function() OBJ.refresh.conf = true  end
                     } 
      OBJ.field.func_Ltrig = OBJ.field.func_Ldrag2  
      
      if DATA.conf.mode == 0 then
        if DATA.cur_point_id and DATA.project['pt'..DATA.cur_point_id] and DATA.project['pt'..DATA.cur_point_id].p_isvalid then 
          local infotxt = 'Point #'..DATA.cur_point_id
            ..'\n'..DATA.project['pt'..DATA.cur_point_id].p_trname
            ..'\n'..DATA.project['pt'..DATA.cur_point_id].p_fxname
            ..'\n'..DATA.project['pt'..DATA.cur_point_id].p_paramname
            ..'\n'..'Inverted: '..DATA.project['pt'..DATA.cur_point_id].i_inv
          OBJ.field.txt = infotxt
        end
      end
      
      OBJ.field_circle = {  otype = 'main',
                      x = OBJ.field.x+OBJ.field.w/2,
                      y = OBJ.field.y+OBJ.field.h/2,
                      w = gfx.w,
                      h = gfx.h-OBJ.buth,
                      ignore_mouse = true,
                      is_circle = true,
                      circle_r = math.floor((math.min(OBJ.field.w,OBJ.field.h)-GUI.offs*2)/2) ,
                      circle_a = 0.5
                     } 
                     
  end
  ---------------------------------------------------   
    function OBJ_mainMode(OBJ, DATA, GUI)
      local mode = 'Morph parameters states'
      local txt_col = OBJ.colors.mode1_green
      if DATA.conf.mode == 1 then mode = 'Morph plugin states' txt_col = OBJ.colors.mode2_blue end
      OBJ.mode = {  otype = 'main',
                 grad_back = true,
                 x = OBJ.menuw,
                 y = 0,
                 w = gfx.w-OBJ.menuw,
                 h = OBJ.buth-1,
                 txt= 'Mode: '..mode,
                 txt_flags = 1|4,
                 txt_col = txt_col,
                 fontsz = GUI.fontsz2,
                 func_Ltrig =  function() 
                                 DATA.conf.mode = math.abs(1-DATA.conf.mode)
                                OBJ.refresh.GUIcontrols = true
                                OBJ.refresh.data = true
                                OBJ.refresh.conf = true 
                                end 
                   }
  end
  ---------------------------------------------------   
    function OBJ_mainOptions(OBJ, DATA, GUI)
      OBJ.options = {  otype = 'main',
              grad_back = true,
              x = 0,
              y = 0,
              w = OBJ.menuw,
              h = OBJ.buth-1,
              txt= '>',
              txt_flags = 1|4,
              fontsz = GUI.fontsz2,
              func_Ltrig =  function() 
                             local t = 
                             {      
                                 { str = 'Cockos Forum thread|',
                                   func = function() Open_URL('https://forum.cockos.com/showthread.php?t=188335') end  } , 
                                 { str = 'Donate to MPL',
                                   func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
                                 { str = 'Contact: MPL VK',
                                   func = function() Open_URL('http://vk.com/mpl57') end  } ,     
                                 { str = 'Contact: MPL SoundCloud|',
                                   func = function() Open_URL('http://soundcloud.com/mpl57') end  } , 
                                     
                                 { str = '#Options'},    
                                 { str = 'Angle check pi ratio difference == 1',
                                   state = DATA.conf.v_anglediff_piratio == 1,
                                   func = function() DATA.conf.v_anglediff_piratio = 1 end},
                                 { str = 'Angle check pi ratio difference == 2',
                                   state = DATA.conf.v_anglediff_piratio == 2,
                                   func = function() DATA.conf.v_anglediff_piratio = 2 end } , 
                                 { str = 'Angle check pi ratio difference == 4',
                                   state = DATA.conf.v_anglediff_piratio == 4,
                                   func = function() DATA.conf.v_anglediff_piratio = 4 end } ,  
                                 { str = 'Points number: 4 ',
                                   state = DATA.project.pointscnt == 4,
                                   func = function() DATA.project.pointscnt = 4 DATA.project.plst_cnt = 4 end},                                        
                                 { str = 'Points number: 8 ',
                                   state = DATA.project.pointscnt == 8,
                                   func = function() DATA.project.pointscnt = 8 DATA.project.plst_cnt = 8 end},                                            
                                   
                             }
                             Menu(MOUSE,t)
                             OBJ.refresh.conf = true 
                             OBJ.refresh.GUIcontrols = 2 
                             OBJ.refresh.data = 2 
                           end
   }
   
   end
   --------------------------------------------------------------------- 
    function OBJ_mainManual(OBJ, DATA, GUI) 
     local man_x = OBJ.field.x+(OBJ.field.w-OBJ.man_sz)* DATA.conf.xpos
     local man_y = OBJ.field.y+(OBJ.field.h-OBJ.man_sz) * DATA.conf.ypos 
     OBJ.manual = {  otype =      'main',
                     grad_back =  true,
                     x =          man_x,
                     y =          man_y,
                     w =          OBJ.man_sz,
                     h =          OBJ.man_sz,
                     frame_a = 0.52,
                     fill_back = true,
                     fill_back_a = 0.5,
                     fill_back_col = 'E83C1A',
                     fontsz = GUI.fontsz2,
                     ignore_mouse = true,
                    }   
                    
  end
 --------------------------------------------------------------------- 
  function OBJ_main(OBJ, DATA, GUI, isminor)
    for i=1, 100 do OBJ['Apoint'..i] = nil end
    
    if not isminor then 
      OBJ_mainField(OBJ, DATA, GUI)
      OBJ_mainMode(OBJ, DATA, GUI)
      OBJ_mainOptions(OBJ, DATA, GUI)
      OBJ_mainManual(OBJ, DATA, GUI)
    end
    
    if DATA.conf.mode ==0 then OBJ_mainPoints_mode0(OBJ, DATA, GUI)  end
    if DATA.conf.mode ==1 then OBJ_mainPoints_mode1(OBJ, DATA, GUI)  end
  end
 --------------------------------------------------------------------- 
  function OBJ_mainPoints_mode0(OBJ, DATA, GUI)    
    local angle_step =360/ DATA.project.pointscnt
    local startangle = -135
    local r =math.floor((math.min(OBJ.field.w,OBJ.field.h)-GUI.offs*2)/2) 
                     
    for i = 1, DATA.project.pointscnt do
      local ang = math.floor(startangle-angle_step*(i-1))
      local ptx = lim(OBJ.field.x + OBJ.field.w/2 + r*math.sin(math.rad(ang))-OBJ.point_sz/2,OBJ.field.x,OBJ.field.x+OBJ.field.w-OBJ.point_sz)
      local pty = lim(OBJ.field.y + OBJ.field.h/2 + r*math.cos(math.rad(ang))-OBJ.point_sz/2,OBJ.field.y,OBJ.field.y+OBJ.field.h-OBJ.point_sz)
      local frame_col
      if DATA.project['pt'..i] and DATA.project['pt'..i].p_isvalid then frame_col = OBJ.colors.pt_active end
      local aval = 0 
      if DATA.point_values and DATA.point_values[i] then aval = DATA.point_values[i] end
      OBJ['Apoint'..i] = {  otype = 'main',
                        grad_back = true,
                        angle=ang,
                        x = ptx,
                        y = pty,
                        w = OBJ.point_sz,
                        h = OBJ.point_sz,
                        txt= i,
                        txt_flags = 1|4,
                        frame_a = 0.7,
                        frame_col = frame_col,
                        fontsz = GUI.fontsz2,
                        fill_back =  true,
                        fill_back_a = aval,
                        func_onptrcatch = function()  
                                        DATA.cur_point_id = i
                                        OBJ.refresh.GUIcontrols = true
                                      end,
                        func_Rtrig = function()  
                                       local t = OBJ_main_PointMenu(OBJ, DATA, GUI,i)
                                       Menu(MOUSE,t)
                                     end,
                       }
        local aval = 1-OBJ['Apoint'..i].fill_back_a
        if aval <0.4 then aval = 0 else aval = 1  end
        local r = math.floor(aval * 0xFF)
        OBJ['Apoint'..i].txt_col = string.format('%02X', r +(r <<8)+(r <<16))
      end 
    end
    
 --------------------------------------------------------------------- 
  function OBJ_mainPoints_mode1(OBJ, DATA, GUI)    
    local angle_step =360/ DATA.project.pointscnt
    local startangle = -135
    local r =math.floor((math.min(OBJ.field.w,OBJ.field.h)-GUI.offs*2)/2) 
                     
    for i = 1, DATA.project.plst_cnt do
      local ang = math.floor(startangle-angle_step*(i-1))
      local ptx = lim(OBJ.field.x + OBJ.field.w/2 + r*math.sin(math.rad(ang))-OBJ.point_sz/2,OBJ.field.x,OBJ.field.x+OBJ.field.w-OBJ.point_sz)
      local pty = lim(OBJ.field.y + OBJ.field.h/2 + r*math.cos(math.rad(ang))-OBJ.point_sz/2,OBJ.field.y,OBJ.field.y+OBJ.field.h-OBJ.point_sz)
      local frame_col
      if DATA.project['plst'..i] and DATA.project['plst'..i].p_isvalid then frame_col = OBJ.colors.plst_active end
               
      local aval = 0 
      if DATA.point_values and DATA.point_values[i] then aval = DATA.point_values[i] end
      OBJ['Apoint'..i] = {  otype = 'main',
                        grad_back = true,
                        angle=ang,
                        x = ptx,
                        y = pty,
                        w = OBJ.point_sz,
                        h = OBJ.point_sz,
                        txt= i,
                        txt_flags = 1|4,
                        frame_a = 0.7,
                        frame_col = frame_col,
                        fontsz = GUI.fontsz2,
                        fill_back =  true,
                        fill_back_a = aval,
                        func_onptrcatch = function()  
                                        DATA.cur_point_id = i
                                        OBJ.refresh.GUIcontrols = true
                                      end,
                        func_Rtrig = function()  
                                       local t = OBJ_main_PointMenu(OBJ, DATA, GUI,i)
                                       Menu(MOUSE,t)
                                     end,
                       }
        local aval = 1-OBJ['Apoint'..i].fill_back_a
        if aval <0.4 then aval = 0 else aval = 1  end
        local r = math.floor(aval * 0xFF)
        OBJ['Apoint'..i].txt_col = string.format('%02X', r +(r <<8)+(r <<16))
      end 
    end    
  --[[
  --------------------------------------------------------------------- 
   function OBJ_mainPoints_mode0(OBJ, DATA, GUI)    
       local angle_step =360/ DATA.project.pointscnt
       local startangle = -135
       local r =math.floor((math.min(OBJ.field.w,OBJ.field.h)-GUI.offs*2)/2) 
                      
       for i = 1, DATA.project.pointscnt do
         local ang = math.floor(startangle-angle_step*(i-1))
         local ptx = lim(OBJ.field.x + OBJ.field.w/2 + r*math.sin(math.rad(ang))-OBJ.point_sz/2,OBJ.field.x,OBJ.field.x+OBJ.field.w-OBJ.point_sz)
         local pty = lim(OBJ.field.y + OBJ.field.h/2 + r*math.cos(math.rad(ang))-OBJ.point_sz/2,OBJ.field.y,OBJ.field.y+OBJ.field.h-OBJ.point_sz)
         local frame_col
         if DATA.conf.mode ==0 and DATA.project['pt'..i] and DATA.project['pt'..i].p_isvalid then frame_col = OBJ.colors.pt_active end
         if DATA.conf.mode ==1 and DATA.project['plst'..i] and DATA.project['plst'..i].p_isvalid then frame_col = OBJ.colors.plst_active end
         
         OBJ['Apoint'..i] = {  otype = 'main',
                         grad_back = true,
                         angle=ang,
                         x = ptx,
                         y = pty,
                         w = OBJ.point_sz,
                         h = OBJ.point_sz,
                         txt= i,
                         txt_flags = 1|4,
                         frame_a = 0.7,
                         frame_col = frame_col,
                         fontsz = GUI.fontsz2,
                         fill_back =  true,
                         fill_back_a = 0,
                         func_onptrcatch = function()  
                                         DATA.cur_point_id = i
                                         OBJ.refresh.GUIcontrols = true
                                       end,
                         func_Rtrig = function()  
                                        local t = OBJ_main_PointMenu(OBJ, DATA, GUI,i)
                                        Menu(MOUSE,t)
                                      end,
                        }
       end 
       
       local max = 1
       if DATA.conf.mode ==1 then
         max = 0
         for i = 1, DATA.project.pointscnt do 
           if DATA.project['plst'..i] and DATA.project['plst'..i].p_isvalid then
             max = math.max(max, DATA_GetValue(OBJ, DATA, GUI,i) ) 
           end
         end
       end
       
       for i = 1, DATA.project.pointscnt do
         if DATA.conf.mode ==1 and DATA.project['plst'..i] and max > 0 then OBJ['Apoint'..i].fill_back_a = lim(DATA_GetValue(OBJ, DATA, GUI,i)  * 1/max) end
         if DATA.conf.mode ==0 and  DATA.project['pt'..i] and DATA.project['pt'..i].i_inv == 1 then OBJ['Apoint'..i].fill_back_a = 1-OBJ['Apoint'..i].fill_back_a end
         local aval = 1-OBJ['Apoint'..i].fill_back_a
         if aval <0.4 then aval = 0 else aval = 1  end
         local r = math.floor(aval * 0xFF)
         OBJ['Apoint'..i].txt_col = string.format('%02X', r +(r <<8)+(r <<16))
       end 
   end
   ]]
  ---------------------------------------------------------------------
  function OBJ_main_PointMenu(OBJ, DATA, GUI,ptid)
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
    local param_txt = '[nothing touched]'
    local tr, trGUID, fxGUID, param, paramname, ret, fxname
    if retval then 
      tr = CSurf_TrackFromID( tracknumber, false )
      trGUID = GetTrackGUID( tr )
      fxGUID = TrackFX_GetFXGUID( tr, fxnumber )
      local retval, buf = reaper.GetTrackName( tr )
      ret, paramname = TrackFX_GetParamName( tr, fxnumber, paramnumber, '')
      ret, fxname = TrackFX_GetFXName( tr, fxnumber, '' )
      if DATA.conf.mode == 0 then param_txt = fxname..' / '..paramname end
      if DATA.conf.mode == 1 then param_txt = buf..' / '..fxname end
    end
    
    if DATA.conf.mode == 0 then
      return {
                { str='Get last touched parameter: '..param_txt:gsub('[<>!#|]',''),
                  func = function() 
                            if not retval then return end
                            DATA.project['pt'..ptid] = {  enabled = 1,
                                                          fxGUID = fxGUID, 
                                                          trGUID=trGUID,
                                                          paramnumber=paramnumber,
                                                          i_inv = 0,
                                                          i_offs = 0,
                                                          i_scale = 1,
                                                        }
                            OBJ.refresh.data = 2
                            OBJ.refresh.GUIcontrols = true
                          end
                },
                { str='Invert parameter',
                  state = retval and DATA.project['pt'..ptid] and DATA.project['pt'..ptid].i_inv == 1,
                  hidden = not(retval and DATA.project['pt'..ptid]),
                  func = function() 
                            if not retval then return end
                            DATA.project['pt'..ptid].i_inv = math.abs(1-DATA.project['pt'..ptid].i_inv)
                            OBJ.refresh.data = 2
                            OBJ.refresh.GUIcontrols = true
                          end
                },                  
                { str='Clean parameter',
                  func = function() 
                            if not retval then return end
                            DATA.project['pt'..ptid] = nil
                            OBJ.refresh.data = 2
                            OBJ.refresh.GUIcontrols = true
                          end
                },                
            }
     else
      return {
                {str='Get last touched plugin state: '..param_txt:gsub('[<>!#|]',''),
                  func = function() 
                     if not retval then return end
                     local paramscnt = TrackFX_GetNumParams( tr, fxnumber )
                     local param_str = ''
                      for paramid = 1, paramscnt do 
                        param_str = param_str..' '..TrackFX_GetParamNormalized( tr, fxnumber, paramid-1) 
                      end
                     param_str = '{'..param_str:sub(2)..'}'
                     DATA.project['plst'..ptid] = {enabled = 1,
                                                   fxGUID = fxGUID, 
                                                   trGUID=trGUID,
                                                   param_str=param_str
                                                   
                                                 }
                                                 
                     OBJ.refresh.data = 2
                     OBJ.refresh.GUIcontrols = true
                  
                  end
                },
                { str='Clean parameter',
                  func = function() 
                            if not retval then return end
                            DATA.project['plst'..ptid] = nil
                            OBJ.refresh.data = 2
                            OBJ.refresh.GUIcontrols = true
                          end
                },
              }
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_LoadVFv2') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then VF_LoadLibraries() main() end
  end
  


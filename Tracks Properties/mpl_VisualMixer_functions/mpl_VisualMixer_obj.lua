-- @description VisualMixer_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    
    obj.but_h = 20
    
    obj.tr_base_rect = 30
    obj.tr_max_rect = 80
    obj.tr_offs_left = 2+obj.tr_max_rect
    obj.tr_offs_right = 2+obj.tr_max_rect
    obj.tr_offs_top = obj.offs*4 + obj.but_h
    obj.tr_offs_bottom = obj.tr_base_rect+obj.offs
    
    obj.scale_lim_low = -60
    obj.scale_cent = 0.8
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = 19
    obj.GUI_fontsz2 = 15 
    obj.GUI_fontsz3 = 13 
    obj.GUI_fontsz_tooltip = 13
    if GetOS():find("OSX") then 
      obj.GUI_fontsz = obj.GUI_fontsz - 6 
      obj.GUI_fontsz2 = obj.GUI_fontsz2 - 5 
      obj.GUI_fontsz3 = obj.GUI_fontsz3 - 4
      obj.GUI_fontsz_tooltip = obj.GUI_fontsz_tooltip - 4
    end 
  end
  ---------------------------------------------------
  function Obj_TrackObj(conf, obj, data, refresh, mouse)
    if not data.tracks then return end
    for trGUID in pairs(data.tracks) do
      local xpos = Obj_GetXPos(obj, data.tracks[trGUID].pan)
      local ypos = Obj_GetYPos(obj, data.tracks[trGUID].vol_dB)      
      local trw = lim(data.tracks[trGUID].width, 0, 1)
      
      local rectw = obj.tr_base_rect + (obj.tr_max_rect - obj.tr_base_rect)*trw
      local recth = 30
      
      obj['tr'..trGUID] = { istrobj = true,
                        clear = true,
                        x = math.floor(xpos-rectw/2),
                        y = math.floor(ypos-recth/2),
                        w = rectw,
                        h = recth,
                        txt= data.tracks[trGUID].name,
                        col =data.tracks[trGUID].col,
                        GUID = trGUID,
                        show = true,
                        mouse_Lclick =  function ()
                                          mouse.context_latch_content = {obj['tr'..trGUID]
                                                                }
                                        end,
                        mouse_Ldrag = function()
                                        if not mouse.context_latch_content then return end
                                        for i = 1, #mouse.context_latch_content do
                                          local temp_obj_t = CopyTable(mouse.context_latch_content[i])
                                          obj['tr'..temp_obj_t.GUID] = temp_obj_t
                                          
                                          --pan
                                            local new_x = temp_obj_t.x + mouse.dx+temp_obj_t.w/2
                                            local pan = Obj_GetXPos(obj, _, new_x )
                                            local new_x = Obj_GetXPos(obj, pan )
                                            obj['tr'..temp_obj_t.GUID].x = new_x-temp_obj_t.w/2
                                            Data_ApplyTrPan(temp_obj_t.GUID,pan )
                                          -- vol
                                            local new_y = temp_obj_t.y + mouse.dy+temp_obj_t.h/2
                                            local vol = Obj_GetYPos(obj, _, new_y )
                                            local new_y = Obj_GetYPos(obj, vol )
                                            obj['tr'..temp_obj_t.GUID].y = new_y-temp_obj_t.h/2
                                            local vol_reap = WDL_DB2VAL(vol)
                                            Data_ApplyTrVol(temp_obj_t.GUID,vol_reap )                                            
                                          
                                        end
                                        refresh.GUI_minor = true
                                      end}
    end  
  end
    
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    Obj_TrackObj(conf, obj, data, refresh, mouse) 
    Obj_MenuMain(conf, obj, data, refresh, mouse)
    for key in pairs(obj) do if type(obj[key]) == 'table' then obj[key].context = key end end    
  end
  -----------------------------------------------
  function Obj_GetXPos(obj, pan, mouse_x)
    local com_w = gfx.w - obj.tr_offs_left - obj.tr_offs_right
    
    if pan then return obj.tr_offs_left + com_w*0.5* (1+pan) end
    if mouse_x then return lim(-1+2*(mouse_x - obj.tr_offs_left)/com_w,  -1,1) end
  end  
  
  -----------------------------------------------
  function Obj_GetYPos(obj, db_val, mouse_y )
    local com_h = gfx.h - obj.tr_offs_top - obj.tr_offs_bottom
 
    if db_val then 
      local linearval = Custom_DB2VAL(obj, db_val)
      return gfx.h - obj.tr_offs_bottom - com_h*linearval,linearval 
    end
    if mouse_y then 
      local linearval = (gfx.h - obj.tr_offs_bottom - mouse_y)/com_h
      return Custom_DB2VAL(obj, _, linearval)
    end
  end
  --------------------------------------------------- 
  function Custom_DB2VAL(obj, db_val, linear_val)
    local log1 = 10
    local log2 = 40
  
    if db_val then 
      local y
      if db_val >= 0 then 
        y = lim(1 - (1-obj.scale_cent) * (12-db_val)/12, 0, 1)
       elseif db_val <= obj.scale_lim_low then 
        y = 0      
       elseif db_val >obj.scale_lim_low and db_val < 0 then 
        y = log1^(db_val/log2) *obj.scale_cent
      end
      if not y then y = 0 end
      return y
    end
    
    if linear_val then 
      local dB
      if not linear_val then return 0 end
      if linear_val >= obj.scale_cent then 
        dB = 12*(linear_val - obj.scale_cent) / (1-obj.scale_cent)      
       else     
        dB = log2*math.log(linear_val/obj.scale_cent, log1)
      end
      return dB    
    end
    
  end
  -----------------------------------------------
  function Obj_MenuMain(conf, obj, data, refresh, mouse)
    obj.menu_y = 0
    obj.menu_w = gfx.w * 1
    
    
    obj.menu = { clear = true,
                        x = 0,
                        y = obj.menu_y,
                        w = obj.menu_w,
                        h = obj.but_h,
                        col = 'white',
                        state = false,
                        txt= 'Menu',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        mouse_Lclick =  function() 
                                  Menu(mouse,               
    {
      { str = conf.mb_title..' '..conf.vrs,
        hidden = true
      },
      { str = '|>Donate / Links / Info'},
      { str = 'Donate to MPL',
        func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
      { str = 'Cockos Forum thread',
        func = function() Open_URL('http://forum.cockos.com/showthread.php?t=188335') end  } , 
      { str = 'MPL on VK',
        func = function() Open_URL('http://vk.com/mpl57') end  } ,     
      { str = 'MPL on SoundCloud|<|',
        func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
        
--[[      { str = '#Options'},    
      { str = 'Peaks buffer|',  
        func =  function() 
                  local ret, psz = GetUserInputs( conf.mb_title, 1, 'Peak buffer size', conf.bufsz_peaks )
                  if not ret or not tonumber(psz) then return end
                  
                  conf.bufsz_peaks = math.ceil(tonumber(psz))
                end
      } , 
      ]]
      
      
      
      
      
      { str = 'Dock '..'MPL '..conf.mb_title..' '..conf.vrs,
        func = function() 
                  conf.dock2 = math.abs(1-conf.dock2) 
                  gfx.quit() 
                  gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                            conf.wind_w, 
                            conf.wind_h, 
                            conf.dock2, conf.wind_x, conf.wind_y)
              end ,
        state = conf.dock2 == 1},                                                                            
    }
    )
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                                end}  
  end


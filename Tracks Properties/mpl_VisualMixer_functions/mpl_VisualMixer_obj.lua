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
                                        
                                        Obj_TrackObjCtrl(conf, obj, data, refresh, mouse)
                                        refresh.GUI_minor = true
                                        refresh.data = true
                                        refresh.save_data_proj = true 
                                      end}
                                                                       
    end  
  end
  -----------------------------------------------------------
  function Obj_TrackObjCtrl(conf, obj, data, refresh, mouse)
    if not data or not data.tracks then return end
    local width_rect = 10
    for trGUID in pairs(data.tracks) do
      local temp_t = obj['tr'..trGUID]
        obj['tr'..trGUID..'w1'] = {
                        clear = true,
                        x = temp_t.x-width_rect/2,
                        y = temp_t.y + (temp_t.h-width_rect)/2,
                        w = width_rect,
                        h = width_rect,
                        txt= '',
                        col =data.tracks[trGUID].col,
                        GUID = trGUID,
                        --show = true,
                        mouse_Lclick =  function ()
                                          mouse.context_latch_content = {obj['tr'..trGUID]
                                                                }
                                        end,
                        mouse_Ldrag = function()
                                        if not mouse.context_latch_content then return end
                                        for i = 1, #mouse.context_latch_content do
                                          local temp_obj_t = CopyTable(mouse.context_latch_content[i])
                                          obj['tr'..temp_obj_t.GUID] = temp_obj_t
                                          
                                          --width
                                            local src_w = lim((temp_obj_t.w-obj.tr_base_rect)/(obj.tr_max_rect-obj.tr_base_rect), 0, 1)
                                            local outval = lim(src_w - mouse.dx/100,0,1)
                                            Data_ApplyTrWidth(temp_obj_t.GUID, outval )
                                            refresh.GUI = true
                                            refresh.data = true
                                            refresh.data_proj = true
                                        end
                                      end}       
        obj['tr'..trGUID..'w2'] = {
                        clear = true,
                        x = temp_t.x+temp_t.w-width_rect/2,
                        y = temp_t.y + (temp_t.h-width_rect)/2,
                        w = width_rect,
                        h = width_rect,
                        txt= '',
                        col =data.tracks[trGUID].col,
                        GUID = trGUID,
                        --show = true,
                        mouse_Lclick =  function ()
                                          mouse.context_latch_content = {obj['tr'..trGUID]
                                                                }
                                        end,
                        mouse_Ldrag = function()
                                        if not mouse.context_latch_content then return end
                                        for i = 1, #mouse.context_latch_content do
                                          local temp_obj_t = CopyTable(mouse.context_latch_content[i])
                                          obj['tr'..temp_obj_t.GUID] = temp_obj_t
                                          
                                          --width
                                            local src_w = lim(temp_obj_t.w/obj.tr_max_rect, 0, 1)
                                            local outval = lim(src_w + mouse.dx/100,0,1)
                                            Data_ApplyTrWidth(temp_obj_t.GUID, outval )
                                            refresh.data_proj = true
                                            refresh.GUI = true
                                            refresh.data = true
                                        end
                                      end} 
    end
  end    
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    if refresh.GUI == true or refresh.GUI_onStart == true then          
      for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
      Obj_TrackObj(conf, obj, data, refresh, mouse) 
      Obj_TrackObjCtrl(conf, obj, data, refresh, mouse)
      
      if not obj.currentsnapshotID then obj.currentsnapshotID = 1 end
      
      obj.menu_w = gfx.w * 0.3
      obj.snsh_w = gfx.w -obj.menu_w-1
      obj.snsh_w_funcbut = 40
      obj.snsh_w_call = 15
      obj.ssnmbp = math.ceil((obj.snsh_w - obj.snsh_w_funcbut * 3) / obj.snsh_w_call)
      if obj.ssnmbp < 2 then 
        obj.menu_w = gfx.w 
       else
        obj.ssnmbp = lim(obj.ssnmbp, 2, 8)
        obj.menu_w = gfx.w - obj.snsh_w_funcbut * 2 - obj.ssnmbp * obj.snsh_w_call - obj.offs * 1
        obj.snsh_w = gfx.w -obj.menu_w-1
        Obj_SnapShots(conf, obj, data, refresh, mouse)
      end
      Obj_MenuMain(conf, obj, data, refresh, mouse)
      for key in pairs(obj) do if type(obj[key]) == 'table' then obj[key].context = key end end 
    end 
  end
                                   
  -----------------------------------------------
  function Obj_SnapShots(conf, obj, data, refresh, mouse)
    if obj.ssnmbp < 2 then return end
    
    for i = 1, obj.ssnmbp do
      local a_frame = 0
      local alpha_back = 0.1
      if data.currentsnapshotID and data.currentsnapshotID == i then a_frame = 0.25 alpha_back = 0.3 end
      local txt_a = 0.2
      if Data_Snapshot_HasExist(data, i)  then txt_a = 0.9 end
      obj['s_sh'..i] = { clear = true,
                        x = obj.menu_w + 1 +obj.snsh_w_call * (i-1),
                        y = obj.menu_y,
                        w = obj.snsh_w_call,
                        h = obj.but_h,
                        col = 'white',
                        state = false,
                        txt= i,
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = a_frame,
                        txt_a = txt_a,
                        alpha_back = alpha_back,
                        mouse_Lclick =  function()  
                                          data.currentsnapshotID = i
                                          Data_Snapshot_SaveExtState(data, data.currentsnapshotID)  
                                          refresh.GUI = true
                                          local snshstr = Data_SnapShot_GetString(data, i)
                                          Data_SnapshotRecall(snshstr )
                                        end
                }
    end              
      --[[obj.ssh_store = { clear = true,
                        x = obj.menu_w + obj.offs*2 + obj.snsh_w_call *obj.ssnmbp,
                        y = obj.menu_y,
                        w = obj.snsh_w_funcbut,
                        h = obj.but_h,
                        col = 'white',
                        state = false,
                        txt= 'Store',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        mouse_Lclick =  function() 
                                          
                                        end
                } ]]
      obj.ssh_copy = { clear = true,
                        x = obj.menu_w + 2 + obj.snsh_w_call *obj.ssnmbp,
                        y = obj.menu_y,
                        w = obj.snsh_w_funcbut,
                        h = obj.but_h,
                        col = 'white',
                        state = false,
                        txt= 'Copy',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        mouse_Lclick =  function() 
                                          local snshstr = Data_SnapShot_GetString(data, data.currentsnapshotID)
                                          mouse.clipboard = snshstr
                                        end
                }    
      obj.ssh_paste = { clear = true,
                        x = obj.menu_w + 2 + obj.snsh_w_call *obj.ssnmbp + obj.snsh_w_funcbut,
                        y = obj.menu_y,
                        w = obj.snsh_w_funcbut,
                        h = obj.but_h,
                        col = 'white',
                        state = false,
                        txt= 'Paste',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        mouse_Lclick =  function()
                                          if mouse.clipboard then 
                                            -- store ext state
                                              local str = mouse.clipboard
                                              Data_Snapshot_SaveExtState(data, data.currentsnapshotID, str) 
                                            -- recall
                                              Data_SnapshotRecall(str )
                                              refresh.GUI = true
                                              refresh.data = true
                                          end
                         
                                        end
                }                                 
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
                  if conf.dock > 0 then conf.dock = 0 else conf.dock = 1 end
                  gfx.quit() 
                  gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                            conf.wind_w, 
                            conf.wind_h, 
                            conf.dock, conf.wind_x, conf.wind_y)
              end ,
        state = conf.dock > 0},                                                                            
    }
    )
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                                end}  
  end


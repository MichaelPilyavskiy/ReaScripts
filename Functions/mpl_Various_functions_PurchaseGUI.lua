-- @description Various_functions_PurchaseGUI
-- @author MPL
-- @noindex

  function ExtState_Def()  
    local t= { 
            -- globals
            vrs = 1.0,
            mb_title = 'MPL Various Function package Purchasing',
            ES_key = 'MPLVFpurch',
            wind_x =  100,
            wind_y =  50,
            wind_w =  500,
            wind_h =  500,
            dock =    0, 
            }
    return t
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Init(MOUSE,OBJ,DATA)
    local offset = 10
    local but_h = 120
    local proccedh = (gfx.h-but_h-offset*3)/5
    local txt_a_vis = 1
    local txt_a_unactive = 0.3
    local fontsz_buttons = 17
    
    OBJ.purchase = {is_button = true,
                    x=offset,
                    y=offset,
                    w=gfx.w - offset*2,
                    h=but_h,
                    grad_back_a = 1,
                    highlight = false,
                    txt=
[[You updated "Various Functions" package from MPL`s ReaPack repository. 
Since version 1.31 this package is paid. 
For more information contact me via email m.pilyavskiy@gmail.com]],
                    fontsz = 20,
                    drawstr_flags = 1|4,
                    }
    OBJ.backtofree = {is_button = true,
                    x=offset,
                    y=offset*2+but_h,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 0,
                    txt='Back to free version?',
                    txt_a = txt_a_vis,
                    highlight = false,
                    func_Ltrig = function() 
                      --OBJ.purchase.selected = true 
                      DATA.refresh.GUI = DATA.refresh.GUI|4 
                    end ,
                    --func_Lrelease = function() OBJ.purchase.selected = false DATA.refresh.GUI = DATA.refresh.GUI|4 end,
                    fontsz = 20,
                    drawstr_flags = 1|4,
                    } 
    OBJ.backtofree1 = {is_button = true,
                    x=offset,
                    y=offset*2+but_h+proccedh,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 1,
                    txt='1. Open Action List \naction "Reapack:Browse packages" \nnavigate to Various functions',
                    func_Ltrig = function() 
                      OBJ.purchase.selected = true 
                      DATA.refresh.GUI = DATA.refresh.GUI|4 
                      ReaPack_BrowsePackages( 'Various functions' ) 
                    end ,
                    func_Lrelease = function() OBJ.purchase.selected = false DATA.refresh.GUI = DATA.refresh.GUI|4 end,
                    fontsz = fontsz_buttons,
                    drawstr_flags = 1|4,
                    }      
    OBJ.backtofree2 = {is_button = true,
                    x=offset,
                    y=offset*2+but_h+proccedh*2,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 1,
                    txt='2. Rightclick on package: \n set "Pin Current Version on"',
                    highlight = false,
                    fontsz = fontsz_buttons,
                    drawstr_flags = 1|4,
                    }  
    OBJ.backtofree3 = {is_button = true,
                    x=offset,
                    y=offset*2+but_h+proccedh*3,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 1,
                    txt='3. Rightclick on package: \n set "Versions - 1.31"',
                    highlight = false,
                    fontsz = fontsz_buttons,
                    drawstr_flags = 1|4,
                    } 
    OBJ.backtofree4 = {is_button = true,
                    x=offset,
                    y=offset*2+but_h+proccedh*4,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 1,
                    txt='4. Click Apply and Sync packages',
                    fontsz = fontsz_buttons,
                    drawstr_flags = 1|4,
                    func_Ltrig =  function()  
                                    OBJ.backtofree4.selected = true  
                                    DATA.refresh.GUI = DATA.refresh.GUI|4  
                                    VF_Action('_REAPACK_SYNC') 
                                  end ,
                    func_Lrelease = function() OBJ.backtofree4.selected = false DATA.refresh.GUI = DATA.refresh.GUI|4 end,
                                        
                    }                      
    OBJ.proccedreg = {is_button = true,
                    x=offset*1.5+(gfx.w - offset*2)/2,
                    y=offset*2+but_h,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 0,
                    txt='Purchase?',
                    highlight = false,
                    --func_Ltrig = function()  OBJ.purchase.selected = true  DATA.refresh.GUI = DATA.refresh.GUI|4  end ,
                    --func_Lrelease = function() OBJ.purchase.selected = false DATA.refresh.GUI = DATA.refresh.GUI|4 end,
                    fontsz = 20,
                    drawstr_flags = 1|4,
                    }  
    OBJ.proccedreg1 = {is_button = true,
                    x=offset*1.5+(gfx.w - offset*2)/2,
                    y=offset*2+but_h+proccedh,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 1,
                    txt='1. Send $30 to paypal.me/donate2mpl \nSkip it if you donated before may 2021',
                    func_Ltrig =  function()  
                                    OBJ.purchase.selected = true  
                                    DATA.refresh.GUI = DATA.refresh.GUI|4 
                                    VF_Open_URL('https://www.paypal.me/donate2mpl')  
                                  end ,
                    func_Lrelease = function() OBJ.purchase.selected = false DATA.refresh.GUI = DATA.refresh.GUI|4 end,
                    fontsz = fontsz_buttons,
                    drawstr_flags = 1|4,
                    }   
    local sysID = VF_GetSystemID()
    OBJ.proccedreg2 = {is_button = true,
                    x=offset*1.5+(gfx.w - offset*2)/2,
                    y=offset*2+but_h+proccedh*2,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 1,
                    txt='2. Copy this system ID and send to m.pilyavskiy@gmail.com: '..sysID,
                    func_Ltrig =  function()  
                                    OBJ.purchase.selected = true  
                                    DATA.refresh.GUI = DATA.refresh.GUI|4 
                                    msg('SystemID:\n'..sysID..'\n\nMail:\nm.pilyavskiy@gmail.com')
                                  end ,
                    func_Lrelease = function() OBJ.purchase.selected = false DATA.refresh.GUI = DATA.refresh.GUI|4 end,
                    fontsz = fontsz_buttons,
                    drawstr_flags = 1|4,
                    }    
    OBJ.proccedreg3 = {is_button = true,
                    x=offset*1.5+(gfx.w - offset*2)/2,
                    y=offset*2+but_h+proccedh*3,
                    w=(gfx.w - offset*2)/2-offset/2,
                    h=proccedh,
                    grad_back_a = 1,
                    txt='3. Paste response code here \n(getting ready in 1-3 days)',
                    func_Ltrig =  function()  
                                    OBJ.purchase.selected = true  
                                    DATA.refresh.GUI = DATA.refresh.GUI|4 
                                    VF_InputResponse()
                                  end ,
                    func_Lrelease = function() OBJ.purchase.selected = false DATA.refresh.GUI = DATA.refresh.GUI|4 end,
                    fontsz = fontsz_buttons,
                    drawstr_flags = 1|4,
                    }                      
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Update(MOUSE,OBJ,DATA)
    
  end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) 
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' 
    if  reaper.file_exists( SEfunc_path ) then
      dofile(SEfunc_path) 
      if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return false end  
     else 
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) 
      if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end
    end   
  end
  --------------------------------------------------------------------  
  -- local ret = VF_CheckFunctions(2.2) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then VF_run_initVars() VF_run_init() end end
  -- local ret = VF_CheckFunctions(2.2) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end
  
  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions_v1.lua' if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) end
  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions_Purchase.lua' if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) end  
  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions_Pers.lua' if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) end  
  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions_MOUSE.lua' if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) end  
  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions_GUI.lua' if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) end  
  
  local last_run = reaper.GetExtState('MPL_Scripts', 'last_run')
  if last_run == '' then
    reaper.SetExtState('MPL_Scripts', 'last_run', os.clock(), false)
    VF_run_initVars() 
    VF_run_init()
  end
  
  

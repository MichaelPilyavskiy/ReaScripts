-- @description Various_functions_PurchaseGUI
-- @author MPL
-- @noindex

  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = ''
    DATA.extstate.extstatesection = 'MPL_Scripts'
    DATA.extstate.mb_title = 'MPL scripts purchase'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  500,
                          wind_h =  300,
                          dock =    0,
                          }
                          
    DATA:ExtStateGet()
    DATA.extstate.wind_x =  100
    DATA.extstate.wind_y =  100
    DATA.extstate.wind_w =  500
    DATA.extstate.wind_h =  300
    DATA.extstate.dock =  0
    GUI:init()
    GUI.userfollow = 0
    GUI_RESERVED_initbuttons(GUI)
    RUN()
  end
  
  ---------------------------------------------------------------------  
  function GUI_RESERVED_initbuttons(GUI)
    
    GUI.custom_texthdef = 23
    GUI.custom_offset = math.floor(GUI.default_scale*GUI.default_txt_fontsz/2)
    GUI.custom_mainbutw = gfx.w/GUI.default_scale-GUI.custom_offset*2
    GUI.custom_mainbuth = (gfx.h/GUI.default_scale-GUI.custom_offset*3)/2
    GUI.custom_mainbuth2 = (gfx.h/GUI.default_scale-GUI.custom_offset*4)/3
    GUI.custom_scrollw = 10
    GUI.custom_frameascroll = 0.05
    GUI.custom_default_framea_normal = 0.1
    GUI.custom_datah = (gfx.h/GUI.default_scale-GUI.custom_mainbuth-GUI.custom_offset*3) 
    GUI.custom_layerset = 21
    
    local cnt = reaper.GetExtState('MPL_Scripts', 'counttotal')
    if not (cnt and cnt ~= '' and tonumber(cnt)) then cnt = 0 end
    local sysID = VF_GetSystemID()
    
    GUI.buttons = {} 
    
      GUI.buttons.p1 = {  x=GUI.custom_offset,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = 'Purchase MPL`s scripts. (Used '..cnt..' times)',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.userfollow~=0,
                            ignoremouse = GUI.userfollow~=0,
                            onmouseclick =  function() 
                                              GUI.userfollow = 1
                                              DATA.UPD.onGUIinit = true 
                                            end} 
                                            
      GUI.buttons.p2 = {  x=GUI.custom_offset,
                            y=GUI.custom_offset*2+GUI.custom_mainbuth,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = 'Revert free version of MPL repository',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.userfollow~=0,
                            ignoremouse = GUI.userfollow~=0,
                            onmouseclick =  function() 
                                              GUI.userfollow = 2
                                              DATA.UPD.onGUIinit = true
                                            end}                                             
  
      GUI.buttons.p11 = {  x=GUI.custom_offset,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth2,
                            txt = '1. Send $30 to paypal.me/donate2mpl \nSkip it if you donated before may 2021\nContact m.pilyavskiy@gmail.com if you don`t have paypal',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.userfollow~=1,
                            ignoremouse = GUI.userfollow~=1,
                            onmouseclick =  function() VF_Open_URL('https://www.paypal.me/donate2mpl')    end}     
      GUI.buttons.p12 = {  x=GUI.custom_offset,
                            y=GUI.custom_offset*2+GUI.custom_mainbuth2,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth2,
                            txt = '2. Send ID by mail (click to show and copy mail and ID)',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.userfollow~=1,
                            ignoremouse = GUI.userfollow~=1,
                            onmouseclick =  function() ClearConsole() msg('SystemID:\n'..sysID..'\n\nMail:\nm.pilyavskiy@gmail.com')    end}          
      GUI.buttons.p13 = {  x=GUI.custom_offset,
                            y=GUI.custom_offset*3+GUI.custom_mainbuth2*2,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth2,
                            txt = '3. Paste response code here \n(getting ready in 1-3 days)',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.userfollow~=1,
                            ignoremouse = GUI.userfollow~=1,
                            onmouseclick =  function() VF_InputResponse()    end}      
                            
                            
                          -- free --
      GUI.buttons.p21 = {  x=GUI.custom_offset,
                            y=GUI.custom_offset,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = 'action "Reapack:Browse packages" \nnavigate to Various functions',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.userfollow~=2,
                            ignoremouse = GUI.userfollow~=2,
                            onmouseclick =  function() ReaPack_BrowsePackages( 'Various functions' )  end}     
      GUI.buttons.p22 = {  x=GUI.custom_offset,
                            y=GUI.custom_offset*2+GUI.custom_mainbuth,
                            w=GUI.custom_mainbutw,
                            h=GUI.custom_mainbuth,
                            txt = '1. Rightclick on package\n2. Set "Pin Current Version on"\n3. Set "Versions - 1.31"\n4. Click "Apply"',
                            txt_fontsz = GUI.default_txt_fontsz2,
                            hide = GUI.userfollow~=2,
                            frame_a = 0,
                            ignoremouse = true,--GUI.userfollow~=2,
                            onmouseclick =  function() ReaPack_BrowsePackages( 'Various functions' )  end}     
                            
                            
                            
    for but in pairs(GUI.buttons) do GUI.buttons[but].key = but end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.84) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) 
  if ret2 then 
    local last_run = reaper.GetExtState('MPL_Scripts', 'last_run')
    if last_run == '' then
      reaper.SetExtState('MPL_Scripts', 'last_run', os.clock(), false)
      main() 
    end
  end end
  
  
  

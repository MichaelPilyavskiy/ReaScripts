-- @description Item spacer
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about
--	Audiobook tool for spacing dialogg with the ability to set minimum items distance
-- @changelog
--    + Init


 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  DATA2 = {}
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '1.0'
    DATA.extstate.extstatesection = 'ItemSpacer'
    DATA.extstate.mb_title = 'Item spacer'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  300,
                          wind_h =  200,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          CONF_minspace = 0.5,--sec
                          CONF_desspace = 0.6,--sec
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          
                          }
    
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets()  
    if DATA.extstate.UI_initatmouse&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    DATA:GUIinit()
    DATA2:GetItems()
    RUN()
  end
  -----------------------------------------------------------------------
  function DATA2:AppSpace()
    if not DATA2.items then return end
    Undo_BeginBlock()
    
    local rippleshift_com = 0
    for i =2, #DATA2.items do
      local space =  DATA2.items[i].pos - (DATA2.items[i-1].pos + DATA2.items[i-1].len)
      rippleshift_com_cur = rippleshift_com
      if space > DATA.extstate.CONF_minspace then
        rippleshift_com = rippleshift_com + (  space-DATA.extstate.CONF_desspace)
        space = DATA.extstate.CONF_desspace
      end 
      out_pos = DATA2.items[i-1].pos + DATA2.items[i-1].len + space - rippleshift_com_cur
      rippleshift_com_cur = rippleshift_com
      local take = GetMediaItemTakeByGUID( 0, DATA2.items[i].take_GUID )
      if take then
        local item = GetMediaItemTake_Item( take )
        SetMediaItemInfo_Value( item, 'D_POSITION', out_pos )
      end
    end
    
    Undo_EndBlock2( 0, 'Item spacer', 0xFFFFFFFF )
  end
  -----------------------------------------------------------------------
  function DATA2:GetItems()
    DATA2.items = {}
    for i = 1, CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem( 0,i-1)
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local take = GetActiveTake(item)
      local retval, GUID = GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
      DATA2.items[pos] = {take_GUID=GUID,
                          pos = pos,
                          len = len,
                          }
    end
    
    local t_sort = {}
    for pos in spairs(DATA2.items) do
      t_sort[#t_sort+1] = CopyTable(DATA2.items[pos])
    end
    
    DATA2.items = t_sort
  end
  -----------------------------------------------------------------------
  function GUI_RESERVED_init(DATA)
    DATA.GUI.buttons = {} 
      -- get globals
        DATA.GUI.custom_gfx_h = math.floor(gfx.h/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
        DATA.GUI.custom_gfx_w = math.floor(gfx.w/DATA.GUI.default_scale)--math.max(250,gfx.h/DATA.GUI.default_scale)
      --DATA.GUI.default_scale = 1
        
      -- init main stuff
        DATA.GUI.custom_referenceH = 300
        DATA.GUI.custom_Yrelation = math.max(DATA.GUI.custom_gfx_h/DATA.GUI.custom_referenceH, 0.5) -- global W
        DATA.GUI.custom_Yrelation = math.min(DATA.GUI.custom_Yrelation, 1) -- global W
        DATA.GUI.custom_buth = math.floor(DATA.GUI.custom_gfx_h/3)
        DATA.GUI.custom_offset =  math.floor(6 * DATA.GUI.custom_Yrelation)
        DATA.GUI.custom_tab_w = math.floor(100*DATA.GUI.custom_Yrelation)
        DATA.GUI.custom_txtsz1 = math.floor(25*DATA.GUI.custom_Yrelation) -- menu
        

        DATA.GUI.buttons.get = { x=0,
                              y=0,
                              w=DATA.GUI.custom_gfx_w ,-- - DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_buth-1,
                              txt = 'Get items',
                              txt_fontsz = DATA.GUI.custom_txtsz1,
                              --frame_a = 1,
                              onmouserelease = function()
                                DATA2:GetItems()
                              end,
                              }
                              
        DATA.GUI.buttons.minthresh = { x=0,
                              y=DATA.GUI.custom_buth,
                              w=DATA.GUI.custom_gfx_w ,-- - DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_buth-1,
                              txt = 'Minimum space '..VF_math_Qdec(DATA.extstate.CONF_minspace,2)..'sec' ,
                              txt_fontsz = DATA.GUI.custom_txtsz1,
                              knob_isknob = true,
                              knob_showvalueright = true,
                              val_res = 0.25,
                              val_min = 0.1,
                              val_max = DATA.extstate.CONF_desspace-0.01,
                              val = DATA.extstate.CONF_minspace,
                              frame_a = DATA.GUI.default_framea_normal,
                              frame_asel = DATA.GUI.default_framea_normal,
                              back_sela = 0,
                              onmousedrag =     function() 
                                DATA.GUI.buttons.minthresh.txt = 'Minimum space '..VF_math_Qdec(DATA.extstate.CONF_minspace,2)..'sec' 
                                DATA.extstate.CONF_minspace = DATA.GUI.buttons.minthresh.val 
                                if DATA.extstate.CONF_desspace < DATA.extstate.CONF_minspace then DATA.extstate.CONF_minspace = DATA.extstate.CONF_desspace - 0.01 end
                              end,
                            onmouserelease  = function() 
                                DATA.GUI.buttons.minthresh.txt = 'Minimum space '..VF_math_Qdec(DATA.extstate.CONF_minspace,2)..'sec' 
                                DATA.extstate.CONF_minspace = DATA.GUI.buttons.minthresh.val 
                                if DATA.extstate.CONF_desspace < DATA.extstate.CONF_minspace then DATA.extstate.CONF_minspace = DATA.extstate.CONF_desspace - 0.01 end
                                DATA.GUI.buttons.space.refresh = true
                                DATA.GUI.buttons.minthresh.refresh = true
                                DATA.UPD.onconfchange = true
                                GUI_RESERVED_init(DATA)
                                DATA2:AppSpace()
                              end,
                              }  
                              
        DATA.GUI.buttons.space = { x=0,
                              y=DATA.GUI.custom_buth*2,
                              w=DATA.GUI.custom_gfx_w ,-- - DATA.GUI.custom_offset,
                              h=DATA.GUI.custom_buth-1,
                              txt = 'Desired space '..VF_math_Qdec(DATA.extstate.CONF_desspace,2)..'sec' ,
                              txt_fontsz = DATA.GUI.custom_txtsz1,
                              knob_isknob = true,
                              knob_showvalueright = true,
                              val_res = 0.25,
                              val_min = DATA.extstate.CONF_minspace+0.01,
                              val_max = 3,
                              val = DATA.extstate.CONF_desspace,
                              frame_a = DATA.GUI.default_framea_normal,
                              frame_asel = DATA.GUI.default_framea_normal,
                              back_sela = 0,
                              onmousedrag =     function() 
                                DATA.GUI.buttons.space.txt = 'Desired space '..VF_math_Qdec(DATA.extstate.CONF_desspace,2)..'sec' 
                                DATA.extstate.CONF_desspace = DATA.GUI.buttons.space.val 
                                if DATA.extstate.CONF_desspace < DATA.extstate.CONF_minspace then DATA.extstate.CONF_minspace = DATA.extstate.CONF_desspace - 0.01 end
                              end,
                            onmouserelease  = function() 
                                DATA.GUI.buttons.space.txt = 'Desired space '..VF_math_Qdec(DATA.extstate.CONF_desspace,2)..'sec' 
                                DATA.extstate.CONF_desspace = DATA.GUI.buttons.space.val 
                                if DATA.extstate.CONF_desspace < DATA.extstate.CONF_minspace then DATA.extstate.CONF_minspace = DATA.extstate.CONF_desspace - 0.01 end
                                DATA.GUI.buttons.space.refresh = true
                                DATA.GUI.buttons.minthresh.refresh = true
                                DATA.UPD.onconfchange = true
                                GUI_RESERVED_init(DATA)
                                DATA2:AppSpace()
                              end,
                              }                               
                              
    
      
      for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
    end 
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end


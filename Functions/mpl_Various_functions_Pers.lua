-- @description Various_functions_Pers
-- @author MPL
-- @noindex


---------------------------------------------------
  function VF_run_initVars()
    OBJ = {-- GUI objects
          } 
      
    DATA = {-- Data used by script
      conf = {}, 
      confproj = {}, -- reaper-ext.ini
      dev_mode = 0, -- test stuff
      refresh = { GUI = 1|2|4, --&1 refresh everything &2 buttons &4 buttons update
                  conf = 0, -- save ext state &1 all &2 reaper-ext.ini only &4 projextstate only &8 preset only
                  data = 1|2|4, -- &1 init &2 update data &4 read &8 write
                },
      GUIvars = {
                  grad_sz = 200, -- gradient background src, px
                  colors = VF_run_initVars_SetColors(MOUSE,OBJ,DATA),
                  menu_w = 25, -- top menu, px
                  menu_h = 25, -- top menu, px
                  menu_fontsz = 17, 
                  scrollt = {}, -- init table for scroll values
                }
      } 
      
    MOUSEt = {}
    VF_ExtState_Load(DATA.conf, DATA.conf.preset_current) 
    if not DATA.conf.vrs then DATA.conf.vrs = '[version undefined]' end
    VF_ExtState_LoadProj(DATA.confproj, DATA.conf.ES_key) 
  end    
  ---------------------------------------------------------------------
  function VF_run_initVars_SetColors(MOUSEt,OBJ,DATA) -- https://htmlcolorcodes.com/colors/
    return {        backgr = '#3f484d',
                    green = '#17B025',
                    blue = '#1792B0',
                    
                    WHITE = "#FFFFFF",
                    AZURE = "#F0FFFF",
                    MINTCREAM = "#F5FFFA",
                    SNOW = "#FFFAFA",
                    IVORY = "#FFFFF0",
                    GHOSTWHITE = "#F8F8FF",
                    FLORALWHITE = "#FFFAF0",
                    ALICEBLUE = "#F0F8FF",
                    LIGHTCYAN = "#E0FFFF",
                    HONEYDEW = "#F0FFF0",
                    LIGHTYELLOW = "#FFFFE0",
                    SEASHELL = "#FFF5EE",
                    LAVENDERBLUSH = "#FFF0F5",
                    WHITESMOKE = "#F5F5F5",
                    OLDLACE = "#FDF5E6",
                    CORNSILK = "#FFF8DC",
                    LINEN = "#FAF0E6",
                    LIGHTGOLDENRODYELLOW = "#FAFAD2",
                    LEMONCHIFFON = "#FFFACD",
                    BEIGE = "#F5F5DC",
                    LAVENDER = "#E6E6FA",
                    PAPAYAWHIP = "#FFEFD5",
                    MISTYROSE = "#FFE4E1",
                    ANTIQUEWHITE = "#FAEBD7",
                    BLANCHEDALMOND = "#FFEBCD",
                    BISQUE = "#FFE4C4",
                    PALETURQUOISE = "#AFEEEE",
                    MOCCASIN = "#FFE4B5",
                    GAINSBORO = "#DCDCDC",
                    PEACHPUFF = "#FFDAB9",
                    NAVAJOWHITE = "#FFDEAD",
                    PALEGOLDENROD = "#EEE8AA",
                    WHEAT = "#F5DEB3",
                    POWDERBLUE = "#B0E0E6",
                    AQUAMARINE = "#7FFFD4",
                    LIGHTGREY = "#D3D3D3",
                    PINK = "#FFC0CB",
                    LIGHTBLUE = "#ADD8E6",
                    THISTLE = "#D8BFD8",
                    LIGHTPINK = "#FFB6C1",
                    LIGHTSKYBLUE = "#87CEFA",
                    PALEGREEN = "#98FB98",
                    LIGHTSTEELBLUE = "#B0C4DE",
                    KHAKI = "#F0D58C",
                    SKYBLUE = "#87CEEB",
                    AQUA = "#00FFFF",
                    CYAN = "#00FFFF",
                    SILVER = "#C0C0C0",
                    PLUM = "#DDA0DD",
                    GRAY = "#BEBEBE",
                    LIGHTGREEN = "#90EE90",
                    VIOLET = "#EE82EE",
                    YELLOW = "#FFFF00",
                    TURQUOISE = "#40E0D0",
                    BURLYWOOD = "#DEB887",
                    GREENYELLOW = "#ADFF2F",
                    TAN = "#D2B48C",
                    MEDIUMTURQUOISE = "#48D1CC",
                    LIGHTSALMON = "#FFA07A",
                    MEDIUMAQUAMARINE = "#66CDAA",
                    DARKGRAY = "#A9A9A9",
                    ORCHID = "#DA70D6",
                    DARKSEAGREEN = "#8FBC8F",
                    DEEPSKYBLUE = "#00BFFF",
                    SANDYBROWN = "#F4A460",
                    GOLD = "#FFD700",
                    MEDIUMSPRINGGREEN = "#00FA9A",
                    DARKKHAKI = "#BDB76B",
                    CORNFLOWERBLUE = "#6495ED",
                    HOTPINK = "#FF69B4",
                    DARKSALMON = "#E9967A",
                    DARKTURQUOISE = "#00CED1",
                    SPRINGGREEN = "#00FF7F",
                    LIGHTCORAL = "#F08080",
                    ROSYBROWN = "#BC8F8F",
                    SALMON = "#FA8072",
                    CHARTREUSE = "#7FFF00",
                    MEDIUMPURPLE = "#9370DB",
                    LAWNGREEN = "#7CFC00",
                    DODGERBLUE = "#1E90FF",
                    YELLOWGREEN = "#9ACD32",
                    PALEVIOLETRED = "#DB7093",
                    MEDIUMSLATEBLUE = "#7B68EE",
                    MEDIUMORCHID = "#BA55D3",
                    CORAL = "#FF7F50",
                    CADETBLUE = "#5F9EA0",
                    LIGHTSEAGREEN = "#20B2AA",
                    GOLDENROD = "#DAA520",
                    ORANGE = "#FFA500",
                    LIGHTSLATEGRAY = "#778899",
                    FUCHSIA = "#FF00FF",
                    MAGENTA = "#FF00FF",
                    MEDIUMSEAGREEN = "#3CB371",
                    PERU = "#CD853F",
                    STEELBLUE = "#4682B4",
                    ROYALBLUE = "#4169E1",
                    SLATEGRAY = "#708090",
                    TOMATO = "#FF6347",
                    DARKORANGE = "#FF8C00",
                    SLATEBLUE = "#6A5ACD",
                    LIMEGREEN = "#32CD32",
                    LIME = "#00FF00",
                    INDIANRED = "#CD5C5C",
                    DARKORCHID = "#9932CC",
                    BLUEVIOLET = "#8A2BE2",
                    DEEPPINK = "#FF1493",
                    DARKGOLDENROD = "#B8860B",
                    CHOCOLATE = "#D2691E",
                    DARKCYAN = "#008B8B",
                    DIMGRAY = "#696969",
                    OLIVEDRAB = "#6B8E23",
                    SEAGREEN = "#2E8B57",
                    TEAL = "#008080",
                    DARKVIOLET = "#9400D3",
                    MEDIUMVIOLETRED = "#C71585",
                    ORANGERED = "#FF4500",
                    OLIVE = "#808000",
                    SIENNA = "#A0522D",
                    DARKSLATEBLUE = "#483D8B",
                    DARKOLIVEGREEN = "#556B2F",
                    FORESTGREEN = "#228B22",
                    CRIMSON = "#DC143C",
                    BLUE = "#0000FF",
                    DARKMAGENTA = "#8B008B",
                    DARKSLATEGRAY = "#2F4F4F",
                    SADDLEBROWN = "#8B4513",
                    BROWN = "#A52A2A",
                    FIREBRICK = "#B22222",
                    PURPLE = "#800080",
                    GREEN = "#008000",
                    RED = "#FF0000",
                    MEDIUMBLUE = "#0000CD",
                    INDIGO = "#4B0082",
                    MIDNIGHTBLUE = "#191970",
                    DARKGREEN = "#006400",
                    DARKBLUE = "#00008B",
                    NAVY = "#000080",
                    DARKRED = "#8B0000",
                    MAROON = "#800000",
                    BLACK = "#000000",
                    
                 }
  end  
--------------------------------------------------------------------
  function VF_run_init()
    gfx.init(DATA.conf.mb_title..' '..DATA.conf.vrs,
                    DATA.conf.wind_w,
                    DATA.conf.wind_h,
                    DATA.conf.dock, 
                    DATA.conf.wind_x, 
                    DATA.conf.wind_y)
    VF_run()
  end  
---------------------------------------------------
  function VF_run()
    VF_MOUSE(MOUSEt,OBJ,DATA)
    --[[ 
      check for project change 
        &1 statechangecount 
        &2 edit cursor change 
        &4 minor XY position change 
        &8 WH dock position change
        &16 project change]]
      local project_change = VF_run_CheckProjUpdates(DATA) 
      if project_change&4==4 or project_change&8==8 then DATA.refresh.conf = DATA.refresh.conf|2 end -- save to ext state on XYWH change
      DATA.refresh.project_change = project_change
      
    -- save ext state
      if DATA.refresh.conf&1==1 or DATA.refresh.conf&2==2 then
        DATA.conf.dock , DATA.conf.wind_x, DATA.conf.wind_y, DATA.conf.wind_w,DATA.conf.wind_h= gfx.dock(-1, 0,0,0,0)
        VF_ExtState_Save(DATA.conf)
      end
      if DATA.refresh.conf&1==1 or DATA.refresh.conf&4==4 then VF_ExtState_SaveProj(DATA.confproj,DATA.conf.ES_key) end
      DATA.refresh.conf = 0 
      
    -- do stuff
      if VF_DATA_UpdateAlways then VF_DATA_UpdateAlways(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&1==1 and VF_DATA_Init then VF_DATA_Init(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&2==2 and VF_DATA_Update then VF_DATA_Update(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&4==4 and VF_DATA_UpdateRead then VF_DATA_UpdateRead(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&8==8 and VF_DATA_UpdateWrite then VF_DATA_UpdateWrite(MOUSEt,OBJ,DATA) end
      DATA.refresh.data = 0
      
    -- refresh GUI
      if project_change&8==8 then DATA.refresh.GUI = DATA.refresh.GUI|2 end-- init buttons on window WH change 
      if (DATA.refresh.GUI&1==1 or DATA.refresh.GUI&2==2) and OBJ_Buttons_Init then OBJ_Buttons_Init(MOUSEt,OBJ,DATA) end -- init buttons
      if (DATA.refresh.GUI&1==1 or DATA.refresh.GUI&2==2 or DATA.refresh.GUI&4==4) and OBJ_Buttons_Update then OBJ_Buttons_Update(MOUSEt,OBJ,DATA) end -- update buttons 
      VF_GUI_draw(MOUSEt,OBJ,DATA)
      DATA.refresh.GUI = 0
      
    -- exit
      if MOUSEt.char >= 0 and MOUSEt.char ~= 27 then defer(VF_run) else   atexit(gfx.quit) end
     
  end    
  
    
  ---------------------------------------------------
  function VF_run_CheckProjUpdates(DATA)
    local ret = 0
    if not DATA.CheckProjUpdates then DATA.CheckProjUpdates = {} end
    
    
    -- SCC &1
      local SCC =  GetProjectStateChangeCount( 0 )
      if (DATA.CheckProjUpdates.lastSCC and DATA.CheckProjUpdates.lastSCC~=DATA.CheckProjUpdates.SCC ) then ret = ret|1 end
      DATA.CheckProjUpdates.lastSCC = DATA.CheckProjUpdates.SCC
      
    -- edit cursor &2
      DATA.CheckProjUpdates.editcurpos =  GetCursorPosition() 
      if (DATA.CheckProjUpdates.last_editcurpos and DATA.CheckProjUpdates.last_editcurpos~=DATA.CheckProjUpdates.editcurpos ) then ret = ret|2 end
      DATA.CheckProjUpdates.last_editcurpos=DATA.editcurpos
    
    -- script XYWH section &4 XY &8 WH/dock
      local  dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
      if not DATA.CheckProjUpdates.last_gfxx 
        or not DATA.CheckProjUpdates.last_gfxy 
        or not DATA.CheckProjUpdates.last_gfxw 
        or not DATA.CheckProjUpdates.last_gfxh 
        or not DATA.CheckProjUpdates.last_dock then 
        DATA.CheckProjUpdates.last_gfxx, 
        DATA.CheckProjUpdates.last_gfxy, 
        DATA.CheckProjUpdates.last_gfxw, 
        DATA.CheckProjUpdates.last_gfxh, 
        DATA.CheckProjUpdates.last_dock = wx,wy,ww,wh, dock
      end
      if wx ~= DATA.CheckProjUpdates.last_gfxx or wy ~= DATA.CheckProjUpdates.last_gfxy then ret = ret|4  end -- XY position change
      if ww ~= DATA.CheckProjUpdates.last_gfxw or wh ~= DATA.CheckProjUpdates.last_gfxh or dock ~= DATA.CheckProjUpdates.last_dock then ret = ret|8 end -- WH and dock change
      DATA.CheckProjUpdates.last_gfxx, DATA.CheckProjUpdates.last_gfxy, DATA.CheckProjUpdates.last_gfxw, DATA.CheckProjUpdates.last_gfxh, DATA.CheckProjUpdates.last_dock = wx,wy,ww,wh,dock
      
    -- proj tab &16
      local reaproj = tostring(EnumProjects( -1 ))
      DATA.CheckProjUpdates.reaproj = reaproj
      if DATA.CheckProjUpdates.last_reaproj and DATA.CheckProjUpdates.last_reaproj ~= DATA.CheckProjUpdates.reaproj then ret = ret|16 end
      DATA.CheckProjUpdates.last_reaproj = reaproj
      
    return ret
  end
  ---------------------------------------------------
  function VF_run_UpdateAll(DATA)
    DATA.refresh.conf = DATA.refresh.conf|1 
    DATA.refresh.GUI = DATA.refresh.GUI|1 
    DATA.refresh.data = DATA.refresh.data|1|2|4|8
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_InitMenuTop(MOUSE,OBJ,DATA, options_t)
    local t = {     { str = '#'..DATA.conf.mb_title..' '..DATA.conf.vrs..'|'},
                    { str = '>MPL contacts'},
                    { str = 'Cockos forum centralized thread',
                      func = function() Open_URL('https://forum.cockos.com/showthread.php?t=188335') end  } , 
                    { str = 'VK page',
                      func = function() Open_URL('http://vk.com/mpl57') end  } ,     
                    { str = 'SoundCloud page|<',
                      func = function() Open_URL('http://soundcloud.com/mpl57') end  }, 
              }
    if options_t then for i =1, #options_t do t[#t+1] = options_t[i] end end
    
    -- dock
    t[#t+1] = { str = '|Dock',
                state = DATA.conf.dock > 0,
                func = function() 
                        if DATA.conf.dock > 0 then DATA.conf.dock = 0 else DATA.conf.dock = 1 end
                        gfx.quit()
                        atexit( )
                        VF_run_init()
                        gfx.showmenu('')
                       end
                }
                
    -- close            
    t[#t+1] = {str = 'Close', func = function() gfx.quit() atexit( ) end} 
                
    OBJ.topline_menu = {is_button = true,  
                 x = 0,
                 y = 0,
                 w = DATA.GUIvars.menu_w,
                 h = DATA.GUIvars.menu_h,
                 txt= '>',
                 drawstr_flags = 1|4,
                 fontsz = DATA.GUIvars.menu_fontsz,
                 func_Ltrig =  function() VF_MOUSE_menu(MOUSE,OBJ,DATA,t) end}                
  end

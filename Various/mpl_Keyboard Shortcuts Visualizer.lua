-- @description Keyboard Shortcuts Visualizer
-- @version 1.0
-- @author MPL
-- @about Script for showing keyboard shortcuts
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Triggering physical keyboard trigger key selection
--    + Clicking virtual keyboard trigger key selection
--    + Hovering virtual keyboard show tooltip with key bindings
--    + Show keys assigned with some shortcut with another color
--    + Respond to some modifiers (CMD, Option not yet available in ReaImGui API, Win is reverse engineered)
--    + Allow to remove shortcuts
--    + Do not show tooltip if tooltip key is current key


--todo
-- different sections
-- midi/osc learn

    
local vrs = 1.0

--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.2'
  
  
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        viewport_posX = 10,
        viewport_posY = 10,
        viewport_posW = 1024,
        viewport_posH = 300, 
        categoriescnt = 16,
        search = '',
        
      }
for i =1, EXT.categoriescnt do EXT['category'..i..'_color'] = '' end
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'kb_shortcuts',
        UI_name = 'Keyboard Shortcuts Visualizer', 
        upd = true, 
        kb={},
        actions= {},
        section_ID = 0,
        selectedkey = '',
        
        reapervisiblemodifiers_mapping = {
            ['Ctrl'] = ImGui.Mod_Ctrl,
            ['Alt'] = ImGui.Mod_Alt,
            ['Shift'] = ImGui.Mod_Shift,
            ['Win'] = 1<<15, -- reversed, didn`t found this one from ReaImGui API
          },
          
        category={
          {name = 'All', color = 0x0F9F0F}, 
          
          {name = 'Item / Take',      color = 0xa4c5ea, str = 'item,take,comp'},
          {name = 'Track',            color = 0xF8FF02, str='track'},
          {name = 'FX',               color = 0xFFe0a3, str = 'fx,mixer'},
          {name = 'View / Navigation',color = 0x9de19a, str='view,grid,layout,marker,region,edit_cursor,play cursor,ruler,screenset,time_selection,toolbar'}, 
          {name = 'Automation',       color = 0xbca9e1, str = 'Automation,Envelope'}, 
          {name = 'Edit',             color = 0xedff71, str='edit'},   
          
          {name = 'Transport',        color = 0xf06543, str = 'transport'},  
          {name = 'Custom',           color = 0x4F3bFd, str='custom'},
          {name = 'Controller/Wheel', color = 0x08605f, str = 'OSC_only,MIDI_CC_relative,mousewheel'},
          {name = '3rd party',        color = 0xF03353, str='Script:,SWS,reapack'},
          },
          
        }
        
-------------------------------------------------------------------------------- INIT UI locals
for key in pairs(reaper) do _G[key]=reaper[key] end 
--local ctx
-------------------------------------------------------------------------------- UI init variables
  UI = {tempcoloring = {}}
-- font  
  UI.font='Arial'
  UI.font1sz=15
  UI.font2sz=14
  UI.font3sz=12
-- style
  UI.pushcnt = 0
  UI.pushcnt2 = 0
-- size / offset
  UI.spacingX = 2
  UI.spacingY = 3
-- mouse
  UI.hoverdelay = 0.3
  UI.hoverdelayshort = 0.1
-- colors 
  UI.main_col = 0x7F7F7F -- grey
  UI.textcol = 0xFFFFFF
  UI.but_hovered = 0x878787
  UI.windowBg = 0x303030
-- alpha
  UI.textcol_a_enabled = 1
  UI.textcol_a_disabled = 0.5
-- special 
  UI.butBg_green = 0x00B300
  UI.butBg_red = 0xB31F0F

-- size
  UI.main_W = 800
  UI.main_H = 600
  
--keyb vis
  UI.release_time = 0.5
  UI.main_butcol = 0x7F7F7F 
  UI.main_butcol_other = 0x0F9F0F
  UI.main_butcol_script = 0xFF0F0F
  UI.main_butcol_sws = 0x0F0FFF
  







function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  ------------------------------------------------------------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end              
-------------------------------------------------------------------------------- 
function DATA:Init_GetColorByActionName(action_name) 
  if not action_name then return end
  
  action_name = action_name:lower()
  for catID =1 , #DATA.category do
    local str = DATA.category[catID].str
    if str then
    
      if action_name:match(str:gsub('_', ' ')) then 
        return DATA.category[catID].color
      end
      
      str = str:lower()
      if str:match(',') then 
        for matchstr in str:gmatch('[^%,]+') do
          if action_name:match(matchstr:gsub('_', ' ')) then 
            return DATA.category[catID].color
          end
        end 
      end
    end
  end
  
  return DATA.category[1].color
end
-------------------------------------------------------------------------------- 
function DATA:Init_kbDefinition_ActionList() 
  local section_ID = DATA.section_ID
  
  local maxactionscnt = 100000
  local retval, name
  for cmdID = 0, maxactionscnt do
    local action_ID, action_name = kbd_enumerateActions( section_ID, cmdID )--Main=0, Main (alt recording)=100, MIDI Editor=32060, MIDI Event List Editor=32061, MIDI Inline Editor=32062, Media Explorer=32063
    if action_ID then
      local action_bindings = {}
      local shortcutscnt = CountActionShortcuts( section_ID, action_ID )
      for shortcutidx = 1, shortcutscnt do
        local retval, shortcut_str = GetActionShortcutDesc( section_ID, action_ID, shortcutidx-1 )
        
        local used_shortcuts_t = {}
        used_shortcuts_t.section_ID=section_ID
        used_shortcuts_t.action_ID=action_ID
        used_shortcuts_t.action_name=action_name
        used_shortcuts_t.shortcut_str=shortcut_str
        
        -- patch for parsing [Something] + [Num +]
          shortcut_str = shortcut_str:gsub('Num %+', 'Num plus')
        
        local modifierflags = 0
        if shortcut_str:match('+') then 
          for key in shortcut_str:gmatch('[^%+]+') do  
            local modkey_match
            for mod in pairs(DATA.reapervisiblemodifiers_mapping) do if key:match(mod) then modifierflags = modifierflags|DATA.reapervisiblemodifiers_mapping[mod] modkey_match = true end end --any of mod keys
            if not modkey_match then used_shortcuts_t.mainkey = key:gsub('Num plus','Num +') end
          end
         else
          used_shortcuts_t.mainkey = shortcut_str:gsub('Num plus','Num +')
        end 
        
        used_shortcuts_t.modifierflags=modifierflags
        used_shortcuts_t.shortcutidx= shortcutidx-1
        used_shortcuts_t.color = DATA:Init_GetColorByActionName(used_shortcuts_t.action_name)  
        DATA:Init_kbDefinition_firUItoActionList(used_shortcuts_t) 
        action_bindings[#action_bindings+1] = used_shortcuts_t
      end
      
      --local action_color = DATA:Init_GetColorByActionName(action_name) 
      DATA.actions[action_ID] = {action_name = action_name,action_bindings=action_bindings,action_color=action_color}
    end
  end
end
-------------------------------------------------------------------------------- 
function  DATA:Init_kbDefinition_firUItoActionList(used_shortcuts_t)
  if not (used_shortcuts_t and used_shortcuts_t.mainkey) then return end
  local mainkey = used_shortcuts_t.mainkey
  for key in pairs(DATA.kb) do
    if DATA.kb[key].mainkey and DATA.kb[key].mainkey == mainkey then
      if not DATA.kb[key].bindings then DATA.kb[key].bindings = {} end
      local bindingID = used_shortcuts_t.modifierflags 
      
      for key_shortcut in pairs(used_shortcuts_t) do
        if not DATA.kb[key].bindings[bindingID] then DATA.kb[key].bindings[bindingID] = {} end
        DATA.kb[key].bindings[bindingID][key_shortcut]=used_shortcuts_t[key_shortcut]
      end
      
      return
    end
  end 
end
-------------------------------------------------------------------------------- 
function  DATA:Init_kbDefinition_UI()
  -- lev1
  DATA.kb.esc = { block = 1, level = 1, pos = 1,extw = 1.5, reaimguikey = ImGui.Key_Escape,   mainkey = 'ESC'  }
  DATA.kb.F1 = { block = 1, level = 1, pos = 3,             reaimguikey = ImGui.Key_F1,       mainkey = 'F1' }
  DATA.kb.F2 = { block = 1, level = 1, pos = 4,             reaimguikey = ImGui.Key_F2,       mainkey = 'F2'  }
  DATA.kb.F3 = { block = 1, level = 1, pos = 5,             reaimguikey = ImGui.Key_F3,       mainkey = 'F3'  }
  DATA.kb.F4 = { block = 1, level = 1, pos = 6,             reaimguikey = ImGui.Key_F4,       mainkey = 'F4'  }
  DATA.kb.F5 = { block = 1, level = 1, pos = 7,             reaimguikey = ImGui.Key_F5,       mainkey = 'F5'  }
  DATA.kb.F6 = { block = 1, level = 1, pos = 8,             reaimguikey = ImGui.Key_F6,       mainkey = 'F6'  }
  DATA.kb.F7 = { block = 1, level = 1, pos = 9,             reaimguikey = ImGui.Key_F7,       mainkey = 'F7'  }
  DATA.kb.F8 = { block = 1, level = 1, pos = 10,            reaimguikey = ImGui.Key_F8,       mainkey = 'F8'  }
  DATA.kb.F9 = { block = 1, level = 1, pos = 11,            reaimguikey = ImGui.Key_F9,       mainkey = 'F9'  }
  DATA.kb.F10 = { block = 1, level = 1, pos = 12,           reaimguikey = ImGui.Key_F10,      mainkey = 'F10'  }
  DATA.kb.F11 = { block = 1, level = 1, pos = 13,           reaimguikey = ImGui.Key_F11,      mainkey = 'F11'  }
  DATA.kb.F12 = { block = 1, level = 1, pos = 14,           reaimguikey = ImGui.Key_F12,      mainkey = 'F12'  }
  
  --DATA.kb['PrtScr'] = { block = 2, level = 1, pos = 1,      reaimguikey = ImGui.Key_PrintScreen   }
  --DATA.kb['Scroll\nLock'] = { block = 2, level = 1, pos = 2,reaimguikey = ImGui.Key_ScrollLock}
  --DATA.kb['Pause'] = { block = 2, level = 1, pos = 3,       reaimguikey = ImGui.Key_Pause }
  
  --[[DATA.kb.res2 = { block = 3, level = 1, pos = 1 }
  DATA.kb.res3 = { block = 3, level = 1, pos = 2 }
  DATA.kb.res4 = { block = 3, level = 1, pos = 3 }
  DATA.kb.res5 = { block = 3, level = 1, pos = 4 }]]
  
  -- lev2
  DATA.kb['~'] = { block = 1, level = 2, pos = 1,            reaimguikey = ImGui.Key_GraveAccent,           mainkey = '`'   }
  DATA.kb['1'] = { block = 1, level = 2, pos = 2,            reaimguikey = ImGui.Key_1,      mainkey = '1'   }
  DATA.kb['2'] = { block = 1, level = 2, pos = 3,            reaimguikey = ImGui.Key_2,      mainkey = '2'   }
  DATA.kb['3'] = { block = 1, level = 2, pos = 4,            reaimguikey = ImGui.Key_3,      mainkey = '3'   }
  DATA.kb['4'] = { block = 1, level = 2, pos = 5,            reaimguikey = ImGui.Key_4,      mainkey = '4'   }
  DATA.kb['5'] = { block = 1, level = 2, pos = 6,            reaimguikey = ImGui.Key_5,      mainkey = '5'   }
  DATA.kb['6'] = { block = 1, level = 2, pos = 7,            reaimguikey = ImGui.Key_6,      mainkey = '6'     }
  DATA.kb['7'] = { block = 1, level = 2, pos = 8,            reaimguikey = ImGui.Key_7,      mainkey = '7'     }
  DATA.kb['8'] = { block = 1, level = 2, pos = 9,            reaimguikey = ImGui.Key_8,      mainkey = '8'     }
  DATA.kb['9'] = { block = 1, level = 2, pos = 10,           reaimguikey = ImGui.Key_9,      mainkey = '9'     }
  DATA.kb['0'] = { block = 1, level = 2, pos = 11,           reaimguikey = ImGui.Key_0,      mainkey = '0'     }
  DATA.kb['-'] = { block = 1, level = 2, pos = 12,           reaimguikey = ImGui.Key_Minus,  mainkey = '-'      }
  DATA.kb['='] = { block = 1, level = 2, pos = 13,           reaimguikey = ImGui.Key_Equal,  mainkey = '='     }
  DATA.kb['Back\nSpace'] = { block = 1, level = 2, pos = 14,extw = 2,reaimguikey = ImGui.Key_Backspace,mainkey = 'Backspace'     }
  
  DATA.kb.Insert = { block = 2, level = 2, pos = 1,          reaimguikey = ImGui.Key_Insert, mainkey = 'Insert'     }
  DATA.kb.Home = { block = 2, level = 2, pos = 2,            reaimguikey = ImGui.Key_Home,   mainkey = 'Home'     }
  DATA.kb['Page\nUp'] = { block = 2, level = 2, pos = 3,     reaimguikey = ImGui.Key_PageUp, mainkey = 'Page Up'     }
  
  DATA.kb['Num\nLock'] = { block = 3, level = 2, pos = 1,    reaimguikey = ImGui.Key_NumLock, disabled = true }
  DATA.kb['/##Num/'] = { block = 3, level = 2, pos = 2,      reaimguikey = ImGui.Key_KeypadDivide, mainkey = 'Num /' }
  DATA.kb['*##Num*'] = { block = 3, level = 2, pos = 3,      reaimguikey = ImGui.Key_KeypadMultiply, mainkey = 'Num *' }
  DATA.kb['-##Num-'] = { block = 3, level = 2, pos = 4,      reaimguikey = ImGui.Key_KeypadSubtract, mainkey = 'Num -' }
  
  -- lev3
  DATA.kb['Tab'] = { block = 1, level = 3, pos = 1,extw = 1.5,reaimguikey = ImGui.Key_Tab,    mainkey = 'Tab'   }
  DATA.kb.Q = { block = 1, level = 3, pos = 2.5,             reaimguikey = ImGui.Key_Q,       mainkey = 'Q'   }
  DATA.kb.W = { block = 1, level = 3, pos = 3.5,             reaimguikey = ImGui.Key_W,       mainkey = 'W'  }
  DATA.kb.E = { block = 1, level = 3, pos = 4.5,             reaimguikey = ImGui.Key_E,       mainkey = 'E'  }
  DATA.kb.R = { block = 1, level = 3, pos = 5.5,             reaimguikey = ImGui.Key_R,       mainkey = 'R'  }
  DATA.kb.T = { block = 1, level = 3, pos = 6.5,             reaimguikey = ImGui.Key_T,       mainkey = 'T'  }
  DATA.kb.Y = { block = 1, level = 3, pos = 7.5,             reaimguikey = ImGui.Key_Y,       mainkey = 'Y'  }
  DATA.kb.U = { block = 1, level = 3, pos = 8.5,             reaimguikey = ImGui.Key_U,       mainkey = 'U'  }
  DATA.kb.I = { block = 1, level = 3, pos = 9.5,             reaimguikey = ImGui.Key_I,       mainkey = 'I'  }
  DATA.kb.O = { block = 1, level = 3, pos = 10.5,            reaimguikey = ImGui.Key_O,       mainkey = 'O'  }
  DATA.kb.P = { block = 1, level = 3, pos = 11.5,            reaimguikey = ImGui.Key_P,       mainkey = 'P'  }
  DATA.kb['['] = { block = 1, level = 3, pos = 12.5,         reaimguikey = ImGui.Key_LeftBracket,mainkey = '['  }
  DATA.kb[']'] = { block = 1, level = 3, pos = 13.5,         reaimguikey = ImGui.Key_RightBracket,mainkey = ']'  }
  DATA.kb['\\'] = { block = 1, level = 3, pos = 14.5,        reaimguikey = ImGui.Key_Backslash, mainkey = '\\'  }
  
  DATA.kb.Del = { block = 2, level = 3, pos = 1,             reaimguikey = ImGui.Key_Delete,  mainkey = 'Delete' }
  DATA.kb.End = { block = 2, level = 3, pos = 2,             reaimguikey = ImGui.Key_End,     mainkey = 'End' }
  DATA.kb['Page\nDown'] = { block = 2, level = 3, pos = 3,   reaimguikey = ImGui.Key_PageDown,mainkey = 'Page Down' }
  
  DATA.kb['7##Num7'] = { block = 3, level = 3, pos = 1,      reaimguikey = ImGui.Key_Keypad7, mainkey = 'Num 7'  }
  DATA.kb['8##Num8'] = { block = 3, level = 3, pos = 2,      reaimguikey = ImGui.Key_Keypad8, mainkey = 'Num 8' }
  DATA.kb['9##Num9'] = { block = 3, level = 3, pos = 3,      reaimguikey = ImGui.Key_Keypad9, mainkey = 'Num 9' }
  DATA.kb['+##Num+'] = { block = 3, level = 3, pos = 4,exth = 2,reaimguikey = ImGui.Key_KeypadAdd, mainkey = 'Num +' }
  
  -- lev3
  DATA.kb['Caps\nLock'] = { block = 1, level = 4, pos = 1,extw = 2,reaimguikey = ImGui.Key_CapsLock,disabled=true  }
  DATA.kb.A = { block = 1, level = 4, pos = 3,                reaimguikey = ImGui.Key_A,      mainkey = 'A'   }
  DATA.kb.S = { block = 1, level = 4, pos = 4,                reaimguikey = ImGui.Key_S,      mainkey = 'S'  }
  DATA.kb.D = { block = 1, level = 4, pos = 5,                reaimguikey = ImGui.Key_D,      mainkey = 'D'  }
  DATA.kb.F = { block = 1, level = 4, pos = 6,                reaimguikey = ImGui.Key_F,      mainkey = 'F'  }
  DATA.kb.G = { block = 1, level = 4, pos = 7,                reaimguikey = ImGui.Key_G,      mainkey = 'G'  }
  DATA.kb.H = { block = 1, level = 4, pos = 8,                reaimguikey = ImGui.Key_H,      mainkey = 'H'  }
  DATA.kb.J = { block = 1, level = 4, pos = 9,                reaimguikey = ImGui.Key_J,      mainkey = 'J'  }
  DATA.kb.K = { block = 1, level = 4, pos = 10,               reaimguikey = ImGui.Key_K,      mainkey = 'K'  }
  DATA.kb.L = { block = 1, level = 4, pos = 11,               reaimguikey = ImGui.Key_L,      mainkey = 'L'  }
  DATA.kb[';'] = { block = 1, level = 4, pos = 12,            reaimguikey = ImGui.Key_Semicolon,      mainkey = ';'  }
  DATA.kb["'"] = { block = 1, level = 4, pos = 13,            reaimguikey = ImGui.Key_Apostrophe,      mainkey = "'"  }
  DATA.kb['Enter'] = { block = 1, level = 4, pos = 14,extw = 2,reaimguikey = ImGui.Key_Enter,      mainkey = 'Enter'    }
  
  DATA.kb['4##Num4'] = { block = 3, level = 4, pos = 1,       reaimguikey = ImGui.Key_Keypad4,      mainkey = 'Num 4'    }
  DATA.kb['5##Num5'] = { block = 3, level = 4, pos = 2,       reaimguikey = ImGui.Key_Keypad5,      mainkey = 'Num 5' }
  DATA.kb['6##Num6'] = { block = 3, level = 4, pos = 3,       reaimguikey = ImGui.Key_Keypad6,      mainkey = 'Num 6' }
  
  -- lev4
  DATA.kb['Shift##Lshift'] = { block = 1, level = 5, pos = 1,extw = 2,reaimguikey = ImGui.Key_LeftShift, disabled = true   }
  DATA.kb.Z = { block = 1, level = 5, pos = 3,                reaimguikey = ImGui.Key_Z,      mainkey = 'Z'  }
  DATA.kb.X = { block = 1, level = 5, pos = 4,                reaimguikey = ImGui.Key_X,      mainkey = 'X'   }
  DATA.kb.C = { block = 1, level = 5, pos = 5,                reaimguikey = ImGui.Key_C,      mainkey = 'C'   }
  DATA.kb.V = { block = 1, level = 5, pos = 6,                reaimguikey = ImGui.Key_V,      mainkey = 'V'   }
  DATA.kb.B = { block = 1, level = 5, pos = 7,                reaimguikey = ImGui.Key_B,      mainkey = 'B'   }
  DATA.kb.N = { block = 1, level = 5, pos = 8,                reaimguikey = ImGui.Key_N,      mainkey = 'N'   }
  DATA.kb.M = { block = 1, level = 5, pos = 9,                reaimguikey = ImGui.Key_M,      mainkey = 'M'   }
  DATA.kb['<'] = { block = 1, level = 5, pos = 10,            reaimguikey = ImGui.Key_Comma,  mainkey = ','   }
  DATA.kb['>'] = { block = 1, level = 5, pos = 11,            reaimguikey = ImGui.Key_Period, mainkey = '.'   }
  DATA.kb['?'] = { block = 1, level = 5, pos = 12,            reaimguikey = ImGui.Key_Slash,  mainkey = '/'  }
  DATA.kb['Shift##Rshift'] = { block = 1, level = 5, pos = 13,extw = 2,reaimguikey = ImGui.Key_RightShift, disabled = true   }
  
  DATA.kb['Up##ArrUp'] = { block = 2, level = 5, pos = 2,     reaimguikey = ImGui.Key_UpArrow,mainkey = 'Up' }
  
  DATA.kb['1##Num1'] = { block = 3, level = 5, pos = 1,       reaimguikey = ImGui.Key_Keypad1,      mainkey = 'Num 1'  }
  DATA.kb['2##Num2'] = { block = 3, level = 5, pos = 2,       reaimguikey = ImGui.Key_Keypad2,      mainkey = 'Num 2'  }
  DATA.kb['3##Num3'] = { block = 3, level = 5, pos = 3,       reaimguikey = ImGui.Key_Keypad3,      mainkey = 'Num 3'  }
  DATA.kb['Enter##NumEnter'] = { block = 3, level = 5, pos = 4,exth = 2,reaimguikey = ImGui.Key_KeypadEnter,mainkey = 'Num Enter'  }
  
  -- lev5
  DATA.kb['Ctrl##LCtrl'] = { block = 1, level = 6, pos = 1,extw = 1.5,   reaimguikey = ImGui.Key_LeftCtrl, disabled = true} 
  DATA.kb['Alt'] = { block = 1, level = 6, pos = 2.5,           reaimguikey = ImGui.Key_LeftAlt, disabled = true  }
  DATA.kb['Win'] = { block = 1, level = 6, pos = 3.5,           disabled = true}
  DATA.kb['Option'] = { block = 1, level = 6, pos = 4.5,        disabled = true }
  DATA.kb['Cmd'] = { block = 1, level = 6, pos = 5.5,           disabled = true}
  DATA.kb['Space'] = { block = 1, level = 6, pos = 6.5,extw = 3,reaimguikey = ImGui.Key_Space,      mainkey = 'Space'  }
  DATA.kb['Alt##Ralt'] = { block = 1, level = 6, pos = 9.5,    reaimguikey = ImGui.Key_RightAlt,   disabled = true  }
  DATA.kb['Ctrl##RCtrl'] = { block = 1, level = 6, pos = 10.5,extw = 1.5,  reaimguikey = ImGui.Key_RightCtrl,  disabled = true}
  
  DATA.kb['Left##ArrLeft'] = { block = 2, level = 6, pos = 1, reaimguikey = ImGui.Key_LeftArrow,   mainkey = 'Left' }
  DATA.kb['Down##ArrDown'] = { block = 2, level = 6, pos = 2, reaimguikey = ImGui.Key_DownArrow,   mainkey = 'Down' }
  DATA.kb['Right##ArrRight'] = { block = 2, level = 6, pos = 3,reaimguikey = ImGui.Key_RightArrow, mainkey = 'Right' } 
  
  DATA.kb['0##Num0'] = { block = 3, level = 6, pos = 1, extw = 2,reaimguikey = ImGui.Key_Keypad0,  mainkey = 'Num 0'}
  DATA.kb[',##NumDel'] = { block = 3, level = 6, pos = 3,   reaimguikey = ImGui.Key_KeypadDecimal, mainkey = 'Num Del' }
end
--------------------------------------------------------------------------------  
function UI.MAIN_calc() 
  -- define x/w
  UI.calc_butHref= 35
  UI.calc_spacingX_wide = UI.spacingX * 4
  UI.calc_spacingY_wide = UI.spacingY * 4
  
  UI.calc_butW = {}
  UI.calc_blockoffs_X= {}
  
  UI.calc_butW[1] = math.floor((DATA.display_w - UI.calc_spacingX_wide*4 - UI.spacingX*18)/21) 
  UI.calc_blockoffs_X[1] = UI.calc_spacingX_wide
  UI.calc_blockoffs_X[2] = UI.calc_spacingX_wide*2 + UI.calc_butW[1]*14 + UI.spacingX*13
  UI.calc_blockoffs_X[3] = UI.calc_spacingX_wide*3 + UI.calc_butW[1]*17 + UI.spacingX*16
  
  -- define async but w
  local mainblockw = UI.calc_blockoffs_X[2] - UI.calc_blockoffs_X[1] - UI.calc_spacingX_wide 
  UI.calc_butW[2] = ((mainblockw- UI.spacingX*14) / 15 )
  UI.calc_butW[3] = ((mainblockw- UI.spacingX*13.5) / 14.5 )
  UI.calc_butW[4] = ((mainblockw- UI.spacingX*14) / 15 )
  UI.calc_butW[5] = ((mainblockw- UI.spacingX*13) / 14 )
  UI.calc_butW[6] = ((mainblockw- UI.spacingX*10) / 11 )
  --UI.calc_mainblockw=mainblockw
    
  -- define y/h
  UI.calc_butH = {
    math.floor(UI.calc_butHref*0.8),
    math.floor(UI.calc_butHref*1.2),
    UI.calc_butHref,
    UI.calc_butHref,
    UI.calc_butHref,
    UI.calc_butHref,
    }
  UI.calc_blockoffs_Y= {
    UI.calc_itemH+UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.calc_spacingY_wide,
    }
    
  -- define current action
    local subblockW = UI.calc_butW[1] * 7 + UI.calc_spacingX_wide + UI.spacingX * 5
    UI.calc_KeyDetails_x = UI.calc_spacingX_wide + UI.calc_butW[1]*4 + UI.spacingX * 3
    UI.calc_KeyDetails_y = UI.calc_blockoffs_Y[7]
    UI.calc_KeyDetails_w = subblockW
    
    UI.calc_KeyCategories_x = UI.calc_spacingX_wide
    UI.calc_KeyCategories_y = UI.calc_KeyDetails_y
    UI.calc_KeyCategories_w = UI.calc_butW[1]*4 + UI.spacingX * 2
    
    UI.calc_ActList_x = UI.calc_spacingX_wide + UI.calc_butW[1]*4 + UI.spacingX * 3
    UI.calc_ActList_y = UI.calc_KeyDetails_y
    UI.calc_ActList_w = UI.calc_KeyDetails_x - (UI.calc_KeyCategories_x + UI.calc_KeyCategories_w) - UI.calc_spacingX_wide
end
-------------------------------------------------------------------------------- 
function DATA:SetSelectionFromReimGuiKey(reaimguikey)
  for key in pairs(DATA.kb) do
    if DATA.kb[key].disabled ~= true and DATA.kb[key].reaimguikey and DATA.kb[key].reaimguikey  == reaimguikey then
      DATA.selectedkey = key
      return
    end
  end
end
-------------------------------------------------------------------------------- 
function UI.HelpMarker(desc)
  if ImGui.BeginItemTooltip(ctx) then
    ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
    ImGui.Text(ctx, desc)
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  end
end
-------------------------------------------------------------------------------- 
function UI.draw_KeyDetails_tooltip(key_src)
  if key_src == DATA.selectedkey then return end
  if ImGui.BeginItemTooltip(ctx) then
    
    
    local Shift_flag = DATA.reapervisiblemodifiers_mapping.Shift
    local Ctrl_flag = DATA.reapervisiblemodifiers_mapping.Ctrl
    local Alt_flag = DATA.reapervisiblemodifiers_mapping.Alt
    local Win_flag = DATA.reapervisiblemodifiers_mapping.Win
    
    local modifiers = {
      {str = '-', flags = 0},
      {str = 'Shift', flags = Shift_flag},
      {str = 'Ctrl', flags = Ctrl_flag},
      {str = 'Shift+Ctrl', flags = Shift_flag|Ctrl_flag},
      {str = 'Alt', flags = Alt_flag},
      {str = 'Shift+Alt', flags = Shift_flag|Alt_flag},
      {str = 'Ctrl+Alt', flags = Ctrl_flag|Alt_flag},
      {str = 'Shift+Ctrl+Alt', flags = Shift_flag|Ctrl_flag|Alt_flag},
      
      {str = 'Win', flags = Win_flag}, 
      {str = 'Shift+Win', flags = Shift_flag|Win_flag},
      {str = 'Ctrl+Win', flags = Ctrl_flag|Win_flag},
      {str = 'Shift+Ctrl+Win', flags = Shift_flag|Ctrl_flag|Win_flag},
      {str = 'Alt+Win', flags = Alt_flag|Win_flag},
      {str = 'Shift+Alt+Win', flags = Shift_flag|Alt_flag|Win_flag},
      {str = 'Ctrl+Alt+Win', flags = Ctrl_flag|Alt_flag|Win_flag},
      {str = 'Shift+Ctrl+Alt+Win', flags = Shift_flag|Ctrl_flag|Alt_flag|Win_flag},
      
      
      }
    
    for i = 1 , #modifiers do
      if DATA.kb[key_src].bindings and DATA.kb[key_src].bindings[modifiers[i].flags] then
        local strmod = modifiers[i].str
        if modifiers[i].str == '-' then strmod = 'No modifier' end
        ImGui.Selectable(ctx,strmod..':')ImGui.SameLine(ctx)
        ImGui.SetCursorPosX( ctx, 100 )
        ImGui.Selectable(ctx,DATA.kb[key_src].bindings[modifiers[i].flags].action_name)
      end
    end
    
    ImGui.EndTooltip(ctx)
  end
end
-------------------------------------------------------------------------------- 
function UI.draw_ActionList() 
  ImGui.SetCursorPos( ctx, UI.calc_ActList_x, UI.calc_ActList_y ) 
    
  if ImGui.BeginChild( ctx, 'actlist', UI.calc_ActList_w, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None|ImGui.WindowFlags_MenuBar ) then
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,5,2)
    if ImGui.BeginMenuBar( ctx ) then
      if ImGui.BeginMenu(ctx, 'Search action list:') then 
        ImGui.EndMenu(ctx)
      end
      local retval, buf = ImGui.InputText( ctx, '##Search', EXT.search,ImGui.InputTextFlags_AutoSelectAll )--|ImGui.InputTextFlags_EnterReturnsTrue
      if retval == true then 
        EXT.search = buf
        DATA:Init_Search_ActionList() 
        EXT:save()
      end
      ImGui.EndMenuBar( ctx ) 
    end
    
    for actionID in pairs(DATA.actions) do
      if DATA.actions[actionID].fitsearch == true then
        ImGui.Selectable(ctx,DATA.actions[actionID].action_name ) 
        if ImGui.BeginDragDropSource( ctx, ImGui.DragDropFlags_None ) then
          ImGui.SetDragDropPayload(ctx, 'actiondrop', actionID, ImGui.Cond_Always) 
          ImGui.EndDragDropSource(ctx)
        end
        
      end
    end
    
    ImGui.PopStyleVar(ctx,1)
    ImGui.EndChild( ctx)
  end 
end
-------------------------------------------------------------------------------- 
function UI.draw_KeyCategories()
  local indent = 7
  ImGui.SetCursorPos( ctx, UI.calc_KeyCategories_x, UI.calc_KeyCategories_y ) 
    
  if ImGui.BeginChild( ctx, 'categories', UI.calc_KeyCategories_w, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None|ImGui.WindowFlags_MenuBar ) then
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,5,2)
    if ImGui.BeginMenuBar( ctx ) then
      if ImGui.BeginMenu(ctx, 'Categories') then 
        ImGui.EndMenu(ctx)
      end
      ImGui.EndMenuBar( ctx ) 
    end
    
    --ImGui.PushFont(ctx, DATA.font3) 
    ImGui.Indent(ctx,indent)
    for catID = 1, #DATA.category do  
      local retval, col_rgb = ImGui.ColorEdit3(ctx, '##cat'..catID, DATA.category[catID].color, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs)
      if retval then
        DATA.category[catID].col = col_rgb
        EXT['category'..catID..'_col'] = col_rgb
        EXT:save()
      end
      if ImGui.IsItemDeactivatedAfterEdit( ctx ) then
        DATA:CollectData()
      end
      ImGui.SameLine(ctx) ImGui.Selectable( ctx, DATA.category[catID].name ) 
    end
    
    
    
    ImGui.Unindent(ctx,indent)
    --ImGui.PopFont(ctx)
    
    ImGui.PopStyleVar(ctx,1)
    ImGui.EndChild( ctx)
  end 
end
-------------------------------------------------------------------------------- 
function UI.draw_KeyDetails(key_src0) 
  local key_src = key_src0
  if not key_src0 then key_src = DATA.selectedkey end
  if not (key_src ~= '' and DATA.kb[key_src]) then return end
  
  if key_src0 == nil then 
    ImGui.SetCursorPos( ctx, UI.calc_KeyDetails_x, UI.calc_KeyDetails_y ) 
  end
    
  if ImGui.BeginChild( ctx, 'currentkey'..key_src, 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None|ImGui.WindowFlags_MenuBar ) then--UI.calc_KeyDetails_w
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,5,2)
    if ImGui.BeginMenuBar( ctx ) then
      if ImGui.BeginMenu(ctx, 'Key details ['..DATA.selectedkey..']:') then
      
        --ImGui.SeparatorText(ctx, 'Actions')
        
        ImGui.EndMenu(ctx)
      end
      ImGui.EndMenuBar( ctx ) 
    end
    
    ImGui.PushFont(ctx, DATA.font3) 
    local Shift_flag = DATA.reapervisiblemodifiers_mapping.Shift
    local Ctrl_flag = DATA.reapervisiblemodifiers_mapping.Ctrl
    local Alt_flag = DATA.reapervisiblemodifiers_mapping.Alt
    local Win_flag = DATA.reapervisiblemodifiers_mapping.Win
    
    local modifiers = {
      {str = '-', flags = 0},
      {str = 'Shift', flags = Shift_flag},
      {str = 'Ctrl', flags = Ctrl_flag},
      {str = 'Shift+Ctrl', flags = Shift_flag|Ctrl_flag},
      {str = 'Alt', flags = Alt_flag},
      {str = 'Shift+Alt', flags = Shift_flag|Alt_flag},
      {str = 'Ctrl+Alt', flags = Ctrl_flag|Alt_flag},
      {str = 'Shift+Ctrl+Alt', flags = Shift_flag|Ctrl_flag|Alt_flag},
      
      {str = 'Win', flags = Win_flag}, 
      {str = 'Shift+Win', flags = Shift_flag|Win_flag},
      {str = 'Ctrl+Win', flags = Ctrl_flag|Win_flag},
      {str = 'Shift+Ctrl+Win', flags = Shift_flag|Ctrl_flag|Win_flag},
      {str = 'Alt+Win', flags = Alt_flag|Win_flag},
      {str = 'Shift+Alt+Win', flags = Shift_flag|Alt_flag|Win_flag},
      {str = 'Ctrl+Alt+Win', flags = Ctrl_flag|Alt_flag|Win_flag},
      {str = 'Shift+Ctrl+Alt+Win', flags = Shift_flag|Ctrl_flag|Alt_flag|Win_flag},
      
      
      }
    if ImGui.BeginTable(ctx, 'currentkeytable', 2, ImGui.TableFlags_None|ImGui.TableFlags_BordersInnerV, 0, 0, 0) then 
      ImGui.TableSetupColumn(ctx, 'Modifier', ImGui.TableColumnFlags_None|ImGui.TableColumnFlags_WidthFixed, 100, 0)
      ImGui.TableSetupColumn(ctx, 'Command', ImGui.TableColumnFlags_None|ImGui.TableColumnFlags_WidthStretch, 0.65, 1)
      ImGui.TableHeadersRow(ctx)
      for i = 1 , #modifiers do
        ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None,0)
        
        -- remove + modifier
          ImGui.TableSetColumnIndex(ctx,0)
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,1,1)
          if ImGui.Button(ctx, 'X##'..i) then
            local binding = DATA.kb[key_src].bindings[modifiers[i].flags]
            local section = binding.section_ID
            local cmdID = binding.action_ID
            local shortcutidx = binding.shortcutidx 
            DeleteActionShortcut( section, cmdID, shortcutidx )
            DATA.upd = true
          end
          ImGui.SameLine(ctx)
          ImGui.Selectable(ctx,modifiers[i].str)
          ImGui.PopStyleVar(ctx,1) 
        
        -- action
          ImGui.TableSetColumnIndex(ctx,1)
          local actionname = '-'
          if DATA.kb[key_src].bindings and DATA.kb[key_src].bindings[modifiers[i].flags] then actionname = DATA.kb[key_src].bindings[modifiers[i].flags].action_name end
          ImGui.Selectable(ctx,actionname)
          if ImGui.BeginDragDropTarget( ctx ) then
            local rv,cmdID = ImGui.AcceptDragDropPayload(ctx, 'actiondrop')
            if rv then
              DoActionShortcutDialog( hwnd, DATA.section_ID, cmdID, -1 )
              --[[msg(payload)
              msg(1)
              DATA:CollectData()]]
            end 
            ImGui.EndDragDropTarget( ctx )
          end
          --[[
          if retval then 
            msg(payload)
          end]]
      end
      ImGui.EndTable(ctx)
    end
    
    ImGui.PopFont(ctx)
    
    ImGui.PopStyleVar(ctx,1)
    ImGui.EndChild( ctx)
  end   
end
-------------------------------------------------------------------------------- 
function UI.draw_keyb() 
  --test
  --[[
  ImGui.SetCursorPos( ctx, UI.calc_blockoffs_X[1], UI.calc_blockoffs_Y[1]+80 )
  ImGui.Button(ctx, 'test',UI.calc_mainblockw,20)
  ]]
  
  ImGui.PushFont(ctx, DATA.font2) 
  local local_pos_x, local_pos_y
  for key in pairs(DATA.kb) do
    local block = DATA.kb[key].block
    local level = DATA.kb[key].level
    local pos =   DATA.kb[key].pos
    local extw =   DATA.kb[key].extw or 1
    local exth =   DATA.kb[key].exth or 1
    local_pos_x = UI.calc_blockoffs_X[block] + (UI.calc_butW[level] * (pos-1)) + UI.spacingX*(pos-1)
    local_pos_y = UI.calc_blockoffs_Y[level]
    local butw = UI.calc_butW[level]*extw+(extw-1)*UI.spacingX
    local buth = UI.calc_butH[level]*exth+(exth-1)*UI.spacingY
    if block == 2 or block == 3 then
      local_pos_x = UI.calc_blockoffs_X[block] + (UI.calc_butW[1] * (pos-1)) + UI.spacingX*(pos-1)
      butw = UI.calc_butW[1]*extw+(extw-1)*UI.spacingX
    end
    ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y )
    
    local col = UI.draw_keyb_definecolor(DATA.kb[key])
    
    local alphanormal0 = 0.5
    UI.draw_keyb_handleKBpress(DATA.kb[key])  
    if DATA.kb[key].state_pressed == true then alphanormal = 0.8 else alphanormal = alphanormal0 end
    if DATA.kb[key].state_release_fall == true then
      alphanormal = alphanormal0 + alphanormal * (1-DATA.kb[key].state_release_alphamult)
    end
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, math.floor(alphanormal*255)|(col<<8) )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, math.floor(0.9*255)|(col<<8) )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, math.floor(0.6*255)|(col<<8) )
    ImGui.BeginDisabled(ctx, DATA.kb[key].disabled or false)
    
    -- actually key
    local butx,buty,butx2,buty2=0,0,0,0
    if ImGui.Button(ctx, key,butw,buth) then
      DATA.selectedkey = key
    end
    butx, buty = ImGui.GetItemRectMin(ctx)
    butx2, buty2 = ImGui.GetItemRectMax(ctx)
    UI.draw_KeyDetails_tooltip(key)
    
    -- selection
    if DATA.selectedkey~= '' and DATA.selectedkey == key then
      local draw_list = ImGui.GetWindowDrawList(ctx)
      ImGui.DrawList_AddRect( draw_list, butx, buty,butx2,buty2, 0xFFFFFF8F, 5, ImGui.DrawFlags_None, 1)
    end
    
    ImGui.EndDisabled(ctx)
    ImGui.PopStyleColor(ctx, 3)
  end
  ImGui.PopFont(ctx)
end
-------------------------------------------------------------------------------- 
function UI.draw_keyb_definecolor(kbt) 
  -- get color
    local inactive_col = UI.main_butcol 
    local active_col = UI.main_butcol_other
    if kbt.bindings and kbt.bindings[tflags] and kbt.bindings[tflags].color then active_col = kbt.bindings[tflags].color end
    
  -- return col
  if kbt.bindings then
    tflags = ImGui.GetKeyMods( ctx )
    if kbt.bindings[tflags] then -- no modifier flags
      
      return active_col
    end
  end
  
  return inactive_col
end
-------------------------------------------------------------------------------- 
function UI.draw_keyb_handleKBpress(keyt) 
  if not keyt.reaimguikey then return end
  keyt.state_pressed = false
  if ImGui.IsKeyDown( ctx, keyt.reaimguikey ) then keyt.state_pressed = true end
  
  -- handle smooth UI release 
  if ImGui.IsKeyReleased( ctx, keyt.reaimguikey ) then 
    DATA:SetSelectionFromReimGuiKey(keyt.reaimguikey)
    keyt.state_releaseTS = os.clock() 
  end
  keyt.state_release_fall = false
  keyt.state_release_alphamult = 0
  if keyt.state_releaseTS and os.clock() - keyt.state_releaseTS  <UI.release_time  then
    keyt.state_release_fall = true
    keyt.state_release_alphamult = ((os.clock() - keyt.state_releaseTS)  / UI.release_time )
  end
  
  
end
-------------------------------------------------------------------------------- 
function UI.MAIN_PushStyle(key, value, value2)  
  if not ctx then return end
  local iscol = key:match('Col_')~=nil
  local keyid = ImGui[key]
  if not iscol then 
    ImGui.PushStyleVar(ctx, keyid, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  local w_min = UI.main_W + UI.spacingX*2
  local h_min = UI.main_H
  
  
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    --window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    window_flags = window_flags | ImGui.WindowFlags_NoDocking
    window_flags = window_flags | ImGui.WindowFlags_TopMost
    window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings() end
    --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
    --open = false -- disable the close button
  
  
    -- set style
      UI.pushcnt = 0
      UI.pushcnt2 = 0
    -- rounding
      UI.MAIN_PushStyle('StyleVar_FrameRounding',5)  
      UI.MAIN_PushStyle('StyleVar_GrabRounding',3)  
      UI.MAIN_PushStyle('StyleVar_WindowRounding',10)  
      UI.MAIN_PushStyle('StyleVar_ChildRounding',5)  
      UI.MAIN_PushStyle('StyleVar_PopupRounding',0)  
      UI.MAIN_PushStyle('StyleVar_ScrollbarRounding',9)  
      UI.MAIN_PushStyle('StyleVar_TabRounding',4)   
    -- Borders
      UI.MAIN_PushStyle('StyleVar_WindowBorderSize',0)  
      UI.MAIN_PushStyle('StyleVar_FrameBorderSize',0) 
    -- spacing
      UI.MAIN_PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
      UI.MAIN_PushStyle('StyleVar_FramePadding',UI.spacingX,UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
      UI.MAIN_PushStyle('StyleVar_ItemInnerSpacing',4,0)
      UI.MAIN_PushStyle('StyleVar_IndentSpacing',20)
      UI.MAIN_PushStyle('StyleVar_ScrollbarSize',10)
    -- size
      UI.MAIN_PushStyle('StyleVar_GrabMinSize',20)
      UI.MAIN_PushStyle('StyleVar_WindowMinSize',w_min,h_min)
    -- align
      UI.MAIN_PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      --UI.MAIN_PushStyle('StyleVar_SelectableTextAlign,0,0 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextAlign,0,0.5 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextPadding,20,3 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextBorderSize,3 )
    -- alpha
      UI.MAIN_PushStyle('StyleVar_Alpha',0.98)
      --UI.MAIN_PushStyle('StyleVar_DisabledAlpha,0.6 ) 
      UI.MAIN_PushStyle('Col_Border',UI.main_col, 0.3)
    -- colors
      --UI.MAIN_PushStyle('Col_BorderShadow(),0xFFFFFF, 1)
      UI.MAIN_PushStyle('Col_Button',UI.main_col, 0.2) --0.3
      UI.MAIN_PushStyle('Col_ButtonActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
      --UI.MAIN_PushStyle('Col_CheckMark(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true) 
      
      
      --Constant: Col_DockingEmptyBg
      --Constant: Col_DockingPreview
      --Constant: Col_DragDropTarget 
      UI.MAIN_PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
      UI.MAIN_PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
      UI.MAIN_PushStyle('Col_FrameBgActive',UI.main_col, .6)
      UI.MAIN_PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
      UI.MAIN_PushStyle('Col_Header',UI.main_col, 0.5) 
      UI.MAIN_PushStyle('Col_HeaderActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
      --Constant: Col_MenuBarBg
      --Constant: Col_ModalWindowDimBg
      --Constant: Col_NavHighlight
      --Constant: Col_NavWindowingDimBg
      --Constant: Col_NavWindowingHighlight
      --Constant: Col_PlotHistogram
      --Constant: Col_PlotHistogramHovered
      --Constant: Col_PlotLines
      --Constant: Col_PlotLinesHovered 
      UI.MAIN_PushStyle('Col_PopupBg',0x303030, 0.9) 
      UI.MAIN_PushStyle('Col_ResizeGrip',UI.main_col, 1) 
      --Constant: Col_ResizeGripActive 
      UI.MAIN_PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
      --Constant: Col_ScrollbarBg
      --Constant: Col_ScrollbarGrab
      --Constant: Col_ScrollbarGrabActive
      --Constant: Col_ScrollbarGrabHovered
      --Constant: Col_Separator
      --Constant: Col_SeparatorActive
      --Constant: Col_SeparatorHovered
      --Constant: Col_SliderGrabActive
      UI.MAIN_PushStyle('Col_SliderGrab',UI.butBg_green, 0.4) 
      UI.MAIN_PushStyle('Col_Tab',UI.main_col, 0.37) 
      --UI.MAIN_PushStyle('Col_TabActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_TabHovered',UI.main_col, 0.8) 
      --Constant: Col_TabUnfocused
      --'Col_TabUnfocusedActive
      --UI.MAIN_PushStyle('Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
      --Constant: Col_TableBorderLight
      --Constant: Col_TableBorderStrong
      
      UI.MAIN_PushStyle('Col_TableHeaderBg',UI.main_col, 0.5) 
      --Constant: Col_TableRowBg
      --Constant: Col_TableRowBgAlt
      UI.MAIN_PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
      --Constant: Col_TextDisabled
      --Constant: Col_TextSelectedBg
      UI.MAIN_PushStyle('Col_TitleBg',UI.main_col, 0.7) 
      UI.MAIN_PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
      --Constant: Col_TitleBgCollapsed 
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 1)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    --ImGui.SetNextWindowSize(ctx, w_min, h_min, ImGui.Cond_Always)
    
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
      DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
      
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_itemH_small = math.floor(UI.calc_itemH*0.8)
      
      UI.MAIN_calc() 
      
      
    -- draw stuff
      UI.draw()
      ImGui.Dummy(ctx,0,0) 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
     else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
    end 
    ImGui.PopFont( ctx ) 
    --if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
  
    return open
end
  --------------------------------------------------------------------------------  
  function UI.MAIN_PopStyle(ctx, cnt, cnt2)
    if cnt then 
      ImGui.PopStyleVar(ctx,cnt)
      UI.pushcnt = UI.pushcnt -cnt
    end
    if cnt2 then
      ImGui.PopStyleColor(ctx,cnt2)
      UI.pushcnt2 = UI.pushcnt2 -cnt2
    end
  end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  
  -- handle xy
  DATA:handleViewportXYWH()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) end
-------------------------------------------------------------------------------- 
function UI.MAIN()
  
  EXT:load() 
  EXT.presetview = 0
  
  -- imgUI init
  ctx = ImGui.CreateContext(DATA.UI_name) 
  -- fonts
  DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
  DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
  DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
  -- config
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
  
  
  -- run loop
  defer(UI.MAINloop)
end
-------------------------------------------------------------------------------- 
function DATA:Init_Search_ActionList() 
  local action_name
  for actionID in pairs(DATA.actions) do
    DATA.actions[actionID].fitsearch = false
    if EXT.search ~= '' then
      action_name = DATA.actions[actionID].action_name
      action_name = action_name:lower()
      if action_name:match(EXT.search:lower()) then
        DATA.actions[actionID].fitsearch = true
      end
     else 
      DATA.actions[actionID].fitsearch = true
    end
  end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData()
  DATA:Init_kbDefinition_UI() 
  DATA:Init_kbDefinition_ActionList() 
  --DATA:Init_Search_ActionList() 
  
  EXT:load() 
  for i =1, EXT.categoriescnt do if EXT['category'..i..'_color'] and EXT['category'..i..'_color']~= '' then DATA.category[i].color = EXT['category'..i..'_color'] end end
  
  --[[ reset colors
    for i =1, EXT.categoriescnt do EXT['category'..i..'_col'] = '' end
    EXT:save()]]
end
-------------------------------------------------------------------------------- 
function EXT:save() 
  if not DATA.ES_key then return end 
  for key in pairs(EXT) do 
    if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
      SetExtState( DATA.ES_key, key, EXT[key], true  ) 
    end 
  end 
  EXT:load()
end
-------------------------------------------------------------------------------- 
function EXT:load() 
  if not DATA.ES_key then return end
  for key in pairs(EXT) do 
    if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
      if HasExtState( DATA.ES_key, key ) then 
        local val = GetExtState( DATA.ES_key, key ) 
        EXT[key] = tonumber(val) or val 
      end 
    end  
  end 
  DATA.upd = true
end
-------------------------------------------------------------------------------- 
function DATA:handleViewportXYWH()
  if not (DATA.display_x and DATA.display_y) then return end 
  if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
  if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
  if not DATA.display_w_last then DATA.display_w_last = DATA.display_w end
  if not DATA.display_h_last then DATA.display_h_last = DATA.display_h end
  
  if  DATA.display_x_last~= DATA.display_x 
    or DATA.display_y_last~= DATA.display_y 
    or DATA.display_w_last~= DATA.display_w 
    or DATA.display_h_last~= DATA.display_h 
    then 
    DATA.display_schedule_save = os.clock() 
  end
  if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
    EXT.viewport_posX = DATA.display_x
    EXT.viewport_posY = DATA.display_y
    EXT.viewport_posW = DATA.display_w
    EXT.viewport_posH = DATA.display_h
    EXT:save() 
    DATA.display_schedule_save = nil 
  end
  DATA.display_x_last = DATA.display_x
  DATA.display_y_last = DATA.display_y
  DATA.display_w_last = DATA.display_w
  DATA.display_h_last = DATA.display_h
end
-------------------------------------------------------------------------------- 
function DATA:handleProjUpdates()
  local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
end
--------------------------------------------------------------------------------  
  function UI.draw()  
    UI.draw_keyb()   
    UI.draw_KeyCategories() 
    --UI.draw_ActionList() 
    UI.draw_KeyDetails() 
  end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
---------------------------------------------------
function VF_CopyTable(orig)--http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[VF_CopyTable(orig_key)] = VF_CopyTable(orig_value)
        end
        setmetatable(copy, VF_CopyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end 
----------------------------------------------------------------------------------------- 
function main() 
  EXT_defaults = VF_CopyTable(EXT)
  UI.MAIN() 
end  
-----------------------------------------------------------------------------------------
main()
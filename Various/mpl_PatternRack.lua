-- @description PatternRack
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + official release

  --------------------------------------------------------------------

  vrs = '1.0'
  name = 'MPL PatternRack'
  
  --------------------------------------------------------------------

local changelog =[[
    1.0 17.03.2017 // REAPER 5.40pre12+
      + official release
      
    1.0pre12  16.03.2017 // REAPER 5.40pre12+
      + Blocks: remove items when add to block
      + Blocks: list samples
      + Blocks: update RS5K instances names and samples
      
    1.0pre11  15.03.2017 // REAPER 5.40pre12+
      - Undo: leave forcing undo only for destructive actions
      + Undo: Menu/Store current state
      + Blocks: init cutby feature - cut blocks by each other, works only for dumped items
      + Blocks: set related samples for RS5k instances when adding samples to block
      + StepSeq: enable dumpitems button
      
    1.0pre9   13.03.2017
      + Undo: init state on start, forcing undo on some actions (mainly add/delete stuff)
      + Undo: up to 10 undo history entries coming to/from ProjExtState binary chunk
      
    1.0pre8c 12.03.2017
      # Blocks: fix broken offsets
      # Blocks: disable all overlap checks, use post overlap checking belong sample tracks
      + Blocks: per block option to disable overlapping, enabled by default
      + StepSeq: clicking on block name select related tracks if any
      # Patterns: support properly follow pooled MIDI patterns      
      
    1.0pre7 11.03.2017
      # fix fontsize on OSX
      # StepSeq: fix steps not editable after changing tab
      + Patterns: change humanize multiplier
      + Patterns: change randomize threshold
      # Patterns: apply new/duplicated pattern on selected item if any
      + Blocks: per block pitch
      + Blocks: per sample pitch
      # Blocks: fix display common offset per sample
      
    1.0pre6 09.03.2017
      + StepSeq: humanize step velocities
      + StepSeq: show block note
      + StepSeq: mousewheel on step change gain/velocity
      # StepSeq: mousewheel scroll blocks only under name
      # StepSeq: fix change mouse context when change pattern len
      + Patterns: support SWS GrooveTool grooves, show groove as yellow lines
      # Patterns: different performance fixes/improvements for patterns update      
      # Blocks: use only JS:time adjustment for block/sample time shifts
      
    1.0pre5 08.03.2017
      # Rename Layers to Blocks
      + Main menu/Shortcuts and mouse modifiers
      + StepSeq: mousewheel on volume
      + StepSeq: option to follow groove per block
      + StepSeq: randomize steps
      + StepSeq: copypaste steps beetween blocks/patterns via context menu or Ctrl+C Ctrl+V
      # StepSeq: doubleclick open block, LMB select block
      # Patterns: update patterns on project state change
      # Patterns: limit dumped pattern items to pattern edges
      # Patterns: fix parse take to pattern
      # Patterns: match current pattern length (in measures) when parsing
      + Blocks: mousewheel on offsets
      # Blocks: removing block remove linked samples tracks
      # Blocks: reset blocks blit buffers on some GUI changes
      # GUI tweaks
      
    1.0pre4 07.08.2017
      + Patterns: Menu/Parse selected MIDI take as new 16-step pattern
      + Patterns: Menu/Parse selected MIDI take to current 16-step pattern
      + Patterns: doubleclick on step count set step count per measure
      + Patterns: shift drag double/half current step count
      + Patterns: add controls, previous/next pattern, remove current pattern
      # Patterns: prevent adding steps when changing length or step count
      # Patterns: prevent erasing parent track when remove all patterns
      # Patterns: remove ALL previous dumped items from tracks (previous behaviour cause lags when converting PPQ to time in some cases)
      # Patterns: match dumped item lengths MIDI notes   
      # Patterns: prevent adding items with position < 0   
      # Layers: show full sample paths 
      # Layers: improved blocks validation
      # GUI: improved knobs
            
    1.0pre3 06.03.2017
      # Patterns: arm pattern track when defining 
      # Patterns: set record MIDI for pattern track when defining 
      + Patterns: volume per layer (dumped items gain follow MIDI velocity)
      + Layers: scroll by scrollbar and mousewheel
      + Layers: global offset (both PPQ/time), alt+LMB or doubleclick to reset
      + Layers: offset per sample (auto add JS: TimeAdjustment), alt+LMB or doubleclick to reset
      + Layers: testing adding RS5K instance via TrackStateChunk. Can cause REAPER crash on open RS5k UI afterwards. Waiting an API from Justin.
      # Reset blit buffers on some GUI changes
      
    1.0pre2 04.03.2017
      + Layers/StepSeq: mute layer tracks
      + Layers/StepSeq: solo layer tracks
      + Layers: store current layer with project
      + Layers: preview layer
      # Layers: fix update block table when add samples to current layer
      + Patterns: store current pattern with project
      # Patterns: fixes for start dialog
      # Patterns: fix create new pattern set selected track as parent track
      # StepSeq: Left Drag + Shift set velocity behaviour changed to match Y position under step
      + Pads: Menu / Show black keys
      + Pads: Menu / Key names
      + Pads: Menu / Visual octave shift
      + Pads: mute/solo indicators
      + Pads: Ableton DrumRack layout
      + Pads: Korg NanoPad layout
      # Pads: proper click behaviour (send note off when release LMB)
      # Update gfx only when changing w/h of window and not x,y position

    1.0pre1 26.02.2017 required new clear ProjExtState
      + Patterns: init mode - dump MIDI notes as audio items for current pattern
      + Patterns: don`t remove items out of pattern clip when updating dumped items
      + Patterns: set pattern MIDI notes muted
      + Patterns: prevent inserting items after pattern edges
      + Patterns: when define parent track, enable all MIDI channels input and monitoring
      + Patterns: reset MIDI notes names not presented in rows
      + Patterns: set pattern track dialog on start
      # Patterns: improved menu
      # Patterns: fix update only pattern track
      # Patterns: fix validating sample/rs5k tracks after delete
      # Global preferences moved to main menu
      + GlobalPref/Layers: set base MIDI pitch
      + GlobalPref/Layers: update RS5k instances pitch range on changing base pitch
      + GlobalPref/About: links, changelog
      + Pads: early stage
      + Pads: reduce pad name down to MIDI pitch when small
      # StepSeq: mouse modifiers improvements
      + StepSeq: improved performance, dedicated ProjExtState for blocks
      + Layers: data table hold MIDI base, blocks hold 0-based MIDI shift
      + Layers: set minimum velocity to zero when adding rs5k instance
      + Layers: Menu / Remove all layers
      + Layers: Menu / Add selected items to separate layers
      # Layers: add new tracks at the end of project
      # Layers: when add first sample to layer, name layer as sample (reduced filename)
      # Layers: improved menu
      # Reduced filename for some contexts not include extension

    1.0alpha28 23.02.2017
      # Layers: fix wrong note when add new sample to layer
      # Layers: fix crash if change tab before updating layers
      + Layers: Menu / Add new layer
      + Layers: Menu / Rename layer    
      + Layers: Menu / Remove layer
      + Layers: Menu / Add selected items to current layer
        form new dedicated track with rs5k instance
        rename rs5k instance with filename
        create MIDI send to new track, disable audio send to new track
        limit rs5k MIDI note range to current layer note
      # StepSeq: fix editing steps apply edits to other patterns
      + StepSeq: click on layer name open this layer in Layers tab
      + StepSeq: support for swing, add swing by default, custom grooves not supported yet
      + StepSeq: Menu / Set selected track as pattern track
      + Tooltips: stepseq pattern length
      + Tooltips: stepseq pattern groove name
      + Patterns: update note names for pattern track
      + Patterns: When create new pattern ask for pattern track
      # Patterns: apply just duplicated pattern to selected items
      # Patterns: legato per-row notes when applying
      # Patterns: when edit current pattern, perform update only to this pattern
      # Patterns: fix editing fist step velocity edit step count
      # Patterns: Use only pattern track for pattern updating/manipulation

    1.0alpha20 17.02.2017
      # Internal chunk rebuild, dedicated table for Blocks (containers for samples/layers/MIDI/pads info)
      + Layers: Menu/Layers list
      + Layers: New layer button      
      + Patterns: support for per-pattern length, global pattern len deprecated
      + Patterns: store scroll offset to current pattern
      + Patterns: Support for take rates
      + Patterns: Support for take offset
      + StepSeq: Perform notes update when editing steps
      + StepSeq: steps mouse modifiers
        LB click/hold on step - draw with vel=100,
        RB click/hold on step - remove,
        LB+ctrl click/hold on step - draw last touched step with vel = 100 + mouse dy
        LB+ctrl+shift click/hold on step - draw with vel = 100 + mouse dy
        LB drag on step count set count
        LB+alt on step count reset count to defaults
      + Patterns: Search for next empty place after edit cursor when inserting/creating pattern
      + StepSeq: Step PPQ len fit GUI length
      + StepSeq: GUI - Scroll bar
      + StepSeq: GUI - grid beats/bars
      + StepSeq: Menu / Unlink selected items from script
      # StepSeq: fix step count and DC on row name relative to blit y shift
      # StepSeq: GUI/update fixes and improvements

    1.0alpha9 11.02.2017
      + StepSeq: name, steps
      + StepSeq: ExtStateParser early stage
      + StepSeq: Menu / create
      + StepSeq: Menu / duplicate
      + StepSeq: Menu / rename
      + StepSeq: Menu / apply
      + StepSeq: Menu / remove pattern+variations
      + StepSeq: Menu / select items linked to pattern
      + Patterns: follow item selection optionally
      + StepSeq: rows early stage, parse midi note, steps count
      # change name to MPL PatternRack

    1.0alpha1 01.02.2017
      + mpl Rack GUI sketch
]]

local MOUSE_modifiers = 
[[
  Shortcuts
    - Escape:             exit script
    - Space:              Transport: Play/Stop
    - Ctrl+C :            copy steps from current pattern selected block
    - Ctrl+V :            paste steps to current pattern selected block
  --------------------------------------------------- 
  StepSeq tab  
  Block volume:
    - Left drag:          change volume
    - Left click + Alt:   reset volume
    - DoubleClick:        reset volume
    - MouseWheel:         change volume    
  Block name:
    - Left click:         select block
    - Right click:        select block, open context menu    
    - Double click:       open block in Blocks tab
  Step count:
    - Left drag:          change step count
    - Left drag + Shift:  half/double step count
    - Left click + Alt:   reset step count
    - DoubleClick:        input step count (1-64)    
  Step matrix:
    - Left click:         add step
    - Left drag:          draw steps
    - Right click/drag:   remove step
    - Left click + ctrl:  change step velocity
    - Left drag + shift:  draw steps, change velocity
  ---------------------------------------------------        
  Blocks tab 
  Offset:
    - Left drag:          change offset
    - MouseWheel:         change offset
    - Left click + Alt:   reset offset
    - Double click:       reset offset
  Pitch: 
    - Left drag:          change pitch semitones
    - MouseWheel:         change pitch semitones
    - Left click + Alt:   reset pitch
    - Left click + Ctrl:  change pitch cents
    - Left click + Shift: change pitch octaves
    - Double click:       reset pitch
]]

  --------------------------------------------------------------------
  --debug_mode = true
  local reaper = reaper
  local gfx = gfx
  local data = {}
  local mouse = {}
  local patterns = {}
  local blocks = {}
  local obj = {}
  local Buf = {}
  local scaling = {}
  local Undo = {}
  --undo_force = true
  --reaper.SetProjExtState( 0, 'MPL_Rack', 'STEPSEQ','') -- reset
  -- filt: NOT obj. NOT mouse. NOT gfx. NOT reaper. NOT patterns.
  
  --------------------------------------------------------------------
  function Data_init_scaling()
    scaling = {
        layer_vol   =   function(val)     
                          if mouse.wheel_trig ~= 0 then return F_limit(val + (mouse.wheel_trig/4000), 0,1) end
                          if mouse.dy then       return F_limit(val - (mouse.dy / 300 ), 0,1)     end
                        end,
                        
        offset =        function(val)   
                          local  coeff   
                          if mouse.wheel_trig ~= 0 then
                            if mouse.wheel_trig >= 0 then coeff = -1 else coeff = 1 end
                            return  F_limit(val - math.abs(mouse.wheel_trig / 500 )^3 * coeff, -1,1, 4)
                          end                       
                          if mouse.dy >= 0 then coeff = -1 else coeff = 1 end
                          return F_limit(val + math.abs(mouse.dy / 150 )^3 * coeff, -1,1, 4)
                        end,
        pitch =         function (val) local dy              
                          if not mouse.dy then 
                            dy = 0 
                           else
                            dy = math.floor(mouse.dy / 10)
                          end
                          if mouse.wheel_trig ~= 0 then if mouse.wheel_trig >= 0 then dy = -1 else dy = 1 end  end
                          if mouse.Ctrl_state then dy = dy/100 end
                          if mouse.Shift_state then dy = math.floor(mouse.dy / 30)*12 end
                          return F_limit(val-dy, -data.Layer_pitch_max, data.Layer_pitch_max)
                        end
        --attack = function(attack) return F_limit(math.exp(attack-1)^60,0,1), 700  end
              }
  end
  --------------------------------------------------------------------  
  function Data_defaults()
    local data_default = {
    -- globals
      wind_w = 500,                     -- default GUI width
      wind_h = 200,                     -- default GUI height
      current_tab = 0,
      max_undo = 10,
      
    --mouse
      knob_mouse_resolution = 150,
      fader_mouse_resolution = 300,
      show_tooltip = 1,

    -- StSeq
      --StSeq_follow_item_selection = 1,
      StSeq_default_steps = 16,         --  default pat division
      StSeq_default_pat_length = 1,     --  default pat length in measures
      StSeq_default_dump_items = 0,
      StSeq_random_threshold = 0.8,
      StSeq_humanize = 0.2,
      StSeq_stepvel_shift_mousewheel = 5,
      
    -- Layers
      insert_tr_at_end = 1,             --  insert tracks at the end
      Layer_offset_max = 0.2,           --  max offset (seconds)
      Layer_pitch_max = 48,
      default_attack_ms = 0,
      
    -- Pads
      oct_shift_note_definitions = 1,   --  octave shift (visual)
      StSeq_midi_offset = 60,           --  note shift
      key_names = 0,                     --  0 - CDE, 1 - DoReMi
      black_keys = 0,
      pad_matrix_col = 4,
      pad_matrix_row = 4,
      pad_matrix_order = 0,
          
      }
    return data_default
  end
  --------------------------------------------------------------------
  function msg(s)
    if not s then return end
    reaper.ShowConsoleMsg(s)
    reaper.ShowConsoleMsg('\n')
  end
  --------------------------------------------------------------------
  function Patterns_FillEmptyFields(ext_id)
    local pat_id
    if ext_id then pat_id = ext_id else pat_id = patterns.cur_pattern end
    if pat_id and patterns[pat_id] then
      for block = 1, #blocks do
        if not patterns[pat_id].rows then patterns[pat_id].rows = {} end
        if not patterns[pat_id].rows[block] then patterns[pat_id].rows[block] = {} end
        patterns[pat_id].rows[block] = {
            steps = data.StSeq_default_steps,
            values = {}
          }
        --for i = 1, data.StSeq_default_steps do patterns[pat_id].rows[block].values[i] = 0 end
      end
    end
  end
  --------------------------------------------------------------------
  function F_conv_int_to_logic(num, inp1, inp2)
    if (num and type(num) == 'number' and num == 1) 
      or (num and type(num) == 'boolean' and num == true) 
      or (num and type(num) == 'table') then
      if inp2 then return inp2 end
      return true
     else
      if inp1 then return inp1 end
      return false
    end
  end
  function F_follow_button(obj) return obj.w + obj.x end
  --------------------------------------------------------------------
  function Objects_Init()  -- static variables
    --if debug_mode then msg('define obj') end
    if gfx.w < 100 then gfx.w = 100 end
    if gfx.h < 100 then gfx.h = 100 end
    local OS_switch = reaper.GetOS():find('Win') or reaper.GetOS():find('Unknown')    
    obj = {
                    main_w = gfx.w,
                    main_h = gfx.h,
                    offs = 1,

                    info_but_h = 20,
                    info_but_w = 150,
                    tab_h = 30,
                    but_h = 20,                   --  pattern name
                    row_h = 40,                   -- layerss h
                    w1 = 18,                      --  mute/solo
                    w2 = 50,                      -- preview layer, insert pattern
                    w3 = 40,                      -- pattern len, groove val
                    w4 = 140,                      -- groove name
                    w5 = 123,                       -- layers/sample names w
                    w6 = math.floor(gfx.w * 0.8), --  pattern name
                    w7 = 10,                       -- scroll bar
                    w8 = 45,                      -- knob w
                    w9 = 30,                      -- prev/next pattern
                    w10 = 12,                     -- PAD mute solo , Layer follow groove
                    w11 = 60,                     -- cutby
                    
                    min_w1 = 500,                 -- layers gain
                    min_w2 = 400,                  -- mute/solo layer
                    min_w3 = 300,                  -- layer name
                    
                    fontname = 'Calibri',
                    fontsize = F_conv_int_to_logic(OS_switch, 13, 18), -- tabs
                    fontsize2 = F_conv_int_to_logic(OS_switch, 11, 15), -- info button
                    fontsize3 = F_conv_int_to_logic(OS_switch, 9, 14), -- midi notes/pitches
                    fontsize4 = F_conv_int_to_logic(OS_switch, 8, 12), -- pads mute/solo
                    fontsize5 = F_conv_int_to_logic(OS_switch, 8, 12), -- knob values                    
                    txt_alpha0 = 0.1,
                    txt_alpha1 = 0.7,
                    txt_alpha2 = 0.2, -- undo
                    
                    glass_side = 200,
                    blit_alpha0 = 0.1,
                    blit_alpha1 = 0.4,
                    blit_alpha2 = 0.2, -- step min
                    blit_alpha3 = 0.8, -- step max
                    blit_alpha4 = 0.3, -- pad active
                    blit_alpha5 = 0.4, -- selected name in step seq
                    blit_alpha6 = 0.2, -- mini buttons
                    
                    gui_color = {['back'] = '20 20 20',
                                  ['back2'] = '51 63 56',
                                  ['black'] = '0 0 0',
                                  ['green'] = '130 255 120',
                                  ['blue2'] = '100 150 255',
                                  ['blue'] = '127 204 255',
                                  ['white'] = '255 255 255',
                                  ['red'] = '255 130 70',
                                  ['green_dark'] = '102 153 102',
                                  ['yellow'] = '200 200 0',
                                  ['pink'] = '200 150 200',
                                }
                  }

      local stseq_y1 = obj.tab_h + obj.offs*2+obj.info_but_h
      local stseq_y2 =   stseq_y1+obj.but_h+obj.offs
      --if OS == "OSX32" or OS == "OSX64" then gfx_fontsize = gfx_fontsize - 5 end
      --------------------------------------------------

      -- start dialog
        local def_p_w = 200
        local def_p_h = 30
        obj.define_pattern = {x =(gfx.w-def_p_w)/2,
                              y = (gfx.h-def_p_h)/2,
                              w = def_p_w,
                              h = def_p_h,
                              a_frame = obj.blit_alpha1,
                              a_txt = obj.txt_alpha1,
                              fontname = obj.fontname,
                              fontsize = obj.fontsize2,
                              txt = 'Set selected track as pattern track'}
      -- version / menu button
        obj.info = {x = gfx.w - obj.info_but_w,
                  y = 0,
                  w = obj.info_but_w,
                  h = obj.info_but_h,
                  a_frame = obj.blit_alpha0,
                  a_txt = obj.txt_alpha1,
                  fontname = obj.fontname,
                  fontsize = obj.fontsize2,
                  txt = '> '..name..' '..vrs
                  }
        obj.undo = {x = 0,
                  y = 0,
                  w = gfx.w-obj.info_but_w-obj.offs,
                  h = obj.info_but_h ,
                  a_frame = obj.blit_alpha0,
                  a_txt = obj.txt_alpha2,
                  fontname = obj.fontname,
                  fontsize = obj.fontsize3,
                  txt = 'Ў Undo',
                  txt_pos = 2}                  
      --  tabs
        obj.tab_cnt = 3
        obj.tab_w = math.ceil(gfx.w  / obj.tab_cnt)
        obj.tab = {}
        for i = 1, obj.tab_cnt do
          obj.tab[i] ={x = obj.tab_w*(i-1),
                  y = obj.offs+obj.info_but_h,
                  w = obj.tab_w,
                  h = obj.tab_h,
                  fontname = obj.fontname,
                  fontsize = obj.fontsize}
        end
        obj.tab[1].txt= 'StepSeq'
        obj.tab[2].txt= 'Blocks'
        obj.tab[3].txt= 'Pads'
      
      -- lc check
        obj.lc_txt = {x = 0,
                      y = obj.info_but_h+5,
                      w = gfx.w,
                      h = obj.row_h,
                      frame_type = 5,
                      fontname = obj.fontname,
                      fontsize = obj.fontsize,
                      a_txt = obj.txt_alpha1,
                      a_frame = obj.blit_alpha0,
                      txt = 'Purchase MPL scripts for $10'}
      -- lc check
        obj.lc_txt2 = {x = 0,
                      y = obj.info_but_h+10+obj.row_h,
                      w = gfx.w,
                      h = obj.row_h,
                      frame_type = 5,
                      fontname = obj.fontname,
                      fontsize = obj.fontsize,
                      a_txt = obj.txt_alpha1,
                      a_frame = obj.blit_alpha0,
                      txt = 'Already purchased'}     
                      
      -- lc check
        obj.lc_txt3 = {x = 0,
                      y = obj.info_but_h+15+obj.row_h*2,
                      w = gfx.w,
                      h = obj.row_h,
                      frame_type = 5,
                      fontname = obj.fontname,
                      fontsize = obj.fontsize,
                      a_txt = obj.txt_alpha1,
                      a_frame = obj.blit_alpha0,
                      txt = 'Continue'}                                         
----------------------------------------------------
      -- SteSeq
        obj.StSeq_pat_prev = {x = 0,        
                            y = stseq_y1,      
                            w = obj.w9,      
                            h = obj.but_h,
                            txt = '<',
                            a_frame = obj.blit_alpha0,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2
                            }     
        obj.StSeq_pat_next = {x = F_follow_button(obj.StSeq_pat_prev),   
                            y = stseq_y1,
                            w = obj.w9,
                            h = obj.but_h,
                            txt = '>',
                            a_frame = obj.blit_alpha0,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2
                            }    
        obj.StSeq_pat_id_new = {x = F_follow_button(obj.StSeq_pat_next),
                            y= stseq_y1,
                            w = obj.w2,
                            h = obj.but_h,
                            txt = 'New',
                            a_frame = obj.blit_alpha1,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2}                              
        obj.StSeq_pat_id_add = {x = F_follow_button(obj.StSeq_pat_id_new),
                            y= stseq_y1,
                            w = obj.w2,
                            h = obj.but_h,
                            txt = 'Insert',
                            a_frame = obj.blit_alpha0,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2}        
        obj.StSeq_pat_id_del = {x = F_follow_button(obj.StSeq_pat_id_add),
                            y= stseq_y1,
                            w = obj.w2,
                            h = obj.but_h,
                            txt = 'Delete',
                            a_frame = obj.blit_alpha0,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2}                                                                              
        obj.StSeq_pat_id = {x = F_follow_button(obj.StSeq_pat_id_del),
                            y = stseq_y1,
                            w = gfx.w - F_follow_button(obj.StSeq_pat_id_del),
                            h = obj.but_h,
                            txt_default = '> Menu',
                            a_frame = obj.blit_alpha0,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2
                            }
        obj.StSeq_global_hum_val = {x = gfx.w-obj.w3*4,
                             y = stseq_y2,
                             w = obj.w3,
                             h = obj.but_h,
                             a_frame = obj.blit_alpha0,
                             a_txt = obj.txt_alpha0,
                             fontname = obj.fontname,
                             fontsize = obj.fontsize2,
                             txt_default = '(val)'}                             
        obj.StSeq_global_rand_val = {x = F_follow_button(obj.StSeq_global_hum_val),
                             y = stseq_y2,
                             w = obj.w3,
                             h = obj.but_h,
                             a_frame = obj.blit_alpha0,
                             a_txt = obj.txt_alpha0,
                             fontname = obj.fontname,
                             fontsize = obj.fontsize2,
                             txt_default = '(val)'}                            
        obj.StSeq_global_groove_val = {x = F_follow_button(obj.StSeq_global_rand_val),
                             y = stseq_y2,
                             w = obj.w3,
                             h = obj.but_h,
                             a_frame = obj.blit_alpha0,
                             a_txt = obj.txt_alpha0,
                             fontname = obj.fontname,
                             fontsize = obj.fontsize2,
                             txt_default = '(val)'}
        obj.StSeq_global_len = {x = F_follow_button(obj.StSeq_global_groove_val),
                             y = stseq_y2,
                             w = obj.w3,
                             h = obj.but_h,
                             a_frame = obj.blit_alpha0,
                             a_txt = obj.txt_alpha0,
                             fontname = obj.fontname,
                             fontsize = obj.fontsize2,
                             txt_default = 0,
                             mouse_id = 'global_len'}
        obj.StSeq_global_DI = {x = 0,
                             y = stseq_y2,
                             w = obj.w3,
                             h = obj.but_h,
                             a_frame = obj.blit_alpha0,
                             a_txt = obj.txt_alpha0,
                             fontname = obj.fontname,
                             fontsize = obj.fontsize2,
                             txt = 'DI',
                             txt_col = 'blue'}                          
        obj.StSeq_global_groove = {x = F_follow_button(obj.StSeq_global_DI),
                             y = stseq_y2,
                             w = obj.StSeq_global_hum_val.x-F_follow_button(obj.StSeq_global_DI),
                             h = obj.but_h,
                             a_frame = obj.blit_alpha0,
                             a_txt = obj.txt_alpha0,
                             fontname = obj.fontname,
                             fontsize = obj.fontsize2,
                             txt_default = '(Groove)',
                             reduce_name_from_start = true}
        obj.StSeq_blit_level= stseq_y2 + obj.but_h + obj.offs
        obj.StSeq_scrollbar = {x = gfx.w-obj.w7,
                              y = obj.StSeq_blit_level,
                              w = obj.w7,
                              h = gfx.h - obj.StSeq_blit_level,
                              a_frame = obj.blit_alpha0}
        obj.StSeq_scrollbar2 = {x = obj.StSeq_scrollbar.x,
                              y = obj.StSeq_scrollbar.y,
                              w = obj.StSeq_scrollbar.w,
                              h = obj.StSeq_scrollbar.h,
                              a_frame = obj.blit_alpha1}
        obj.StSeq_matrix = {x = obj.offs,
                            y = obj.StSeq_blit_level,
                            w = gfx.w - obj.offs*2-obj.StSeq_scrollbar.w,
                            h = gfx.h - obj.StSeq_blit_level-obj.offs*2}
----------------------------------------------------------
      -- Layers
        obj.Layer_id_prev = F_table_copy(obj.StSeq_pat_prev)
        obj.Layer_id_next = F_table_copy(obj.StSeq_pat_next)
        
        obj.Layer_id_add = F_table_copy(obj.StSeq_pat_id_new)
        obj.Layer_id_add.txt = 'New' 
        obj.Layer_id_del = F_table_copy(obj.StSeq_pat_id_add)
        obj.Layer_id_del.txt = 'Delete' 
        
                
        obj.Layer_id = {x = F_follow_button(obj.Layer_id_del),
                            y = stseq_y1,
                            w = gfx.w - F_follow_button(obj.Layer_id_del),
                            h = obj.but_h,
                            txt_default = '> Menu',
                            a_frame = obj.blit_alpha1,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2
                            --txt_col = 'green'
                            }
        
                  

        obj.Layers_blit_level = stseq_y1+obj.but_h*2+obj.offs*3+obj.row_h
        
        obj.Layers_scrollbar = {x = gfx.w-obj.w7,
                              y = obj.Layers_blit_level,
                              w = obj.w7,
                              h = gfx.h - obj.Layers_blit_level,
                              a_frame = obj.blit_alpha0}
        obj.Layers_scrollbar2 = {x = obj.StSeq_scrollbar.x,
                              y = obj.Layers_scrollbar.y,
                              w = obj.Layers_scrollbar.w,
                              h = obj.Layers_scrollbar.h,
                              a_frame = obj.blit_alpha1}
        obj.Layers_matrix = {x=0, -- for layer scroll only
                             y = obj.Layers_blit_level,
                             w = gfx.w - obj.offs - obj.Layers_scrollbar.w,
                             h = gfx.h - obj.Layers_blit_level
                            }
----------------------------------------------------------
      -- pad
        obj.pad_matrix = {  x= 0,
                             y = stseq_y2,
                             w = gfx.w - obj.offs*2,
                             h = gfx.h - stseq_y2}
        obj.pad_menu = {x = 0,
                            y = stseq_y1,
                            w = gfx.w,
                            h = obj.but_h,
                            txt= '> '..'Menu',
                            a_frame = obj.blit_alpha1,
                            a_txt = obj.txt_alpha1,
                            fontname = obj.fontname,
                            fontsize = obj.fontsize2
                            }


    return obj
  end
  --------------------------------------------------------------------
  function F_reduce_button_name(t, str0, fontname, fontsize ,w0)
    -- for button
      if t and t.txt then 
        gfx.setfont(1, t.fontname, t.fontsize)
        if gfx.measurestr(t.txt) > t.w then
          local edges_lim = 2
          local out_str
          for i = 1, 256 do
            t.txt = F_conv_int_to_logic(t.reduce_name_from_start, t.txt:sub(2), t.txt:sub(0,-2))
            if   (not t.reduce_name_from_start and gfx.measurestr('...'..t.txt) < t.w - edges_lim) or
                  (t.reduce_name_from_start and gfx.measurestr(t.txt..'...') < t.w - edges_lim) then break end
          end
          t.txt = F_conv_int_to_logic(t.reduce_name_from_start, '...'..t.txt, t.txt..'...')
        end
      end
    
  end
  --------------------------------------------------------------------
  function Objects_Update() local last_h
    if not update_gfx then return end
    
    -- upd udo
      if Undo[#Undo] then obj.undo.txt = '> '..Undo[#Undo].name end
      F_reduce_button_name(obj.undo)
    --if debug_mode then msg(string.rep('_',30)..'\n') msg('Upd objects '..os.date()) msg(str)  end

    -- validate parent tr
      local parent_tr
      if patterns.tr_GUID then parent_tr = reaper.BR_GetMediaTrackByGUID( 0,patterns.tr_GUID) end
      if not parent_tr then
        data.current_tab = 0
        update_gfx = true
        return
      end

      if  parent_tr and data.current_tab == 0 then data.current_tab = 1 end

    -- update tabs
      for i = 1, obj.tab_cnt do
        if i == data.current_tab then
          obj.tab[i].a_frame = obj.blit_alpha1
          obj.tab[i].a_txt = obj.txt_alpha1
         else
          obj.tab[i].a_frame = obj.blit_alpha0
          obj.tab[i].a_txt = obj.txt_alpha0
        end
      end
    
    ----------------- PATTERN GUI updates ----------------------------

    -- define rows controls
    if data.current_tab == 1 then
      
      if patterns[patterns.cur_pattern] then 
        obj.StSeq_pat_id.txt = '> Pattern#'..math.floor(patterns.cur_pattern)..': '..patterns[patterns.cur_pattern].name
        obj.StSeq_global_groove.txt = patterns[patterns.cur_pattern].groove
        obj.StSeq_global_groove_val.txt = 'G:'..math.floor(patterns[patterns.cur_pattern].groove_val * 100)..'%'
        
        obj.StSeq_global_hum_val.txt = 'H:'..math.floor(data.StSeq_humanize*100)..'%'
        obj.StSeq_global_rand_val.txt = 'R:'..math.floor(data.StSeq_random_threshold*100)..'%'
        obj.StSeq_global_len.txt = patterns[patterns.cur_pattern].length..'bar'
        obj.StSeq_global_DI.a_frame = F_conv_int_to_logic(patterns[patterns.cur_pattern].dumpitems==1,obj.blit_alpha0,obj.blit_alpha1)
        obj.StSeq_global_DI.a_txt = F_conv_int_to_logic(patterns[patterns.cur_pattern].dumpitems==1, obj.txt_alpha0,obj.txt_alpha1) 
       else
        obj.StSeq_pat_id.txt = obj.StSeq_pat_id.txt_default 
        obj.StSeq_global_groove.txt = obj.StSeq_global_groove.txt_default
        obj.StSeq_global_groove_val.txt = obj.StSeq_global_groove_val.txt_default
        obj.StSeq_global_len.txt = obj.StSeq_global_len.txt_default
      end
      
      local pat_cond = patterns.cur_pattern and patterns.cur_pattern > 0 and patterns[patterns.cur_pattern] ~= nil 
      
      obj.StSeq_pat_prev.a_frame = F_conv_int_to_logic(pat_cond, obj.blit_alpha0, obj.blit_alpha1)
      obj.StSeq_pat_next.a_frame = F_conv_int_to_logic(pat_cond, obj.blit_alpha0, obj.blit_alpha1)
      obj.StSeq_pat_id_new.w = F_conv_int_to_logic(gfx.w>obj.min_w3,0,obj.w2) 
      obj.StSeq_pat_id_add.w = F_conv_int_to_logic(gfx.w>obj.min_w3,0,obj.w2) 
      obj.StSeq_pat_id_add.a_frame = F_conv_int_to_logic(pat_cond, obj.blit_alpha0, obj.blit_alpha1)
      obj.StSeq_pat_id_del.w = F_conv_int_to_logic(gfx.w>obj.min_w3,0,obj.w2)
      obj.StSeq_pat_id_del.a_frame = F_conv_int_to_logic(pat_cond, obj.blit_alpha0, obj.blit_alpha1)
      obj.StSeq_pat_id.a_frame = F_conv_int_to_logic(pat_cond, obj.blit_alpha0, obj.blit_alpha1)
      obj.StSeq_pat_id.x = F_conv_int_to_logic(gfx.w>obj.min_w3, obj.w9*2, obj.StSeq_pat_id_del.x+obj.StSeq_pat_id_del.w)
      obj.StSeq_pat_id.w = F_conv_int_to_logic(gfx.w>obj.min_w3, gfx.w - obj.w9*2, gfx.w - obj.StSeq_pat_id_del.w - obj.StSeq_pat_id_del.x)
      obj.StSeq_global_len.a_txt = F_conv_int_to_logic(pat_cond, obj.txt_alpha0,obj.txt_alpha1)        
      obj.StSeq_global_groove.a_txt = F_conv_int_to_logic(pat_cond, obj.txt_alpha0,obj.txt_alpha1) 
      obj.StSeq_global_groove_val.a_txt = F_conv_int_to_logic(pat_cond, obj.txt_alpha0,obj.txt_alpha1)
      obj.StSeq_global_rand_val.a_txt = F_conv_int_to_logic(pat_cond, obj.txt_alpha0,obj.txt_alpha1)
      obj.StSeq_global_hum_val.a_txt = F_conv_int_to_logic(pat_cond, obj.txt_alpha0,obj.txt_alpha1)
      
      F_reduce_button_name(obj.StSeq_pat_id)
      F_reduce_button_name(obj.StSeq_global_groove)
      
      obj.StSeq_rows = {}
      if patterns.cur_pattern
        and patterns.cur_pattern > 0
        and patterns[patterns.cur_pattern]
        and patterns[patterns.cur_pattern].rows then
        for bl_id = 1, #blocks do
          obj.StSeq_rows[bl_id] = {}
          local step_cnt = patterns[patterns.cur_pattern].rows[bl_id].steps * patterns[patterns.cur_pattern].length
          local ctrl_w = obj.row_h - obj.offs*2
          local row_ctrl_y = 0 + (bl_id-1)*(obj.row_h+obj.offs)
          obj.StSeq_rows[bl_id].mute = {x = 0,
                                       y = row_ctrl_y,
                                       w = F_conv_int_to_logic(gfx.w<obj.min_w2, obj.w1, 0),
                                       h= obj.row_h,
                                       txt = 'M',
                                       a_frame = F_conv_int_to_logic(blocks.cur_block == bl_id, obj.blit_alpha0,obj.blit_alpha5),
                                       col_frame = F_conv_int_to_logic(blocks[bl_id].mute, nil,'red'),
                                       a_txt = obj.txt_alpha1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize2,
                                       mouse_id = 'lay_mute'..bl_id,
                                       state = blocks[bl_id].mute }
          obj.StSeq_rows[bl_id].solo = {x = obj.StSeq_rows[bl_id].mute.x+obj.StSeq_rows[bl_id].mute.w,
                                       y = row_ctrl_y,
                                       w = F_conv_int_to_logic(gfx.w<obj.min_w2, obj.w1, 0),
                                       h= obj.row_h,
                                       txt = 'S',
                                        a_frame = F_conv_int_to_logic(blocks.cur_block == bl_id, obj.blit_alpha0,obj.blit_alpha5),
                                        col_frame = F_conv_int_to_logic(blocks[bl_id].solo, nil,'green'),
                                        a_txt = obj.txt_alpha1,
                                        fontname = obj.fontname,
                                        fontsize = obj.fontsize2,
                                        mouse_id = 'lay_solo'..bl_id,
                                        state = blocks[bl_id].solo
                                       }
          obj.StSeq_rows[bl_id].vol = {frame_type = 4,
                                      x=  obj.StSeq_rows[bl_id].solo.x+obj.StSeq_rows[bl_id].solo.w,
                                      y = row_ctrl_y,
                                      w = F_conv_int_to_logic(gfx.w<obj.min_w1, obj.w8, 0),
                                      h = obj.row_h,
                                      a_frame = F_conv_int_to_logic(blocks.cur_block == bl_id, obj.blit_alpha0,obj.blit_alpha5),
                                      knob_val = blocks[bl_id].vol,
                                      knob_val_alias = math.floor(blocks[bl_id].vol*100)..'%',
                                      knob_alias = '',
                                      a_txt = F_conv_int_to_logic(blocks[bl_id], obj.txt_alpha0, obj.txt_alpha1),
                                      mouse_id = 'vol'..bl_id,
                                      man_col = 'white'
                                      }                                   
          obj.StSeq_rows[bl_id].name = {x = obj.StSeq_rows[bl_id].vol.x+obj.StSeq_rows[bl_id].vol.w, -- knob vol
                                       y = row_ctrl_y,
                                       w = F_conv_int_to_logic(gfx.w<obj.min_w3, obj.w5, 0),
                                       h= obj.row_h,
                                       a_frame = F_conv_int_to_logic(blocks.cur_block == bl_id, obj.blit_alpha0,obj.blit_alpha5),
                                       txt = blocks[bl_id].name,
                                       a_txt = obj.txt_alpha1,
                                       --txt_col = 'green',
                                       txt_pos = 1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize2
                                       }
          F_reduce_button_name(obj.StSeq_rows[bl_id].name)
          obj.StSeq_rows[bl_id].MIDI = {x = obj.StSeq_rows[bl_id].name.x+obj.StSeq_rows[bl_id].name.w-obj.w10*2,
                                       y = obj.StSeq_rows[bl_id].name.y+obj.StSeq_rows[bl_id].name.h-obj.w10,
                                       w = obj.w10*2,
                                       h= obj.w10,
                                       txt = blocks[bl_id].MIDI + data.StSeq_midi_offset,
                                       a_frame = obj.blit_alpha6,
                                       a_txt = obj.txt_alpha1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize4,
                                       mouse_id = 'lay_midi'..bl_id }          
          obj.StSeq_rows[bl_id].fol_gr = {x = obj.StSeq_rows[bl_id].name.x+obj.StSeq_rows[bl_id].name.w-obj.w10*3,
                                       y = obj.StSeq_rows[bl_id].name.y+obj.StSeq_rows[bl_id].name.h-obj.w10,
                                       w = obj.w10,
                                       h= obj.w10,
                                       txt = 'G',
                                       a_frame = F_conv_int_to_logic(blocks[bl_id].fol_gr,obj.blit_alpha0,obj.blit_alpha6),
                                       col_frame = F_conv_int_to_logic(blocks[bl_id].fol_gr, nil,'white'),
                                       a_txt = F_conv_int_to_logic(blocks[bl_id].fol_gr, obj.txt_alpha0,obj.txt_alpha1),
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize4,
                                       mouse_id = 'lay_folgr'..bl_id,
                                       state = blocks[bl_id].fol_gr }
          obj.StSeq_rows[bl_id].rand = {x = obj.StSeq_rows[bl_id].name.x+obj.StSeq_rows[bl_id].name.w-obj.w10*4,
                                       y = obj.StSeq_rows[bl_id].name.y+obj.StSeq_rows[bl_id].name.h-obj.w10,
                                       w = obj.w10,
                                       h= obj.w10,
                                       txt = 'R',
                                       a_frame = obj.blit_alpha0,
                                       a_txt = obj.txt_alpha1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize4,
                                       mouse_id = 'lay_rand'..bl_id} 
          obj.StSeq_rows[bl_id].hum = {x = obj.StSeq_rows[bl_id].name.x+obj.StSeq_rows[bl_id].name.w-obj.w10*5,
                                       y = obj.StSeq_rows[bl_id].name.y+obj.StSeq_rows[bl_id].name.h-obj.w10,
                                       w = obj.w10,
                                       h= obj.w10,
                                       txt = 'H',
                                       a_frame = obj.blit_alpha0,
                                       a_txt = obj.txt_alpha1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize4,
                                       mouse_id = 'lay_hum'..bl_id}                                                                                         
          obj.StSeq_rows[bl_id].stepsframe = {x = obj.StSeq_rows[bl_id].name.x + obj.StSeq_rows[bl_id].name.w,
                                       y = row_ctrl_y,
                                       w = F_conv_int_to_logic(gfx.w<obj.min_w1, obj.w3, 0),
                                       h= obj.row_h,
                                       a_frame = F_conv_int_to_logic(blocks.cur_block == bl_id, obj.blit_alpha0,obj.blit_alpha5),
                                       txt = patterns[patterns.cur_pattern].rows[bl_id].steps,
                                       a_txt = obj.txt_alpha1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize2  }
          last_h = row_ctrl_y + obj.row_h
          obj.StSeq_rows[bl_id].steps = {}
          local step_com_w = obj.StSeq_matrix.w - obj.StSeq_rows[bl_id].stepsframe.x-obj.StSeq_rows[bl_id].stepsframe.w
          local step_w = step_com_w/step_cnt
          local step_x =  obj.StSeq_rows[bl_id].stepsframe.x+obj.StSeq_rows[bl_id].stepsframe.w
          for i = 1, step_cnt do
            local x_needed = step_x+step_w*(i-1)
            local x_q = math.floor(step_x+step_w*(i-1))+1
            local w_q = math.floor(step_w + x_needed-x_q)
            obj.StSeq_rows[bl_id].steps[i] = {frame_type = 2,
                                              x = x_q ,
                                              y = row_ctrl_y,
                                              w = w_q,
                                              h = obj.row_h,
                                              mouse_id = 'row'..bl_id..'st'..i,
                                              col_frame = F_conv_int_to_logic(patterns[patterns.cur_pattern].dumpitems, 'green','blue'),
                                              val_step = patterns[patterns.cur_pattern].rows[bl_id].values[i]}
            last_x = obj.StSeq_rows[bl_id].steps[i].x
          end
          obj.StSeq_rows[bl_id].stepfield = { x = step_x,
                                              y = row_ctrl_y,
                                              w = last_x+step_w-step_x,
                                              h = obj.row_h,
                                              a_frame = obj.blit_alpha0}
          obj.StSeq_blit_h = last_h
        end -- loop row

        -- update scrollbar
        local actual_stepseq_h = gfx.h - obj.StSeq_blit_level
        if not obj.StSeq_blit_h then obj.StSeq_blit_h = 0 end
        if actual_stepseq_h > obj.StSeq_blit_h then
          obj.StSeq_scrollbar2.y = obj.StSeq_scrollbar.y
          obj.StSeq_scrollbar2.h = obj.StSeq_scrollbar.h
          obj.StSeq_blit_shift = 0
         else
          local pat_scroll = patterns[patterns.cur_pattern].scroll
          obj.StSeq_scrollbar2.h = obj.StSeq_scrollbar.h * actual_stepseq_h / obj.StSeq_blit_h
          obj.StSeq_scrollbar2.y = obj.StSeq_scrollbar.y +(obj.StSeq_scrollbar.h - obj.StSeq_scrollbar2.h)*pat_scroll
          obj.StSeq_blit_shift = pat_scroll* (obj.StSeq_blit_h-actual_stepseq_h)
        end
      end
    end


    -----------------  LAYERS validation  -------------------------------------------
    
    -- check active layer
      if blocks.cur_block and blocks[blocks.cur_block] then
        obj.Layer_id.txt = '> '..blocks[blocks.cur_block].name
       else
        if not blocks.cur_block then blocks.cur_block = 0 end
        for i = blocks.cur_block, 1, -1  do
          if blocks[i] then
            obj.Layer_id.txt = '> '..blocks[i].name
            blocks.cur_block = i
            update_layers = true
            goto skip_cur_block_check
          end
        end
                
        for i = blocks.cur_block, #blocks do
          if blocks[i] then
            obj.Layer_id.txt = '> '..blocks[i].name
            blocks.cur_block = i
            update_layers = true
            goto skip_cur_block_check
          end
        end
    
        ::skip_cur_block_check::       
        
        if not blocks[blocks.cur_block] then obj.Layer_id.txt = obj.Layer_id.txt_default end
        obj.Layer_id.a_frame = obj.blit_alpha0
      end
    
    -- GUI blocks
      -------------------------
      local block_cond = blocks.cur_block and blocks.cur_block > 0 and blocks[blocks.cur_block] ~= nil 
      obj.Layer_id_add.w = F_conv_int_to_logic(gfx.w>obj.min_w3, 0,obj.w2 )
      obj.Layer_id_del.x = F_follow_button(obj.Layer_id_add)
      obj.Layer_id_del.w = F_conv_int_to_logic(gfx.w>obj.min_w3, 0,obj.w2 )
      obj.Layer_id.x = F_follow_button(obj.Layer_id_del)
      obj.Layer_id.w = gfx.w-F_follow_button(obj.Layer_id_del)
      F_reduce_button_name(obj.Layer_id)
      
    -- validate sample tracks
      for block_id = 1, #blocks do
        for sample = #blocks[block_id].samples, 1, -1 do
          local smpl_tr_GUID = blocks[block_id].samples[sample].tr_GUID
          local tr = reaper.BR_GetMediaTrackByGUID( 0, smpl_tr_GUID )
          if not tr then
            table.remove(blocks[block_id].samples,sample)
          end
        end
      end
      
    -- upd alpha name
      obj.Layer_id.a_frame = F_conv_int_to_logic(blocks[blocks.cur_block],obj.blit_alpha0,obj.blit_alpha1)
      obj.Layer_id_prev.a_frame = F_conv_int_to_logic(blocks[blocks.cur_block],obj.blit_alpha0,obj.blit_alpha1)
      obj.Layer_id_next.a_frame = F_conv_int_to_logic(blocks[blocks.cur_block],obj.blit_alpha0,obj.blit_alpha1)
      obj.Layer_id_del.a_frame = F_conv_int_to_logic(blocks[blocks.cur_block],obj.blit_alpha0,obj.blit_alpha1)
      
    obj.Layer_dyn = {rows={}}
    -------------------- LAYERS updates   ------------------
    if data.current_tab == 2 
      and blocks.cur_block 
      and blocks.cur_block > 0
      and blocks[blocks.cur_block]
      and blocks[blocks.cur_block].samples
      then
      -- define mutesolo controls
        local lay_y2 =   obj.Layer_id.y+obj.but_h+obj.offs
        obj.Layer_dyn.mute = {x = 0,
                                       y = lay_y2,
                                       w = obj.w1,
                                       h= obj.but_h,
                                       txt = 'M',
                                       a_frame = F_conv_int_to_logic(blocks[blocks.cur_block].mute,obj.blit_alpha0,obj.blit_alpha1),
                                       col_frame = F_conv_int_to_logic(blocks[blocks.cur_block].mute, nil,'red'),
                                       a_txt = obj.txt_alpha1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize2,
                                       mouse_id = 'lay_mute'..blocks.cur_block,
                                       state = blocks[blocks.cur_block].mute }
        obj.Layer_dyn.solo = {x = obj.w1,
                                       y = lay_y2,
                                       w = obj.w1,
                                       h= obj.but_h,
                                       txt = 'S',
                                        a_frame = F_conv_int_to_logic(blocks[blocks.cur_block].solo,obj.blit_alpha0,obj.blit_alpha1),
                                        col_frame = F_conv_int_to_logic(blocks[blocks.cur_block].solo, nil,'green'),
                                        a_txt = obj.txt_alpha1,
                                        fontname = obj.fontname,
                                        fontsize = obj.fontsize2,
                                        mouse_id = 'lay_solo'..blocks.cur_block,
                                        state = blocks[blocks.cur_block].solo
                                       }
        obj.Layer_dyn.overlap = {x =F_follow_button(obj.Layer_dyn.solo ),
                                       y = lay_y2,
                                       w = obj.w1,
                                       h= obj.but_h,
                                       txt = 'O',
                                        a_frame = F_conv_int_to_logic(blocks[blocks.cur_block].overlap,obj.blit_alpha0,obj.blit_alpha1),
                                        col_frame = F_conv_int_to_logic(blocks[blocks.cur_block].overlap, nil,'blue'),
                                        a_txt = obj.txt_alpha1,
                                        fontname = obj.fontname,
                                        fontsize = obj.fontsize2,
                                        mouse_id = 'lay_overlap'..blocks.cur_block,
                                        state = blocks[blocks.cur_block].overlap
                                       }    
                                                                         
        obj.Layer_dyn.preview = {x = F_follow_button(obj.Layer_dyn.overlap),
                                       y = lay_y2,
                                       w = obj.w1,
                                       h= obj.but_h,
                                       txt = '>',
                                      a_frame = obj.blit_alpha0,
                                        a_txt = obj.txt_alpha1,
                                        txt_col = 'green',
                                        fontname = 'Times New Roman',
                                        fontsize = obj.fontsize2,
                                        mouse_id = 'preview'..blocks.cur_block,
                                        state = blocks[blocks.cur_block].solo
                                       }
        obj.Layer_dyn.cutby = {x =gfx.w - obj.w11 - obj.Layers_scrollbar.w-obj.offs,
                                       y = lay_y2,
                                       w = obj.w11,
                                       h= obj.but_h,
                                       txt = F_conv_int_to_logic(blocks[blocks.cur_block].cutby~=-1,'(free)', 'Cut by '..blocks[blocks.cur_block].cutby+data.StSeq_midi_offset),
                                        a_frame = obj.blit_alpha0,
                                        --col_frame = F_conv_int_to_logic(blocks[blocks.cur_block].cutby, nil,'blue'),
                                        a_txt = obj.txt_alpha1,
                                        fontname = obj.fontname,
                                        fontsize = obj.fontsize2,
                                        mouse_id = 'lay_cutby'..blocks.cur_block
                                       }          
        obj.Layer_dyn.glob_ctrl = {x=0,
                               y = lay_y2 + obj.but_h + obj.offs,
                               w = gfx.w-obj.Layers_scrollbar.w- obj.offs,
                               h = obj.row_h,
                               a_frame = obj.blit_alpha0
                              }
        obj.Layer_dyn.gl_pitch = {frame_type = 4,
                               is_centered = true,
                               x=gfx.w-obj.Layers_scrollbar.w-obj.offs*2-obj.w8*2,
                               y = lay_y2 + obj.but_h + obj.offs,
                               w = obj.w8,
                               h = obj.row_h,
                               a_frame = obj.blit_alpha0,
                               knob_val = blocks[blocks.cur_block].gl_pitch/data.Layer_pitch_max,
                               knob_val_alias = blocks[blocks.cur_block].gl_pitch,
                               knob_alias = 'pitch',
                               a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                               mouse_id = 'gl_pitch',
                               man_col = 'white'
                              }                               
        obj.Layer_dyn.gl_offset = {frame_type = 4,
                               is_centered = true,
                               x=F_follow_button(obj.Layer_dyn.gl_pitch),
                               y = lay_y2 + obj.but_h + obj.offs,
                               w = obj.w8,
                               h = obj.row_h,
                               a_frame = obj.blit_alpha0,
                               knob_val = blocks[blocks.cur_block].gl_offset,
                               knob_val_alias = math.floor(blocks[blocks.cur_block].gl_offset*data.Layer_offset_max*1000)..'ms',
                               knob_alias = 'offset',
                               a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                               mouse_id = 'gl_offs',
                               man_col = 'white'--F_conv_int_to_logic(blocks[blocks.cur_block].gl_offset==0, 'white', 'green')
                              }        
                              
        local knob_x_sh = obj.w8 + obj.offs
        obj.Layer_dyn.gl_attack = {frame_type = 4,
                               x=obj.w5+knob_x_sh,
                               y = lay_y2 + obj.but_h + obj.offs,
                               w = obj.w8,
                               h = obj.row_h,
                               a_frame = obj.blit_alpha0,
                               knob_val = blocks[blocks.cur_block].gl_attack,
                               knob_val_alias = (math.floor(blocks[blocks.cur_block].gl_attack*20000)/10)..'ms',
                               knob_alias = 'attack',
                               a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                               mouse_id = 'gl_attack',
                               man_col = 'white'--F_conv_int_to_logic(blocks[blocks.cur_block].gl_attack==0, 'white', 'green')
                              }        
        obj.Layer_dyn.gl_decay = {frame_type = 4,
                               x=obj.w5+obj.offs+knob_x_sh*2,
                               y = lay_y2 + obj.but_h + obj.offs,
                               w = obj.w8,
                               h = obj.row_h,
                               a_frame = obj.blit_alpha0,
                               knob_val = blocks[blocks.cur_block].gl_decay,
                               knob_val_alias = math.floor(blocks[blocks.cur_block].gl_decay*1000)..'ms',
                               knob_alias = 'decay',
                               a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                               mouse_id = 'gl_decay',
                               man_col = 'white'--F_conv_int_to_logic(blocks[blocks.cur_block].gl_decay==0.25, 'white', 'green')
                              }     
        obj.Layer_dyn.gl_sustain = {frame_type = 4,
                               x=obj.w5+obj.offs+knob_x_sh*3,
                               y = lay_y2 + obj.but_h + obj.offs,
                               w = obj.w8,
                               h = obj.row_h,
                               a_frame = obj.blit_alpha0,
                               knob_val = blocks[blocks.cur_block].gl_attack,
                               knob_val_alias = math.floor(blocks[blocks.cur_block].gl_attack*1000)..'ms',
                               knob_alias = 'attack',
                               a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                               mouse_id = 'gl_attack',
                               man_col = 'white'--F_conv_int_to_logic(blocks[blocks.cur_block].gl_attack==0, 'white', 'green')
                              }     
        obj.Layer_dyn.gl_release = {frame_type = 4,
                               x=obj.w5+obj.offs+knob_x_sh*4,
                               y = lay_y2 + obj.but_h + obj.offs,
                               w = obj.w8,
                               h = obj.row_h,
                               a_frame = obj.blit_alpha0,
                               knob_val = blocks[blocks.cur_block].gl_attack,
                               knob_val_alias = math.floor(blocks[blocks.cur_block].gl_attack*1000)..'ms',
                               knob_alias = 'attack',
                               a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                               mouse_id = 'gl_attack',
                               man_col = F_conv_int_to_logic(blocks[blocks.cur_block].gl_attack==0, 'white', 'green')
                              }     
                              
                                                                                                  
        for smpl = 1, #blocks[blocks.cur_block].samples do
          obj.Layer_dyn.rows[smpl] = {}
          local row_ctrl_y = 0 + (smpl-1)*(obj.row_h+obj.offs)
          obj.Layer_dyn.rows[smpl].prev_smpl = {
                                      x=gfx.w-obj.Layers_scrollbar.w-obj.offs*2-obj.w8*3,
                                      y = row_ctrl_y,
                                      w = math.ceil(obj.w8/2),
                                      h = obj.row_h,
                                      a_frame = obj.blit_alpha0,
                                      a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                                      mouse_id = 'prevsmpl'..smpl,
                                      txt = '<'}    
          obj.Layer_dyn.rows[smpl].next_smpl = {
                                      x=gfx.w-obj.Layers_scrollbar.w-obj.offs*2-obj.w8*3+ math.ceil(obj.w8/2),
                                      y = row_ctrl_y,
                                      w = math.ceil(obj.w8/2),
                                      h = obj.row_h,
                                      a_frame = obj.blit_alpha0,
                                      a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                                      mouse_id = 'nextsmpl'..smpl,
                                      txt = '>'}                                               
          obj.Layer_dyn.rows[smpl].pitch = {frame_type = 4,
                                      is_centered = true,
                                      x=gfx.w-obj.Layers_scrollbar.w-obj.offs*2-obj.w8*2,
                                      y = row_ctrl_y,
                                      w = obj.w8,
                                      h = obj.row_h,
                                      a_frame = obj.blit_alpha0,
                                      knob_val = F_limit( (blocks[blocks.cur_block].samples[smpl].pitch+ blocks[blocks.cur_block].gl_pitch)/data.Layer_pitch_max,-1,1),
                                      knob_val_alias = blocks[blocks.cur_block].samples[smpl].pitch+ blocks[blocks.cur_block].gl_pitch,
                                      knob_alias = '',
                                      a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                                      mouse_id = 'pitch'..smpl,
                                      man_col = F_conv_int_to_logic(blocks[blocks.cur_block].samples[smpl].pitch==0, 'white', 'green')
                                      }                                     
          obj.Layer_dyn.rows[smpl].offset = {frame_type = 4,
                                      is_centered = true,
                                      x=F_follow_button(obj.Layer_dyn.rows[smpl].pitch),
                                      y = row_ctrl_y,
                                      w = obj.w8,
                                      h = obj.row_h,
                                      a_frame = obj.blit_alpha0,
                                      knob_val = blocks[blocks.cur_block].samples[smpl].offset+blocks[blocks.cur_block].gl_offset,
                                      knob_val_alias = math.floor(blocks[blocks.cur_block].samples[smpl].offset*data.Layer_offset_max*1000)
                                                      +math.floor(blocks[blocks.cur_block].gl_offset*data.Layer_offset_max*1000)..'ms',
                                      knob_alias = '',
                                      a_txt = F_conv_int_to_logic(blocks[blocks.cur_block], obj.txt_alpha0, obj.txt_alpha1),
                                      mouse_id = 'offs'..smpl,
                                      man_col = F_conv_int_to_logic(blocks[blocks.cur_block].samples[smpl].offset==0, 'white', 'green')
                                      }
          obj.Layer_dyn.rows[smpl].name = {x =0,
                                       y = row_ctrl_y,
                                       w = obj.Layer_dyn.rows[smpl].prev_smpl.x,
                                       h= obj.row_h,
                                       a_frame = obj.blit_alpha0,
                                       txt = blocks[blocks.cur_block].samples[smpl].filename,
                                       a_txt = obj.txt_alpha1,
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize2
                                       }
          F_reduce_button_name(obj.Layer_dyn.rows[smpl].name)                                
                                                                  
          last_h = row_ctrl_y + obj.row_h

        end -- loop row
        obj.Layers_blit_h = last_h

        -- update scrollbar
        local actual_Layers_h = gfx.h - obj.Layers_blit_level
        if not obj.Layers_blit_h then obj.Layers_blit_h = 0 end
        if actual_Layers_h > obj.Layers_blit_h then
          obj.Layers_scrollbar2.y = obj.Layers_scrollbar.y
          obj.Layers_scrollbar2.h = obj.Layers_scrollbar.h
          obj.Layers_blit_shift = 0
         else
          local Layers_scroll = blocks[blocks.cur_block].scroll
          obj.Layers_scrollbar2.h = obj.Layers_scrollbar.h * actual_Layers_h / obj.Layers_blit_h
          obj.Layers_scrollbar2.y = obj.Layers_scrollbar.y +(obj.Layers_scrollbar.h - obj.Layers_scrollbar2.h)*Layers_scroll
          obj.Layers_blit_shift = Layers_scroll* (obj.Layers_blit_h-actual_Layers_h)
        end
    end


    --------------------------------------------------------------------------
    if not obj.StSeq_blit_shift then obj.StSeq_blit_shift = 0 end
    if not obj.Layers_blit_shift then obj.Layers_blit_shift = 0 end

    ------------------ PADS updates     -------------------------------------
    if data.current_tab == 3 then
      obj.Pad_pads = {}

      local pad_matr_step_w = data.pad_matrix_col
      local pad_matr_step_h = data.pad_matrix_row
      local order = data.pad_matrix_order

      -- define wh
        local pad_h = obj.pad_matrix.h /pad_matr_step_h
        local pad_w = obj.pad_matrix.w /pad_matr_step_w--math.floor(pad_h*1.5)
        --if pad_w * pad_matr_step_w > obj.pad_matrix.w then pad_w = obj.pad_matrix.w / pad_matr_step_w end

      -- init shifts
        local x_shift, y_shift = 0 , 0
        if order == 1 then y_shift = pad_matr_step_h+1 end

      for i = 1, pad_matr_step_w*pad_matr_step_h do

        -- get order
          if order == 0 then
            x_shift = (i-1)%pad_matr_step_w
            if x_shift == 0 then y_shift = y_shift + 1 end
           elseif order == 1 then
            x_shift = (i-1)%pad_matr_step_w
            if x_shift == 0 then y_shift = y_shift-1 end
          end

        -- define xy
          x = obj.pad_matrix.x + obj.offs+pad_w*x_shift
          y = obj.pad_matrix.y+obj.pad_matrix.h - pad_h*y_shift

        -- check existed blocks
          local midi_note_block_id = nil
          for block_id = 1, #blocks do
            if blocks[block_id].MIDI == i -1 then
              midi_note_block_id = block_id
              break
            end
          end

        -- define pad name from block
          local BL_name if blocks[midi_note_block_id] then BL_name  = blocks[midi_note_block_id].name end
          --BL_name = F_reduce_button_name(nil, BL_name, obj.fontname, obj.fontsize3 ,pad_w-obj.w10)

        -- black key color
          local txt_col
          if data.black_keys == 1 then
            if      i % 12 == 2
              or  i % 12 == 4
              or  i % 12 == 7
              or  i % 12 == 9
              or  i % 12 == 11
              then txt_col = 'black' end
          end

        obj.Pad_pads[i] = {frame_type = 3,
                        x = x,
                        y = y,
                        w = pad_w,
                        h = pad_h,
                        a_frame = obj.blit_alpha0,
                        MIDInote = i-1+data.StSeq_midi_offset,
                        a_frame = F_conv_int_to_logic(midi_note_block_id~=nil,obj.blit_alpha0,obj.blit_alpha4),
                        a_txt = F_conv_int_to_logic(midi_note_block_id~=nil,obj.txt_alpha0,obj.txt_alpha1),
                        fontname = obj.fontname,
                        fontsize = obj.fontsize3,
                        txt = BL_name,
                        txt_col= txt_col,
                        collapsed = false }
        F_reduce_button_name(obj.Pad_pads[i])
        gfx.setfont(1,obj.fontname, obj.fontsize3)
        if gfx.texth*2 > pad_h-3 then obj.Pad_pads[i].collapsed = true end

        if midi_note_block_id and obj.w10*2 < pad_h then
          if not obj.Pad_ctrls then obj.Pad_ctrls = {} end
          if not obj.Pad_ctrls[i] then obj.Pad_ctrls[i] = {} end
          obj.Pad_ctrls[i].mute = {x = x+pad_w-obj.w10,
                                       y = y+pad_h-obj.w10*2,
                                       w = obj.w10,
                                       h= obj.w10,
                                       txt = 'M',
                                       a_frame = F_conv_int_to_logic(blocks[midi_note_block_id].mute,obj.blit_alpha0,obj.blit_alpha6),
                                       col_frame = F_conv_int_to_logic(blocks[midi_note_block_id].mute, nil,'red'),
                                       a_txt = F_conv_int_to_logic(blocks[midi_note_block_id].mute, obj.txt_alpha0,obj.txt_alpha1),
                                       fontname = obj.fontname,
                                       fontsize = obj.fontsize4,
                                       mouse_id = 'pad_mute'..midi_note_block_id,
                                       state = blocks[midi_note_block_id].mute }
          obj.Pad_ctrls[i].solo = {x = x+pad_w-obj.w10,
                                       y = y+pad_h-obj.w10,
                                       w = obj.w10,
                                       h= obj.w10,
                                       txt = 'S',
                                        a_frame = F_conv_int_to_logic(blocks[midi_note_block_id].solo,obj.blit_alpha0,obj.blit_alpha6),
                                        col_frame = F_conv_int_to_logic(blocks[midi_note_block_id].solo, nil,'green'),
                                        a_txt = F_conv_int_to_logic(blocks[midi_note_block_id].solo, obj.txt_alpha0,obj.txt_alpha1),
                                        fontname = obj.fontname,
                                        fontsize = obj.fontsize4,
                                        mouse_id = 'pad_solo'..midi_note_block_id,
                                        state = blocks[midi_note_block_id].solo
                                       }
        end


      end
    end
  end


  --------------------------------------------------------------------
  function F_ssv_fromNative(col)
    r1, g1, b1 = reaper.ColorFromNative( col )
    local str
    if OS == "OSX32" or OS == "OSX64" then
      str = b1..' '..g1..' '..r1
     else
      str = r1..' '..g1..' '..b1
    end
    return str
  end
  --------------------------------------------------------------------
  function F_extract_filename(orig_name)
    local reduced_name_slash = orig_name:reverse():find('[%/%\\]')
    local reduced_name = orig_name:sub(-reduced_name_slash+1)
    reduced_name = reduced_name:sub(0,-1-reduced_name:reverse():find('%.'))
    return reduced_name
  end
  --------------------------------------------------------------------
  function GUI_Layers()
    F_frame(obj.Layer_id_prev)
    F_frame(obj.Layer_id_next)
    F_frame(obj.Layer_id_add)
    F_frame(obj.Layer_id_del)
    F_frame(obj.Layer_id)
    
    if not obj.Layer_dyn then return end
    F_frame(obj.Layer_dyn.glob_ctrl)
    F_frame(obj.Layer_dyn.gl_pitch)
    F_frame(obj.Layer_dyn.gl_offset)
    
    --F_frame(obj.Layer_dyn.gl_attack)
    --F_frame(obj.Layer_dyn.gl_decay)
    --F_frame(obj.Layer_dyn.gl_sustain)
    --F_frame(obj.Layer_dyn.gl_release)
    
    if blocks.cur_block and blocks[blocks.cur_block] then
      F_frame(obj.Layer_dyn.mute)
      F_frame(obj.Layer_dyn.solo)
      F_frame(obj.Layer_dyn.overlap)
      F_frame(obj.Layer_dyn.cutby)
      F_frame(obj.Layer_dyn.preview)      
      F_frame(obj.Layers_scrollbar)
      F_frame(obj.Layers_scrollbar2)
      
      gfx.dest = 6
      gfx.a = 1
      gfx.setimgdim(6, -1, -1)
      gfx.setimgdim(6, gfx.w-obj.Layers_scrollbar.w, obj.Layers_blit_h )
      if debug_mode then gfx.x, gfx.y = 0,0 gfx.set (1,1,1,1) gfx.drawstr(6) end
      if obj.Layer_dyn.rows and #obj.Layer_dyn.rows > 0 then
        GUI_backgr(gfx.w - obj.offs-obj.Layers_scrollbar.w, obj.Layers_blit_h)
        for smpl = 1, #obj.Layer_dyn.rows do 
          
          F_frame(obj.Layer_dyn.rows[smpl].name) 
          F_frame(obj.Layer_dyn.rows[smpl].prev_smpl)
          F_frame(obj.Layer_dyn.rows[smpl].next_smpl)
          F_frame(obj.Layer_dyn.rows[smpl].pitch)
          F_frame(obj.Layer_dyn.rows[smpl].offset)
        end
      end
    end
  end

  --------------------------------------------------------------------
  function GUI_Pads()
    for i = 1, #obj.Pad_pads do
      F_frame(obj.Pad_pads[i])
      if obj.Pad_ctrls and obj.Pad_ctrls[i] then
        F_frame(obj.Pad_ctrls[i].mute)
        F_frame(obj.Pad_ctrls[i].solo)
      end
    end
    F_frame(obj.pad_menu)
  end
  --------------------------------------------------------------------
  local function F_Convert_Num2Pitch(val)  local key_names
    local oct_shift = -1+math.floor(data.oct_shift_note_definitions )
    if not val then return end
    local val = math.floor(val)
    local oct = math.floor(val / 12)
    local note = math.fmod(val,  12)
    if note and oct and note <= 13 then
      if data.key_names == 0 then
        key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',} end
      if data.key_names == 1 then
        key_names = {'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si',} end
      if data.key_names == 2 then return val end
      return key_names[note+1]..oct+oct_shift
    end
  end
  --------------------------------------------------------------------
  function GUI_draw()
    gfx.mode = 0
    --[[

    3 gradient glass
    5 steps
    6 samples
    10 common static buf

    ]]
    -- update buf on start
      if update_gfx_onstart then
          -- back
          gfx.dest = 3
          gfx.setimgdim(3, -1, -1)
          gfx.setimgdim(3, obj.glass_side, obj.glass_side)
          gfx.a = 1
          local r,g,b,a = 0.9,0.9,1,0.6
          gfx.x, gfx.y = 0,0
          local drdx = 0.00001
          local drdy = 0
          local dgdx = 0.0001
          local dgdy = 0.0003
          local dbdx = 0.00002
          local dbdy = 0
          local dadx = 0.0003
          local dady = 0.0004
          gfx.gradrect(0,0,obj.glass_side, obj.glass_side,
                          r,g,b,a,
                          drdx, dgdx, dbdx, dadx,
                          drdy, dgdy, dbdy, dady)
          update_gfx_on_start = nil
      end

    -- update static buffers
    if update_gfx then
        gfx.a = 1
        gfx.dest = 10
        gfx.setimgdim(10, -1, -1)
        gfx.setimgdim(10, gfx.w, gfx.h)
        GUI_backgr()
        gfx.setimgdim(5,-1,-1) -- reset stseq buf
        gfx.setimgdim(6,-1,-1) -- reset layer buf
        for i = 1, obj.tab_cnt do F_frame(obj.tab[i]) end
        if data.current_tab == 1 then GUI_StSeq() end
        if data.current_tab == 2 then GUI_Layers() end
        if data.current_tab == 3 then GUI_Pads() end
    end

    -- draw common buffer
    if not patterns.tr_GUID then goto skip_main_blit end

    ----------------------------------------------------
    --clock_LFO_time = 2
    --clock_LFO = math.sin(math.rad(360*(clock % clock_LFO_time) /clock_LFO_time))
    -----------------------------------------------------
    gfx.dest = -1
    gfx.a = 1
    
    gfx.blit(10, 1, 0,
            0,0,  obj.main_w,obj.main_h,
            0,0,  obj.main_w,obj.main_h, 0,0)
    gfx.a =1
    -- patterns
    if data.current_tab == 1 then
        gfx.blit(5, 1, 0,
                      0,obj.StSeq_blit_shift,
                      gfx.w,
                      obj.StSeq_blit_h,
                      0,
                      obj.StSeq_blit_level ,
                      gfx.w,
                      obj.StSeq_blit_h,
                      0,0)
    end
    -- layers
    if data.current_tab == 2 then
        gfx.blit(6, 1, 0,
                      0,obj.Layers_blit_shift,
                      gfx.w,
                      obj.Layers_blit_h,
                      0,
                      obj.Layers_blit_level ,
                      gfx.w,
                      obj.Layers_blit_h,
                      0,0)
    end
    ---------------------------------------------------------

    :: skip_main_blit::
    if data.current_tab == 0 then
      gfx.dest = -1
      GUI_backgr()
      F_frame(obj.define_pattern)
    end
    F_frame(obj.info)
    F_frame(obj.undo)



    --[[ debug buf
      gfx.x = 0
      gfx.y = obj.StSeq_blit_level
      gfx.lineto(gfx.w,obj.StSeq_blit_h+obj.StSeq_blit_level )]]

    update_gfx_onstart = false
    update_gfx = false
    gfx.update()
  end
  --------------------------------------------------------------------
  function GUI_backgr(w,h)
    if not w then w = gfx.w end
    if not h then h = gfx.h+20 end
    F_Get_SSV(obj.gui_color.black)
    gfx.a = 1
    gfx.rect(0,0,w, h, 1)
    F_Get_SSV(obj.gui_color.white)
    gfx.a = 0.2
    gfx.rect(0,0,w, h, 1)
  end
  --------------------------------------------------------------------
  function GUI_StSeq()

    F_frame(obj.StSeq_pat_prev)
    F_frame(obj.StSeq_pat_next)
    F_frame(obj.StSeq_pat_id_new)
    F_frame(obj.StSeq_pat_id_add)
    F_frame(obj.StSeq_pat_id_del)
    F_frame(obj.StSeq_pat_id)

    if patterns.cur_pattern and patterns[patterns.cur_pattern] then
      F_frame(obj.StSeq_global_DI)
      F_frame(obj.StSeq_global_groove)
      F_frame(obj.StSeq_global_hum_val)
      F_frame(obj.StSeq_global_rand_val)
      F_frame(obj.StSeq_global_groove_val)
      F_frame(obj.StSeq_global_len)     
      
      
      
      F_frame(obj.StSeq_scrollbar)
      F_frame(obj.StSeq_scrollbar2)
      gfx.dest = 5
      gfx.a = 1
      gfx.setimgdim(5, -1, -1)
      gfx.setimgdim(5, gfx.w-obj.StSeq_scrollbar.w, obj.StSeq_blit_h )

      if debug_mode then gfx.x, gfx.y = 0,0 gfx.set (1,1,1,1) gfx.drawstr(5) end

      if obj.StSeq_rows and #obj.StSeq_rows > 0 then
        GUI_backgr(gfx.w-obj.StSeq_scrollbar.w, obj.StSeq_blit_h)
        for row = 1, #obj.StSeq_rows do
          F_frame(obj.StSeq_rows[row].mute)
          F_frame(obj.StSeq_rows[row].solo)
          F_frame(obj.StSeq_rows[row].vol)
          F_frame(obj.StSeq_rows[row].name)
          F_frame(obj.StSeq_rows[row].MIDI) 
          F_frame(obj.StSeq_rows[row].fol_gr) 
          F_frame(obj.StSeq_rows[row].rand)
          F_frame(obj.StSeq_rows[row].hum)
          F_frame(obj.StSeq_rows[row].stepsframe)

          -- yellow groove
            if patterns[patterns.cur_pattern].groove_t 
              and blocks[row] 
              and blocks[row].fol_gr == 1 then
              local x,y,w,h = F_UnzipTable(obj.StSeq_rows[row].stepfield)
              gfx.a = 0.2
              gfx.mode = 1
              F_Get_SSV(obj.gui_color.yellow)
              for i = 1, #patterns[patterns.cur_pattern].groove_t do
                gfx.rect(math.floor(x + patterns[patterns.cur_pattern].groove_t[i]*(w/(4*patterns[patterns.cur_pattern].length))+1),
                                         y,
                                         1,
                                         h*(1-100/127), 1)
              end
              gfx.mode = 0
            end   
            
          for step = 1 , #obj.StSeq_rows[row].steps do F_frame(obj.StSeq_rows[row].steps[step]) end
          
          -- grid lines
            local x,y,w,h = F_UnzipTable(obj.StSeq_rows[row].stepfield)
            gfx.a = 0.2
            gfx.mode = 1
            local cnt = 4*patterns[patterns.cur_pattern].length
            F_Get_SSV(obj.gui_color.white)
            for div = 1, cnt do
              local y_r = y
              local h_r = 0
              if (div-1) % 1 == 0 then h_r = h/4 end
              if (div-1) % 2 == 0 then h_r = h_r + h/4 end
              if (div-1) % 4 == 0 then h_r = h_r + h/4 end
              if (div-1) % 8 == 0 then h_r = h_r + h/4 end
              h_r = h_r * 0.8
              y_r = y + h - h_r
              gfx.rect(x + (div-1)*w/cnt+1,
                       y_r,
                       1,
                       h_r, 1)
            end
            gfx.mode = 0

        end
      end
    end

  end
  --------------------------------------------------------------------
  function F_UnzipTable(xywh)
    if xywh then return xywh.x, xywh.y, xywh.w, xywh.h end
  end
  --------------------------------------------------------------------
  function F_frame(t)
    if not t then return end
    local  x,y,w,h = t.x, t.y, t.w, t.h
    if w < obj.offs then return end
    if t.a_frame then gfx.a = t.a_frame end
    local y1 = y
    local h1 = h
    if debug_mode then 
      gfx.a = 0.1
      gfx.line(x,y,x+w,y+h)
      gfx.line(x,y+h,x+w,y)
      gfx.rect(x,y,w,h,0)
    end
    -- REGULAR ----------------------
    if not t.frame_type or t.frame_type == 1 or t.frame_type == 5 then -- 5=rect frame
      gfx.blit(3, 1, math.rad(0),
                0,
                0,
                obj.glass_side,
                obj.glass_side,
                x,y1,w,h1,
                0, 0)
      if t.frame_type == 5  then gfx.rect(x,y,w,h) end
      
      if t.col_frame then
        F_Get_SSV(obj.gui_color[t.col_frame])
        gfx.rect(x,y,w,h,1)
      end  
      if t.txt_col then F_Get_SSV(obj.gui_color[t.txt_col]) else gfx.set(1,1,1) end
      if t.txt then
        gfx.setfont(1, t.fontname, t.fontsize)
        local measurestrname = gfx.measurestr(t.txt)
        if not t.txt_pos then
          gfx.x = x + (w-measurestrname)/2
         elseif t.txt_pos == 1 then -- right aligned
          gfx.x = x + w-measurestrname- 2
         elseif t.txt_pos == 2 then -- left aligned
          gfx.x = x+2
        end
        gfx.y = y + (h-gfx.texth)/2
        if t.a_txt then gfx.a = t.a_txt end
        gfx.drawstr(t.txt)
      end              
    end

    -- STEP --------------------

     if t.frame_type == 2 then
      gfx.a = obj.blit_alpha2
      gfx.blit(3, 1, math.rad(0),
              0,
              0,
              obj.glass_side,
              obj.glass_side,
              x,y1,w,h1,
              0, 0)
      h1 = h * (t.val_step/127)
      y1 = h-h1+y
      gfx.a = obj.blit_alpha2 + (obj.blit_alpha3 - obj.blit_alpha2) * (t.val_step/127)
      if t.val_step > 0 and t.col_frame then
        F_Get_SSV(obj.gui_color[t.col_frame])
        gfx.rect(x,math.ceil(y1),w,h1,1)
      end
    end
    
    -- PAD ---------------------------
    if t.frame_type == 3 then
      gfx.blit(3, 1, math.rad(0),
              0,
              0,
              obj.glass_side,
              obj.glass_side,
              x,y1,w,h1,
              0, 0)
      if t.txt_col then F_Get_SSV(obj.gui_color[t.txt_col]) else F_Get_SSV(obj.gui_color.white) end

      if t.MIDInote then
        local txt_note = F_Convert_Num2Pitch(t.MIDInote)
        if t.MIDInote == data.StSeq_midi_offset and data.key_names ~= 2 then txt_note = txt_note ..' ('..t.MIDInote..')' end
        --gfx.set(1,1,1)
        gfx.setfont(1, t.fontname, t.fontsize)
        local measurestrname = gfx.measurestr(txt_note)
        gfx.x = x + 2--(w-measurestrname)/2
        gfx.y = y + 2--(h-gfx.texth)/2
        if t.a_txt then gfx.a = t.a_txt end
        gfx.drawstr(txt_note)
      end

      if t.txt and not t.collapsed then
        --gfx.set(1,1,1)
        gfx.setfont(1, t.fontname, obj.fontsize3)
        local measurestrname = gfx.measurestr(t.txt)
        gfx.x = x + 2--(w-measurestrname)/2
        gfx.y = y + gfx.texth + 2--(h-gfx.texth)/2
        if t.a_txt then gfx.a = t.a_txt end
        gfx.drawstr(t.txt)
      end
    end
    --  KNOB  -----------------------------------------
    if t.frame_type == 4 then
      gfx.blit(3, 1, math.rad(0),
              0,
              0,
              obj.glass_side,
              obj.glass_side,
              x,y1,w,h1,
              0, 0)
      
      if t.knob_val then
        GUI_knob(t, t.knob_val)
        if t.txt_col then F_Get_SSV(obj.gui_color[t.txt_col]) else F_Get_SSV(obj.gui_color.white) end  
        gfx.setfont(1, obj.fontname, obj.fontsize5)
        local measurestrname = gfx.measurestr(t.knob_val_alias)
        gfx.x = math.floor(x + (w-measurestrname)/2)   
        if t.knob_alias and t.knob_alias ~= '' then 
          gfx.y = y + (h-gfx.texth)/2 + 4
         else
          gfx.y = y + h-gfx.texth*1.5
        end
        if t.a_txt then gfx.a = t.a_txt end
        gfx.drawstr(t.knob_val_alias)        
      end
      if t.knob_alias then
        if t.txt_col then F_Get_SSV(obj.gui_color[t.txt_col]) else F_Get_SSV(obj.gui_color.white) end  
        gfx.setfont(1, obj.fontname, obj.fontsize5)
        local measurestrname = gfx.measurestr(t.knob_alias)
        gfx.x = math.floor(x + (w-measurestrname)/2)
        gfx.y = math.floor(y + h - gfx.texth)
        if t.a_txt then gfx.a = t.a_txt end
        gfx.drawstr(t.knob_alias)        
      end      
    end
    
  end
  --------------------------------------------------------------------     
  function GUI_knob(t, val)
    local  x,y,w,h = t.x, t.y, t.w, t.h
    if not val then val = 0 end
    local ang_lim = -30 -- grad
    local x0 = math.floor(x+w/2 )-1
    local r0 = math.floor(w/2)-1
    local y0 = math.floor(y+ h/2-(r0*math.sin(math.rad(ang_lim)))/2)
    
    -- arc
      gfx.a = 0.01
      for i = 1 , 3, 0.2  do 
        gfx.arc(x0,y0,      r0-i, math.rad(-90 + ang_lim ), math.rad(-90), 1)
        gfx.arc(x0,y0-1,  r0-i, math.rad(-90 ), math.rad(0), 1) 
        gfx.arc(x0+1,y0-1,    r0-i, math.rad(0), math.rad(90), 1) 
        gfx.arc(x0+1,y0,      r0-i, math.rad(90), math.rad(90- ang_lim), 1) 
      end
    
    -- value
      if t.man_col then F_Get_SSV(obj.gui_color[t.man_col]) end
      gfx.a = 0.2
      local com_gr = 180-ang_lim*2
      if t.is_centered then
        local ang_val = val*com_gr/2
        for i = 1 , 3, 0.2  do 
          if ang_val > 0 and ang_val <= 90 then 
            gfx.arc(x0+1,y0-1,r0-i, math.rad(0), math.rad(ang_val), 1) 
           elseif ang_val > 0 and ang_val <= 180 then
            gfx.arc(x0+1,y0-1,r0-i, math.rad(0), math.rad(90), 1)  
            gfx.arc(x0+1,y0,r0-i, math.rad(90), math.rad(ang_val), 1)  
           elseif ang_val > -90 and ang_val <= 0 then 
            gfx.arc(x0,y0-1,r0-i, math.rad(0), math.rad(ang_val), 1)
           elseif ang_val <= -90 then
            gfx.arc(x0,y0-1,r0-i, math.rad(-90), math.rad(0), 1) 
            gfx.arc(x0,y0,r0-i, math.rad(-90), math.rad(ang_val), 1)                      
          end
        end        
       else
        local ang_val = -90+ang_lim+ com_gr * val
        for i = 1 , 3, 0.2  do 
          if ang_val <= -90 then gfx.arc(x0,y0,r0-i, math.rad(-90+ang_lim ), math.rad(ang_val), 1)
            elseif ang_val <= 0 then 
              gfx.arc(x0,y0,r0-i, math.rad(-90+ang_lim ), math.rad(-90), 1)
              gfx.arc(x0,y0-1,r0-i, math.rad(-90), math.rad(ang_val), 1)
            elseif ang_val <= 90 then 
              gfx.arc(x0,y0,r0-i, math.rad(-90+ang_lim ), math.rad(-90), 1)
              gfx.arc(x0,y0-1,r0-i, math.rad(-90), math.rad(0), 1) 
              gfx.arc(x0+1,y0-1,r0-i, math.rad(0), math.rad(ang_val), 1)   
            elseif ang_val <= 180 then 
              gfx.arc(x0,y0,r0-i, math.rad(-90+ang_lim ), math.rad(-90), 1)
              gfx.arc(x0,y0-1,r0-i, math.rad(-90), math.rad(0), 1) 
              gfx.arc(x0+1,y0-1,r0-i, math.rad(0), math.rad(90), 1)  
              gfx.arc(x0+1,y0,r0-i, math.rad(90), math.rad(ang_val), 1)                         
          end
        end
      end
  end  
  -----------------------------------------------------------------------
  function F_gfx_rect(x,y,w,h)
    if x and y and w and h then
      gfx.x, gfx.y = x,y
      gfx.line(x, y, x+w, y)
      gfx.line(x+w, y+1, x+w, y+h - 1)
      gfx.line(x+w, y+h,x, y+h)
      gfx.line(x, y+h-1,x, y+1)
    end
  end
  ------------------------------------------------------------------
  function MOUSE_match(b, offs, x_only)
    if b and b.x and b.y and b.w and b.h then
      local mouse_y_match = b.y
      local mouse_h_match = b.y+b.h
      if offs then
        mouse_y_match = mouse_y_match - offs
        mouse_h_match = mouse_y_match+b.h
      end
      if not x_only then
        if mouse.mx > b.x
          and mouse.mx < b.x+b.w
          and mouse.my > mouse_y_match
          and mouse.my < mouse_h_match
          then return true
        end
       else
        if mouse.mx > b.x
          and mouse.mx < b.x+b.w
          then return true
        end
      end
    end
  end
  -----------------------------------------------------------------------
  function MOUSE_button(xywh, offs, is_right)
    if is_right then
      if MOUSE_match(xywh, offs)
        and mouse.RMB_state
        and not mouse.last_RMB_state
        then
          mouse.last_obj = xywh.mouse_id
          return true
       end
     else
      if MOUSE_match(xywh, offs)
        and mouse.LMB_state
        and not mouse.last_LMB_state
        then
          mouse.last_obj = xywh.mouse_id
          return true
      end
    end
  end
  -----------------------------------------------------------------------
  function MOUSE_button2(xywh, offs)
    if MOUSE_match(xywh, offs) and mouse.LMB_state and mouse.last_LMB_state then
      mouse.last_obj_state = xywh.state
    end
    if MOUSE_match(xywh, offs) and mouse.LMB_state then
      mouse.last_obj2 = xywh.mouse_id
    end
  end
  -----------------------------------------------------------------------  
  function Patterns_GetSelectedItem()
    local sel_item = reaper.GetSelectedMediaItem(0,0)
    if not sel_item then return end
    local take = reaper.GetActiveTake(sel_item)
    if not reaper.TakeIsMIDI(take) then return end
    if not patterns.tr_GUID then return end
    local it_tr = reaper.GetMediaItemTrack( sel_item )
    local it_tr_GUID=reaper.GetTrackGUID( it_tr ):gsub('-','')
    local check_GUID = patterns.tr_GUID:gsub('-',''):gsub('\n','')
    if it_tr_GUID == check_GUID then  return sel_item end
  end
  -----------------------------------------------------------------------
  function Patterns_InsertNewItem(new_name, prevent_overlap)
    --reaper.Main_OnCommand(40289,0) -- unselect all items
    -- get track
      if not patterns.tr_GUID then reaper.MB('Patterns track not found',name, 0) return end
      local sel_tr =  reaper.BR_GetMediaTrackByGUID( 0,patterns.tr_GUID)
      if not sel_tr then reaper.MB('Patterns track not found',name, 0) return end
    -- add/select new item
      local edit_cur = reaper.GetCursorPosition()
      --local new_st_time = edit_cur
      local new_len_beats
      if patterns.cur_pattern and patterns[patterns.cur_pattern] and patterns[patterns.cur_pattern].length then new_len_beats = patterns[patterns.cur_pattern].length else new_len_beats = 1 end
      local new_len = reaper.TimeMap2_beatsToTime( 0, 0,  new_len_beats )
      local new_st_time = edit_cur
      if prevent_overlap then
        for itemidx = 1,  reaper.CountTrackMediaItems( sel_tr ) do
          local it =  reaper.GetTrackMediaItem( sel_tr, itemidx -1)
          local it_pos = reaper.GetMediaItemInfo_Value( it, 'D_POSITION')
          local it_next =  reaper.GetTrackMediaItem( sel_tr, itemidx)
          local it_len = reaper.GetMediaItemInfo_Value( it, 'D_LENGTH')
          if new_st_time and not (new_st_time >= it_pos and new_st_time <= it_pos+it_len) then  else new_st_time = it_pos+it_len end
          if edit_cur >= it_pos and edit_cur <= it_pos+it_len then new_st_time = it_pos+it_len  end
        end
      end
      if not new_st_time then new_st_time = 0 end
      local new_end_time = new_st_time + new_len
      
      
      local new_item = Patterns_GetSelectedItem()
      if not new_item then 
        new_item = reaper.CreateNewMIDIItemInProj( sel_tr, new_st_time,new_end_time) 
      end
      reaper.SetMediaItemInfo_Value( new_item, 'B_UISEL', 1 )

    -- add take to media item
      local act_take = reaper.GetActiveTake(new_item)
      --reaper.GetSetMediaItemTakeInfo_String( act_take, 'P_NAME', '',  1 )

    -- get guid
      local itemGUID = reaper.BR_GetMediaItemGUID( new_item )
      local _, poolGUID = reaper.BR_GetMidiTakePoolGUID( act_take )

      return act_take, itemGUID, poolGUID
  end
  -----------------------------------------------------------------------------------
  function Patterns_Update2(pattern_tr, pat)
    -- check1
      if     not patterns[pat] 
          or not patterns[pat].takes 
          or not pattern_tr 
          or not patterns[pat].rows
          or #patterns[pat].rows == 0
        then  
        return 
      end
      
    
    -- form groove table
      local gr_t = {}
      local groove_path = reaper.GetResourcePath()..'/Grooves/'..patterns[pat].groove..'.rgt'
      local file = io.open(groove_path, 'r')
      if file then 
        file = io.open(groove_path, 'r')
        local groove_content = file:read('a')
        file:close()          
        for line in groove_content:gmatch('[^\r\n]+') do  
          if tonumber(line) then gr_t[#gr_t+1] = tonumber(line)/2 end  
        end
      end              
      patterns[pat].groove_t = gr_t
    
    -- loop takes
    for tk = 1, #patterns[pat].takes do
      if not patterns[pat].takes[tk] or not patterns[pat].takes[tk].itemGUID then goto skip_next_take end
      
      -- check2
        local pattern_item = reaper.BR_GetMediaItemByGUID( 0, patterns[pat].takes[tk].itemGUID)
        if not pattern_item then goto skip_next_take end
        local pattern_item_track = reaper.GetMediaItem_Track( pattern_item )
        if pattern_item_track ~= pattern_tr then goto skip_next_take end
        local pattern_item_take = reaper.GetActiveTake(pattern_item)
        if not reaper.TakeIsMIDI(pattern_item_take) then goto skip_next_take end

      -- upd pattern item
        reaper.GetSetMediaItemTakeInfo_String( pattern_item_take, 'P_NAME', '>'..patterns[pat].name,  1 )
        local _, notecnt = reaper.MIDI_CountEvts( pattern_item_take )
        for i = notecnt, 1, -1 do reaper.MIDI_DeleteNote( pattern_item_take, i-1 ) end

      -- pattern item properties
        local item = {pos =  reaper.GetMediaItemInfo_Value( pattern_item, 'D_POSITION' ),
                len =  reaper.GetMediaItemInfo_Value( pattern_item, 'D_LENGTH' ),
                rate = reaper.GetMediaItemTakeInfo_Value( pattern_item_take, 'D_PLAYRATE' ),
                offs = reaper.GetMediaItemTakeInfo_Value( pattern_item_take, 'D_STARTOFFS' )
                }
        _, _, _, item.pos_beats = reaper.TimeMap2_timeToBeats( 0, item.pos -item.offs)
        
      -- pattern com length values
        local PI_len_beats = 4*patterns[pat].length / item.rate
        
      -- contruct MIDI from pattern item
        for block = 1, #blocks do
          if not patterns[pat].rows[block] then goto skip_next_block end 
          
          local step_cnt = patterns[pat].rows[block].steps * patterns[pat].length
          local step_len_beats = PI_len_beats/step_cnt
          
          local last_step_pos = nil
          smpl_lim = {}
          for step = step_cnt, 1, -1 do 
            if patterns[pat].rows[block].values[step] and patterns[pat].rows[block].values[step] > 0 then
              
              -- get position
                local step_pos_beats = step_len_beats * (step-1)
                
              -- get velocity
                local step_vel = math.floor(patterns[pat].rows[block].values[step]*blocks[block].vol)
                
              -- app swing
                if patterns[pat].groove == 'Swing' 
                  and step_cnt % 4 == 0 
                  and blocks[block].fol_gr == 1 
                  then
                  if step % 2 == 0 then step_pos_beats = step_pos_beats + step_len_beats*patterns[pat].groove_val end
                end                
              
              -- app groove
                if patterns[pat].groove_t 
                  and blocks[block].fol_gr == 1 
                  and #patterns[pat].groove_t > 0 then
                  for i = 1, #patterns[pat].groove_t-1 do
                    
                    if step_pos_beats > patterns[pat].groove_t[i] 
                      and step_pos_beats < patterns[pat].groove_t[i+1] 
                      and math.abs(step_pos_beats - patterns[pat].groove_t[i]) > 0.001 
                      then 
                      local half = (patterns[pat].groove_t[i+1]-patterns[pat].groove_t[i])/2
                      
                      if step_pos_beats >= half then 
                        step_pos_beats = step_pos_beats + (patterns[pat].groove_t[i+1]-step_pos_beats)*patterns[pat].groove_val
                       else
                        step_pos_beats = step_pos_beats - (step_pos_beats-patterns[pat].groove_t[i])*patterns[pat].groove_val
                      end
                      break
                    end
                  end
                end
                
              -- convert to ppq/ cut by itself
                step_pos_ms =  reaper.TimeMap2_beatsToTime( 0, item.pos_beats + step_pos_beats)
                local step_posPPQ = reaper.MIDI_GetPPQPosFromProjTime( pattern_item_take, step_pos_ms) 
                local step_end_ms = reaper.TimeMap2_beatsToTime( 0, item.pos_beats + PI_len_beats) 
                local step_endPPQ = reaper.MIDI_GetPPQPosFromProjTime( pattern_item_take, step_end_ms)
                if last_step_pos then
                  step_end_ms =  last_step_pos
                  step_endPPQ = reaper.MIDI_GetPPQPosFromProjTime( pattern_item_take, step_end_ms) 
                end
                
                local step_pos_ms_block = step_pos_ms + (blocks[block].gl_offset)*data.Layer_offset_max
                
              -- check is step pos inside pattern item edges
                if step_pos_ms < item.pos or step_pos_ms > item.pos + item.len then goto skip_next_step end                
                last_step_pos = step_pos_ms -- for midi
              
              -- check for cut
                
                
                
              -- insert MIDI  
               reaper.MIDI_InsertNote( 
                pattern_item_take, 
                false, -- selected
                patterns[pat].dumpitems == 1, -- muted
                step_posPPQ, -- start ppq
                step_endPPQ,--pattern_end_PPQ-step_PPQ_pos-1 ,  -- end ppq
                0, -- channel
                blocks[block].MIDI + data.StSeq_midi_offset, -- pitch
                step_vel, -- velocity
                true) -- no sort
                
                
                
              -- insert audio items
                if patterns[pat].dumpitems == 1 then
                  for smpl = 1, #blocks[block].samples do
                    step_pos_ms = step_pos_ms_block + (blocks[block].samples[smpl].offset)*data.Layer_offset_max
                    smpl_lim[smpl] = step_pos_ms
                    -- check is step pos inside pattern item edges
                      if step_pos_ms < item.pos or step_pos_ms > item.pos + item.len then 
                        goto skip_next_smpl 
                      end     
                      
                      local smpl_tr =  reaper.BR_GetMediaTrackByGUID( 0, blocks[block].samples[smpl].tr_GUID )
                      if not smpl_tr then goto skip_next_smpl end
                      local step_item = reaper.AddMediaItemToTrack( smpl_tr )
                      local step_item_take = reaper.AddTakeToMediaItem( step_item )
                      local step_item_src = reaper.PCM_Source_CreateFromFile( blocks[block].samples[smpl].filename)
                      local step_item_src_len = reaper.GetMediaSourceLength( step_item_src )
                      local rate = 2^((blocks[block].gl_pitch+blocks[block].samples[smpl].pitch)/12)
                      step_item_src_len = step_item_src_len / rate
                      reaper.SetMediaItemInfo_Value( step_item, 'D_POSITION', step_pos_ms)
                      reaper.SetMediaItemInfo_Value( step_item, 'D_LENGTH', step_item_src_len)--F_limit(step_end_ms+(blocks[block].samples[smpl].offset)*data.Layer_offset_max - step_pos_ms, 0, step_item_src_len) )
                      reaper.SetMediaItemInfo_Value( step_item, 'D_FADEINLEN', 0 )
                      reaper.SetMediaItemInfo_Value( step_item, 'D_FADEOUTLEN', 0.001 )
                      reaper.SetMediaItemInfo_Value( step_item, 'B_LOOPSRC', 0 )
                      reaper.SetMediaItemInfo_Value( step_item, 'D_VOL', step_vel / 127 )
                      reaper.SetMediaItemTakeInfo_Value( step_item_take, 'D_PITCH', blocks[block].gl_pitch )
                      reaper.SetMediaItemTakeInfo_Value( step_item_take, 'D_PLAYRATE', rate)
                       
                      reaper.GetSetMediaItemTakeInfo_String( step_item_take, 'P_NAME', F_extract_filename(blocks[block].samples[smpl].filename), true )
                      reaper.BR_SetTakeSourceFromFile2( step_item_take, blocks[block].samples[smpl].filename,false,true)
                      ::skip_next_smpl::
                  end
                end
                
              ::skip_next_step::
            end              
          end
          
          ::skip_next_block::
        end
        reaper.MIDI_Sort( pattern_item_take )
        
      ::skip_next_take::
    end
  end
  -----------------------------------------------------------------------  
  function Act(id) reaper.Main_OnCommand(id, 0) end
  -----------------------------------------------------------------------
  function F_UnpoolItem(item)
    _, chunk = reaper.GetItemStateChunk(item, '', false)
    local t = {} for line in chunk:gmatch('[^\n\r]+') do t[#t+1] = line end
    for i = 1, #t do
      if t[i]:find('POOLCOLOR') then t[i] = '' end
      if t[i]:find('<SOURCE MIDIPOOL') then t[i] = '<SOURCE MIDI' end
      local new_pool = reaper.genGuid('')
      if t[i]:find('POOLEDEVTS') then t[i] = 'POOLEDEVTS '..new_pool end
    end
    out_ch = table.concat(t, '\n')
    reaper.SetItemStateChunk(item,out_ch, true )
    return new_pool
  end
  
  -----------------------------------------------------------------------
  function Patterns_Update() 
    if (not update_patterns and not update_patterns_minor) then return end
    update_patterns = false
    
      
    -- check pattern track
      if not patterns.tr_GUID then return end
      local tr = reaper.BR_GetMediaTrackByGUID( 0,patterns.tr_GUID)
      if not tr then return end
    
    
    -- validate takes/clear patterns table
      for pat = 1, #patterns do
        if patterns[pat].takes then
          for tk = #patterns[pat].takes, 1, -1 do
            local it = reaper.BR_GetMediaItemByGUID( 0, patterns[pat].takes[tk].itemGUID )
            if not it then table.remove(patterns[pat].takes, tk) end
          end
        end
      end
    
    -------------------------------    
    -- check for POOL GUIDs
      -- collect pooled GUIDs
        local is_there_pooled_takes = nil
        local  pool_items = {}
        for i =1,  reaper.CountTrackMediaItems( tr ) do
          local tr_item = reaper.GetTrackMediaItem( tr, i-1 )
          local take = reaper.GetActiveTake(tr_item)
          if reaper.TakeIsMIDI(take) then
            local ret, poolGUID = reaper.BR_GetMidiTakePoolGUID( take ) 
            if ret then 
              is_there_pooled_takes = true
              local it_GUID = reaper.BR_GetMediaItemGUID(tr_item)
              local pat_ex = nil
              for pat = 1, #patterns do
                if patterns[pat].takes then
                  for tk = 1, #patterns[pat].takes do
                    if it_GUID == patterns[pat].takes[tk].itemGUID then 
                      pat_ex = pat 
                    end
                  end
                end
              end
              pool_items[#pool_items+1]  = {it_GUID = it_GUID, 
                    poolGUID = poolGUID, 
                    pat_ex = pat_ex}
            end
          end
        end        
    
      -- sort table of linked pooles      -- skip if there arnt pool takes
        local src_pool = {}
        if not is_there_pooled_takes then goto skip_pool_mod end    
        for i = 1, #pool_items do
          local poolGUID = pool_items[i].poolGUID
          if not src_pool[poolGUID] then src_pool[poolGUID] = {}  end  
          src_pool[poolGUID][#src_pool[poolGUID]+1] = {it_GUID = pool_items[i].it_GUID, pat_ex = pool_items[i].pat_ex}
        end
      -- clear from existed itemGUIDs / move pat to upper level
        for key in pairs(src_pool) do
          for i = 1, #src_pool[key] do 
            if src_pool[key][i].pat_ex then 
              src_pool[key].pat = src_pool[key][i].pat_ex 
              src_pool[key][i].pat_ex = nil
              local it_GUID = src_pool[key][i].it_GUID
              for pat = 1, #patterns do
                if patterns[pat].takes then
                  for tk = 1, #patterns[pat].takes do
                    if it_GUID == patterns[pat].takes[tk].itemGUID  then
                      src_pool[key][i].it_GUID = nil
                      break
                    end
                  end
                end
              end
            end            
          end
        end
      -- unpool items/add to patterns
        for key in pairs(src_pool) do
          if src_pool[key].pat then
            local out_pat = src_pool[key].pat
            for i = 1, #src_pool[key] do
              local item =  reaper.BR_GetMediaItemByGUID( 0, src_pool[key][i].it_GUID )
              if item then 
                Patterns_AddTakeToPattern(out_pat, src_pool[key][i].it_GUID)
                F_UnpoolItem(item)
              end
            end
          end
        end
      
      --force_undo = 'Unpool items and add to related patterns'
      ::skip_pool_mod::
    -------------------------------
    -- check selected item pattern
      local sel_item = reaper.GetSelectedMediaItem(0,0)
      if sel_item then
        local take = reaper.GetActiveTake(sel_item)        
        if reaper.TakeIsMIDI(take) and reaper.GetMediaItemTrack( sel_item ) == tr then
          local item_guid = reaper.BR_GetMediaItemGUID( sel_item )
          for pat = 1, #patterns do
            if patterns[pat] and patterns[pat].takes then
              for tk = 1, #patterns[pat].takes do
                if patterns[pat].takes[tk].itemGUID == item_guid then patterns.cur_pattern = pat break end
              end
            end
          end          
        end
      end
    
    
    -- check ex cur pat
      if not patterns[patterns.cur_pattern] then 
        if patterns.cur_pattern == 0 then 
          for i = 1, #patterns do if patterns[i] ~= nil then patterns.cur_pattern = i break end end
         else 
          if patterns.cur_pattern then 
            for i = patterns.cur_pattern, 1,-1 do 
              if patterns[i] ~= nil then patterns.cur_pattern = i break end 
            end
          end
        end
      end
      

    -- rename parent track
      local _, tr_name = reaper.GetSetMediaTrackInfo_String( tr, 'P_NAME', '> Patterns', 1 )
      --retval, stringNeedBig reaper.GetSetMediaTrackInfo_String( tr, 'P_NAME', stringNeedBig, setnewvalue )

    -- reset names for regular items
      for i = 1,  reaper.CountTrackMediaItems( tr ) do
        local item =  reaper.GetTrackMediaItem( tr,i-1)
        local take = reaper.GetActiveTake(item)
        if take and reaper.TakeIsMIDI(take) then
          local ret, take_name = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', '',  0 )
          if ret then reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', take_name:gsub('>',''),  1 ) end
        end
      end
      
    -- remove all child items
      for block = 1, #blocks do
        if blocks[block].overlap == 1 then
          if blocks[block].samples then
            for sample = 1, #blocks[block].samples do
              local tr_GUID = blocks[block].samples[sample].tr_GUID
              if tr_GUID then
                local tr_child = reaper.BR_GetMediaTrackByGUID( 0,tr_GUID)
                if tr_child then
                  for it_id = reaper.CountTrackMediaItems( tr_child ), 1, -1  do
                    local tr_it =  reaper.GetTrackMediaItem( tr_child, it_id-1 )
                    reaper.DeleteTrackMediaItem( tr_child, tr_it )
                  end
                end
              end
            end
          end
        end
      end  
    
    reaper.PreventUIRefresh( -1 )
    
    -- upd patterns
      if update_patterns_minor then 
        Patterns_Update2(tr, patterns.cur_pattern)
       else
        for pat = 1, #patterns do Patterns_Update2(tr, pat)  end
      end
    
    -- dump blocks MIDI
      -- get block from cutby value
      local function F_GetBlockidFromCutbyValue(cutby)
        for block = 1, #blocks do 
          if blocks[block].MIDI == cutby then return block end
        end
      end
      
    -- prevent overlaps
      local out_items = {}
      for block = 1, #blocks do
        local cut_by_block = F_GetBlockidFromCutbyValue(blocks[block].cutby)
        if blocks[block].samples then 
          for smpl = 1, #blocks[block].samples do
            local last_it_pos = nil
            local smpl_tr = reaper.BR_GetMediaTrackByGUID( 0,blocks[block].samples[smpl].tr_GUID)
            if smpl_tr then 
              for it_id = 1, reaper.CountTrackMediaItems( smpl_tr )  do                
                local tr_it =  reaper.GetTrackMediaItem( smpl_tr, it_id-1 )
                local it_GUID = reaper.BR_GetMediaItemGUID( tr_it )
                local it_pos = reaper.GetMediaItemInfo_Value( tr_it, 'D_POSITION' )
                local it_len = reaper.GetMediaItemInfo_Value( tr_it, 'D_LENGTH' )
                if last_it_pos and it_pos < last_it_pos+last_it_len then
                  local last_it =  reaper.GetTrackMediaItem( smpl_tr, it_id-2 )
                  if last_it then
                    out_items[#out_items ].it_len = it_pos-last_it_pos
                    reaper.SetMediaItemInfo_Value(last_it, 'D_LENGTH',it_pos-last_it_pos )
                  end
                end
                out_items[#out_items+1] = { it_pos=it_pos,
                                            it_len=it_len,
                                            it_GUID=it_GUID,
                                            it_block = block,
                                            cut_by_block = cut_by_block }
                last_it_pos = it_pos
                last_it_len = it_len
              end
            end
          end
        end
      end
      
    -- perform cut checking
      for i = 1, #out_items do        
        if out_items[i].cut_by_block then          
           cutting_block = out_items[i].cut_by_block
           
          for j = 1, #out_items do
          
            if out_items[j].it_block == cutting_block then 
              --msg(out_items[j].it_block)
              if out_items[j].it_pos > out_items[i].it_pos 
                and out_items[j].it_pos < out_items[i].it_pos + out_items[i].it_len then
                  local c_it = reaper.BR_GetMediaItemByGUID( 0, out_items[i].it_GUID )
                  reaper.SetMediaItemInfo_Value( c_it, 'D_LENGTH', out_items[j].it_pos - out_items[i].it_pos )
                break
              end
            end
          end
        end
      end
      
    reaper.PreventUIRefresh( 1 )
      
    update_patterns_minor = false
    Patterns_Save()
    reaper.UpdateArrange()
  end
  -----------------------------------------------------------------------
  function F_table_copy(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[F_table_copy(orig_key)] = F_table_copy(orig_value)
          end
          setmetatable(copy, F_table_copy(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end
  -----------------------------------------------------------------------
  function Patterns_def_parent_track()
    local tr = reaper.GetSelectedTrack(0,0)
    if not tr then
      reaper.MB('Select track for pattern and try again.',name,  0)
      return
     else
      patterns.tr_GUID = reaper.GetTrackGUID( tr )
    end

    local bits_set=tonumber('111111'..'00000',2)
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+bits_set ) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) -- monitor input
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1)
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMODE',4) -- record MIDI out

    data.current_tab = 1
    Data_Update()
    update_gfx = true
    update_patterns = true
    Patterns_Save()
    force_undo = 'Define pattern track'
    return true
  end
  -----------------------------------------------------------------------  
  function Patterns_Parse_MIDI_take(pattern_id)
    local item = reaper.GetSelectedMediaItem(0,0)
    if not item then return end
    local take = reaper.GetActiveTake( item )
    if not take or not reaper.TakeIsMIDI(take) then return end
    local _, notecntOut = reaper.MIDI_CountEvts( take )
    
    -- get valid pitches
      local pitches = {}
      for bl_id = 1, #blocks do pitches[#pitches+1] = {pitch = blocks[bl_id].MIDI, block = bl_id} end
    
    --  get com ppq
      local item_pos  =reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      local beats, measuresOutOptional = reaper.TimeMap2_timeToBeats( 0, item_pos )
      local measure_sec =  reaper.TimeMap2_beatsToTime( 0, beats, measuresOutOptional+patterns[pattern_id].length )
      local len_ppq =   reaper.MIDI_GetPPQPosFromProjTime( take, measure_sec ) -- measure
      
      
    for noteidx = 1, notecntOut do
      local _, _, _, startppqposOut, _, _, pitch, vel = reaper.MIDI_GetNote( take, noteidx-1 )
      pitch = pitch- data.StSeq_midi_offset
      for i = 1, #pitches do
        if pitch == pitches[i].pitch then
          local pos = math.floor((startppqposOut/len_ppq)*16) + 1
          --[[msg('pitches[i].block '..pitches[i].block )
          msg('pos'..pos)
          msg('vel'..vel)
          msg('pattern_id'..pattern_id)
          msg('----')]]
          if not patterns[pattern_id].rows then patterns[pattern_id].rows = {} end
          if not  patterns[pattern_id].rows [  pitches[i].block  ] then patterns[pattern_id].rows [  pitches[i].block  ] = {} end
          if not patterns[pattern_id].rows [  pitches[i].block  ].values then patterns[pattern_id].rows [  pitches[i].block  ].values = {} end
          patterns[pattern_id].rows [  pitches[i].block  ].values[pos] = vel
        end
      end
    end
    
  end
  -----------------------------------------------------------------------  
  function Patterns_Create()
    if not patterns.tr_GUID then
      local ret = Patterns_def_parent_track()
      if not ret then return end
    end
    local ret, new_name = reaper.GetUserInputs(name, 1, 'Set new pattern name', '#'..1 + #patterns)
    if not ret then return end
    local position = #patterns + 1
    local _, itemGUID, poolGUID = Patterns_InsertNewItem(new_name, true)
    table.insert(patterns, position, {name = new_name,
                                            scroll = 0,
                                            length = data.StSeq_default_pat_length,
                                            groove = 'Swing',
                                            groove_val = 0,
                                            dumpitems = data.StSeq_default_dump_items})
    Patterns_AddTakeToPattern(position, itemGUID,poolGUID)
    update_patterns = true
    patterns.cur_pattern = position
    --force_undo = 'Create new pattern'
    Patterns_FillEmptyFields()
    update_gfx = true
  end 
  -----------------------------------------------------------------------
  function MENU_patterns()
    gfx.x, gfx.y = mouse.mx,mouse.my
    local str = ''
    local expat, mark ,dump_items,fix,add_par_track
    if patterns and #patterns > 0 then expat = true end
    if expat then mark = '' else mark = '#' end
    if data.StSeq_follow_item_selection == 1 then fis = '!' else fis = '' end
    if not patterns.tr_GUID then add_par_track = ' / Define patterns parent track' else add_par_track = '' end
     local actions = {
      { name='#[Patterns]|'},
      { name='Create new pattern'..add_par_track..'|',
        func = function() 
                Patterns_Create() 
                --force_undo = 'Create new pattern' 
              end},

      { name=mark..'Duplicate pattern|',
        func = function()
                if not patterns.cur_pattern then return end
                local new_name
                old_name = patterns[patterns.cur_pattern].name
                if old_name:find('_[%d]+') then
                  repl_str = old_name:match('_[%d]+')
                  new_name = old_name:gsub(repl_str, '_'..tonumber(repl_str:sub(2))+1)
                 else
                  new_name = old_name..'_1'
                end
                table.insert(patterns, patterns.cur_pattern+1,{name = new_name})
                patterns[patterns.cur_pattern+1] = F_table_copy(patterns[patterns.cur_pattern])
                patterns[patterns.cur_pattern+1].name = new_name
                patterns[patterns.cur_pattern+1].takes = {}
                patterns.cur_pattern = patterns.cur_pattern+1
                Patterns_AppCurPatToSelItems(patterns.cur_pattern)
                --Patterns_FillEmptyFields()
                update_patterns = true
                update_gfx = true
                --force_undo = 'Duplicate pattern'
              end},

      { name=mark..'Rename pattern|',
        func = function()
                if not patterns.cur_pattern then return end
                local ret, new_name = reaper.GetUserInputs('MPL Rack', 1, 'Set new pattern name', patterns[patterns.cur_pattern].name)
                if not ret then return end
                patterns[patterns.cur_pattern].name = new_name
                update_patterns = true
                update_gfx = true
              end},


      { name=mark..'Delete pattern|',
        func = function()
                  if not patterns.cur_pattern then return end
                  if patterns[patterns.cur_pattern].takes then
                    for tk = 1, #patterns[patterns.cur_pattern].takes do
                      local item =  reaper.BR_GetMediaItemByGUID( 0, patterns[patterns.cur_pattern].takes[tk].itemGUID)
                      if item then reaper.DeleteTrackMediaItem(  reaper.GetMediaItem_Track( item ), item ) end
                    end
                  end
                  table.remove(patterns,patterns.cur_pattern)
                  update_patterns = true
                  patterns.cur_pattern = nil
                  update_gfx = true
                  force_undo = 'Delete pattern'
               end},

      {name=mark..'Delete all patterns||',
        func = function()
                  local ret_mb = reaper.MB('Remove ALL patterns from current project?','MPL PatternRack',  4)
                  if ret_mb == 6 then
                    for pat = 1, #patterns do
                      for tk = 1, #patterns[pat].takes do
                        local item =  reaper.BR_GetMediaItemByGUID( 0, patterns[pat].takes[tk].itemGUID)
                        if item then reaper.DeleteTrackMediaItem(  reaper.GetMediaItem_Track( item ), item ) end
                      end
                    end
                    
                    local tr_GUID = patterns.tr_GUID
                    patterns = {tr_GUID = tr_GUID}
                    update_patterns = true
                    patterns.cur_pattern = nil
                    update_gfx = true
                    force_undo = 'Delete all patterns'
                  end
               end},

      {name='Parse selected MIDI take as new 16-step pattern|',
        func = function()
                local position = #patterns + 1
                table.insert(patterns, position, {name = new_name,
                                            scroll = 0,
                                            length = data.StSeq_default_pat_length,
                                            groove = 'Swing',
                                            groove_val = 0,
                                            dumpitems = data.StSeq_default_dump_items,
                                            name = '(parsed pattern)'})
                
                patterns.cur_pattern = position
                Patterns_Parse_MIDI_take(position)
                --Patterns_FillEmptyFields(position)
                update_patterns = true
                update_gfx = true
               end},
      {name=mark..'Parse selected MIDI take to current 16-step pattern||',
        func = function()
                if patterns.cur_pattern and patterns[patterns.cur_pattern] then
                  Patterns_Parse_MIDI_take(patterns.cur_pattern)
                  --Patterns_FillEmptyFields(patterns.cur_pattern)
                  update_patterns = true
                  update_gfx = true
                  force_undo = 'Parse selected MIDI take to current 16-step pattern'
                end
               end},               
               
      {name='#[Items]|'},
      { name=mark..'Apply pattern to selected items|',
        func =  function()
                  if not patterns.cur_pattern then return end
                  for i = 1, reaper.CountSelectedMediaItems(0) do
                    local item = reaper.GetSelectedMediaItem(0,i-1)
                    if item then
                      local take = reaper.GetActiveTake(item)
                      if reaper.TakeIsMIDI(take)  then
                        local itemGUID = reaper.BR_GetMediaItemGUID( item )
                        local _, poolGUID = reaper.BR_GetMidiTakePoolGUID( take )
                        Patterns_ClearTakeFromAllPatterns(itemGUID,poolGUID)
                        Patterns_AddTakeToPattern(patterns.cur_pattern, itemGUID,poolGUID)
                      end
                    end
                  end
                  update_patterns = true
                  update_gfx = true
                  --force_undo = 'Apply pattern to selected items'
                end},

      { name=mark..'Select pattern items|',
        func =  function()
                  if not patterns.cur_pattern then return end
                  reaper.Main_OnCommand(40289,0) -- unselect all items
                  for tk = 1, #patterns[patterns.cur_pattern].takes do
                    local item = reaper.BR_GetMediaItemByGUID( 0, patterns[patterns.cur_pattern].takes[tk].itemGUID)
                    if item then reaper.SetMediaItemSelected( item, true ) end
                  end
                  reaper.UpdateArrange()
                end},


      { name=mark..'Unlink selected items from current pattern|',
        func = function ()
                  for i = 1, reaper.CountSelectedMediaItems(0) do
                    local item = reaper.GetSelectedMediaItem(0,i-1)
                    local take = reaper.GetActiveTake(item)
                    if item and take and reaper.TakeIsMIDI(take) then
                      local itemGUID = reaper.BR_GetMediaItemGUID( item )
                      local _, poolGUID = reaper.BR_GetMidiTakePoolGUID( take )
                      Patterns_ClearTakeFromAllPatterns(itemGUID,poolGUID)
                    end
                  end
                  update_patterns = true
                  force_undo = 'Unlink selected items from current pattern'
               end},


      {name='Set selected track as patterns track||',
        func = function () Patterns_def_parent_track() end},


      {name='#[Preferences]|'},
      
      {name= 'Dump items by default|',
       val = data.StSeq_default_dump_items,
       func =  function()
                  data.StSeq_default_dump_items = math.abs(data.StSeq_default_dump_items-1)
                  Data_Update()
                  update_gfx = true
                  update_ProjStateCng = true
                end },
    --[[{name= '#Follow item selection',
     val = data.StSeq_follow_item_selection,
     func =  function()
                data.StSeq_follow_item_selection = math.abs(data.StSeq_follow_item_selection-1)
                Data_Update()
                update_gfx = true
                update_ProjStateCng = true
              end },]]
      {name='|#[Patterns list]|'}

      } -- action list end
    
    
    -- insert pattern options
      if patterns.cur_pattern and patterns.cur_pattern > 0 and patterns[patterns.cur_pattern] then 
        local t_shift = #actions
        table.insert(actions, t_shift,
          {name= '|Pattern #'..patterns.cur_pattern..': enable dump audio items|',
           val = patterns[patterns.cur_pattern].dumpitems,
           func =  function()
                      patterns[patterns.cur_pattern].dumpitems = math.abs(patterns[patterns.cur_pattern].dumpitems-1)
                      update_patterns = true
                      update_gfx = true
                    end })
      end   
       
    -- form pattern list
      local pat_list_shift = #actions
      for i = 1, #patterns do 
        actions[#actions+1] =
          {name = i..': '..patterns[i].name..'|',
          func = function() 
                      patterns.cur_pattern = ret - pat_list_shift
                      Patterns_AppCurPatToSelItems(patterns.cur_pattern)
                      update_patterns = true
                      update_gfx = true
                end}
      end
    
   
    -- from menu string    
      local check
      for i = 1, #actions  do
        if actions[i] then
          if actions[i].val and actions[i].val == 1 then 
            check = '!' 
            if actions[i].name:find'|' == 1 then 
              str = str..'|!'.. actions[i].name:sub(2) 
             else
              str = str..'!'.. actions[i].name
            end
           else 
            str = str..actions[i].name 
          end
          
        end
      end
      
    -- draw/perform menu
      ret = gfx.showmenu(str) 
      if ret > 0 and ret <= #actions then assert(load(actions[ret].func)) end -- perform action
      ret = nil
  end
  -----------------------------------------------------------------------
  function Patterns_AppCurPatToSelItems(pat)
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem(0,i-1)
      if item then
        local take = reaper.GetActiveTake(item)
        if reaper.TakeIsMIDI(take)  then
          local itemGUID = reaper.BR_GetMediaItemGUID( item )
          local _, poolGUID = reaper.BR_GetMidiTakePoolGUID( take )
          Patterns_ClearTakeFromAllPatterns(itemGUID,poolGUID)
          Patterns_AddTakeToPattern(pat, itemGUID,poolGUID)
        end
      end
    end
  end
  
  -----------------------------------------------------------------------
  function MOUSE_Tab_StepSeq()
    -- tooltips
      if mouse.show_tooltip then
        if MOUSE_match(obj.StSeq_global_len) then
          reaper.TrackCtl_SetToolTip( 'Pattern length in measures', mouse.abs_x+10, mouse.abs_y, true )
         elseif MOUSE_match(obj.StSeq_global_groove) and patterns[patterns.cur_pattern] and patterns[patterns.cur_pattern].groove then
          reaper.TrackCtl_SetToolTip( patterns[patterns.cur_pattern].groove, mouse.abs_x+10, mouse.abs_y, true )
         else
          reaper.TrackCtl_SetToolTip( '',0,0,false)
        end
      end


    ------------------- PAT ctrl ------------------------
    -- prev
      if MOUSE_button(obj.StSeq_pat_prev) 
        and patterns.cur_pattern 
        and patterns.cur_pattern > 0 then
          patterns.cur_pattern = F_limit(patterns.cur_pattern - 1, 1, #patterns)
          Patterns_AppCurPatToSelItems(patterns.cur_pattern)
          update_gfx = true
          update_patterns= true
      end

    -- next
      if MOUSE_button(obj.StSeq_pat_next) 
        and patterns.cur_pattern 
        and patterns.cur_pattern > 0  then
          patterns.cur_pattern = F_limit(patterns.cur_pattern + 1, 1, #patterns)
          Patterns_AppCurPatToSelItems(patterns.cur_pattern)
          update_patterns= true
          update_gfx = true
      end      
    -- new
      if MOUSE_button(obj.StSeq_pat_id_new)  then Patterns_Create() end  
          
    -- insert
      if MOUSE_button(obj.StSeq_pat_id_add) and patterns.cur_pattern and patterns.cur_pattern > 0 then
        local _, itemGUID, poolGUID = Patterns_InsertNewItem(nil, true)
        Patterns_AddTakeToPattern(patterns.cur_pattern, itemGUID,poolGUID)
        update_patterns = true
      end
    
    -- remove
      
      if MOUSE_button(obj.StSeq_pat_id_del) 
        and patterns.cur_pattern 
        and patterns.cur_pattern > 0 then
        table.remove(patterns,patterns.cur_pattern)
        update_patterns = true
        update_gfx = true
        force_undo = 'Delete pattern'
      end      
    --  name
      if MOUSE_button(obj.StSeq_pat_id) then MENU_patterns() end

    if not patterns.cur_pattern or not patterns[patterns.cur_pattern] then return end -- BYPASS MODIFIERS IF NO CURRENT PATTERN

    --  len
      if MOUSE_match(obj.StSeq_global_len)
        and mouse.LMB_state
        and not mouse.last_LMB_state  then
          mouse.context = 'glob_measure'
          mouse.context_val = patterns[patterns.cur_pattern].length
      end
      if mouse.LMB_state and mouse.context == 'glob_measure' then
        patterns[patterns.cur_pattern].length = F_limit(math.floor(mouse.context_val - mouse.dy/50), 1, 4)
        update_gfx = true
        update_patterns = true
      end
      
    -- enable DI
      if MOUSE_button(obj.StSeq_global_DI) then
        patterns[patterns.cur_pattern].dumpitems = math.abs(1-patterns[patterns.cur_pattern].dumpitems)
        update_gfx = true
        update_patterns = true
      end
      
    -- PAT groove
      if MOUSE_button(obj.StSeq_global_groove) then
        -- groove menu
        gfx.x, gfx.y = mouse.mx,mouse.my
        local i = 0
        local t = {}
        repeat
        file = reaper.EnumerateFiles(reaper.GetResourcePath()..'/Grooves', i)
        if file then t[#t+1] = file:gsub('.rgt','') end
        i = i +1
        until file == nil or file == ''
        
        table.insert(t, 1, 'Swing')
        
        local ret = gfx.showmenu(table.concat(t,'|'))
        if ret > 0 then
          patterns[patterns.cur_pattern].groove = t[ret]
          update_gfx = true
          update_patterns = true
        end
      end

    -- PAT groove val
      if MOUSE_match(obj.StSeq_global_groove_val)
        and mouse.LMB_state
        and not mouse.last_LMB_state  then
          mouse.last_obj = 'groove val'
          mouse.last_obj_val = patterns[patterns.cur_pattern].groove_val
      end
      if mouse.LMB_state and mouse.last_obj == 'groove val' then
        patterns[patterns.cur_pattern].groove_val = F_limit(mouse.last_obj_val - mouse.dy/200, 0, 1)
        update_gfx = true
        update_patterns = true
      end
    -- PAT hum
      if MOUSE_match(obj.StSeq_global_hum_val)
        and mouse.LMB_state
        and not mouse.last_LMB_state  then
          mouse.last_obj = 'hum val'
          mouse.last_obj_val = data.StSeq_humanize
      end
      if mouse.LMB_state and mouse.last_obj == 'hum val' then
        data.StSeq_humanize = F_limit(mouse.last_obj_val - mouse.dy/200, 0, 1)
        update_gfx = true
        update_patterns = true
      end

    -- PAT random
      if MOUSE_match(obj.StSeq_global_rand_val)
        and mouse.LMB_state
        and not mouse.last_LMB_state  then
          mouse.last_obj = 'rand val'
          mouse.last_obj_val = data.StSeq_random_threshold
      end
      if mouse.LMB_state and mouse.last_obj == 'rand val' then
        data.StSeq_random_threshold = F_limit(mouse.last_obj_val - mouse.dy/200, 0, 1)
        update_gfx = true
        update_patterns = true
      end

    ---------------  SCROLL  -------------------------------
    -- scroll bar
      if MOUSE_match(obj.StSeq_scrollbar)
        and mouse.LMB_state
        and not mouse.last_LMB_state  then
        mouse.last_obj = 'scrollbar'
        mouse.last_obj_val = patterns[patterns.cur_pattern].scroll
      end
      if mouse.LMB_state and mouse.last_obj == 'scrollbar' then
        patterns[patterns.cur_pattern].scroll =
        F_limit(mouse.last_obj_val+mouse.dy/data.fader_mouse_resolution,0,1)
        update_gfx = true
        update_patterns = true
      end


    
    
   ----------------   ROWS   ----------------------

    if not obj.StSeq_blit_shift then obj.StSeq_blit_shift = 0 end
    local blit_offs = -obj.StSeq_blit_level+obj.StSeq_blit_shift
    if (obj.StSeq_blit_level 
      and (mouse.LMB_stamp_y and mouse.LMB_stamp_y < obj.StSeq_blit_level)  )
      then goto skip_loop_rows end
      
    -- click on row
    if not obj.StSeq_rows then return end
      for row = 1, #obj.StSeq_rows do
        -- mute
          if MOUSE_match(obj.StSeq_rows[row].mute, blit_offs)
            and mouse.LMB_state  then
            mouse.context = obj.StSeq_rows[row].mute.mouse_id end
          if MOUSE_match(obj.StSeq_rows[row].mute, blit_offs)
            and not mouse.last_LMB_state
            and mouse.LMB_state  then
             mouse.context_state = obj.StSeq_rows[row].mute.state
          end
          if MOUSE_match(obj.StSeq_rows[row].mute, blit_offs)
            and mouse.context_state
            and mouse.context == obj.StSeq_rows[row].mute.mouse_id then
             blocks[row].mute = math.abs(1-mouse.context_state)
             update_layers = true
             update_gfx = true
             break
          end

        -- solo
          if MOUSE_match(obj.StSeq_rows[row].solo, blit_offs)
            and mouse.LMB_state then
            mouse.context = obj.StSeq_rows[row].solo.mouse_id end
          if MOUSE_match(obj.StSeq_rows[row].solo, blit_offs)
            and not mouse.last_LMB_state
            and mouse.LMB_state then
             mouse.context_state = obj.StSeq_rows[row].solo.state
          end
          if MOUSE_match(obj.StSeq_rows[row].solo, blit_offs)
            and mouse.context_state
            and mouse.context == obj.StSeq_rows[row].solo.mouse_id then
             blocks[row].solo = math.abs(1-mouse.context_state)
             update_layers = true
             update_gfx = true
             break
          end
        
        -- vol
          local ret = MOUSE_knob(obj.StSeq_rows[row].vol,
                                  blocks[row].vol,
                                  scaling.layer_vol,
                                  1,blit_offs )
          if ret then 
            blocks[row].vol = F_limit(ret,0,1,2) 
            update_layers = true
            update_patterns = true
            update_gfx = true
            ret = nil
            break
          end        
        
        --[[ rand
          local ret = MOUSE_knob(obj.StSeq_rows[row].rand,
                                  0,
                                  function() return F_limit(mouse.dy/100,0,1) end,
                                  0,blit_offs )
          if ret then 
          
            for step = 1, #patterns[patterns.cur_pattern].rows[row].values do
              local val = math.random()
              if val > ret then val = 1 else val = 0 end
              patterns[patterns.cur_pattern].rows[row].values[step] = math.floor(100*val)
            end
            update_layers = true
            update_patterns = true
            update_gfx = true
            ret = nil
            break
          end   ]]      
        --  Step count  //  dc set count
          if MOUSE_DC(obj.StSeq_rows[row].stepsframe,blit_offs) then
            local retval, new_cnt = reaper.GetUserInputs( name, 1, 'Set steps per measure', patterns[patterns.cur_pattern].rows[row].steps )
            if not retval or not tonumber(new_cnt) then return end
            new_cnt = math.floor(tonumber(new_cnt))
            if new_cnt >= 1 or new_cnt <=64 then
              patterns[patterns.cur_pattern].rows[row].steps = new_cnt
              update_patterns = true
              update_gfx = true
              break
            end
          end
          -- drag
          if MOUSE_match(obj.StSeq_rows[row].stepsframe,blit_offs)
            and mouse.LMB_state
            --and not mouse.Alt_state
            and not mouse.last_LMB_state  then
            mouse.context = 'cnt_row-'..row
            mouse.context_val = patterns[patterns.cur_pattern].rows[row].steps
          end
          if mouse.LMB_state
            and mouse.last_LMB_state
            --and not mouse.Alt_state
            and mouse.context
            and mouse.context == 'cnt_row-'..row
            and mouse.context_val 
            and mouse.dy ~= 0 then
            
            local out_val
            if mouse.Shift_state then 
              if mouse.dy ~= 0 then 
                out_val = F_limit(  mouse.context_val / 2^(math.floor(mouse.dy*0.05) ) , 1,64) 
               --else out_val = F_limit((mouse.context_val * (2*mouse.dy)), 1,64) 
              end
             else
              out_val = F_limit(mouse.context_val- (mouse.dy*0.05), 1,64)
            end
            patterns[patterns.cur_pattern].rows[row].steps = math.floor(out_val)
            update_patterns = true
            update_gfx = true
            break
          end
          
        --  Step count  //  alt // reset
          if MOUSE_button(obj.StSeq_rows[row].stepsframe,blit_offs) and mouse.Alt_state then
            patterns[patterns.cur_pattern].rows[row].steps = data.StSeq_default_steps
            update_patterns = true
            update_gfx = true
            break
          end
        
        if MOUSE_match(obj.StSeq_rows[row].fol_gr ,blit_offs) then
          -- Groove follow
            if MOUSE_button(obj.StSeq_rows[row].fol_gr ,blit_offs) then
              blocks[row].fol_gr = math.abs(1-blocks[row].fol_gr)
              update_gfx = true
              update_layers = true
              update_patterns = true
              break
            end 
            
            -- random steps
          elseif MOUSE_button(obj.StSeq_rows[row].rand ,blit_offs) then -- skip for drag
              for step = 1, #patterns[patterns.cur_pattern].rows[row].values do
                local val = math.random()
                if val > data.StSeq_random_threshold then val = 1 else val = 0 end
                patterns[patterns.cur_pattern].rows[row].values[step] = math.floor(100*val)
              end
              update_gfx = true
              update_layers = true
              update_patterns = true
              break

            -- humanize steps
          elseif MOUSE_button(obj.StSeq_rows[row].hum ,blit_offs) then -- skip for drag
              for step = 1, #patterns[patterns.cur_pattern].rows[row].values do
                local val = patterns[patterns.cur_pattern].rows[row].values[step]
                if val ~= 0 then
                  local rand_shift = 127 * ( 1- 2*math.random() ) *  data.StSeq_humanize
                  local new_val = math.floor( F_limit(  val + rand_shift, math.floor(127*data.StSeq_humanize), 127) )
                  patterns[patterns.cur_pattern].rows[row].values[step] = new_val
                end
              end
              update_gfx = true
              update_layers = true
              update_patterns = true
              break
                          
            else
          -- Name menu  //  RMB
            if not update_gfx and update_before_menu and update_before_menu == 'menu layers from stepseq' then
              update_before_menu = nil
              local ret = MENU_Layers(row)
              if ret then break end-- stop loop if row match
            end
            if MOUSE_button(obj.StSeq_rows[row].name,blit_offs, true) then
              blocks.cur_block = row
              update_gfx = true
              update_layers = true
              update_before_menu = 'menu layers from stepseq'
            end
            
          -- Name menu  //  DC
            if MOUSE_DC(obj.StSeq_rows[row].name,blit_offs) then
              data.current_tab = 2
              blocks.cur_block = row
              update_gfx = true
              break
            end
          -- Name menu  //  LMB
            if MOUSE_button(obj.StSeq_rows[row].name,blit_offs) then
              blocks.cur_block = row
              -- select tracks or current block if any
                if blocks[blocks.cur_block].samples then 
                  reaper.Main_OnCommand(40297, 0)--Track: Unselect all tracks
                  for smpl = 1, #blocks[blocks.cur_block].samples do
                    local smpl_tr = reaper.BR_GetMediaTrackByGUID( 0, blocks[blocks.cur_block].samples[smpl].tr_GUID )
                    if smpl_tr then reaper.SetTrackSelected( smpl_tr, true ) end
                  end
                end
              update_gfx = true
              update_layers = true
              break
            end
            
        -- scroll on name
          if MOUSE_match(obj.StSeq_rows[row].name)
            and mouse.wheel_trig and mouse.wheel_trig ~= 0 then
            local shift = 0.4
            if mouse.wheel_trig > 0 then
              patterns[patterns.cur_pattern].scroll = F_limit(patterns[patterns.cur_pattern].scroll - shift,0,1)
             else
              patterns[patterns.cur_pattern].scroll = F_limit(patterns[patterns.cur_pattern].scroll + shift,0,1)
            end
            update_gfx = true
            update_patterns = true
          end
                
        end
          
          
      ------------------    STEP    ---------------------------
        for step = 1, #obj.StSeq_rows[row].steps do
          -- scroll - change velo
            if MOUSE_match(obj.StSeq_rows[row].steps[step], blit_offs)
              and mouse.wheel_trig 
              and mouse.wheel_trig ~= 0 
              and patterns[patterns.cur_pattern].rows[row].values[step] ~= 0 then
                local shift = data.StSeq_stepvel_shift_mousewheel
                if mouse.wheel_trig < 0 then shift = shift else shift = -shift end
                patterns[patterns.cur_pattern].rows[row].values[step] = F_limit(patterns[patterns.cur_pattern].rows[row].values[step] - shift,0,127)
                update_gfx = true
                update_patterns = true
            end
            
          -- trig context on left click
            if MOUSE_match(obj.StSeq_rows[row].steps[step], blit_offs)
              and mouse.LMB_state
              and not mouse.last_LMB_state
              then
              mouse.context = obj.StSeq_rows[row].steps[step].mouse_id
              mouse.context_val = patterns[patterns.cur_pattern].rows[row].values[step]
            end

          -- trig context on left click / shift
            if MOUSE_match(obj.StSeq_rows[row].steps[step], blit_offs)
              and mouse.LMB_state
              and mouse.Shift_state
              then
              mouse.context2 = obj.StSeq_rows[row].steps[step].mouse_id
              --mouse.context_val = patterns[patterns.cur_pattern].rows[row].values[step]
            end

          -- left drag insert note
            if MOUSE_match(obj.StSeq_rows[row].steps[step], blit_offs)
              and mouse.LMB_state
              and not mouse.Ctrl_state
              and not mouse.Shift_state
              and mouse.context 
              and mouse.context:match('row[%d]+st[%d]+')
              then
              patterns[patterns.cur_pattern].rows[row].values[step] =  100
              update_patterns = true
              update_gfx = true
            end

          -- left + ctrl + dragY to change velo
            if mouse.LMB_state
              and mouse.context
              and mouse.context == obj.StSeq_rows[row].steps[step].mouse_id
              and mouse.Ctrl_state
              and not mouse.Shift_state then
              local val = F_limit(mouse.context_val-mouse.dy, 0,127)
              patterns[patterns.cur_pattern].rows[row].values[step] =  math.floor(val)
              update_patterns = true
              update_gfx = true
              break
            end

          -- left + shift + dragY to change velo
            if mouse.LMB_state
              and mouse.context
              and mouse.context2
              and mouse.context:match('row[%d]+')
              and mouse.context2:find(mouse.context:match('row[%d]+'))
              and mouse.context2 == obj.StSeq_rows[row].steps[step].mouse_id
              and not mouse.Ctrl_state
              and mouse.Shift_state then
              local val = 1-(mouse.my-(obj.StSeq_rows[row].steps[step].y-blit_offs))/obj.StSeq_rows[row].steps[step].h
              patterns[patterns.cur_pattern].rows[row].values[step] = F_limit(math.floor(val*127),0,127)
              update_patterns = true
              update_gfx = true
            end

          -- right drag remove note
            if MOUSE_match(obj.StSeq_rows[row].steps[step], blit_offs) and mouse.RMB_state then
              
              patterns[patterns.cur_pattern].rows[row].values[step] =  0
              update_patterns = true
              update_gfx = true
            end

        end
        ---------------------------------------


      end-- END loop rows
      ::skip_loop_rows::
  end


  -----------------------------------------------------------------------
  function F_SetFXName(track, fx, new_name)
    local edited_line,edited_line_id, segm
    -- get ref guid
      if not track or not tonumber(fx) then return end
      local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
      if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
      local plug_type = reaper.TrackFX_GetIOSize( track, fx )
    -- get chunk t
      local _, chunk = reaper.GetTrackStateChunk( track, '', false )
      local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
    -- find edit line
      local search
      for i = #t, 1, -1 do
        local t_check = t[i]:gsub('-','')
        if t_check:find(FX_GUID) then search = true  end
        if t[i]:find('<') and search and not t[i]:find('JS_SER') then
          edited_line = t[i]:sub(2)
          edited_line_id = i
          break
        end
      end
    -- parse line
      if not edited_line then return end
      local t1 = {}
      for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
      local t2 = {}
      for i = 1, #t1 do
        segm = t1[i]
        if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
        if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
      end

      if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
      if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST

      local out_line = table.concat(t2,' ')
      t[edited_line_id] = '<'..out_line
      local out_chunk = table.concat(t,'\n')
      --msg(out_chunk)
      reaper.SetTrackStateChunk( track, out_chunk, false )
      reaper.UpdateArrange()
  end
  -----------------------------------------------------------------------  
  function F_dec(data) --http://lua-users.org/wiki/BaseSixtyFour
    if not data then return end
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      data = string.gsub(data, '[^'..b..'=]', '')
      return (data:gsub('.', function(x)
          if (x == '=') then return '' end
          local r,f='',(b:find(x)-1)
          for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
          return r;
      end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
          if (#x ~= 8) then return '' end
          local c=0
          for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
          return string.char(c)
      end))
  end
  -----------------------------------------------------------------------  
  function F_enc(data)--http://lua-users.org/wiki/BaseSixtyFour
    -- character table string
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      return ((data:gsub('.', function(x)
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end 
  -----------------------------------------------------------------------
  function Layers_add_sample_to_layer(filename, layer0)
    if layer0 then layer0 = tonumber(layer0) end
    if not layer0 or not  blocks[layer0] then
      layer = Layers_AddNewLayer()
     else
      layer = layer0
    end
            -- get patterns track
              local tr =  reaper.BR_GetMediaTrackByGUID( 0, patterns.tr_GUID )
              if not tr then reaper.MB('Define pattern track firstly (by creating at least one pattern))',name, 0) end
              local tr_id = reaper.CSurf_TrackToID( tr, false )
              local tr_pos
              if data.insert_tr_at_end then
                tr_pos = reaper.CountTracks(0)
               else
                tr_pos = tr_id
              end
              reaper.InsertTrackAtIndex( tr_pos, true )
              local new_tr = reaper.CSurf_TrackFromID( tr_pos+1, false )
              local new_name = F_extract_filename(filename)
              reaper.GetSetMediaTrackInfo_String( new_tr, 'P_NAME', '>'..new_name, 1 )
              local  new_tr_GUID = reaper.GetTrackGUID( new_tr )
              reaper.TrackList_AdjustWindows( false )
              
            -- send MIDI to new track
              new_send_id = reaper.CreateTrackSend( tr, new_tr )
              reaper.SetTrackSendInfo_Value( tr, 0, new_send_id, 'I_SRCCHAN', -1 )
              reaper.SetTrackSendInfo_Value( tr, 0, new_send_id, 'I_MIDIFLAGS', 0 )

            -- set note range as actual layer MIDI note
              local act_MIDI
              if blocks[layer] then
                act_MIDI = blocks[layer].MIDI
               else
                act_MIDI = 0
              end
              
            -- Add RS5K to new track
              local rs5k_pos = reaper.TrackFX_AddByName( new_tr, 'ReaSamplOmatic5000 (Cockos)', false, 1 )
              if reaper.APIExists('TrackFX_SetNamedConfigParm') then 
                --msg('rs5k_pos='..rs5k_pos)
                --msg('filename='..filename)
                reaper.TrackFX_SetNamedConfigParm(new_tr, rs5k_pos, "FILE0", filename)
                reaper.TrackFX_SetNamedConfigParm(new_tr, rs5k_pos, "DONE","")
              end
              
              local tadj_pos = reaper.TrackFX_AddByName( new_tr, 'time_adjustment', false, -1 )
              F_SetFXName(new_tr, rs5k_pos, 'RS5K '..new_name)

    if not blocks[layer] then blocks[layer] = {} end
    if not blocks[layer].samples then blocks[layer].samples = {} end
    blocks[layer].samples[#blocks[layer].samples+1] = {filename=filename, tr_GUID = new_tr_GUID}
    if #blocks[layer].samples == 1 then blocks[layer].name = new_name end

    update_gfx = true
    update_layers = true
    reaper.UpdateArrange()

  end
  -----------------------------------------------------------------------
  function MENU_Pads()
    gfx.x, gfx.y = mouse.mx,mouse.my
    local str = ''
    local actions = {
       {name='#[Preferences]'},
       {name= 'Set base MIDI pitch',
       func =  function()
                  local retval, midi_base = reaper.GetUserInputs( name, 1, 'Set MIDI base note', data.StSeq_midi_offset )
                  if not retval or not tonumber(midi_base) then return end
                  midi_base = math.floor(tonumber(midi_base))
                  if midi_base >= 1 and midi_base <=127 then
                    data.StSeq_midi_offset = midi_base
                  end
                  update_layers = true
                  update_gfx = true
                end },
      {name= 'Set visual octave shift',
       func =  function()
                  local retval, oct_shift_note_definitions = reaper.GetUserInputs( name, 1, 'Set visual octave shift', data.oct_shift_note_definitions )
                  if retval
                    and tonumber(oct_shift_note_definitions)
                    and tonumber(oct_shift_note_definitions) > -5
                    and tonumber(oct_shift_note_definitions) < 5 then
                    data.oct_shift_note_definitions = math.floor(tonumber(oct_shift_note_definitions))
                    Data_Update()
                    update_gfx = true
                  end
                end },                
      {name= 'Toggle show black keys|',
       check = data.black_keys==1,
       func =  function()
                  data.black_keys = math.abs(1-data.black_keys)
                  Data_Update()
                  update_gfx = true
                end },

      {name= 'Key names: CDE',
       check = data.key_names==0,
       func =  function()
                  data.key_names = 0
                  Data_Update()
                  update_gfx = true
                end },
      {name= 'Key names: DoReMi',
       check = data.key_names==1,
       func =  function()
                  data.key_names = 1
                  Data_Update()
                  update_gfx = true
                end },
      {name= 'Key names: MIDI pitch|',
       check = data.key_names==2,
       func =  function()
                  data.key_names = 2
                  Data_Update()
                  update_gfx = true
                end },

       {name= '>Pad layouts|Korg NanoPAD',
        func =  function()
                  data.pad_matrix_col = 8
                  data.pad_matrix_row = 2
                  data.pad_matrix_order = 1
                  Data_Update()
                  update_gfx = true
                end },
       {name= '<Ableton DrumRack',
        func =  function()
                  data.pad_matrix_col = 4
                  data.pad_matrix_row = 4
                  data.pad_matrix_order = 0
                  Data_Update()
                  update_gfx = true
                end },
                      }


    for i = 1, #actions  do
      if actions[i].check then str = str..'!'..actions[i].name..'|'
        else str = str..actions[i].name..'|'  end
    end
    local ret = gfx.showmenu(str)
    if ret > 0 and ret <= #actions then assert(load(actions[ret].func)) end

  end
  -----------------------------------------------------------------------
  function MENU_Layers(layer, is_layers_tab)
    gfx.x, gfx.y = mouse.mx,mouse.my
    local str,add_entry, ex = '','',''
    if blocks[layer] then
      add_entry = ' - '..layer..': '..blocks[layer].name
     else
      ex = '#'
    end
    local t_fol_gr 
    if blocks[blocks.cur_block] then
      t_fol_gr = 
        {name= 'Block #'..blocks.cur_block..': Toggle follow groove|',
        val = blocks[blocks.cur_block].fol_gr,
        func =  function()
                 blocks[blocks.cur_block].fol_gr = math.abs(1-blocks[blocks.cur_block].fol_gr)
                 update_gfx = true
                 update_layers = true
                 update_pattens = true
               end } 
      else
       t_fol_gr = nil
    end
               
    local actions = {
      {name='#[Blocks]'},
      {name='New block',
        func = function() Layers_AddNewLayer() end },

      {name=ex..'Rename block',
        func =  function()
                  local ret, new_name = reaper.GetUserInputs('MPL Rack', 1, 'Set new layer name', blocks[layer].name)
                  if not ret then return end
                  blocks[layer].name = new_name
                  update_gfx = true
                  update_layers = true
                end},

      {name=ex..'Delete block',
        func = function()
                  for smpl = 1, #blocks[layer].samples do
                    local tr=  reaper.BR_GetMediaTrackByGUID( proj, blocks[layer].samples[smpl].tr_GUID)
                    reaper.DeleteTrack( tr )
                  end
                  table.remove(blocks, layer)
                  for pat = 1, #patterns do table.remove(patterns[pat].rows, layer) end
                  reaper.TrackList_AdjustWindows( false )
                  update_patterns = true
                  update_layers = true
                  update_gfx = true
                  force_undo = 'Remove block'
               end},
      {name='Delete all blocks',
        func = function()
                  for layer = 1, #blocks do
                    for smpl = 1, #blocks[layer].samples do
                      local tr=  reaper.BR_GetMediaTrackByGUID( proj, blocks[layer].samples[smpl].tr_GUID)
                      reaper.DeleteTrack( tr )
                    end
                  end
                  blocks = {}
                  for pat = 1, #patterns do patterns[pat].rows = {} end
                  update_patterns = true
                  update_layers = true
                  update_gfx = true
                  force_undo = 'Remove all blocks'
               end},


      {name='|#[Items]'},
      {name=ex..'Add selected items to current block',
       func = function()
                for sel_it = 1,  reaper.CountSelectedMediaItems( 0 ) do
                  local item = reaper.GetSelectedMediaItem( 0, sel_it-1 )
                  local take = reaper.GetActiveTake(item)
                  if not reaper.TakeIsMIDI(take) then
                    local src = reaper.GetMediaItemTake_Source( take )
                    local filename = reaper.GetMediaSourceFileName( src, '' )
                    Layers_add_sample_to_layer(filename, layer)
                  end
                end
                reaper.Main_OnCommand(40006,0)--Item: Remove items
                update_layers = true
                force_undo = 'Add selected items to current block'
              end},

      {name='Add selected items to separate blocks',
       func = function()
                for sel_it = 1,  reaper.CountSelectedMediaItems( 0 ) do
                  local item = reaper.GetSelectedMediaItem( 0, sel_it-1 )
                  local take = reaper.GetActiveTake(item)
                  if not reaper.TakeIsMIDI(take) then
                    local src = reaper.GetMediaItemTake_Source( take )
                    local filename = reaper.GetMediaSourceFileName( src, '' )
                    Layers_AddNewLayer()
                    Layers_add_sample_to_layer(filename, #blocks)
                  end
                end
                reaper.Main_OnCommand(40006,0)--Item: Remove items
                update_layers = true
                force_undo = 'Add selected items to separate blocks'
              end},
              
       {name='|#[Preferences]'},
       {name= 'Add new tracks at the end of track list|',
       val = data.insert_tr_at_end,
       func =  function()
                  data.insert_tr_at_end = math.abs(data.insert_tr_at_end-1)
                  Data_Update()
                  update_gfx = true
                  update_layers = true
                end },     
        t_fol_gr
     
                      }                      
                      
    if is_layers_tab then  
      actions[#actions+1] ={name='#[Blocks list]'} 
     else
      actions[#actions+1] ={name='#[Steps]'}
      actions[#actions+1] ={name= 'Copy steps from selected block',
                            func =  function() Patterns_steps_copy(patterns.cur_pattern, blocks.cur_block)   end }   
      actions[#actions+1] ={name= 'Paste steps from selected block',
                            func =  function() Patterns_steps_paste(patterns.cur_pattern, blocks.cur_block) force_undo = 'Paste steps to selected block' end }   
                               
                                      
                           
    end
    
    
    
    
    for i = 1, #actions  do
      local check
      if actions[i].val and actions[i].val == 1 then check = '!' else check = '' end
      str = str..check..actions[i].name..'|'
    end

    if is_layers_tab then -- layers list
      for i = 1, #blocks do str = str..i..': '..blocks[i].name..'|' end 
    end 
    
    local ret = gfx.showmenu(str)
    if ret > 0 and ret <= #actions then assert(load(actions[ret].func)) end
    
    if ret > #actions then
      blocks.cur_block = math.floor(ret - #actions)
      update_gfx = true
      update_layers = true
    end
    
  end
  
  -----------------------------------------------------------------------
  function Patterns_steps_copy(cur_pattern, layer)
    if cur_pattern
      and layer
      and patterns[cur_pattern]
      and patterns[cur_pattern].rows
      and patterns[cur_pattern].rows[layer]
      and patterns[cur_pattern].rows[layer].values then
        Buf = { values  = F_table_copy(patterns[cur_pattern].rows[layer].values) ,
                steps   = patterns[cur_pattern].rows[layer].steps}
    end
  end
  -----------------------------------------------------------------------  
  function Patterns_steps_paste(cur_pattern, layer)
    if Buf
      and cur_pattern
      and layer
      and patterns[cur_pattern]
      and patterns[cur_pattern].rows
      and patterns[cur_pattern].rows[layer]
      and patterns[cur_pattern].rows[layer].values then    
        patterns[cur_pattern].rows[layer].values = F_table_copy(Buf.values)
        patterns[cur_pattern].rows[layer].steps = F_table_copy(Buf.steps)
        update_patterns = true
        update_gfx = true
    end
  end  
  -----------------------------------------------------------------------
  function Patterns_AddTakeToPattern(p_id, itemGUID,poolGUID)
    -- add to table
      if not patterns[p_id] then patterns[p_id] = {} end
      if not patterns[p_id].takes then patterns[p_id].takes = {} end
      patterns[p_id].takes[#patterns[p_id].takes+1] = {itemGUID=itemGUID}--,poolGUID=poolGUID }
  end
  -----------------------------------------------------------------------
  function Patterns_ClearTakeFromAllPatterns(itemGUID,poolGUID)
    if not itemGUID or not poolGUID then return end
    -- clear item/pooltake in other patterns
      for pat = 1, #patterns do
        if patterns[pat] and patterns[pat].takes then
          for tk = 1, #patterns[pat].takes do
            if patterns[pat].takes[tk]
              and patterns[pat].takes[tk].itemGUID
              and patterns[pat].takes[tk].itemGUID == itemGUID
              --or patterns[pat].takes[tk].poolGUID == poolGUID) 
              then
                patterns[pat].takes[tk] = {}
            end
          end
        end
      end
  end
  -----------------------------------------------------------------------
  function MOUSE_Tab_Layers()
    -- Layer name
      if MOUSE_button(obj.Layer_id) then MENU_Layers(blocks.cur_block, true) end

    -- layer +
      if MOUSE_button(obj.Layer_id_add) then 
        Layers_AddNewLayer() 
        --force_undo = 'Add new layer'
      end
      if MOUSE_button(obj.Layer_id_del) then 
        table.remove(blocks, blocks.cur_block)
        for pat = 1, #patterns do table.remove(patterns[pat].rows, blocks.cur_block) end
        update_patterns = true
        update_layers = true
        update_gfx = true
        force_undo = 'Delete layer'
      end
    -- layer prev
      if MOUSE_button(obj.Layer_id_prev) then  
        if blocks.cur_block and blocks.cur_block > 0 and blocks[blocks.cur_block] then
          blocks.cur_block = F_limit(blocks.cur_block-1, 1, #blocks)
          update_gfx = true
        end
      end
    -- layer next
      if MOUSE_button(obj.Layer_id_next) then  
        if blocks.cur_block and blocks.cur_block > 0 and blocks[blocks.cur_block] then
          blocks.cur_block = F_limit(blocks.cur_block+1, 1, #blocks)
          update_gfx = true
        end
      end
            
    -- layer mute
      if MOUSE_button(obj.Layer_dyn.mute) then
        if blocks.cur_block and blocks.cur_block > 0 and blocks[blocks.cur_block] then
          blocks[blocks.cur_block].mute = math.abs(1-blocks[blocks.cur_block].mute)
          update_layers = true
        end
      end
    -- layer solo
      if MOUSE_button(obj.Layer_dyn.solo) then
        if blocks.cur_block and blocks[blocks.cur_block] then
          blocks[blocks.cur_block].solo = math.abs(1-blocks[blocks.cur_block].solo)
          update_layers = true
        end
      end
    -- layer overlap
      if MOUSE_button(obj.Layer_dyn.overlap) then
        if blocks.cur_block and blocks[blocks.cur_block] then
          blocks[blocks.cur_block].overlap = math.abs(1-blocks[blocks.cur_block].overlap)
          update_layers = true
        end
      end      
    -- preview
      if MOUSE_button(obj.Layer_dyn.preview) then
        if blocks.cur_block and blocks[blocks.cur_block] then
          local midi_chan = 0
          reaper.StuffMIDIMessage( 0, '0x9'..string.format("%x", midi_chan),
                                      math.floor(blocks[blocks.cur_block].MIDI+data.StSeq_midi_offset),
                                      100)
        end
      end
      
    -- cutby
      if MOUSE_button(obj.Layer_dyn.cutby) then
        gfx.x, gfx.y = mouse.mx,mouse.my
        local str = ''
        for i = 1, #blocks  do
          local add_str = blocks[i].MIDI+data.StSeq_midi_offset..': '..blocks[i].name..'|'
          if i == blocks.cur_block then add_str = '(self: follow overlap settings) '..add_str end
          if blocks[i].MIDI == blocks[blocks.cur_block].cutby then add_str = '!'..add_str end
          str = str..add_str
        end
        local ret = gfx.showmenu(str)
        if ret > 0 then
          if blocks[blocks.cur_block].MIDI ~= blocks[ret].MIDI then 
            blocks[blocks.cur_block].cutby = blocks[ret].MIDI
           else 
            blocks[blocks.cur_block].cutby = -1
          end
          update_layers = true
          update_patterns = true
          update_gfx = true
        end
      end
      
    -- glob pitch
      if blocks.cur_block and blocks[blocks.cur_block] then
        local ret = MOUSE_knob(obj.Layer_dyn.gl_pitch,
                                blocks[blocks.cur_block].gl_pitch,
                                scaling.pitch,
                                0 )
        if ret then 
          blocks[blocks.cur_block].gl_pitch = ret
          update_layers = true
          update_patterns = true
          update_gfx = true
        end
      end
            
    -- glob offs
      if blocks.cur_block and blocks[blocks.cur_block] then
        local ret = MOUSE_knob(obj.Layer_dyn.gl_offset,
                                blocks[blocks.cur_block].gl_offset,
                                scaling.offset,
                                0 )
        if ret then 
          blocks[blocks.cur_block].gl_offset = ret
          update_layers = true
          update_patterns = true
          update_gfx = true
        end
      end
      
    --[[ glob att
      if blocks.cur_block and blocks[blocks.cur_block] then
        local ret = MOUSE_knob(obj.Layer_dyn.gl_attack,
                                blocks[blocks.cur_block].gl_attack,
                                scaling.offset,
                                data.default_attack_ms )
        if ret then 
          blocks[blocks.cur_block].gl_attack = ret
          update_layers = true
          update_patterns = true
          update_gfx = true
        end
      end    ]]  
      
    ---------------  SCROLL  -------------------------------
    -- scroll bar
      if MOUSE_match(obj.Layers_scrollbar)
        and mouse.LMB_state
        and not mouse.last_LMB_state  then
        mouse.last_obj = 'scrollbar_L'
        mouse.last_obj_val = blocks[blocks.cur_block].scroll
      end
      if mouse.LMB_state and mouse.last_obj == 'scrollbar_L' then
        blocks[blocks.cur_block].scroll =
        F_limit(mouse.last_obj_val+mouse.dy/data.fader_mouse_resolution,0,1)
        update_gfx = true
        update_patterns = true
      end

    -- scroll by wheel
      if MOUSE_match(obj.Layers_matrix)
        and mouse.wheel_trig and mouse.wheel_trig ~= 0 then
        local shift = 0.1
        if mouse.wheel_trig > 0 then
          blocks[blocks.cur_block].scroll = F_limit(blocks[blocks.cur_block].scroll - shift,0,1)
         else
          blocks[blocks.cur_block].scroll = F_limit(blocks[blocks.cur_block].scroll + shift,0,1)
        end
        update_gfx = true
        update_patterns = true
      end
    
    
    if not obj.Layers_blit_shift then obj.Layers_blit_shift = 0 end
    local blit_offs = -obj.Layers_blit_level+obj.Layers_blit_shift
     
    -- samples
    if blocks[blocks.cur_block]
      and blocks[blocks.cur_block].samples then
      for smpl = 1, #blocks[blocks.cur_block].samples do
        if obj.Layer_dyn.rows[smpl] then 
        
          -- pitch
            local ret = MOUSE_knob(obj.Layer_dyn.rows[smpl].pitch,
                                    blocks[blocks.cur_block].samples[smpl].pitch,
                                    scaling.pitch,
                                    0,blit_offs )
            if ret then 
              blocks[blocks.cur_block].samples[smpl].pitch = F_limit(ret,-data.Layer_pitch_max/2,data.Layer_pitch_max/2) 
              update_layers = true
              update_patterns = true
              update_gfx = true
              break
            end        
              
          --offset
          local ret = MOUSE_knob(obj.Layer_dyn.rows[smpl].offset,
                                  blocks[blocks.cur_block].samples[smpl].offset,
                                  scaling.offset,
                                  0,blit_offs )
          if ret then 
            blocks[blocks.cur_block].samples[smpl].offset = F_limit(ret,-1,1,2) 
            update_layers = true
            update_patterns = true
            update_gfx = true
            break
          end
          
          
          -- prev
            if MOUSE_button(obj.Layer_dyn.rows[smpl].prev_smpl,blit_offs) then 
              local filename = blocks[blocks.cur_block].samples[smpl].filename
              local out_fn = F_change_fn(filename, -1)
              if out_fn then 
                blocks[blocks.cur_block].samples[smpl].filename = out_fn
                text =  out_fn
                update_layers = true
                update_patterns = true
                update_gfx = true
              end
            end
            
          -- next
            if MOUSE_button(obj.Layer_dyn.rows[smpl].next_smpl,blit_offs) then 
              local filename = blocks[blocks.cur_block].samples[smpl].filename
              
              local out_fn = F_change_fn(filename, 1)
              if out_fn then 
                blocks[blocks.cur_block].samples[smpl].filename = out_fn
                text =  out_fn
                update_layers = true
                update_patterns = true
                update_gfx = true
              end
            end
                        
        end
      end
    end
      
  end
  -----------------------------------------------------------------------  
    function F_change_fn(fn, dir) -- next/previous sample
    local ext = {'wav'}
    -- find path
      local slash 
      local slash_win = fn:reverse():find('\\') if slash_win then slash = slash_win end
      local slash_osx = fn:reverse():find('/') if slash_osx then slash = slash_osx end
      if not slash then return end
      local path = fn:sub(0,-slash-1)
      local cur_file = fn:sub(-slash+1)
    -- get files list
      local  files = {}
      local i = 0
      repeat
      local file = reaper.EnumerateFiles( path, i )
      if file then
        for i = 1, #ext do
          if file:lower():reverse():find(ext[i]:lower():reverse()) == 1 then
            files[#files+1] = file
            break
          end
        end
      end
      i = i+1
      until file == nil
    -- search file list
      local trig_file
      if #files < 2 then return end
    -- next/prev
      if dir == 1 then 
        for i = 2, #files do          
          if files[i-1] == cur_file then trig_file = path..'/'..files[i] break end
        end
        return trig_file
       else 
        for i = #files-1, 1, -1 do
          if files[i+1] == cur_file then trig_file = path..'/'..files[i] break end
        end
        return trig_file
      end
    end  
  -----------------------------------------------------------------------
  function MOUSE_knob(obj_t, val, scale_func, default_val,blit_offs)
    if not blit_offs then blit_offs = 0 end
    if not obj_t then return end
    if (not mouse.last_LMB_state 
            and mouse.LMB_state
            and MOUSE_match(obj_t, blit_offs)
            and mouse.Alt_state)
        or MOUSE_DC(obj_t,blit_offs) 
        then
        return default_val
    end
    -- store context
      if not mouse.last_LMB_state 
        and mouse.LMB_state
        and MOUSE_match(obj_t, blit_offs) 
        and not mouse.Alt_state then
          mouse.context = obj_t.mouse_id
          mouse.context_val = val
      end
    -- app context 
      if mouse.context and mouse.context == obj_t.mouse_id 
        and mouse.last_LMB_state
        and mouse.LMB_state 
        and math.abs(mouse.dy) > 1 then
        return scale_func(mouse.context_val)
      end
    -- wheel
      if MOUSE_match(obj_t, blit_offs) and mouse.wheel_trig ~= 0 then
        return scale_func(val) 
      end
  end
  -----------------------------------------------------------------------
  function Layers_AddNewLayer()
        local steps = data.StSeq_default_steps
        local values = {}
        for i = 1, steps do values[#values+1]= 0 end

        -- check last free note
          local last_row_midi
          if #blocks == 0 then
            last_row_midi = 0
           else
            for note = 0, 127 do
              local ex_midi
              for block = 1, #blocks do if blocks[block].MIDI == note then ex_midi = true end end
              if not ex_midi then last_row_midi = note break end
            end
            if not last_row_midi then last_row_midi = 0 end
          end

          blocks[#blocks+1] = {MIDI = last_row_midi,
                            name = 'Row '..#blocks+1}

        -- add new row to all patterns

          for pat = 1, #patterns do
            if not patterns[pat].rows then patterns[pat].rows = {} end
            patterns[pat].rows[#blocks] = {steps = steps,   values = values}
          end

        update_gfx = true
        update_patterns = true
        update_layers = true
        blocks.cur_block = #blocks
        return blocks.cur_block
  end
  -----------------------------------------------------------------------
  function F_open_URL(url)
   local OS = reaper.GetOS()
     if OS=="OSX32" or OS=="OSX64" then
       os.execute("open ".. url)
      else
       os.execute("start ".. url)
     end
   end
  -----------------------------------------------------------------------
  function Layers_Update() local tr_id
    if not blocks then return end
    if not update_layers then return end
    
    local tr =  reaper.BR_GetMediaTrackByGUID( 0, patterns.tr_GUID )
    if tr then tr_id = reaper.CSurf_TrackToID( tr, false ) - 1 end
    local last_MIDI = 1

    for bl_id = 1, #blocks do
      local act_MIDI = blocks[bl_id].MIDI
      local mute = blocks[bl_id].mute
      local solo = blocks[bl_id].solo
      if not mute then mute = 0 end
      if not solo then solo = 0 end
      local layer_name = blocks[bl_id].name
      if tr then reaper.SetTrackMIDINoteNameEx( 0, tr, act_MIDI, -1, layer_name ) end
      if blocks[bl_id].samples then
        for smpl = 1, #blocks[bl_id].samples do
          local rs5k_tr = reaper.BR_GetMediaTrackByGUID( 0, blocks[bl_id].samples[smpl].tr_GUID )
          if rs5k_tr then
            -- upd tr info
              reaper.SetMediaTrackInfo_Value( rs5k_tr, 'B_MUTE', mute )
              reaper.SetMediaTrackInfo_Value( rs5k_tr, 'I_SOLO', solo )
              
              local rs5k_pos = reaper.TrackFX_AddByName( rs5k_tr, 'RS5K', false, 0 )
              local tadj_pos = reaper.TrackFX_AddByName( rs5k_tr, 'time_adjustment', false, 1 )
              
              
            -- upd time adjustment delay                
              if tadj_pos and tadj_pos >=0 and blocks[bl_id].samples[smpl].offset then
                local offs = (1000 + (blocks[bl_id].gl_offset*data.Layer_offset_max*1000+blocks[bl_id].samples[smpl].offset*data.Layer_offset_max*1000)) /2000
                reaper.TrackFX_SetParamNormalized( rs5k_tr, tadj_pos, 0, offs)                
              end
              
            -- upd rs5k instances
              if rs5k_pos and rs5k_pos >=0 then
                -- Set rs5K sample
                reaper.TrackFX_SetNamedConfigParm( rs5k_tr, rs5k_pos, 'FILE0', blocks[bl_id].samples[smpl].filename )
                reaper.TrackFX_SetNamedConfigParm( rs5k_tr, rs5k_pos, 'DONE', "")
                F_SetFXName(rs5k_tr, rs5k_pos, 'RS5K '..F_extract_filename(blocks[bl_id].samples[smpl].filename))
                reaper.TrackFX_SetParamNormalized( rs5k_tr, rs5k_pos, 2, 0) -- gain for min vel
                reaper.TrackFX_SetParamNormalized( rs5k_tr, rs5k_pos, 3, (act_MIDI+data.StSeq_midi_offset)/127 ) -- note range start
                reaper.TrackFX_SetParamNormalized( rs5k_tr, rs5k_pos, 4, (act_MIDI+data.StSeq_midi_offset)/127 ) -- note range start
                reaper.TrackFX_SetParamNormalized( rs5k_tr, rs5k_pos, 5, 0.5 ) -- pitch for start
                reaper.TrackFX_SetParamNormalized( rs5k_tr, rs5k_pos, 6, 0.5 ) -- pitch for end
                if not blocks[bl_id].samples[smpl].pitch then blocks[bl_id].samples[smpl].pitch = 0 end
                if not blocks[bl_id].gl_pitch then blocks[bl_id].gl_pitch = 0 end
                reaper.TrackFX_SetParamNormalized( rs5k_tr, rs5k_pos, 15,0.5*(  (blocks[bl_id].samples[smpl].pitch+blocks[bl_id].gl_pitch) / 80  +1) ) -- pitch for end
                --reaper.TrackFX_SetParamNormalized( rs5k_tr, rs5k_pos, 9, 0) -- attack
                
                
              end
          end
        end
      end
      last_MIDI = act_MIDI
    end
    if tr then for i = last_MIDI+1, 127 do   reaper.SetTrackMIDINoteNameEx( 0, tr, i, -1, '' )   end end
    Layers_Save()
    update_layers = false
    
    reaper.TrackList_AdjustWindows( false )
  end
  -----------------------------------------------------------------------
  function MENU_main()
    local actions = {

      --{name='#[About]'},
      {name=  name..' thread on Cockos forum',
        func = function() F_open_URL('http://forum.cockos.com/showthread.php?t=188987' ) end},
      {name='Show changelog',
        func = function() reaper.ClearConsole() msg(changelog) end},     
      {name='Shortcuts and mouse modifiers|',
        func = function() reaper.ClearConsole() msg(MOUSE_modifiers) end}, 
      {name='MPL @ SondCloud',
        func = function() F_open_URL('http://soundcloud.com/mp57') end},
      {name='MPL @ VK',
        func = function() F_open_URL('http://vk.com/michael_pilyavskiy') end},
      {name='MPL @ PDJ',
        func = function() F_open_URL('http://promodj.com/MichaelPilyavskiy') end},
      --[[{name='Donate to MPL',
        func = function() F_open_URL('http://www.paypal.me/donate2mpl') end},     ]]   
    }

    gfx.x, gfx.y = mouse.mx,mouse.my
    local str = ''
    for i = 1, #actions  do
      local check
      if actions[i].val and actions[i].val == 1 then check = '!' else check = '' end
      str = str..check..actions[i].name..'|'
    end
    local ret = gfx.showmenu(str)
    if ret > 0 and ret <= #actions then assert(load(actions[ret].func)) end
  end
  -----------------------------------------------------------------------
  function MOUSE_Tab_Pads()
    local midi_chan = 0
    if MOUSE_button(obj.pad_menu) then MENU_Pads() end
    if not obj.Pad_pads then return end
    -- init note on
    for i = 1, 16 do
      if MOUSE_button(obj.Pad_pads[i]) then
        for bl_id  = 1, #blocks do
          if blocks[bl_id] and blocks[bl_id].MIDI == i -1 then
            reaper.StuffMIDIMessage( 0, '0x9'..string.format("%x", midi_chan),
                                        math.floor(blocks[bl_id].MIDI+data.StSeq_midi_offset),
                                        100)

            break
          end
        end
      end
    end

    --init note off
    for i = 1, 16 do
      if MOUSE_match(obj.pad_matrix)
        and not mouse.LMB_state
        and mouse.last_LMB_state then
        for bl_id  = 1, #blocks do
          if blocks[bl_id] and blocks[bl_id].MIDI == i -1 then
            reaper.StuffMIDIMessage( 0, '0x8'..string.format("%x", midi_chan),
                                        math.floor(blocks[bl_id].MIDI+data.StSeq_midi_offset),
                                        0)
            break
          end
        end
      end
    end


  end
  -----------------------------------------------------------------------
  function MENU_undo()  
    gfx.x, gfx.y = mouse.mx,mouse.my
    local str = 'Store current state||'
    for i = #Undo, 1, -1 do str = str..Undo[i].timestamp..'   '..Undo[i].name..'|' end
    local ret = gfx.showmenu(str)
    if ret == 1 then 
      Undo_StoreNewPoint('Manually stored state')
     elseif ret > 1 then 
      Undo_perform(#Undo - ret+2)
    end
  end
  -----------------------------------------------------------------------
  function MOUSE_get()
    mouse.abs_x, mouse.abs_y = reaper.GetMousePosition()
    mouse.mx = gfx.mouse_x
    mouse.my = gfx.mouse_y
    mouse.LMB_state = gfx.mouse_cap&1 == 1
    mouse.RMB_state = gfx.mouse_cap&2 == 2
    --mouse.MMB_state = gfx.mouse_cap&64 == 64
    --mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5
    mouse.Ctrl_state = gfx.mouse_cap&4 == 4
    mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
    mouse.Shift_state = gfx.mouse_cap&8 == 8
    mouse.wheel = gfx.mouse_wheel
    if not mouse.last_obj then mouse.last_obj = 0 end
    if not mouse.last_obj2 then mouse.last_obj2 = 0 end
    -- move state/tooltip state clear
      if not mouse.last_mx or not mouse.last_my or (mouse.last_mx ~= mouse.mx and mouse.last_my ~= mouse.my) then
        mouse.move = true
        mouse.show_tooltip = false
       else
        mouse.move = false
      end

    -- wheel
      if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end
      if not mouse.wheel_trig then mouse.wheel_trig = 0 end

    -- dx/dy
      if (not mouse.last_LMB_state and mouse.LMB_state) then
        mouse.LMB_stamp_x = mouse.mx
        mouse.LMB_stamp_y = mouse.my
      end
      if mouse.LMB_state then
        mouse.dx = mouse.mx - mouse.LMB_stamp_x
        mouse.dy = mouse.my - mouse.LMB_stamp_y
      end
    if run_l < 2 then goto skip_mouse_mod end
    
    -- tooltips
      if mouse.move then mouse.hold_ts = clock mouse.show_tooltip = false end
      if not mouse.move and mouse.hold_ts and clock- mouse.hold_ts > 0.5 then
        if data.show_tooltip == 1 and MOUSE_match({x=0,y=0,w=gfx.w, h=gfx.h}) then
          mouse.show_tooltip = true
        end
      end
      if MOUSE_match({x=0,y=0,w=gfx.w, h=gfx.h}) and not mouse.show_tooltip then reaper.TrackCtl_SetToolTip( '',0,0,false) end

    --undo
      if MOUSE_button(obj.undo) then MENU_undo() goto skip_mouse_mod end
    -- tabs
      for i = 1, obj.tab_cnt do
        if MOUSE_button(obj.tab[i]) then
          data.current_tab = i
          update_gfx = true
          mouse.LMB_stamp_y = nil
          Data_Update()
          return
        end
      end

    -- start dialog
      if data.current_tab == 0 then
        if MOUSE_button(obj.define_pattern) then
          Patterns_def_parent_track()
          update_patterns = true
          update_gfx = true
        end
      end

      if data.current_tab == 1 then MOUSE_Tab_StepSeq() end
      if data.current_tab == 2 then MOUSE_Tab_Layers() end
      if data.current_tab == 3 then MOUSE_Tab_Pads() end

    ::skip_mouse_mod::
    
    if run_l == 0 or run_l == 1 then
      if MOUSE_button(obj.lc_txt) then 
        local ret = reaper.MB(
[[

All MPL stuff with GUI will get a protection like this in near future. 
Once purchased you don`t need to puchase other scripts.
And your license info stored in you REAPER configuration (will not lost after import/export).

After purchasing there will be more privileges for you, if you will need some advanced features or you want me to fix some bugs/behaviour.
By giving some money you support my efforts to do existing or hidden REAPER features better and usable.

Procedure of puchasing MPL`s stuff looks like this:
1) after click "Yes" paypal page will be opened in your default browser, this link used also for donations;
2) send $10;
3) send email to m.pilyavskiy@gmail.com (so I`ll know where to send activation code);
4) wait for email response with activation code. If you didn`t get one, check your spam folder or PM me at any resource mentioned (click on version in top right corner of script GUI);
5) click "Already purchased" and paste activation code;
6) enjoy.

If you have problems with PayPal, you can PM me at Cockos forum or m.pilyavskiy@gmail.com.

Purchase MPL scripts?

]], name..': purchasing',3)
        if ret == 6 then F_open_URL('https://www.paypal.me/donate2mpl') end
      end
      if MOUSE_button(obj.lc_txt2) then  
        local retval, retvals_csv = reaper.GetUserInputs( name, 1, 'License code,extrawidth=400','' )
        if retval then 
          reaper.SetExtState( 'MPL_LC', 'lickey', retvals_csv, true )
          force_upd = true
        end
      end
      
    end
    if run_l == 1 and MOUSE_button(obj.lc_txt3) then run_l = 2 end
    -- info button
      if MOUSE_button(obj.info) then MENU_main() end
      
    -- reset mouse context/doundo
      if (mouse.last_LMB_state and not mouse.LMB_state)
        or (mouse.last_RMB_state and not mouse.RMB_state) then
        mouse.last_obj = 0
        mouse.context = ''
        mouse.context_val = ''
        mouse.last_obj_val = nil
        mouse.dx = 0
        mouse.dy = 0
      end

    -- mouse release
      mouse.last_LMB_state = mouse.LMB_state
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel
      mouse.last_mx = mouse.mx
      mouse.last_my = mouse.my
  end
-----------------------------------------------------------------------    
 function F_open_URL(url)  
  local OS = reaper.GetOS()  
    if OS=="OSX32" or OS=="OSX64" then
      os.execute("open ".. url)
     else
      os.execute("start ".. url)
    end
  end  
  -----------------------------------------------------------------------
  function MOUSE_DC(xywh,blit_offs)
    if MOUSE_match(xywh,blit_offs)
      and not mouse.last_LMB_state
      and mouse.LMB_state
      and mouse.last_click_ts
      and clock - mouse.last_click_ts > 0
      and clock - mouse.last_click_ts < 0.2 then
        return true
    end
    if MOUSE_match(xywh,blit_offs) and not mouse.last_LMB_state and mouse.LMB_state then  mouse.last_click_ts = clock end
  end
  -----------------------------------------------------------------------
  function F_open_URL(url)
    local OS = reaper.GetOS()
    if OS=="OSX32" or OS=="OSX64" then os.execute("open ".. url) else os.execute("start ".. url) end
  end
  -----------------------------------------------------------------------
  function F_Get_SSV(s)
    if not s then return end
    local t = {}
    for i in s:gmatch("[%d%.]+") do t[#t+1] = tonumber(i) / 255 end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
  end
  -----------------------------------------------------------------------
  function GUI_menu(t, check) local name
    local str = ''
    for i = 1, #t do
      name = t[i]
      if check == i-1 then  str = str..'!'..name ..'|'  else str = str..name ..'|'   end
    end
    gfx.x, gfx.y = mouse.mx,mouse.my
    ret = gfx.showmenu(str) - 1
    if ret >= 0 then return ret else return -1 end
  end
 -----------------------------------------------------------------------
  function F_limit(val,min,max,quant_digits)
      if val == nil then return end
      local val_out = val
      if min and val < min then val_out = min end
      if max and val > max then val_out = max end
      local int, dec = math.modf(val_out)
      if dec == 0 then return int end
      if quant_digits then
        return math.floor(val_out*10^quant_digits)/10^quant_digits
      end
      return val_out
    end
 -----------------------------------------------------------------------    
  function F_xywh_gfx()
    -- save xy state
      _, wind_x,wind_y = gfx.dock(-1,0,0,0,0)
      wind_w, wind_h = gfx.w, gfx.h
      if
        not last_wind_x
        or not last_wind_y
        or not last_wind_w
        or not last_wind_h
        or last_wind_w~=wind_w
        or last_wind_h~=wind_h then
        --if debug_mode then msg(string.rep('_',30)..'\n') msg('SAVE WH '..os.date())  end

        reaper.SetExtState( name, 'wind_w', math.floor(wind_w), true )
        reaper.SetExtState( name, 'wind_h', math.floor(wind_h), true )
        update_gfx = true
        Objects_Init()
      end

      if  last_wind_x~=wind_x or last_wind_y~=wind_y then
        --if debug_mode then msg(string.rep('_',30)..'\n') msg('SAVE XY '..os.date())  end
        reaper.SetExtState( name, 'x_pos', math.floor(wind_x), true )
        reaper.SetExtState( name, 'y_pos', math.floor(wind_y), true )
      end

      last_wind_x = wind_x
      last_wind_y = wind_y
      last_wind_w = wind_w
      last_wind_h = wind_h
  end
  --------------------------------------------------------------------
  function Run()
    F_xywh_gfx()
    if run_l == 0 or run_l == 1 then
      if run_l == 0 then cnt = math.floor(os.clock() - ts) end
      
      GUI_backgr(gfx.w,gfx.h)
      F_frame(obj.info)
      F_frame(obj.lc_txt)
      F_frame(obj.lc_txt2)
      obj.lc_txt3.txt = 'Continue after '..5-cnt..' seconds'
      if cnt >= 5 then obj.lc_txt3.txt = 'Continue' end
      F_frame(obj.lc_txt3)
      gfx.update()
      MOUSE_get()
      
      if cnt > 5 and run_l ~= 2 then run_l = 1 end
      
      if char ~= -1 then reaper.defer(Run) else gfx.quit() end 
     elseif run_l == 2 then

    clock = os.clock ()
    
    -- upd gfx
      check_cnt = reaper.GetProjectStateChangeCount( 0 )
      if not last_check_cnt or last_check_cnt ~= check_cnt then 
        update_gfx = true 
        update_patterns = true
      end
      last_check_cnt = check_cnt

    -- upd gfx reduced
      if not defer_cnt then defer_cnt =0 end
      defer_cnt = defer_cnt + 1
      if defer_cnt == 10 then
        defer_cnt = 0
        --update_gfx = true
      end

    Patterns_Update()
    Layers_Update()
    Objects_Update()
    GUI_draw()
    MOUSE_get()
    
    if force_undo then 
      Undo_StoreNewPoint(force_undo)
      force_undo = false      
    end
    char = gfx.getchar()
    -- local filepath = gfx.get_dragged_filepath()
    if filepath and filepath ~= '' then
      msg('drag sample test'..filepath)
      Layers_add_sample_to_layer(filepath, data.current_layer)
    end    
    
    -- shortcuts
      if patterns.cur_pattern and blocks.cur_block then
        if char == 3 then Patterns_steps_copy(patterns.cur_pattern, blocks.cur_block) end
        if char == 22 then Patterns_steps_paste(patterns.cur_pattern, blocks.cur_block) end
      end
      if char == 26 then Undo_perform() end
    
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end -- space: play/pause
    if char == 27 then gfx.quit() end      -- escape
    if char ~= -1 then reaper.defer(Run) else gfx.quit() end    -- check is ReaScript GUI opened
   end
  end
  --------------------------------------------------------------------  
  function Undo_perform(ext_id)
    if Undo and #Undo > 1 then
      local undo_id
      if not ext_id then undo_id = #Undo-1 else undo_id  = ext_id end
      if Undo[undo_id].patterns then Patterns_Load(Undo[undo_id].patterns) end
      if Undo[undo_id].blocks then Layers_Load(Undo[undo_id].blocks) end
      for i = #Undo, undo_id + 1, -1 do Undo[i] = nil end
      update_gfx = true
      update_layers = true
      update_patterns = true
    end
    Undo_Save()
  end
  --------------------------------------------------------------------   
  function Undo_Load()
    local retval, str_ext = reaper.GetProjExtState( 0, name, 'undo' )
    if not retval then return end
    if debug_mode then msg('load ext '..os.date())  msg(str_ext) end
    
    -- split projextstate into lines
      local t = {} for line in str_ext:gmatch('[^\r\n]+') do t[#t+1] = line end
    -- extract undo chunks
      local  undo_chunks = {}
      local undo_id = 0
      local q = 0
      local activate = nil
      for i = 1, #t do
        if t[i]:find('<UNDO') then
          undo_id = undo_id + 1
          activate = true
        end 
        if activate then
          if t[i]:find('<') then q = q + 1 end
          if t[i]:find('>') then q = q - 1 end
          if not undo_chunks[undo_id] then undo_chunks[undo_id] = '' end
          undo_chunks[undo_id] = undo_chunks[undo_id]..'\n'..t[i]
          if q == 0 then activate = nil end
        end
      end
    
      Undo = {}
      
    -- loop chunks  
      for i = 1, #undo_chunks do
        local name = F_load_variable(undo_chunks[i], 'NAME', '' )   
        local patterns = F_load_variable(undo_chunks[i], 'PATTERNS', nil ) 
        local blocks = F_load_variable(undo_chunks[i], 'BLOCKS', nil ) 
        local timestamp = F_load_variable(undo_chunks[i], 'TIMESTAMP', nil )  
        Undo[#Undo+1] = {name = F_dec(name),
                         patterns = F_dec(patterns), 
                         blocks = F_dec(blocks),
                         timestamp = F_dec(timestamp)}
      end  
  end
  --------------------------------------------------------------------
  function Undo_Save()
    local str = ''    
    if #Undo >= data.max_undo then table.remove(Undo, 1) end
    for i = 1, #Undo do
      str = str..'<UNDO\n'
        for key in pairs(Undo[i]) do        
          if key then str = str ..'   '..key:upper()..' '..F_enc(Undo[i][key])..'\n' end        
        end
        str = str..'>\n'
    end
    if debug_mode then 
      msg(string.rep('_',30)..'\n') msg('save ext UNDO '..os.date()) msg(str) 
    end 
    reaper.SetProjExtState( 0, name, 'undo', str )
  end
  --------------------------------------------------------------------
  function GUI_init_gfx()
    local obj = Objects_Init()
    local mouse_x, mouse_y = reaper.GetMousePosition()
    local x_pos = reaper.GetExtState( name, 'x_pos' )
    local y_pos = reaper.GetExtState( name, 'y_pos' )
    local w = reaper.GetExtState( name, 'wind_w' )
    local h = reaper.GetExtState( name, 'wind_h' )
    if tonumber(w) then
      data.wind_w = tonumber(w)
      data.wind_h = tonumber(h)
    end
    gfx.quit()
    
    if x_pos and x_pos ~= '' then
      local txt_name = name..' '..vrs
              gfx.init('', data.wind_w, data.wind_h, 0, x_pos, y_pos)
     else     gfx.init('', data.wind_w, data.wind_h, 0)--mouse_x, mouse_y)
    end
    Objects_Init()
    
  end
  --------------------------------------------------------------------
  function Data_LoadConfig()
    local def_data = Data_defaults()
    -- get config path
      local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.ini'
    -- check default file
      local file = io.open(config_path, 'r')
      if not file then
        file = io.open(config_path, 'w')
        local def_content =
[[// Configuration data for ]]..name..[[

[Info]
[Global_variables]
]]
        file:write(def_content)
        file.close()
      end
      file:close()
    -- Load data section
      ext_name = 'Global_variables'
      for key in pairs(def_data) do
        if type(def_data[key]) == 'number' or type(def_data[key]) == 'string' then
          local _, stringOut = reaper.BR_Win32_GetPrivateProfileString( ext_name, key, def_data[key], config_path )
          if stringOut ~= ''  then
            if tonumber(stringOut) then stringOut = tonumber(stringOut) end
            data[key] = stringOut
            --data[key] = def_data[key] -- FOR RESET DEBUG
            reaper.BR_Win32_WritePrivateProfileString( ext_name, key, data[key], config_path )
           else
            reaper.BR_Win32_WritePrivateProfileString( ext_name, key, def_data[key], config_path )
          end
        end
      end
  end
  ------------------------------------------------------------------
  function Data_Update()
    local def_data = Data_defaults()
    local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.ini'
    local d_state, win_pos_x,win_pos_y = gfx.dock(-1,0,0)
    data.window_x, data.window_y, data.window_w, data.window_h, data.d_state = win_pos_x,win_pos_y, gfx.w, gfx.h, d_state
    for key in pairs(def_data) do
      if type(data[key])~= 'table'
        then
        reaper.BR_Win32_WritePrivateProfileString( 'Global_variables', key, data[key], config_path )
      end
    end
    reaper.BR_Win32_WritePrivateProfileString( 'Info', 'vrs', vrs, config_path )
  end
  --------------------------------------------------------------------
  function Layers_Load(undo_state) local retval, str_ext
    if not undo_state then
      retval, str_ext = reaper.GetProjExtState( 0, name, 'blocks' )
      if not retval then return end
     else
      str_ext = undo_state
    end
    if not str_ext then return end
    if debug_mode then msg('load ext '..os.date())  msg(str_ext) end
    blocks = {}

    -- get current block     
      
      blocks.cur_block = F_load_variable(str_ext, 'CURBLOCK', 0 )
     -- blocks.sel = F_load_variable(str_ext, 'SELECTED', 0 )
      
    -- split projextstate into lines
      local t = {} for line in str_ext:gmatch('[^\r\n]+') do t[#t+1] = line end
      
    -- extract block chunks
      local block_chunks = {}
      local block_id = 0
      local q = 0
      local activate = nil
      for i = 1, #t do
        if t[i]:find('<BLOCK') then
          block_id = block_id + 1
          activate = true
        end -- filt takes chunk
        if activate then
          if t[i]:find('<') then q = q + 1 end
          if t[i]:find('>') then q = q - 1 end
          if not block_chunks[block_id] then block_chunks[block_id] = '' end
          block_chunks[block_id] = block_chunks[block_id]..'\n'..t[i]
          if q == 0 then activate = nil end
        end
      end

    -- add blocks from chunks
      local id
      for i = 1, #block_chunks do
        local id = F_load_variable(block_chunks[i], 'ID', '' )          
          
        -- search samples/form src
          local samples = {}
          for line in block_chunks[i]:gmatch('[^\r\n]+') do
            if line:match('SAMPLE ') then
              local t0 = {}
              
              for cut in line:gmatch('[^%"]+') do t0[#t0+1] = cut end
              local new_src = reaper.PCM_Source_CreateFromFile( t0[2] )
              local src_len = reaper.GetMediaSourceLength( new_src )
              
              samples[#samples+1] = {filename = t0[2],
                                     tr_GUID = t0[4],
                                     --src = new_src,
                                     src_len = src_len,
                                     offset = tonumber(t0[6]),
                                     pitch = tonumber(t0[8])}
            end
          end

        blocks[id] = {
          MIDI=  F_load_variable(block_chunks[i], 'MIDI', 0 ),
          name =             F_load_variable(block_chunks[i], 'NAME', '' ),
          scroll=            F_load_variable(block_chunks[i], 'SCROLL', 0 ),
          samples =samples,
          mute=       F_load_variable(block_chunks[i], 'MUTE', 0 ),
          solo=       F_load_variable(block_chunks[i], 'SOLO', 0 ),
          vol =       F_load_variable(block_chunks[i], 'VOL', 1 ), 
          gl_offset=  F_load_variable(block_chunks[i], 'GL_OFFSET', 0 ),
          gl_attack=  F_load_variable(block_chunks[i], 'GL_ATT', data.default_attack_ms ),
          gl_decay =  F_load_variable(block_chunks[i], 'GL_DEC', 0.250 ),
          gl_sustain= F_load_variable(block_chunks[i], 'GL_SUS', 0 ),
          gl_release= F_load_variable(block_chunks[i], 'GL_REL', 0 ),
          fol_gr  =   F_load_variable(block_chunks[i], 'FOLGR', 0 ),
          gl_pitch=   F_load_variable(block_chunks[i], 'PITCH', 0 ),
          overlap =   F_load_variable(block_chunks[i], 'OVERLAP', 1 ),
          cutby =     F_load_variable(block_chunks[i], 'CUTBY', -1 )
          
                        }
      end
  end
  --------------------------------------------------------------------
  function F_load_variable(string_src, extstate_key,default_value)
    if not string_src then return end
    local ret = string_src:match(extstate_key..' .-[\n]')
    if not ret then 
      ret = default_value 
     else 
      ret = ret:sub(extstate_key:len()+2)
      if tonumber(ret) then 
        ret = tonumber(ret) 
       else 
        if ret:find('"') and ret:find('"') == 1 then ret = ret:sub(2,-3) end
      end      
    end
    return ret
  end
  --------------------------------------------------------------------
  function Patterns_Load(undo_state) local retval, str_ext
    if not undo_state then       
      retval, str_ext = reaper.GetProjExtState( 0, name, 'patterns' )
      if not retval then return end
     else
      str_ext = undo_state
    end
    
    if not str_ext then return end
    if debug_mode then msg('load ext '..os.date())  msg(str_ext) end

    patterns = {}

    patterns.tr_GUID = F_load_variable(str_ext, 'TR_GUID', '' )
    patterns.cur_pattern = F_load_variable(str_ext, 'CURPAT', 0 )

    -- split projextstate into lines
      local t = {} for line in str_ext:gmatch('[^\r\n]+') do t[#t+1] = line end

    ----------------------------------------------
    -- extract pat chunks
      local pat_chunks = {}
      local pat_id = 0
      local q = 0
      local activate = nil
      for i = 1, #t do
        if t[i]:find('<PAT') then
          pat_id = pat_id + 1
          activate = true
        end -- filt takes chunk
        if activate then
          if t[i]:find('<') then q = q + 1 end
          if t[i]:find('>') then q = q - 1 end
          if not pat_chunks[pat_id] then pat_chunks[pat_id] = '' end
          pat_chunks[pat_id] = pat_chunks[pat_id]..'\n'..t[i]
          if q == 0 then activate = nil end
        end
      end

    -- add pattern from chunks
      local id
      for i = 1, #pat_chunks do
        local id = F_load_variable(pat_chunks[i], 'ID', 1)
        
        -- search takes
          local takes = {}
          for line in pat_chunks[i]:gmatch('[^\r\n]+') do
            if line:match('TAKE {') then
              local t = {}
              for cut in line:gmatch('[^%s]+') do t[#t+1] = cut end
              takes[#takes+1] = {itemGUID = t[2]}--, poolGUID = t[3]}
            end
          end


        -- search row
          local rows = {}
          for line in pat_chunks[i]:gmatch('[^\r\n]+') do
            if line:match('ROW ') then
              local t0 = {}
              for cut in line:gmatch('[^%"]+') do t0[#t0+1] = cut end
              local steps = tonumber(t0[2])
              local values = t0[4]
              local t_val = {}
              if values then for num in values:gmatch('[^%s]+') do t_val[#t_val+1] = tonumber(num) end  end
              rows[#rows+1] = {steps = steps,values = t_val}
            end
          end

        patterns[id] = {name =        F_load_variable(pat_chunks[i], 'NAME', ''),
                        scroll =      F_load_variable(pat_chunks[i], 'SCROLL', 0),
                        takes = takes,
                        rows = rows,
                        length=       F_load_variable(pat_chunks[i], 'LENGTH', data.StSeq_default_pat_length),
                        groove =      F_load_variable(pat_chunks[i], 'GROOVE', ''),
                        groove_val =  F_load_variable(pat_chunks[i], 'GROOVEVAL', 0),
                        dumpitems =   F_load_variable(pat_chunks[i], 'DUMPITEMS', data.StSeq_default_dump_items)}
                        
        if not patterns[id].rows or #patterns[id].rows < #blocks then Patterns_FillEmptyFields(id) end
        
        
      end
  end
  -------------------------------------------------------------------- 
  function LC_check()
    local modstr = reaper.GetExtState( 'MPL_LC', 'lickey' )
    if modstr == '' then return end
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' local modstr = string.gsub(modstr, '[^'..b..'=]', '') modstr = (modstr:gsub('.', function(x)  if (x == '=') then return '' end local r,f='',(b:find(x)-1) for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end return r; end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x) if (#x ~= 8) then return '' end local c=0  for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end return string.char(c) end)) local outstr = '' for i = 1, modstr:len(), 4 do outstr = outstr..string.char(tonumber(modstr:sub(i,i+3))) end if modstr:find('46') and modstr:find('64')  then return true end return false
  end
   if LC_check() then run_l = 2 else run_l = 0 end
  --------------------------------------------------------------------
  function Layers_Save()
    local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_patterns.ini'     -- form string
    local str = '==Block configuration for MPL PatternRack==\n'
    if not blocks then return end

    -- export cur block
      if blocks.cur_block then str = str..'\nCURBLOCK '..blocks.cur_block..' \n' end
      --if blocks.sel then str = str..'\nSELECTED '..blocks.sel..' \n' end
      
    -- block data
      for i =1, #blocks do
        if blocks[i] then
          if not blocks[i].name then      blocks[i].name = '' end
          if not blocks[i].MIDI then      blocks[i].MIDI = 0 end
          if not blocks[i].scroll then    blocks[i].scroll = 0 end
          if not blocks[i].samples then   blocks[i].samples = {} end
          if not blocks[i].mute then      blocks[i].mute = 0 end
          if not blocks[i].solo then      blocks[i].solo = 0 end
          if not blocks[i].gl_offset then blocks[i].gl_offset = 0 end
          if not blocks[i].gl_attack then blocks[i].gl_attack = data.default_attack_ms end
          if not blocks[i].gl_decay then blocks[i].gl_decay = 0.250 end
          if not blocks[i].gl_sustain then blocks[i].gl_sustain = 0 end
          if not blocks[i].gl_release then blocks[i].gl_release = 0 end
          if not blocks[i].vol then blocks[i].vol = 1 end
          if not blocks[i].fol_gr then blocks[i].fol_gr = 1 end
          if not blocks[i].gl_pitch then blocks[i].gl_pitch = 0 end
          if not blocks[i].overlap then blocks[i].overlap = 1 end
          if not blocks[i].cutby then blocks[i].cutby = -1 end
          
          -- parameters
          str = str..'<BLOCK'
                    ..'\n   ID '..i
                    ..'\n   NAME "'..blocks[i].name..'"'
                    ..'\n   MIDI '..blocks[i].MIDI
                    ..'\n   SCROLL '..blocks[i].scroll
                    ..'\n   MUTE '..blocks[i].mute
                    ..'\n   SOLO '..blocks[i].solo
                    ..'\n   GL_OFFSET '..blocks[i].gl_offset
                    ..'\n   GL_ATT '..blocks[i].gl_attack
                    ..'\n   GL_DEC '..blocks[i].gl_decay
                    ..'\n   GL_SUS '..blocks[i].gl_sustain
                    ..'\n   GL_REL '..blocks[i].gl_release
                    ..'\n   VOL '..blocks[i].vol
                    ..'\n   FOLGR '..blocks[i].fol_gr
                    ..'\n   PITCH '..blocks[i].gl_pitch
                    ..'\n   OVERLAP '..blocks[i].overlap
                    ..'\n   CUTBY '..blocks[i].cutby
                    
          -- samples data
          for smpl_id = 1, # blocks[i].samples do
            if blocks[i].samples[smpl_id].filename and blocks[i].samples[smpl_id].tr_GUID then
            
            if not blocks[i].samples[smpl_id].offset then blocks[i].samples[smpl_id].offset = 0 end
            if not blocks[i].samples[smpl_id].pitch then blocks[i].samples[smpl_id].pitch = 0 end
            
              str = str..'\n   SAMPLE '
                ..'"'..blocks[i].samples[smpl_id].filename..'" '
                ..'"'..blocks[i].samples[smpl_id].tr_GUID..'" '
                ..'"'..blocks[i].samples[smpl_id].offset..'" '
                ..'"'..blocks[i].samples[smpl_id].pitch..'" '
            end
          end
          str = str..'\n>\n'
        end
      end

      --if debug_mode then 
      --msg(string.rep('_',30)..'\n') msg('save ext BLOCK '..os.date()) msg(str)  --end
      -- save
        reaper.SetProjExtState( 0, name, 'blocks', str )
      return str
  end
  --------------------------------------------------------------------
  function Patterns_Save()
      local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_patterns.ini'     -- form string

      --  export patterns
        local str = '==Pattern configuration for MPL PatternRack=='
        if not patterns then return end

      -- export globals
        if patterns.tr_GUID then str = str..'\nTR_GUID '..patterns.tr_GUID end
        if patterns.cur_pattern then str = str..'\nCURPAT '..patterns.cur_pattern..' ' end

      --  patterns data
        for i =1, #patterns do
          if patterns[i] then
          
            if not patterns[i].name then patterns[i].name = '' end
            if not patterns[i].length then patterns[i].length = 1 end
            if not patterns[i].scroll then patterns[i].scroll = 0 end
            if not patterns[i].dumpitems then patterns[i].dumpitems = 0 end
            
            -- parameters
              str = str..'\n<PAT'..
                    '\n   ID '..i..
                    '\n   LENGTH '..patterns[i].length..
                    '\n   NAME "'..patterns[i].name..'"'..
                    '\n   SCROLL '..patterns[i].scroll..
                    '\n   GROOVE "'..patterns[i].groove..'"'..
                    '\n   GROOVEVAL '..patterns[i].groove_val..
                    '\n   DUMPITEMS '..patterns[i].dumpitems

            -- linked items
              if patterns[i].takes then
                for takeid = 1, #patterns[i].takes do
                  if patterns[i].takes[takeid] then
                    local item =  reaper.BR_GetMediaItemByGUID( 0, patterns[i].takes[takeid].itemGUID)
                    if item --and patterns[i].takes[takeid].poolGUID 
                      then-- validate item
                      str = str..'\n   TAKE '
                          ..patterns[i].takes[takeid].itemGUID
                          --..' '..patterns[i].takes[takeid].poolGUID
                    end
                  end
                end
              end

            -- row
              if patterns[i].rows then
                for row = 1, #blocks do
                  if patterns[i].rows[row] then
                    if not patterns[i].rows[row].steps then patterns[i].rows[row].steps = data.StSeq_default_steps end
                    if not patterns[i].rows[row].name then patterns[i].rows[row].name = '' end
                    if not patterns[i].rows[row].values then patterns[i].rows[row].values = {} end
                    --fill nulls
                    if #patterns[i].rows[row].values < patterns[i].rows[row].steps * patterns[i].length then
                      for step = #patterns[i].rows[row].values + 1, patterns[i].rows[row].steps * patterns[i].length do
                        if not patterns[i].rows[row].values[step] then patterns[i].rows[row].values[step] = 0 end
                      end
                    end
                    str = str..'\n   ROW '
                          --..'"'..patterns[i].rows[row].MIDI..'" '
                          ..'"'..patterns[i].rows[row].steps..'" '
                          --..'"'..patterns[i].rows[row].name..'" '
                          ..'"'..table.concat(patterns[i].rows[row].values, ' ')..'"'

                  end
                end
              end

            str = str..'\n>'
          end
        end

      if debug_mode then msg(string.rep('_',60)..'\n') msg('save ext PATTERNS'..os.date()) msg(str)  end
    -- save
      reaper.SetProjExtState( 0, name, 'patterns', str )
      return str
  end
  
  --------------------------------------------------------------------    
  function Undo_StoreNewPoint(name, is_init)
    if is_init and Undo[1] and Undo[1].name == 'Init state' then 
      return 
    end
    local blocks_state = Layers_Save()    
    local pat_state = Patterns_Save()    
    Undo[#Undo+1]= {name = name,
                  patterns = pat_state,
                  blocks = blocks_state,
                  timestamp = os.date()}
    --if Undo[2] and Undo[2].name == 'Init state' then table.remove(Undo, 1) end -- prevent storing 2 init states
    --if not not_save then 
    Undo_Save()-- end
    update_gfx = true
  end
  --------------------------------------------------------------------
  function F_vrs_check()
    appvrs = reaper.GetAppVersion()
    appvrs = appvrs:match('[%d%p]+')
    if not appvrs then return end
    appvrs =  tonumber(appvrs)
    if not appvrs or appvrs < 5.40 then return end
    local APITest = { 'BR_GetMidiTakePoolGUID', 
                      'BR_GetMediaTrackByGUID',
                      'BR_GetMediaTrackByGUID',
                      'BR_Win32_GetPrivateProfileString',
                      'BR_GetMediaItemGUID',
                      'BR_GetMediaItemByGUID'
                      }
    for i =1, #APITest do if not reaper.APIExists( APITest[i] ) then return end end
    return true
  end
  --------------------------------------------------------------------
  ts = os.clock()
  if not F_vrs_check() then 
    reaper.MB('Install latest REAPER and SWS extension releases.\nScript supports REAPER 5.40 and later, SWS 2.7.2 and later ', name, 0)
    goto skip 
  end
  reaper.atexit()
  reaper.ClearConsole()  
  Data_init_scaling()
  Data_LoadConfig()
  Data_Update()  
  Layers_Load()
  Patterns_Load()
  Undo_Load()
  Undo_StoreNewPoint('Init state', true)
  GUI_init_gfx()
  update_gfx = true
  update_gfx_onstart = true
  update_patterns = true
  update_layers = true
  Run()
  ::skip::
    

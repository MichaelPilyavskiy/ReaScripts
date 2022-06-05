-- @description Spectral editing tools
-- @version 1.04
-- @author MPL
-- @about Various tools for spectral editing
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Action: port focused FX to spectral edits
--    + Manipulate SE: add scaling gain tweak
--    + Manipulate SE: add set gain tweak
--    # Add SE: properly handle time selection outside item

 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.04
    DATA.extstate.extstatesection = 'SETools'
    DATA.extstate.mb_title = 'Spectral editing tools'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  500,
                          wind_h =  500,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- mode
                          CONF_action = 2, -- 1 == init
                            -- 2 == add SE at specified frequency
                            -- 3 == Add user-defined spectral edits pattern
                            -- 4 == manipulate spectral edit parameters
                            -- 5 == various
                          
                          CONF_ASF_Fbase = 10000,
                          CONF_ASF_Farea = 1000,
                          CONF_ASF_Gaindb = -10,
                          CONF_ASF_pencilmode = 0,
                          CONF_ASF_pencil_len = 0.3,
                          
                          CONF_AUDP_pattern = 'F500A100P0L0.5G-20 F1000A100P0.5L0.5G-20 F1500A100P1L0.5G-20 F2000A100P1.5L0.5G-20',
                          
                          CONF_gain_scaling = 1,
                          CONF_Params_GAIN = 0,--dB
                          CONF_Params_GTO = -200, -- gate threshold
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          UI_processoninit = 0,
                          
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
    GUI_RESERVED_init(DATA)
    RUN()
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    --DATA.GUI.default_scale = 2
    
    -- init main stuff
      DATA.GUI.custom_mainbuth = 30*DATA.GUI.default_scale
      DATA.GUI.custom_texthdef = 23
      DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
      DATA.GUI.custom_mainsepx = gfx.w/DATA.GUI.default_scale--(gfx.w/DATA.GUI.default_scale)*0.4-- *DATA.GUI.default_scale--400*DATA.GUI.default_scale--
      DATA.GUI.custom_mainbutw = gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2 --(gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*3
      DATA.GUI.custom_scrollw = 10
      DATA.GUI.custom_frameascroll = 0.05
      DATA.GUI.custom_default_framea_normal = 0.1
      DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
      DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset*3) 
    
    -- shortcuts
      DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
    -- buttons
      local txt = ''
      DATA.GUI.custom_t_map = {
        [1] = '#Action',
        [2]='Add spectral edit',
        [3]='Add user-defined spectral edits pattern',
        [4]='Manipulate spectral edits',
        [5]='Advanced Actions',
        }
        
        
        
        
      for i = 1, #DATA.GUI.custom_t_map do if DATA.extstate.CONF_action == i then txt = DATA.GUI.custom_t_map[i]  end end
      DATA.GUI.buttons = {} 
      DATA.GUI.buttons.app = {  x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = txt,
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() 
                                              local mt = {} for i = 1, #DATA.GUI.custom_t_map do mt[#mt+1] = {str=DATA.GUI.custom_t_map[i], func = function() DATA.extstate.CONF_action = i DATA.UPD.onconfchange = true DATA.UPD.onGUIinit = true end} end
                                              DATA:GUImenu(mt)
                                            end} 
                                            
      --[[DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_short = (DATA.extstate.CONF_NAME or '[untitled]'),
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA:GUIbut_preset() end}     ]]  
                            
      local hide_exec = DATA.extstate.CONF_action==4 or DATA.extstate.CONF_action==5 or (DATA.extstate.CONF_action==2 and DATA.extstate.CONF_ASF_pencilmode ==1) or DATA.extstate.CONF_action==6
      local runtxt = 'Run'
      if DATA.extstate.CONF_action ==2 or DATA.extstate.CONF_action ==3 then runtxt = 'Run (or trig externally)' end
      DATA.GUI.buttons.exec = {  x=DATA.GUI.custom_offset,
                            y=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_offset*5,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = runtxt,
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide =hide_exec,
                            ignoremouse = hide_exec,
                            onmouseclick =  function() 
                                              DATA2:Process()
                                            end}                        
      DATA.GUI.buttons.Rsettings = { x=gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx,
                            y=DATA.GUI.custom_mainbuth + DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainsepx,
                            h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth*2 - DATA.GUI.custom_offset*2,
                            txt = '',
                            --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            frame_a = 0,
                            --offsetframe = DATA.GUI.custom_offset,
                            offsetframe_a = 0.1,
                            ignoremouse = true,
                            }
      DATA:GUIBuildSettings()
      
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_refresh(mode)
    local imode = mode or 0
    DATA.custom = {valid = false, items = {}}
    DATA.custom.loopS, DATA.custom.loopE = GetSet_LoopTimeRange2( 0, false, 0, -1, -1, false )
    
    if imode ~= 1 then 
      for i = 1, CountSelectedMediaItems(0) do 
        local item = GetSelectedMediaItem(0,i-1)
        DATA2:Process_refresh_sub(item) 
      end
      DATA.custom.valid = true
      return
    end
    
    if imode == 1 then -- item from mouse cursor
      local screen_x, screen_y = reaper.GetMousePosition()
      local item, take = reaper.GetItemFromPoint( screen_x, screen_y, false )
      if reaper.ValidatePtr2( 0, item, 'MediaItem*' ) then DATA2:Process_refresh_sub(item, take) DATA.custom.valid = true end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_refresh_sub(item, take)
    local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    
    local ret, SEdata = DATA2:Process_GetSpectralData(item)
    local id = #DATA.custom.items+1
    DATA.custom.items[id] = SEdata
    if not DATA.custom.items[id] then DATA.custom.items[id] = {} end
    DATA.custom.items[id].item_ptr = item
    DATA.custom.items[id].item_pos = item_pos
    DATA.custom.items[id].item_len = item_len
    if take then 
      local tk = take --or GetActiveTake( item )
      local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
      DATA.custom.items[id].active_take = tk_id+1
    end
    
  end
  -------------------------------------------------------
  function DATA2:Process_AddUserDefPattern(mode)
    -- parse pattern
      local pat = DATA.extstate.CONF_AUDP_pattern
      local val_block_t = {}
      local letters = {'F','A','P','L','G'} -- 'F','A','P','L','G' must have, others can be added further like fades
      for val_block in pat:gmatch('[^%s]+') do
        local t = {}
        for i = 1, #letters do t[letters[i]] = val_block:match(letters[i]..'([%d%p]+)') if t[letters[i]] then t[letters[i]] = tonumber(t[letters[i]]) end end
        if t.F and t.A and t.P and t.L and t.G then val_block_t[#val_block_t+1 ] = CopyTable(t) end
      end
      if #val_block_t <2 then return end
      
    -- add blocks 
      local cur_pos = GetCursorPosition()
      if mode == 1 then
        local x,y = reaper.GetMousePosition()
        cur_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1) -- get 
      end
      
    
    for i = 1, #DATA.custom.items do 
      local it_table = DATA.custom.items[i] 
      local tk_id = it_table.active_take -- ONLY ACTIVE TAKE 
      local SR = it_table.takes[tk_id].SR
      local item_pos = it_table.item_pos
      local item_len = it_table.item_len
      local loopS = DATA.custom.loopS
      local loopE = DATA.custom.loopE
      
      local F_base = DATA.extstate.CONF_ASF_Fbase
      local F_Area = DATA.extstate.CONF_ASF_Farea
      local gain_dB = DATA.extstate.CONF_ASF_Gaindb
                                 
      if not it_table.takes[tk_id] then return end
      if not it_table.takes[tk_id].SE then it_table.takes[tk_id].SE = {} end
       
      for block =1, #val_block_t do
        local offset = it_table.takes[tk_id].s_offs
        local playrate = it_table.takes[tk_id].rate
        local mark_pos = (cur_pos - item_pos + offset)*playrate
        
        local freq_L = math.max(0, val_block_t[block].F-val_block_t[block].A)
        local freq_H = math.min(SR, val_block_t[block].F+val_block_t[block].A)
        local pos = mark_pos + val_block_t[block].P
        local len = val_block_t[block].L
        local gain = 10^(val_block_t[block].G/20)
        
        it_table.takes[tk_id].SE [ #it_table.takes[tk_id].SE + 1] = -- ADD FOR ACTIVE TAKE
          {pos = pos,
           len = len,
           gain = gain,
           fadeinout_horiz = 0,
           fadeinout_vert = 0,
           freq_low = freq_L,
           freq_high = freq_H,
           chan = -1, -- -1 all 0 L 1 R
           bypass = 0, -- bypass&1 solo&2
           gate_threshold = 0,
           gate_floor = 0,
           compress_threshold = 1,
           compress_ratio = 1,
           unknown1 = 1,
           unknown2 = 1,
           fadeinout_horiz2 = 0, 
           fadeinout_vert2 = 0}
      end
    end
  end
  -------------------------------------------------------
  function DATA2:Process_Actions_PortReaEQ()
    
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX2()
    if not (retval &1==1 and fx >= 0) then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    local num_params = TrackFX_GetNumParams( tr, fx )
    local bands = {}
    for param = 1, num_params - 2, 3 do
      local retval, b_enabled = TrackFX_GetNamedConfigParm( tr, fx, 'BANDENABLED'..(-1+(param+2)/3) )
      b_enabled = tonumber(b_enabled)
      if b_enabled == 1 then
        local retval, db_gain  = TrackFX_GetFormattedParamValue( tr, fx, param, '' )
        db_gain = tonumber(db_gain) if not db_gain then db_gain = -150 end 
        local retval, freq = TrackFX_GetFormattedParamValue( tr, fx, param-1,'')
        freq = math.floor(tonumber(freq) ) 
        local retval, N = TrackFX_GetFormattedParamValue( tr, fx, param+1,'') 
        N = tonumber(N) 
        local retval_type, b_type = TrackFX_GetNamedConfigParm( tr, fx, 'BANDTYPE'..(-1+(param+2)/3) )  
        b_type = tonumber(b_type)
        
        if b_type == 0 or b_type == 4 then DATA2:Process_AddSpectralEditIntoTable({FL=freq,G=db_gain }) end-- low shelf / hi pass
        if b_type == 1 or b_type == 3 then DATA2:Process_AddSpectralEditIntoTable({G=db_gain,FH=freq}) end -- high shelf / low pass
        if b_type == 8 or b_type == 6 then -- band / notch
          if db_gain < -60 then N = 0.5 end
          local Q = math.sqrt(2^N) / (2^N - 1 ) 
          local BW = freq/Q
          DATA2:Process_AddSpectralEditIntoTable({FL = freq - BW/2 , FH = freq + BW/2, G =db_gain, FIV = N/4, FOV = N/4 })
        end 
        if b_type == 7 or b_type == 10 then -- band pass / parallel band pass
          if db_gain < -60 then N = 0.5 end
          local Q = math.sqrt(2^N) / (2^N - 1 ) 
          local BW = freq/Q
          DATA2:Process_AddSpectralEditIntoTable({FH = freq - BW/2, G =db_gain, FIV = 0, FOV = N/4 })
          DATA2:Process_AddSpectralEditIntoTable({FL = freq + BW/2, G =db_gain, FIV = N/4, FOV = 0 })
        end         
      end
    end
    
  end
  -------------------------------------------------------
  function DATA2:Process_AddSpectralEditIntoTable(t)
    if not t then t = {} end
    local pencilmode =   APIExists( 'JS_Window_GetClientRect'  ) and APIExists( 'JS_Window_FindChildByID'  ) and  DATA.extstate.CONF_ASF_pencilmode == 1 and (DATA.extstate.CONF_action == 2 or DATA.extstate.CONF_action == 3) -- only for add se / add pattern
    local x,y, cur_pos 
    if pencilmode then
      x,y = reaper.GetMousePosition()
      cur_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1)  
    end
    
    for i = 1, #DATA.custom.items do 
      local it_table = DATA.custom.items[i]
      local active_tk = it_table.active_take
      if not it_table.takes[active_tk] then return end
      if not it_table.takes[active_tk].SE then it_table.takes[active_tk].SE = {} end 
      
      -- pos / len 
        -- handle time selection
          local item_pos = it_table.item_pos 
          local item_len = it_table.item_len 
          local loopS = DATA.custom.loopS
          local loopE = DATA.custom.loopE
          local pos, len = 0, item_len
          if loopE - loopS > 0.001 and 
            ( -- do time selection cross item
              (item_pos > loopS and item_pos < loopE)
              or (item_pos+item_len > loopS and item_pos+item_len < loopE)
              or (item_pos< loopS and item_pos+item_len > loopE)
            )
            then 
            if loopS >= item_pos and loopS <= item_pos + item_len then pos = loopS- item_pos end
            if loopE >= item_pos and loopE <= item_pos + item_len then  len = loopE - loopS  else len = item_pos + item_len - loopS end
          end 
          if len < 0 then len = item_len end
        -- handle pencil mode
          if pencilmode then
            local offset = it_table.takes[active_tk].s_offs
            local playrate = it_table.takes[active_tk].rate
            pos = (cur_pos - item_pos + offset)*playrate
            len = DATA.extstate.CONF_ASF_pencil_len  
          end
      
      -- gain
        local gain_dB = DATA.extstate.CONF_ASF_Gaindb
      
      -- frequency
        local SR = it_table.takes[active_tk].SR
        local F_base = DATA.extstate.CONF_ASF_Fbase
        -- handle pencil mode
          if pencilmode then
            local numCH = it_table.takes[active_tk].numCH
            local tky = it_table.takes[active_tk].I_LASTY
            local tkh = it_table.takes[active_tk].I_LASTH
            local ypos = 1/numCH - ((y-tky) / tkh) % (1/numCH)
            F_base = SR*ypos
          end
      
      local F_base = t.F or F_base
      local F_Area = t.A or DATA.extstate.CONF_ASF_Farea  
      local gain_dB = t.G or gain_dB
      local freq_L = math.max(0, F_base-F_Area)
      local freq_H = math.min(SR, F_base+F_Area)
      if t.FL or t.FH then 
        if t.FL then freq_L = t.FL else freq_L = 0 end
        if t.FH then freq_H = t.FH else freq_H = SR/2 end
      end
      local fadein_vert = t.FIV or 0
      local fadeout_vert = t.FOV or 0
      
      it_table.takes[active_tk].SE [ #it_table.takes[active_tk].SE + 1] = 
        {pos = pos,
         len = len,
         gain = 10^(gain_dB/20),
         fadeinout_horiz = 0,
         fadeinout_vert = fadein_vert,
         freq_low = freq_L,
         freq_high = freq_H,
         chan = -1, -- -1 all 0 L 1 R
         bypass = 0, -- bypass&1 solo&2
         gate_threshold = 0,
         gate_floor = 0,
         compress_threshold = 1,
         compress_ratio = 1,
         unknown1 = 1,
         unknown2 = 1,
         fadeinout_horiz2 = 0, 
         fadeinout_vert2 = fadeout_vert}
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_CopyPaste_Copy()
    if not DATA.custom.items[1] then return end
    if not DATA.custom.items[1].active_take then return end
    local act_take = DATA.custom.items[1].active_take
    if not DATA.custom.items[1].takes then return end
    local se_table = DATA.custom.items[1].takes[act_take]
    DATA.buffer = {t = CopyTable(se_table), valid = true} 
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_CopyPaste_Paste(mode)
    if not DATA.buffer then return end 
    if not (DATA.buffer.valid and DATA.buffer.t and DATA.buffer.t.SE) then return end 
    
    for it_id = 1, #DATA.custom.items do
      if not DATA.custom.items[it_id] then return end
      
      if mode == 3 then -- active take only
        if not DATA.custom.items[it_id].active_take then return end
        local act_take = DATA.custom.items[it_id].active_take
        if not (DATA.custom.items[it_id].takes and DATA.custom.items[it_id].takes[act_take]) then return end  
        local se_table = DATA.custom.items[it_id].takes[act_take]
        for se_id = 1, #DATA.buffer.t.SE do table.insert(se_table.SE, DATA.buffer.t.SE[se_id]) end
      end
      
      if mode == 4 then -- all takes
        for take_id = 1, #DATA.custom.items[it_id].takes do
          if not (DATA.custom.items[it_id].takes and DATA.custom.items[it_id].takes[take_id]) then return end 
          local se_table = DATA.custom.items[it_id].takes[take_id]
          for se_id = 1, #DATA.buffer.t.SE do table.insert(se_table.SE, DATA.buffer.t.SE[se_id]) end
        end
      end
      
    end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_CopyPaste_Clear(mode)
    for it_id = 1, #DATA.custom.items do
      if not DATA.custom.items[it_id] then return end 
      if mode == 5 then -- active take only
        if not DATA.custom.items[it_id].active_take then return end
        local act_take = DATA.custom.items[it_id].active_take
        DATA.custom.items[it_id].takes[act_take].SE = nil
      end
      
      if mode == 6 then -- all takes
        for take_id = 1, #DATA.custom.items[it_id].takes do 
          DATA.custom.items[it_id].takes[take_id].SE = nil
        end
      end
      
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:Process_Bypass(mode) 
    --[[for bypass
      =2 toggle
      =3 enable
      =4 disaable
      ]]
    for it_id = 1, #DATA.custom.items do
      if DATA.custom.items[it_id] and DATA.custom.items[it_id].takes then
        
        for tk_id = 1, #DATA.custom.items[it_id].takes do
          if DATA.custom.items[it_id].takes[tk_id].SE then 
            for se_id = 1, #DATA.custom.items[it_id].takes[tk_id].SE do 
              local byp = DATA.custom.items[it_id].takes[tk_id].SE[se_id].bypass
              if mode  == 2 then 
                byp = byp~1 
               elseif mode  == 3 then -- set 1
                byp = 1
               elseif mode  == 4 then -- set 1
                byp = 0
              end
              DATA.custom.items[it_id].takes[tk_id].SE[se_id].bypass = byp
            end
          end
        end
        
      end
    end
  end  
  ---------------------------------------------------------------------  
  function DATA2:Process_EditParams(mode)
    for it_id = 1, #DATA.custom.items do
      if DATA.custom.items[it_id] and DATA.custom.items[it_id].takes then
        
        for tk_id = 1, #DATA.custom.items[it_id].takes do
          if DATA.custom.items[it_id].takes[tk_id].SE then 
            for se_id = 1, #DATA.custom.items[it_id].takes[tk_id].SE do 
              if mode == 30 then DATA.custom.items[it_id].takes[tk_id].SE[se_id].gain = DATA.custom.items[it_id].takes[tk_id].SE[se_id].gain * DATA.extstate.CONF_gain_scaling end
              if mode == 31 then DATA.custom.items[it_id].takes[tk_id].SE[se_id].gain = WDL_DB2VAL(DATA.extstate.CONF_Params_GAIN) end
              if mode == 32 then DATA.custom.items[it_id].takes[tk_id].SE[se_id].gate_threshold = WDL_DB2VAL(DATA.extstate.CONF_Params_GTO) end
              
            end
          end
        end
        
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:Process(mode) 
    --[[ =1 triggered externally, 
        for copypaste: 
          =2 copy, 
          =3 paste, 
          =4 paste to all takes
          =5 clean, 
          =6 clean to all takes
          =20 toggle =21 enable =22 disaable
    ]]
    
    DATA2:Process_refresh(mode) -- =1 triggered externally, 
    if not DATA.custom.valid then return end
    local process = false
    
    if DATA.extstate.CONF_action == 2 then DATA2:Process_AddSpectralEditIntoTable() process = true end
    if DATA.extstate.CONF_action == 3 then DATA2:Process_AddUserDefPattern(mode) process = true  end 
    if DATA.extstate.CONF_action == 4 then 
      if mode ==2 then DATA2:Process_CopyPaste_Copy() end 
      if mode ==3 or mode ==4  then DATA2:Process_CopyPaste_Paste(mode) process = true end --3 paste, =4 paste to all takes
      if mode ==5 or mode ==6 then DATA2:Process_CopyPaste_Clear(mode) process = true end  -- =5 clean, =6 clean to all takes
      if mode ==20 or mode ==21 or mode ==22 then DATA2:Process_Bypass(mode) process = true end --=20 toggle =21 enable =22 disaable
      if mode >30 then DATA2:Process_EditParams(mode) process = true end -- 30 scale gain 31 set gain
    end
    if DATA.extstate.CONF_action == 5 then if mode ==2 then DATA2:Process_Actions_PortReaEQ() process = true end end 
    
    
    if process == true then
      Undo_BeginBlock() 
      DATA2:Process_SetSpectralData()  
      Undo_EndBlock( DATA.GUI.custom_t_map[DATA.extstate.CONF_action], 0xFFFFFFFF )
    end
  end      
    
    
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = DATA.GUI.custom_mainsepx*0.7*DATA.GUI.default_scale
    local SR_spls = 22050--tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    
    
    local hasJSAPI =   APIExists( 'JS_Window_GetClientRect'  ) and APIExists( 'JS_Window_FindChildByID'  ) 
                          
    local  t = 
    {    
          -----------------------------------------  
          
          
        {str = 'Pencil mode (require js_ReascriptAPI)' ,                      group = 1, itype = 'check', confkey = 'CONF_ASF_pencilmode', 
          hide=DATA.extstate.CONF_action~=2,
          func_onrelease = function()DATA.UPD.onGUIinit=true  end,
          },   
        {str = 'Frequency center' ,                 group = 1, itype = 'readout', confkey = 'CONF_ASF_Fbase',
          val_res = 0.05, 
          val_min = 0, 
          val_max = SR_spls, 
          val_format = function(x) if x then  return math.floor(x)..'Hz' end end,
          hide=DATA.extstate.CONF_action~=2 or (DATA.extstate.CONF_action==2 and DATA.extstate.CONF_ASF_pencilmode ==1)
          
          },
        {str = 'Frequency area' ,                   group = 1, itype = 'readout', confkey = 'CONF_ASF_Farea', 
          val_res = 0.05, 
          val_min = 10, 
          val_max = 22050, 
          val_format = function(x) if x then  return math.floor(x)..'Hz' end end,
          hide=DATA.extstate.CONF_action~=2
          },
        {str = 'Gain' ,                             group = 1, itype = 'readout', confkey = 'CONF_ASF_Gaindb',
          val_res = 0.05, 
          val_min = -80, 
          val_max = 50, 
          val_format = function(x) if x then  return math.floor(x)..'dB' end end,
          hide=DATA.extstate.CONF_action~=2
          },
        {str = 'Length' ,                           group = 1, itype = 'readout', confkey = 'CONF_ASF_pencil_len',
          val_min = 0.02, 
          val_max = 2, 
          val_res = 0.05, 
          val_format = function(x) return (math.floor(x*1000)/1000)..'s' end, 
          val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, 
          hide=DATA.extstate.CONF_action~=2 or (DATA.extstate.CONF_action==2 and DATA.extstate.CONF_ASF_pencilmode ~=1)
          },          
          
          -----------------------------------------        
        {str = 'Pattern' ,                          group = 1, itype = 'readout', confkey = 'CONF_AUDP_pattern',readoutw_extw=readoutw_extw,func_onrelease = function()DATA.UPD.onconfchange=true  end,
          val_isstring = true,
          val_input_extrawidth = 400,
          val = 0,
          hide=DATA.extstate.CONF_action~=3
          },
          -----------------------------------------
        {str = 'Copy selected item active take SE' ,                            group = 1, itype = 'button',  func = function() DATA2:Process(2) end, hide=DATA.extstate.CONF_action~=4 },      
        {str = 'Paste SE to selected items active take' ,                       group = 1, itype = 'button',  func = function() DATA2:Process(3) end, hide=DATA.extstate.CONF_action~=4 },   
        {str = 'Paste SE to selected items all takes' ,                         group = 1, itype = 'button',  func = function() DATA2:Process(4) end, hide=DATA.extstate.CONF_action~=4 },            
        {str = '' ,                                                             group = 1, itype = 'sep',  hide=DATA.extstate.CONF_action~=4, },           
        {str = 'Clear SE from selected items active take' ,                     group = 1, itype = 'button',  func = function() DATA2:Process(5) end, hide=DATA.extstate.CONF_action~=4 },  
        {str = 'Clear SE from selected items all takes' ,                       group = 1, itype = 'button',  func = function() DATA2:Process(6) end, hide=DATA.extstate.CONF_action~=4 },     
        {str = '' ,                                                             group = 1, itype = 'sep',  hide=DATA.extstate.CONF_action~=4, },            
        {str = 'Toggle bypass for selected items all takes SE' ,                group = 1, itype = 'button',  func = function() DATA2:Process(20) end, hide=DATA.extstate.CONF_action~=4 },   
        {str = 'Enable bypass for selected items all takes SE' ,                group = 1, itype = 'button',  func = function() DATA2:Process(21) end, hide=DATA.extstate.CONF_action~=4 },    
        {str = 'Disable bypass for selected items all takes SE' ,               group = 1, itype = 'button',  func = function() DATA2:Process(22) end, hide=DATA.extstate.CONF_action~=4 }, 
        {str = '' ,                                                             group = 1, itype = 'sep',  hide=DATA.extstate.CONF_action~=4, },            
        {str = 'Scale (tweak only)' ,                                                group = 1, itype = 'readout', confkey = 'CONF_gain_scaling',  val_min = 0.01,  val_max = 4, 
          val_format = function(x) return (math.floor(x*1000)/1000)..'x' end,  val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end,  val_res = 0.05,  func_onrelease = function() DATA2:Process(30) DATA.extstate.CONF_gain_scaling = 1 DATA.UPD.onconfchange = true DATA.UPD.onGUIinit = true end,  func_onmouseclick = function() DATA2:Process_refresh() end, hide=DATA.extstate.CONF_action~=4},
        {str = 'Gain' ,                                                group = 1, itype = 'readout', confkey = 'CONF_Params_GAIN',  val_min = -80,  val_max = 12, 
          val_format = function(x) return (math.floor(x*1000)/1000)..'dB' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end,  val_res = 0.05,  func_onrelease = function() DATA2:Process(31)end, func_onmouseclick = function() DATA2:Process_refresh() end, hide=DATA.extstate.CONF_action~=4},          
        {str = 'Gate threshold' ,                                                group = 1, itype = 'readout', confkey = 'CONF_Params_GTO',  val_min = -200,  val_max = 0, 
          val_format = function(x) return (math.floor(x*1000)/1000)..'dB' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end,  val_res = 0.05,  func_onrelease = function() DATA2:Process(32)end, func_onmouseclick = function() DATA2:Process_refresh() end, hide=DATA.extstate.CONF_action~=4},          
          
          -----------------------------------------          
        {str = 'Port focused ReaEQ bands to SE on selected items' ,                group = 1, itype = 'button',  func = function() DATA2:Process(2) end, hide=DATA.extstate.CONF_action~=5 },           
          
    } 
    return t
    
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Process_GetSpectralData(item)
    if not item then return end
    local chunksrc = ({GetItemStateChunk( item, '', false )})[2]
    local chunk = 'TAKE\n'..chunksrc:match('NAME.*'):gsub('TAKE[%s-]','ENDTAKE\nTAKE '):sub(0,-3)..'ENDTAKE'
    local pat = '([%d%.]+%s[%d%.]+)' -- pattern for free draw
    local pat2 = '([%d%.]+)%s([%d%.]+)' -- pattern for free draw extract
    local data  = {itemchunk = chunksrc:match('(.-)NAME'), takes = {}}
    
    local tr =  reaper.GetMediaItemTrack( item )
    local tr_y = GetMediaTrackInfo_Value( tr, 'I_TCPY' )
    if  APIExists( 'JS_Window_GetClientRect'  ) and APIExists( 'JS_Window_FindChildByID'  ) then 
      local _, left, top, right, bottom = reaper.JS_Window_GetClientRect( reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000) )
      tr_y = tr_y + top
    end
    
    for takeblock in chunk:gmatch('TAKE(.-)ENDTAKE') do 
      local tkid = #data.takes+1
      data.takes[tkid] = {}
      if takeblock:match('%sSEL%s') then data.takes[tkid].selected = true end
      takeblock = takeblock:gsub('%sSEL%s','') 
      data.takes[tkid].chunk=takeblock 
      local FFT_sz = takeblock:match('SPECTRAL_CONFIG ([%d]+)')
      if FFT_sz then data.takes[tkid].FFT_sz = tonumber(FFT_sz) end
      
      local take = GetMediaItemTake( item, tkid-1 )
      local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS'  )
      local rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE'  ) 
      local I_LASTY = GetMediaItemTakeInfo_Value( take, 'I_LASTY'  ) 
      local I_LASTH = GetMediaItemTakeInfo_Value( take, 'I_LASTH'  ) 
      local src =  reaper.GetMediaItemTake_Source( take )
      local SR = GetMediaSourceSampleRate( src )
      local numCH = GetMediaSourceNumChannels( src )
      
      data.takes[tkid].rate = rate
      data.takes[tkid].SR = SR
      data.takes[tkid].s_offs = s_offs
      data.takes[tkid].I_LASTY = tr_y-I_LASTY
      data.takes[tkid].I_LASTH = I_LASTH
      data.takes[tkid].numCH = numCH
      
      data.takes[tkid].SE = {}
      local SEid = 0
      for line in takeblock:gmatch('[^\r\n]+') do
        if not line:match('SPECTRAL_EDIT') then  goto nextline end
        if line:match('SPECTRAL_EDIT%s') then 
          SEid = SEid + 1 
          local tnum = {} for num in line:gmatch('[^%s]+') do if tonumber(num) then tnum[#tnum+1] = tonumber(num) end end
          data.takes[tkid].SE[SEid] =       
                                {pos = (tnum[1] - s_offs)/rate,
                                 len = tnum[2]/rate,
                                 gain = tnum[3],
                                 fadeinout_horiz = tnum[4], -- knobleft/2 + knobright/2
                                 fadeinout_vert = tnum[5], -- knoblower/2 + knobupper/2
                                 freq_low = tnum[6],
                                 freq_high = tnum[7],
                                 chan = tnum[8], -- -1 all 0 L 1 R
                                 bypass = tnum[9], -- bypass&1 solo&2
                                 gate_threshold = tnum[10],
                                 gate_floor = tnum[11],
                                 compress_threshold = tnum[12],
                                 compress_ratio = tnum[13],
                                 unknown1 = tnum[14],
                                 unknown2 = tnum[15],
                                 fadeinout_horiz2 = tnum[16],  -- knobright - knobleft
                                 fadeinout_vert2 = tnum[17],
                                 freedrawT = {},
                                 freedrawB = {}} -- knobupper - knoblower      
        end
        if line:match('SPECTRAL_EDIT_T') and SEid > 0 then local tpairs = {}  for pair in line:gmatch(pat) do  local v1,v2 = pair:match(pat2) table.insert(data.takes[tkid].SE[SEid].freedrawT, {ptpos = tonumber(v1), ptval = tonumber(v2)})  end end
        if line:match('SPECTRAL_EDIT_B') and SEid > 0 then local tpairs = {}  for pair in line:gmatch(pat) do  local v1,v2 = pair:match(pat2) table.insert(data.takes[tkid].SE[SEid].freedrawB, {ptpos = tonumber(v1), ptval = tonumber(v2)}) end end
        ::nextline::
      end 
    end
    
    -- handle active take
      local found_active = false
      for tkid = 1, #data.takes do
        if data.takes[tkid].selected == true then data.active_take = tkid found_active = true break end
      end
      if not found_active then data.active_take = 1 data.takes[1].selected = true end
    
    return true, data
  end
  ------------------------------------------------------------------------------------------------------
  function DATA2:Process_SetSpectralData()
    for i = 1, #DATA.custom.items do 
      local item_t = DATA.custom.items[i]
      local item = item_t.item_ptr
      if not item then return end
      local out_chunk = item_t.itemchunk
      for tkid = 1, #item_t.takes do
        -- add basic take data
        local tkchunksrc = item_t.takes[tkid].chunk:gsub('SPECTRAL_.-[\r\n]','')
        local issel = '' if tkid > 1 and item_t.takes[tkid].selected then  issel = ' SEL' end
        local head = 'TAKE'..issel..'\n'
        if tkid == 1 then head = '' end
        out_chunk = out_chunk..'\n\n'..head..tkchunksrc
        
        if not item_t.takes[tkid].SE then goto skip_SE end
        
        -- add spectral edits
        out_chunk = out_chunk..'SPECTRAL_CONFIG '..(item_t.takes[tkid].FFT_sz or 1024)..'\n' 
        for SEid = 1, #item_t.takes[tkid].SE do
          out_chunk = out_chunk..'SPECTRAL_EDIT '
                  ..item_t.takes[tkid].SE[SEid].pos*item_t.takes[tkid].rate + item_t.takes[tkid].s_offs..' '
                  ..item_t.takes[tkid].SE[SEid].len*item_t.takes[tkid].rate..' '
                  ..item_t.takes[tkid].SE[SEid].gain..' '
                  ..item_t.takes[tkid].SE[SEid].fadeinout_horiz..' '
                  ..item_t.takes[tkid].SE[SEid].fadeinout_vert..' '
                  ..item_t.takes[tkid].SE[SEid].freq_low..' '
                  ..item_t.takes[tkid].SE[SEid].freq_high..' '
                  ..item_t.takes[tkid].SE[SEid].chan..' '
                  ..item_t.takes[tkid].SE[SEid].bypass..' '
                  ..item_t.takes[tkid].SE[SEid].gate_threshold..' '
                  ..item_t.takes[tkid].SE[SEid].gate_floor..' '
                  ..item_t.takes[tkid].SE[SEid].compress_threshold..' '
                  ..item_t.takes[tkid].SE[SEid].compress_ratio..' '
                  ..item_t.takes[tkid].SE[SEid].unknown1..' '
                  ..item_t.takes[tkid].SE[SEid].unknown2..' '
                  ..item_t.takes[tkid].SE[SEid].fadeinout_horiz2..' '
                  ..item_t.takes[tkid].SE[SEid].fadeinout_vert2..' '
                  ..'\n'
                  
                  
          local dropnextline = 8        
          if item_t.takes[tkid].SE[SEid].freedrawT and #item_t.takes[tkid].SE[SEid].freedrawT > 2 then 
            local freedrawTstr = 'SPECTRAL_EDIT_T '
            for freedrawT_ID = 2, #item_t.takes[tkid].SE[SEid].freedrawT, 2 do
              if freedrawT_ID%dropnextline==0 then
                freedrawTstr = freedrawTstr:sub(0,-3)
                freedrawTstr = freedrawTstr..'\nSPECTRAL_EDIT_T '
              end
              freedrawTstr = freedrawTstr
                ..item_t.takes[tkid].SE[SEid].freedrawT[freedrawT_ID-1].ptpos..' '..item_t.takes[tkid].SE[SEid].freedrawT[freedrawT_ID-1].ptval..' + '
                ..item_t.takes[tkid].SE[SEid].freedrawT[freedrawT_ID].ptpos..' '..item_t.takes[tkid].SE[SEid].freedrawT[freedrawT_ID].ptval..' + '
            end
            freedrawTstr = freedrawTstr:sub(0,-3)
            out_chunk = out_chunk..freedrawTstr..'\n'
          end
    
          if item_t.takes[tkid].SE[SEid].freedrawB and #item_t.takes[tkid].SE[SEid].freedrawB > 2 then 
            local freedrawBstr = 'SPECTRAL_EDIT_B '
            for freedrawB_ID = 2, #item_t.takes[tkid].SE[SEid].freedrawB, 2 do
              if freedrawB_ID%dropnextline==0 then
                freedrawBstr = freedrawBstr:sub(0,-3)
                freedrawBstr = freedrawBstr..'\nSPECTRAL_EDIT_B '
              end
              freedrawBstr = freedrawBstr
                ..item_t.takes[tkid].SE[SEid].freedrawB[freedrawB_ID-1].ptpos..' '..item_t.takes[tkid].SE[SEid].freedrawB[freedrawB_ID-1].ptval..' + '
                ..item_t.takes[tkid].SE[SEid].freedrawB[freedrawB_ID].ptpos..' '..item_t.takes[tkid].SE[SEid].freedrawB[freedrawB_ID].ptval..' + '
            end
            freedrawBstr = freedrawBstr:sub(0,-3)
            out_chunk = out_chunk..freedrawBstr..'\n'
          end
        end
        ::skip_SE::
      end
      out_chunk = out_chunk..'\n>'
      
      
    
      --ClearConsole()
      --msg(out_chunk)
      SetItemStateChunk( item, out_chunk, false )
      UpdateItemInProject( item )
    end
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE(DATA)
    if gmem_read(1) == 1 then
      gmem_write(1,0)
      DATA2:Process(1)
    end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.14) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then reaper.gmem_attach('MPL_SPEDIT_TOOLS' ) gmem_write(1,0 ) main() end end
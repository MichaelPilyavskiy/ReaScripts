-- @description Spectral search
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Script allows to search audio data spectrum match based on given piece of other audio data
-- @changelog
--    + initial release
--    + Get source: take spectral print of selected track - item - take as matching source
--    + Get destination: take spectral print of selected track - item - take as matching destination
--    + Preset/Action: Share points to destination track as razor edits
--    + Preset: allow to clear razor edits before sharing
--    + Preset: Spectrum settings
--    + Preset/Spectrum settings: FFT size
--    + Preset/Spectrum settings: window, independent from FFT size, can overlap or be inside [0.5 x FFT size / Sample rate]
--    + Preset/PointsDetectionAlgorithm: allow to limit source length
--    + Preset/PointsDetectionAlgorithm: allow to set threshold for minimum difference betweeen src and dest
--    + Preset/Initialization: various init options
--    + GUI: show source
--    + GUI/Difference graph: show difference graph
--    + GUI/Difference graph: show points detection threshold


--    

  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  local DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 1.0
    DATA.extstate.extstatesection = 'MPL_SpectralSearch'
    DATA.extstate.mb_title = 'Spectral search'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  300,
                          wind_h =  600,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_ampcoeff = 0.02,--transparency 
                          UI_showtooltips = 1, 
                          UI_groupflags = 0, -- show/hide setting flags
                          
                          
                          UI_respath = reaper.GetResourcePath()..'/Data/Spectral sources/',
                          UI_resdefsrc = 'default.sssrc',
                          UI_appatinit = 1, -- 1 get source 2 load default
                          UI_searchatinit = 0, 
                          UI_getsourceflags = 1, --0 time sel 1 selected item
                          UI_getdestflags = 1,--0 time sel 1 selected item
                          
                          CONF_window = 0.05,--sec
                          CONF_FFTsz = 256,
                          CONF_maxsrclen = 1,--sec
                          
                          CONF_algo_threshold = 0.7, -- 0...1
                          
                          CONF_action = 0, -- 0 share to take markers
                            CONF_removeRE = 1, -- clear existing
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
    
    if DATA.extstate.UI_appatinit==1 then
      DATA2:FFTsource_get() 
      DATA2:FFTsource_writetofile()
     elseif DATA.extstate.UI_appatinit==2 then 
      DATA2:FFTsource_load()  
    end
    
    if DATA.extstate.UI_searchatinit==1 then
      DATA2:FFTsource_match()  
    end
    
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    RUN()
  end
  --------------------------------------------------------------------- 
  function DATA2:FFTsource_match()    
    DATA2:sssrc_get() 
    DATA2:Main_GetDiffTable() 
    DATA2:Main_CalcPoints() 
    
  end
  --------------------------------------------------------------------- 
  function DATA2:Action()  
    if not DATA2.points then return end
    if DATA.extstate.CONF_action == 0 then DATA2:Action_GenRazorEdits() end  --action = 'Share points to destination as take markers' end
      
      
    
  end
  --------------------------------------------------------------------- 
  function DATA2:Action_GenRazorEdits()  
    if not DATA2.src.track then return end
    
    local REt = {} 
    local track = DATA2.src.track
    local retval, stringNeedBig = GetSetMediaTrackInfo_String( track, 'P_RAZOREDITS', '', 0 )
    if DATA.extstate.CONF_removeRE == 1 and stringNeedBig~= '' then GetSetMediaTrackInfo_String( track, 'P_RAZOREDITS', '', 1 ) end -- clear RE
    for i = 1, #DATA2.points do
      if DATA2.points[i].state == 1 then
        REt[#REt+1] = {[1] = DATA2.points[i].pos, [2] = DATA2.points[i].pos + DATA2.source.len}
      end
    end
    
    -- app table to track
      
      for i = 1, #REt do REt[i][3] = REt[i][3] or '""' end
      local RE_str = ''
      for i = 1, #REt do RE_str = RE_str..' '..table.concat(REt[i],' ') end
      GetSetMediaTrackInfo_String( track, 'P_RAZOREDITS', RE_str, 1 )
    --reaper.GetNumTakeMarkers( take )
    --reaper.DeleteTakeMarker( take, idx )]]
  end
  --------------------------------------------------------------------- 
  function DATA2:Main_CalcPoints()  
    if not DATA2.offset_diff then return end
    DATA2.points = {}
    local sz = #DATA2.offset_diff
    for i = 1, sz do 
      local state = 0
      if DATA2.offset_diff[i].diff <DATA.extstate. CONF_algo_threshold then state = 1 end
      DATA2.points[i] = {state = state, pos=DATA2.offset_diff[i].pos }
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:Main_GetDiffTable_sub(srcid_offs) -- get difference between whole source and destination
    local diff = 0 
    
    for patblock = 1, #DATA2.source.spls do -- loop each vercial spectrum 
      for bin=1, #DATA2.source.spls[patblock].buf do 
        local block_diff = math.abs(DATA2.source.spls[patblock].buf[bin])- 
            math.abs(DATA2.src.spls[srcid_offs + patblock-1].buf[bin])
        diff = diff + math.abs(block_diff) 
      end 
    end 
    return diff
  end
  --------------------------------------------------------------------- 
  function DATA2:Main_GetDiffTable() 
    if not (DATA2.src and DATA2.src.spls and DATA2.source and DATA2.source.spls) then return end
    
    DATA2.offset_diff = {}
    
    --[[local int_pat_sum = 0
    for patblock = 1, #DATA2.source.spls do -- loop each vercial spectrum 
      for bin=1, #DATA2.source.spls[patblock].buf do 
        int_pat_sum = int_pat_sum + math.abs(DATA2.source.spls[patblock].buf[bin]) 
      end
    end]]
    
    local id = 1
    for srcid_offs = 1, #DATA2.src.spls-#DATA2.source.spls do
      local offs= DATA2.src.spls[srcid_offs].pos
      local diff = DATA2:Main_GetDiffTable_sub(srcid_offs)--int_pat_sum/2  
      --if diff == int_pat_sum then diff = 100000 end
      DATA2.offset_diff[id] = {diff=diff,pos=offs}
      id = id + 1
    end
    
    -- normalize DATA2.offset_diff
    local max = 0
    local min = math.huge
    for i = 1, #DATA2.offset_diff do 
      max = math.max(max, DATA2.offset_diff[i].diff) 
      --min = math.min(min, DATA2.offset_diff[i].diff) 
    end
    for i = 1, #DATA2.offset_diff do DATA2.offset_diff[i].diff = (DATA2.offset_diff[i].diff / max) end
  end
  --------------------------------------------------------------------- 
  function DATA2:sssrc_get() 
    local TSstart, TSend = GetSet_LoopTimeRange2( 0, false, 0, 0, 0, 0 ) 
    local track = GetSelectedTrack(0,0)
    
    if DATA.extstate.UI_getdestflags==1 then 
      local item = GetSelectedMediaItem( 0, 0 )
      if not item then return end
      track = GetMediaItem_Track( item )
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len =  GetMediaItemInfo_Value( item, 'D_LENGTH' )
      TSstart = pos
      TSend = pos + len
    end
    
    if not track then return end
    if TSend-TSstart < 1 then return end
    local SR = VF_GetProjectSampleRate()
    local numchannels = 1
    local pos_step = DATA.extstate.CONF_window
    local FFTwind_sec = 2*DATA.extstate.CONF_FFTsz/SR 
    
    local accessor = CreateTrackAudioAccessor( track )
    local pow = 6
    local id = 0
    DATA2.src= {spls = {},
                track=track}
    for pos = TSstart, TSend, pos_step do
      local samplebuffer = new_array(DATA.extstate.CONF_FFTsz*2)
      GetAudioAccessorSamples( accessor, SR, numchannels, pos, DATA.extstate.CONF_FFTsz, samplebuffer )
      samplebuffer.fft_real(DATA.extstate.CONF_FFTsz, true)
      samplebuffer.resize(DATA.extstate.CONF_FFTsz/2)
      local t = samplebuffer.table()
      samplebuffer.clear()
      local tsz = #t
      for i = 1,tsz  do  t[i] = math.floor(t[i]*10^pow)/10^pow end
      id = id+1
      DATA2.src.spls[id] = {buf = t,
                                pos = pos,
                                }
    end
    reaper.DestroyAudioAccessor( accessor )
    
    
  end
  --------------------------------------------------------------------- 
  function DATA2:FFTsource_load() 
    local fp =  DATA.extstate.UI_respath
    local f=io.open(fp..DATA.extstate.UI_resdefsrc,'rb')
    local content
    if f then 
      content = f:read('a')
      f:close()
    end
    if not content then return end
    DATA2.source = {spls={}}
    local blockid =1 
    DATA2.source.pat_step = tonumber(content:match('pat_step ([%d%p]+)'))
    DATA2.source.pat_fftsz = tonumber(content:match('pat_fftsz ([%d%p]+)'))
    DATA2.source.len = tonumber(content:match('pat_len ([%d%p]+)'))
    
    for chunk in content:gmatch('%<POS%>(.-)%<%/POS%>') do
      local buf = {} 
      local id=0
      for val in chunk:gmatch('[^%s]+') do
        buf[id]=tonumber(val)
        id = id+1
      end
      DATA2.source.spls[blockid] = {buf=buf}
      blockid=blockid+1
    end
    
    -- mod current preset to match loaded source
      DATA.extstate.CONF_FFTsz = DATA2.source.pat_fftsz 
      DATA.extstate.CONF_window = DATA2.source.pat_step
      
  end
 --------------------------------------------------------------------- 
  function DATA2:FFTsource_writetofile()
    if not (DATA2.source and DATA2.source.spls) then return end
    
    local fp =  DATA.extstate.UI_respath
    local context = ''
    local head = 
'// spectral source for MPL Spectral search.lua'..'\n'..
'// generated '..os.date()..'\n'..
'// script_vrs '..DATA.extstate.version..'\n'..
'// pat_step '..DATA2.source.step..'\n'..
'// pat_fftsz '..DATA2.source.fftsz..'\n'..
'// pat_len '..DATA2.source.len..'\n'
    
    local id = 1
    local t_out = {}
    local tsz= #DATA2.source.spls
    for i = 1,tsz do
      local t_spls = {}
      local id2 = 0
      for spl =1, #DATA2.source.spls[i].buf do
        id2 = id2 + 1
        t_spls[id2] = DATA2.source.spls[i].buf[spl]
      end
      t_out[id] = '<POS> '..DATA2.source.spls[i].pos..'\n'..table.concat(t_spls,' ')..'</POS>'
      id = id + 1
    end
    context = head..'\n'..table.concat(t_out,'\n')
    
    RecursiveCreateDirectory( fp, 1)
    local f=io.open(fp..DATA.extstate.UI_resdefsrc,'w')
    if f then 
      f:write(context)
      f:close()
    end
  end
 --------------------------------------------------------------------- 
  function DATA2:FFTsource_get()
    local TSstart, TSend = GetSet_LoopTimeRange2( 0, false, 0, 0, 0, 0 ) 
    local track = GetSelectedTrack(0,0)
    if DATA.extstate.UI_getsourceflags==1 then 
      local item = GetSelectedMediaItem( 0, 0 )
      if not item then return end
      track = GetMediaItem_Track( item )
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len =  GetMediaItemInfo_Value( item, 'D_LENGTH' )
      TSstart = pos
      TSend = pos + len
    end
    if not track then return end
    
    DATA2.source = {step = DATA.extstate.CONF_window,
                     fftsz = DATA.extstate.CONF_FFTsz,
                     spls = {}}
    local SR = VF_GetProjectSampleRate()
    local numchannels = 1
    local pos_step = DATA.extstate.CONF_window
    local FFTwind_sec = 2*DATA.extstate.CONF_FFTsz/SR
    --if pos_step<FFTwind_sec then pos_step = FFTwind_sec end
    local id = 0
    
    --if TSend - TSstart < pos_step*5 then return end
    TSend = VF_lim(TSend, TSstart+pos_step, TSstart+DATA.extstate.CONF_maxsrclen)
    
    DATA2.source.len = TSend - TSstart
    local accessor = CreateTrackAudioAccessor( track )
    local pow = 6
    for pos = TSstart, TSend, pos_step do
      local samplebuffer = new_array(DATA.extstate.CONF_FFTsz*2)
      GetAudioAccessorSamples( accessor, SR, numchannels, pos, DATA.extstate.CONF_FFTsz, samplebuffer )
      id = id + 1 
      samplebuffer.fft_real(DATA.extstate.CONF_FFTsz, true)
      samplebuffer.resize(DATA.extstate.CONF_FFTsz/2)
      local t = samplebuffer.table()
      local tsz = #t
      for i = 1,tsz  do  t[i] = math.floor(t[i]*10^pow)/10^pow end
      DATA2.source.spls[id] = {buf = t,
                                pos = TSstart + pos,
                                }
      samplebuffer.clear()
    end
    reaper.DestroyAudioAccessor( accessor )
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init_shortcuts(DATA)
    if DATA.extstate.UI_enableshortcuts == 0 then return end
    
    DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    
  end

  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    GUI_RESERVED_init_shortcuts(DATA)
    DATA.GUI.buttons = {} 
    
    DATA.GUI.custom_scrollw = 10
    DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    DATA.GUI.custom_mainsepx = (gfx.w/DATA.GUI.default_scale)*0.4
    DATA.GUI.custom_mainsepxupd = 150
    DATA.GUI.custom_setposx = gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx
    DATA.GUI.custom_mainbuth = 30
    DATA.GUI.custom_setposy = (DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*3
    DATA.GUI.custom_tracklistw = (gfx.w/DATA.GUI.default_scale- DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset
    DATA.GUI.custom_tracklisty = DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth
    DATA.GUI.custom_tracklisth = gfx.h/DATA.GUI.default_scale - DATA.GUI.custom_tracklisty-DATA.GUI.custom_offset
    
    DATA.GUI.actnamesmap = {
      [0]='Share points to destination track as razor edits',
      --[1]='Test',
      }
    
    local bw = gfx.w/DATA.GUI.default_scale-DATA.GUI.custom_offset*2
    --[[DATA.GUI.buttons.Rlayer = { x=DATA.GUI.custom_offset,
                           y=DATA.GUI.custom_tracklisty,
                           w=DATA.GUI.custom_tracklistw,
                           h=DATA.GUI.custom_tracklisth,
                           frame_a = 0,
                           layer = DATA.GUI.custom_layerset2,
                           ignoremouse = true,
                           hide = true,
                           }]]
    local printdata,matchdata,ptsdata
    if DATA2.source and DATA2.source.spls then printdata = DATA2.source.spls end
    if DATA2.offset_diff then matchdata = DATA2.offset_diff end
    if DATA2.points then ptsdata = DATA2.points end
    DATA.GUI.buttons.print = { x=DATA.GUI.custom_offset,
                          y=DATA.GUI.custom_offset,
                          w=bw ,
                          h=DATA.GUI.custom_mainbuth*2,
                          txt = 'Get source',
                          txt_fontsz = DATA.GUI.default_txt_fontsz2,
                          onmouseclick =  function () 
                            DATA2:FFTsource_get() 
                            DATA2:FFTsource_writetofile()
                            GUI_RESERVED_init(DATA)
                          end,
                          data = printdata,
                          } 
    DATA.GUI.buttons.getsrc = { x=DATA.GUI.custom_offset,
                          y=(DATA.GUI.custom_offset+DATA.GUI.custom_mainbuth)*2,
                          w=bw, 
                          h=DATA.GUI.custom_mainbuth*2,
                          txt = 'Get destination',
                          txt_fontsz = DATA.GUI.default_txt_fontsz2,
                          onmouseclick =  function () 
                            DATA2:FFTsource_match() 
                            GUI_RESERVED_init(DATA)
                          end,
                          data2 = matchdata,
                          data3 = DATA.extstate.CONF_algo_threshold,
                          data4 = ptsdata,
                          }     
    local action = DATA.GUI.actnamesmap[DATA.extstate.CONF_action] or ''
    DATA.GUI.buttons.action = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*3+DATA.GUI.custom_mainbuth*4,
                            w=bw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Action: '..action,
                            txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            onmouseclick =  function() DATA2:Action() end}  
                            
    DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*4+DATA.GUI.custom_mainbuth*5,
                            w=bw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            onmouseclick =  function() DATA:GUIbut_preset() end}    
                            
    DATA.GUI.buttons.Rsettings = { x=0,
                           y=(DATA.GUI.custom_offset*5+DATA.GUI.custom_mainbuth*6),
                           w=gfx.w/DATA.GUI.default_scale,
                           h=gfx.h/DATA.GUI.default_scale - (DATA.GUI.custom_offset*5+DATA.GUI.custom_mainbuth*6)-DATA.GUI.custom_offset,
                           txt = 'Settings',
                           --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                           frame_a = 0,
                           offsetframe = DATA.GUI.custom_offset,
                           offsetframe_a = 0.1,
                           ignoremouse = true,
                           }
    DATA:GUIBuildSettings() 
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end

  --------------------------------------------------------------------- 
  function GUI_RESERVED_draw_datasub1_sourceFFT(DATA, b)
    -- patter FFT
    local pat_t = b.data
    if pat_t then 
      local sz = #pat_t
      local step_pos = math.floor(sz/b.w)
      for xpos = b.x, b.w do
        local xpos_lin = (xpos - b.x) / b.w
        local t_pos = math.floor(sz * xpos_lin)+1
        if pat_t[t_pos] and pat_t[t_pos].buf then
          local fftsz = #pat_t[t_pos].buf/2
          local buf = pat_t[t_pos].buf
          for ypos = b.y, b.h do
            local ypos_lin = (ypos - b.y) / b.h
            local bufpos = math.floor(fftsz*ypos_lin)+1
            if buf[bufpos ] then
              local val = buf[bufpos ]
              gfx.x, gfx.y = xpos*DATA.GUI.default_scale, (b.y + b.h - ypos)*DATA.GUI.default_scale
              gfx.a = math.min(math.max(math.abs(val*DATA.extstate.UI_ampcoeff),0),0.4)
              local r = 1
              gfx.setpixel(r,r,r )
            end
          end
        end
      end
    end
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_draw_datasub2_diffgraph(DATA, b)
    -- difference table
    local difft = b.data2
    local pts = b.data4
    if difft then 
      local sz = #difft
      local step_pos = math.floor(sz/(b.w))
      for xpos = b.x, b.w do
        local xpos_lin = (xpos - b.x) / b.w
        local t_pos = math.floor(sz * xpos_lin)+1
        if difft[t_pos] and difft[t_pos].diff then
          gfx.x, gfx.y = xpos*DATA.GUI.default_scale, (b.y + b.h-b.h*difft[t_pos].diff)*DATA.GUI.default_scale
          gfx.a = 0.3
          local h_lev = difft[t_pos].diff*DATA.GUI.default_scale*b.h
          --gfx.lineto(xpos*DATA.GUI.default_scale,(b.y + b.h)*DATA.GUI.default_scale)
          gfx.rect(xpos*DATA.GUI.default_scale,(b.y + b.h)*DATA.GUI.default_scale-h_lev,1*DATA.GUI.default_scale,h_lev+1)
        end
      end
    end   
    
    local pts = b.data4
    if pts then 
      local sz = #difft
      for i =1, sz do
        if pts[i].state == 1 then 
          local xpos = math.floor(b.x+b.w*(i/sz))
          gfx.a = 0.4
          gfx.line(xpos*DATA.GUI.default_scale, b.y *DATA.GUI.default_scale,
               xpos*DATA.GUI.default_scale, (b.y + b.h)*DATA.GUI.default_scale)
        end
      end
    end
    
  end
  
  
  --------------------------------------------------------------------- 
  function GUI_RESERVED_draw_datasub3_getsrcthreshold(DATA, b)
    if not b.data3 then return end
    local triside = 2*DATA.GUI.default_scale
    local w = b.w*DATA.GUI.default_scale*0.5
    local y_val = b.y + b.h-b.h*b.data3
    local drdx=0
    local dgdx=0
    local dbdx=0
    local dadx=0
    local drdy=0
    local dgdy=0
    local dbdy=0
    local dady=0
    local a = 0.4
    gfx.gradrect(triside+b.x*DATA.GUI.default_scale,(y_val-1)*DATA.GUI.default_scale,w,2*DATA.GUI.default_scale, 1,1,1,a, drdx, dgdx, dbdx, -a/(w), drdy, dgdy, dbdy, dady ) 
    gfx.a = 0.5
    gfx.triangle(b.x*DATA.GUI.default_scale,(y_val-triside)*DATA.GUI.default_scale,b.x*DATA.GUI.default_scale,(y_val+triside)*DATA.GUI.default_scale,(b.x+triside)*DATA.GUI.default_scale,y_val*DATA.GUI.default_scale )
  end
  
  --------------------------------------------------------------------- 
  function GUI_RESERVED_draw_data(DATA, b)
    GUI_RESERVED_draw_datasub1_sourceFFT(DATA, b)
    GUI_RESERVED_draw_datasub2_diffgraph(DATA, b)
    GUI_RESERVED_draw_datasub3_getsrcthreshold(DATA, b) 
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings_refreshpoints(DATA, is_minor)
    if not is_minor then DATA2:Main_CalcPoints()   end
    DATA.GUI.buttons.getsrc.data3 = DATA.extstate.CONF_algo_threshold 
    DATA.GUI.buttons.getsrc.data4 =  DATA2.points
    DATA.GUI.buttons.getsrc.refresh = true
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local readoutw_extw = 150
        
    local  t = 
    { 
      {str = 'Spectrum settings' ,                      group = 1, itype = 'sep'}, 
        {str = 'Window' ,                                 group = 1, itype = 'readout', confkey = 'CONF_window', level = 1, val_min = 0.005, val_max = 0.4, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,3)..'s' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end},
        {str = 'FFT size' ,                               group = 1, itype = 'readout', confkey = 'CONF_FFTsz', level = 1, menu = { 
          [16]=16,
          [32]=32,
          [64]=64, 
          [128]=128, 
          [256]=256,  
          [512]=512,
          [1024]=1024,
        }}, 
      --{str = 'Source settings' ,                       group = 7, itype = 'sep'}, 
        
      
      
      {str = 'Points detection algorithm' ,             group = 5, itype = 'sep'},    
        {str = 'Max source length' ,                    group = 5, itype = 'readout', confkey = 'CONF_maxsrclen', level = 1, val_min = 0.3, val_max = 5, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,3)..'s' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end},
        {str = 'Threshold' ,                            group = 5, itype = 'readout', confkey = 'CONF_algo_threshold', level = 1, val_res = 0.05, val_format = function(x) return math.floor(x*100)..'%' end, val_format_rev = function(x) if x:match('[%d%.]+') then return tonumber(x:match('[%d%.]+'))/100 end end, 
          func_onrelease = function() GUI_RESERVED_BuildSettings_refreshpoints(DATA) end,
          func_onmousedrag = function() GUI_RESERVED_BuildSettings_refreshpoints(DATA, true) end,
          },
          
      {str = 'Action' ,                                 group = 6, itype = 'sep'},  
        {str = DATA.GUI.actnamesmap[0] ,                group = 6, itype = 'check', level = 1, confkey = 'CONF_action', isset=0},
        {str = 'Clear existing RE' ,          group = 6, itype = 'check', level = 2, confkey = 'CONF_removeRE', hide = DATA.extstate.CONF_action ~= 0 },
        --{str = DATA.GUI.actnamesmap[1] ,                group = 6, itype = 'check', level = 1, confkey = 'CONF_action', isset=1},
        
      {str = 'Initialization' ,                         group = 4, itype = 'sep'},    
        {str = 'Get source at init' ,                  group = 4, itype = 'check', level = 1, confkey = 'UI_appatinit', isset=1},
        {str = 'Load last source at init',             group = 4, itype = 'check', level = 1, confkey = 'UI_appatinit', isset=2},
        {str = 'Match source at init' ,                group = 4, itype = 'check', level = 1, confkey = 'UI_searchatinit'}, 
        {str = 'Init UI at mouse position' ,            group = 4, itype = 'check', level = 1, confkey = 'UI_initatmouse'},
      {str = 'UI settings' ,                            group = 3, itype = 'sep'},  
        {str = 'Get source' ,                          group = 3, itype = 'button', level = 1},
        {str = 'Use time selection' ,                   group = 3, itype = 'check', level = 2, confkey = 'UI_getsourceflags', isset=0},
        {str = 'Use selected item' ,                    group = 3, itype = 'check', level = 2, confkey = 'UI_getsourceflags', isset=1},
        {str = 'Get destination' ,                          group = 3, itype = 'button', level = 1},
        {str = 'Use time selection' ,                   group = 3, itype = 'check', level = 2, confkey = 'UI_getdestflags', isset=0},
        {str = 'Use selected item' ,                    group = 3, itype = 'check', level = 2, confkey = 'UI_getdestflags', isset=1},        
        
        {str = 'UI source gain' ,                      group = 3, itype = 'readout', confkey = 'UI_ampcoeff', level = 1, val_min = 0.01, val_max = 1, val_res = 0.05}
    } 
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.30) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end
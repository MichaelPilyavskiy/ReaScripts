-- @description Align Takes
-- @version 2.27
-- @author MPL
-- @about Script for matching RMS of audio takes and stratch them using stretch markers
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix 'Switch to full mode' for retina on Mac and non-100% scaling on Win


  --[[
    * Changelog: 
      * v2.0 (01.2022)
      * v1.00 (2016-02-11) Public release
      * v0.23 (2016-01-25) Split from Warping tool
      * v0.01 (2015-09-01) Alignment / Warping / Tempomatching tool idea
    --]]
    
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  -- to do
    -- zero crossing  
    -- get existed stretch markers as points
    -- preserve transients (guard)
    -- use eel for CPU hungry stuff 
    -- obey pitch data
    -- align pitch data
  
   DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 2.27
    DATA.extstate.extstatesection = 'AlignTakes2'
    DATA.extstate.mb_title = 'AlignTakes'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  200,
                          wind_h =  150,
                          dock =    0,
                          
                          FPRESET1 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gUGlja2VkIGd1aXRhcgpDT05GX2FwcGF0Y2hhbmdlPTEKQ09ORl9hdWRpb19ic19hMT0wCkNPTkZfYXVkaW9fYnNfYTI9MQpDT05GX2F1ZGlvX2JzX2EzPTAKQ09ORl9hdWRpb19ic19hND0xCkNPTkZfYXVkaW9fYnNfZjE9MjAwCkNPTkZfYXVkaW9fYnNfZjI9MjAwMApDT05GX2F1ZGlvX2JzX2YzPTUwMDAKQ09ORl9hdWRpb19saW09MQpDT05GX2F1ZGlvZG9zcXVhcmVyb290PTEuMApDT05GX2NsZWFubWFya2R1Yj0xCkNPTkZfY29tcGVuc2F0ZW92ZXJsYXA9MQpDT05GX2VuYWJsZXNob3J0Y3V0cz0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2luaXRmbGFncz0zCkNPTkZfbWFya2dlbl9STVNwb2ludHM9NQpDT05GX21hcmtnZW5fZW52ZWxvcGVyaXNlZmFsbD0yCkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHM9MTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDg3NQpDT05GX21hcmtnZW5fdGhyZXNob2xkPTEKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MwpDT05GX21hdGNoX2lnbm9yZXplcm9zPTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0wCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MApDT05GX3dpbmRvdz0wLjAxNwpDT05GX3dpbmRvd19vdmVybGFwPTE=',
                          FPRESET2 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gRGlzdG9ydGVkIGd1aXRhcgpDT05GX2FwcGF0Y2hhbmdlPTEKQ09ORl9hdWRpb19ic19hMT0wCkNPTkZfYXVkaW9fYnNfYTI9MQpDT05GX2F1ZGlvX2JzX2EzPTAKQ09ORl9hdWRpb19ic19hND0wCkNPTkZfYXVkaW9fYnNfZjE9ODMKQ09ORl9hdWRpb19ic19mMj0xMjUwCkNPTkZfYXVkaW9fYnNfZjM9NTAwMApDT05GX2F1ZGlvX2xpbT0xCkNPTkZfYXVkaW9kb3NxdWFyZXJvb3Q9MS4wCkNPTkZfY2xlYW5tYXJrZHViPTEKQ09ORl9jb21wZW5zYXRlb3ZlcmxhcD0xCkNPTkZfZW5hYmxlc2hvcnRjdXRzPTAKQ09ORl9pbml0YXRtb3VzZXBvcz0wCkNPTkZfaW5pdGZsYWdzPTMKQ09ORl9tYXJrZ2VuX1JNU3BvaW50cz01CkNPTkZfbWFya2dlbl9lbnZlbG9wZXJpc2VmYWxsPTEKQ09ORl9tYXJrZ2VuX2ZpbHRlcnBvaW50cz0xMQpDT05GX21hcmtnZW5fbWluaW1hbGFyZWFSTVM9MC4wODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQ9MQpDT05GX21hdGNoX2Jsb2NrYXJlYT0xCkNPTkZfbWF0Y2hfaWdub3JlemVyb3M9MApDT05GX21hdGNoX3N0cmV0Y2hkdWJhcnJheT0xCkNPTkZfb2J0aW1lc2VsPTAKQ09ORl9wb3N0X3BvczBtYXJrPTEKQ09ORl9wb3N0X3BzaGlmdD0tMQpDT05GX3Bvc3RfcHNoaWZ0c3ViPTAKQ09ORl9wb3N0X3NtbW9kZT0yCkNPTkZfcG9zdF9zdHJtYXJrZmRzaXplPTAuMDExMQpDT05GX3Ntb290aD0wCkNPTkZfd2luZG93PTAuMDE3CkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
                          FPRESET3 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gVm9jYWxzCkNPTkZfYXBwYXRjaGFuZ2U9MQpDT05GX2F1ZGlvX2JzX2ExPTAuMzMxMjUKQ09ORl9hdWRpb19ic19hMj0xCkNPTkZfYXVkaW9fYnNfYTM9MC4zMzEyNQpDT05GX2F1ZGlvX2JzX2E0PTAuNgpDT05GX2F1ZGlvX2JzX2YxPTIwMApDT05GX2F1ZGlvX2JzX2YyPTIwMDAKQ09ORl9hdWRpb19ic19mMz01MDAwCkNPTkZfYXVkaW9fbGltPTEKQ09ORl9hdWRpb2Rvc3F1YXJlcm9vdD0xLjAKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9lbmFibGVzaG9ydGN1dHM9MApDT05GX2luaXRhdG1vdXNlcG9zPTAKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTUKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTEzCkNPTkZfbWFya2dlbl9taW5pbWFsYXJlYVJNUz0wLjAzMTI1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQ9MQpDT05GX21hdGNoX2Jsb2NrYXJlYT0yNgpDT05GX21hdGNoX2lnbm9yZXplcm9zPTAKQ09ORl9tYXRjaF9tYXhibG9ja3NzdGFydG9mZnM9NgpDT05GX21hdGNoX21pbmJsb2Nrc3N0YXJ0b2Zmcz00CkNPTkZfbWF0Y2hfc2VhcmNoZnVydGhlcm9ubHk9MApDT05GX21hdGNoX3N0cmV0Y2hkdWJhcnJheT0xCkNPTkZfb2J0aW1lc2VsPTAKQ09ORl9wb3N0X3BvczBtYXJrPTEKQ09ORl9wb3N0X3BzaGlmdD0tMQpDT05GX3Bvc3RfcHNoaWZ0c3ViPTAKQ09ORl9wb3N0X3NtbW9kZT0yCkNPTkZfcG9zdF9zdHJtYXJrZmRzaXplPTAuMDExMQpDT05GX3Ntb290aD0wCkNPTkZfd2luZG93PTAuMDE0CkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
                          FPRESET4 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gVm9jYWxzIC0gdGlueSBhbGlnbiBtb3N0bHkgYnkgaGlnaHMKQ09ORl9hbGlnbml0ZW10YWtlcz0wCkNPTkZfYXBwYXRjaGFuZ2U9MQpDT05GX2F1ZGlvX2JzX2ExPTAKQ09ORl9hdWRpb19ic19hMj0wLjIxODc1CkNPTkZfYXVkaW9fYnNfYTM9MQpDT05GX2F1ZGlvX2JzX2E0PTEKQ09ORl9hdWRpb19ic19mMT04OApDT05GX2F1ZGlvX2JzX2YyPTIwMDAKQ09ORl9hdWRpb19ic19mMz01MDAwCkNPTkZfYXVkaW9fZ2F0ZT0wCkNPTkZfYXVkaW9fbGltPTEKQ09ORl9hdWRpb2Rvc3F1YXJlcm9vdD0wLjQKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTEwCkNPTkZfbWFya2dlbl9hbGdvPTEKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTE2CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMyPTIxCkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMzPTg0CkNPTkZfbWFya2dlbl9tYW51YWxlZGl0PTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDE4NzUKQ09ORl9tYXJrZ2VuX3RocmVzaG9sZD0wLjcxODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQyPTAuMzkzNzUKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MTUKQ09ORl9tYXRjaF9maXJzdHNyZ21vbmx5PTAKQ09ORl9tYXRjaF9pZ25vcmV6ZXJvcz0wCkNPTkZfbWF0Y2hfbWF4YmxvY2tzc3RhcnRvZmZzPTEKQ09ORl9tYXRjaF9taW5ibG9ja3NzdGFydG9mZnM9MgpDT05GX21hdGNoX3NlYXJjaGZ1cnRoZXJvbmx5PTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0wCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MApDT05GX3dpbmRvdz0wLjAxCkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
                          FPRESET5 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gR3Jvd2xpbmcgdm9jYWxzLCB0aW1lIHNlbGVjdGlvbgpDT05GX2FsaWduaXRlbXRha2VzPTAKQ09ORl9hdWRpb19ic19hMT0wLjE0NDQ0NDQ0NDQ0NDQ0CkNPTkZfYXVkaW9fYnNfYTI9MC45MTY2NjY2NjY2NjY2NwpDT05GX2F1ZGlvX2JzX2EzPTEKQ09ORl9hdWRpb19ic19hND0xLjAKQ09ORl9hdWRpb19ic19mMT0xOTIuNQpDT05GX2F1ZGlvX2JzX2YyPTIwMDAKQ09ORl9hdWRpb19ic19mMz04MjY2LjY2NjY2NjY2NjcKQ09ORl9hdWRpb19nYXRlPTAKQ09ORl9hdWRpb19saW09MQpDT05GX2F1ZGlvZG9zcXVhcmVyb290PTAuNTMwMjc3Nzc3Nzc3NzgKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9pZ25vcmVlbXB0eXRha2VzPTEKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTEwCkNPTkZfbWFya2dlbl9hbGdvPTEKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTE2CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMyPTE4CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMzPTQwCkNPTkZfbWFya2dlbl9tYW51YWxlZGl0PTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDE4NzUKQ09ORl9tYXJrZ2VuX3RocmVzaG9sZD0wLjcxODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQyPTAuNzAyMDgzMzMzMzMzMzMKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MTUKQ09ORl9tYXRjaF9maXJzdHNyZ21vbmx5PTAKQ09ORl9tYXRjaF9pZ25vcmV6ZXJvcz0xCkNPTkZfbWF0Y2hfbWF4YmxvY2tzc3RhcnRvZmZzPTEKQ09ORl9tYXRjaF9taW5ibG9ja3NzdGFydG9mZnM9MgpDT05GX21hdGNoX3NlYXJjaGZ1cnRoZXJvbmx5PTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0xCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MApDT05GX3dpbmRvdz0wLjAxCkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
                          FPRESET6 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gR3Jvd2xpbmcgdm9jYWxzMiBmaW5pc2ggMC4xc2hpZnQKQ09ORl9hbGlnbml0ZW10YWtlcz0wCkNPTkZfYXVkaW9fYnNfYTE9MApDT05GX2F1ZGlvX2JzX2EyPTAuMjE5NDQ0NDQ0NDQ0NDQKQ09ORl9hdWRpb19ic19hMz0wLjQKQ09ORl9hdWRpb19ic19hND0wLjUyNQpDT05GX2F1ZGlvX2JzX2YxPTE5Mi41CkNPTkZfYXVkaW9fYnNfZjI9MTY2My41NzYzODg4ODg5CkNPTkZfYXVkaW9fYnNfZjM9ODI2Ni42NjY2NjY2NjY3CkNPTkZfYXVkaW9fZ2F0ZT0wCkNPTkZfYXVkaW9fbGltPTEKQ09ORl9hdWRpb2Rvc3F1YXJlcm9vdD0wLjUzMDI3Nzc3Nzc3Nzc4CkNPTkZfYnVpbGRyZWZhc21heGltdW1zPTEKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9pZ25vcmVlbXB0eXRha2VzPTEKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTEwCkNPTkZfbWFya2dlbl9hbGdvPTEKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTE2CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMyPTI5CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMzPTIwCkNPTkZfbWFya2dlbl9tYW51YWxlZGl0PTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDE4NzUKQ09ORl9tYXJrZ2VuX3RocmVzaG9sZD0wLjcxODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQyPTAuNzAyMDgzMzMzMzMzMzMKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MTUKQ09ORl9tYXRjaF9maXJzdHNyZ21vbmx5PTAKQ09ORl9tYXRjaF9pZ25vcmV6ZXJvcz0xCkNPTkZfbWF0Y2hfbWF4YmxvY2tzc3RhcnRvZmZzPTEKQ09ORl9tYXRjaF9taW5ibG9ja3NzdGFydG9mZnM9MgpDT05GX21hdGNoX3NlYXJjaGZ1cnRoZXJvbmx5PTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0xCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MQpDT05GX3dpbmRvdz0wLjAwNQpDT05GX3dpbmRvd19vdmVybGFwPTE=',
                          CONF_NAME = 'default',
                          
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0,
                          UI_appatchange = 1,
                          
                          CONF_initflags = 7, -- &1 init ref &2 init dub
                          CONF_cleanmarkdub = 1,
                          CONF_obtimesel = 0, 
                          CONF_alignitemtakes = 0, -- per item mode
                          CONF_ignoreemptytakes = 1, -- skip takes with linear amp < 0.05
                          CONF_buildrefasmaximums = 0, 
                          
                          CONF_window = 0.01,
                          CONF_window_overlap = 1,
                          
                          CONF_audiodosquareroot = 0.4,
                          
                          CONF_audio_bs_f1 = 88,
                          CONF_audio_bs_f2 = 2000,
                          CONF_audio_bs_f3 = 5000,
                          CONF_audio_bs_a1 = 0,
                          CONF_audio_bs_a2 = 0.21875,
                          CONF_audio_bs_a3 = 1,
                          CONF_audio_bs_a4 = 1,
                          CONF_audio_lim = 1,
                          CONF_audio_gate = 0,
                          CONF_smooth = 0, 
                          CONF_compensateoverlap = 1, 
                          
                          CONF_markgen_manualedit = 0, 
                          CONF_markgen_algo = 1, 
                            CONF_markgen_enveloperisefall = 1, -- ==1 at fall ==2 at rise
                            CONF_markgen_filterpoints = 16, 
                            CONF_markgen_RMSpoints = 10, 
                            CONF_markgen_minimalareaRMS = 0.01875,
                            CONF_markgen_threshold = 0.71875,
                          -- alg2
                            CONF_markgen_filterpoints2 = 21, -- minimal poits distance
                            CONF_markgen_threshold2 = 0.39375,
                          -- alg3
                            CONF_markgen_filterpoints3 = 84, -- minimal poits distance
                            
                          CONF_match_blockarea = 15, 
                          CONF_match_stretchdubarray = 1,
                          CONF_match_ignorezeros = 0,
                          CONF_match_searchfurtheronly = 0,
                          CONF_match_minblocksstartoffs = 2,
                          CONF_match_maxblocksstartoffs = 1,
                          CONF_match_firstsrgmonly = 0,
                          
                          CONF_post_pshift = -1,
                          CONF_post_pshiftsub = 0,
                          CONF_post_strmarkfdsize = 0.0111,
                          CONF_post_smmode = 2,
                          CONF_post_pos0mark = 1,
                          CONF_post_zerocross = 0,
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
    if DATA.extstate.CONF_initflags&1==1 or DATA.GUI.compactmode == 1 then DATA2:GetRefAudioData() end 
    if DATA.extstate.CONF_initflags&2==2 or DATA.GUI.compactmode == 1 then DATA2:GetDubAudioData(  (DATA.extstate.CONF_initflags&1==1 or DATA.GUI.compactmode == 1 )) end 
    RUN()
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init_shortcuts(DATA)
    -- left/right arrow move main knob
    -- G/g get ref/dub
    -- R/r get ref
    -- D/d get dub
    if DATA.extstate.UI_enableshortcuts == 0 then return end
    
    local function GUI_RESERVED_init_shortcutsLRArrow(DATA, mult0)
      local mult = mult0 or 1
      local step = 0.1
      if DATA.GUI.compactmode == 0 then 
        DATA.GUI.buttons.knob.val = VF_lim(DATA.GUI.buttons.knob.val+mult*step)
        DATA2:ApplyOutput(DATA,true)  
        DATA.GUI.buttons.knob.refresh = true
       else
        DATA.GUI.buttons.knobCOMPACT.val = VF_lim(DATA.GUI.buttons.knobCOMPACT.val+mult*step)
        DATA2:ApplyOutput(DATA, true)  
        DATA.GUI.buttons.knobCOMPACT.refresh = true
      end
    end
    
    DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
    DATA.GUI.shortcuts[71] = function() DATA2:GetRefAudioData() DATA2:GetDubAudioData(true) end -- G / g to get data
    DATA.GUI.shortcuts[103] = DATA.GUI.shortcuts[71]
    DATA.GUI.shortcuts[82] = function() DATA2:GetRefAudioData() end -- R / r to get reference
    DATA.GUI.shortcuts[114] = DATA.GUI.shortcuts[82] 
    DATA.GUI.shortcuts[68] = function() DATA2:GetDubAudioData() end -- R / r to get reference
    DATA.GUI.shortcuts[100] = DATA.GUI.shortcuts[68]  
    DATA.GUI.shortcuts[1919379572] = function() GUI_RESERVED_init_shortcutsLRArrow(DATA, 1) end
    DATA.GUI.shortcuts[1818584692] = function() GUI_RESERVED_init_shortcutsLRArrow(DATA, -1) end
    
    
  end
  --------------------------------------------------------------------- 
  function DATA2:gettruewindow()
    local wind = DATA.extstate.CONF_window/DATA.extstate.CONF_window_overlap
    if DATA.extstate.CONF_compensateoverlap == 1 then wind = DATA.extstate.CONF_window end
    return wind
  end
  ---------------------------------------------------------------------   
  function DATA2:ApplyOutput_ProjPosToStretchMarkerPos(projpos, item_pos, takerate) 
    local markpos = takerate * (projpos - item_pos)
    return markpos
  end
  --------------------------------------------------------------------- 
  function DATA2:ApplyOutput_ProjPosToStretchMarkerSrcPos(projpos, item_pos, takerate, takeoffs) 
    local markpos = takeoffs + (projpos - item_pos)*takerate
    return markpos
  end
  --------------------------------------------------------------------- 
  function DATA2:ApplyOutput(DATA, is_major) 
    if not DATA2.dubdata then return end
    
    for dubdataID = 1, #DATA2.dubdata do
      -- get table data
        local take_dubdata = DATA2.dubdata[dubdataID]
        if not take_dubdata then goto skipdubtake2 end 
      -- vars
        local data_pointsSRCDEST = take_dubdata.data_pointsSRCDEST
        local take =      take_dubdata.take
        local takeoffs =  take_dubdata.take_offs
        local takerate =  take_dubdata.take_rate
        local item =      take_dubdata.item
        local item_pos =  take_dubdata.item_pos
        local item_len =  take_dubdata.item_len
        local item_srclen =  take_dubdata.item_srclen
        
      -- validate take
        if not ValidatePtr2( 0, take, 'MediaItem_Take*' )  then goto skipdubtake2 end    
      -- clean markers
        --DATA2:CleanDubMarkers(take, DATA2.refdata.edge_start,DATA2.refdata.edge_end, item, item_pos, takerate)   
        DATA2:CleanDubMarkers2(take,  takerate, math.max(0,DATA2.refdata.edge_start - item_pos),math.min(item_len ,DATA2.refdata.edge_end - item_pos)) 
      -- get true window
        local wind = DATA2:gettruewindow()
      -- validate data_pointsSRCDEST
        if not data_pointsSRCDEST then goto skipdubtake2 end
      -- get value
        local val = 0
        if DATA.GUI.compactmode == 1 then 
          if DATA.GUI.buttons and DATA.GUI.buttons.knobCOMPACT and DATA.GUI.buttons.knobCOMPACT.val then val =  DATA.GUI.buttons.knobCOMPACT.val else val = 1 end
         else 
          if DATA.GUI.buttons and DATA.GUI.buttons.knob and DATA.GUI.buttons.knob.val then val =  DATA.GUI.buttons.knob.val else val = 1 end
        end
      -- add markers      
        local last_src_pos
        local last_dest_pos 
        for i = 1, #data_pointsSRCDEST do 
          local tpair = data_pointsSRCDEST[i]
          local src_pos = DATA2:ApplyOutput_ProjPosToStretchMarkerPos((tpair.src) * wind + DATA2.refdata.edge_start, item_pos, takerate) 
          local dest_pos = DATA2:ApplyOutput_ProjPosToStretchMarkerPos((tpair.dest-1) * wind + DATA2.refdata.edge_start, item_pos, takerate) 
          local dest_pos = src_pos + (dest_pos-src_pos) *val
          local src_pos0 = DATA2:ApplyOutput_ProjPosToStretchMarkerSrcPos((tpair.src) * wind + DATA2.refdata.edge_start, item_pos, takerate, takeoffs) 
          
          
          
          local is_inside_boundary = dest_pos < math.min(item_len ,DATA2.refdata.edge_end - item_pos) and dest_pos > math.max(0,DATA2.refdata.edge_start - item_pos)
          if last_src_pos ~= nil and last_dest_pos ~= nil then
            -- check for negative stretch markers
            if (src_pos - last_src_pos) / (dest_pos - last_dest_pos ) > 0 then
              if is_inside_boundary then 
                SetTakeStretchMarker(take, -1, dest_pos,src_pos0 ) 
              end
              last_src_pos = src_pos
              last_dest_pos = dest_pos
            end
           else
            if is_inside_boundary then 
              SetTakeStretchMarker(take, -1, dest_pos,src_pos0 )  
            end           
            last_src_pos = src_pos
            last_dest_pos = dest_pos
          end
        end 
      
      if is_major == true then
        if DATA.extstate.CONF_post_pshift >= 0 then pshift = DATA.extstate.CONF_post_pshift end
        if DATA.extstate.CONF_post_pshift >= 0 and  DATA.extstate.CONF_post_pshiftsub >= 0 then  pshiftsub = DATA.extstate.CONF_post_pshiftsub end
        if DATA.extstate.CONF_post_pshift >= 0 or DATA.extstate.CONF_post_strmarkfdsize ~= 0.0025 then  VF_SetTimeShiftPitchChange(item, false, (DATA.extstate.CONF_post_pshift<<16) + DATA.extstate.CONF_post_pshiftsub, DATA.extstate.CONF_post_smmode, DATA.extstate.CONF_post_strmarkfdsize)  end 
        if DATA.extstate.CONF_post_zerocross ==1 then  MPL_QuantizeSMtoZeroCross( reaper.GetActiveTake( item )) end 
      end
      if item then UpdateItemInProject( item ) end
      ::skipdubtake2::
    end
  end
  ---------------------------------------------------------------------
  function MPL_QuantizeSMtoZeroCross(take)
    if not take then return end
    if reaper.TakeIsMIDI(take) then return end
    local source = reaper.GetMediaItemTake_Source( take )
    local SR = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 ))--GetMediaSourceSampleRate( source ) 
    local cnt = reaper.GetTakeNumStretchMarkers( take )
    local soffs = reaper.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    local rate = reaper.GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    local it = reaper.GetMediaItemTake_Item( take )
    local it_pos = reaper.GetMediaItemInfo_Value(  it, 'D_POSITION' )
    local tr =  reaper.GetMediaItemTrack( it )
    local pr_offs = reaper.GetProjectTimeOffset( 0, false )
     sm_t = {}
    local pow = 8
    for i = 1, cnt do 
      local retval, posOut, src_pos = reaper.GetTakeStretchMarker( take, i-1 )
      
      local pos_proj = it_pos + posOut/rate + pr_offs
      sm_t[#sm_t+1] = {pos = posOut, src_pos = math.floor((10^pow)*src_pos) / (10^pow), pos_proj = pos_proj} 
    end
    
    local bufsz_check = math.floor(SR * (500 / 44100)) -- take approximately 500 samples at 44.1
    local buf_offs_sec =  math.floor(SR * (1 / 44100))/SR -- take approximately 5 samples at 44.1
    local accessor = reaper.CreateTrackAudioAccessor( tr)
    local samplebuffer = reaper.new_array(bufsz_check);
    for i = 1, #sm_t do
      local pos_check = sm_t[i].pos_proj - buf_offs_sec - pr_offs
      reaper.GetAudioAccessorSamples( accessor, SR, 1, pos_check, bufsz_check, samplebuffer )
      sm_t[i].pos_ZC = sm_t[i].src_pos
      for spl = 3,bufsz_check do
        if (samplebuffer[spl] >=0 and samplebuffer[spl-1] <0) or (samplebuffer[spl] <0 and samplebuffer[spl-1] >=0) then
          sm_t[i].pos_ZC  = sm_t[i].src_pos + (spl-2)/ SR
          break
        end
      end
      samplebuffer.clear()
    end
    reaper.DestroyAudioAccessor( accessor )
     
      
    for i = 2,#sm_t-1 do
      local src_pos = sm_t[i].src_pos
      local src_ZC = sm_t[i].pos_ZC
      local diff = sm_t[i].pos_ZC - sm_t[i].src_pos
      reaper.SetTakeStretchMarker( take, i-1, sm_t[i].pos + diff, sm_t[i].src_pos+diff )
    end
    reaper.UpdateItemInProject( it )
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    
    --GUI.default_scale = 2
    DATA.GUI.custom_mainbuth = 30
    DATA.GUI.custom_texthdef = 23
    DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    DATA.GUI.custom_mainsepx = (gfx.w/DATA.GUI.default_scale)*0.4-- *GUI.default_scale--400*GUI.default_scale--
    DATA.GUI.custom_mainbutw = ((gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*4) / 3
    DATA.GUI.custom_scrollw = 10
    DATA.GUI.custom_frameascroll = 0.05
    DATA.GUI.custom_default_framea_normal = 0.1
    DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
    DATA.GUI.custom_layerset= 21
    DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth-DATA.GUI.custom_offset*3) 
    
    DATA.GUI.default_data_a = 0.3
    DATA.GUI.default_data_a1 = 0.8
    DATA.GUI.default_data_a2 = 0.8
    DATA.GUI.default_data_col = '#FFFFFF'
    DATA.GUI.default_data_col_adv = '#00ff00' -- green
    DATA.GUI.default_data_col_adv2 = '#e61919' -- red
    
    GUI_RESERVED_init_shortcuts(DATA)
    
    -- define compact mode
      local w,h = gfx.w,gfx.h
      DATA.GUI.compactmode = 0
      DATA.GUI.compactmodelimh = 200
      DATA.GUI.compactmodelimw = 500
      if w < DATA.GUI.compactmodelimw*DATA.GUI.default_scale or h < DATA.GUI.compactmodelimh*DATA.GUI.default_scale then DATA.GUI.compactmode = 1 end
    
    DATA.GUI.buttons = {} 
    -- main buttons
      if DATA.GUI.compactmode == 0 then 
        DATA.GUI.buttons.getreference = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Get Ref',
                            txt_short = 'REF',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            onmouseclick =  function() DATA2:GetRefAudioData() end,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            } 
        DATA.GUI.buttons.getdub = { x=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbutw,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Get Dub',
                            txt_short = 'DUB',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA2:GetDubAudioData() end}  
        DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset*5+DATA.GUI.custom_mainbutw*3,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA:GUIbut_preset() end} 
                                            
        DATA.GUI.buttons.knob = { x=DATA.GUI.custom_offset*3 + DATA.GUI.custom_mainbutw*2 ,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = '',
                            txt_fontsz = DATA.GUI.custom_texthdef,
                            knob_isknob = true,
                            val_res = 0.25,
                            val = 0,
                            frame_a = DATA.GUI.default_framea_normal,
                            frame_asel = DATA.GUI.default_framea_normal,
                            back_sela = 0,
                            hide = DATA.GUI.compactmode==1,
                            ignoremouse = DATA.GUI.compactmode==1,
                            onmousedrag =  function() DATA2:ApplyOutput(DATA) end,
                            onmouserelease  =  function() 
                                                  DATA2:ApplyOutput(DATA, true)
                                                  Undo_OnStateChange2( 0, 'Align Takes' ) 
                                                end
                                            
                                            } 
        DATA.GUI.buttons.Rsettings = { x=gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx,
                            y=DATA.GUI.custom_mainbuth + DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainsepx,
                            h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth - DATA.GUI.custom_offset,
                            txt = 'Settings',
                            --txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            frame_a = 0,
                            offsetframe = DATA.GUI.custom_offset,
                            offsetframe_a = 0.1,
                            ignoremouse = true,
                            }   
                            
        DATA:GUIBuildSettings()
        GUI_initdata(DATA)
      end
      
      if DATA.GUI.compactmode == 1 then 
      local h_help = 20
      DATA.GUI.layers[22]= nil
      DATA.GUI.buttons.knobCOMPACT = { x=0 ,
                            y=h_help,
                            w=gfx.w/DATA.GUI.default_scale,
                            h=(gfx.h-h_help)/DATA.GUI.default_scale,
                            txt = '',
                            txt_fontsz = DATA.GUI.custom_texthdef,
                            knob_isknob = true,
                            --val_res = 0.25,
                            val = 0,
                            frame_a = DATA.GUI.default_framea_normal,
                            frame_asel = DATA.GUI.default_framea_normal,
                            back_sela = 0,
                            hide = DATA.GUI.compactmode~=1,
                            ignoremouse = DATA.GUI.compactmode~=1,
                            onmousedrag =  function()  DATA2:ApplyOutput(DATA) end,
                            onmouserelease  =  function() 
                                                  DATA2:ApplyOutput(DATA, true)
                                                  Undo_OnStateChange2( 0, 'Align Takes' ) 
                                                end }  
      DATA.GUI.buttons.help = { x=0 ,
                            y=0,
                            w=gfx.w/DATA.GUI.default_scale,
                            h=(h_help)/DATA.GUI.default_scale,
                            txt = 'Switch to full mode',
                            txt_fontsz = DATA.GUI.default_txt_fontsz3,
                            frame_a = 0,
                            --frame_asel = DATA.GUI.default_framea_normal,
                            back_sela = 0,
                            hide = DATA.GUI.compactmode~=1,
                            ignoremouse = DATA.GUI.compactmode~=1,
                            onmouserelease =  function()  
                              DATA.extstate.wind_w = 700*DATA.GUI.default_scale
                              DATA.extstate.wind_h = 500*DATA.GUI.default_scale
                              gfx.init( title,
                                        DATA.extstate.wind_w or 100,
                                        DATA.extstate.wind_h or 100,
                                        DATA.extstate.dock or 0, 
                                        DATA.extstate.wind_x or 100, 
                                        DATA.extstate.wind_y or 100)
                            end, }
      end                      
           
    
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end
  ---------------------------------------------------------------------  
  function GUI_initdata(GUI) 
    local cntdub = 0
    if DATA2.dubdata then cntdub  = #DATA2.dubdata end
    local cnt_data = cntdub + 1
    local data_h_t = DATA.GUI.custom_datah / cnt_data
    local data_h_t_mod = data_h_t -2 
    local val_data_under 
    
    -- reference data
      local layerref= 22
      local val_data,  val_data_adv , val_data_adv2
      if DATA2.refdata then
        if DATA2.refdata.data then val_data= DATA2.refdata.data  end
        if DATA2.refdata.data_points then val_data_adv= DATA2.refdata.data_points end
      end 
      if DATA2.dubdata and DATA2.dubdata[1] and DATA2.dubdata[1].stretchedarray then
        val_data_under= DATA2.dubdata[1].stretchedarray
      end 
      DATA.GUI.buttons.refdata = { x=0, -- link to GUI.buttons.getreference
                            y=0,
                            w=DATA.GUI.custom_spectralw ,
                            h=data_h_t_mod,
                            ignoremouse = true,
                            val_data = val_data,
                            val_data_adv = val_data_adv,
                            val_data_under=val_data_under,
                            layer = layerref,
                            hide = DATA.GUI.compactmode==1,
                            refresh = true,
                            frame_a = 0
                            } 
      DATA:GUIquantizeXYWH(DATA.GUI.buttons.refdata)
      if not DATA.GUI.layers[layerref] then DATA.GUI.layers[layerref] = {} end
      DATA.GUI.layers[layerref].a=1
      DATA.GUI.layers[layerref].hide = DATA.GUI.compactmode==1
      DATA.GUI.layers[layerref].layer_x = DATA.GUI.custom_offset
      DATA.GUI.layers[layerref].layer_y = DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbuth
      DATA.GUI.layers[layerref].layer_w = DATA.GUI.buttons.refdata.w+1
      DATA.GUI.layers[layerref].layer_h = DATA.GUI.custom_datah
      DATA.GUI.layers[layerref].layer_yshift = 0
    
    -- dub data
      if not DATA2.dubdata then return end
      for i = 1, 1000 do DATA.GUI.buttons['dubdata'..i] = nil end
      for i = 1, #DATA2.dubdata do
        local dubdata = DATA2.dubdata[i]
        local val_data, val_data_adv, val_data_adv2,data_pointsSRCDEST
        if dubdata.data then val_data= dubdata.data end
        if dubdata.data_points then val_data_adv= dubdata.data_points end
        if dubdata.data_points_match then val_data_adv2= dubdata.data_points_match end
        if dubdata.data_pointsSRCDEST then data_pointsSRCDEST= dubdata.data_pointsSRCDEST end
        
        DATA.GUI.buttons['dubdata'..i] = { x=0, -- link to GUI.buttons.getreference
                                  y=data_h_t*i,
                                  w=DATA.GUI.custom_spectralw ,
                                  h=data_h_t_mod,
                                  val_data = val_data,
                                  val_data_adv = val_data_adv,
                                  val_data_adv2 = val_data_adv2,
                                  val_data_com = data_pointsSRCDEST,
                                  layer = layerref,
                                  hide = DATA.GUI.compactmode==1,
                                  refresh = true,
                                  frame_a = 0,
                                  back_sela = 0,
                                  onmouseclick = function() if DATA.extstate.CONF_markgen_manualedit == 0 then return end GUI_initdata_DUBedit(DATA, 0,dubdata.data_points,DATA.GUI.buttons['dubdata'..i])  end,
                                  onmousedragR = function() if DATA.extstate.CONF_markgen_manualedit == 0 then return end GUI_initdata_DUBedit(DATA, 1,dubdata.data_points, DATA.GUI.buttons['dubdata'..i])  end,
                                  onmouserelease = function() if DATA.extstate.CONF_markgen_manualedit == 0 then return end local dubdataId = i DATA2.dubdata[dubdataId].data_points_match, DATA2.dubdata[dubdataId].data_pointsSRCDEST, DATA2.dubdata[dubdataId].stretchedarray = DATA2:ApplyMatch(DATA2.dubdata[dubdataId])GUI_initdata(DATA) end,
                                  onmousereleaseR = function() if DATA.extstate.CONF_markgen_manualedit == 0 then return end local dubdataId = i DATA2.dubdata[dubdataId].data_points_match, DATA2.dubdata[dubdataId].data_pointsSRCDEST, DATA2.dubdata[dubdataId].stretchedarray = DATA2:ApplyMatch(DATA2.dubdata[dubdataId]) GUI_initdata(DATA) end
                                  
                                  }  
      end
      
    
      
  end
  ---------------------------------------------------------------------  
  function GUI_initdata_DUBedit(DATA, mode, pointst, b) 
    if not pointst then return end
    if mode==0 then -- L click
      local block = math.floor(#pointst * (DATA.GUI.x-b.x) / (b.w-b.x))
      pointst[block] = 1
    end 
    
    if mode==1 then -- R drag
      local block = math.floor(#pointst * (DATA.GUI.x-b.x) / (b.w-b.x))
      pointst[block] = 0
      if pointst[block-1] then pointst[block-1] = 0 end
      if pointst[block-1] then pointst[block+1] = 0 end
    end
    
  end
  ---------------------------------------------------------------------  
  function DATA2:ProcessAtChange(DATA)
    if DATA.extstate.UI_appatchange&1==1 then 
      DATA2:GetRefAudioData()
      DATA2:GetDubAudioData(true)
    end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)
    local BandSplitterFreq_res = 0.05
    local readoutw_extw = 150
    --
    
    -- get pitch shift mode
      pitch_shift_t = {}
      pitch_shift_t[-1] = '[default]'
      for mode=0, 32 do
        local retval, modename = reaper.EnumPitchShiftModes( mode )
        if retval and modename and modename ~= '' then pitch_shift_t[mode] = modename   end
      end
      
    -- get pitch shift sub mode
      local pitch_shift_tsub = {}
      pitch_shift_tsub[-1] = '[default]'
      local mode = 0
      if DATA.extstate.CONF_post_pshift >=0 then mode = DATA.extstate.CONF_post_pshift end
      for submode=0, 32 do
        local modename = EnumPitchShiftSubModes( mode, submode )
        if modename and modename ~= '' then pitch_shift_tsub[submode] = modename end
      end   
      
    -- form sm mod table
      local smmode = { 
        [0] = 'default',      
        [1] = 'Balanced',      
        [2] = 'Tonal optimized',
        [4] = 'Transient optimized',
        [5] = 'No pre echo reduction'}
        
    local  t = 
    { 
      {str = 'Global' ,                                   group = 1, itype = 'sep'},
        {str = 'Get reference take at initialization' ,   group = 1, itype = 'check', confkey = 'CONF_initflags', confkeybyte=1, level = 1, tooltip='Get reference take at initialization'},
        {str = 'Get dub take at initialization' ,         group = 1, itype = 'check', confkey = 'CONF_initflags', confkeybyte=2, level = 1, tooltip='Get dub take at initialization'},
        {str = 'Clean dub markers at initialization' ,    group = 1, itype = 'check', confkey = 'CONF_cleanmarkdub', level = 1, tooltip='Clean dub markers at initialization'},
        {str = 'Obey time selection' ,                    group = 1, itype = 'check', confkey = 'CONF_obtimesel', level = 1},
        {str = 'Align takes inside item' ,                group = 1, itype = 'check', confkey = 'CONF_alignitemtakes', level = 1},
        {str = 'Skip empty audio takes' ,                group = 1, itype = 'check', confkey = 'CONF_ignoreemptytakes', level = 1},
        {str = 'Use maximul amplitude values from all takes as ref' ,                group = 1, itype = 'check', confkey = 'CONF_buildrefasmaximums', level = 1, tooltip='Use maximul amplitude values from all takes as ref'},
        
      {str = 'Audio data' ,                               group = 2, itype = 'sep'},  
        {str = 'BandSplitter Freq 1' ,                    group = 2, itype = 'readout', confkey = 'CONF_audio_bs_f1', level = 1, val_min = 20, val_max = DATA.extstate.CONF_audio_bs_f2,                                  val_res = BandSplitterFreq_res, val_format = function(x) return math.floor(x)..'Hz' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'BandSplitter Freq 2' ,                    group = 2, itype = 'readout', confkey = 'CONF_audio_bs_f2', level = 1, val_min = DATA.extstate.CONF_audio_bs_f1, val_max = DATA.extstate.CONF_audio_bs_f3,      val_res = BandSplitterFreq_res, val_format = function(x) return math.floor(x)..'Hz' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'BandSplitter Freq 3' ,                    group = 2, itype = 'readout', confkey = 'CONF_audio_bs_f3', level = 1, val_min = DATA.extstate.CONF_audio_bs_f2, val_max = 10000,                               val_res = BandSplitterFreq_res, val_format = function(x) return math.floor(x)..'Hz' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'BandSplitter Band 1' ,                    group = 2, itype = 'readout', confkey = 'CONF_audio_bs_a1', level = 1, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'BandSplitter Band 2' ,                    group = 2, itype = 'readout', confkey = 'CONF_audio_bs_a2', level = 1, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'BandSplitter Band 3' ,                    group = 2, itype = 'readout', confkey = 'CONF_audio_bs_a3', level = 1, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'BandSplitter Band 4' ,                    group = 2, itype = 'readout', confkey = 'CONF_audio_bs_a4', level = 1, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Gate' ,                                   group = 2, itype = 'readout', confkey = 'CONF_audio_gate', level = 1, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
        {str = 'Limit' ,                                  group = 2, itype = 'readout', confkey = 'CONF_audio_lim', level = 1, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end},
      
      {str = 'Peak follower' ,                            group = 3, itype = 'sep'}, 
        {str = 'Window' ,                                 group = 3, itype = 'readout', confkey = 'CONF_window', level = 1, val_min = 0.005, val_max = 0.4, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,3)..'s' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,tooltip='Time of audio block for read'},
        {str = 'Overlap divider' ,                        group = 3, itype = 'readout', confkey = 'CONF_window_overlap', level = 1, menu = { [1]='[window]', [2]='2x', [4]='4x', [8]='8x' },tooltip='Overlap window block back for a window time divided by this coefficient',func_onrelease = function() DATA2:ProcessAtChange(DATA) end, }, 
        {str = 'val^y (scaling)' ,                        group = 3, itype = 'readout', confkey = 'CONF_audiodosquareroot', level = 1, val_min = 0.1, val_max = 2, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,3) end, func_onrelease = function() DATA2:ProcessAtChange(DATA) end}, 
        {str = 'Smooth envelope' ,                        group = 3, itype = 'readout', confkey = 'CONF_smooth', level = 1, menu = { [0]='[none]', [1]='1x',  [2]='2x', [4]='4x', [8]='8x' }, func_onrelease = function() DATA2:ProcessAtChange(DATA) end}, 
        {str = 'Compensate overlap / Reduce points' ,     group = 3, itype = 'check', confkey = 'CONF_compensateoverlap', level = 1, tooltip='When doing overlap it multiply count of points. This check compensate it'},
      
      {str = 'Source markers generator' ,                 group = 4, itype = 'sep'}, 
        {str = 'Allow manual editing' ,                   group = 4, itype = 'check', confkey = 'CONF_markgen_manualedit', level = 1},
        {str = 'Algorithm 1 (slow rise/fall detect)' ,    group = 4, itype = 'check', confkey = 'CONF_markgen_algo', level = 1, isset = 0, tooltip='Trigger points for relative rises/falls at defined area by some RMS-per-block change'},
          {str = 'Set at envelope fall' ,                 group = 4, itype = 'check', confkey = 'CONF_markgen_enveloperisefall', level = 2, confkeybyte = 1, hide = DATA.extstate.CONF_markgen_algo~=0},
          {str = 'Set at envelope rise' ,                 group = 4, itype = 'check', confkey = 'CONF_markgen_enveloperisefall', level = 2, confkeybyte = 2, hide = DATA.extstate.CONF_markgen_algo~=0},
          {str = 'Minimum points distance' ,              group = 4, itype = 'readout', confkey = 'CONF_markgen_filterpoints', level = 2, val_min = 5, val_max = 50, val_res = 0.05, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide = DATA.extstate.CONF_markgen_algo~=0,
                                                          val_isinteger = true,
                                                          val_format = function(x) return x*DATA.extstate.CONF_window..'s' end,
                                                          val_format_rev = function(x) x = x:match('[%d%.]+') if not x then return end return math.floor(tonumber(x)/DATA.extstate.CONF_window) end},
          {str = 'area_RMS length' ,                      group = 4, itype = 'readout', confkey = 'CONF_markgen_RMSpoints', level = 2, val_min = 5, val_max = 30, val_res = 0.05, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide = DATA.extstate.CONF_markgen_algo~=0,
                                                          val_isinteger = true,
                                                          val_format = function(x) return VF_math_Qdec(x*DATA.extstate.CONF_window,3)..'s' end,
                                                          val_format_rev = function(x) x = x:match('[%d%.]+') if not x then return end return math.floor(tonumber(x)/DATA.extstate.CONF_window) end},
          {str = 'minimum of [value/abs(area_RMS-value)]',group = 4, itype = 'readout', confkey = 'CONF_markgen_minimalareaRMS', level = 2, val_min = 0, val_max =0.7, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide = DATA.extstate.CONF_markgen_algo~=0,},                                                
          {str = 'Level threshold',                       group = 4, itype = 'readout', confkey = 'CONF_markgen_threshold', level = 2, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide = DATA.extstate.CONF_markgen_algo~=0,},                                                
        {str = 'Algorithm 2 (gate trigger)' ,             group = 4, itype = 'check', confkey = 'CONF_markgen_algo', level = 1, isset = 1, tooltip='Trigger points at gate open/close'},
          {str = 'Minimum points distance' ,              group = 4, itype = 'readout', confkey = 'CONF_markgen_filterpoints2', level = 2, val_min = 5, val_max = 50, val_res = 0.05, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide = DATA.extstate.CONF_markgen_algo~=1,
                                                          val_isinteger = true,
                                                          val_format = function(x) return VF_math_Qdec(x*DATA.extstate.CONF_window,3)..'s' end,
                                                          val_format_rev = function(x) x = x:match('[%d%.]+') if not x then return end return math.floor(tonumber(x)/DATA.extstate.CONF_window) end},
          {str = 'Trigger threshold',                     group = 4, itype = 'readout', confkey = 'CONF_markgen_threshold2', level = 2, val_res = 0.05, ispercentvalue = true, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide = DATA.extstate.CONF_markgen_algo~=1,},           
        {str = 'Algorithm 3 (equal distance)' ,           group = 4, itype = 'check', confkey = 'CONF_markgen_algo', level = 1, isset = 2},
          {str = 'Points distance' ,                      group = 4, itype = 'readout', confkey = 'CONF_markgen_filterpoints3', level = 2, val_min = 5, val_max = 100, val_res = 0.05, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, hide = DATA.extstate.CONF_markgen_algo~=2,
                                                          val_isinteger = true,
                                                          val_format = function(x) return VF_math_Qdec(x*DATA.extstate.CONF_window,3)..'s' end,
                                                          val_format_rev = function(x) x = x:match('[%d%.]+') if not x then return end return math.floor(tonumber(x)/DATA.extstate.CONF_window) end},        
        
      {str = 'Audio match algorithm' ,                    group = 6, itype = 'sep'},  
          {str = 'Brutforce search area' ,                group = 6, itype = 'readout', confkey = 'CONF_markgen_filterpoints3', level = 2, val_min = 3, val_max = 100, val_res = 0.05, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, tooltip='Maximum deviation of source markers',
                                                          val_isinteger = true,
                                                          val_format = function(x) return VF_math_Qdec(x*DATA.extstate.CONF_window,3)..'s' end,
                                                          val_format_rev = function(x) x = x:match('[%d%.]+') if not x then return end return math.floor(tonumber(x)/DATA.extstate.CONF_window) end},           
          {str = 'Stretch dub array on the fly' ,         group = 6, itype = 'check', confkey = 'CONF_match_stretchdubarray', level = 1},
          {str = 'Ignore zero values difference check' ,  group = 6, itype = 'check', confkey = 'CONF_match_ignorezeros', level = 1},
          {str = 'Search forward only' ,                  group = 6, itype = 'check', confkey = 'CONF_match_searchfurtheronly', level = 1},
          {str = 'Compare until midblock' ,               group = 6, itype = 'check', confkey = 'CONF_match_firstsrgmonly', level = 1},
          {str = 'Minimum block search start offset' ,    group = 6, itype = 'readout', confkey = 'CONF_match_minblocksstartoffs', level = 1, val_min =0, val_max = 30, val_res = 0.05, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, tooltip='Minimum between comparing block start poind and movable midpoint',
                                                          val_isinteger = true,
                                                          val_format = function(x) return VF_math_Qdec(x*DATA.extstate.CONF_window,3)..'s' end,
                                                          val_format_rev = function(x) x = x:match('[%d%.]+') if not x then return end return math.floor(tonumber(x)/DATA.extstate.CONF_window) end},             
          {str = 'Minimum block search end offset' ,      group = 6, itype = 'readout', confkey = 'CONF_match_maxblocksstartoffs', level = 1, val_min =0, val_max = 30, val_res = 0.05, func_onrelease = function() DATA2:ProcessAtChange(DATA) end, tooltip='Minimum between comparing block end poind and movable midpoint',
                                                          val_isinteger = true,
                                                          val_format = function(x) return VF_math_Qdec(x*DATA.extstate.CONF_window,3)..'s' end,
                                                          val_format_rev = function(x) x = x:match('[%d%.]+') if not x then return end return math.floor(tonumber(x)/DATA.extstate.CONF_window) end},   
                                                          
      {str = 'Take output' ,                              group = 7, itype = 'sep'}, 
        {str = 'Pitch shift mode' ,                       group = 7, itype = 'readout', confkey = 'CONF_post_pshift', readoutw_extw = readoutw_extw, level = 1, menu = pitch_shift_t, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,}, 
        {str = 'Pitch shift submode' ,                    group = 7, itype = 'readout', confkey = 'CONF_post_pshiftsub', readoutw_extw = readoutw_extw, level = 1, menu = pitch_shift_tsub, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,},  
        {str = 'Stretch marker mode' ,                    group = 7, itype = 'readout', confkey = 'CONF_post_smmode', readoutw_extw = readoutw_extw, level = 1, menu = smmode, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,},  
        {str = 'Stretch marker fade size' ,               group = 7, itype = 'readout', confkey = 'CONF_post_strmarkfdsize', level = 1, val_min = 0.0025, val_max =0.05, val_res = 0.05, val_format = function(x) return VF_math_Qdec(x,4)..'s' end, val_format_rev = function(x) return tonumber(x:match('[%d%.]+')) end, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,},
        {str = 'Quantize to zero crossings' ,             group = 7, itype = 'check', confkey = 'CONF_post_zerocross', level = 1, func_onrelease = function() DATA2:ProcessAtChange(DATA) end,},
        
        
      {str = 'UI options' ,                               group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,                       group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse position' ,              group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        {str = 'Show tootips' ,                           group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Process on settings change',              group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        
      
    } 
    return t
    
  end
  ---------------------------------------------------------------------
  function DATA2:GetAudioData_BandSplit(buf, srate) -- 4-Band Splitter ported from JSFX -- desc:4-Band Splitter
    local sz = #buf--.get_alloc()
    local extstate = DATA.extstate or {}
    
    -- frequency 
    local slider1 = extstate.CONF_audio_bs_f1 or 200
    local slider2 = extstate.CONF_audio_bs_f2 or 2000
    local slider3 = extstate.CONF_audio_bs_f3 or 5000
    
    -- init
    local cDenorm=10^-30;
    
    local freqHI = math.max(math.min(slider3,srate),slider2);
    local xHI = math.exp(-2.0*math.pi*freqHI/srate);
    local a0HI = 1.0-xHI;
    local b1HI = -xHI;
    
    local freqMID = math.max(math.min(math.min(slider2,srate),slider3),slider1);
    local xMID = math.exp(-2.0*math.pi*freqMID/srate);
    local a0MID = 1.0-xMID;
    local b1MID = -xMID;
    
    local freqLOW = math.min(math.min(slider1,srate),slider2);
    local xLOW = math.exp(-2.0*math.pi*freqLOW/srate);
    local a0LOW = 1.0-xLOW;
    local b1LOW = -xLOW;
    
    local tmplMID = 0
    local tmplLOW = 0
    local tmplHI = 0 
    local low0,hi0,spl0,spl2,spl4,spl6, s0
    
    for i = 1, sz do  
      s0 = buf[i]; 
      
      tmplMID = a0MID*s0 - b1MID*tmplMID + cDenorm
      low0 = tmplMID; 
      tmplLOW = a0LOW*low0 - b1LOW*tmplLOW + cDenorm
      spl0 = tmplLOW; -- band1 
      spl2 = low0 - spl0; -- band2 
      hi0 = s0 - low0; 
      tmplHI = a0HI*hi0 - b1HI*tmplHI + cDenorm
      spl4 = tmplHI; -- band3 
      spl6 = hi0 - spl4; -- band4
      
      local bandsum = 
        math.abs(spl0) * extstate.CONF_audio_bs_a1 + 
        math.abs(spl2) * extstate.CONF_audio_bs_a2 + 
        math.abs(spl4) * extstate.CONF_audio_bs_a3 + 
        math.abs(spl6) * extstate.CONF_audio_bs_a4
      buf[i] = bandsum
      
    end
    
  end
  --------------------------------------------------------------------  
  function DATA2:GetAudioData_GetTable2(parent_track, edge_start, edge_end, take, item, tkoffs, take_rate) 
  
    -- init 
      local data = {}
      local accessor 
      local FFTsz = 512
      local window_spls = FFTsz*2
      local SR = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      if take then 
        accessor = CreateTakeAudioAccessor( take )
        edge_end = edge_end - edge_start -- tkoffs*take_rate
        edge_start = 0
        local pcm_src  =  GetMediaItemTake_Source( take )
        local SR = reaper.GetMediaSourceSampleRate( pcm_src ) 
       else
        accessor = CreateTrackAudioAccessor( parent_track ) 
      end
      
      local window = window_spls / SR
      DATA.extstate.CONF_window = window
      local samplebuffer = reaper.new_array(window_spls) 
      local t = {}
      local id = 0
    
      local buft = {}
      local buftid = 0
      for pos_seek = edge_start, edge_end, window do
          local pos_seek0 = pos_seek 
          local rms = 0
          local rmscnt = 0
          reaper.GetAudioAccessorSamples( accessor, SR, 1, pos_seek, window_spls, samplebuffer ) 
          samplebuffer.fft_real(FFTsz, true, 1 )
          local sum = 0
          local rms = 0
          local rmsid = 0
          local prev_Re = 0
          local prev_Im = 0 
          buftid =buftid + 1
          buft[buftid] = {}
          local bin2 = -1
          for bin = 1, FFTsz/2 do 
            bin2 = bin2 + 2
            local Re = samplebuffer[bin2]
            local Im = samplebuffer[bin2 + 1]
            local magnitude = math.sqrt(Re^2 + Im^2)
            rms = rms + magnitude
            rmscnt = rmscnt + 1
            local phase = math.atan(Im, Re)
            buft[buftid][bin] = {magnitude=magnitude,phase=phase}
          end
          buft[buftid].rms = rms / rmscnt
      end
    
    samplebuffer.clear( )
    reaper.DestroyAudioAccessor( accessor )
    local t = DATA2:GetComplexDomainOnsetEnvelope_GetDifference(buft) 
    local rms, peak = DATA2:GetRMSPeakRatio(t)
    --VF2_NormalizeT(t)
    
    local max_val = 0
    for i = 1, #t do t[i] = math.abs(t[i]) max_val = math.max(max_val, t[i]) end -- abs all values
    --[[for i = 1, #t do t[i] = math.min(DATA.extstate.CONF_audio_lim, t[i] /DATA.extstate.CONF_audio_lim) end -- limit 
    for i = 1, #t do t[i] = (t[i]/max_val) ^DATA.extstate.CONF_audiodosquareroot end -- normalize  / scale
    
    
    local lastval = 0
    for smooth = 1, DATA.extstate.CONF_smooth do
      for i = 1, #t do  
        t[i] = (lastval + t[i] ) /2
        lastval = t[i]
      end
    end]]
    
    return t,peak
  end
  --------------------------------------------------------------------  
  function DATA2:GetRMSPeakRatio(t) 
    local rms = 0 
    local peak = 0
    local sz = #t
    local val
    for  i = 1,sz do
      val = t[i]
      rms = rms + val
      peak = math.max(peak, val)
    end
    rms = rms / sz
    return rms, peak
  end
  --------------------------------------------------------------------  
  function DATA2:GetComplexDomainOnsetEnvelope_GetDifference(buft)  -- buft is after fft real
    local out_t = {}
    
    for frame = 3, #buft do
      local t = buft[frame]
      local t_prev = buft[frame-1]
      local t_prev2 = buft[frame-2]
      local sz = #t
      local sum = 0
      local Euclidean_distance, Im1, Im2, Re1, Re2
      local hp = 1--math.floor(sz*0.02)
      local lp = sz - math.floor(sz*0.1)
      for bin = hp, lp do
        magnitude_targ = t_prev[bin].magnitude
        phase_targ = t_prev[bin].phase + (t_prev[bin].phase - t_prev2[bin].phase)
        
        Re2 = magnitude_targ * math.cos(phase_targ);
        Im2 = magnitude_targ * math.sin(phase_targ);
        
        Re1 = t[bin].magnitude * math.cos(t[bin].phase);
        Im1 = t[bin].magnitude * math.sin(t[bin].phase);
                
        Euclidean_distance = math.sqrt((Re2 - Re1)^2 + (Im2 - Im1)^2)
        sum = sum + Euclidean_distance *(1-bin/sz) -- weight to highs
      end
      
      out_t[frame] = sum * buft[frame].rms
    end
    out_t[1] =out_t[3]
    out_t[2] = out_t[3]
    return out_t
  end
  ---------------------------------------------------------------------
  function DATA2:GetAudioData_GetTable(parent_track, edge_start, edge_end, take, item, tkoffs, take_rate) 
    -- init 
      local accessor 
      if take then 
        accessor = CreateTakeAudioAccessor( take )
        edge_end = edge_end - edge_start -- tkoffs*take_rate
        edge_start = 0
       else
        accessor = CreateTrackAudioAccessor( parent_track )
      end
      local data = {}
      local id = 0
      local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      local window_sec = DATA.extstate.CONF_window
      local bufsz = math.ceil(window_sec * SR_spls)
    -- loop stuff 
      local overlap = DATA.extstate.CONF_window_overlap
      for pos = edge_start, edge_end, window_sec/overlap do 
        local samplebuffer = new_array(bufsz);
        GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
        local samplebuffer_t = samplebuffer.table()
        samplebuffer.clear()
        DATA2:GetAudioData_BandSplit(samplebuffer_t, SR_spls)
        local sum = 0 
        for i = 1, bufsz do 
          local val = math.abs(samplebuffer_t[i]) 
          if val < DATA.extstate.CONF_audio_gate then val  = 0 end
          sum = sum + val 
        end
        
        id = id + 1
        data[id] = sum / bufsz
      end
      DestroyAudioAccessor( accessor )
      
      local max_val = 0
      for i = 1, #data do data[i] = math.abs(data[i]) max_val = math.max(max_val, data[i]) end -- abs all values
      for i = 1, #data do data[i] = math.min(DATA.extstate.CONF_audio_lim, data[i] /DATA.extstate.CONF_audio_lim) end -- limit 
      for i = 1, #data do data[i] = (data[i]/max_val) ^DATA.extstate.CONF_audiodosquareroot end -- normalize  / scale
      
      
      local lastval = 0
      for smooth = 1, DATA.extstate.CONF_smooth do
        for i = 1, #data do  
          data[i] = (lastval + data[i] ) /2
          lastval = data[i]
        end
      end
      
      local reduceddata = {}
      for i = 1, #data do if i%overlap == 1 then reduceddata[#reduceddata+1] = data[i] end end
      if DATA.extstate.CONF_compensateoverlap==1 and overlap ~= 1 then return reduceddata, max_val else return data, max_val end
  end 
 ---------------------------------------------------------------------
  function DATA2:CleanDubMarkers2(take, takerate, edge_start,edge_end) 
    if not take then return end
    local approx = 10^-12
    for idx =  GetTakeNumStretchMarkers( take ), 1, -1 do
      local retval, pos, srcpos = GetTakeStretchMarker( take, idx-1 )
      if pos>edge_start-approx and pos< edge_end+approx then DeleteTakeStretchMarkers( take, idx-1 ) end
    end
    SetTakeStretchMarker( take, -1, edge_start*takerate)
    SetTakeStretchMarker( take, -1, edge_end*takerate )
    UpdateItemInProject(  reaper.GetMediaItemTake_Item( take ) )
  end
  ---------------------------------------------------------------------
  function DATA2:GetDubAudioData_Sub(item,take)
    local dubdataId = #DATA2.dubdata+1
    local parent_track = GetMediaItem_Track( item ) 
    local takeGUID = VF_GetTakeGUID(take)
    local take_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE')
    local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local item_len= GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local src =  GetMediaItemTake_Source( take )
    local tkoffs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS'  )
    local item_srclen, lengthIsQN = GetMediaSourceLength( src )
    if DATA.extstate.CONF_cleanmarkdub&1==1 and DATA2.refdata and DATA2.refdata.edge_start  then  DATA2:CleanDubMarkers2(take,  take_rate, math.max(0,DATA2.refdata.edge_start - item_pos),math.min(item_len ,DATA2.refdata.edge_end - item_pos))  end--and DATA.extstate.CONF_markgen_algo ~= 3
    DATA2.dubdata[dubdataId] = {takeGUID = takeGUID,
                      take = take,
                      item = item,
                      item_pos = item_pos,
                      item_len=item_len,
                      take_rate = take_rate,
                      item_srclen=item_srclen,
                      take_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS')
                      }
                      
    local take_src, item_src
    if DATA.extstate.CONF_alignitemtakes == 1 then take_src = take item_src = item end
    DATA2.dubdata[dubdataId].data,max_val = DATA2:GetAudioData_GetTable(parent_track, DATA2.refdata.edge_start, DATA2.refdata.edge_end, take_src, item_src, tkoffs, take_rate) 
    if DATA.extstate.CONF_ignoreemptytakes == 1 and max_val < 0.05 then DATA2.dubdata[dubdataId] = nil return end 
    DATA2.dubdata[dubdataId].data = DATA2:GetAudioData_CorrentSource(DATA2.dubdata[dubdataId].data, DATA2.refdata.edge_start, DATA2.refdata.edge_end, item_pos, item_pos+item_len)
    if DATA.extstate.CONF_buildrefasmaximums == 1 then DATA2:GetAudioData_ForceTakeMaxReference() end
    if DATA.extstate.CONF_markgen_algo == 0  then DATA2.dubdata[dubdataId].data_points = DATA2:GeneratePoints_0(DATA2.dubdata[dubdataId].data) end -- legacy v1
    if DATA.extstate.CONF_markgen_algo == 1  then DATA2.dubdata[dubdataId].data_points = DATA2:GeneratePoints_1(DATA2.dubdata[dubdataId].data) end -- gate
    if DATA.extstate.CONF_markgen_algo == 2  then DATA2.dubdata[dubdataId].data_points = DATA2:GeneratePoints_2(DATA2.dubdata[dubdataId].data) end -- equal
    if DATA.extstate.CONF_markgen_algo == 3  then DATA2.dubdata[dubdataId].data_points = DATA2:GeneratePoints_3(take) end -- get stretch markers
    DATA2.dubdata[dubdataId].data_points_match, DATA2.dubdata[dubdataId].data_pointsSRCDEST, DATA2.dubdata[dubdataId].stretchedarray = DATA2:ApplyMatch(DATA2.dubdata[dubdataId]) 
  end
  ---------------------------------------------------------------------
  function DATA2:GetAudioData_ForceTakeMaxReference()
    for i =1, #DATA2.refdata.data do
      local max = DATA2.refdata.data[i]
      for dubdataId = 1, #DATA2.dubdata do
        max = math.max(max, DATA2.dubdata[dubdataId].data[i])
      end
      DATA2.refdata.data[i] = max
    end
  end
  ---------------------------------------------------------------------
  function DATA2:GetDubAudioData(takefromsecondtake)
    if not DATA2.refdata then return end
    local reftrack = VF_GetTrackByGUID(DATA2.refdata.parent_trackGUID) 
    if not reftrack then return end
    DATA2.dubdata = {}
    
    if DATA.extstate.CONF_alignitemtakes == 0 then -- normal mode
      local st = 1
      if takefromsecondtake == true then st = 2 end
      for i = st, CountSelectedMediaItems( 0 ) do
        local item = GetSelectedMediaItem(0,i-1)
        local parent_track = GetMediaItem_Track( item ) 
        local take = GetActiveTake(item) 
        if not take or (take and TakeIsMIDI(take)) then  goto skipnextdub end  
        if parent_track == reftrack then goto skipnextdub end  
        DATA2:GetDubAudioData_Sub(item,take) 
        ::skipnextdub::
      end
    end
    
    if DATA.extstate.CONF_alignitemtakes == 1 then -- per item  mode
      local item = GetSelectedMediaItem(0,0)
      if item then
        local acttake = GetActiveTake(item) 
        for takeidx = 1,  CountTakes( item ) do
          local take =  GetTake( item, takeidx-1 )
          if not take or (take and TakeIsMIDI(take)) or (take and take == acttake) then goto skipnextdub end  
          DATA2:GetDubAudioData_Sub(item,take) 
          ::skipnextdub::
        end
      end
    end
    
    GUI_initdata(GUI) 
  end
  ---------------------------------------------------------------------
  function DATA2:GetAudioData_CorrentSource(t, edge_start, edge_end, item_pos, item_end)
    local ovlap = DATA.extstate.CONF_window_overlap
    if DATA.extstate.CONF_compensateoverlap==1 and overlap ~= 1 then ovlap = 1 end
    local sz = #t
    local blockms =  DATA.extstate.CONF_window/ovlap
    local blockdestroy_start = -1
    local blockdestroy_end =sz+1
    if item_pos> edge_start then blockdestroy_start = (item_pos - edge_start) / blockms end
    if item_end< edge_end then blockdestroy_end = sz - (edge_end - item_end) / blockms end
    for i = 1, sz do 
      if i < blockdestroy_start then t[i] = 0 end
      if i > blockdestroy_end then t[i] = 0 end
    end
    return t
  end
  ---------------------------------------------------------------------
  function DATA2:GetRefAudioData()
    local parent_track 
    local edge_start,edge_end = math.huge, 0
    for i = 1, CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem(0,i-1)
      local take = GetActiveTake(item)
      if not take or TakeIsMIDI(take) then goto skipnextref end 
      local track = GetMediaItem_Track( item ) 
      if not parent_track then parent_track = track end
      if parent_track and parent_track ==  track then
        local pos =  reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
        local len =  reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
        edge_start = math.min(pos,edge_start)
        edge_end = math.max(pos+len,edge_end)
      end
      ::skipnextref::
    end
    
    if DATA.extstate.CONF_obtimesel == 1 then edge_start,edge_end = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false ) end
    if not parent_track or edge_start > edge_end then return end 
    
    if edge_end - edge_start > 20 then 
      local ret = MB('Analyzing can take long time, proceed anyway?', 'Align Takes', 3)
      if ret ~= 6 then return end
    end
    
    DATA2.refdata = {}
    DATA2.refdata.data = DATA2:GetAudioData_GetTable(parent_track, edge_start, edge_end)
    DATA2.refdata.parent_trackGUID = GetTrackGUID(parent_track)
    DATA2.refdata.edge_start = edge_start
    DATA2.refdata.edge_end = edge_end
    
    GUI_initdata(GUI)
    
  end
  ---------------------------------------------------------------------
  function DATA2:GeneratePoints_3(take)
    --DATA2.refdata.edge_start, DATA2.refdata.edge_end
    --reaper.GetTakeNumStretchMarkers( take )
    --retval, pos, srcpos = reaper.GetTakeStretchMarker( take, idx )
  end
  ---------------------------------------------------------------------
  function DATA2:GeneratePoints_2(t0)
    local t = {}
    local block_area = DATA.extstate.CONF_markgen_filterpoints3
    -- get src points
      for i = 1,#t0 do 
        t[i] = 0
        if i%block_area == 0 then  t[i] = 1  end
      end
      t[1] = 1
      t[#t] = 1
      
      for i = 3, #t do if t[i] == 1 then t[math.floor(i/2)] = 1 break end end -- create mdi point between 1nd and 2nd blocks
      
    return t
  end
  ---------------------------------------------------------------------
  function DATA2:GeneratePoints_1(t0)
    local t = {}
    local block_area = DATA.extstate.CONF_markgen_filterpoints2
    local threshold = DATA.extstate.CONF_markgen_threshold2
    local lastgateid
    -- get src points
      for i = 2,#t0 -1 do 
        t[i] = 0
        local curr_val = t0[i]
        gate = curr_val > threshold
        local trig 
        if lastgate == false and gate == true then trig = true end
        if trig then 
          if not lastgateid or (lastgateid and i-lastgateid > block_area) then
            t[i] = 1 
          end
          lastgateid =i
        end
        lastgate = gate
      end
      t[1] = 1
      t[#t] = 1
      
      for i = 3, #t do if t[i] == 1 then t[math.floor(i/2)] = 1 break end end  -- create mdi point between 1nd and 2nd blocks
      
    return t
  end
  ---------------------------------------------------------------------
  function DATA2:GeneratePoints_0(t0)
    local t = {}
    local block_area = DATA.extstate.CONF_markgen_filterpoints 
    local block_RMSarea = DATA.extstate.CONF_markgen_RMSpoints 
    -- get src points
      for i = 1,#t0 do 
        t[i] = 0
        local prev_val = t0[i-1]
        local curr_val = t0[i]
        local next_val = t0[i+1]
        if prev_val and next_val and (   (DATA.extstate.CONF_markgen_enveloperisefall==1 and curr_val<prev_val and next_val>curr_val)  or  (DATA.extstate.CONF_markgen_enveloperisefall==2 and curr_val>prev_val and next_val<curr_val)    ) then t[i] = 1 end
      end
    
    -- filter closer points
      local last_pointID = 0
      for i = 1, #t do
        if t[i] == 1 then
          local last_pointID_fol = i
          if i - last_pointID < block_area then 
            if t0[i] and t0[last_pointID] then 
              if (t0[i] < t0[last_pointID] and DATA.extstate.CONF_markgen_enveloperisefall==1) or (t0[i] > t0[last_pointID] and DATA.extstate.CONF_markgen_enveloperisefall==2) then 
                t[last_pointID] = 0 
                last_pointID_fol = i
               else
                t[i] = 0 
                last_pointID_fol = last_pointID
              end  
            end
          end
          last_pointID = last_pointID_fol
        end
      end
    
    -- how deep/high point in block_area
    for i = 1, #t do
      if t[i] == 1 then
        local rms = 0
        local cnt = 0
        local min_area = i-block_RMSarea
        local max_area = i+block_RMSarea
        for j = min_area,max_area do
          if t0[j] then 
            cnt = cnt + 1
            rms = rms + t0[j]
          end 
        end
        rms = rms / cnt
        local extremum_diff_ratio = t0[i] / math.abs(rms - t0[i]) 
        if t0[i] > math.abs(rms - t0[i]) then extremum_diff_ratio = math.abs(rms - t0[i]) / t0[i] end
        if extremum_diff_ratio < DATA.extstate.CONF_markgen_minimalareaRMS then t[i] = 0 end
      end
    end
    
    -- level filter
    for i = 1, #t do
      if t[i] == 1 then    
        if t0[i] > DATA.extstate.CONF_markgen_threshold then t[i] = 0 end
      end
    end
    
    t[1] = 1
    t[#t] = 1
    
    for i = 3, #t do if t[i] == 1 then t[math.floor(i/2)] = 1 break end end  -- create mdi point between 1nd and 2nd blocks
    
    return t
  end    
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch_GetTableDifference(t1,t2,block_st,block_end, block_src, midblock) 
    local diff = 0 
    local block_end0 = block_end
    if DATA.extstate.CONF_match_firstsrgmonly == 1 then 
      block_end0 = midblock
    end
    for block = block_st, block_end0 do  
      if t1[block] and t2 and t2[block] then
        if DATA.extstate.CONF_match_ignorezeros == 1 or (DATA.extstate.CONF_match_ignorezeros == 0 and t1[block] ~= 0 and t2[block] ~= 0) then
          diff = diff + math.abs(t1[block]-t2[block]) 
        end
      end
    end 
    return diff 
  end
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch_Find(t1,t2,block_st,block_src,block_end)
    
    if not (block_st and block_src and block_end and block_st ~= 1) then return block_src end
    local block_search = DATA.extstate.CONF_match_blockarea
    
    -- init edges for searches
      local offs =DATA.extstate.CONF_match_minblocksstartoffs
      local offs2 =DATA.extstate.CONF_match_maxblocksstartoffs
      local block_mid_search_min = math.max(block_st+offs, block_src - block_search)
      if DATA.extstate.CONF_match_searchfurtheronly == 1  then block_mid_search_min = block_src end
      local block_mid_search_max = math.min(block_end - 1 - offs2, block_src + block_search) 
    
    -- loop through difference block
      local refdub_diffence = math.huge
      local bestblock
      for midblock = block_mid_search_min, block_mid_search_max do
        local t2_stretched = DATA2:ApplyMatch_StretchT(t2, block_st, block_end, block_src, midblock) 
        local tablediff = DATA2:ApplyMatch_GetTableDifference(t1,t2_stretched,block_st,block_end, block_src, midblock)
        if tablediff < refdub_diffence then
          bestblock = midblock
          refdub_diffence = tablediff
        end
      end
    
    if bestblock then return bestblock else return block_src end
  end
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch_StretchT(t, block_st, block_end, block_src, block_dest) 
    local tout = {}
    if not (t and block_st) then return end
    local ratio1 = (block_src - block_st) / (block_dest - block_st)
    local ratio2 = (block_end - block_src) / (block_end - block_dest)
    for i = 1, block_st-1 do tout[i] = t[i] end for i = block_end+1, #t do tout[i] = t[i] end -- copy src table
    for i = block_st, block_end do
      if i <= block_dest then
        local stri = math.min(math.floor(block_st + (i-block_st)*ratio1), block_src)
        tout[i] = t[stri] 
       else
        local stri = block_src + math.floor((i-block_dest+1)*ratio2 )
        tout[i] = t[stri] 
      end
    end 
    
    
    return tout
  end
  ---------------------------------------------------------------------
  function DATA2:ApplyMatch(t)
    if not t.data_points then return end
    local t_out = {}
    local t1 = DATA2.refdata.data
    local t2 = t.data
    local t2pts = t.data_points
    -- collect src point
    local pointsID = {}
    for i = 1, #t2pts do if t2pts[i] == 1 then pointsID[#pointsID+1] = i end end
    pointsID[#pointsID+1] = #t2pts 
    --if #pointsID>3 then  table.insert(pointsID, 1 , math.floor(pointsID[2]/2)) end
    local pointsID2 = { --[1]     = {src= 1, dest = 1} -- create edges
                        --[t_out] = {src= 1, dest = 1}
                        }
    
    
    for i = 1, #pointsID-1 do
      local block_st = pointsID[i-1]
      if i == 1 then block_st = 1 end
      local block_mid = pointsID[i]
      local block_end = pointsID[i+1]
      pointsID[i] = DATA2:ApplyMatch_Find(t1,t2,block_st,block_mid,block_end)
      pointsID2[#pointsID2 + 1] = {src = block_mid, dest = pointsID[i]} 
      if DATA.extstate.CONF_match_stretchdubarray&1==1 then t2=DATA2:ApplyMatch_StretchT(t2, block_st, block_end, block_mid, pointsID[i]) end
    end
    
    table.insert(pointsID2, 1,{src= 1, dest = 1}  ) -- fill start marker
    --table.insert(pointsID2, #pointsID+1, {src= pointsID[#pointsID], dest = pointsID[#pointsID]}  )-- fill end marker
    
    for i = 1, #pointsID do t_out[pointsID[i]] = 1  end -- force output
    for i = 1, #t2pts do if not t_out[i] then t_out[i] = 0 end end
    t_out[1] = 0 t_out[pointsID[#pointsID]] =0 -- clean edges
    
    -- clean same src dest
    for i = #pointsID2, 1, -1 do if pointsID2[i].src == pointsID2[i].dest then table.remove(pointsID2,i) end  end -- force output
    
    return t_out, pointsID2, t2
  end    
      
  -----------------------------------------------------------------------------  
    function GUI_RESERVED_draw_data(DATA, b)
      if not b.val_data then return end
      local x,y,w,h, backgr_col, frame_a, frame_asel, back_sela,val =  
                              b.x or 0,
                              b.y or 0,
                              b.w or 100,
                              b.h or 100,
                              b.backgr_col or '#333333',
                              b.frame_a or DATA.GUI.default_framea_normal,
                              b.frame_asel or DATA.GUI.default_framea_selected,
                              b.back_sela or DATA.GUI.default_back_sela,
                              b.val or 0
  
      x,y,w,h = 
                x*DATA.GUI.default_scale,
                y*DATA.GUI.default_scale,           
                w*DATA.GUI.default_scale,            
                h*DATA.GUI.default_scale
      local t = b.val_data
      local t0 = b.val_data_adv
      local t1 = b.val_data_adv2
      local tund = b.val_data_under
      local dataw = w/#t
      local datax = 0
      local last_datax,last_datay= datax,y+h
      gfx.x,gfx.y = x, y+h
      
      for i = 1, #t do
        --if t[i] == 0 then goto skipdataentry end
        datax = x+math.floor(dataw * (i-1))
        if last_datax ~= datax then
          local datay = math.floor(y+h-h*t[i])
          gfx.x = gfx.x + 1
          local x0 = gfx.x
          local y0 = gfx.y
          
          if  t and t[i] and t[i] ~= 0 then
            if t[i-1] and t[i-1] == 0 then last_datax = datax end
            DATA:GUIhex2rgb(DATA.GUI.default_data_col, true)
            gfx.a = DATA.GUI.default_data_a
            gfx.line(last_datax,last_datay-1,datax,datay-1)
            gfx.line(datax,y+h,datax,datay) 
          end 
          
          
          
          if  t0 and t0[i] and t0[i] ~= 0 then
            DATA:GUIhex2rgb(DATA.GUI.default_data_col_adv, true)
            gfx.a = DATA.GUI.default_data_a1
            --gfx.line(datax,y0,datax,datay) 
            gfx.rect(datax,y+1,2,h-2,1,1) 
          end 
          
          if  t1 and t1[i] and t1[i] ~= 0 then
            DATA:GUIhex2rgb(DATA.GUI.default_data_col_adv2, true)
            gfx.a = DATA.GUI.default_data_a2
            --gfx.line(datax,y0,datax,datay)  
            gfx.rect(datax,y+1,2,h-2,1,1) 
          end 
          
          if  tund 
            and tund[i+1] and tund[i+1] ~= 0 
            and tund[i] and tund[i] ~= 0 
            then
            local datay = math.floor(y+h-h*tund[i])
            local datay2 = math.floor(y+h-h*tund[i+1])
            if tund[i-1] and tund[i-1] == 0 then last_datax = datax end
            DATA:GUIhex2rgb(DATA.GUI.default_data_col_adv, true)
            gfx.a = DATA.GUI.default_data_a
            gfx.line(last_datax,datay,datax-1,datay2)
          end 
          
          last_datay = datay
        end
        last_datax= datax
        ::skipdataentry::
      end
      
      DATA:GUIhex2rgb(DATA.GUI.default_data_col_adv, true)
      local srcR, srcG, srcB = gfx.r,gfx.g,gfx.b
      DATA:GUIhex2rgb(DATA.GUI.default_data_col_adv2, true)
      local destR, destG, destB = gfx.r,gfx.g,gfx.b
      
      gfx.a = 0.2
      if b.val_data_com then 
        local gradt = b.val_data_com
        for i = 1, #gradt do 
          local blmin, blmax, dir = gradt[i].src, gradt[i].dest,- 1
          if gradt[i].src > gradt[i].dest then dir = 1 end
          for block = blmax, blmin, dir/dataw do
            local progress = (block-blmin) / (blmax - blmin)
            datax = x+math.floor(dataw * (block-1))
            gfx.r,gfx.g,gfx.b = srcR + progress * (destR - srcR),
                                srcG + progress * (destG - srcG),
                                srcB + progress * (destB - srcB)
            gfx.rect(datax,y,2,y+h-10,1,1) 
          end
        end
      end
    end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.59) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end
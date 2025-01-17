-- @description Align Takes
-- @version 3.09
-- @author MPL
-- @about Script for matching takes audio and stretch them using stretch markers
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Add Vocals2 preset



--[[
    * Changelog: 
      * v3.0 (08.2024) reaimgui, overhaul some stuff
      * v2.0 (01.2022) custom UI framework, improved algorithms
      * v1.00 (2016-02-11) Public release
      * v0.23 (2016-01-25) Split from Warping tool
      * v0.01 (2015-09-01) Alignment / Warping / Tempomatching tool idea
  ]]
  
  
    
--NOT reaper NOT gfx
local vrs = 3.09

--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3'
  
  
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        viewport_posX = 10,
        viewport_posY = 10,
        viewport_posW = 400,
        viewport_posH = 300, 
        flowvisible = 0,
        presetview = 0,
        
        FPRESET1 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gUGlja2VkIGd1aXRhcgpDT05GX2FwcGF0Y2hhbmdlPTEKQ09ORl9hdWRpb19ic19hMT0wCkNPTkZfYXVkaW9fYnNfYTI9MQpDT05GX2F1ZGlvX2JzX2EzPTAKQ09ORl9hdWRpb19ic19hND0xCkNPTkZfYXVkaW9fYnNfZjE9MjAwCkNPTkZfYXVkaW9fYnNfZjI9MjAwMApDT05GX2F1ZGlvX2JzX2YzPTUwMDAKQ09ORl9hdWRpb19saW09MQpDT05GX2F1ZGlvZG9zcXVhcmVyb290PTEuMApDT05GX2NsZWFubWFya2R1Yj0xCkNPTkZfY29tcGVuc2F0ZW92ZXJsYXA9MQpDT05GX2VuYWJsZXNob3J0Y3V0cz0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2luaXRmbGFncz0zCkNPTkZfbWFya2dlbl9STVNwb2ludHM9NQpDT05GX21hcmtnZW5fZW52ZWxvcGVyaXNlZmFsbD0yCkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHM9MTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDg3NQpDT05GX21hcmtnZW5fdGhyZXNob2xkPTEKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MwpDT05GX21hdGNoX2lnbm9yZXplcm9zPTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0wCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MApDT05GX3dpbmRvdz0wLjAxNwpDT05GX3dpbmRvd19vdmVybGFwPTE=',
        FPRESET2 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gRGlzdG9ydGVkIGd1aXRhcgpDT05GX2FwcGF0Y2hhbmdlPTEKQ09ORl9hdWRpb19ic19hMT0wCkNPTkZfYXVkaW9fYnNfYTI9MQpDT05GX2F1ZGlvX2JzX2EzPTAKQ09ORl9hdWRpb19ic19hND0wCkNPTkZfYXVkaW9fYnNfZjE9ODMKQ09ORl9hdWRpb19ic19mMj0xMjUwCkNPTkZfYXVkaW9fYnNfZjM9NTAwMApDT05GX2F1ZGlvX2xpbT0xCkNPTkZfYXVkaW9kb3NxdWFyZXJvb3Q9MS4wCkNPTkZfY2xlYW5tYXJrZHViPTEKQ09ORl9jb21wZW5zYXRlb3ZlcmxhcD0xCkNPTkZfZW5hYmxlc2hvcnRjdXRzPTAKQ09ORl9pbml0YXRtb3VzZXBvcz0wCkNPTkZfaW5pdGZsYWdzPTMKQ09ORl9tYXJrZ2VuX1JNU3BvaW50cz01CkNPTkZfbWFya2dlbl9lbnZlbG9wZXJpc2VmYWxsPTEKQ09ORl9tYXJrZ2VuX2ZpbHRlcnBvaW50cz0xMQpDT05GX21hcmtnZW5fbWluaW1hbGFyZWFSTVM9MC4wODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQ9MQpDT05GX21hdGNoX2Jsb2NrYXJlYT0xCkNPTkZfbWF0Y2hfaWdub3JlemVyb3M9MApDT05GX21hdGNoX3N0cmV0Y2hkdWJhcnJheT0xCkNPTkZfb2J0aW1lc2VsPTAKQ09ORl9wb3N0X3BvczBtYXJrPTEKQ09ORl9wb3N0X3BzaGlmdD0tMQpDT05GX3Bvc3RfcHNoaWZ0c3ViPTAKQ09ORl9wb3N0X3NtbW9kZT0yCkNPTkZfcG9zdF9zdHJtYXJrZmRzaXplPTAuMDExMQpDT05GX3Ntb290aD0wCkNPTkZfd2luZG93PTAuMDE3CkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
        FPRESET3 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gVm9jYWxzCkNPTkZfYXBwYXRjaGFuZ2U9MQpDT05GX2F1ZGlvX2JzX2ExPTAuMzMxMjUKQ09ORl9hdWRpb19ic19hMj0xCkNPTkZfYXVkaW9fYnNfYTM9MC4zMzEyNQpDT05GX2F1ZGlvX2JzX2E0PTAuNgpDT05GX2F1ZGlvX2JzX2YxPTIwMApDT05GX2F1ZGlvX2JzX2YyPTIwMDAKQ09ORl9hdWRpb19ic19mMz01MDAwCkNPTkZfYXVkaW9fbGltPTEKQ09ORl9hdWRpb2Rvc3F1YXJlcm9vdD0xLjAKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9lbmFibGVzaG9ydGN1dHM9MApDT05GX2luaXRhdG1vdXNlcG9zPTAKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTUKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTEzCkNPTkZfbWFya2dlbl9taW5pbWFsYXJlYVJNUz0wLjAzMTI1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQ9MQpDT05GX21hdGNoX2Jsb2NrYXJlYT0yNgpDT05GX21hdGNoX2lnbm9yZXplcm9zPTAKQ09ORl9tYXRjaF9tYXhibG9ja3NzdGFydG9mZnM9NgpDT05GX21hdGNoX21pbmJsb2Nrc3N0YXJ0b2Zmcz00CkNPTkZfbWF0Y2hfc2VhcmNoZnVydGhlcm9ubHk9MApDT05GX21hdGNoX3N0cmV0Y2hkdWJhcnJheT0xCkNPTkZfb2J0aW1lc2VsPTAKQ09ORl9wb3N0X3BvczBtYXJrPTEKQ09ORl9wb3N0X3BzaGlmdD0tMQpDT05GX3Bvc3RfcHNoaWZ0c3ViPTAKQ09ORl9wb3N0X3NtbW9kZT0yCkNPTkZfcG9zdF9zdHJtYXJrZmRzaXplPTAuMDExMQpDT05GX3Ntb290aD0wCkNPTkZfd2luZG93PTAuMDE0CkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
        FPRESET4 = 'CkNPTkZfTkFNRT1Wb2NhbHMyCkNPTkZfYWxpZ25pdGVtdGFrZXM9MApDT05GX2FwcGF0Y2hhbmdlPTEKQ09ORl9hdWRpb19ic19hMT0wCkNPTkZfYXVkaW9fYnNfYTI9MC4yNQpDT05GX2F1ZGlvX2JzX2EzPTEKQ09ORl9hdWRpb19ic19hND0wLjM5NQpDT05GX2F1ZGlvX2JzX2YxPTM3NC42CkNPTkZfYXVkaW9fYnNfZjI9MTY5NS43CkNPTkZfYXVkaW9fYnNfZjM9NDM0NC40CkNPTkZfYXVkaW9fZ2F0ZT0wCkNPTkZfYXVkaW9fbGltPTEKQ09ORl9hdWRpb19ub2lzZXRocmVzaG9sZD0wLjAwMDEKQ09ORl9hdWRpb2RhdGFfbWV0aG9kPTAKQ09ORl9hdWRpb2Rvc3F1YXJlcm9vdD0wLjkKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTAKQ09ORl9lbmFibGVzaG9ydGN1dHM9MApDT05GX2lnbm9yZWVtcHR5dGFrZXM9MQpDT05GX2lnbm9yZWVtcHR5dGFrZXNfdGhyZXNob2xkPTAuMDUKQ09ORl9pbml0YXRtb3VzZXBvcz0wCkNPTkZfaW5pdGZsYWdzPTMKQ09ORl9tYXJrZ2VuX1JNU3BvaW50cz0xMApDT05GX21hcmtnZW5fYWxnbz0wCkNPTkZfbWFya2dlbl9lbnZlbG9wZXJpc2VmYWxsPTEKQ09ORl9tYXJrZ2VuX2V4dHJlbXVtYXJlYV9STVNyZWxhdGlvbj0xLjA4MQpDT05GX21hcmtnZW5fZXh0cmVtdW1hcmVhX2V4Y2x1ZGV0aHJlc2g9MC4wCkNPTkZfbWFya2dlbl9leHRyZW11bWFyZWFfcmlzZT0xNQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTE2CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMyPTIwCkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMzPTUwCkNPTkZfbWFya2dlbl9tYW51YWxlZGl0PTAKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDE4NzUKQ09ORl9tYXJrZ2VuX3RocmVzaG9sZD0wLjcxODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQyPTAuNApDT05GX21hdGNoX2Jsb2NrYXJlYT03CkNPTkZfbWF0Y2hfZmlyc3Rzcmdtb25seT0wCkNPTkZfbWF0Y2hfaWdub3JlemVyb3M9MApDT05GX21hdGNoX21heGJsb2Nrc3N0YXJ0b2Zmcz0xCkNPTkZfbWF0Y2hfbWluYmxvY2tzc3RhcnRvZmZzPTIKQ09ORl9tYXRjaF9zZWFyY2hmdXJ0aGVyb25seT0wCkNPTkZfbWF0Y2hfc3RyZXRjaGR1YmFycmF5PTEKQ09ORl9vYnRpbWVzZWw9MApDT05GX3Bvc3RfcG9zMG1hcms9MQpDT05GX3Bvc3RfcHNoaWZ0PS0xCkNPTkZfcG9zdF9wc2hpZnRzdWI9MApDT05GX3Bvc3Rfc21tb2RlPTIKQ09ORl9wb3N0X3N0cm1hcmtmZHNpemU9MC4wMTExCkNPTkZfcG9zdF96ZXJvY3Jvc3M9MApDT05GX3Ntb290aD0xNgpDT05GX3Ntb290aF9tZWRpYW5fTD0wLjIKQ09ORl9zbW9vdGhfbWVkaWFuX2E9MQpDT05GX3Ntb290aF9tZWRpYW5fbT0yCkNPTkZfc21vb3RoX21lZGlhbl93PTAuMQpDT05GX3dhcm5pbmdfYW5hbHl6ZV90aW1lX2R1Yj0yNDAKQ09ORl93YXJuaW5nX2FuYWx5emVfdGltZV9yZWY9MzAKQ09ORl93aW5kb3c9MC4wMDkKQ09ORl93aW5kb3dfb3ZlcmxhcD0x',
        
        FPRESET5 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gVm9jYWxzIC0gdGlueSBhbGlnbiBtb3N0bHkgYnkgaGlnaHMKQ09ORl9hbGlnbml0ZW10YWtlcz0wCkNPTkZfYXBwYXRjaGFuZ2U9MQpDT05GX2F1ZGlvX2JzX2ExPTAKQ09ORl9hdWRpb19ic19hMj0wLjIxODc1CkNPTkZfYXVkaW9fYnNfYTM9MQpDT05GX2F1ZGlvX2JzX2E0PTEKQ09ORl9hdWRpb19ic19mMT04OApDT05GX2F1ZGlvX2JzX2YyPTIwMDAKQ09ORl9hdWRpb19ic19mMz01MDAwCkNPTkZfYXVkaW9fZ2F0ZT0wCkNPTkZfYXVkaW9fbGltPTEKQ09ORl9hdWRpb2Rvc3F1YXJlcm9vdD0wLjQKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTEwCkNPTkZfbWFya2dlbl9hbGdvPTEKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTE2CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMyPTIxCkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMzPTg0CkNPTkZfbWFya2dlbl9tYW51YWxlZGl0PTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDE4NzUKQ09ORl9tYXJrZ2VuX3RocmVzaG9sZD0wLjcxODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQyPTAuMzkzNzUKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MTUKQ09ORl9tYXRjaF9maXJzdHNyZ21vbmx5PTAKQ09ORl9tYXRjaF9pZ25vcmV6ZXJvcz0wCkNPTkZfbWF0Y2hfbWF4YmxvY2tzc3RhcnRvZmZzPTEKQ09ORl9tYXRjaF9taW5ibG9ja3NzdGFydG9mZnM9MgpDT05GX21hdGNoX3NlYXJjaGZ1cnRoZXJvbmx5PTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0wCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MApDT05GX3dpbmRvdz0wLjAxCkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
        FPRESET6 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gR3Jvd2xpbmcgdm9jYWxzLCB0aW1lIHNlbGVjdGlvbgpDT05GX2FsaWduaXRlbXRha2VzPTAKQ09ORl9hdWRpb19ic19hMT0wLjE0NDQ0NDQ0NDQ0NDQ0CkNPTkZfYXVkaW9fYnNfYTI9MC45MTY2NjY2NjY2NjY2NwpDT05GX2F1ZGlvX2JzX2EzPTEKQ09ORl9hdWRpb19ic19hND0xLjAKQ09ORl9hdWRpb19ic19mMT0xOTIuNQpDT05GX2F1ZGlvX2JzX2YyPTIwMDAKQ09ORl9hdWRpb19ic19mMz04MjY2LjY2NjY2NjY2NjcKQ09ORl9hdWRpb19nYXRlPTAKQ09ORl9hdWRpb19saW09MQpDT05GX2F1ZGlvZG9zcXVhcmVyb290PTAuNTMwMjc3Nzc3Nzc3NzgKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9pZ25vcmVlbXB0eXRha2VzPTEKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTEwCkNPTkZfbWFya2dlbl9hbGdvPTEKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTE2CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMyPTE4CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMzPTQwCkNPTkZfbWFya2dlbl9tYW51YWxlZGl0PTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDE4NzUKQ09ORl9tYXJrZ2VuX3RocmVzaG9sZD0wLjcxODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQyPTAuNzAyMDgzMzMzMzMzMzMKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MTUKQ09ORl9tYXRjaF9maXJzdHNyZ21vbmx5PTAKQ09ORl9tYXRjaF9pZ25vcmV6ZXJvcz0xCkNPTkZfbWF0Y2hfbWF4YmxvY2tzc3RhcnRvZmZzPTEKQ09ORl9tYXRjaF9taW5ibG9ja3NzdGFydG9mZnM9MgpDT05GX21hdGNoX3NlYXJjaGZ1cnRoZXJvbmx5PTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0xCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MApDT05GX3dpbmRvdz0wLjAxCkNPTkZfd2luZG93X292ZXJsYXA9MQ==',
        FPRESET7 = 'CkNPTkZfTkFNRT1bZmFjdG9yeV0gR3Jvd2xpbmcgdm9jYWxzMiBmaW5pc2ggMC4xc2hpZnQKQ09ORl9hbGlnbml0ZW10YWtlcz0wCkNPTkZfYXVkaW9fYnNfYTE9MApDT05GX2F1ZGlvX2JzX2EyPTAuMjE5NDQ0NDQ0NDQ0NDQKQ09ORl9hdWRpb19ic19hMz0wLjQKQ09ORl9hdWRpb19ic19hND0wLjUyNQpDT05GX2F1ZGlvX2JzX2YxPTE5Mi41CkNPTkZfYXVkaW9fYnNfZjI9MTY2My41NzYzODg4ODg5CkNPTkZfYXVkaW9fYnNfZjM9ODI2Ni42NjY2NjY2NjY3CkNPTkZfYXVkaW9fZ2F0ZT0wCkNPTkZfYXVkaW9fbGltPTEKQ09ORl9hdWRpb2Rvc3F1YXJlcm9vdD0wLjUzMDI3Nzc3Nzc3Nzc4CkNPTkZfYnVpbGRyZWZhc21heGltdW1zPTEKQ09ORl9jbGVhbm1hcmtkdWI9MQpDT05GX2NvbXBlbnNhdGVvdmVybGFwPTEKQ09ORl9pZ25vcmVlbXB0eXRha2VzPTEKQ09ORl9pbml0ZmxhZ3M9MwpDT05GX21hcmtnZW5fUk1TcG9pbnRzPTEwCkNPTkZfbWFya2dlbl9hbGdvPTEKQ09ORl9tYXJrZ2VuX2VudmVsb3BlcmlzZWZhbGw9MQpDT05GX21hcmtnZW5fZmlsdGVycG9pbnRzPTE2CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMyPTI5CkNPTkZfbWFya2dlbl9maWx0ZXJwb2ludHMzPTIwCkNPTkZfbWFya2dlbl9tYW51YWxlZGl0PTEKQ09ORl9tYXJrZ2VuX21pbmltYWxhcmVhUk1TPTAuMDE4NzUKQ09ORl9tYXJrZ2VuX3RocmVzaG9sZD0wLjcxODc1CkNPTkZfbWFya2dlbl90aHJlc2hvbGQyPTAuNzAyMDgzMzMzMzMzMzMKQ09ORl9tYXRjaF9ibG9ja2FyZWE9MTUKQ09ORl9tYXRjaF9maXJzdHNyZ21vbmx5PTAKQ09ORl9tYXRjaF9pZ25vcmV6ZXJvcz0xCkNPTkZfbWF0Y2hfbWF4YmxvY2tzc3RhcnRvZmZzPTEKQ09ORl9tYXRjaF9taW5ibG9ja3NzdGFydG9mZnM9MgpDT05GX21hdGNoX3NlYXJjaGZ1cnRoZXJvbmx5PTAKQ09ORl9tYXRjaF9zdHJldGNoZHViYXJyYXk9MQpDT05GX29idGltZXNlbD0xCkNPTkZfcG9zdF9wb3MwbWFyaz0xCkNPTkZfcG9zdF9wc2hpZnQ9LTEKQ09ORl9wb3N0X3BzaGlmdHN1Yj0wCkNPTkZfcG9zdF9zbW1vZGU9MgpDT05GX3Bvc3Rfc3RybWFya2Zkc2l6ZT0wLjAxMTEKQ09ORl9zbW9vdGg9MQpDT05GX3dpbmRvdz0wLjAwNQpDT05GX3dpbmRvd19vdmVybGFwPTE=',
        CONF_NAME = 'default',
        
        
        -- ref/dub 
        CONF_initflags = 3, -- &1 init ref &2 init dub 
        
        -- get ref
        CONF_obtimesel = 0, 
        CONF_warning_analyze_time_ref = 30,-- sec
        
        -- get dub 
        CONF_cleanmarkdub = 1,  
        CONF_alignitemtakes = 0, -- per item mode 
        CONF_ignoreemptytakes = 1, -- skip takes with linear amp < 0.05
        CONF_ignoreemptytakes_threshold = 0.05,
        CONF_warning_analyze_time_dub = 240,-- sec
        
        -- get audio
        CONF_audiodata_method = 1, -- 0 rms 1 co,plex domain -- V3+
        CONF_window = 0.025,  
        CONF_compensateoverlap = 0,   
        CONF_window_overlap = 1,   
        CONF_audio_noisethreshold = 0.0001,
        CONF_smooth = 16, -- 0 - no smooth, 1..15x -- smooth, &16 = weight
          CONF_smooth_median_L = 0.2, -- positive median weighting value 
          CONF_smooth_median_m = 2, -- previous values  count
          CONF_smooth_median_a = 1,--  positive mean weighting value 
          CONF_smooth_median_w = 0.1, -- a weighting value
          
          -- rms
          CONF_audio_gate = 0,
          CONF_audio_lim = 1, 
          CONF_audiodosquareroot = 0.4,  
          CONF_audio_bs_f1 = 88,
          CONF_audio_bs_f2 = 2000,
          CONF_audio_bs_f3 = 5000,
          CONF_audio_bs_a1 = 0,
          CONF_audio_bs_a2 = 0.21875,
          CONF_audio_bs_a3 = 1,
          CONF_audio_bs_a4 = 1,
          
        -- anchor points algorithm
        CONF_markgen_algo = 0, -- 0 risefall 1 gate 2  equal
          -- CONF_markgen_algo 0 rise
          CONF_markgen_extremumarea_rise = 15,  
          CONF_markgen_extremumarea_RMSrelation = 1.2,  
          CONF_markgen_extremumarea_excludethresh = 0.05,  
          -- CONF_markgen_algo 1 gate 
          CONF_markgen_threshold2 = 0.4,
          CONF_markgen_filterpoints2 = 20, -- minimal poits distance
          -- CONF_markgen_algo 2 equal
          CONF_markgen_filterpoints3 = 50, -- minimal poits distance
            
            
        -- calc best fit
          CONF_match_blockarea = 10, 
          CONF_match_minblocksstartoffs = 2,
          CONF_match_maxblocksstartoffs = 1, 
          CONF_match_stretchdubarray = 1, 
          CONF_match_searchfurtheronly = 0,
        
        
        
        
        UI_enableshortcuts = 0,
        UI_initatmouse = 0,
        UI_showtooltips = 1,
        UI_groupflags = 0,
        UI_appatchange = 1,
        
        
        CONF_markgen_manualedit = 0, 
          CONF_markgen_filterpoints = 16, 
          CONF_markgen_RMSpoints = 10, 
          CONF_markgen_minimalareaRMS = 0.01875,
          CONF_markgen_threshold = 0.71875,
        -- alg2
          
        -- alg3
          
          
        
        CONF_match_ignorezeros = 0,
        CONF_match_firstsrgmonly = 0,
        
        CONF_post_pshift = -1,
        CONF_post_pshiftsub = 0,
        CONF_post_strmarkfdsize = 0.0111,
        CONF_post_smmode = 2,
        CONF_post_pos0mark = 1,
        CONF_post_zerocross = 0,
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'AlignTakes2',
        UI_name = 'Align Takes', 
        upd = true, 
        AT = {align_strength=0}
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
  UI.spacingX = 4
  UI.spacingY = 3
-- mouse
  UI.hoverdelay = 0.8
  UI.hoverdelayshort = 0.8
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

-- AT
-- size
  UI.main_butw = 150
  UI.main_butclosew = 20
  UI.main_buth = 40
  UI.flowchildW = 600
  UI.flowchildH = UI.main_buth*8
  UI.plotW = UI.flowchildW - 200
  UI.plotH = UI.main_buth








function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 

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
  local w_min = UI.main_butw + UI.spacingX*2
  local h_min = UI.flowchildH 
  if EXT.flowvisible == 1 then 
    w_min = w_min + UI.flowchildW 
  end
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    window_flags = window_flags | ImGui.WindowFlags_NoResize
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
      UI.MAIN_PushStyle('StyleVar_FramePadding',10,UI.spacingY) 
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
      --Constant: Col_TableHeaderBg
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
    --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize(ctx, w_min, h_min, ImGui.Cond_Always)
    
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    
    local rv,open = ImGui.Begin(ctx, DATA.UI_name..' '..vrs..'##'..DATA.UI_name, open, window_flags) 
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
      
    -- draw stuff
      UI.draw()
      ImGui.Dummy(ctx,0,0) 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
     else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
    end 
    
    ImGui.PopFont( ctx ) 
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
  
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
  
  --if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  
  -- handle xy
  DATA:handleViewportXYWH()
  
  if DATA.sched then
    if EXT.CONF_initflags&1==1 then DATA.f01_GetReferenceTake() end 
    if EXT.CONF_initflags&2==2 then DATA.f02_GetDubTake(EXT.CONF_initflags&1==1) end 
    DATA.sched = nil
  end
  
  
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
  
  DATA.sched = EXT.CONF_initflags
  --if EXT.CONF_initflags&1==1 then DATA.f01_GetReferenceTake() end 
  --if EXT.CONF_initflags&2==2 then DATA.f02_GetDubTake(EXT.CONF_initflags&1==1) end 
  
  -- run loop
  defer(UI.MAINloop)
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
function UI.draw_knob(sliderid, sliderW,  sliderH, paramval, app_func) 
  if not (paramval and sliderid ) then return end
  
  local mindim = math.min(sliderW,sliderH)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, 0x00000000)
  local retval, v = ImGui.VSliderDouble( ctx, sliderid,  sliderW,  sliderH, paramval, 0, 1, '' )
  ImGui.PopStyleColor(ctx,2)
  
  -- handle mouse state
  if not temp then temp = {} end
  if not temp[sliderid] then temp[sliderid] = {} end 
  if  ImGui.IsItemActivated( ctx ) then temp[sliderid].latchstate = paramval goto drawknob end 
  if  ImGui.IsItemActive( ctx ) and temp[sliderid].latchstate then
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local outval = temp[sliderid].latchstate - y/500
    outval = math.max(0,math.min(outval,1))
    local dx, dy = ImGui.GetMouseDelta( ctx )
    if dy~=0 and app_func then app_func(outval) end
  end
  if ImGui_IsItemDeactivated( ctx ) then
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local outval = temp[sliderid].latchstate - y/500
    outval = math.max(0,math.min(outval,1))
    app_func(outval, true)
  end
  ::drawknob::
  
  -- draw stuff vars
  local knob_handle = 0xc8edfa 
  if  (UI and UI.knob_handle) then  knob_handle = UI.knob_handle end
  --local draw_list = ImGui.GetWindowDrawList(ctx)
  local draw_list = ImGui.GetForegroundDrawList(ctx)
  ImGui.SameLine( ctx, 0, 0 )
  local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
  local knob_w = ImGui.CalcItemWidth( ctx )
  curposx = curposx - sliderH
  local thicknessIn = 3
  local roundingIn = 0
  local col_rgba = 0xF0F0F0FF
  local p_min_x =curposx
  local p_min_y = curposy
  local p_max_x = curposx + sliderW
  local p_max_y  =curposy + sliderH
  local radius = math.floor(mindim/2)
  local radius_draw = math.floor(0.9 * radius)
  local center_x = curposx + sliderW/2-radius/2
  local center_y = curposy + sliderH/2
  local ang_min = -220
  local ang_max = 40
  local ang_val = ang_min + math.floor((ang_max - ang_min)*paramval)
  local radiusshift_y = (radius_draw- radius)
  local radius_draw2 = radius_draw-math.floor(0.1 * radius)
  local radius_draw3 = radius_draw-math.floor(mindim*0.3)
  if UI.tempcoloring[10] == 3 then knob_handle = 0x00FF00 end
  -- arc
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
  ImGui.DrawList_PathStroke(draw_list, knob_handle<<8|0x2F,  ImGui.DrawFlags_None,thicknessIn)
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
  if paramval > 0 then ImGui.DrawList_PathStroke(draw_list, knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2) end
  -- handle
  ImGui.DrawList_PathClear(draw_list)
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathStroke(draw_list, knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
end
--------------------------------------------------------------------------------  
  function UI.draw_presets() 
    if ImGui_BeginChild( ctx, 'presets', UI.main_butw,UI.main_buth*6+UI.spacingY*3, reaper.ImGui_ChildFlags_None() ) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,2)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0,0.5)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,2)
      local but_w = UI.main_butw - UI.main_butclosew - UI.spacingY
      ImGui.PushFont(ctx, DATA.font3) 
      
      ImGui.SeparatorText(ctx, 'Actions')
      if ImGui_Button( ctx, 'Restore defaults##presdef', UI.main_butw, 0 ) then DATA.PRESET_RestoreDefaults() end
      if ImGui_Button( ctx, 'Save current as new##prescur', UI.main_butw, 0 ) then DATA.PRESET_SavePreset() end
      
      
      
      ImGui.SeparatorText(ctx, 'User presets')
      
      for tid in pairs(DATA.presets.user) do
        if DATA.presets.user[tid]  then 
          local name = DATA.presets.user[tid].CONF_NAME
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5) 
          if ImGui_Button( ctx, 'X##presclose'..tid, UI.main_butclosew, 0 ) then 
            DATA.PRESET_RemoveUserPreset(tid) 
            DATA.PRESET_GetExtStatePresets() 
          end 
          ImGui.PopStyleVar(ctx) 
          ImGui.SameLine(ctx)
          if ImGui_Button( ctx, name..'##pres'..tid, but_w, 0 ) then 
            DATA.PRESET_ApplyPreset(DATA.presets.user[tid]) 
          end
          ImGui.SetItemTooltip(ctx, name)  
        end
      end
      
      ImGui.SeparatorText(ctx, 'Factory presets')
      
      for tid in pairs(DATA.presets.factory) do
        if DATA.presets.factory[tid] then 
          local name = DATA.presets.factory[tid].CONF_NAME
          if ImGui_Button( ctx, name..'##pres'..tid,  UI.main_butw, 0 ) then DATA.PRESET_ApplyPreset(DATA.presets.factory[tid]) end
          ImGui.SetItemTooltip(ctx, name) 
        end
      end
      
      
      ImGui.SeparatorText(ctx, 'Script info') 
      ImGui.Text(ctx, 'Version: '..vrs)
      
      ImGui.PopStyleVar(ctx,3)
      ImGui.PopFont(ctx) 
      ImGui_EndChild( ctx )
    end
  end
--------------------------------------------------------------------------------  
  function UI.draw()  
    if EXT.presetview == 0 then
      -- get ref
      if EXT.flowvisible == 1 and UI.tempcoloring[10] == 1 then UI.draw_setbuttoncolor(UI.butBg_green) end
      
      local refdirty = not (DATA.AT.refdata and DATA.AT.refdata.dirty==false)
      if refdirty == true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, math.floor(DATA.flicker*255)|(UI.textcol<<8))  end
      if ImGui.Button(ctx, 'Get reference',UI.main_butw,UI.main_buth) then DATA.f01_GetReferenceTake() end
      if refdirty == true then ImGui.PopStyleColor(ctx) end
      UI.tempcoloring[1] = ImGui_IsItemHovered( ctx, ImGui_HoveredFlags_None() )
      if EXT.flowvisible == 1 and UI.tempcoloring[10] == 1 then UI.draw_setbuttoncolor(UI.butBg_green, true) end
      
      -- get dub
      if EXT.flowvisible == 1 and UI.tempcoloring[10] == 2 then UI.draw_setbuttoncolor(UI.butBg_green) end
      local dubdirty = not (DATA.AT.dubdata and DATA.AT.dubdata.dirty==false)
      if dubdirty == true then ImGui.PushStyleColor(ctx, ImGui.Col_Text, math.floor(DATA.flicker*255)|(UI.textcol<<8))  end
      if ImGui.Button(ctx, 'Get dub',UI.main_butw,UI.main_buth) then       DATA.f02_GetDubTake() end
      if dubdirty == true then ImGui.PopStyleColor(ctx) end
      UI.tempcoloring[2] = ImGui_IsItemHovered( ctx, ImGui_HoveredFlags_None() )
      if EXT.flowvisible == 1 and UI.tempcoloring[10] == 2 then UI.draw_setbuttoncolor(UI.butBg_green, true) end
      
      -- apply
      if EXT.flowvisible == 1 and UI.tempcoloring[10] == 3 then UI.draw_setbuttoncolor(UI.butBg_green) end
      UI.draw_knob('##mainalignslider', UI.main_butw,  UI.main_buth*3, DATA.AT.align_strength, function(val,atrelease) 
        DATA.AT.align_strength = val 
        DATA.f05_ApplyOutput(atrelease)
        if atrelease == true then Undo_OnStateChange2( 0, 'Align Takes' )  end
      end) 
      UI.tempcoloring[3] = ImGui_IsItemHovered( ctx, ImGui_HoveredFlags_None() )
      if EXT.flowvisible == 1 and UI.tempcoloring[10] == 3 then UI.draw_setbuttoncolor(UI.butBg_green, true) end
      
      ImGui.Dummy(ctx,1,1)
      if ImGui.Button(ctx, 'Parameters',UI.main_butw,UI.main_buth) then EXT.flowvisible = EXT.flowvisible~1  end
     else
       UI.draw_presets()
    end
    if ImGui.Button(ctx, 'Presets',UI.main_butw,UI.main_buth) then  EXT.presetview = EXT.presetview~1 end
    
    UI.draw_flow()  
  end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttoncolor(col, release) 
    if not release then
      UI.MAIN_PushStyle('Col_Button',col, 0.5, true) 
      UI.MAIN_PushStyle('Col_ButtonActive',col, 1, true) 
      UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8, true)
     else
      ImGui.PopStyleColor(ctx, 3)
      UI.pushcnt2 = UI.pushcnt2 - 3
    end
  end
  --------------------------------------------------------------------------------  
    function UI.draw_flow_tempcolor(release) 
      if not release then
        UI.MAIN_PushStyle('Col_Tab',UI.butBg_green, 0.37, true) 
        --UI.MAIN_PushStyle('Col_TabActive',UI.butBg_green, 1, true) 
        UI.MAIN_PushStyle('Col_TabHovered',UI.butBg_green, 0.8, true) 
       else
        ImGui.PopStyleColor(ctx, 2)
        UI.pushcnt2 = UI.pushcnt2 - 2
      end
    end
    
--------------------------------------------------------------------------------  
function UI.draw_flow_CHECK(t)
  local byte = t.confkeybyte or 0
  if reaper.ImGui_Checkbox( ctx, t.key, EXT[t.extstr]&(1<<byte)==(1<<byte) ) then 
    EXT[t.extstr] = EXT[t.extstr]~(1<<byte) 
    EXT:save() 
    UI.draw_flow_markdirty(t) 
  end
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    UI.draw_flow_markdirty(t)
  end
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  
end
--------------------------------------------------------------------------------  
function UI.draw_flow_COMBO(t)
  local preview_value = t.values[EXT[t.extstr]]
  ImGui.SetNextItemWidth( ctx, 200 )
  if ImGui.BeginCombo( ctx, t.key, preview_value ) then
    for id in spairs(t.values) do
      if ImGui.Selectable( ctx, t.values[id], id==EXT[t.extstr]) then
        EXT[t.extstr] = id
        EXT:save()
        UI.draw_flow_markdirty(t)
      end
    end
    ImGui.EndCombo(ctx)
  end
  
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    UI.draw_flow_markdirty(t)
  end 
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  
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
  ------------------------------------------------------------------------------------------------------
  function VF_math_Qdec(num, pow) if not pow then pow = 3 end return math.floor(num * 10^pow) / 10^pow end  
--------------------------------------------------------------------------------  
function UI.draw_flow_markdirty(t)
    -- aligntakes v3+
    if t.markdirty then 
      if t.markdirty &1==1 then 
        if DATA.AT and DATA.AT.refdata then DATA.AT.refdata.dirty = true end
      end
      if t.markdirty &2==2 then 
        if DATA.AT and DATA.AT.dubdata  then DATA.AT.dubdata.dirty = true end
      end
    end
end
--------------------------------------------------------------------------------  
function UI.draw_flow_SLIDER(t) 
    ImGui.SetNextItemWidth( ctx, 100 )
    local retval, v
    if t.int or t.block then
      local format = t.format
      if t.block then 
        local wind = DATA.AudioData_gettruewindow()
        format = VF_math_Qdec(EXT[t.extstr] * wind,3)..'s' 
      end
      retval, v = reaper.ImGui_SliderInt ( ctx, t.key..'##'..t.extstr, math.floor(EXT[t.extstr]), t.min, t.max, format )
     elseif t.percent then
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr]*100, t.percent_min or 0, t.percent_max or 100, t.format or '%.1f%%' )
     else  
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr], t.min, t.max, t.format )
    end
    
    
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
      UI.draw_flow_markdirty(t)
     else
      if retval then 
        if t.percent then EXT[t.extstr] = v /100 else EXT[t.extstr] = v  end
        EXT:save() 
        UI.draw_flow_markdirty(t)
      end
    end
  
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
    
end
--------------------------------------------------------------------------------  
function UI.draw_flow_00data_reference() 
  -- reference
  local max = 1
  local refdata = new_array(1)
  if(DATA.AT.refdata and  DATA.AT.refdata.data) then 
    refdata = new_array(DATA.AT.refdata.data) 
   else 
    return
  end
  ImGui.PlotHistogram(ctx, 'Reference', refdata, 0, '', 0, max, UI.plotW, UI.plotH)
  refdata.clear()
end
--------------------------------------------------------------------------------  
function UI.draw_flow_00data_dub(showonlyone) 
  if not DATA.AT.dubdata then return end
  local distH = 10
  local maxdubsshow = #DATA.AT.dubdata
  if showonlyone then maxdubsshow = 1 end
  local max = 1 
  
  -- arrays audio
  local posXinit, posYinit = ImGui.GetCursorPos( ctx )
  for dubID = 1, maxdubsshow do
    if DATA.AT.dubdata[dubID] and DATA.AT.dubdata[dubID].take_name then
      local dubdata = new_array(1)
      if(DATA.AT.dubdata[dubID] and  DATA.AT.dubdata[dubID].data) then 
        dubdata = new_array(DATA.AT.dubdata[dubID].data) 
       else
        return
      end
      local posX, posY = ImGui.GetCursorPos( ctx )
      ImGui.PlotHistogram(ctx, 'Dub #'..dubID..' '..DATA.AT.dubdata[dubID].take_name..'##'..dubID, dubdata, 0, '', 0, max, UI.plotW, UI.plotH)
      ImGui.SetCursorPos( ctx, posX, posY )
      
      
      ImGui.SetCursorPos( ctx, posX, posY + UI.plotH)
      dubdata.clear()
    end
  end
  
  -- arrays points
  ImGui.SetCursorPos( ctx,posXinit, posYinit  )
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogram,0xF00000FF) -- red
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,0x00000000)
  for dubID = 1, maxdubsshow do
    if DATA.AT.dubdata[dubID] and DATA.AT.dubdata[dubID].take_name then
    
      
      --local dubdata_points = new_array(DATA.AT.dubdata[dubID].data_points)
      -- resize to plotW 
      local dubdata_points = new_array(UI.plotW)
      for i = 1, UI.plotW do dubdata_points[i] = 0  end
      if(DATA.AT.dubdata[dubID] and DATA.AT.dubdata[dubID].output_srcdest) then  
        local sz=#DATA.AT.dubdata[dubID].data_points
        for i = 1,#DATA.AT.dubdata[dubID].output_srcdest do
          local srcid = DATA.AT.dubdata[dubID].output_srcdest[i].src
          local id = math.ceil((srcid / sz) * UI.plotW)
          --dubdata_points[id] = 1
          if id + 1 < UI.plotW then
            dubdata_points[id+1] = 1
          end
        end
      end 
      
      local posX, posY = ImGui.GetCursorPos( ctx )
      if DATA.AT.dubdata[dubID].data_points then 
        ImGui.PlotHistogram(ctx, '##pts'..dubID, dubdata_points, 0, '', 0, max, UI.plotW, UI.plotH) 
      end
      
      if UI.activetab == 4 and EXT.CONF_markgen_algo==1 then
        local thresharr = new_array(2)
        thresharr[1] = EXT.CONF_markgen_threshold2
        thresharr[2] = EXT.CONF_markgen_threshold2
        ImGui.SetCursorPos( ctx, posX, posY )
        ImGui.PlotLines(ctx, '##thresh'..dubID, thresharr, 0, overlay_text, 0, 1, 0,UI.plotH)
        --[[ImGui.SetCursorPos( ctx, posX, posY+UI.plotH)
        local mindist = new_array(#DATA.AT.dubdata[dubID].data)
        for i = 1, EXT.CONF_markgen_filterpoints2 do mindist[i] = 1 end
        ImGui.PlotHistogram(ctx, '##ptsmindist'..dubID, mindist, 0, '', 0, 1, UI.plotW, distH) ]]
      end
      
      ImGui.SetCursorPos( ctx, posX, posY + UI.plotH) 
      dubdata_points.clear()
    end
  end
  ImGui.PopStyleColor(ctx,2)
  
end
--------------------------------------------------------------------------------  
function UI.draw_flow_00data() 
  if ImGui.BeginTabItem(ctx, 'Takes') then 
    UI.activetab = 0
    UI.draw_flow_00data_reference() 
    if ImGui.BeginChild( ctx, '##dubtakes', 0, 0 ) then UI.draw_flow_00data_dub() ImGui.EndChild( ctx) end
    ImGui.EndTabItem(ctx)
  end
end
--------------------------------------------------------------------------------  
function UI.draw_flow_01audio()
  local indent = 30
  
  if ImGui.BeginTabItem(ctx, 'Audio') then
    UI.activetab = 1
    UI.draw_flow_00data_reference()
    if ImGui.BeginChild( ctx, '##audioparamstab', 0, 0 ) then
    
      -- params
      UI.draw_flow_COMBO({['key']='Method',                                           ['extstr'] = 'CONF_audiodata_method',                 ['values'] = {[0]='RMS', [1] = 'CDOE'},['tooltip']='RMS - audio amplitude, CDOE - Complex domain onset envelope',markdirty=3}) ImGui.SameLine(ctx)
      UI.draw_flow_SLIDER({ ['key']='Window',                                         ['extstr'] = 'CONF_window',                           ['format']='%.3f sec',    ['min']=0.005,  ['max']=0.4,markdirty=3})  
      UI.draw_flow_COMBO({['key']='Overlap',                                          ['extstr'] = 'CONF_window_overlap',                   ['values'] = {[1]='[window]', [2]='2x', [4]='4x', [8]='8x'},markdirty=3 }) 
      if EXT.CONF_window_overlap > 1 then  ImGui.SameLine(ctx)
        UI.draw_flow_CHECK({['key']='Compensate overlap (reduce data)',               ['extstr'] = 'CONF_compensateoverlap',markdirty=3}) 
      end
      if EXT.CONF_audiodata_method == 0 then 
        ImGui.Indent(ctx, indent)  
        if EXT.CONF_audiodata_method == 0 then 
        UI.draw_flow_SLIDER({ ['key']='Scaling',                                      ['extstr'] = 'CONF_audiodosquareroot',                ['format']='%.3f',  ['min']=0.1,  ['max']=2,markdirty=3})  end
        UI.draw_flow_SLIDER({ ['key']='Gate (linear scale)',                          ['extstr'] = 'CONF_audio_gate',                       ['format']='%.3f',  ['min']=0,  ['max']=0.1,markdirty=3}) 
        UI.draw_flow_SLIDER({ ['key']='Limit (linear scale)',                         ['extstr'] = 'CONF_audio_lim',                       ['format']='%.3f',  ['min']=0,  ['max']=1,markdirty=3})  
        UI.draw_flow_SLIDER({ ['key']='##BandSplitter Freq 1',                        ['extstr'] = 'CONF_audio_bs_f1',                      ['format']='%.1f Hz',    ['min']=20,  ['max']=EXT.CONF_audio_bs_f2,markdirty=3}) 
        ImGui.SameLine(ctx) UI.draw_flow_SLIDER({ ['key']='##BandSplitter Freq 2',    ['extstr'] = 'CONF_audio_bs_f2',                      ['format']='%.1f Hz',    ['min']=EXT.CONF_audio_bs_f1,  ['max']=EXT.CONF_audio_bs_f3,markdirty=3}) 
        ImGui.SameLine(ctx) UI.draw_flow_SLIDER({ ['key']='Bands frequency',          ['extstr'] = 'CONF_audio_bs_f3',                      ['format']='%.1f Hz',    ['min']=EXT.CONF_audio_bs_f2,  ['max']=10000,markdirty=3})  
        UI.draw_flow_SLIDER({ ['key']='##BandSplitter Band 1',                        ['extstr'] = 'CONF_audio_bs_a1',                      ['format']='%.3f',  ['min']=0,  ['max']=1,markdirty=3}) 
        ImGui.SameLine(ctx) UI.draw_flow_SLIDER({ ['key']='##BandSplitter Band 2',    ['extstr'] = 'CONF_audio_bs_a2',                      ['format']='%.3f',  ['min']=0,  ['max']=1,markdirty=3}) 
        ImGui.SameLine(ctx) UI.draw_flow_SLIDER({ ['key']='##BandSplitter Band 3',    ['extstr'] = 'CONF_audio_bs_a3',                      ['format']='%.3f',  ['min']=0,  ['max']=1,markdirty=3}) 
        ImGui.SameLine(ctx) UI.draw_flow_SLIDER({ ['key']='Bands amp',                ['extstr'] = 'CONF_audio_bs_a4',                      ['format']='%.3f',  ['min']=0,  ['max']=1,markdirty=3})  
        ImGui.Unindent(ctx, indent)
      end  
      UI.draw_flow_COMBO({['key']='Smoothing',                                        ['extstr'] = 'CONF_smooth',                           ['values'] = {[0]='[none]', [1]='1x',  [2]='2x', [4]='4x', [8]='8x', [16]='Weight'} ,markdirty=3})  
      if EXT.CONF_smooth &16==16 then
        UI.draw_flow_SLIDER({ ['key']='Positive median weighting value',              ['extstr'] = 'CONF_smooth_median_L',                  ['format']='%.3f',  ['min']=0.03,  ['max']=2,markdirty=3}) 
        UI.draw_flow_SLIDER({ ['key']='Buffer block',                                 ['extstr'] = 'CONF_smooth_median_m',                  ['block'] = true,  ['min']=2,  ['max']=30,markdirty=3}) 
        UI.draw_flow_SLIDER({ ['key']='Positive mean weighting value',                ['extstr'] = 'CONF_smooth_median_a',                  ['format']='%.3f',  ['min']=0.05,  ['max']=2,markdirty=3}) 
        UI.draw_flow_SLIDER({ ['key']='Weighting value',                              ['extstr'] = 'CONF_smooth_median_w',                  ['format']='%.3f',  ['min']=0.05,  ['max']=0.3,markdirty=3}) 
      end
      UI.draw_flow_SLIDER({ ['key']='Noise threshold',                                         ['extstr'] = 'CONF_audio_noisethreshold',    ['format']='%.3f',    ['min']=0,  ['max']=0.1,markdirty=3}) 
      ImGui.EndChild( ctx)
    end
    ImGui.EndTabItem(ctx)
  end
end
--------------------------------------------------------------------------------  
function UI.draw_flow_02GetRef() 
  -- get ref
  if UI.tempcoloring[1] == true then UI.draw_flow_tempcolor() end 
  if ImGui.BeginTabItem(ctx, 'Get ref >') then
    UI.activetab = 2
    UI.tempcoloring[10] = 1
    UI.draw_flow_CHECK({['key']='Get reference take at initialization',         ['extstr'] = 'CONF_initflags',       ['confkeybyte'] = 0})
    UI.draw_flow_CHECK({['key']='Obey time selection',                          ['extstr'] = 'CONF_obtimesel',markdirty=3})
    UI.draw_flow_SLIDER({['key']='Warn if audio data is longer than this time',           ['extstr'] = 'CONF_warning_analyze_time_ref', ['format']='%d sec',    ['min']=20,  ['max']=240, ['int'] = true}) 
    ImGui.EndTabItem(ctx)
  end
  if UI.tempcoloring[1] == true then UI.draw_flow_tempcolor(true) end 
end
--------------------------------------------------------------------------------  
function UI.draw_flow_03GetDub() 
  -- get ref
  if UI.tempcoloring[2] == true then UI.draw_flow_tempcolor() end 
  if ImGui.BeginTabItem(ctx, 'Get dub >') then
    UI.activetab = 3
    UI.tempcoloring[10] = 2
    UI.draw_flow_CHECK({['key']='Get dub take at initialization',               ['extstr'] = 'CONF_initflags',       ['confkeybyte'] = 1})
    UI.draw_flow_CHECK({['key']='Clean dub stretch markers at initialization',  ['extstr'] = 'CONF_cleanmarkdub',markdirty=2})
    UI.draw_flow_CHECK({['key']='Align takes inside single item',               ['extstr'] = 'CONF_alignitemtakes',markdirty=3})
    if EXT.CONF_audiodata_method == 0 then
      UI.draw_flow_CHECK({['key']='Skip silent audio takes',                    ['extstr'] = 'CONF_ignoreemptytakes',markdirty=2})
      if EXT.CONF_ignoreemptytakes == 1 then
        ImGui.SameLine(ctx)
        UI.draw_flow_SLIDER({['key']='Threshold',                               ['extstr'] = 'CONF_ignoreemptytakes_threshold',   ['format']='%.1f%%',  ['min']=0.001,  ['max']=0.2, ['percent'] = true, ['percent_max'] = 50,markdirty=2})
      end
    end
    UI.draw_flow_SLIDER({['key']='Warn if audio data is longer than this time', ['extstr'] = 'CONF_warning_analyze_time_dub', ['format']='%d sec',    ['min']=20,  ['max']=240, ['int'] = true}) 
    
    ImGui.EndTabItem(ctx)
  end
  if UI.tempcoloring[2] == true then UI.draw_flow_tempcolor(true) end 
end
--------------------------------------------------------------------------------  
function UI.draw_flow_04CalcAnchorPoints() 
  -- get ref
  if UI.tempcoloring[2] == true then UI.draw_flow_tempcolor() end 
  if ImGui.BeginTabItem(ctx, 'Anchor points >') then
    UI.activetab = 4
    UI.tempcoloring[10] = 2
    
    
    UI.draw_flow_00data_dub(true) 
    
    UI.draw_flow_COMBO({['key']='Method##anchorpoints',['values'] = {
      [0]='Envelope rise/fall', 
      [1] = 'Gate trigger',
      [2] = 'Equal distance'
      
      },                          
      ['extstr'] = 'CONF_markgen_algo',markdirty=2}) 
    
    
    -- Envelope
    if EXT.CONF_markgen_algo==0 then
      UI.draw_flow_SLIDER({['key']='Extremum check area',                 ['extstr'] = 'CONF_markgen_extremumarea_rise',   ['min']=3,  ['max']=100, ['block'] = true,markdirty=2})
      UI.draw_flow_SLIDER({['key']='RMS relation',                        ['extstr'] = 'CONF_markgen_extremumarea_RMSrelation',   ['percent_min']=100,  ['percent_max']=200, ['percent'] = true,markdirty=2})
      UI.draw_flow_SLIDER({['key']='Exclude point below threshold',       ['extstr'] = 'CONF_markgen_extremumarea_excludethresh',   ['percent_min']=0,  ['percent_max']=90, ['percent'] = true,markdirty=2})
    end
    
    -- trigger gate
    if EXT.CONF_markgen_algo==1 then
      UI.draw_flow_SLIDER({['key']='Threshold',                  ['extstr'] = 'CONF_markgen_threshold2',   ['format']='%.1f%%',  ['min']=0.05,  ['max']=0.5, ['percent'] = true, ['percent_max'] = 100,markdirty=2})
      UI.draw_flow_SLIDER({['key']='Min. distance',  ['extstr'] = 'CONF_markgen_filterpoints2',   ['min']=EXT.CONF_match_blockarea,  ['max']=100, ['block'] = true,markdirty=2})
    end
    
    -- equal distance
    if EXT.CONF_markgen_algo==2 then
      UI.draw_flow_SLIDER({['key']='Distance',  ['extstr'] = 'CONF_markgen_filterpoints3',   ['min']=EXT.CONF_match_blockarea,  ['max']=100, ['block'] = true,markdirty=2})
    end
                                                        
    ImGui.EndTabItem(ctx)
  end
  if UI.tempcoloring[2] == true then UI.draw_flow_tempcolor(true) end 
end
--------------------------------------------------------------------------------  
function UI.draw_flow_05CalcBestFit() 
  -- get ref
  if UI.tempcoloring[2] == true then UI.draw_flow_tempcolor() end 
  if ImGui.BeginTabItem(ctx, 'Calc best fit >') then
    UI.activetab = 5
    UI.tempcoloring[10] = 2
    
    UI.draw_flow_SLIDER({['key']='Brutforce search area',  ['extstr'] = 'CONF_match_blockarea',   ['min']=3,  ['max']=80, ['block'] = true, tooltip='Bigger value increase search area, keep it lower for fine tweaking. Huge values increase calculation time',markdirty=2})
    UI.draw_flow_CHECK({['key']='Stretch dub array on the fly',  ['extstr'] = 'CONF_match_stretchdubarray',  tooltip='Append calculation array while brutforcing',markdirty=2})
    UI.draw_flow_CHECK({['key']='Ignore zero values at difference check',  ['extstr'] = 'CONF_match_ignorezeros',markdirty=2})
    UI.draw_flow_CHECK({['key']='Search forward only',  ['extstr'] = 'CONF_match_searchfurtheronly',markdirty=2})
    UI.draw_flow_CHECK({['key']='Compare until midblock',  ['extstr'] = 'CONF_match_firstsrgmonly',  tooltip='When calculating reference and dub array compare only data between start and middle block',markdirty=2})
    UI.draw_flow_SLIDER({['key']='Minimum block search start offset',  ['extstr'] = 'CONF_match_minblocksstartoffs',   ['min']=0,  ['max']=30, ['block'] = true, tooltip='Minimum between previos block and movable midpoint, require to have at least one block offset',markdirty=2})
    UI.draw_flow_SLIDER({['key']='Minimum block search end offset',  ['extstr'] = 'CONF_match_maxblocksstartoffs',   ['min']=0,  ['max']=30, ['block'] = true, tooltip='Minimum between next block and movable midpoint, require to have at least one block offset',markdirty=2})
                                                    
    ImGui.EndTabItem(ctx)
  end
  if UI.tempcoloring[2] == true then UI.draw_flow_tempcolor(true) end 
end
--------------------------------------------------------------------------------  
function UI.draw_flow_06AppOut() 
  -- get ref
  if UI.tempcoloring[3] == true then UI.draw_flow_tempcolor() end 
  if ImGui.BeginTabItem(ctx, 'Output') then
    UI.activetab = 6
    UI.tempcoloring[10] = 3
    
    -- get pitch shift mode
      local pitch_shift_t = {}
      pitch_shift_t[-1] = '[default]'
      for mode=0, 32 do
        local retval, modename = reaper.EnumPitchShiftModes( mode )
        if retval and modename and modename ~= '' then pitch_shift_t[mode] = modename   end
      end
    -- get pitch shift sub mode
      local pitch_shift_tsub = {}
      pitch_shift_tsub[-1] = '[default]'
      local mode = 0
      if EXT.CONF_post_pshift >=0 then mode = EXT.CONF_post_pshift end
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
    
    ImGui.SeparatorText(ctx, 'Stretch markers')
    UI.draw_flow_CHECK({['key']='Quantize to zero crossings',  ['extstr'] = 'CONF_post_zerocross',markdirty=2})
    ImGui.SeparatorText(ctx, 'Take resampling')
    UI.draw_flow_COMBO({['key']='Pitch shift mode##pshift',['values'] = pitch_shift_t,  ['extstr'] = 'CONF_post_pshift',markdirty=2}) 
    UI.draw_flow_COMBO({['key']='Pitch shift submode##pshiftsubmode',['values'] = pitch_shift_tsub,  ['extstr'] = 'CONF_post_pshiftsub',markdirty=2}) 
    UI.draw_flow_COMBO({['key']='Stretch marker mode##smmode',['values'] = smmode,  ['extstr'] = 'CONF_post_smmode',markdirty=2}) 
    UI.draw_flow_SLIDER({['key']='Stretch marker fade size',  ['extstr'] = 'CONF_post_strmarkfdsize',   ['min']=0.0025,  ['max']=0.05, tooltip='Increase to reduce glitches',markdirty=2})
    ImGui.EndTabItem(ctx)
  end
  if UI.tempcoloring[3] == true then UI.draw_flow_tempcolor(true) end  
end
--------------------------------------------------------------------------------  
  function UI.draw_flow()  
    reaper.ImGui_SetCursorPos( ctx, UI.main_butw+UI.spacingX*2, UI.calc_itemH + UI.spacingY )
    if ImGui.BeginChild(ctx,'Flowchart', UI.flowchildW-UI.spacingX,UI.flowchildH-UI.spacingY*3-UI.calc_itemH , ImGui.ChildFlags_None|reaper.ImGui_ChildFlags_Border(), ImGui.WindowFlags_None) then 
        
      if ImGui.BeginTabBar(ctx, 'Flowchartbar', ImGui.TabBarFlags_None) then
         
        UI.draw_flow_00data()  
        UI.draw_flow_01audio() 
        UI.draw_flow_02GetRef() 
        UI.draw_flow_03GetDub()  
        UI.draw_flow_04CalcAnchorPoints()  
        UI.draw_flow_05CalcBestFit()  
        UI.draw_flow_06AppOut()
        
        ImGui.EndTabBar(ctx) 
      end 
      
      ImGui.EndChild(ctx)
    end
  end
  ---------------------------------------------------------------------
  function DATA.f01_GetReferenceTake()  
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
    
    if EXT.CONF_obtimesel == 1 then edge_start,edge_end = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false ) end 
    if not parent_track or edge_start > edge_end then return end 
    
    if edge_end - edge_start > EXT.CONF_warning_analyze_time_ref then 
      local ret = MB('Analyzing can take long time, proceed anyway?', 'Align Takes', 3)
      if ret ~= 6 then return end
    end
    
    DATA.AT.refdata = {data={}}
    DATA.AT.refdata.parent_track = parent_track
    DATA.AT.refdata.edge_start = edge_start
    DATA.AT.refdata.edge_end = edge_end 
    DATA.AT.refdata.parent_trackGUID = GetTrackGUID(parent_track)
    
    local ret = DATA.AudioData_Get(DATA.AT.refdata)
    if ret then 
      DATA.AT.refdata.valid = true 
      DATA.AT.refdata.dirty = false
    end
    
    
  end
  ---------------------------------------------------------------------
  function DATA.AudioData_Get(srct) 
    local parent_track, edge_start, edge_end, take, item, tkoffs, take_rate = 
      srct.parent_track, 
      srct.edge_start, 
      srct.edge_end, 
      srct.take,
      srct.item,
      srct.tkoffs,
      srct.take_rate
    
    
    -- init 
      local accessor  
      local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
      if take then 
        local pcm_src  =  GetMediaItemTake_Source( take )
        SR_spls = reaper.GetMediaSourceSampleRate( pcm_src ) 
        accessor = CreateTakeAudioAccessor( take )
        edge_end = edge_end - edge_start -- tkoffs*take_rate
        edge_start = 0
       else
        accessor = CreateTrackAudioAccessor( parent_track )
      end
      local data = {}
      local id = 0 
      local window_sec = EXT.CONF_window 
      local FFTsz = 32
      local bufsz = math.ceil(window_sec * SR_spls)
      if EXT.CONF_audiodata_method == 1 then bufsz = FFTsz end
      local frame3 = {}
      
      
    -- loop stuff 
      local overlap = EXT.CONF_window_overlap
      for pos = edge_start, edge_end, window_sec/overlap do 
        
        -- RMS
        if EXT.CONF_audiodata_method == 0 then
          local samplebuffer = new_array(bufsz);
          GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
          local samplebuffer_t = samplebuffer.table()
          samplebuffer.clear()
          DATA.AudioData_BandSplit(samplebuffer_t, SR_spls)
          local sum = 0 
          for i = 1, bufsz do 
            local val = math.abs(samplebuffer_t[i]) 
            if val < EXT.CONF_audio_gate then val  = 0 end
            sum = sum + val 
          end 
          id = id + 1
          data[id] = sum / bufsz
        end
        
        -- CDOE
        if EXT.CONF_audiodata_method == 1 then
          local samplebuffer = new_array(bufsz);
          GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer ) 
          samplebuffer.fft_real(FFTsz, true, 1 ) 
          local buft = {}
          local bpair_real = 0
          for binpair = 1, FFTsz, 2 do
            local Re = samplebuffer[binpair]
            local Im = samplebuffer[binpair + 1]
            local magnitude = math.sqrt(Re^2 + Im^2)
            local phase = math.atan(Im, Re)
            bpair_real = bpair_real + 1
            buft[bpair_real] = {magnitude=magnitude,phase=phase}
          end  
          frame3[#frame3+1] = buft
          if #frame3 > 3 then table.remove(frame3, 1) end 
          local cdoe_difference= DATA.AudioData_Get_CDOEdifference(frame3)
          samplebuffer.clear()
          id = id + 1
          data[id] = cdoe_difference 
          data.buft = buft
        end
      end
      DestroyAudioAccessor( accessor ) 
      
      
    -- postprocessing envelope --
    
      -- abs all values
      local max_val = 0
      for i = 1, #data do data[i] = math.abs(data[i]) max_val = math.max(max_val, data[i]) end 
      -- limit  
      if EXT.CONF_audiodata_method == 0 and EXT.CONF_audio_lim < 1 then for i = 1, #data do data[i] = math.min(EXT.CONF_audio_lim, data[i] /EXT.CONF_audio_lim) end end  
      -- normalize  / scale / noise threshold
      local norm
      local pow = EXT.CONF_audiodosquareroot 
      local scale = EXT.CONF_audiodata_method == 0
      for i = 1, #data do 
        norm = (data[i]/max_val)
        if scale == true then data[i] = norm ^pow else data[i] = norm end
        if data[i] < EXT.CONF_audio_noisethreshold then data[i] = 0 end
      end  
    
    DATA.AudioData_Smooth(data)
    
    
    -- compensate overlap --
      local outdata = data if EXT.CONF_compensateoverlap==1 and overlap ~= 1 then   local reduceddata = {} for i = 1, #data do if i%overlap == 1 then reduceddata[#reduceddata+1] = data[i] end end outdata = reduceddata  end 
    
    
    -- output --
      srct.data = outdata
      srct.max_val = max_val 
    
    return true
  end   
  ---------------------------------------------------------------------
  function DATA.AudioData_Smooth(data)-- smooth envelope --
    if EXT.CONF_smooth > 0 and EXT.CONF_smooth < 16 then 
      -- smooth
      local lastval = 0 
      for smooth = 1, EXT.CONF_smooth do 
        for i = 1, #data do 
          data[i] = (lastval + data[i] ) /2 
          lastval = data[i]  
        end 
      end
     elseif EXT.CONF_smooth&16==16 then 
      DATA.AudioData_Smooth_Median(data)
    end
  end
  ---------------------------------------------------------------------
  function DATA.AudioData_Smooth_Median(t) 
    local sz = #t
    
    --[[local L = 0.1 -- positive median weighting value 
    local m = 5 -- previous values  count
    local a = 1--  positive mean weighting value 
    local w = 0.1 -- a weighting value]]
    
    local L = EXT.CONF_smooth_median_L -- positive median weighting value 
    local m = EXT.CONF_smooth_median_m -- previous values  count
    local a = EXT.CONF_smooth_median_a--  positive mean weighting value 
    local w = EXT.CONF_smooth_median_w  -- a weighting value
    
    
    local largest_peak = 0
    local N
    local median
    
    local thresh_t = {}
    local sz = #t
    local median, mean, meancnt
    for i = 1, sz do  
      local val = t[i] 
      largest_peak = math.max(largest_peak, val)
      N = w * largest_peak
      
      median = 0
      mean = 0
      meancnt = 0
      local med_t = {}
      for j = i-m, i do
        if t[j] then
          local val_med = t[j]
          med_t[#med_t+1] = val_med
          meancnt = meancnt + 1
          mean = mean + val_med
        end
      end
      if meancnt > 0 then mean = mean / meancnt end
      table.sort(med_t)
      if #med_t>= 3 then median = med_t[math.floor(#med_t/2)] end
      
      thresh_t[i] = L * median + a * mean + N
    end
    
    local compens =m
    for i = 1, sz do 
      if t[i] ~= 0 and thresh_t[i+compens+1] then t[i]  = thresh_t[i+compens+1] end -- compensate previous block shift
    end
    
  end
    ---------------------------------------------------------------------
    function DATA.AudioData_Get_CDOEdifference(frame3)
      if not (frame3 and #frame3 == 3) then return 0 end
      
      local t = frame3[3]
      local t_prev = frame3[2]
      local t_prev2 = frame3[1]
      local sz = #t
      local sum = 0
      local Euclidean_distance, Im1, Im2, Re1, Re2, magnitude_targ, phase_targ
      local hp = 1--math.floor(sz*0.02)
      local lp = math.floor(sz*(1-0.3))
      for bin = hp, lp do
        magnitude_targ = t_prev[bin].magnitude
        phase_targ = t_prev[bin].phase + (t_prev[bin].phase - t_prev2[bin].phase)
        Re2 = magnitude_targ * math.cos(phase_targ);
        Im2 = magnitude_targ * math.sin(phase_targ); 
        Re1 = t[bin].magnitude * math.cos(t[bin].phase);
        Im1 = t[bin].magnitude * math.sin(t[bin].phase); 
        Euclidean_distance = math.sqrt((Re2 - Re1)^2 + (Im2 - Im1)^2)
        sum = sum + (Euclidean_distance)-- *(1-bin/sz) -- math.abs
      end  
      
      return sum
    end
    ---------------------------------------------------------------------
    function DATA.AudioData_BandSplit(buf, srate) -- 4-Band Splitter ported from JSFX -- desc:4-Band Splitter 
      local sz = #buf--local sz = buf.get_alloc()
      local extstate = EXT or {}
      
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
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end    
---------------------------------------------------------------------
function DATA.f02_GetDubTake(takefromsecondtake) 
  if not (DATA.AT.refdata and DATA.AT.refdata.valid) then return end
  
  local reftrack = VF_GetTrackByGUID(DATA.AT.refdata.parent_trackGUID) 
  if not reftrack then return end
  DATA.AT.dubdata = {}
  if EXT.CONF_alignitemtakes == 0 then -- normal mode
    local st = 1
    if takefromsecondtake == true then st = 2 end
    for i = st, CountSelectedMediaItems( 0 ) do
      local item = GetSelectedMediaItem(0,i-1)
      local parent_track = GetMediaItem_Track( item ) 
      local take = GetActiveTake(item) 
      if not take or (take and TakeIsMIDI(take)) then  goto skipnextdub end  
      if parent_track == reftrack then goto skipnextdub end  
      DATA.f02_GetDubTake_Sub(item,take) 
      ::skipnextdub::
    end
  end
  
  if EXT.CONF_alignitemtakes == 1 then -- per item  mode
    local item = GetSelectedMediaItem(0,0)
    if item then
      local acttake = GetActiveTake(item) 
      for takeidx = 1,  CountTakes( item ) do
        local take =  GetTake( item, takeidx-1 )
        if not take or (take and TakeIsMIDI(take)) or (take and take == acttake) then goto skipnextdub end  
        DATA.f02_GetDubTake_Sub(item,take) 
        ::skipnextdub::
      end
    end
  end
  
  
end    
---------------------------------------------------------------------
function DATA.f02_GetDubTake_Sub(item,take)
  local dubdataId = #DATA.AT.dubdata+1
  local parent_track = GetMediaItem_Track( item ) 
  local retval, takeGUID = reaper.GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
  local retval, take_name = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', '', false )
  local take_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE')
  local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
  local item_len= GetMediaItemInfo_Value( item, 'D_LENGTH' )
  
  if item_len > EXT.CONF_warning_analyze_time_dub then 
    local ret = MB('Analyzing can take long time, proceed anyway?', 'Align Takes', 3)
    if ret ~= 6 then return end
  end
  
  local src =  GetMediaItemTake_Source( take )
  local tkoffs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS'  )
  local item_srclen, lengthIsQN = GetMediaSourceLength( src )
  if EXT.CONF_cleanmarkdub&1==1 and DATA.AT.refdata and DATA.AT.refdata.edge_start  then  DATA.Markers_Clean(take,  take_rate, math.max(0,DATA.AT.refdata.edge_start - item_pos),math.min(item_len ,DATA.AT.refdata.edge_end - item_pos))  end
  
  
  DATA.AT.dubdata[dubdataId] =
    { takeGUID = takeGUID,
      --take = take, 
      take_rate = take_rate, 
      tkoffs = tkoffs,
      take_name = take_name,
      item = item,
      item_pos = item_pos,
      item_len=item_len,
      item_srclen=item_srclen, 
      item_end = item_pos+item_len,
      parent_track = parent_track,
      edge_start = DATA.AT.refdata.edge_start,
      edge_end = DATA.AT.refdata.edge_end,
    }
  
  if EXT.CONF_alignitemtakes == 1 then DATA.AT.dubdata[dubdataId].take = take end
                    
  local ret = DATA.AudioData_Get(DATA.AT.dubdata[dubdataId]) 
  if EXT.CONF_audiodata_method == 0 and EXT.CONF_ignoreemptytakes == 1 and DATA.AT.dubdata[dubdataId].max_val < EXT.CONF_ignoreemptytakes_threshold then DATA.AT.dubdata[dubdataId] = nil return end 
  local blockdestroy_start,blockdestroy_end = DATA.AudioData_CorrentSource(DATA.AT.dubdata[dubdataId])
  
  DATA.AT.dubdata[dubdataId].data_SZ = #DATA.AT.dubdata[dubdataId].data
    DATA.AT.dubdata[dubdataId].blockdestroy_start=blockdestroy_start
    DATA.AT.dubdata[dubdataId].blockdestroy_end=blockdestroy_end
  DATA.f03_GeneratePoints(DATA.AT.dubdata[dubdataId]) 
  DATA.f04_CalculateBestFit(DATA.AT.dubdata[dubdataId])  
  
  
  DATA.AT.dubdata.dirty = false
end
---------------------------------------------------------------------
function DATA.f03_GeneratePoints_Boundary(dub_t)
  if not dub_t.data_points then dub_t.data_points = {} end 
  dub_t.data_points[dub_t.blockdestroy_start+1]=1
  dub_t.data_points[dub_t.blockdestroy_end+1]=1
  
  dub_t.data_points_SZ = #dub_t.data_points
end
---------------------------------------------------------------------
function DATA.f03_GeneratePoints_FilterCloserPoint(dub_t)
  -- filter points closer than search area
    local sz = #dub_t.data_points
    local val,last_pointID
    for i = 1, sz do
      val = dub_t.data_points[i]
      if val == 1 then 
        if not last_pointID then 
          last_pointID = i 
         elseif last_pointID then
          if i-last_pointID < EXT.CONF_match_blockarea then
            dub_t.data_points[i] = 0
           else
            last_pointID = i
          end
        end
      end
    end
    
  -- filter below threshold
    local val 
    for i = 1, sz do
      val = dub_t.data_points[i]
      if val == 1 and dub_t.data and dub_t.data[i] and dub_t.data[i] < EXT.CONF_markgen_extremumarea_excludethresh then 
        dub_t.data_points[i] =  0
      end
    end
end
---------------------------------------------------------------------
function DATA.f03_GeneratePoints(dub_t)
  if EXT.CONF_markgen_algo == 0  then dub_t.data_points = DATA.f03_GeneratePoints_0_EnvelopeRiseFall(dub_t.data) end -- legacy v1 
  if EXT.CONF_markgen_algo == 1  then dub_t.data_points = DATA.f03_GeneratePoints_1_Gate(dub_t.data) end -- gate 
  if EXT.CONF_markgen_algo == 2  then dub_t.data_points = DATA.f03_GeneratePoints_2_EqiDist(dub_t.data) end -- equal
  DATA.f03_GeneratePoints_FilterCloserPoint(dub_t) 
end
---------------------------------------------------------------------
 function DATA.Markers_Clean(take, takerate, edge_start,edge_end)  
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
function DATA.AudioData_CorrentSource(t) -- fix overlap / clear 
  local mod_t = VF_CopyTable(t)
  local ovlap = EXT.CONF_window_overlap
  local wind = EXT.CONF_window
  if EXT.CONF_compensateoverlap==1 and ovlap ~= 1 then ovlap = 1 end 
  
  local sz = #mod_t.data
  
  t.blockdestroy_start = 0
  t.blockdestroy_end =sz
  
  local blockms =  DATA.AudioData_gettruewindow() --wind/ovlap
  local blockdestroy_start = 0
  local blockdestroy_end =sz
  if mod_t.item_pos>= mod_t.edge_start then blockdestroy_start = (mod_t.item_pos - mod_t.edge_start) / blockms end
  if mod_t.item_pos+mod_t.item_end< mod_t.edge_end then 
    blockdestroy_end = sz - (mod_t.edge_end - mod_t.item_end) / blockms 
  end
  for i = 1, sz do 
    if i < blockdestroy_start then mod_t.data[i] = 0 end
    if i > blockdestroy_end then mod_t.data[i] = 0 end
  end
  t = mod_t
  mod_t = nil
  return math.floor(blockdestroy_start),math.floor(blockdestroy_end)
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
---------------------------------------------------------------------
function DATA.f03_GeneratePoints_0_EnvelopeRiseFall(t0)
  local t = {}
  --local block_area = EXT.CONF_markgen_filterpoints 
  --local block_RMSarea = EXT.CONF_markgen_RMSpoints 
  local extremumarea = EXT.CONF_markgen_extremumarea_rise
  local RMSrelation = EXT.CONF_markgen_extremumarea_RMSrelation
  
  -- follow rise state
    local state,last_state
    local lastblock_rise_val
    
    for i = 1,#t0 do 
      t[i] = 0
      state = t0[i-1]  and t0[i] >= t0[i-1] 
      if (state == false and last_state == true) then -- extremum candidate
        -- make sure this point is largest in the area
        local curvalue = t0[i]
        local is_largest = true
        local com,cnt = 0, 0
        for j = i-extremumarea, i + extremumarea do
          if i~=j and t[j] then
            com = com + t0[j]
            cnt = cnt + 1
            if t[j] > curvalue then is_largest=false break end
          end
        end
        if cnt ~=0 and is_largest == true and t0[i] / (com/cnt)>RMSrelation then t[i] = 1 end
      end
      last_state = state
    end
    
  return t
end   

---------------------------------------------------------------------
function DATA.f03_GeneratePoints_1_Gate(t0)
  local t = {}
  local block_area = EXT.CONF_markgen_filterpoints2
  local threshold = EXT.CONF_markgen_threshold2
  local sz = #t0
  local lastgateid,gate_open,gate_closed
  local state = false
  local state_last = state
   
  for i = 1,sz do 
    t[i] = 0 
    state = t0[i] > threshold
    gate_open = state_last == false and state == true
    gate_closed = state_last == true and state == false 
    state_last = state
    
    if gate_open == true then 
      if not lastgateid or (lastgateid and i - lastgateid>block_area) then  
        lastgateid = i 
        t[i] = 1  
      end
    end 
  end
  
  --[[ boundary edges
  t[1] = 1
  t[#t] = 1]]
    
    --for i = 3, #t do if t[i] == 1 then t[math.floor(i/2)] = 1 break end end  -- create mdi point between 1nd and 2nd blocks
    
  return t
end    
---------------------------------------------------------------------
function DATA.f03_GeneratePoints_2_EqiDist(t0) 
  local t = {}
  local block_area = EXT.CONF_markgen_filterpoints3
  local sz = #t0
  local lastID
  
  for i = 1,sz do  
    if i%block_area == 0  then t[i] = 1 lastID = i else t[i] = 0 end
  end
  --[[ boundary edges
  t[1] = 1
  t[#t] = 1]]
  if lastID and sz - lastID < block_area then t[lastID] = 0 end -- prevent too close lines from ends
  
  
  --for i = 3, #t do if t[i] == 1 then t[math.floor(i/2)] = 1 break end end -- create mdi point between 1nd and 2nd blocks
    
  return t
end
---------------------------------------------------------------------
--function DATA.f04_CalculateBestFit(t) 
  
---------------------------------------------------------------------
function DATA.f04_CalculateBestFit(t)
  if not t.data_points then return end
  local wind = DATA.AudioData_gettruewindow()
  local t_out = {}
  local t1 = DATA.AT.refdata.data
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
    --if i == 1 then block_st = 1 end
    local block_mid = pointsID[i] 
    if i == 1 then block_st = math.max(1,block_mid - EXT.CONF_match_blockarea) end
    local block_end = pointsID[i+1]
    pointsID[i] = DATA.f04_CalculateBestFit_Find(t1,t2,block_st,block_mid,block_end)
    pointsID2[#pointsID2 + 1] = {src = block_mid, dest = pointsID[i]} 
    if EXT.CONF_match_stretchdubarray&1==1 then t2=DATA.f04_CalculateBestFit_StretchT(t2, block_st, block_end, block_mid, pointsID[i]) end
  end
  
  table.insert(pointsID2, 1,{src= 1, dest = 1}  ) -- fill start marker
  --table.insert(pointsID2, #pointsID+1, {src= pointsID[#pointsID], dest = pointsID[#pointsID]}  )-- fill end marker
  
  for i = 1, #pointsID do t_out[pointsID[i]] = 1  end -- force output
  for i = 1, #t2pts do if not t_out[i] then t_out[i] = 0 end end
  t_out[1] = 0 t_out[pointsID[#pointsID]] =0 -- clean edges
  
  -- clean same src dest
  for i = #pointsID2, 1, -1 do if pointsID2[i].src == pointsID2[i].dest then table.remove(pointsID2,i) end  end -- force output
  
  -- debug
  pointsID2_debug = {} 
  for i = 1, #pointsID2 do 
    pointsID2_debug[i] = {
      src_pos = wind * pointsID2[i].src ,
      dest_pos = wind * pointsID2[i].dest
                          }
  end 
  pointsID_debug = {} for i = 1, #pointsID  do pointsID_debug[i] = wind * pointsID[i] end
  
  --return t_out, pointsID2, t2
  t.data_points_match = t_out
  t.output_srcdest = pointsID2
  t.stretchedarray = t2
end    
    
  ---------------------------------------------------------------------
  function DATA.f04_CalculateBestFit_Find(t1,t2,block_st,block_src,block_end)
    
    if not (block_st and block_src and block_end and block_st ~= 1) then return block_src end
    local block_search = EXT.CONF_match_blockarea
    
    -- init edges for searches
      local offs =EXT.CONF_match_minblocksstartoffs
      local offs2 =EXT.CONF_match_maxblocksstartoffs
      local block_mid_search_min = math.max(block_st+offs, block_src - block_search)
      if EXT.CONF_match_searchfurtheronly == 1  then block_mid_search_min = block_src end
      local block_mid_search_max = math.min(block_end - 1 - offs2, block_src + block_search) 
    
    -- loop through difference block
      local refdub_diffence = math.huge
      local bestblock
      for midblock = block_mid_search_min, block_mid_search_max do
        local t2_stretched = DATA.f04_CalculateBestFit_StretchT(t2, block_st, block_end, block_src, midblock) 
        local tablediff = DATA.f04_CalculateBestFit_GetTableDifference(t1,t2_stretched,block_st,block_end, block_src, midblock)
        if tablediff < refdub_diffence then
          bestblock = midblock
          refdub_diffence = tablediff
        end
      end
    
    if bestblock then return bestblock else return block_src end
  end
    ---------------------------------------------------------------------
    function DATA.f04_CalculateBestFit_GetTableDifference(t1,t2,block_st,block_end, block_src, midblock) 
      local diff = 0 
      local block_end0 = block_end
      if EXT.CONF_match_firstsrgmonly == 1 then 
        block_end0 = midblock
      end
      for block = block_st, block_end0 do  
        if t1[block] and t2 and t2[block] then
          if EXT.CONF_match_ignorezeros == 1 or (EXT.CONF_match_ignorezeros == 0 and t1[block] ~= 0 and t2[block] ~= 0) then
            diff = diff + math.abs(t1[block]-t2[block]) 
          end
        end
      end 
      return diff 
    end
    ---------------------------------------------------------------------
    function DATA.f04_CalculateBestFit_GetTableMult(t1,t2,block_st,block_end, block_src, midblock) 
      local sum = 0 
      for block = block_st, block_end do  
        if t1[block] and t1[block] ~= 0 and t2 and t2[block] and t2[block] ~= 0 then sum = sum + t1[block]*t2[block] end
      end 
      return sum 
    end    
    
    
  ---------------------------------------------------------------------
  function DATA.f04_CalculateBestFit_StretchT(t, block_st, block_end, block_src, block_dest) 
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
function DATA.f05_ApplyOutput(is_major)  
  if not DATA.AT.dubdata then return end
  -- get true window
    local wind = DATA.AudioData_gettruewindow()  
  for dubdataID = 1, #DATA.AT.dubdata do
    -- get table data
      local take_dubdata = DATA.AT.dubdata[dubdataID]
      if not take_dubdata then goto skipdubtake2 end 
    -- vars
      local output_srcdest = take_dubdata.output_srcdest
      local take =      GetMediaItemTakeByGUID( 0, take_dubdata.takeGUID)
      local takeoffs =  take_dubdata.tkoffs
      local takerate =  take_dubdata.take_rate
      local item =      take_dubdata.item
      local item_pos =  take_dubdata.item_pos
      local item_len =  take_dubdata.item_len
      local item_srclen =  take_dubdata.item_srclen
      
    -- validate take
      if not (take and ValidatePtr2( 0, take, 'MediaItem_Take*' ))  then goto skipdubtake2 end   
      
    -- clean markers
      DATA.Markers_Clean(take,  takerate, -0.01 + math.max(0,DATA.AT.refdata.edge_start - item_pos),0.01 + math.min(item_len ,DATA.AT.refdata.edge_end - item_pos)) 
    -- validate output_srcdest
      if not output_srcdest then goto skipdubtake2 end
    -- get value
      local val = DATA.AT.align_strength
    -- add markers      
      local last_src_pos
      local last_dest_pos 
      for i = 1, #output_srcdest do 
        local tpair = output_srcdest[i]
        
        local src_pos = DATA.f05_ApplyOutput_ProjPosToStretchMarkerPos(tpair.src * wind + DATA.AT.refdata.edge_start, item_pos, takerate) 
        local dest_pos = DATA.f05_ApplyOutput_ProjPosToStretchMarkerPos(tpair.dest * wind + DATA.AT.refdata.edge_start, item_pos, takerate) 
        local dest_pos = src_pos + (dest_pos-src_pos) *val
        local src_pos0 = DATA.f05_ApplyOutput_ProjPosToStretchMarkerSrcPos(tpair.src * wind + DATA.AT.refdata.edge_start, item_pos, takerate, takeoffs) 
        
         tpair.dest_pos=dest_pos
        local is_inside_boundary = dest_pos < math.min(item_len ,DATA.AT.refdata.edge_end - item_pos) and dest_pos > math.max(0,DATA.AT.refdata.edge_start - item_pos)
        
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
      DATA.f05_ApplyOutput_SetTakeModes(item)
      if EXT.CONF_post_zerocross ==1 then  DATA.f05_ApplyOutput_QuantizeSMtoZeroCross( reaper.GetActiveTake( item )) end 
    end
    if item then UpdateItemInProject( item ) end
    ::skipdubtake2::
  end
end 
---------------------------------------------------------------------   
function DATA.f05_ApplyOutput_ProjPosToStretchMarkerPos(projpos, item_pos, takerate) 
  local markpos = takerate * (projpos - item_pos)
  return markpos
end
--------------------------------------------------------------------- 
function DATA.f05_ApplyOutput_ProjPosToStretchMarkerSrcPos(projpos, item_pos, takerate, takeoffs) 
  local markpos = takeoffs + (projpos - item_pos)*takerate
  return markpos
end
--------------------------------------------------------------------- 
function DATA.f05_ApplyOutput_SetTakeModes(item)
  for takeidx = 1,  CountTakes( item ) do
    local take =  GetTake( item, takeidx-1 )
    reaper.SetMediaItemTakeInfo_Value( take, 'I_PITCHMODE', (EXT.CONF_post_pshift<<16) + EXT.CONF_post_pshiftsub ) --  : int * : pitch shifter mode, -1=project default, otherwise high 2 bytes=shifter, low 2 bytes=parameter
    reaper.SetMediaItemTakeInfo_Value( take, 'I_STRETCHFLAGS', EXT.CONF_post_smmode ) --  : int * : stretch marker flags (&7 mask for mode override: 0=default, 1=balanced, 2/3/6=tonal, 4=transient, 5=no pre-echo)
    reaper.SetMediaItemTakeInfo_Value( take, 'F_STRETCHFADESIZE',EXT.CONF_post_strmarkfdsize ) 
  end
end
---------------------------------------------------------------------
function DATA.f05_ApplyOutput_QuantizeSMtoZeroCross(take) 
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
  local sm_t = {}
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
function DATA.AudioData_gettruewindow() -- get real block duration
  local wind = EXT.CONF_window
  if EXT.CONF_compensateoverlap ~= 1 then 
    wind = wind/EXT.CONF_window_overlap
  end
  return wind
end
--------------------------------------------------------------------- 
function DATA.PRESET_SavePreset()
  -- find first free preset id
    local id
    for i = 1, 128 do if not DATA.presets.user[i] then id = i break end end
    if not id then return end
  
  -- get new name
    local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', EXT.CONF_NAME)
    if not retval then return end
    if retvals_csv~= '' then EXT.CONF_NAME = retvals_csv end
  -- save
    DATA.PRESET_StorePresetData(id)
    DATA.PRESET_GetExtStatePresets()
end
--------------------------------------------------------------------- 
function DATA.PRESET_StorePresetData(id)
  local str = ''
  for key in spairs(EXT) do  if key:match('CONF_') then str = str..'\n'..key..'='..EXT[key] end end
  SetExtState(DATA.ES_key, 'PRESET'..id, DATA.PRESET_encBase64(str), true)
end 
--------------------------------------------------------------------- 
function DATA.PRESET_ApplyPreset(preset_t)  
  if not preset_t then return end
  
  -- align takes 3+ 
  if not preset_t.CONF_audiodata_method then preset_t.CONF_audiodata_method = 0 end
  
  for key in pairs(preset_t) do
    if key:match('CONF_') then 
      local presval = preset_t[key]
      EXT[key] = tonumber(presval) or presval
    end
  end
  
  
  EXT:save() 
end
--------------------------------------------------------------------- 
  function DATA.PRESET_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
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
--------------------------------------------------------------------- 
function DATA.PRESET_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
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
--------------------------------------------------------------------- 
function DATA.PRESET_RemoveUserPreset(id) 
  if HasExtState(DATA.ES_key, 'PRESET'..id) then DeleteExtState(DATA.ES_key, 'PRESET'..id, true ) end
end
--------------------------------------------------------------------- 
function DATA.PRESET_RestoreDefaults(key, UI)
  if not key then
    for key in pairs(EXT) do
      if key:match('CONF_') or (UI and UI == true and key:match('UI_'))then
        local val = EXT_defaults[key]
        if val then EXT[key]  = val end
      end
    end
   else
    local val = EXT_defaults[key]
    if val then EXT[key]  = val end
  end
  
  EXT:save() 
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetExtStatePresets()
  DATA.presets = {user={},factory={}}
  
  -- load 32 user presets
  for id_out=1, 128 do
    local str = GetExtState( DATA.ES_key , 'PRESET'..id_out)
    local str_dec = DATA.PRESET_decBase64(str)
    if str_dec~= '' then 
      local tid = #DATA.presets.user+1
      DATA.presets.user[tid] = {str=str}
      for line in str_dec:gmatch('[^\r\n]+') do
        local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
        if key and value and key:match('CONF_') then DATA.presets.user[tid][key]= tonumber(value) or value end
      end   
    end
  end
  
  -- load factory presets
  for extkey in spairs(EXT) do
    if extkey:match('FPRESET%d+')then
      local str = EXT[extkey]
      local str_dec = DATA.PRESET_decBase64(str)
      if str_dec~= '' then 
        local tid = #DATA.presets.factory+1
        DATA.presets.factory[tid] = {str=str}
        for line in str_dec:gmatch('[^\r\n]+') do
          local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
          if key and value and key:match('CONF_') then
            DATA.presets.factory[tid][key]= tonumber(value) or value
          end
        end  
        if DATA.presets.factory[tid].CONF_NAME then
          DATA.presets.factory[tid].CONF_NAME = DATA.presets.factory[tid].CONF_NAME:gsub('%[factory%]','')
        end
      end
    end
  end
  
end
----------------------------------------------------------------------------------------- 
function main() 
  EXT_defaults = VF_CopyTable(EXT)
  DATA.PRESET_GetExtStatePresets()
  UI.MAIN() 
end  
-----------------------------------------------------------------------------------------
main()
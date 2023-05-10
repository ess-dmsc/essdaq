
-- Copyright (C) 2023 European Spallation Source ERIC
-- Wireshark plugin for dissecting TimePix3 UDP and TimePix3 Control TCP

-- bytes
datasize = 8

function i64_ax(h,l)
 local o = {}; o.l = l; o.h = h; return o;
end -- +assign 64-bit v.as 2 regs

function i64u(x)
 return ( ( (bit.rshift(x,1) * 2) + bit.band(x,1) ) % (0xFFFFFFFF+1));
end -- keeps [1+0..0xFFFFFFFFF]


function i64_toInt(a)
  return (a.l + (a.h * (0xFFFFFFFF+1)));
end -- value=2^53 or even less, so better use a.l value

function i64_toString(a)
  local s1=string.format("%x",a.l);
  local s2=string.format("%x",a.h);
  return "0x"..string.upper(s2)..string.upper(s1);
end

-- -----------------------------------------------------------------------------------------------
-- the protocol dissector
-- -----------------------------------------------------------------------------------------------
timepix_proto = Proto("timepix","TimePix3 protocol")

function timepix_proto.dissector(buffer, pinfo, tree)
	pinfo.cols.protocol = "TIMEPIX"
	protolen = buffer():len()
	timepixhdr = tree:add(timepix_proto,buffer(),"Timepix Header")

  bytesleft = protolen
  offset = 0

  local cookie = 0x53534501
  if (buffer(offset, 4):le_uint() == cookie) then
    local counter =                   buffer(offset + 4,  4):le_uint()
    local pulseTimeSeconds =          buffer(offset + 8,  4):le_uint()
    local pulseTimeNanoseconds =      buffer(offset + 12, 4):le_uint()
    local prevPulseTimeSeconds =      buffer(offset + 16, 4):le_uint()
    local prevPulseTimeNanoseconds =  buffer(offset + 20, 4):le_uint()
    dtree = timepixhdr:add(buffer(offset, 8),string.format("EVR timestamp, counter %d, pulseTimeSeconds %d, pulseTimeNanoseconds %d, prevPulseTimeSeconds %d, prevPuseTimeNanoseconds %d", counter, pulseTimeSeconds, pulseTimeNanoseconds, prevPulseTimeSeconds, prevPulseTimeNanoseconds))
    dtree:add(buffer(offset + 4, 4),  string.format("Counter                  %d", counter))
    dtree:add(buffer(offset + 8, 4),  string.format("pulseTimeSeconds         %d", pulseTimeSeconds))
    dtree:add(buffer(offset + 12, 4), string.format("pulseTimeNanoseconds     %d", pulseTimeNanoseconds))
    dtree:add(buffer(offset + 16, 4), string.format("prevPulseTimeSeconds     %d", prevPulseTimeSeconds))
    dtree:add(buffer(offset + 20, 4), string.format("prevPulseTimeNanoseconds %d", prevPulseTimeNanoseconds))
  else
    while (bytesleft >= datasize)
    do
      -- Readout Data (Timepix specific)
      
      -- reading 3 overlapping chunks of data, le_uint doesn't support 64bit ints
      -- and 'data' field of timepix readout spans first 4 and last 4 bytes
      local readout_high =    buffer(offset + 4, 4):le_uint()
      local readout_bytes_2 = buffer(offset + 2, 4):le_uint()
      local readout_low =     buffer(offset    , 4):le_uint()

      --- applying mask and shifts for each element of readout
      local readout_type = bit.rshift(bit.band(readout_high, 0xF0000000), 28)

      if (readout_type == 11) then
        local dcol =         bit.rshift(bit.band(readout_high, 0x0FE00000), 21) 
        local spix =         bit.rshift(bit.band(readout_high, 0x001F8000), 15)
        local pix =          bit.rshift(bit.band(readout_high, 0x00007000), 12) 
        local data =         bit.band(readout_bytes_2, 0x0FFFFFFF)
        local spidr_time =   bit.band(readout_low, 0x0000FFFF)
      

        dtree = timepixhdr:add(buffer(offset, 8),string.format("Pixel readout, type %2d, dcol %d, spix %d, pix %d, data %d, spidr_time %d",
        readout_type, dcol, spix, pix, data, spidr_time))

      elseif (readout_type == 6) then
        local trigger_counter = bit.rshift(bit.band(readout_high, 0x00FFF000), 12)
        local timestamp =       bit.lshift(bit.band(readout_high, 0x00000FFF), 23) + bit.rshift(bit.band(readout_low, 0xFFFFFE00), 9)
        local stamp =           bit.rshift(bit.band(readout_low, 0x000001E0), 5)
        local reserved =        bit.band(readout_low, 0x0000001F)
        
        dtree = timepixhdr:add(buffer(offset, 8),string.format("TDC timestamp, type %2d, trigger_counter %d, stamp %d, reserved %d",
        readout_type, trigger_counter, timestamp, stamp, reserved))

      elseif (readout_type == 4) then
        local timestamp = bit.lshift(bit.band(readout_high, 0x00FFFFFF), 24) + bit.rshift(bit.band(readout_low, 0xFFFFFF00), 8)
        local stamp =     bit.rshift(bit.band(readout_low, 0x000000F0), 4)
        local reserved =  bit.band(readout_low, 0x0000000F)
        dtree = timepixhdr:add(buffer(offset, 8),string.format("Global timestamp, type %2d, timestamp %d, stamp %d, reserved %d",
        readout_type, timestamp, stamp, reserved))
      else
        dtree = timepixhdr:add(buffer(offset, 8),string.format("unknown type %2d",
        readout_type))
      end

    

      bytesleft = bytesleft - datasize
      offset = offset + datasize
  
    end
  end
end

--  TIMEPIX config data

-- protocol commands and register addresses

cmd = {
  [0x0111] = "Device ID",
  [0x0114] = "Get IPAddr Dest",
  [0x0115] = "Set IPAddr Dest",
  [0x0117] = "Get Server Port",
  [0x0118] = "Set Server Port",
  [0x011A] = "Get DAC",
  [0x011B] = "Set DAC",
  [0x0121] = "Set CTPR",

  [0x022A] = "Set PixConf",
  [0x022E] = "Reset Pixels",

  [0x0331] = "Set TP PeriodPhase",
  [0x0332] = "Set TP Number",
  [0x0335] = "Set Gen Config",
  [0x0336] = "Get PLL Config",
  [0x0338] = "Set SenseDAC",

  [0x0445] = "Set Seq Readout",
  [0x0446] = "Set DDriven Readout",
  [0x0447] = "Pause Readout",

  [0x0549] = "Get Remote Temp",
  [0x054A] = "Get Local Temp",
  [0x054D] = "Get AVDD Now",
  [0x054E] = "Get SPIDER ADC",
  [0x0550] = "Restart Timers",
  [0x0551] = "Reset Timer",
  [0x0563] = "Set Readout Speed",
  [0x0564] = "Get Readout Speed",
  [0x056D] = "Get VDD Now",

  [0x0783] = "Get SPIDER Register",
  [0x0784] = "Set SPIDER Register",

  [0x0901] = "Get SW Version",
  [0x0902] = "Get FW Version",
  [0x0905] = "Get Header Filter",
  [0x0906] = "Set Header Filter",
  [0x0907] = "Reset",
  [0x090F] = "Board ID",
}


-- helper variable and functions

function getcmdtype(t)
if t == 0
then
return "Request "
else
return "Response"
end
end


function arr2str(arr, val)
res = arr[val]
if (res == nil)
then
res = string.format("[Unknown 0x%04x]", val)
end
return res
end

function cmd2str(type)
return arr2str(cmd, type)
end


-- -----------------------------------------------------------------------------------------------
-- the protocol dissectors
-- -----------------------------------------------------------------------------------------------

-- ------------------------------------------------------
-- CONTROL - TCP port 50000
-- ------------------------------------------------------

tpix_ctrl = Proto("tpix3ctrl","TimePix3 Control")

function tpix_ctrl.dissector(buffer,pinfo,tree)
pinfo.cols.protocol = "TIMEPIX CTL"
local protolen = buffer():len()
local header = tree:add(tpix_ctrl,buffer(),"Timepix Header")

local reqresp = buffer(0, 2):uint()
local command = buffer(2, 2):uint()
local len = buffer(6, 2):uint()
local cmdarg = buffer(16, 4):uint()
local remain = protolen - 20

header:add(buffer( 0, 2), string.format("type    : %s", getcmdtype(reqresp)))
header:add(buffer( 2, 2), string.format("command : %s", cmd2str(command)))
header:add(buffer( 6, 2), string.format("length  : %s", len))
header:add(buffer(16, 4), string.format("cmd arg : 0x%08x (%d)", cmdarg, cmdarg))

if (remain == 0) then
pinfo.cols.info = string.format("%s - %-24s 0x%08x", getcmdtype(reqresp), cmd2str(command), cmdarg)
else
pinfo.cols.info = string.format("%s - %-24s 0x%08x (+ %d more bytes)", getcmdtype(reqresp), cmd2str(command), cmdarg, remain)
end
end


-- Register the protocol

udp_table = DissectorTable.get("udp.port")
udp_table:add(8192, timepix_proto)

tcp_table = DissectorTable.get("tcp.port")
tcp_table:add(50000, tpix_ctrl)

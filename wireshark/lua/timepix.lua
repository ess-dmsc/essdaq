
-- Copyright (C) 2023 European Spallation Source ERIC
-- Wireshark plugin for dissecting TimePix3 UDP

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

  while (bytesleft >= datasize)
  do
    -- Readout Data (Timepix specific)
   
   -- reading 3 overlapping chunks of data, le_uint doesn't support 64bit ints
   -- and 'data' field of timepix readout spans first 4 and last 4 bytes
   local readout_bytes_1 = buffer(offset+4, 4):le_uint()
   local readout_bytes_2 = buffer(offset+2, 4):le_uint()
   local readout_bytes_3 = buffer(offset, 4):le_uint()
   
   --- applying mask and shifts for each element of readout
   local readout_type = bit.rshift(bit.band(readout_bytes_1, 0xF0000000), 28)
   local dcol =         bit.rshift(bit.band(readout_bytes_1, 0x0FE00000), 21) 
   local spix =         bit.rshift(bit.band(readout_bytes_1, 0x001F8000), 15)
   local pix =          bit.rshift(bit.band(readout_bytes_1, 0x00007000), 12) 
   local data =         bit.band(readout_bytes_2, 0x0FFFFFFF)
   local spidr_time =   bit.band(readout_bytes_3, 0x0000FFFF)
   

    dtree = timepixhdr:add(buffer(offset, 8),string.format("type %d, dcol %d, spix %d, pix %d, data %d, spidr_time %d",
    readout_type, dcol, spix, pix, data, spidr_time))

    bytesleft = bytesleft - datasize
    offset = offset + datasize
  end

end

-- Register the protocol
udp_table = DissectorTable.get("udp.port")
added = udp_table:add(9888, timepix_proto)
print(string.format("added: %s\n", tostring(added)))

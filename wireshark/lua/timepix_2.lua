
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
   local dcol = buffer(offset + 0, 2):bitfield(4, 7)
   local spix = buffer(offset + 1, 2):bitfield(3, 6)
   local pix = buffer(offset + 2, 1):bitfield(1, 3)
   local data = buffer(offset + 2, 4):bitfield(4, 28)
   local spidr_time = buffer(offset + 6, 2):bitfield(0, 16)     

    dtree = timepixhdr:add(buffer(offset, 8),string.format("dcol %d, spix %d, pix %d, data %d, spidr_time %d",
    dcol, spix, pix, data, spidr_time))

    bytesleft = bytesleft - datasize
    offset = offset + datasize
  end

end

-- Register the protocol
udp_table = DissectorTable.get("udp.port")
added = udp_table:add(8192, timepix_proto)
print(string.format("added: %s\n", tostring(added)))

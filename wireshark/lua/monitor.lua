
-- Copyright (C) 2023 - 2025 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Beam Monitor Readout

-- helper variable and functions

require "common"

datasize = 16
dataheadersize = 4
resolution = 11.36 -- ns per clock tick for 88.025 MHz which is ESS time

-- monitor type identifier

typearr = {
	[0x00] = "Unknown Monitor",
	[0x01] = "TTL Monitor    ",
	[0x02] = "Monitor Type 2 ",
	[0x03] = "Monitor Type 3 ",
	[0x04] = "Monitor Type 4 ",
	[0x05] = "Monitor Type 5 ",
	[0x06] = "Monitor Type 6 "
}

function arr2str(arr, val)
  res = arr[val]
  if (res == nil)
  then
      res = "[Undefined]"
  end
  return res
end

function type2str(typeid)
  return arr2str(typearr, typeid)
end

-- -----------------------------------------------------------------------------------------------
-- the protocol dissector
-- -----------------------------------------------------------------------------------------------
essmonitor_proto = Proto("ess_monitor","ESSR Monitor")

function essmonitor_proto.dissector(buffer, pinfo, tree)

	esshdrsize = essheader("ESSR/MONITOR", essmonitor_proto, buffer, pinfo, tree)

  bytesleft = protolen - esshdrsize
  offset = esshdrsize

  readouts  = 1

  while ( bytesleft >= dataheadersize + datasize )
  do
    fiberid  = buffer(offset                      , 1):uint()
		ringid   = fiberid//2
    fenid    = buffer(offset                  +  1, 1):uint()
    dlen     = buffer(offset                  +  2, 2):le_uint()
	  th       = buffer(offset + dataheadersize +  0, 4):le_uint()
    tl       = buffer(offset + dataheadersize +  4, 4):le_uint()
		type     = buffer(offset + dataheadersize +  8, 1):uint()
    channel  = buffer(offset + dataheadersize +  9, 1):uint()
		adc      = buffer(offset + dataheadersize + 10, 2):le_uint()
    xpos     = buffer(offset + dataheadersize + 12, 2):le_uint()
		ypos     = buffer(offset + dataheadersize + 14, 2):le_uint()


    -- make a readout summary
    dtree = tree:add(buffer(offset, dataheadersize + datasize),
            string.format("%3d Fiber/Ring/FEN %u/%d/%u, Type: %d, " ..
						              "Channel %d, Pos (%3d, %3d), ADC %5d",
            readouts, fiberid, ringid, fenid, type, channel, xpos, ypos, adc))

    -- -- make an expanding tree with details of the fields
    -- dtree:add(buffer(offset +                   0, 1), string.format("Fiber   %d",    fiberid))
    -- dtree:add(buffer(offset +                   1, 1), string.format("FEN     %d",    fenid))
    -- dtree:add(buffer(offset +                   2, 2), string.format("Length  %d",    dlen))
    -- dtree:add(buffer(offset + dataheadersize +  0, 4), string.format("Time Hi 0x%04x", th))
    -- dtree:add(buffer(offset + dataheadersize +  4, 4), string.format("Time Lo 0x%04x", tl))
		-- dtree:add(buffer(offset + dataheadersize +  8, 1), string.format("Type      %d",   type))
    -- dtree:add(buffer(offset + dataheadersize +  9, 1), string.format("Channel   %d",   channel))
		-- dtree:add(buffer(offset + dataheadersize + 10, 2), string.format("ADC       %d",   adc))
		-- dtree:add(buffer(offset + dataheadersize + 12, 2), string.format("XPos      %d",   xpos))
		-- dtree:add(buffer(offset + dataheadersize + 14, 2), string.format("YPos      %d",   ypos))


    bytesleft = bytesleft - datasize - dataheadersize
    offset    = offset + dataheadersize + datasize
	  readouts  = readouts + 1
  end
	-- pinfo.cols.info = string.format("Type: 0x%x, OQ: %d", type, oq)
end


register_protocol(essmonitor_proto)

-- Copyright (C) 2019 - 2025 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Readout data for DREAM (CDT)

-- helper variable and functions

-- CDT/DREAM Packet Structure
-- Time HI [31:0]
-- Time LO [31:0]
-- Cathode [15:8] Anode [7:0]

require "common"

datasize = 16

-- -----------------------------------------------------------------------------------------------
-- the protocol dissector
-- -----------------------------------------------------------------------------------------------
essdream_proto = Proto("essreadout","ESSR Protocol")

function essdream_proto.dissector(buffer, pinfo, tree)

	esshdrsize = essheader("ESSR/DREAM", essdream_proto, buffer, pinfo, tree)

  bytesleft = protolen - esshdrsize
  offset = esshdrsize

  while (bytesleft >= datasize)
  do
    -- Readout Header (RING, FEN, Size)
    fiberid = buffer(offset    , 1):uint()
    ringid = fiberid/2
    fenid  = buffer(offset + 1, 1):uint()
    dlen   = buffer(offset + 2, 2):le_uint()
    dtree = esshdr:add(buffer(offset, 4),string.format("Fiber %d, Ring %d, FEN %d, Length %d",
               fiberid, ringid, fenid, dlen))

    -- Readout Data (DREAM specific)
    th      = buffer(offset +  4, 4):le_uint()
    tl      = buffer(offset +  8, 4):le_uint()
    OM      = buffer(offset + 12, 1):uint()
    unused  = buffer(offset + 13, 1):uint()
    cathode = buffer(offset + 14, 1):uint()
    anode   = buffer(offset + 15, 1):uint()
    dtree:add(buffer(offset + 0, datasize),string.format(
        "time  0x%08x %08x, cathode %5d, anode%5d", th, tl, cathode, anode))

    bytesleft = bytesleft - datasize
    offset = offset + datasize
  end
end


register_protocol(essdream_proto)


-- Copyright (C) 2019 - 2025 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Readout data for LOKI

-- helper variable and functions

require "common"

datasize = 20
dataheadersize = 4

-- -----------------------------------------------------------------------------------------------
-- the protocol dissector
-- -----------------------------------------------------------------------------------------------
esscaen_proto = Proto("essreadout","ESSR Protocol")

function esscaen_proto.dissector(buffer, pinfo, tree)


  esshdrsize = essheader("ESSR/BIFROST", esscaen_proto, buffer, pinfo, tree)

  bytesleft = protolen - esshdrsize
  offset = esshdrsize

  while bytesleft >= 24
  do
    fiber  = buffer(offset +  0, 1):uint()
    fenid  = buffer(offset +  1, 1):uint()
    dlen   = buffer(offset +  2, 2):le_uint()
    th     = buffer(offset +  4, 4):le_uint()
    tl     = buffer(offset +  8, 4):le_uint()
    om     = buffer(offset + 12, 1):uint()
    group  = buffer(offset + 13, 1):uint()
    unused = buffer(offset + 14, 2):le_uint()
    ampa   = buffer(offset + 16, 2):le_uint()
    ampb   = buffer(offset + 18, 2):le_uint()
    ampc   = buffer(offset + 20, 2):le_uint()
    ampd   = buffer(offset + 22, 2):le_uint()

    ringid = fiber/2

    dtree = esshdr:add(buffer(offset, 24),string.format("Fiber %2d, Ring %2d, FEN %2d - Time 0x%08x 0x%08x - OM 0x%02x, Group %2d, A %5d, B %5d, C %5d, D %5d",
               fiber, ringid, fenid, th, tl, om, group, ampa, ampb, ampc, ampd))

    if bytesleft < 24 then
        return
    end

    offset = offset + 24
    bytesleft = bytesleft - 24

  end
	-- pinfo.cols.info = string.format("Type: 0x%x, OQ: %d", type, oq)
end


register_protocol(esscaen_proto)

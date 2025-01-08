
-- Copyright (C) 2019 - 2025 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Readout data for LOKI

require "common"

-- -----------------------------------------------------------------------------------------------
-- the protocol dissector
-- -----------------------------------------------------------------------------------------------
esscaen_proto = Proto("essreadout","ESSR Protocol")

function esscaen_proto.dissector(buffer, pinfo, tree)
  -- helper variable and functions

  esshdrsize = 30
  datasize = 20
  dataheadersize = 4
  --
	pinfo.cols.protocol = "ESSR/LOKI"
	protolen = buffer():len()
	esshdr = tree:add(esscaen_proto,buffer(),"ESSR Header")

  padding1= buffer(0,1):uint()
  version = buffer(1,1):uint()
  cookie =  buffer(2,3):uint()
  type =    buffer(5,1):uint()
  length =  buffer(6,2):le_uint()
  oq =      buffer(8,1):uint()
  tmsrc =   buffer(9,1):uint()

  pth =     buffer(10, 4):le_uint()
  ptl =     buffer(14, 4):le_uint()
  ppth =    buffer(18, 4):le_uint()
  pptl =    buffer(22, 4):le_uint()
  seqno =   buffer(26, 4):le_uint()

	esshdr:add(buffer( 0,1),string.format("Padding  0x%02x", padding1))
  esshdr:add(buffer( 1,1),string.format("Version  %d", version))
  esshdr:add(buffer( 2,3),string.format("Cookie   0x%x", cookie))
  esshdr:add(buffer( 5,1),string.format("Type     0x%02x", type))
  esshdr:add(buffer( 6,2),string.format("Length   %d", length))
  esshdr:add(buffer( 8,1),string.format("OutputQ  %d", oq))
  esshdr:add(buffer( 9,1),string.format("TimeSrc  %d", tmsrc))
  esshdr:add(buffer(10,8),string.format("PulseT   0x%04x%04x", pth, ptl))
  esshdr:add(buffer(18,8),string.format("PrevPT   0x%04x%04x", ppth, pptl))
  esshdr:add(buffer(26,4),string.format("SeqNo    %d", seqno))

  if version == 1 then
    esshdrsize = esshdrsize + 2
    padding2 = buffer(30, 2):le_uint()
    esshdr:add(buffer(30,2),string.format("V1 pad   %d", padding2))
  end

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

    dtree = esshdr:add(buffer(offset, 24),string.format("Fiber %2d, Ring %2d, FEN %2d, OM 0x%02x, Group %2d, A %5d, B %5d, C %5d, D %5d",
               fiber, ringid, fenid, om, group, ampa, ampb, ampc, ampd))

    if bytesleft < 24 then
        return
    end

    offset = offset + 24
    bytesleft = bytesleft - 24

  end
end


--
-- Register the protocol
--

udp_table = DissectorTable.get("udp.port")

efuport = os.getenv("EFUPORT")
if efuport ~= nil then
  udp_table:add(efuport, esscaen_proto)
else
  udp_table:add(9000, esscaen_proto)
end

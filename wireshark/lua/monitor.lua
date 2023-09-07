
-- Copyright (C) 2019 - 2023 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Readout data for TTL monitor

-- -----------------------------------------------------------------------------------------------
-- the protocol dissector
-- -----------------------------------------------------------------------------------------------
essttlmon_proto = Proto("ess_ttlmon","ESSR Protocol Mon")

function essttlmon_proto.dissector(buffer, pinfo, tree)
	-- helper variable and functions
	esshdrsize = 30
	datasize = 12
	dataheadersize = 4
	resolution = 11.36 -- ns per clock tick for 88.025 MHz which is ESS time
	--

	pinfo.cols.protocol = "ESSR/TTL MON"
	protolen = buffer():len()
	esshdr = tree:add(essttlmon_proto,buffer(0, esshdrsize),"ESSR Header")

  padding = buffer( 0, 1):uint()
  version = buffer( 1, 1):uint()
  cookie  = buffer( 2, 3):uint()
  type    = buffer( 5, 1):uint()
  length  = buffer( 6, 2):le_uint()
  oq      = buffer( 8, 1):uint()
  tmsrc   = buffer( 9, 1):uint()
  pth     = buffer(10, 4):le_uint()
  ptl     = buffer(14, 4):le_uint()
  ppth    = buffer(18, 4):le_uint()
  pptl    = buffer(22, 4):le_uint()
  seqno   = buffer(26, 4):le_uint()

  esshdr:add(buffer( 0,1),string.format("Padding  0x%02x", padding))
  esshdr:add(buffer( 1,1),string.format("Version  %d", version))
  esshdr:add(buffer( 2,3),string.format("Cookie   0x%x", cookie))
  esshdr:add(buffer( 5,1),string.format("Type     0x%02x", type))
  esshdr:add(buffer( 6,2),string.format("Length   %d", length))
  esshdr:add(buffer( 8,1),string.format("OutputQ  %d", oq))
  esshdr:add(buffer( 9,1),string.format("TimeSrc  %d", tmsrc))

  esshdr:add(buffer(10,8),string.format("PulseT   0x%04x 0x%04x", pth, ptl))
  esshdr:add(buffer(18,8),string.format("PrevPT   0x%04x 0x%04x", ppth, pptl))
  esshdr:add(buffer(26,4),string.format("SeqNo    0x%04x", seqno))

  bytesleft = protolen - esshdrsize
  offset    = esshdrsize
  readouts  = 1

  while ( bytesleft >= dataheadersize + datasize )
  do
    fiberid  = buffer(offset                      , 1):uint()
		ringid   = fiberid/2
    fenid    = buffer(offset                  +  1, 1):uint()
    dlen     = buffer(offset                  +  2, 2):le_uint()
	  th       = buffer(offset + dataheadersize +  0, 4):le_uint()
    tl       = buffer(offset + dataheadersize +  4, 4):le_uint()
    pos      = buffer(offset + dataheadersize +  8, 1):uint()
		ch       = buffer(offset + dataheadersize +  9, 1):uint()
    adc      = buffer(offset + dataheadersize + 10, 2):uint()



    -- make a readout summary
    dtree = tree:add(buffer(offset, dataheadersize + datasize),
            string.format("MON Readout %3d, Fiber %u, Ring %d, FEN %d, Pos:%3d, " ..
                          "CH:%3d, ADC %5d",
            readouts, fiberid, ringid, fenid, pos, ch, adc))

    -- make an expanding tree with details of the fields
    dtree:add(buffer(offset +                   0, 1), string.format("Fiber   %d",    fiberid))
    dtree:add(buffer(offset +                   1, 1), string.format("FEN     %d",    fenid))
    dtree:add(buffer(offset +                   2, 2), string.format("Length  %d",    dlen))
    dtree:add(buffer(offset + dataheadersize +  0, 4), string.format("Time Hi 0x%04x", th))
    dtree:add(buffer(offset + dataheadersize +  4, 4), string.format("Time Lo 0x%04x", tl))
    dtree:add(buffer(offset + dataheadersize +  8, 1), string.format("Pos       %d",   pos))
		dtree:add(buffer(offset + dataheadersize +  9, 1), string.format("Channel   %d",   ch))
		dtree:add(buffer(offset + dataheadersize + 10, 1), string.format("ADC       %d",   adc))


    bytesleft = bytesleft - datasize - dataheadersize
    offset    = offset + dataheadersize + datasize
	  readouts  = readouts + 1
  end
	-- pinfo.cols.info = string.format("Type: 0x%x, OQ: %d", type, oq)
end

-- Register the protocol
udp_table = DissectorTable.get("udp.port")
udp_table:add(9810, essttlmon_proto)
udp_table:add(9010, essttlmon_proto)
udp_table:add(9000, essttlmon_proto)
udp_table:add(9001, essttlmon_proto)

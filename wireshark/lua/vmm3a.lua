
-- Copyright (C) 2019 - 2025 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Readout data for VMM3a

-- helper variable and functions

datasize = 16
dataheadersize = 4
resolution = 11.36 -- ns per clock tick for 88.025 MHz which is ESS time

-- -----------------------------------------------------------------------------------------------
-- the protocol dissector
-- -----------------------------------------------------------------------------------------------
essvmm3a_proto = Proto("ess_vmm3a","ESSR Protocol")

function essvmm3a_proto.dissector(buffer, pinfo, tree)

	esshdrsize = essheader("ESSR/VMM3a", essvmm3a_proto, buffer, pinfo, tree)

  bytesleft = protolen - esshdrsize
  offset = esshdrsize


  readouts  = 1
  while ( bytesleft >= dataheadersize + datasize )
  do
    fiberid  = buffer(offset                      , 1):uint()
		ringid   = fiberid/2
    fenid    = buffer(offset                  +  1, 1):uint()
    dlen     = buffer(offset                  +  2, 2):le_uint()
	  th       = buffer(offset + dataheadersize +  0, 4):le_uint()
    tl       = buffer(offset + dataheadersize +  4, 4):le_uint()
    bc       = buffer(offset + dataheadersize +  8, 2):le_uint()
    othr_adc = buffer(offset + dataheadersize + 10, 2):le_uint()
    geo      = buffer(offset + dataheadersize + 12, 1):uint()
    tdc      = buffer(offset + dataheadersize + 13, 1):uint()
    vmmid    = buffer(offset + dataheadersize + 14, 1):uint()
    chno     = buffer(offset + dataheadersize + 15, 1):uint()

    tl_ns    = tl * resolution
    adc      = bit.band(othr_adc, 0x03ff)
    othr     = bit.band(bit.rshift(othr_adc, 15), 1)
    overflow = math.floor(bit.rshift(tl, 1) / 4096)

    -- if bit 7 of geo is zero - Readout, else BC calibration
    if bit.band(geo, 0x80) == 0 then
      -- make a readout summary
	    dtree = tree:add(buffer(offset, dataheadersize + datasize),
              string.format("%3d Readout            , Fiber %d, Ring %d, FEN %d, VMM:%2d, " ..
                            "CH:%2d, Time %d s %.2f ns, Overflow %d, " ..
                            "BC %4d, OTHR %1d, ADC %4d, TDC:%3d GEO %2d",
              readouts, fiberid, ringid, fenid, vmmid, chno, th, tl_ns, overflow, bc, othr, adc, tdc, geo, tdc))

      -- make an expanding tree with details of the fields
      dtree:add(buffer(offset +                   0, 1), string.format("Fiber   %d",    fiberid))
      dtree:add(buffer(offset +                   1, 1), string.format("FEN     %d",    fenid))
      dtree:add(buffer(offset +                   2, 2), string.format("Length  %d",    dlen))
      dtree:add(buffer(offset + dataheadersize +  0, 4), string.format("Time Hi 0x%08x", th))
      dtree:add(buffer(offset + dataheadersize +  4, 4), string.format("Time Lo 0x%08x", tl))
      dtree:add(buffer(offset + dataheadersize +  8, 2), string.format("BC      %d",    bc))
      dtree:add(buffer(offset + dataheadersize + 10, 2), string.format("OT|ADC  0x%04x", othr_adc))
      dtree:add(buffer(offset + dataheadersize + 12, 1), string.format("GEO     %d",     geo))
      dtree:add(buffer(offset + dataheadersize + 13, 1), string.format("TDC     %d",    tdc))
      dtree:add(buffer(offset + dataheadersize + 14, 1), string.format("VMM     %d",    vmmid))
      dtree:add(buffer(offset + dataheadersize + 15, 1), string.format("Channel %2d",    chno))
    else
      dtree = tree:add(buffer(offset, dataheadersize + datasize),
              string.format("%3d Latency calibration, Fiber %d, Ring %d, FEN %d, VMM:%2d, CH:%2d, BC %4d, CBC %4d",
              readouts, fiberid, ringid, fenid, vmmid, chno, bc, bit.band(geo, 0x0f)*256 + tdc))
    end

    bytesleft = bytesleft - datasize - dataheadersize
    offset    = offset + dataheadersize + datasize
	  readouts  = readouts + 1
  end
	-- pinfo.cols.info = string.format("Type: 0x%x, OQ: %d", type, oq)
end


register_protocol(essvmm3a_proto)

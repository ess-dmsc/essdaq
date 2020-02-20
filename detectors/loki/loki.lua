
-- Copyright (C) 2019 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Readout data for LOKI

-- helper variable and functions

esshdrsize = 30
datasize = 20
dataheadersize = 4

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
essloki_proto = Proto("essreadout","ESSR Protocol")

function essloki_proto.dissector(buffer, pinfo, tree)
	pinfo.cols.protocol = "ESSR/LOKI"
	protolen = buffer():len()
	esshdr = tree:add(essloki_proto,buffer(),"ESSR Header")

  padding = buffer(0,2):le_uint()
  cookie = buffer(2,4):uint()
  version = buffer(5,1):uint()
  type = buffer(6,1):uint()
  oq = buffer(7,1):uint()
  length = buffer(8,2):le_uint()
  pth = buffer(10, 4):le_uint()
  ptl = buffer(14, 4):le_uint()
  ppth = buffer(18, 4):le_uint()
  pptl = buffer(22, 4):le_uint()
  seqno = buffer(26, 4):le_uint()
	esshdr:add(buffer( 0,2),string.format("Padding  0x%x", padding))
  esshdr:add(buffer( 2,4),string.format("Cookie   0x%x", cookie))
  esshdr:add(buffer( 5,1),string.format("Version  %d", version))
  esshdr:add(buffer( 6,1),string.format("DataType 0x%x", type))
  esshdr:add(buffer( 7,1),string.format("OutputQ  %d", oq))
  esshdr:add(buffer( 8,2),string.format("Length   %d", length))
  esshdr:add(buffer(10,8),string.format("PulseT   0x%04x%04x", pth, ptl))
  esshdr:add(buffer(18,8),string.format("PrevPT   0x%04x%04x", ppth, pptl))
  esshdr:add(buffer(26,4),string.format("SeqNo    %d", seqno))

  bytesleft = protolen - esshdrsize
  offset = esshdrsize

  while (bytesleft)
  do
    ringid = buffer(offset, 1):uint()
    fenid = buffer(offset + 1, 1):uint()
    dlen = buffer(offset + 2, 2):le_uint()
    readouts = (dlen - dataheadersize) / datasize
    dtree = esshdr:add(buffer(offset, 4),string.format("Ring %d, FEN %d, Length %d, Readouts %d",
               ringid, fenid, dlen, readouts))

    bytesleft = bytesleft - dataheadersize
    offset = offset + dataheadersize

    if (readouts * datasize > bytesleft) then
      return
    end

    if (readouts > 0) then
      for i=1,readouts
      do
        th = buffer(offset + 0, 4):le_uint()
        tl = buffer(offset + 4, 4):le_uint()
        fpga = buffer(offset + 8, 1):uint()
        tube = buffer(offset + 9, 1):uint()
        adc = buffer(offset + 10, 2):le_uint()
        ampa = buffer(offset + 12, 2):le_uint()
        ampb = buffer(offset + 14, 2):le_uint()
        ampc = buffer(offset + 16, 2):le_uint()
        ampd = buffer(offset + 18, 2):le_uint()
        dtree:add(buffer(offset + 0, datasize),string.format(
            "Time   0x%08x 0x%08x Fpga %3d, Tube %3d, A:%5d, B:%5d, C:%5d, D:%5d",
             th, tl, fpga, tube, ampa, ampb, ampc, ampd))
        bytesleft = bytesleft - datasize
        offset = offset + datasize
      end
      if (bytesleft < 24) then
        return
      end
    end

  end
	-- pinfo.cols.info = string.format("Type: 0x%x, OQ: %d", type, oq)
end

-- Register the protocol
udp_table = DissectorTable.get("udp.port")
udp_table:add(9000, essloki_proto)

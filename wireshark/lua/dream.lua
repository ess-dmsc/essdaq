
-- Copyright (C) 2019 - 2022 European Spallation Source ERIC
-- Wireshark plugin for dissecting ESS Readout data for DREAM (CDT)

-- helper variable and functions

-- CDT/DREAM Packet Structure
-- Time HI [31:0]
-- Time LO [31:0]
-- Cathode [15:8] Anode [7:0]


-- bytes
esshdrsize = 30
datasize = 16

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
essdream_proto = Proto("essreadout","ESSR Protocol")

function essdream_proto.dissector(buffer, pinfo, tree)
	pinfo.cols.protocol = "ESSR/DREAM"
	protolen = buffer():len()
	esshdr = tree:add(essdream_proto,buffer(),"ESSR Header")

  padding = buffer( 0, 1):le_uint()
  version = buffer( 1, 1):uint()
  cookie  = buffer( 2, 3):uint()
  type    = buffer( 5, 1):uint()
  length  = buffer( 6, 2):le_uint()
  oq      = buffer( 8, 1):uint()
  tsrc    = buffer( 9, 1):uint()
  pth     = buffer(10, 4):le_uint()
  ptl     = buffer(14, 4):le_uint()
  ppth    = buffer(18, 4):le_uint()
  pptl    = buffer(22, 4):le_uint()
  seqno   = buffer(26, 4):le_uint()

	esshdr:add(buffer( 0,1),string.format("Padding  0x%x", padding))
  esshdr:add(buffer( 1,1),string.format("Version  %d", version))
  esshdr:add(buffer( 2,3),string.format("Cookie   0x%x", cookie))
  esshdr:add(buffer( 5,1),string.format("DataType 0x%x", type))
  esshdr:add(buffer( 6,2),string.format("Length   %d", length))
  esshdr:add(buffer( 8,1),string.format("OutputQ  %d", oq))
  esshdr:add(buffer( 9,1),string.format("TimeSrc  %d", tsrc))
  esshdr:add(buffer(10,8),string.format("PulseT   0x%08x %08x", pth, ptl))
  esshdr:add(buffer(18,8),string.format("PrevPT   0x%08x %08x", ppth, pptl))
  esshdr:add(buffer(26,4),string.format("SeqNo    %d", seqno))

  bytesleft = protolen - esshdrsize
  offset = esshdrsize

  while (bytesleft >= datasize)
  do
    -- Readout Header (RING, FEN, Size)
    ringid = buffer(offset    , 1):uint()
    fenid  = buffer(offset + 1, 1):uint()
    dlen   = buffer(offset + 2, 2):le_uint()
    dtree = esshdr:add(buffer(offset, 4),string.format("Ring %d, FEN %d, Length %d",
               ringid, fenid, dlen))

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

-- Register the protocol
udp_table = DissectorTable.get("udp.port")
udp_table:add(9000, essdream_proto)



function i64_ax(h,l)
 local o = {}; o.l = l; o.h = h; return o;
end -- +assign 64-bit v.as 2 regs

function i64u(x)
 return ( ( (bit.rshift(x,1) * 2) + bit.band(x,1) ) % (0xFFFFFFFF+1));
end -- keeps [1+0..0xFFFFFFFFF]


function i64_toInt(a)
  return (a.l + (a.h * (0xFFFFFFFF+1)));
end

function i64_toString(a)
  local s1=string.format("%x",a.l);
  local s2=string.format("%x",a.h);
  return "0x"..string.upper(s2)..string.upper(s1);
end


function essheader(name, proto, buffer, pinfo, tree)
  esshdrsize = 30
  pinfo.cols.protocol = name
  protolen = buffer():len()
  esshdr = tree:add(proto, buffer(),"ESSR Header")

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

  ptg = i64_ax(pth, ptl)

  esshdr:add(buffer( 0,1),string.format("Padding  0x%02x", padding1))
  esshdr:add(buffer( 1,1),string.format("Version  %d", version))
  esshdr:add(buffer( 2,3),string.format("Cookie   0x%x", cookie))
  esshdr:add(buffer( 5,1),string.format("Type     0x%02x", type))
  esshdr:add(buffer( 6,2),string.format("Length   %d", length))
  esshdr:add(buffer( 8,1),string.format("OutputQ  %d", oq))
  esshdr:add(buffer( 9,1),string.format("TimeSrc  %d", tmsrc))
  esshdr:add(buffer(10,8),string.format("PulseT   0x%08x %08x", pth, ptl))
  esshdr:add(buffer(18,8),string.format("PrevPT   0x%08x %08x", ppth, pptl))
  esshdr:add(buffer(26,4),string.format("SeqNo    %d", seqno))

  if version == 1 then
    esshdrsize = esshdrsize + 2
    padding2 = buffer(30, 2):le_uint()
    esshdr:add(buffer(30,2),string.format("V1 pad   %d", padding2))
  end
  return esshdrsize
end



function register_protocol(proto)
  udp_table = DissectorTable.get("udp.port")

  efuport = os.getenv("EFUPORT")

  if efuport ~= nil then
    udp_table:add(efuport, proto)
  else
    udp_table:add(9000, proto)
  end
end

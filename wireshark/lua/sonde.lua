
-- Copyright (C) 2023 European Spallation Source ERIC
-- Wireshark plugin for dissecting TimePix3 UDP and TimePix3 Control TCP

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


--  TIMEPIX config data

-- protocol commands and register addresses

commands = {
  [0x0000] = "Register 0x0000",
  [0x0001] = "Register 0x0001",
  [0x0002] = "Register 0x0002",
  [0x0031] = "Register 0x0031",
  [0x0032] = "Register 0x0032",
  [0x0033] = "Register 0x0033",
  [0x0400] = '1KB',
}


cmdtype = {
  [0x0011] = "Request ",
  [0x0012] = "Response",
  [0x0020] = "Data    ",
}


-- helper variable and functions

function getcmdtype(t)
  if t == 0x11
  then
    return "Request "
  else
    return "Response"
  end
end


function arr2str(arr, val)
  res = arr[val]
  if (res == nil)
  then
    res = string.format("[0x%04x]", val)
  end
  return res
end

function ctype2str(t)
  return arr2str(cmdtype, t)
end  

function cmd2str(t)
  return arr2str(commands, t)
end


-- -----------------------------------------------------------------------------------------------
-- the protocol dissectors
-- -----------------------------------------------------------------------------------------------

-- ------------------------------------------------------
-- CONTROL - TCP port 50000
-- ------------------------------------------------------

sonde_proto = Proto("sondectrl","SoNDe CB Control")

function sonde_proto.dissector(buffer, pinfo,tree)
  pinfo.cols.protocol = "SONDE CTRL"
  local protolen = buffer():len()
  

  local reqresp = buffer(0, 2):uint()
  local seqno = buffer(2, 2):uint()
  local cmdlen = buffer(9, 1):uint()
  local cmdarg = buffer(10, 2):uint()
  local cmdstr = cmd2str(cmdarg)
  -- if (cmdlen == 2 and reqresp == "Request ") then
  --   local cmdstr = cmd2str(cmdarg)
  -- else
  --   local cmdstr = "unimplemented"
  -- end
  if (cmdlen > 30) 
  then
    cmdlen = 30
  end


  b = buffer(12, cmdlen - 2):bytes():tohex()

  pinfo.cols.info = string.format("seqno %3s: %s cmd %-20s | %s", seqno, ctype2str(reqresp), cmdstr, b)
  local header = tree:add(sonde_proto, buffer(), string.format("seqno %s: %s cmd %s | %s", seqno, ctype2str(reqresp), cmdstr, b))
end

-- Register the protocol
tcp_table = DissectorTable.get("tcp.port")
tcp_table:add(50010, sonde_proto)

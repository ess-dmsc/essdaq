
-- Copyright (C) 2026 European Spallation Source ERIC
-- Wireshark plugin for dissecting IDEAS remote software upgrade.

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

registers = {
  [0x0000] = "Register 0x0000",
  [0x0001] = "Register 0x0001",
  [0x0002] = "Register 0x0002",
  [0x0031] = "Register 0x0031",
  [0x0032] = "Register 0x0032",
  [0x0033] = "Register 0x0033",
  [0x0400] = "---",
}


commands = {
  [0x0011] = "Request ",
  [0x0012] = "Response",
  [0x0020] = "Data    ",
  [0x0022] = "Unknown ",
}


-- helper variable and functions

function arr2str(arr, val)
  res = arr[val]
  if (res == nil)
  then
    res = string.format("[0x%04x]", val)
  end
  return res
end

function ctype2str(t)
  return arr2str(commands, t)
end  

function cmd2str(t)
  return arr2str(registers, t)
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
  local cmdtype = ctype2str(reqresp)

  local seqno = buffer(2, 2):uint()
  local cmdlen = buffer(9, 1):uint()

  local cmdarg = buffer(10, 2):uint()
  local cmdstr = cmd2str(cmdarg)

  hexlen = cmdlen
  if (cmdlen > 30) 
  then
    hexlen = 30
  end


  local common = string.format("seqno %3d: %s", seqno, cmdtype)
  

  if reqresp == 0x20 then
    local laddr = buffer(14,4):uint()
    pinfo.cols.info = string.format("%s                   | load 1024 bytes at 0x%08x", common, laddr)
  elseif reqresp == 0x22 then
    local b = buffer(0, hexlen):bytes():tohex()
    pinfo.cols.info = string.format("%s                   | %s", common, b)
  else
    local b = buffer(12, hexlen - 2):bytes():tohex()
    pinfo.cols.info = string.format("%s - %-15s | %s", common, cmdstr, b)
  end

  -- local b = string.format("%d %s", seqno, buffer(12, cmdlen - 2):bytes():tohex())
  --   -- pinfo.cols.info = string.format("seqno %3s: %s cmd %-20s | %s", seqno, cmdtype, cmdstr, string.format("load %d bytes @ 0x%04x", llen, laddr))
  
  -- if (reqresp == 0x20) then
  --   print("Data")
  --   local laddr = buffer(14,4):uint()
  --   llen = 1024
  --   local b = string.format("seqno %d %d %db at 0x%08x", seqno, reqresp, llen, laddr)
  -- end
  --  -- local header = tree:add(sonde_proto, buffer(), string.format("seqno %s: %s cmd %s | %s", seqno, cmdtype, cmdstr, b))
  -- pinfo.cols.info = string.format("%s",b)
  
  local header = tree:add(sonde_proto, buffer(), string.format("ABCDE"))

end 



-- Register the protocol
tcp_table = DissectorTable.get("tcp.port")
tcp_table:add(50010, sonde_proto)


-- Copyright (C) 2023 European Spallation Source ERIC
-- Wireshark plugin for dissecting TIMEPIX config data

-- protocol commands and register addresses

cmd = {
        [0x0111] = "Device ID",
        [0x0114] = "Get IPAddr Dest",
        [0x0115] = "Set IPAddr Dest",
        [0x0117] = "Get Server Port",
        [0x0118] = "Set Server Port",

        [0x022A] = "Set PixConf",
        [0x022E] = "Reset Pixels",

        [0x0335] = "Set Gen Config",
        [0x0336] = "Get PLL Config",

        [0x0549] = "Get Remote Temp",
        [0x054A] = "Get Local Temp",
        [0x054D] = "Get AVDD Now",
        [0x054E] = "Get SPIDER ADC",
        [0x0550] = "Restart Timers",
        [0x0551] = "Reset Timer",
        [0x0563] = "Set Readout Speed",
        [0x0564] = "Get Readout Speed",
        [0x056D] = "Get VDD Now",

        [0x0783] = "Get SPIDER Register",
        [0x0784] = "Set SPIDER Register",

        [0x0901] = "Get SW Version",
        [0x0902] = "Get FW Version",
        [0x0905] = "Get Header Filter",
        [0x0906] = "Set Header Filter",
        [0x0907] = "Reset",
        [0x090F] = "Board ID",
      }


-- helper variable and functions

function getcmdtype(t)
  if t == 0
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
      res = "[Unknown]"
  end
  return res
end

function cmd2str(type)
  return arr2str(cmd, type)
end


-- -----------------------------------------------------------------------------------------------
-- the protocol dissectors
-- -----------------------------------------------------------------------------------------------

-- ------------------------------------------------------
-- CONTROL - TCP port 50000
-- ------------------------------------------------------

tpix_ctrl = Proto("tpix3ctrl","TimePix3 Control")

function tpix_ctrl.dissector(buffer,pinfo,tree)
  pinfo.cols.protocol = "TIMEPIX CTL"
  local protolen = buffer():len()
  local header = tree:add(tpix_ctrl,buffer(),"Timepix Header")

  local reqresp = buffer(0, 2):uint()
  local command = buffer(2, 2):uint()

  if (reqresp == 0) then
    header:add(buffer(0, protolen), string.format("Request : %s",
               cmd2str(command)))
  else
    header:add(buffer(0, protolen), string.format("Response: %s",
               cmd2str(command)))
  end

  pinfo.cols.info = string.format("%s 0x%04x, %s", getcmdtype(reqresp), command, cmd2str(command))
end


-- Register the protocol
tcp_table = DissectorTable.get("tcp.port")
tcp_table:add(50000, tpix_ctrl)

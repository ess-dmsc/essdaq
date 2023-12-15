import struct
from scapy.all import *
from multiprocessing import Pool

# Pixel data
TYPE_MASK = 0xF000000000000000
PIXEL_DCOL_MASK = 0x0FE0000000000000
PIXEL_SPIX_MASK = 0x001F800000000000
PIXEL_PIX_MASK = 0x0000700000000000
PIXEL_TOA_MASK = 0x00000FFFC0000000
PIXEL_TOT_MASK = 0x000000003FF00000
PIXEL_FTOA_MASK = 0x00000000000F0000
PIXEL_SPTIME_MASK = 0x000000000000FFFF
TYPE_OFFS = 60
PIXEL_DCOL_OFFS = 52
PIXEL_SPIX_OFFS = 45
PIXEL_PIX_OFFS = 44
PIXEL_TOA_OFFS = 28
PIXEL_TOT_OFFS = 20
PIXEL_FTOA_OFFS = 16

# TDC type data
TDC_TYPE_MASK = 0x0F00000000000000
TDC_TRIGGERCOUNTER_MASK = 0x00FFF00000000000
TDC_TIMESTAMP_MASK = 0x00000FFFFFFFFE00
TDC_STAMP_MASK = 0x00000000000001E0
TDC_TYPE_OFFSET = 56
TDC_TRIGGERCOUNTER_OFFSET = 44
TDC_TIMESTAMP_OFFSET = 9
TDC_STAMP_OFFSET = 5

class UdpParser:
    def __init__(self):
        self.packet_counter = 0
        self.readout_counter = 0
        self.readout_timestamp = 0
    
    def __get_readout_type(self, data_bytes):
        return (data_bytes & TYPE_MASK) >> TYPE_OFFS
    
    def __parse_evr_packet(self, packet):
                    
        evr_packet = struct.unpack('<bbhlllll', packet)
        self.readout_counter += 1
        
        return {
            'Readout': self.readout_counter,
            'PacketId': self.packet_counter,
            'ReadoutTime': self.readout_timestamp,
            'Counter': evr_packet[3],
#            'PulseTimeSeconds': evr_packet[4],
#            'PulseTimeNanoSeconds': evr_packet[5],
#            'PrevPulseTimeSeconds': evr_packet[6],
#            'PrevPulseTimeNanoSeconds': evr_packet[7],
            'Type': "EVR"
        }
    
    def __parse_tdc_packet(self, data_bytes):
        tdc_type = (data_bytes & TDC_TYPE_MASK) >> TDC_TYPE_OFFSET
        counter = (data_bytes & TDC_TRIGGERCOUNTER_MASK ) >> TDC_TRIGGERCOUNTER_OFFSET
        timestamp = (data_bytes & TDC_TIMESTAMP_MASK) >> TDC_TIMESTAMP_OFFSET;
        stamp = (data_bytes & TDC_STAMP_MASK) >> TDC_STAMP_OFFSET;
                      
        tdc_timestamp = 3.125 * timestamp + 0.26 * stamp
        self.readout_counter += 1
        
        return {
            'Readout': self.readout_counter,
            'PacketId': self.packet_counter,
            'ReadoutTime': self.readout_timestamp,
            'Tcounter': counter,
#            'Timestamp': timestamp,
#            'Stamp': stamp,
            'CTime': tdc_timestamp,
            'Type': "TDC"
        }
    
    def __parse_pixel_packet(self, data_bytes):        
        dcol = (data_bytes & PIXEL_DCOL_MASK) >> PIXEL_DCOL_OFFS
        spix = (data_bytes & PIXEL_SPIX_MASK) >> PIXEL_SPIX_OFFS
        pix = (data_bytes & PIXEL_PIX_MASK) >> PIXEL_PIX_OFFS
        toa = (data_bytes & PIXEL_TOA_MASK) >> PIXEL_TOA_OFFS
        tot = ((data_bytes & PIXEL_TOT_MASK) >> PIXEL_TOT_OFFS) * 25
        ftoa = (data_bytes & PIXEL_FTOA_MASK) >> PIXEL_FTOA_OFFS
        spidr_time = data_bytes & PIXEL_SPTIME_MASK
        
        calculated_toa = 409600 * spidr_time + 25 * toa + 1.5625 * ftoa
        self.readout_counter += 1
        
        return {
            'Readout': self.readout_counter,
            'PacketId': self.packet_counter,
            'ReadoutTime': self.readout_timestamp,
            'Dcol': dcol,
            'Spix': spix,
            'Pix': pix,
            'ToA': toa,
            'CTime': calculated_toa,
            'ToT': tot,
            'FToA': ftoa,
            'SpidrTime': spidr_time,
            'Type': "PIXEL"
        }
    
    """Parse UDP packets according to timpix3 data frames
    
        Parameters:
            packet: udp packet to parse
        
        Return:
            
    """
    def parse_udp_packet(self, packet):
        if UDP in packet:
            udp_data = packet[UDP].payload
            if isinstance(udp_data, Raw):
                
                self.packet_counter += 1
                
                udp_bytes = udp_data.load
                data_len = len(udp_bytes)
                
                self.readout_timestamp = packet.time
                
                if (data_len <= 7):
                    print("Garbage data")
                
                if (data_len == 24):
                    print(self.__parse_evr_packet(udp_bytes))
                
                for i in range(0, data_len, 8):
                    if i + 8 <= data_len:
                        data_bytes = struct.unpack('<Q', udp_bytes[i:i+8])[0]
                          
                    if(self.__get_readout_type(data_bytes) == 6):
                        print(self.__parse_tdc_packet(data_bytes))

pool = Pool(20)
parser = UdpParser()

def epoch_s_to_ns(epoch_s):
    return epoch_s * 1e9

def ms_to_epoch(ms):
    return ms / 1e3

def parse_packet(packet):
    global pool
    global parser
    
    pool.apply_async(parser.parse_udp_packet, (packet))

print("Start Timpix Packet Monitoring")


sniff(iface="ens2f0.2713", filter="udp and port 9888", prn=parse_packet)

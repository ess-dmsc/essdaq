import struct
import gc
import pickle
import logging, sys
import pandas as pd
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

class Timepix3Parser:
    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

    def __init__(self, is_pixel = False):
        self.readout_counter = 0
        self.packet_counter = 0
        
        self.packet_timestamp = 0
        self.is_pixel = is_pixel

        self.evr = pd.DataFrame()
        self.tdc = pd.DataFrame()
        self.pixel = pd.DataFrame()
    
    def __get_readout_type(self, data_bytes):
        return (data_bytes & TYPE_MASK) >> TYPE_OFFS
    
    def __parse_evr_packet(self, packet):
                    
        evr_packet = struct.unpack('<bbhlllll', packet)

        self.readout_counter += 1
        
        return {
            'Readout': self.readout_counter,
            'PacketId': self.packet_counter,
            'ReadoutTime': self.packet_timestamp,
            'Counter': evr_packet[3],
            'PulseTimeSeconds': evr_packet[4],
            'PulseTimeNanoSeconds': evr_packet[5],
            'PrevPulseTimeSeconds': evr_packet[6],
            'PrevPulseTimeNanoSeconds': evr_packet[7],
            'Type': "EVR"
        }
    
    def __parse_tdc_packet(self, data_bytes):
        tdc_type = (data_bytes & TDC_TYPE_MASK) >> TDC_TYPE_OFFSET
        counter = (data_bytes & TDC_TRIGGERCOUNTER_MASK ) >> TDC_TRIGGERCOUNTER_OFFSET
        timestamp = (data_bytes & TDC_TIMESTAMP_MASK) >> TDC_TIMESTAMP_OFFSET
        stamp = (data_bytes & TDC_STAMP_MASK) >> TDC_STAMP_OFFSET
                      
        tdc_timestamp = 3.125 * timestamp + 0.26 * stamp
        
        self.readout_counter += 1
        
        return {
            'Readout': self.readout_counter,
            'PacketId': self.packet_counter,
            'ReadoutTime': self.packet_timestamp,
            'Tcounter': counter,
            'Timestamp': timestamp,
            'Stamp': stamp,
            'CTime': tdc_timestamp,
            'Type': "TDC"
        }
    
    def __parse_pixel_packet(self, data_bytes):        
#         dcol = (data_bytes & PIXEL_DCOL_MASK) >> PIXEL_DCOL_OFFS
#         spix = (data_bytes & PIXEL_SPIX_MASK) >> PIXEL_SPIX_OFFS
#         pix = (data_bytes & PIXEL_PIX_MASK) >> PIXEL_PIX_OFFS
        toa = (data_bytes & PIXEL_TOA_MASK) >> PIXEL_TOA_OFFS
        tot = ((data_bytes & PIXEL_TOT_MASK) >> PIXEL_TOT_OFFS) * 25
        ftoa = (data_bytes & PIXEL_FTOA_MASK) >> PIXEL_FTOA_OFFS
        spidr_time = data_bytes & PIXEL_SPTIME_MASK
        
        calculated_toa = 409600 * spidr_time + 25 * toa + 1.5625 * ftoa

        self.readout_counter += 1
        
        return {
            'Readout': self.readout_counter,
            'PacketId': self.packet_counter,
            'ReadoutTime': self.packet_timestamp,
#             'Dcol': dcol,
#             'Spix': spix,
#             'Pix': pix,
#             'ToA': toa,
            'CTime': calculated_toa,
            'ToT': tot,
            # 'FToA': ftoa,
#             'SpidrTime': spidr_time,
            'Type': "PIXEL"
        }
       
    def load_pcap_file(self, file):

        logging.debug('Reading: %s', file)
        packets = rdpcap(file)

        logging.debug('Parsing: %s', file)
        packets_num = len(packets)
        chunk_size = 2000

        for chunk in range(0, packets_num, chunk_size):
            pixel = []
            tdc = []
            evr = []

            for packet in packets[chunk:chunk + chunk_size]:
                if UDP in packet:
                    udp_data = packet[UDP].payload
                    if isinstance(udp_data, Raw):
                        
                        self.packet_counter += 1
                        self.packet_timestamp = packet.time
                        
                        udp_bytes = udp_data.load
                        data_len = len(udp_bytes)
                        
                        if (data_len == 24):
                            evr.append(self.__parse_evr_packet(udp_bytes))
                        
                        for i in range(0, data_len, 8):
                            if i + 8 <= data_len:
                                data_bytes = struct.unpack('<Q', udp_bytes[i:i+8])[0]
                                
                            if(self.__get_readout_type(data_bytes) == 6):
                                tdc.append(self.__parse_tdc_packet(data_bytes))
                                               
                            if(self.is_pixel):
                                if(self.__get_readout_type(data_bytes) == 11):
                                    pixel.append(self.__parse_pixel_packet(data_bytes))

            if(self.is_pixel):
                self.pixel = pd.concat([self.pixel, pd.DataFrame.from_records(pixel)], ignore_index=True)
            self.tdc = pd.concat([self.tdc, pd.DataFrame.from_records(tdc)], ignore_index=True)
            self.evr = pd.concat([self.evr, pd.DataFrame.from_records(evr)], ignore_index=True)
            del pixel, tdc, evr
            gc.collect()

            logging.debug("We processed: %d readouts, %d packets %d packets left for %s",
                          self.readout_counter, chunk + chunk_size, packets_num - (chunk_size + chunk), file)
            
        del packets
        gc.collect()

    def dump_to_filesystem(self, filepath):
        with open(filepath, 'wb') as file_writer:
            pickle.dump(self, file_writer)

    @staticmethod
    def load_from_file(filepath):
        with open(filepath, 'rb') as file_reader:
            return pickle.load(file_reader)

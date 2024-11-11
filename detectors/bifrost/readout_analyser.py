from scapy.all import *
import struct
import signal
import sys

PORT = 9001

# Define the PacketHeaderV0 struct format
packet_header_v0_format = 'BBIHBIIIII'

# Define the CaenReadout struct format
caen_readout_format = 'BBHII2BH4h'

# Function to parse the CaenReadout struct
def parse_caen_readout(data):
    unpacked_data = struct.unpack(caen_readout_format, data)
    caen_readout = {
        'FiberId': unpacked_data[0],
        'FENId': unpacked_data[1],
        'DataLength': unpacked_data[2],
        'TimeHigh': unpacked_data[3],
        'TimeLow': unpacked_data[4],
        'FlagsOM': unpacked_data[5],
        'Group': unpacked_data[6],
        'Unused': unpacked_data[7],
        'AmpA': unpacked_data[8],
        'AmpB': unpacked_data[9],
        'AmpC': unpacked_data[10],
        'AmpD': unpacked_data[11],
    }
    return caen_readout

# Function to handle incoming UDP packets
def handle_packet(packet):
    if UDP in packet:
        udp_payload = bytes(packet[UDP].payload)
        header_size = struct.calcsize(packet_header_v0_format)
        caen_readout_size = struct.calcsize(caen_readout_format)

        # Ensure the payload is larger than the header size
        if len(udp_payload) > header_size:
            # Skip the header part
            remaining_payload = udp_payload[header_size:]

            # Process each CaenReadout struct in the remaining payload
            for i in range(0, len(remaining_payload), caen_readout_size):
                if i + caen_readout_size <= len(remaining_payload):
                    caen_readout_data = remaining_payload[i:i + caen_readout_size]
                    caen_readout = parse_caen_readout(caen_readout_data)
                    
                    print(f"TimeHigh: {caen_readout['TimeHigh']} "
                          f"TimeLow: {caen_readout['TimeLow']}, "
                          f"AmpA: {caen_readout['AmpA']}, "
                          f"AmpB: {caen_readout['AmpB']}")
                    with open('output.csv', 'a') as f:
                        f.write(f"{caen_readout['TimeHigh']},"
                                f"{caen_readout['TimeLow']},"
                                f"{caen_readout['AmpA']},"
                                f"{caen_readout['AmpB']}\n")

# Start sniffing UDP packets
sniff(iface="ens2f0", filter=f"udp port {PORT}", prn=handle_packet)

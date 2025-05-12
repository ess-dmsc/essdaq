from scapy.all import *
import struct

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

# Define the CbmReadout struct format (little-endian)
cbm_readout_format = '<BBHIIBBHI'  # Added '<' for little-endian

def parse_cbm_readout(data):
    unpacked_data = struct.unpack(cbm_readout_format, data)
    cbm_readout = {
        'FiberId': unpacked_data[0],
        'FENId': unpacked_data[1],
        'DataLength': unpacked_data[2],
        'TimeHigh': unpacked_data[3],
        'TimeLow': unpacked_data[4],
        'Type': unpacked_data[5],
        'Channel': unpacked_data[6],
        'ADC': unpacked_data[7],
        'NPos': unpacked_data[8],  # Using NPos from the union
    }
    return cbm_readout

# Function to handle incoming UDP packets
def handle_packet(packet):
    if UDP in packet:
        udp_payload = bytes(packet[UDP].payload)
        header_size = struct.calcsize(packet_header_v0_format)
        cbm_readout_size = struct.calcsize(cbm_readout_format)

        # Ensure the payload is larger than the header size
        if len(udp_payload) > header_size:
            # Skip the header part
            remaining_payload = udp_payload[header_size:]

            # Process each CaenReadout struct in the remaining payload
            for i in range(0, len(remaining_payload), cbm_readout_size):
                if i + cbm_readout_size <= len(remaining_payload):
                    readout_data = remaining_payload[i:i + cbm_readout_size]
                    readout = parse_cbm_readout(readout_data)
                    
                    print(f"TimeHigh: {readout['TimeHigh']} "
                          f"TimeLow: {readout['TimeLow']}, "
                          f"Type: {readout['Type']}, "
                          f"Channel: {readout['Channel']}, "
                          f" ADC: {readout['ADC']}, "
                          f"NPos: {readout['NPos']}")
                    with open('output.csv', 'a') as f:
                        f.write(f"{readout['TimeHigh']},"
                                f"{readout['TimeLow']},"
                                f"{readout['Type']},"
                                f"{readout['Channel']},"
                                f"{readout['ADC']},"
                                f"{readout['NPos']}\n")

# Start sniffing UDP packets
sniff(iface="ens2f0", filter=f"udp port {PORT}", prn=handle_packet)

from scapy.all import *
import struct

PORT = 9000
HEADER = True

# Define the PacketHeaderV0 struct format
packet_header_v0_format = '<BB4BHBBIIIII'

def parse_packet_header_v0(data):
    unpacked_data = struct.unpack(packet_header_v0_format, data)
    packet_header = {
        'Padding0': unpacked_data[0],
        'Version': unpacked_data[1],
        'E': chr(unpacked_data[2]),
        'S1': chr(unpacked_data[3]),
        'S2': chr(unpacked_data[4]),
        'Type': hex(unpacked_data[5]),
        'TotalLength': unpacked_data[6],
        'OutputQueue': unpacked_data[7],
        'TimeSource': unpacked_data[8],
        'PulseHigh': unpacked_data[9],
        'PulseLow': unpacked_data[10],
        'PrevPulseHigh': unpacked_data[11],
        'PrevPulseLow': unpacked_data[12],
        'SeqNum': unpacked_data[13],
    }
    return packet_header

# Define the CaenReadout struct format
caen_readout_format = '<BBHII2BH4h'

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

            packet_header_data = udp_payload[:header_size]
            remaining_payload = udp_payload[header_size:]
            packet_header = parse_packet_header_v0(packet_header_data)
            if HEADER:
             print(f"Packet Header: {packet_header}")

            # Process each CaenReadout struct in the remaining payload
            for i in range(0, len(remaining_payload), caen_readout_size):
                if i + caen_readout_size <= len(remaining_payload):
                    caen_readout_data = remaining_payload[i:i + caen_readout_size]
                    caen_readout = parse_caen_readout(caen_readout_data)
                    
                    print(f"TimeHigh: {caen_readout['TimeHigh']}\t"
                          f"TimeLow: {caen_readout['TimeLow']},\t"
                          f"FiberId: {caen_readout['FiberId']},\t"
                          f"FENId: {caen_readout['FENId']},\t"
                          f"Group: {caen_readout['Group']},\t"
                          f"AmpA: {caen_readout['AmpA']},\t"
                          f"AmpB: {caen_readout['AmpB']}")
                    
                    with open('output.csv', 'a') as f:
                        f.write(f"{caen_readout['TimeHigh']},"
                                f"{caen_readout['TimeLow']},"
                                f"{caen_readout['FiberId']},"
                                f"{caen_readout['FENId']},"
                                f"{caen_readout['Group']}"
                                f"{caen_readout['AmpA']},"
                                f"{caen_readout['AmpB']}\n")

# Start sniffing UDP packets
sniff(iface="ens2np0", filter=f"udp port {PORT}", prn=handle_packet)

import os, gc, logging, sys
import pickle
from scapy.all import *
from Timepix3Parser import *
from multiprocessing import Pool
import pandas as pd

def handle_error(error):
    print(error)

def epoch_s_to_ns(epoch_s):
    return epoch_s * 1e9

def ms_to_epoch(ms):
    return ms / 1e3

def generate_args(data_folder, pcap_folder, files):
    args = []
    for file in files:
        arg = (data_folder, pcap_folder, file)
        args.append(arg)
    
    return args

def proccess_pcap_file(arg):
    data_foder, pcap_folder, file = arg

    parser = Timepix3Parser(1)

    logging.debug("Processing data in: %s", file)
    parser.load_pcap_file(os.path.join(pcap_folder, file))
    logging.debug("Dumping processed data to filesystem for: %s", file)
    parser.dump_to_filesystem(os.path.join(data_foder, file))

    del parser
    gc.collect()

# DEBUG: Strange results with this
def concat_tpx_pkt_dataframes(base_df: pd.DataFrame, next_df: pd.DataFrame, last_packetid: int, last_readout: int):
        
        chunk_size = 1000000

        next_df['Readout'] = next_df['Readout'] + last_readout
        next_df['PacketId'] = next_df['PacketId'] + last_packetid

        if(len(next_df) > chunk_size):
                chunk_list = []
                for i in range(0, len(next_df), chunk_size):
                    chunk_list.append(next_df.iloc[i:i+chunk_size])
                return pd.concat(chunk_list)
        
        return pd.concat([base_df, next_df], ignore_index=True)

if __name__ == "__main__":
    args = sys.argv[1:]

    current_pid = os.getpid()
    logging.basicConfig(filename=f'analyser_{current_pid}.log', encoding='utf-8', level=logging.DEBUG)

    if len(args) == 0:
        logging.info("No base folder defined, using current folder for operation")

    if len(args) > 1:
        logging.error("Too much argument defined! Exit!")
        exit()

    work_folder = args[0]

    start = time.time()

    pcap_folder = r'split/'
    data_folder = r'tmp_tpx/'
    result_folder = r'tpx_data/'

    if work_folder:
        os.chdir(work_folder)

    if not os.path.exists(pcap_folder):
        exit(1)

    if not os.path.exists(data_folder):
        os.makedirs(data_folder)

    if not os.path.exists(result_folder):
        os.makedirs(result_folder)

    def natural_sort_key(s):
        return [int(text) if text.isdigit() else text.lower() for text in re.split('([0-9]+)', s)]

    def sort_filenames(filenames):
        return sorted(filenames, key=natural_sort_key)
        
    logging.info("Searching for pcap files in %s folder", pcap_folder)
    pcap_files = []

    for file in os.listdir(pcap_folder):
        if os.path.isfile(os.path.join(pcap_folder, file)):
            pcap_files.append(file)
    
    
    pcap_files = sort_filenames(pcap_files)
    logging.debug("Pcap files sorted: %s", pcap_files)

    cpus = len(pcap_files)
    logging.info("Create process pool of %d proccess", cpus)
    pool = Pool(cpus)

    logging.info("Start data processing!")
    result = pool.map_async(proccess_pcap_file, generate_args(data_folder, pcap_folder, pcap_files), error_callback=handle_error)       
    result.wait()

    pool.close()

    logging.info("Concat parser outputs into tpx pkt dataframes")

    tmp_tpx_files = []

    for file in os.listdir(data_folder):
        if os.path.isfile(os.path.join(data_folder, file)):
            tmp_tpx_files.append(file)
    
    tmp_tpx_files  = sort_filenames(pcap_files)

    all_pixels = pd.DataFrame()
    all_evr = pd.DataFrame()
    all_tdc = pd.DataFrame()

    last_readout = 0
    last_packetid = 0
    for file in tmp_tpx_files :
        with open(os.path.join(data_folder, file), 'rb') as reader:
            parser = pickle.load(reader)

        logging.info(f"Reconstructing parser out file: {file}")

        if(parser.pixel.shape[0] != 0):
            parser.pixel['Readout'] = parser.pixel['Readout'] + last_readout
            parser.pixel['PacketId'] = parser.pixel['PacketId'] + last_packetid
        else:
            logger.info(f"No pixel readouts in data frame. Skipping pixels for {file} file.")

        if(parser.tdc.shape[0] != 0):
            parser.tdc['Readout'] = parser.tdc['Readout'] + last_readout
            parser.tdc['PacketId'] = parser.tdc['PacketId'] + last_packetid
        else:
            logger.info(f"No tdc readouts in data frame. Skipping tdc's for {file} file.")

        if(parser.evr.shape[0] != 0):
            parser.evr['Readout'] = parser.evr['Readout'] + last_readout
            parser.evr['PacketId'] = parser.evr['PacketId'] + last_packetid
        else:
            logger.info(f"No evr readouts in data frame. Skipping evr's for {file} file.")

        all_pixels = pd.concat([all_pixels, parser.pixel], ignore_index=True)
        all_evr = pd.concat([all_evr, parser.evr], ignore_index=True)
        all_tdc = pd.concat([all_tdc, parser.tdc], ignore_index=True)

        last_packetid += parser.packet_counter
        last_readout += parser.readout_counter

    logging.info("Save final results")
    all_pixels.to_pickle(os.path.join(result_folder, "all_pixel_pkt.tpx3"))
    all_tdc.to_pickle(os.path.join(result_folder, "all_tdc_pkt.tpx3"))
    all_evr.to_pickle(os.path.join(result_folder, "all_evr_pkt.tpx3"))

    end = time.time()

    logging.info(f"Done in {end - start}")

#!/usr/bin/env python3

from scipp import array, DataArray, ones_like
from argparse import ArgumentParser
import h5py, os
import matplotlib.pyplot as plt

#nspertick = 11.356860963629653  # ESS clock is 88052500 Hz

# Convert Ring and FEN to numbers or if not set, to 'A'
def id2chr(id):
    if id == -1:
        return 'any'
    else:
        return f'{id}'

def readtoscipp(filename):

    f = h5py.File(filename, 'r')
    dat =  f['loki_readouts']

    #time = dat['EventTimeHigh'].astype('int')+dat['EventTimeLow'].astype('int')*nspertick/1000000000
    #time = array(values=time, dims=['event'], unit='sec')

    tube = array(values=dat['TubeId'].astype('int'), dims=['event'])
    ring = array(values=dat['RingId'].astype('int'), dims=['event'])
    fen = array(values=dat['FENId'].astype('int'), dims=['event'])

    ampl_a = array(values=1.0 * dat['AmpA'].astype('int'), dims=['event'], unit='mV')
    ampl_b = array(values=1.0 * dat['AmpB'].astype('int'), dims=['event'], unit='mV')
    ampl_c = array(values=1.0 * dat['AmpC'].astype('int'), dims=['event'], unit='mV')
    ampl_d = array(values=1.0 * dat['AmpD'].astype('int'), dims=['event'], unit='mV')

    events = ones_like(1. * tube)
    events.unit = 'counts'

    pos = (ampl_a + ampl_b) / (ampl_a + ampl_b + ampl_c + ampl_d)
    straw = (ampl_b + ampl_d) / (ampl_a + ampl_b + ampl_c + ampl_d)

    return DataArray(data=events,
            coords={'pos': pos, 'straw': straw, # 'time': time,
                    'tube': tube, 'ring': ring, 'fen': fen,
                    'amplitude_a': ampl_a, 'amplitude_b': ampl_b,
                    'amplitude_c': ampl_c, 'amplitude_d': ampl_d})


def load_and_save(args):
    dat = readtoscipp(args.filename)

    rgrp = array(dims=['ring'], values=[args.ring])
    fgrp = array(dims=['fen'], values=[args.fen])

    fig, ax = plt.subplots(4,2, figsize=(16,16))
    #fig.tight_layout()

    for i in range(args.tubes):
        print(f'processing ring {id2chr(args.ring)}, fen {id2chr(args.fen)}, tube {i}')
        tgrp = array(dims=['tube'], values=[i])
        if args.ring == -1 and args.fen == -1:
            grp = dat.group(tgrp).bins.concat()
        elif args.ring == -1 and args.fen != -1:
            grp = dat.group(fgrp, tgrp).bins.concat()
        elif args.ring != -1 and args.fen == -1:
            grp = dat.group(rgrp, tgrp).bins.concat()
        else:
            grp = dat.group(rgrp, fgrp, tgrp).bins.concat()

        yi = i // 2
        xi = i % 2
        cax = ax[yi, xi]
        grp.hist(pos=args.bin, straw=args.bin).plot(aspect=1.,norm='log', ax=cax)
        cax.title.set_text(f'Tube {i}')
        cax.set_xlim(args.xmin, args.xmax)
        cax.set_ylim(args.ymin, args.ymax)
        cax.yaxis.tick_left()
        cax.yaxis.set_label_position('left')
        if i <= 5:
            cax.set(xlabel='', ylabel='pos')
        else:
            cax.set(xlabel='straw', ylabel='pos')

    plt.suptitle(f'Ring: {id2chr(args.ring)}, FEN: {id2chr(args.fen)}, Tubes 0 - 8', size='28')
    plt.savefig(os.path.join(args.outdir, f'strawpos_{id2chr(args.ring)}_{id2chr(args.fen)}.png'))


if __name__ == '__main__':
    parser = ArgumentParser(prog='dattoplot', description=__doc__)
    parser.add_argument('filename', type=str, nargs='?', default="",
                        help='.h5 file to load and plot')
    parser.add_argument('-o','--outdir', type=str, default="",
                        help='output directory')
    parser.add_argument('-r','--ring', type=int, default=-1, help='Ring Id (default all rings)')
    parser.add_argument('-f','--fen', type=int, default=-1, help='FEN Id (default all fens)')
    parser.add_argument('-t','--tubes', type=int, default=8, help='number of tubes')
    parser.add_argument('--xmin', type=float, default=0.0, help='min x-value')
    parser.add_argument('--xmax', type=float, default=1.0, help='max x-value')
    parser.add_argument('--ymin', type=float, default=0.0, help='min y-value')
    parser.add_argument('--ymax', type=float, default=1.0, help='max y-value')
    parser.add_argument('-b', '--bin', type=int, default=200, help='histogram bin size')

    args = parser.parse_args()

    load_and_save(args)

"""
Command line parser for HDF5 MANIPULATOR
"""
from __future__ import print_function
import argparse


def get_args_split():

    """parse arguments for split"""

    parser = argparse.ArgumentParser(
        description="HDF5 MANIPULATOR (split)", usage="./split.py <options>"
    )

    parser.add_argument(
        "--prefix",
        action="store",
        dest="prefix",
        metavar="[path/to/filename_base]",
        default=None,
        help="prefix for splitted files (base on input file if not defined)",
    )

    parser.add_argument(
        "--filelist",
        action="store",
        dest="filelist",
        metavar="[path/to/filelist]",
        default=None,
        help="save output files list in txt file",
    )

    required = parser.add_argument_group("required arguments")

    required.add_argument(
        "--input",
        action="store",
        dest="input",
        metavar="[path/to/input_file]",
        required=True,
        help="path to input hdf5 file",
    )

    required.add_argument(
        "--size",
        action="store",
        dest="size",
        metavar="[int]",
        required=True,
        help="number of entries per file",
    )

    required.add_argument(
        "--n_files",
        action="store",
        dest="n_files",
        metavar="[int]",
        required=True,
        help="number of files (will stop after creating this amount of files)",
    )

    return parser.parse_args()


def get_args_merge(category=False, req_key=False):

    """parse arguments for merge"""

    parser = argparse.ArgumentParser(
        description="HDF5 MANIPULATOR (merge)", usage="./merge.py <options>"
    )

    required = parser.add_argument_group("required arguments")

    required.add_argument(
        "--input",
        action="store",
        dest="input_files",
        metavar="input files",
        required=True,
        nargs="+",
        help="path to input hdf5 files to merge using bash synthax",
    )

    required.add_argument(
        "--output",
        action="store",
        dest="output",
        metavar="[path/to/filename]",
        required=True,
        help="path to output hdf5 file",
    )

    if category is False:
        return parser.parse_args()

    optional = parser.add_argument_group("optional arguments")

    optional.add_argument(
        "--keys",
        action="store",
        dest="keys_to_store",
        nargs="+",
        required=req_key,
        default=None,
        help="optional: defines dataset key which wants to be kept in merged \
         file.",
    )

    optional.add_argument(
        "--category",
        action="store",
        dest="category",
        required=False,
        help="category to keep",
    )
    args = parser.parse_args()
    return args


def get_args_extract():

    """parse arguments for extract"""

    parser = argparse.ArgumentParser(
        description="HDF5 MANIPULATOR (extract)", usage="./extract.py <options>"
    )

    required = parser.add_argument_group("required arguments")

    required.add_argument(
        "--input",
        action="store",
        dest="input",
        metavar="[path/to/filename]",
        required=True,
        help="path to input hdf5 file",
    )

    required.add_argument(
        "--output",
        action="store",
        dest="output",
        metavar="[path/to/filename]",
        required=True,
        help="path to output hdf5 file",
    )

    required.add_argument(
        "--keys",
        action="store",
        dest="keys",
        metavar="['key1, key2, ...']",
        required=True,
        help="list of datasets to be saved in the output file",
    )

    return parser.parse_args()


def get_args_combine():

    """parse arguments for combine"""

    parser = argparse.ArgumentParser(
        description="HDF5 MANIPULATOR (combine)", usage="./combine.py <options>"
    )

    parser.add_argument(
        "--keys1",
        action="store",
        dest="keys1",
        metavar="['key1, key2, ...']",
        default=None,
        help="list of datasets to be extracted from the first input file \
              (use all if not defined)",
    )

    parser.add_argument(
        "--keys2",
        action="store",
        dest="keys2",
        metavar="['key1, key2, ...']",
        default=None,
        help="list of datasets to be extracted from the second input file \
              (use all if not defined)",
    )

    parser.add_argument(
        "--do-not-warn",
        action="store_false",
        dest="print_warnings",
        default=True,
        help="if supplied, don't print warnings during combination",
    )

    parser.add_argument(
        "--show-progress",
        action="store_true",
        dest="show_progress",
        default=True,
        help="if supplied, give an event indicator every 100 events",
    )

    required = parser.add_argument_group("required arguments")

    required.add_argument(
        "--input1",
        action="store",
        dest="input1",
        metavar="[path/to/filename1]",
        required=True,
        help="path to first input hdf5 file",
    )

    required.add_argument(
        "--input2",
        action="store",
        dest="input2",
        metavar="[path/to/filename2]",
        required=True,
        help="path to second input hdf5 file",
    )

    required.add_argument(
        "--output",
        action="store",
        dest="output",
        metavar="[path/to/filename]",
        required=True,
        help="path to output hdf5 file",
    )

    required.add_argument(
        "--match",
        action="store",
        dest="match",
        metavar="[key]",
        required=True,
        help="the common key use to order data",
    )

    return parser.parse_args()


def get_args_rename():

    """parse arguments for rename"""

    parser = argparse.ArgumentParser(
        description="HDF5 MANIPULATOR (rename)", usage="./rename_dataset.py <options>"
    )

    required = parser.add_argument_group("required arguments")

    required.add_argument(
        "--input",
        action="store",
        dest="input",
        metavar="[path/to/filename]",
        required=True,
        help="path to input hdf5 file",
    )

    required.add_argument(
        "--dataset",
        action="store",
        dest="dataset",
        metavar="[old name]",
        required=True,
        help="name of dataset to be changed",
    )

    required.add_argument(
        "--name",
        action="store",
        dest="name",
        metavar="[new name]",
        required=True,
        help="new name of dataset",
    )

    return parser.parse_args()

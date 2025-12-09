Research Support for Channel Estimation in srsRAN (v24.10)

This folder provides a research-friendly environment for experimenting with Channel Estimation (CE) algorithms in srsRAN version 24.10.
It enables researchers to:

Replace or modify the default srsRAN CE algorithms

Export raw pilot/channel-related data from srsRAN (C++ layer)

Process the data in Python

Implement new CE algorithms

Compare their performance against:

The srsRAN built-in algorithm

Standard 5G NR estimation methods

The goal of this folder is to make rapid prototyping, debugging, and validation of channel estimation methods simple and reproducible.

Folder Structure
Real_time_algo
│
├── channel_estimation_algo.py           # Python-based CE algorithms for research
├── port_channel_average_impl.cpp        # Modified srsRAN CE implementation with data extraction
└── README.md                # Documentation (this file)

1. channel_estimation_algo.py (Python Implementation)

This file contains:

Python-based channel estimation algorithms

MMSE, LSE, and other experimental estimators

A socket interface that receives pilot/DMRS data streamed from the modified srsRAN code

Tools to compare:

Custom algorithm vs srsRAN CE

Custom algorithm vs 5G NR reference estimator

Metrics such as MSE, NMSE, EVM, correlation, etc.

This file allows researchers to prototype and evaluate algorithms much faster than modifying C++ and rebuilding srsRAN repeatedly.

2. port_channel_average_impl.cpp (C++ Implementation in srsRAN)

This is a modified version of the channel estimation code in srsRAN.

✔ Modified Lines (59–106)

These lines were updated to:

Collect pilot symbols, received samples, DMRS RE positions, and LS estimates

Package them into a compact struct/array

Send the data through a UDP socket to Python in real-time

This enables Python side processing without disrupting srsRAN’s internal pipelines.

Where this function is used?

The modified CE function is called in:

preprocess_pilots_and_cfo (Lines 540–616)

This is part of srsRAN’s uplink receiver pipeline.
Here, the modified channel estimation code is invoked right after DMRS extraction and before equalization and demodulation.

This ensures that the extracted data accurately reflects:

The received pilot samples

The estimated uplink channel

The noise/impairments present at runtime

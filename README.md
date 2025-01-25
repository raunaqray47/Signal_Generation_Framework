# ADS-B Signal Processing and Transceiver Integration

This project focuses on generating and processing Automatic Dependent Surveillance-Broadcast (ADS-B) signals for integration with a multi-band transceiver IC.

## Project Overview

This repository contains MATLAB functions for generating, encoding, and simulating ADS-B messages. The project aims to create a signal interface for a band-switchable transceiver IC, enabling the generation of sample ADS-B messages from user-defined data and evaluating the transceiver's performance.

## Features

- Generation of ADS-B messages for various types (Aircraft Identification, Surface Position, Airborne Position)
- Implementation of Compact Position Reporting (CPR) encoding
- Pulse Position Modulation (PPM) encoding of ADS-B bitstreams
- Integration with Cadence Virtuoso for signal simulation
- Generation of I+ and I- components for baseband representation

## MATLAB Functions

1. `ADSB_aircraftID_category.m`: Generates Aircraft Identification messages
2. `ADSB_encode_airbornePosition.m`: Generates Airborne Position messages
3. `ADSB_encode_surfacePosition.m`: Generates Surface Position messages
4. `generatePPM.m`: Creates PPM-encoded signals for ADS-B messages
5. `generateflippedPPM.m`: Generates flipped PPM signals for I- component

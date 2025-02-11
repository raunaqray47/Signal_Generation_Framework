import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def plot_csv_data(filename):
    filename = '"C:\Users\rauna\Downloads\ADSB_2_Stopped_CH1.csv"'
    # Load the CSV file
    data = pd.read_csv(filename)

    # Convert time to microseconds and amplitude to millivolts
    data['TIME'] *= 1e6  # Time in microseconds
    data['CH1'] *= 1e3  # Amplitude in millivolts

    # Group by unique time values and average amplitudes for duplicates
    grouped_data = data.groupby('TIME', as_index=False).mean()

    # Plot the cleaned data
    plt.figure(figsize=(10, 6))
    plt.plot(grouped_data['TIME'], grouped_data['CH1'], label='Amplitude')
    plt.xlabel('Time (microseconds)')
    plt.ylabel('Amplitude (millivolts)')
    plt.title('Filtered Data Around 100 Microseconds')
    plt.grid(True)
    plt.legend()
    plt.show()
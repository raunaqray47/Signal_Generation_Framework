function plot_and_compare_adsb(filename_transmitted, filename_received)
    % Read the transmitted signal CSV file
    data_tx = readtable(filename_transmitted);
    
    % Read the received signal CSV file
    data_rx = readtable(filename_received);

    % Convert time to microseconds and amplitude to millivolts
    time_tx = data_tx.TIME * 1e6; % Time in microseconds
    amplitude_tx = data_tx.CH1 * 1e3; % Amplitude in millivolts
    
    time_rx = data_rx.TIME * 1e6; % Time in microseconds
    amplitude_rx = data_rx.CH1 * 1e3; % Amplitude in millivolts

    % Plot the original transmitted waveform
    figure;
    plot(time_tx, amplitude_tx, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Transmitted Waveform');
    grid on;
    ylim([-50,1050]);
    xlim([-2, 150]);
    
    % Plot the original received waveform
    figure;
    plot(time_rx, amplitude_rx, 'r');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Received Waveform');
    grid on;
    
    % Process the transmitted signal
    % Create a modified amplitude for processing (not for display)
    modified_amplitude_tx = amplitude_tx;
    modified_amplitude_tx(modified_amplitude_tx < 0) = 0; % Set amplitudes below 0 mV to 0 mV
    modified_amplitude_tx(modified_amplitude_tx > 200) = 100; % Set amplitudes above 200 mV to 1000 mV

    % Find the indices where the transmitted waveform starts and ends
    pulse_indices_tx = find(modified_amplitude_tx > 0); % Non-zero amplitudes indicate pulses
    if isempty(pulse_indices_tx)
        error('No pulses found in the transmitted waveform.');
    end

    start_index_tx = pulse_indices_tx(1);
    end_index_tx = pulse_indices_tx(end);

    % Adjust transmitted time and amplitude arrays to focus on the region of interest
    adjusted_time_tx = time_tx(start_index_tx:end_index_tx) - time_tx(start_index_tx);
    adjusted_amplitude_tx = amplitude_tx(start_index_tx:end_index_tx);
    
    % Process the received signal
    % Create a modified amplitude for processing (not for display)
    modified_amplitude_rx = amplitude_rx;
    modified_amplitude_rx(modified_amplitude_rx < 0) = 0; % Set amplitudes below 0 mV to 0 mV
    modified_amplitude_rx(modified_amplitude_rx > 200) = 1000; % Set amplitudes above 200 mV to 1000 mV

    % Find the indices where the received waveform starts and ends
    pulse_indices_rx = find(modified_amplitude_rx > 0); % Non-zero amplitudes indicate pulses
    if isempty(pulse_indices_rx)
        error('No pulses found in the received waveform.');
    end

    start_index_rx = pulse_indices_rx(1);
    end_index_rx = pulse_indices_rx(end);

    % Adjust received time and amplitude arrays to focus on the region of interest
    adjusted_time_rx = time_rx(start_index_rx:end_index_rx) - time_rx(start_index_rx); % Shift time to start at 0
    adjusted_amplitude_rx = amplitude_rx(start_index_rx:end_index_rx);
    
    % Superimpose the transmitted and received waveforms for comparison
    
    % Find the maximum time value for both signals
    max_time = max(max(adjusted_time_tx), max(adjusted_time_rx));
    
    % Create a common time base for interpolation
    common_time = linspace(0, max_time, 10000);
    
    % Interpolate both signals to the common time base
    interp_tx = interp1(adjusted_time_tx, adjusted_amplitude_tx, common_time, 'linear', 0);
    interp_rx = interp1(adjusted_time_rx, adjusted_amplitude_rx, common_time, 'linear', 0);
    
    % Plot the superimposed waveforms
    figure;
    plot(common_time, interp_tx, 'b', 'LineWidth', 1.5);
    hold on;
    plot(common_time, interp_rx, 'r', 'LineWidth', 1);
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Transmitted vs. Received Waveforms');
    legend('Transmitted', 'Received');
    grid on;
end

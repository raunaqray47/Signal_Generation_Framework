function plot_csv_data(filename)
    % Read the CSV file
    data = readtable(filename);

    % Convert time to microseconds and amplitude to millivolts
    time = data.TIME * 1e6; % Time in microseconds
    amplitude = data.CH1 * 1e3; % Amplitude in millivolts

    % Create a modified amplitude
    modified_amplitude = amplitude;
    modified_amplitude(modified_amplitude < 0) = 0; % Set amplitudes below 0 mV to 0 mV
    modified_amplitude(modified_amplitude > 500) = 1000; % Set amplitudes above 500 mV to 1000 mV

    % Find the indices where the waveform starts and ends
    pulse_indices = find(modified_amplitude > 0); % Non-zero amplitudes indicate pulses
    if isempty(pulse_indices)
        error('No pulses found in the waveform.');
    end

    start_index = pulse_indices(1);
    end_index = pulse_indices(end);

    % Adjust time and amplitude arrays to focus on the region of interest
    adjusted_time = time(start_index:end_index) - time(start_index); % Shift time to start at 0
    adjusted_amplitude = modified_amplitude(start_index:end_index);

    % Add a linear segment from (0, 0) to the first point of the waveform
    extended_time_start = [0; adjusted_time];
    extended_amplitude_start = [0; adjusted_amplitude];

    % Add a linear segment from the last point of the waveform to (end_time, 0)
    extended_time_end = [extended_time_start; adjusted_time(end)];
    extended_amplitude_end = [extended_amplitude_start; 0];

    % Calculate scaling factor to make the waveform exactly 120 microseconds long
    current_duration = extended_time_end(end); % Current duration of the waveform
    scaling_factor = 120 / current_duration; % Scaling factor for time adjustment

    % Apply scaling factor to time axis
    scaled_time = extended_time_end * scaling_factor;

    % Plot the original waveform
    figure;
    plot(time, amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Original Waveform');
    grid on;

    % Plot the scaled waveform with adjusted time axis and extended segments
    figure;
    plot(scaled_time, extended_amplitude_end, 'r');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Scaled Waveform (120 \mus)');
    grid on;
    ylim([-50,1050]);
    xlim([-2,122]);
    
end

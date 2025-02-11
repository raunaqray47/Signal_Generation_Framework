function plot_csv_data(filename)
    % Read the CSV file
    data = readtable(filename);

    % Convert time to microseconds and amplitude to millivolts
    time = data.TIME * 1e6; % Time in microseconds
    amplitude = data.CH1 * 1e3; % Amplitude in millivolts

    %{
    % Create a modified amplitude
    modified_amplitude = amplitude;
    modified_amplitude(modified_amplitude < 0) = 0; % Set amplitudes below 0 mV to 0 mV
    modified_amplitude(modified_amplitude > 800) = 1000; % Set amplitudes steadily above 800 mV to 1000 mV
    %}

    % Plot the original waveform
    figure;
    plot(time, amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Original Waveform');
    grid on;
    ylim([-50, 1050]);
    xlim([-2,122]);

    %{
    % Plot the modified waveform
    figure;
    plot(time, modified_amplitude, 'r');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Modified Waveform');
    grid on;
    ylim([-50, 1050]);
    %}
    
end

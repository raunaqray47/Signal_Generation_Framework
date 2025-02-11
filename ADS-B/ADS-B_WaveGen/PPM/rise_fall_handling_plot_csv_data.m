function rise_fall_handling_plot_csv_data(filename)
    % Read the CSV file
    data = readtable(filename);

    % Convert time to microseconds and amplitude to millivolts
    time = data.TIME * 1e6; % Time in microseconds
    amplitude = data.CH1 * 1e3; % Amplitude in millivolts

    % Plot the original waveform
    figure;
    plot(time, amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Original Waveform');
    grid on;
    ylim([-50, 1050]);
    xlim([-2, 122]);

    % Create a modified waveform with instant rise/fall times
    modified_time = [];
    modified_amplitude = [];
    
    for i = 1:length(amplitude) - 1
        modified_time = [modified_time; time(i)];
        modified_amplitude = [modified_amplitude; amplitude(i)];
        
        if amplitude(i) ~= amplitude(i+1)
            % Add an instant transition point
            modified_time = [modified_time; time(i)];
            modified_amplitude = [modified_amplitude; amplitude(i+1)];
        end
    end
    
    % Add last point
    modified_time = [modified_time; time(end)];
    modified_amplitude = [modified_amplitude; amplitude(end)];

    % Plot the modified waveform (square wave)
    figure;
    plot(modified_time, modified_amplitude, 'r');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Modified Waveform (Square Wave with Instant Transitions)');
    grid on;
    ylim([-50, 1050]);
    xlim([-2, 122]);
end

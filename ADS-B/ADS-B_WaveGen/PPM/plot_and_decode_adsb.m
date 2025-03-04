function plot_and_decode_adsb(filename)
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

    % Plot the original waveform
    figure;
    plot(time, amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Original Waveform');
    grid on;
    ylim([-50,1050]);
    xlim([-2, 150]);

    % Plot the adjusted waveform with extended segments
    figure;
    plot(extended_time_end, extended_amplitude_end, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Adjusted Waveform');
    grid on;
    ylim([-50,1050]);
    xlim([-2, max(extended_time_end)+2]);

    % Remove the first 4 bits
    bit_duration = 2.4; % Assuming each bit is approximately 2.4 microseconds
    first_4_bits_end = 4 * bit_duration;
    
    % Find the start of the 5th bit (first spike after removing 4 bits)
    message_start_index = find(extended_time_end > first_4_bits_end & extended_amplitude_end > 0, 1);
    
    % Adjust time and amplitude arrays to focus on the new region of interest
    message_time = extended_time_end(message_start_index:end) - extended_time_end(message_start_index);
    message_amplitude = extended_amplitude_end(message_start_index:end);

    % Add a linear segment from (0, 0) to the first point of the message waveform
    message_time = [0; message_time];
    message_amplitude = [0; message_amplitude];
    
    % Add a linear segment from the last point of the message waveform to (end_time, 0)
    message_time = [message_time; message_time(end)];
    message_amplitude = [message_amplitude; 0];

    % Plot the message waveform (without first 4 bits)
    figure;
    plot(message_time, message_amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Message Waveform');
    grid on;
    ylim([-50,1050]);
    xlim([-2, max(message_time)+2]);

    % Call the decode function
    decoded_bits = decode_adsb_message(message_time, message_amplitude);

    % Print the decoded bits
    disp('Decoded ADS-B message:');
    disp(decoded_bits);
end

function decoded_bits = decode_adsb_message(message_time, message_amplitude)
    % Initialize variables
    decoded_bits = [];
    bit_duration = 1.0; % Each bit is 1 microsecond in ADS-B
    threshold = 500; % Amplitude threshold for detecting a pulse
    
    % Find all pulse positions (where amplitude goes above threshold)
    pulse_positions = [];
    for i = 1:length(message_time)-1
        if message_amplitude(i) <= threshold && message_amplitude(i+1) > threshold
            % Interpolate to find the exact crossing time
            t1 = message_time(i);
            t2 = message_time(i+1);
            a1 = message_amplitude(i);
            a2 = message_amplitude(i+1);
            
            % Linear interpolation to find where amplitude crosses threshold
            t_cross = t1 + (threshold - a1) * (t2 - t1) / (a2 - a1);
            pulse_positions = [pulse_positions, t_cross];
        end
    end
    
    % Process each pulse to determine the bit value
    for i = 1:length(pulse_positions)
        % Calculate which bit this pulse belongs to
        bit_number = floor(pulse_positions(i) / bit_duration);
        
        % Calculate position within the bit (0 to 1)
        position_in_bit = (pulse_positions(i) - bit_number * bit_duration) / bit_duration;
        
        % Determine if it's a 0 or 1 based on pulse position
        % If pulse is in first half of bit duration, it's a 1, otherwise it's a 0
        if position_in_bit < 0.5
            bit_value = 1; % Pulse in first half, so it's a 1
        else
            bit_value = 0; % Pulse in second half, so it's a 0
        end
        
        % Add the bit to our decoded message
        if bit_number+1 > length(decoded_bits)
            % Pad with zeros if there are missing bits
            decoded_bits = [decoded_bits, zeros(1, bit_number+1-length(decoded_bits))];
        end
        decoded_bits(bit_number+1) = bit_value;
    end
    
    % Check if we have 112 bits (standard ADS-B message length)
    if length(decoded_bits) > 112
        % Truncate to 112 bits if longer
        decoded_bits = decoded_bits(1:112);
        disp('Warning: Decoded more than 112 bits, truncating to standard ADS-B length.');
    elseif length(decoded_bits) < 112
        % Throw an error if fewer than 112 bits
        error(['Error: Decoded only ', num2str(length(decoded_bits)), ' bits. ADS-B messages must contain exactly 112 bits.']);
    end
end
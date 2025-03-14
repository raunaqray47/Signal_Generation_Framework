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

    % Ensure the waveform is exactly 120 microseconds long
    % Find the index where time exceeds 120 microseconds
    end_120us_index = find(adjusted_time >= 120, 1);
    
    % If the waveform is shorter than 120 microseconds, pad it
    if isempty(end_120us_index)
        % Extend the time array to 120 microseconds
        last_time = adjusted_time(end);
        time_step = mean(diff(adjusted_time));
        additional_times = (last_time+time_step):time_step:120;
        adjusted_time = [adjusted_time; additional_times'];
        adjusted_amplitude = [adjusted_amplitude; zeros(length(additional_times), 1)];
    %else
        % Truncate to exactly 120 microseconds
        %adjusted_time = adjusted_time(1:end_120us_index);
        %adjusted_amplitude = adjusted_amplitude(1:end_120us_index);
    end

    % Plot the original waveform
    figure;
    plot(time, amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Original Waveform');
    grid on;

    % Plot the adjusted waveform
    figure;
    stairs(adjusted_time, adjusted_amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Adjusted Waveform (120 \mus)');
    grid on;
    ylim([-50,1050]);
    xlim([-2, 122]);

    % Remove the first 8 microseconds (preamble)
    preamble_end = 8.0; % 8 microseconds for preamble
    
    % Find the index where time exceeds the preamble duration
    message_start_index = find(adjusted_time >= preamble_end, 1);
    
    if isempty(message_start_index)
        warning('Could not find the end of the preamble. Using the entire signal.');
        message_time = adjusted_time;
        message_amplitude = adjusted_amplitude;
    else
        % Extract the message portion (after preamble)
        message_time = adjusted_time(message_start_index:end) - adjusted_time(message_start_index);
        message_amplitude = adjusted_amplitude(message_start_index:end);
    end

    % Plot the message waveform (without preamble)
    figure;
    stairs(message_time, message_amplitude, 'b');
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Message Waveform (Preamble Removed)');
    grid on;
    ylim([-50,1050]);
    xlim([-2, 122]);

    % Call the decode function
    decoded_bits = decode_adsb_message(message_time, message_amplitude);

    % Print the decoded bits
    disp('Decoded ADS-B message:');
    disp(decoded_bits);

    % Collate decoded bits into a binary string
    binary_string = num2str(decoded_bits,'%d');
    binary_string = regexprep(binary_string,'\s',''); % remove whitespace

    % Flip bits: 0 -> 1, 1 -> 0
    flipped_bits = regexprep(binary_string,{'0','1'},{'x','0'}); % temporary placeholder 'x'
    flipped_bits = regexprep(flipped_bits,'x','1');

    % Append an additional '0' at the end
    new_binary_string = [flipped_bits '1'];

    % Display the final binary string
    disp('Final binary string:');
    disp(new_binary_string);
end

function decoded_bits = decode_adsb_message(message_time, message_amplitude)
    % Initialize variables
    decoded_bits = [];
    bit_duration = 1.0; % Each bit is 1 microsecond in ADS-B
    threshold = 500; % Amplitude threshold for detecting a pulse
    margin = 0.05; % Margin of error in microseconds
    
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
        
        % Determine if it's a 0 or 1 based on pulse position with margin
        % If pulse is in first half (0 to 0.5 ± margin) of bit duration, it's a 1
        % If pulse is in second half (0.5 to 1.0 ± margin) of bit duration, it's a 0
        if position_in_bit < (0.5 + margin) && position_in_bit > (0 - margin)
            bit_value = 1; % Pulse in first half, so it's a 1
        elseif position_in_bit >= (0.5 - margin) && position_in_bit <= (1 + margin)
            bit_value = 0; % Pulse in second half, so it's a 0
        else
            % If outside valid ranges (shouldn't happen with proper margin)
            warning('Pulse at unusual position: %f in bit %d', position_in_bit, bit_number);
            % Default to closest valid position
            if position_in_bit < 0.5
                bit_value = 1;
            else
                bit_value = 0;
            end
        end
        
        % Add the bit to our decoded message
        if bit_number+1 > length(decoded_bits)
            % Pad with zeros if there are missing bits
            decoded_bits = [decoded_bits, zeros(1, bit_number+1-length(decoded_bits))];
        end
        decoded_bits(bit_number+1) = bit_value;
    end
    
    % Report the number of bits decoded
    fprintf('Decoded %d bits from the waveform.\n', length(decoded_bits));
    
    % Check if we have 112 bits (standard ADS-B message length)
    if length(decoded_bits) > 112
        fprintf('Warning: Decoded %d bits, which is more than the standard 112 bits.\n', length(decoded_bits));
    elseif length(decoded_bits) < 112
        fprintf('Warning: Decoded only %d bits, fewer than the standard 112 bits.\n', length(decoded_bits));
    end
end

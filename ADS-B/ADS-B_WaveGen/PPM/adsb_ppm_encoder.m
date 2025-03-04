function adsb_ppm_encoder(hex_message)
    % Define constants
    BIT_RATE = 1e6;            % 1 Mbps
    SAMPLING_RATE = 20e6;      % 20 MHz
    SAMPLES_PER_BIT = SAMPLING_RATE / BIT_RATE;  % 20 samples per bit for message
    
    % Step 1: Convert hex to binary
    binary_message = hex2bin(hex_message);
    
    % Step 2: Check if binary length is exactly 112 bits
    if length(binary_message) ~= 112
        error('Error: Binary message length must be exactly 112 bits');
    end
    
    % Calculate total samples for the entire signal
    preamble_duration_us = 8;  % 8 μs preamble
    message_duration_us = 112; % 112 μs for message (1 μs per bit)
    total_duration_us = preamble_duration_us + message_duration_us;
    total_samples = round(total_duration_us * 1e-6 * SAMPLING_RATE);
    
    % Create exact time vector
    time_vector = (0:total_samples-1) / SAMPLING_RATE;
    
    % Create empty signal array
    signal = zeros(1, total_samples);
    
    % Generate preamble
    % Preamble has 4 pulses at positions 0, 1, 3.5, and 4.5 μs, each 0.5 μs wide
    preamble_pulse_positions_us = [0, 1, 3.5, 4.5];
    pulse_width_us = 0.5;
    
    for pos = preamble_pulse_positions_us
        start_sample = floor(pos * 1e-6 * SAMPLING_RATE) + 1;
        end_sample = floor((pos + pulse_width_us) * 1e-6 * SAMPLING_RATE);
        signal(start_sample:end_sample) = 1;
    end
    
    % Generate data portion
    preamble_samples = round(preamble_duration_us * 1e-6 * SAMPLING_RATE);
    half_bit_samples = round(SAMPLES_PER_BIT / 2);
    
    for i = 1:length(binary_message)
        bit_start_sample = preamble_samples + (i-1) * SAMPLES_PER_BIT + 1;
        
        if binary_message(i) == 1
            % Pulse in first half of bit period
            start_sample = bit_start_sample;
            end_sample = bit_start_sample + half_bit_samples - 1;
        else
            % Pulse in second half of bit period
            start_sample = bit_start_sample + half_bit_samples;
            end_sample = bit_start_sample + SAMPLES_PER_BIT - 1;
        end
        
        signal(start_sample:end_sample) = 1;
    end
    
    % Plot original signal
    figure(1);
    stairs(time_vector * 1e6, signal);
    title('ADS-B Original Signal');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    grid on;
    xlim([0, total_duration_us]);
    ylim([-0.2, 1.2]);
    
    % Save original signal to txt file
    save_signal_to_file(time_vector * 1e6, signal, 'original_signal.txt');
    
    % Generate flipped signal
    flipped_signal = -signal;
    
    % Save flipped signal to txt file
    save_signal_to_file(time_vector * 1e6, flipped_signal, 'flipped_signal.txt');
    
    % Plot flipped signal
    figure(2);
    stairs(time_vector * 1e6, flipped_signal);
    title('ADS-B Flipped Signal');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    grid on;
    xlim([0, total_duration_us]);
    ylim([-1.2, 0.2]);
    
    % Plot both signals together
    figure(3);
    stairs(time_vector * 1e6, signal, 'b');
    hold on;
    stairs(time_vector * 1e6, flipped_signal, 'r');
    title('ADS-B Original and Flipped Signals');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    legend('Original Signal', 'Flipped Signal');
    grid on;
    xlim([0, total_duration_us]);
    ylim([-1.2, 1.2]);
    
    fprintf('Processing complete. Files saved: original_signal.txt and flipped_signal.txt\n');
    
    % Print timing information for verification
    fprintf('Sampling rate: %.2f MHz (%d samples per bit)\n', SAMPLING_RATE/1e6, SAMPLES_PER_BIT);
    fprintf('Time resolution: %.3f ns\n', 1e9/SAMPLING_RATE);
end

function binary_message = hex2bin(hex_message)
    % Convert hex message to binary
    hex_chars = char(hex_message);
    binary_message = [];
    
    for i = 1:length(hex_chars)
        decimal_value = hex2dec(hex_chars(i));
        binary_chunk = dec2bin(decimal_value, 4); % 4 bits per hex character
        binary_message = [binary_message, binary_chunk];
    end
    
    % Convert from char to numeric array (0s and 1s)
    binary_message = binary_message - '0';
end

function save_signal_to_file(time_vector, signal, filename)
    % Save signal to file with time-amplitude pairs
    data = [time_vector', signal'];
    fid = fopen(filename, 'w');
    fprintf(fid, '# Time(μs)\tAmplitude\n');
    fprintf(fid, '%f\t%f\n', data');
    fclose(fid);
end
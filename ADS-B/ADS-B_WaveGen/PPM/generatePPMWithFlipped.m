function generatePPMWithFlipped(hex_input)
    % File paths for saving
    output_original = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\ppm_signal.txt';
    output_flipped = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\flipped_ppm_signal.txt';
    
    % Parameters
    sampling_rate = 20e6; % 20 MHz sampling rate
    
    % Generate preamble (8μs)
    [preamble_signal, ~] = generatePreamble(sampling_rate);
    
    % Convert hex input to binary message (112 bits)
    binary_message = hexToBinaryVector(hex_input);
    if length(binary_message) ~= 112
        error('Hex input must produce exactly 112 bits (28 hex characters)');
    end
    
    % Generate message signal (112μs)
    [message_signal, ~] = generateMessage(binary_message, sampling_rate);
    
    % Combine signals
    original_signal = [preamble_signal, message_signal];
    time_axis = (0:length(original_signal)-1) / sampling_rate;
    
    % Plot original signal
    figure;
    stairs(time_axis * 1e6, original_signal);
    ylim([-0.5 1.5]);
    title('Original PPM Signal with Preamble');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    grid on;

    % Save original signal
    writematrix([time_axis', original_signal'], output_original, 'Delimiter', 'tab');
    disp(['Original signal saved to: ', output_original]);
    
    % Generate flipped signal (amplitude inversion)
    flipped_signal = -original_signal;
    
    % Plot flipped signal
    figure;
    stairs(time_axis * 1e6, flipped_signal);
    ylim([-1.5 0.5]);
    title('Flipped PPM Signal');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    grid on;
    
    % Save flipped signal
    writematrix([time_axis', flipped_signal'], output_flipped, 'Delimiter', 'tab');
    disp(['Flipped signal saved to: ', output_flipped]);
    
    % Plot combined signals
    figure;
    stairs(time_axis * 1e6, original_signal, 'b', 'DisplayName', 'Original');
    hold on;
    stairs(time_axis * 1e6, flipped_signal, 'r', 'DisplayName', 'Flipped');
    ylim([-1.5 1.5]);
    title('Combined PPM Signals');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    legend show;
    grid on;
end

function [ppm_signal, time_axis] = generatePreamble(sampling_rate)
    % Preamble parameters
    preamble_bits = '1010000101000000'; % 16 bits at 0.5μs each (8μs total)
    bit_rate = 2e6; % 2 Mbps for preamble (0.5μs/bit)
    samples_per_bit = sampling_rate / bit_rate;
    
    ppm_signal = zeros(1, length(preamble_bits) * samples_per_bit);
    
    for i = 1:length(preamble_bits)
        start_idx = (i-1)*samples_per_bit + 1;
        end_idx = i*samples_per_bit;
        
        if preamble_bits(i) == '1'
            ppm_signal(start_idx:end_idx) = 1;
        end
    end
    
    time_axis = (0:length(ppm_signal)-1)/sampling_rate;
end

function [ppm_signal, time_axis] = generateMessage(binary_message, sampling_rate)
    % Message parameters
    bit_rate = 1e6; % 1 Mbps (1μs/bit)
    samples_per_bit = sampling_rate / bit_rate;
    pulse_width = round(0.5 * samples_per_bit);
    
    ppm_signal = zeros(1, length(binary_message) * samples_per_bit);
    
    for i = 1:length(binary_message)
        start_idx = (i-1)*samples_per_bit + 1;
        mid_idx = start_idx + pulse_width - 1;
        end_idx = start_idx + samples_per_bit - 1;
        
        if binary_message(i) == '1'
            ppm_signal(start_idx:mid_idx) = 1;
        else
            ppm_signal(mid_idx+1:end_idx) = 1;
        end
    end
    
    time_axis = (0:length(ppm_signal)-1)/sampling_rate;
end

function binary_vector = hexToBinaryVector(hex_str)
    binary_vector = '';
    hex_map = containers.Map({'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}, ...
        {'0000','0001','0010','0011','0100','0101','0110','0111','1000','1001','1010','1011','1100','1101','1110','1111'});
    
    for i = 1:length(hex_str)
        binary_vector = [binary_vector, hex_map(upper(hex_str(i)))];
    end
end
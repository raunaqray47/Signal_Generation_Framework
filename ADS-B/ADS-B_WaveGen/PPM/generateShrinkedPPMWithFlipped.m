function generateShrinkedPPMWithFlipped(hex_input)
    output_original = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\ppm_signal_shrinked.txt';
    output_flipped = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\flipped_ppm_signal_shrinked.txt';
    
    original_length = 136e-6; % 136 microseconds
    desired_length = 112e-6; % 112 microseconds

    % Convert hex input to binary
    binary_message = hexToBinaryVector(hex_input);

    % Generate PPM signal for the original message
    [original_signal, time_axis] = generatePPM(binary_message, original_length, desired_length);

    % Plot original PPM signal
    figure;
    plot(time_axis * 1e6, original_signal);
    ylim([-0.5, 1.5]);
    grid on;
    title('Original PPM Signal');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Save original PPM signal to text file
    writematrix([time_axis', original_signal'], output_original, 'Delimiter', 'tab');
    disp(['Original PPM signal saved to: ', output_original]);

    % Flip the binary message
    flipped_message = char(bitxor(binary_message - '0', 1) + '0');

    % Generate PPM signal for the flipped message
    [flipped_signal, ~] = generatePPM(flipped_message, original_length, desired_length);

    % Plot flipped PPM signal
    figure;
    plot(time_axis * 1e6, flipped_signal);
    ylim([-0.5, 1.5]);
    grid on;
    title('Flipped PPM Signal');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Save flipped PPM signal to text file
    writematrix([time_axis', flipped_signal'], output_flipped, 'Delimiter', 'tab');
    disp(['Flipped PPM signal saved to: ', output_flipped]);
end

function [ppm_signal, time_axis] = generatePPM(binary_message, original_length, desired_length)
    bit_rate = 1000000; % 1 Mbps
    total_samples = 2240; % To match the function generator's limitation
    
    % Calculate the shrink factor
    shrink_factor = desired_length / original_length;
    
    % Calculate new parameters
    adjusted_duration = desired_length * shrink_factor; % This will be shorter than 112 microseconds
    samples_per_second = total_samples / adjusted_duration;
    samples_per_bit = total_samples / length(binary_message);
    pulse_width_samples = round(0.5 * samples_per_bit);

    ppm_signal = zeros(1, total_samples);

    for i = 1:length(binary_message)
        start_index = round((i-1) * samples_per_bit) + 1;
        mid_index = start_index + pulse_width_samples;
        end_index = round(i * samples_per_bit);

        if binary_message(i) == '1'
            ppm_signal(start_index:mid_index-1) = 1; % Pulse first half for '1'
        else
            ppm_signal(mid_index:end_index) = 1;   % Pulse second half for '0'
        end
    end

    time_axis = linspace(0, adjusted_duration, total_samples);
end

function binary_vector = hexToBinaryVector(hex_str)
    binary_vector = '';
    
    for i = 1:length(hex_str)
        nibble = hex_str(i);
        if nibble >= '0' && nibble <= '9'
            bin_nibble = dec2bin(str2double(nibble), 4);
        else
            bin_nibble = dec2bin(double(nibble) - double('A') + 10, 4);
        end
        
        binary_vector = [binary_vector, bin_nibble];
    end
end

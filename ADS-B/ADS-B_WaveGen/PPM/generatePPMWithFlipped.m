function generatePPMWithFlipped(hex_input)
    output_original = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\ppm_signal.txt';
    output_flipped = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\flipped_ppm_signal.txt';
    
    % Convert hex input to binary
    binary_message = hexToBinaryVector(hex_input);

    % Generate PPM signal for the original message
    [original_signal, time_axis] = generatePPM(binary_message);

    % Plot original PPM signal
    figure;
    plot(time_axis * 1e6, original_signal); % Convert to microseconds for display
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
    [flipped_signal, ~] = generatePPM(flipped_message);

    % Plot flipped PPM signal
    figure;
    plot(time_axis * 1e6, flipped_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('Flipped PPM Signal');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Save flipped PPM signal to text file
    writematrix([time_axis', flipped_signal'], output_flipped, 'Delimiter', 'tab');
    disp(['Flipped PPM signal saved to: ', output_flipped]);
end

function [ppm_signal, time_axis] = generatePPM(binary_message)
    % ADS-B PPM encoding parameters
    bit_rate = 1000000; % 1 Mbps
    samples_per_second = 20000000; % 20 MHz sampling rate
    samples_per_bit = samples_per_second / bit_rate;
    pulse_width_samples = round(0.5 * samples_per_bit); % 0.5 μs pulse width

    % Initialize PPM signal
    ppm_signal = zeros(1, length(binary_message) * samples_per_bit);

    % Generate PPM signal
    for i = 1:length(binary_message)
        start_index = round((i-1) * samples_per_bit) + 1;
        mid_index = start_index + pulse_width_samples;
        end_index = start_index + samples_per_bit - 1;

        if binary_message(i) == '1'
            ppm_signal(start_index:mid_index-1) = 1; % Pulse first half for '1'
        else
            ppm_signal(mid_index:end_index) = 1;   % Pulse second half for '0'
        end
    end

    % Generate time axis
    time_axis = (0:length(ppm_signal)-1) / samples_per_second;
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
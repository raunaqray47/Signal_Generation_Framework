% Generates and compares original and bit-flipped PPM encoded ADS-B messages.
% It takes a hexadecimal ADS-B message, converts it to binary, generates PPM signals for both the original and bit-flipped messages, plots them,
% and saves the flipped PPM signal to a text file.
% Input:
% hex_value = '8D4840D6202CC371C32CE0576098';
% generateFlippedPPM(hex_value);
% Output:
% Original PPM Encoded Message (Hex):
% 8D4840D6202CC371C32CE0576098
% Original PPM Encoded Message (Binary):
% 10001101010010000100000011010110001000000010110011000011011100011100...
% Flipped PPM Encoded Message (Binary):
% 01110010101101111011111100101001110111111101001100111100100011000011...
% Flipped PPM signal saved to: C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\flipped_ppm_signal.txt
%
% The function also generates two figures:
% 1. Original PPM Encoded ADS-B Message
% 2. Flipped PPM Encoded ADS-B Message

function generateFlippedPPM(hex_value)
    % Convert the hex message to binary
    hex_message = hexToBinaryVector(hex_value);

    % Generate PPM encoded signal for the original message
    [ppm_signal, time_axis] = generatePPM(hex_message);

    % Plot PPM encoded signal for the original message
    figure;
    plot(time_axis * 1e6, ppm_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('Original PPM Encoded Message');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Display the original PPM message
    disp('Original PPM Encoded Message (Hex):');
    disp(hex_value);
    disp('Original PPM Encoded Message (Binary):');
    disp(hex_message);

    % Flip the bits in the binary message
    flipped_message = char(bitxor(hex_message - '0', 1) + '0');

    % Generate PPM signal for the flipped message
    [flipped_ppm_signal, flipped_time_axis] = generatePPM(flipped_message);

    % Display the flipped binary message
    disp('Flipped PPM Encoded Message (Binary):');
    disp(flipped_message);

    % Plot flipped PPM encoded signal
    figure;
    plot(flipped_time_axis * 1e6, flipped_ppm_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('Flipped PPM Encoded Message');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Save flipped PPM signal to text file
    outputPath = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\flipped_ppm_signal.txt';
    writematrix([flipped_time_axis', flipped_ppm_signal'], outputPath, 'Delimiter', 'tab');
    disp(['Flipped PPM signal saved to: ', outputPath]);
end

function [ppm_signal, time_axis] = generatePPM(binary_message)
    % ADS-B PPM encoding parameters
    bit_rate = 1000000; % 1 Mbps
    samples_per_second = 20000000; % 20 MHz sampling rate for smooth representation
    samples_per_bit = samples_per_second / bit_rate;
    pulse_width_samples = round(0.5 * samples_per_bit); % 0.5 μs pulse width
    
    % Initialize PPM signal
    ppm_signal = zeros(1, length(binary_message) * samples_per_bit);
    
    % Generate PPM signal
    for i = 1:length(binary_message)
        if binary_message(i) == '0'
            start_index = round((i-1) * samples_per_bit) + 1;
        else
            start_index = round((i-1) * samples_per_bit + samples_per_bit/2) + 1;
        end
        end_index = min(start_index + pulse_width_samples - 1, length(ppm_signal));
        ppm_signal(start_index:end_index) = 1;
    end
    
    % Generate time axis
    time_axis = (0:length(ppm_signal)-1) / samples_per_second;
end

function bin_vector = hexToBinaryVector(hex_str)
    bin_vector = '';
    for i = 1:length(hex_str)
        nibble = hex_str(i);
        if nibble >= '0' && nibble <= '9'
            bin_nibble = dec2bin(str2double(nibble), 4);
        else
            bin_nibble = dec2bin(double(nibble) - double('A') + 10, 4);
        end
        bin_vector = [bin_vector, bin_nibble];
    end
end

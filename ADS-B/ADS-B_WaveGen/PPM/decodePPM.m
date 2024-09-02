function [decoded_hex, decoded_binary] = decodePPM(file_path)
% decodePPM - Decode Pulse Position Modulation (PPM) signal from a text file
%
% This function reads a PPM signal from a text file, plots the original waveform,
% decodes the PPM signal to binary, and converts the binary to hexadecimal.
%
% Input:
%   file_path - Path to the text file containing the PPM signal data
%
% Output:
%   decoded_hex - The decoded data in hexadecimal format
%   decoded_binary - The decoded data in binary format
%
% The function performs the following operations:
% 1. Reads the PPM signal data from the specified text file
% 2. Plots the original PPM waveform
% 3. Decodes the PPM signal to binary
% 4. Converts the binary data to hexadecimal
% 5. Plots the decoded binary data
%
% Usage example:
%   file_path = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\ppm_signal.txt';
%   [decoded_hex, decoded_binary] = decodePPM(file_path);

    % Read the PPM signal from the text file
    data = readmatrix(file_path);
    time = data(:, 1);
    ppm_signal = data(:, 2);

    % Plot the original PPM waveform
    figure;
    subplot(2,1,1);
    plot(time * 1e6, ppm_signal);
    title('Original PPM Waveform');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    ylim([-0.5 1.5]);
    grid on;

    % Decode the PPM signal
    bit_duration = 1e-6; % 1 μs (1 Mbps)
    threshold = 0.5;
    decoded_binary = [];

    num_bits = floor(max(time) / bit_duration);
    for bit_index = 0:num_bits-1
        start_time = bit_index * bit_duration;
        end_time = (bit_index + 1) * bit_duration;
        sample_indices = find(time >= start_time & time < end_time);
        if ~isempty(sample_indices) && any(ppm_signal(sample_indices) > threshold)
            if mean(time(sample_indices(ppm_signal(sample_indices) > threshold))) - start_time > bit_duration/2
                decoded_binary = [decoded_binary 1];
            else
                decoded_binary = [decoded_binary 0];
            end
        else
            decoded_binary = [decoded_binary 0];
        end
    end

    % Ensure decoded_binary is a row vector
    decoded_binary = decoded_binary(:)';

    % Convert binary to hexadecimal
    padded_binary = [decoded_binary zeros(1, mod(-length(decoded_binary), 4))];
    decoded_hex = binaryVectorToHex(padded_binary);

    % Plot the decoded binary data
    subplot(2,1,2);
    stairs(0:length(decoded_binary)-1, decoded_binary);
    title('Decoded Binary Data');
    xlabel('Bit Index');
    ylabel('Bit Value');
    ylim([-0.5 1.5]);
    xlim([0 length(decoded_binary)]);
    grid on;

    % Display results
    disp('Decoded Hexadecimal:');
    disp(decoded_hex);
    disp('Decoded Binary:');
    disp(num2str(decoded_binary));
end

function hex = binaryVectorToHex(binary_vector)
    hex_chars = '0123456789ABCDEF';
    hex = '';
    for i = 1:4:length(binary_vector)
        nibble = binary_vector(i:i+3);
        hex_index = 1 + nibble(1)*8 + nibble(2)*4 + nibble(3)*2 + nibble(4);
        hex = [hex hex_chars(hex_index)];
    end
end
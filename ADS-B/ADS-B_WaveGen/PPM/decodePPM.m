% This function decodes a Pulse Position Modulation (PPM) encoded signal from a waveform stored in a text file.
%
% The function performs the following steps:
% 1. Reads the PPM signal from a specified text file.
% 2. Plots the original PPM waveform for visual inspection.
% 3. Decodes the PPM signal by analyzing pulse positions within each bit period.
% 4. Converts the decoded binary sequence to hexadecimal.
% 5. Displays and returns the decoded binary and hexadecimal representations.
%
% Input:
% file_path = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\ppm_signal.txt';
% [decoded_hex, decoded_binary] = decodePPM(file_path);
%
% Outputs:
% Decoded Hexadecimal:
% F8
% Decoded Binary:
% 1  1  1  1  1  0  0  0
%
% The function assumes:
% - A bit duration of 1 μs
% - 20 samples per bit (20 MHz sampling rate)
% - An amplitude threshold of 0.5 for pulse detection
%
% Note: This decoder is designed for ADS-B-like PPM signals where '0' is represented by a pulse in the first half of the bit period, and '1' by a pulse in the second half.

function [decoded_hex, decoded_binary] = decodePPM(file_path)
    % Read the PPM signal from the text file
    data = readmatrix(file_path);
    time = data(:, 1);
    ppm_signal = data(:, 2);

    % Plot the original PPM waveform
    figure;
    plot(time * 1e6, ppm_signal);
    title('PPM Encoded Signal');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    ylim([-0.5 1.5]);
    grid on;

    % Decode the PPM signal
    bit_duration = 1e-6; % 1 μs per bit
    samples_per_bit = 20; % 20 samples per bit at 20 MHz
    threshold = 0.5; % Amplitude threshold for detecting a pulse
    
    % Initialize decoded binary array
    decoded_binary = zeros(1, floor(max(time) / bit_duration));

    % Process each bit period
    for bit_index = 1:length(decoded_binary)
        % Determine the time range for the current bit
        start_time = (bit_index - 1) * bit_duration;
        end_time = start_time + bit_duration;
        
        % Find the samples corresponding to the current bit
        sample_indices = find(time >= start_time & time < end_time);
        if isempty(sample_indices)
            continue;
        end
        
        % Check for a pulse in the first or second half of the bit period
        mid_point = start_time + bit_duration / 2;
        first_half_indices = sample_indices(time(sample_indices) < mid_point);
        second_half_indices = sample_indices(time(sample_indices) >= mid_point);
        
        if any(ppm_signal(first_half_indices) > threshold)
            decoded_binary(bit_index) = 0; % Pulse in the first half -> '0'
        elseif any(ppm_signal(second_half_indices) > threshold)
            decoded_binary(bit_index) = 1; % Pulse in the second half -> '1'
        end
    end

    % Trim any trailing zeros and ensure length is a multiple of 8
    decoded_binary = decoded_binary(1:find(decoded_binary, 1, 'last'));
    if mod(length(decoded_binary), 8) ~= 0
        decoded_binary = [decoded_binary zeros(1, 8 - mod(length(decoded_binary), 8))];
    end

    % Convert binary to hexadecimal
    decoded_hex = binaryVectorToHex(decoded_binary);

    % Display results
    disp('Decoded Hexadecimal:');
    disp(decoded_hex);
    disp('Decoded Binary:');
    disp(num2str(decoded_binary));
end

function hex = binaryVectorToHex(binary_vector)
    hex = dec2hex(bin2dec(reshape(char(binary_vector + '0'), 8, [])'))';
    hex = hex(:)'; % Convert to a single row
end
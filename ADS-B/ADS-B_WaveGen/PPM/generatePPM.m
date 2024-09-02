function [ppm_signal, time_axis] = generatePPM(hex_input)
    % Convert hex input to binary string
    binary_message = hexToBinaryVector(hex_input);
    
    % ADS-B PPM encoding parameters
    bit_rate = 1000000; % 1 Mbps
    samples_per_second = 20000000; % 20 MHz sampling rate for smooth representation
    samples_per_bit = samples_per_second / bit_rate;
    pulse_width_samples = round(0.5 * samples_per_bit); % 0.5 μs pulse width
    
    % Initialize PPM signal
    ppm_signal = zeros(1, length(binary_message) * samples_per_bit);
    
    % Generate PPM signal
    for i = 1:length(binary_message)
        if binary_message(i) == 0
            start_index = round((i-1) * samples_per_bit) + 1;
        else
            start_index = round((i-1) * samples_per_bit + samples_per_bit/2) + 1;
        end
        end_index = min(start_index + pulse_width_samples - 1, length(ppm_signal));
        ppm_signal(start_index:end_index) = 1;
    end
    
    % Generate time axis
    time_axis = (0:length(ppm_signal)-1) / samples_per_second;
    
    % Plot the PPM waveform
    figure;
    plot(time_axis, ppm_signal);
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('PPM Waveform');
end

function binary = hexToBinaryVector(hex)
    % Remove any spaces and convert to uppercase
    hex = upper(strrep(hex, ' ', ''));
    
    % Convert hex to decimal
    dec = hex2dec(hex);
    
    % Convert decimal to binary
    binary = dec2bin(dec, 4 * length(hex)) - '0';
    
    % Reshape to a row vector
    binary = reshape(binary', 1, []);
end
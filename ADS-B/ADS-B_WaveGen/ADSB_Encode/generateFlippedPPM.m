function generateFlippedPPM(ADS_B_hex_final)
    % Convert the final ADS-B message to binary
    ADS_B_with_parity = hexToBinaryVector(ADS_B_hex_final, 112);

    % Generate PPM encoded signal for the original message
    [ppm_signal, time_axis] = generatePPM(ADS_B_with_parity);

    % Plot PPM encoded signal for the original message
    figure;
    plot(time_axis * 1e6, ppm_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('Original PPM Encoded ADS-B Message');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Flip the bits in the binary message
    flipped_message = '';
    for i = 1:length(ADS_B_with_parity)
        if ADS_B_with_parity(i) == '0'
            flipped_message = [flipped_message '1'];
        else
            flipped_message = [flipped_message '0'];
        end
    end

    % Generate PPM signal for the flipped message
    [flipped_ppm_signal, flipped_time_axis] = generatePPM(flipped_message);

    % Display the flipped binary message
    disp('Flipped ADS-B Message (Binary):');
    disp(flipped_message);

    % Convert flipped binary message to hexadecimal
    flipped_hex = binaryToHexManual(flipped_message);
    disp('Flipped ADS-B Message (Hexadecimal):');
    disp(flipped_hex);

    % Plot flipped PPM encoded signal
    figure;
    plot(flipped_time_axis * 1e6, flipped_ppm_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('Flipped PPM Encoded ADS-B Message');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Save flipped PPM signal to text file
    outputPath = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\ADSB_Encode\CSV\flipped_ppm_signal.txt';
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

function hex_str = binaryToHexManual(bin_str)
    hex_str = '';
    for i = 1:4:length(bin_str)
        nibble = bin_str(i:min(i+3, length(bin_str)));
        if length(nibble) < 4
            nibble = [nibble, repmat('0', 1, 4-length(nibble))];
        end
        dec_val = sum(2.^(3:-1:0) .* (nibble == '1'));
        if dec_val < 10
            hex_str = [hex_str, char(dec_val + '0')];
        else
            hex_str = [hex_str, char(dec_val - 10 + 'A')];
        end
        end
end

function bin_vector = hexToBinaryVector(hex_str, num_bits)
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
    bin_vector = bin_vector(1:num_bits);
end

function aircraftIDmessage(DF, CA, ICAO_hex, type_code, category, aircraft_id)
    % Generate ADS-B message for Aircraft Identification and Category, plot, and show PPM encoding
    
    % Convert DF and CA to binary
    DF_bin = dec2bin(DF, 5); % DF is 5 bits long
    CA_bin = dec2bin(CA, 3); % CA is 3 bits long

    % Concatenate DF and CA to form the first 8 bits of the ADS-B message
    ADS_B_message = [DF_bin CA_bin];

    % Convert ICAO address from hexadecimal to binary
    ICAO_bin = dec2bin(hex2dec(ICAO_hex), 24);

    % Convert Type Code and Category to binary
    type_code_bin = dec2bin(type_code, 5); % Type Code is 5 bits long
    category_bin = dec2bin(category, 3); % Category is 3 bits long

    % Convert Aircraft Identification characters to binary
    aircraft_id_bin = '';
    for i = 1:length(aircraft_id)
        aircraft_id_bin = [aircraft_id_bin charToBinary6bit(aircraft_id(i))];
    end

    % Concatenate Type Code, Category, and Aircraft Identification to form the payload
    payload_bin = [type_code_bin category_bin aircraft_id_bin];

    % Concatenate all parts to form the complete ADS-B message
    ADS_B_complete = [ADS_B_message ICAO_bin payload_bin];

    % Plot the complete ADS-B message bits
    figure;
    stem(0:length(ADS_B_complete)-1, ADS_B_complete - '0', 'filled');
    ylim([-0.5, 1.5]);
    grid on;  
    title('ADS-B Aircraft Identification and Category Message Bits');
    xlabel('Bit Position');
    ylabel('Bit Value');

    % Display the final ADS-B message in binary
    disp('Final ADS-B Aircraft Identification and Category Message (Binary):');
    disp(ADS_B_complete);

    % Convert binary string to hexadecimal manually
    ADS_B_hex_final = binaryToHexManual(ADS_B_complete);

    disp('Final ADS-B Aircraft Identification and Category Message (Hexadecimal):');
    disp(ADS_B_hex_final);

    % Generate PPM encoded signal
    [ppm_signal, time_axis] = generatePPM(ADS_B_complete);

    % Plot PPM encoded signal
    figure;
    plot(time_axis * 1e6, ppm_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('PPM Encoded ADS-B Message');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    
    % Save PPM signal to specified text file
    outputPath = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\ADSB_Encode\CSV\ppm_signal.txt';
    writematrix([time_axis', ppm_signal'], outputPath, 'Delimiter', 'tab');
    disp(['PPM signal saved to: ', outputPath]);
end

function char_bin = charToBinary6bit(char)
    if char >= 'A' && char <= 'Z'
        char_dec = double(char) - double('A') + 1; % A-Z: 1-26
    elseif char >= '0' && char <= '9'
        char_dec = double(char) - double('0') + 48; % 0-9: 48-57
    elseif char == ' '
        char_dec = 32; % space: 32
    else
        error('Invalid character for aircraft ID');
    end
    char_bin = dec2bin(char_dec, 6); % Convert decimal to 6-bit binary
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

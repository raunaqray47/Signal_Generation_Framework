% Generates an ADS-B message for aircraft identification and category.
% It constructs the message, calculates CRC parity bits, appends them, and generates a Pulse Position Modulation (PPM) encoded signal.
% The function displays the ADS-B message in hexadecimal format (with and without parity) and saves the PPM signal to a text file.
% Input:
% DF = 17;
% CA = 5;
% ICAO_hex = 'ABCDEF';
% type_code = 4;
% category = 1;
% aircraft_id = 'N12345';
% ADSB_aircraftID_category(DF, CA, ICAO_hex, type_code, category, aircraft_id);
% Output:
% ADS-B Message without Parity (Hexadecimal):
% 8D4840D6202CC371C32CE0
% Parity Bits (Hexadecimal):
% F1B562
% Final ADS-B Message with Parity (Hexadecimal):
% 8D4840D6202CC371C32CE0576098
% PPM signal saved to: C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\ADSB_Encode\CSV\ppm_signal.txt


function ADSB_aircraftID_category(DF, CA, ICAO_hex, type_code, category, aircraft_id)
    % Generate ADS-B message for Aircraft Identification and Category
    
    % Convert DF and CA to binary
    DF_bin = dec2bin(DF, 5);
    CA_bin = dec2bin(CA, 3);

    % Concatenate DF and CA to form the first 8 bits of the ADS-B message
    ADS_B_message = [DF_bin CA_bin];

    % Convert ICAO address from hexadecimal to binary
    ICAO_bin = dec2bin(hex2dec(ICAO_hex), 24);

    % Convert Type Code and Category to binary
    type_code_bin = dec2bin(type_code, 5); % Type Code is 5 bits long
    category_bin = dec2bin(category, 3); % Category is 3 bits long

    % Convert Aircraft Identification characters to binary
    aircraft_id_bin = '';
    % Pad the aircraft ID with spaces if it's less than 8 characters
    aircraft_id = pad(aircraft_id, 8, 'right', ' ');
    for i = 1:length(aircraft_id)
        aircraft_id_bin = [aircraft_id_bin charToBinary6bit(aircraft_id(i))];
    end

    % Concatenate Type Code, Category, and Aircraft Identification to form the payload
    payload_bin = [type_code_bin category_bin aircraft_id_bin];

    % Concatenate all parts to form the complete ADS-B message without parity
    ADS_B_complete = [ADS_B_message ICAO_bin payload_bin];

    % Convert the binary message to hexadecimal
    ADS_B_hex = binaryToHexManual(ADS_B_complete);

    % Calculate the CRC/parity bits
    [parity_bin, parity_hex] = ADSB_CRC(ADS_B_hex);

    % Append parity bits to the ADS-B message
    ADS_B_with_parity = [ADS_B_complete parity_bin];

    % Display the ADS-B message without parity
    %disp('ADS-B Message without Parity (Binary):');
    %disp(ADS_B_complete);
    disp('ADS-B Message without Parity (Hexadecimal):');
    disp(ADS_B_hex);

    % Display the parity bits
    %disp('Parity Bits (Binary):');
    %disp(parity_bin);
    disp('Parity Bits (Hexadecimal):');
    disp(parity_hex);

    % Display the final ADS-B message with parity
    %disp('Final ADS-B Message with Parity (Binary):');
    %disp(ADS_B_with_parity);

    % Convert the final message to hexadecimal
    ADS_B_hex_final = binaryToHexManual(ADS_B_with_parity);

    disp('Final ADS-B Message with Parity (Hexadecimal):');
    disp(ADS_B_hex_final);

    % Generate PPM encoded signal
    [ppm_signal, time_axis] = generatePPM(ADS_B_with_parity);

    % Plot PPM encoded signal
    figure;
    plot(time_axis * 1e6, ppm_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('PPM Encoded ADS-B Message');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    
    % Save PPM signal to text file
    outputPath = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\ADSB_Encode\CSV\ppm_signal.txt';
    writematrix([time_axis', ppm_signal'], outputPath, 'Delimiter', 'tab');
    disp(['PPM signal saved to: ', outputPath]);
end

function [remainder_bin, remainder_hex] = ADSB_CRC(data_hex)
    % Define the generator in binary format
    generator_bin = '1111111111111010000001001';
    
    % Convert the generator to a numeric array
    generator = double(generator_bin) - '0';
    
    % Convert the hex data to a binary string
    data_bin = hexToBinaryVector(data_hex, 88);
    
    % Append 24 zero bits to the data
    data_bin = [data_bin, zeros(1, 24)];
    
    % Perform the division using XOR
    for i = 1:(length(data_bin) - length(generator) + 1)
        if data_bin(i) == 1  % Only perform XOR if the current bit is 1
            data_bin(i:i+length(generator)-1) = xor(data_bin(i:i+length(generator)-1), generator);
        end
    end
    
    % The remainder is the last 24 bits of the modified data
    remainder = data_bin(end-(length(generator)-2):end);
    
    % Convert the binary remainder to a string
    remainder_bin = num2str(remainder);
    remainder_bin = strrep(remainder_bin, ' ', '');  % Remove spaces
    
    % Convert the binary remainder to a hexadecimal string
    remainder_hex = dec2hex(bin2dec(remainder_bin), 6);
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


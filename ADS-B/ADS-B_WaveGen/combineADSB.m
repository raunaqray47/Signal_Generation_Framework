function combineADSB(ADSB_Band1, ADSB_Band2)
    % Extract parts from first frame
    df_ca1 = ADSB_Band1(1:2);     % Downlink Format and Capability
    icao1 = ADSB_Band1(3:8);      % ICAO address
    message1 = ADSB_Band1(9:22);  % Message part
    parity1 = ADSB_Band1(23:28);  % Parity part
    
    % Extract parts from second frame
    df_ca2 = ADSB_Band2(1:2);     % Downlink Format and Capability
    icao2 = ADSB_Band2(3:8);      % ICAO address
    message2 = ADSB_Band2(9:22);  % Message part
    parity2 = ADSB_Band2(23:28);  % Parity part
    
    % Store original frame information for output
    ADSB_Band1_info = struct('full_frame', ADSB_Band1, 'df_ca', df_ca1, 'icao', icao1, 'message', message1, 'parity', parity1);
    ADSB_Band2_info = struct('full_frame', ADSB_Band2, 'df_ca', df_ca2, 'icao', icao2, 'message', message2, 'parity', parity2);
    
    % Verify that df_ca and ICAO are the same
    if ~strcmp(df_ca1, df_ca2) || ~strcmp(icao1, icao2)
        error('Error: The messages belong to different ICAOs or have different DF/CA values.');
    end
    
    % Add messages
    message = '';
    for i = 1:length(message1)
        val1 = hex2dec(message1(i));
        val2 = hex2dec(message2(i));
        sum_val = val1 + val2;
        if sum_val >= 16
            sum_val = sum_val - 16;  % Equivalent to modulo 16
        end
        message = [message, dec2hex(sum_val, 1)];
    end
    
    % Combine common df_ca, icao, and the message
    data_frame_without_parity = [df_ca1, icao1, message];
    
    % Calculate parity bits
    [~, parity] = ADSB_CRC(data_frame_without_parity);
    
    % Append parity bits to form the full ADS-B message
    ADSB_Result = [data_frame_without_parity, parity];
    
    % Display information about the frames
    disp(['ADSB_Band1: ', ADSB_Band1]);
    % disp(['  Full Frame: ', ADSB_Band1]);
    % disp(['  DF/CA: ', df_ca1]);
    % disp(['  ICAO: ', icao1]);
    % disp(['  Message: ', message1]);
    % disp(['  Parity: ', parity1]);
    % disp(' ');
    
    disp(['ADSB_Band2: ', ADSB_Band2]);
    % disp(['  Full Frame: ', ADSB_Band2]);
    % disp(['  DF/CA: ', df_ca2]);
    % disp(['  ICAO: ', icao2]);
    % disp(['  Message: ', message2]);
    % disp(['  Parity: ', parity2]);
    % disp(' ');
    
    disp(['ADSB_Result: ', ADSB_Result]);
    % disp(['  Full Frame: ', ADSB_Result]);
    % disp(['  DF/CA: ', df_ca1]);
    % disp(['  ICAO: ', icao1]);
    % disp(['  Message: ', message]);
    % disp(['  Parity: ', parity]);
end

function [remainder_bin, remainder_hex] = ADSB_CRC(data_hex)
    % Define the generator
    generator_bin = '1111111111111010000001001';
    generator = double(generator_bin) - '0';
    
    % Convert the hex data to a binary vector
    data_bin = hexToBinaryVector(data_hex, 88);
    
    % Append 24 zero bits to the data
    data_bin = [data_bin, zeros(1, 24)];
    
    % Perform the division using XOR
    for i = 1:(length(data_bin) - length(generator) + 1)
        if data_bin(i) == 1  % Only perform XOR if the current bit is 1
            data_bin(i:i+length(generator)-1) = xor(data_bin(i:i+length(generator)-1), generator);
        end
    end
    
    % Remainder is the last 24 bits of the modified data
    remainder = data_bin(end-(length(generator)-2):end);
    
    % Convert the binary remainder to a string
    remainder_bin = num2str(remainder);
    remainder_bin = strrep(remainder_bin, ' ', '');  % Remove spaces
    
    % Convert the binary remainder to a hexadecimal string
    remainder_hex = dec2hex(bin2dec(remainder_bin), 6);
end

function binary_vector = hexToBinaryVector(hex_string, num_bits)
    % Initialize output vector
    binary_vector = zeros(1, num_bits);
    
    for i = 1:length(hex_string)
        % Convert current hex character to decimal
        decimal = hex2dec(hex_string(i));
        % Convert to 4 binary bits
        for j = 0:3
            position = (i-1)*4 + (4-j);
            if position <= num_bits
                binary_vector(position) = bitget(decimal, j+1);
            end
        end
    end
end

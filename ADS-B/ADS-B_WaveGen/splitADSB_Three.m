function splitADSB_Three(hex_input)
    % Inputs:
    %   hex_input - A 28-character hexadecimal string representing an ADS-B frame
    %
    % Outputs:
    %   output_frame1 - First ADS-B frame with positions 1, 4, 7, 10, 13
    %   output_frame2 - Second ADS-B frame with positions 2, 5, 8, 11, 14
    %   output_frame3 - Third ADS-B frame with positions 3, 6, 9, 12
    
    % Ensure the input is 28 characters (112 bits) long
    if length(hex_input) ~= 28
        error('Input must be a 28-character hexadecimal string');
    end
    
    % Extract parts of the message
    df_ca = hex_input(1:2);      % Downlink Format and Capability
    icao = hex_input(3:8);       % ICAO address
    message = hex_input(9:22);   % Message
    parity = hex_input(23:28);   % Parity
    
    % Initialize the three separate messages
    message1 = '';
    message2 = '';
    message3 = '';
    
    % Split the message part based on position
    for i = 1:length(message)
        if mod(i, 3) == 1  %
            message1 = [message1, message(i)];
            message2 = [message2, '0'];
            message3 = [message3, '0'];
        elseif mod(i, 3) == 2
            message1 = [message1, '0'];
            message2 = [message2, message(i)];
            message3 = [message3, '0'];
        else
            message1 = [message1, '0'];
            message2 = [message2, '0'];
            message3 = [message3, message(i)];
        end
    end
    
    % Check if adding the three messages gives the original
    combined = '';
    for i = 1:length(message)
        val1 = hex2dec(message1(i));
        val2 = hex2dec(message2(i));
        val3 = hex2dec(message3(i));
        sum_val = val1 + val2 + val3;
        if sum_val >= 16
            sum_val = sum_val - 16;
        end      
        combined = [combined, dec2hex(sum_val, 1)];
    end
    if strcmpi(combined, message)
        disp('Verification: Message splitting is correct');
    else
        warning('Verification failed: Message splitting does not match the original');
        disp(['Original: ', upper(message)]);
        disp(['Combined: ', upper(combined)]);
        % Show where the mismatch occurs
        for i = 1:length(message)
            if ~strcmpi(combined(i), message(i))
                disp(['Mismatch at position ', num2str(i), ': Expected ', upper(message(i)), ', Got ', upper(combined(i))]);
            end
        end
    end
    
    % Assemble the final frames without parity
    frame1_without_parity = [df_ca, icao, message1];
    frame2_without_parity = [df_ca, icao, message2];
    frame3_without_parity = [df_ca, icao, message3];
    
    % Calculate CRC for each frame
    [~, remainder1_hex] = ADSB_CRC(frame1_without_parity);
    [~, remainder2_hex] = ADSB_CRC(frame2_without_parity);
    [~, remainder3_hex] = ADSB_CRC(frame3_without_parity);
    
    % Assemble the final frames with parity
    output_frame1 = [frame1_without_parity, remainder1_hex];
    output_frame2 = [frame2_without_parity, remainder2_hex];
    output_frame3 = [frame3_without_parity, remainder3_hex];
    
    % Display the results
    disp('Input ADS-B Frame:');
    disp(upper(hex_input));
    disp('Output ADS-B Frame 1:');
    disp(upper(output_frame1));
    disp('Output ADS-B Frame 2:');
    disp(upper(output_frame2));
    disp('Output ADS-B Frame 3:');
    disp(upper(output_frame3));
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

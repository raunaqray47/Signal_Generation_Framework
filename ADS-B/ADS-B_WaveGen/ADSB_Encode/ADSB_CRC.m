% Calculates the Cyclic Redundancy Check (CRC) for ADS-B messages. 
% It takes a hexadecimal input, converts it to binary, performs polynomial division using a specific generator polynomial, and outputs the 24-bit CRC in both binary and hexadecimal formats.
% Input:
% data_hex = '8D4840D6202CC371C32CE0576098';
% [remainder_bin, remainder_hex] = ADSB_CRC(data_hex);
% Output:
% Binary Remainder: 111110001101110101100010
% Hexadecimal Remainder: F1B562

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
    
    % Display the results
    fprintf('Binary Remainder: %s\n', remainder_bin);
    fprintf('Hexadecimal Remainder: %s\n', remainder_hex);
end

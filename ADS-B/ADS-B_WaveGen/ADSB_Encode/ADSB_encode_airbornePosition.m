% Encodes airborne position information into ADS-B messages.
% Generates two messages (ME0 and ME1) with Compact Position Reporting (CPR) encoding.
% Calculates CRC for each message and determines the most recent message based on timestamps.
%
% Inputs:
% latitude = 52.2572;
% longitude = 3.91937;
% altitude = 38000;
% t0 = 1457996402;
% t1 = 1457996400;
% typeCode = 19;
% surveillanceStatus = 0;
% singleAntennaFlag = 1;
% DF = 17;
% CA = 5;
% ICAO = '40621D';
% [message0, message1, mostRecent] = ADSB_encode_airbornePosition(latitude, longitude, altitude, t0, t1, typeCode, surveillanceStatus, singleAntennaFlag, DF, CA, ICAO)
%
% Outputs:
% message0: '8D40621D265862D690C8ACF9EA27'
% message1: '8D40621D26586241ECC8ACDF67B5'
% mostRecent: 'ME0 is the most recent message'
%
% The function returns two complete ADS-B messages in hexadecimal format (28 characters each)
% and indicates which message is the most recent based on the provided timestamps.
% Self_Note: Check altitude encoding.


function [message0, message1, mostRecent] = ADSB_encode_airbornePosition(latitude, longitude, altitude, t0, t1, typeCode, surveillanceStatus, singleAntennaFlag, DF, CA, ICAO)
    % Constants
    NZ = 15;
    
    % Calculate dlat values
    dlat0 = 360 / (4 * NZ);
    dlat1 = 360 / (4 * NZ - 1);
    
    % Calculate CPR latitudes
    lat_cpr0 = mod(latitude, dlat0) / dlat0;
    lat_cpr1 = mod(latitude, dlat1) / dlat1;
    
    % Calculate NL and dlon
    NL = calculateNL(latitude);
    if NL < 1
        NL = 1;
    end
    dlon = 360 / NL;
    
    % Calculate CPR longitudes
    lon_cpr0 = mod(longitude, dlon) / dlon;
    lon_cpr1 = mod(longitude, dlon) / dlon;
    
    % Encode altitude (assuming altitude is in feet)
    alt_enc = encodeAltitude(altitude);
    
    % Convert CPR to binary
    lat_cpr0_bin = dec2bin(round(lat_cpr0 * 2^17), 17);
    lon_cpr0_bin = dec2bin(round(lon_cpr0 * 2^17), 17);
    lat_cpr1_bin = dec2bin(round(lat_cpr1 * 2^17), 17);
    lon_cpr1_bin = dec2bin(round(lon_cpr1 * 2^17), 17);
    
    % Construct ME fields (56 bits each) with type code, surveillance status, and single antenna flag
    me0 = [dec2bin(typeCode, 5) dec2bin(surveillanceStatus, 2) dec2bin(singleAntennaFlag, 1) alt_enc lat_cpr0_bin lon_cpr0_bin];
    me1 = [dec2bin(typeCode, 5) dec2bin(surveillanceStatus, 2) dec2bin(singleAntennaFlag, 1) alt_enc lat_cpr1_bin lon_cpr1_bin];
    
    % Convert ME fields to hexadecimal
    me0_hex = bin2hex(me0);
    me1_hex = bin2hex(me1);
    
    % Combine DF and CA into a single byte and convert to hex
    DFCA_bin = [dec2bin(DF, 5) dec2bin(CA, 3)];
    DFCA_hex = dec2hex(bin2dec(DFCA_bin), 2); % Convert to 2-digit hex
    
    % Construct the full message with DF, CA, and ICAO
    message0 = [DFCA_hex ICAO me0_hex];
    message1 = [DFCA_hex ICAO me1_hex];
    
    % Append CRC to the messages
    [~, crc0_hex] = ADSB_CRC(message0);
    [~, crc1_hex] = ADSB_CRC(message1);
    
    message0 = [message0 crc0_hex];
    message1 = [message1 crc1_hex];
    
    % Determine the most recent message
    if t0 >= t1
        mostRecent = 'ME0 is the most recent message';
    else
        mostRecent = 'ME1 is the most recent message';
    end
end

function NL = calculateNL(lat)
    % Calculate the number of longitude zones
    if abs(lat) >= 87
        NL = 2;
    elseif lat == 0
        NL = 59;
    else
        NZ = 15;
        NL = floor(2*pi / (acos(1 - (1-cos(pi/(2*NZ))) / (cos(pi/180*abs(lat))^2))));
    end
end

function hex = bin2hex(bin)
    % Convert binary string to hexadecimal string using uint64 for large numbers
    decimalValue = uint64(bin2dec(bin)); % Convert to uint64 to avoid precision issues
    hex = dec2hex(decimalValue);
    % Ensure the output is 14 characters long (56 bits = 14 hex digits)
    hex = pad(hex, 14, 'left', '0');
end

function alt_enc = encodeAltitude(altitude_ft)
    % Encode altitude according to ADS-B format
    % This is a simplified version and might need adjustment
    altitude_ft = max(min(altitude_ft, 50175), -1000);  % Limit range
    N = floor((altitude_ft + 1000) / 25);
    alt_enc = dec2bin(N, 12);
end

function [remainder_bin, remainder_hex] = ADSB_CRC(data_hex)
    % Define the generator in binary format
    generator_bin = '1111111111111010000001001';
    
    % Convert the generator to a numeric array
    generator = double(generator_bin) - '0';
    
    % Convert the hex data to a binary string
    data_bin = hexToBinaryVector(data_hex, numel(data_hex) * 4);
    
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
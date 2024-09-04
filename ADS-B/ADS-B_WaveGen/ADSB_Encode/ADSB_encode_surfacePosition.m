% Encodes surface position information into an ADS-B message.   
% Generates the Message (ME) field for surface position reports using Compact Position Reporting (CPR) encoding.
%
% Inputs:
% typeCode = 7; 			% Type code for surface position
% groundTrackStatus = 1; 	% Ground track status (1 for valid, 0 for invalid)
% movementSpeed = 17; 	% Speed in knots
% trackAngle = 92.8125; 	% Track angle in degrees
% latitude = 4.73473; 	% Latitude in degrees (example: Seattle, WA)
% longitude = 4.375; 		% Longitude in degrees (example: Seattle, WA)
% refLat = 51.990; 		% Reference latitude (example: Seattle, WA)
% refLon = -122.3331; 	% Reference longitude (example: Seattle, WA)
% t0 = 1457996410; 		% Unix timestamp for even frame
% t1 = 1457996412; 		% Unix timestamp for odd frame (1 second later)
% DF = 17; 				% Downlink Format
% CA = 4; 				% Capability
% ICAO = '484175'; 		% ICAO address (hexadecimal)
% [msg0, msg1, mostRecent, breakdown0, breakdown1] = ADSB_encode_surfacePosition(typeCode, groundTrackStatus, movementSpeed, trackAngle, latitude, longitude, refLat, refLon, t0, t1, DF, CA, ICAO, timeFlag)
%
% Output:
% msg0: 8C48417538DA13858A126CABE85A
% msg1: 8C48417538DA15323E11E81C4BB2
% msg1 is the most recent message
% mostRecent =
%     'msg1 is the most recent message'
%
% Note: The actual output may vary slightly due to rounding in floating-point calculations.
% Self_note: This function encodes only the ME field. Yet to create a complete ADS-B message. 
% Prepend the Downlink Format (DF), Capability (CA), and ICAO address, and append the CRC to this ME field.
% Verification Pending


function [msg0, msg1, mostRecent] = ADSB_encode_surfacePosition(typeCode, groundTrackStatus, movementSpeed, trackAngle, latitude, longitude, refLat, refLon, t0, t1, DF, CA, ICAO, varargin)
    % Set default value for timeFlag if not provided
    if nargin < 14
        timeFlag = 0; % Default time flag is 0
    else
        timeFlag = varargin{1}; % Use provided time flag
    end

    % Constants
    NZ = 15; % Number of zones

    % Calculate dLat for even and odd frames
    dLatEven = 90 / (4 * NZ);
    dLatOdd = 90 / (4 * NZ - 1);
    
    % Calculate CPR latitudes
    latCPREven = mod(latitude, dLatEven) / dLatEven;
    latCPROdd = mod(latitude, dLatOdd) / dLatOdd;
    
    % Calculate NL based on reference latitude
    NL = calculateNL(refLat);
    dLonEven = 360 / max(NL, 1);
    dLonOdd = 360 / max(NL - 1, 1);
    
    % Calculate CPR longitudes using reference longitude
    lonCPREven = mod(longitude - refLon, dLonEven) / dLonEven;
    lonCPROdd = mod(longitude - refLon, dLonOdd) / dLonOdd;
    
    % Encode movement speed
    movEnc = encodeMovementSpeed(movementSpeed);
    
    % Encode track angle
    trackEnc = encodeTrackAngle(trackAngle);
    
    % Convert CPR to binary
    latCPREvenBin = dec2bin(round(latCPREven * 2^17), 17);
    lonCPREvenBin = dec2bin(round(lonCPREven * 2^17), 17);
    latCPROddBin = dec2bin(round(latCPROdd * 2^17), 17);
    lonCPROddBin = dec2bin(round(lonCPROdd * 2^17), 17);
    
    % Construct ME fields (56 bits each) with F flag for even and odd
    meEven = [dec2bin(typeCode, 5) movEnc num2str(groundTrackStatus) trackEnc num2str(timeFlag) '0' latCPREvenBin lonCPREvenBin];
    meOdd = [dec2bin(typeCode, 5) movEnc num2str(groundTrackStatus) trackEnc num2str(timeFlag) '1' latCPROddBin lonCPROddBin];
    
    % Convert ME fields to hexadecimal
    meEvenHex = bin2hex(meEven);
    meOddHex = bin2hex(meOdd);
    
    % Combine DF and CA into a single byte and convert to hex
    DFCA_bin = [dec2bin(DF, 5) dec2bin(CA, 3)];
    DFCA_hex = dec2hex(bin2dec(DFCA_bin), 2);
    
    % Construct the full message with DF, CA, and ICAO
    msg0 = [DFCA_hex ICAO meEvenHex];
    msg1 = [DFCA_hex ICAO meOddHex];
    
    % Append CRC to the messages
    [~, crcEvenHex] = ADSB_CRC(msg0);
    [~, crcOddHex] = ADSB_CRC(msg1);
    
    msg0 = [msg0 crcEvenHex];
    msg1 = [msg1 crcOddHex];
    
    % Determine the most recent message
    if t0 >= t1
        mostRecent = 'msg0 is the most recent message';
    else
        mostRecent = 'msg1 is the most recent message';
    end
    
    % % Break down the messages into binary and segregate type code
    % breakdown0 = breakdownMessage(msg0);
    % breakdown1 = breakdownMessage(msg1);
end

% function breakdown = breakdownMessage(msg)
%     % Convert the entire message to binary
%     msgBin = hexToBinaryVector(msg, length(msg) * 4);
%     
%     % Extract different parts of the message
%     DF = msgBin(1:5);
%     CA = msgBin(6:8);
%     ICAO = msgBin(9:32);
%     ME = msgBin(33:88);
%     CRC = msgBin(89:end);
%     
%     % Extract type code from ME field
%     typeCode = ME(1:5);
%     
%     % Create a structure with the breakdown
%     breakdown = struct('FullBinary', strjoin(cellstr(char(msgBin + '0')), ''), ...
%                        'DF', strjoin(cellstr(char(DF + '0')), ''), ...
%                        'CA', strjoin(cellstr(char(CA + '0')), ''), ...
%                        'ICAO', strjoin(cellstr(char(ICAO + '0')), ''), ...
%                        'ME', strjoin(cellstr(char(ME + '0')), ''), ...
%                        'TypeCode', strjoin(cellstr(char(typeCode + '0')), ''), ...
%                        'CRC', strjoin(cellstr(char(CRC + '0')), ''));
% end

function NL = calculateNL(lat)
    % Calculate the number of longitude zones
    if abs(lat) >= 87
        NL = 1;
    elseif lat == 0
        NL = 59;
    else
        NZ = 15;
        NL = floor(2 * pi / (acos(1 - (1 - cos(pi / (2 * NZ))) / (cos(pi / 180 * abs(lat))^2))));
    end
end

function movEnc = encodeMovementSpeed(movementSpeed)
    % Encode movement speed according to ADS-B format
    if movementSpeed < 0.125
        movEnc = dec2bin(1, 7);
    elseif movementSpeed < 1
        movEnc = dec2bin(2, 7);
    elseif movementSpeed < 7
        movEnc = dec2bin(3 + floor(movementSpeed - 1), 7);
    elseif movementSpeed < 15
        movEnc = dec2bin(9 + floor((movementSpeed - 7) / 2), 7);
    elseif movementSpeed < 70
        movEnc = dec2bin(13 + floor((movementSpeed - 15) / 5), 7);
    elseif movementSpeed < 130
        movEnc = dec2bin(39 + floor(movementSpeed - 70), 7);
    elseif movementSpeed < 180
        movEnc = dec2bin(94 + floor((movementSpeed - 130) / 2), 7);
    elseif movementSpeed < 310
        movEnc = dec2bin(109 + floor((movementSpeed - 180) / 5), 7);
    else
        movEnc = dec2bin(124, 7);
    end
end

function trackEnc = encodeTrackAngle(trackAngle)
    % Encode track angle according to ADS-B format
    trackEnc = dec2bin(round(trackAngle * 128 / 360), 7);
end

function hex = bin2hex(bin)
    % Convert binary string to hexadecimal string using uint64 for large numbers
    decimalValue = uint64(bin2dec(bin)); % Convert to uint64 to avoid precision issues
    hex = dec2hex(decimalValue);
    % Ensure the output is 14 characters long (56 bits = 14 hex digits)
    hex = pad(hex, 14, 'left', '0');
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
function decodedData = ADSB_decode_surfacePosition(msg0, msg1, t0, t1, refLat, refLon)
    % Convert hex messages to binary strings
    msg0_bin = hexToBinaryVector(msg0, length(msg0) * 4);
    msg1_bin = hexToBinaryVector(msg1, length(msg1) * 4);
    
    % Convert binary vectors to character vectors
    msg0_bin_str = char(msg0_bin + '0');
    msg1_bin_str = char(msg1_bin + '0');
    
    % Extract ME fields
    ME0 = msg0_bin_str(33:88);
    ME1 = msg1_bin_str(33:88);
    
    % Extract type code
    typeCode0 = bin2dec(ME0(1:5));
    typeCode1 = bin2dec(ME1(1:5));
    
    % Extract ground track status
    groundTrackStatus0 = bin2dec(ME0(12));
    groundTrackStatus1 = bin2dec(ME1(12));
    
    % Extract movement speed
    movementSpeed0 = decodeMovementSpeed(ME0(6:12));
    movementSpeed1 = decodeMovementSpeed(ME1(6:12));
    
    % Extract track angle
    trackAngle0 = decodeTrackAngle(ME0(13:19));
    trackAngle1 = decodeTrackAngle(ME1(13:19));
    
    % Extract CPR latitude and longitude
    latCPREven = bin2dec(ME0(21:37)) / 2^17;
    lonCPREven = bin2dec(ME0(38:54)) / 2^17;
    latCPROdd = bin2dec(ME1(21:37)) / 2^17;
    lonCPROdd = bin2dec(ME1(38:54)) / 2^17;
    
    % Decode latitude and longitude using CPR decoding
    [latitude, longitude] = decodeCPR(latCPREven, lonCPREven, latCPROdd, lonCPROdd, refLat, refLon, t0, t1);
    
    % Prepare decoded data
    decodedData = struct('TypeCode', [typeCode0, typeCode1], ...
                         'GroundTrackStatus', [groundTrackStatus0, groundTrackStatus1], ...
                         'MovementSpeed', [movementSpeed0, movementSpeed1], ...
                         'TrackAngle', [trackAngle0, trackAngle1], ...
                         'Latitude', latitude, ...
                         'Longitude', longitude);
end

function speed = decodeMovementSpeed(movEnc)
    % Decode movement speed from ADS-B format
    % Add your decoding logic here
    speed = movEnc; % Placeholder
end

function angle = decodeTrackAngle(trackEnc)
    % Decode track angle from ADS-B format
    angle = (bin2dec(trackEnc) * 360) / 128;
end

function [latitude, longitude] = decodeCPR(latCPREven, lonCPREven, latCPROdd, lonCPROdd, refLat, refLon, t0, t1)
    % Decode latitude and longitude using CPR decoding
    % Add your CPR decoding logic here
    latitude = refLat; % Placeholder
    longitude = refLon; % Placeholder
end

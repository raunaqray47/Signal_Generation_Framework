function [decodedSpeed, decodedTrackAngle, decodedLat, decodedLon] = ADSB_decode_surfacePosition(msg, refLat, refLon)
    % Extract ME field from the message
    ME = msg(9:22); % ME field is 56 bits (14 hex characters)
    ME_bin = hexToBinaryVector(ME, 56);
    
    % Decode Type Code
    typeCode = bin2dec(ME_bin(1:5));
    if typeCode < 5 || typeCode > 8
        error('Invalid type code for surface position message.');
    end
    
    % Decode Movement Speed
    movEnc = bin2dec(ME_bin(6:12));
    decodedSpeed = decodeMovementSpeed(movEnc);
    
    % Decode Track Angle
    trackEnc = bin2dec(ME_bin(14:20));
    decodedTrackAngle = trackEnc * 360 / 128;
    
    % Decode Latitude and Longitude
    F = bin2dec(ME_bin(21)); % F flag (0 for even, 1 for odd)
    latCPR = bin2dec(ME_bin(23:39)) / 2^17;
    lonCPR = bin2dec(ME_bin(40:56)) / 2^17;
    
    % Decode position using CPR and reference position
    [decodedLat, decodedLon] = decodeCPR(latCPR, lonCPR, refLat, refLon, F);
end

function speed = decodeMovementSpeed(movEnc)
    % Decode movement speed from encoded value
    if movEnc == 0
        speed = 0;
    elseif movEnc == 1
        speed = 0.0625; % < 0.125 knots
    elseif movEnc == 2
        speed = 0.5; % 0.125-1 knots
    elseif movEnc <= 8
        speed = movEnc - 1; % 1-7 knots
    elseif movEnc <= 12
        speed = 7 + 2 * (movEnc - 9); % 7-15 knots
    elseif movEnc <= 38
        speed = 15 + 5 * (movEnc - 13); % 15-70 knots
    elseif movEnc <= 93
        speed = 70 + (movEnc - 39); % 70-130 knots
    elseif movEnc <= 108
        speed = 130 + 2 * (movEnc - 94); % 130-180 knots
    elseif movEnc <= 123
        speed = 180 + 5 * (movEnc - 109); % 180-310 knots
    else
        speed = 310; % > 310 knots
    end
end

function [lat, lon] = decodeCPR(latCPR, lonCPR, refLat, refLon, isOdd)
    NZ = 15;
    
    % Compute latitude zone size
    if isOdd
        dLat = 90 / (4 * NZ - 1);
    else
        dLat = 90 / (4 * NZ);
    end
    
    % Compute latitude
    j = floor(refLat / dLat) + floor(0.5 + ((mod(refLat, dLat)) / dLat - latCPR));
    lat = dLat * (j + latCPR);
    
    % Compute number of longitude zones
    NL = calculateNL(lat);
    
    % Compute longitude zone size
    if isOdd
        dLon = 360 / max(NL - 1, 1);
    else
        dLon = 360 / max(NL, 1);
    end
    
    % Compute longitude
    m = floor(refLon / dLon) + floor(0.5 + ((mod(refLon, dLon)) / dLon - lonCPR));
    lon = dLon * (m + lonCPR);
    
    % Adjust for hemisphere
    if lat > 90
        lat = lat - 180;
    elseif lat < -90
        lat = lat + 180;
    end
    
    if lon > 180
        lon = lon - 360;
    elseif lon < -180
        lon = lon + 360;
    end
end

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

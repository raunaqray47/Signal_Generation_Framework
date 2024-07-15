function [msg_even, msg_odd] = ADSB_encodeCPR(DF, CA, ICAO_hex, lat, lon, altitude_ft)
    % ADSB_encodeCPR: Encode position into ADS-B messages
    % Input:
    %   DF: Downlink Format (17 for ADS-B)
    %   CA: Capability (0-7)
    %   ICAO_hex: ICAO 24-bit address (as hexadecimal string)
    %   lat: Latitude in degrees (-90 to 90)
    %   lon: Longitude in degrees (-180 to 180)
    %   altitude_ft: Altitude in feet
    % Output:
    %   msg_even, msg_odd: Complete ADS-B messages (112 bits each) as uint8 arrays

    % Constants
    NZ = 15; % Number of latitude zones
    TYPE_CODE = 11; % Airborne position

    % Encode altitude
    altitude_encoded = encodeAltitude(altitude_ft);

    % Limit latitude range
    lat = max(min(lat, 90), -90);
    
    % Compute latitude index
    YZ = floor(2^17 * mod(lat, 360) / 360 + 0.5);
    
    % Compute NL(lat) - number of longitude zones
    NL = NL_function(lat);
    
    % Compute longitude index
    XZ = floor(2^17 * mod(lon, 360) / 360 + 0.5);
    
    % Encode latitude and longitude
    lat_cpr_even = mod(YZ, 2^17);
    lat_cpr_odd = mod(YZ - floor(YZ/(2*NZ)) + floor((mod(YZ,2*NZ))/NZ), 2^17);
    
    if NL > 1
        lon_cpr_even = mod(XZ, 2^17);
        lon_cpr_odd = mod(XZ - floor(XZ/(2*NL-1)) + floor((mod(XZ,2*NL-1))/(NL-1)), 2^17);
    else
        lon_cpr_even = 0;
        lon_cpr_odd = 0;
    end

    % Compose messages
    msg_even = composeMessage(DF, CA, ICAO_hex, TYPE_CODE, 0, altitude_encoded, lat_cpr_even, lon_cpr_even);
    msg_odd = composeMessage(DF, CA, ICAO_hex, TYPE_CODE, 1, altitude_encoded, lat_cpr_odd, lon_cpr_odd);
end

function NL = NL_function(lat)
    % Calculate the number of longitude zones
    if abs(lat) >= 87
        NL = 1;
    elseif abs(lat) >= 85
        NL = 2;
    elseif abs(lat) >= 80
        NL = 3;
    elseif abs(lat) >= 75
        NL = 4;
    elseif abs(lat) >= 70
        NL = 5;
    else
        NL = floor(2*pi / acos(1 - (1-cos(pi/(2*15))) / cos(lat*pi/180)^2));
    end
end

function alt_encoded = encodeAltitude(altitude_ft)
    % Encode altitude (assuming feet, Q-bit set to 1)
    N = floor((altitude_ft + 1000) / 25);
    alt_encoded = bitset(uint16(N), 12, 1); % Set Q-bit to 1
end

function msg = composeMessage(DF, CA, ICAO_hex, TC, CPR_format, altitude, lat_cpr, lon_cpr)
    % Compose 112-bit ADS-B message
    msg = zeros(1, 14, 'uint8');
    
    % DF (5 bits) and CA (3 bits)
    msg(1) = bitor(bitshift(DF, 3), CA);
    
    % ICAO address (24 bits)
    icao = hex2dec(ICAO_hex);
    msg(2) = bitand(bitshift(icao, -16), 255);
    msg(3) = bitand(bitshift(icao, -8), 255);
    msg(4) = bitand(icao, 255);
    
    % Type Code (5 bits) and Surveillance Status (2 bits, set to 0)
    msg(5) = bitshift(TC, 3);
    
    % CPR format (1 bit) and altitude (12 bits)
    msg(6) = bitor(bitshift(CPR_format, 7), bitand(bitshift(altitude, -4), 127));
    msg(7) = bitor(bitshift(bitand(altitude, 15), 4), bitand(bitshift(lat_cpr, -13), 15));
    
    % Latitude CPR (17 bits)
    msg(8) = bitand(bitshift(lat_cpr, -5), 255);
    msg(9) = bitor(bitshift(bitand(lat_cpr, 31), 3), bitand(bitshift(lon_cpr, -14), 7));
    
    % Longitude CPR (17 bits)
    msg(10) = bitand(bitshift(lon_cpr, -6), 255);
    msg(11) = bitand(bitshift(lon_cpr, 2), 255);
    msg(12) = bitand(bitshift(lon_cpr, -6), 252);
    
    % Remaining bits set to 0
end

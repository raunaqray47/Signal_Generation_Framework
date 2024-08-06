function [me0_hex, me1_hex] = ADSB_encodeADSBPosition(latitude, longitude, altitude, t0, t1)
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
    
    % Construct ME fields (56 bits each)
    me0 = [alt_enc lat_cpr0_bin lon_cpr0_bin];
    me1 = [alt_enc lat_cpr1_bin lon_cpr1_bin];
    
    % Convert ME fields to hexadecimal
    me0_hex = bin2hex(me0);
    me1_hex = bin2hex(me1);
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
    % Convert binary string to hexadecimal string
    hex = dec2hex(bin2dec(bin));
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

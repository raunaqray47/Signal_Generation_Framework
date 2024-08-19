function [me_hex] = ADSB_encode_surfacePosition(latitude, longitude, speed, track, t)
    % Constants
    NZ = 15;
    
    % Calculate dlat values
    dlat = 360 / (4 * NZ);
    
    % Calculate CPR latitude
    lat_cpr = mod(latitude, dlat) / dlat;
    
    % Calculate NL and dlon
    NL = calculateNL(latitude);
    if NL < 1
        NL = 1;
    end
    dlon = 360 / NL;
    
    % Calculate CPR longitude
    lon_cpr = mod(longitude, dlon) / dlon;
    
    % Encode speed (movement)
    movement = encodeSpeed(speed);
    
    % Encode track angle
    ground_track = round(mod(track, 360) / 2.8125);
    
    % Convert CPR to binary
    lat_cpr_bin = dec2bin(round(lat_cpr * 2^17), 17);
    lon_cpr_bin = dec2bin(round(lon_cpr * 2^17), 17);
    
    % Construct ME field (56 bits)
    % Assuming Type Code for surface position is 5
    type_code = dec2bin(5, 5);
    ground_track_status = '1';  % Assuming valid ground track
    time_bit = dec2bin(t, 1);  % Time bit
    
    me = [type_code dec2bin(movement, 7) ground_track_status dec2bin(ground_track, 7) time_bit '0' lat_cpr_bin lon_cpr_bin];
    
    % Convert ME field to hexadecimal
    me_hex = bin2hex(me);
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

function movement = encodeSpeed(speed)
    % Encode speed (movement) according to ADS-B format
    if speed <= 0.22
        movement = 1;
    elseif speed <= 1.12
        movement = floor((speed - 0.22) / 0.125) + 2;
    elseif speed <= 22.82
        movement = floor((speed - 1.12) / 0.145) + 9;
    else
        movement = 124;
    end
end

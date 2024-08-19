% To decode position
%msg0 = '8D40621D 265862D690C8AC 2863A7';
%msg1 = '8D40621D 26586241ECC8AC 692AD6';
%t0 = 1457996402;
%t1 = 1457996400;
%ADSB_decode_airbornePosition(msg0, msg1, t0, t1)

function [latitude, longitude, altitude] = ADSB_decode_airbornePosition(msg0, msg1, t0, t1)
    % Input validation
    if ~ischar(msg0) || ~ischar(msg1) || length(msg0) ~= 28 || length(msg1) ~= 28
        error('Invalid message format');
    end
    
    % Extract ME field (bits 33-88)
    me0 = hex2bin(msg0(9:22));
    me1 = hex2bin(msg1(9:22));

    % Extract altitude
    alt0 = decodeAltitude(me0(1:12));
    alt1 = decodeAltitude(me1(1:12));

    % Extract CPR latitude and longitude
    lat_cpr0 = bin2dec(me0(23:39)) / 131072;  % 2^17
    lon_cpr0 = bin2dec(me0(40:56)) / 131072;  % 2^17
    lat_cpr1 = bin2dec(me1(23:39)) / 131072;  % 2^17
    lon_cpr1 = bin2dec(me1(40:56)) / 131072;  % 2^17

    % Compute the latitude index
    j = floor(59 * lat_cpr0 - 60 * lat_cpr1 + 0.5);

    % Compute latitudes
    NZ = 15;
    dlat0 = 360 / (4 * NZ);
    dlat1 = 360 / (4 * NZ - 1);
    lat0 = dlat0 * (mod(j, 60) + lat_cpr0);
    lat1 = dlat1 * (mod(j, 59) + lat_cpr1);

    % Adjust for southern hemisphere
    if lat0 >= 270, lat0 = lat0 - 360; end
    if lat1 >= 270, lat1 = lat1 - 360; end

    % Calculate NL for both latitudes
    NL_lat0 = calculateNL(lat0);
    NL_lat1 = calculateNL(lat1);

    if NL_lat0 ~= NL_lat1
        % Cannot decode, return NaN
        longitude = NaN;
        latitude = NaN;
        altitude = NaN;
    else
        % Choose most recent latitude and altitude
        if t0 >= t1
            lat = lat0;
            alt = alt0;
        else
            lat = lat1;
            alt = alt1;
        end

        % Compute longitude index
        ni = max(NL_lat0, 1);
        m = floor(lon_cpr0 * (ni-1) - lon_cpr1 * ni + 0.5);

        % Compute longitude
        dlon = 360 / ni;
        lon0 = dlon * (mod(m, ni) + lon_cpr0);
        lon1 = dlon * (mod(m, ni) + lon_cpr1);

        % Adjust longitude to [-180, 180] range
        if lon0 >= 180, lon0 = lon0 - 360; end
        if lon1 >= 180, lon1 = lon1 - 360; end

        % Choose most recent longitude
        if t0 >= t1
            longitude = lon0;
            latitude = lat0;
        else
            longitude = lon1;
            latitude = lat1;
        end
    end

    % Return the most recent altitude
    altitude = alt;
end

function altitude = decodeAltitude(alt_bin)
    % Decode altitude from binary
    N = bin2dec(alt_bin);
    altitude = N * 25 - 1000; % Convert to feet
end

function binary = hex2bin(hex)
    % Convert hexadecimal string to binary string
    binary = '';
    for i = 1:length(hex)
        decimal = hex2dec(hex(i));
        binary = [binary dec2bin(decimal, 4)];
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

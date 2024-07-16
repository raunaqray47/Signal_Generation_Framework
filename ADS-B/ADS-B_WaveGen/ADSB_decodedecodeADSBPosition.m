function altitude = decodeADSBAltitude(msg)
    % Input validation
    if ~ischar(msg) || length(msg) ~= 28
        error('Invalid message format');
    end
    
    % Extract ME field (bits 33-88)
    me = hex2bin(msg(9:22));
    
    % Extract altitude bits (41-52)
    altBits = me(9:20);
    
    % Convert binary string to decimal
    altCode = bin2dec(altBits);
    
    % Decode altitude according to ADS-B protocol
    % This is a simplified version and may need adjustment based on specific ADS-B format
    altitude = (altCode * 25) - 1000;
end

function [latitude, longitude] = decodeADSBPosition(msg0, msg1, t0, t1)
    % Input validation
    if ~ischar(msg0) || ~ischar(msg1) || length(msg0) ~= 28 || length(msg1) ~= 28
        error('Invalid message format');
    end
    
    % Extract ME field (bits 33-88)
    me0 = hex2bin(msg0(9:22));
    me1 = hex2bin(msg1(9:22));

    % Extract CPR latitude and longitude
    lat_cpr0 = bin2dec(me0(23:39)) / 2^17;
    lon_cpr0 = bin2dec(me0(40:56)) / 2^17;
    lat_cpr1 = bin2dec(me1(23:39)) / 2^17;
    lon_cpr1 = bin2dec(me1(40:56)) / 2^17;

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

    % Choose most recent latitude
    if t0 >= t1
        lat = lat0;
    else
        lat = lat1;
    end

    % Compute NL(lat) - Number of longitude zones
    NL = floor(2*pi / (acos(1 - (1-cos(pi/(2*NZ))) / (cos(pi/180*abs(lat))^2))));

    if NL(lat0) ~= NL(lat1)
        % Cannot decode, return NaN
        longitude = NaN;
        latitude = NaN;
    else
        % Compute longitude index
        ni = max(NL, 1);
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
end

function binary = hex2bin(hex)
    % Convert hexadecimal string to binary string
    binary = '';
    for i = 1:length(hex)
        decimal = hex2dec(hex(i));
        binary = [binary dec2bin(decimal, 4)];
    end
end

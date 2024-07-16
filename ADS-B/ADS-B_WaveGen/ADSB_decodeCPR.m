function [lat, lon, alt] = ADSB_decodeCPR(message, ref_lat, ref_lon)
    % Decode ADS-B airborne position message
    % Inputs:
    %   message: 14-character hex string (56-bit ME field)
    %   ref_lat: Reference latitude in degrees
    %   ref_lon: Reference longitude in degrees
    % Outputs:
    %   lat: Decoded latitude in degrees
    %   lon: Decoded longitude in degrees
    %   alt: Decoded altitude in feet

    % Constants
    NZ = 15;

    % Convert hex to binary
    bin = hexToBinaryVector(message, 56);

    % Extract fields
    tc = bin2dec(char(bin(1:5) + '0'));
    alt_bits = [bin(9:20) bin(22)];
    lat_cpr = bin2dec(char(bin(23:39) + '0')) / 2^17;
    lon_cpr = bin2dec(char(bin(40:56) + '0')) / 2^17;
    odd = bin(22);

    % Decode altitude
    alt = decodeAltitude(alt_bits);

    % Decode latitude
    dlat = 360 / (4 * NZ - odd);
    j = floor(ref_lat / dlat) + ...
        floor(0.5 + mod(ref_lat, dlat) / dlat - lat_cpr);
    lat = dlat * (j + lat_cpr);

    % Decode longitude
    nl = NL(lat);
    if odd
        ni = max(nl - 1, 1);
    else
        ni = max(nl, 1);
    end
    dlon = 360 / ni;
    m = floor(ref_lon / dlon) + ...
        floor(0.5 + mod(ref_lon, dlon) / dlon - lon_cpr);
    lon = dlon * (m + lon_cpr);

    % Adjust latitude and longitude to correct range
    if lat > 90
        lat = lat - 360;
    end
    if lon > 180
        lon = lon - 360;
    end
end

function alt = decodeAltitude(alt_bits)
    % Decode altitude
    if alt_bits(end) == 1  % Q-bit set
        n = bin2dec(char(alt_bits(1:11) + '0'));
        alt = 25 * n - 1000;
    else
        % Gillham code decoding (not implemented here)
        alt = NaN;
    end
end

function nl = NL(lat)
    % Calculate the number of longitude zones
    if abs(lat) >= 87
        nl = 1;
    elseif abs(lat) >= 85
        nl = 2;
    elseif abs(lat) >= 80
        nl = 3;
    elseif abs(lat) >= 75
        nl = 4;
    elseif abs(lat) >= 70
        nl = 5;
    else
        nz = 15;
        nl = floor(2*pi / acos(1 - (1-cos(pi/(2*nz))) / (cos(pi/180 * lat)^2)));
    end
end

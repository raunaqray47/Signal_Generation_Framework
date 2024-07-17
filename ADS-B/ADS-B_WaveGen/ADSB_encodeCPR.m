function [me0, me1] = encodeADSBPosition(latitude, longitude)
    % Constants
    NZ = 15;

    % Calculate CPR latitude and longitude
    lat_cpr0 = mod(latitude, dlat0) / dlat0;
    lat_cpr1 = mod(latitude, dlat1) / dlat1;
    
    NL = calculateNL(latitude);
    if NL < 1
        NL = 1;
    end
    dlon = 360 / NL;
    
    lon_cpr0 = mod(longitude, dlon) / dlon;
    lon_cpr1 = mod(longitude, dlon) / dlon;

    % Convert to binary
    lat_cpr0_bin = dec2bin(round(lat_cpr0 * 2^17), 17);
    lon_cpr0_bin = dec2bin(round(lon_cpr0 * 2^17), 17);
    lat_cpr1_bin = dec2bin(round(lat_cpr1 * 2^17), 17);
    lon_cpr1_bin = dec2bin(round(lon_cpr1 * 2^17), 17);

    % Construct ME fields (56 bits each)
    me0 = ['00011' lat_cpr0_bin lon_cpr0_bin];
    me1 = ['00011' lat_cpr1_bin lon_cpr1_bin];

    % Helper functions
    function NL = calculateNL(lat)
        if abs(lat) >= 87
            NL = 2;
        elseif lat == 0
            NL = 59;
        else
            NL = floor(2*pi / (acos(1 - (1-cos(pi/(2*NZ))) / (cos(pi/180*abs(lat))^2))));
        end
    end

    function dlat = dlat0()
        dlat = 360 / (4 * NZ);
    end

    function dlat = dlat1()
        dlat = 360 / (4 * NZ - 1);
    end
end

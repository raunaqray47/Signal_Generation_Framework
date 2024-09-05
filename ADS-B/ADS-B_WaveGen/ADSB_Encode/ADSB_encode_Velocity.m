function [adsb_bin, adsb_hex, adsb_crc, Vew, Vns, HDG, AS, VR, dAlt] = ADSB_encode_Velocity(DF, CA, ICAO_hex, TypeCode, IntentChangeFlag, IFRCapabilityFlag, NUC, ReservedBits, speed, track_angle, Sew, Sns, subtype, SH, T, VrSrc, S_Vr, VS, sign_bit, dAlt)
    % Validate inputs
    if DF < 0 || DF > 31
        error('DF must be between 0 and 31.');
    end
    if CA < 0 || CA > 7
        error('CA must be between 0 and 7.');
    end

    % Validate ICAO_hex input
    if ~ischar(ICAO_hex) || isempty(regexp(ICAO_hex, '^[0-9A-Fa-f]{1,6}$', 'once'))
        error('ICAO must be a valid hexadecimal string of up to 6 characters (0-9, A-F).');
    end
    
    % Convert ICAO from hexadecimal to decimal
    ICAO = hex2dec(ICAO_hex);
    
    if ICAO < 0 || ICAO > 16777215
        error('ICAO must be between 0 and FFFFFF.');
    end
    
    if TypeCode ~= 19  % Type Code for airborne velocity messages
        error('TypeCode must be 19 for airborne velocity messages.');
    end
    if IntentChangeFlag < 0 || IntentChangeFlag > 1
        error('Intent Change Flag must be either 0 or 1.');
    end
    if IFRCapabilityFlag < 0 || IFRCapabilityFlag > 1
        error('IFR Capability Flag must be either 0 or 1.');
    end
    if NUC < 0 || NUC > 7
        error('NUC must be between 0 and 7.');
    end
    if ReservedBits < 0 || ReservedBits > 3
        error('ReservedBits must be between 0 and 3.');
    end

    % Convert inputs to binary strings
    DF_bin = dec2bin(DF, 5);
    CA_bin = dec2bin(CA, 3);
    ICAO_bin = dec2bin(ICAO, 24);
    TypeCode_bin = dec2bin(TypeCode, 3);
    IntentChangeFlag_bin = num2str(IntentChangeFlag);
    IFRCapabilityFlag_bin = num2str(IFRCapabilityFlag);
    NUC_bin = dec2bin(NUC, 3);
    ReservedBits_bin = dec2bin(ReservedBits, 2);

    % Encode airborne velocity
    [Vew_bin, Vns_bin, HDG_bin, AS_bin, VR_bin, dAlt_bin] = ADSB_encode_airborneVelocity(speed, track_angle, Sew, Sns, subtype, SH, T, VrSrc, S_Vr, VS, sign_bit, dAlt);

    % Combine all parts into a single binary string
    adsb_bin = [DF_bin CA_bin ICAO_bin TypeCode_bin IntentChangeFlag_bin IFRCapabilityFlag_bin NUC_bin ReservedBits_bin ...
                 Vew_bin Vns_bin HDG_bin AS_bin VR_bin dAlt_bin];

    % Calculate CRC/parity bits
    [adsb_crc_bin, adsb_crc] = ADSB_CRC(adsb_bin);

    % Append parity bits to the ADS-B message
    adsb_bin_with_crc = [adsb_bin adsb_crc_bin];

    % Convert binary string to hexadecimal
    adsb_hex = '';
    for i = 1:4:length(adsb_bin_with_crc)
        adsb_hex = [adsb_hex, dec2hex(bin2dec(adsb_bin_with_crc(i:min(i+3, length(adsb_bin_with_crc)))), 1)];
    end

    % Decompose the ME field
    Vew = bin2dec(Vew_bin);
    Vns = bin2dec(Vns_bin);
    HDG = bin2dec(HDG_bin);
    AS = bin2dec(AS_bin);
    VR = bin2dec(VR_bin);
    dAlt = decode_dAlt(dAlt_bin);
end

function [Vew_bin, Vns_bin, HDG_bin, AS_bin, VR_bin, dAlt_bin] = ADSB_encode_airborneVelocity(speed, track_angle, Sew, Sns, subtype, SH, T, VrSrc, S_Vr, VS, sign_bit, dAlt)
    % Convert track angle from degrees to radians
    lambda = deg2rad(track_angle);
    
    % Initialize binary strings
    Vew_bin = '';
    Vns_bin = '';
    HDG_bin = '';
    AS_bin = '';
    VR_bin = '';  % Initialize VR_bin
    dAlt_bin = ''; % Initialize dAlt_bin

    % Adjust for sign bits and subtype
    if subtype == 1  % Sub-type 1
        % Calculate East-West and North-South velocity components
        if Sew == 0
            Vew = speed * sin(lambda) - 1;  % From West to East
        else
            Vew = -1 * (speed * sin(lambda) - 1); % From East to West
        end

        if Sns == 0
            Vns = speed * cos(lambda) - 1;  % From South to North
        else
            Vns = -1 * (speed * cos(lambda) - 1); % From North to South
        end

        % Convert Vew and Vns to binary
        Vew_bin = dec2bin(round(Vew), 10);
        Vns_bin = dec2bin(round(Vns), 10);
        
    elseif subtype == 2  % Sub-type 2
        % Calculate East-West and North-South velocity components
        if Sew == 0
            Vew = 4 * (speed * sin(lambda) - 1);  % From West to East
        else
            Vew = -4 * (speed * sin(lambda) - 1); % From East to West
        end

        if Sns == 0
            Vns = 4 * (speed * cos(lambda) - 1);  % From South to North
        else
            Vns = -4 * (speed * cos(lambda) - 1); % From North to South
        end

        % Convert Vew and Vns to binary
        Vew_bin = dec2bin(round(Vew), 10);
        Vns_bin = dec2bin(round(Vns), 10);
        
    elseif subtype == 3 || subtype == 4  % Sub-type 3 or 4
        % Calculate airspeed based on the input airspeed type (T)
        if T == 0  % Indicated airspeed (IAS)
            AS_value = speed - 1;  % Subtract 1 for IAS
        elseif T == 1  % True airspeed (TAS)
            AS_value = 4 * (speed - 1);  % Multiply by 4 for TAS
        end
        
        % Convert airspeed to binary
        AS_bin = dec2bin(AS_value + 1, 10); % Add 1 before converting to binary
        
        % Calculate magnetic heading if SH is available
        if SH == 1
            % Convert magnetic heading to binary
            HDG_value = round(track_angle * (1024 / 360)); % Scale to 10-bit
            HDG_bin = dec2bin(HDG_value, 10); % Convert to binary
        end
    else
        error('Invalid sub-type. Please enter 1, 2, 3, or 4.');
    end

    % Encode vertical rate regardless of subtype
    VR_bin = encode_vertical_rate(VrSrc, S_Vr, VS);
    
    % Encode altitude difference
    dAlt_bin = encode_dAlt(sign_bit, dAlt);
end

function VR_bin = encode_vertical_rate(VrSrc, S_Vr, VS)
    % Initialize VR binary string
    VR_bin = '';
    
    % Calculate VR based on vertical rate direction
    if S_Vr == 0  % Climb
        VR = round(VS / 64 + 1);
    else  % Descent
        VR = round(-VS / 64 + 1);
    end
    
    % Ensure VR is within valid range (1 to 511)
    VR = max(1, min(511, VR));
    
    % Convert VR to binary
    VR_bin = dec2bin(VR, 9);
end

function dAlt_bin = encode_dAlt(sign_bit, dAlt)
    % Calculate magnitude based on altitude difference
    if sign_bit == 0
        magnitude = min(dAlt / 25, 127);  % GNSS above barometric altitude
    else
        magnitude = min(abs(dAlt) / 25, 127);  % GNSS below barometric altitude
    end
    
    % Add 1 to the magnitude
    magnitude = magnitude + 1;
    
    % Combine sign bit and magnitude
    dAlt_value = sign_bit * 128 + magnitude;  % The first bit is the sign bit
    
    % Convert to binary (8 bits)
    dAlt_bin = dec2bin(dAlt_value, 8);
end

function dAlt = decode_dAlt(dAlt_bin)
    % Extract the sign bit
    sign_bit = str2double(dAlt_bin(1));
    
    % Extract the magnitude
    magnitude = bin2dec(dAlt_bin(2:end));
    
    % Calculate the altitude difference
    if sign_bit == 0
        dAlt = (magnitude - 1) * 25;  % GNSS above barometric altitude
    else
        dAlt = -1 * (magnitude - 1) * 25;  % GNSS below barometric altitude
    end
end

function [remainder_bin, remainder_hex] = ADSB_CRC(data_bin)
    % Define the generator in binary format
    generator_bin = '1111111111111010000001001';  % Example generator polynomial
    generator = double(generator_bin) - '0';  % Convert to numeric array

    % Append 24 zero bits to the data
    data_bin = [data_bin zeros(1, 24)];
    
    % Perform the division using XOR
    for i = 1:(length(data_bin) - length(generator) + 1)
        if data_bin(i) == 1  % Only perform XOR if the current bit is 1
            data_bin(i:i+length(generator)-1) = xor(data_bin(i:i+length(generator)-1), generator);
        end
    end
    
    % The remainder is the last bits of the modified data
    remainder = data_bin(end-(length(generator)-2):end);
    
    % Convert the binary remainder to a string
    remainder_bin = num2str(remainder);
    remainder_bin = strrep(remainder_bin, ' ', '');  % Remove spaces
    
    % Convert the binary remainder to a hexadecimal string
    remainder_hex = dec2hex(bin2dec(remainder_bin), 6);
end
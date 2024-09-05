function [Vew_bin, Vns_bin, HDG_bin, AS_bin, VR_bin] = ADSB_encode_airborneVelocity(speed, track_angle, Sew, Sns, subtype, SH, T, VrSrc, S_Vr, VS)
    % Convert track angle from degrees to radians
    lambda = deg2rad(track_angle);
    
    % Initialize binary strings
    Vew_bin = '';
    Vns_bin = '';
    HDG_bin = '';
    AS_bin = '';
    VR_bin = '';  % Initialize VR_bin

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
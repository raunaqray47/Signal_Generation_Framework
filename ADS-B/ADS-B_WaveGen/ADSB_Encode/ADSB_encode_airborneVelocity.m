function [msg, mostRecent] = ADSB_encode_airborneVelocity(DF, CA, ICAO, typeCode, subType, intentChangeFlag, IFRFlag, NUC, VrSrc, Svr, verticalRate, SDiff, altitudeDifference, Dew, eastWestVelocity, Dns, northSouthVelocity)
    % Constants
    reservedBit = 0;  % Reserved bit always set to 0

    % Validate inputs
    if typeCode ~= 19
        error('Type code must be 19 for airborne velocity messages.');
    end

    % Encode vertical rate
    if verticalRate == 0
        verticalRateEnc = dec2bin(0, 12);  % No information
    else
        if verticalRate > 0
            Svr = 0;  % Up
        else
            Svr = 1;  % Down
        end
        verticalRateEnc = dec2bin(abs(verticalRate), 12);  % Encode the absolute value
    end

    % Encode GNSS and Barometric altitude difference
    if altitudeDifference == 0
        SDiff = 0;  % No information
    else
        SDiff = (altitudeDifference > 0);  % Set SDiff based on altitude difference
    end
    altitudeDifferenceEnc = dec2bin(abs(altitudeDifference), 12);  % Encode the absolute value

    % Function to encode velocity according to ADS-B format based on subtype
    function velocityEnc = encodeVelocity(velocity, subtype)
        % Encode velocity according to ADS-B format based on subtype
        if subtype == 1 || subtype == 2 % Subtypes for ground speed
            if velocity < 0
                velocity = 0;  % No negative velocities
            end
            velocityEnc = dec2bin(min(velocity, 127), 7);  % Limit to 7 bits
        elseif subtype == 3 || subtype == 4 % Subtypes for airspeed
            if velocity < 0
                velocity = 0;  % No negative velocities
            end
            if subtype == 3 % Subtype for indicated airspeed (IAS)
                velocityEnc = dec2bin(min(velocity, 127), 7);  % Limit to 7 bits
            elseif subtype == 4 % Subtype for true airspeed (TAS)
                velocityEnc = dec2bin(min(velocity * 4, 255), 8);  % Limit to 8 bits with multiplication factor of 4
            end
        else
            error('Unsupported subtype for velocity encoding.');
        end
    end

    % Encode east-west velocity based on subtype
    if eastWestVelocity == 0
        eastWestVelocityEnc = dec2bin(0, 7);  % No information
        eastWestDirection = 0;  % Direction for East-West velocity
    else
        eastWestVelocityEnc = encodeVelocity(eastWestVelocity, subType);
        eastWestDirection = Dew;  % Direction for East-West velocity
    end

    % Encode north-south velocity based on subtype
    if northSouthVelocity == 0
        northSouthVelocityEnc = dec2bin(0, 7);  % No information
        northSouthDirection = 0;  % Direction for North-South velocity
    else
        northSouthVelocityEnc = encodeVelocity(northSouthVelocity, subType);
        northSouthDirection = Dns;  % Direction for North-South velocity
    end

    % Construct the message fields including Capability (CA)
    msgFields = [
        dec2bin(DF, 5), ...          % Downlink Format
        dec2bin(CA, 3), ...           % Capability Area
        dec2bin(ICAO_to_dec(ICAO), 24), ...  % ICAO address
        dec2bin(typeCode, 5), ...    % Type Code
        dec2bin(subType, 3), ...      % Sub-type
        dec2bin(intentChangeFlag, 1), ...  % Intent Change Flag
        dec2bin(IFRFlag, 1), ...      % IFR Capability Flag
        NUC, ...                       % NUC (000 always)
        dec2bin(VrSrc, 1), ...        % Source bit for vertical rate
        dec2bin(Svr, 1), ...          % Sign bit for vertical rate
        verticalRateEnc,              % Vertical Rate
        dec2bin(reservedBit, 1), ...  % Reserved bit
        dec2bin(SDiff, 1), ...        % Sign bit for GNSS/Baro altitude difference
        altitudeDifferenceEnc,        % Altitude Difference
        dec2bin(eastWestDirection, 1), ... % Direction East-West
        eastWestVelocityEnc,          % East-West Velocity
        dec2bin(northSouthDirection, 1), ... % Direction North-South
        northSouthVelocityEnc          % North-South Velocity
    ];

    % Concatenate all fields to form the complete ADS-B message
    completeMsg = strjoin(msgFields, '');

    % Calculate CRC
    [remainder_bin, remainder_hex] = ADSB_CRC(completeMsg);
    msg = [completeMsg remainder_bin];  % Append CRC to the message

    % Convert to hexadecimal
    msg_hex = binaryToHexManual(msg);

    % Display the final ADS-B message in binary format
    disp('Final ADS-B Message in Binary:');
    disp(msg);

    % Display the final ADS-B message with parity in hexadecimal format
    disp('Final ADS-B Message with Parity (Hexadecimal):');
    disp(msg_hex);

    % Decompose ME field
    MEfield= msg(33:end);
    
    TC= MEfield(1:5); % Type Code
    ST= MEfield(6:end); % Sub-type
    
     IC= MEfield(9); % Intent Change Flag
    
     IFR= MEfield(10); % IFR Capability Flag
    
     NUCfield= MEfield(11:end); % NUC
    
     VrSrcfield= MEfield(14); % Source bit for vertical rate
    
     Svrfield= MEfield(15); % Sign bit for vertical rate
    
     VRreservedfield= MEfield(16:end-1); % Vertical Rate and Reserved bits combined
    
     SDifffield= MEfield(end); % Sign bit for GNSS/Baro altitude difference
    
     ADdirectionfield= MEfield(end-7:end-5); % Altitude Difference combined with Directions
    
     DEWfield= MEfield(end-6:end-5); % Direction East-West
    
     EWVfield= MEfield(end-4:end-1); % East-West Velocity
    
     DNSfield= MEfield(end-4:end); % Direction North-South
    
      NSVfield=MEfield(end);

      disp('Decomposed ME Field:');
      disp(['Type Code (TC): ', TC]);
      disp(['Sub-type (ST): ', ST]);
      disp(['Intent Change Flag (IC): ', IC]);
      disp(['IFR Capability Flag (IFR): ', IFR]);
      disp(['NUC: ', NUCfield]);
      disp(['Source bit for vertical rate (VrSrc): ', VrSrcfield]);
      disp(['Sign bit for vertical rate (Svr): ', Svrfield]);
      disp(['Vertical Rate and Reserved bits combined (VR): ', VRreservedfield]);
      disp(['Reserved bit (Reserved): ', '0']); % Assuming Always Zero for Simplicity
      
      disp(['Sign bit for GNSS/Baro altitude difference (SDiff): ', SDifffield]);
      disp(['Altitude Difference combined with Directions (AD): ', ADdirectionfield]);
      disp(['Direction East-West (DEW): ', DEWfield]);
      disp(['East-West Velocity (EWV): ', EWVfield]);
      disp(['Direction North-South (DNS): ', DNSfield]);
      disp(['North-South Velocity (NSV): ', NSVfield]);

      % Determine most recent message 
      mostRecent='This is the latest message';
end

% Function to convert ICAO hexadecimal to decimal 
function ICAO_dec= ICAO_to_dec(ICAO_hex)
    % Convert ICAO hexadecimal to decimal 
    ICAO_dec= hex2dec(ICAO_hex);
end

% Function to convert binary string to hexadecimal string manually 
function hex_str= binaryToHexManual(bin_str)
    hex_str='';
    for i=1:4:length(bin_str)
        nibble= bin_str(i:min(i+3,length(bin_str)));
        if length(nibble)<4 
            nibble=[nibble repmat('0',1,4-length(nibble))];
        end 
        dec_val=sum(2.^(-3:-1).* (nibble=='1'));
        if dec_val<10 
            hex_str=[hex_str char(dec_val+'0')];
        else 
            hex_str=[hex_str char(dec_val-10+'A')];
        end 
    end 
end

% Function to calculate CRC for ADS-B messages 
function [remainder_bin , remainder_hex]= ADSB_CRC(data_bin)
     % Define generator in binary format 
     generator_bin='1111111111111010000001001';
     
     % Convert generator to numeric array 
     generator=double(generator_bin)-'0';
     
     % Append zero bits to data 
     data_bin=[data_bin ,zeros(1 ,24)];
     
     % Perform division using XOR 
     for i=1:(length(data_bin)-length(generator)+1)
         if data_bin(i)==1 % Only perform XOR if current bit is one 
             data_bin(i:i+length(generator)-1)=xor(data_bin(i:i+length(generator)-1),generator);
         end 
     end 
    
     % The remainder is last twenty-four bits of modified data 
     remainder=data_bin(end-(length(generator)-2):end);
     
     % Convert binary remainder to string 
     remainder_bin=num2str(remainder);
     remainder_bin=strrep(remainder_bin,' ',''); % Remove spaces
     
     % Convert binary remainder to hexadecimal string 
     remainder_hex=dec2hex(bin2dec(remainder_bin),6);
end
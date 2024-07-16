function altitude = ADSB_decodeADSBAltitude(msg)
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

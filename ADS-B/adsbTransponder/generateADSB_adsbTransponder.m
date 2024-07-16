% Generate ADS-B message
icaoAddress = 'ABC123';
transponder = adsbTransponder(icaoAddress);
transponder.Category = adsbCategory(12);
transponder.Callsign = 'TEST1234';

gps = gpsSensor('PositionInputFormat', 'Geodetic', 'HorizontalPositionAccuracy', 100);
transponder.GPS = gps;

position = [42.753, 31.896, 10000];
velocity = [250, 0, 0];

adsbMessage = transponder(position, velocity);

% Convert message to binary
binMessage = adsbMessageToBinary(adsbMessage);

% Convert binary message to hexadecimal
hexMessage = binaryToHex(binMessage);

% Display the hexadecimal ADS-B message
disp('Hexadecimal ADS-B Message:');
disp(hexMessage);

% PPM encoding
ppmSignal = [];
for bit = binMessage
    if bit == 0
        ppmSignal = [ppmSignal 1 0 0 0];
    else
        ppmSignal = [ppmSignal 1 1 0 0];
    end
end

% Upsample and shape the signal
samplesPerChip = 2;
upsampledSignal = upsample(ppmSignal, samplesPerChip);
pulseDuration = 0.5e-6;
sampleRate = 2e6;
pulseShape = ones(1, round(pulseDuration * sampleRate));
shapedSignal = conv(upsampledSignal, pulseShape, 'same');

% Normalize signal
normalizedSignal = shapedSignal / max(abs(shapedSignal));

% Display the normalized signal
figure;
plot(normalizedSignal);
title('Normalized ADS-B Signal');
xlabel('Sample');
ylabel('Amplitude');
ylim([-0.1 1.1]);  % Set y-axis limits for better visibility
grid on;

% Display message details
disp('ADS-B Message Details:');
disp(['ICAO: ' adsbMessage.ICAO]);
disp(['Callsign: ' adsbMessage.Callsign]);
disp(['Latitude: ' num2str(adsbMessage.Latitude)]);
disp(['Longitude: ' num2str(adsbMessage.Longitude)]);
disp(['Altitude: ' num2str(adsbMessage.Altitude)]);

% Helper function to convert ADS-B message to binary
function binMessage = adsbMessageToBinary(adsbMessage)
    % Initialize binary message
    binMessage = [];
    
    % Convert ICAO address (24 bits)
    icaoBin = dec2bin(hex2dec(adsbMessage.ICAO), 24) - '0';
    binMessage = [binMessage icaoBin];
    
    % Convert Category (4 bits)
    catBin = dec2bin(adsbMessage.Category, 4) - '0';
    binMessage = [binMessage catBin];
    
    % Convert Callsign (56 bits)
    callsignBin = [];
    for i = 1:8
        if i <= length(adsbMessage.Callsign)
            charBin = dec2bin(uint8(adsbMessage.Callsign(i)), 7) - '0';
        else
            charBin = zeros(1, 7);
        end
        callsignBin = [callsignBin charBin];
    end
    binMessage = [binMessage callsignBin];
    
    % Convert Latitude (17 bits)
    latBin = dec2bin(round(adsbMessage.Latitude * 1e7), 17) - '0';
    binMessage = [binMessage latBin];
    
    % Convert Longitude (17 bits)
    lonBin = dec2bin(round(adsbMessage.Longitude * 1e7), 17) - '0';
    binMessage = [binMessage lonBin];
    
    % Convert Altitude (12 bits)
    altBin = dec2bin(round(adsbMessage.Altitude), 12) - '0';
    binMessage = [binMessage altBin];
end

% Helper function to convert binary to hexadecimal
function hexMessage = binaryToHex(binMessage)
    binStr = num2str(binMessage);
    binStr = binStr(~isspace(binStr));  % Remove spaces
    hexMessage = '';
    for i = 1:4:length(binStr)
        hexDigit = binStr(i:i+3);
        hexMessage = [hexMessage dec2hex(bin2dec(hexDigit))];
    end
end

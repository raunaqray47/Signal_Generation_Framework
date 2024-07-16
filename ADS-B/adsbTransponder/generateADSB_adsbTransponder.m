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
binMessage = de2bi(hex2dec(adsbMessage.Payload), 112, 'left-msb');

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

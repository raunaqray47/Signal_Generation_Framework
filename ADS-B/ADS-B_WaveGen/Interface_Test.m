% Generate waveform
t = linspace(0, 1, 16384);
waveform = sin(2*pi*10*t);

% Convert to string
waveformStr = sprintf('%.6f,', waveform);
waveformStr = waveformStr(1:end-1);

% Send waveform data
writeline(visaObj, "SOURCE1:TRACe:DATA:DAC16 VOLATILE," + waveformStr);

% Set as arbitrary waveform
writeline(visaObj, "SOURCE1:FUNC:ARB VOLATILE");

% Enable output
writeline(visaObj, "OUTPUT1 ON");

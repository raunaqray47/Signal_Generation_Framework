function [ppm_signal, time_axis] = generatePPM(hex_input)
    % Convert hex input to binary
    binary_message = hexToBinaryVector(hex_input);
    % ADS-B PPM encoding parameters
    bit_rate = 1000000; % 1 Mbps
    samples_per_second = 20000000; % 20 MHz
    samples_per_bit = samples_per_second / bit_rate;
    pulse_width_samples = round(0.5 * samples_per_bit); % 0.5μs pulse width
    
    % Initialize PPM signal
    ppm_signal = zeros(1, length(binary_message) * samples_per_bit);
    
    % Generate PPM signal
    for i = 1:length(binary_message)
        start_index = round((i-1) * samples_per_bit) + 1;
        mid_index = start_index + pulse_width_samples;
        end_index = start_index + samples_per_bit - 1;
        
        if binary_message(i) == 1
            % 1: 0.5μs pulse followed by 0.5μs flat signal
            ppm_signal(start_index:mid_index-1) = 1;
        else
            % 0: 0.5μs flat signal followed by 0.5μs pulse
            ppm_signal(mid_index:end_index) = 1;
        end
    end
    
    % Generate time axis
    time_axis = (0:length(ppm_signal)-1) / samples_per_second;
    
    % Plot the PPM waveform
    figure;
    plot(time_axis * 1e6, ppm_signal); % Convert to microseconds for display
    ylim([-0.5, 1.5]);
    grid on;
    title('PPM Encoded ADS-B Message');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    
    % Display hex input and its binary representation
    disp('Hex Input:');
    disp(hex_input);
    disp('Binary Representation:');
    disp(num2str(binary_message));
    
    % Save PPM signal to text file
    outputPath = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\ppm_signal.txt';
    writematrix([time_axis', ppm_signal'], outputPath, 'Delimiter', 'tab');
    disp(['PPM signal saved to: ', outputPath]);
end

function binary = hexToBinaryVector(hex)
    % Remove any spaces and convert to uppercase
    hex = upper(strrep(hex, ' ', ''));
    
    % Initialize binary vector
    binary = zeros(1, length(hex) * 4);
    
    % Define a mapping from hex characters to 4-bit binary
    hex_to_bin = containers.Map({'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}, ...
                                {'0000','0001','0010','0011','0100','0101','0110','0111', ...
                                 '1000','1001','1010','1011','1100','1101','1110','1111'});
    
    % Convert each hex character to its 4-bit binary representation
    for i = 1:length(hex)
        binary_chunk = hex_to_bin(hex(i));
        binary((i-1)*4+1 : i*4) = str2num(binary_chunk(:))';
    end
end
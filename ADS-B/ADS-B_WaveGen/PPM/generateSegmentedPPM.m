function generateSegmentedPPM(hex_input)
    % Convert hex input to binary
    binary_message = hexToBinaryVector(hex_input);
    
    % Define segments
    segments = {
        'Type Code', 1:5;
        'Movement', 6:12;
        'Ground Track Status', 13;
        'Ground Track', 14:20;
        'Time', 21;
        'CPR Format', 22;
        'CPR-Latitude', 23:39;
        'CPR-Longitude', 40:56
    };
    
    % Generate PPM for each segment
    for i = 1:size(segments, 1)
        segment_name = segments{i, 1};
        segment_bits = segments{i, 2};
        segment_data = binary_message(segment_bits);
        
        [ppm_signal, time_axis] = encodePPM(segment_data);
        
        % Plot the PPM waveform for this segment
        figure;
        plot(time_axis * 1e6, ppm_signal);
        ylim([-0.5, 1.5]);
        grid on;
        title(['PPM Encoded ', segment_name]);
        xlabel('Time (μs)');
        ylabel('Amplitude');
        
        % Save Ground Track waveform to text file
        if strcmp(segment_name, 'Ground Track')
            outputPath = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV\ground_track_ppm_signal.txt';
            writematrix([time_axis', ppm_signal'], outputPath, 'Delimiter', 'tab');
            disp(['Ground Track PPM signal saved to: ', outputPath]);
        end
    end
    
    % Display hex input and its binary representation
    disp('Hex Input:');
    disp(hex_input);
    disp('Binary Representation:');
    disp(num2str(binary_message));
end

function [ppm_signal, time_axis] = encodePPM(binary_data)
    % ADS-B PPM encoding parameters
    bit_rate = 1000000; % 1 Mbps
    samples_per_second = 20000000; % 20 MHz sampling rate for smooth representation
    samples_per_bit = samples_per_second / bit_rate;
    pulse_width_samples = round(0.5 * samples_per_bit); % 0.5 μs pulse width
    
    % Initialize PPM signal
    ppm_signal = zeros(1, length(binary_data) * samples_per_bit);
    
    % Generate PPM signal
    for i = 1:length(binary_data)
        start_index = round((i-1) * samples_per_bit) + 1;
        mid_index = start_index + pulse_width_samples;
        end_index = start_index + samples_per_bit - 1;
        
        if binary_data(i) == 1
            % 1 bit: 0.5 μs pulse followed by 0.5 μs flat signal
            ppm_signal(start_index:mid_index-1) = 1;
        else
            % 0 bit: 0.5 μs flat signal followed by 0.5 μs pulse
            ppm_signal(mid_index:end_index) = 1;
        end
    end
    
    % Generate time axis
    time_axis = (0:length(ppm_signal)-1) / samples_per_second;
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

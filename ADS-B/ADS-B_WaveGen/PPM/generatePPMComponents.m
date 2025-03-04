function generatePPMComponents(hex_input)
    %Save file location
    output_dir = 'C:\Users\rauna\OneDrive - UW\Study\Project\Summer_Internship\ADS-B\ADS-B_WaveGen\PPM\CSV';

    % Parameters
    bit_rate = 1e6;         % 1 Mbps
    sampling_rate = 20e6;   % 20 MHz
    samples_per_bit = sampling_rate / bit_rate;
    pulse_width_samples = round(0.5 * samples_per_bit); % 0.5 μs pulse width
    amplitude = 1;          % Voltage amplitude (+/-1V)

    % Convert hex input to binary
    binary_message = hexToBinaryVector(hex_input);

    % Generate I+ component
    [i_plus_signal, time_axis] = generateAlternatingPPM(binary_message, bit_rate, samples_per_bit, pulse_width_samples, amplitude);

    % Generate I- component
    i_minus_signal = -i_plus_signal;

    % Plot I+ component
    figure;
    stairs(time_axis * 1e6, i_plus_signal, 'b');
    ylim([-1.5, 1.5]);
    grid on;
    title('I+ Component');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Plot I- component
    figure;
    stairs(time_axis * 1e6, i_minus_signal, 'r');
    ylim([-1.5, 1.5]);
    grid on;
    title('I- Component');
    xlabel('Time (μs)');
    ylabel('Amplitude');

    % Plot combined I+ and I- components
    figure;
    stairs(time_axis * 1e6, i_plus_signal, 'b', 'DisplayName', 'I+ Component');
    hold on;
    stairs(time_axis * 1e6, i_minus_signal, 'r', 'DisplayName', 'I- Component');
    ylim([-1.5, 1.5]);
    grid on;
    title('I+ and I- Components');
    xlabel('Time (μs)');
    ylabel('Amplitude');
    legend show;

    % Save I+ component
    i_plus_file = fullfile(output_dir, 'i_plus_component.txt');
    writematrix([time_axis', i_plus_signal'], i_plus_file, 'Delimiter', 'tab');
    
    % Save I- component
    i_minus_file = fullfile(output_dir, 'i_minus_component.txt');
    writematrix([time_axis', i_minus_signal'], i_minus_file, 'Delimiter', 'tab');
    
    disp(['I+ component saved to: ', i_plus_file]);
    disp(['I- component saved to: ', i_minus_file]);
end

function [ppm_signal, time_axis] = generateAlternatingPPM(binary_message, bit_rate, samples_per_bit, pulse_width_samples, amplitude)
    % Initialize PPM signal
    ppm_signal = zeros(1, length(binary_message) * samples_per_bit);
    
    flip_sign = 1; % Start with positive amplitude

    for i = 1:length(binary_message)
        start_index = round((i-1) * samples_per_bit) + 1;
        mid_index = start_index + pulse_width_samples - 1;
        end_index = start_index + samples_per_bit - 1;

        if binary_message(i) == '1'
            ppm_signal(start_index:mid_index) = flip_sign * amplitude; % Pulse in first half for '1'
        else
            ppm_signal(mid_index+1:end_index) = flip_sign * amplitude; % Pulse in second half for '0'
        end

        flip_sign = -flip_sign; % Alternate the sign for the next bit
    end

    % Generate time axis
    time_axis = (0:length(ppm_signal)-1) / (bit_rate * samples_per_bit);
end

function binary_vector = hexToBinaryVector(hex_str)
    binary_vector = '';
    
    for i = 1:length(hex_str)
        nibble = hex_str(i);
        if nibble >= '0' && nibble <= '9'
            bin_nibble = dec2bin(str2double(nibble), 4);
        else
            bin_nibble = dec2bin(double(nibble) - double('A') + 10, 4);
        end
        
        binary_vector = [binary_vector, bin_nibble];
    end
end

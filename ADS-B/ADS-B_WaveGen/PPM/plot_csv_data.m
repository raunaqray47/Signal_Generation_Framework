function plot_csv_data(filename)
    data = readtable(filename);

    time = data.TIME  * 1e6;
    amplitude = data.CH1 * 1e3;

    figure;
    plot(time, amplitude);
    xlabel('Time (\mus)');
    ylabel('Amplitude (mV)');
    title('Time vs Amplitude');
    grid on;
end


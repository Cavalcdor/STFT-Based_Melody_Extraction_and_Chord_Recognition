function [multi_pitch, confidences] = melody_extraction(audio, fs, params, output_dir)
% 多基频提取模块
% 输入:
%   audio         - 输入音频信号
%   fs            - 采样率
%   params        - 参数结构体，包含:
%                   .window_length   - 窗长
%                   .hop_length      - 跳长
%                   .window          - 窗函数
%                   .windowed_frames - 加窗后的帧数据(用于可视化)
%   output_dir    - 可视化结果输出目录
% 输出:
%   multi_pitch   - 多基频矩阵(帧数×4，每行最多4个频率值)
%   confidences   - 对应基频的置信度矩阵(帧数×4) 
    window_length = params.window_length;
    hop_length = params.hop_length;
    window = params.window;

    % 计算STFT
    [S, F, T] = spectrogram(audio, window, hop_length, window_length, fs, 'yaxis');
    S = abs(S);  % 幅度谱
    F = F(1:window_length/2+1);  % 频率向量
    T = T';  % 时间向量

    % 计算每帧能量
    frame_energy = sum(S.^2, 1)';  % 每帧能量
    [~, max_energy_idx] = max(frame_energy);  % 找到能量最大的帧索引

    % 初始化结果矩阵
    num_frames = size(S, 2);
    multi_pitch = zeros(num_frames, 4);     % 每帧最多4个基频
    confidences = zeros(num_frames, 4);     % 对应置信度

    % 对每一帧提取前4个峰值频率
    for i = 1:num_frames
        frame_spectrum = S(:, i);
        
        % 查找局部最大值
        [pks, locs] = findpeaks(frame_spectrum, 'SortStr', 'descend', 'NPeaks', 4);
        
        % 转换为频率
        peak_freqs = F(locs);
        
        % 保存结果
        num_peaks = min(4, length(pks));
        if num_peaks > 0
            multi_pitch(i, 1:num_peaks) = peak_freqs(1:num_peaks);
            confidences(i, 1:num_peaks) = pks(1:num_peaks) / max(frame_spectrum); % 归一化置信度
        end
    end

    % 可视化帧能量
    visualize_energy(frame_energy, T, output_dir);

    % 可视化最大能量帧的频谱图
    max_energy_frame = params.windowed_frames(:, max_energy_idx);
    visualize_spectrum(max_energy_frame, fs, output_dir);

    fprintf('多基频提取完成 - 总帧数: %d\n', num_frames);
    fprintf('最大能量帧索引: %d (%.2f秒)\n', max_energy_idx, T(max_energy_idx));
end

%% 子函数：可视化帧能量
function visualize_energy(frame_energy, T, output_dir)
    figure('Position', [100, 100, 1000, 400]);
    plot(T, frame_energy/max(frame_energy));
    title('归一化帧能量');
    xlabel('时间 (秒)');
    ylabel('能量');
    grid on;

    % 保存图像
    saveas(gcf, fullfile(output_dir, 'frame_energy.png'));
end

%% 子函数：可视化指定帧的频谱图
function visualize_spectrum(frame, fs, output_dir)
    N = length(frame);
    fft_frame = fft(frame);
    fft_frame = fft_frame(1:N/2+1);
    f = (0:N/2)*(fs/N);
    mag = abs(fft_frame);
    
    % 只显示200-800Hz范围内的频谱
    freq_range = [200, 800];
    idx_range = (f >= freq_range(1)) & (f <= freq_range(2));
    
    % 绘制指定频率范围的频谱图
    figure('Position', [100, 100, 1000, 400]);
    plot(f(idx_range), 20*log10(mag(idx_range)), 'b-', 'LineWidth', 1.5);
    
    % 添加标题和标签
    title('最大能量帧的频谱图');
    xlabel('频率 (Hz)');
    ylabel('幅度 (dB)');
    grid on;
    
    % 设置x轴范围
    xlim(freq_range);
    
    % 保存图像
    saveas(gcf, fullfile(output_dir, 'max_energy_frame_spectrum.png'));
end
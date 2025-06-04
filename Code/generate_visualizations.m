function generate_visualizations(original_audio, processed_audio, fs, params, multi_pitch, chord_labels, output_dir)
    % 结果可视化模块
    % 输入:
    %   original_audio - 原始音频信号
    %   processed_audio - 预处理后的音频
    %   fs - 采样率
    %   params - 处理参数
    %   multi_pitch - 多基频矩阵
    %   chord_labels - 和弦标签
    %   output_dir - 输出目录

    %% 检查输出目录是否存在
    if ~exist(output_dir, 'dir')
        error('输出目录 %s 不存在，请检查。', output_dir);
    end

    %% 时间轴
    t = (0:length(original_audio)-1) / fs;
    frame_time = (0:size(multi_pitch,1)-1) * params.hop_length / fs;

    %% 创建一个新的图形窗口，用于绘制音频波形、频谱图和多基频叠加图
    figure('Position', [100, 100, 1200, 1000]);

    %% 绘制原始音频波形
    subplot(4, 1, 1);
    plot(t, original_audio);
    title('原始音频波形');
    xlabel('时间 (秒)');
    ylabel('幅度');
    grid on;

    %% 绘制预处理后的音频波形
    subplot(4, 1, 2);
    plot(t, processed_audio);
    title('预处理后的音频波形');
    xlabel('时间 (秒)');
    ylabel('幅度');
    grid on;

    %% 绘制频谱图
    subplot(4, 1, 3);
    [S, F, T] = spectrogram(processed_audio, params.window, params.overlap, params.window_length, fs);
    imagesc(T, F, 10*log10(abs(S)));
    axis xy;
    title('频谱图 (dB)');
    xlabel('时间 (秒)');
    ylabel('频率 (Hz)');
    colorbar;

    %% 绘制多基频叠加图
    subplot(4, 1, 4);
    imagesc(T, F, 10*log10(abs(S)));
    axis xy;
    hold on;

    % 绘制多基频轨迹
    colors = {'r', 'g', 'b', 'm'};
    for i = 1:size(multi_pitch, 2)
        valid_idx = multi_pitch(:, i) > 0;
        plot(frame_time(valid_idx), multi_pitch(valid_idx, i), colors{i}, 'Marker', '.', 'LineStyle', 'none');
    end

    title('多基频轨迹与时频图叠加');
    xlabel('时间 (秒)');
    ylabel('频率 (Hz)');
    legend('基频1', '基频2', '基频3', '基频4');
    colorbar;

    % 保存图像
    saveas(gcf, fullfile(output_dir, 'multi_pitch_visualization.png'));

    %% 创建一个新的图形窗口，用于绘制和弦识别结果
    figure('Position', [100, 100, 1200, 200]);
    num_frames = length(chord_labels);

    % 合并连续相同的和弦标签
    merged_chords = {};
    merged_start_times = [];
    merged_end_times = [];
    current_chord = chord_labels{1};
    start_time = frame_time(1);
    for i = 2:num_frames
        if ~strcmp(chord_labels{i}, current_chord)
            merged_chords{end+1} = current_chord;
            merged_start_times(end+1) = start_time;
            merged_end_times(end+1) = frame_time(i-1);
            current_chord = chord_labels{i};
            start_time = frame_time(i);
        end
    end
    % 处理最后一个和弦
    merged_chords{end+1} = current_chord;
    merged_start_times(end+1) = start_time;
    merged_end_times(end+1) = frame_time(end);

    % 绘制合并后的和弦标签
    for i = 1:length(merged_chords)
        mid_time = (merged_start_times(i) + merged_end_times(i)) / 2;
        text(mid_time, 0.5, merged_chords{i}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        % 绘制矩形框表示和弦持续时间
        rectangle('Position', [merged_start_times(i), 0, merged_end_times(i)-merged_start_times(i), 1], 'EdgeColor', 'k', 'LineStyle', '--');
    end

    xlim([frame_time(1), frame_time(end)]);
    ylim([0, 1]);
    title('和弦识别初始结果');
    xlabel('时间 (秒)');
    yticklabels([]);
    grid on;

    % 保存图像
    saveas(gcf, fullfile(output_dir, 'chord_recognition.png'));
end
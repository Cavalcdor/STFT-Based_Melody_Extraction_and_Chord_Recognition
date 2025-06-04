function [processed_audio, params] = preprocessing(input_audio, fs)
% 音频预处理模块
% 输入:
%   input_audio - 输入音频信号（列向量）
%   fs - 采样率（Hz）
% 输出:
%   processed_audio - 预处理后的音频信号（列向量）
%   params - 处理参数结构体

%% 1. 信号归一化
processed_audio = input_audio / max(abs(input_audio)); % 归一化到[-1, 1]

%% 2. 设置处理参数
window_length = 2048;     % 长时窗（42ms@48kHz）
overlap = 1434;           % 70%重叠率
filter_type = 'chebyshev';
cutoff_freqs = [20, 2000]; % 抑制高频噪声
params = struct('window_length', window_length, 'overlap', overlap, ...
    'filter_type', filter_type, 'cutoff_freqs', cutoff_freqs, 'fs', fs);

%% 3. 应用带通滤波器（保留20-10kHz）
processed_audio = apply_bandpass_filter(processed_audio, fs, filter_type, cutoff_freqs);

%% 4. 分帧处理（返回帧矩阵，每行是一帧）
[frames, hop_length] = audio_framing(processed_audio, window_length, overlap);
params.frames = frames;
params.num_frames = size(frames, 2); % 总帧数
params.hop_length = hop_length;

%% 5. 加窗处理（汉宁窗）
window = hann(window_length, 'periodic'); % 周期汉宁窗
params.window = window;
params.windowed_frames = frames .* window(:, ones(1, params.num_frames)); % 带窗帧矩阵

fprintf('预处理完成\n窗长: %d样本 (%.1fms), 重叠率: %.1f%%\n滤波器: %s, 通带: %d-%dkHz\n', ...
    window_length, window_length/fs*1000, overlap/window_length*100, filter_type, ...
    cutoff_freqs(1)/1000, cutoff_freqs(2)/1000);

end

%% 子函数：应用带通滤波器
function filtered_audio = apply_bandpass_filter(audio, fs, filter_type, cutoff_freqs)
    Wn = cutoff_freqs / (fs/2); % 归一化截止频率
    Wn = max(min(Wn, 0.99), 0.01); % 防止接近0或1

    switch lower(filter_type)
        case 'butterworth'
            [b, a] = butter(6, Wn, 'bandpass');
        case 'chebyshev'
            [b, a] = cheby1(4, 1, Wn, 'bandpass'); % 降低阶数避免数值问题
        otherwise
            error('不支持的滤波器类型');
    end

    filtered_audio = filtfilt(b, a, audio); % 零相位滤波
end

%% 子函数：音频分帧
function [frames, hop_length] = audio_framing(audio, window_length, overlap)
    hop_length = window_length - overlap;
    num_frames = floor((length(audio) - window_length) / hop_length) + 1;
    frames = zeros(window_length, num_frames);

    for i = 1:num_frames
        start_idx = (i-1)*hop_length + 1;
        end_idx = start_idx + window_length - 1;
        frames(:, i) = audio(start_idx:end_idx);
    end
end    
close all; clear; clc;

%% 参数配置
% audio_path = '../Test/Sources/Chords/Chords_full/Chords_full_0009.wav';
audio_path = '../Test/Sources/Songs/平行线.wav';
% 钢琴基频库
c4_midi = 60;                 % 中央C的MIDI编号
g5_midi = 79;                 % 高音谱号上加一线G5的MIDI编号
a4_midi = 69;                 % A4的MIDI编号
a4_freq = 440;                % A4的频率(Hz)
piano_midi = c4_midi:g5_midi;  % 中央C到G5的范围
piano_freqs = a4_freq * 2.^((piano_midi - a4_midi)/12);  % 十二平均律计算频率

% 创建结果目录
timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss');
output_dir = fullfile('..', 'Results', char(timestamp));
if ~exist(output_dir, 'dir'), mkdir(output_dir); end
fprintf('成功创建目录: %s\n', output_dir);

%% 加载音频
try
    [audio, fs] = audioread(audio_path);
    if size(audio, 2) > 1
        audio = audio(:, 1);
        fprintf('注: 输入音频为立体声，已自动转换为单声道\n');
    end
    fprintf('成功加载音频: %s\n采样率: %d Hz, 长度: %.2f 秒\n', ...
        audio_path, fs, length(audio)/fs);
catch ME
    error('音频加载失败: %s', ME.message);
end

%% 预处理
fprintf('\n===== 开始预处理 =====\n');
[processed_audio, params] = preprocessing(audio, fs);

%% 多基频提取
fprintf('\n===== 开始多基频提取 =====\n');
[multi_pitch, confidences] = melody_extraction(processed_audio, fs, params, output_dir);

% 保存多基频结果
frame_time = (0:size(multi_pitch,1)-1) * params.hop_length / fs;
output_data = [frame_time', multi_pitch, confidences];
output_data(isnan(output_data)) = 0;
writematrix(output_data, fullfile(output_dir, 'multi_pitch.csv'), 'Delimiter', ',');
fprintf('多基频结果已保存至: %s\n', fullfile(output_dir, 'multi_pitch.csv'));

%% 和弦识别
fprintf('\n===== 开始和弦识别 =====\n');
chord_labels = chord_recognition(multi_pitch, confidences, piano_midi, piano_freqs);

% 保存和弦结果
chord_data = [cellstr(chord_labels')];
writecell(chord_data, fullfile(output_dir, 'chords.csv'));
fprintf('和弦识别结果已保存至: %s\n', fullfile(output_dir, 'chords.csv'));

%% 可视化结果
fprintf('\n===== 生成可视化结果 =====\n');
generate_visualizations(audio, processed_audio, fs, params, multi_pitch, chord_labels, output_dir);

fprintf('\n===== 处理完成 =====\n结果已保存至: %s\n', output_dir);    
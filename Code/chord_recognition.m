function chord_labels = chord_recognition(multi_pitch, confidences, piano_midi, piano_freqs)
% 和弦识别模块
% 输入:
%   multi_pitch   - 多基频矩阵 (帧数×4，每行最多4个频率值)
%   confidences   - 对应基频的置信度矩阵 (帧数×4)
%   piano_midi    - 钢琴MIDI编号数组
%   piano_freqs   - 对应钢琴频率数组
% 输出:
%   chord_labels  - 和弦标签细胞数组

%% 初始化参数
num_frames = size(multi_pitch, 1);
chord_labels = cell(num_frames, 1);

%% 定义7种和弦类型
chord_types = [
    struct('name', '',    'intervals', [0,4,7],   'min_notes', 3);
    struct('name', 'm',    'intervals', [0,3,7],   'min_notes', 3);
    struct('name', 'aug',    'intervals', [0,4,8],   'min_notes', 3);
    struct('name', 'dim',    'intervals', [0,3,6],   'min_notes', 3);
    struct('name', '7',    'intervals', [0,4,7,10], 'min_notes', 4);
    struct('name', 'maj7',    'intervals', [0,4,7,11], 'min_notes', 4);
    struct('name', 'm7',    'intervals', [0,3,7,10], 'min_notes', 4)];

%% 频率到MIDI编号的映射函数
    function midi_note = freq_to_midi(freq)
        if isempty(freq) || isnan(freq) || freq <= 0
            midi_note = NaN;
            return;
        end
        [~, idx] = min(abs(freq - piano_freqs)); % 寻找最接近的钢琴频率
        midi_note = piano_midi(idx); % 获取对应的MIDI编号
    end

%% 主循环：逐帧处理
frame_scores = zeros(num_frames, 1); % 存储每帧的最佳分数
for frame = 1:num_frames
    %% 提取当前帧有效基频和置信度
    freqs = multi_pitch(frame, :);
    confs = confidences(frame, :);
    valid_mask = ~isnan(freqs) & freqs > 0;
    valid_freqs = freqs(valid_mask);
    valid_confs = confs(valid_mask);
    
    %% 转换为MIDI音符并去重
    midi_notes = arrayfun(@freq_to_midi, valid_freqs);
    [unique_notes, ~, note_indices] = unique(midi_notes);
    num_unique = length(unique_notes);
    if num_unique < 2 % 至少需要2个音符
        chord_labels{frame} = '未知';
        frame_scores(frame) = 0;
        continue;
    end
    
    %% 计算每个唯一音符的综合置信度
    unique_confs = arrayfun(@(n) max(valid_confs(note_indices == n)), 1:num_unique);
    
    %% 生成根音候选（按置信度降序排列）
    [~, sort_idx] = sort(unique_confs, 'descend');
    root_candidates = unique_notes(sort_idx);
    
    %% 遍历根音候选和和弦类型
    best_score = -inf;
    best_chord = '未知';
    for root_idx = 1:min(3, length(root_candidates)) % 只考虑前3个根音候选
        root = root_candidates(root_idx);
        intervals = mod(unique_notes - root, 12); % 计算相对于根音的半音间隔
        
        %% 遍历所有和弦类型
        for ct = 1:length(chord_types)
            ct_struct = chord_types(ct);
            if num_unique < ct_struct.min_notes % 音符数不足
                continue;
            end
            
            %% 检查是否包含所有必要音程
            required = ct_struct.intervals;
            missing = false(size(required));
            for i = 1:length(required)
                missing(i) = ~any(intervals == required(i));
            end
            if any(missing)
                continue; % 跳过不匹配的和弦类型
            end
            
            %% 计算和弦匹配度分数
            matched = ismember(intervals, required);
            matched_confs = unique_confs(matched);
            score = mean(matched_confs); % 匹配音符的置信度均值
            
            %% 特殊处理：如果是三和弦但检测到4个音符，降低分数
            if ct_struct.min_notes == 3 && num_unique > 3
                score = score * 0.9; % 轻微惩罚
            end
            
            %% 更新最优解
            if score > best_score
                best_score = score;
                root_name = midi_to_note_name(root);
                best_chord = [root_name, ' ', ct_struct.name];
            end
        end
    end
    
    %% 保存结果，置信度小于0.4的标记为未知
    if best_score < 0.4
        chord_labels{frame} = '未知';
        frame_scores(frame) = 0;
    else
        chord_labels{frame} = best_chord;
        frame_scores(frame) = best_score;
    end
end

%% 后处理：过滤掉短持续时间的和弦（1帧/2帧）
if num_frames >= 3
    for frame = 2:num_frames-1
        % 检查当前帧是否与前后帧都不同
        if strcmp(chord_labels{frame}, chord_labels{frame-1}) == 0 && ...
           strcmp(chord_labels{frame}, chord_labels{frame+1}) == 0
            chord_labels{frame} = '未知';
        end
    end
    
    % 处理第一帧
    if num_frames >= 2 && strcmp(chord_labels{1}, chord_labels{2}) == 0
        % 第一帧与第二帧相同，保留
    else
        chord_labels{1} = '未知';
    end
    
    % 处理最后一帧
    if num_frames >= 2 && strcmp(chord_labels{num_frames}, chord_labels{num_frames-1}) == 0
        % 最后一帧与倒数第二帧相同，保留
    else
        chord_labels{num_frames} = '未知';
    end
end

%% 辅助函数：MIDI编号转音符名称
    function note_name = midi_to_note_name(midi)
        notes = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
        note_idx = mod(midi - 60, 12) + 1; % 以中央C为基准
        note_name = notes{note_idx};
    end
end
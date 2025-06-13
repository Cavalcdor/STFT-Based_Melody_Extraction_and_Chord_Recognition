# STFT-Based Melody Extraction and Chord Recognition

**Signal Analysis and Processing Course Project**

## 1. 项目概述

本项目聚焦于音乐信号处理领域的核心问题——旋律与和弦的自动化解析，通过短时傅里叶变换（STFT）与时频分析技术，构建了一套从音频信号到音乐结构信息的完整处理链路。项目以MATLAB为开发平台，结合信号处理、音乐理论与模式识别技术，实现了多基频追踪与和弦分类两大核心功能，为音乐信息检索、自动伴奏生成、智能乐谱解析等应用场景提供了基础算法框架。

### 1.1 技术背景与应用场景

#### 1.1.1 技术背景

- **非平稳信号处理挑战**：音乐音频作为典型的非平稳信号，其频率成分随时间动态变化，传统傅里叶变换无法捕捉时频域联合特征。STFT通过滑动窗函数实现局部频谱分析，成为处理此类信号的经典方法。
- **音乐理论数字化映射**：和弦识别需将物理频率映射至音乐理论体系，涉及频率-MIDI音符转换、根音定位、音程匹配等多层级处理。

#### 1.1.2 应用场景

- **音乐教育辅助**：自动识别演奏音频中的旋律与和弦，生成实时乐谱标注，辅助学习者分析作品和声结构。
- **智能音乐创作**：为AI作曲系统提供输入音频的和声分析结果，实现旋律与和弦的自动配器。
- **音频检索与分类**：基于和弦进行序列构建音乐指纹，支持按和声风格检索音频片段。

### 1.2 核心技术架构

项目采用**三级流水线架构**，从原始音频到结构化音乐信息依次经过预处理、特征提取、模式识别三个阶段，各阶段技术要点如下：

#### 1.2.1 音频预处理

- **信号标准化**：通过归一化消除不同录音设备的幅度差异，确保后续STFT计算的一致性。
- **频段筛选**：采用4阶Chebyshev I型带通滤波器（1dB波纹，20-2000Hz通带），滤除人耳不敏感的次声波/超声波（<20Hz/<2000Hz）及高频噪声，同时保留钢琴等乐器的基频与泛音成分。
- **分帧加窗策略**：
  - **2048样本帧长**：对应48kHz采样率下约42.7ms时长，平衡时间分辨率与频率分辨率。
  - **70%重叠率**：减少帧间突变导致的频谱不连续，确保基频轨迹平滑。
  - **汉宁窗应用**：通过余弦加权抑制帧边缘信号突变，降低频谱泄漏对峰值检测的干扰。

#### 1.2.2 多基频提取

- **STFT幅度谱分析**：对每帧信号进行FFT变换，生成时频矩阵，通过峰值检测算法定位能量集中的频率成分。
- **多音高检测**：考虑到和弦通常由3-4个音符构成，设计单帧提取前4个峰值频率的策略，覆盖主流和弦的音符数量。
- **可视化辅助调试**：
  - **帧能量曲线**（`frame_energy.png`）：定位音频中的强信号段，辅助判断基频检测的有效区间。
  - **最大能量帧频谱**（`max_energy_frame_spectrum.png`）：聚焦200-800Hz中频区域，验证基频检测是否匹配乐谱标注。

#### 1.2.3 和弦识别

- **84类标准和弦库构建**：
  - **根音**：覆盖中央C至B4的12个半音，对应钢琴键盘的一个八度，涵盖流行音乐中大部分的和弦根音。
  - **和弦类型**：包含7种基础类型（大三、小三、增三、减三、大七、小七、属七），覆盖古典与流行音乐中的主流和声结构。
- **层次化匹配流程**：
  1. **频率-音符映射**：通过十二平均律公式\(f=440\times2^{(m-69)/12}\)（\(m\)为MIDI音符编号），实现物理信号到音乐符号的跨域转换。
  2. **根音枚举搜索**：对当前帧检测到的音符集合，枚举所有可能的根音，计算每个音符相对于根音的半音间隔。
  3. **音程结构匹配**：将半音间隔序列与和弦类型模板进行比对，选择最高分对应的根音与和弦类型组合。

```  
STFT-Based_Melody_Extraction_and_Chord_Recognition/
├── Code/                  # MATLAB核心代码
│   ├── main.m             # 主流程控制
│   ├── preprocessing.m    # 预处理模块（默认Chebyshev滤波）
│   ├── melody_extraction.m# 旋律提取（含帧能量分析）
│   ├── chord_recognition.m# 和弦识别（含后处理过滤）
│   ├── generate_visualizations.m # 运行过程可视化
│   └── GUI.htm # 结果可视化界面
├── Report/                # 技术文档
│   └── Project_Report.pdf # 项目报告
├── Documentation/         # 参考文献
│   └── 基于Matlab实现音乐识别与自动配置和声的功能_杨若芳.pdf
├── Test/                  # 测试数据
│   └── Sources/           # 原始音频源
│       ├── Chords/        # 和弦测试集（84个标准和弦音频）
│       │   ├── Chords_full/  # 完整和弦序列（Chords_full_0000.wav至Chords_full_0083.wav）
│       │   ├── Chords.mscz   # 和弦乐谱（MuseScore格式）
│       │   ├── Chords.pdf    # 和弦乐谱（PDF格式）
│       │   └── Chords.wav    # 和弦测试总音频
│       └── Songs/         # 歌曲测试集
│           ├── 第一夜.mscz  # 歌曲乐谱（MuseScore格式）
│           ├── 第一夜.pdf   # 歌曲乐谱（PDF格式）
│           ├── 第一夜.wav   # 歌曲测试音频
│           └── ...         # 更多测试文件
├── Results/                # 动态输出
│   ├── 2025-06-01_12-00-00/  
│   │   ├── multi_pitch.csv       # 多基频序列
│   │   ├── chords.csv            # 和弦类型
│   │   ├── multi_pitch_visualization.png # 基频与时频图叠加
│   │   ├── chord_recognition.png       # 和弦持续时间可视化
│   │   ├── frame_energy.png            # 归一化帧能量曲线
│   │   └── max_energy_frame_spectrum.png # 关键帧频谱细节
│   └── ...  
├── README.md              # 项目说明
└── LICENSE                # 开源协议
```  

## 3. 功能模块与代码实现细节

### 3.1 音频预处理

**技术实现**：  

- **信号归一化**：将输入音频信号归一化到[-1, 1]范围，以消除不同音频信号幅度的差异。

```matlab
processed_audio = input_audio / max(abs(input_audio));  
```

- **带通滤波**：应用带通滤波器，保留20-2000Hz的频率成分，抑制高频噪声。支持Butterworth和Chebyshev滤波器。

```matlab
Wn = cutoff_freqs / (fs/2); % 归一化截止频率
Wn = max(min(Wn, 0.99), 0.01); % 防止接近0或1
[b, a] = cheby1(4, 1, Wn, 'bandpass'); % 降低阶数避免数值问题
filtered_audio = filtfilt(b, a, audio); % 零相位滤波
```

- **分帧处理**：将音频信号分成长度为`window_length`的帧，帧与帧之间有`overlap`的重叠。

```matlab
hop_length = window_length - overlap;
num_frames = floor((length(audio) - window_length) / hop_length) + 1;
frames = zeros(window_length, num_frames);
for i = 1:num_frames
    start_idx = (i-1)*hop_length + 1;
    end_idx = start_idx + window_length - 1;
    frames(:, i) = audio(start_idx:end_idx);
end
```

- **加窗处理**：对分帧后的音频信号应用汉宁窗，以减少频谱泄漏。

```matlab
window = hann(window_length, 'periodic'); % 周期汉宁窗
params.windowed_frames = frames .* window(:, ones(1, params.num_frames)); % 带窗帧矩阵
```

### 3.2 主旋律提取

**基于 STFT 的多基频提取流程**：

1. **计算 STFT**：对预处理后的音频信号进行STFT计算，得到幅度谱。

```matlab
[S, F, T] = spectrogram(audio, window, hop_length, window_length, fs, 'yaxis');
S = abs(S);  % 幅度谱
```

2. **提取峰值频率**：对每帧的幅度谱进行处理，提取前4个峰值频率作为基频，并计算相应的置信度。

```matlab
for i = 1:num_frames
    frame_spectrum = S(:, i);
    [pks, locs] = findpeaks(frame_spectrum, 'SortStr', 'descend', 'NPeaks', 4);
    peak_freqs = F(locs);
    num_peaks = min(4, length(pks));
    if num_peaks > 0
        multi_pitch(i, 1:num_peaks) = peak_freqs(1:num_peaks);
        confidences(i, 1:num_peaks) = pks(1:num_peaks) / max(frame_spectrum); % 归一化置信度
    end
end
```

3. **帧能量分析**：计算每帧能量并生成`frame_energy.png`，用于定位音频中的强信号段。
4. **最大能量帧频谱**：生成`max_energy_frame_spectrum.png`，聚焦 200-800Hz 范围内的频谱细节，辅助验证基频检测准确性。

### 3.3 和弦识别

**和弦识别流程**：

1. **定义和弦类型**：定义7种和弦类型，包括大三、小三、增三、减三、大七、小七和属七和弦。

```matlab
chord_types = [
    struct('name', '',    'intervals', [0,4,7],   'min_notes', 3);
    struct('name', 'm',    'intervals', [0,3,7],   'min_notes', 3);
    struct('name', 'aug',    'intervals', [0,4,8],   'min_notes', 3);
    struct('name', 'dim',    'intervals', [0,3,6],   'min_notes', 3);
    struct('name', '7',    'intervals', [0,4,7,10], 'min_notes', 4);
    struct('name', 'maj7',    'intervals', [0,4,7,11], 'min_notes', 4);
    struct('name', 'm7',    'intervals', [0,3,7,10], 'min_notes', 4)];
```  

2. **钢琴基频库映射**：

```matlab
% 钢琴基频库定义（中央C到G5）
c4_midi = 60;                 % 中央C的MIDI编号
g5_midi = 79;                 % 高音谱号上加一线G5的MIDI编号
a4_midi = 69;                 % A4的MIDI编号
a4_freq = 440;                % A4的频率(Hz)
piano_midi = c4_midi:g5_midi;  % 中央C到G5的范围
piano_freqs = a4_freq * 2.^((piano_midi - a4_midi)/12);  % 十二平均律计算频率
```  

3. **逐帧处理**：将检测到的频率映射为钢琴MIDI音符，去重后计算每个唯一音符的综合置信度。
4. **根音候选与和弦匹配**：生成根音候选，遍历根音候选和和弦类型，计算相对于根音的半音间隔，检查是否包含所有必要音程，计算匹配度分数，更新最优解。
5. **后处理过滤**：
   - 若某帧和弦与前后帧均不同，则标记为“未知”（过滤单帧噪声）。
   - 首帧和末帧需与相邻帧一致才保留，否则标记为“未知”。

## 4. 运行与调试

### 4.1 环境依赖

```matlab
% 必选工具箱检测代码
if ~license('test', 'signal_toolbox') || ~license('test', 'audio_toolbox')
    error('请安装Signal Processing Toolbox与Audio Toolbox');
end
```

### 4.2 调试技巧

1. **预处理可视化**：

   ```matlab
   % 在preprocessing.m后添加频谱图绘制
   figure;
   spectrogram(processed_audio, params.window, params.overlap, params.window_length, fs);
   ```

2. **基频估计调试**：
   - 打印置信度序列：`disp(confidences);`
   - 绘制基频曲线：`plot(multi_pitch); title('多基频轨迹');`
   - 分析 `max_energy_frame_spectrum.png`，验证峰值频率是否符合音乐理论。
3. **和弦匹配诊断**：
   - 输出所有匹配分数：`disp(chord_conf);`
   - 可视化和弦识别结果：查看生成的 `chord_recognition.png` 文件，检查和弦持续时间标注是否合理。

## 5. 团队贡献详情

- **Cavalcdor**：统筹项目进度，基础算法框架实现，钢琴基频库设计与实现，Musescore的模拟输入实现及调试
- **Atopos**：主导撰写技术报告，实验数据整理与分析，参与算法测试
- **luvwy**：可视化模块开发，GUI界面设计，优化用户界面
- **ing**：梳理项目技术路线，汇报PPT制作，准备展示相关材料

## 6. 开发工具说明

本项目开发过程中使用了以下工具：

- **音频输入工具**：MuseScore 3
- **开发环境**：MATLAB R2024a

## 7. 版权与开源声明

### 7.1 项目背景与版权归属

本项目为浙江大学《信号分析与处理》课程作业，由控制科学与工程学院2023级本科生4人团队独立完成。代码与文档的**著作权归团队所有**，核心算法基于公开文献中的原理优化实现，**仅限学术交流与课程展示使用**，未经允许不得用于商业场景。

### 7.2 代码开源许可

**代码部分（`Code/`目录下文件）**采用**MIT许可证**开源（见项目根目录`LICENSE`文件），允许非商业用途的学习、修改和再分发，但需遵守以下条件：

1. 保留代码中的版权声明和许可证文本；
2. 若修改代码，需在提交版本中说明修改内容；
3. 不得声称原始代码为自行创作。

**技术文档部分（`Report/`等）** 不属于开源范围，版权归团队所有，仅供参考学习，请勿复制传播。

### 7.3 许可证文本获取

MIT许可证全文请查看项目根目录`LICENSE`文件，或访问[MIT License 标准文本](https://opensource.org/licenses/MIT)。

### 7.4 测试数据版权说明

### 7.4.1 第三方数据性质声明

**Test/Sources/Songs/** 目录下的测试音频与和弦数据为团队基于公开音频自行听辨整理的**非官方和声分析结果**，**不代表原曲实际和弦构成**，仅用于**浙江大学《信号分析与处理》课程作业的算法验证**。  

### 7.4.2 版权声明与使用限制

1. **原作品版权**：
   所涉及的原歌曲版权归**原作者及所属唱片公司**所有，本项目**未获得原作品任何授权**。
2. **数据性质**：  
   团队整理的和弦进行为**非官方演绎创作**，可能与原曲存在差异，**严禁作为原谱传播或用于音乐教学、商业编曲等场景**。
3. **使用范围**：
   该数据仅限在**课程作业提交、课堂展示**等**校内学术场景**中使用，**禁止公开传播、开源发布或用于任何营利目的**。

### 7.4.3 风险提示

- 使用者需自行遵守《中华人民共和国著作权法》等法律法规，若因数据使用引发版权纠纷，**责任由使用者自行承担**。
- 建议使用**自有版权素材**或**公共领域音乐**进行算法测试。

**团队成员**：Cavalcdor, Atopos, luvwy, ing
**日期**：2025年6月1日

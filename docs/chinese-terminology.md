# 中文术语与翻译优化（0.4.3）

本版检查现有 1,266 条语言资源，修订 79 条中文译文，新增 4 个按控件用途区分的翻译键。此轮覆盖常用工具、滤镜参数、Camera Raw、选区与蒙版提示；不是全部界面和所有窗口宽度的一致性认证。

## 翻译原则

- 先对照原生控件与实际操作，再决定中文措辞。常见修图术语参考 Adobe 简体中文文档，但更清楚的参数名不必逐字沿用其所有旧版译法。
- 图层比例、画布缩放、裁剪、剪贴蒙版和色调剪切分别使用不同含义的文字。
- 同一个英文词在不同操作中含义不同，使用上下文翻译键；英文显示值仍保持原文，枚举原始值、命令 ID、快捷键、用户输入与文件数据不翻译。
- 本次只更改文字与显示用翻译键，保留控件布局、按键映射、参数范围与编辑方法。正式发布前检查格式参数、英文资源和编译后的语言包，运行既有本地化测试并检查实际界面。

## 主要术语

| 英文或场景 | 当前中文 | 用途与说明 |
| --- | --- | --- |
| Scale / Zoom / Ratio | 比例 / 画布缩放 / 纵横比 | 分别表示图层大小、视图倍率与裁剪宽高关系。 |
| Amount（滤镜）/ Amount（选区） | 强度 / 像素数 | 滤镜作用程度与扩展、收缩、羽化的距离分开显示。 |
| Master（色相/饱和度） | 全图 | 同时调整所有颜色，不指 RGB 主通道。 |
| Light（Camera Raw）/ Light（色块） | 明暗 / 亮色 | 曝光等色调调整区与颜色色块分开显示。 |
| Type（工具）/ Type（污点修复模式） | 文字 / 修复方式 | 修复模式选择器的辅助功能名称不再显示为“文字”。 |
| Guides（画布）/ Guides（透视校正） | 参考线 / 校正线 | 透视校正面板的清除按钮不会暗示清除画布参考线。 |
| Uniform / Gaussian | 均匀 / 高斯 | 噪声分布方式；“均匀”避免与平均颜色滤镜混淆。 |
| Nearest / Sampling | 最近邻 / 插值方式 | 图像变换与重采样时的插值选项。 |
| Vignette / Vignetting | 晕影 | 可调暗或调亮边缘，因此不只称“暗角”。 |
| Dehaze | 去除薄雾 | 提高数值去雾、降低数值加雾。 |
| Green/Purple Amount | 绿色/紫色去边强度 | 表示减弱色边的程度，而非绿色或紫色的数量。 |
| Three-Way / Parametric / Point | 三色轮 / 参数曲线 / 点曲线 | 明确色轮数量与两种曲线操作方式。 |
| Highlight/Shadow Clipping | 高光/阴影剪切 | 指亮部或暗部细节丢失；帮助文字说明预览颜色，区别于画布裁剪和剪贴蒙版。 |
| Clone source | 取样点 | 统一仿制图章的取样位置与对齐说明。 |
| Line Spacing / Thickness（扫描线） | 线条间距 / 线宽 | 区别于文字行距与立体对象厚度。 |
| Trim / Layer via Copy | 裁边 / 通过复制新建图层 | 明确裁去边缘与创建新图层的结果。 |

## 参考来源

“晕影”“去除薄雾”及正负参数含义参考 [Adobe Camera Raw 效果说明](https://helpx.adobe.com/cn/camera-raw/desktop/edit-and-enhance-images/tone-and-color/vignette-grain-effects-camera-raw.html)。

“高光/阴影剪切”的含义参考 [Adobe Lightroom 色调与颜色说明](https://helpx.adobe.com/cn/lightroom-classic/desktop/process-and-develop-photos/image-tone-color.html)。

“全图”色相范围和常用混合模式名称参考 [Adobe Photoshop 中文参考手册](https://helpx.adobe.com/archive/cn/photoshop/cc/2015/photoshop_reference.pdf)。

Adobe 不同年代的界面译法存在差别，例如 Uniform 的“平均”和 Amount 的“数量”。本版选用“均匀”和“强度”是减少歧义，不据此宣称 Adobe 旧译法或原生算法错误。软件中控件的实际实现仍以采用的 Compositor 源码为准。

## 本次逐条修订

| 英文键 | 原中文 | 当前中文 |
| --- | --- | --- |
| Amount | 数量 | 强度 |
| Master | 主通道 | 全图 |
| Uniform | 平均 | 均匀 |
| Nearest | 邻近 | 最近邻 |
| Sampling | 采样 | 插值方式 |
| Ratio | 比例 | 纵横比 |
| Green Amount | 绿色数量 | 绿色去边强度 |
| Purple Amount | 紫色数量 | 紫色去边强度 |
| Green Hue | 绿色色相 | 绿色色相范围 |
| Purple Hue | 紫色色相 | 紫色色相范围 |
| Dehaze | 去朦胧 | 去除薄雾 |
| Clears haze when raised, and adds haze when lowered. | 提高时去除朦胧，降低时增加朦胧。 | 提高数值可去除薄雾，降低数值可增加薄雾。 |
| Three-Way | 三向 | 三色轮 |
| Three-Way shows shadows, midtones, and highlights. The other choices show one wheel. | 三向模式同时显示阴影、中间调与高光；其他模式显示一个色轮。 | 三色轮模式同时显示阴影、中间调和高光三个色轮；其他模式显示一个色轮。 |
| Parametric | 参数 | 参数曲线 |
| Point | 点 | 点曲线 |
| Parametric lifts tonal regions. Point places anchors on the curve. | 参数模式调整色调区域；点模式在曲线上放置控制点。 | 参数曲线按亮度区域调整明暗；点曲线通过控制点调整曲线形状。 |
| Grading | 分级 | 调色 |
| Upright | 直立 | 透视校正 |
| Rectilinear | 直线 | 直线投影 |
| Perspective allows stronger keystone. Rectilinear keeps the warp gentler. | 透视模式支持更强的梯形校正；直线模式的变形较柔和。 | 透视投影支持较强的梯形校正；直线投影采用较柔和的变形。 |
| Draw Guides | 绘制参考线 | 绘制校正线 |
| Drag on the layer to place a guide. Draw at least two lines. | 在图层上拖动放置参考线，至少绘制两条。 | 在图层上拖动绘制校正线，至少绘制两条。 |
| Draw two or more lines on the preview that should be level or vertical. | 在预览中绘制至少两条应为水平或垂直的线。 | 在预览中绘制至少两条应为水平或垂直的校正线。 |
| Remove every guide line. | 移除所有参考线。 | 清除所有透视校正线。 |
| Off leaves the picture as it is. Guided straightens from lines you draw on the picture. | 关闭时保持原图；引导模式根据你在图片中绘制的线条校正。 | 关闭时保持原图；引导模式根据图中绘制的校正线校正透视。 |
| Shifts the picture from blue to yellow. | 将图片从偏蓝调整为偏黄。 | 在蓝色与黄色之间调整色温。 |
| Shifts the picture from green to mauve. | 将图片从偏绿调整为偏紫。 | 在绿色与洋红色之间调整色调。 |
| Hue shifts the color, Saturation its strength, and Luminance its brightness. | 色相改变颜色，饱和度改变浓度，亮度改变明暗。 | 色相改变颜色种类，饱和度改变颜色的鲜艳程度，亮度改变明暗。 |
| Makes the picked color stronger or quieter. | 增强或减弱拾取颜色的浓度。 | 增强或减弱所取样颜色的饱和度。 |
| Makes the selected color family stronger or quieter. | 增强或减弱所选色系的浓度。 | 增强或减弱所选色系的饱和度。 |
| Strengthens or weakens every color by the same amount. | 以相同幅度增强或减弱所有颜色。 | 以相同幅度提高或降低所有颜色的饱和度。 |
| Strengthens quiet colors more than colors that are already strong, and protects skin tones. | 优先增强较淡颜色，同时保护肤色。 | 优先调整低饱和度颜色，对已鲜艳的颜色影响较小，并保护肤色。 |
| Highlight Clipping Indicator | 高光溢出指示 | 高光剪切指示 |
| Shadow Clipping Indicator | 阴影溢出指示 | 阴影剪切指示 |
| Show clipped highlights in red on the preview. | 在预览中用红色显示溢出的高光。 | 在预览中用红色标出高光剪切区域（亮部细节丢失）。 |
| Show clipped shadows in blue on the preview. | 在预览中用蓝色显示溢出的阴影。 | 在预览中用蓝色标出阴影剪切区域（暗部细节丢失）。 |
| Adjusts the bright parts of the picture. Hold Option to see clipped highlights. | 调整图片的明亮区域。按住 Option 查看溢出的高光。 | 调整图片的高光区域。按住 Option 查看高光剪切预览。 |
| Adjusts the dark parts of the picture. Hold Option to see clipped shadows. | 调整图片的暗部。按住 Option 查看溢出的阴影。 | 调整图片的阴影区域。按住 Option 查看阴影剪切预览。 |
| Brightens or darkens the whole picture, in stops of light. Hold Option to see clipped highlights. | 以曝光档数调亮或调暗整张图片。按住 Option 查看溢出的高光。 | 以曝光档数调亮或调暗整张图片。按住 Option 查看高光剪切预览。 |
| Sets the brightest point. Hold Option to see clipped highlights. | 设置最亮点。按住 Option 查看溢出的高光。 | 设置白场。按住 Option 查看高光剪切预览。 |
| Sets the darkest point. Hold Option to see clipped shadows. | 设置最暗点。按住 Option 查看溢出的阴影。 | 设置黑场。按住 Option 查看阴影剪切预览。 |
| Keep the source moving with the brush between strokes; off starts every stroke at the source point | 在笔画之间保持来源随画笔移动；关闭后，每笔都从来源点开始 | 在连续笔画之间保持取样点与画笔的相对位置；关闭后，每次绘制都从同一取样点开始。 |
| Option-click to set the source | 按住 Option 点击设置来源 | 按住 Option 点击设置取样点 |
| Clone Stamp (S) · Option-click sets the source | 仿制图章（S）· 按住 Option 点击设置来源 | 仿制图章（S）· 按住 Option 点击设置取样点 |
| Option-click to set the source · Drag to clone · [ ] size · Shift-[ ] hardness · 1–0 opacity · Space to pan | Option 点击设置来源 · 拖动仿制 · [ ] 大小 · Shift-[ ] 硬度 · 1–0 不透明度 · 空格平移 | Option 点击设置取样点 · 拖动仿制 · [ ] 大小 · Shift-[ ] 硬度 · 1–0 不透明度 · 空格平移 |
| Option-click where Clone Stamp should copy from first. | 请先按住 Option 点击仿制图章的来源位置。 | 请先按住 Option 点击图像，设置仿制图章的取样点。 |
| Copy from the active layer only, or from every visible layer as shown | 仅从当前图层复制，或从所有可见图层的显示结果复制 | 仅从当前图层取样，或从所有可见图层的合成结果取样 |
| Read colors from the active layer only, or from every visible layer as shown | 仅从当前图层读取颜色，或从所有可见图层的显示结果读取 | 从当前图层取样，或从所有可见图层的合成结果取样 |
| Analyze the active layer only, or every visible layer as shown | 仅分析当前图层，或分析所有可见图层的显示效果 | 仅分析当前图层，或分析所有可见图层的合成结果 |
| Show Controls | 显示控件 | 显示变换框 |
| Show Transform Controls | 显示变换控件 | 显示变换框 |
| Show the transform box and handles (⌘H). When hidden, drag anywhere to move the layer. | 显示变换框与控制点（⌘H）。隐藏时，在任意位置拖动即可移动图层。 | 显示变换框与控制点（⌘H）。隐藏后，在画布任意位置拖动即可移动当前图层。 |
| Line Spacing | 行间距 | 线条间距 |
| Thickness | 厚度 | 线宽 |
| Layer via Copy | 通过拷贝的图层 | 通过复制新建图层 |
| Duplicate / Layer via Copy | 复制图层 / 通过拷贝的图层 | 复制图层 / 通过复制新建图层 |
| Bake and Delete | 固化并删除 | 保留效果并删除 |
| Remove Links and Delete | 移除链接并删除 | 解除链接并删除 |
| Bake keeps the current masked appearance in the dependent layers’ pixels. Remove Links reveals their pixels. You can undo either choice. | 固化会将当前蒙版效果写入依赖图层的像素；移除链接会显示其原始像素。两种操作均可撤销。 | 保留效果会把当前蒙版效果写入使用此蒙版的图层像素；解除链接会显示这些图层未被蒙版遮盖的像素。两种操作均可撤销。 |
| These layers supply live masks | 这些图层提供实时蒙版 | 这些图层被用作实时蒙版 |
| This layer supplies a live mask | 此图层提供实时蒙版 | 此图层被用作实时蒙版 |
| Trim | 修边 | 裁边 |
| Trim… | 修边… | 裁边… |
| Trim Away | 移除边缘 | 裁去边缘 |
| Couldn’t trim image | 无法修边 | 无法裁去图像边缘 |
| No content remained after trimming. | 修边后没有剩余内容。 | 裁边后没有剩余内容。 |
| The trimmed image dimensions are invalid. | 修边后的图像尺寸无效。 | 裁边后的图像尺寸无效。 |
| Develop “%@” | 处理“%@” | RAW 显影“%@” |
| Choose the vignette color | 选择暗角颜色 | 选择晕影颜色 |
| Color Picker (Vignette Color) | 拾色器（暗角颜色） | 拾色器（晕影颜色） |
| How much of the profile vignetting correction is applied. | 镜头配置文件渐晕校正的应用比例。 | 镜头配置文件晕影校正的应用比例。 |
| Makes the vignette rounder or more square. | 使暗角更圆或更方。 | 使晕影更圆或更方。 |
| Moves the vignette correction inward or outward. | 向内或向外移动渐晕校正范围。 | 向内或向外移动晕影校正范围。 |
| Protects bright pixels while a dark vignette is applied. Used by Highlight Priority. | 应用暗角时保护明亮像素，用于高光优先模式。 | 应用晕影时保护明亮像素，用于高光优先模式。 |
| Sets where the vignette begins, from the center outward. | 设置暗角从中心向外开始的位置。 | 设置晕影从中心向外开始的位置。 |
| Softens the edge of the vignette. | 柔化暗角边缘。 | 柔化晕影边缘。 |
| Vignette | 暗角 | 晕影 |
| Vignetting | 渐晕 | 晕影 |
| Selection adjustment amount | Amount（新增上下文键） | 像素数 |
| Healing type | Type（新增上下文键） | 修复方式 |
| Clear perspective guides | Clear Guides（新增上下文键） | 清除校正线 |
| Camera Raw light section | Light（新增上下文键） | 明暗 |

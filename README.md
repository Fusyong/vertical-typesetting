ConTeXt模块，在ConTeXt lmtx/LuaTEX环境中实现中文竖排/直书。

## 安装和使用方法

* 两种安装方法：
    1. 按[ConTeXt官方指南](https://wiki.contextgarden.net/Modules)安装模块文件：`t-vtypeset.mkiv`（入口）和`t-vtypeset.lua`，然后使用`context --generate`命令更新文件索引
    1. 将上述文件直接放在编译时的当前路径（通常即排版脚本所在的目录，在vscode环境中即项目根目录）；直接使用lua模块时不限定存放位置，但需要自行确保导入位置正确
* 使用时在排版脚本前言中设置如下：

```latex
%%%%%%%%%%%%% 使用模块(保持顺序) %%%%%%%%%%%%%
% 竖排
\usemodule[vtypeset]


% 标点压缩与支持
\usemodule[zhpunc][pattern=kaiming, spacequad=0.5, hangjian=false]
% 
% 四种标点压缩方案：全角、开明、半角、原样：
%   pattern: quanjiao(default), kaiming, banjiao, yuanyang
% 行间标点（转换`、，。．：！；？`到行间，pattern建议用banjiao）：
%   hangjian: false(default), true
% 加空宽度（角）：
%   spacequad: 0.5(default)
% 
% 行间书名号和专名号（\bar实例）：
%   \zhuanmh{专名}
%   \shumh{书名}


% 夹注
\usemodule[jiazhu][fontname=tf, fontsize=10.5pt, interlinespace=0.2em]
% default: fontname=tf, fontsize=10.5pt, interlinespace=0.08em(行间标点时约0.2em)
% fontname和fontsize与\switchtobodyfont的对应参数一致
% 夹注命令：
%   \jiazh{夹注}

```

可参考test文件夹下样例脚本中的设置（可能使用了夹注[jiazhu](https://github.com/Fusyong/jiazhu)、竖排[vtypeset](https://github.com/Fusyong/vertical-typesetting)、标点挤压[zhpunc](https://github.com/Fusyong/zhpunc)三个模块）。

### 编译脚本

1. 仅在[ConTeXt LMTX](https://wiki.contextgarden.net/Installation)环境测试，其他版本的ConTeXt当不支持。ConTeXt LMTX是与LuaMetaTeX(LuaTeX的后继者)配合使用的、最新的ConTeXt版本。调整后当可用于LuaTeX。可以使用`context --version && luametatex --version`命令查看你的环境版本。
1. 如下编译排版脚本：
    >```shell
    >> context 大学章句.lmtx
    >```
1. 如果控制台显示中文时有乱码，可用命令临时改变代码页：
    >```shell
    >> chcp 65001
    >```

## 效果

![plot](https://blog.xiiigame.com/img/2022-11-20-ConTeXt简介和中文排版效果/竖开明大学.jpg)

![plot](https://blog.xiiigame.com/img/2022-11-20-ConTeXt简介和中文排版效果/横全角庄子.jpg)

## bug & TODO 

* [x] 字符旋转、对齐
* [x] 双行夹注/割注，参见[jiazhu](https://github.com/Fusyong/jiazhu)插件
* [x] 字右、字左注音
* [x] 《标点符号用法》 5.2 竖排文稿标点符号的位置和书写形式
    * [x] 5.2.1 句号、问号、叹号、逗号、顿号、分号和冒号均置于相应文字之下偏右。
    * [x] 5.2.2 破折号、省略号、连接号、间隔号和分隔号置于相应文字之下居中,上下方向排列。
    * [x] 5.2.3 引号改用双引号“﹃”“﹄”和单引号“﹁”“﹂”,括号改用“︵”“︶”,标在相应项目的上下。
    * [x] 5.2.4 竖排文稿中使用浪线式书名号“﹏”,标在相应文字的左侧。
    * [x] 5.2.5 着重号标在相应文字的右侧,专名号标在相应文字的左侧。
    * 5.2.6 横排文稿中关于某些标点不能居行首或行末的要求,同样适用于竖排文稿。
* [x] 改为在shipouts after回调中装盒旋转
    * [x] 缓存标点的偏置数据
    * [ ] 缓存旋转后的盒子（至少是标点盒子），并测试收益
* [x] 模块化
* [x] 兼容现有bar功能
    * [x] 文字（text选项，可做竖排书名号/波浪线）
        * [x] 楷体正文时有间隙
    * [x] MetaPost（mp选项）
* [x] 删除破折号、省略号禁止排在行头的规则
* [ ] 更改旋转对齐规则（解决“一、灬”等字的问题）
* [ ] 使PDF文件拷贝后的文字分行、分段正确
* [ ] 管理属性设置，防止冲突（包括标点压缩、夹注个模块）


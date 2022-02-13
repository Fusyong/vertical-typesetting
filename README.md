个人学习ConTeXt lmtx 与 LuaTEX，尝试实现中文竖排/直书功能

## 内容

1. zhfonts文件夹，请拷贝[zhfonts](https://github.com/Fusyong/zhfonts)项目中的文件到其下；[zhfonts](https://github.com/Fusyong/zhfonts)对[liyanrui/zhfonts](https://github.com/liyanrui/zhfonts)项目的改造，谨致谢忱！
1. vertical_typeset.lua是直排插件，目前通过vtypesetting_callback.lmtx示例文档来使用
1. vtypesetting_box.lmtx是早期的功能探索示例文档，参见说明[ConTeXt LMTX的汉字竖排思路](htttps://blog.xiiigame.com/2022-01-14-ConTeXt%20LMTX的汉字竖排思路/)

## 现状

![xz](https://github.com/Fusyong/vertical-typesetting/blob/46efdef93eef29619597d1528c2851ae3b252e8d/img/README/2022-02-13-18-50-41.png)

## TODO 

* 更改旋转对齐规则（“一”等字的问题）
* 删除破折号、省略号紧止排在行头的规则
* 夹注/割注
* 注音
* ……

<!-- 
## 参考资料

### [《挤进推出避头尾》](https://www.thetype.com/2018/05/14501/)所述的避头尾规则：

> * 点号，包括句号、问号、叹号、逗号、顿号、分号、冒号，都要避头。
> * 标号中的引号、括号、书名号：前一半避尾，后一半避头。
> * 标号中的连接号（–）、间隔号（·）都不能出现在行头。
> * 标号中的分隔号（/）不能出现在行头也不出现在行尾。

### 无需旋转的竖排标点

︵ ︷ ︿ ︹ ︽ _ ﹁ ﹃ ︻ ︶ ︸ ﹀ ︺ ︾ ˉ ﹂ ﹄ ︼

-->

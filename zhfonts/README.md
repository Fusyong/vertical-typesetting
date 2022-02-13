## 调整说明

* 增加文件t-zhspuncs.mkiv，使标点压缩成为一个独立模块。使用方法`\usemodule[zhspuncs]`
* 修改文件t-zhspuncs.lua，使两个模块都可以使用；增加直排标点压缩支持；为教学目的添加中文注释。

## 原作者的说明

* Introduction

zhfonts is a module for ConTeXt MkIV. It can help some users to try ConTeXt MkIV based LuaTeX for Chinese typesetting.

The zhfonts is implemented by using "nodes.tasks.appendaction('processors','after', 'my_callback_function')" which is offered by ConTeXt MkIV.Therefore I could not guarantee zhfonts works all along unless my_callback_function is always valid.

* Usage

Please read http://garfileo.is-programmer.com/posts/23740
--ah21 vertical_typeset.lua
Moduledata = Moduledata or {}
Moduledata.vertical_typeset = Moduledata.vertical_typeset or {}

-- 本地化以提高运行效率
local glyph_id = nodes.nodecodes.glyph --node.id("glyph")

local node_copy = node.copy
local node_getproperty = node.getproperty
local node_insertafter = node.insertafter
local node_new = node.new
local node_remove = node.remove
local node_setproperty = node.setproperty

--判断是不是汉字（是否需要直排）
local function c_to_vertical(c)
    -- 常用的汉字编码范围，还有更多
    return c >= 0x04E00 and c <= 0x09FFF
end

--需要旋转的标点符号集
local puncs_to_rotate = {
    [0x3001] = {0.15, 0.5, 1.0, 0.5},   -- 、
    [0xFF0C] = {0.15, 0.5, 1.0, 0.3},   -- ，
    [0x3002] = {0.15, 0.6, 1.0, 0.3},   -- 。
    [0xFF0E] = {0.15, 0.5, 1.0, 0.5},   -- ．
    [0xFF1F] = {0.15, 0.5, 1.0, 0.5},   -- ？
    [0xFF01] = {0.15, 0.5, 1.0, 0.5},   -- ！
    [0xFF1A] = {0.15, 0.5, 1.0, -0.1},  -- ：
    [0xFF1B] = {0.15, 0.5, 1.0, 0.5},   -- ；
}

-- 旋转汉字和部分标点
function Moduledata.vertical_typeset.processmystuff(head)
    local n = head
    while n do --不在node.traverse_id()中增删结点，以免引用混乱
        if n.id == glyph_id then
            local n_char = n.char
            local p_to_rotate = puncs_to_rotate[n_char]
            if  c_to_vertical(n_char) or p_to_rotate then
                local l = node_new("hlist")
                l.list =  node_copy(n) --复制结点到新建的结点列表\hbox下
                local w, h, d, t = n.width, n.height, n.depth, n.total
                if p_to_rotate then
                    -- 给盒子设置资产表，携带字符char TODO 删除l.list.data = 10000
                    --l. = {}
                    local p = node_getproperty(l)
                    if not p then
                        p = {}
                        node_setproperty(l, p)
                    end
                    p.char = n_char
                    local pre_space = w * 0.15 --前留白，可以通过boundingbox等信息精确调整
                    l.width, l.height, l.depth = w, w, 0 --设置尺寸
                    l.yoffset = w * 0.3 --楷体0.2, 宋体0.3
                    l.hoffset = h + pre_space
                else --汉字
                    l.width, l.height, l.depth = w, w, 0 --设置尺寸
                    l.yoffset = -w * 0.2 --楷体0.2, 宋体0.3
                    l.hoffset = h + (w - t) / 2 --两侧平均留空
                end
                l.orientation = 0x003 --以基线左端为圆心顺转3*90度，即左转90度
                head, l = node_insertafter(head, n, l)
                --删除原结点（注释后如果要观察前后相对关系，并配合\showboxes）
                head, n = node_remove(head, n)
            end
        end
        n = n.next
    end
    node.flushlist(n)
    return head, true
end

-- 挂载任务
function Moduledata.vertical_typeset.opt()
    --把`vertical_typeset.processmystuff`函数挂载到processors回调的normalizers类别中。
    nodes.tasks.appendaction("processors", "after", "Moduledata.vertical_typeset.processmystuff")
    --nodes.tasks.enableaction("processors", "vertical_typeset.processmystuff")--启用
    --nodes.tasks.disableaction("processors", "vertical_typeset.processmystuff")--停用
end

return Moduledata.vertical_typeset

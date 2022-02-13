--ah21 vertical_typeset.lua
moduledata = moduledata or {}
moduledata.vertical_typeset = moduledata.vertical_typeset or {}
vertical_typeset = moduledata.vertical_typeset

-----------------遍历结点，打印信息----------------------
local hlist_code = nodes.nodecodes.hlist
local glyphs = nodes.nodecodes.glyph
local glyph_id = node.id("glyph")
local hlist_id = node.id("hlist")
local vlist_id = node.id("vlist")
local fonthashes = fonts.hashes
local font_id_table = fonthashes.identifiers -- assumes generic font loader
local fontdata   = fonthashes.identifiers
local quaddata   = fonthashes.quads

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

function vertical_typeset.processmystuff(head)
    --for n in node.traverse_id(glyphs, head) do --在遍历中删除会造成会乱
    local n = head
    while n do
        if n.id == glyph_id then
            local n_char = n.char
            local p_to_rotate = puncs_to_rotate[n_char]
            if  c_to_vertical(n_char) or p_to_rotate then
                local l = nodes.new("hlist")
                l.list =  node.copy(n) --复制结点到新建的结点列表\hbox下
                --[[
                print(":::n 包含字符:::", nodes.toutf(n))
                -- 打印结点的所有字段信息
                print ('::::::node.fields(n.id):::::')
                for _, v in pairs(node.fields(n.id)) do
                    print(v, n[v])
                end
                -- 打印结点字模描述信息
                desc = font_id_table[n.font].descriptions[n.char]
                print ('::::::n.char font desc:::::')
                for i, v in pairs(desc) do
                    print(i,v)
                end
                print (':::::BoundingBox:::::')
                for i, k in pairs (desc.boundingbox) do
                    -- 以基线左点为原点，依次是x1、y1，x2、y2
                    print (i,k)
                end
                --]]
                local w, h, d, t = n.width, n.height, n.depth, n.total
                if p_to_rotate then
                    l.list.data = 10000 --标记，也可以标记在l.list.subtype，只怕有冲突
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
                head, l = node.insert_after(head, n, l)
                --print("::::::::::::::", nodes.toutf(head))
                --删除原结点（注释后如果要观察前后相对关系，并配合\showboxes）
                head, n = node.remove(head, n)
                --print("::::::::::::::", nodes.toutf(head))
                --print("::::::::::::::", nodes.toutf(n))
            end
        end
        n = n.next
    end
    -- print(":::旋转后nodes.tosequence(head):::")
    -- print(nodes.tosequence(head))
    return head, true
end

-- 挂载任务
function vertical_typeset.opt()
    --把`vertical_typeset.processmystuff`函数挂载到processors回调的normalizers类别中。
    nodes.tasks.appendaction("processors", "after", "vertical_typeset.processmystuff")
    --启用
    --nodes.tasks.enableaction("processors", "vertical_typeset.processmystuff")
    --停用
    --nodes.tasks.disableaction("processors", "vertical_typeset.processmystuff")
end

return vertical_typeset

--ah21 vertical_typeset.lua
Moduledata = Moduledata or {}
Moduledata.vertical_typeset = Moduledata.vertical_typeset or {}

-- 本地化以提高运行效率
local glyph_id = nodes.nodecodes.glyph --node.id("glyph")
local rule_id = nodes.nodecodes.rule
local penalty_id = nodes.nodecodes.penalty
local kern_id = nodes.nodecodes.kern
local glue_id = nodes.nodecodes.glue
local hlist_id = nodes.nodecodes.hlist
local vlist_id = nodes.nodecodes.vlist

local node_copy = node.copy
local node_getproperty = node.getproperty
local node_insertafter = node.insertafter
local node_new = node.new
local node_remove = node.remove
local node_setproperty = node.setproperty
local node_setattribute = node.setattribute
local node_getattribute = node.getattribute
local node_hasattribute = node.hasattribute

---[[ 结点跟踪工具
local function show_detail(n, label) 
    print(">>>>>>>>>"..label.."<<<<<<<<<<")
    print(nodes.toutf(n))
    for i in node.traverse(n) do
        local char
        if i.id == glyph_id then
            char = utf8.char(i.char)
            print(i, char)
        elseif i.id == penalty_id then
            print(i, i.penalty)
        elseif i.id == glue_id then
            print(i, i.width, i.stretch,i.stretchorder, i.shrink, i.shrinkorder)
        elseif i.id == hlist_id then
            print(i, nodes.toutf(i.list))
        else
            print(i)
        end
    end
end
--]]

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
                ---- 给盒子设置资产表，携带字符char(效率较低)
                -- local p = node_getproperty(l)
                -- if not p then
                --     p = {}
                --     node_setproperty(l, p)
                -- end
                -- p.char = n_char

                -- 给盒子设置属性{1：n.char}（效率更高）
                node_setattribute(l, 1, n_char)
                
                l.list =  node_copy(n) --复制结点到新建的结点列表\hbox下
                local w, h, t = n.width, n.height, n.total
                if p_to_rotate then


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
                head, n = node_remove(head, n, true)
            end
        end
        n = n.next
    end
    node.flushlist(n)
    return head, true
end

-- 把旋转过的列表中的bar rule移到外面，不旋转
function Moduledata.vertical_typeset.get_out_bar(head)
    -- 找出bar类条线rule，移动到旋转盒子外盒子外面
    local function find_rotated_hlist(head)
        local n = head
        while n do
            if node_hasattribute(n, 1) then
                -- print("=======================")
                -- print(nodes.tosequence(n.head))
                local h_head = n.head
                local t = node.tail(h_head)
                while t do
                    -- 画线rule和罚点
                    if (t.id == rule_id or t.id == hlist_id) and t.prev.id == kern_id then
                        local kern
                        local rule_or_hlist
                        h_head, t, kern = node_remove(h_head, t.prev)
                        h_head, t, rule_or_hlist = node_remove(h_head, t)
                        head, rule_or_hlist = node_insertafter(head, n, rule_or_hlist)
                        head, kern = node_insertafter(head, n, kern)
                    else
                        t = t.prev
                    end
                end
            end
            if n.id == hlist_id or n.id == vlist_id then
                find_rotated_hlist(n.head)
            end
            n = n.next
        end
    end

    find_rotated_hlist(head)

    return head, true
end

-- 挂载任务
function Moduledata.vertical_typeset.opt()
    --把`vertical_typeset.processmystuff`函数挂载到processors回调的normalizers类别中。
    nodes.tasks.appendaction("processors", "after", "Moduledata.vertical_typeset.processmystuff")
    nodes.tasks.appendaction("shipouts", "after", "Moduledata.vertical_typeset.get_out_bar")
    --nodes.tasks.enableaction("processors", "vertical_typeset.processmystuff")--启用
    --nodes.tasks.disableaction("processors", "vertical_typeset.processmystuff")--停用
end

return Moduledata.vertical_typeset

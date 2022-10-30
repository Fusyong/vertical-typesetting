Moduledata = Moduledata or {}
Moduledata.vtypeset = Moduledata.vtypeset or {}

-- 本地化以提高运行效率
local glyph_id = nodes.nodecodes.glyph --node.id("glyph")
local hlist_id = nodes.nodecodes.hlist
local vlist_id = nodes.nodecodes.vlist

local node_copy = node.copy
local node_insertafter = node.insertafter
local node_new = node.new
local node_remove = node.remove

local fonts_hashes = fonts.hashes
local fonts_hashes_identifiers   = fonts_hashes.identifiers


--[[ 结点跟踪工具
-- local rule_id = nodes.nodecodes.rule
-- local kern_id = nodes.nodecodes.kern
-- local node_getproperty = node.getproperty
-- local node_insertbefore = node.insertbefore
-- local node_setproperty = node.setproperty
-- local node_setattribute = node.setattribute
-- local node_getattribute = node.getattribute
-- local node_hasattribute = node.hasattribute
local penalty_id = nodes.nodecodes.penalty
local glue_id = nodes.nodecodes.glue

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
local function chars_to_vertical(c)
    -- 常用的汉字编码范围，还有更多
    return c >= 0x04E00 and c <= 0x09FFF
end

--需要旋转的标点符号集
local puncs_to_rotate = {
    [0x3001] = true,   -- 、
    [0xFF0C] = true,   -- ，
    [0x3002] = true,   -- 。
    [0xFF0E] = true,   -- ．
    [0xFF1F] = true,   -- ？
    [0xFF01] = true,   -- ！
    [0xFF1A] = true,  -- ：
    [0xFF1B] = true,   -- ；
}

-- 标点符号偏置缓存{font = {char = {xoffset, yoffset}, ...} ...}
local puncs_to_offset = {}

local function rotate_glyph_with_hlist(head, n, p_to_rotate)

    local l = node_new("hlist")
    local w = n.width
    l.width = w
    l.list =  node_copy(n) --复制结点到新建的结点列表\hbox下
    l.orientation = 0x203 --以基线左端为圆心顺转3*90度，即左转90度
    
    -- 一般字符偏置
    local n_font = n.font
    local font_identifier = fonts_hashes_identifiers[n_font] --字体数据
    local font_parameters = font_identifier.parameters -- 字体定义参数
    local font_descender = font_parameters.descender
    l.yoffset = - font_descender
    l.xoffset = - font_descender
    
    -- 旋转后竖排标点的调整
    if p_to_rotate then
        -- 字符原始描述
        local n_char = n.char
        local xoffset
        local yoffset

        local offset_font = puncs_to_offset[n_font]
        if offset_font and offset_font[n_char]then
            -- 取缓存表数据
            xoffset = offset_font[n_char][1]
            yoffset = offset_font[n_char][2]
        else
            -- 计算并缓存
            puncs_to_offset[n_font] = puncs_to_offset[n_font] or {}
            
            local vfactor = font_parameters.vfactor
            local char_font_desc = font_identifier.descriptions[n_char]
            local width = char_font_desc.width
            local height = char_font_desc.height
            local depth = char_font_desc.depth or -char_font_desc.boundingbox[2]
            local font_ascender = font_parameters.ascender
            local x1 = char_font_desc.boundingbox[1]
            local x2 = char_font_desc.boundingbox[3]
            
            local total = height + depth
            if total < (width / 2) then
                -- 保留横排是固定留空（x1）
                xoffset = font_ascender - (x1 + height) * vfactor
            else
                -- 居中(基线居中，再字中线居中)
                xoffset = (font_ascender - w/2) - (total / 2  - depth) * vfactor
            end
            
            local hfactor = font_parameters.hfactor
            -- 字符内框以行中线为准镜像到对侧（上侧）
            yoffset = font_ascender - font_descender - ((x2- x1) * hfactor - 2 * (font_descender - x1 *hfactor) )

            puncs_to_offset[n_font][n_char] = {xoffset, yoffset}
        end

        l.yoffset = l.yoffset + yoffset
        l.xoffset = l.xoffset - xoffset
    end

    -- 替换原结点
    head, l = node_insertafter(head, n, l)
    head, l = node_remove(head, n, true)

    return head, l
end

-- 旋转需要直排的字符
function Moduledata.vtypeset.rotate_all(head)
    -- 找出bar类条线rule，移动到旋转盒子外盒子外面
    local function find_rotated_hlist(list, is_top_level)
        
        -- 顶层例外（输入为head）；也不考虑字符旋转需求
        local n
        if is_top_level then
            n = list
        else
            n = list.head
        end
        
        while n do
            if n.id == hlist_id or n.id == vlist_id then
                -- 递归
                n = find_rotated_hlist(n, false)
            elseif n.id == glyph_id then
                local n_char = n.char
                local p_to_rotate = puncs_to_rotate[n_char]
                local c_to_vertical = chars_to_vertical(n_char)
                if c_to_vertical or p_to_rotate then
                    -- 当列表头本身需要旋转/已经改变时，必须更换
                    -- 仅为下层（顶层不会有这样旋转字符）
                    list.head, n =rotate_glyph_with_hlist(list.head, n, p_to_rotate)
                end
            end
            n = n.next
        end

        node.flushlist(n)

        return list
    end
    
    head = find_rotated_hlist(head, true)

    return head, done
end

-- 挂载任务
function Moduledata.vtypeset.append()
    --把`vtypeset.processmystuff`函数挂载到processors回调的normalizers类别中。
    -- nodes.tasks.appendaction("processors", "after", "Moduledata.vtypeset.processmystuff")
    nodes.tasks.appendaction("shipouts", "after", "Moduledata.vtypeset.rotate_all")
    Moduledata.vtypeset.appended = true --挂载标记 TODO 优化
    --nodes.tasks.enableaction("processors", "vtypeset.processmystuff")--启用
    --nodes.tasks.disableaction("processors", "vtypeset.processmystuff")--停用
end

return Moduledata.vtypeset

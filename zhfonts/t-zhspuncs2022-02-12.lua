--ah21 t-zhspuncs.lua
moduledata = moduledata or {}
moduledata.zhspuncs = moduledata.zhspuncs or {}
zhspuncs = moduledata.zhspuncs
-- zhspuncs = zhspuncs or {}

local hlist = nodes.nodecodes.hlist
local glyph   = nodes.nodecodes.glyph --node.id ('glyph')
local fonthashes = fonts.hashes
local fontdata   = fonthashes.identifiers
local quaddata   = fonthashes.quads
local node_count = node.count
local node_dimensions = node.dimensions
local node_traverse_id = node.traverse_id
local node_traverse = node.traverse
local insert_before = node.insert_before
local insert_after = node.insert_after
local new_kern = nodes.pool.kern
local tasks = nodes.tasks



-- 标点单用时左、右的预期留空率，有后续标点时的调整比例
-- 比如`“`，单用时左、右空率0.5、0.1，后续标点时0.5*0.5、0.1*1.0
-- TODO 改成按字体信息逐一计算（性能问题？？？）；
-- 分出cp、pc、pp、ppc四种模式；或再左右标点分组？？？
local puncs = {
    -- 左半标点
    [0x2018] = {0.5, 0.1, 1.0, 1.0}, -- ‘
    [0x201C] = {0.5, 0.1, 0.5, 1.0}, -- “
    [0x3008] = {0.3, 0.1, 0.4, 1.0}, -- 〈
    [0x300A] = {0.5, 0.1, 0.4, 1.0}, -- 《
    [0x300C] = {0.5, 0.1, 0.4, 1.0}, -- 「
    [0x300E] = {0.5, 0.1, 0.4, 1.0}, -- 『
    [0x3010] = {0.5, 0.1, 0.4, 1.0}, -- 【
    [0x3014] = {0.5, 0.1, 0.4, 1.0}, -- 〔
    [0x3016] = {0.5, 0.1, 0.4, 1.0}, -- 〖
    [0xFF08] = {0.5, 0.1, 0.4, 1.0}, -- （
    [0xFF3B] = {0.5, 0.1, 0.4, 1.0}, -- ［
    [0xFF5B] = {0.5, 0.1, 0.4, 1.0}, -- ｛
    -- 右半标点
    [0x2019] = {0.1, 0.5, 1.0, 0.0}, -- ’
    [0x201D] = {0.1, 0.5, 1.0, 0.0}, -- ”
    [0x3009] = {0.1, 0.3, 1.0, 0.4}, -- 〉
    [0x300B] = {0.1, 0.5, 1.0, 0.4}, -- 》
    [0x300D] = {0.1, 0.5, 1.0, 0.4}, -- 」
    [0x300F] = {0.1, 0.5, 1.0, 0.4}, -- 』
    [0x3011] = {0.1, 0.5, 1.0, 0.4}, -- 】
    [0x3015] = {0.1, 0.5, 1.0, 0.4}, -- 〕
    [0x3017] = {0.1, 0.5, 1.0, 0.4}, -- 〗
    [0xFF09] = {0.1, 0.5, 1.0, 0.4}, -- ）
    [0xFF3D] = {0.1, 0.5, 1.0, 0.4}, -- ］
    [0xFF5D] = {0.1, 0.5, 1.0, 0.4}, -- ｝
    -- 独立右标点
    [0x3001] = {0.15, 0.5, 1.0, 0.5},   -- 、
    [0x3002] = {0.15, 0.5, 1.0, 0.5},   -- 。
    [0xFF0C] = {0.15, 0.5, 1.0, 0.5},   -- ，
    [0xFF0E] = {0.15, 0.5, 1.0, 0.5},   -- ．
    [0xFF1A] = {0.15, 0.5, 1.0, 0.5},   -- ：
    [0xFF1B] = {0.15, 0.5, 1.0, 0.5},   -- ；
    [0xFF01] = {0.15, 0.5, 1.0, 0.5},   -- ！
    [0xFF1F] = {0.15, 0.5, 1.0, 0.5},   -- ？
    [0xFF05] = {0.00, 0.0, 1.0, 0.5},    -- ％
    [0x2500] = {0.00, 0.0, 1.0, 1.0},    -- ─
    -- 双用左右皆可，单用仅在文右
    [0x2014] = {0.00, 0.0, 1.0, 1.0}, -- — 半字线
    [0x2026] = {0.10, 0.1, 1.0, 1.0},    -- …
}

-- 旋转过的标点（装在hlist中，n.head.data=10000）
local puncs_r = {
    [0x3001] = {0.15, 0.6, 1.0, 0.1},   -- 、
    [0x3002] = {0.15, 0.6, 1.0, 0.1},   -- 。
    [0xFF0C] = {0.15, 0.6, 1.0, 0.1},   -- ，
    [0xFF0E] = {0.15, 0.6, 1.0, 0.1},   -- ．
    [0xFF1A] = {0.15, 0.8, 1.0, 0.8},   -- ：
    [0xFF01] = {0.15, 0.8, 1.0, 0.8},   -- ！
    [0xFF1B] = {0.15, 0.8, 1.0, 0.8},   -- ；
    [0xFF1F] = {0.15, 0.8, 0.7, 0.7},   -- ？
}

-- 是标点结点(false,glyph:1,hlist:2)
local function is_punc_glyph_or_hlist(n)
    if n.id == glyph and puncs[n.char] then
        return 1
    elseif n.id == hlist and n.head and n.head.data and n.head.data == 10000 and puncs[n.head.char] then --n.head.data == 10000 是直排插件所作的标记
        return 2
    else
        return false
    end
end

-- 左标点在行头时的左移比例(数据暂用puncs第一个代替)
local left_puncs = {
    [0x2018] = 0.35, -- ‘
    [0x201C] = 0.35, -- “
    [0x3008] = 0.35, -- 〈
    [0x300A] = 0.35, -- 《
    [0x300C] = 0.35, -- 「
    [0x300E] = 0.35, -- 『
    [0x3010] = 0.35, -- 【
    [0x3014] = 0.35, -- 〔
    [0x3016] = 0.35, -- 〖
    [0xFF08] = 0.35, -- （
    [0xFF3B] = 0.35, -- ［
    [0xFF5B] = 0.35  -- ｛
}

-- 是左标点
local function is_left_punc(n)
    local type_flag = is_punc_glyph_or_hlist(n)
    if (type_flag == 1 and left_puncs[n.char]) or (type_flag == 2 and left_puncs[n.head.char]) then
        return true
    else
        return false
    end
end

-- 后一个字符节点（包括包含旋转标点的hlist）是标点
local function next_is_punc(n)
    local next_n = n.next
    while next_n do
        if next_n.id == glyph or next_n.id == hlist then
            if is_punc_glyph_or_hlist(next_n) then
                return true
            else
                return false
            end
        end
        next_n = next_n.next
    end
end

-- 前一个字符节点（包括包含旋转标点的hlist）是标点
local function pre_is_punc(n)
    local prev_n = n.prev
    while prev_n do
        if prev_n.id == glyph or prev_n.id == hlist then
            if is_punc_glyph_or_hlist(prev_n) then
                return true
            else
                return false
            end
        end
        prev_n = prev_n.prev
    end
end

-- 本结点与前后是不是标点：false，only，with_pre， with_next，all
local function is_zhcnpunc_node_group (n)
    local pre = pre_is_punc(n)
    local current = is_punc_glyph_or_hlist(n)
    local next = next_is_punc(n)
    if current then
        if next and pre then
            return "all"
        elseif next then
            return "with_next"
        elseif pre then
            return "with_pre"
        else
            return "only"
        end
    else
        return false
    end
end

-- 是cjk_ideo（未使用）
local function is_cjk_ideo (n)
    -- CJK Ext A
    if n.char >= 13312 and n.char <= 19893 then
        return true
    -- CJK
    elseif n.char >= 19968 and n.char <= 40891 then
        return true
    -- CJK Ext B
    elseif n.char >= 131072 and n.char <= 173782 then
        return true
    else
        return false
    end
end

-- 空铅/嵌块(quad)
local function quad_multiple (font, r)
    local quad = quaddata[font]
    return r * quad
end

-- 处理每个标点前后的kern
local function process_punc (head, n, punc_flag)
    local is_glyph = (is_punc_glyph_or_hlist(n) == 1)
    local is_hlist = (is_punc_glyph_or_hlist(n) == 2)
    local current_glyph_node
    local current_puncs_table
    if is_glyph then
        current_glyph_node = n
        current_puncs_table = puncs
    elseif is_hlist then
        current_glyph_node = n.head
        current_puncs_table = puncs_r
    end
    -- 取得结点字体的描述（未缩放的原始字模信息）
    local desc = fontdata[current_glyph_node.font].descriptions[current_glyph_node.char]
    if not desc then return end
    local quad = quad_multiple (current_glyph_node.font, 1)

    local l_space = desc.boundingbox[1] / desc.width --左空比例
    local r_space = (desc.width - desc.boundingbox[3]) / desc.width --右空比例
    local l_kern, r_kern = 0.0, 0.0

    -- 仅本结点是标点
    if punc_flag == "only" then
        l_kern = (current_puncs_table[current_glyph_node.char][1] - l_space) * quad
        r_kern = (current_puncs_table[current_glyph_node.char][2] - r_space) * quad
    -- 本结点和后一个结点都是标点
    elseif punc_flag == "with_pre" then
        l_kern = (current_puncs_table[current_glyph_node.char][1] * current_puncs_table[current_glyph_node.char][3] - l_space) * quad
    elseif punc_flag == "with_next" then
        r_kern = (current_puncs_table[current_glyph_node.char][2] * current_puncs_table[current_glyph_node.char][4] - r_space) * quad
    elseif punc_flag == "all" then
        l_kern = (current_puncs_table[current_glyph_node.char][1] * current_puncs_table[current_glyph_node.char][3] - l_space) * quad
        r_kern = (current_puncs_table[current_glyph_node.char][2] * current_puncs_table[current_glyph_node.char][4] - r_space) * quad
    end

    insert_before (head, n, new_kern (l_kern))
    insert_after (head, n, new_kern (r_kern))
end

-- 迭代段落结点列表，处理标点组
local function compress_punc (head)
    for n in node_traverse(head) do
        if is_punc_glyph_or_hlist(n) then
            local n_flag = is_zhcnpunc_node_group (n)
            -- 至少本结点是标点
            if n_flag then
                process_punc (head, n, n_flag)
            end
        end
    end
end

-- 包装回调任务：分行前的过滤器
function zhspuncs.my_linebreak_filter (head, is_display)
    compress_punc (head)
    return head, true
end

-- 分行后处理对齐
function zhspuncs.align_left_puncs(head)
    local it = head
    while it do
        if it.id == hlist then
            local e = it.head
            local neg_kern = nil
            local hit = nil
            while e do
                if is_punc_glyph_or_hlist(e) then
                    if is_left_punc(e) then
                        hit = e
                    end
                    break
                end
                e = e.next
            end
            if hit ~= nil then
                -- 文本行整体向左偏移
                neg_kern = -puncs[hit.char][1] * quad_multiple(hit.font, 1) * 0.7 --ah21
                -- neg_kern = -left_puncs[hit.char] * quad_multiple(hit.font, 1) --ah21
                insert_before(head, hit, new_kern(neg_kern))
                -- 统计字符个数
                local w = 0
                local x = hit
                while x do
                    if is_punc_glyph_or_hlist(x) then w = w + 1 end
                    x = x.next
                end
                if w == 0 then w = 1 end
                -- 将 neg_kern 分摊出去
                x = it.head -- 重新遍历
                local av_neg_kern = -neg_kern/w
                local i = 0
                while x do
                    if is_punc_glyph_or_hlist(x) then
                        i = i + 1
                        -- 最后一个字符之后不插入 kern
                        if i < w then 
                            insert_after(head, x, new_kern(av_neg_kern))
                        end
                    end
                    x = x.next
                end
            end
        end
        it = it.next
    end
    return head, done
end

-- 挂载任务
function zhspuncs.opt ()
    -- 段落分行前回调（最后调用）
    tasks.appendaction("processors","after","zhspuncs.my_linebreak_filter")
    -- 段落分行后回调（最后调用）
    nodes.tasks.appendaction("finalizers", "after", "zhspuncs.align_left_puncs")
end

-- 未使用？？？
fonts.protrusions.vectors['myvector'] = {  
   [0xFF0c] = { 0, 0.60 },  -- ，
   [0x3002] = { 0, 0.60 },  -- 。
   [0x2018] = { 0.60, 0 },  -- ‘
   [0x2019] = { 0, 0.60 },  -- ’
   [0x201C] = { 0.50, 0 },  -- “
   [0x201D] = { 0, 0.35 },  -- ”
   [0xFF1F] = { 0, 0.60 },  -- ？
   [0x300A] = { 0.60, 0 },  -- 《
   [0x300B] = { 0, 0.60 },  -- 》
   [0xFF08] = { 0.50, 0 },  -- （
   [0xFF09] = { 0, 0.50 },  -- ）
   [0x3001] = { 0, 0.50 },  -- 、
   [0xFF0E] = { 0, 0.50 },  -- ．
}

-- 未使用？？？
fonts.protrusions.classes['myvector'] = {
   vector = 'myvector', factor = 1
}

return zhspuncs


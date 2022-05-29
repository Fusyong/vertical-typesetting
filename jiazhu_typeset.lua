--ah21 jiazhu_typeset.lua
moduledata = moduledata or {}
moduledata.jiazhu_typeset = moduledata.jiazhu_typeset or {}
jiazhu_typeset = moduledata.jiazhu_typeset

-----------------遍历结点，打印信息----------------------
local glyph_id = nodes.nodecodes.glyph --node.id("glyph")
local hlist_id = nodes.nodecodes.hlist --node.id("hlist")
local vlist_id = nodes.nodecodes.vlist --node.id("vlist")

-- 根据指定宽度重排vbox
local function rewide(vbox)

    print(">>>>>>>>>>>>>>>>>>>>>>")
    local w = tex.box[0].width
    print(w)
    local vb0 = node.copy_list(tex.box[0])
    print(vb0)

end

-- 根据指定宽度重排vbox
local function split_vox(vbox)

    print(">>>>>>>>>>>>>>>>>>>>>>")
    local w = tex.box[0].width
    print(w)
    local vb0 = node.copy_list(tex.box[0])
    print(vb0)

end

function jiazhu_typeset.jiazhu()
    --context.vtop(s)
    -- 输出
    context(tex.box[0])
    --split_and_rewide()
    
end


--判断是不是汉字（是否需要直排）
local function c_to_jiazhu(c)
    -- 常用的汉字编码范围，还有更多
    return c >= 0x04E00 and c <= 0x09FFF
end


-- 旋转汉字和部分标点
function jiazhu_typeset.processmystuff(head)
    local n = head
    while n do --不在node.traverse_id()中增删结点，以免引用混乱
        if n.id == hlist_id then
            -- print(nodes.toutf(n.head))
            local v , vb = node.findattribute(n.head, 2)
            -- print(v,vb)
            if v and (v == 222) and vb.id == vlist_id then
                print(">>>>>>>>>>>>>>>>>>>>>>>>")
                print(nodes.tosequence(vb))
                print(nodes.toutf(vb))
                local width_left, _, _ = node.dimensions(
                    n.glue_set,
                    n.glue_sign,
                    n.glue_order,
                    n.head,
                    vb
                )

                local line_num = node.count(hlist_id, vb.list)
                local new_list = unpack(vb.list)
                print(line_num)
                for l in node.traverse_id(hlist_id, vb.list) do
                    print("-------")
                    print(nodes.toutf(l.list))
                end

                print("width_left", width_left)
                print(vb.width)
                print(tex.dimen.hsize)
                print(tex.dimen.linewidth)

                -- local vlist = tex.splitbox(n,height,mode)
                -- unhbox, unvbox, unhcopy, unvcopy
            end

            --[[
            print("---HList---")
            -- print(nodes.tosequence(n))
            print("tex.dimen.linewidth",tex.dimen.linewidth)
            print("n.width",n.width)
            for t in node.traverse_id(glyph_id, n.head) do
                -- print(nodes.tosequence(t))
                print(nodes.toutf(t))
                -- 后面的实际宽度（包括突出）、高度、深度
                print (node.dimensions(
                    n.glue_set,
                    n.glue_sign,
                    n.glue_order,
                    t,
                    node.tail(t)
                ))
                print (node.dimensions(
                    n.glue_set,
                    n.glue_sign,
                    n.glue_order,
                    t,
                    jiazhu_typeset.glyph_boundary(t)
                ))
            end
            --]]
        end
        n = n.next
    end
    return head, true
end

-- 找最后一个字模结点
function jiazhu_typeset.glyph_boundary(head)
    local n = head
    local tail = node.tail(n)
    while tail do
        if tail.id == glyph_id then
            return tail.next
        else
            tail = tail.prev
        end
    end
    return nil
end

-- 挂载任务
function jiazhu_typeset.opt()
    --把`jiazhu_typeset.processmystuff`函数挂载到finalizers回调的normalizers类别中。
    nodes.tasks.appendaction("finalizers", "before", "jiazhu_typeset.processmystuff")
    --nodes.tasks.enableaction("finalizers", "jiazhu_typeset.processmystuff")--启用
    --nodes.tasks.disableaction("finalizers", "jiazhu_typeset.processmystuff")--停用
end

return jiazhu_typeset

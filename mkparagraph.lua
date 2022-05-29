function mknodes( text )
  local current_font = font.current()
  local font_parameters = font.getfont(current_font).parameters
  local n, head, last
  -- we should insert the paragraph indentation at the beginning
  head = node.new("glue")
  head.spec = node.new("glue_spec")
  head.spec.width = 20 * 2^16
  last = head

  for s in string.utfvalues( text ) do
    local char = unicode.utf8.char(s)
    if unicode.utf8.match(char,"%s") then
      -- its a space
      n = node.new("glue")
      n.spec = node.new("glue_spec")
      n.spec.width   = font_parameters.space
      n.spec.shrink  = font_parameters.space_shrink
      n.spec.stretch = font_parameters.space_stretch
    else -- a glyph
      n = node.new("glyph")
      n.font = current_font
      n.subtype = 1
      n.char = s
      n.lang = tex.language
      n.uchyph = 1
      n.left = tex.lefthyphenmin
      n.right = tex.righthyphenmin
    end
    last.next = n
    last = n
  end
  
  -- now add the final parts: a penalty and the parfillskip glue
  local penalty = node.new("penalty")
  penalty.penalty = 10000

  local parfillskip = node.new("glue")
  parfillskip.spec = node.new("glue_spec")
  parfillskip.spec.stretch = 2^16
  parfillskip.spec.stretch_order = 2
  
  last.next = penalty
  penalty.next = parfillskip

  -- just to create the prev pointers for tex.linebreak
  node.slide(head)
  return head
end


local txt = "A wonderful serenity has taken possession of my entire soul, like these sweet mornings of spring which I enjoy with my whole heart. I am alone, and feel the charm of existence in this spot, which was created for the bliss of souls like mine."

tex.baselineskip = node.new("glue_spec")
tex.baselineskip.width = 14 * 2^16

local head = mknodes(txt)
lang.hyphenate(head)
head = node.kerning(head)
head = node.ligaturing(head)

local vbox = tex.linebreak(head,{ hsize = tex.sp("3in")})
node.write(vbox)
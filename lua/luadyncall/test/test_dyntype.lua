require "dynstruct"
regstructinfo("Rect{i x i y i w i h}")
x = gettypeinfo("Rect")
dumptypeinfo(x)
-- dumptypeinfos()
y = newdynstruct("Rect")

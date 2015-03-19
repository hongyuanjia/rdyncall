require "dynstruct"

regstructinfo("Rect{cccc}x y z w;")
x = newdynstruct("Rect")
print(x.x)
x.x = -34
print(x.x)


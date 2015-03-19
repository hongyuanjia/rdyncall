require "ldyntype"

-- utilities
 
local function align(x, align)
  return math.floor( ( x + (align-1) ) / align ) * align
end

-- typeinfo table constructors

function typeinfo_base(signature, size, align)
  return { name = signature, signature = signature, class = "base", size = size, align = align } 
end

function typeinfo_ptr(signature, basetypeinfo, ptrlevels)
  return { name = signature, signature = signature, class = "ptr", basetypeinfo = basetypeinfo, ptrlevels = ptrlevels, size = _TI.p.size, align = _TI.p.align }
end

function typeinfo_struct(name, signature, size, align, fields)
  return { name = name, signature = signature, class = "struct" , size = size, align = align , fields = fields }
end

local function istypeinfo(typespec)
  return type(typespec) == "table"
end

function typeinfo_tostring(typename)
  local ti = gettypeinfo(typename)
  local s = ti.name .. "\tsize=" .. ti.size .. "\talign=" .. ti.align 
  if ti.basetypeinfo then
    local baseti = gettypeinfo(ti.basetypeinfo)
    if baseti.name then
      s = s .. "\tbase=" .. baseti.name
    else
      s = s .. "\tbase=" .. baseti
    end
  end
  if ti.fields then
    for k, v in pairs(ti.fields) do
      s = s .. "\n- "..k .. ":\toffset=" .. v.offset 
    end
  end
  return s
end


-- typeinfo registry

_TI = { } 

function settypeinfo(name,info)
  _TI[name] = info
end

function gettypeinfo(typespec)
  if istypeinfo(typespec) then return typespec end
  local typeinfo = _TI[typespec]
  if not typeinfo then -- pointer type ?
    local ptrs, basename = typespec:match("(%**)<(%a+)>")
    if ptrs and basename then -- pointer type signature:
      typeinfo = typeinfo_ptr( typespec, gettypeinfo(basename), #ptrs)
      settypeinfo(typespec, typeinfo)
    end -- else, typespec remains a string (unknown type)
  end
  return typeinfo
end

function dumptypeinfos()
  for k,v in pairs(_TI) do
    print(typeinfo_tostring(v))
  end
end

function dumptypeinfo(x)
  print(typeinfo_tostring(x))
end

-- 

local function regbasetypes()
  local sigs = "BcCsSiIjJlLpZ"
  for typechar in sigs:gmatch(".") do
    settypeinfo(typechar, typeinfo_base( typechar, ldyntype.dtSize(typechar), ldyntype.dtAlign(typechar) ) )
  end
end

function regstructinfo(structsignature)
  local name, typeclass, signature, fieldnames = structsignature:match("(%a+)([{|])(.+)%}(.+)")
 
  if name and type and signature then
    local offset   = 0
    local maxalign = 0
    local maxsize  = 0
    local fields   = { }

    local fieldname = signature:gmatch("(%S+)")

    for typespec, fieldname in signature:gmatch("(%S)") do

      local typeinfo = gettypeinfo(typespec)

      offset = align(offset, typeinfo.align)
      maxalign = math.max(typeinfo.align,maxalign)
      maxsize  = math.max(typeinfo.size, maxsize)

      fields[fieldname] = { offset = offset, typeinfo = typeinfo }

      if typeclass == "{" then -- structure
        offset = offset + typeinfo.size
      end

    end

    local structsize

    if typeclass == "|" then
      structsize = maxsize
    else
      structsize = offset
    end
   
    settypeinfo(name, typeinfo_struct(name, signature, structsize, maxalign, fields) )
  end

end

function regstructinfo_backup(structsignature)
  local name, typeclass, signature = structsignature:match("(%a+)([{|])(.+)%}")
 
  if name and type and signature then
    local offset   = 0
    local maxalign = 0
    local maxsize  = 0
    local fields   = { }
    for typespec, fieldname in signature:gmatch("(%S+)%s+(%S+)") do

      local typeinfo = gettypeinfo(typespec)

      offset = align(offset, typeinfo.align)
      maxalign = math.max(typeinfo.align,maxalign)
      maxsize  = math.max(typeinfo.size, maxsize)

      fields[fieldname] = { offset = offset, typeinfo = typeinfo }

      if typeclass == "{" then -- structure
        offset = offset + typeinfo.size
      end

    end

    local structsize

    if typeclass == "|" then
      structsize = maxsize
    else
      structsize = offset
    end
   
    settypeinfo(name, typeinfo_struct(name, signature, structsize, maxalign, fields) )
  end

end

function parsebasetypes(basetypesignature)
  for type,size,align in basetypesignature:gmatch("(%a+)%s+(%d)%s+(%d)%s*") do
    settypeinfo(type, {signature=type,base=type,class="storage",size=size,align=align})
  end
end

-- initialize typeinfo registry

regbasetypes()


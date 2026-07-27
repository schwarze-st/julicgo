using Printf

"""
  split_top(s::AbstractString; sep=';')

Teilt `s` nur an den Trenn‐Semikolons `sep`, die *nicht* innerhalb
einer eckigen Klammernestung stehen. Liefert einen Vektor von Strin•gs.
"""
function split_top(s::AbstractString; sep=';')
    parts = String[]
    buf   = IOBuffer()   # sammelt Zeichen für das aktuelle Part
    depth = 0            # Zähle '[' als +1, ']' als –1
    for c in s
        if c == '['
            depth += 1
            write(buf, c)
        elseif c == ']'
            depth = max(depth-1, 0)
            write(buf, c)
        elseif c == sep && depth == 0
            # Top-Level-Sep gefunden → Part abschließen
            push!(parts, String(take!(buf)))
        else
            write(buf, c)
        end
    end
    # Rest in Buffer noch hinzu
    push!(parts, String(take!(buf)))
    return parts
end

"""
  detect_bounds(str::String, var::Char, lb::Vector{Float64}, ub::Vector{Float64})

Sucht in `str` nach Ausdrücken der Form

A)  Einzel‐Index‐Bounds für x[i] bzw. y[i]:
   1.a)  x[i] -  c   ⇒  x[i] <=  c
   1.b) -c + x[i]    ⇒  x[i] <=  c
   2.a)  x[i] +  c   ⇒  x[i] <= -c
   2.b)  c + x[i]    ⇒  x[i] <= -c
   3.a) -x[i] +  c   ⇒  x[i] >=  c
   3.b)  c - x[i]    ⇒  x[i] >=  c
   4.a) -x[i] -  c   ⇒  x[i] >= -c
   4.b) -c - x[i]    ⇒  x[i] >= -c
   5)    x[i]        ⇒  x[i] <=  0
   6)   -x[i]        ⇒  x[i] >=  0

B)  Globale Bounds (für alle Komponenten von x oder y):
   analog zu A), nur ohne Index ‑ wird auf jeden Eintrag angewandt

C)  Vektor‐Bounds der Form
   1.a)  x - [...]'    ⇒  x[j] <=   [...]₍ⱼ₎
   1.b) -[...]' + x    ⇒  x[j] <=   [...]₍ⱼ₎
   2.a)  x + [...]'   ⇒  x[j] <=  -[...]₍ⱼ₎
   2.b)  [...]' + x   ⇒  x[j] <=  -[...]₍ⱼ₎
   3.a)  [...]' - x   ⇒  x[j] >=   [...]₍ⱼ₎
   3.b) -x + [...]'   ⇒  x[j] >=   [...]₍ⱼ₎
   4.a) -[...]' - x   ⇒  x[j] >=  -[...]₍ⱼ₎
   4.b)  x - [...]'   ⇒  x[j] >=  -[...]₍ⱼ₎

Dabei ist `[...]'` ein row‐vector‐Literal, z.B. `[1 2 3]'` oder `[1;2;3]'`.  
Returns `(found::Bool, lb, ub)`, wobei `found=true`, sobald irgendein Pattern passt.
"""
function detect_bounds(str::AbstractString, var::Char, lb::Vector{Float64}, ub::Vector{Float64})
    found = false
    full_dim = true
    dim   = length(lb)
    lb = copy(lb)
    ub = copy(ub)

    # Patterns
    numpat    = raw"(?:(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|pi)"
    idx_i     = raw"\((\d+)\)"
    varpat    = string(var)           # "x" oder "y"
    vecnumpat = raw"\[(.*?)\]'?"

    # A) Einzel‐Index‐Bounds
    # 1.a) x[i] - c
    if (m = match(Regex("^\\s*$(varpat)$(idx_i)\\s*-\\s*($numpat)\\s*\$"), str)) !== nothing
        i = parse(Int,   m.captures[1])
        c = parse(Float64, m.captures[2])
        ub[i] = min(ub[i], c); found = true; full_dim = false

    # 1.b) -c + x[i]
    elseif (m = match(Regex("^\\s*-\\s*($numpat)\\s*\\+\\s*$(varpat)$(idx_i)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        i = parse(Int,     m.captures[2])
        ub[i] = min(ub[i], c); found = true; full_dim = false

    # 2.a) x[i] + c
    elseif (m = match(Regex("^\\s*$(varpat)$(idx_i)\\s*\\+\\s*($numpat)\\s*\$"), str)) !== nothing
        i = parse(Int,   m.captures[1])
        c = parse(Float64, m.captures[2])
        ub[i] = min(ub[i], -c); found = true; full_dim = false

    # 2.b) c + x[i]
    elseif (m = match(Regex("^\\s*($numpat)\\s*\\+\\s*$(varpat)$(idx_i)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        i = parse(Int,     m.captures[2])
        ub[i] = min(ub[i], -c); found = true; full_dim = false

    # 3.a) -x[i] + c
    elseif (m = match(Regex("^\\s*-\\s*$(varpat)$(idx_i)\\s*\\+\\s*($numpat)\\s*\$"), str)) !== nothing
        i = parse(Int,   m.captures[1])
        c = parse(Float64, m.captures[2])
        lb[i] = max(lb[i], c); found = true; full_dim = false

    # 3.b) c - x[i]
    elseif (m = match(Regex("^\\s*($numpat)\\s*-\\s*$(varpat)$(idx_i)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        i = parse(Int,     m.captures[2])
        lb[i] = max(lb[i], c); found = true; full_dim = false

    # 4.a) -x[i] - c
    elseif (m = match(Regex("^\\s*-\\s*$(varpat)$(idx_i)\\s*-\\s*($numpat)\\s*\$"), str)) !== nothing
        i = parse(Int,   m.captures[1])
        c = parse(Float64, m.captures[2])
        lb[i] = max(lb[i], -c); found = true; full_dim = false

    # 4.b) -c - x[i]
    elseif (m = match(Regex("^\\s*-\\s*($numpat)\\s*-\\s*$(varpat)$(idx_i)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        i = parse(Int,     m.captures[2])
        lb[i] = max(lb[i], -c); found = true; full_dim = false

    # 5) x[i]
    elseif (m = match(Regex("^\\s*$(varpat)$(idx_i)\\s*\$"), str)) !== nothing
        i = parse(Int, m.captures[1])
        ub[i] = min(ub[i], 0.0); found = true; full_dim = false

    # 6) -x[i]
    elseif (m = match(Regex("^\\s*-\\s*$(varpat)$(idx_i)\\s*\$"), str)) !== nothing
        i = parse(Int, m.captures[1])
        lb[i] = max(lb[i], 0.0); found = true; full_dim = false

    # B) Globale Bounds (für alle Indizes)
    elseif (m = match(Regex("^\\s*$(varpat)\\s*-\\s*($numpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        ub .= min.(ub, c); found = true

    elseif (m = match(Regex("^\\s*-\\s*($numpat)\\s*\\+\\s*$(varpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        ub .= min.(ub, c); found = true

    elseif (m = match(Regex("^\\s*$(varpat)\\s*\\+\\s*($numpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        ub .= min.(ub, -c); found = true

    elseif (m = match(Regex("^\\s*($numpat)\\s*\\+\\s*$(varpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        ub .= min.(ub, -c); found = true

    elseif (m = match(Regex("^\\s*-\\s*$(varpat)\\s*\\+\\s*($numpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        lb .= max.(lb, c); found = true

    elseif (m = match(Regex("^\\s*($numpat)\\s*-\\s*$(varpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        lb .= max.(lb, c); found = true

    elseif (m = match(Regex("^\\s*-\\s*$(varpat)\\s*-\\s*($numpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        lb .= max.(lb, -c); found = true

    elseif (m = match(Regex("^\\s*-\\s*($numpat)\\s*-\\s*$(varpat)\\s*\$"), str)) !== nothing
        c = parse(Float64, m.captures[1])
        lb .= max.(lb, -c); found = true

    elseif (match(Regex("^\\s*$(varpat)\\s*\$"), str)) !== nothing 
        ub .= min.(ub, 0.0); found = true

    elseif (match(Regex("^\\s*-\\s*$(varpat)\\s*\$"), str)) !== nothing 
        lb .= max.(lb, 0.0); found = true

    # C) Vektor‐Bounds mit "[...]'"
    elseif (m = match(Regex("^\\s*$(varpat)\\s*\\-\\s*$(vecnumpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            ub[j] = min(ub[j], vals[j])
        end
        found = true
    elseif (m = match(Regex("^\\s*-\\s*$(varpat)\\s*\\-\\s*$(vecnumpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            lb[j] = max(lb[j], -vals[j])
        end
        found = true
    elseif (m = match(Regex("^\\s*-\\s*$(vecnumpat)\\s*\\+\\s*$(varpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            ub[j] = min(ub[j], vals[j])
        end
        found = true

    elseif (m = match(Regex("^\\s*$(varpat)\\s*\\+\\s*$(vecnumpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            ub[j] = min(ub[j], -vals[j])
        end
        found = true
    elseif (m = match(Regex("^\\s*-\\s*$(varpat)\\s*\\+\\s*$(vecnumpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            lb[j] = max(lb[j], vals[j])
        end
        found = true
    elseif (m = match(Regex("^\\s*$(vecnumpat)\\s*\\+\\s*$(varpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            ub[j] = min(ub[j], -vals[j])
        end
        found = true

    elseif (m = match(Regex("^\\s*$(vecnumpat)\\s*-\\s*$(varpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            lb[j] = max(lb[j], vals[j])
        end
        found = true

    elseif (m = match(Regex("^\\s*-\\s*$(vecnumpat)\\s*-\\s*$(varpat)\\s*\$"), str)) !== nothing
        vals = [parse(Float64,t) for t in split(m.captures[1], r"[;,\s]+") if !isempty(t)]
        for j in 1:min(dim,length(vals))
            lb[j] = max(lb[j], -vals[j])
        end
        found = true
    end

    return found, full_dim, lb, ub
end

function translate_syntax(expr, NX, NY)
    # Zeilenvektoren → Spaltenvektoren'
    expr = replace(expr,
      # (?<!\[)      : Stelle sicher, daß links kein '[' steht
      # []           : erste Zeichengruppe darf kein ], , ; oder whitespace enthalten
      # ([]+[]+)     : mindestens eine weitere solche Zeichengruppe mit Trennzeichen " " oder "," davor    
      # (?!')        : nur wenn direkt dahinter kein ' steht
      r"(?<!\[)\[([^\[\],;\s]+(?:[ ,]+[^\[\],;\s]+)+)\](?!')" => (inner::SubString) -> begin
        parts = split(inner, r"[,\s]+")
        return join(parts, "; ") * "'"
      end
    )
    # diag([1; 2; 3]')/diag([1; 2; 3]) → Diagonal([1; 2; 3])
    expr = replace(expr, r"diag\(\s*\[([^\]]+)\]\'\s*\)" => s"Diagonal([\1])")
    expr = replace(expr, r"diag\(\s*(.*?)\s*\)" => s"Diagonal(\1)") 
    # x(i) → x[i], y(j) → y[j]
    expr = replace(expr, r"x\((\d+)\)" => s"x[\1]")
    expr = replace(expr, r"y\((\d+)\)" => s"y[\1]")
    if NX == 1
        expr = replace(expr, r"\bx\b(?!\[)" => "x[1]")
    end
    if NY == 1
        expr = replace(expr, r"\by\b(?!\[)" => "y[1]")
    end
    return expr
end

""" 
  parse_and_append(mfile::String, jl_txt::String, num_vars::Int, index::Int)
    wenn `num_vars` kleiner als die Dimensionen des Problems in `mfile`, wird `false` zurückgegeben, 
    sonst werden die Funktionen übersetzt und der Julia-Code in `jl_txt` angehängt und `true` zurückgegeben.

    Input:
    - mfile: Pfad zur MATLAB-Datei
    - jl_txt: Pfad zur Julia-Datei
    - num_vars: Anzahl der Variablen
    - index: Index des Problems (wird als Suffix an die Funktionsnamen gehängt)
"""

function parse_and_append(mfile::String, jl_txt::String, num_vars::Int, index::Int)
  lines = readlines(mfile) # Zeilen einlesen
  # 1) Dimensionen aus Kommentar extrahieren
  NX=NY=nG=ng=0
  for L in lines
    if occursin("dim_x", L)
      nums = parse.(Int, collect(m.match for m in eachmatch(r"\d+", L)))
      NX, NY, nG, ng = nums[1:4]
      break
    end
  end
  if NX+NY > num_vars
    return false
  end
  # 2) Parser-Loop: Relevante Zeilen zu den einzelnen Funktionen sammeln
  blocks = Dict{String,Vector{String}}()
  current = ""
  inblock = false
  for L in lines
    s = strip(L)
    # a) Start des relevanten Blocks?
    if !inblock && occursin("nargin<4", s)
      inblock = true
      continue
    end
    # b) Wenn wir drin sind …
    if inblock
      # b.1) beim "end" raus
      if lowercase(s) == "end" break end
      # b.2) neue case-Zeile?
      m = match(r"^case\s*'(\w+)'(.*)", s)         # fange 'F','G','f','g' und alles was danach steht ein
      if m !== nothing
        current = m.captures[1]
        blocks[current] = String[]
        rest = strip(m.captures[2])
        rest = strip(split(rest, "%"; limit=2)[1]) # Kommentar entfernen
        rest = strip(replace(rest, r"^\s*;"=>""))  # führendes Semikolon entfernen
        if !isempty(rest) push!(blocks[current], rest) end
        continue
      end
      # b.3) Folgezeilen gehören zum aktuellen case
      if current != ""
        rest = strip(split(s, "%"; limit=2)[1])   # Kommentar entfernen
        if !isempty(rest) push!(blocks[current], rest) end
      end
    end
  end
  # 3) Funktionen übersetzen, bounds extrahieren und in jl_txt anhängen
  pname = basename(mfile)[1:end-2]
  # Placeholder für Variablenbounds
  x_l = -ones(NX)*Inf; x_u = ones(NX)*Inf
  y_l = -ones(NY)*Inf; y_u = ones(NY)*Inf
  open(jl_txt, "a") do io
    println(io, "# Instance $pname (number $index)")
    # a) (Ziel-)Funktionsblöcke F/f
    for funkey in ["F","f"]
      body = get(blocks, funkey, String[])
      if isempty(body)
        @warn "kein Block für $funkey gefunden in $mfile"
      end
      # a.1) Funktionskopf
      println(io, "function $(funkey)_$(index)(x::AbstractVector{<:Real}, y::AbstractVector{<:Real})")
      for stmt in body
        expr = stmt
        expr = strip(replace(expr, r"\s*;\s*$"=>"")) # Abschließendes Semikolon entfernen
        expr = translate_syntax(expr, NX, NY)     # Matlab-Indexierung → Julia-Indexierung
        if occursin(r"^w\s*=", expr)              # aus w= wird return
          rhs = match(r"w\s*=\s*(.*)", expr).captures[1]
          println(io, "    return ", rhs)
        else
          println(io, "    ", expr)               # Andere (übersetzte) Zuweisungen anfügen
        end
      end
      println(io, "end")
      println(io, "")
    end
    # b) (Nebenbedingungs-)Funktionsblöcke G/g
    for funkey in ["G","g"]
      body = get(blocks, funkey, String[])
      if isempty(body)
        @warn "kein Block für $funkey gefunden in $mfile"
      end
      # b.1) Funktionskopf
      println(io, "function $(funkey)_$(index)(x::AbstractVector{<:Real}, y::AbstractVector{<:Real})")
      str = ""
      for (i, stmt) in enumerate(body)
        expr = stmt
        # b.2) w = …   → return …
        if occursin(r"^w\s*=", expr) 
          str = join(body[i:end], " ")                        # alles ab w= in einen String packen
          str = strip(replace(str, r"\s*;\s*$"=>""))             # Abschließendes Semikolon entfernen
          break
        else
          expr = translate_syntax(expr, NX, NY)
          println(io, "    ", expr)                           # Andere (übersetzte) Zuweisungen anfügen
        end
      end
      # b.3) Bounds-Detection
      rhs = strip(replace(str, r"^w\s*=\s*(.*)\s*$" => s"\1"))
      inner = replace(rhs, r"^\s*\[\s*(.*)\s*\]\s*$" => s"\1")
      inner_new = []
      for stmt in split_top(inner; sep=';')
        found = false
        stmt = strip(stmt)
        # jetzt findet detect_bounds(evtl.) nur an diesen top‐level‐Ausdrücken statt
        if funkey == "G"
          found, full_dim, x_l, x_u = detect_bounds(stmt, 'x', x_l, x_u)
          if found
            full_dim ? nG=nG-NX : nG=nG-1
          end
        elseif funkey == "g"  
          found1, full_dim, x_l, x_u = detect_bounds(stmt, 'x', x_l, x_u)
          if found1
            full_dim ? ng=ng-NX : ng=ng-1
          end
          found2, full_dim, y_l, y_u = detect_bounds(stmt, 'y', y_l, y_u)
          if found2
            full_dim ? ng=ng-NY : ng=ng-1
          end
          found = found1 || found2
        end
        if found == false
          stmt = translate_syntax(stmt, NX, NY)
          if stmt!==""
            push!(inner_new, stmt)
          end
        end
      end
      if length(inner_new) == 0
        println(io, "    return []")
      elseif length(inner_new) == 1
        println(io, "    return $(inner_new[1])")
      else
        inner_new = join(inner_new, "; ")
        println(io, "    return [$(inner_new)]")
      end
      println(io, "end")
      println(io, "")
    end
    @printf(io, "const NX_%d = %d\n", index, NX)
    @printf(io, "const NY_%d = %d\n", index, NY)
    @printf(io, "const nG_%d = %d\n", index, nG)
    @printf(io, "const ng_%d = %d\n\n", index, ng)
    println("")
    println(io, "const x_l_$index = [", join(x_l, ", "),"]")
    println(io, "const x_u_$index = [", join(x_u, ", "),"]")
    println(io, "const y_l_$index = [", join(y_l, ", "),"]")
    println(io, "const y_u_$index = [", join(y_u, ", "),"]")
    println(io, "")
  end
  return true
end

function main()
  m_folder  = joinpath(@__DIR__, "..", "data", "BOLIBver2", "Examples", "Nonlinear")
  jl_folder = joinpath(@__DIR__, "..", "data", "BOLIBver2_julia")
  isdir(jl_folder) || mkpath(jl_folder)
  num_vars = 4
  outfile = joinpath(jl_folder, "nonlinear_testbed.jl")
  taboolist = ["AnEtal2009", "MorganPatrone2006b", "MorganPatrone2006c", "CalamaiVicente1994a", 
    "IshizukaAiyoshi1992a", "HenrionSurowiec2011", "GumusFloudas2001Ex5", "LuDebSinha2016a", "LuDebSinha2016c"]
  open(outfile, "a") do io
    println(io, "# Generated by parse_bolib.jl")
    println(io, "# nonlinear testbed of BOLIBver2")
    println(io, "# maximum number of variables: $num_vars")
    println(io, "")
  end
  testbed = []
  index = 1
  for mfile in readdir(m_folder; join=true)
    endswith(mfile, ".m") || continue
    name = basename(mfile)[1:end-2]
    if !(name in taboolist) && parse_and_append(mfile, outfile, num_vars, index)
      index += 1
      #TODO Hier relevante Problemdaten aus 'InfomAllExamp.m' auslesen?
      push!(testbed, name)
    end
  end
  open(outfile, "a") do io
    println(io, "# Filtered testbed of BOLIBver2")
    println(io, "const testbed = [")
    for name in testbed
      println(io, "    \"$(name)\",")
    end
    println(io, "]")
  end

  
end

main()
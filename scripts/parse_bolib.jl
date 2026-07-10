using Printf

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
    if NX > 1
        # x ± Zahl → x .± Zahl
        expr = replace(expr,
            r"(\bx\b)\s*([+-])\s*(\d+)" => s"\1 .\2 \3")
        # Zahl ± x → Zahl .± x
        expr = replace(expr,
            r"(\d+)\s*([+-])\s*(\bx\b)" => s"\1 .\2 \3")
    elseif NX == 1
        expr = replace(expr, r"\bx\b(?!\[)" => "x[1]")
    end
    if NY > 1
        expr = replace(expr,
            r"(\by\b)\s*([+-])\s*(\d+)" => s"\1 .\2 \3")
        expr = replace(expr,
            r"(\d+)\s*([+-])\s*(\by\b)" => s"\1 .\2 \3")
    elseif NY == 1
        expr = replace(expr, r"\by\b(?!\[)" => "y[1]")
    end
    return expr
end

function parse_and_append(mfile::String, jl_txt::String, num_vars::Int, index::Int)
   # 1) Einlesen
  lines = readlines(mfile)

  # 2) Dimensionen aus Kommentar extrahieren
  NX=NY=nG=ng=0
  for L in lines
    if occursin("dim_x", L)
      nums = parse.(Int, collect(m.match for m in eachmatch(r"\d+", L)))
      NX,NY,nG,ng = nums[1:4]
      break
    end
  end

  if NX+NY > num_vars
    return false
  end

  # 3) Parser-Loop: ersten if-Block bis zum ELSE sammeln
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
      # b.1) beim ELSE raus
      if lowercase(s) == "end"
        break
      end

      # b.2) neue case-Zeile?
      #     fange 'F','G','f','g' und alles was danach bis Semicolon steht ein
      m = match(r"^case\s*'(\w+)'(.*)", s)
      if m !== nothing
        current = m.captures[1]
        blocks[current] = String[]
        rest = strip(m.captures[2])
        rest = strip(split(rest, "%"; limit=2)[1]) # Kommentar entfernen
        rest = strip(replace(rest, r"^\s*;"=>""))  # führendes Semikolon entfernen
        rest = strip(replace(rest, r";\s*$"=>""))  # abschließendes Semikolon entfernen
        if !isempty(rest)
          push!(blocks[current], rest)
        end
        continue
      end
      # b.3) Folgezeilen gehören zum aktuellen case
      if current != ""
        rest = strip(split(s, "%"; limit=2)[1])   # Kommentar entfernen
        rest = strip(replace(rest, r"^\s*;"=>"")) # führendes Semikolon entfernen
        rest = strip(replace(rest, r";\s*$"=>"")) # abschließendes Semikolon entfernen
        if !isempty(rest)
          push!(blocks[current], rest)
        end
      end
    end
  end

  # 4) Emit Julia‐Modul
  pname = basename(mfile)[1:end-2]
  # Placeholder für Variablenbounds
  x_l = -ones(NX)*Inf
  x_u = ones(NX)*Inf
  y_l = -ones(NY)*Inf
  y_u = ones(NY)*Inf
  
  open(jl_txt, "a") do io
    println(io, "# Parsing instance $pname (number $index)")
    @printf(io, "const NX_%d = %d\n", index, NX)
    @printf(io, "const NY_%d = %d\n", index, NY)
    @printf(io, "const nG_%d = %d\n", index, nG)
    @printf(io, "const ng_%d = %d\n\n", index, ng)

    for funkey in ["F","f"]
      body = get(blocks, funkey, String[])
      if isempty(body)
        @warn "kein Block für $funkey gefunden in $mfile"
      end
      # wir gehen hier von Vektor-Inputs aus
      println(io, "function $(funkey)_$(index)(x::AbstractVector{<:Real}, y::AbstractVector{<:Real})")
      for stmt in body
        expr = stmt
        # 1) Matlab-Indexierung → Julia-Indexierung
        expr = translate_syntax(expr, NX, NY)
        # 2) w = …   → return …
        if occursin(r"^w\s*=", expr)
          rhs = match(r"w\s*=\s*(.*)", expr).captures[1]
          println(io, "    return ", rhs)
        else
          # alle anderen Zuweisungen einfach 1:1
          println(io, "    ", expr)
        end
      end
      println(io, "end")
      println(io, "")
    end
    for funkey in ["G","g"]
      body = get(blocks, funkey, String[])
      if isempty(body)
        @warn "kein Block für $funkey gefunden in $mfile"
      end
      # wir gehen hier von Vektor-Inputs aus
      println(io, "function $(funkey)_$(index)(x::AbstractVector{<:Real}, y::AbstractVector{<:Real})")
      for stmt in body
        expr = stmt
        # 1) Matlab-Indexierung → Julia-Indexierung
        expr = translate_syntax(expr, NX, NY)
        # 2) w = …   → return …
        if occursin(r"^w\s*=", expr)
          rhs = match(r"w\s*=\s*(.*)", expr).captures[1]
          println(io, "    return ", rhs)
        else
          # alle anderen Zuweisungen einfach 1:1
          println(io, "    ", expr)
        end
      end
      println(io, "end")
      println(io, "")
    end

  end
  
  return true
end

function main()
  m_folder  = joinpath(@__DIR__, "..", "data", "BOLIBver2", "Examples", "Nonlinear")
  jl_folder = joinpath(@__DIR__, "..", "data", "BOLIBver2_julia")
  isdir(jl_folder) || mkpath(jl_folder)
  num_vars = 4
  outfile = joinpath(jl_folder, "nonlinear_testbed.jl")
  open(outfile, "a") do io
    println(io, "# generated by parse_bolib.jl")
    println(io, "# nonlinear testbed of BOLIBver2")
    println(io, "# maximum number of variables: $num_vars")
    println(io, "")
  end
  taboolist = ["AnEtal2009", "MorganPatrone2006b", "MorganPatrone2006c", "CalamaiVicente1994a", 
    "IshizukaAiyoshi1992a", "HenrionSurowiec2011", "GumusFloudas2001Ex5", "LuDebSinha2016a", "LuDebSinha2016c"]
  testbed = []
  index = 1
  for mfile in readdir(m_folder; join=true)
    endswith(mfile, ".m") || continue
    name = basename(mfile)[1:end-2]
    if !(name in taboolist) && parse_and_append(mfile, outfile, num_vars, index)
      index += 1
      push!(testbed, name)
    end
  end
  open(outfile, "a") do io
    println(io, "# Testbed of BOLIBver2")
    println(io, "const testbed = [")
    for name in testbed
      println(io, "    \"$(name)\",")
    end
    println(io, "]")
  end

  
end

main()
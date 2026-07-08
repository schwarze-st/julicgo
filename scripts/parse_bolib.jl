#!/usr/bin/env julia
using Printf

function parse_and_emit(mfile::String, jl_folder::String)
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
  outfile = joinpath(jl_folder, "$pname.jl")
  open(outfile, "w") do io
    println(io, "module $pname")
    println(io, "export NX, NY, nG, ng, F, G, f, g\n")
    @printf(io, "const NX = %d\n", NX)
    @printf(io, "const NY = %d\n", NY)
    @printf(io, "const nG = %d\n", nG)
    @printf(io, "const ng = %d\n\n", ng)

    for funkey in ["F","G","f","g"]
      body = get(blocks, funkey, String[])
      if isempty(body)
        @warn "kein Block für $funkey gefunden in $mfile"
      end

      # wir gehen hier von Vektor-Inputs aus
      println(io, "function $funkey(x::AbstractVector{<:Real}, y::AbstractVector{<:Real})")
      for stmt in body
        expr = stmt
        # 1) Matlab-Indexierung → Julia-Indexierung
        expr = replace(expr, r"x\((\d+)\)" => s"x[\1]")
        expr = replace(expr, r"y\((\d+)\)" => s"y[\1]")
        if NX > 1
            # x ± Zahl → x .± Zahl
            expr = replace(expr,
                r"(\bx\b)\s*([+-])\s*(\d+)" => s"\1 .\2 \3")
            # Zahl ± x → Zahl .± x
            expr = replace(expr,
                r"(\d+)\s*([+-])\s*(\bx\b)" => s"\1 .\2 \3")
        end
        if NY > 1
            expr = replace(expr,
                r"(\by\b)\s*([+-])\s*(\d+)" => s"\1 .\2 \3")
            expr = replace(expr,
                r"(\d+)\s*([+-])\s*(\by\b)" => s"\1 .\2 \3")
        end
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

    println(io, "end # module $pname")
  end
  
  println("🖊️  $outfile erzeugt")
end

function main()
  m_folder  = joinpath(@__DIR__, "..", "data", "BOLIBver2", "Examples", "Nonlinear")
  jl_folder = joinpath(@__DIR__, "..", "data", "BOLIBver2_julia", "Nonlinear")
  isdir(jl_folder) || mkpath(jl_folder)

  for mfile in readdir(m_folder; join=true)
    endswith(mfile, ".m") || continue
    parse_and_emit(mfile, jl_folder)
  end
end

main()
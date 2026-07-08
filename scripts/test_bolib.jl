# src/test_all.jl
# ------------------------

# Damit `import Modulname` die Dateien in src/TestprobsJulia findet:
function main()
    jl_folder = joinpath(@__DIR__, "..", "data", "BOLIBver2_julia", "Nonlinear")
    push!(LOAD_PATH, jl_folder)
    local k = 0

    for file in readdir(jl_folder)
        if k in [2]
            continue
        end
        # nur .jl-Dateien
        endswith(file, ".jl") || continue

        # Modulname als Symbol, z.B. :AnandalinghamWhite1990
        name, _ = splitext(basename(file))
        mod_sym = Symbol(name)

        # 3) Modul importieren
        @eval import $(mod_sym)
        mod = getfield(Main, mod_sym)

        # 4) Modul-Objekt holen
        #M = eval(mod_sym)

        println("==========================================")
        println("Test für Modul: ", name)
        println("  NX = ", mod.NX, ", NY = ", mod.NY,
                ", nG = ", mod.nG, ", ng = ", mod.ng)

        # 5) Test-Eingaben anlegen
        a = zeros(mod.NX)
        b = zeros(mod.NY)

        # 6) Funktionen ausprobieren
        println("  F(a,b) = ", mod.F(a,b))
        println("  G(a,b) = ", mod.G(a,b))    # Vector der Länge nG
        println("  f(a,b) = ", mod.f(a,b))
        println("  g(a,b) = ", mod.g(a,b))    # Vector der Länge ng
        println()
        k = k+1
        if k>=6
            break
        end
    end
end 

main()
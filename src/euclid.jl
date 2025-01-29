"""
Compute the Eucliean distance between N-dimensional point a and b
"""
euclid(a, b) = √(sum((a .- b).^2))

"""
Compute the matrix of Euclidean distances among atoms separated by at least `k` positions in a chain.
"""
function euclid_atoms(df::DataFrame, k)
    nb_atom = size(df, 1)

    d = zeros(nb_atom, nb_atom)

    coords_i = zeros(3)
    coords_j = zeros(3)

    for i in eachindex(eachrow(df))
        coords_i .= df.X[i], df.Y[i], df.Z[i]

        target_atoms = 1:(i -(k+1))
        for j in target_atoms
            coords_j .= df.X[j], df.Y[j], df.Z[j]
            d[i, j] = euclid(coords_i, coords_j)
        end 
    end

    return d
end

"""
    inter_atomic_distance_map(f, df, k)
"""
function inter_atomic_distance_map(f::Function, df, k)
    coords_i = zeros(3)
    coords_j = zeros(3)
    nb = length(df.ResidueName)

    for i in eachindex(df.ResidueName)
        nuc_i = df.ResidueName[i]
        coords_i .= df.X[i], df.Y[i], df.Z[i]
        chain_i = df.ChainID[i]

        for j in (i + (k + 1)):nb
            chain_j = df.ChainID[j]
            chain_i == chain_j || break

            nuc_j = df.ResidueName[j]
            coords_j .= df.X[j], df.Y[j], df.Z[j]

            d = euclid(coords_i, coords_j)
            f(nuc_i, nuc_j, d)
        end
    end

    return nothing
end

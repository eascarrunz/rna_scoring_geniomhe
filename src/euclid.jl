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

        # target_atoms = (i+(k+1)):nb_atom
        # for j in target_atoms
        #     coords_j .= [df.X[j], df.Y[j], df.Z[j]]
        #     d[i, j] = euclid(coords_i, coords_j)
        # end 
    end

    return d
end

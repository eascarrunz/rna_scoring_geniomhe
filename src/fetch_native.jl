using Downloads

handle_list = "native_list.txt"
outdir = joinpath("data", "native")

const BASE_URL_PDB = "https://files.rcsb.org/download"

function read_handle_list(file)
    handles = Vector{String}()
    s = ""
    open(file) do io
        while ! eof(io)
            c = read(io, Char)
            if isspace(c)
                length(s) == 0 && continue
                push!(handles, s)
                s = ""
            else
                s *= c
            end
        end
    end

    length(s) > 0 && push!(handles, s)

    return handles
end

function unzip(gz_path)
    unzip_cmd = `gunzip $(gz_path)`
    run(unzip_cmd)
end

make_pdb_url(handle) = BASE_URL_PDB * '/' * handle * ".pdb.gz"
make_pdb_path(handle, dir) = joinpath(dir, handle * ".pdb")

function main()
    isdir(outdir) || mkpath(outdir)

    handles = read_handle_list(handle_list)
    
    unzip_taks = Vector{Task}()
    
    for handle in handles
        url = make_pdb_url(handle)
        pdb_path = make_pdb_path(handle, outdir)
        pdb_gz_path = pdb_path * ".gz"
        Downloads.download(url, pdb_gz_path)
        task = Threads.@spawn unzip(pdb_gz_path)
        push!(unzip_taks, task)
    end
    
    wait.(unzip_taks)

    return 0
end

main()
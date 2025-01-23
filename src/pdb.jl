using DataFrames:DataFrame
using GZip

const PDB_FIELD_DEFINITIONS = (
    RecordType              = (Range = 1:6,     Type = String   ),
    AtomSerialNumber        = (Range = 7:11,    Type = Int      ),
    AtomName                = (Range = 13:16,   Type = String   ),
    AltLocation             = (Range = 17,      Type = Char     ),
    ResidueName             = (Range = 18:20,   Type = String   ),
    ChainID                 = (Range = 22,      Type = Char     ),
    ResidueSeqNumber        = (Range = 23:26,   Type = Int      ),
    ResidueInsertionCode    = (Range = 27,      Type = Int      ),
    X                       = (Range = 31:38,   Type = Float64  ),
    Y                       = (Range = 39:46,   Type = Float64  ),
    Z                       = (Range = 47:54,   Type = Float64  ),
)

AtomInfo = @NamedTuple begin
    AtomSerialNumber::Int
    AtomName::String
    ResidueName::String
    ChainID::String
    ResidueSeqNumber::Int
    X::Float64
    Y::Float64
    Z::Float64
end

function beginswith(text::String, pattern::String)
    length(text) < length(pattern) && return false

    for (i, c) in enumerate(pattern)
        text[i] != c && return false
    end

    return true
end


function extract_pdb_field(line::String, field::Symbol)
    field_def = PDB_FIELD_DEFINITIONS[field]
    field_text = line[field_def.Range]

    if field_def.Type ≡ String
        field_value = String(strip(field_text))
    elseif field_def.Type ≡ Char
        field_value = Char(field_text)
    else
        field_value = parse(field_def.Type, field_text)
    end

    return field_value
end


_atom_name_check(::AbstractString, ::Int) = true
_atom_name_check(text::AbstractString, tag::String) = text == tag
# _atom_name_check(text::AbstractString, tags::Vector{String}) = text ∈ tags

get_file_extension(s) = last(split(s, '.'))

function read_atoms(file::String; name = "")
    ext = get_file_extension(file)

    io = lowercase(ext) == "gz" ? gzopen(file) : open(file)

    return read_atoms(io; name = name)
end


"""
    read_atoms(file; atom_name = "")

Read atom ("ATOM" or "HETATM") records from a PDB file into a DataFrame. If there are several models in the same file, only the first model will be read.

Records can be optionally filtered by atom name (string or vector of strings). No filtering is done if the atom name is an empty string (the default) or an empty vector.

The following record fields are returned as columns in the data frame:
`:AtomSerialNumber`, `:AtomName`, `:ResidueName`, `:ChainID`, `:ResidueSeqNumber`, `:X`, `:Y`, `:Z`
"""
function read_atoms(io::IO; name="")::DataFrame
    atom_name_tag = isempty(name) ? 0 : name

    df = DataFrame()

    cursor_in_model = false

    for line in eachline(io)

        if beginswith(line, "MODEL")
            cursor_in_model = true
            continue
        end

        if cursor_in_model && beginswith(line, "ENDMDL")
            return df
        end
        
        record_type = extract_pdb_field(line, :RecordType)
        if record_type == "ATOM" || record_type == "HETATM"
            atom_name_in_line = extract_pdb_field(line, :AtomName)
            _atom_name_check(atom_name_in_line, atom_name_tag) || continue

            line_data = (
                AtomSerialNumber =  extract_pdb_field(line, :AtomSerialNumber),
                AtomName =          atom_name_in_line,
                ResidueName =       extract_pdb_field(line, :ResidueName),
                ChainID =           extract_pdb_field(line, :ChainID),
                ResidueSeqNumber =  extract_pdb_field(line, :ResidueSeqNumber),
                X =                 extract_pdb_field(line, :X),
                Y =                 extract_pdb_field(line, :Y),
                Z =                 extract_pdb_field(line, :Z)
            )

            push!(df, line_data)
        end
    end

    return df
end


export stoppropagation,
       subscribe,
       samplesignals

# Don't allow a signal to propagate outward
immutable StopPropagation <: Tile
    tile::Tile
    name::Symbol
end

@doc """
Stop a UI signal from propagating further.
""" ->
stoppropagation(tile::Tile, name::Symbol) =
    StopPropagation(tile, name)

render(tile::StopPropagation) =
    render(tile.tile) <<
        Elem("stop-propagation",
            attributes=[:name=>tile.name])


# Send a signal update to the Julia side
immutable SignalTransport <: Tile
    tile::Tile
    name::Symbol
    signal::Input
end

subscribe(t::Tile, name, s::Input; absorb=true) =
    SignalTransport(t, name, s) |>
       (x -> absorb ? stoppropagation(x, name) : x)

render(sig::SignalTransport) =
    render(sig.tile) <<
        Elem("signal-transport",
            attributes=[:name=>sig.name, :signalId => setup_transport(sig.signal)])


setup_transport(x) =
    error("Looks like there is no trasport set up")

# Utility functions for transports
decodeJSON(sig::Input, val) = val
decodeJSON{T <: String}(sig::Input{T}, ::Nothing) = ""
decodeJSON{T <: String}(sig::Input{T}, val) = string(val)
decodeJSON{T <: Integer}(sig::Input{T}, val) = convert(T, int(val))
decodeJSON{T <: FloatingPoint}(sig::Input{T}, val) = convert(T, float(val))

istruthy(::Nothing) = false
istruthy(b::Bool) = b
istruthy(::None) = false
istruthy(x) = !isempty(x)

decodeJSON(sig::Input{Bool}, val) = istruthy(val)

import Base.Random: UUID, uuid4

const signal_to_id = Dict()
const id_to_signal = Dict()

function makeid(sig::Signal)
    if haskey(signal_to_id, sig)
        # todo ensure connection
        return signal_to_id[sig]
    else
        id = get!(() -> string(uuid4()), signal_to_id, sig)
        id_to_signal[id] = sig
        return id
    end
end

function fromid(id)
    id_to_signal[id]
end



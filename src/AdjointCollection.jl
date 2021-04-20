struct AdjointCollection{layer, T, V <: AbstractCollection{layer, T}} <: AbstractCollection{layer, T}
    parent::V
end
Base.parent(c::AdjointCollection) = c.parent
LinearAlgebra.adjoint(c::AbstractCollection) = AdjointCollection(c)

# getindex
Base.IndexStyle(::Type{<: AdjointCollection}) = IndexLinear()
Base.length(c::AdjointCollection) = length(parent(c))
Base.size(c::AdjointCollection) = (1, length(c))
@inline function Base.getindex(c::AdjointCollection, i::Int)
    @boundscheck checkbounds(c, i)
    @inbounds parent(c)[i]
end

function Base.show(io::IO, mime::MIME"text/plain", c::AdjointCollection)
    summary(io, c)
    println(io)
    Base.print_array(io, Array(c)')
end

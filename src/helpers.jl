macro unreachable(message="This line of code cannot be reached. Please file an issue.")
    quote
        error($(esc(message)))
    end
end

apply2all(f, args::Tuple{}) = ()
apply2all(f, args::Tuple{Any}) = (f(args[1]),)
apply2all(f, args::Tuple{Any, Any}) = (f(args[1]), f(args[2]))
apply2all(f, args::Tuple) = (f(args[1]), apply2all(f, Base.tail(args))...)

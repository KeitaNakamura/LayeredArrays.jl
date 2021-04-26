macro unreachable(message="This line of code cannot be reached. Please file an issue.")
    quote
        error($(esc(message)))
    end
end

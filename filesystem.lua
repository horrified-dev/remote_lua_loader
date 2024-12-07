function filesystem()
    local chain_data = bump.alloc(256)
    memory.write_buffer(chain_data, "/app0\0") 
    
    local fd = syscall.open(chain_data, 0, 0) 
    if fd:tonumber() < 0 then
        return
    end
    printf("fd: %d\n", fd:tonumber())

    syscall.resolve({getdents = 272})

    local dir_buffer = chain_data + 0x10
    local buffer_size = 1028
    if syscall.getdents(fd:tonumber(), dir_buffer, buffer_size):tonumber() < 0 then
        error("getdents() error: " .. get_error_string())
    else
        print("data from /app0\n\n", memory.read_buffer(dir_buffer, buffer_size))
    end
    syscall.close(fd:tonumber())
end

function main()
    filesystem()
end
main()
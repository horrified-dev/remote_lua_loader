-- parts taken from al-azif ftp server. to credits to him. thank you very much.
-- As of right now, this should work on ps4. Haven't really added any support for ps5.
-- The server is NOT completed, so don't expect anything from this just yet.
-- Server will spawn on port 1337.

DEBUGGING = "off"
FTP_FILE_LOG_PATH = "/av_contents/content_tmp/"
FTP_TEST_PATH = "/av_contents/content_tmp"
FTP_TRANSFER_TYPE = "A"

local FTP_PS4_ADDR = bump.alloc(16)
local FTP_CLIENT_ADDR = bump.alloc(16)
local FTP_CLIENT_ADDR_LEN = bump.alloc(8)
local FTP_CLIENT_SOCK = nil

function sceNetRecv(sockfd, buf, len, flags)
    return syscall.recvfrom(sockfd, buf, len, flags, 0, 0):tonumber()
end

-- __int64 __fastcall send(__int64 a1, __int64 a2, __int64 a3, __int64 a4)
function sceNetSend(sockfd, buf, len, flags)
    return syscall.sendto(sockfd, buf, len, flags, 0, 0):tonumber()
end

function sceNetListen(sockfd, backlog)
    return syscall.listen(sockfd, backlog):tonumber()
end

function sceNetBind(sockfd, addr, addrlen)
    return syscall.bind(sockfd, addr, addrlen):tonumber()
end

function sceNetSocket(domain, type, protocol)
    return syscall.socket(domain, type, protocol):tonumber()
end

function sceNetSocketClose(sockfd)
    return syscall.close(sockfd):tonumber()
end

function sceNetSetsockopt(sockfd, level, optname, optval, optlen)
    return syscall.setsockopt(sockfd, level, optname, optval, optlen):tonumber()
end

--11E10
function sceNetInetPton(a1, a2, a3)
    local fn = function_rop(libkernel_base + 0x11E10)
    return fn(a1, a2, a3)
end

function sceNetHtonl(hostlong)
    return bit32.bor(
        bit32.lshift(bit32.band(hostlong, 0xFF), 24),
        bit32.lshift(bit32.band(hostlong, 0xFF00), 8),
        bit32.rshift(bit32.band(hostlong, 0xFF0000), 8),
        bit32.rshift(bit32.band(hostlong, 0xFF000000), 24)
    )
end

function sceNetHtons(hostshort)
    return bit32.bor(
        bit32.lshift(bit32.band(hostshort, 0xFF), 8),
        bit32.rshift(bit32.band(hostshort, 0xFF00), 8)
    )
end

function sceNetAccept(sockfd, addr, addrlen)
    return syscall.accept(sockfd, addr, addrlen):tonumber()
end

function sceNetGetsockname(sockfd, addr, addrlen)
    return syscall.getsockname(sockfd, addr, addrlen):tonumber()
end

function ftp_send_message(sck, str)
    return sceNetSend(sck, str, #str, 0)
end

function ftp_send_user(sck)
    ftp_send_message(sck, "331 Anonymous login accepted, send your email as password\r\n")
end

function ftp_send_noop(sck)
    ftp_send_message(sck, "200 No operation\r\n")
end

function ftp_send_pass(sck)
    ftp_send_message(sck, "230 User logged in\r\n")
end

function ftp_send_quit(sck)
    ftp_send_message(sck, "221 Goodbye\r\n")
end

function ftp_send_cwd(sck)
    ftp_send_message(sck, "502 Command not implemented (CWD).")
end

function ftp_send_stor(sck)
    ftp_send_message(sck, "502 Command not implemented (STOR).")
end

function ftp_send_dele(sck)
    ftp_send_message(sck, "502 Command not implemented (DELE).")
end

function ftp_send_rmd(sck)
    ftp_send_message(sck, "502 Command not implemented (RMD).")
end

function ftp_send_mkd(sck)
    ftp_send_message(sck, "502 Command not implemented (MKD).")
end

function ftp_send_rnfr(sck)
    ftp_send_message(sck, "502 Command not implemented (RNFR).")
end

function ftp_send_rnto(sck)
    ftp_send_message(sck, "502 Command not implemented (RNTO).")
end

function ftp_send_size(sck)
    ftp_send_message(sck, "502 Command not implemented (SIZE).")
end

function ftp_send_rest(sck)
    ftp_send_message(sck, "502 Command not implemented (REST).")
end

function ftp_send_feat(sck)
    ftp_send_message(sck, "211-extensions\r\n")
    ftp_send_message(sck, "REST STREAM\r\n")
    ftp_send_message(sck, "211 end\r\n")
end

function ftp_send_appe(sck)
    ftp_send_message(sck, "502 Command not implemented (APPE).")
end

function ftp_send_retr(sck)
    ftp_send_message(sck, "502 Command not implemented (RETR).")
end

function ftp_send_cdup(sck)
    ftp_send_message(sck, "502 Command not implemented (CDUP).")
end

function ftp_send_type(sck, cmd)
    local requested_type = cmd:match("^TYPE (.+)")
    if requested_type == "I" then
        FTP_TRANSFER_TYPE = "I"
        ftp_send_message(sck, "200 Switching to Binary mode\r\n")
    elseif requested_type == "A" then
        FTP_TRANSFER_TYPE = "A"
        ftp_send_message(sck, "200 Switching to ASCII mode\r\n")
    else
        ftp_send_message(sck, "504 Command not implemented for that parameter\r\n")
    end
end

function ftp_send_pwd(sck)
    ftp_send_message(sck, string.format("257 \"%s\" is the current directory\r\n", FTP_TEST_PATH))
end

function send_list(sck, path)
    local tmp_stat = bump.alloc(96)
    printf("here we go.")
    if syscall.stat(path, tmp_stat):tonumber() < 0 then
        ftp_send_message(sck, "550 Invalid directory\r\n")
        return
    end

    printf("here we go.")
    local dfd = syscall.open(path, 0, 0):tonumber() -- path, O_RDONLY, 0
    if dfd < 0 then
        ftp_send_message(sck, "550 Invalid directory\r\n")
        return
    end

    printf("here we go.")
    ftp_send_message(sck, "150 Opening ASCII mode data transfer for LIST.\r\n")
end

function ftp_send_list(sck)
    send_list(sck, FTP_TEST_PATH)
end

function ftp_send_port(sck)
    ftp_send_message(sck, "502 Command not implemented (PORT).")
end

function ftp_send_pasv(sck)
    FTP_CLIENT_SOCK = sceNetSocket(AF_INET, SOCK_STREAM, 0)

    memory.write_byte(FTP_CLIENT_ADDR + 1, AF_INET)
    memory.write_word(FTP_CLIENT_ADDR + 2, sceNetHtons(0))
    memory.write_dword(FTP_CLIENT_ADDR + 4, sceNetHtonl(INADDR_ANY))

    sceNetBind(FTP_CLIENT_SOCK, FTP_CLIENT_ADDR, 16)
    sceNetListen(FTP_CLIENT_SOCK, 128)

    local pick = bump.alloc(16)
    local namelen = bump.alloc(8)
    memory.write_dword(namelen, 16)

    sceNetGetsockname(FTP_CLIENT_ADDR, pick, namelen)

    local pick_port = memory.read_dword(pick + 2)

    local ps4_s_addr = memory.read_dword(FTP_CLIENT_ADDR + 4)
    ftp_send_message(sck, string.format("227 Entering Passive Mode (%d,%d,%d,%d,%d,%d)\r\n",
        bit32.band(bit32.rshift(ps4_s_addr:tonumber(), 0), 0xff),
        bit32.band(bit32.rshift(ps4_s_addr:tonumber(), 8), 0xff),
        bit32.band(bit32.rshift(ps4_s_addr:tonumber(), 16), 0xff),
        bit32.band(bit32.rshift(ps4_s_addr:tonumber(), 24), 0xff),
        bit32.band(bit32.rshift(pick_port:tonumber(), 0), 0xff),
        bit32.band(bit32.rshift(pick_port:tonumber(), 8), 0xff)
    ))
end

function ftp_send_syst(sck)
    ftp_send_message(sck, "215 UNIX Type: L8\r\n")
end

function ftp_send_passive(sck, pasv_port)
    -- local loopback for now.
    local pasv_ip = "127,0,0,1"
    local pasv_hi_port = math.floor(pasv_port / 256)
    local pasv_lo_port = pasv_port % 256
    ftp_send_message(sck, string.format("227 Entering Passive Mode (%s,%d,%d)\r\n", pasv_ip, pasv_hi_port, pasv_lo_port))
end

function ftp_client_thread(server_sck)
    FTP_CLIENT_SOCK = sceNetAccept(server_sck, FTP_CLIENT_ADDR, FTP_CLIENT_ADDR_LEN)
    if FTP_CLIENT_SOCK >= 0 then
        -- new connection
        ftp_send_message(FTP_CLIENT_SOCK, "220 FTP Server ready.\r\n")

        local recv_buffer = bump.alloc(512)
        while true do
            local n_recv = sceNetRecv(FTP_CLIENT_SOCK, recv_buffer, 512, 0)
            if n_recv <= 0 then break end

            local cmd = memory.read_buffer(recv_buffer, n_recv):gsub("\r\n", "")

            if cmd:match("^NOOP") then
                ftp_send_noop(FTP_CLIENT_SOCK)
            elseif cmd:match("^USER") then
                ftp_send_user(FTP_CLIENT_SOCK)
            elseif cmd:match("^PASS") then
                ftp_send_pass(FTP_CLIENT_SOCK)
            elseif cmd:match("^QUIT") then
                ftp_send_quit(FTP_CLIENT_SOCK)
                break
            elseif cmd:match("^SYST") then
                ftp_send_syst(FTP_CLIENT_SOCK)
            elseif cmd:match("^PASV") then
                ftp_send_pasv(FTP_CLIENT_SOCK)
            elseif cmd:match("^PORT") then
                ftp_send_port(FTP_CLIENT_SOCK)
            elseif cmd:match("^LIST") then
                ftp_send_list(FTP_CLIENT_SOCK)
            elseif cmd:match("^PWD") then
                ftp_send_pwd(FTP_CLIENT_SOCK)
            elseif cmd:match("^CWD") then
                ftp_send_cwd(FTP_CLIENT_SOCK)
            elseif cmd:match("^TYPE (.+)") then
                ftp_send_type(FTP_CLIENT_SOCK, cmd)
            elseif cmd:match("^CDUP") then
                ftp_send_cdup(FTP_CLIENT_SOCK)
            elseif cmd:match("^RETR") then
                ftp_send_retr(FTP_CLIENT_SOCK)
            elseif cmd:match("^STOR") then
                ftp_send_stor(FTP_CLIENT_SOCK)
            elseif cmd:match("^DELE") then
                ftp_send_dele(FTP_CLIENT_SOCK)
            elseif cmd:match("^RMD") then
                ftp_send_rmd(FTP_CLIENT_SOCK)
            elseif cmd:match("^MKD") then
                ftp_send_mkd(FTP_CLIENT_SOCK)
            elseif cmd:match("^RNFR") then
                ftp_send_rnfr(FTP_CLIENT_SOCK)
            elseif cmd:match("^RNTO") then
                ftp_send_rnto(FTP_CLIENT_SOCK)
            elseif cmd:match("^SIZE") then
                ftp_send_size(FTP_CLIENT_SOCK)
            elseif cmd:match("^REST") then
                ftp_send_rest(FTP_CLIENT_SOCK)
            elseif cmd:match("^FEAT") then
                ftp_send_feat(FTP_CLIENT_SOCK)
            elseif cmd:match("^APPE") then
                ftp_send_appe(FTP_CLIENT_SOCK)
            else
                ftp_send_message(FTP_CLIENT_SOCK, "502 Unable to process command: " .. cmd)
            end
        end
        sceNetSocketClose(FTP_CLIENT_SOCK)
    end
end

function ftp_listen_server(ftp_port)
    local server_sock = sceNetSocket(AF_INET, SOCK_STREAM, 0)
    if server_sock < 0 then
        error("sceNetSocket() error: " .. get_error_string())
    end

    local s_enable = bump.alloc(4)
    local s_sockaddr_in = bump.alloc(16) -- sizeof(sockaddr_in)
    local s_sockaddr_len = 16

    memory.write_dword(s_enable, 1)
    if sceNetSetsockopt(server_sock, 0xffff, 4, s_enable, 4) < 0 then
        error("sceNetSetsockopt() error: " .. get_error_string())
    end

    memory.write_byte(s_sockaddr_in + 1, AF_INET)
    memory.write_word(s_sockaddr_in + 2, sceNetHtons(ftp_port))
    memory.write_dword(s_sockaddr_in + 4, sceNetHtonl(INADDR_ANY))

    if sceNetBind(server_sock, s_sockaddr_in, s_sockaddr_len) < 0 then -- 16 being size of sockaddr_in
        error("sceNetBind() error: " .. get_error_string())
    end

    -- if we've come this far, then good.
    if sceNetListen(server_sock, 128) < 0 then
        error("sceNetListen() error: " .. get_error_string())
    end

    -- Todo!
    -- Spawn a thread to accept incoming clients.
    -- Add commands, such as LIST, PWD, USER, PASV, PORT etc...

    sceNetInetPton(AF_INET, "127.0.0.1", FTP_PS4_ADDR)
    while true do
        ftp_client_thread(server_sock)
        break -- early exit.
    end

    -- aight, we closing this connection for now.
    if sceNetSocketClose(server_sock) < 0 then
        error("sceNetSocketClose() error: " .. get_error_string())
    end
    
end

function main()
    syscall.resolve({
        recvfrom = 29, -- recv.
        getsockname = 32,
        access = 33,
        readlink = 58,
        sendto = 133, -- send.
        stat = 188,
        getdirentries = 196,
        getdents = 272,
        sendfile = 393,
    })

    LOG_FILE = FTP_FILE_LOG_PATH .. "ftp.txt"
    log_fd = io.open(LOG_FILE, "w")
    log_fd:write("test from ftp payload.")
    log_fd:close()

    ftp_listen_server(1337)
end

main()

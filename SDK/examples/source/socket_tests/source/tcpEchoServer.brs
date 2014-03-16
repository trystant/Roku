function InitTCPEchoServer(localPort as Integer, msgPort=invalid as Dynamic) as Dynamic
    this = CreateObject("roAssociativeArray")
    this.name = "TCPEchoServer"
    this.msgPort = msgPort
    this.localPort = localPort
    this.reset = tcp_echo_server_reset
    this.setup = tcp_echo_server_setup
    this.iterate = echo_server_iterate
    this.handle = tcp_echo_server_handle_message
    this.status = tcp_echo_server_status
    this.reset()
    return this
end function

function tcp_echo_server_reset() as Boolean
    m.sockets = createobject("roAssociativeArray")
    server = InitSocket(m.name,"roStreamSocket",m.msgPort,m.localPort)
    m.serverID = Stri(server.id)
    m.sockets[m.serverID]=server
    return server<>invalid
end function

function tcp_echo_server_setup() as Boolean
    server = m.sockets[m.serverID]
    server.sock.listen(3)
    return server.sock.eOk()
end function

function tcp_echo_server_handle_message(msg as Dynamic) as Boolean
    sockID = Stri(msg.getSocketID())
    if sockID=invalid then return false
    m.lastSockID = sockID
    sock = m.sockets[sockID]
    if sockID=m.serverID
        client = sock.accept()
        if client<>invalid then m.sockets[Stri(client.id)] = client
    else if sock.receive()
        if sock.sock.eSuccess()
            'print m.name; " receive: "; sock.status
            sock.send(sock.message)
        endif
    else
        m.sockets.delete(sockID)
    end if
    return sock.sock.eOk()
end function

function tcp_echo_server_status() as String
    lsi = m.lastSockID
    if lsi<>invalid
        ls = m.sockets[lsi]
        if ls<>invalid then return ls.status else return "socket "+lsi+" closed"
    else
        return "no activity"
    end if
end function


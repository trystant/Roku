function InitTCPEchoClient(serverAddress as String, msgPort=invalid as Dynamic, localPort=0 as Integer) as Dynamic
    this = CreateObject("roAssociativeArray")
    this.name = "TCPEchoClient"
    this.msgPort = msgPort
    this.localPort = localPort
    this.serverAddress = serverAddress
    this.iteration = 0
    this.sent = false
    this.reset = tcp_echo_client_reset
    this.setup = tcp_echo_client_setup
    this.connect = tcp_echo_client_connect
    this.iterate = this.connect
    this.status = echo_client_status
    return this
end function

function tcp_echo_client_reset() as Boolean
    m.client = InitSocket(m.name, "roStreamSocket", m.msgPort, m.localPort)
    return m.client<>invalid
end function

function tcp_echo_client_setup() as Boolean
    return m.reset() and m.connect()
end function

function tcp_echo_client_connect()
    m.client.connect(m.serverAddress)
    connected =  m.client.sock.isConnected()
    if connected 
        if m.msgPort=invalid then m.iterate = echo_client_iterate else m.iterate = echo_client_async_iterate
    end if 
    return m.client.sock.eOK()
end function

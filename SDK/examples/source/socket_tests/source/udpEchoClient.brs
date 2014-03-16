function InitUDPEchoClient(serverAddress as String, msgPort=invalid as Dynamic, localPort=0 as Integer) as Dynamic
    this = CreateObject("roAssociativeArray")
    this.name = "UDPEchoClient"
    this.msgPort = msgPort
    this.localPort = localPort
    this.serverAddress = serverAddress
    this.iteration = 0
    this.sent = false
    this.reset = udp_echo_client_reset
    this.setup = udp_echo_client_setup
    this.connect = udp_echo_client_connect
    this.iterate = echo_client_iterate
    this.status = echo_client_status
    return this
end function

function udp_echo_client_reset() as Boolean
    m.client = InitSocket(m.name,"roDatagramSocket",m.msgPort,m.localPort)
    return m.client<>invalid
end function

function udp_echo_client_setup() as Boolean
    return m.reset() and m.connect()
end function

function udp_echo_client_connect()
    m.client.connect(m.serverAddress)
    return m.client.sock.eOK()
end function


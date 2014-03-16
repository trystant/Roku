function InitSocket(title as String, socketType as String, msgPort=invalid as Dynamic, port=0 as Integer) as Dynamic
    this = CreateObject("roAssociativeArray")
    this.title = title
    this.socketType = socketType
    this.msgPort = msgPort
    this.port = port
    this.status = "new"
    this.reset = socket_create
    this.reset()
    return this
end function

function WrapSocket(title as String, sock as Dynamic, msgPort=invalid as Dynamic) as Dynamic
    if sock=invalid then return invalid
    this = CreateObject("roAssociativeArray")
    this.title = title
    this.msgPort = msgPort
    this.sock = sock
    this.id = sock.getID()
    this.status = "wrapped"
    this.reset = socket_init
    this.reset()
    return this
end function

function socket_create()
    sock = CreateObject(m.socketType)
    address = CreateObject("roSocketAddress")
    address.setPort(m.port)
    address.setHostName("0.0.0.0")
    sock.setAddress(address)
    m.sock = sock
    m.id = sock.getID()
    m.status = "sock id"+Stri(m.id)+" bound to " + sock.getAddress().getAddress()
    m.init = socket_init
    m.init()
end function

function socket_init()
    m.send = socket_send
    m.receive = socket_receive
    m.connect = socket_connect
    m.accept = socket_accept
    m.close = socket_close
    m.sock.setSendTimeout(5)
    m.sock.setReceiveTimeout(100)
    m.sock.setMessagePort(m.msgPort)
    m.sock.notifyReadable(m.msgPort<>invalid)
    m.iteration = 0
    print "Socket: "; m.title; " "; m.status
end function

function socket_send(message="" as String) as Boolean
    if Len(message)=0
        m.iteration = m.iteration + 1
        message = m.title + " message #"+Stri(m.iteration)
    end if
    sent = m.sock.sendStr(message)
    if sent>0
        toAddress = m.sock.getSendToAddress()
        toStr = toAddress.getAddress()
        m.status = "sent to " + toStr + " '" + message + "'"
    else if m.sock.eOk()
        m.status = "send not ready"
    else
        m.status = "send error"
        return false
    end if
    return m.sock.eOk()
end function

function socket_receive() as Boolean
    m.message = m.sock.receiveStr(127)
    if m.message=invalid
        if m.sock.eOK()
            m.status = "receive not ready"
        else
            m.status = "receive error" 
            return false
        end if
    else if Len(m.message)=0
        print "Socket: peer closed"; m.sock.getReceivedFromAddress().getAddress()
        m.close()
        return false
    else
        fromAddress = m.sock.getReceivedFromAddress()
        fromStr = fromAddress.getAddress()
        m.status = "received from " + fromStr + " '" + m.message + "'"
    end if
    return m.sock.eOk()
end function

function socket_connect(serverAddress as Dynamic) as Boolean
    if m.server=invalid and serverAddress<>invalid
        m.server = CreateObject("roSocketAddress")
        m.server.setAddress(serverAddress)
        m.sock.setSendToAddress(m.server)
        print "Socket: connecting to "; m.sock.getSendToAddress().getAddress()
    end if
    if type(m.sock)="roStreamSocket"
        m.sock.connect()
        connected = m.sock.isConnected()
        if connected then m.status = "connected"
        print "Socket: connected to "; m.sock.getSendToAddress().getAddress()
    end if
    return m.sock.eOK()
end function

function socket_accept() as Dynamic
    client = WrapSocket(m.title, m.sock.accept(), m.msgPort)
    if client<>invalid
        client.sock.notifyReadable(true)
        fromString = "<null>"
        fromAddress = client.sock.getReceivedFromAddress()
        if (fromAddress<>invalid) fromString = fromAddress.getAddress()
        m.status = "accepted connection from " + fromString
    end if
    return client
end function

function socket_close()
    m.status = "closed"
    m.sock.notifyReadable(false)
    m.sock.setMessagePort(invalid)
    m.sock.close()
end function

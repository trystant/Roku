function Main()
    m.msgPort = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.setMessagePort(m.msgPort)
    screen.show()
    print "Main: starting Socket Test"
    test = InitTCPEchoServer(50104, m.msgPort)
    'test = InitTCPEchoClient("10.1.1.6:50104", m.msgPort)
    'test = InitUDPEchoClient("10.1.1.6:50102", m.msgPort)
    'test = InitOptionsTest()
    TestLoop(test)
    print "Main: exiting Socket Test"
end function

function TestLoop(test as Dynamic) as Boolean
    if test=invalid return false
    print "Main: starting test "; test.name
    while test.setup()
        continue = true
        while continue
            if not test.doesexist("handle")
                continue = test.iterate()
                print "Main: "; test.name; " "; test.status()
            end if
            if checkClose(test) return true
        end while
        if checkClose(test) return true
    end while
    print "Main: exiting test "; test.name
    return true
end function

function checkClose(test as Object) as Boolean
    msg = wait(1000,m.msgPort)
    tm = type(msg)
    if tm="roParagraphScreenEvent" and msg.isScreenClosed()
        print "Main: Screen closed"
        return true
    else if tm="roSocketEvent"
        if test.doesexist("handle") then test.handle(msg)
        print "Main: "; test.name; " "; test.status()
    else if msg=invalid
        print "Main: idle"
    else
        print "Unhandled message type "; tm
    end if
    return false
end function

' these are common to several tests, called via AA

function echo_client_iterate() as Boolean
    return m.client.send() and m.client.receive() 
end function

function echo_client_async_iterate() as Boolean
    if m.sent
        if not m.client.receive() then return false
        if m.client.sock.eSuccess() then m.sent = false          
    end if
    if not m.sent
        if not m.client.send() then return false
        if m.client.sock.eSuccess() then m.sent = true
    end if
    return m.client.sock.eOK()
end function

function echo_client_status() as String
    if m.client<>invalid then status = m.client.status else status = "no client"
    return status
end function

function echo_server_iterate() as Boolean
    return m.client.receive() and m.client.send(m.client.message)
end function



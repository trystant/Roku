function InitOptionsTest() as Object
    this = CreateObject("roAssociativeArray")
    this.name = "SocketOptions"
    this.all_pass = true
    this.setup = options_simple_test_all
    this.iterate = options_null
    this.checkResult = options_check_result
    this.base = options_base
    this.test = options_test
    return this
end function

function options_simple_test_all() as Boolean
    m.sockType = "roDatagramSocket"
    m.special = options_cast
    m.test()

    m.sockType = "roStreamSocket"
    m.special = options_connection
    m.test()

    print m.name; ": all results pass "; m.all_pass
    return false ' one shot
end function

function options_test()
    m.sock = CreateObject(m.sockType)
    if (m.sock<>invalid)
        m.base()
        m.special()
    else
        print m.name; ": couldn't create "; m.sockType
    end if
end function

function options_check_result(title as String, result as Boolean)
    if result then status = "succeeds" else status = "failed"
    print m.name; ": test "; m.sockType; " "; title; " "; status
    m.all_pass = m.all_pass and result
end function

function options_null() as Boolean
    return false
end function

function options_base()
    sock = m.sock

    hops = 17
    m.checkResult("TTL", sock.setTTL(hops) and sock.getTTL()=hops)

    enabled = true
    m.checkResult("ReuseAddr:true", sock.setReuseAddr(enabled) and sock.getReuseAddr()=enabled)

    enabled = false
    m.checkResult("ReuseAddr:false", sock.setReuseAddr(enabled) and sock.getReuseAddr()=enabled)

    enabled = true
    m.checkResult("OOBInline:true", sock.setOOBInline(enabled) and sock.getOOBInline()=enabled)

    enabled = false
    m.checkResult("OOBInline:false", sock.setOOBInline(enabled) and sock.getOOBInline()=enabled)

    secs = 11
    m.checkResult("ReceiveTimeout", sock.setReceiveTimeout(secs) and sock.getReceiveTimeout()=secs)

    secs = 15
    m.checkResult("SendTimeout", sock.setSendTimeout(secs) and sock.getSendTimeout()=secs)

    buf_size = 17 * 1024
    m.checkResult("SendBuf", sock.setSendBuf(buf_size) and sock.getSendBuf()=2*buf_size)

    buf_size = 31 *1024
    m.checkResult("RcvBuf", sock.setRcvBuf(buf_size) and sock.getRcvBuf()=2*buf_size)

    enabled = true
    m.checkResult("DontRoute:true", sock.setDontRoute(enabled) and sock.getDontRoute()=enabled)

    enabled = false
    m.checkResult("DontRoute:false", sock.setDontRoute(enabled) and sock.getDontRoute()=enabled)
end function

function options_cast()
    sock = m.sock

    enabled = true
    m.checkResult("Broadcast:true", sock.setBroadcast(enabled) and sock.getBroadcast()=enabled)

    enabled = false
    m.checkResult("Broadcast:false", sock.setBroadcast(enabled) and sock.getBroadcast()=enabled)

    group = CreateObject("roSocketAddress")
    group.setHostName("239.255.255.250")
    m.checkResult("JoinGroup", sock.joinGroup(group))
    m.checkResult("DropGroup", sock.dropGroup(group))

    hops = 25
    m.checkResult("MulticastTTL", sock.setMulticastTTL(hops) and sock.getMulticastTTL()=hops)

    enabled = true
    m.checkResult("MulticastLoop:true", sock.setMulticastLoop(enabled) and sock.getMulticastLoop()=enabled)

    enabled = false
    m.checkResult("MulticastLoop:false", sock.setMulticastLoop(enabled) and sock.getMulticastLoop()=enabled)
end function

function options_connection()
    sock = m.sock

    enabled = true
    m.checkResult("KeepAlive:true", sock.setKeepAlive(enabled) and sock.getKeepAlive()=enabled)

    enabled = false
    m.checkResult("KeepAlive:false", sock.setKeepAlive(enabled) and sock.getKeepAlive()=enabled)

    seg_size = 440
    m.checkResult("MaxSeg", sock.setMaxSeg(seg_size) and sock.getMaxSeg()=seg_size)
    print m.name; ": "; m.sockType; " MaxSeg ("; seg_size; ")="; sock.getMaxSeg()

    enabled = true
    m.checkResult("NoDelay:true", sock.setNoDelay(enabled) and sock.getNoDelay()=enabled)

    enabled = false
    m.checkResult("NoDelay:false", sock.setNoDelay(enabled) and sock.getNoDelay()=enabled)

    secs = 0
    m.checkResult("Linger:0", sock.setLinger(secs) and sock.getLinger()=secs)

    secs = 123
    m.checkResult("Linger:123", sock.setLinger(secs) and sock.getLinger()=secs)
    print m.name; ": "; m.sockType; " Linger ("; secs; ")="; sock.getLinger()
end function

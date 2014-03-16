' ********************************************************************
' ********************************************************************
' **  Posterscreen routines
' **  Handle Poster screen events and volume change events
' **
' **  February 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

function create_poster(name, iconname, descline2, f, container)
    return {
	            sdposterurl: m.imageDir + iconname
	            hdposterurl: m.imagedir + iconname
	            shortdescriptionline1: name
	            shortdescriptionline2: descline2
	            RenderFunction: f
	            container: container
	        }
end function

function NewPosterScreen(port as object) as object
    s = CreateObject("roPosterScreen")
    s.SetMessagePort(port)
    s.SetListStyle("flat-category")
    return {
                screen: s
                getmsg: pstr_process
           }
end function

' ****************************************************************************
' Common wait processing loop that waits for messages on a port shared
' between the screen and the filesystem
' It does much of the work required for storage device events (add, remove)
' and returns that message to the caller
' If a regular screen message comes in, it will just return that to the caller
' ****************************************************************************
function pstr_process(screen, name) as object
    while true
	    print "posterscreen process: waiting for message"
        msg = WaitMessage(screen.getmessageport())
        print "pstr_process got message type=";type(msg)
        if msg.isScreenClosed()
	        print "got screen closed, return msg"
	        return msg
	    else  if msg.isRemoteKeyPressed()
    	    print "Got remote key, index=";msg.getindex();" msg="; msg.getmessage()
    	    return msg
    	else if msg.isListItemSelected() then
            print "list item selected | current show = "; msg.GetIndex()
            return msg
        else if msg.isListFocused() then
             print "list focused current list = "; msg.GetIndex()
             return msg
        endif
        
        if type(msg) = "roGridScreenEvent" then

            if msg.isListItemFocused() then
               print"list item focused current list = "; msg.GetIndex(); " show="; msg.getData()
            else
                print "ignoring unknown gridscreen event"
            endif
        else
            if msg.isStorageDeviceAdded() or msg.isStorageDeviceRemoved()
	            'resync available content
	            v = msg.getmessage()
	            print "got volume change: ";v
	            if msg.isStorageDeviceAdded()
       	            update_volume(screen, AddToVolumeList(v))
       	            v = v + "/"
   	                print "Volume added: "; v ; "label = "; lookupLabel(v)
	            endif
	            if msg.isStorageDeviceRemoved()
	                v = v + "/"
	                print "Volume removed: "; v
	                delete_volume(v)
	            endif
  	            update_content(screen, name)
	            return msg
            else if msg.isListItemFocused()
                print "Got new focus, index=";msg.getindex()
                return msg
            else if msg.isListItemInfo()
                print "Got Info button press for index=";msg.getindex()
                return msg
            else
                print "ignoring unknown event:"; type(msg)
            end if
        end if
    end while
end function

Sub SetContent(screen, content)
    screen.SetContentList(content)
    if content.IsEmpty() screen.ShowMessage("this folder is empty")
End Sub

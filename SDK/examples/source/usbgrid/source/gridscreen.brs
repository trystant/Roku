' ********************************************************************
' ********************************************************************
' **  Posterscreen routines
' **  Handle Poster screen events and volume change events
' **
' **  February 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

function create_gridposter(name, iconname, descline2, f, container)
    return {
	            sdposterurl: m.imageDir + iconname
	            hdposterurl: m.imagedir + iconname
	            shortdescriptionline1: name
	            shortdescriptionline2: descline2
	            RenderFunction: f
	            container: container
	        }
end function

function NewGridScreen(port as object) as object
    s = CreateObject("roGridScreen")
    s.SetMessagePort(port)
    's.setdisplaymode("best-fit")
    s.setdisplaymode("scale-to-fill")
    s.SetGridStyle("flat-portrait")
    return {
                screen: s
                getmsg: pstr_process
           }
end function

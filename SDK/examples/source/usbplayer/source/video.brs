Function findvideos(filelist)
' return a list of files with playable video extensions
	return get_filelist(filelist, "^.+\.(?:mp4|m4v|mov|wmv|ts|mkv)$")
end Function

Function make_video_content(url)
    content = {}
    content.title = url
    content.StreamUrls = [ url ]
    content.streambitrates = [ 0 ]
    content.streamqualities = [ "SD" ]
    content.description = url
    content.HDPosterURL = m.imageDir + "icon-videos-hd.jpg"
    content.SDPosterURL = m.imageDir + "icon-videos-sd.jpg"
    content.contenttype = "episode"
    content.FullHD = true
    content.FrameRate = 24

    content.streamformat = "mp4"
    ' guess the filetype from the extension
    ' if other than mpeg 4
    extension = right(url,4)
    if (extension = ".wmv") or (extension = ".asf") or (extension = ".mkv")
	    content.streamformat = mid(extension, 2)
    endif
    return content
end Function 

Sub ShowVideo(container, content, selection, playbutton)
    url = content[selection].fullurl
    s = CreateObject("roVideoScreen")
    ' at the playback level, we ignore usb events, so use our own msgport
    ' this also cleans up easier as the port and any left over messages should go away when the port is destroyed
    
    port = CreateObject("roMessagePort")
    s.SetMessagePort(port)

    episode = make_video_content(url)
    mediacount = content.Count()
    showOrder = GenerateMediaOrder(mediacount, selection, container.repeatmode = 3)

    s.SetContent(episode)
    s.Show()
    repeatmode = container.repeatmode
'   Treat play button like select, do not make it repeat (unless repeating is already set in preferences)
'    if (playbutton)
'        if repeatmode = 0
'            repeatmode = 2 'sequential
'        endif
'    endif
    index = 0
    while true
        print "waiting for videoscreen event"
	    msg = waitmessage(port)
        print  "video msg:"; type(msg)
	    if msg.isScreenClosed()
	        print "screen closed - ignored"
	        'return
	    else if msg.isFullResult() or msg.isRequestFailed()
             print "full result/requestfailed type="; msg.gettype()
             if repeatmode = 0
                    return
             endif
             if repeatmode > 1
                index = index + 1
                if index >= mediacount
                    index = 0
                endif
                selection = showorder[index]
                print "index=";index;" new selection=";selection
             endif
             episode = make_video_content(content[selection].fullurl)
             s = CreateObject("roVideoScreen")
             port = CreateObject("roMessagePort")
             s.SetMessagePort(port)
             s.setContent(episode)
             s.Show()
	    else if msg.isPartialResult()
		    print "partial result - screen closed?"
		    return
	    else
	    	print "unknown event type:"; msg.GetType(); " msg: "; msg.GetMessage()
	    endif
    end while
End Sub

Sub showVideosCategories(item)
    container = item.container
    looping = true
    while looping
        content = []
        content.Push(create_poster("all "+container.name, "icon-folder-hd.jpg", str(container.files.Count())+ " files", ShowAllAlpha, container))
        content.Push(create_poster("By Folder", "icon-folder-hd.jpg", "Navigate file structure", Browse, container))
        looping = DoCategories(item, content)
    end while
end Sub

Sub VideoSettings(item)
    container = item.container
    while true
        posters = []
        desc1 = "Repeat set to "+rm_str(container.repeatmode)
        posters.Push(create_setting("Provider_Settings_Center_HD.png", desc1, doRepeatModeScreen) )
        result = dosetting(item.container, posters)
        if (result = -1) return
    end while
end Sub

Function newVideosContainer()
    container = newContentContainer("videos", findvideos, "icon-videos-hd.jpg", "icon-videos-sd.jpg", ShowVideo, videosettings)
    return container
end Function

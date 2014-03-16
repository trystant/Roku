Function findphotos(filelist)
' return a list of files with viewable image extensions
	return get_filelist(filelist, "^.+\.(?:jpg|png|gif)$")
end Function

Function make_photo_content(url)
    content = {}
    content.url = "file://" + url
    content.TextOverlayBody = url
    return content
end Function

sub doSlideShow(container, content, index, playbutton)
    s = CreateObject("roSlideShow")
    port = CreateObject("romessageport")
    s.SetMessagePort(port)
    s.setcontentlist( [make_photo_content(content[index].fullurl)] )
    s.setTextoverlayholdtime(2000)
    s.setPeriod(400000)
    s.setDisplayMode("best-fit")
    s.show()
    
    slidecount = content.Count()
    
    ' need to precompute order of the slideshow so if random, we can go backwards
    ' if repeat mode is 3 (random), generate a random sequence
    slideshowOrder = GenerateMediaOrder(slidecount, index, container.repeatmode = 3)
   
    do_next_photo = false
    do_prev_photo = false
    do_auto = false
    is_playing = false
'   If poster was started with playbutton go into slideshow mode    
    repeatmode = container.repeatmode
    if (playbutton)
        is_playing = true
        if repeatmode = 0
            repeatmode = 2 'sequential
        endif
    endif
    index = 0

    while true
        print "waiting for slideshow event, is_playing=";is_playing
	    msg = wait(4000, port)
	    if msg = invalid
	        if is_playing
                do_auto = 1
                do_next_photo = 1
	        endif
	    else
	        if msg.isScreenClosed() return
	        if msg.isRemoteKeyPressed() then
                button = msg.GetIndex()
                print "Remote Key button = "; button
                if button = 5 ' right
                   do_next_photo = true
                   is_playing = false
                else if button = -13     ' play button
                    if is_playing = false
                        is_playing = true
                        if repeatmode = 0
                            repeatmode = 2 ' go to sequential from no-repeat
                        endif
                    else
                        is_playing = false
                        do_next_photo = true
                        do_auto = true
                    endif
                else if button = 4 ' left
                    do_prev_photo = true
                    is_playing = false
                endif
            else if msg.isButtonPressed() then
                button = msg.GetIndex()
                print "button index="; button
            else if msg.isPaused()
                is_playing = false
            else if msg.isResumed()
                is_playing = true
                do_next_photo = true
                do_auto = true
                if repeatmode = 0
                    repeatmode = 2 ' go to sequential from no-repeat
                endif
            else
	            print "got msg type=";msg.gettype()
	        endif
	    endif
	    if do_next_photo
	        print "Do Next Photo"
	        if do_auto=false or repeatmode>1
	            index = index + 1
	            if index >= slidecount
	                index = 0
	            endif
	        endif
	        selection = slideshoworder[index]
            print "selected next index="; index; "selection=";selection
            s.clearContent()
            s.setContentList( [make_photo_content(content[selection].fullurl)] )
            s.setNext(0, true)
            s.Show()
            do_next_photo = false
            do_auto = false
	    endif
	    if do_prev_photo
	        print "Do Prev Photo"
	        index = index - 1
	        if index < 0
	            index = slidecount - 1
	        endif
	        selection = slideshoworder[index]
            print "selected prev index="; index; "selection=";selection
            s.clearContent()
            s.setContentList( [make_photo_content(content[selection].fullurl)] )
            s.setNext(0, true)
            s.Show()
            do_prev_photo = false
	    endif
    end while
end sub

sub showPhotosCategories(item)
    container = item.container
    looping = true
    while looping
        content = []
        content.Push(create_poster("all "+container.name, "icon-folder-hd.jpg", str(container.files.Count())+ " files", ShowAllAlpha, container))
        content.Push(create_poster("By Folder", "icon-folder-hd.jpg", "Navigate file structure", Browse, container))
        looping = DoCategories(item, content)
    end while
end sub

sub PhotoSettings(item)
    container = item.container
    while true
        posters = []
        desc1 = "Repeat set to "+rm_str(container.repeatmode)
        posters.Push(create_setting("Provider_Settings_Center_HD.png", desc1, doRepeatModeScreen) )
        result = dosetting(item.container, posters)
        if (result = -1) return
    end while
end sub

function newPhotosContainer()
    container = newContentContainer("photos", findphotos, "icon-photos-hd.jpg", "icon-photos-hd.jpg", doSlideshow, photosettings)
    return container
end function

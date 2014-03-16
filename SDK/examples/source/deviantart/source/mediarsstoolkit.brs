'**********************************************************
'**  DeviantART Example Application - slideshow and audioplayer
'**  March 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

' ********************************************************************
' ********************************************************************
' ***** Object Constructor
' ***** Object Constructor
' ********************************************************************
' ********************************************************************

Function CreateMediaRSSConnection()As Object
	rss = {
		port: CreateObject("roMessagePort"),
		http: CreateObject("roUrlTransfer"),

		DisplayUserFavorites: DisplayUserFavorites,
		DisplayDailyDeviations: DisplayDailyDeviations,
		DisplaySlideShow: DisplaySlideShow,
		GetPhotoListFromFeed: GetPhotoListFromFeed,
		}

	return rss
End Function

Function DisplaySetup(port as object)
	slideshow = CreateObject("roSlideShow")
	slideshow.SetMessagePort(port)
	slideshow.SetUnderscan(5.0)      ' shrink pictures by 5% to show a little bit of border (no overscan)
	slideshow.SetBorderColor("#6b4226")
	slideshow.SetMaxUpscale(8.0)
	slideshow.SetDisplayMode("best-fit")
	slideshow.SetPeriod(6)
	slideshow.Show()
	return slideshow
End Function


Sub DisplayUserFavorites()
	slideshow = DisplaySetup(m.port)

	photolist=m.GetPhotoListFromFeed("http://backend.deviantart.com/rss.xml?q=favby%3Alolly%2F359519")
	m.DisplaySlideShow(slideshow, photolist)
End Sub


Sub DisplayDailyDeviations()
	slideshow = DisplaySetup(m.port)

	photolist=m.GetPhotoListFromFeed("http://backend.deviantart.com/rss.xml?q=special%3Add")
	m.DisplaySlideShow(slideshow, photolist)
End Sub


Function GetPhotoListFromFeed(feed_url) As Object

	print "GetPhotoListFromFeed: ";feed_url
	m.http.SetUrl(feed_url)
	xml=m.http.GetToString()
	rss=CreateObject("roXMLElement")
	if not rss.Parse(xml) then stop
	print "rss@version=";rss@version

	pl=CreateObject("roList")
	for each item in rss.channel.item
		pl.Push(newPhotoFromXML(m.http, item))
		print "photo title=";pl.Peek().GetTitle()
	next

	return pl

End Function


Function newPhotoFromXML(http As Object, xml As Object) As Object
  photo = {http:http, xml:xml, GetURL:pGetURL}
  photo.GetTitle=function():return m.xml.title.GetText():end function
  return photo
End Function


Function pGetURL()
	for each c in m.xml.GetNamedElements("media:content")
		if c@medium="image" then return c@url
	next

	return invalid
End Function


Sub DisplaySlideShow(slideshow, photolist)

print "in DisplaySlideShow"
    'using SetContentList()
    contentArray = CreateObject("roArray", photolist.Count(), true)
	for each photo in photolist
		print "---- new DisplaySlideShow photolist loop ----"
		url = photo.GetURL()
		if url<>invalid then
        	aa = CreateObject("roAssociativeArray")
			aa.Url = url
			contentArray.Push(aa)
			print "PRELOAD TITLE: ";photo.GetTitle()
		end if
	next
    slideshow.SetContentList(contentArray)

    'this is an alternate technique for adding content using AddContent():
	'aa = CreateObject("roAssociativeArray")
	'for each photo in photolist
	'	print "---- new DisplaySlideShow photolist loop ----"
	'	url = photo.GetURL()
	'	if url<>invalid then
	'		aa.Url = url
	'		slideshow.AddContent(aa)
	'		print "PRELOAD TITLE: ";photo.GetTitle()
	'	end if
	'next


    btn_more_from_author = 0
    btn_similar          = 1
    btn_bookmark         = 2
    btn_hide             = 3

waitformsg:
	msg = wait(0, m.port)
	print "DisplaySlideShow: class of msg: ";type(msg); " type:";msg.gettype()
	'for each x in msg:print x;"=";msg[x]:next
	if msg <> invalid then							'invalid is timed-out
		if type(msg) = "roSlideShowEvent" then
    		if msg.isScreenClosed() then
	    		return
    		else if msg.isButtonPressed() then
                print "Menu button pressed: " + Stri(msg.GetIndex())
                'example button usage during pause:
                'if msg.GetIndex() = btn_hide slideshow.ClearButtons()
    		else if msg.isPlaybackPosition() then
	    		onscreenphoto = msg.GetIndex()
		    	print "slideshow display: " + Stri(msg.GetIndex())
    		else if msg.isRemoteKeyPressed() then
    			print "Button pressed: " + Stri(msg.GetIndex())
    		else if msg.isRequestSucceeded() then
	    		print "preload succeeded: " + Stri(msg.GetIndex())
    		elseif msg.isRequestFailed() then
    			print "preload failed: " + Stri(msg.GetIndex())
    		elseif msg.isRequestInterrupted() then
    			print "preload interrupted" + Stri(msg.GetIndex())
    		elseif msg.isPaused() then
                print "paused"
                'example button usage during pause:
                'buttons will only be shown in when the slideshow is paused
                'slideshow.AddButton(btn_more_from_author, "more photos from this author")
                'slideshow.AddButton(btn_similar, "similar images")
                'slideshow.AddButton(btn_bookmark, "mark as favorite")
                'slideshow.AddButton(btn_hide, "hide buttons")
    		elseif msg.isResumed() then
                print "resumed"
                'example button usage during pause:
                'slideshow.ClearButtons()
            end if
        end if
	end if
	goto waitformsg
End Sub

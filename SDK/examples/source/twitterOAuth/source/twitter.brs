'**********************************************************
'**  twitter OAuth example
'**  May 2010
'**  Copyright (c) 2010 Roku Inc. All Rights Reserved.
'**********************************************************

'
' application wide twitter object
'
' It can be used to perform general twitter queries
' It should have a lifetime that matches the app lifetime
' since this will initialize and release twitter specific resources.
'

Function Twitter() As Object
    ' global singleton
    ' if m.twitter=invalid then m.twitter = InitTwitter()
    ' trust that main has done this already and remove check for better performance
    return m.twitter
End Function

Function InitTwitter() As Object
    ' constructor
    this = CreateObject("roAssociativeArray")
    this.server = "api.twitter.com"
    this.protocol = "https"
    this.prefix = this.protocol + "://" + this.server + "/"

    this.ParseTweets = parse_status_response
    this.ShowTweetCanvas = show_tweet_canvas
    
    print "Twitter: init complete"
    return this
End Function


Function init_tweet_item() As Object
    o = CreateObject("roAssociativeArray")

    o.ImageSource      = ""
    o.Message          = ""
    o.UserName         = ""

    return o
End Function

Function parse_status_response(xml As Object, tweetArray As Object) As Void

    tweetElements = xml.GetChildElements()
    tweetCount = 0

    for each tweet in tweetElements

        item = init_tweet_item()

        item.Message          = validstr(tweet.text.GetText()) 
        item.UserName         = validstr(tweet.user.screen_name.GetText()) 
        item.ImageSource      = validstr(tweet.user.profile_image_url.GetText())

        tweetCount = tweetCount + 1
        tweetArray.Push(item)
    end for

End Function

Function show_tweet_canvas() As Void

    http = NewHttp(m.prefix+"1/statuses/user_timeline.xml?screen_name=RokuPlayer")
    oa = Oauth()
    oa.sign(http,false)
    rsp = http.getToStringWithTimeout(10)

    xml=CreateObject("roXMLElement")
    if not xml.Parse(rsp) then
        print "Can't parse feed"
        sleep(25)
        return
    endif

    if islist(xml.GetBody()) = false then
        print "no feed body found"
        sleep(25)
        return 
    endif

    tweetArray = CreateObject("roArray", 100, true)
    m.ParseTweets(xml, tweetArray)

    canvasArray = CreateObject("roArray", 100, true)
    canvasCount = 0
    tweetCount% = 0
    tweetColumn% = 0
    tweetRow% = 0
    for each tweet in tweetArray

        canvasItem = CreateObject("roAssociativeArray")
        canvasItem.url =  tweet.ImageSource
        targetRect = CreateObject("roAssociativeArray")
        targetRect.x = tweetColumn% * 540 + 36  
        targetRect.y = tweetRow% * 135 + 36           
        targetRect.w = 48
        targetRect.h = 48
        canvasItem.TargetRect = targetRect
        canvasCount = canvasCount + 1
        canvasArray.Push(canvasItem)

        canvasItem = CreateObject("roAssociativeArray")
        canvasItem.Text = tweet.UserName
        canvasItem.TextAttrs = {Color:"#FFC8AB14", Font:"Medium", HAlign:"HLeft",VAlign:"VCenter", Direction:"LeftToRight"}
        targetRect = CreateObject("roAssociativeArray")
        targetRect.x = tweetColumn% * 540 + 60 + 36
        targetRect.y = tweetRow% * 135 + 36
        targetRect.w = 210 
        targetRect.h = 45  
        canvasItem.TargetRect = targetRect
        canvasCount = canvasCount + 1
        canvasArray.Push(canvasItem)

        canvasItem = CreateObject("roAssociativeArray")
        canvasItem.Text = tweet.Message
        canvasItem.TextAttrs = {Color:"#FFCCCCCC", Font:"Medium", HAlign:"HLeft",VAlign:"VCenter", Direction:"LeftToRight"}
        targetRect = CreateObject("roAssociativeArray")
        targetRect.x = tweetColumn% * 540 + 60 + 36
        targetRect.y = tweetRow% * 135 + 36 + 45
        targetRect.w = 480 ' 
        targetRect.h = 90  ' two rows of text
        canvasItem.TargetRect = targetRect
        canvasCount = canvasCount + 1
        canvasArray.Push(canvasItem)

        tweetCount% = tweetCount% + 1
        tweetColumn% = tweetCount% / 4
        tweetRow% = tweetCount% - (tweetColumn% * 4)

        print "tweetColumn% = "; tweetColumn%; "tweetRow% = ";tweetRow%
        
        ' only 8 tweets displayed on HD screen 
        if tweetCount% = 8 then
            exit for
        endif
        
    end for

    showImageCanvas(canvasArray)
    
End Function

'** Application startup
Sub Main()
    facade = CreateObject("roImageCanvas")
    facade.SetBackgroundColor("#00000000")
    facade.show()

    m.display_images=true
    SimpleMetadataTest()
    'm.display_images=false
    'SimpleMetadataStressTest()
End Sub

Sub SimpleMetadataStressTest()
    for i=1 to 100000 step 1
        SimpleMetadataTest()
    end for
End Sub

Sub SimpleMetadataTest()
    http = CreateObject("roUrlTransfer")
    http.SetPort(CreateObject("roMessagePort"))
    http.SetUrl("http://download.lisztonian.com/music/download/Sonata+in+F+Major+K+300k+332+III+Allegro-101.mp3")
    http.GetToFile("tmp:/download.mp3")
    ReadImageMetadata("pkg:/images/img_1858.jpg")
    ReadAudioMetadata("tmp:/download.mp3") ' cover art = no for this mp3 file... Try replacing with your own urls that have cover art
End Sub

Sub ReadImageMetadata(filename):
    meta = CreateObject("roImageMetadata")
    meta.SetUrl(filename)
    print "------------- GetRawExif() ----------------------"
    allexif = meta.GetRawExif()
    printAA(allexif)
    print "------------- GetMetadata() ---------------------"
    simple = meta.GetMetadata()
    printAA(simple)
    print "------------- GetRawExifTag() -------------------"
    rawexiftag = meta.GetRawExifTag(2,36868)
    printAA(rawexiftag)
    print "------------- GetThumbnail() --------------------"
    thumbnail = meta.GetThumbnail()
    if (thumbnail <> invalid) then
        DisplayBytesAsImage(thumbnail.bytes,thumbnail.type)
    end if
End Sub

Sub ReadAudioMetadata(filename):
    meta = CreateObject("roAudioMetadata")
    meta.SetUrl(filename)
    print "------------- GetTags() -------------------------"
    tags = meta.GetTags()
    printAA(tags)
    print "------------- GetAudioProperties() --------------"
    properties = meta.GetAudioProperties()
    printAA(properties)
    print "------------- GetCoverArt() ---------------------"
    art = meta.GetCoverArt()
    if (art <> invalid) then
        DisplayBytesAsImage(art.bytes,art.type)
    end if
End Sub

Sub DisplayBytesAsImage(bytes, image_type)
    if (not m.display_images) then return
    
    if (bytes = invalid) then
        return
    end if
        
    if (m.count = invalid)
        m.count = 0
    end if
    m.count = m.count + 1
    image_ext=""
    if (image_type = "image/jpeg" or image_type = "jpg") then
        image_ext = "jpg"
    else if (image_type = "image/png" or image_type = "png") then
        image_ext = "png"
    else
        image_ext = "jpg"
    end if
    
    tmp_img = "tmp:/tmp_img_" + str(m.count) + "." + image_ext
    if (m.tmp_img <> invalid) then
        DeleteFile(m.tmp_img)
    end if
    m.tmp_img = tmp_img
    bytes.Writefile(m.tmp_img)
    DisplayImage(m.tmp_img)
End Sub

Sub DisplayImage(image_url)
    print "Displaying - " ; image_url ; " press up to continue..." 
    canvas = CreateObject("roImageCanvas")
    prt = CreateObject("roMessagePort")
    canvas.SetMessagePort(prt)
    canvas.SetBackgroundColor("#000000")
    sr = canvas.GetCanvasRect()

    c = {url:image_url, targetrect:{x:50,y:50}}
    canvas.SetContentList(c)
    canvas.Show()

    while(true)
        msg = wait(0,prt) 
        if (type(msg) = "roImageCanvasEvent") then
            if (msg.isRemoteKeyPressed()) then
                i = msg.GetIndex()
                print "Key Pressed - " ;  i.ToStr()
                if (i = 2) then
                    canvas.PurgeCachedImages()
                    canvas.close()
                    canvas = invalid
                    return
                end if
            else if (msg.isScreenClosed()) then
                return
            end if
        end if
    end while
End Sub

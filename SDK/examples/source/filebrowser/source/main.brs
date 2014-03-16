' ********************************************************************
' ********************************************************************
' **  Roku File Browser Channel (BrightScript)
' **
' **  January 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

Sub Main()
    m.port = CreateObject("roMessagePort")
    m.filesystem = CreateObject("roFilesystem")
    m.filesystem.SetMessagePort(m.port)
    app = CreateObject("roAppManager")
    app.SetTheme({
        OverhangOffsetSD_X: "64"
        OverhangOffsetSD_Y: "40"
        OverhangSliceSD: "pkg:/images/overhang-background-sd.png"
        OverhangLogoSD:  "pkg:/images/logo-sd.png"

        OverhangOffsetHD_X: "108"
        OverhangOffsetHD_Y: "60"
        OverhangSliceHD: "pkg:/images/overhang-background-hd.png"
        OverhangLogoHD:  "pkg:/images/logo-hd.png"

        BackgroundColor:       "#404040"
        PosterScreenLine1Text: "#18c314"
        BreadcrumbTextRight:   "#18c314"
    })
    Descend(CreateObject("roPath", ""))
End Sub

Sub Descend(path)
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(m.port)
    screen.SetBreadcrumbText("", path)
    screen.SetListStyle("flat-category")
    screen.Show()
    content = GetContent(path)
    SetContent(screen, content)

    while true
        msg = WaitMessage(m.port)
        if msg.isScreenClosed() or DeviceRemoved(path) return

        if msg.isStorageDeviceAdded() or msg.isStorageDeviceRemoved()
            content = GetContent(path)
            SetContent(screen, content)
        else if msg.isListItemSelected() and msg.GetIndex() < content.Count()
            item = content[msg.GetIndex()]
            if item.RenderFunction = invalid
                Descend(CreateObject("roPath", item.FullPath))
            else
                item.RenderFunction(item, m.port)
            end if
            if DeviceRemoved(path) return
            content = GetContent(path)
            SetContent(screen, content)
        end if
    end while
End Sub

'This function is used to report status on the current device.  If the current
'path is no longer valid because a device has been removed, then return true.
Sub DeviceRemoved(path) As Boolean
    return path.IsValid() and not m.filesystem.Exists(path)
End Sub

'This is a wait wrapper that ignores invalid message objects (from debugging)
Sub WaitMessage(port) As Object
    while true
        msg = wait(0, port)
        if msg <> invalid return msg
    end while
End Sub

'Turns an integer into a comma-separated numeric representation (1,234,567)
Sub PrettyInteger(value) as String
    s = value.tostr()
    r = CreateObject("roRegex", "(\d+)(\d{3})", "")
    while r.IsMatch(s): s = r.Replace(s, "\1,\2"): end while
    return s
End Sub

Sub GetContent(path) As Object
    mimetypes = { 'map known extensions to pseudo-mime-type here
        x_3g2: { type: "video", format: "mp4" }
        x_3gp: { type: "video", format: "mp4" }
        x_m4v: { type: "video", format: "mp4" }
        x_mp4: { type: "video", format: "mp4" }
        x_mov: { type: "video", format: "mp4" }
        x_mkv: { type: "video", format: "mkv" }
        x_wmv: { type: "video", format: "wmv" }
        x_ts:  { type: "video", format: "ts"  }
        x_m3u8:{ type: "video", format: "hls" }
        x_m4a: { type: "audio", format: "mp4" }
        x_mp3: { type: "audio", format: "mp3" }
        x_wma: { type: "audio", format: "wma" }
        x_mka: { type: "audio", format: "mka" }
        x_aif: { type: "audio", format: "pcm" }
        x_au:  { type: "audio", format: "pcm" }
        x_wav: { type: "audio", format: "pcm" }
        x_jpg: { type: "image" }
        x_png: { type: "image" }
        x_gif: { type: "image" }
        'Anything else belongs in the "other" category
    }
    renderers = { 'map pseudo-mime-type to display function
        image: RenderImage
        video: RenderAV
        audio: RenderAV
        other: RenderOther
    }

    content = []
    if path.IsValid()
        for each c in m.filesystem.GetDirectoryListing(path)
            cpath = CreateObject("roPath", path + "/" + c)
            info = m.filesystem.Stat(cpath)
            desc = invalid
            mimetype = invalid
            if info.type = "directory"
                mimetype = { type: "folder" }
            else if info.type = "file"
                mimetype = mimetypes["x_" + cpath.Split().extension.mid(1)]
                if mimetype = invalid mimetype = { type: "other" }
                desc = "size: " + PrettyInteger(info.size) + " bytes"
            end if
            if mimetype <> invalid content.Push({
                RenderFunction: renderers[mimetype.type]
                FullPath: cpath
                SDPosterUrl: "pkg:/images/icon-" + mimetype.type + "-sd.jpg"
                HDPosterUrl: "pkg:/images/icon-" + mimetype.type + "-hd.jpg"
                ShortDescriptionLine1: c
                ShortDescriptionLine2: desc
                StreamFormat: mimetype.format
            })
        end for
    else
        for each c in m.filesystem.GetVolumeList()
            c = c + "/"
            if c.left(3) = "ext" loc = "ext" else loc = "int"
            info = m.filesystem.GetVolumeInfo(c)
            label = c
            if info.label <> invalid and info.label <> ""
                label = label + " (" + info.label + ")"
            end if
            desc = invalid
            if info.blocks > 0
                usage = int(100.0 * info.usedblocks / info.blocks + 0.5)
                desc = "usage: " + usage.tostr() + "%"
            end if
            content.Push({
                FullPath: c
                SDPosterUrl: "pkg:/images/icon-phy" + loc + "-sd.jpg"
                HDPosterUrl: "pkg:/images/icon-phy" + loc + "-hd.jpg"
                ShortDescriptionLine1: label
                ShortDescriptionLine2: desc
            })
        end for
    end if
    return content
End Sub

Sub SetContent(screen, content)
    screen.SetContentList(content)
    if content.IsEmpty() screen.ShowMessage("this folder is empty")
End Sub

Sub RenderImage(item, port)
    s = CreateObject("roSlideShow")
    s.SetMessagePort(port)
    s.SetContentList([{ Url: "file://" + item.FullPath }])
    s.Show()
    while not WaitMessage(port).isScreenClosed(): end while
End Sub

Sub RenderAV(item, port)
    s = CreateObject("roVideoScreen")
    s.SetMessagePort(port)
    s.SetContent({
        Title: item.FullPath
        Stream: { url: "file://" + item.FullPath }
        StreamFormat: item.StreamFormat
    })
    s.Show()
    while not WaitMessage(port).isScreenClosed(): end while
End Sub

Sub RenderOther(item, port)
    s = CreateObject("roParagraphScreen")
    s.SetBreadcrumbText("", item.FullPath)
    s.SetMessagePort(port)
    s.AddButton(0, "done")
    s.Show()
    text = CreateObject("roByteArray")
    text.ReadFile(item.FullPath, 0, 1000)
    s.AddParagraph(text.ToAsciiString())
    while not WaitMessage(port).isButtonPressed(): end while
End Sub

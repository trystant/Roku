' *********************************************************
' *********************************************************
' **
' **  BrightScript Yahoo Flickr API
' **
' **  A. Wood, November 2009
' **
' **  Copyright (c) 2009 Anthony Wood. All Rights Reserved.
' **
' *********************************************************
' *********************************************************





' ********************************************************************
' ********************************************************************
' ***** Object Constructor
' ***** Object Constructor
' ********************************************************************
' ********************************************************************

Function CreateFlickrConnection(api_key, api_secret=invalid)As Object
	flickr = {
		api_key: api_key,
		api_secret: api_secret
		auth_token: RegRead("auth_token"),
		http: CreateObject("roUrlTransfer"),

		DisplayInterestingPhotos: DisplayInterestingPhotos,
		GetInterestingnessPhotoList: GetInterestingnessPhotoList,
		ExecServerAPI: ExecServerAPI,
		MakeApiSig: MakeApiSig,
		LinkAccount: LinkAccount,
		DisplayMyPhotoStream: DisplayMyPhotoStream,
		GetPhotoStreamPhotoList: GetPhotoStreamPhotoList,
		PrepDisplaySlideShow: PrepDisplaySlideShow,
		DisplaySlideShow: DisplaySlideShow,
		IsLinked: IsLinked,
		BrowseMySets: BrowseMySets,
		DisplayPhotoSet: DisplayPhotoSet,
		GetPhotoSetList: GetPhotoSetList,
		newPhotoSetFromXML: newPhotoSetFromXML,
		BrowseMyGroups: BrowseMyGroups,
		GetPublicGroupsList: GetPublicGroupsList,
		newGroupFromXML: newGroupFromXML,
		DisplayGroupPhotoPool: DisplayGroupPhotoPool,
		BrowseTags: BrowseTags,
		BrowseHotTags: BrowseHotTags,
		DisplayTaggedPhotos: DisplayTaggedPhotos,
		GetTaggedPhotoList: GetTaggedPhotoList,
		GetHotList: GetHotList,
		BrowsePhotoInfo: BrowsePhotoInfo,
		AddNextPhotoToSlideShow : 	AddNextPhotoToSlideShow,
		GetPhotoInfo : GetPhotoInfo,
		ProcessSlideShowEvent : ProcessSlideShowEvent, 
		DisplayNSIDPhotoStream: DisplayNSIDPhotoStream,
		digest : CreateObject("roEVPDigest"),
		md5 : function(str):ba=CreateObject("roByteArray"):m.digest.Setup("md5"):ba.FromAsciiString(str):return m.digest.process(ba):end function,
		}

	if flickr.auth_token<>invalid then
		rsp=flickr.ExecServerAPI("flickr.auth.checkToken",[])
		if rsp@stat="ok" then
			print "Valid auth token loaded from registry"
			flickr.perms=rsp.auth.perms.GetText()
			flickr.nsid=rsp.auth.user@nsid
			flickr.username=rsp.auth.user@username
			flickr.fullname=rsp.auth.user@fullname
		else
			print "invalid auth token in registry"
			print "Erasing Token from Registry"
			flickr.auth_token=invalid
			RegDelete("auth_token")
		end if
	end if

	return flickr

End Function

' ********************************************************************
' ********************************************************************
' ***** ExecServerAPI
' ***** ExecServerAPI
' ********************************************************************
' ********************************************************************

Function ExecServerAPI(method, param_list=[] As Object, authmode=m.auth_token<>invalid) As Object

	apiurlstr="http://api.flickr.com/services/rest/?method="+method+"&api_key="+m.api_key
	for each p in param_list
		apiurlstr=apiurlstr+"&"+p
	next

	if authmode and m.auth_token=invalid then
		print "Internal ERROR"
		stop
	end if

	if authmode then apiurlstr=apiurlstr+"&auth_token="+m.auth_token+"&api_sig="+m.MakeApiSig(method, param_list)

	'print "ExecServerAPI: ";method
	'print apiurlstr
	m.http.SetUrl(apiurlstr)
	xml=m.http.GetToString()
	rsp=CreateObject("roXMLElement")
	if not rsp.Parse(xml) then stop

	'print "EXITING ExecServerAPI with rsp@stat=";rsp@stat

	return rsp

End Function

' ********************************************************************
' ********************************************************************
' ***** DisplaySlideShow
' ***** DisplaySlideShow
' ********************************************************************
' ********************************************************************

Sub AddNextPhotoToSlideShow(ss, photolist)

	'print "--- AddNextPhotoToSlideShow Entry ---"
	
	if photolist.IsNext() then
		photo=photolist.Next()
		rsp=m.ExecServerAPI("flickr.photos.getSizes", ["photo_id="+photo.GetID()])
		'size=""
		s=invalid
		for each s in rsp.sizes.size
			'print "for each s: ";s@label
			if s@label="Large" then
				'size="b"
				exit for
			end if
		next
		if s<>invalid then 
			photo.Info={}
			photo.TagList=[]
			m.GetPhotoInfo(photo.GetID(), photo.Info, photo.TagList)
			photo.Info.url=s@source
			ss.AddContent(photo.Info)
		end if
	end if
End Sub

function PrepDisplaySlideShow()

	print "---- Prep DisplaySlideShow  ----"

	ss = CreateObject("roSlideShow")
	ss.Show()
    mp = CreateObject("roMessagePort")
    if mp=invalid then print "roMessagePort Create Failed":stop
    ss.SetMessagePort(mp)
	ss.SetPeriod(0)
	ss.SetDisplayMode("best-fit")
	ss.AddContent( {url : "file://pkg:/images/Logo_Overhang_Flickr_HD.png"} )
	
	return ss
	
end function

function ProcessSlideShowEvent(ss, msg, photolist, onscreenphoto)

	if type(msg)="roSlideShowEvent" then
		'print "roSlideShowEvent. Type ";msg.GetType();", index ";msg.GetIndex();", Data ";msg.GetData();", msg ";msg.GetMessage()
		if msg.isScreenClosed() then
			return true
		else if msg.IsPaused() then
			ss.SetTextOverlayIsVisible(true)
		else if msg.isRemoteKeyPressed() and msg.GetIndex()=3 and ss.CountButtons()=0 then
			ss.AddButton(0, "Browse Tags")
			ss.AddButton(1, "SlideShow Author")
			ss.AddButton(2, "Cancel")
		else if msg.IsResumed() then
			ss.SetTextOverlayIsVisible(false)
			ss.ClearButtons()
		else if msg.isButtonPressed() then
			ss.ClearButtons()
			ss.SetTextOverlayIsVisible(false)
			if msg.GetIndex()=0 then m.BrowseTags(photolist[onscreenphoto[0]-1].TagList)  ' -1 because flickr logo is photo zero
			if msg.GetIndex()=1 then m.DisplayNSIDPhotoStream(photolist[onscreenphoto[0]-1].GetOwner())
		else if msg.isPlaybackPosition()
			onscreenphoto[0]=msg.GetIndex()
			if onscreenphoto[0]=photolist.Count()   'last photo shown?
'					print "Resetart slide show..."
				ss.SetNext(0, false)
			end if
		end if
	end if
	
	return false
	
end function

Sub DisplaySlideShow(ss, photolist)

	print "---- Do DisplaySlideShow  ----"

	photolist.Reset()   ' reset ifEnum
	if not photolist.IsNext() then return
	sleep(1000) ' let photo decode faster; no proof this actually helps
	ss.SetPeriod(3)
	onscreenphoto=[0]  'using a list so i can pass reference instead of pass by value 
	port=ss.GetMessagePort()
	
'
' add all the photos to the slide show as fast as possible, while still processing events
'
	while photolist.IsNext()
		m.AddNextPhotoToSlideShow(ss, photolist)
		while true
			msg = port.GetMessage()
			if msg=invalid then exit while
			if m.ProcessSlideShowEvent(ss, msg, photolist, onscreenphoto) then return
		end while
	end while
	
	'
	' all photos have been added to the slide show at this point, so just process events
	'
	while true
		msg = wait(0, port)
		if m.ProcessSlideShowEvent(ss, msg, photolist, onscreenphoto) then return
	end while

End Sub


REM
REM newPhotoListFromXML
REM
REM    Takes an roXMLElement Object that is a list of <photo> ... </photo>
REM    Returns a BrightScript list of photo objects
REM

Function newPhotoListFromXML(http As Object, xmllist As Object, owner=invalid As dynamic) As Object

  photolist=CreateObject("roList")
  for each photo in xmllist
    photolist.Push(newPhotoFromXML(http, photo, owner))
  next
  return photolist
End Function

REM
REM newPhotoFromXML
REM
REM    Takes an roXMLElement Object that is an <photo> ... </photo>
REM    Returns an brs object of type Photo
REM       photo.GetTitle()
REM       photo.GetID()
REM       photo.GetURL()
REM      photo.GetOwner()
REM

Function newPhotoFromXML(http As Object, xml As Object, owner As dynamic) As Object
  photo = CreateObject("roAssociativeArray")
  photo.http=http
  photo.xml=xml
  photo.owner=owner
  photo.GetTitle=function():return m.xml@title:end function
  photo.GetID=function():return m.xml@id:end function
  photo.GetOwner=pGetOwner
  photo.GetURL=pGetURL
  return photo
End Function

Function pGetOwner() As String
  if m.owner<>invalid return m.owner
  return m.xml@owner
End Function

' size can be a single letter string
' default -  medium, 500 on longest side
' s small square 75x75
' t thumbnail, 100 on longest side
' m small, 240 on longest side
' b large, 1024 on longest side (only exists for very large original images)

Function pGetURL(size="") As String
  a=m.xml.GetAttributes()
  if size<>"" then size="_"+size
  url="http://farm"+a.farm+".static.flickr.com/"+a.server+"/"+a.id+"_"+a.secret+size+".jpg"
  'print url
  return url
End Function


REM
REM GetUserIDByURL
REM
REM takes the end of the Flickr user URL
REM

' todo -- use the new ExecServerAPI() call

Function GetUserIDByURL(userurl as String) As String

  m.http.SetUrl("http://api.flickr.com/services/rest/?method=flickr.urls.lookupUser&url=//flickr.com/photos/"+userurl+"/"+"&api_key=1beba5866bc14edec5bff26091cecc2c")
  xml=m.http.GetToString()

  root=CreateObject("roXMLElement")
  if not root.Parse(xml) then stop

  user_id=root.getBody().Peek().GetAttributes()["id"]
  'print "user_id: ";user_id

  return user_id

End Function

' ********************************************************************
' ********************************************************************
' ***** Auth Auth Auth Auth Auth
' ***** Auth Auth Auth Auth Auth
' ********************************************************************
' ********************************************************************


Function IsLinked() As Boolean

	return m.auth_token<>invalid

End Function

Function LinkAccount(mini_token) As Boolean

	'print "LinkAcccout: mini_token=";mini_token
	api_sig = m.MakeApiSig("flickr.auth.getFullToken",[],mini_token)
	'print api_sig
	apiurlstr="http://api.flickr.com/services/rest/?method=flickr.auth.getFullToken&api_key="+m.api_key+"&mini_token="+mini_token+"&api_sig="+api_sig

	'print apiurlstr

	m.http.SetUrl(apiurlstr)
	xml=m.http.GetToString()
	rsp=CreateObject("roXMLElement")
	if not rsp.Parse(xml) then stop

	'print rsp@stat

	if rsp@stat<>"ok" then return false

	m.auth_token=rsp.auth.token.GetText()
	m.perms=rsp.auth.perms.GetText()
	m.nsid=rsp.auth.user@nsid
	m.username=rsp.auth.user@username
	m.fullname=rsp.auth.user@fullname

	RegWrite("auth_token",m.auth_token)

	return true

End Function

Function MakeApiSig(method, param_list=[], mini_token=invalid) As String

	if mini_token=invalid
		'copy_param_list=["auth_token="+m.auth_token].Append(param_list)  ' not working.  After griffin integrates latest brightscript, try again
		copy_param_list=["auth_token="+m.auth_token, "api_key="+m.api_key, "method="+method]
		for each p in param_list:copy_param_list.Push(p):next
	else
		'copy_param_list=["mini_token="+mini_token].Append(param_list)
		copy_param_list=["mini_token="+mini_token, "api_key="+m.api_key, "method="+method]
		for each p in param_list:copy_param_list.Push(p):next
	end if

	Sort(copy_param_list)

	str=""
	for each p in copy_param_list
		eq_pos=instr(1,p,"=")
		str=str+left(p, eq_pos-1)+m.http.unescape(mid(p, eq_pos+1))
	next

	'print "str=";str

	apisigstr=m.api_secret+str
	'print "apisigstr: ";apisigstr
	api_sig=m.md5(apisigstr)
	'print "api_sig:";api_sig
	return api_sig

End Function



' ********************************************************************
' ********************************************************************
' ***** Interestingness Interestingness Interestingness
' ***** Interestingness Interestingness Interestingness
' ********************************************************************
' ********************************************************************

REM
REM Interestingness
REM pass an (optional) page of value 1 - 5 to get 100 photos starting at 0/100/200/300/400
REM returns a list of "Interestingness" photos with 100 entries
REM
REM

Function GetInterestingnessPhotoList(page=1 As Integer, per_page=100 As Integer) As Object

	'print "In GetInterestingnessPhotoList()"
	'print "page=";page
	'print "per_page";per_page

	rsp=m.ExecServerAPI("flickr.interestingness.getList", ["page="+mid(stri(page),2), "per_page="+mid(stri(per_page),2)])
	if rsp@stat="ok" then
		return newPhotoListFromXML(m.http, rsp.photos.photo)
	else
		return []
	end if

End Function

Sub DisplayInterestingPhotos()
	ss=PrepDisplaySlideShow()
	photolist=m.GetInterestingnessPhotoList(rnd(5))
	m.DisplaySlideShow(ss, photolist)
	ss=invalid ' take down roSlideShow by eliminating all references to it

End Sub


' ********************************************************************
' ********************************************************************
' ***** PhotoStream PhotoStream PhotoStream
' ***** PhotoStream PhotoStream PhotoStream
' ********************************************************************
' ********************************************************************

REM
REM PhotoStream
REM pass an (optional) page of value 1 - 5 to get 100 photos starting at 0/100/200/maxphotos
REM returns a list of "PhotoStream" photos with 100 (max) entries
REM
REM

Function GetPhotoStreamPhotoList(page=1 As Integer, per_page=50 As Integer) As Object

	'print "in GetPhotoStreamPhotoList"
	'print "page=";page
	'print "per_page";per_page

'!!!!!! page not implemented, need to implement it.

	if m.auth_token=invalid then return []

	rsp=m.ExecServerAPI("flickr.photos.search", ["user_id="+m.http.Escape(m.nsid)])
	if rsp@stat="ok" then
		return newPhotoListFromXML(m.http, rsp.photos.photo)
	else
		return []
	end if

End Function


Sub DisplayMyPhotoStream()

	if not DoFlickrAccountLink(m) then  ' in accountlink.brs  -- calling outside flickrtoolkit!!!!
		print "DisplayMyPhotoStream: Account not linked:"
		return
	end if

	ss=m.PrepDisplaySlideShow()
	photolist=m.GetPhotoStreamPhotoList()
	m.DisplaySlideShow(ss, photolist)
	ss=invalid ' take down roSlideShow by eliminating all references to it

End Sub

Sub DisplayNSIDPhotoStream(nsid)

	ss=m.PrepDisplaySlideShow()
	
	rsp=m.ExecServerAPI("flickr.photos.search", ["user_id="+m.http.Escape(nsid)])
	if rsp@stat="ok" then
		photolist=newPhotoListFromXML(m.http, rsp.photos.photo)
		m.DisplaySlideShow(ss, photolist)
	end if
	
	ss=invalid ' take down roSlideShow by eliminating all references to it

End Sub

' ********************************************************************
' ********************************************************************
' ***** Sets Sets Sets Sets Sets Sets
' ***** Sets Sets Sets Sets Sets Sets
' ********************************************************************
' ********************************************************************

Sub BrowseMySets()

	'print "in BrowseMySets"

	if not DoFlickrAccountLink(m) then
		print "BrowseMySets: Account not linked."
		return
	end if

	poster=uitkPreShowPosterMenu()   'display poster screen quickly for instant UI feedback

	psl = m.GetPhotoSetList(m.nsid)
	if psl.IsEmpty() then return

	mainmenudata = []
	for each set in psl
		primary = set.GetPrimaryURL()
		mainmenudata.Push({ShortDescriptionLine1: set.GetTitle(), HDPosterUrl: primary, SDPosterUrl: primary})
	next

	onselect = [1, psl, m, function(psl, flickr, set_idx):flickr.DisplayPhotoSet(psl[set_idx]):end function]

	uitkDoPosterMenu(mainmenudata, poster, onselect)

End Sub

Sub DisplayPhotoSet(set)

	ss=m.PrepDisplaySlideShow()
	photolist=set.GetPhotos()
	m.DisplaySlideShow(ss, photolist)
	ss=invalid ' take down roSlideShow by eliminating all references to it

End Sub

REM
REM GetPhotoSetList
REM
REM    takes a user_id
REM    Returns an roList of PhotoSet objects
REM

Function GetPhotoSetList(userid As String) As Object

	rsp=m.ExecServerAPI("flickr.photosets.getList", ["user_id="+m.http.Escape(userid)])
	photosetlist=CreateObject("roList")
	if rsp@stat="ok" then
		for each set in rsp.photosets.photoset   'root.GetBody().Peek().GetBody()
			photosetlist.Push(m.newPhotoSetFromXML(set, userid))
		next
	end if
  return photosetlist

End Function


REM
REM newPhotoSetFromXML
REM
REM    Takes an roXMLElement Object that is: <photoset> ... </photoset>
REM    Returns an brs object of type PhotoSet
REM       photoset.GetTitle()
REM       photoset.GetID()
REM       photoset.GetOwner()
REM       photoset.GetPhotos()			' returns a roList of Photo objects
REM	      photoset.GetPrimaryURL(size)  ' returns an URL to the photoset icon
REM

' example XML
'<photosets cancreate="1">
'  <photoset id="5" primary="2483" secret="abcdef"
'    server="8" photos="4" farm="1">
'    <title>Test</title>
'    <description>foo</description>
'  </photoset>
'  <photoset id="4" primary="1234" secret="832659"
'    server="3" photos="12" farm="1">
'    <title>My Set</title>
'    <description>bar</description>
'  </photoset>
'</photosets>

Function newPhotoSetFromXML(set_xml As Object, owner As String) As Object
  photoset = CreateObject("roAssociativeArray")
  photoset.flickr=m
  photoset.owner=owner
  photoset.xml=set_xml
  photoset.GetPhotos=psGetPhotos
  photoset.GetTitle=function():return m.xml.title.GetText():end function
  photoset.GetID=function():return m.xml@id:end function
  photoset.GetOwner=function():return m.owner:end function
  photoset.GetTotal=function():return m.xml@photos:end function
  photoset.GetPrimaryURL=pGetPrimaryURL
  return photoset
End Function


Function psGetPhotos() as Object
	rsp=m.flickr.ExecServerAPI("flickr.photosets.getPhotos", ["photoset_id="+m.GetID()])
	' note: each photo entry in the photo set does not have an owner, hence the need to pass it in below
	return newPhotoListFromXML(m.flickr.http, rsp.photoset.photo, m.owner)
End Function

Function pGetPrimaryURL(size="") As String

	'rsp=m.flickr.ExecServerAPI("flickr.photos.getInfo",["photo_id="+m.xml@primary])
	'if rsp@stat<>"ok" then return invalid

	a=m.xml.GetAttributes()

	if size<>"" then size="_"+size
	url="http://farm"+a.farm+".static.flickr.com/"+a.server+"/"+a.primary+"_"+a.secret+size+".jpg"
	'print url
	return url
End Function

REM
REM GetPhotoSet
REM
REM takes a user URL and a Title
REM returns a photoset
REM
Function GetPhotoSet(user As String, title As String) As dynamic
  photosetlist=m.GetPhotoSetList(m.GetUserIDByURL(user))
  for each set in photosetlist
    if set.GetTitle()=title then
      return set
    endif
  next

  return invalid

End Function



' ********************************************************************
' ********************************************************************
' ***** Groups Groups Groups Groups Groups Groups
' ***** Groups Groups Groups Groups Groups Groups
' ********************************************************************
' ********************************************************************

Sub BrowseMyGroups()

	'print "in BrowseMyGroups"

	if not DoFlickrAccountLink(m) then
		print "BrowseMyGroups: Account not linked."
		return
	end if

	poster=uitkPreShowPosterMenu()   'display poster screen quickly for instant UI feedback

	pgl = m.GetPublicGroupsList(m.nsid)
	if pgl.IsEmpty() then return

	mainmenudata = []
	for each group in pgl
		primary = group.GetPrimaryURL()
		mainmenudata.Push({ShortDescriptionLine1: group.GetTitle(), HDPosterUrl: primary, SDPosterUrl: primary})
	next

	onselect = [1, pgl, m, function(pgl, flickr, idx):flickr.DisplayGroupPhotoPool(pgl[idx]):end function]

	uitkDoPosterMenu(mainmenudata, poster, onselect)

End Sub

Sub DisplayGroupPhotoPool(group)

	ss=m.PrepDisplaySlideShow()
	photolist=group.GetPhotos()
	m.DisplaySlideShow(ss, photolist)
	ss=invalid ' take down roSlideShow by eliminating all references to it

End Sub

REM
REM GetPublicGroupsList
REM
REM    takes a user_id
REM    Returns an roList of Group objects
REM
'  <?xml version="1.0" encoding="utf-8" ?>
'  <rsp stat="ok">
'  <groups>
'  <group nsid="51035612836@N01" name="Flickr API" admin="0" eighteenplus="0" />
'  <group nsid="59479601@N00" name="London-alt" admin="0" eighteenplus="0" />
'  <group nsid="46381141@N00" name="Texas A&M Aggies" admin="0" eighteenplus="0" />
'  <group nsid="32446415@N00" name="Abandonded Gas Stations" admin="0" eighteenplus="0" />
'  <group nsid="323600@N20" name="Texas Wildflowers" admin="0" eighteenplus="0" />
'  <group nsid="405187@N24" name="I Love Old Signs!" admin="0" eighteenplus="0" />
'  <group nsid="764064@N23" name="TRS-80 Love" admin="0" eighteenplus="0" />
'  </groups>
'  </rsp>
Function GetPublicGroupsList(userid As String) As Object

	rsp=m.ExecServerAPI("flickr.people.getPublicGroups", ["user_id="+m.http.Escape(userid)])
	grouplist=CreateObject("roList")
	if rsp@stat="ok" then
		for each group in rsp.groups.group
			grouplist.Push(m.newGroupFromXML(group))
		next
	end if
  return grouplist

End Function

REM
REM newGroupFromXML
REM
REM    Takes an roXMLElement Object that is: <group> ... </group>
REM    Returns an brs object of type PhotoSet
REM       group.GetTitle()
REM       group.GetID()
REM       group.GetPhotos()			' returns a roList of Group objects
REM	      group.GetPrimaryURL(size) ' returns an URL to the first photo in group photo pool
REM

Function newGroupFromXML(xml As Object) As Object
  group = CreateObject("roAssociativeArray")
  group.flickr=m
  group.xml=xml
  group.GetPhotos=gGetPhotos
  group.GetTitle=function():return m.xml@name:end function
  group.GetID=function():return m.xml@nsid:end function
  group.GetPrimaryURL=gGetPrimaryURL
  return group
End Function


Function gGetPhotos() as Object
	rsp=m.flickr.ExecServerAPI("flickr.groups.pools.getPhotos", ["group_id="+m.GetID()])
	return newPhotoListFromXML(m.flickr.http, rsp.photos.photo)
End Function

Function gGetPrimaryURL(size="") As String

	rsp=m.flickr.ExecServerAPI("flickr.groups.pools.getPhotos", ["page=1","per_page=1","group_id="+m.GetID()])
	if rsp@stat<>"ok" then return invalid

	a=rsp.photos.photo.GetAttributes()

	if size<>"" then size="_"+size
	url="http://farm"+a.farm+".static.flickr.com/"+a.server+"/"+a.id+"_"+a.secret+size+".jpg"
	'print url
	return url
End Function

REM
REM GetGroupPhotoPoolByURL
REM
REM takes the end of the Flickr Group URL
REM returns a list of Photos
REM

Function GetGroupPhotoPoolByURL(http as Object, groupurl as String) As Object

  http.SetUrl("http://api.flickr.com/services/rest/?method=flickr.urls.lookupGroup&url=//flickr.com/groups/"+groupurl+"/"+"&api_key=1beba5866bc14edec5bff26091cecc2c")
  xml=http.GetToString()

  rsp=CreateObject("roXMLElement")
  if not rsp.Parse(xml) then stop

  group_id=rsp.group@id      'rsp.getBody().Peek().GetAttributes()["id"]
  'print "group_id: ";group_id

  http.SetUrl("http://api.flickr.com/services/rest/?method=flickr.groups.pools.getPhotos&group_id="+group_id+"&api_key=1beba5866bc14edec5bff26091cecc2c")
  xml=http.GetToString()

  if not rsp.Parse(xml) then stop

  size=rsp.photos@total    'rsp.GetBody().Peek().GetAttributes()["total"]
  'print "total size of full list: ";size

  return newPhotoListFromXML(http, rsp.photos.photo)  'root.GetBody().Peek().GetBody()

End Function

' ********************************************************************
' ********************************************************************
' ***** Tags Tags Tags Tags Tags Tags Tags
' ***** Tags Tags Tags Tags Tags Tags Tags
' ********************************************************************
' ********************************************************************

Sub BrowseHotTags()
	m.BrowseTags(m.GetHotList())
End Sub

Sub BrowseTags(tl)
	'print "in BrowseTags"

	if tl.IsEmpty() then return

	poster=uitkPreShowPosterMenu()   'display poster screen quickly for instant UI feedback

	mainmenudata = []
	for each tag in tl
		p=m.GetTaggedPhotoList(tag, 1,1)[0]
		if type(p)="roAssociativeArray" then
			primary = p.GetUrl()
			mainmenudata.Push({ShortDescriptionLine1: tag, HDPosterUrl: primary, SDPosterUrl: primary})
		end if
	next

	onselect = [1, tl, m, function(tl, flickr, idx):flickr.DisplayTaggedPhotos(tl[idx]):end function]

	uitkDoPosterMenu(mainmenudata, poster, onselect)

End Sub

Sub DisplayTaggedPhotos(tag)

	ss=m.PrepDisplaySlideShow()
	photolist=m.GetTaggedPhotoList(tag)
	m.DisplaySlideShow(ss, photolist)
	ss=invalid ' take down roSlideShow by eliminating all references to it

End Sub

'  <?xml version="1.0" encoding="utf-8" ?>
'  <rsp stat="ok">
'  <hottags period="day" count="20">
'  <tag score="95">day85</tag>
'  <tag score="81">musclemen</tag>
'  <tag score="74">hppt</tag>
'  <tag score="73">gorgeousgreenthursday</tag>
'  </hottags>
'  </rsp>


Function GetHotList() As Object
	rsp=m.ExecServerAPI("flickr.tags.getHotList", [])
	taglist=CreateObject("roList")
	if rsp@stat="ok" then
		for each tag in rsp.hottags.tag
			taglist.Push(tag.GetText())
		next
	end if
  return taglist

End Function

Function GetTaggedPhotoList(tags As String, page=1 As Integer, per_page=50 As Integer) As Object
	rsp=m.ExecServerAPI("flickr.photos.search", ["tags="+m.http.Escape(tags), "sort=interestingness-desc", "page="+mid(stri(page),2), "per_page="+mid(stri(per_page),2)])
	if rsp@stat="ok" then
		return newPhotoListFromXML(m.http, rsp.photos.photo)
	else
		return []
	end if
End Function

' ********************************************************************
' ********************************************************************
' ***** Photo Info Photo Info Photo Info
' ***** Photo Info Photo Info Photo Info
' ********************************************************************
' ********************************************************************

Sub GetPhotoInfo(photo_id, info, taglist)

	rsp=m.ExecServerAPI("flickr.photos.getInfo",["photo_id="+photo_id])
	if rsp@stat<>"ok" then return

	info.TextOverlayUL="Title: "+rsp.photo.title.GetText()
	info.TextOverlayUR="More Options -> Nav Down"
	
	if rsp.photo.owner@realname<>"" then 
		info.TextOverlayBody = "Author: "+rsp.photo.owner@realname
	else
		info.TextOverlayBody = ""
	end if
	
	d = rsp.photo.descripton
	if d.Count()=1 and d.GetText()<>"" then
		if info.TextOverlayBody="" then
			info.TextOverlayBody=d.GetText()
		else
			info.TextOverlayBody=info.TextOverlayBody+chr(10)+d.GetText()
		end if
	end if
	
	if info.TextOverlayBody="" then 
		info.TextOverlayBody = "Tags: "
	else
		info.TextOverlayBody = info.TextOverlayBody+chr(10)+"Tags: "
	end if
		
	tags=rsp.photo.tags.tag
	if not tags.IsEmpty() then
		for each t in tags
			info.TextOverlayBody = info.TextOverlayBody + t.GetText()
			taglist.Push(t.GetText())
			if tags.IsNext() then info.TextOverlayBody = info.TextOverlayBody + ", "
		next
	end if

end sub

'
' flickr.photos.getInfo EXAMPLE RESULT
'
'<photo id="2733" secret="123456" server="12"
'	isfavorite="0" license="3" rotation="90" 
'	originalsecret="1bc09ce34a" originalformat="png">
'	<owner nsid="12037949754@N01" username="Bees"
'		realname="Cal Henderson" location="Bedford, UK" />
'	<title>orford_castle_taster</title>
'	<description>hello!</description>
'	<visibility ispublic="1" isfriend="0" isfamily="0" />
'	<dates posted="1100897479" taken="2004-11-19 12:51:19"
'		takengranularity="0" lastupdate="1093022469" />
'	<permissions permcomment="3" permaddmeta="2" />
'	<editability cancomment="1" canaddmeta="1" />
'	<comments>1</comments>
'	<notes>
'		<note id="313" author="12037949754@N01"
'			authorname="Bees" x="10" y="10"
'			w="50" h="50">foo</note>
'	</notes>
'	<tags>
'		<tag id="1234" author="12037949754@N01" raw="woo yay">wooyay</tag>
'		<tag id="1235" author="12037949754@N01" raw="hoopla">hoopla</tag>
'	</tags>
'	<urls>
'		<url type="photopage">http://www.flickr.com/photos/bees/2733/</url> 
'	</urls>
'</photo>

Sub BrowsePhotoInfo(photo_id)
    screen = CreateObject("roSpringboardScreen")
    'screen.SetBreadcrumbText(lastLocation, currentLocation)
    mp = CreateObject("roMessagePort")
    if mp=invalid then print "roMessagePort Create Failed":stop
    screen.SetMessagePort(mp)
    screen.SetDescriptionStyle("generic")
	screen.AddButton(0, "Done")

	rsp=m.ExecServerAPI("flickr.photos.getInfo",["photo_id="+photo_id])
	if rsp@stat<>"ok" then return

	a=rsp.photo.GetAttributes()

	o={ }
    o.Categories       = ["Photo"]
	o.Description = rsp.photo.title.GetText()+" By "+rsp.photo.owner@realname
	d = rsp.photo.descripton
	if d.Count()=1 and d.GetText()<>""
		o.Description = o.Description+", "+d.GetText()
	end if
	tags=rsp.photo.tags.tag
	if not tags.IsEmpty() then
		o.Description = o.Description+", Tags: "
		screen.AddButton(1, "Browse Tags")
		taglist=CreateObject("roList")
		for each t in tags
			o.Description = o.Description + t.GetText()
			taglist.Push(t.GetText())
			if tags.IsNext() then o.Description = o.Description + ", "
		next
	end if

	o.SDPosterUrl = "http://farm"+a.farm+".static.flickr.com/"+a.server+"/"+a.id+"_"+a.secret+".jpg"
	o.HDPosterUrl = o.SDPosterUrl

    screen.SetContent(o)
	screen.Show()

    'the ids for the remote events from RCButton.txt file
    remoteLeft  = 4
    remoteRight = 5

    waitformsg:

    while true
        msg = wait(0, mp)
		'print "BrowsePhotoInfo: received "; type(msg)
        if type(msg) = "roSpringboardScreenEvent"
            if msg.isScreenClosed()
                return
            else if msg.isButtonPressed() then
                 if msg.GetIndex() = 1 then       'Browse Tags
					m.BrowseTags(taglist)
                 else if msg.GetIndex() = 0 then  'Done
					return
                endif
			else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        endif
    end while
End Sub

' ********************************************************************
' ********************************************************************
' ***** TODO TODO TODO TODO TODO TODO TODO
' ***** TODO TODO TODO TODO TODO TODO TODO
' ********************************************************************
' ********************************************************************

'TODO: make functions private or static that are not in the flickr object

' to do
' - when getting a photo list, allow getting of more than just the first page
' - photoset.GetRandomPhoto()
' - GetRandomUserPhoto

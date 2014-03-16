
'
' Test program to produce beeps
' Demonstrates BrightScript programming concepts
' 

sub isplaying(b1,b2)
    print "beep1 playing=";b1.isplaying();" beep2 playing=";b2.isplaying()
end sub

function Main()

	screen = CreateObject("roParagraphScreen") ' kludge for now
	screen.Show()
	
	sleep(1000)

    doramp = 0
    dointerrupt = 0
    dohammer = 0
    doSampRate = 1
    dosystem = 0

    if dosystem = 1
        print "Do System Soundeffects"
	    beep1=CreateObject("roAudioResource", "Select")
	    beep2=CreateObject("roAudioResource", "navsingle")
	    beep3=CreateObject("roAudioResource", "navmulti")
	    beep4=CreateObject("roAudioResource", "deadend")
        print "trigger select"
        beep1.trigger(50)   '
        sleep(1000)
        print "trigger navsingle"
        beep2.trigger(50)
        sleep(1000)
        print "trigger navmulti"
        beep3.trigger(25)
        sleep(1000)
        print "trigger deadend"
        beep4.trigger(50)
        sleep(1000)
    endif

    if doramp = 1
        print "Do Ramp"
    	beep1=CreateObject("roAudioResource", "pkg:/sounds/akm1km-3-5sec.wav")
        print "trigger vol=6"
        beep1.trigger(6)
        sleep(6000)
        print "trigger vol=12"
        beep1.trigger(12)
        sleep(6000)
        print "trigger vol=25"
        beep1.trigger(25)
        sleep(6000)
        print "trigger vol=50"
        beep1.trigger(50)
        sleep(6000)
        print "trigger vol=100"
        beep1.trigger(100)
        sleep(6000)
    endif

    if doInterrupt
    	beep1=CreateObject("roAudioResource", "pkg:/sounds/akm1km-3-5sec.wav")
    	beep2=CreateObject("roAudioResource", "pkg:/sounds/cartoon008.wav")

        maxStreams = beep1.maxSimulStreams()
        print "Do Interrupt max simultaneous stream = "; maxStreams
        isplaying(beep1, beep2)
    	beep1.Trigger(50)
        print "play to completion"
            isplaying(beep1, beep2)	
	
	    ' set sleep to 100 or 200 to trigger the bug, a setting of 400 makes it safe for beep2
	    sleep(5000)
	    isplaying(beep1, beep2)
        print "start beep again"
        sleep(1000)

      if 0
        beep1.Trigger(50)
        print "interrupt with stop"
	    sleep(500)
        print "stop 1"
        beep1.stop()
        sleep(5000)
      endif

        if dohammer
' hammer beep test
          while true
            beep1.trigger(50)
            sleep(20)
            beep2.trigger(50)
            sleep(20)
          end while
        endif

     if 1  
        beep1.trigger(100)
        print "Interrupt with a different beep"
        sleep(500)
	    beep2.Trigger(100)

        sleep(5000)
      endif
      if 0
        print "simul play "
        beep1.trigger(35)
        sleep(1000)
        ' this only does simul play on roku 2, on roku 1 it interrupts
        beep2.trigger(100, maxStreams - 1)
        sleep(3000)
      endif
    endif

    if doSampRate
        print "Do sample rate tests"
    	beep44100=CreateObject("roAudioResource", "pkg:/sounds/akm1km44100-3-1sec.wav")
    	beep8000=CreateObject("roAudioResource", "pkg:/sounds/akm1km8000-3-1sec.wav")
    	beep16000=CreateObject("roAudioResource", "pkg:/sounds/akm1km16000-3-1sec.wav")
    	beep96000=CreateObject("roAudioResource", "pkg:/sounds/akm1km96000-3-1sec.wav")
    	beep48000=CreateObject("roAudioResource", "pkg:/sounds/akm1km48000-3-1sec.wav")
        print "44100"
        beep44100.trigger(50)
        sleep(2000)
        print "8000"
        beep8000.trigger(50)
        sleep(2000)
        print "16000"
        beep16000.trigger(50)
        sleep(2000)
        print "48000"
        beep48000.trigger(50)
        sleep(2000)
        print "96000"
        beep96000.trigger(50)
        sleep(2000)
    endif
    print "Done"
end function

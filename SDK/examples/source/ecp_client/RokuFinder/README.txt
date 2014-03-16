This java program uses Roku's ECP SSDP functionality to find Roku Streaming Players on the local LAN.
It requires SSDP (UDP port 1900) to be available for send and receive.
It can be built like this from the RokuFinder/src directory:
javac -cp . .
It can be run like this:
java -cp . RokuFinder

It will print items as it finds them or as they expire. Once shortly after starting, and every five minutes thereafter, it will list the currently known RSPs.

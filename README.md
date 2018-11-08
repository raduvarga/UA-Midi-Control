# Universal Audio (UA) Midi Control

APP DOWNLOAD LINK (Mac OSX): https://github.com/vargaradu/UA-Midi-Control/raw/master/UA%20Midi%20Control.zip

Similar App for Focusrite interfaces: https://github.com/vargaradu/Focusrite-Midi-Control

On Chrome you might receive a "UA Midi Control.zip is not commonly downloaded and may be dangerous" warning, you have to click "Keep" to continue the donwload.

## What is it?

It's an App that let's you Midi Map the volumes of your Universal Audio interface. You must have the UA Mixer Engine process running, which starts up along with the Console app. The Console app can be quit afterwards, the UA Mixer Engine will keep running in the background.

There is no special permissions required to connect this app to the UA Mixer Engine, it will just work if they are opened on the same machine.

## Why did you do it?

Because:
1. Controlling volumes using a mouse sucks
2. To unify DAW volume controls with the UA direct monitoring ones
3. For some tracks, I want to control the DAW loop volume and UA monitor volume at the same time (and having the same value) 

Alas, you can now have a central mixer for both your DAW and UA on the same Midi Controller.

## This doesn't work with my UA machine

Create an issue with your specific problem, and I'll see what I can sort out.

## But this doesn't work on Windows..help?

I've only coded an app for OSX because it was faster to achieve, but the hard part of cracking the code behind the code is done, so if you're a developer check the code/examples/resources in this project to make your own app for Windows, Android, whatever.

## Ok, so how did you do it?

I reverse-engineered UA's messaging protocols.

First step was to use Wireshark to capture TCP packets: https://www.wireshark.org/
Then I opened up the Console app and immediately saw packets flying on localhost, from which I figured the port of the UA server (which is `4710`).

For sending/receiving TCP messages, a few important things:
- Connect to TCP on port `4710` on localhost
- The protocol is standard TCP, BUT to be able to properly send/received messages, you need to know that there is a terminating character for each messages. UA chose the NULL character for this (00 ASCII code). This was tricky in Swift, because if you append a NULL character to a String, that String will say it has the same length (and the length you need to know in order to properly separate your reading of TCP messages), but I ended using the Data class instead which worked fine with this. So in conclustion: every received message will have a NULL character at the end, when you send a message you have to append a NULL character.
- I saw that the Console app sends a perioadical `set /Sleep false` message (seems like a Keep Alive message). I do it as well, every 3 seconds. I haven't seen any difference between sending or not sending this message, but I guess it's a good thing to do.

Wireshark also allowed me to figure out the form of the commands and response values, which are as follows:
- Commands:
	 - `method path` - e.g. `set /devices/inputs/FaderLevelTapered/value/1`
	 - I've identified the following methods: `get` `set` `subscribe`
	 - and some of the paths I've used: `/devices`,  `/devices/{id}/inputs`, `/devices/{id}/inputs/{id}`, `/devices/{id}/DeviceOnline`, `/devices/{id}/DeviceOnline`, etc
	- The list of commands I've identified are not exclusive, I only got a few of them via Wireshark, the others I've discovered through oldschool pattern recognition. So there might be much more out there.

- Responses:
	- they come in JSON, in the following base format: `{"path": path, "data": {"properties": props, "children": children}}`
	- the `path` field is handy, because you can link your requests to your results (remember that plain TCP doesn't have all the perks of HTTP)
	- example answer for `get /devices` command: `{"path": "/devices", "data": {"properties": {"Type": {"type": "string", "value": "container"}}, "children": {"0": {}}}}`

Walkthrough of the communication steps I did to achieve this app:
1. Send a `get /devices` request. In the response, the list of children will your available device ids.
2. For each device id, send a `subscribe /devices/{id}/DeviceOnline`. Response: `{"path": "/devices/0/DeviceOnline/value", "data": false}`. Useful for showing when the interface is connected or not (Online/Offline in the app UI)
3. For each device id, send a `get /devices/{id}`. There are a few useful infos here, I only use the `DeviceName` here.
4. For each device id, send a `get /devices/{id}/inputs`. This looks like this: `{"path": "/devices/0/inputs", "data": {"properties": {"Type": {"type": "string", "value": "container"}}, "children": {"0": {}, "1": {}, "2": {}, "3": {}, "4": {}, "5": {}, "6": {}, "7": {}, "8": {}, "9": {}, "10": {}, "11": {}, "12": {}, "13": {}, "14": {}, "15": {}, "16": {}, "17": {}, "18": {}, "19": {}, "20": {}, "21": {}}}}`. Again, you get the input id's as the children fields, which it's slightly annoying because you don't know in advance the exact JSON Model for parsing, so you'll have to do a bit of manual work there, not too bad in the end.
5. For each input id, send a  `get /devices/{devId}/inputs/{inputId}`. What I use from here is the `Name` property, which has a `default` (default name of that input) and a `value` (user custom name of that input). I show them both in the UI for clarity.
6. Any time I detect a mapped midi message, I send a `set /devices/{devId}/inputs/{inputId}/FaderLevelTapered/value/ {vol}` (the space before {vol} is intentional), which changes the fader levels. You have both the option to use FaderLevel (db value, 0 to -inf) or FaderLevelTapered (0 to 1). FaderLevelTapered is much more handy, you just need to normalize your midi CC message values, from the range 0-127 to 0-1.

That's basically all I need to comunicate with the UA server to get things done.
A useful thing to know if you want to expand this app's functionality is that you can access any `property` you see in the responses as a command, i.e. send a `get`, `set` or `subscribe` to any or most of them. e.g. `subscribe /devices/{devId}/inputs/{inputId}/FaderLevelTapered/` - you will constantly be informed when this value changes.

## Appendix

This is the second time I've written an OSX app, so don't judge the code too hard.
If you need help developing your own UA client, feel free to contact me.
Happy Midi Mapping!


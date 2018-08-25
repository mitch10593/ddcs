# marker.lua - make action with markers on MAP

## MOVE ships to marker position

Syntax: 

```
MOVE(groupName,speed)
```

Parameters:

* groupName: the group name to move on
* speed: group speed required

Exemple:

To move the CVN group to the marker position at 20 knots.

```
MOVE(CVN,20)
```

## TANKER - replace tankers to marker position

Syntax: 

```
TANKER(groupName,speed,hdg,distance,alt)
```

Parameters:

* groupName: the group name to move on
* speed: group speed in knots required (default: 320 kts)
* hdg: heading to go from the marker position (default: 0 degrees)
* distance: distance in Nm to go from the marker position (default: 20 Nm)
* alt: altitude required in feets (default: 20 000 ft)

Exemple:

To move the "ARCO" group to the marker position :

```
TANKER(ARCO)
```

To move the "ARCO" group to the marker position, at 350kts, with a route to 45°/30Nm at 18000ft:

```
TANKER(ARCO,350,45,30,18000)
```

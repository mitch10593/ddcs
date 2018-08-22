# Dynamic DCS scripts

A fully work in progress for a more Dynamic DCS World

this project use some libraries to work

* [grass.lua](doc/grass.md): a lib to create units on FARPS and to create grass runways
* [GroundTakeOff](mod/GroundTakeOff/README.md): a mod to place some aircrafts on ground

## Work on this project

Requirements:
- [git for windows](https://gitforwindows.org/)
- [7-zip](https://www.7-zip.org/)

```shell
git clone https://github.com/mitch10593/ddcs.git
cd ddcs
```

This project use a workflow to build and extract the Mission .miz file.

### After changes on scripts, you need to run:

```shell
./build.sh
```

then, you need to open again your mission in DCS World.

### After changes in mission editor (after save), you need to run:

```shell
./extract.sh
```

Never make changes on both sides (changes will be overwritten)

Mission (.miz) file will be released like executables build.

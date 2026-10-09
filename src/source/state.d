module state;

import core.sys.posix.netinet.in_;
import raylib;
import protocol;

// globals -
__gshared PInfo[MAXP] P;
__gshared Peer[MAXP] peers;
__gshared int sock = -1, myId = 0, scene = 0; // scene: 0 menu, 1 join, 2 play
__gshared bool isHost, joined;
__gshared sockaddr_in hostAddr;
__gshared char[16] ipText, localIp;
__gshared int ipLen;
__gshared char[16] myName;
__gshared char[80] menuMsg;
__gshared float mx = 0, mz = 0, myYaw = 0, pitch = 0, flash = 0;
__gshared ubyte mySpawns = 255;
__gshared double lastSnap = 0, lastSend = 0, lastJoin = 0, joinStart = 0, lastFire = 0;

// chat
struct Line
{
	char[100] t;
	double time;
}

__gshared Line[8] chat;
__gshared bool chatOpen;
__gshared char[80] chatInput;
__gshared int chatLen;
__gshared bool cursorLocked;

// pause
__gshared bool paused;

// input helpers
__gshared bool mobile;
__gshared bool g_hasTap;
__gshared Vector2 g_tap;
__gshared bool[16] tDown;
__gshared Vector2[16] tPos;
__gshared Vector2 knob;

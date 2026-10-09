module protocol;

import core.sys.posix.netinet.in_;

// // protocol //
enum MAXP = 8;
enum PORT = 7777;
enum : ubyte
{
	C_JOIN = 1,
	C_STATE = 2,
	C_CHAT = 3,
	C_SHOOT = 4,

	S_WELCOME = 10,
	S_SNAP = 11,
	S_CHAT = 12 }

align(1) struct PInfo
{
	ubyte used,
	hp, spawns;
	char[12] name;
	float x, z, yaw;
}

align(1) struct Snap
{ ubyte type;
	PInfo[MAXP] p;
}

struct Peer
{
	sockaddr_in addr;
	double last;
	double lastShot;
}

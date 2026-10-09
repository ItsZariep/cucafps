module net;

import core.stdc.stdio : snprintf;
import core.stdc.string : memset;
import core.stdc.errno : errno;
import core.sys.posix.sys.socket;
import core.sys.posix.netinet.in_;
import core.sys.posix.arpa.inet;
import core.sys.posix.unistd : close;
import core.sys.posix.fcntl;
import raylib;
import protocol;
import state;
import world;
import messages;

// networking //
ushort swap16(ushort v)
{
	return cast(ushort)((v << 8) | (v >> 8));
}

void setNonblock(int fd)
{
	fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
}

void findLocalIp()
{
	snprintf(localIp.ptr, 16, "127.0.0.1");
	int s = socket(AF_INET, SOCK_DGRAM, 0);
	if (s < 0) return;
	sockaddr_in a;
	a.sin_family = AF_INET;
	a.sin_port = swap16(53);
	a.sin_addr.s_addr = inet_addr("8.8.8.8"); // UDP connect sends nothing
	if (connect(s, cast(sockaddr*)&a, cast(socklen_t)a.sizeof) == 0)
	{
		sockaddr_in me;
		socklen_t l = cast(socklen_t)me.sizeof;
		if (getsockname(s, cast(sockaddr*)&me, &l) == 0)
		{
			inet_ntop(AF_INET, &me.sin_addr, localIp.ptr, 16);
		}
	}
	close(s);
}

void leaveGame(const(char)* why)
{
	if (sock >= 0) close(sock);
	sock = -1;
	joined = false;
	scene = 0;
	isHost = false;
	chatOpen = false;
	paused = false;
	if (cursorLocked)
	{
		EnableCursor();
		cursorLocked = false;
	}
	snprintf(menuMsg.ptr, 80, "%s", why);
}

void resetPlayers()
{
	memset(P.ptr, 0, P.sizeof);
	memset(peers.ptr, 0, peers.sizeof);
	foreach (ref l; chat)
	{
		memset(l.t.ptr, 0, 100);
		l.time = -100;
	}
	P[myId].used = 1;
	P[myId].hp = 100;
	snprintf(P[myId].name.ptr, 12, "%s", myName.ptr);
}

bool startHost()
{
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0)
	{
		snprintf(menuMsg.ptr, 80, "socket() failed, errno %d", errno);
		return false;
	}
	sockaddr_in a;
	a.sin_family = AF_INET;
	a.sin_port = swap16(PORT);
	a.sin_addr.s_addr = 0; // INADDR_ANY
	if (bind(sock, cast(sockaddr*)&a, cast(socklen_t)a.sizeof) != 0)
	{
		snprintf(menuMsg.ptr, 80, "bind() failed, errno %d", errno);
		close(sock);
		sock = -1;
		return false;
	}
	setNonblock(sock);
	findLocalIp();
	isHost = true;
	joined = true;
	myId = 0;
	paused = false;
	resetPlayers();
	spawnPoint(0, &mx, &mz);
	myYaw = 0;
	pitch = 0;
	addChat("Room created. Tell friends the IP shown top-left.");
	return true;
}

bool startClient()
{
	uint ip = inet_addr(ipText.ptr);
	if (ip == 0xFFFFFFFF || ipLen < 7) return false;
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0) return false;
	setNonblock(sock);
	memset(&hostAddr, 0, hostAddr.sizeof);
	hostAddr.sin_family = AF_INET;

	// parse port from portText
	int customPort = 0;
	foreach (ch; portText[0 .. portLen])
	{
		if (ch < '0' || ch > '9') return false;
		customPort = customPort * 10 + (ch - '0');
	}
	if (customPort < 1 || customPort > 65535) return false;

	hostAddr.sin_port = swap16(cast(ushort)customPort);

	hostAddr.sin_addr.s_addr = ip;
	isHost = false;
	joined = false;
	myId = 0;
	mySpawns = 255;
	paused = false;
	resetPlayers();
	joinStart = GetTime();
	lastJoin = -1;
	return true;
}

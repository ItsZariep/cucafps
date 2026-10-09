module client;

import core.stdc.stdio : snprintf;
import core.stdc.string : memcpy, strlen;
import core.sys.posix.sys.socket;
import core.sys.posix.netinet.in_;
import protocol;
import state;
import messages;
import net : leaveGame;

void clientNet(double now)
{
	ubyte[512] buf;
	sockaddr_in from;
	while (true)
	{
		socklen_t fl = cast(socklen_t)from.sizeof;
		auto n = recvfrom(sock, buf.ptr, 500, 0, cast(sockaddr*)&from, &fl);
		if (n <= 0) break;
		if (from.sin_port != hostAddr.sin_port) continue;
		buf[n] = 0;
		switch (buf[0])
		{
			case S_WELCOME:
				if (n >= 2 && buf[1] < MAXP)
				{
					myId = buf[1];
					joined = true;
				}
				break;
			case S_SNAP:
				if (n >= Snap.sizeof && joined)
				{
					Snap s;
					memcpy(&s, buf.ptr, Snap.sizeof);
					foreach (i; 0 .. MAXP)
					{
						if (i != myId)
						{
							P[i] = s.p[i];
							continue;
						}
						P[i].used = s.p[i].used;
						P[i].hp = s.p[i].hp;
						if (s.p[i].spawns != mySpawns)
						{
							mySpawns = s.p[i].spawns;
							mx = s.p[i].x;
							mz = s.p[i].z;
						}
					}
				}
				break;
			case S_CHAT:
				addChat(cast(char*)buf.ptr + 1);
				break;
			default: break;
		}
	}

	if (!joined)
	{
		if (now - lastJoin > 0.5)
		{
			lastJoin = now;
			ubyte[20] pk;
			pk[0] = C_JOIN;
			snprintf(cast(char*)pk.ptr + 1, 12, "%s", myName.ptr);
			sendto(sock, pk.ptr, 2 + strlen(cast(char*)pk.ptr + 1), 0,
				cast(sockaddr*)&hostAddr, cast(socklen_t)sockaddr_in.sizeof);
		}
		if (now - joinStart > 8)
		{
			leaveGame("Could not reach host (check IP / same Wi-Fi / UDP 7777)");
		}
	}
	else if (now - lastSend > 0.05)
	{
		lastSend = now;
		ubyte[13] pk;
		pk[0] = C_STATE;
		memcpy(pk.ptr + 1, &mx, 4);
		memcpy(pk.ptr + 5, &mz, 4);
		memcpy(pk.ptr + 9, &myYaw, 4);
		sendto(sock, pk.ptr, 13, 0, cast(sockaddr*)&hostAddr, cast(socklen_t)sockaddr_in.sizeof);
	}
}

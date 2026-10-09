module messages;

import core.stdc.stdio : snprintf;
import core.stdc.string : memset, strlen;
import core.sys.posix.sys.socket;
import core.sys.posix.netinet.in_;
import raylib;
import protocol;
import state;

// chat //
void addChat(const(char)* s)
{
	foreach (i; 0 .. 7)
	{
		chat[i] = chat[i + 1];
	}
	memset(chat[7].t.ptr, 0, 100);
	snprintf(chat[7].t.ptr, 100, "%s", s);
	chat[7].time = GetTime();
}

// host only: show locally and send to every client
void say(const(char)* s)
{
	addChat(s);
	ubyte[104] pk;
	pk[0] = S_CHAT;
	snprintf(cast(char*)pk.ptr + 1, 100, "%s", s);
	size_t len = 2 + strlen(cast(char*)pk.ptr + 1);
	foreach (i; 1 .. MAXP)
	{
		if (P[i].used)
		{
			sendto(sock, pk.ptr, len, 0, cast(sockaddr*)&peers[i].addr,
				cast(socklen_t)sockaddr_in.sizeof);
		}
	}
}

void sendChat(const(char)* msg)
{
	if (isHost)
	{
		char[100] b;
		snprintf(b.ptr, 100, "<%s> %s", P[0].name.ptr, msg);
		say(b.ptr);
	}
	else
	{
		ubyte[104] pk;
		pk[0] = C_CHAT;
		snprintf(cast(char*)pk.ptr + 1, 90, "%s", msg);
		size_t len = 2 + strlen(cast(char*)pk.ptr + 1);
		sendto(sock, pk.ptr, len, 0, cast(sockaddr*)&hostAddr,
			cast(socklen_t)sockaddr_in.sizeof);
	}
}

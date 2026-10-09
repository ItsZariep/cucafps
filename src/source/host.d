module host;

import core.stdc.stdio : snprintf;
import core.stdc.string : memset, memcpy;
import core.stdc.math : sinf, cosf, fabsf;
import core.sys.posix.sys.socket;
import core.sys.posix.netinet.in_;
import protocol;
import state;
import world;
import messages;

// host: damage / hit scan
void hostShoot(int s, float yaw)
{
	float fx = sinf(yaw), fz = cosf(yaw), sx = P[s].x, sz = P[s].z;
	int best = -1;
	float bestT = 1e9f;
	foreach (i; 0 .. MAXP)
	{
		if (i == s || !P[i].used || P[i].hp == 0) continue;
		float dx = P[i].x - sx, dz = P[i].z - sz;
		float t = dx * fx + dz * fz;
		if (t <= 0 || t > 60) continue;
		if (fabsf(dx * fz - dz * fx) > 0.6f) continue;
		if (t < bestT)
		{
			best = i;
			bestT = t;
		}
	}
	if (best < 0 || rayBlocked(sx, sz, fx, fz, bestT)) return;

	int hp = cast(int)P[best].hp - 34;
	if (hp > 0)
	{
		P[best].hp = cast(ubyte)hp;
		return;
	}

	char[100] m;
	snprintf(m.ptr, 100, "%s was shot by %s", P[best].name.ptr, P[s].name.ptr);
	say(m.ptr);
	float nx, nz;
	spawnPoint(best, &nx, &nz);
	P[best].x = nx;
	P[best].z = nz;
	P[best].hp = 100;
	P[best].spawns++;
	if (best == 0)
	{
		mx = nx;
		mz = nz;
	}
}

void hostPacket(ubyte* b, int n, ref sockaddr_in from, double now)
{
	int id = -1;
	foreach (i; 1 .. MAXP)
	{
		if (P[i].used && peers[i].addr.sin_addr.s_addr == from.sin_addr.s_addr
			&& peers[i].addr.sin_port == from.sin_port)
		{
			id = i;
			break;
		}
	}

	if (b[0] == C_JOIN)
	{
		if (id < 0)
		{
			foreach (i; 1 .. MAXP)
			{
				if (!P[i].used)
				{
					id = i;
					break;
				}
			}
			if (id < 0) return; // room full
			memset(&P[id], 0, PInfo.sizeof);
			P[id].used = 1; P[id].hp = 100;
			snprintf(P[id].name.ptr, 12, "%s", cast(char*)b + 1);
			peers[id].addr = from;
			float nx, nz;
			spawnPoint(id, &nx, &nz);
			P[id].x = nx; P[id].z = nz;
			char[100] m;
			snprintf(m.ptr, 100, "%s joined the game", P[id].name.ptr);
			say(m.ptr);
		}
		peers[id].last = now;
		ubyte[2] w = [S_WELCOME, cast(ubyte)id];
		sendto(sock, w.ptr, 2, 0, cast(sockaddr*)&from, cast(socklen_t)sockaddr_in.sizeof);
		return;
	}
	if (id < 0) return;
	peers[id].last = now;

	switch (b[0])
	{
		case C_STATE:
			if (n >= 13)
			{
				memcpy(&P[id].x, b + 1, 4);
				memcpy(&P[id].z, b + 5, 4);
				memcpy(&P[id].yaw, b + 9, 4);
			}
			break;
		case C_CHAT:
		{
			char[100] m;
			snprintf(m.ptr, 100, "<%s> %s", P[id].name.ptr, cast(char*)b + 1);
			say(m.ptr);
			break;
		}
		case C_SHOOT:
			if (n >= 5 && now - peers[id].lastShot > 0.2)
			{
				peers[id].lastShot = now;
				float yaw;
				memcpy(&yaw, b + 1, 4);
				hostShoot(id, yaw);
			}
			break;
		default: break;
	}
}

void hostNet(double now)
{
	ubyte[512] buf;
	sockaddr_in from;
	while (true)
	{
		socklen_t fl = cast(socklen_t)from.sizeof;
		auto n = recvfrom(sock, buf.ptr, 500, 0, cast(sockaddr*)&from, &fl);
		if (n <= 0) break;
		buf[n] = 0;
		hostPacket(buf.ptr, cast(int)n, from, now);
	}
	foreach (i; 1 .. MAXP)
	{
		if (P[i].used && now - peers[i].last > 8)
		{
			char[100] m;
			snprintf(m.ptr, 100, "%s left the game", P[i].name.ptr);
			P[i].used = 0;
			say(m.ptr);
		}
	}
	P[0].x = mx; P[0].z = mz; P[0].yaw = myYaw;
	if (now - lastSnap > 0.05)
	{
		lastSnap = now;
		Snap s;
		s.type = S_SNAP;
		memcpy(s.p.ptr, P.ptr, P.sizeof);
		foreach (i; 1 .. MAXP)
		{
			if (P[i].used)
			{
				sendto(sock, &s, Snap.sizeof, 0, cast(sockaddr*)&peers[i].addr,
					cast(socklen_t)sockaddr_in.sizeof);
			}
		}
	}
}

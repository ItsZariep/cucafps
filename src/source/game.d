module game;

import core.stdc.stdio : snprintf;
import core.stdc.string : memcpy;
import core.stdc.math : sinf, cosf, sqrtf;
import core.sys.posix.sys.socket;
import core.sys.posix.netinet.in_;
import raylib;
import protocol;
import state;
import world;
import messages;
import host : hostNet, hostShoot;
import client : clientNet;
import input;
import ui : drawChat;
import net : leaveGame;

void play(float dt, int w, int h)
{
	double now = GetTime();
	if (isHost)
	{
		hostNet(now);
	}
	else
	{
		clientNet(now);
	}
	if (scene != 2) return;

	// chat input + pause key (desktop)
	if (!mobile)
	{
		bool escUsed = false;
		if (!chatOpen)
		{
			if (!paused && (IsKeyPressed(KeyboardKey.KEY_T) || IsKeyPressed(KeyboardKey.KEY_ENTER)))
			{
				chatOpen = true;
				chatLen = 0;
				chatInput[0] = 0;
				while (GetCharPressed() != 0) {}
			}
		}
		else
		{
			int c;
			while ((c = GetCharPressed()) != 0)
			{
				if (c >= 32 && c < 127 && chatLen < 78)
				{
					chatInput[chatLen++] = cast(char)c;
					chatInput[chatLen] = 0;
				}
			}
			if (IsKeyPressed(KeyboardKey.KEY_BACKSPACE) && chatLen > 0) chatInput[--chatLen] = 0;
			if (IsKeyPressed(KeyboardKey.KEY_ENTER))
			{
				if (chatLen > 0) sendChat(chatInput.ptr);
				chatOpen = false;

			}
			if (IsKeyPressed(KeyboardKey.KEY_ESCAPE))
			{
				chatOpen = false;
				escUsed = true;
			}
		}
		if (!chatOpen && !escUsed && (IsKeyPressed(KeyboardKey.KEY_ESCAPE) || IsKeyPressed(KeyboardKey.KEY_P)))
		{
			paused = !paused;
		}

		bool wantLock = !chatOpen && !paused;
		if (!wantLock && cursorLocked)
		{
			EnableCursor();
			cursorLocked = false;

		}
		if (wantLock && !cursorLocked)
		{
			DisableCursor();
			cursorLocked = true;
		}
	}

	// movement / look / shooting
	bool ready = isHost || joined;
	Input inp = readInput(w, h);
	float sens = mobile ? 0.005f : 0.0025f;
	if (ready && !paused)
	{
		myYaw -= inp.lookx * sens;
		pitch -= inp.looky * sens;
		if (pitch > 1.3f) pitch = 1.3f;
		if (pitch < -1.3f) pitch = -1.3f;
		float l = sqrtf(inp.fwd * inp.fwd + inp.str * inp.str);
		if (l > 1)
		{
			inp.fwd /= l;
			inp.str /= l;
		}
		float sy = sinf(myYaw), cy = cosf(myYaw);
		float dx = (sy * inp.fwd - cy * inp.str) * 5 * dt;
		float dz = (cy * inp.fwd + sy * inp.str) * 5 * dt;
		if (!blockedAt(mx + dx, mz, 0.4f)) mx += dx;
		if (!blockedAt(mx, mz + dz, 0.4f)) mz += dz;

		if (inp.fire && now - lastFire > 0.25)
		{
			lastFire = now;
			flash = 0.1f;
			if (isHost)
			{
				hostShoot(0, myYaw);
			}
			else
			{
				ubyte[5] pk;
				pk[0] = C_SHOOT;
				memcpy(pk.ptr + 1, &myYaw, 4);
				sendto(sock, pk.ptr, 5, 0, cast(sockaddr*)&hostAddr, cast(socklen_t)sockaddr_in.sizeof);
			}
		}
	}
	if (flash > 0) flash -= dt;

	// render 3D //
	Camera3D cam;
	cam.position = Vector3(mx, 1.6f, mz);
	cam.target = Vector3(mx + sinf(myYaw) * cosf(pitch), 1.6f + sinf(pitch), mz + cosf(myYaw) * cosf(pitch));
	cam.up = Vector3(0, 1, 0);
	cam.fovy = 70;
	cam.projection = 0;

	ClearBackground(Color(20, 24, 35, 255));
	BeginMode3D(cam);
	DrawPlane(Vector3(0, 0, 0), Vector2(40, 40), Colors.DARKGRAY);
	DrawGrid(40, 1);
	foreach (ref b; boxes)
	{
		DrawCube(Vector3(b.x, b.h / 2, b.z), b.hw * 2, b.h, b.hd * 2, Colors.GRAY);
		DrawCubeWires(Vector3(b.x, b.h / 2, b.z), b.hw * 2, b.h, b.hd * 2, Colors.BLACK);
	}
	foreach (i; 0 .. MAXP)
	{
		if (i == myId || !P[i].used || P[i].hp == 0) continue;
		Color c = Color(cast(ubyte)(80 + (i * 53) % 170), cast(ubyte)(60 + (i * 97) % 180), cast(ubyte)(200 - (i * 31) % 120), 255);
		DrawCube(Vector3(P[i].x, 0.9f, P[i].z), 0.8f, 1.8f, 0.8f, c);
		DrawCube(Vector3(P[i].x, 2.05f, P[i].z), 0.5f, 0.5f, 0.5f, Color(240, 200, 160, 255));
		DrawCube(Vector3(P[i].x + sinf(P[i].yaw) * 0.55f, 1.2f, P[i].z + cosf(P[i].yaw) * 0.55f), 0.15f, 0.15f, 0.15f, Colors.BLACK);
	}
	EndMode3D();

	// names above heads
	foreach (i; 0 .. MAXP)
	{
		if (i == myId || !P[i].used || P[i].hp == 0) continue;
		Vector2 s = GetWorldToScreen(Vector3(P[i].x, 2.6f, P[i].z), cam);
		float fx = P[i].x - mx, fz = P[i].z - mz;
		if (fx * sinf(myYaw) + fz * cosf(myYaw) <= 0) continue; // behind
		int tw = MeasureText(P[i].name.ptr, 18);
		DrawText(P[i].name.ptr, cast(int)s.x - tw / 2, cast(int)s.y, 18, Colors.WHITE);
	}

	// HUD //
	DrawLine(w / 2 - 10, h / 2, w / 2 + 10, h / 2, flash > 0 ? Colors.RED : Colors.WHITE);
	DrawLine(w / 2, h / 2 - 10, w / 2, h / 2 + 10, flash > 0 ? Colors.RED : Colors.WHITE);
	char[96] hud;
	if (isHost) snprintf(hud.ptr, 96, "ROOM %s:%d", localIp.ptr, PORT);
	else if (joined) snprintf(hud.ptr, 96, "Connected to %s:%d", ipText.ptr, PORT);
	else snprintf(hud.ptr, 96, "Connecting to %s ...", ipText.ptr);
	DrawRectangle(8, 8, MeasureText(hud.ptr, 24) + 16, 34, Color(0, 0, 0, 140));
	DrawText(hud.ptr, 16, 13, 24, Colors.GREEN);
	int hp = P[myId].hp;
	DrawRectangle(w / 2 - 100, h - 30, 200, 16, Color(0, 0, 0, 160));
	DrawRectangle(w / 2 - 100, h - 30, hp * 2, 16, hp > 40 ? Colors.GREEN : Colors.RED);

	drawChat(w, h, now);

	if (mobile)
	{
		Vector2 sc = Vector2(150, h - 150);
		DrawCircleLines(cast(int)sc.x, cast(int)sc.y, 110, Colors.WHITE);
		DrawCircle(cast(int)(sc.x + knob.x), cast(int)(sc.y + knob.y), 40, Color(255, 255, 255, 120));
		DrawCircle(w - 130, h - 170, 70, Color(220, 40, 40, 150));
		DrawText("FIRE", w - 160, h - 182, 28, Colors.WHITE);
		if (!paused)
		{
			if (button(Rectangle(w - 130, 10, 120, 56), "CHAT", 26)) chatOpen = !chatOpen;
			if (button(Rectangle(w - 130, 76, 120, 56), "PAUSE", 26))
			{
				paused = true;
				chatOpen = false;
			}
			if (chatOpen)
			{
				immutable(char)*[4] phrases = ["gg", "hello!", "nice shot", "help!"];
				foreach (i; 0 .. 4)
				{
					if (button(Rectangle(w / 2 - 110, 90 + i * 62, 220, 54), phrases[i], 26))
					{
						sendChat(phrases[i]);
						chatOpen = false;
					}
				}
			}
		}
	}

	// pause overlay
	if (paused)
	{
		float u = h / 720.0f;
		DrawRectangle(0, 0, w, h, Color(0, 0, 0, 150));
		const(char)* title = "PAUSED";
		int tfs = cast(int)(56 * u);
		DrawText(title, w / 2 - MeasureText(title, tfs) / 2, cast(int)(150 * u), tfs, Colors.WHITE);
		if (button(Rectangle(w / 2 - 160 * u, 280 * u, 320 * u, 80 * u), "RESUME", cast(int)(32 * u)))
		{
			paused = false;
		}
		else if (button(Rectangle(w / 2 - 160 * u, 380 * u, 320 * u, 80 * u), "QUIT TO MENU", cast(int)(30 * u)))
		{
			leaveGame("You left the room");
		}
		if (!mobile)
		{
			const(char)* hint = "P / Esc to resume";
			int hfs = cast(int)(18 * u);
			DrawText(hint, w / 2 - MeasureText(hint, hfs) / 2, cast(int)(480 * u), hfs, Colors.WHITE);
		}
	}
}

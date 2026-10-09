module fps;

import core.stdc.string : memset;
import core.stdc.stdio : snprintf;
import core.stdc.stdlib : rand, srand;
import core.stdc.time : time;
import core.sys.posix.unistd : close;
import raylib;
import state;
import net : resetPlayers;
import input : pollTap, endTouch;
import ui : menuScreen, joinScreen;
import game : play;

// main //
extern(C) int main()
{
	srand(cast(uint)time(null));
	memset(ipText.ptr, 0, ipText.sizeof);
	memset(localIp.ptr, 0, localIp.sizeof);
	memset(menuMsg.ptr, 0, menuMsg.sizeof);
	memset(chatInput.ptr, 0, chatInput.sizeof);
	memset(myName.ptr, 0, myName.sizeof);
	snprintf(myName.ptr, 12, "Player%d", rand() % 100);
	resetPlayers();

	version (Android)
	{
		mobile = true;
		InitWindow(0, 0, "CucaFPS");
	}
	else
	{
		InitWindow(1280, 720, "CucaFPS");
	}

	SetTargetFPS(60);
	SetExitKey(0);

	while (!WindowShouldClose())
	{
		float dt = GetFrameTime();
		int w = GetScreenWidth(), h = GetScreenHeight();
		pollTap();
		BeginDrawing();
		if (scene == 0) menuScreen(w, h);
		else if (scene == 1) joinScreen(w, h);
		else play(dt, w, h);
		endTouch();
		EndDrawing();
	}
	if (sock >= 0) close(sock);
	CloseWindow();
	return 0;
}

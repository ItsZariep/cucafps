module ui;

import core.stdc.stdio : snprintf;
import raylib;
import state;
import input;
import net : startHost, startClient;

// UI //
void menuScreen(int w, int h)
{
	ClearBackground(Color(20, 22, 35, 255));
	float u = h / 720.0f;
	DrawText("CUCA FPS", cast(int)(w / 2 - 110 * u), cast(int)(100 * u), cast(int)(60 * u), Colors.WHITE);
	if (menuMsg[0])
	{
		DrawText(menuMsg.ptr, 20, cast(int)(190 * u), cast(int)(22 * u), Colors.YELLOW);
	}
	if (button(Rectangle(w / 2 - 200 * u, 260 * u, 400 * u, 100 * u), "HOST ROOM", cast(int)(36 * u)))
	{
		menuMsg[0] = 0;
		if (startHost())
		{
			scene = 2;
		}
		else
		{
			snprintf(menuMsg.ptr, 80, "Could not open UDP port 7777");
		}
	}
	if (button(Rectangle(w / 2 - 200 * u, 390 * u, 400 * u, 100 * u), "JOIN ROOM", cast(int)(36 * u)))
	{
		menuMsg[0] = 0;
		scene = 1;
	}
}

void joinScreen(int w, int h)
{
	ClearBackground(Color(20, 22, 35, 255));
	float u = h / 720.0f;
	DrawText("Host IP:", cast(int)(w / 2 - 135 * u), cast(int)(30 * u), cast(int)(26 * u), Colors.WHITE);
	DrawRectangle(cast(int)(w / 2 - 135 * u), cast(int)(65 * u), cast(int)(270 * u), cast(int)(60 * u), Color(0, 0, 0, 180));
	DrawText(ipText.ptr, cast(int)(w / 2 - 125 * u), cast(int)(75 * u), cast(int)(40 * u), Colors.GREEN);
	if (menuMsg[0]) DrawText(menuMsg.ptr, 20, cast(int)(135 * u), cast(int)(20 * u), Colors.YELLOW);

	// physical keyboard (desktop)
	int c;
	while ((c = GetCharPressed()) != 0)
	{
		if (((c >= '0' && c <= '9') || c == '.') && ipLen < 15)
		{
			ipText[ipLen++] = cast(char)c;
			ipText[ipLen] = 0;
		}
	}
	if (IsKeyPressed(KeyboardKey.KEY_BACKSPACE) && ipLen > 0) ipText[--ipLen] = 0;

	// on-screen keypad (Android)
	foreach (k; 0 .. 12)
	{
		char[2] lab;
		lab[0] = "123456789.0<"[k];
		lab[1] = 0;
		float bx = w / 2 - 135 * u + (k % 3) * 92 * u;
		float by = 150 * u + (k / 3) * 72 * u;
		if (button(Rectangle(bx, by, 86 * u, 66 * u), lab.ptr, cast(int)(32 * u)))
		{
			if (lab[0] == '<')
			{
				if (ipLen > 0)
				{
					ipText[--ipLen] = 0;
				}
			}
			else if (ipLen < 15)
			{
				ipText[ipLen++] = lab[0];
				ipText[ipLen] = 0;
			}
		}
	}
	if (button(Rectangle(w / 2 - 135 * u, 450 * u, 270 * u, 66 * u), "CONNECT", cast(int)(30 * u)))
	{
		menuMsg[0] = 0;
		if (startClient())
		{
			scene = 2;
		}
		else
		{
			snprintf(menuMsg.ptr, 80, "Invalid IP address");
		}
	}
	if (button(Rectangle(w / 2 - 135 * u, 525 * u, 270 * u, 56 * u), "BACK", cast(int)(26 * u)))
	{
		scene = 0;
	}
}

void drawChat(int w, int h, double now)
{
	int startY = mobile ? 90 : h - 70 - 8 * 24;
	foreach (i; 0 .. 8)
	{
		if (chat[i].t[0] == 0) continue;
		double age = now - chat[i].time;
		if (!chatOpen && age > 8) continue;
		int a = 255;
		if (!chatOpen && age > 6)
		{
			a = cast(int)(255 * (8 - age) / 2);
		}
		int y = startY + i * 24;
		DrawRectangle(8, y, 560, 22, Color(0, 0, 0, cast(ubyte)(a * 110 / 255)));
		DrawText(chat[i].t.ptr, 12, y + 2, 18, Color(255, 255, 255, cast(ubyte)a));
	}
	if (!mobile && chatOpen)
	{
		DrawRectangle(8, h - 40, 560, 26, Color(0, 0, 0, 170));
		DrawText(chatInput.ptr, 12, h - 37, 20, Colors.WHITE);
		int tw = MeasureText(chatInput.ptr, 20);
		if ((cast(int)(now * 2)) & 1)
		{
			DrawRectangle(14 + tw, h - 37, 10, 20, Colors.WHITE);
		}
	}
}

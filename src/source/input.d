module input;

import core.stdc.math : sqrtf;
import raylib;
import state;

// // input //
void pollTap()
{
	g_hasTap = false;

	int n = GetTouchPointCount();
	if (n > 0) mobile = true; // a finger touched the screen -> touch device

	// touch: any finger that was not down last frame is a new tap
	foreach (i; 0 .. n)
	{
		if (!tDown[GetTouchPointId(i) & 15])
		{
			g_hasTap = true;
			g_tap = GetTouchPosition(i);
		}
	}

	// mouse: only on non-touch devices
	if (!mobile && !g_hasTap && IsMouseButtonPressed(0))
	{
		g_hasTap = true;
		g_tap = GetMousePosition();
	}
}

void endTouch()
{
	bool[16] seen;
	int n = GetTouchPointCount();
	foreach (i; 0 .. n)
	{
		int s = GetTouchPointId(i) & 15;
		seen[s] = true;
		tPos[s] = GetTouchPosition(i);
	}
	foreach (s; 0 .. 16)
	{
		tDown[s] = seen[s];
	}
}

bool inRect(Vector2 p, Rectangle r)
{
	return CheckCollisionPointRec(p, r);
}

bool button(Rectangle r, const(char)* label, int fs)
{
	DrawRectangleRec(r, Color(30, 30, 50, 220));
	DrawRectangleLines(cast(int)r.x, cast(int)r.y, cast(int)r.width, cast(int)r.height, Colors.WHITE);
	int tw = MeasureText(label, fs);
	DrawText(label, cast(int)(r.x + (r.width - tw) / 2), cast(int)(r.y + (r.height - fs) / 2), fs, Colors.WHITE);
	return g_hasTap && inRect(g_tap, r);
}

struct Input
{
	float fwd, str, lookx, looky;
	bool fire;
}

Input readInput(int w, int h)
{
	Input r = Input(0, 0, 0, 0, false);
	if (paused) return r;

	int touchCount = GetTouchPointCount();
	if (touchCount > 0) mobile = true;

	version (Android)
	{
		mobile = true;
	}

	if (mobile)
	{
		Vector2 sc = Vector2(150, h - 150);
		float rad = 110;
		knob = Vector2(0, 0);

		foreach (i; 0 .. touchCount)
		{
			int s = GetTouchPointId(i) & 15;
			Vector2 p = GetTouchPosition(i);

			// Debug: draw touch positions
			// DrawCircle(cast(int)p.x, cast(int)p.y, 20, Color(255, 0, 0, 128));

			Vector2 fireC = Vector2(w - 130, h - 170);
			float fdx = p.x - fireC.x, fdy = p.y - fireC.y;

			// Movement joystick (left side)
			if (p.x < w * 0.4f && p.y > h * 0.35f)
			{
				float dx = (p.x - sc.x) / rad, dy = (p.y - sc.y) / rad;
				float l = sqrtf(dx * dx + dy * dy);
				if (l > 1)
				{
					dx /= l;
					dy /= l;
				}
				r.str = dx;
				r.fwd = -dy;
				knob = Vector2(dx * rad, dy * rad);
			}
			// Fire button (right side)
			else if (fdx * fdx + fdy * fdy < 90 * 90)
			{
				r.fire = true;
			}
			// UI buttons (top right)
			else if (p.x > w - 140 && p.y < 150)
			{
				// CHAT / PAUSE buttons - handled by button() in play()
			}
			// Look area (rest of screen)
			else
			{
				// Check if this touch was already tracked
				if (tDown[s])
				{
					r.lookx += p.x - tPos[s].x;
					r.looky += p.y - tPos[s].y;
				}
			}
		}
		if (chatOpen)
		{
			r.fire = false;
			r.lookx = 0;
			r.looky = 0;
		}
	}
	else
	{
		// Desktop input
		if (!chatOpen)
		{
			r.fwd = (IsKeyDown(KeyboardKey.KEY_W) ? 1.0f : 0.0f) - (IsKeyDown(KeyboardKey.KEY_S) ? 1.0f : 0.0f);
			r.str = (IsKeyDown(KeyboardKey.KEY_D) ? 1.0f : 0.0f) - (IsKeyDown(KeyboardKey.KEY_A) ? 1.0f : 0.0f);
			Vector2 d = GetMouseDelta();
			r.lookx = d.x;
			r.looky = d.y;
			r.fire = IsMouseButtonDown(0);
		}
	}
	return r;
}

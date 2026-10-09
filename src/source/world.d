module world;

import core.stdc.stdlib : rand;
import core.stdc.math : fabsf;

// world //
struct Box
{
	float x, z, hw, hd, h;
}
immutable Box[6] boxes =
[
	Box(0, 0, 2, 2, 3),
	Box(8, 8, 1.5f, 1.5f, 2.5f),
	Box(-8, 8, 1.5f, 1.5f, 2.5f),
	Box(8, -8, 1.5f, 1.5f, 2.5f),
	Box(-8, -8, 1.5f, 1.5f, 2.5f),
	Box(0, 11, 4, 0.5f, 2)
];

bool blockedAt(float x, float z, float r)
{
	if (x > 19 || x < -19 || z > 19 || z < -19) return true;
	foreach (ref b; boxes)
	{
		if (fabsf(x - b.x) < b.hw + r && fabsf(z - b.z) < b.hd + r) return true;
	}
	return false;
}

void spawnPoint(int i, float* x, float* z)
{
	int k = (i + rand()) & 3;
	*x = (k & 1) ? 15.0f : -15.0f;
	*z = (k & 2) ? 15.0f : -15.0f;
}

// host: line-of-sight check for hit scan
bool rayBlocked(float sx, float sz, float fx, float fz, float dist)
{
	for (float t = 0.3f; t < dist; t += 0.2f)
	{
		foreach (ref b; boxes)
		{
			if (fabsf(sx + fx * t - b.x) < b.hw && fabsf(sz + fz * t - b.z) < b.hd) return true;
		}
	}
	return false;
}

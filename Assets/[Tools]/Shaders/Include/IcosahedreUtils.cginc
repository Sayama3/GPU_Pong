#ifndef _ICOSAHEDRE_UTILS_INCLUDED_
#define _ICOSAHEDRE_UTILS_INCLUDED_

static const float phi = (1 + sqrt(5)) / 2.0;
static const float fixRadius = 1 / sqrt(1 + phi * phi);

float3 IcosahedreMagicNumber(uint sectorIndex)
{
	// https://fr.wikipedia.org/wiki/Icosa%C3%A8dre 
#if 0
	// will be encoded as a very small buffer bound to the shader.
	static const float3 MagicNumbers[] =
	{
		fixRadius * float3(0,   -1, phi),
		fixRadius * float3(1, -phi,   0),
		fixRadius * float3(phi,    0,  -1),
		fixRadius * float3(1,  phi,  0),
		fixRadius * float3(0,    1, phi),
	};

	return MagicNumbers[sectorIndex];
#else
	uint sub = sectorIndex >= 2 ? (sectorIndex - 2) : (2 - sectorIndex);

	float3 result = sub == 1 ? fixRadius * float3(1, phi, 0) : fixRadius * float3(phi, 0, -1);
	result = sub == 2 ? fixRadius * float3(0, 1, phi) : result;
	result.y = sectorIndex >= 2 ? result.y : -result.y;
	return result;
#endif
}

void GetIcosahedreVertexInfo(uint vertexIndex, uint triIndex, out float3 position, out float3 normal)
{
	const bool parity = triIndex % 2;
	const bool symetry = (triIndex / 2) % 2;
	const uint sectorIndex = (triIndex / 4) % 5;
	const bool reverseOrder = parity ^ symetry; // to keep same culling order

	uint3 sectorIndices = sectorIndex + uint3(!reverseOrder, reverseOrder, 3);
	sectorIndices %= 5;

	const float3 vertexC = -IcosahedreMagicNumber(sectorIndices.z);
	const float3 vertex0 = parity ? vertexC : fixRadius * float3(phi, 0, 1);

	const float3 vertex1 = IcosahedreMagicNumber(sectorIndices.x);
	const float3 vertex2 = IcosahedreMagicNumber(sectorIndices.y);

	// no need to reverse normal, because when symetry is true, the normal is already reversed by "reverseOrder" way of computation (tricky !!)
	normal = cross(vertex1 - vertex0, vertex2 - vertex0);

	position = vertexIndex == 1 ? vertex1 : vertex0;
	position = vertexIndex == 2 ? vertex2 : position;
	position = symetry ? -position : position;
}

#endif

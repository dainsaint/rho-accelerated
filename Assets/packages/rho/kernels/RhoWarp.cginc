bool inRadius( float3 position, float3 center, float radius )
{
    float3 d = position - center;
    return dot(d,d) < radius * radius;
}


/*
	xyz = position
	w = intersectionType
		0 => none
		1 => entering
		2 => inside 
		3 => leaving
*/

float4 intersectsSphere( float3 position, float3 velocity, float deltaTime, float3 center, float radius )
{
	float3 nextPositionOffset = velocity * deltaTime;
	float3 p1 = position - center;
	float3 p2 = p1 + nextPositionOffset;

	float sqrRadius = radius * radius;

	if( dot(p1,p1) < sqrRadius && dot(p2,p2) < sqrRadius )
	{
		return float4( position, 2 );
	}


	float3 segment = p2 - p1;

	float a = dot(segment, segment);
	float b = 2 * dot( segment, p1 );
	float c = dot(p1,p1) - sqrRadius;

	float discriminant = b * b - 4 * a * c;

	float two_a = 2 * a;
	if( discriminant == 0 )
	{
		//TANGENT

		float t = -b/(two_a);
		float3 p = p1 + t * segment;
		p.z = position.z;

		return float4( p, 2 );
	} 

	if( discriminant > 0 )
	{

		float discSqrt = sqrt(discriminant);
		float t0 = (-b - discSqrt) / two_a;
		float t1 = (-b + discSqrt) / two_a;

		if( t0 > t1 )
		{
			float temp = t0;
			t0 = t1;
			t1 = temp;
		}

		if( t0 > 0 && t0 <= 1 )
		{
			return float4( position + t0 * nextPositionOffset, 1 );
		}

		if( t1 > 0 && t1 <= 1 )
		{
			return float4( position + t1 * nextPositionOffset, 3 );
		}
	} 

	return float4( position, 0 );

	//return (float4)0;
}




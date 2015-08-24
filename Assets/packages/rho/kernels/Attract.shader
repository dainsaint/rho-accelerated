Shader "Hidden/Rho/Kernels/Attract" {

	Properties 
	{
		_PositionTex ("-", 2D) = ""{}
        _VelocityTex ("-", 2D) = ""{}
	}

	CGINCLUDE

		#include "UnityCG.cginc"
		#include "RhoWarp.cginc"

		sampler2D _PositionTex;
		sampler2D _VelocityTex;
		
		float4 _PositionTex_TexelSize;
    	float4 _VelocityTex_TexelSize;

    	float3 _Position;
    	float _Radius;
    	float _Strength;

    	float2 _TimeParams; // (current, delta)
    	

	    float4 frag_update_position(v2f_img i) : SV_Target
	    {
	    	//float2 uv_prev = float2(_PositionTex_TexelSize.x, 0);
	        float4 p = tex2D(_PositionTex, i.uv);

	        return p;
	    }

		float4 frag_update_velocity(v2f_img i) : SV_Target
		{
			// Only needs the leftmost pixel.
	        float2 uv = i.uv * float2(0, 1);

	        // Fetch the current position/velocity.
	        float3 p = tex2D(_PositionTex, uv).xyz;
	        float3 v = tex2D(_VelocityTex, uv).xyz;

	       	bool inRange = inRadius( p, _Position, _Radius );

	       	if( inRange )
	       	{
	       		float3 d = _Position - p;
	       		float3 normal = float3(0,0,1);

	       		float3 dist = normal * d;
	       		float3 projected = p - dist * normal;
	       		float3 change = _Position - projected;

	       		float3 force = _Strength * change;
	        	v += force * _TimeParams.y;
	        	v *= (1.0 - 0.9 * _TimeParams.y);
	        }


	        return float4(v, 0);
		}


	ENDCG


	SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_update_position
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_update_velocity
            ENDCG
        }

    }



}

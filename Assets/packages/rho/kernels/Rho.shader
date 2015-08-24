Shader "Hidden/Rho/Kernels/Rho" {

	Properties 
	{
		_PositionTex ("-", 2D) = ""{}
        _VelocityTex ("-", 2D) = ""{}
	}


	CGINCLUDE

		#include "UnityCG.cginc"
		#include "ClassicNoise3D.cginc"

		#pragma multi_compile _ ENABLE_ATTRACT

		sampler2D _PositionTex;
		sampler2D _VelocityTex;
		
		float4 _PositionTex_TexelSize;
    	float4 _VelocityTex_TexelSize;


    	float _RandomSeed;

    	float3 _Direction;
    	float _Speed;
    	float _Drag;
    	float2 _TimeParams; // (current, delta)
    	float3 _AttractPos;

    	float _Rate;

    	// Pseudo random number generator
	    float nrand(float2 uv, float salt)
	    {
	        uv += float2(salt, _RandomSeed);
	        return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453); 
	    }


	    // Position dependant force field



	    float3 position_force(float3 p, float2 uv)
	    {

	    	float4 _NoiseParams = float4( 0.1, 5, 1, 2 );

	        p = p * _NoiseParams.x + _TimeParams.x * _NoiseParams.z + _RandomSeed;
	        float3 uvc = float3(uv, 7.919) * _NoiseParams.w;
	        float nx = cnoise(p + uvc.xyz);
	        float ny = cnoise(p + uvc.yzx);
	        float nz = cnoise(p + uvc.zxy);
	        return float3(nx, ny, nz) * _NoiseParams.y;
	    }

	    // Attractor position
	    float3 attract_point(float2 uv)
	    {
	        float3 r = float3(nrand(uv, 0), nrand(uv, 1), nrand(uv, 2));
	        return float3(0) + (r - (float3)0.5) * 5;
	    }
	

		float4 frag_init_position(v2f_img i) : SV_Target 
	    {

	        return float4( 0, 0, 0, 0 );
	    }

	    // Pass 1: velocity initialization
	    float4 frag_init_velocity(v2f_img i) : SV_Target 
	    {
	        return float4( 0, 0, 0, 0 );
	    }

	    float should_initialize( float2 uv )
	    {
	    	float r = _Rate ;
	    	float v_start = r * (_TimeParams.x) % 1;
	        float v_end = v_start + r * _TimeParams.y;

        	return uv.y >= v_start && uv.y < v_end;
	    }

    	float4 frag_update_position(v2f_img i) : SV_Target
    	{
    		float2 uv_prev = float2(_PositionTex_TexelSize.x, 0);
	        float4 p = tex2D(_PositionTex, i.uv - uv_prev);
	        float4 pv = tex2D(_PositionTex, i.uv);


	        float _Lifetime = 1/_Rate;
	        
	      
        	

      
        	if( should_initialize(i.uv) )
        	{
        		//initialize
        		p = float4(nrand( i.uv.yy, 0 ), nrand( i.uv.yy, 1 ), nrand( i.uv.yy, 2 ), _Lifetime);
        	} else {

        		float3 flow = (float3)0;
	       		float3 v = tex2D(_VelocityTex, i.uv).xyz;
	       		float u_0 = i.uv.x < _PositionTex_TexelSize.x;

        		p = float4( p.xyz + lerp(flow, v, u_0) * _TimeParams.y, p.w - _TimeParams.y );
        	}

        	//p.xyz = should_initialize(i.uv);

	       return p;
    	}

		float4 frag_update_velocity(v2f_img i) : SV_Target
		{
			// Only needs the leftmost pixel.
	        float2 uv = i.uv * float2(0, 1);

	        // Fetch the current position/velocity.
	        float4 p = tex2D(_PositionTex, uv);
	        float3 v = tex2D(_VelocityTex, uv).xyz;/// + _Speed * float3( nrand(uv, 5), nrand(uv, 15), nrand(uv, 12) );


	        float v_start = _Rate * _TimeParams.x;
        	float v_end = v_start + _Rate * _TimeParams.y;

        	float activate = uv.y >= v_start && uv.y < v_end;

       		if( should_initialize(i.uv) )
        	{
        		v = _Speed * _Direction;
        	} else {
        		v *= (1.0 - _Drag * _TimeParams.y);
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
            #pragma fragment frag_init_position
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_init_velocity
            ENDCG
        }
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

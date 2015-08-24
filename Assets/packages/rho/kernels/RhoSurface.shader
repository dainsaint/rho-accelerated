//
// Surface shader for Swarm
//
// Texture format:
//
// _PositionTex.xyz = position
// _PositionTex.w   = random number
//
Shader "Rho/Surface"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = ""{}
        _EmissionGain("Emission Gain", Range(0,1) ) = 0.3
    }

    CGINCLUDE

    #pragma multi_compile COLOR_RANDOM COLOR_SMOOTH

    sampler2D _PositionTex;
    float4 _PositionTex_TexelSize;

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    float _LineWidth;
    half4 _Color1;

    float _EmissionGain;

    float2 _BufferOffset;

    struct Input {
        float4 color;
        float2 uv_MainTex;
        float2 someUV;
    };

    // pseudo random number generator
    float nrand(float2 uv, float salt)
    {
        uv += float2(salt, 0);
        return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
    }

    void vert(inout appdata_full v, out Input data, float flip)
    {
        UNITY_INITIALIZE_OUTPUT(Input, data);

        float4 uv = float4(v.texcoord + _BufferOffset, 0, 0);
        float4 duv = float4(_PositionTex_TexelSize.x, 0, 0, 0);

        // line number
        float ln = uv.y;

        // adjacent vertices
        float3 p1 = tex2Dlod(_PositionTex, uv - duv * 2).xyz;
        float3 p2 = tex2Dlod(_PositionTex, uv          ).xyz;
        float3 p3 = tex2Dlod(_PositionTex, uv + duv * 2).xyz;

        // binormal vector
    /*    float3 bn = normalize(cross(p3 - p2, p2 - p1)) * flip;
        
        bn = float3(flip,0,0);

        v.vertex.xyz = p2 + bn * _LineWidth *  v.vertex.x;
        v.normal = normalize(cross(bn, p2 - p1));
*/

        v.normal = normalize( WorldSpaceViewDir(v.vertex) );

        float3 bn = normalize(cross(v.normal, p2 - p1)) * flip;
        
        v.vertex.xyz = p2 + bn * _LineWidth *  v.vertex.x;
       
        data.someUV = v.texcoord1;


        data.color = float4(v.normal,1);

    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Transparent" }

        
        CGPROGRAM

        #pragma surface surf Standard vertex:vert_front nolightmap addshadow alpha:fade
        #pragma target 3.0

        void vert_front(inout appdata_full v, out Input data)
        {
            vert(v, data, 1);
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {

            float4 color = _Color1 * tex2D (_MainTex, IN.someUV);

            o.Albedo = float4(1,1,1,1);
            o.Alpha = color.a;
            o.Emission = pow( color.rgb , 2.2 )* exp(_EmissionGain * 5.0f);
        }

        ENDCG

        CGPROGRAM

        #pragma surface surf Standard vertex:vert_back nolightmap addshadow alpha:fade
        #pragma target 3.0

        void vert_back(inout appdata_full v, out Input data)
        {
            vert(v, data, -1);
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float4 color = _Color1 * tex2D (_MainTex, IN.someUV);
            
            o.Albedo = float4(1,1,1,1);
            o.Alpha = color.a;
            o.Emission = pow( color.rgb , 2.2 )* exp(_EmissionGain * 5.0f);
        }

        ENDCG
    }
}

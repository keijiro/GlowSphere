//
// GPGPU kernels for Burst.
//
// MainTex format:
// .xyz = beam tip position
//

Shader "Hidden/Kvant/Burst/Kernel"
{
    Properties
    {
        _MainTex ("-", 2D)     = ""{}
        _Config  ("-", Vector) = (1, 0, 0, 0)   // (random seed, throttle, 0, 0)
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float4 _Config;

    // PRNG function.
    float nrand(float2 uv, float salt)
    {
        uv += float2(salt, _Config.x);
        return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
    }

    // Get a new beam.
    float4 new_beam(float2 uv)
    {
        float t = _Time.x;

        float u1 = nrand(uv, t + 1) * 2 - 1;
        float u2 = sqrt(1 - u1 * u1);
        float theta = nrand(uv, t + 2) * 3.14 * 2;

        float3 p = float3(u2 * cos(theta), u2 * sin(theta), u1) * nrand(uv, t + 3);

        // Random position.
        //float3 p = float3(nrand(uv, t + 1), nrand(uv, t + 2), nrand(uv, t + 3));
        //p -= (float3)0.5;

        // Throttling.
        return float4(p, 0) * (uv.x < _Config.y);
    }

    // Pass 0: Initialization
    float4 frag_init(v2f_img i) : SV_Target 
    {
        return new_beam(i.uv);
    }

    // Pass 1: Update
    float4 frag_update(v2f_img i) : SV_Target 
    {
        return tex2D(_MainTex, i.uv.xy);
        //return new_beam(i.uv);
    }

    ENDCG

    SubShader
    {
        // Pass 0: Initialization
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_init
            ENDCG
        }
        // Pass 1: Update
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_update
            ENDCG
        }
    }
}

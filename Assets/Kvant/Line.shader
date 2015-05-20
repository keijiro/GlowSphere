//
// Line shader for Burst.
//
// Vertex format:
// position.x  = origin (0) or tip (1)
// texcoord.xy = uv for BeamTex
//
Shader "Hidden/Kvant/Burst/Line"
{
    Properties
    {
        _BeamTex     ("-", 2D)    = ""{}
        [HDR] _Color ("-", Color) = (1, 1, 1, 1)
        _Radius      ("-", Float) = 1

        _Speed ("Speed", float)  = 6
        _Alpha ("Alpha", Vector) = (10, 8, 4, 0)
        _Beta  ("Beta",  Vector) = (0.028, 0.047, 0.032, 0)
        _Gamma ("Gamma", Vector) = (1, 2.789, 3.21, 0)
    }

    CGINCLUDE

    #pragma multi_compile_fog

    #include "UnityCG.cginc"

    struct appdata
    {
        float4 position : POSITION;
        float2 texcoord : TEXCOORD0;
    };

    struct v2f
    {
        float4 position : SV_POSITION;
        half4 color : COLOR;
        UNITY_FOG_COORDS(0)
    };

    sampler2D _BeamTex;
    float4 _BeamTex_TexelSize;

    half4 _Color;
    float _Radius;

    float _Speed;
    float3 _Alpha;
    float3 _Beta;
    float3 _Gamma;

    float wave(float3 p)
    {
        float t = _Time.y * _Speed;
        float a = sin(p.x * _Alpha.x * sin(t * _Beta.x)  * _Gamma.x +
                  sin(p.y * _Alpha.y * sin(t * _Beta.y)) * _Gamma.y +
                  sin(p.z * _Alpha.z * sin(t * _Beta.z)) * _Gamma.z + t);
        return (a + 1) / 2;
    }

    v2f vert(appdata v)
    {
        v2f o;

        float sw = v.position.x;

        float2 uv = v.texcoord.xy + _BeamTex_TexelSize.xy / 2;
        float3 p = tex2D(_BeamTex, uv).xyz;

        if (wave(normalize(p) /2 + float3(0, 0.6, 0)) > 0.2) p = normalize(p) * 0.5 / _Radius;

        o.position = mul(UNITY_MATRIX_MVP, float4(p * sw * _Radius, 1));

        o.color = _Color;
        o.color.a *= (1.0 - sw);

        UNITY_TRANSFER_FOG(o, o.position);

        return o;
    }

    half4 frag(v2f i) : SV_Target
    {
        fixed4 c = i.color;
        UNITY_APPLY_FOG(i.fogCoord, c);
        return c;
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    } 
}

Shader "Custom/GlowSphere"
{
    Properties
    {
        _Color     ("Color",      Color     ) = (1,1,1,1)
        _Emission  ("Emission",   Color     ) = (1,1,1,1)
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic  ("Metallic",   Range(0,1)) = 0.0
        _Cutoff    ("Cutoff",     Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows addshadow alphatest:_Cutoff
        #pragma target 3.0

        struct Input
        {
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        half4 _Color;
        half4 _Emission;

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            o.Albedo = _Color.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = _Emission;

            o.Alpha =
                sin(IN.worldPos.y * 30 + _Time.y + sin(IN.worldPos.x * 20)) +
                sin(IN.worldPos.z * IN.worldPos.x * 30 + _Time.w) +
                sin(IN.worldPos.z * 30);
        }
        ENDCG
    } 
    FallBack "Diffuse"
}

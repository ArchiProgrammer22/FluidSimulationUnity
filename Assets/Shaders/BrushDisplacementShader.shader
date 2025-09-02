Shader "Custom/BrushDisplacementShader"
{
    Properties
    {
        _MainTex ("Texture (R=height, G=velocity)", 2D) = "white" {}
        _BrushPos ("Brush Position", Vector) = (-1,-1,0,0)
        _BrushRadius ("Brush Radius", Range(0, 0.5)) = 0.05
        _BrushStrength ("Brush Strength (height)", Range(-1, 1)) = 0.1
        _ImpulseStrength ("Impulse Strength (velocity)", Range(-5,5)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
            struct v2f { half2 uv : TEXCOORD0; float4 vertex : SV_POSITION; };

            sampler2D _MainTex;
            half4 _BrushPos;
            half _BrushRadius;
            half _BrushStrength;
            half _ImpulseStrength;

            v2f vert(appdata v) 
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                half2 uv = i.uv;
                half2 brush = _BrushPos.xy;
                half dist = distance(uv, brush);

                fixed4 prev = tex2D(_MainTex, uv);
                half height = prev.r;
                half vel = prev.g;

                half inner = saturate(1.0h - dist / _BrushRadius);
                half deltaH = -inner * _BrushStrength;
                height += deltaH;
                vel += -deltaH * _ImpulseStrength;

                return half4(height, vel, 0, 0);
            }
            ENDCG
        }
    }
}

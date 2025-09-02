Shader "Custom/DisplacementSimulationShader_Mobile"
{
    Properties
    {
        _MainTex ("Displacement (R=height, G=vel)", 2D) = "white" {}
        _DeltaTime ("Delta Time", Float) = 0.016
        _Stiffness ("Stiffness", Range(0,2000)) = 200.0
        _Damping ("Damping", Range(0,10)) = 2.0
        _EnableOscillation ("Enable Oscillation", Range(0,1)) = 1
        _DecayFactor ("Decay factor", Range(0, 10)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _DeltaTime;
            half _Stiffness;
            half _Damping;
            half _EnableOscillation;
            half _DecayFactor;

            fixed4 frag(v2f_img i) : SV_Target
            {
                half2 uv = i.uv;
                half2 prev = tex2D(_MainTex, uv).rg;
                half x = prev.r;     
                half v = prev.g;     

                // модель с осцилляциями
                half a = -_Stiffness * x - _Damping * v;
                half v1 = v + a * _DeltaTime;
                half x1 = x + v1 * _DeltaTime;

                // модель простого затухания
                half decay = 1.0h - (_DecayFactor * _DeltaTime);
                decay = max(decay, 0.0h);
                half x2 = x * decay;
                half v2 = v * decay;

                // линейный выбор без ветвлений
                x = lerp(x2, x1, _EnableOscillation);
                v = lerp(v2, v1, _EnableOscillation);

                return half4(x, v, 0, 0);
            }
            ENDCG
        }
    }
}

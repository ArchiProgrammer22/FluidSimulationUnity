Shader "Custom/MeshCombinedShader_Half" 
{
    Properties 
    {
        _BaseColor ("Base Color (Deep Color)", Color) = (0.05,0.25,0.4,1)
        _PearlescentColor ("Surface Color (Light Color)", Color) = (0.2,0.8,0.5,1)
        _Metallic ("Metallic", Range(0,1)) = 0.8
        _Smoothness ("Smoothness", Range(0,1)) = 0.9
        _CubeMap ("Reflection CubeMap", Cube) = "" {}
        _NoiseScale ("Noise Scale", Range(0.1, 10)) = 1.5
        _NoiseSpeed ("Noise Speed", Range(0, 10)) = 1.0
        _NoiseAmplitude ("Noise Amplitude", Range(0, 5)) = 0.1
        _DisplacementMap ("Displacement Map", 2D) = "black" {}
        _DisplacementStrength ("Displacement Strength", Range(-1,1)) = 0.2
    }

    SubShader 
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0
        #pragma multi_compile_instancing

        #include "UnityCG.cginc"

        samplerCUBE _CubeMap;
        fixed4 _BaseColor;
        fixed4 _PearlescentColor;
        half _Metallic;
        half _Smoothness;
        half _NoiseScale;
        half _NoiseSpeed;
        half _NoiseAmplitude;
        sampler2D _DisplacementMap;
        half _DisplacementStrength;
        half4 _DisplacementMap_ST;

        half2 fade(half2 t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

        half2 hash(half2 p) 
        { 
            p = half2(dot(p, half2(127.1, 311.7)), dot(p, half2(269.5, 183.3))); 
            return -1.0 + 2.0 * frac(sin(p) * 43758.5453123); 
        }

        half perlinNoise(half2 p) 
        { 
            half2 i = floor(p); 
            half2 f = frac(p); 
            half2 u = f * f * (3.0 - 2.0 * f); 

            half2 a = hash(i); 
            half2 b = hash(i + half2(1.0, 0.0)); 
            half2 c = hash(i + half2(0.0, 1.0)); 
            half2 d = hash(i + half2(1.0, 1.0)); 

            half res = lerp(
                lerp(dot(a, f), dot(b, f - half2(1.0, 0.0)), u.x), 
                lerp(dot(c, f - half2(0.0, 1.0)), dot(d, f - half2(1.0, 1.0)), u.x), 
                u.y
            ); 
            return res * 0.5 + 0.5; 
        }

        half perlinNoiseOctaves(half2 p, int octaves) 
        { 
            half total = 0.0; 
            half frequency = 1.0; 
            half amplitude = 1.0; 
            half maxVal = 0.0; 
            for (int i = 0; i < octaves; i++) 
            { 
                total += perlinNoise(p * frequency) * amplitude; 
                maxVal += amplitude; 
                amplitude *= 0.5; 
                frequency *= 2.0; 
            } 
            return total / maxVal; 
        }

        half3 getNormal(half2 noiseCoord) 
        { 
            half tiny_step = 0.001; 
            half n_dx = perlinNoiseOctaves(noiseCoord + half2(tiny_step, 0.0), 2); 
            half n_dy = perlinNoiseOctaves(noiseCoord + half2(0.0, tiny_step), 2); 

            half3 tangent = normalize(half3(tiny_step, (n_dx - perlinNoiseOctaves(noiseCoord, 2)) * _NoiseAmplitude, 0.0)); 
            half3 binormal = normalize(half3(0.0, (n_dy - perlinNoiseOctaves(noiseCoord, 2)) * _NoiseAmplitude, tiny_step)); 
            return normalize(cross(tangent, binormal)); 
        }

        struct Input 
        { 
            half3 worldNormal; 
            half3 viewDir; 
            half3 worldPos; 
            half2 uv_DisplacementMap : TEXCOORD0; 
        };

        void vert (inout appdata_full v, out Input o) 
        { 
            UNITY_INITIALIZE_OUTPUT(Input, o); 
            half2 noiseCoord = half2(v.vertex.x, v.vertex.z) * _NoiseScale + _Time.y * _NoiseSpeed; 
            half noiseValue = perlinNoiseOctaves(noiseCoord, 4); 
            half noiseDisp = noiseValue * _NoiseAmplitude; 

            half2 dispUV = v.texcoord.xy; 
            fixed4 packed = tex2Dlod(_DisplacementMap, half4(dispUV, 0.0, 0.0)); 
            half drawnDisp = packed.r * _DisplacementStrength; 
            half totalDisp = noiseDisp + drawnDisp; 

            v.vertex.xyz += v.normal * totalDisp; 
            v.normal = getNormal(noiseCoord); 

            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; 
            o.uv_DisplacementMap = TRANSFORM_TEX(v.texcoord, _DisplacementMap); 
        }

        void surf (Input IN, inout SurfaceOutputStandard o) 
        { 
            half gradientFactor = saturate((IN.worldPos.y - _WorldSpaceCameraPos.y + 0.15) / 0.3); 
            fixed3 finalColor = lerp(_BaseColor.rgb, _PearlescentColor.rgb, gradientFactor); 

            o.Albedo = finalColor; 
            half fresnel = pow(1.0 - dot(normalize(IN.viewDir), normalize(IN.worldNormal)), 3.0); 
            o.Albedo = o.Albedo * (1.0 - fresnel * 0.2) + _PearlescentColor.rgb * fresnel * 0.2; 

            o.Metallic = _Metallic; 
            o.Smoothness = _Smoothness; 

            fixed3 reflection = texCUBE(_CubeMap, reflect(-IN.viewDir, normalize(IN.worldNormal))).rgb; 
            o.Emission = reflection * fresnel * 0.01; 
        }
        ENDCG
    }
    FallBack "Standard"
}

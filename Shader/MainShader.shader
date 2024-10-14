Shader "Unlit/MainShader"
{
    Properties
    {
        [Header(Blur)]
        [Space(5)]
        _MainTex ("Texture", 2D) = "white" {}
        [MaterialToggle] _BlurActive ("BlurActive", Float) = 0
        [MaterialToggle] _Optimized ("Optimized", Float) = 0
        _BlendFactor ("BlendFactor", Range(0, 1)) = 0.25 
        _BlurRadius ("BlendRadius", Range(0, 1)) = 0.25 
        _BlurStep ("BlurStep", Float) = 4 

        [Space(20)]
        [Header(Brightness)]
        [Space(5)]
        //Brightness
        [MaterialToggle] _BrightnessActive ("BrightnessActive", Float) = 0
        _BrightnessAmount ("BrightnessAmount", Float) = 0.25 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Blur
            float _BlendFactor;  
            float _BlurRadius;  
            float _BlurStep;  
            float _Optimized;
            float _BlurActive;

            // Brightness
            float _BrightnessAmount;
            float _BrightnessActive;

            fixed4 nonOptimizedBlurShader(fixed4 finalColor, float2 uv)
            {
                float2 offsets[8] = {
                    float2(0, 1),    
                    float2(1, 0),    
                    float2(0, -1),   
                    float2(-1, 0),   
                    float2(1, 1),    
                    float2(-1, -1),  
                    float2(1, -1),   
                    float2(-1, 1),    
                };
                
                for (int j = 0; j < 8; j++)
                {
                    finalColor += tex2D(_MainTex, uv + offsets[j] * _BlurRadius);

                    for (int i = 1; i <= _BlurStep; i++)
                    {
                        finalColor += tex2D(_MainTex, uv + (offsets[j] / i) * _BlurRadius);
                    }
                }

                return finalColor;
            }

            fixed4 optimizedBlurShader(fixed4 finalColor, float2 uv)
            {
                float2 offsets[4] = {
                    float2(0, 1),    
                    float2(1, 0),    
                    float2(0, -1),   
                    float2(-1, 0),   
                };
                
                for (int j = 0; j < 4; j++)
                {
                    finalColor += tex2D(_MainTex, uv + offsets[j] * _BlurRadius);
                }

                return finalColor;
            }

            fixed4 addBrightness(fixed4 finalColor, float brightnessAmount)
            {
                return finalColor * brightnessAmount;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                fixed4 finalColor = tex2D(_MainTex, uv);


                if(_BrightnessActive)
                {
                   finalColor += addBrightness(finalColor, _BrightnessAmount);
                }
                
                if(_BlurActive)
                {
                    if(_Optimized)
                    {
                        finalColor += optimizedBlurShader(finalColor, uv);
                    }
                    else
                    {
                        finalColor += nonOptimizedBlurShader(finalColor, uv);
                    }    
                }

                
                
                return finalColor * _BlendFactor;
            }

            ENDCG
        }
    }
}
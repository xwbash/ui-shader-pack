Shader "Unlit/MainShader"
{
    Properties
    {
        [Header(Main)]
        [Space(5)]
        _TintColor ("Main Color", Color) = (1,1,1,1)
        _TintIntensity ("Tint Intensity", Range(0, 1)) = 0.5
        
        [Space(10)]
        [Header(Masking)]
        [Space(5)]
        [MaterialToggle] _MaskingActive ("MaskingActive", Float) = 0
        [MaterialToggle] _InverseMasking ("InverseMasking", Float) = 0
        _MaskingTiling ("MaskingTiling", Vector) = (1, 1, 0, 0)
        _MaskTexture ("Texture", 2D) = "white" {}
        
        [Space(10)]
        [Header(Shine Breathing Effect)]
        [Space(5)]
        [MaterialToggle] _ShineEffectActive ("Shine Breathing Effect Active", Float) = 0
        _ShineMinValue ("Shine Min Value", Range(0, 1)) = 0.25 
        _ShineSpeed ("Shine Breathing Speed", Range(0, 1)) = 0.25 
        _ShineBrightness ("Shine Breathing Brightness", Range(0, 1)) = 0.25
        
        [Space(10)]
        [Header(Blur)]
        [Space(5)]
        _MainTex ("Texture", 2D) = "white" {}
        [MaterialToggle] _BlurActive ("Blur Active", Float) = 0
        [MaterialToggle] _Optimized ("Optimized", Float) = 0
        _BlendFactor ("Blend Factor", Range(0, 1)) = 0.25 
        _BlurRadius ("Blend Radius", Range(0, 1)) = 0.25 
        _BlurStep ("Blur Step", Float) = 4 

        [Space(0)]
        [Header(Brightness)]
        [Space(5)]
        [MaterialToggle] _BrightnessActive ("Brightness Active", Float) = 0
        _BrightnessAmount ("Brightness Amount", Float) = 0.25 
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

            // Main Data
            float _TintIntensity;
            float4 _TintColor;
            
            // Main Texture
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Masking
            float _MaskingActive;
            float _InverseMasking;
            float2 _MaskingTiling;
            sampler2D _MaskTexture;

            // Shine Effect
            float _ShineEffectActive;
            float _ShineMinValue;
            float _ShineSpeed;
            float _ShineBrightness;

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
                finalColor = lerp(finalColor, finalColor * _TintColor, _TintIntensity);


                if(_ShineEffectActive)
                {
                    finalColor += max(_ShineMinValue, sin(_Time.y * _ShineSpeed) * _ShineBrightness);
                }

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

                 if(_MaskingActive)
                {
                    if(_InverseMasking)
                    {
                        finalColor *= 1 - tex2D(_MaskTexture, uv * _MaskingTiling);
                    }
                    else
                    {
                        finalColor *= tex2D(_MaskTexture, uv * _MaskingTiling);
                    }
                }

                return finalColor * _BlendFactor;
            }

            ENDCG
        }
    }
}

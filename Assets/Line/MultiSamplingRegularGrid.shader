﻿Shader "Line/MultiSamplingRegularGrid"
{
    Properties
    {
        _Color("Color", Color) = (0, 0, 0, 1)
        _Width("Width", Float) = 0.25
        _StepCount("StepCount", Float) = 3
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent+0"
        }

        Pass
        {
            Blend One OneMinusSrcAlpha
            Cull Off
            Lighting Off
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            uniform float _Width;
            uniform float4 _Color;
            uniform float _StepCount;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord0;
                return o;
            }

            float SampleValue(float2 texCoords)
            {
                const bool inLine = (texCoords.x >= (0.5 - _Width)) && (texCoords.x <= (0.5 + _Width));
                return inLine ? 1 : 0;
            }

            float2 GetSampleDelta(uint index, int sqrtStepCount)
            {
                uint x = index % sqrtStepCount;
                uint y = index / sqrtStepCount;
                return (-0.5 + float2(x + 0.5, y + 0.5) / sqrtStepCount) * ((sqrtStepCount - 1) / (float)sqrtStepCount);
            }

            float4 frag(v2f IN) : COLOR
            {
                const float2 ddxUV = ddx(IN.uv);
                const float2 ddyUV = ddy(IN.uv);
                const uint stepCount = clamp(_StepCount, 1, 10000);
                const uint sqrtStepCount = ceil(sqrt(stepCount));
                float hits = 0;
                /*
                for (uint x = 0; x < sqrtStepCount; ++x)
                {
                    for (uint y = 0; y < sqrtStepCount; ++y)
                    {
                        const float2 localXY = (-0.5 + float2(x + 0.5, y + 0.5) / sqrtStepCount) * ((sqrtStepCount - 1) / (float)sqrtStepCount);
                        const float2 localDeltaUVxUVy = ddxUV * localXY.x + ddyUV * localXY.y;
                        hits += SampleValue(IN.uv + localDeltaUVxUVy);
                    }
                }
                */
                
                for (uint i = 0; i < stepCount; ++i)
                {
                    const float2 localXY = GetSampleDelta(i, sqrtStepCount);
                    const float2 localDeltaUVxUVy = ddxUV * localXY.x + ddyUV * localXY.y;
                    hits += SampleValue(IN.uv + localDeltaUVxUVy);
                }
                
                const float proportion = hits / stepCount;
                return _Color * proportion;
            }
            ENDCG
        }
    }
}

Shader "Custom/TDCours2"
{
Properties
{
    _Size("Size", Float) = 0.1
    _Number("Number", int) = 1
    _MainTex("Main Tex", 2D) = "white" {}
    _StepCount("StepCount", int) = 6
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
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        #include "Assets/[Tools]/Shaders/Include/Wang_Hash.cginc"
        #include "Assets/[Tools]/Shaders/Include/Halton.cginc"
        #include "Assets/[Tools]/Shaders/Include/Hammersley.cginc"
            
        #define ID_PER_PRIMITIVE 6

        #ifndef PI
        #define PI 3.14159265358979
        #endif

        uniform float _Size;
        uniform texture2D _MainTex;
        uniform SamplerState linear_mirror_sampler;
        uniform SamplerState point_mirror_sampler;
        uniform uint _VertexCount;
        uniform uint _InstanceCount;
        uniform int _Number;
        uniform uint _StepCount;
        uniform float4 _DayTime;

        struct v2f
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        float2 GetCorner(uint index)
        {
        #if 0
            const float2 corners[ID_PER_PRIMITIVE] = { float2(-0.5, -0.5), float2(-0.5, 0.5), float2(0.5, 0.5), float2(0.5, 0.5), float2(0.5, -0.5), float2(-0.5, -0.5) };
            return corners[index % ID_PER_PRIMITIVE];
        #else
            return float2((index >= 2 && index <= 4) ? 0.5 : -0.5, (index >= 1 && index <= 3) ? 0.5 : -0.5);
        #endif
        }

        v2f vert (uint id : SV_VertexID)
        {
            v2f o;
            
            const uint quadIndex = id / ID_PER_PRIMITIVE;
            const uint vertexIndex = id % ID_PER_PRIMITIVE;

            const uint quadCount = _VertexCount / ID_PER_PRIMITIVE;
            const float2 corner = GetCorner(vertexIndex);
            const float3 direction0 = float3(1, 0, 0);
            const float3 direction1 = float3(0, 1, 0);
            const float3 localPos = corner.x * direction0 * _Size +
                                    corner.y * direction1 * _Size +
                                    quadIndex * -direction0;
            const float3 worldPos = mul(unity_ObjectToWorld, float4(localPos, 1)).xyz;

            o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
            float2 localUV = (0.5f + corner);
            localUV.y = 1 - localUV.y;
            uint unite = round(pow(10, quadIndex));

            uint number = _DayTime.x;
            uint digit =  (number / unite) % 10;

            int columnIndex = digit % 4;
            int lineIndex = digit / 4;
            o.uv = (localUV * 0.25) + float2(0.25 * columnIndex, 0.25 * lineIndex);
            o.uv.y = 1 - o.uv.y;

            if (_Number < (int)unite && quadIndex > 0)
            {
                o.vertex *= 0;
            }

            return o;
        }

        float2 GetSampleDeltaHammersley(uint index, uint stepCount)
        {
            return Hammersley2d(index + 1, stepCount) - 0.5f;
        }

        float4 SampleValue(float2 uv)
        {
            float4 tex = _MainTex.Sample(point_mirror_sampler, uv);
            bool inLetter = tex.r > 0.5;
            bool inStroke = tex.r > 0.4;
            //return inLetter ? 1 : (inStroke ? float4(0, 0, 0, 1) : 0);
            //return inLetter ? 1 : tex.x;
            return tex;
        }
            
        float4 frag (v2f IN) : COLOR
        {
            //float4 tex = _MainTex.Sample(linear_mirror_sampler, IN.uv);
            //float4 result = tex.r > 0.5 ? 1 : 0;

            const float2 ddxUV = ddx(IN.uv);
            const float2 ddyUV = ddy(IN.uv);
            const uint stepCount = clamp(_StepCount, 1, 10000);
            const uint sqrtStepCount = ceil(sqrt(stepCount));
            float4 hits = 0;
            for (uint i = 0; i < stepCount; ++i)
            {
                const float2 localXY = GetSampleDeltaHammersley(i, stepCount);
                const float2 localDeltaUVxUVy = ddxUV * localXY.x + ddyUV * localXY.y;
                hits += SampleValue(IN.uv + localDeltaUVxUVy);
            }
            
            const float4 proportion = hits / stepCount;
            float4 result = proportion;

            //result.xyz += 0.2;

            return result;
        }
        ENDCG
    }
}
}

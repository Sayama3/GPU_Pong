Shader "Custom/Cours3"
{
Properties
{
}

SubShader
{
    Tags
    {
        "RenderType" = "Opaque"
        "Queue" = "Geometry+0"
    }

    Pass
    {
        Blend Off
        Cull Off
        Lighting Off
        ZWrite On
        ZTest LEqual

        CGPROGRAM
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        
		#define ID_PER_PRIMITIVE 6
        #include "Assets/[Tools]/Shaders/Include/QuaternionUtils.cginc"
        struct MeshVertex
        {
            float3 pos;
            float3 normal;
            float2 uv;
        };

        uniform StructuredBuffer<MeshVertex> _MeshBuffer;
        uniform uint _MeshBufferSize;

        struct InstancingData
        {
            float3 position;
            uint color;
            float3 Eulers;
        };

        uniform StructuredBuffer<InstancingData> _InstancingBuffer;
        uniform uint _InstancingBufferSize;

        uniform sampler linear_mirror_sampler;

        struct v2f
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : NORMAL;
            float4 color : COLOR;
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
            uint vertexIndex = id % _MeshBufferSize;
            uint instanceIndex = id / _MeshBufferSize;
            float3 vertex = 0;
            float2 uv = 0;
            float3 normal = 0;
            float4 color = 0;
            if (instanceIndex < _InstancingBufferSize)
            {
                InstancingData iData = _InstancingBuffer[instanceIndex];
                float3 eulers = iData.Eulers;
                float4 quat = CreateQuaternion(eulers);
                uint iDataColor = iData.color;
                vertex = MultiplyQuaternion(quat, _MeshBuffer[vertexIndex].pos) + iData.position;
                uv = _MeshBuffer[vertexIndex].uv;
                normal = _MeshBuffer[vertexIndex].normal;
                color = float4(iDataColor & 0xFF, (iDataColor >> 8) & 0xFF
                , (iDataColor >> 16) & 0xFF, (iDataColor >> 24) & 0xFF) * (1 / 255.0f);
            }
            
            o.vertex = UnityObjectToClipPos(float4(vertex, 1));
            o.uv = uv;
            o.normal = normal;
            o.color = color;
            return o;
        }
            
        float4 frag (v2f IN) : COLOR
        {
            return float4(IN.normal * 0.5 + 0.5, 1);
            
        }
        ENDCG
    }
}
}

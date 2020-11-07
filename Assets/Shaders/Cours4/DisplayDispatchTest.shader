Shader "Custom/DisplayDispatchTest"
{
Properties
{
}
SubShader
{
    Tags
    {
        "RenderType" = "Geometry"
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
        // UNITY_SHADER_NO_UPGRADE : disable unity upgrade
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        
		#define ID_PER_PRIMITIVE 6

        struct v2f
        {
            float4 position : POSITION;
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

        texture2D _DispatchTestOutput;
        sampler sampler_mirror_linear;

        v2f vert (uint id : SV_VertexID)
        {
            const uint quadIndex = id / ID_PER_PRIMITIVE;
            const uint vertexIndex = id % ID_PER_PRIMITIVE;

            const float3 direction0 = float3(1, 0, 0);
            const float3 direction1 = float3(0, 1, 0);
			const float3 direction2 = float3(0, 0, 1);

            const float2 corner = GetCorner(vertexIndex);
            const float2 quadSize = 1;
            const float3 localVertexPos = quadSize.x * corner.x * direction0 + 
                                          quadSize.y * corner.y * direction1;
            const float3 quadPos = 0;

            const float3 vertexPos = localVertexPos + quadPos;

            v2f o;
            o.position = mul(UNITY_MATRIX_MVP, float4(vertexPos, 1));
            o.uv = 0.5f + corner;
            return o;
        }
            
        float4 frag (v2f IN) : COLOR
        {
            float4 texColor = _DispatchTestOutput.Sample(sampler_mirror_linear, IN.uv);
            return texColor;
        }
        ENDCG
    }
}
}

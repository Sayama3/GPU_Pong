
Shader "Custom/EpiCycloid"
{
Properties
{
    _QuadSize("QuadSize", Float) = 0.1

    _R("R", Float) = 10
    _r("r0", Float) = 1
    _r1("r1", Float) = 0.5

    _dTheta("d Theta", Float) = 0.05
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

        #include "Assets/[Tools]/Shaders/Include/HSVUtils.cginc"
        
		#define ID_PER_PRIMITIVE 6
        #define PI 3.141592

        uniform float _QuadSize;
        uniform float _R;
        uniform float _r;
        uniform float _r1;
        uniform float _dTheta;

        struct v2f
        {
            float4 position : POSITION;
            float2 uv : TEXCOORD0;
            float3 color : COLOR;
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
            const uint quadIndex = id / ID_PER_PRIMITIVE;
            const uint vertexIndex = id % ID_PER_PRIMITIVE;

            const float3 direction0 = float3(1, 0, 0);
            const float3 direction1 = float3(0, 1, 0);
			const float3 direction2 = float3(0, 0, 1);

            const float2 corner = GetCorner(vertexIndex);
            const float2 quadSize = _QuadSize;
            const float3 localVertexPos = quadSize.x * corner.x * direction0 + 
                                          quadSize.y * corner.y * direction1;

            const float theta = quadIndex * _dTheta;
            const float theta2 = (_R / _r) * theta;
            float2 cosSinTheta;
            sincos(theta, cosSinTheta.y, cosSinTheta.x);
            float2 cosSinTheta2;
            sincos(theta2, cosSinTheta2.y, cosSinTheta2.x);
            
            const float2 quadPos2d = (_R - _r) * cosSinTheta + _r1  *cosSinTheta2;
            const float angleIn01 = atan2(quadPos2d.y, quadPos2d.x) / (2 * PI);
            const float3 color = hsv2rgb(float3(angleIn01, 1, 1));

            const float3 quadPos = quadPos2d.x * direction0 + quadPos2d.y * direction1;
            const float3 vertexPos = localVertexPos + quadPos;

            v2f o;
            o.position = mul(UNITY_MATRIX_MVP,float4(vertexPos, 1));
            o.uv = 0.5f + corner;
            o.color = color;
            return o;
        }
            
        float4 frag (v2f IN) : COLOR
        {
            return float4(IN.color, 1);
        }
        ENDCG
    }
}
}

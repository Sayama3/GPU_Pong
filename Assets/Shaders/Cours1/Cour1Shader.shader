
Shader "Custom/Cours1"
{
Properties
{
    _GridTex("Grid", 2D) = "white" {}
    _Range("Range", Float) = 1
    [Enum(sincD,0, sincxy,1, snoise,2)] _Method ("Function ", Float) = 0.0
    [Enum(texture,0, color,1, normal,2, mix,3)] _ColorMethod ("Color ", Float) = 1.0
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
        ZWrite On
        ZTest LEqual

        CGPROGRAM
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        
		#define ID_PER_PRIMITIVE 6
        #include "Assets/[Tools]/Shaders/include/hsvutils.cginc"
        #include "Assets/[Tools]/Shaders/include/snoise.cginc"

        uniform Texture2D _GridTex;
        uniform SamplerState linear_mirror_sampler;
        uniform float _Range;
        uniform int _Method;
        uniform int _ColorMethod;

        struct v2f
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : NORMAL;
            float3 albedo : ALBEDO;
        };

        float FunctionToPlot(float2 coords)
        {
            if (_Method == 0)
            {
                return sin(length(coords)) / length(coords);
            }

            if (_Method == 1)
            {
                float2 sincxy = sin(coords) / coords;
                return sincxy.x * sincxy.y;
            }

            if (_Method == 2)
            {
                return snoise(coords * 0.1);
            }

            return 0;
        }

        uniform uint _VertexCount;
        uniform uint _InstanceCount;

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
            const uint columnCount = sqrt(_InstanceCount);
            const uint quadColumn = quadIndex % columnCount;
            const uint quadLine = quadIndex / columnCount;
            const float scale = 1.0f / columnCount;

            const float2 corner = GetCorner(vertexIndex);
            const float3 direction0 = float3(1, 0, 0);
            const float3 direction1 = float3(0, 1, 0);
			const float3 direction2 = float3(0, 0, 1);
            const float3 quadCenter = quadColumn * direction0 +
                                      quadLine * direction2;
            const float3 localVertex = corner.x * direction0 +
                                       corner.y * direction2;

            float3 vertex = scale * (localVertex + quadCenter);
            float2 offset = -_Range * 0.5;
            float2 absissa = _Range * vertex.xz + offset;
            vertex.y = FunctionToPlot(absissa);
            float epsilon = 0.001f;
            float valueXPlus = FunctionToPlot(absissa + float2(epsilon, 0));
            float valueXMinus = FunctionToPlot(absissa + float2(-epsilon, 0));
            float valueYPlus = FunctionToPlot(absissa + float2(0, epsilon));
            float valueYMinus = FunctionToPlot(absissa + float2(0, -epsilon));
            float dfdx = (valueXPlus - valueXMinus) / (2 * epsilon);
            float dfdy = (valueYPlus - valueYMinus) / (2 * epsilon);
            float3 normal = normalize(float3(- dfdx, 1, -dfdy));

            o.vertex = UnityObjectToClipPos(float4(vertex, 1));
            o.uv = 0.5f + corner;
            o.normal = normal;
            o.albedo = hsv2rgb(float3(vertex.y, 1, 0.5));
            return o;
        }
            
        float4 frag (v2f IN) : COLOR
        {
            float4 tex = _GridTex.Sample(linear_mirror_sampler, IN.uv);
            float4 normal = float4(IN.normal.xzy * 0.5 + 0.5, 1);
            float4 albedo = float4(IN.albedo, 1);

            float4 mix = float4(IN.albedo * 0.7 + (IN.normal.xzy * 0.5 + 0.5) * 0.5, 1);
            switch (_ColorMethod)            
            {
            case 0 : return tex;
            case 1 : return albedo;
            case 2 : return normal;
            case 3 : return mix;
            }

            return 0;
        }
        ENDCG
    }
}
}

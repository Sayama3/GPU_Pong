Shader "Custom/MinimalShader"
{
    Properties
    {
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
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            struct appdata
            {
                float4 vertex : POSITION;
				float2 uv : TEXCOORD;
            };
            struct v2f
            {
                float4 vertex : POSITION;
				float2 uv : TEXCOORD;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = 2 * v.uv;
                return o;
            } 
            float4 frag (v2f IN) : COLOR
            { 
                return float4(IN.uv.x, IN.uv.y, 0, 1);
            }
            ENDCG
        }
    }
}

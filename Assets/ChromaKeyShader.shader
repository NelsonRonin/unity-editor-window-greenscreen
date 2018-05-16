Shader "Unlit/ChromaKeyShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_tolerance ("Tolerance", Range (0.0,50.0)) = 0.4
		_mainColor ("Color for Chroma Key", Color) = (0, 1, 0, 1)
	}
	SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _mainColor;
            float _tolerance;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				float maxTarget = 1 - _tolerance;

				// Red screen
				if (_mainColor.r > _mainColor.g && _mainColor.r > _mainColor.b) {
					if (col.r >= maxTarget && col.g <= maxTarget - 0.1 && col.b <= maxTarget - 0.1) {
						col.a = 0.0;
					}

				// Green screen
				} else if (_mainColor.g > _mainColor.r && _mainColor.g > _mainColor.b) {
					if (col.g >= maxTarget && col.r <= maxTarget - 0.1 && col.b <= maxTarget - 0.1) {
						col.a = 0.0;
					}
					
				// Blue screen
				} else if (_mainColor.b > _mainColor.g && _mainColor.b > _mainColor.r) {
					if (col.b >= maxTarget && col.r <= maxTarget - 0.1 && col.g <= maxTarget - 0.1) {
						col.a = 0.0;
					}
				}
                
				return col;
            }
            ENDCG
        }
    }
}

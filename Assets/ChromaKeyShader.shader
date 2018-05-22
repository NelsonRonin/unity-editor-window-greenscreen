Shader "Unlit/ChromaKeyShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_mainColor ("Color for Chroma Key", Color) = (0, 1, 0, 1)
		_tolerance ("Tolerance", Range (0.0,1.0)) = 0.4
        _lightness ("Lightness", Range (0.0,1.0)) = 0.02
	}
	SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            // Start of CG programm (vertex and fragment shader)
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // input data of camera image
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            // output data for camera view
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // Shader properties
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _mainColor;
            float _tolerance;
            float _lightness;
            
            // Transform camera view vertex
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            //----------------------------------------------------------------------------------------
            // Convertion helpers (RGB <-> colorHSL , RGB <-> HSV)
            //----------------------------------------------------------------------------------------
            // Converting RGB to hue/chroma/value
            float Epsilon = 1e-10;

            // Converting RGB to HCV
            float3 RGBtoHCV(in float3 RGB) {
                // Based on work by Sam Hocevar and Emil Persson
                float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
                float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
                float C = Q.x - min(Q.w, Q.y);
                float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
                return float3(H, C, Q.x);
            }

            // Converting RGB to HSL
            float3 RGBtoHSL(in float3 RGB) {
                float3 HCV = RGBtoHCV(RGB);
                float L = HCV.z - HCV.y * 0.5;
                float S = HCV.y / (1 - abs(L * 2 - 1) + Epsilon);
                return float3(HCV.x, S, L);
            }
            
            // Transform camera view fragment (pixel rgb)
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 colors = tex2D(_MainTex, i.uv);

                //----------------------------------------------------------------------------------------
                // Color tolerance setting
                //----------------------------------------------------------------------------------------
				float maxTargetColor = 1 - _tolerance;

				// Red screen
				if (_mainColor.r > _mainColor.g && _mainColor.r > _mainColor.b) {
					if (colors.r >= maxTargetColor && colors.g <= maxTargetColor - 0.1 && colors.b <= maxTargetColor - 0.1) {
						colors.a = 0.0;
					}

				// Green screen
				} else if (_mainColor.g > _mainColor.r && _mainColor.g > _mainColor.b) {
					if (colors.g >= maxTargetColor && colors.r <= maxTargetColor - 0.1 && colors.b <= maxTargetColor - 0.1) {
						colors.a = 0.0;
					}
					
				// Blue screen
				} else if (_mainColor.b > _mainColor.g && _mainColor.b > _mainColor.r) {
					if (colors.b >= maxTargetColor && colors.r <= maxTargetColor - 0.1 && colors.g <= maxTargetColor - 0.1) {
						colors.a = 0.0;
					}
				}

                //----------------------------------------------------------------------------------------
                // Color lightness setting (colorHSL)
                //----------------------------------------------------------------------------------------
                float3 colorHSL     = RGBtoHSL(float3(colors.r, colors.g, colors.b));
                float3 mainColorHSL = RGBtoHSL(float3(_mainColor.r, _mainColor.g, _mainColor.b));
                float minTargetHue  = mainColorHSL.x - _lightness <= 0.0 ? 0.0 : mainColorHSL.x - _lightness;
                float maxTargetHue  = mainColorHSL.x + _lightness >= 1.0 ? 1.0 : mainColorHSL.x + _lightness;
                
                // Check if color lightness is inside tolerated lightness
                if (colorHSL.x >= minTargetHue && colorHSL.x <= maxTargetHue) {
                    colors.a = 0.0;
                }

				return colors;
            }

            ENDCG
        }
    }
}

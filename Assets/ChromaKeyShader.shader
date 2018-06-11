Shader "Unlit/ChromaKeyShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_mainColor ("Color for Chroma Key", Color) = (0, 1, 0, 1)
		_tolerance ("Tolerance", Range (0.0,360.0)) = 20.0
        _lightness ("Lightness", Range (0.0,1.0)) = 0.2
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
            // Convertion helpers (RGB -> HSL)
            //----------------------------------------------------------------------------------------

            // Calculate Hue by RGB, RGB max and min max difference
            float getHue(in float maxRGB, in float3 RGB, in float minMaxDiff) {
                float H = 0.0;

                // Calculate Hue value depending on which value of RGB is max
                if (maxRGB == RGB.r) {
                    H = (RGB.g - RGB.b) / minMaxDiff;

                } else if (maxRGB == RGB.g) {
                    H = 2.0 + (RGB.b - RGB.r) / minMaxDiff;

                } else if (maxRGB == RGB.b) {
                    H = 4.0 + (RGB.r - RGB.g) / minMaxDiff;
                }

                // Multiply Hue with 60 to convert value to degrees of color circle
                H = H * 60;

                // If Hue got negativ: add 360 to enter the color circle of 360 degrees
                return H < 0 ? H + 360 : H;
            }

            // Calculate Saturation by min and max difference and sum 
            float getSaturation(in float L, in float diff, in float sum) {
                // Check Lightness value/level and set Saturation in each case
                if (L > 0.5) {
                    return diff / sum;
                } else {
                    return diff / (2.0 - diff);
                }
            }

            // Get HSL from RGB (H = [0, 360], S = [0, 1], L = [0, 1])
            float3 RGBtoHSL(in float3 RGB) {
                float H = 0.0;
                float S = 0.0;
                float L = 0.0;

                // Get min and max value of RGB
                float maxRGB = max(RGB.r, RGB.g);
                float minRGB = min(RGB.r, RGB.g);
                maxRGB = max(maxRGB, RGB.b);
                minRGB = min(minRGB, RGB.b);

                // Get difference and sum of min and max
                float minMaxDiff = maxRGB - minRGB;
                float minMaxSum = maxRGB + minRGB;

                // Calculate Lightness value
                L = minMaxSum / 2;

                // If min and max are equal: Hue and Saturation are zero
                if (maxRGB == minRGB) {
                    H = S = 0;
                } else {
                    // Calculate Saturation value
                    S = getSaturation(L, minMaxDiff, minMaxSum);

                    // Calculate Hue value
                    H = getHue(maxRGB, float3(RGB.r, RGB.g, RGB.b), minMaxDiff);
                }
                
                return float3(H, S, L);
            }
            
            // Transform camera view fragment (pixel rgb)
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 colors = tex2D(_MainTex, i.uv);

                // Get colors in HSL format
				float3 colorHSL = RGBtoHSL(float3(colors.r, colors.g, colors.b));
				float3 mainColorHSL = RGBtoHSL(float3(_mainColor.r, _mainColor.g, _mainColor.b));

				// Get min and max values for HUE tolerance
				float minTargetHue = mainColorHSL.x - _tolerance <= 0.0 ? 0.0 : mainColorHSL.x - _tolerance;
				float maxTargetHue = mainColorHSL.x + _tolerance >= 360.0 ? 360.0 : mainColorHSL.x + _tolerance;

				// Get min and max values for lightness tolerance
				float minTargetLightness = mainColorHSL.z - _lightness <= 0.0 ? 0.0 : mainColorHSL.z - _lightness;
				float maxTargetLightness = mainColorHSL.z + _lightness >= 1.0 ? 1.0 : mainColorHSL.z + _lightness;

				// Check if color HUE is inside tolerated value
				if (colorHSL.x >= minTargetHue && colorHSL.x <= maxTargetHue) {
					// Check if color lightness is inside tolerated value
					if (colorHSL.z >= minTargetLightness && colorHSL.z <= maxTargetLightness) {
						colors.a = 0.0;
					}
				}

				return colors;
            }

            ENDCG
        }
    }
}

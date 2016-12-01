// Adapted from ImageEffects/Tonemapping, simplified to User Curve for mobile
Shader "Custom/MobileTonemapper" {
	Properties{
		_MainTex("", 2D) = "black" {}
	_Curve("", 2D) = "black" {}
	}

		CGINCLUDE

#include "UnityCG.cginc"

	struct v2f {
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
	};

	sampler2D _MainTex;
	sampler2D _Curve;

	float _RangeScale;

	v2f vert(appdata_img v)
	{
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.texcoord.xy;
		return o;
	}

		float3 ToCIE(float3 FullScreenImage)
	{
		// RGB -> XYZ conversion 
		// http://www.w3.org/Graphics/Color/sRGB 
		// The official sRGB to XYZ conversion matrix is (following ITU-R BT.709)
		// 0.4125 0.3576 0.1805
		// 0.2126 0.7152 0.0722 
		// 0.0193 0.1192 0.9505 

		float3x3 RGB2XYZ = { 0.5141364, 0.3238786, 0.16036376, 0.265068, 0.67023428, 0.06409157, 0.0241188, 0.1228178, 0.84442666 };
		float3 XYZ = mul(RGB2XYZ, FullScreenImage.rgb);
		float3 Yxy;
		Yxy.r = XYZ.g;
		float temp = dot(float3(1.0, 1.0, 1.0), XYZ.rgb);
		Yxy.gb = XYZ.rg / temp;
		return Yxy;
	}

	float3 FromCIE(float3 Yxy)
	{
		float3 XYZ;
		XYZ.r = Yxy.r * Yxy.g / Yxy.b;
		XYZ.g = Yxy.r;
		XYZ.b = Yxy.r * (1 - Yxy.g - Yxy.b) / Yxy.b;
		float3x3 XYZ2RGB = { 2.5651,-1.1665,-0.3986, -1.0217, 1.9777, 0.0439, 0.0753, -0.2543, 1.1892 };
		return mul(XYZ2RGB, XYZ);
	}

		float4 frag(v2f i) : COLOR
	{
		float4 color = tex2D(_MainTex, i.uv);
		float3 cie = ToCIE(color.rgb);

		// Remap to new lum range
		float newLum = tex2D(_Curve, float2(cie.r * _RangeScale, 0.5)).r;
		cie.r = newLum;
		color.rgb = FromCIE(cie);

		return color;
	}

		ENDCG

		Subshader {
			Pass{
			ZTest Always Cull Off ZWrite Off
			Fog{ Mode off }

			CGPROGRAM
#pragma fragmentoption ARB_precision_hint_fastest 
#pragma vertex vert
#pragma fragment frag
			ENDCG
		}
	}

	Fallback off

}
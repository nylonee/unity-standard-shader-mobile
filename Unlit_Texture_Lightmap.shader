Shader "Custom/Unlit Texture (Supports Lightmap)" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Float) = 0.1
		_Contrast ("Contrast", Float) = 1
		_Color ("Color", Color) = (1,1,1,1)
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	#pragma multi_compile_fog

	// Define to modify texture and apply brightness, contrast and color
	#define TEXMOD color_overlay(brightness_contrast(tex2D(_MainTex, i.uv_main)))

	struct appdata
	{
		float4 vertex : POSITION;
		float2 texcoord : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
	};

	struct v2f_lm
	{
		float4 vertex : SV_POSITION;
		half2 uv_lightmap : TEXCOORD0;
		half2 uv_main : TEXCOORD1;
		UNITY_FOG_COORDS(2)
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		half2 uv_main : TEXCOORD0;
		UNITY_FOG_COORDS(1)
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	half _Brightness;
	half _Contrast;
	half4 _Color;

	v2f vert(appdata i)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, i.vertex);
		o.uv_main = TRANSFORM_TEX(i.texcoord, _MainTex);
		UNITY_TRANSFER_FOG(o, o.vertex);
		return o;
	}

	half4 brightness_contrast(half4 main_color)
	{
		// Brightness and contrast. Uses _Contrast and _Brightness
		main_color.rgb /= main_color.a;
		main_color.rgb = ((main_color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;
		main_color.rgb += _Brightness;
		main_color.rgb *= main_color.a;
		return main_color;
	}

	half4 color_overlay(half4 main_color)
	{
		// Painter's algorithm for color overlay, uses _Color
		main_color.rgb = ((main_color.rgb * main_color.a) + (_Color.rgb * _Color.a) * (1 - main_color.a)) / (main_color.a + _Color.a * (1 - main_color.a));
		return main_color;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		half4 main_color = TEXMOD;
		// Apply fog
		UNITY_APPLY_FOG(i.fogCoord, main_color);
		return main_color;
	}

	v2f_lm vert_lm(appdata i)
	{
		v2f_lm o;
		o.vertex = mul(UNITY_MATRIX_MVP, i.vertex);
		o.uv_main = TRANSFORM_TEX(i.texcoord, _MainTex);
		o.uv_lightmap = i.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		UNITY_TRANSFER_FOG(o, o.vertex);
		return o;
	}

	fixed4 frag_lm (v2f_lm i) : SV_Target
	{
		half4 main_color = TEXMOD;
		main_color.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_lightmap));
		// Apply fog
		UNITY_APPLY_FOG(i.fogCoord, main_color);
		return main_color;
	}

	ENDCG

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass {
			Tags { "LightMode" = "VertexLM" }
			// Disable lighting, we're only using the lightmap
			Lighting Off

			CGPROGRAM
			#pragma vertex vert_lm
			#pragma fragment frag_lm
			ENDCG
		}

		Pass {
			Tags{ "LightMode" = "VertexLMRGBM" }
			// Disable lighting, we're only using the lightmap
			Lighting Off

			CGPROGRAM
			#pragma vertex vert_lm
			#pragma fragment frag_lm
			ENDCG
		}

		Pass{
			Tags{ "LightMode" = "Vertex" }
			// Disable lighting
			Lighting Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
}

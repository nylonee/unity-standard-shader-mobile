Shader "Custom/Building (Supports Lightmap)" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
	_Brightness("Brightness", Float) = 0.1
		_Contrast("Contrast", Float) = 1
		_Color("Color", Color) = (1,1,1,1)
		_AlternateTex("Secondary Texture", 2D) = "white" {}
		_AlternateStrength("Strength of secondary texture", Float) = 0
	}

		SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

		Pass{
		Tags{ "LightMode" = "VertexLM" }

		// Disable lighting, we're only using the lightmap
		Lighting Off

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
		// Make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		float2 texcoord : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		half2 uv_lightmap : TEXCOORD0;
		half2 uv_main : TEXCOORD1;
		UNITY_FOG_COORDS(2)
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	half _Brightness;
	half _Contrast;
	half4 _Color;

	sampler2D _AlternateTex;
	half _AlternateStrength;

	v2f vert(appdata i)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, i.vertex);
		o.uv_main = TRANSFORM_TEX(i.texcoord, _MainTex);
		o.uv_lightmap = i.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		UNITY_TRANSFER_FOG(o, o.vertex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		half4 main_color = tex2D(_MainTex, i.uv_main) + _AlternateStrength * tex2D(_AlternateTex, i.uv_main);

		main_color.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_lightmap));

		// Brightness and contrast. If slow, comment out these lines
		main_color.rgb /= main_color.a;
		main_color.rgb = ((main_color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;
		main_color.rgb += _Brightness;
		main_color.rgb *= main_color.a;

		// Painter's algorithm for color overlay. If slow, comment this out
		main_color.rgb = ((main_color.rgb * main_color.a) + (_Color.rgb * _Color.a) * (1 - main_color.a)) / (main_color.a + _Color.a * (1 - main_color.a));

		// Apply fog
		UNITY_APPLY_FOG(i.fogCoord, main_color);

		return main_color;
	}

		ENDCG

	}
		Pass{
		Tags{ "LightMode" = "VertexLMRGBM" }

		// Disable lighting, we're only using the lightmap
		Lighting Off

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
		// Make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		float2 texcoord : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		half2 uv_lightmap : TEXCOORD0;
		half2 uv_main : TEXCOORD1;
		UNITY_FOG_COORDS(2)
	};

	sampler2D _MainTex;
	half4 _MainTex_ST;

	half _Brightness;
	half _Contrast;
	half4 _Color;

	sampler2D _AlternateTex;
	half _AlternateStrength;

	v2f vert(appdata i)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, i.vertex);
		o.uv_main = TRANSFORM_TEX(i.texcoord, _MainTex);
		o.uv_lightmap = i.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		UNITY_TRANSFER_FOG(o, o.vertex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		half4 main_color = tex2D(_MainTex, i.uv_main) + _AlternateStrength * tex2D(_AlternateTex, i.uv_main);

		main_color.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_lightmap));

		// Brightness and contrast. If slow, comment out these lines
		main_color.rgb /= main_color.a;
		main_color.rgb = ((main_color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;
		main_color.rgb += _Brightness;
		main_color.rgb *= main_color.a;

		// Painter's algorithm for color overlay. If slow, comment this out
		main_color.rgb = ((main_color.rgb * main_color.a) + (_Color.rgb * _Color.a) * (1 - main_color.a)) / (main_color.a + _Color.a * (1 - main_color.a));

		// Apply fog
		UNITY_APPLY_FOG(i.fogCoord, main_color);

		return main_color;
	}

		ENDCG

	}

		Pass{
		Tags{ "LightMode" = "Vertex" }

		// Disable lighting
		Lighting Off

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
		// Make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		float2 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		UNITY_FOG_COORDS(1)
			half2 uv_main : TEXCOORD0;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	half _Brightness;
	half _Contrast;
	half4 _Color;

	sampler2D _AlternateTex;
	half _AlternateStrength;

	v2f vert(appdata i)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, i.vertex);
		o.uv_main = TRANSFORM_TEX(i.texcoord, _MainTex);
		UNITY_TRANSFER_FOG(o, o.vertex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		half4 main_color = tex2D(_MainTex, i.uv_main) + _AlternateStrength * tex2D(_AlternateTex, i.uv_main);

		// Brightness and contrast. If slow, comment out these lines
		main_color.rgb /= main_color.a;
		main_color.rgb = ((main_color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;
		main_color.rgb += _Brightness;
		main_color.rgb *= main_color.a;

		// Painter's algorithm for color overlay. If slow, comment this out
		main_color.rgb = ((main_color.rgb * main_color.a) + (_Color.rgb * _Color.a) * (1 - main_color.a)) / (main_color.a + _Color.a * (1 - main_color.a));

		// Apply fog
		UNITY_APPLY_FOG(i.fogCoord, main_color);

		return main_color;
	}

		ENDCG

	}

	}
}




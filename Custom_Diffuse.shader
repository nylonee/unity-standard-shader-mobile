// Simplified Diffuse shader
// - no Main Color
// - only supports one directional light (all others are per-vertex computed)
// - has bumpmapping
// - allows emission

Shader "Custom/MobileDiffuse" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BumpMap("Bumpmap", 2D) = "bump" {}
		_BumpMapIntensity("Bumpmap Intensity", Range(0.0, 1.0)) = 0.0
		_Emission("Emission", 2D) = "emission" {}
		_EmissionIntensity("Emission Intensity", Range(0.0, 2.0)) = 0.0
	}
		SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 150

		CGPROGRAM
#pragma surface surf Lambert nodynlightmap

		sampler2D _MainTex;
	sampler2D _BumpMap;
	sampler2D _Emission;

	half _BumpMapIntensity;
	half _EmissionIntensity;

	struct Input {
		float2 uv_MainTex;
		float2 uv_BumpMap;
		float2 uv_Emission;
	};

	void surf(Input IN, inout SurfaceOutput o) {

		o.Albedo = tex2D(_MainTex, IN.uv_MainTex);
		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)) * _BumpMapIntensity;
		o.Emission = tex2D(_Emission, IN.uv_Emission) * _EmissionIntensity;
	}
	ENDCG
	}

	Fallback "Mobile/VertexLit"
}

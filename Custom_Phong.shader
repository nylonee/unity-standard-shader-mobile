// Simplified Phong shader

Shader "Custom/MobilePhong" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Range(-10.0, 10.0)) = 0.0
		_Contrast ("Contrast", Range(0.0, 3.0)) = 1
    _Color("Color tint", Color) = (0, 0, 0, 0)
    _PointLightColor("Point Light Color", Color) = (0, 0, 0, 0)
    _PointLightPosition("Point Light Position", Vector) = (0.0, 0.0, 0.0)
    _AmbiencePower("Ambience intensity", Range(0.0, 2.0)) = 1.0
    _SpecularPower("Specular intensity", Range(0.0, 2.0)) = 1.0
    _DiffusePower("Diffuse intensity", Range(0.0, 2.0)) = 1.0
    _EmissionMap ("Emission", 2D) = "white" {}
    _EmissionStrength ("Emission Strength", Range(0.0, 10.0)) = 1
	}

  CGINCLUDE
  #include "UnityCG.cginc"
  #pragma multi_compile_fog

	sampler2D _MainTex;
	float4 _MainTex_ST;

  uniform float4 _PointLightColor;
  uniform float3 _PointLightPosition;

  float _AmbiencePower;
  float _SpecularPower;
  float _DiffusePower;

  float _Brightness;
  float _Contrast;
  float4 _Color;

  sampler2D _EmissionMap;
  float _EmissionStrength;

  float4 brightness_contrast(float4 main_color)
  {
    // Brightness and contrast. Uses _Contrast and _Brightness
    main_color.rgb /= main_color.a;
    main_color.rgb = ((main_color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;
    main_color.rgb += _Brightness * 0.05;
    main_color.rgb *= main_color.a;
    return main_color;
  }

  struct appdata
  {
    float4 vertex : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float2 texcoord : TEXCOORD0;
  };

  struct appdata_lm
  {
    float4 vertex : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float2 texcoord : TEXCOORD0;
    float2 lightmapcoord : TEXCOORD1;
  };

  struct v2f
  {
    float4 vertex : SV_POSITION;
    float4 color: COLOR;
    float4 worldVertex : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float2 uv_main : TEXCOORD2;
    UNITY_FOG_COORDS(3)
  };

  struct v2f_lm
  {
    float4 vertex : SV_POSITION;
    float4 color: COLOR;
    float4 worldVertex : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float2 uv_main : TEXCOORD2;
    UNITY_FOG_COORDS(3)
    float2 uv_lightmap : TEXCOORD4;
  };

  v2f vert(appdata v)
  {
    v2f o;

    // Convert Vertex position and corresponding normal into world coords
    // Note that we have to multiply the normal by the transposes inverse of the world
    // transformation matrix (for cases where we have non-uniform scaling, we also don't
    // care about the "fourth" dimension, because translations don't affect the normal)
    float4 worldVertex = mul(unity_ObjectToWorld, v.vertex);
    float3 worldNormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal.xyz));

    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.color = v.color;
    o.worldVertex = worldVertex;
    o.worldNormal = worldNormal;
    o.uv_main = TRANSFORM_TEX(v.texcoord, _MainTex);
    UNITY_TRANSFER_FOG(o, o.vertex);

    return o;
  }

  v2f_lm vert_lm(appdata_lm v)
  {
    v2f_lm o;

    // Convert Vertex position and corresponding normal into world coords
    // Note that we have to multiply the normal by the transposes inverse of the world
    // transformation matrix (for cases where we have non-uniform scaling, we also don't
    // care about the "fourth" dimension, because translations don't affect the normal)
    float4 worldVertex = mul(unity_ObjectToWorld, v.vertex);
    float3 worldNormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal.xyz));

    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.color = v.color;
    o.worldVertex = worldVertex;
    o.worldNormal = worldNormal;
    o.uv_main = TRANSFORM_TEX(v.texcoord, _MainTex);
    // lightmap
    o.uv_lightmap = v.lightmapcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
    UNITY_TRANSFER_FOG(o, o.vertex);

    return o;
  }

  fixed4 frag(v2f v) : SV_Target
  {
    float4 returnColor = brightness_contrast(tex2D(_MainTex, v.uv_main) + tex2D(_EmissionMap, v.uv_main)*(_EmissionStrength/5));

    // Our interpolated normal might not be of length 1
    float3 interpNormal = normalize(v.worldNormal);

    // Calculate ambient RGB intensities
    float Ka = _AmbiencePower;
    float3 amb = v.color.rgb * unity_AmbientSky * Ka;

    // Calculate diffuse RGB reflections, we save the results of L.N because we will use it again
    // (when calculating the reflected ray in our specular component)
    float fAtt = 1;
    float Kd = _DiffusePower;
    float3 L = normalize(_PointLightPosition - v.worldVertex.xyz);
    float LdotN = dot(L, interpNormal);
    float3 dif = fAtt * _PointLightColor.rgb * Kd * returnColor.rgb * saturate(LdotN);

    // Calculate specular reflections
    float Ks = _SpecularPower;
    float specN = 25; // Values >> 1 give tighter highlights
    float3 V = normalize(_WorldSpaceCameraPos - v.worldVertex.xyz);
    // Using Blinn-Phong approximation:
    float3 H = normalize(V+L);
    float3 spe = fAtt * _PointLightColor.rgb * Ks * pow(saturate(dot(interpNormal, H)), specN);

    // Combine Phong illumination model components
    returnColor.rgb = lerp(returnColor.rgb, amb.rgb + dif.rgb + spe.rgb, _PointLightColor.a);
    returnColor.rgb = lerp(returnColor.rgb, _Color.rgb, _Color.a);
    UNITY_APPLY_FOG(v.fogCoord, returnColor);

    return returnColor;
  }

  fixed4 frag_lm(v2f_lm v) : SV_Target
  {
    float4 returnColor = brightness_contrast(tex2D(_MainTex, v.uv_main) + tex2D(_EmissionMap, v.uv_main)*(_EmissionStrength/5));

    // Our interpolated normal might not be of length 1
    float3 interpNormal = normalize(v.worldNormal);

    // Calculate ambient RGB intensities
    float Ka = _AmbiencePower;
    float3 amb = returnColor.rgb * unity_AmbientSky.rgb * Ka;

    // Calculate diffuse RGB reflections, we save the results of L.N because we will use it again
    // (when calculating the reflected ray in our specular component)
    float fAtt = 1;
    float Kd = _DiffusePower;
    float3 L = normalize(_PointLightPosition - v.worldVertex.xyz);
    float LdotN = dot(L, interpNormal);
    float3 dif = fAtt * _PointLightColor.rgb * Kd * returnColor.rgb * saturate(LdotN);

    // Calculate specular reflections
    float Ks = _SpecularPower;
    float specN = 25; // Values >> 1 give tighter highlights
    float3 V = normalize(_WorldSpaceCameraPos - v.worldVertex.xyz);
    // Using Blinn-Phong approximation:
    float3 H = normalize(V+L);
    float3 spe = fAtt * _PointLightColor.rgb * Ks * pow(saturate(dot(interpNormal, H)), specN);

    returnColor.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, v.uv_lightmap));

    // Combine Phong illumination model components
    returnColor.rgb = lerp(returnColor.rgb, amb.rgb + dif.rgb + spe.rgb, _PointLightColor.a);
    returnColor.rgb = lerp(returnColor.rgb, _Color.rgb, _Color.a);
    UNITY_APPLY_FOG(v.fogCoord, returnColor);

    return returnColor;
  }

	ENDCG


  SubShader {
  	Tags { "RenderType" = "Opaque" }
  	LOD 150

    Pass {
      Tags { "LightMode" = "VertexLM" }
      Lighting Off
  		CGPROGRAM
      #pragma vertex vert_lm
      #pragma fragment frag_lm
      ENDCG
    }

    Pass {
      Tags { "LightMode" = "VertexLMRGBM" }
      Lighting Off
  		CGPROGRAM
      #pragma vertex vert_lm
      #pragma fragment frag_lm
      ENDCG
    }

    Pass {
      Tags { "LightMode" = "Vertex" }
      Lighting Off
  		CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      ENDCG
    }
  }

	Fallback "Mobile/VertexLit"
}
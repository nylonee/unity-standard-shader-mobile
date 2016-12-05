// Standard shader for mobile
// Written by Nihal Mirpuri @nylonee

// NOTE: Does not support shadow casting
// the shorthand '_lm' refers to lightmap
// TODO: _Color.a doesn't work
// TODO: Detail map and detail mask
// TODO: Normal map

Shader "Custom/StandardMobile"
{
  Properties
  {
    //[Enum(Opaque,0,Transparent,1)] _RenderType ("Render type", Float) = 0

    _MainTex("Albedo", 2D) = "white" {}

    _Color("Color", Color) = (1,1,1,1)
    _Brightness ("Brightness", Range(-10.0, 10.0)) = 0.0
    _Contrast ("Contrast", Range(0.0, 3.0)) = 1

    [Toggle(PHONG_ON)] _Phong("Point Light Toggle", Int) = 0
    _PointLightColor("Point Light Color", Color) = (1,1,1,1)
    _PointLightPosition("Point Light Position", Vector) = (0.0,0.0,0.0)
    _AmbiencePower("Ambience intensity", Range(0.0,2.0)) = 1.0
    _SpecularPower("Specular intensity", Range(0.0,2.0)) = 1.0
    _DiffusePower("Diffuse intensity", Range(0.0,2.0)) = 1.0


    [Toggle(EMISSION_ON)] _Emission("Emission Map Toggle", Int) = 0
    _EmissionMap("Emission", 2D) = "white" {}
    _EmissionStrength("Emission Strength", Range(0.0,10.0)) = 1
  }

  CGINCLUDE
  #include "UnityCG.cginc"

  // DEFINES, CONSTRUCTORS AND STRUCTS
  #pragma multi_compile_fog
  #pragma shader_feature PHONG_ON
  #pragma shader_feature EMISSION_ON

  sampler2D _MainTex;
  float4 _MainTex_ST;

  float4 _Color;
  float _Brightness;
  float _Contrast;

  // Phong
  #if PHONG_ON
  uniform float4 _PointLightColor;
  uniform float3 _PointLightPosition;

  float _AmbiencePower;
  float _SpecularPower;
  float _DiffusePower;
  #endif

  #if EMISSION_ON
  sampler2D _EmissionMap;
  float _EmissionStrength;
  #endif

  struct appdata
  {
    float4 vertex : POSITION;
    float2 texcoord : TEXCOORD0;
    #if PHONG_ON
    float4 normal : NORMAL;
    #endif
  };

  struct appdata_lm
  {
    float4 vertex : POSITION;
    float2 texcoord : TEXCOORD0;
    float2 texcoord_lm : TEXCOORD1;
    #if PHONG_ON
    float4 normal : NORMAL;
    #endif
  };

  struct v2f
  {
    float4 vertex : SV_POSITION;
    float2 uv_main : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    #if PHONG_ON
    float4 worldVertex : TEXCOORD2;
    float3 worldNormal : TEXCOORD3;
    #endif
  };

  struct v2f_lm
  {
    float4 vertex : SV_POSITION;
    float2 uv_main : TEXCOORD0;
    float2 uv_lm : TEXCOORD1;
    UNITY_FOG_COORDS(2)
    #if PHONG_ON
    float4 worldVertex : TEXCOORD3;
    float3 worldNormal : TEXCOORD4;
    #endif
  };

  // VERTEX SHADERS

  v2f vert(appdata v)
  {
    v2f o;

    #if PHONG_ON
    o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
    o.worldNormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal.xyz));
    #endif

    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv_main = TRANSFORM_TEX(v.texcoord, _MainTex);
    UNITY_TRANSFER_FOG(o, o.vertex);

    return o;
  }

  v2f_lm vert_lm(appdata_lm v)
  {
    v2f_lm o;

    #if PHONG_ON
    o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
    o.worldNormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal.xyz));
    #endif

    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv_main = TRANSFORM_TEX(v.texcoord, _MainTex);
    o.uv_lm = v.texcoord_lm.xy * unity_LightmapST.xy + unity_LightmapST.zw;
    UNITY_TRANSFER_FOG(o, o.vertex);

    return o;
  }

  // FRAGMENT SHADERS

  // Fix the brightness, contrast and color
  float4 bcc(float4 main_color)
  {
    main_color.rgb /= main_color.a;
    main_color.rgb = ((main_color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;
    main_color.rgb += _Brightness * 0.05;
    main_color.rgb *= main_color.a;
    main_color.rgb = lerp(main_color.rgb, _Color.rgb, _Color.a);

    return main_color;
  }

  fixed4 frag(v2f i) : SV_Target
  {
    float4 returnColor = tex2D(_MainTex, i.uv_main);
    #if EMISSION_ON
    returnColor += tex2D(_EmissionMap, i.uv_main)*_EmissionStrength/5;
    #endif

    #if PHONG_ON
    // interpolated normal may not be 1
    float3 interpNormal = normalize(i.worldNormal);
    // ambient intensities
    float3 amb = returnColor.rgb * unity_AmbientSky * _AmbiencePower;
    // diffuse intensities
    float3 L = normalize(_PointLightPosition - i.worldVertex.xyz);
    float LdotN = dot(L, interpNormal);
    float3 dif = _PointLightColor.rgb * returnColor.rgb * saturate(LdotN) * _DiffusePower;
    // specular intensities
    float3 V = normalize(_WorldSpaceCameraPos - i.worldVertex.xyz);
    float3 H = normalize(V+L);
    float3 spe = _PointLightColor.rgb * pow(saturate(dot(interpNormal, H)), 25) * _SpecularPower;

    returnColor.rgb = lerp(returnColor.rgb, amb.rgb+dif.rgb+spe.rgb, _PointLightColor.a);
    #endif

    UNITY_APPLY_FOG(i.fogCoord, returnColor);

    return bcc(returnColor);
  }

  fixed4 frag_lm(v2f_lm i) : SV_Target
  {
    float4 returnColor = tex2D(_MainTex, i.uv_main);
    #if EMISSION_ON
    returnColor += tex2D(_EmissionMap, i.uv_main)*_EmissionStrength/5;
    #endif
    returnColor.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_lm));

    #if PHONG_ON
    // interpolated normal may not be 1
    float3 interpNormal = normalize(i.worldNormal);
    // ambient intensities
    float3 amb = returnColor.rgb * unity_AmbientSky * _AmbiencePower;
    // diffuse intensities
    float3 L = normalize(_PointLightPosition - i.worldVertex.xyz);
    float LdotN = dot(L, interpNormal);
    float3 dif = _PointLightColor.rgb * returnColor.rgb * saturate(LdotN) * _DiffusePower;
    // specular intensities
    float3 V = normalize(_WorldSpaceCameraPos - i.worldVertex.xyz);
    float3 H = normalize(V+L);
    float3 spe = _PointLightColor.rgb * pow(saturate(dot(interpNormal, H)), 25) * _SpecularPower;

    returnColor.rgb = lerp(returnColor.rgb, amb.rgb+dif.rgb+spe.rgb, _PointLightColor.a);
    #endif

    UNITY_APPLY_FOG(i.fogCoord, returnColor);

    return bcc(returnColor);
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

  FallBack "Mobile/VertexLit"
  //CustomEditor "MobileShaderGUI"
}

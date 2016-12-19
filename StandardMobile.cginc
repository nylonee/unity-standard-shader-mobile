#include "UnityCG.cginc"

// DEFINES, CONSTRUCTORS AND STRUCTS

sampler2D _MainTex;
half4 _MainTex_ST;

#if COLOR_ON
half4 _Color;
half _Brightness;
half _Contrast;
#endif

// Phong
#if PHONG_ON
uniform half4 _PointLightColor;
uniform half3 _PointLightPosition;

half _AmbiencePower;
half _SpecularPower;
half _DiffusePower;
#endif

#if DETAIL_ON
sampler2D _DetailMap;
half _DetailStrength;
#endif

#if DETAIL_ON && DETAIL_MASK_ON
sampler2D _DetailMask;
#endif

#if EMISSION_ON
sampler2D _EmissionMap;
half _EmissionStrength;
#endif

#if NORMAL_ON
sampler2D _NormalMap;
half4 _NormalMap_ST;
#endif

struct appdata
{
  float4 vertex : POSITION;
  half2 texcoord : TEXCOORD0;
  #if PHONG_ON || NORMAL_ON
  float4 normal : NORMAL;
  #endif
};

struct appdata_lm
{
  float4 vertex : POSITION;
  half2 texcoord : TEXCOORD0;
  half2 texcoord_lm : TEXCOORD1;
  #if PHONG_ON || NORMAL_ON
  float4 normal : NORMAL;
  #endif
};

struct v2f
{
  float4 vertex : SV_POSITION;
  half2 uv_main : TEXCOORD0;
  UNITY_FOG_COORDS(1)
  #if PHONG_ON
  float4 worldVertex : TEXCOORD2;
  #endif
  #if PHONG_ON || NORMAL_ON
  float3 worldNormal : TEXCOORD3;
  #endif
};

struct v2f_lm
{
  float4 vertex : SV_POSITION;
  half2 uv_main : TEXCOORD0;
  half2 uv_lm : TEXCOORD1;
  UNITY_FOG_COORDS(2)
  #if PHONG_ON
  float4 worldVertex : TEXCOORD3;
  #endif
  #if PHONG_ON || NORMAL_ON
  float3 worldNormal : TEXCOORD4;
  #endif
};

// VERTEX SHADERS

v2f vert(appdata v)
{
  v2f o;

  #if PHONG_ON
  o.worldVertex = mul(unity_ObjectToWorld, v.vertex);
  #endif
  #if PHONG_ON || NORMAL_ON
  //o.worldNormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal.xyz));
  o.worldNormal = UnityObjectToWorldNormal(v.normal);
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
  #endif
  #if PHONG_ON || NORMAL_ON
  //o.worldNormal = normalize(mul(transpose((float3x3)unity_WorldToObject), v.normal.xyz));
  o.worldNormal = UnityObjectToWorldNormal(v.normal);
  #endif

  o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

  o.uv_main = TRANSFORM_TEX(v.texcoord, _MainTex);
  o.uv_lm = v.texcoord_lm.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  UNITY_TRANSFER_FOG(o, o.vertex);

  return o;
}

// FRAGMENT SHADERS

#if COLOR_ON
// Fix the brightness, contrast and color
half4 bcc(half4 main_color)
{
  main_color.rgb /= main_color.a;
  main_color.rgb = ((main_color.rgb - 0.5f) * max(_Contrast, 0)) + 0.5f;
  main_color.rgb += _Brightness * 0.05;
  main_color.rgb *= main_color.a;

  //main_color.rgb = lerp(main_color.rgb, _Color.rgb, _Color.a);
  main_color *= _Color;

  return main_color;
}
#endif

fixed4 frag(v2f i) : SV_Target
{
  half4 returnColor = tex2D(_MainTex, i.uv_main);

  #if DETAIL_ON
  half4 mask = half4(1, 1, 1, 1);
  #endif
  #if DETAIL_ON && DETAIL_MASK_ON
  mask = tex2D(_DetailMask, i.uv_main);
  #endif
  #if DETAIL_ON
  half4 detailMap = tex2D(_DetailMap, i.uv_main) * mask;
  const fixed3 constantList = fixed3(1.0, 0.5, 0.0);
  returnColor = (returnColor + _DetailStrength*detailMap) * constantList.xxxz + (returnColor + _DetailStrength*detailMap) * constantList.zzzy;
  #endif

  #if EMISSION_ON
  returnColor += tex2D(_EmissionMap, i.uv_main)*_EmissionStrength*0.2;
  #endif

  #if PHONG_ON || NORMAL_ON
  float3 normal;
  float3 localCoords;
  #endif

  #if PHONG_ON
  // interpolated normal may not be 1
  normal = normalize(i.worldNormal);
  localCoords = i.worldVertex.xyz;
  #endif

  #if NORMAL_ON
  localCoords = UnpackNormal(tex2D(_NormalMap, i.uv_main));
  /*normal = normalize(cross(i.worldNormal, tex2D(_NormalMap, _NormalMap_ST.xy * i.uv_main.xy + _NormalMap_ST.zw)));
  localCoords = float3(2.0 * normal.z - 1.0, 2.0 * normal.y - 1.0, 0.0);
  localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords);*/
  #endif

  #if PHONG_ON
  // ambient intensities
  half3 amb = returnColor.rgb * unity_AmbientSky * _AmbiencePower;
  // diffuse intensities
  half3 L = normalize(_PointLightPosition - localCoords);
  half LdotN = dot(L, normal);
  half3 dif = _PointLightColor.rgb * returnColor.rgb * saturate(LdotN) * _DiffusePower;
  // specular intensities
  half3 V = normalize(_WorldSpaceCameraPos - localCoords);
  half3 H = normalize(V+L);
  half3 spe = _PointLightColor.rgb * pow(saturate(dot(normal, H)), 25) * _SpecularPower;

  returnColor.rgb = lerp(returnColor.rgb, amb.rgb+dif.rgb+spe.rgb, _PointLightColor.a);
  #endif

  UNITY_APPLY_FOG(i.fogCoord, returnColor);

  #if COLOR_ON
  returnColor = bcc(returnColor);
  #endif

  return returnColor;
}

fixed4 frag_lm(v2f_lm i) : SV_Target
{
  half4 returnColor = tex2D(_MainTex, i.uv_main);

  #if DETAIL_ON
  half4 mask = half4(1, 1, 1, 1);
  #endif
  #if DETAIL_ON && DETAIL_MASK_ON
  mask = tex2D(_DetailMask, i.uv_main);
  #endif
  #if DETAIL_ON
  half4 detailMap = tex2D(_DetailMap, i.uv_main) * mask;
  const fixed3 constantList = fixed3(1.0, 0.5, 0.0);
  returnColor = (returnColor + _DetailStrength*detailMap) * constantList.xxxz + (returnColor + _DetailStrength*detailMap) * constantList.zzzy;
  #endif

  #if EMISSION_ON
  returnColor += tex2D(_EmissionMap, i.uv_main)*_EmissionStrength/5;
  #endif
  returnColor.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_lm));

  #if PHONG_ON || NORMAL_ON
  float3 normal;
  float3 localCoords;
  #endif

  #if PHONG_ON
  // interpolated normal may not be 1
  normal = normalize(i.worldNormal);
  localCoords = i.worldVertex.xyz;
  #endif

  #if NORMAL_ON
  localCoords = UnpackNormal(tex2D(_NormalMap, i.uv_main));
  /*normal = normalize(cross(i.worldNormal, tex2D(_NormalMap, _NormalMap_ST.xy * i.uv_main.xy + _NormalMap_ST.zw)));
  localCoords = float3(2.0 * normal.z - 1.0, 2.0 * normal.y - 1.0, 0.0);
  localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords);*/
  #endif

  #if PHONG_ON
  // ambient intensities
  half3 amb = returnColor.rgb * unity_AmbientSky * _AmbiencePower;
  // diffuse intensities
  half3 L = normalize(_PointLightPosition - localCoords);
  half LdotN = dot(L, normal);
  half3 dif = _PointLightColor.rgb * returnColor.rgb * saturate(LdotN) * _DiffusePower;
  // specular intensities
  half3 V = normalize(_WorldSpaceCameraPos - localCoords);
  half3 H = normalize(V+L);
  half3 spe = _PointLightColor.rgb * pow(saturate(dot(normal, H)), 25) * _SpecularPower;

  returnColor.rgb = lerp(returnColor.rgb, amb.rgb+dif.rgb+spe.rgb, _PointLightColor.a);
  #endif

  UNITY_APPLY_FOG(i.fogCoord, returnColor);

  #if COLOR_ON
  returnColor = bcc(returnColor);
  #endif

  return returnColor;
}

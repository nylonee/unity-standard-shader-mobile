Shader "Custom/MobileBloomAndTonemapping" {
  Properties {
    _MainTex("Base (RGB)", 2D) = "black" {}
    _Curve("Curve (RGB)", 2D) = "black" {}
    _Bloom("Bloom (RGB)", 2D) = "black" {}
  }

  CGINCLUDE

  #include "UnityCG.cginc"

  sampler2D _MainTex;
  sampler2D _Bloom;
  sampler2D _Curve;

  half _RangeScale;

  uniform half4 _MainTex_TexelSize;

  uniform half4 _Parameter;
  uniform half4 _OffsetsA;
  uniform half4 _OffsetsB;

  #define ONE_MINUS_THRESHHOLD_TIMES_INTENSITY _Parameter.w
  #define THRESHHOLD _Parameter.z

  struct v2f_simple
  {
    float4 pos : SV_POSITION;
    half2 uv : TEXCOORD0;

    #if UNITY_UV_STARTS_AT_TOP
    half2 uv2 : TEXCOORD1;
    #endif
  };

  v2f_simple vertBloom(appdata_img v)
  {
    v2f_simple o;

    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv = v.texcoord;

    #if UNITY_UV_STARTS_AT_TOP
    o.uv2 = v.texcoord;
    if (_MainTex_TexelSize.y < 0.0)
    o.uv.y = 1.0 - o.uv.y;
    #endif

    return o;
  }

  struct v2f_tap
  {
    float4 pos : SV_POSITION;
    half2 uv20 : TEXCOORD0;
    half2 uv21 : TEXCOORD1;
    half2 uv22 : TEXCOORD2;
    half2 uv23 : TEXCOORD3;
  };

  v2f_tap vert4Tap(appdata_img v)
  {
    v2f_tap o;

    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.uv20 = v.texcoord + _MainTex_TexelSize.xy;
    o.uv21 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h, -0.5h);
    o.uv22 = v.texcoord + _MainTex_TexelSize.xy * half2(0.5h, -0.5h);
    o.uv23 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h, 0.5h);

    return o;
  }

  half3 ToCIE(half3 FullScreenImage)
  {
    // RGB -> XYZ conversion
    // http://www.w3.org/Graphics/Color/sRGB
    // The official sRGB to XYZ conversion matrix is (following ITU-R BT.709)
    // 0.4125 0.3576 0.1805
    // 0.2126 0.7152 0.0722
    // 0.0193 0.1192 0.9505

    half3x3 RGB2XYZ = { 0.5141364, 0.3238786, 0.16036376, 0.265068, 0.67023428, 0.06409157, 0.0241188, 0.1228178, 0.84442666 };
    half3 XYZ = mul(RGB2XYZ, FullScreenImage.rgb);
    half3 Yxy;
    Yxy.r = XYZ.g;
    half temp = dot(half3(1.0, 1.0, 1.0), XYZ.rgb);
    Yxy.gb = XYZ.rg / temp;
    return Yxy;
  }

  half3 FromCIE(half3 Yxy)
  {
    half3 XYZ;
    XYZ.r = Yxy.r * Yxy.g / Yxy.b;
    XYZ.g = Yxy.r;
    XYZ.b = Yxy.r * (1 - Yxy.g - Yxy.b) / Yxy.b;
    half3x3 XYZ2RGB = { 2.5651,-1.1665,-0.3986, -1.0217, 1.9777, 0.0439, 0.0753, -0.2543, 1.1892 };
    return mul(XYZ2RGB, XYZ);
  }

  fixed4 fragBloom(v2f_simple i) : SV_Target
  {
    #if UNITY_UV_STARTS_AT_TOP

    fixed4 color = tex2D(_MainTex, i.uv2) + tex2D(_Bloom, i.uv);
    half3 cie = ToCIE(color.rgb);

    // Remap to new Lum range
    half newLum = tex2D(_Curve, half2(cie.r * _RangeScale, 0.5)).r;
    cie.r = newLum;
    color.rgb = FromCIE(cie);

    return color;

    #else

    fixed4 color = tex2D(_MainTex, i.uv) + tex2D(_Bloom, i.uv);
    half3 cie = ToCIE(color.rgb);

    // Remap to new Lum range
    half newLum = tex2D(_Curve, half2(cie.r * _RangeScale, 0.5)).r;
    cie.r = newLum;
    color.rgb = FromCIE(cie);

    return color;

    #endif
  }

  fixed4 fragDownsample(v2f_tap i) : SV_Target
  {
    fixed4 color = tex2D(_MainTex, i.uv20);
    color += tex2D(_MainTex, i.uv21);
    color += tex2D(_MainTex, i.uv22);
    color += tex2D(_MainTex, i.uv23);
    return max(color / 4 - THRESHHOLD, 0) * ONE_MINUS_THRESHHOLD_TIMES_INTENSITY;
  }

  // weight curves

  static const half curve[7] = { 0.0205, 0.0855, 0.232, 0.324, 0.232, 0.0855, 0.0205 };  // gauss'ish blur weights

  static const half4 curve4[7] = { half4(0.0205,0.0205,0.0205,0), half4(0.0855,0.0855,0.0855,0), half4(0.232,0.232,0.232,0),
    half4(0.324,0.324,0.324,1), half4(0.232,0.232,0.232,0), half4(0.0855,0.0855,0.0855,0), half4(0.0205,0.0205,0.0205,0) };

    struct v2f_withBlurCoords8
    {
      float4 pos : SV_POSITION;
      half4 uv : TEXCOORD0;
      half2 offs : TEXCOORD1;
    };

    struct v2f_withBlurCoordsSGX
    {
      float4 pos : SV_POSITION;
      half2 uv : TEXCOORD0;
      half4 offs[3] : TEXCOORD1;
    };

    v2f_withBlurCoords8 vertBlurHorizontal(appdata_img v)
    {
      v2f_withBlurCoords8 o;
      o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

      o.uv = half4(v.texcoord.xy, 1, 1);
      o.offs = _MainTex_TexelSize.xy * half2(1.0, 0.0) * _Parameter.x;

      return o;
    }

    v2f_withBlurCoords8 vertBlurVertical(appdata_img v)
    {
      v2f_withBlurCoords8 o;
      o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

      o.uv = half4(v.texcoord.xy, 1, 1);
      o.offs = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _Parameter.x;

      return o;
    }

    half4 fragBlur8(v2f_withBlurCoords8 i) : SV_Target
    {
      half2 uv = i.uv.xy;
      half2 netFilterWidth = i.offs;
      half2 coords = uv - netFilterWidth * 3.0;

      half4 color = 0;
      for (int l = 0; l < 7; l++)
      {
        half4 tap = tex2D(_MainTex, coords);
        color += tap * curve4[l];
        coords += netFilterWidth;
      }
      return color;
    }

    ENDCG

    SubShader {
      ZTest Off Cull Off ZWrite Off Blend Off

      // 0
      Pass{

        CGPROGRAM
        #pragma vertex vertBloom
        #pragma fragment fragBloom

        ENDCG

      }

      // 1
      Pass{

        CGPROGRAM

        #pragma vertex vert4Tap
        #pragma fragment fragDownsample

        ENDCG

      }

      // 2
      Pass{
        ZTest Always
        Cull Off

        CGPROGRAM

        #pragma vertex vertBlurVertical
        #pragma fragment fragBlur8

        ENDCG
      }

      // 3
      Pass{
        ZTest Always
        Cull Off

        CGPROGRAM

        #pragma vertex vertBlurHorizontal
        #pragma fragment fragBlur8

        ENDCG
      }
    }

    FallBack Off
  }

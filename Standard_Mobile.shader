// Standard shader for mobile
// Written by Nihal Mirpuri @nylonee

// Notes
// Doesn't support shadow casting
// Only supports exponential2 fog (the cheapest)
// TODO: Detail map and detail mask
// TODO: Specular map
// TODO: Convert all relevant float into half and fixed values
// TODO: Change defined point light to a single inputted light?
// TODO: Treat all other light sources as Vertex lights?
// TODO: Bump mapping seems a bit weird?
// TODO: Transparency vs Opaque? Dropdown menu?
// TODO: Optimisation

Shader "Custom/StandardMobile"
{
  Properties
  {
    _MainTex("Albedo", 2D) = "white" {}

    _Color("Color", Color) = (1,1,1,0)
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

    [Toggle(BUMP_ON)] _Bump("Bump Map Toggle", Int) = 0
    _BumpMap("Bump Map", 2D) = "white" {}
  }

  SubShader {
  	Tags { "RenderType" = "Opaque" }
  	LOD 150

    Pass {
      Tags { "LightMode" = "VertexLM" }
      Lighting Off
  		CGPROGRAM
      #pragma vertex vert_lm
      #pragma fragment frag_lm

      #pragma multi_compile_fog
      #pragma skip_variants FOG_LINEAR FOG_EXP

      #pragma shader_feature PHONG_ON
      #pragma shader_feature EMISSION_ON
      #pragma shader_feature BUMP_ON

      #include "StandardMobile.cginc"
      ENDCG
    }

    Pass {
      Tags { "LightMode" = "VertexLMRGBM" }
      Lighting Off
      CGPROGRAM
      #pragma vertex vert_lm
      #pragma fragment frag_lm

      #pragma multi_compile_fog
      #pragma skip_variants FOG_LINEAR FOG_EXP

      #pragma shader_feature PHONG_ON
      #pragma shader_feature EMISSION_ON
      #pragma shader_feature BUMP_ON

      #include "StandardMobile.cginc"
      ENDCG
    }

    Pass {
      Tags { "LightMode" = "Vertex" }
      Lighting Off
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag

      #pragma multi_compile_fog
      #pragma skip_variants FOG_LINEAR FOG_EXP

      #pragma shader_feature PHONG_ON
      #pragma shader_feature EMISSION_ON
      #pragma shader_feature BUMP_ON

      #include "StandardMobile.cginc"
      ENDCG
    }
  }

  FallBack "Mobile/VertexLit"
}

// Simplified Phong shader

Shader "Custom/MobilePhong" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
    _PointLightColor("Point Light Color", Color) = (0, 0, 0)
    _PointLightPosition("Point Light Position", Vector) = (0.0, 0.0, 0.0)
	}

	SubShader {
		Tags { "RenderType" = "Opaque" }
		LOD 150

    Pass {
  		CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog

      #include "UnityCG.cginc"

    	sampler2D _MainTex;
    	float4 _MainTex_ST;

      uniform float3 _PointLightColor;
      uniform float3 _PointLightPosition;

      struct appdata
      {
        float4 vertex : POSITION;
        float4 normal : NORMAL;
        float4 color : COLOR;
        float2 texcoord : TEXCOORD0;
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

      fixed4 frag(v2f v) : SV_Target
      {
        // Our interpolated normal might not be of length 1
        float3 interpNormal = normalize(v.worldNormal);

        float4 returnColor = tex2D(_MainTex, v.uv_main);

        // Calculate ambient RGB intensities
        float Ka = 1;
        float3 amb = v.color.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb * Ka;

        // Calculate diffuse RGB reflections, we save the results of L.N because we will use it again
        // (when calculating the reflected ray in our specular component)
        float fAtt = 1;
        float Kd = 1;
        float3 L = normalize(_PointLightPosition - v.worldVertex.xyz);
        float LdotN = dot(L, interpNormal);
        float3 dif = fAtt * _PointLightColor.rgb * Kd * v.color.rgb * saturate(LdotN);

        // Calculate specular reflections
        float Ks = 1;
        float specN = 5; // Values >> 1 give tighter highlights
        float3 V = normalize(_WorldSpaceCameraPos - v.worldVertex.xyz);

        // Using classic reflection calculation
        //float3 R = normalize((2.0 * LdotN * interpNormal) - L);
        //float3 spe = fAtt * _PointLightColor.rgb * Ks * pow(saturate(dot(V, R)), specN);

        // Using Blinn-Phong approximation:
        specN = 25; // We usually need a higher specular power when using Blinn-Phong
        float3 H = normalize(V+L);
        float3 spe = fAtt * _PointLightColor.rgb * Ks * pow(saturate(dot(interpNormal, H)), specN);

        // Combine Phong illumination model components
        // XXX: This could be better merged. Lerp? (not multiplied)
        returnColor.rgb *= amb.rgb + dif.rgb + spe.rgb;

        UNITY_APPLY_FOG(v.fogCoord, returnColor);

        return returnColor;
      }

  		ENDCG
    }

	}

	Fallback "Mobile/VertexLit"
}

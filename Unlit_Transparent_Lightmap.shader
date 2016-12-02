Shader "Custom/Unlit Transparent (Supports Lightmap)" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
			_Color ("Main Color", Color) = (1,1,1,1)
		}

		SubShader {
			Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
			LOD 150

			ZWrite on
			Blend SrcAlpha OneMinusSrcAlpha

			Pass {
				Tags{ "LightMode" = "VertexLM" }
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
					float2 uv_lightmap : TEXCOORD0;
					float2 uv_main : TEXCOORD1;
					UNITY_FOG_COORDS(2)
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;
				float4 _Color;

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
					half4 main_color = tex2D(_MainTex, i.uv_main);

					main_color.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_lightmap)) * _Color;
					// Apply fog
					UNITY_APPLY_FOG(i.fogCoord, main_color);
					return main_color;
				}

				ENDCG
			}

			Pass{
				Tags{ "LightMode" = "VertexLMRGBM" }
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
					float2 uv_lightmap : TEXCOORD0;
					float2 uv_main : TEXCOORD1;
					UNITY_FOG_COORDS(2)
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;
				float4 _Color;

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
					half4 main_color = tex2D(_MainTex, i.uv_main);

					main_color.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_lightmap)) * _Color;
					// Apply fog
					UNITY_APPLY_FOG(i.fogCoord, main_color);
					return main_color;
				}

				ENDCG
			}

			Pass{
				Tags{ "LightMode" = "Vertex" }
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
					float2 uv_main : TEXCOORD0;
					UNITY_FOG_COORDS(1)
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;
				float4 _Color;

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
					half4 main_color = tex2D(_MainTex, i.uv_main);
					main_color.rgb *= _Color;
					// Apply fog
					UNITY_APPLY_FOG(i.fogCoord, main_color);
					return main_color;
				}

				ENDCG
			}
		}
	}

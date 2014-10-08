Shader "Custom/Core" {
	Properties {
		//tessellation properties
		_EdgeLength ("Edge length", Range(2,50)) = 15
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_DispTex ("Disp Texture", 2D) = "gray" {}
		_NormalMap ("Normalmap", 2D) = "bump" {}
		_Displacement ("Displacement", Range(0, 1.0)) = 0.3
		_Color ("Color", color) = (1,1,1,0)
		//Shield properties//
		_NoiseTex("Noise (RGBA)", 2D) = "white" {}
		_Noise("Noise", FLOAT) = 0.2
		_Speed("Speed", FLOAT) = 0.2
		_FallOff("FallOff", FLOAT) = 2
		_Lines("Lines", FLOAT) = 0.2
		_Width("Width", FLOAT) = 0.2
		_ShieldColor ("Shield Color", color) = (1,1,1,0.5)
		//Rim lighting//
		_Illum ("Illumin (A)", 2D) = "white" {}
		_EmissionLM ("Emission (Lightmapper)", Float) = 0
		_RimColor ("Rim Color", Color) = (0.26,0.19,0.16,0.0)
		_RimPower ("Rim Power", Range(0.5,8.0)) = 3.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 300

		CGPROGRAM
		#pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessEdge nolightmap
		#pragma target 5.0
		#include "Tessellation.cginc"

		struct appdata {
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		float _EdgeLength;

		float4 tessEdge (appdata v0, appdata v1, appdata v2)
		{
			return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
		}

		sampler2D _DispTex;
		float _Displacement;

		void disp (inout appdata v)
		{
			float d = tex2Dlod(_DispTex, float4(v.texcoord.xy * _SinTime,0,0)).r * _Displacement;
			v.vertex.xyz += v.normal * d;
		}

		struct Input {
			float2 uv_MainTex;
			float2 uv_Illum;
			float3 viewDir;
		};

		sampler2D _MainTex;
		sampler2D _NormalMap;
		fixed4 _Color;
		sampler2D _Illum;
		float4 _RimColor;
		float _RimPower;

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Gloss = 1.0;
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
			fixed4 rc = c * _Color;
			half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
			o.Emission =  rc.rgb * tex2D(_Illum, IN.uv_Illum).a  + pow (rim, _RimPower) * _RimColor.rgb;
		}
		ENDCG
		//Render the shield//
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Off
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"	
			float4 _NoiseTex_ST;
			sampler2D _NoiseTex;
			float _Speed;
			half4 _ShieldColor;
			float _FallOff;
			float _Lines;
			float _Noise;
			float _Width;

			struct data{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD;
				float3 normal : NORMAL;
			};

			struct v2f{
				float4 position : POSITION;
				float2 uv : TEXCOORD;
				float viewAngle : TEXCOORD1;
				float ypos : TEXCOORD2;
			};

			v2f vert(data v){
				v2f o;
				o.position = mul(UNITY_MATRIX_MVP, v.vertex + float4(v.normal, 0) * _Width);
				o.uv = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				o.viewAngle = 1- abs(dot(v.normal, normalize(ObjSpaceViewDir(v.vertex))));
				o.ypos = o.position.y;
				return o;
			}

			half4 frag(v2f i) : COLOR {
				float2 uvOffset1 = _Time.xy*_Noise;
				float2 uvOffset2 = -_Time.xx*_Noise;
				half4 noise1 = tex2D(_NoiseTex, i.uv + uvOffset1);
				half4 noise2 = tex2D(_NoiseTex, i.uv + uvOffset2);
				float noise = (dot(noise1, noise2) - 1) * _Noise;
				half4 col = sin((i.ypos*_Lines + _Time.x*_Speed + noise)*100);
				noise1 = tex2D(_NoiseTex, i.uv*6 + uvOffset1);
				noise2 = tex2D(_NoiseTex, i.uv*6 + uvOffset2);
				col.a *= saturate(1.3-(noise1.g+noise2.g)) * pow(i.viewAngle,_FallOff) * 15;
				return col * _ShieldColor * 2;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
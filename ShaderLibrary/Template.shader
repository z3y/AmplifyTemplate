Shader /*ase_name*/ "Hidden/Built-In (z3y)/Lit" /*end*/
{
    Properties
    {
        /*ase_props*/
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+0" "DisableBatching" = "False" }
        /*ase_all_modules*/
		/*ase_pass*/
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            /*ase_pragma*/

            #include "UnityCG.cginc"
            #include "Packages/com.z3y.shadersamplify/ShaderLibrary/Functions.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 uv2 : TEXCOORD2;
                /*ase_vdata:p=p;n=n;t=t;uv0=tc0;uv1=tc1;uv2=tc2*/
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                #if defined(LIGHTMAP_ON) && defined(DYNAMICLIGHTMAP_ON)
                    centroid float4 lightmapUV : TEXCOORD3;
                #elif defined(LIGHTMAP_ON)
                    centroid float2 lightmapUV : TEXCOORD4;
                #endif
                UNITY_FOG_COORDS(5)
                /*ase_interp(6,):sp=sp;wp=tc0;wn=tc1;wt=tc2*/
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };

            /*ase_globals*/
            /*ase_funcs*/

            Varyings vert (Attributes attributes/*ase_vert_input*/)
            {
                Varyings varyings;
				UNITY_SETUP_INSTANCE_ID(attributes);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				UNITY_TRANSFER_INSTANCE_ID(attributes, varyings);

                /*ase_vert_code:attributes=Attributes;varyings=Varyings*/

                float4 positionCS = UnityObjectToClipPos(attributes.positionOS);
                float3 positionWS = mul(unity_ObjectToWorld, float4(attributes.positionOS, 1.0)).xyz;
                float3 normalWS = UnityObjectToWorldNormal(attributes.normalOS);
                float4 tangentWS = float4(UnityObjectToWorldDir(attributes.tangentOS.xyz), attributes.tangentOS.w);

                varyings.positionCS = positionCS;
                varyings.positionWS = positionWS;
                varyings.normalWS = normalWS;
                varyings.tangentWS = tangentWS;

                #if defined(LIGHTMAP_ON)
                    varyings.lightmapUV.xy = mad(attributes.uv1.xy, unity_LightmapST.xy, unity_LightmapST.zw);
                #endif
                #if defined(DYNAMICLIGHTMAP_ON)
                    varyings.lightmapUV.zw = mad(attributes.uv2.xy, unity_DynamicLightmapST.xy, unity_DynamicLightmapST.zw);
                #endif

                UNITY_TRANSFER_FOG(varyings, varyings.vertex);
                return varyings;
            }

            // #define _NORMALMAP

            half4 frag (Varyings varyings/*ase_frag_input*/) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
                /*ase_local_var*/float2 lightmapUV = 0;
                #if defined(LIGHTMAP_ON)
                    lightmapUV = varyings.lightmapUV;
                #endif
                
                // float renormFactor = 1.0 / length(varyings.normalWS.xyz);
                float oddNegativeScale = unity_WorldTransformParams.w;
                float crossSign = (varyings.tangentWS.w > 0.0 ? 1.0 : -1.0) * oddNegativeScale;
                float3 bitangentWS = crossSign * cross(varyings.normalWS.xyz, varyings.tangentWS.xyz);
                float3 tangentWS;
                float3 normalWS;
                /*ase_local_var:wbt*/float3 bitangentWSVertex = bitangentWS;

                #if defined(_NORMALMAP)
                    // float3x3 tangentToWorld = float3x3(varyings.tangentWS.xyz, bitangentWS, varyings.normalWS.xyz);
                    // normalWS = TransformTangentToWorld(surfaceDescription.Normal, tangentToWorld);

                    normalWS = Unity_SafeNormalize(varyings.normalWS);
                #else
                    normalWS = normalize(varyings.normalWS);
                    tangentWS = varyings.tangentWS.xyz;
                    bitangentWS = bitangentWS;
                #endif

                /*ase_frag_code:varyings=Varyings*/

                half4 color = /*ase_frag_out:Albedo;Float4*/half4(1,1,1,1)/*end*/;
                UNITY_APPLY_FOG(i.fogCoord, color);
                return color;
            }
            ENDCG
        }
    }
}

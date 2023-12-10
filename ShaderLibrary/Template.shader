/*applydfg*/
Shader /*ase_name*/ "Hidden/Built-In/Lit" /*end*/
{
    Properties
    {
        [HideInInspector] [NonModifiableTextureData] [NoScaleOffset] _DFG ("DFG", 2D) = "" {}
        /*ase_props*/
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+0" "DisableBatching" = "False" }
        /*ase_all_modules*/
		/*ase_pass*/
        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "ForwardBase" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            /*ase_pragma*/

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
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

                UNITY_TRANSFER_FOG(varyings, varyings.positionCS);
                return varyings;
            }

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
                /*ase_local_var:wn*/float3 geometricNormalWS = normalize(varyings.normalWS);
                /*ase_local_var:wt*/float3 geometricTangentWS = normalize(varyings.tangentWS.xyz);
                /*ase_local_var:wbt*/float3 geometricBitangentWS = normalize(bitangentWS);
                /*ase_local_var:wp*/float3 positionWS = varyings.positionWS;
                /*ase_local_var:wvd*/float3 viewDirectionWS = normalize(UnityWorldSpaceViewDir(positionWS));

                /*ase_frag_code:varyings=Varyings*/
                half3 albedo = /*ase_frag_out:Albedo;Float3*/1.0/*end*/;
                half alpha = /*ase_frag_out:Alpha;Float*/1.0/*end*/;
                float3 normalTS = /*ase_frag_out:Normal;Float3*/float3(0, 0, 1)/*end*/;
                half roughness = /*ase_frag_out:Roughness;Float*/0.5/*end*/;
                half metallic = /*ase_frag_out:Metallic;Float*/0.0/*end*/;
                half reflectance = /*ase_frag_out:Reflectance;Float*/0.5/*end*/;
                half3 emission = /*ase_frag_out:Emission;Float3*/0.0/*end*/;
                half gsaaVariance = /*ase_frag_out:GSAA Variance;Float*/0.15/*end*/;
                half gsaaThreshold = /*ase_frag_out:GSAA Threshold;Float*/0.1/*end*/;

                #if defined(_NORMALMAP)
                    float3x3 tangentToWorld = float3x3(varyings.tangentWS.xyz, bitangentWS, varyings.normalWS.xyz);
                    normalWS = mul(normalTS, tangentToWorld);
                    normalWS = Unity_SafeNormalize(normalWS);
                #else
                    normalWS = geometricNormalWS;
                #endif
                tangentWS = geometricTangentWS;
                bitangentWS = geometricBitangentWS;

                half NoV = abs(dot(normalWS, viewDirectionWS)) + 1e-5f;
                #if defined(_GEOMETRIC_SPECULAR_AA)
                    roughness = Filament::GeometricSpecularAA(geometricNormalWS, roughness, gsaaVariance, gsaaThreshold);
                #endif
                half roughness2 = roughness * roughness;
                half roughness2Clamped = max(roughness2, 0.002);
                float3 reflectVector = reflect(-viewDirectionWS, normalWS);
                #if !defined(QUALITY_LOW)
                    reflectVector = lerp(reflectVector, normalWS, roughness2);
                #endif
                half3 f0 = 0.16 * reflectance * reflectance * (1.0 - metallic) + albedo * metallic;

                half4 color = half4(albedo, alpha);

                color.rgb += emission;
                UNITY_APPLY_FOG(i.fogCoord, color);
                return color;
            }
            ENDHLSL
        }
    }
}

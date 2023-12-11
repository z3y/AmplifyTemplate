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
            /*ase_main_pass*/
            Name "Forward"
            Tags { "LightMode" = "ForwardBase" }

            HLSLPROGRAM
            #pragma target 4.5 
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma skip_variants LIGHTPROBE_SH
            /*ase_pragma*/

            #define pos positionCS
            #define vertex positionOS
            #define normal normalOS
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                SHADOW_COORDS(6)
                #if !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    float3 sh : TEXCOORD7;
                #endif
                /*ase_interp(8,):sp=sp;wp=tc0;wn=tc1;wt=tc2*/
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };

            #include "Packages/com.z3y.shadersamplify/ShaderLibrary/Functions.hlsl"

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

                #if !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    varyings.sh = ShadeSHPerVertex(varyings.normalWS, 0);
                #endif

                UNITY_TRANSFER_SHADOW(varyings, attributes.uv1.xy);
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

                Light light = Light::Initialize(varyings);
                /*ase_local_var*/half3 lightColor = light.color;
                /*ase_local_var*/half3 lightDirection = light.direction;
                /*ase_local_var*/half lightAttenuation = light.attenuation;

                /*ase_frag_code:varyings=Varyings*/
                half3 albedo = /*ase_frag_out:Albedo;Float3;_Albedo*/1.0/*end*/;
                half alpha = /*ase_frag_out:Alpha;Float;_Alpha*/1.0/*end*/;
                half alphaClipThreshold = /*ase_frag_out:Alpha Clip Threshold;Float;_AlphaClip*/0.5/*end*/;
                float3 normalTS = /*ase_frag_out:Normal;Float3;_NormalTS*/float3(0, 0, 1)/*end*/;
                half roughness = /*ase_frag_out:Roughness;Float;_Roughness*/0.5/*end*/;
                half metallic = /*ase_frag_out:Metallic;Float;_Metallic*/0.0/*end*/;
                half occlusion = /*ase_frag_out:Occlusion;Float;_Occlusion*/1.0/*end*/;
                half reflectance = /*ase_frag_out:Reflectance;Float;_Reflectance*/0.5/*end*/;
                half3 emission = /*ase_frag_out:Emission;Float3;_Emission*/0.0/*end*/;
                half gsaaVariance = /*ase_frag_out:GSAA Variance;Float;_GSAAV*/0.15/*end*/;
                half gsaaThreshold = /*ase_frag_out:GSAA Threshold;Float;_GSAAT*/0.1/*end*/;
                half specularAOIntensity = /*ase_frag_out:Specular Occlusion;Float;_SPAO*/0.0/*end*/;

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
                half3 brdf;
                half3 energyCompensation;
                Filament::EnvironmentBRDF(NoV, roughness, f0, brdf, energyCompensation);

                half3 indirectDiffuse;
                half3 indirectOcclusion;
                #if defined(LIGHTMAP_ON)
                    half3 illuminance = DecodeLightmap(unity_Lightmap.SampleLevel(custom_bilinear_clamp_sampler, lightmapUV, 0));

                    #if defined(DIRLIGHTMAP_COMBINED) || defined(_BAKERY_MONOSH)
                        half4 directionalLightmap = unity_LightmapInd.SampleLevel(custom_bilinear_clamp_sampler, lightmapUV, 0);
                        #ifdef _BAKERY_MONOSH
                            half3 L0 = illuminance;
                            half3 nL1 = directionalLightmap * 2.0 - 1.0;
                            half3 L1x = nL1.x * L0 * 2.0;
                            half3 L1y = nL1.y * L0 * 2.0;
                            half3 L1z = nL1.z * L0 * 2.0;
                            half3 sh = L0 + normalWS.x * L1x + normalWS.y * L1y + normalWS.z * L1z;
                            illuminance = sh;
                        #else
                            half halfLambert = dot(normalWS, directionalLightmap.xyz - 0.5) + 0.5;
                            illuminance = illuminance * halfLambert / max(1e-4, directionalLightmap.w);
                        #endif
                    #endif
                    indirectDiffuse = illuminance;

                    #if defined(_BAKERY_MONOSH)
                        indirectOcclusion = (dot(nL1, reflectVector) + 1.0) * L0 * 2.0;
                    #else
                        indirectOcclusion = illuminance;
                    #endif
                #else
                    #if UNITY_SAMPLE_FULL_SH_PER_PIXEL
                        indirectDiffuse = ShadeSHPerPixel(normalWS, 0.0, positionWS);
                    #else
                        indirectDiffuse = ShadeSHPerPixel(normalWS, varyings.sh, positionWS);
                    #endif
                    indirectOcclusion = indirectDiffuse;
                #endif
                indirectDiffuse = max(0.0, indirectDiffuse);

                half3 directDiffuse = 0;
                half3 directSpecular = 0;
                half3 indirectSpecular = 0;

                // main light
                ShadeLight(light, viewDirectionWS, normalWS, roughness, NoV, f0, energyCompensation, directDiffuse, directSpecular);

                // reflection probes
                #if !defined(_GLOSSYREFLECTIONS_OFF)
                    Unity_GlossyEnvironmentData envData;
                    envData.roughness = roughness;
                    envData.reflUVW = BoxProjectedCubemapDirection(reflectVector, positionWS, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);

                    half3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
                    half3 reflectionSpecular = probe0;

                    #if defined(UNITY_SPECCUBE_BLENDING)
                        UNITY_BRANCH
                        if (unity_SpecCube0_BoxMin.w < 0.99999)
                        {
                            envData.reflUVW = BoxProjectedCubemapDirection(reflectVector, positionWS, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                            float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
                            reflectionSpecular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
                        }
                    #endif
                    indirectSpecular += reflectionSpecular;
                #endif

                #if !defined(QUALITY_LOW)
                    float horizon = min(1.0 + dot(reflectVector, normalWS), 1.0);
                    indirectSpecular *= horizon * horizon;
                #endif

                indirectSpecular *= energyCompensation * brdf;
                directSpecular *= UNITY_PI;

                half specularAO = lerp(1.0, saturate(sqrt(dot(indirectOcclusion + directDiffuse, 1.0))), specularAOIntensity) * Filament::ComputeSpecularAO(NoV, occlusion, roughness2);
                indirectSpecular *= specularAO;

                half4 color = half4(albedo * (1.0 - metallic) * (indirectDiffuse * occlusion + directDiffuse), alpha);
                color.rgb += directSpecular + indirectSpecular;
                color.rgb += emission;

                UNITY_APPLY_FOG(i.fogCoord, color);
                return color;
            }
            ENDHLSL
        }
        /*ase_pass*/
        Pass
        {
            /*ase_hide_pass*/
            Name "SHADOWCASTER"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On
            Cull Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            /*ase_pragma*/

            #define pos positionCS
            #define vertex positionOS
            #define normal normalOS
            #include "UnityCG.cginc"
            // #include "Lighting.cginc"
            // #include "AutoLight.cginc"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                /*ase_vdata:p=p;n=n*/
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                /*ase_interp(1,):sp=sp*/
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

                Attributes v = attributes;
                TRANSFER_SHADOW_CASTER_NOPOS(varyings, varyings.positionCS);
                return varyings;
            }

            void frag (Varyings varyings/*ase_frag_input*/)
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
                /*ase_frag_code:varyings=Varyings*/
                half alpha = /*ase_frag_out:Alpha;Float;_Alpha*/1.0/*end*/;
                half alphaClipThreshold = /*ase_frag_out:Alpha Clip Threshold;Float;_AlphaClip*/0.5/*end*/;
                #ifdef _ALPHATEST_ON
					clip(alpha - alphaClipThreshold);
				#endif
            }
            ENDHLSL
        }
        /*ase_pass*/
        Pass
        {
            /*ase_hide_pass*/
            Name "META"
            Tags { "LightMode"="Meta" }
            Cull Off

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature EDITOR_VISUALIZATION
            /*ase_pragma*/

            #define pos positionCS
            #define vertex positionOS
            #define normal normalOS
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityMetaPass.cginc"

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
                #ifdef EDITOR_VISUALIZATION
                    float2 vizUV : TEXCOORD0;
                    float4 lightCoord : TEXCOORD1;
                #endif
                /*ase_interp(2,):sp=sp*/
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

                varyings.positionCS = UnityMetaVertexPosition(float4(attributes.positionOS, 1.0), attributes.uv1.xy, attributes.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
                #ifdef EDITOR_VISUALIZATION
                    varyings.vizUV = 0;
                    varyings.lightCoord = 0;
                    if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
                        varyings.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, attributes.uv0.xy, attributes.uv1.xy, attributes.uv2.xy, unity_EditorViz_Texture_ST);
                    else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
                    {
                        varyings.vizUV = attributes.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                        varyings.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(attributes.positionOS, 1)));
                    }
                #endif

                return varyings;
            }

            half3 LightmappingAlbedo(half3 diffuse, half3 specular, half roughness)
            {
                half3 res = diffuse;
                res += specular * roughness * 0.5;
                return res;
            }

            half4 frag (Varyings varyings/*ase_frag_input*/) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
                /*ase_frag_code:varyings=Varyings*/
                half3 albedo = /*ase_frag_out:Albedo;Float3;_Albedo*/1.0/*end*/;
                half alpha = /*ase_frag_out:Alpha;Float;_Alpha*/1.0/*end*/;
                half alphaClipThreshold = /*ase_frag_out:Alpha Clip Threshold;Float;_AlphaClip*/0.5/*end*/;
                half roughness = /*ase_frag_out:Roughness;Float;_Roughness*/0.5/*end*/;
                half metallic = /*ase_frag_out:Metallic;Float;_Metallic*/0.0/*end*/;
                half3 emission = /*ase_frag_out:Emission;Float3;_Emission*/0.0/*end*/;

                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

                half3 specColor;
                half oneMinisReflectivity;
                half3 diffuseColor = DiffuseAndSpecularFromMetallic(albedo, metallic, specColor, oneMinisReflectivity);

                #ifdef EDITOR_VISUALIZATION
                    o.Albedo = diffuseColor;
                    o.VizUV = varyings.vizUV;
                    o.LightCoord = varyings.lightCoord;
                #else
                    o.Albedo = LightmappingAlbedo(diffuseColor, specColor, roughness);
                #endif
                
                o.SpecularColor = specColor;
                o.Emission = emission;

                #if defined(_ALPHATEST_ON)
                    clip(alpha - alphaClipThreshold);
                #endif
                
                return UnityMetaFragment(o);
            }
            ENDHLSL
        }
    }
}

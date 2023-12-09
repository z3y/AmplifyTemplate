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

            struct Attributes
            {
                float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                /*ase_vdata:p=p;n=n;t=t;uv0=tc0;uv1=tc1.xyzw*/
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                UNITY_FOG_COORDS(3)
                /*ase_interp(4,):sp=sp.xyzw*/
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };

            /*ase_globals*/
            /*ase_funcs*/

            Varyings vert (Attributes attributes /*ase_vert_input*/)
            {
                Varyings varyings;
				UNITY_SETUP_INSTANCE_ID(attributes);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				UNITY_TRANSFER_INSTANCE_ID(attributes, varyings);

                /*ase_vert_code:attributes=Attributes;varyings=Varyings*/

                varyings.positionCS = UnityObjectToClipPos(float4(attributes.positionOS.xyz, 1.0));
                UNITY_TRANSFER_FOG(varyings, varyings.vertex);
                return varyings;
            }

            half4 frag (Varyings varyings /*ase_frag_input*/) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
                /*ase_frag_code:varyings=Varyings*/

                half4 finalColor = /*ase_frag_out:Albedo;Float4*/half4(1,1,1,1)/*end*/;
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                return finalColor;
            }
            ENDCG
        }
    }
}

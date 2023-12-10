using System.IO;
using UnityEditor;
using UnityEngine;

namespace z3y
{
    class MyAllPostprocessor : AssetPostprocessor
    {
        static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets, string[] movedFromAssetPaths, bool didDomainReload)
        {
            foreach (string path in importedAssets)
            {
                bool isShader = path.EndsWith(".shader");
                if (!isShader)
                {
                    continue;
                }

                var lines = File.ReadLines(path);
                foreach (var line in lines)
                {
                    if (line.StartsWith("/*applydfg*/"))
                    {
                        ApplyDFGLut(path);
                        break;
                    }

                    if (line.StartsWith("Shader"))
                    {
                        break;
                    }
                }
            }
        }
        private const string DFG_PATH = "Packages/com.z3y.shadersamplify/ShaderLibrary/dfg-multiscatter.exr";
        private static void ApplyDFGLut(string path)
        {
            var shader = AssetDatabase.LoadAssetAtPath<Shader>(path);
            var dfg = AssetDatabase.LoadAssetAtPath<Texture>(DFG_PATH);
            EditorMaterialUtility.SetShaderNonModifiableDefaults(shader, new [] { "_DFG" }, new [] { dfg });
        }
    }
}
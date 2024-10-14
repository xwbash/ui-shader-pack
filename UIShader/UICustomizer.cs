using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class UICustomizer : MonoBehaviour
{
}

#if UNITY_EDITOR
[Serializable]
public class BlurData
{
    public int BlurStep;
    public float BlendFactor;
    public float BlendRadius;
    public bool Optimized;
}

[CustomEditor(typeof(UICustomizer))]
public class MyScriptEditor : Editor
{
    [SerializeField] [InspectorName("Blur")] private bool m_blurActive;
    private BlurData blurData = new BlurData();
    private bool isEffectsFoldoutActive = false;

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        isEffectsFoldoutActive = EditorGUILayout.Foldout(isEffectsFoldoutActive, "Effects");

        if (isEffectsFoldoutActive)
        {
            EditorGUI.indentLevel++; 

            m_blurActive = EditorGUILayout.Toggle("Activate Blur", m_blurActive);

            if (m_blurActive)
            {
                if (!blurData.Optimized)
                {
                    blurData.BlurStep = EditorGUILayout.IntField("Blur Step", blurData.BlurStep);
                }

                blurData.BlendFactor = EditorGUILayout.FloatField("Blend Factor", blurData.BlendFactor);
                blurData.BlendRadius = EditorGUILayout.FloatField("Blend Radius", blurData.BlendRadius);
                blurData.Optimized = EditorGUILayout.Toggle("Optimized", blurData.Optimized);
            }
        
            EditorGUI.indentLevel--;
        }
    }

}
#endif
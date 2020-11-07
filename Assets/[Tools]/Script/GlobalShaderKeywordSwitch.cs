using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

class GlobalShaderKeywordSwitch : UnityEngine.MonoBehaviour
{
    public int ButtonWidth = 80;
    public int ButtonHeight = 20;
    public string[] ShaderKeywords = { };

    private int currentShaderKeywordIndex = -1;
    
    public void OnEnable()
    {
        this.currentShaderKeywordIndex = -1;
    }

    public void OnDisable()
    {
        if (this.currentShaderKeywordIndex >= 0)
        {
            UnityEngine.Shader.DisableKeyword(this.ShaderKeywords[this.currentShaderKeywordIndex]);
            this.currentShaderKeywordIndex = -1;
        }
    }

    public void OnGUI()
    {
        UnityEngine.Rect oneLine = new UnityEngine.Rect(0, 0, UnityEngine.Screen.width, ButtonHeight);
        UnityEngine.Rect endOfLine = oneLine;
        endOfLine.xMin = endOfLine.xMax - ButtonWidth;
        for (int i = 0; i < this.ShaderKeywords.Length; ++i)
        {
            if (this.currentShaderKeywordIndex != i)
            {
                if (UnityEngine.GUI.Button(endOfLine, ShaderKeywords[i]))
                {
                    if (this.currentShaderKeywordIndex >= 0)
                    {
                        UnityEngine.Shader.DisableKeyword(this.ShaderKeywords[this.currentShaderKeywordIndex]);
                        this.currentShaderKeywordIndex = -1;
                    }

                    this.currentShaderKeywordIndex = i;
                    UnityEngine.Shader.EnableKeyword(this.ShaderKeywords[this.currentShaderKeywordIndex]);
                }
            }
            else
            {
                UnityEngine.GUI.Box(endOfLine, ShaderKeywords[i]);
            }
            
            endOfLine.y += endOfLine.height;
        }

        if (this.currentShaderKeywordIndex != -1)
        {
            if (UnityEngine.GUI.Button(endOfLine, "x"))
            {
                if (this.currentShaderKeywordIndex >= 0)
                {
                    UnityEngine.Shader.DisableKeyword(this.ShaderKeywords[this.currentShaderKeywordIndex]);
                    this.currentShaderKeywordIndex = -1;
                }

                this.currentShaderKeywordIndex = -1;
            }
        }
        else
        {
            UnityEngine.GUI.Box(endOfLine, "x");
        }
    }
}

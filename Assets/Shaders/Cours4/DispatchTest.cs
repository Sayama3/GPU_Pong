

using UnityEngine.Rendering;

public class DispatchTest : DrawProceduralRenderer
{
    public UnityEngine.ComputeShader computeShader;

    public int DispatchSizeX = 64;
    public int DispatchSizeY = 64;
    
    public UnityEngine.Vector2Int size = new UnityEngine.Vector2Int(1024, 1024);
    public string RenderTextureExportName = "_DispatchTestOutput";

    private UnityEngine.RenderTexture renderTexture;

    protected override void Unload()
    {
        base.Unload();
        if (this.renderTexture != null)
        {
            this.renderTexture.Release();
        }

        this.renderTexture = null;
    }

    protected override void AddCommands(CommandBuffer commandBuffer)
    {
        if (this.renderTexture == null ||
            this.renderTexture.width != this.size.x ||
            this.renderTexture.height != this.size.y)
        {
            this.renderTexture?.Release();
            UnityEngine.RenderTextureDescriptor rtd = new UnityEngine.RenderTextureDescriptor(this.size.x, this.size.y, UnityEngine.RenderTextureFormat.ARGB32);
            rtd.enableRandomWrite = true;
            rtd.useMipMap = false;
            this.renderTexture = new UnityEngine.RenderTexture(rtd);
            this.renderTexture.name = this.RenderTextureExportName;
            this.renderTexture.Create();
        }

        base.AddCommands(commandBuffer);

        commandBuffer.SetGlobalTexture(this.RenderTextureExportName, this.renderTexture);
        if (this.computeShader)
        {
            commandBuffer.DispatchCompute(this.computeShader, 0, this.DispatchSizeX, this.DispatchSizeY, 1);
        }

    }
}



using UnityEngine.Rendering;

public class GPUPong : DrawProceduralRenderer
{
    public UnityEngine.ComputeShader computeShader;
    public string EvolveKernelName = "CSEvolve";
    public string ResetKernelName = "CSReset";

    public string EvolveWorldKernelName = "CSWorldEvolve";
    public string ResetWorldKernelName = "CSWorldReset";

    public int kernelSizeX = 32;

    private UnityEngine.ComputeBuffer inputAndTime;
    private float[] inputAndTimeDatas;
    private UnityEngine.ComputeBuffer worldData;
    private UnityEngine.ComputeBuffer ballData;
    private bool doReset = true;

    private int evolveKernelIndex = 0;
    private int resetKernelIndex = 1;

    private int evolveWorldKernelIndex = 0;
    private int resetWorldKernelIndex = 1;

    public void OnGUI()
    {
        if (UnityEngine.GUILayout.Button("Reset"))
        {
            this.doReset = true;
        }
    }

    protected override void Load()
    {
        base.Load();
        this.doReset = true;
        this.evolveKernelIndex = this.computeShader.FindKernel(this.EvolveKernelName);
        this.resetKernelIndex = this.computeShader.FindKernel(this.ResetKernelName);
        this.evolveWorldKernelIndex = this.computeShader.FindKernel(this.EvolveWorldKernelName);
        this.resetWorldKernelIndex = this.computeShader.FindKernel(this.ResetWorldKernelName);
    }
    protected override void Unload()
    {
        base.Unload();
        if (this.inputAndTime != null)
        {
            this.inputAndTime.Release();
        }

        if (this.ballData != null)
        {
            this.ballData.Release();
        }

        if (this.worldData != null)
        {
            this.worldData.Release();
        }

        this.inputAndTime = null;
        this.ballData = null;
        this.worldData = null;
    }

    protected override void AddCommands(CommandBuffer commandBuffer)
    {
        this.CreateBuffersIFN();

        base.AddCommands(commandBuffer);
        this.FillInputAndTime(commandBuffer);
        commandBuffer.SetGlobalBuffer("_InputAndTime", this.inputAndTime);
        commandBuffer.SetGlobalBuffer("_WorldData", this.worldData);
        commandBuffer.SetGlobalBuffer("_BallData", this.ballData);
        commandBuffer.SetGlobalInt("_BallDataSize", this.ballData.count);
        if (this.computeShader != null)
        {
            int kernelX = this.ballData.count / this.kernelSizeX;
            if (kernelSizeX * kernelX <  this.ballData.count)
            {
                ++kernelX;
            }

            if (this.doReset)
            {
                commandBuffer.DispatchCompute(this.computeShader, this.resetWorldKernelIndex, 1, 1, 1);
                commandBuffer.DispatchCompute(this.computeShader, this.resetKernelIndex, kernelX, 1, 1);
                this.doReset = false;
            }

            commandBuffer.DispatchCompute(this.computeShader, this.evolveWorldKernelIndex, 1, 1, 1);
            commandBuffer.DispatchCompute(this.computeShader, this.evolveKernelIndex, kernelX, 1, 1);
        }
    }

    private void CreateBuffersIFN()
    {
        if (this.inputAndTime == null)
        {
            // 2 touches 2 fois (4) + souris (2) + bouton souris (2) + dt (1) = 
            this.inputAndTime = new UnityEngine.ComputeBuffer(16, 4);
            this.inputAndTimeDatas = new float[this.inputAndTime.count];
        }

        if (this.worldData == null)
        {
            int sizeofOfStruct = System.Runtime.InteropServices.Marshal.SizeOf(typeof(WorldData));
            this.worldData = new UnityEngine.ComputeBuffer(1, sizeofOfStruct);
        }

        if (this.ballData == null || this.ballData.count != this.InstanceCount)
        {
            this.ballData?.Release();
            int sizeofOfStruct = System.Runtime.InteropServices.Marshal.SizeOf(typeof(BallData));
            this.ballData = new UnityEngine.ComputeBuffer(this.InstanceCount, sizeofOfStruct);
            this.doReset = true;
        }
    }

    private void FillInputAndTime(CommandBuffer commandBuffer)
    {
        this.inputAndTimeDatas[0] = UnityEngine.Time.deltaTime;
        this.inputAndTimeDatas[1] = UnityEngine.Time.smoothDeltaTime;

        this.inputAndTimeDatas[2] = UnityEngine.Input.GetKey(UnityEngine.KeyCode.LeftArrow) ? 1 : 0;
        this.inputAndTimeDatas[3] = UnityEngine.Input.GetKey(UnityEngine.KeyCode.RightArrow) ? 1 : 0;

        this.inputAndTimeDatas[4] = UnityEngine.Input.GetKey(UnityEngine.KeyCode.Q) ? 1 : 0;
        this.inputAndTimeDatas[5] = UnityEngine.Input.GetKey(UnityEngine.KeyCode.D) ? 1 : 0;

        this.inputAndTimeDatas[6] = UnityEngine.Input.mousePosition.x;
        this.inputAndTimeDatas[7] = UnityEngine.Input.mousePosition.y;
        this.inputAndTimeDatas[7] = UnityEngine.Input.GetKey(UnityEngine.KeyCode.Mouse0) ? 1 : 0;
        this.inputAndTimeDatas[8] = UnityEngine.Input.GetKey(UnityEngine.KeyCode.Mouse1) ? 1 : 0;

        commandBuffer.SetComputeBufferData(this.inputAndTime, this.inputAndTimeDatas);
    }

    private struct BallData
    {
        UnityEngine.Vector2 pos;
        UnityEngine.Vector2 speed;
        uint status;
    }

    private struct WorldData
    {
        UnityEngine.Vector2 handle0Pos;
        UnityEngine.Vector2 handle0Size;
        UnityEngine.Vector2 handle1Pos;
        UnityEngine.Vector2 handle1Size;

        UnityEngine.Vector2 worldSize;

        uint player0Score;
        uint player1Score;
    }
}
